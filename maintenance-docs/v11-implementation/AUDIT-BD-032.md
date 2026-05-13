# AUDIT-BD-032 — Auditor observability infrastructure vs. configuration boundary (rule 21)

## §0 One-line summary

Rule 21's prose split between `auditor-architecture` (wiring exists) and `auditor-ops` (configured for deployment) is **logically defensible and well documented for the two scenarios it names**, but suffers from **shallow example density (2 ops-side examples, 2 architecture-side examples)** and **silence on three operationally common scenarios** (sampling configuration, alerting/SLO wiring, log-redaction *enforcement* path) that will produce live boundary disputes the moment a real cloud-deployed observability codebase is audited. Verdict: **CLEAN WITH NITS** for the rule itself; one **SHOULD-FIX** for missing the metrics/traces sub-cases that mirror the logging treatment in deployment-python rule 21.

## §1 Audit scope + methodology

### What I read

- `BACKLOG.md` BD-032 entry (lines 2445–2462) — authoritative spec.
- `project-template/skills/audit-methodology/SKILL.md` rules 13–21, 25–32, 33–39, 40–47.
- `project-template/.claude/agents/auditor-ops.md` (full).
- `project-template/.codex/agents/auditor-ops.toml` (full).
- `project-template/.gemini/agents/auditor-ops.md` (full).
- `project-template/.claude/agents/auditor-architecture.md` (full).
- `project-template/.gemini/agents/auditor-architecture.md` (frontmatter + Permission/Output sections, for trinity baseline comparison).
- `project-template/skills/deployment-python/SKILL.md` (whole file, 43 lines).
- `project-template/skills/deployment-apple/SKILL.md` (whole file, 43 lines).
- `project-template/skills/python-server-architecture/SKILL.md` (whole file, 45 lines).
- `project-template/skills/apple-architecture-core/SKILL.md` (whole file, 99 lines).
- `project-template/skills/ios-architecture/SKILL.md`, `macos-architecture/SKILL.md`, `python-data-architecture/SKILL.md` (greps only — no observability rules present).
- `project-template/docs/pack/PACK-FEEDBACK.md` Q1 entry (lines 310–332) — confirms the original deferral rationale.
- `project-template/docs/pack/PLATFORM-SKILLS.md` — confirms `deployment-python` / `deployment-apple` are the skills auditor-ops loads, and `python-server-architecture` / `apple-architecture-core` are the skills auditor-architecture loads for observability infrastructure rules.

### What I did not read (and why)

- `project-template/CLAUDE.md`, `AGENTS.md`, `GEMINI.md` — out of scope; rule 21 lives entirely inside `audit-methodology/SKILL.md` and the per-CLI auditor-ops agent files.
- `auditor-code.md`, `auditor-ui.md`, `auditor-tests.md`, `auditor-security.md`, `auditor-docs.md` — adjacent boundaries only; not the BD-032 target. Cross-cutting findings noted as OBSERVATIONs, not as scope creep into BD-033/BD-034.
- `maintenance-docs/v11-research/*` — out-of-band per scope guard.
- `scripts/`, `Sources/`, build artifacts — pack repo has no observability code (the very condition that made this an audit-only desk evaluation).

### Methodology

- **Walked five concrete observability scenarios** through the rule and the agent files. For each, decided whether rule 21 + its boundary clarification + the auditor-ops scope text + the auditor-architecture scope text is enough for an agent to assign ownership without escalation. Recorded each outcome in §5.
- **Counted concrete examples** in rule 21's "Boundary clarification" paragraph vs. comparable boundary clarifications in rules 16 and 20.
- **Diffed** auditor-ops.md across `.claude/agents/` and `.gemini/agents/` and inspected `.codex/agents/auditor-ops.toml` to verify the trinity discipline status.
- **Cross-checked** the loaded skill bodies — `deployment-python`, `deployment-apple`, `python-server-architecture`, `apple-architecture-core` — to see what observability rules an auditor-ops or auditor-architecture agent would *actually* be applying when it cites rule 21. This matters because the rule's clarity is only useful if the loaded skills give the agents something to enforce.

## §2 Rule 21 verbatim

From `project-template/skills/audit-methodology/SKILL.md` line 55:

> 21. **auditor-ops** — deployment readiness, configuration management, and cross-cutting operational concerns. Covers: platform-specific deployment configuration correctness (signing, entitlements, notarization, container security, health checks, graceful shutdown), configuration management (env vars, feature flag defaults, per-environment config correctness, drift between environments), and observability configuration (logging output format, metrics endpoints, tracing exporter setup). Always runs — every project deploys somewhere. **Boundary clarification — observability code in source files.** Observability *code* that lives in source files (e.g., `Sources/Observability/Bootstrap.swift`, `server/src/observability/setup.py`) belongs to auditor-architecture if the finding is structural ("the `Logger` protocol is the wrong shape", "`configure_tracing` is not wired into the app entry point"). It belongs to auditor-ops if the finding is about deployment-target correctness ("the OTLP endpoint is hardcoded", "the resource `service.name` is missing for cloud deployment", "the exporter is not installed for the prod environment"). When uncertain, file under auditor-ops — operational findings almost always have a deployment-shaped fix. Findings about *log content* (credentials, tokens, PII in log messages) belong to auditor-security per rule 33; auditor-ops may surface them as deployment-config-shaped concerns and annotate `(also detected by: security)` per rule 33.

The `auditor-architecture` mirror text in rule 15 is short:

> observability infrastructure completeness (are logs/metrics/traces wired up at the right layers?)

The detailed mirror lives in `project-template/.claude/agents/auditor-architecture.md` under "Observability infrastructure" — it explicitly defers source-file deployment-target code to auditor-ops via the same wording, preserving the boundary on both sides.

## §3 Findings

### F1 — Rule 21 names logging as a sub-domain three times but names metrics and tracing only once each

**Severity:** SHOULD-FIX
**Evidence:**

- `audit-methodology/SKILL.md:55` (rule 21) — the sentence "observability configuration (logging output format, metrics endpoints, tracing exporter setup)" is the only place metrics and tracing are listed as ops-side concerns. The Boundary-clarification paragraph that follows gives **two ops-side examples (`OTLP endpoint hardcoded`, `service.name missing`, `exporter not installed`) — all OpenTelemetry / tracing-flavoured** — and **two architecture-side examples (`Logger protocol wrong shape`, `configure_tracing not wired`) — one logging, one tracing**. There are zero metrics-flavoured boundary examples on either side.
- `deployment-python/SKILL.md:41` carries exactly **one** observability rule (rule 21 — "Enable structured logging (JSON format) for production"). No metrics-export rule, no tracing-export rule. So the ops-side skill an `auditor-ops` agent loads gives it **nothing to cite** for the metrics-endpoint and tracing-exporter ops-side concerns rule 21 names.
- `deployment-apple/SKILL.md` has zero observability rules of any kind (the only `log` hit is a notarization-log troubleshooting note).
- `python-server-architecture/SKILL.md:44` (rule 8 — "Auth, logging, and metrics belong in gRPC interceptors") is the **only** observability-infrastructure rule in any architecture skill. No tracing-propagation rule, no metric-collection-point rule, no logger-abstraction-shape rule — even though all three are explicitly named as auditor-architecture concerns in rule 15 and in `auditor-architecture.md`'s "Observability infrastructure" bullet.
- `apple-architecture-core/SKILL.md` has zero observability rules.

**Why it matters:** Rule 21's prose says "logging output format, metrics endpoints, tracing exporter setup" are all in scope for auditor-ops. But the agent loading rule 21 *plus* the deployment skills will only have a logging-shaped rule to enforce. The same agent has the rule's permission to flag a missing metrics endpoint as a defect but has no skill-level rule defining what "missing metrics endpoint" looks like for a Python server (Prometheus `/metrics`? OTLP push? StatsD?) — so it will either guess inconsistently or skip the finding. This is a "rule says X is in scope but the loaded skills don't give the agent X to apply" gap, not a rule-21-text gap *per se*, but it manifests as boundary noise: an agent unsure whether a vague-feeling tracing finding is "structural" (architecture) or "deployment-target" (ops) will default per the rule's last-resort guidance ("When uncertain, file under auditor-ops") and then have nothing in deployment-python to cite.

**Recommended disposition:** **Add concrete example to rule 21** — specifically one metrics-flavoured boundary pair (e.g., "metrics histogram bucket boundaries hardcoded for sub-millisecond local development = ops" vs. "no metrics emitted at the service-layer boundary at all = architecture"). AND **add a sub-rule for the specific boundary case** in the form of a deployment-python observability rule that names the metrics export and tracing export expectations the auditor-ops agent is supposed to enforce. The latter is technically a deployment-python skill change, not a rule 21 change — flag for Pack Chat triage so it can route to the right batch (this audit's scope is rule 21, but the gap is real and worth surfacing).

---

### F2 — "When uncertain, file under auditor-ops" tilts the boundary toward ops without naming the consequence

**Severity:** NIT
**Evidence:** `audit-methodology/SKILL.md:55` — "When uncertain, file under auditor-ops — operational findings almost always have a deployment-shaped fix."

**Why it matters:** This is a sensible default and I'm not proposing flipping it. But the rule does not name what *should* trigger uncertainty in the first place. A reader of the rule cannot infer: "if the finding has both a code shape AND a config shape, file under ops." The rule lists 3 ops-side examples and 2 architecture-side examples, all unambiguous; the genuinely ambiguous middle (e.g., "the exporter is installed conditionally on `ENV == 'prod'` via a runtime check inside `setup_tracing()`") is precisely the case the boundary clarification was added to handle, and it is also precisely the case the rule does not work an example for. Result: the heuristic fires correctly for the unambiguous cases (where it isn't needed) and is silent on the ambiguous ones (where it is). Mild — readers can *infer* the intent — hence NIT.

**Recommended disposition:** **Refine the boundary phrasing in rule 21** — add one sentence after "When uncertain, file under auditor-ops" naming what triggers uncertainty: "Uncertainty typically arises when the same source-file location has both a structural shape (the abstraction or wiring is wrong) and a deployment-target shape (the wrong concrete value was chosen). Prefer ops in those cases — the deployment-shaped fix usually subsumes the structural fix." OR: leave as-is and accept the looseness — the default works, the cost of being wrong is low (cross-detection annotation makes it visible to the other cluster anyway).

---

### F3 — Sampling-rate, alerting, and SLO wiring are absent from rule 21's enumeration

**Severity:** SHOULD-FIX
**Evidence:** Rule 21's "observability configuration" parenthetical names "logging output format, metrics endpoints, tracing exporter setup." It does NOT name:

- **Trace / log sampling rate** (e.g., "the prod trace sampler is hardcoded to 1.0, which will overwhelm the collector"). This is unambiguously a deployment-target concern; ops would clearly own it. But because it isn't named, an auditor-ops agent following the rule literally may treat it as out of scope.
- **Alerting / SLO hooks** (e.g., "the metric `http_request_duration_seconds` is exported but no alert rule references it; no SLO is defined; the operations team has no signal when latency degrades"). The BD-032 problem description explicitly names "alerting hooks" as an auditor-ops concern, but rule 21 does not.
- **Log retention** (the BD-032 problem also names "retention" — also unnamed in rule 21).

**Why it matters:** All three of these are operationally critical for cloud-deployed observability and all three live in deployment manifests (Prometheus rules, alertmanager configs, OTel collector sampler config) which are inside `auditor-ops`'s file scope per rule 32. The rule grants the agent the file scope but not the rule to apply. An agent reading rule 21 and finding an alertmanager YAML with no rules defined will be uncertain whether "no alert rules" is a finding at all.

**Recommended disposition:** **Add a sub-rule for the specific boundary case** — extend rule 21's enumeration to: "logging output format, log retention, metrics endpoints, sampling rates, tracing exporter setup, alerting/SLO definitions" (or similar minimal additions). This is a phrasing-only change to rule 21 plus a consequent broadening of the auditor-ops.md "Scope" bullet on observability wiring (which currently mirrors the rule). NOTE: the BD-032 BACKLOG description names alerting and retention, but the implemented rule does not. That gap between the BACKLOG framing and the rule body is itself the finding.

---

### F4 — Rule 21's boundary clarification gives examples but does not name the *test* an agent can apply

**Severity:** OBSERVATION
**Evidence:** Rule 21's boundary clarification works by enumeration: three ops-side examples, two architecture-side examples, plus the "when uncertain" default. There is no underlying rubric stated. By contrast, rule 16 (auditor-code systemic threshold) names a concrete test: "*systemic* when the same divergence or omission appears at three or more independent call sites, OR crosses module boundaries." That rule can be applied without examples; the threshold is the test.

**Why it matters:** If we ever want to add observability scenarios beyond the original five, the maintenance burden falls on whoever is editing the rule to invent more examples that fit the implicit pattern. A named test — e.g., "structural if the fix would change the *type* of an interface, the *call graph*, or the *wiring* between modules; deployment-target if the fix would change a *value* read from configuration at runtime" — would let new scenarios be classified by the test rather than by analogy. Not urgent — examples are working today — but worth flagging because rule 16 is the precedent and rule 21 diverges from it.

**Recommended disposition:** **No change needed** for v11.0; revisit when BD-032 closes empirically (first real cloud-observability audit) and the example list would otherwise grow past ~6 entries. At that point: **Refine the boundary phrasing in rule 21** to add a one-sentence rubric and prune redundant examples.

---

### F5 — Auditor-ops scope text and rule 21 prose duplicate the boundary clarification verbatim across four files

**Severity:** OBSERVATION
**Evidence:** The "Boundary clarification — observability code in source files" prose exists nearly verbatim in:

- `audit-methodology/SKILL.md:55` (rule 21 itself)
- `project-template/.claude/agents/auditor-ops.md` lines 26–37 (Scope / Observability wiring bullet)
- `project-template/.gemini/agents/auditor-ops.md` lines 28–39
- `project-template/.codex/agents/auditor-ops.toml` line 19 (developer_instructions)
- `project-template/.claude/agents/auditor-architecture.md` lines 30–40 (Observability infrastructure bullet — mirror side of the same boundary)

Five copies of the same boundary text (with the audit-methodology one being canonical and the four agent-file ones derived). When rule 21 changes — and F1, F3 above suggest it should — all five sites need the parallel edit. The skill says "If a subagent file and this skill disagree, this skill wins" (line 8–10), so the duplication is *safe* (the skill is canonical), but it's still a maintenance tax. The agent-file bullets could legitimately reduce to "see audit-methodology rule 21 for the boundary clarification" since the skill is loaded by all auditor subagents anyway.

**Recommended disposition:** **No change needed** for BD-032. Surface for Pack Chat triage as a possible separate cleanup BD — collapsing the duplicated prose to skill-only with one-line cross-references in the agent files would be a structural change, not a rule-21 fix. Out of scope for this audit.

## §4 Trinity discipline check

**Auditor-ops three-file comparison:**

- `project-template/.claude/agents/auditor-ops.md` — 148 lines.
- `project-template/.codex/agents/auditor-ops.toml` — 66 lines (TOML wrapper around `developer_instructions = """..."""` block; necessary format difference).
- `project-template/.gemini/agents/auditor-ops.md` — 131 lines.

**Are they byte-identical or differ only by per-tool tokens?** **No — and intentionally so.** The Gemini variant is a condensed-prose version of the Claude variant (Hard rules section compressed from per-bullet expansion into one-line entries; Permission / Output policy sections trimmed of the "no system reminder forbids this write" defensive paragraphs). The Codex variant is a TOML-encoded paraphrase. This pattern repeats across `auditor-architecture.md` (verified: same condensation pattern) and presumably across all auditor subagents — it is a pre-existing pack convention, not a BD-032 regression.

**Trinity disposition:** Cross-CLI prose drift exists and is consistent with the rest of the auditor agent set. The substantive content — the Scope/Observability-wiring bullet that carries rule 21's boundary clarification — is **prose-identical across all three files** (verified by direct read). The boundary-clarification semantics are preserved on all three CLIs. The drift is in the surrounding "Permission profile" / "Hard rules" boilerplate, which is not BD-032's concern.

**Recommended disposition:** **No change needed** for BD-032. If the broader question "should the trinity be tightened to byte-identity for auditor agent files" comes up, that is a separate structural BD touching all 7 auditor subagents simultaneously — not appropriate to attach to a rule-21 audit.

## §5 Boundary scenarios walked through

I walked five scenarios through rule 21 + the auditor-ops scope + the auditor-architecture scope:

### Scenario A — "The OTLP exporter is configured with `endpoint = 'http://localhost:4318'` in `setup_tracing.py` and is never overridden by env var; production deploys with this hardcoded value"

Boundary outcome: **Clean — auditor-ops owns it.** Rule 21's example list literally names "the OTLP endpoint is hardcoded" as an ops-side example. No ambiguity.

### Scenario B — "The `Logger` protocol exposes only `log(message: String)` with no severity or structured-fields support; service-layer code calls it but cannot attach request-id"

Boundary outcome: **Clean — auditor-architecture owns it.** Rule 21's example list names "the `Logger` protocol is the wrong shape" as an architecture-side example. No ambiguity.

### Scenario C — "The trace context is not propagated across the gRPC client→server boundary in the dev environment because no `OpenTelemetryClientInterceptor` is registered on the channel"

Boundary outcome: **Ambiguous — leans architecture.** This is the BD-032 prompt's example. Rule 21 does not name interceptor wiring. Two readings:

1. *Architecture:* "interceptor not registered" = wiring missing = the configure-tracing wasn't wired into the app entry point = explicit architecture example in rule 21.
2. *Ops:* "in the dev environment" = environment-conditional configuration = ops.

The rule's tilt — "When uncertain, file under auditor-ops" — would push this to ops. But that's wrong here: the missing interceptor is structural (call graph misses a hop), and the dev-vs-prod framing is incidental noise. An agent applying the rule literally would file it under ops, get cross-detected as architecture, and the parent's ownership precedence (rule 35: "Architecture violation wins over code idiom") would not apply because both clusters are architecture-or-ops, not architecture-vs-code. **The parent has no precedence rule for ops-vs-architecture duplicates** — see rule 38's order ("security → architecture → tests → ops → code → ui → docs"), which would resolve in architecture's favour, but only after a duplicate is detected. This works mechanically but only if both subagents file the finding; if the auditor-ops agent files alone (per the "when uncertain" tilt) and auditor-architecture skips the location because it's in `Sources/Observability/setup.py` and looks deployment-config-shaped, the finding ends up in the wrong cluster with no signal that it was misclassified.

### Scenario D — "The Prometheus metrics endpoint `/metrics` is mounted in the gRPC server but no `Counter` or `Histogram` is registered for the per-RPC handler — the endpoint exists but emits nothing useful"

Boundary outcome: **Falls through.** This is half-architecture (no metric collection at the service-layer boundary = `python-server-architecture` rule 8 territory, which says "metrics belong in interceptors" but doesn't define what to count) and half-ops (the endpoint is configured but underutilized). Neither auditor-architecture nor auditor-ops has a specific rule to cite. The rule 21 enumeration says "metrics endpoints" are ops, suggesting the endpoint's *existence* and *exposure* are ops; the rule says nothing about whether *what is exposed* (or not exposed) at that endpoint is ops or architecture. Likely outcome: both agents skip it for lack of a citable rule.

### Scenario E — "The application logs sensitive data (Authorization header value) at INFO level in the request handler"

Boundary outcome: **Clean — auditor-security owns it per rule 21's explicit deferral.** Rule 21 says "Findings about log *content* (credentials, tokens, PII in log messages) belong to auditor-security per rule 33; auditor-ops may surface them as deployment-config-shaped concerns and annotate `(also detected by: security)`." Working as designed.

**Summary:** 2 of 5 scenarios are clean (A, B, E). 1 of 5 is ambiguous and resolves wrongly under the literal rule (C — the gRPC interceptor case). 1 of 5 falls through entirely (D — the empty metrics endpoint). 1 of 5 (E) demonstrates the rule's deferral to security works as designed.

## §6 Overall verdict

**NEEDS FIXES.** The rule's logical structure is sound, but two SHOULD-FIX gaps will produce live boundary disputes the moment a real cloud-deployed observability audit runs:

- **F1** — metrics and tracing are listed in rule 21's scope but neither has a worked boundary example AND the loaded deployment / architecture skills carry only one observability rule between them (deployment-python rule 21 — JSON logging). The rule's reach exceeds the loaded skills' grasp.
- **F3** — sampling, alerting / SLO, and log retention are operationally critical and live inside the auditor-ops file scope (rule 32) but are not named in rule 21's enumeration. The BD-032 BACKLOG description names them; the implemented rule does not. Closing this gap is a phrasing-only change to rule 21 plus a parallel one-line edit to the three auditor-ops agent files.

**Plus one NIT (F2)** — uncertainty trigger unnamed; mild, defer-able; **and two OBSERVATIONs (F4, F5)** — rule 21's enumeration vs. rubric structure (F4) and the boundary-clarification prose duplicated across five files (F5). Both are out of BD-032 scope per the audit-only mandate and are surfaced for Pack Chat triage rather than as fix proposals.

**Trinity discipline:** Pre-existing intentional cross-CLI condensation pattern; substantive content preserved across `.claude` / `.codex` / `.gemini` for both auditor-ops and auditor-architecture. Not a BD-032 concern.

**Pack Chat fix-pass guidance** (per EXECUTION-PLAN §4 Batch 14 + in-session fix rule §B): F1 and F3 can be addressed in one rule-21 phrasing edit + one parallel three-file agent edit + (separately, route to a different batch or BD) one or two new rules in deployment-python. F2 is a one-sentence add or accept-as-is. F4 and F5 should be tracked as separate observations and not bundled into BD-032's fix pass.
