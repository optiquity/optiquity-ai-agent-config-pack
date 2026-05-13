# ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY

**Author:** pack-architect
**Date:** 2026-05-12
**Pack version target:** v11.0 (in development on `v11-dev`)
**BD:** BD-162
**Pipeline stage:** 2 of 4 (researcher → **architect** → planner → coder)
**Output consumer:** `pack-planner` (for `PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY.md`)

Inputs read:
- `RESEARCH-DEPLOYMENT-PYTHON-OBSERVABILITY.md` (1077 lines, full)
- `AUDIT-BD-032.md` (cross-cutting note + scenarios C and D)
- `BACKLOG.md` BD-162 (lines 1354–1361)
- Existing skills: `deployment-python` (43 lines), `python-server-architecture` (47 lines), `python-best-practices`, `audit-methodology` rules 21 and 32
- Pattern references: `protobuf-patterns` (249 lines, ~45 rules), `swift-concurrency-patterns` (418 lines, 66 rules)
- `PLATFORM-SKILLS.md` §intersection table, §dimensional skills, §full skill inventory
- `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.1 / §3.2 thresholds

Design framing (from the user, verbatim):
> "Not too vague — 'respect retention policy' without naming what triggers a defect is useless to an auditor. Not too specific — citing a specific Prometheus client API method that may change in a year is brittle. Cover the topic properly — the auditor-ops agent should be able to act on these rules to catch real defects in real Python observability code."

The right-fit calibration is the binding constraint, not rule count. Rule count is downstream.

---

## §1 Scope decision

**Selected envelope: Comprehensive (~55–65 rules) with one explicit deferral.** Closer in shape to BD-158 swift-concurrency-patterns (66 rules, 418 lines) than to BD-156 protobuf-patterns (45 rules, 249 lines).

### 1.1 Why comprehensive — not conservative, not tracing-first

BD-162's stated success criterion is closing the BD-032 cross-cutting gap end-to-end: rule 21 names **five sub-domains** (metrics, tracing, sampling rate, alerting / SLO, log retention) and the auditor-ops agent must be able to cite real rules in each one. The two non-comprehensive envelopes both leave one or more sub-domains uncovered:

- **Conservative (~25–35 rules)** — covers tracing + metrics + log correlation, but omits alerting / SLO and retention. That re-opens the BD-032 gap from one level deeper: rule 21 promises auditor-ops can flag "no alert rule references the exported `http_request_duration_seconds` metric and no SLO is defined" and "the log retention policy in the deployment manifest defaults to 1 day in prod" (both verbatim from rule 21's expanded enumeration), but the loaded skills wouldn't carry the rules to cite. The conservative envelope is incompatible with the BD-032 audit's already-shipped rule 21 wording.
- **Tracing-first (~40 rules)** — same problem: defers metrics-naming + SLO + retention. Made sense as a hedge if metrics or SLO surfaced as volatile in research, but research §6 shows both are highly stable (Prometheus naming conventions and the Google SRE MWMB pattern have been settled for years).
- **Comprehensive** — matches the rule 21 enumeration one-to-one. Each sub-domain gets its own clearly-titled section, so the auditor-ops agent has a deterministic citation target per finding.

### 1.2 Cluster-by-cluster decisions (research §8.1)

| # | Research cluster | In scope | Rationale |
|---|---|---|---|
| 1 | Trace SDK setup + resource attributes | YES | Very durable; semconv resource shape is the foundation for every tracing rule |
| 2 | Span lifecycle + attributes | YES | Very durable; semconv namespaces (HTTP/RPC/DB) are version-pinned but the *shape* (lowercase dotted, low-cardinality `http.route`, `_method` not `_get`) is durable |
| 3 | Trace context propagation | YES | Very durable; W3C TraceContext is an IETF standard since 2020 |
| 4 | Auto-instrumentation discipline | YES, abbreviated | The *workflow* (distro + bootstrap + instrument; auto for inbound/outbound HTTP/DB/RPC; manual for domain-significant) is durable. Rules cite the *workflow shape* not specific package names |
| 5 | Exporter configuration | YES | Durable; OTLP gRPC default + OTLP HTTP fallback + collector tier is the canonical pattern |
| 6 | Prometheus metric naming | YES | Very durable; the naming guide has been stable for ~8 years |
| 7 | Prometheus label cardinality | YES | Very durable; this is *the* Prometheus rule that catches real defects |
| 8 | Prometheus metric type selection | YES | Very durable; Counter/Gauge/Histogram/Summary semantics are foundational |
| 9 | Prometheus multiprocess mode | YES | Durable, gate-shaped (only fires for fork-model servers); skipping it would miss a common production defect class |
| 10 | Metrics endpoint exposition | YES | Durable; `/metrics` exposition shape is fixed |
| 11 | Structured logging — required fields | YES | Very durable; field set (timestamp/level/service/trace_id/request_id/exception) is library-agnostic |
| 12 | Trace-log correlation | YES | Durable; `OTEL_PYTHON_LOG_CORRELATION` + the `otelTraceID` / `otelSpanID` field names are stable |
| 13 | Sensitive-data redaction | YES, narrowed | Rule the *shape* (no secrets in bound contexts; redaction processor early in pipeline). Defer *content classification* to `auditor-security` per audit-methodology rule 33 — cross-reference, do not duplicate |
| 14 | Log destination + per-environment level | YES | Durable; stdout-for-cloud is the floor |
| 15 | Sampling — head sampler default | YES | Durable; `ParentBased(TraceIdRatioBased(ratio))` is the Python SDK consensus default |
| 16 | Sampling — tail sampling boundary | YES | Durable as a *boundary rule* ("tail sampling is collector-side, not SDK-side; do not implement custom tail sampling in the application"). Operational specifics defer to deployment manifest review |
| 17 | SLO + burn-rate alerts | YES, shape-only | Rule the *SLO definition shape* (SLI / Objective / MWMB 4-window) and the *page-vs-ticket routing principle*. Do NOT rule the framework choice (Sloth vs Pyrra vs Grafana SLO vs hand-written) — research §8.3 flagged framework choice as project-shaped |
| 18 | Retention policy expectations | YES, shape-only | Rule the *tiering shape* (hot/warm/cold defined; audit logs separated; metrics downsampling acknowledged). Do NOT rule specific day counts — those are vendor- and compliance-shaped |

### 1.3 Pack-fit calibration

- **Size.** Estimated 55–65 rules across 9–11 sections, ~350–420 lines. Sits between BD-156 (45 rules, 249 lines) and BD-158 (66 rules, 418 lines). Inside the established `*-patterns` band.
- **Shape.** Frontmatter + Applicability section + numbered rules grouped under topical `## Section` headings — same shape as BD-156 / BD-158.
- **Tone.** Imperative, terse rule statements; durable principles (named tests an auditor can apply) over example dumps; cite library *workflow* names but not specific method signatures.
- **Loadability.** Single canonical SKILL.md path per pack convention; per-CLI fan-out at install time via `init-project.sh stage_s4_skills`.

### 1.4 Durability anchors

Every rule in the comprehensive envelope traces back to one of: an IETF / W3C standard (TraceContext, Baggage), an OpenTelemetry semantic-convention namespace pattern (the *shape* of `http.*` / `rpc.*` / `db.*`, not specific attribute names that may revise), a Prometheus naming guideline (8 years stable), the Google SRE workbook MWMB pattern (5+ years stable as the canonical alerting recipe), or an industry-baseline retention shape. Volatile material (research §8.3: native histogram client API, `tracestate` "ot" key, OTel Logs SDK as sole log path, eBPF auto-instrumentation, specific SLO framework) is deferred — see §6 anti-rule list.


---

## §2 Skill placement (resolves ADP-2)

**Decision: Option (C) — create a NEW skill `python-observability-patterns/SKILL.md` at the single canonical path `project-template/skills/python-observability-patterns/SKILL.md`.**

### 2.1 Why (C) and not (A) or (B)

**Option (A) — append to `deployment-python/SKILL.md`** is rejected for two independent reasons:

1. **Center-of-gravity inversion.** `deployment-python` is currently 43 lines / 23 rules covering Docker, secrets, health checks, graceful shutdown, and production config. Adding 55–65 observability rules would make observability ~70% of the file's mass and shift its identity from "deployment" to "deployment + observability." That violates BD-149's naming-convention discipline (the suffix `-python` denotes deployment scope, not a multi-topic catch-all) and creates a misleading load semantics: the skill loads at D2=python ∩ D5=linux-container, but observability rules apply to *any* Python server regardless of deployment surface (a developer running locally during a code review still wants the rules to fire).
2. **Agent-load mismatch.** `deployment-python` loads only for `auditor-ops` and `docs-researcher` per the dimensional skills table (PLATFORM-SKILLS.md line 461). The observability rule set's natural audience is much broader — `architect`, `coder`, `reviewer`, `auditor-architecture`, and `auditor-code` all need the in-process structural rules (span lifecycle, metric type selection, log field requirements). Forcing them through `deployment-python` would either expand its agent-load list (broadening a deployment skill's reach beyond deployment) or fragment the rules so half live elsewhere.

**Option (B) — split between `deployment-python` and `python-server-architecture`** is the cleanest mapping onto the audit-methodology rule 21 ownership rubric (deployment-config-shaped → ops; type / call graph / wiring → architecture). It would work. But it has three costs:

1. **Two-location authoring.** Every observability concept gets divided across two files — span attribute semantics live in `python-server-architecture`, exporter endpoint config lives in `deployment-python`, and the cross-references between them carry the maintenance burden. Future additions force a re-classification decision per rule.
2. **Discoverability tax.** A developer asking "how does this pack handle Python tracing?" has no single skill to read — they must traverse two skills + the rule-21 boundary clarification to assemble the picture.
3. **Conflict with the "single-skill, multi-agent loading" precedent.** BD-156 (`protobuf-patterns`) and BD-158 (`swift-concurrency-patterns`) both keep their domain together in one skill and rely on per-agent loading filters to scope visibility. Splitting across two skills here would diverge from that precedent for no compensating benefit.

**Option (C) — new `python-observability-patterns` skill** wins on:

1. **Direct precedent.** BD-156 (protobuf-patterns) and BD-158 (swift-concurrency-patterns) both created new `*-patterns` skills for exactly this kind of cross-cutting domain (one per major-subject-area that touches multiple agents and multiple project shapes). BD-162's BACKLOG description explicitly cites that precedent ("comparable to BD-156 protobuf-patterns ... or BD-158 swift-concurrency-patterns"). The pack's `*-patterns` suffix exists for this case.
2. **Agent-load fit.** A single skill loaded by `architect`, `coder`, `reviewer`, `auditor-architecture`, `auditor-code`, AND `auditor-ops` — each agent applies the rules through its own scope filter (auditor-ops focuses on the deployment-config-shaped half per audit-methodology rule 21's ownership rubric; auditor-architecture focuses on the structural half). The rule 21 boundary is preserved at the *agent's interpretation* layer, not by physically splitting the rules.
3. **Discoverability.** One file. One name (`python-observability-patterns`) that says exactly what it covers. Cross-references collapse to "see this skill" rather than "see this skill for X and that skill for Y."
4. **`deployment-python` stays focused.** Its 23 rules continue to cover Docker / secrets / health / shutdown / config — a coherent deployment-readiness scope. Its existing observability rule (the JSON logging one-liner) consolidates into the new skill — see ADP-4 resolution.

### 2.2 The boundary-rubric concern (option B's strongest argument)

Audit-methodology rule 21 defines a clean rubric: ops if the fix changes a *value* read from configuration; architecture if the fix changes a *type* / *call graph* / *wiring*. Option (B) maps this rubric onto skill placement. Option (C) does not — it puts both kinds of rules in one skill.

**Option (C) handles this by surfacing the rubric inside the skill body.** The new skill's Applicability section names the rubric explicitly and tells each loading agent which subset to apply. Worked example: rule "the OTLP exporter endpoint MUST be set via `OTEL_EXPORTER_OTLP_ENDPOINT`, not hardcoded in source" is a deployment-config-shaped rule → auditor-ops applies it. Rule "the application MUST register `LoggingInstrumentor` at process entry point" is a wiring-shaped rule → auditor-architecture applies it. Both live in `python-observability-patterns`; both are tagged in the rule body with a parenthetical owner-cluster hint (e.g., `(ops)` / `(arch)` / `(both)`) so the loading agent has a deterministic application target.

This is the same pattern audit-methodology rule 21 itself uses — name the rubric, enumerate the boundary cases, let the loading clusters apply. It works there; it works here.

### 2.3 Resulting cross-references

If (C) is approved, the surrounding edits are:

- `deployment-python/SKILL.md`: replace its current rule 21 (JSON logging one-liner) with a 1-line cross-reference: "Observability rules live in `python-observability-patterns`. This skill covers deployment-config concerns (Docker, secrets, health, shutdown, env-driven production config)." Renumber subsequent rules.
- `python-server-architecture/SKILL.md`: extend its current rule 8 (gRPC interceptors carry auth/logging/metrics) with a one-line cross-reference: "Substantive observability rules — span lifecycle, metric type selection, structured-log field requirements, trace-log correlation — live in `python-observability-patterns`. This skill defines the *placement* (interceptors / middleware); the patterns skill defines *what to put in them*."
- `audit-methodology/SKILL.md` rule 21 boundary clarification: no edits required — its named test ("ops if the fix changes a value, architecture if the fix changes a type / call graph / wiring") already supports the in-skill-body rubric. Optional addition: append "(rules to apply: see `python-observability-patterns` for D2=python projects)" but this is purely informational; the loading mechanism doesn't need it.


---

## §3 Resolve remaining ADPs

### 3.1 ADP-1 — Canonical library citation per rule

**Decision: cite library *roles*, not library names, in the rule statements; name canonical libraries in the Applicability section as the assumed ecosystem; permit alternatives where research §6 shows a real split.**

Per concern:

| Concern | Canonical citation in rule body | Alternatives acknowledged in Applicability |
|---|---|---|
| Tracing API/SDK | **OpenTelemetry** (`opentelemetry-api` / `opentelemetry-sdk`) | None — OpenTracing and Jaeger native clients are deprecated (research §6.2). Single canonical choice |
| Auto-instrumentation runtime | **`opentelemetry-distro` + `opentelemetry-bootstrap` + `opentelemetry-instrument`** workflow | None — this is the only documented zero-code path |
| Exporters | **OTLP** (gRPC default; HTTP fallback) | Vendor exporters acknowledged as legacy paths (research §6.2 / §7.2) |
| Metrics SDK | **Prometheus client (`prometheus_client`)** as the dominant canonical choice; OpenTelemetry metrics SDK acknowledged as alternative | Both permitted. Rules name the *concept* (counter ends in `_total`, histogram buckets must straddle the SLO threshold) and mention "via `prometheus_client` or via OpenTelemetry metrics → OTLP → Prometheus translation" where relevant |
| Structured logging | **Library-agnostic field set**; recommend `structlog` for new code, `python-json-logger` over stdlib as the universal floor | Both permitted; loguru acknowledged but not recommended (no native OTel integration per research §3.1) |
| Trace ↔ log correlation | **`opentelemetry-instrumentation-logging`** with `OTEL_PYTHON_LOG_CORRELATION=true` | OTel Logs SDK named as forward direction; not the rule-able foundation today |

**Why not pick one structured-logging library as canonical:** research §3.1 / §6.1 shows three viable options with no dominant choice. Forcing one ("must use structlog") would (a) conflict with the auditor's right-fit calibration (the user's example: brittle citation of a specific library API method), (b) generate false-positive defects against projects using a different valid library, and (c) age poorly if the landscape consolidates differently. Library-agnostic field-set rules survive any consolidation.

**Why pin OpenTelemetry as canonical for tracing:** research §6.2 confirms there is no other viable choice — OpenTracing and Jaeger client-libraries are deprecated and the OpenTelemetry project absorbed both. Single-choice citation is honest, not arbitrary.

**Why permit both prometheus_client AND OpenTelemetry metrics:** research §6.1 / §2.1 shows `prometheus_client` is dominant for Python today, but OpenTelemetry metrics → OTLP → collector → Prometheus is a working alternative path that some fleets prefer. Rules name the metric *shape* (naming, cardinality, type selection) which applies equally to both.

### 3.2 ADP-3 — Cross-references to `python-server-architecture`

**Decision: extend the cross-reference, do not duplicate rules.**

`python-server-architecture` rule 8 currently states: "Auth, logging, and metrics belong in gRPC interceptors (or framework middleware for REST), not in servicer / handler implementations." This is a *placement* rule — where observability concerns live in the request flow. It stays where it is.

The new `python-observability-patterns` skill answers a different question — *what* to put in those interceptors / middleware (which spans, which attributes, which metrics, which fields). The two skills compose:

- `python-server-architecture` rule 8 (placement) cross-references `python-observability-patterns` (content): the existing one-liner gains a trailing sentence as described in §2.3.
- `python-observability-patterns` Applicability section names `python-server-architecture` as the placement-rule home: "Where observability concerns are wired into the request flow (interceptors, middleware, app-entry-point hooks) is governed by `python-server-architecture` rule 8. This skill defines the substantive content of those wirings."

No content overlap. No rule numbering collision. Both skills load together for any Python server project (D2=python ∩ D3=server triggers both — see §4 below).

### 3.3 ADP-4 — Overlap with existing `deployment-python` rule 21

**Decision: replace `deployment-python` rule 21 with a one-line cross-reference; consolidate the substantive content into `python-observability-patterns`.**

Current `deployment-python` rule 21 reads: "Enable structured logging (JSON format) for production. Include request ID, method, status, and latency in every log entry."

This is a fragment of the full required-field set (research §3.2 cluster 11 enumerates timestamp, level, service identifiers, trace correlation, request identifiers, exception data, plus event-specific fields). Three options were considered:

- (a) **Replace with the expanded field-set rule** — rejected because expanded version belongs in the new skill (per §2.1's center-of-gravity argument).
- (b) **Keep rule 21 + add the new skill** — rejected because it creates a soft duplicate (two skills define the same concern at different fidelity), violates research §6.5's no-duplication clause, and forces auditor-ops to choose which to cite.
- (c) **Move rule 21 into the new skill; replace with cross-reference** — selected. `deployment-python` keeps its scope coherent (Docker / secrets / health / shutdown / production config); the structured-logging substance moves to its proper home; the cross-reference preserves discoverability for an auditor reading `deployment-python` end-to-end.

The cross-reference text is given in §2.3 above.

### 3.4 ADP-5 — Coverage of the auditor-ops rule 21 sub-domains

**Decision: all five sub-domains covered; depth varies by durability.**

| Sub-domain | Coverage depth | Rule count target | Justification |
|---|---|---|---|
| **Metrics** | Deep | 12–15 rules | Highest concentration of stable, defect-catching rules (naming, cardinality, type selection, multiprocess, exposition). Research §2 is durable end to end |
| **Tracing** | Deep | 14–18 rules | Same — research §1 is durable; semconv namespace shape is stable even if specific attribute names revise |
| **Sampling rate** | Medium | 4–6 rules | Head sampler default + per-environment ratio + the "no custom tail sampling in app" boundary rule. Tail sampling specifics defer to deployment manifest review (out of skill scope) |
| **Alerting / SLO** | Shape-only (medium) | 5–7 rules | Rule the SLI / Objective / MWMB shape and the page-vs-ticket routing principle. Do NOT rule framework choice (Sloth vs Pyrra vs Grafana SLO is project-shaped per research §8.3) |
| **Log retention** | Shape-only (light) | 3–5 rules | Tiering (hot/warm/cold), audit-log separation, metrics downsampling acknowledgement. Day counts are vendor- and compliance-shaped — rule the *shape* (tiers must exist; audit logs separate; downsampling configured), not the values |

Total estimate: 38–51 sub-domain rules + 5–8 cross-cutting rules (trace-log correlation, redaction-shape, log destination, per-environment level, OTLP exporter config, container observability boundary) = **43–59 rules**. Allows for some discovery during coder authoring; final count likely 50–65, comfortably in the BD-156/158 band.

### 3.5 ADP-6 — Trinity / multi-CLI considerations

**Decision: single canonical SKILL.md path. No CLI-specific divergence.**

Per pack convention (BD-156, BD-157, BD-158 all followed this), skills ship at `project-template/skills/<name>/SKILL.md` as a single source of truth. Per-CLI fan-out happens at install time via `init-project.sh stage_s4_skills`, which copies the skill into `.claude/skills/<name>/SKILL.md`, `.codex/skills/<name>/SKILL.md`, and `.gemini/skills/<name>/SKILL.md`.

The research found zero Python-specific CLI-tool divergence in the observability landscape. Trinity replication is the trivial default.

The trinity edits required by this BD that DO need parallel-edit discipline are NOT in the new skill itself but in the surrounding pack-product files — see §8 for the full list.


---

## §4 Loading semantics

### 4.1 Dimensional placement

`python-observability-patterns` loads as an **intersection-cell skill**, not a dimensional skill, not Tier 0.

**Predicate:** `D2=python ∩ (D3=server ∨ observability-marker present)`

The `D3=server` branch covers the dominant case (any Python gRPC / FastAPI / Django / Flask server). The marker branch handles the secondary case where observability is wired into a Python process that isn't a request-serving server (e.g., a Python data pipeline or worker that emits its own metrics / traces). The marker check is cheap and avoids missing legitimate observability codebases.

### 4.2 Detection marker

**New helper: `scripts/lib/detect.sh::python_observability_marker_detected()`** — parallels the existing `python_data_marker_detected()` (BD-141) and `swiftdata_marker_detected()` (BD-157) helpers.

Marker checks (any one true → load):

1. Dependency manifest (`requirements.txt`, `pyproject.toml`, `setup.py`, `setup.cfg`, `uv.lock`) lists any of: `opentelemetry-api`, `opentelemetry-sdk`, `opentelemetry-distro`, `opentelemetry-instrumentation*`, `opentelemetry-exporter-*`, `prometheus-client`, `prometheus_client`, `structlog`, `python-json-logger`.
2. Source file contains `import opentelemetry`, `from opentelemetry`, `import prometheus_client`, `from prometheus_client`, `import structlog`, or `from structlog`.

The marker is *additive* — D3=server already triggers loading even without the marker (a server with no observability deps still wants the rules to apply during *new code review*, when an architect is deciding what to wire in). The marker covers the non-server cases.

This matches the BD-141 / BD-157 convention exactly: marker helper in `scripts/lib/detect.sh`, intersection-table predicate in PLATFORM-SKILLS.md, no new dimension.

### 4.3 Agent loading

Per pack convention, skills are loaded by agent role × project shape. The new skill loads for:

- **`architect`** (intersection-loaded, per Step 2 in PLATFORM-SKILLS.md) — needs the structural half (where to wire observability, what shape spans take, what fields logs require).
- **`coder`** — needs the same content during implementation.
- **`reviewer`** — needs both halves to review observability changes.
- **`auditor-architecture`** — needs the structural half (per audit-methodology rule 21 ownership rubric: type / call graph / wiring rules).
- **`auditor-code`** — needs the code-idiom half (e.g., "do not use `Summary` in distributed deployments" is a code rule).
- **`auditor-ops`** — needs the deployment-config half (per audit-methodology rule 21 ownership rubric: value-shaped rules; sampler ratio; exporter endpoint; retention manifest values).
- **`docs-researcher`** — needs the rule set when answering "how does this pack handle observability?"

The skill body's per-rule `(ops)` / `(arch)` / `(code)` / `(both)` parenthetical (per §2.2) tells each loading agent which subset to apply.

### 4.4 PLATFORM-SKILLS.md cells the new content occupies

- **§Intersection table (line 213):** new row immediately after `python-server-architecture` (line 220) and before `apple-swiftdata-patterns` (line 223). Predicate: `D2=python ∩ (D3=server ∨ observability-marker)`.
- **§Full skill inventory dimensional table (line 439, current count: 19):** new row immediately after `python-server-architecture` (line 462). Updated count: 20.
- **§Combining dimensions worked examples (line 252):** the "Python gRPC server (Linux container)" example (line 270) and the "Mixed iOS+macOS+Python backend" example (line 281) both gain `python-observability-patterns` in the intersection list.
- **§Step 2 per-agent skill assignments (line 312):** add `python-observability-patterns` to architect, coder, reviewer, auditor-architecture, auditor-code, auditor-ops, docs-researcher.

### 4.5 Why not Tier 0, why not D2-implied

- **Not Tier 0** — observability rules don't apply to non-Python projects, and Tier 0 means "every project, every agent." Wrong shape.
- **Not D2-implied for D2=python** — research §3 / §4 confirms small Python scripts and CLI tools don't need this skill; only servers and observability-emitting processes do. D2-implied would over-load. The intersection mechanism (D2=python ∩ marker) is more discriminating.
- **Not loaded by `tester`** — observability rules don't apply to test-file authoring. (Tests verify observability *integration* via integration tests, but those are per-project test patterns, not pack-level rules.)


---

## §5 Rule set outline (organizational; NOT rule writing)

This section defines the section structure, per-section rule count target, and topical scope. **Rule text itself is the coder's job (stage 4).** Two worked-example rules in §5.10 illustrate the right-fit calibration; the rest is outline.

### 5.1 Frontmatter + Applicability (front matter)

YAML frontmatter (`name`, `description`, `allowed-tools`) following BD-156/158 shape. Applicability section (~25–35 lines) covering: (a) the load predicate; (b) the audit-methodology rule 21 ownership rubric and how the per-rule `(ops)`/`(arch)`/`(code)`/`(both)` tags map to it; (c) the canonical library positions per ADP-1; (d) cross-references to `python-server-architecture` rule 8 (placement) and `deployment-python` (deployment-config scope); (e) the boundary with `auditor-security` for log-content rules per audit-methodology rule 33.

### 5.2 §A — Telemetry SDK setup and resource attributes (5–7 rules)

**Topical scope:** OpenTelemetry SDK initialization at process entry; `Resource` set once and shared across signals; required resource attributes (`service.name`, `service.version`, `service.instance.id`, `deployment.environment`); semconv package version pinning; environment variables that drive SDK config (`OTEL_RESOURCE_ATTRIBUTES`, `OTEL_SERVICE_NAME`).

**Owner-tag mix:** `(both)` for "service.name MUST be set" — the *requirement* is structural (architecture audits the wiring), the *value* is deployment-target (ops audits the value's correctness for the environment).

### 5.3 §B — Span lifecycle and attributes (8–10 rules)

**Topical scope:** `start_as_current_span` over manual `start_span`; status code semantics (OK explicit only on domain confirmation; UNSET default; ERROR with `record_exception`); semconv-aligned attributes for HTTP / RPC / DB / messaging using the *namespace shape* (lowercase dotted, low-cardinality); `http.route` (template) not rendered URL; span links for fan-out / fan-in patterns; do-not-create-spans-in-tight-loops anti-pattern.

**Owner-tag mix:** mostly `(arch)` and `(code)` — in-process structural / idiomatic. One `(ops)` rule on the cardinality of attribute *values* under load.

### 5.4 §C — Trace context propagation (3–4 rules)

**Topical scope:** W3C TraceContext + Baggage as the default propagator pair; vendor-specific propagators (B3, Jaeger, X-Ray-headers) as opt-in for fleet interop only; programmatic `set_global_textmap()` vs `OTEL_PROPAGATORS` env; gRPC and HTTP propagation hookup via auto-instrumentation.

**Owner-tag mix:** `(arch)` for the wiring rules; `(ops)` for the env-var configuration.

### 5.5 §D — Auto-instrumentation discipline (3–4 rules)

**Topical scope:** the `opentelemetry-distro` + `opentelemetry-bootstrap` + `opentelemetry-instrument` workflow as the canonical zero-code path; auto-instrument inbound + outbound HTTP, DB, RPC, messaging at minimum; manually instrument domain-significant operations only (do not duplicate auto-coverage with manual spans); pinning of contrib package versions in lock file.

**Owner-tag mix:** mostly `(ops)` (workflow / dependency choices).

### 5.6 §E — Exporter configuration (4–5 rules)

**Topical scope:** OTLP gRPC default for in-cluster; OTLP HTTP for egress-restricted; collector tier between application and backend (do not export directly to vendor backends from new code); exporter timeouts and queue limits; the boundary with vendor-specific exporters (Cloud Trace / X-Ray / Application Insights — acknowledge as legacy paths; new code uses OTLP + collector translation).

**Owner-tag mix:** `(ops)` — endpoint, queue config, and collector wiring are deployment-target concerns.

### 5.7 §F — Prometheus metrics: naming, labels, types (12–15 rules)

**Three sub-sub-sections, since this is the largest section:**

- **F.1 Metric naming (4–5 rules):** counters end in `_total`; base SI units (`_seconds`, `_bytes`); single thing per metric; namespace/subsystem prefix discipline; reserved suffix conflicts (`_count` only for histograms).
- **F.2 Label cardinality (4–5 rules):** never label by unbounded sets (user_id, request_id, trace_id, raw URL); label by route templates; status-code-class vs specific-code rules; no PII in label values; the 10k-series-per-metric soft cap as an audit threshold.
- **F.3 Metric type selection (4–5 rules):** Counter vs Gauge vs Histogram vs Summary semantic differences; Summary is not aggregatable across instances (avoid in distributed deployments); histogram bucket selection (default for general HTTP latency, custom for outliers, native histograms acknowledged as forward direction); SLO-tuned bucket boundaries (the SLO threshold MUST be an exact bucket boundary).

**Owner-tag mix:** `(code)` and `(arch)` for naming / cardinality / type selection (in-process). `(ops)` for histogram bucket *values* (per environment).

### 5.8 §G — Prometheus exposition: multiprocess and endpoint (4–5 rules)

**Topical scope:** when multiprocess mode is required (fork-model servers — Gunicorn sync workers, uWSGI); `PROMETHEUS_MULTIPROC_DIR` env requirement and the directory-wipe-before-start rule; `MultiProcessCollector` at `/metrics`; per-gauge multiprocess mode selection (`livesum` / `liveall` / `min` / `max` / `sum` / `all`); `/metrics` endpoint exposition rules (unauthenticated or scrape-credential; excluded from request instrumentation; reachable from scraper).

**Owner-tag mix:** mostly `(both)` — the wiring is structural, the env var values are deployment-target.

### 5.9 §H — Structured logging: required fields and trace correlation (8–10 rules)

**Topical scope:** required field set (timestamp w/ TZ, level, service identifiers, trace_id / span_id, request_id, exception data on error, event-name as separate field from message body); library-agnostic field requirements (rules cite *fields*, not specific library APIs per ADP-1); `OTEL_PYTHON_LOG_CORRELATION=true` or programmatic `LoggingInstrumentor` setup at process entry; key naming for the OTel-injected fields (`otelTraceID`, `otelSpanID`); per-environment `LOG_LEVEL` and `LOG_FORMAT` defaults; stdout-as-destination for cloud-deployed services (no file destinations in containers); the *redaction-shape* rule (define a redaction processor / filter early in the pipeline; never bind auth headers to context-vars).

**Owner-tag mix:** `(arch)` for the wiring rules (where the LoggingInstrumentor lives); `(code)` for the bound-context discipline; `(ops)` for the env-driven level / format defaults.

**Cross-reference to `auditor-security`:** sensitive-data classification rules ("don't log JWTs / passwords / full PII") live in `security-patterns` per audit-methodology rule 33. This skill rules the *redaction-pipeline shape* (a processor exists; it runs early; it is testable); the security skill rules the *content classification* (which keys count as sensitive). Cross-reference to security-patterns in the rule body.

### 5.10 §I — Sampling (4–6 rules)

**Topical scope:** head sampler default — `ParentBased(TraceIdRatioBased(ratio))` — for any service participating in distributed traces; per-environment ratio (env-var-driven; do not hardcode in source); the boundary rule that tail sampling is collector-side (never implement custom tail-sampling logic in the application); the cost/coverage tradeoff principle; `OTEL_TRACES_SAMPLER` + `OTEL_TRACES_SAMPLER_ARG` env-driven configuration.

**Owner-tag mix:** mostly `(ops)` — sampler ratio is the canonical "value read from configuration at runtime" example from audit-methodology rule 21.

### 5.11 §J — SLO definition shape and burn-rate alerts (5–7 rules)

**Topical scope:** SLO three-part shape (SLI query / Objective percentage / evaluation window); MWMB 4-window pattern (page-fast / page-slow / ticket-slow / ticket-very-slow with the 14.4 / 6 / 3 / 1 burn rates from research §4.3); page-vs-ticket routing principle (page → on-call rotation; ticket → backlog); SLO must reference an existing exported metric (the orphaned-SLO defect: alert defined against a metric the application doesn't emit); recording rules for SLI computations (don't compute the SLI in alert evaluation hot path); environment-shaped alert routing (test alerts to non-paging channel).

**Owner-tag mix:** all `(ops)` — these live in alertmanager / Sloth / Pyrra / hand-written PromQL deployment manifests.

**Anti-coupling note in the skill body:** rules name the SLO *shape*, not the framework. "Generate the alerts via Sloth, Pyrra, Grafana SLO, or hand-written PromQL — pack does not opine."

### 5.12 §K — Retention policy shape (3–5 rules)

**Topical scope:** three-tier shape (hot / warm / cold) MUST be defined for logs; audit logs in a separate retention bucket from operational logs; metrics retention with downsampling (acknowledge Prometheus default 15 days local + long-term-storage tier); trace retention as the lowest-fidelity tier (acknowledge typical 10-day default); compliance-driven retention (HIPAA / PCI / SOX) overrides operational defaults.

**Owner-tag mix:** all `(ops)` — retention values live in deployment manifests.

### 5.13 Worked-example rules (calibration)

Two illustrative rules in the right-fit shape. The coder writes the full set; these establish the calibration.

**Worked example 1 — from §5.7 (F.2 label cardinality):**

> *N.* **Label values MUST come from a low-cardinality enumeration known at deploy time.** Never use `user_id`, `request_id`, `trace_id`, `session_id`, raw URL path, IP address, or any other unbounded identifier as a Prometheus label value — these belong in logs and traces, not metrics. The auditable threshold: a label whose value space exceeds ~100 distinct values across the production fleet, OR a label whose value comes from user-controlled input without enumeration, is a defect. Acceptable label values: HTTP method (`GET`/`POST`/...), status code class (`2xx`/`4xx`/`5xx`) or specific code, route template (`/users/{id}`, NOT `/users/42`), RPC service + method names, queue name, error class. `(code)`

This is calibrated:
- **Not too vague** — names a concrete defect threshold ("~100 distinct values across the production fleet") an auditor can apply, names the prohibited identifier classes by example.
- **Not too specific** — does not cite a specific `prometheus_client.Counter.labels(...)` API call that may change. Names the *concept* (label values) and the *shape* of the defect (cardinality > threshold OR user-controlled input).
- **Properly covered** — the auditor-ops or auditor-code agent reading this rule against a real Python codebase can flag `Counter("http_requests", labelnames=["user_id"])` as a defect against the rule, with an actionable fix ("move user_id to a log field; replace the label with route template + method + status class").

**Worked example 2 — from §5.11 (SLO shape):**

> *M.* **Every defined SLO MUST reference a metric the application actually exports.** An alert rule, recording rule, or SLO definition that references `http_request_duration_seconds` MUST correspond to a histogram registered in the application's metric registry and exposed at the `/metrics` endpoint (or equivalent OTLP push). The auditable defect: an SLO YAML / alertmanager rule / Sloth spec that names a metric absent from any application's metric registration. The fix is always one of (a) register and emit the metric, (b) rewrite the SLO against an existing metric, or (c) delete the orphaned SLO. `(ops)`

This is calibrated:
- **Not too vague** — names the exact defect ("references a metric the application doesn't emit"), names the auditable artifact ("SLO YAML / alertmanager rule / Sloth spec"), names the three valid fixes.
- **Not too specific** — does not cite a specific Sloth / Pyrra schema field (which would age poorly). Names the *referential integrity property* between SLO definition and metric registration — a property that survives any framework change.
- **Properly covered** — auditor-ops reading this rule against an alertmanager.yaml + the application's metric registration code can mechanically verify the cross-reference. This is the kind of orphaned-SLO defect that bites teams in production and is invisible without the rule.

### 5.14 Section count and rule count summary

11 sections (Frontmatter+Applicability + §A through §K). Rule total estimate: 5+8+3+3+4+12+4+8+4+5+3 = **59 rules**, plus or minus 5 for discovery during coder authoring. Comfortably between BD-156 (45) and BD-158 (66).


---

## §6 Anti-rule list (explicit exclusions)

The following topics are **explicitly excluded** from the v11 scope of `python-observability-patterns`. Each is named because a future contributor might reasonably ask "why isn't there a rule about X" and the answer needs to be on file.

### 6.1 Excluded — landscape volatility (per research §8.3)

- **Native histogram client API specifics.** The `prometheus_client` native-histogram API and the wire format are still stabilizing through 2025–2026 (research §6.3). A rule "use native histograms" is too forward-looking; rules naming specific native-histogram method signatures would age within months. The skill *acknowledges* native histograms as the migration target in the §F.3 metric type discussion (one sentence) but does not rule on their use.
- **`tracestate` "ot" probability key.** In active stabilization 2025–2026 per research §5.3 / §6.3. Cannot serve as a rule-able foundation today.
- **OpenTelemetry Logs SDK as the sole log path.** Technically API-stable but production migration is years out (research §6.3). Most production fleets still use stdlib + `opentelemetry-instrumentation-logging` correlation injection; ruling on full OTel-Logs migration would force premature change. Acknowledged as forward direction; not ruled.
- **eBPF auto-instrumentation (Pixie / Beyla / Coroot).** Emerging; vendor-fragmented (research §7.1). Mentioned as alternative; not ruled.

### 6.2 Excluded — out of pack scope

- **Specific SLO framework choice (Sloth vs Pyrra vs Grafana SLO vs hand-written).** Research §4.1 / §8.3 — framework choice is project-shaped (lives in deployment manifest / GitOps repo, not application code). Pack does not opine. The §J rules name the SLO *shape* (SLI / Objective / MWMB); the framework is the project's choice.
- **Specific cloud-vendor exporter configuration (X-Ray, Cloud Trace, Application Insights detail).** Research §7.2 — all three clouds support the same logical pattern (instrument with vanilla OTel, export OTLP, let collector translate). Vendor-specific Python SDKs are legacy paths. The §E rules cover the OTLP-collector-translation pattern; vendor-specific configuration belongs in vendor docs, not in a pack skill.
- **Log aggregation / search platform configuration (Splunk, Datadog Logs, Loki, ELK).** The application's job is to emit structured logs in a known format to stdout. The aggregation tier is platform-specific deployment work that doesn't generalize. §H covers what the application emits; downstream is out of scope.
- **Profiling and continuous profiling (Pyroscope, Parca).** Adjacent observability surface but distinct from the metrics / traces / logs trinity. Defer to a future BD if profiling becomes a documented pack concern.
- **Real-User Monitoring (RUM) and front-end observability.** The pack's Python observability scope is server-side. RUM lives in the UI layer (and is currently out of pack scope per the deferred non-Apple UI skills work).

### 6.3 Excluded — overlap with other skills

- **Log content classification (which keys count as "sensitive").** Owned by `security-patterns` per audit-methodology rule 33. This skill rules the redaction *pipeline shape* (a processor exists; it runs early; it is testable); the security skill rules the *content classification*. Cross-reference, do not duplicate.
- **CVE detection in observability dependencies.** Owned by `auditor-security` per audit-methodology rule 19 / 34. The §D auto-instrumentation rules say "pin contrib package versions in lock file" but do not rule on which versions or which CVEs.
- **Health check endpoints (`/healthz`, gRPC health).** Owned by `deployment-python` rules 11–14. The new skill does not duplicate health-check guidance.
- **Container resource limits and OOM behavior.** Owned by `deployment-python` rule 22. Mentioned as a metric *target* in the metrics section (memory / CPU gauges) but not ruled here.
- **gRPC interceptor placement (where logging/metrics live in the request flow).** Owned by `python-server-architecture` rule 8. New skill rules the *content* of those interceptors, not the placement.

### 6.4 Deferred — future BDs (Pack Chat triage)

Topics that may justify their own future BD if production demand surfaces. These are not opened proactively; the architect surfaces them so Pack Chat has the option:

- **`apple-observability-patterns`** — symmetrical Apple-platform observability skill (OSLog, MetricKit, Instruments integration, Combine-based telemetry). Audit-methodology rule 21's symmetric Apple example would benefit from this; today `deployment-apple` carries zero observability rules per the BD-032 audit. Open as future BD if a real Apple project surfaces a defect the pack can't catch.
- **`profiling-patterns`** — continuous profiling (Pyroscope, Parca, py-spy). Open if a project asks.
- **`web-frontend-observability-patterns`** — RUM / Sentry / OpenTelemetry browser SDK. Defer until the non-Apple UI skills cluster lands.
- **Tier 0 `observability-architecture`** — universal cross-language observability principles (signal trinity, sampling decision tradeoffs, structured-log field discipline as language-independent rules). Parallel to BD-153's deferred `concurrency-architecture`. Defer to v12+ once enough language-specific observability skills exist to factor commonality from.


---

## §7 Cross-reference design

Three skills change cross-reference text; one skill (audit-methodology) optionally adds an informational pointer. No content duplication.

### 7.1 `python-observability-patterns` → other skills (outbound from new skill)

In the Applicability section of the new skill:

> Where observability concerns are *placed* in the request flow (interceptors, middleware, app-entry-point hooks, layer boundaries) is governed by `python-server-architecture` rule 8. This skill defines the substantive *content* of those wirings — span shape, metric type, log field set.
>
> Deployment-readiness concerns adjacent to observability — Docker layout, secrets management, health checks, graceful shutdown, container resource limits, env-var-driven production config — live in `deployment-python`. The cross-reference is bidirectional: this skill rules observability content; that skill rules deployment plumbing.
>
> Sensitive-data classification ("which keys count as credentials / tokens / PII?") is owned by `security-patterns` per `audit-methodology` rule 33. This skill rules the *redaction-pipeline shape* (a processor exists; it runs early; it is testable); the security skill rules the *content classification*. Auditor-security cross-detects log-content findings and annotates them per audit-methodology rule 33.
>
> Audit-methodology rule 21's ownership rubric (`(ops)` if the fix changes a value read from configuration; `(arch)` if the fix changes a type / call graph / wiring) determines which loading agent applies which rules. Each rule below is tagged `(ops)`, `(arch)`, `(code)`, or `(both)` — the loading agent applies its tagged subset.

### 7.2 `python-server-architecture` → new skill (inbound cross-reference)

`python-server-architecture` rule 8 currently reads:

> 8. Auth, logging, and metrics belong in gRPC interceptors (or framework middleware for REST), not in servicer / handler implementations.

**Proposed extension (text the planner hands to the coder verbatim):**

> 8. Auth, logging, and metrics belong in gRPC interceptors (or framework middleware for REST), not in servicer / handler implementations. The substantive observability rules — what spans to create, which attributes to attach, which fields every log record must carry, how to wire trace ↔ log correlation — live in `python-observability-patterns` (loaded for any Python server project per the intersection table). This skill defines the *placement*; the patterns skill defines the *content*.

### 7.3 `deployment-python` → new skill (inbound cross-reference replacing rule 21)

`deployment-python` rule 21 currently reads:

> 21. Enable structured logging (JSON format) for production. Include request ID, method, status, and latency in every log entry.

**Proposed replacement (text the planner hands to the coder verbatim):**

> 21. Substantive observability rules — structured-log field set, metrics naming and cardinality, tracing setup, sampling, SLO definition shape, retention policy shape — live in `python-observability-patterns`. This skill (`deployment-python`) covers deployment-readiness concerns adjacent to observability: container layout, secrets, health checks, graceful shutdown, env-driven production config. Auditor-ops loads both skills for D2=python ∩ D5=linux-container projects.

(Rule numbering stays the same — rule 21 keeps its number, just changes content. Rules 22–23 stay where they are.)

### 7.4 `audit-methodology` rule 21 (no required change; optional informational pointer)

The current rule 21 boundary clarification names a clean ownership test. It does not need to know about specific platform skills. Optional sentence to append in a separate cleanup BD (NOT this BD):

> "For D2=python projects, the loaded skill that carries the substantive observability rules each cluster applies is `python-observability-patterns`. For D1 ∈ {ios, macos} projects, the equivalent Apple-platform skill is deferred (see future BD)."

This is informational only — the loading mechanism doesn't depend on it. Out of scope for BD-162; flag for Pack Chat as a possible follow-up cleanup.

### 7.5 `audit-methodology` rule 32 (auditor-ops file scope) — no change required

Rule 32's file scope already covers the deployment manifests and config files that auditor-ops examines. The new skill's `(ops)`-tagged rules apply within that existing scope — no scope expansion needed.


---

## §8 Maintenance properties

### 8.1 Mechanical vs structural classification

**Verdict: structural — and therefore correctly routed through the architect-pass pipeline (researcher → architect → planner → coder) per BD-159 maintainability principle.**

Per `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.1 / §3.2 thresholds:

| Signal | Status |
|---|---|
| §3.1 cond. 1 — Trinity scope | YES (uniform — trinity replication is mechanical at install time) |
| §3.1 cond. 2 — Existing dimension fit | YES (composes D2=python ∩ D3=server with a marker; no new dimension) |
| §3.1 cond. 3 — Existing pattern fit | YES (`*-patterns` standalone skill, parallel to BD-156 / BD-158) |
| §3.1 cond. 4 — Existing naming convention fit | YES (`*-patterns` suffix, codified per BD-149) |
| §3.1 cond. 5 — Existing validator coverage | PARTIAL — Check 31 (BD-146 skill-cell consistency) covers the new row; new marker helper does not require a new validator check; no new `check_*` function added |
| §3.1 cond. 6 — Bounded file footprint | **NO** — see §8.2 below; touches **9 files** including 1 NEW skill dir, exceeds the 3-new-file mechanical bound although stays within the 10-edited-file mechanical bound |
| §3.1 cond. 7 — No agent-permission expansion | YES (no new entries in any forbidden list) |

§3.2 structural signals also check:
- §3.2 sig. 5 — New top-level doc: NO new top-level pack-product doc (the architect / planner / coder workflow artifacts under `maintenance-docs/v11-implementation/` are exempted per §3.2 sig. 5 carve-out: "ARCHITECTURE-*.md / PLAN-*.md / IMPLEMENTATION-REPORT-*.md / PACK-REVIEW-*.md / AUDIT-*.md / RESEARCH-*.md / *-DISCOVERY.md produced by the existing... workflow" — applies to this very document, the upstream RESEARCH-*.md, the downstream PLAN-*.md, and the eventual IMPLEMENTATION-REPORT-*.md / PACK-REVIEW-*.md).
- §3.2 sig. 6 — New script: NO (no top-level script change; only a helper extension to `scripts/lib/detect.sh`).
- All other §3.2 signals: NO.

**Disposition.** §3.1 condition 6 is exceeded (footprint-wise) and §3.1 condition 5 is satisfied only because Check 31 already exists. The change is structural by file-footprint, but cleanly so — it follows the BD-156 / BD-158 / BD-141 pattern exactly. The principle's §3.3 ("borderline cases — the architect-pass gate") covers this: "Adding a new intersection-table row — mechanical IF the predicate composes existing dimension selectors (BD-156 / BD-157 example); structural IF the predicate introduces a new selector primitive." Here the predicate `D2=python ∩ (D3=server ∨ marker)` composes existing primitives — but the *content authoring* (~60 rules) is substantial structural change. **Architect-pass-then-planner-pass is the correct routing**, exactly as BD-162's BACKLOG entry specified, and exactly as BD-156 / BD-157 / BD-158 were routed before it.

### 8.2 File-count footprint

Files the planner + coder will create or edit (exhaustive):

**NEW (3 entries, all in one new directory):**
1. `project-template/skills/python-observability-patterns/SKILL.md` (the substantive content; ~350–420 lines, ~60 rules)
2. `maintenance-docs/v11-implementation/PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY.md` (planner stage 3 output; workflow-artifact carve-out per §3.2 sig. 5)
3. `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-DEPLOYMENT-PYTHON-OBSERVABILITY.md` (coder stage 4 output; workflow-artifact carve-out)

**EDITED (8 files):**
4. `project-template/skills/deployment-python/SKILL.md` — replace rule 21 with cross-reference per §7.3.
5. `project-template/skills/python-server-architecture/SKILL.md` — extend rule 8 with cross-reference per §7.2.
6. `project-template/docs/pack/PLATFORM-SKILLS.md` — add new intersection-table row (§4.4 cell 1); add new dimensional-skill-table row + count bump 19→20 (§4.4 cell 2); add new skill to two worked examples (§4.4 cell 3); add new skill to per-agent assignments for architect / coder / reviewer / auditor-architecture / auditor-code / auditor-ops / docs-researcher (§4.4 cell 4).
7. `scripts/lib/detect.sh` — add `python_observability_marker_detected()` helper paralleling `python_data_marker_detected()` and `swiftdata_marker_detected()`.
8. `scripts/init-project.sh` — extend `pack_skill_coverage_for()` Python case to include `python-observability-patterns` when the marker fires or D3=server is selected.
9. `scripts/add-capability.sh` — extend `capability_skills` mapping for the relevant Python capability rows.
10. `scripts/test-detect.sh` — add test coverage for the new marker helper (positive + negative cases).
11. `BACKLOG.md` — flip BD-162 status to Resolved with batch-completion note (final post-coder step; PM Chat does this, not the coder).

**Total: 3 NEW + 8 EDITED = 11 file paths touched.**

Per §3.1 cond. 6 thresholds:
- 0–3 NEW pack-product files mechanical; this BD is 1 NEW pack-product file (the SKILL.md) — within bound.
- 0–10 EDITED files mechanical; this BD is 8 EDITED — within bound.
- 0 NEW top-level docs in pack-product or pack-ops scope — this BD has 0 in either (the 3 NEW workflow artifacts are in `maintenance-docs/v11-implementation/` and exempted).
- 0 NEW scripts; 0 NEW validate-pack.py checks — both satisfied.

The footprint is honest: 11 paths total, 1 substantive new pack-product file, parallel structure to BD-156 / BD-157 / BD-158 in shape. **Sits at the architect-pass-required threshold by content scope, not by file count.**

### 8.3 Trinity discipline (no trinity files in scope)

This BD touches NO trinity files (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` at pack-repo root or project-template root). The new skill ships at the single canonical path `project-template/skills/python-observability-patterns/SKILL.md`; per-CLI fan-out happens at install time. No trinity edits required, no parallel-edit discipline required.

### 8.4 Migration consideration

**Cross-reference to BD-161 — required.** BD-161 (open) extends the v10→v11 migrator to install net-new v11 SKILL.md directories. Today the migrator does NOT install the BD-156 / BD-157 / BD-158 skills automatically; clients migrating from v10 retain their v10 skill inventory and the new v11 skills are silently absent.

**`python-observability-patterns` adds to that backlog of net-new v11 skills.** When BD-161 lands, it must enumerate `python-observability-patterns` alongside `protobuf-patterns`, `apple-swiftdata-patterns`, `swift-concurrency-patterns`, `python-server-architecture` (post-split), and `python-data-architecture` (post-split). The implementation guidance in BD-161's File/Symbol field already says "enumerates skills from `project-template/skills/<name>/` against what's currently installed in the target's `<cli>/skills/` trees" — this is enumeration-driven, so any new skill ships through automatically. The BD-162 coder does not need to edit BD-161; the BD-161 implementation will pick up `python-observability-patterns` mechanically by enumeration.

**Action item for the planner.** Note in PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY.md that BD-161 must be aware of this skill (the BD-161 BACKLOG entry already describes enumeration-driven discovery, so no edit is strictly required — but the planner should verify BD-161's test cases include `python-observability-patterns` once both BDs land).

**Persona-contract update.** Per BD-161's File/Symbol field, `scripts/persona-contracts/contract-migration.sh` will gain a post-migration v11 skill-inventory parity assertion. Once that lands, `python-observability-patterns` is automatically covered by the enumeration assertion.

**No standalone migrator stage required.** The skill ships at the canonical path; install time fans out to all three CLI trees; existing migrator framework (BD-119) handles the rest once BD-161 closes the install gap.

### 8.5 Future-extension architecture (single-skill v11; sibling-extraction-ready)

**v11 ships one skill: `python-observability-patterns`.** This subsection captures the design discipline that keeps the skill *extensible* into tool-specific siblings later, without rework, if real demand surfaces. No future siblings are scoped here; the v11 single-skill design stands.

**Candidate future sibling skills.** Natural splits that the §A–§K section structure was deliberately chosen to support:

- **`python-otel-patterns`** — OpenTelemetry-specific tracing / propagation / instrumentation / exporter / sampling rules. Lifts §A (SDK setup) + §B (span lifecycle) + §C (propagation) + §D (auto-instrumentation) + §E (exporters) + §I (sampling).
- **`python-prometheus-patterns`** — Prometheus-specific metric naming / cardinality / type selection / multiprocess / exposition / SLO rules. Lifts §F (metrics) + §G (exposition) + the Prometheus-specific portion of §J (SLO shape — recording rules, alertmanager routing, MWMB pattern).
- **`python-structlog-patterns`** — only opens if `structlog`-specific patterns dominate (custom processor pipelines, bound-context discipline at structlog's API level). If §H stays library-agnostic-field-set-dominant (the current ADP-1 calibration), §H stays in the foundation indefinitely. Decision deferred to first real demand signal.

**Sibling loading model — siblings ADD to the foundation; no replacement, no hierarchy.** Each future sibling binds to `D2=python ∩ <tool-specific-marker>` (e.g., `python_otel_marker_detected()` checking for `opentelemetry-api` in deps; `python_prometheus_marker_detected()` checking for `prometheus_client`). When a sibling predicate fires, it co-loads with `python-observability-patterns` — both skills load together. Cross-references in the sibling rule bodies handle composition ("foundation rule N covers the field-set; this rule extends it for OTel-specific span attributes"). No hierarchy means the foundation is never "downgraded" to a base class; it remains a complete standalone skill.

**Cross-cutting rules that stay in the foundation as integration glue (NEVER lift out):**

- **Trace ↔ log correlation (§H subset).** Spans the OTel side AND the logging side; lives in foundation forever because it bridges two tools.
- **Redaction-pipeline shape (§H subset).** Cross-cutting between logging-library choice and `auditor-security` rule 33 boundary; library-agnostic by ADP-1 design.
- **Audit-methodology rule 21 ownership rubric and the per-rule `(ops)` / `(arch)` / `(code)` / `(both)` tagging convention.** Documented in the foundation's Applicability section; all siblings inherit and apply the same convention. Moving it would force every sibling to redocument the rubric — a duplication tax the principle (BD-159) explicitly forbids.
- **Per-environment configuration shape rules (§H stdout-for-cloud, `LOG_LEVEL` / `LOG_FORMAT` env-var-driven).** Library-agnostic environmental discipline; integration glue.
- **The retention-policy shape rules (§K).** Vendor-agnostic and signal-agnostic; lives in foundation.

**Implication for rule authoring in BD-162's coder stage.** The coder writes rules in a way that does NOT entangle tool-specific content across sections. Concretely:

- A Prometheus-specific rule belongs in §F or §G — never in §A (SDK setup) or §I (sampling). If the coder finds themselves writing "the Prometheus exposition endpoint must..." inside §A, that is a section-placement defect.
- An OpenTelemetry-specific rule belongs in §A–§E or §I — never inside §F (metrics naming) or §G (exposition). If the coder writes "the OTLP exporter must..." inside §G, that is a section-placement defect.
- A `structlog`-specific rule (if any survive ADP-1's library-agnostic preference) belongs only inside the §H subsection that explicitly addresses library-specific patterns. Generic field-set rules stay library-agnostic.
- Every rule belongs cleanly to ONE section. Multi-section rules indicate the rule is doing too much and should be split.

**Result.** When a future BD opens a sibling skill (e.g., `python-otel-patterns`), the lift-out is a mechanical sed-pattern extraction of §A + §B + §C + §D + §E + §I rules into the new sibling, plus cross-reference edits in the foundation pointing at the sibling. No content rewrite. No re-classification audit. No defect surface. The §A–§K section structure is the seam along which a future split is mechanical rather than structural.



---

## §9 Hand-off to planner

### 9.1 Locked decisions (do not re-litigate)

- **Skill placement.** New skill `python-observability-patterns` at single canonical path `project-template/skills/python-observability-patterns/SKILL.md`. ADP-2 = (C). Final.
- **Loading semantics.** Intersection-cell with predicate `D2=python ∩ (D3=server ∨ python_observability_marker_detected())`. New marker helper in `scripts/lib/detect.sh`. Final.
- **Scope envelope.** Comprehensive (~55–65 rules across 11 sections). Final.
- **Library citation policy.** OpenTelemetry as canonical for tracing; library-agnostic for metrics + logging; rule the *shape* not specific method signatures. Final.
- **Cross-reference text.** Verbatim text for `python-server-architecture` rule 8 extension and `deployment-python` rule 21 replacement is in §7.2 / §7.3 — coder uses this verbatim, no rewriting.
- **Boundary handling for the audit-methodology rule 21 ownership rubric.** In-skill-body per-rule `(ops)` / `(arch)` / `(code)` / `(both)` tagging per §2.2. Final.
- **Anti-rule list.** §6 is final — coder does not author rules on excluded topics. If the coder discovers an exclusion is wrong, they SendMessage the architect, not unilaterally add rules.

### 9.2 Open decisions (planner sequences)

- **Section ordering within the skill.** §5 lists §A–§K in a logical order (SDK setup → spans → propagation → instrumentation → exporters → metrics → exposition → logging → sampling → SLO → retention) but the planner may reorder for editorial flow. The coder should not invent new ordering on the fly.
- **Per-section batch decomposition.** §9.3 below proposes a single-commit batch but flags the alternative.
- **Worked-example rule numbering vs final numbering.** §5.13's two worked-example rules are illustrative; their final rule numbers in the SKILL.md depend on the section count and ordering. The planner sets final numbering scheme.
- **Validate-pack discovery.** Confirm Check 31 (BD-146 skill-cell consistency) actually validates the new intersection row; if not, the planner flags it to the architect (could be a structural surprise).

### 9.3 Suggested batch decomposition

**Recommendation: one commit (one batch).** Parallel to BD-156 (commit 0a7f...) and BD-158 (commit 8c117cf), which each shipped their `*-patterns` skill + cross-references + scripts + PLATFORM-SKILLS.md updates as a single coherent batch.

The 11 file paths form one coherent change — splitting them risks landing the new skill without its install wiring (a half-installed skill that doesn't load) or with its install wiring but no content (a load that finds an empty file). The batch is large but cohesive.

**Alternative: two-commit decomposition** if the planner judges the batch unwieldy:
1. Commit 1: NEW skill SKILL.md + cross-reference edits to `deployment-python` and `python-server-architecture` (content only).
2. Commit 2: PLATFORM-SKILLS.md updates + scripts changes (`detect.sh`, `init-project.sh`, `add-capability.sh`, `test-detect.sh`) + tests.

The architect's preference is single-commit (matches BD-156 / BD-158 precedent and the BD-159 mechanical-batch shape). If the planner picks two-commit, ensure both commits land in the same session so the skill is never half-installed in main.

### 9.4 Review and fix discipline (per CLAUDE.md pack memory)

- One review/fix cycle per batch. Pack-reviewer runs once after the coder lands; one fix-pass; flip BDs to Resolved.
- Post-batch validate-pack must pass 30/30; test-detect must include the new marker test cases (positive: project with `import opentelemetry`; positive: project with `prometheus_client` in deps; negative: pure Apple project; negative: Python script without observability deps and without D3=server).
- The coder writes the rules; the reviewer verifies the right-fit calibration via spot-check (sample 10 random rules; flag any that violate the not-too-vague / not-too-specific calibration).

### 9.5 What the architect remains alive to clarify

Pack Chat or the planner may SendMessage with questions on:

- The owner-tag scheme (`(ops)` / `(arch)` / `(code)` / `(both)`) — exact placement at end-of-rule vs start-of-rule, capitalization, whether `(both)` is necessary or whether `(ops, arch)` is clearer.
- The boundary between §F.3 (metric type selection) and §G (exposition / multiprocess) — could merge into a single Prometheus section if the planner judges them too small to stand alone.
- The §I (sampling) / §J (SLO) / §K (retention) sub-sections' rule counts — these are the smallest sections and the planner may judge they read better merged or split differently.
- Cross-reference text in §7.2 / §7.3 — the architect's exact wording is non-binding; the planner may polish for editorial flow as long as the substance (which skill rules what) is preserved.

The architect remains alive (sub-agent context not torn down) until Pack Chat ends the BD-162 stage 2 review. The docs-researcher (`aba8ef1124ab310ce`) is also alive and reachable via SendMessage if a research point needs deepening during planning or coding.

---

**End of architecture report.** Planner proceeds in stage 3.
