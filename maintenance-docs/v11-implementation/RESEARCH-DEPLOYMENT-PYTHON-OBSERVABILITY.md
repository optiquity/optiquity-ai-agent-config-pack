# RESEARCH-DEPLOYMENT-PYTHON-OBSERVABILITY

**Author:** pack-docs-researcher
**Date:** 2026-05-12
**Pack version target:** v11.0 (in development on `v11-dev`)
**BD:** BD-162
**Pipeline stage:** 1 of 4 (researcher → architect → planner → coder)
**Output consumer:** `pack-architect` (for `ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md`)

---

## Purpose

The BD-032 audit (`maintenance-docs/v11-implementation/AUDIT-BD-032.md`)
extended `audit-methodology/SKILL.md` rule 21 (auditor-ops scope) to
explicitly name **metrics, tracing, sampling rate, alerting / SLO, and log
retention** as observability sub-domains the auditor-ops cluster owns —
but the loaded `deployment-python/SKILL.md` carries only **one**
observability rule today (rule 21: structured JSON logging). Auditor-ops
findings in the new sub-domains would therefore have no rule content to
cite.

BD-162 closes that gap by authoring substantive observability rules
grounded in current authoritative external sources rather than
training-data approximations. This document is the upstream evidence
base for that authoring work. **No design decisions are made here** —
rule shape, scope, skill placement, and dimension assignment are
architect decisions in stage 2.

All claims in this document are dated 2026-05-12 (currency-as-of). When
a fact is version-pinned (library version, spec milestone), the version
+ release date is given explicitly.

---

## §1 OpenTelemetry Python SDK conventions

### 1.1 Current versions (currency: 2026-05-12)

- **`opentelemetry-api` / `opentelemetry-sdk`:** **1.41.1** (released
  2026-04-24). 1.x line is stable for traces, metrics, and logs APIs.
  Recent 1.x releases: 1.41.0 (2026-04-09), 1.40.0 (2026-03-04),
  1.39.1 (2025-12-11). [opentelemetry-sdk · PyPI](https://pypi.org/project/opentelemetry-sdk/)
- **`opentelemetry-semantic-conventions`:** **0.62b1** (released
  2026-04-24). Note the `0.x` / `b` suffix — semantic conventions are
  versioned independently of the SDK and are still explicitly
  pre-1.0 / beta. Stability differs by signal area (HTTP and DB are
  generally stable; resource and RPC have moved more recently).
  [opentelemetry-semantic-conventions · PyPI](https://pypi.org/project/opentelemetry-semantic-conventions/)
- **Spec / semantic conventions doc version:** **1.41.0**.
  [OpenTelemetry semantic conventions 1.41.0](https://opentelemetry.io/docs/specs/semconv/)
- **Python version support:** Python 3.9+.
  [opentelemetry-python (GitHub)](https://github.com/open-telemetry/opentelemetry-python)

### 1.2 Resource attributes

The `Resource` is set once at SDK initialization and applies to every
signal (traces, metrics, logs) emitted from that process. The Python
SDK exposes constants via `opentelemetry.semconv.resource.ResourceAttributes`.
Standard required-or-recommended attributes for a deployed service:

- **`service.name`** (REQUIRED). Logical service name; used as the
  primary identifier in nearly every backend.
- **`service.version`** — version of the service (semver, git SHA,
  build number).
- **`service.instance.id`** — unique per-process identifier (typically
  `${HOSTNAME}-${PID}` or a UUID generated at boot).
- **`service.namespace`** — used to disambiguate `service.name`
  collisions across teams / tenants.
- **`deployment.environment`** (now `deployment.environment.name` in
  newer semconv revisions; both names appear in field) — `dev`,
  `staging`, `prod`, etc.
- Container / k8s attributes (`container.id`, `k8s.pod.name`,
  `k8s.namespace.name`, `k8s.node.name`) — auto-populated by resource
  detectors when available.

Citations: [Semantic Conventions overview](https://opentelemetry.io/docs/concepts/semantic-conventions/),
[Python semconv package](https://pypi.org/project/opentelemetry-semantic-conventions/).

### 1.3 Span naming and attribute conventions

Span names follow the **operation/method** form (e.g. `GET /users/:id`,
`grpc.UserService/GetUser`, `SELECT users`). Attributes follow signal-
specific semconv namespaces:

- **HTTP** (`http.*`): `http.request.method`, `http.response.status_code`,
  `http.route` (low-cardinality template, NOT the rendered URL),
  `url.full`, `url.scheme`, `server.address`, `server.port`.
- **RPC** (`rpc.*`): `rpc.system` (`grpc`), `rpc.service`, `rpc.method`,
  `rpc.grpc.status_code`.
- **DB** (`db.*`): `db.system` (`postgresql`, `mysql`, etc.),
  `db.namespace`, `db.operation.name`, `db.collection.name`,
  `db.query.text` (sanitized).
- **Messaging** (`messaging.*`): `messaging.system`,
  `messaging.destination.name`, `messaging.operation.name`.

Citation: [OpenTelemetry semantic conventions 1.41.0](https://opentelemetry.io/docs/specs/semconv/).
The HTTP / DB / RPC namespaces have moved through several breaking
revisions in 2024–2025 — pinning the semconv package version is
operationally important.

### 1.4 Trace context propagation

Defaults for the Python SDK: a `CompositePropagator` of
**`TraceContextTextMapPropagator`** (W3C TraceContext — `traceparent` /
`tracestate` headers) plus **`W3CBaggagePropagator`** (W3C Baggage —
`baggage` header). Custom propagators are configured via
`opentelemetry.propagate.set_global_textmap()` or via the
`OTEL_PROPAGATORS` env var.

W3C TraceContext is the IETF / W3C standard since 2020 and supersedes
all vendor-specific propagation formats (B3, Jaeger, X-Ray header) for
new code. Vendor formats remain available as opt-in propagators for
interop with existing fleets.

Citations: [Python propagation docs](https://opentelemetry.io/docs/languages/python/propagation/),
[Context propagation concepts](https://opentelemetry.io/docs/concepts/context-propagation/),
[Propagators API spec](https://opentelemetry.io/docs/specs/otel/context/api-propagators/).

### 1.5 Auto-instrumentation library landscape

The OpenTelemetry Python contrib repo (`opentelemetry-python-contrib`)
ships ~70 instrumentation packages. The bootstrap workflow:

```
pip install opentelemetry-distro opentelemetry-exporter-otlp
opentelemetry-bootstrap -a install   # detects installed libs, pip-installs the matching opentelemetry-instrumentation-* packages
opentelemetry-instrument python myapp.py
```

`opentelemetry-bootstrap` reads the active site-packages and installs
the corresponding `opentelemetry-instrumentation-<framework>` package
for each detected library; `opentelemetry-instrument` is the runtime
auto-loader that monkey-patches the instrumented libraries at process
start.

Commonly-loaded instrumentation packages for a Python server:

- `opentelemetry-instrumentation-{requests,httpx,urllib3,aiohttp-client}` — outbound HTTP
- `opentelemetry-instrumentation-{fastapi,django,flask,starlette,asgi,wsgi}` — inbound HTTP
- `opentelemetry-instrumentation-{sqlalchemy,psycopg,psycopg2,asyncpg,pymysql,pymongo,redis}` — DB / cache
- `opentelemetry-instrumentation-{grpc,grpc-aio}` — gRPC client + server
- `opentelemetry-instrumentation-{kafka,confluent-kafka,pika,aio-pika}` — messaging
- `opentelemetry-instrumentation-{logging,celery,boto,boto3sqs}` — cross-cutting

Citations: [Python zero-code instrumentation](https://opentelemetry.io/docs/zero-code/python/),
[opentelemetry-instrumentation PyPI](https://pypi.org/project/opentelemetry-instrumentation/),
[opentelemetry-distro PyPI](https://pypi.org/project/opentelemetry-distro/),
[FastAPI instrumentation (contrib docs)](https://opentelemetry-python-contrib.readthedocs.io/en/latest/instrumentation/fastapi/fastapi.html).

### 1.6 Manual instrumentation patterns

```python
from opentelemetry import trace
tracer = trace.get_tracer(__name__)

with tracer.start_as_current_span("checkout.process_order") as span:
    span.set_attribute("order.id", order_id)
    span.set_attribute("order.item_count", len(items))
    span.add_event("payment.authorized", {"payment.method": "card"})
    try:
        result = process(order_id)
        span.set_status(trace.Status(trace.StatusCode.OK))
    except Exception as exc:
        span.record_exception(exc)
        span.set_status(trace.Status(trace.StatusCode.ERROR, str(exc)))
        raise
```

Status codes: **OK** (explicit success), **ERROR** (explicit failure),
**UNSET** (default — backend infers from `error` semantic flag /
exception). Production rule: only set OK when the application has
domain-level confirmation; let UNSET flow otherwise so the backend's
own heuristics apply.

Span links (`Link`) connect spans across causal boundaries that are not
parent-child (e.g. message-queue producer → consumer batch where one
consumer span links to N producer spans).

### 1.7 Exporters

- **OTLP gRPC** (`opentelemetry-exporter-otlp-proto-grpc`) — default in
  `opentelemetry-distro`. Recommended for in-cluster export to a
  collector. Endpoint env: `OTEL_EXPORTER_OTLP_ENDPOINT` (default
  `http://localhost:4317`).
- **OTLP HTTP/protobuf** (`opentelemetry-exporter-otlp-proto-http`) —
  preferred when egress is HTTP-only (managed SaaS endpoints, FaaS
  with no gRPC support). Default port `4318`.
- **Cloud-native exporters:** Jaeger and Zipkin direct exporters exist
  but are deprecated paths in favor of OTLP-to-collector-to-backend.
  The Jaeger backend itself accepts OTLP natively since v1.35
  ([Jaeger SDK migration](https://www.jaegertracing.io/sdk-migration/)).

Citations: [OpenTelemetry sampling concepts](https://opentelemetry.io/docs/concepts/sampling/),
[OpenTelemetry sampling milestones (2025)](https://opentelemetry.io/blog/2025/sampling-milestones/).

---

## §2 Prometheus client library conventions

### 2.1 Current state (currency: 2026-05-12)

- **`prometheus_client` (Python):** the canonical Python instrumentation
  library, hosted at `prometheus/client_python` on GitHub. It implements
  the four metric types (Counter, Gauge, Histogram, Summary), exposition
  in both the legacy Prometheus text format and OpenMetrics, and the
  multi-process collector for fork-model servers.
  [prometheus-client PyPI](https://pypi.org/project/prometheus-client/),
  [client_python docs](https://prometheus.github.io/client_python/).
- **Prometheus server:** native histograms (formerly "sparse
  histograms") have been available since Prometheus 2.40 and are
  the recommended forward path for latency metrics, replacing
  hand-tuned bucket lists. [Native Histograms spec](https://prometheus.io/docs/specs/native_histograms/).

### 2.2 Metric naming conventions

Authoritative source: [Prometheus naming conventions](https://prometheus.io/docs/practices/naming/)
and [Writing client libraries](https://prometheus.io/docs/instrumenting/writing_clientlibs/).

- Metric name shape: `[namespace_][subsystem_]name[_unit][_total]` —
  snake_case; namespace + subsystem are optional helpers, name +
  unit is the durable shape.
- **Counters end in `_total`.** The `prometheus_client` library
  appends `_total` automatically — the application code creates
  `Counter("http_requests", ...)` and the exposed series is
  `http_requests_total`. (OpenMetrics requires the `_total` suffix;
  the library handles compatibility between Prometheus text format
  and OpenMetrics.)
- **Histograms expose `_bucket`, `_sum`, `_count`** suffixes
  automatically. The base name describes what is measured
  (`http_request_duration_seconds`, NOT
  `http_request_duration_seconds_histogram`).
- **Use base SI units in the name:** `_seconds` (NOT `_milliseconds`
  or `_ms`), `_bytes` (NOT `_kb` or `_mb`), `_meters`. This is a
  hard rule from the Prometheus naming guide — backends and dashboards
  assume base units.
- **Single-word `_total` is reserved for counters.** Do not use
  `_count` as a metric suffix on a counter (Prometheus already exposes
  `_count` as a histogram suffix; double-naming creates query
  confusion).
- A metric name SHOULD have a single unit and SHOULD measure a single
  thing (latency-of-X is one metric; success-vs-failure split goes in
  a label, not a separate metric name).

### 2.3 Label conventions and cardinality

Authoritative source: [Prometheus naming conventions](https://prometheus.io/docs/practices/naming/),
[Histogram and summary practices](https://prometheus.io/docs/practices/histograms/).

- Every unique combination of label values creates a new time series.
  Cardinality cost is multiplicative across labels.
- **Never label by unbounded sets:** `user_id`, `email`, `request_id`,
  `trace_id`, `session_id`, raw URL path, IP address. These belong in
  logs / traces, not metrics.
- **Label by low-cardinality dimensions:** HTTP route template (NOT
  rendered path), HTTP method, status code class (`2xx`, `4xx`, `5xx`)
  or specific code, RPC service + method, queue name, error class.
- **Label keys describe the dimension**, label values are the
  enumeration. `method="GET"`, NOT `get="true"`.
- No PII in labels — label values are stored verbatim and indexed.
- Practical soft limit: keep total series-per-metric below ~10k;
  dashboards and ad-hoc queries degrade above that.

### 2.4 Histogram bucket selection

- **Default `prometheus_client` Python buckets** for the `Histogram`
  type: `(.005, .01, .025, .05, .075, .1, .25, .5, .75, 1.0, 2.5,
  5.0, 7.5, 10.0, +Inf)` — designed for HTTP request latency in
  seconds, covering the 5ms..10s range with logarithmic-ish spacing.
  [Histogram (client_python)](https://prometheus.github.io/client_python/instrumenting/histogram/).
- **Custom buckets are required when the latency distribution falls
  outside that range** (e.g., sub-millisecond cache lookups; minute-
  scale batch jobs). Hand-picked buckets that don't include the
  service's actual SLO threshold produce wrong quantile estimates.
- **`p99` quantile estimates from `histogram_quantile()`** are only
  meaningful when buckets straddle the actual quantile. Rule of
  thumb: have at least 2-3 buckets between p50 and p99.
- **Native histograms (Prometheus 2.40+)** dynamically choose
  exponential buckets at ingest time, removing the bucket-tuning
  problem. Library support: `prometheus_client` exposes native
  histograms via `Histogram(..., buckets=...)` plus the OpenMetrics
  exposition path; the canonical forward direction is OpenTelemetry
  exponential histograms exported via OTLP and converted at the
  Prometheus side. [Native Histograms spec](https://prometheus.io/docs/specs/native_histograms/),
  [OpenTelemetry Histograms with Prometheus (Asserts blog)](https://www.asserts.ai/blog/opentelemetry-histograms-with-prometheus/).
- **SLO-tuned buckets:** include the SLO threshold as an exact bucket
  boundary (e.g., if SLO is "99% of requests under 200ms", include
  `0.2` in the bucket list).

### 2.5 Counter / Gauge / Histogram / Summary semantics

Authoritative source: [Metric types](https://prometheus.io/docs/concepts/metric_types/).

- **Counter** — monotonically increasing; resets to zero on process
  restart. Use for `_total` suffix metrics: requests, errors, bytes
  sent. Query with `rate()` / `increase()`, never raw value.
- **Gauge** — value that can go up and down. Use for current state:
  `_in_progress`, queue depth, memory usage, connection-pool size.
- **Histogram** — bucketed observations of a value distribution
  (latency, payload size). Quantiles computed at query time via
  `histogram_quantile()`. Aggregatable across instances.
- **Summary** — pre-computed quantiles emitted at exposition time.
  **NOT aggregatable across instances** (you cannot average p99s).
  Avoid in distributed deployments; histograms are almost always
  the right answer.

### 2.6 Multi-process exposition

Python's fork-based servers (Gunicorn with sync or `gthread` workers,
uWSGI, `gunicorn -k uvicorn.workers.UvicornWorker` with
`--workers > 1`) need the **multiprocess mode** because each worker
runs in its own process and the in-memory metric registry is not
shared.

Configuration:

1. Set env var `PROMETHEUS_MULTIPROC_DIR=/path/to/dir` (must be set
   from the start-up shell, not from Python — the directory MUST
   exist before any prometheus_client import).
2. Wipe the directory **before each server start** (stale files from
   the previous run cause incorrect counter values).
3. The `/metrics` endpoint must use `MultiProcessCollector` to
   aggregate across worker shards before exposing.

Citations: [Multiprocess Mode (client_python)](https://prometheus.github.io/client_python/multiprocess/),
[FastAPI + Gunicorn](https://prometheus.github.io/client_python/exporting/http/fastapi-gunicorn/).

Caveats:
- **Counter / Histogram / Summary** work correctly in multiprocess mode
  via per-worker shard files.
- **Gauge** semantics are tricky — choose a multiprocess mode
  (`all`, `liveall`, `livesum`, `min`, `max`, `sum`) per gauge that
  matches its meaning.
- Multiprocess mode adds disk-IO overhead per metric write.

**Async-only servers** (single-process Uvicorn / Hypercorn / pure
asyncio) do NOT need multiprocess mode — the in-memory registry works.

### 2.7 Exposition endpoint

`/metrics` over HTTP, content-type
`text/plain; version=0.0.4; charset=utf-8` (Prometheus text format) or
`application/openmetrics-text` (OpenMetrics). The endpoint must:

- Be unauthenticated (or use a separate scrape-only credential) — the
  Prometheus scraper has no application identity.
- Be reachable from the Prometheus server (network policy, k8s
  Service, ServiceMonitor / PodMonitor for the operator).
- Be excluded from request-tracing / request-counting (don't measure
  the scrape with the metrics it produces).


---

## §3 Structured logging landscape

### 3.1 Library options (currency: 2026-05-12)

| Library | Latest version | Niche | Notes |
|---|---|---|---|
| `structlog` | **25.5.0** (2026) | Performance + observability | Processor-pipeline architecture; first-class JSON renderer; bound loggers carry context; integrates cleanly with stdlib logging via `ProcessorFormatter`. [structlog PyPI](https://pypi.org/project/structlog/), [Processors docs](https://www.structlog.org/en/stable/processors.html). |
| `loguru` | 0.7.x line | Developer ergonomics | Single-import `from loguru import logger`; built-in file rotation / compression; no native OpenTelemetry integration as of 2026. |
| `python-json-logger` | 3.x line | Stdlib JSON formatter | Drop-in JSON `Formatter` for stdlib `logging`. Library-friendly (third-party libs that log via stdlib stay JSON-correct). Limited context-binding API (every contextual field via `extra={}`). |
| Stdlib `logging` (alone) | n/a (CPython) | Universal floor | Always present; required as the destination for any third-party library that logs. Custom `Formatter` can produce JSON but lacks context binding. |

Citations: [Choosing a Python Logging Library in 2026 (Dash0)](https://www.dash0.com/guides/python-logging-libraries),
[Which Python Logging Library Should I Use in 2026? (BSWEN)](https://docs.bswen.com/blog/2026-04-29-python-logging-library-choice/),
[structlog vs Python stdlib Logging (BSWEN)](https://docs.bswen.com/blog/2026-04-29-structlog-vs-stdlib-logging/).

### 3.2 Required structured-log fields (independent of library choice)

For any production Python service, every log record SHOULD carry:

- **Timestamp** — ISO-8601 with timezone (UTC, `+00:00` suffix).
- **Severity / level** — `DEBUG | INFO | WARN | ERROR | CRITICAL`
  (and increasingly `TRACE` / `NOTICE` for OpenTelemetry parity).
- **Service identifiers** — `service.name`, `service.version`,
  `service.instance.id`, `deployment.environment` (mirroring the
  OpenTelemetry resource attributes from §1.2 so logs and traces
  join cleanly in the backend).
- **Trace correlation** — `trace_id`, `span_id`, `trace_flags`
  (sampled-bit) — see §3.3.
- **Request identifiers** — `request_id` / `correlation_id` (set at
  ingress middleware, propagated through async tasks via
  `contextvars`).
- **Event-specific fields** — domain key/value pairs. Avoid
  string-interpolated message bodies; prefer `logger.info("payment.declined", reason=..., amount=...)`.
- **Exception data** — full stack trace + exception type + message
  on `ERROR`/`CRITICAL` records. `structlog.processors.format_exc_info`
  or stdlib `exc_info=True`.

### 3.3 Trace ↔ log correlation

The OpenTelemetry-Python contrib package
`opentelemetry-instrumentation-logging` injects the active span's
`trace_id` and `span_id` into every stdlib log record:

- Set env: `OTEL_PYTHON_LOG_CORRELATION=true`.
- Or call `LoggingInstrumentor().instrument(set_logging_format=True)`
  programmatically.
- The injected log-record attributes are `otelTraceID`, `otelSpanID`,
  `otelServiceName`, `otelTraceSampled` (note the `otel`-prefixed
  attribute names, designed not to collide with custom fields).

Default formatter string (when `set_logging_format=True`):

```
%(asctime)s %(levelname)s [%(name)s] [%(filename)s:%(lineno)d] [trace_id=%(otelTraceID)s span_id=%(otelSpanID)s resource.service.name=%(otelServiceName)s trace_sampled=%(otelTraceSampled)s] - %(message)s
```

For JSON output, route the same record through a JSON formatter
(`python-json-logger` or `structlog`'s JSON renderer); the
`otelTraceID` / `otelSpanID` keys appear as top-level JSON fields.

Citations: [OpenTelemetry Logging Instrumentation (Python contrib)](https://opentelemetry-python-contrib.readthedocs.io/en/latest/instrumentation/logging/logging.html),
[How to Inject Trace IDs into Application Logs with OpenTelemetry SDKs](https://oneuptime.com/blog/post/2026-02-06-inject-trace-ids-application-logs-opentelemetry/view).

The longer-term OpenTelemetry direction is the **OTel Logs SDK** (now
stable in 1.x), where logs are emitted via the OTel API and exported
to a backend over OTLP — eliminating the stdlib bridge. The Python
SDK supports this path (`opentelemetry.sdk._logs`) but most production
fleets still use stdlib logging + correlation injection because of
the third-party-library compatibility floor.

### 3.4 Sensitive-data redaction

Authoritative source: [OpenTelemetry Logging spec](https://opentelemetry.io/docs/specs/otel/logs/),
plus general OWASP / cloud guidance.

- Never log **secrets, tokens, passwords, API keys, JWTs, session
  cookies, or full PII** (full email, full SSN, full credit card,
  full address, raw user input that may contain credentials).
- Define a redaction processor early in the log pipeline (structlog:
  a custom processor that walks the event dict and masks known-
  sensitive keys; stdlib: a `Filter` subclass).
- Hash or partial-mask (`tok_****abcd`) rather than full-redact when
  a debugging trail needs continuity.
- Bound contexts (`structlog.contextvars.bind_contextvars`) make it
  easy to accidentally bind a token at request entry and have it
  appear on every downstream log; codify a "no auth headers in
  bound context" rule.

### 3.5 Per-environment configuration

- `LOG_LEVEL` env var; default INFO in prod, DEBUG in local.
- `LOG_FORMAT` env var: `json` in prod (machine-parsed), `console`
  in local (human-readable, color).
- Avoid two log destinations in prod (file + stdout) unless the file
  is explicitly the application log and stdout is the platform log;
  cloud platforms (k8s, Cloud Run, ECS, App Service) collect stdout
  by default — log there.

---

## §4 SLO / alerting frameworks

### 4.1 Framework landscape (currency: 2026-05-12)

| Framework | Shape | Notes |
|---|---|---|
| **Sloth** | YAML SLO spec → generated PrometheusRule manifests | OSS, Apache 2.0; "Easy and simple Prometheus SLO generator". Generates SLI recording rules + multi-window multi-burn-rate (MWMB) alert rules. Plugin-based architecture (alert_rules_v1 plugin). [slok/sloth (GitHub)](https://github.com/slok/sloth), [Sloth alert_rules_v1 plugin](https://sloth.dev/slo-plugins/core/alert_rules_v1/), [Sloth architecture](https://sloth.dev/introduction/architecture/). |
| **Pyrra** | Kubernetes-native CRD + UI | OSS; defines SLOs as a `ServiceLevelObjective` CRD; generates recording rules + MWMB alerts at 4 severity levels; ships a UI for SLO browsing. [pyrra-dev/pyrra (GitHub)](https://github.com/pyrra-dev/pyrra), [pyrra.dev](https://pyrra.dev/). |
| **Grafana SLO** | Grafana-managed (Cloud + Enterprise) | Closed-source; defines SLOs in Grafana UI / Terraform; generates MWMB alerts via Grafana's alerting layer. |
| **Hand-written PromQL** | DIY | Always an option; the [Google SRE workbook on alerting on SLOs](https://sre.google/workbook/alerting-on-slos/) is the canonical reference for what to write. |

### 4.2 SLO definition shape

A standard SLO has three parts:

1. **SLI** (indicator) — a query that produces "good events" / "all
   events" over a time window. For HTTP: `rate(http_requests_total{status!~"5.."}[5m]) / rate(http_requests_total[5m])`. For latency: `rate(http_request_duration_seconds_bucket{le="0.2"}[5m]) / rate(http_request_duration_seconds_count[5m])`.
2. **Objective** — a target percentage (`99.9%`) over an evaluation
   window (`30d`).
3. **Alert rules** — multi-window multi-burn-rate alerts derived
   from the SLO and the error budget.

### 4.3 Multi-window multi-burn-rate (MWMB) alerts

Source: [Google SRE workbook — Alerting on SLOs](https://sre.google/workbook/alerting-on-slos/),
[Sloth alert_rules_v1](https://sloth.dev/slo-plugins/core/alert_rules_v1/),
[99.99% SLO Alert Template (Multi-Window Burn Rate)](https://medium.com/@obaff/99-99-slo-alert-template-multi-window-burn-rate-35d0bb38962f).

Standard 4-window pattern (for a 30-day SLO window):

| Severity | Long window | Short window | Burn rate |
|---|---|---|---|
| Page (fast burn) | 1h | 5m | 14.4 (2% budget in 1h) |
| Page (slow burn) | 6h | 30m | 6 (5% budget in 6h) |
| Ticket (slow burn) | 24h | 2h | 3 (10% budget in 24h) |
| Ticket (very slow) | 3d | 6h | 1 (10% budget in 3d) |

Both windows MUST fire to alert (the short window guards against
over-alerting on stale conditions; the long window guards against
flapping on noise spikes).

### 4.4 Notification routing

- **Alertmanager** is the canonical routing layer for Prometheus-based
  alerts: deduplication, grouping, silencing, inhibition,
  routing-by-label to receivers (PagerDuty, Slack, Opsgenie, email,
  webhook).
- Page-vs-ticket severity routes to different receivers: page →
  on-call rotation; ticket → backlog channel.
- Alert routing is environment-shaped (test alerts to Slack-test;
  prod alerts to PagerDuty), driven by the `environment` /
  `severity` label that flows from the SLO definition.

---

## §5 Sampling strategies

### 5.1 Head sampling (decided at trace start)

OpenTelemetry built-in samplers (Python SDK):

- **`AlwaysOn`** / **`AlwaysOff`** — debug / disabled.
- **`TraceIdRatioBased(ratio)`** — sample `ratio` fraction of traces
  by hashing the trace ID. Deterministic per trace ID; identical
  decisions across services if they share the same root sampler.
- **`ParentBased(root_sampler, ...)`** — composite sampler that
  respects the parent span's sampled flag (if a parent exists) and
  otherwise delegates to `root_sampler`. **This is the recommended
  default** for any service that participates in distributed traces:
  if an upstream service decided to sample (or not), the downstream
  service honors that decision so the trace is whole.

Common production root sampler:
`ParentBased(root=TraceIdRatioBased(0.01))` — sample 1% of traces
that originate at this service; downstream sampling for traces
inherited from upstream follows the upstream decision.

Set via env: `OTEL_TRACES_SAMPLER=parentbased_traceidratio`,
`OTEL_TRACES_SAMPLER_ARG=0.01`.

Citations: [OpenTelemetry Sampling concepts](https://opentelemetry.io/docs/concepts/sampling/),
[Python SDK sampling reference](https://opentelemetry-python.readthedocs.io/en/latest/sdk/trace.sampling.html),
[OpenTelemetry Sampling milestones (2025)](https://opentelemetry.io/blog/2025/sampling-milestones/).

### 5.2 Tail sampling (decided after trace completes)

Implemented by the **OpenTelemetry Collector** `tail_sampling`
processor, NOT in the SDK. The collector buffers all spans for a
trace until either (a) `decision_wait` elapses or (b) a configurable
condition fires, then evaluates ordered policies:

- **`probabilistic`** — keep N% of traces (same shape as
  `TraceIdRatioBased`).
- **`status_code`** — keep all traces containing an `ERROR` span.
- **`latency`** — keep traces where total duration > threshold.
- **`string_attribute`** / **`numeric_attribute`** — keep on
  matched attributes (`http.status_code = 500`, `customer.tier = enterprise`).
- **`rate_limiting`** — cap kept traces per second.
- **`composite`** — combine policies with rate limits per policy.

Configuration parameters: `decision_wait` (default 30s), `num_traces`
(default 50000), `expected_new_traces_per_sec`.

Tradeoff vs head sampling:
- **Head sampling:** decided cheaply per trace at the SDK; loses
  rare-but-important traces (errors, slow requests) at the same rate
  as everything else.
- **Tail sampling:** keeps the interesting traces; requires a
  collector tier sized for full trace volume in memory for
  `decision_wait` seconds; requires all spans for a given trace to
  reach the same collector instance (load-balancer affinity by
  `trace_id` or a load-balancing exporter in a two-tier collector).

Citations: [Tail Sampling Processor (collector-contrib)](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/processor/tailsamplingprocessor/README.md),
[Tail Sampling with OpenTelemetry (OTel blog 2022)](https://opentelemetry.io/blog/2022/tail-sampling/),
[How to Configure the Probabilistic Sampler Processor](https://oneuptime.com/blog/post/2026-02-06-probabilistic-sampler-processor-opentelemetry-collector/view).

### 5.3 Adaptive / dynamic sampling

Newer collector and vendor implementations support adaptive sampling
(adjust sample rate based on observed traffic / error rate). The
2025 OpenTelemetry sampling milestones blog (cited above) introduces
the `tracestate` "ot" probability key (`th:0` for 100%) so downstream
systems can reason about and re-sample without losing absolute-rate
information. This is in active stabilization as of 2026-05-12.


---

## §6 Library landscape currency (2026-05-12 snapshot)

### 6.1 Dominant in v11.0 timeframe

| Concern | Library | Latest version | Stability |
|---|---|---|---|
| Tracing API/SDK | `opentelemetry-api` / `opentelemetry-sdk` | 1.41.1 (2026-04-24) | Stable |
| Semantic conventions | `opentelemetry-semantic-conventions` | 0.62b1 (2026-04-24) | Beta — pin exact version |
| Auto-instrumentation runtime | `opentelemetry-distro` + `opentelemetry-instrument` | 0.62b1 line | Stable for the agent path; per-library packages versioned independently |
| Metrics (push-/pull-based) | `prometheus_client` | 0.x line, active | Stable; the canonical Python Prometheus library |
| Native histograms | Prometheus 2.40+ on the server side | n/a | Stable; opt-in per metric |
| Structured logging — recommended | `structlog` | 25.5.0 (2026) | Stable |
| Structured logging — minimal | `python-json-logger` | 3.x | Stable |
| Structured logging — DX-focused | `loguru` | 0.7.x | Stable; no native OTel support |
| Trace/log correlation | `opentelemetry-instrumentation-logging` | 0.62b1 | Stable |
| OTLP exporters | `opentelemetry-exporter-otlp-proto-grpc` / `…-http` | 1.41.1 | Stable |
| Cloud trace exporters | `opentelemetry-exporter-gcp-trace`, `azure-monitor-opentelemetry-exporter` | active | Stable; vendor-maintained |

Citations: [opentelemetry-api PyPI](https://pypi.org/project/opentelemetry-api/),
[opentelemetry-sdk PyPI](https://pypi.org/project/opentelemetry-sdk/),
[opentelemetry-distro PyPI](https://pypi.org/project/opentelemetry-distro/),
[opentelemetry-instrumentation PyPI](https://pypi.org/project/opentelemetry-instrumentation/),
[prometheus-client PyPI](https://pypi.org/project/prometheus-client/),
[structlog PyPI](https://pypi.org/project/structlog/),
[opentelemetry-exporter-gcp-trace PyPI](https://pypi.org/project/opentelemetry-exporter-gcp-trace/),
[azure-monitor-opentelemetry-exporter PyPI](https://pypi.org/project/azure-monitor-opentelemetry-exporter/).

### 6.2 Deprecated / EOL

- **OpenTracing API and `opentracing` Python package** — deprecated;
  the OpenTracing project merged into OpenTelemetry. New code MUST
  use the OpenTelemetry API. An OpenTracing shim
  (`opentelemetry-opentracing-shim`) exists for incremental
  migration of large codebases that still call the OpenTracing API.
  [Migrating from OpenTracing](https://opentelemetry.io/docs/migration/opentracing/).
- **Jaeger native client libraries** (`jaeger-client`, including the
  Python implementation) — retired by the Jaeger project in 2022.
  Migration target: OpenTelemetry SDK + OTLP exporter. The Jaeger
  backend itself remains supported and accepts OTLP natively since
  v1.35. [Jaeger SDK migration](https://www.jaegertracing.io/sdk-migration/).
- **Zipkin's `py_zipkin`-style direct exporters** — superseded by
  OTel + OTLP-to-collector-with-Zipkin-exporter for new code; direct
  exporters still work but are not the recommended path.

### 6.3 Emerging / unstable

- **Native histograms in `prometheus_client`** — the wire format and
  client APIs are stabilizing through 2025–2026; production rollout
  is fleet-by-fleet with explicit opt-in.
- **OpenTelemetry Logs SDK in Python** — the API is stable; the
  `opentelemetry.sdk._logs` module name carries an underscore
  prefix indicating residual instability around the bridge to
  stdlib logging. Most production code uses stdlib + correlation
  injection; full OTel-native logs is forward-looking.
- **`tracestate` "ot" probability key** (per the 2025 sampling
  milestones blog) — in active stabilization for cross-system
  sample-rate reasoning. Not yet a rule-able foundation.

---

## §7 Cross-cutting concerns

### 7.1 Container observability

- **Sidecar exporter pattern** — the canonical k8s pattern is an
  OpenTelemetry Collector running as a DaemonSet (one collector per
  node) or as a sidecar (one collector per pod, lower scale). The
  application exports OTLP to `localhost:4317`; the collector
  forwards to the backend. This decouples application lifecycle
  from backend choice.
- **OpenTelemetry Operator** (k8s) — manages collector lifecycles
  and supports auto-injection of instrumentation via the
  `Instrumentation` CRD (`instrumentation.opentelemetry.io/inject-python: "true"` annotation injects a Python init container with `opentelemetry-distro` pre-installed and configured).
- **eBPF auto-instrumentation** (Pixie, Beyla, Coroot) — kernel-
  level capture of HTTP / gRPC / database calls without code change.
  Useful for legacy services or polyglot fleets; lower fidelity than
  in-process SDK instrumentation (no application-level context, no
  span attributes for domain data, no manual span creation).

### 7.2 Cloud-platform-specific patterns

- **GCP Cloud Trace + Cloud Logging + Cloud Monitoring** — Google
  Cloud Observability now accepts OTLP natively at
  `telemetry.googleapis.com` (announced Sep 2025; see [InfoQ article](https://www.infoq.com/news/2025/09/gcp-opentelemetry-adoption/)),
  removing the need for the legacy `opentelemetry-exporter-gcp-trace`
  vendor exporter for new code. Vendor exporter remains supported
  for projects already using it. Logs auto-correlate via
  `logging.googleapis.com/trace` field.
- **AWS X-Ray + CloudWatch** — AWS Distro for OpenTelemetry (ADOT)
  is the AWS-supported distribution; X-Ray exporter lives in the
  collector (not the SDK). For new code, instrument with vanilla
  OTel, export to ADOT collector, let the collector translate to
  X-Ray + CloudWatch Metrics. [AWS ADOT X-Ray getting-started](https://aws-otel.github.io/docs/getting-started/x-ray/).
- **Azure Monitor / Application Insights** —
  `azure-monitor-opentelemetry-exporter` (or the higher-level
  `azure-monitor-opentelemetry` distro) sends OTLP-shaped data into
  Application Insights. Alternative: standard OTLP exporter →
  Azure Monitor's OTLP ingestion endpoint.
- **All three clouds** support the same logical pattern: instrument
  with vanilla OpenTelemetry, export OTLP, let the cloud-side
  collector / endpoint translate. Vendor-specific Python SDKs are
  legacy paths.

### 7.3 Multi-tenancy and isolation

- **Resource attributes for tenancy:** add a tenant identifier to
  the resource (`tenant.id`) only if backend isolation requires it.
  Caution: high-cardinality `tenant.id` on metrics labels causes
  the same cardinality problem as user IDs.
- **Per-tenant sampling rates** require tail sampling (head sampling
  cannot read tenant attributes set deeper in the trace).
- **Log routing by tenant** — typically done at the log-pipeline
  layer (Fluent Bit / Vector / collector) rather than in the
  application; the application includes `tenant.id` as a structured
  field, the pipeline routes accordingly.

### 7.4 Cost considerations

Authoritative source: [Log Retention Policies (groundcover)](https://www.groundcover.com/learn/logging/log-retention-policies),
[Google Cloud Observability pricing](https://cloud.google.com/products/observability/pricing),
[New Relic data retention](https://docs.newrelic.com/docs/accounts/original-accounts-billing/product-based-pricing/overview-data-retention-components/).

- **Logs are the dominant cost** in observability budgets. Industry
  baselines for production retention:
  - **Hot tier** (full-text indexed, fast query): 7–30 days. GCP
    Cloud Logging default: 30 days for non-audit logs.
  - **Warm tier**: 30–90 days, reduced index.
  - **Cold / archive tier**: 90 days – 7 years, object storage,
    re-hydratable but slow query.
  - **Audit / security / compliance logs**: separate retention
    bucket, often multi-year regardless of operational need (HIPAA,
    PCI-DSS, SOX).
- **Metrics retention**: Prometheus defaults 15 days local; long-
  term storage (Thanos, Cortex, Mimir, vendor TSDBs) typically
  keeps 30 days at full resolution and 13 months at downsampled
  resolution. Prometheus / Mimir / Thanos / cloud TSDBs all support
  recording rules for downsampling.
- **Trace retention**: lowest in dollars-per-trace at the per-span
  level but highest in volume; common SaaS default is **10 days**
  for full traces, with sampled trace summaries kept longer.
- **Cardinality is a metrics-cost lever** — every label combination
  is a series; series count drives storage and query cost
  super-linearly.
- **Sampling is a trace-cost lever** — head sampling at the SDK
  reduces wire bytes; tail sampling at the collector keeps the
  interesting subset.

---

## §8 Recommended scope for the rule set

This section gives the architect concrete input for the scope
decision. **The architect decides** the final scope, the rule
shape, and skill placement; this section enumerates the durable
material the research surfaced.

### 8.1 Candidate rule clusters (extracted from §1–§7)

Each cluster represents 4–10 prospective rules at the
`*-patterns`-skill granularity. Ordered by how durable / how
universally applicable the underlying material is.

1. **Trace SDK setup and resource attributes** (very durable):
   `service.name` / `service.version` / `service.instance.id` /
   `deployment.environment` requirements; `Resource` set once at
   SDK init; semconv package version pinning. Source: §1.1, §1.2.
2. **Span lifecycle and attributes** (very durable):
   `start_as_current_span` pattern; status code semantics (OK /
   ERROR / UNSET — when to set OK explicitly); `record_exception`
   on error path; semconv-aligned attributes for HTTP / RPC / DB.
   Source: §1.3, §1.6.
3. **Trace context propagation** (very durable): W3C TraceContext
   + Baggage as default; vendor formats opt-in only; `OTEL_PROPAGATORS`
   env or programmatic `set_global_textmap()`. Source: §1.4.
4. **Auto-instrumentation discipline** (durable): `opentelemetry-distro`
   + `opentelemetry-bootstrap` + `opentelemetry-instrument` workflow;
   auto-instrument inbound + outbound HTTP, DB, gRPC, messaging at
   minimum; manual-instrument domain-significant operations only.
   Source: §1.5.
5. **Exporter configuration** (durable): OTLP gRPC default;
   OTLP HTTP for egress-restricted environments; collector tier
   between application and backend. Source: §1.7, §7.1.
6. **Prometheus metric naming** (very durable): `_total` for
   counters; base SI units (`_seconds`, `_bytes`); single thing per
   metric; namespace/subsystem prefix discipline. Source: §2.2.
7. **Prometheus label cardinality discipline** (very durable):
   no unbounded labels (user_id, request_id, raw URL); use route
   templates not rendered paths; no PII in label values; 10k
   series-per-metric soft cap. Source: §2.3.
8. **Prometheus metric type selection** (very durable): Counter
   vs Gauge vs Histogram vs Summary semantic differences; Summary
   not aggregatable across instances; Histogram bucket selection
   rules (default for HTTP latency, custom for outliers, native
   histograms for new code). Source: §2.4, §2.5.
9. **Prometheus multiprocess mode** (durable, gate-shaped):
   when required (fork-model servers); `PROMETHEUS_MULTIPROC_DIR`
   env + directory wipe-before-start + `MultiProcessCollector` at
   the `/metrics` endpoint. Source: §2.6.
10. **Metrics endpoint exposition** (durable): `/metrics`
    unauthenticated or scrape-credential; excluded from request
    instrumentation; reachable from scraper. Source: §2.7.
11. **Structured logging — required fields** (very durable):
    timestamp w/ TZ, level, service identifiers, trace correlation,
    request identifier, exception data on error. Source: §3.2.
12. **Trace-log correlation** (durable):
    `opentelemetry-instrumentation-logging` for stdlib bridge;
    `OTEL_PYTHON_LOG_CORRELATION=true`; `otelTraceID` /
    `otelSpanID` field names. Source: §3.3.
13. **Sensitive-data redaction in logs** (very durable; security-
    adjacent — coordinate with `security-patterns` to avoid
    overlap): never log secrets / tokens / full PII; redaction
    processor early in pipeline; bound-context discipline. Source:
    §3.4.
14. **Log destination and per-environment level** (durable):
    stdout for cloud platforms; `LOG_LEVEL` / `LOG_FORMAT` env;
    JSON in prod, console in local. Source: §3.5.
15. **Sampling — head sampler default** (durable):
    `ParentBased(TraceIdRatioBased(ratio))` as the production
    default; env config (`OTEL_TRACES_SAMPLER`,
    `OTEL_TRACES_SAMPLER_ARG`); per-environment ratio override.
    Source: §5.1.
16. **Sampling — tail sampling boundary** (less durable, more
    project-shaped): collector-side `tail_sampling` processor for
    "keep all errors / slow / specific tenants"; load-balancing
    requirements; cost tradeoff with head sampling. Source: §5.2.
17. **SLO definition and burn-rate alerts** (durable as patterns;
    project-shaped in instantiation): SLI / Objective / window
    structure; MWMB 4-window pattern; Sloth / Pyrra as generators;
    page-vs-ticket routing. Source: §4.
18. **Retention policy expectations** (durable): hot/warm/cold
    tiering for logs; metrics retention defaults; trace retention
    defaults; audit-log separation. Source: §7.4.

### 8.2 Scope-shape options for the architect

These are scope envelopes the architect can choose between; the
research does not prefer any one.

- **Conservative (~25–35 rules):** clusters 1, 2, 3, 6, 7, 8, 11,
  12, 15. Covers OpenTelemetry-tracing-correctness + Prometheus-
  metrics-correctness + log-trace-correlation. Skips alerting,
  retention, multiprocess, redaction (those would land elsewhere
  or stay deferred).
- **Comprehensive (~60–80 rules — comparable to BD-158
  swift-concurrency-patterns at 66 rules):** all 18 clusters.
  Matches the auditor-ops rule 21 sub-domain coverage one-to-one.
- **Tracing-first (~40 rules):** clusters 1–5, 11–12, 15–16. All
  the tracing surface plus log correlation plus sampling. Defers
  metrics-naming + SLO + retention to a later BD if the priority
  is closing the trace gap first.

### 8.3 Sections where the landscape is too volatile for durable rules

- **Native histogram client API** (§2.4 / §6.3) — wire format and
  client API still stabilizing. A rule "use native histograms" is
  too forward-looking; a rule "be aware of native histograms as
  the migration target" can land as a pointer.
- **`tracestate` "ot" probability key** (§5.3 / §6.3) — in active
  stabilization 2025–2026.
- **OpenTelemetry Logs SDK as the single log path** (§6.3) —
  technically stable but production migration is years out;
  ruling on it would force premature migration. Rule the stdlib +
  correlation-injection pattern; reference the OTel Logs SDK as
  forward direction.
- **Specific SLO framework choice** (§4.1) — Sloth vs Pyrra vs
  Grafana SLO vs hand-written PromQL is project-shaped (the SLO
  framework lives in the deployment layer, not in the application).
  Rule the SLO **shape** (SLI / Objective / MWMB alerts), don't
  rule the framework.
- **eBPF auto-instrumentation** (§7.1) — emerging path, vendor-
  fragmented. Mention as alternative; don't rule.


---

## §9 Open questions for the architect

These are decisions the research **does not pre-empt**. Each is
labeled architect-decision-point (ADP); the research surfaces the
inputs, not the answer.

### ADP-1 — Canonical library citation per rule

For every prospective rule that names a Python library, the architect
must pick the canonical citation. The research's input data:

- **Tracing SDK:** OpenTelemetry is the only viable choice — OpenTracing
  and Jaeger native clients are deprecated (§6.2). Citing
  `opentelemetry-api` / `opentelemetry-sdk` is unambiguous.
- **Metrics SDK:** `prometheus_client` is the canonical Python
  Prometheus instrumentation library (§2.1). The OpenTelemetry
  metrics API is an alternative path (export OTel metrics via OTLP,
  collector translates to Prometheus exposition or remote write);
  the architect chooses whether rules should be Prometheus-first,
  OTel-metrics-first, or both-permitted-with-a-criterion.
- **Structured logging:** the research shows a 3-way split
  (`structlog` / `loguru` / `python-json-logger`+stdlib) with no
  single dominant choice (§3.1). The architect picks one of:
  (a) recommend `structlog` as canonical (best OTel integration,
  highest performance, processor pipeline), with stdlib +
  `python-json-logger` as the universal floor for libraries;
  (b) recommend stdlib + `python-json-logger` as canonical (lowest
  buy-in, third-party-library compatible);
  (c) library-agnostic rules — name the **fields** that must
  appear, leave library choice to the project.

### ADP-2 — Skill placement

BD-162's File/Symbol field allows three placements:

- (a) Append all rules to **`deployment-python/SKILL.md`** (current
  BD-032 audit follow-up target). Pro: tight cohesion with the
  existing one observability rule (rule 21 JSON logging); skills
  load mechanism unchanged. Con: a 60-rule observability addendum
  doubles the size of `deployment-python` and shifts its center of
  gravity from "deployment" to "deployment + observability".
- (b) Split rules between **`deployment-python`** (deployment-config
  shaped: exporter endpoints, env-var-driven sampler ratios, retention
  manifest values, `/metrics` exposition wiring) and
  **`python-server-architecture`** (in-process shaped: span attribute
  semantics, structured-log field requirements, trace correlation
  setup, metric type selection). Pro: respects the existing
  auditor-ops vs auditor-architecture split that
  `audit-methodology` rule 21's "Boundary clarification —
  observability code in source files" already codifies (the rubric
  in `audit-methodology/SKILL.md` rule 21: ops if the fix changes a
  configuration value; architecture if the fix changes a type / call
  graph / wiring). Con: cross-skill cross-references and a harder
  auditor-ops scope-of-load decision.
- (c) Create a NEW **`python-observability-patterns`** skill,
  parallel to BD-156's `protobuf-patterns` precedent (234 lines /
  45 rules) and BD-158's `swift-concurrency-patterns` (418 lines /
  66 rules). Pro: parallel structure to the v11.0 `*-patterns`
  pattern; keeps `deployment-python` focused; gives auditor-ops a
  dedicated skill to load. Con: requires a new skill-load predicate
  (D2=python AND server-or-deploy?), an entry in
  `docs/pack/PLATFORM-SKILLS.md`, possibly a marker helper,
  init-project.sh / add-capability.sh wiring, and v10→v11 migrator
  install coverage (which is itself an open BD — BD-161).

The research observation: option (c) is the closest structural
parallel to the BD-156 / BD-158 precedent the BD-162 description
explicitly cites. Option (b) maps most cleanly onto the existing
auditor-ops vs auditor-architecture rubric. Option (a) is the
smallest pack-product change. The architect picks; the research
does not.

### ADP-3 — Cross-references to `python-server-architecture`

`python-server-architecture` rule 8 already states "Auth, logging, and
metrics belong in gRPC interceptors (or framework middleware for REST),
not in servicer / handler implementations" — i.e. there is already
a thin observability touch in the server-architecture skill. The
architect must decide:

- Should the new observability rules **extend** that touch (cross-
  reference rule 8 from a new rule like "log/metric/trace bootstrap
  lives at app entry, not in handlers")?
- Or should the new rules **stay disjoint** from
  `python-server-architecture` (observability rules cite their own
  skill, and the architecture skill keeps its single observability
  touchpoint)?

### ADP-4 — Overlap with existing `deployment-python` rule 21

`deployment-python` rule 21 today reads: "Enable structured logging
(JSON format) for production. Include request ID, method, status,
and latency in every log entry." This is a fragment of what §3.2 of
this research enumerates as the full required-field set. The
architect must decide:

- (a) Replace rule 21 with the expanded field-set rule from §3.2
  cluster 11.
- (b) Keep rule 21 as-is and add a new rule that supersedes it
  semantically (creates a soft duplicate).
- (c) Move rule 21 into the new skill (option ADP-2c) entirely,
  leaving `deployment-python` without any observability rule —
  which would re-create the BD-032 audit gap one level up if any
  rule references back.

### ADP-5 — Coverage of the auditor-ops rule 21 sub-domains

`audit-methodology` rule 21 names five sub-domains:
**metrics, tracing, sampling rate, alerting / SLO, log retention**.
BD-162's stated goal is to give auditor-ops "rule content to cite"
in each sub-domain. The architect must decide for each sub-domain
whether the new rule set includes:

| Sub-domain | Source in this research | Architect choice: include? |
|---|---|---|
| Metrics | §2 (clusters 6–10) | (likely yes — central to BD-162) |
| Tracing | §1 (clusters 1–5) | (likely yes — central to BD-162) |
| Sampling rate | §5 (clusters 15–16) | (likely yes; cluster 16 may defer) |
| Alerting / SLO | §4 (cluster 17) | (decision: rule the SLO **shape** or punt as project-specific?) |
| Log retention | §7.4 (cluster 18) | (decision: deployment-config-shaped rule, or punt to platform-specific docs?) |

The shape-vs-value distinction (rule the durable shape, leave the
project-specific value to deployment manifests) is the natural
escape hatch for sub-domains where landscape volatility (§8.3)
makes a concrete rule premature.

### ADP-6 — Trinity / multi-CLI considerations

Skills in `project-template/skills/<name>/SKILL.md` ship to all three
CLI agent surfaces (`.claude/skills/`, `.codex/skills/`,
`.gemini/skills/`) byte-identically. The research has no Python-
specific CLI-tool divergence, so trinity replication is the trivial
default. **No ADP here unless** the architect chooses option ADP-2c
(new skill), in which case the new skill name + load predicate need
trinity-replicated coverage in `init-project.sh`,
`add-capability.sh`, `validate-pack`'s skill-inventory check, and
the `PLATFORM-SKILLS.md` intersection table.

---

## Source index (deduped, alphabetical by host)

- AWS — [Adding metrics and traces to your application on Amazon EKS with AWS Distro for OpenTelemetry, AWS X-Ray and Amazon CloudWatch](https://aws.amazon.com/blogs/mt/adding-metrics-and-traces-to-your-application-on-amazon-eks-with-aws-distro-for-opentelemetry-aws-x-ray-and-amazon-cloudwatch/)
- AWS ADOT — [Getting Started with the AWS X-Ray Exporter in the Collector](https://aws-otel.github.io/docs/getting-started/x-ray/)
- Asserts — [OpenTelemetry Histograms with Prometheus](https://www.asserts.ai/blog/opentelemetry-histograms-with-prometheus/)
- BSWEN — [Which Python Logging Library Should I Use in 2026?](https://docs.bswen.com/blog/2026-04-29-python-logging-library-choice/)
- BSWEN — [structlog vs Python stdlib Logging: Which Should You Choose?](https://docs.bswen.com/blog/2026-04-29-structlog-vs-stdlib-logging/)
- Better Stack — [Python Monitoring with Prometheus (Beginner's Guide)](https://betterstack.com/community/guides/monitoring/prometheus-python-metrics/)
- Better Stack — [Sampling in OpenTelemetry: A Beginner's Guide](https://betterstack.com/community/guides/observability/opentelemetry-sampling/)
- Dash0 — [Choosing a Python Logging Library in 2026](https://www.dash0.com/guides/python-logging-libraries)
- Datadog — [Correlating OpenTelemetry Traces and Logs](https://docs.datadoghq.com/tracing/other_telemetry/connect_logs_and_traces/opentelemetry/)
- Datadog — [Ingestion Sampling with OpenTelemetry](https://docs.datadoghq.com/opentelemetry/ingestion_sampling/)
- DeepWiki — [Propagators (open-telemetry/opentelemetry-python)](https://deepwiki.com/open-telemetry/opentelemetry-python/8.2-propagators)
- GitHub — [open-telemetry/opentelemetry-python](https://github.com/open-telemetry/opentelemetry-python)
- GitHub — [open-telemetry/opentelemetry-collector-contrib — tail_sampling processor](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/processor/tailsamplingprocessor/README.md)
- GitHub — [open-telemetry/semantic-conventions Releases](https://github.com/open-telemetry/semantic-conventions/releases)
- GitHub — [pyrra-dev/pyrra](https://github.com/pyrra-dev/pyrra)
- GitHub — [slok/sloth](https://github.com/slok/sloth)
- GitHub — [GoogleCloudPlatform/opentelemetry-operations-python](https://github.com/GoogleCloudPlatform/opentelemetry-operations-python)
- Google Cloud — [Pricing | Google Cloud Observability](https://cloud.google.com/products/observability/pricing)
- Google SRE — [Alerting on SLOs](https://sre.google/workbook/alerting-on-slos/)
- Groundcover — [Log Retention Policies Explained: Challenges & Best Practices](https://www.groundcover.com/learn/logging/log-retention-policies)
- InfoQ — [Google Cloud Observability Adopts OpenTelemetry Protocol for Native Trace Ingestion (Sep 2025)](https://www.infoq.com/news/2025/09/gcp-opentelemetry-adoption/)
- Jaeger — [Migration to OpenTelemetry SDK](https://www.jaegertracing.io/sdk-migration/)
- Last9 — [Histogram Buckets in Prometheus Made Simple](https://last9.io/blog/histogram-buckets-in-prometheus/)
- Microsoft Learn — [Manage data retention in a Log Analytics workspace](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/data-retention-configure)
- Microsoft Learn — [Microsoft Azure Monitor Opentelemetry Exporter Trace Python Samples](https://learn.microsoft.com/en-us/samples/azure/azure-sdk-for-python/microsoft-azure-monitor-opentelemetry-exporter-trace-python-samples/)
- New Relic — [Data retention for original pricing model](https://docs.newrelic.com/docs/accounts/original-accounts-billing/product-based-pricing/overview-data-retention-components/)
- OneUptime — [How to Configure the Probabilistic Sampler Processor](https://oneuptime.com/blog/post/2026-02-06-probabilistic-sampler-processor-opentelemetry-collector/view)
- OneUptime — [How to Inject Trace IDs into Application Logs with OpenTelemetry SDKs](https://oneuptime.com/blog/post/2026-02-06-inject-trace-ids-application-logs-opentelemetry/view)
- OpenTelemetry — [Context propagation](https://opentelemetry.io/docs/concepts/context-propagation/)
- OpenTelemetry — [Migration | overview](https://opentelemetry.io/docs/migration/)
- OpenTelemetry — [Migrating from OpenTracing](https://opentelemetry.io/docs/migration/opentracing/)
- OpenTelemetry — [OpenTelemetry Logging spec](https://opentelemetry.io/docs/specs/otel/logs/)
- OpenTelemetry — [OpenTelemetry Sampling milestones (2025)](https://opentelemetry.io/blog/2025/sampling-milestones/)
- OpenTelemetry — [Propagators API spec](https://opentelemetry.io/docs/specs/otel/context/api-propagators/)
- OpenTelemetry — [Python | OpenTelemetry](https://opentelemetry.io/docs/languages/python/)
- OpenTelemetry — [Python propagation](https://opentelemetry.io/docs/languages/python/propagation/)
- OpenTelemetry — [Python zero-code instrumentation](https://opentelemetry.io/docs/zero-code/python/)
- OpenTelemetry — [Sampling concepts](https://opentelemetry.io/docs/concepts/sampling/)
- OpenTelemetry — [Semantic Conventions overview](https://opentelemetry.io/docs/concepts/semantic-conventions/)
- OpenTelemetry — [Semantic Conventions 1.41.0 spec](https://opentelemetry.io/docs/specs/semconv/)
- OpenTelemetry — [Tail Sampling with OpenTelemetry (2022 blog)](https://opentelemetry.io/blog/2022/tail-sampling/)
- OpenTelemetry Python contrib — [FastAPI instrumentation](https://opentelemetry-python-contrib.readthedocs.io/en/latest/instrumentation/fastapi/fastapi.html)
- OpenTelemetry Python contrib — [Logging instrumentation](https://opentelemetry-python-contrib.readthedocs.io/en/latest/instrumentation/logging/logging.html)
- OpenTelemetry Python — [SDK trace sampling reference](https://opentelemetry-python.readthedocs.io/en/latest/sdk/trace.sampling.html)
- Prometheus — [Histograms and summaries practices](https://prometheus.io/docs/practices/histograms/)
- Prometheus — [Metric and label naming](https://prometheus.io/docs/practices/naming/)
- Prometheus — [Metric types](https://prometheus.io/docs/concepts/metric_types/)
- Prometheus — [Native Histograms specification](https://prometheus.io/docs/specs/native_histograms/)
- Prometheus — [Writing client libraries](https://prometheus.io/docs/instrumenting/writing_clientlibs/)
- Prometheus client_python — [Counter](http://prometheus.github.io/client_python/instrumenting/counter/)
- Prometheus client_python — [FastAPI + Gunicorn](https://prometheus.github.io/client_python/exporting/http/fastapi-gunicorn/)
- Prometheus client_python — [Histogram](http://prometheus.github.io/client_python/instrumenting/histogram/)
- Prometheus client_python — [Multiprocess Mode](https://prometheus.github.io/client_python/multiprocess/)
- PyPI — [azure-monitor-opentelemetry-exporter](https://pypi.org/project/azure-monitor-opentelemetry-exporter/)
- PyPI — [opentelemetry-api](https://pypi.org/project/opentelemetry-api/)
- PyPI — [opentelemetry-distro](https://pypi.org/project/opentelemetry-distro/)
- PyPI — [opentelemetry-exporter-gcp-trace](https://pypi.org/project/opentelemetry-exporter-gcp-trace/)
- PyPI — [opentelemetry-instrumentation](https://pypi.org/project/opentelemetry-instrumentation/)
- PyPI — [opentelemetry-sdk](https://pypi.org/project/opentelemetry-sdk/)
- PyPI — [opentelemetry-semantic-conventions](https://pypi.org/project/opentelemetry-semantic-conventions/)
- PyPI — [prometheus-client](https://pypi.org/project/prometheus-client/)
- PyPI — [structlog](https://pypi.org/project/structlog/)
- Pyrra — [Pyrra: SLO monitoring for Prometheus without the PromQL pain](https://pyrra.dev/)
- SigNoz — [Python OpenTelemetry Instrumentation](https://signoz.io/docs/instrumentation/opentelemetry-python/)
- SigNoz — [Understanding OpenTelemetry — Trace ID vs. Span ID](https://signoz.io/comparisons/opentelemetry-trace-id-vs-span-id/)
- Sloth — [Architecture](https://sloth.dev/introduction/architecture/)
- Sloth — [alert_rules_v1 plugin](https://sloth.dev/slo-plugins/core/alert_rules_v1/)
- Uptrace — [OpenTelemetry Sampling: head-based and tail-based](https://uptrace.dev/opentelemetry/sampling)
- Uptrace — [OpenTelemetry Trace Context Propagation (Python)](https://uptrace.dev/get/opentelemetry-python/propagation)
- structlog — [Processors](https://www.structlog.org/en/stable/processors.html)
- structlog — [Standard Library Logging](https://www.structlog.org/en/stable/standard-library.html)

---

**End of research report.** Architect proceeds in stage 2; researcher
remains alive for clarifying-question SendMessage from Pack Chat or
the architect.
