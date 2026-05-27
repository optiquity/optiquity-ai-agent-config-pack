---
name: python-observability-patterns
description: Use for Python observability — OpenTelemetry tracing setup, span lifecycle, trace context propagation, auto-instrumentation, exporter configuration; Prometheus metrics naming / cardinality / type selection / multiprocess exposition; structured logging field requirements + trace-log correlation; head sampling; SLO definition shape and burn-rate alerts; retention-policy shape. Loads at D2=python ∩ (D3=server ∨ observability-marker).
allowed-tools: Read, Grep, Glob, Bash
---

## Applicability

This skill is loaded for `architect`, `coder`, `reviewer`,
`auditor-architecture`, `auditor-code`, `auditor-ops`, and
`docs-researcher` whenever the project's intersection cell is
`D2=python ∩ (D3=server ∨ python_observability_marker_detected())`.
The `D3=server` branch covers the dominant case (any Python gRPC /
FastAPI / Django / Flask server). The marker branch handles the
secondary case where observability is wired into a Python process
that isn't a request-serving server (e.g., a Python data pipeline
or worker that emits its own metrics / traces). The marker check
is the canonical predicate
`scripts/lib/detect.sh::python_observability_marker_detected()`
(see `docs/pack/PLATFORM-SKILLS.md` Intersection table).

The rules cover the observability signal trinity (traces, metrics,
logs) plus sampling, SLO shape, and retention shape — the five
sub-domains named by `audit-methodology` rule 21.

**Canonical library positions** (per architecture decision §3.1):

- **Tracing**: OpenTelemetry (`opentelemetry-api` /
  `opentelemetry-sdk`) is the single canonical choice. OpenTracing
  and Jaeger native client-libraries are deprecated.
- **Auto-instrumentation**: the `opentelemetry-distro` +
  `opentelemetry-bootstrap` + `opentelemetry-instrument` workflow
  is the canonical zero-code path.
- **Exporters**: OTLP gRPC default; OTLP HTTP fallback. Vendor
  exporters acknowledged as legacy paths.
- **Metrics**: `prometheus_client` is dominant for Python today;
  OpenTelemetry metrics → OTLP → Prometheus translation is a
  working alternative path. Rules name the *concept* (counter
  ends in `_total`, histogram buckets must straddle the SLO
  threshold) and apply to either path.
- **Structured logging**: library-agnostic field set. `structlog`
  recommended for new code; `python-json-logger` over stdlib as
  the universal floor; loguru acknowledged but lacks native OTel
  integration today.
- **Trace ↔ log correlation**:
  `opentelemetry-instrumentation-logging` with
  `OTEL_PYTHON_LOG_CORRELATION=true`. The OTel Logs SDK is named
  as forward direction; not the rule-able foundation today.

**Cross-references to other skills** (per architecture §7.1):

Where observability concerns are *placed* in the request flow
(interceptors, middleware, app-entry-point hooks, layer
boundaries) is governed by `python-server-architecture` rule 8.
This skill defines the substantive *content* of those wirings —
span shape, metric type, log field set.

Deployment-readiness concerns adjacent to observability — Docker
layout, secrets management, health checks, graceful shutdown,
container resource limits, env-var-driven production config —
live in `deployment-python`. The cross-reference is bidirectional:
this skill rules observability content; that skill rules
deployment plumbing.

Sensitive-data classification ("which keys count as credentials /
tokens / PII?") is owned by `security-patterns` per
`audit-methodology` rule 33. This skill rules the
*redaction-pipeline shape* (a processor exists; it runs early; it
is testable); the security skill rules the *content
classification*. Auditor-security cross-detects log-content
findings and annotates them per audit-methodology rule 33.

Audit-methodology rule 21's ownership rubric (`(ops)` if the fix
changes a value read from configuration; `(arch)` if the fix
changes a type / call graph / wiring) determines which loading
agent applies which rules. Each rule below is tagged `(ops)`,
`(arch)`, `(code)`, or `(both)` — the loading agent applies its
tagged subset.

## §A — Telemetry SDK setup and resource attributes

1. Initialize the OpenTelemetry SDK exactly once, at process entry
   (before any business logic runs). Late or repeated initialization
   produces traces with missing or mixed `Resource` attributes that
   are ambiguous to downstream backends. The auditable defect: an
   `import opentelemetry` followed by tracer / meter creation in a
   request handler module without a verified one-shot init at
   process start. `(arch)`
2. Construct the `Resource` once at SDK init and share it across
   the tracer, meter, and logger providers. A divergent `Resource`
   between signals (e.g., `service.name` only on tracer) prevents
   joining traces / metrics / logs by service in the backend. `(arch)`
3. Set `service.name` on every deployed service. The value MUST
   uniquely identify the service across the fleet — never `"app"`,
   `"server"`, `"python"`, or any default placeholder. `(both)`
4. Set `service.version` (release tag or git SHA),
   `service.instance.id` (per-process unique value, typically the
   container ID or hostname:port), and `deployment.environment`
   (`dev` / `staging` / `prod` — match the deployment manifest's
   environment value exactly). Missing any of the three breaks
   common backend slicing. `(both)`
5. Drive resource attributes from environment variables
   (`OTEL_SERVICE_NAME`, `OTEL_RESOURCE_ATTRIBUTES`) rather than
   hardcoding in source. Hardcoded resource attributes leak across
   environments when the same image is promoted dev → staging →
   prod. `(ops)`
6. Pin the OpenTelemetry semantic-convention package version in
   the lock file. Semconv attribute keys (e.g., `http.request.method`
   vs the older `http.method`) revise across versions and a silent
   upgrade can break backend dashboards / alerts that key on the
   prior attribute names. `(ops)`

## §B — Span lifecycle and attributes

7. Use `tracer.start_as_current_span("name")` (context manager
   form) for any span whose lifetime is bounded by a code block.
   Manual `start_span` + `end()` invites missing-end defects when
   exception paths bypass the explicit close — leaked spans stay
   open in memory until the process exits. `(code)`
8. Span names are low-cardinality identifiers — verb + resource
   shape (e.g., `GET /users/{id}`, `Repo.findById`, `kafka.publish
   payments`). Never embed user-controlled values, request IDs,
   trace IDs, or rendered URL paths in the span name; those go on
   attributes. High-cardinality span names defeat backend
   aggregation and inflate index storage. `(code)`
9. Set span status only on confirmed domain outcomes. Leave the
   default `UNSET` for in-progress / inconclusive paths; set
   `StatusCode.OK` only when the operation's domain success is
   confirmed; set `StatusCode.ERROR` with a brief description on
   failure. Setting `OK` on every successful return value is
   redundant noise that defeats the `UNSET`-vs-`OK` distinction
   downstream tooling relies on. `(code)`
10. Record exceptions via `span.record_exception(exc)` AND set
    span status to `ERROR` in the same except clause. Recording
    without setting status leaves the span as `UNSET` — the trace
    backend sees the exception event but classifies the span as
    successful. `(code)`
11. Use semantic-convention attribute namespaces (`http.*`,
    `rpc.*`, `db.*`, `messaging.*`) rather than ad-hoc names. The
    *shape* — lowercase dotted, low-cardinality on the value side —
    is durable; specific attribute keys may revise across semconv
    versions but the namespace pattern is stable. Custom domain
    attributes go under a service-specific prefix
    (e.g., `myorg.order.id`), never bare. `(arch)`
12. Use `http.route` (the route template — `/users/{id}`) on
    server spans, never the rendered URL path (`/users/42`). The
    rendered path is high-cardinality and explodes the span-name
    space; route templates are bounded by the application's route
    table. `(code)`
13. Span attribute *values* must be bounded in cardinality under
    production load. Free-text user input, raw URL paths, and
    arbitrary IDs as attribute values inflate index storage and
    can exceed backend per-span attribute limits. Reserve those
    for log fields, where high cardinality is acceptable. `(ops)`
14. Use span links (`trace.Link(span_context)`) to model
    fan-out / fan-in patterns where a child operation is causally
    related to multiple parent operations (e.g., a batch job
    triggered by N enqueue operations). Linking is the correct
    primitive — never overload `parent_span_id` for non-tree
    relationships. `(arch)`

## §C — Trace context propagation

15. Use the W3C TraceContext + Baggage propagator pair as the
    default. Set programmatically via `set_global_textmap(...)` at
    SDK init or via `OTEL_PROPAGATORS=tracecontext,baggage` env.
    Vendor-specific propagators (B3, Jaeger, X-Ray-headers) load
    only as opt-in for fleet interop with non-OTel services. `(arch)`
16. Configure propagators via `OTEL_PROPAGATORS` env when the
    deployment must add interop (`tracecontext,baggage,b3multi`).
    Programmatic-only configuration forces a code change for an
    interop-tier shift. `(ops)`
17. Verify auto-instrumentation hooks the inbound and outbound
    transport propagation (gRPC + HTTP) by default — no manual
    propagator wiring should be required in handler code. Manual
    `inject` / `extract` calls in request handlers are a code
    smell indicating the auto-instrumentation contrib package for
    that transport is missing or misconfigured. `(arch)`

## §D — Auto-instrumentation discipline

18. Use the `opentelemetry-distro` + `opentelemetry-bootstrap` +
    `opentelemetry-instrument` workflow as the canonical zero-code
    path. The distro brings sensible defaults, bootstrap installs
    the contrib packages matching the project's installed
    dependencies, and the wrapper launches the application with
    auto-instrumentation hooks active. `(ops)`
19. Auto-instrument inbound + outbound HTTP, DB, RPC, and
    messaging at minimum. Pick contrib packages by the project's
    actual transport / driver dependencies — the bootstrap step
    enumerates installed packages and installs matching contrib
    packages automatically. `(ops)`
20. Manually instrument only domain-significant operations
    (business-logic boundaries, batch-job stages, cache
    populations). Do NOT duplicate auto-coverage with manual
    spans — duplicated spans inflate trace volume, fragment span
    timings, and obscure the call hierarchy. The auditable defect:
    a manual `with tracer.start_as_current_span("http_request")`
    inside an HTTP handler whose framework already has
    auto-instrumentation. `(code)`
21. Pin the version of every `opentelemetry-instrumentation-*`
    contrib package in the lock file. Contrib packages release
    on a faster cadence than the SDK, and a silent minor upgrade
    has historically introduced breaking changes to attribute
    naming. `(ops)`

## §E — Exporter configuration

22. Use OTLP gRPC as the default exporter for in-cluster traffic
    between the application and the observability backend (or the
    local OpenTelemetry Collector). Use OTLP HTTP only when
    egress restrictions or backend support force it. `(ops)`
23. Place an OpenTelemetry Collector tier between the application
    and the vendor backend. Direct application-to-vendor exports
    couple the application's runtime to vendor-SDK behavior
    (retry, batching, schema translation) and prevent fleet-wide
    sampling / filtering policy changes without an application
    redeploy. `(arch)`
24. Configure exporter endpoint via `OTEL_EXPORTER_OTLP_ENDPOINT`
    (and signal-specific overrides:
    `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT`,
    `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT`,
    `OTEL_EXPORTER_OTLP_LOGS_ENDPOINT`) — never hardcode the
    endpoint in source. The auditable defect: a `OTLPSpanExporter
    (endpoint="https://...")` literal in application code rather
    than an env-driven default. `(ops)`
25. Set explicit batch processor queue limits and export timeouts
    (`OTEL_BSP_MAX_QUEUE_SIZE`, `OTEL_BSP_EXPORT_TIMEOUT`). Default
    queue sizes can OOM under load spikes; missing timeouts let a
    stalled exporter back-pressure the application's request
    path. `(ops)`
26. New code uses OTLP + collector translation. Vendor-specific
    Python SDKs (X-Ray, Cloud Trace, Application Insights direct
    SDKs) are legacy paths only — do not introduce them in new
    services. The OpenTelemetry Collector translates OTLP into
    every supported vendor format. `(arch)`

## §F — Prometheus metrics: naming, labels, types

### F.1 — Metric naming

27. Counter metrics MUST end in the `_total` suffix
    (e.g., `http_requests_total`, `tasks_processed_total`).
    Prometheus query semantics rely on the suffix to distinguish
    monotonically-increasing counters from gauges; a counter
    without `_total` reads correctly with `rate()` only by
    accident and will confuse downstream alerting and
    dashboards. `(code)`
28. Use base SI units in metric names: `_seconds` for durations
    (never `_ms`, `_us`, `_ns`), `_bytes` for sizes (never `_kb`,
    `_mb`). Mixed-unit metrics across services break aggregate
    queries and recording rules that assume a uniform unit
    family. `(code)`
29. Each metric measures one thing. Do not encode multiple
    measurements via labels (e.g., a single `http_requests` metric
    with a `metric_type` label switching between count / latency /
    error rate). One metric per thing keeps the query language
    natural and avoids label-cardinality explosion via the
    encoding axis. `(arch)`
30. Use a namespace / subsystem prefix that identifies the
    application or subsystem (e.g., `myorg_billing_invoices_total`,
    `mysvc_grpc_requests_total`). Bare metric names
    (`requests_total`) collide across services in the global
    Prometheus namespace. The `_count` suffix is reserved for
    histogram counts — never use it as a generic metric suffix. `(arch)`

### F.2 — Label cardinality

31. **Label values MUST come from a low-cardinality enumeration known at deploy time.** Never use `user_id`, `request_id`, `trace_id`, `session_id`, raw URL path, IP address, or any other unbounded identifier as a Prometheus label value — these belong in logs and traces, not metrics. The auditable threshold: a label whose value space exceeds ~100 distinct values across the production fleet, OR a label whose value comes from user-controlled input without enumeration, is a defect. Acceptable label values: HTTP method (`GET`/`POST`/...), status code class (`2xx`/`4xx`/`5xx`) or specific code, route template (`/users/{id}`, NOT `/users/42`), RPC service + method names, queue name, error class. `(code)`
32. Label HTTP / RPC requests by route template + method + status
    class (or specific status code), never by rendered URL or raw
    path. The route template is bounded by the application's
    route table; the rendered path is unbounded. `(code)`
33. PII MUST NOT appear in label values under any circumstance.
    Email addresses, names, account numbers, IP addresses
    (depending on jurisdiction), and any field classified as
    sensitive by `security-patterns` are forbidden as label
    values regardless of cardinality. The redaction concern is
    secondary to the cardinality concern — even a low-cardinality
    PII label is a defect. `(both)`
34. The 10k-series-per-metric soft cap is the auditor threshold.
    If a single metric (any combination of label values across
    its label set) exceeds ~10,000 active series across the
    production fleet, the labeling is too high-cardinality and
    must be revisited. Backend storage / query cost grows with
    series count, not metric count. `(ops)`

### F.3 — Metric type selection

35. Counter for monotonically-increasing values that reset only
    on process restart (request counts, bytes processed, errors).
    Gauge for instantaneously-sampled values (queue depth,
    in-flight requests, memory usage). Histogram for distributions
    of observations (request latency, response size). Summary is
    deprecated for distributed deployments — its quantiles are
    not aggregatable across instances. `(code)`
36. Do NOT use `Summary` in distributed deployments. Summary
    quantiles are computed per-instance and cannot be aggregated
    across pods / processes — a fleet-wide P99 from per-instance
    Summaries is mathematically meaningless. Use Histogram and
    aggregate quantiles via `histogram_quantile()` at query
    time. `(code)`
37. Histogram bucket selection is service-specific. The default
    bucket set
    (`.005, .01, .025, .05, .1, .25, .5, 1, 2.5, 5, 10`) is
    appropriate for general HTTP latency in seconds; latency
    distributions outside this range (sub-millisecond batch
    operations, multi-minute background jobs) require custom
    buckets matching the operation's expected percentile range.
    Native histograms are acknowledged as the forward direction
    once the wire format and client API stabilize. `(ops)`
38. The SLO threshold MUST be an exact bucket boundary on the
    SLI histogram. If the SLO is "P95 latency < 250ms," a
    histogram bucket at exactly `0.25` seconds is required —
    `histogram_quantile(0.95, ...)` interpolates linearly within
    a bucket and an off-by-one bucket boundary produces
    quantile estimates that drift relative to the SLO threshold,
    invalidating burn-rate calculations. `(both)`

## §G — Prometheus exposition: multiprocess and endpoint

39. Multiprocess mode is required when the deployment uses a
    fork-model server (Gunicorn sync workers, uWSGI workers,
    Apache mod_wsgi). In a fork model the parent's
    `prometheus_client` registry is duplicated per worker on
    fork, and per-worker counters do not aggregate to a fleet
    total without the multiprocess collector. `(both)`
40. When multiprocess mode is enabled, set
    `PROMETHEUS_MULTIPROC_DIR` to a writable directory, wipe
    the directory contents at process start (stale per-worker
    files from prior runs corrupt the collector's view), and
    register `MultiProcessCollector(registry)` at `/metrics`. The
    auditable defect: a Gunicorn deployment with multiple sync
    workers and no `PROMETHEUS_MULTIPROC_DIR` set — fleet
    metrics will be missing N-1 workers' worth of counts. `(ops)`
41. Per-gauge multiprocess mode selection MUST be deliberate,
    not default. The auditable defect: a `Gauge` declared in
    fork-model deployment without an explicit `multiprocess_mode=`
    keyword argument — the framework default semantics rarely
    match the intended aggregation, and worker restart will
    silently double-count or drop values. Pick the mode that
    matches the metric's semantics: instantaneous fleet sum
    (e.g., `livesum` in `prometheus_client`), aggregate across
    all worker generations including dead, or per-worker
    last-seen. The specific mode-string vocabulary is
    library-governed; the requirement to choose deliberately
    is durable. `(both)`
42. Expose `/metrics` as an unauthenticated endpoint on the
    scrape network (or behind scrape-credential auth at the
    scraper tier — Prometheus / VictoriaMetrics / OpenMetrics
    scrapers all support basic-auth headers). Exclude `/metrics`
    from request instrumentation (the metrics endpoint serving
    its own metrics inflates the metrics it serves). The endpoint
    MUST be reachable from the scraper network and MUST return a
    body Prometheus can parse (no body wrappers, no JSON
    envelopes). `(both)`

## §H — Structured logging: required fields and trace correlation

43. Every log record MUST carry the following fields:
    `timestamp` (with timezone, ISO 8601 or RFC 3339), `level`
    (uppercase string per stdlib level names), `service.name`
    (matching the OTel resource attribute),
    `service.instance.id`, `trace_id` and `span_id` (from the
    current OTel span context — empty when no span is active),
    `request_id` (correlation ID propagated through the request
    lifecycle), `event` (a low-cardinality event name) as a
    field separate from `message` (free-text human-readable
    body). Missing any field defeats backend slicing and
    aggregation. `(both)`
44. Field names follow a single project-wide convention
    (snake_case is the default). Mixed conventions
    (`requestId` in some records, `request_id` in others)
    fragment backend queries. `(code)`
45. Log records on error paths MUST include
    `exception.type` (fully-qualified class), `exception.message`
    (one-line summary), and `exception.stacktrace` (multi-line
    formatted stack). Logging only the message body or relying on
    the logging framework's default exception formatter loses
    structured access in the backend. `(code)`
46. Library-agnostic field requirements: the rules above describe
    the *fields*, not specific library APIs. Whether emitted via
    `structlog.get_logger().info(event=...)`,
    `python-json-logger`-formatted stdlib `logging`, or an
    in-house JSON formatter, the field set is uniform. The
    auditor checks the on-the-wire JSON record, not the
    library-specific configuration. `(arch)`
47. Wire trace ↔ log correlation by enabling
    `OTEL_PYTHON_LOG_CORRELATION=true` (env-driven) or by
    instantiating `LoggingInstrumentor().instrument()` at process
    entry. The instrumentor injects `otelTraceID` and
    `otelSpanID` into every log record's extra fields,
    enabling the backend to pivot trace → log → trace. The
    auditable defect: structured logs without `trace_id` /
    `span_id` populated even though OTel tracing is active in
    the same process. `(arch)`
48. Per-environment log level is env-driven (`LOG_LEVEL=INFO` in
    prod, `DEBUG` in dev). Log format is also env-driven
    (`LOG_FORMAT=json` in prod, `text` in dev) so the same
    image runs everywhere. Hardcoded `logging.basicConfig
    (level=logging.DEBUG)` at module-import time is a defect —
    it locks the level regardless of environment. `(ops)`
49. Cloud-deployed services log to stdout (or stderr for
    errors), never to local files. The container runtime collects
    stdout / stderr and ships to the log aggregation tier; file
    destinations require additional log-shipper configuration,
    fill the container's writable layer, and are lost when the
    container exits. `(both)`
50. Define a redaction processor / filter early in the logging
    pipeline (the first transformer in the structlog processor
    chain, or the first filter in the stdlib logging
    configuration). Never bind authentication headers, session
    tokens, or secret material into thread-local / contextvar
    state used by structured loggers — bound context fields are
    serialized into every record and a misclassified secret
    leaks into every log line until the pipeline is restarted.
    Sensitive-data classification (which keys count as secrets)
    lives in `security-patterns` per audit-methodology rule 33;
    this skill rules the *pipeline shape*. `(arch)`
51. The redaction pipeline must be testable. Add unit tests that
    pass synthetic records containing canonical sensitive keys
    (per `security-patterns`) and assert the records emerge with
    those keys redacted or removed. An untested redaction filter
    is indistinguishable from no redaction. `(code)`

## §I — Sampling

52. Use `ParentBased(TraceIdRatioBased(ratio))` as the head
    sampler default for any service participating in distributed
    traces. The parent-based wrapper preserves trace coherence
    across service boundaries — once a trace is sampled at the
    root, every child service sees the sampling decision via
    propagation context and the trace remains complete in the
    backend. `(ops)`
53. Sample ratio is per-environment and env-var-driven
    (`OTEL_TRACES_SAMPLER=parentbased_traceidratio`,
    `OTEL_TRACES_SAMPLER_ARG=0.05`). Hardcoding the ratio in
    source forces a code change to adjust sampling in
    production. The auditable defect: a `TraceIdRatioBased(0.1)`
    literal in application code rather than an env-driven
    default. `(ops)`
54. Tail sampling is collector-side, never application-side.
    Implement custom tail sampling decisions
    (sample-on-error, sample-on-slow, sample-on-customer-tier)
    in the OpenTelemetry Collector's tail-sampling processor —
    not by writing a custom `Sampler` subclass in the
    application. Application-side tail sampling requires
    holding spans in process memory until the trace completes,
    which is unbounded under load. `(arch)`
55. Sampling ratio is a cost/coverage tradeoff. Higher ratios
    increase trace storage cost and per-request overhead; lower
    ratios miss rare-event traces. Document the ratio and its
    rationale alongside the deployment manifest — never set
    the ratio without recording why. `(ops)`

## §J — SLO definition shape and burn-rate alerts

56. Every SLO has a three-part shape: an **SLI query** (a
    PromQL expression evaluating to a 0-to-1 success ratio over
    an interval), an **Objective** (a target percentage,
    e.g., 99.9%), and an **evaluation window** (e.g., 30-day
    rolling window). All three parts MUST be explicit in the
    SLO definition; an SLO without one of the three is
    incomplete. `(ops)`
57. Implement multi-window multi-burn-rate (MWMB) alerts using
    the four-window pattern from the Google SRE workbook:
    page-fast (5m+1h windows, burn rate 14.4), page-slow
    (30m+6h, burn rate 6), ticket-slow (2h+1d, burn rate 3),
    ticket-very-slow (6h+3d, burn rate 1). Page-tier alerts
    route to on-call rotation; ticket-tier alerts route to a
    backlog. Single-window alerts either over-page on
    transient blips or under-page on slow burns. `(ops)`
58. Page-tier alerts route to on-call paging
    (PagerDuty / Opsgenie); ticket-tier alerts route to a
    work-tracking backlog (Jira / Linear). Mixed routing
    (paging on a 24-hour-window low-burn alert) inverts the
    severity signal and erodes on-call trust. `(ops)`
59. **Every defined SLO MUST reference a metric the application actually exports.** An alert rule, recording rule, or SLO definition that references `http_request_duration_seconds` MUST correspond to a histogram registered in the application's metric registry and exposed at the `/metrics` endpoint (or equivalent OTLP push). The auditable defect: an SLO YAML / alertmanager rule / Sloth spec that names a metric absent from any application's metric registration. The fix is always one of (a) register and emit the metric, (b) rewrite the SLO against an existing metric, or (c) delete the orphaned SLO. `(ops)`
60. Compute the SLI via a recording rule, not in the alert
    expression directly. Recording rules pre-compute the
    success ratio at scrape interval and store it as a new
    series; the alert expression then evaluates a simple
    threshold against the recorded series. Computing the SLI
    in the alert hot path repeats the heavyweight
    `histogram_quantile()` / `rate()` work on every alert
    evaluation cycle. `(ops)`
61. Test-environment alerts route to a non-paging channel
    (a chatops room, a development inbox), never to the
    production on-call rotation. Pages from a non-production
    environment train the on-call rotation to ignore alerts
    from the alert source — a permanent reduction in alert
    signal value. `(ops)`

## §K — Retention policy shape

62. Logs MUST have a defined three-tier retention shape: hot
    (queryable, recent — typically 7-30 days), warm
    (indexed, slower-query — typically 30-90 days), cold
    (archived, restoration-required — months to years per
    compliance). The auditable defect: a deployment manifest
    with a single retention value and no tier distinction. The
    skill does NOT rule specific day counts (vendor- and
    compliance-shaped); it rules that the tiers must exist and
    be explicit. `(ops)`
63. Audit logs (authentication events, authorization decisions,
    privileged operations, data-access events) live in a
    separate retention bucket from operational logs and
    typically require longer retention per compliance
    (HIPAA / PCI / SOX). Mixing audit and operational logs in
    one bucket forces operational-log-volume cost to subsidize
    audit-log compliance retention and complicates legal
    hold. `(ops)`
64. Metrics retention acknowledges Prometheus's local default
    (15 days) plus a long-term-storage tier
    (Thanos / Cortex / VictoriaMetrics / vendor backend) for
    multi-month / multi-year analysis. The long-term tier
    typically downsamples (e.g., 1m resolution → 5m → 1h
    across age tiers); document the downsampling boundaries
    so dashboard authors know which resolution is available at
    which lookback. `(ops)`
65. Trace retention is the lowest-fidelity tier — typical
    industry default is ~10 days. Compliance-driven retention
    (HIPAA / PCI / SOX, regulatory investigation cycles)
    overrides the operational default and applies to every
    signal type per the compliance regime's specific
    requirement. Document the override and the regime that
    drives it. `(ops)`
