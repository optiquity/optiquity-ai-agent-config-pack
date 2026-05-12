# AUDIT-BD-032 — Auditor observability infrastructure vs. configuration boundary

**Verdict:** (b) Findings — fix-follow recommended pre-launch.

The architecture/ops boundary for observability is *conceptually* clean
("does the wiring exist?" vs. "is it configured correctly for the
deployment target?") but the current spec does not give the two
subagents enough concrete examples to file the same finding the same
way without coordinating. Two ambiguities are large enough to be
worth tightening before v11.0 ships, and one trinity gap should be
closed at the same time. The BD itself stays Open with its
PACK-FEEDBACK Q1 blocker intact — the *real* validation still
requires first-real-audit data — but a small spec refinement now
will reduce the chance of a confusing first audit.

---

## Spec assessment

### audit-methodology rule 21 (auditor-ops scope)

Rule 21 reads (paraphrased to highlight the observability sentence):

> auditor-ops … covers … **observability configuration** (logging
> output format, metrics endpoints, tracing exporter setup). Always
> runs — every project deploys somewhere.

Counterpart in rule 15 (auditor-architecture scope):

> auditor-architecture … observability infrastructure completeness
> (are logs/metrics/traces wired up at the right layers?).

Both subagent files restate the contrast verbatim:

- `project-template/.claude/agents/auditor-architecture.md`,
  `## Scope` / "Observability infrastructure" bullet — "This is about
  whether the wiring *exists*, not whether it is configured correctly
  for deployment (that is `auditor-ops`'s scope per rule 21)."
- `project-template/.claude/agents/auditor-ops.md`, `## Scope` /
  "Observability wiring" bullet — "Whether the wiring exists at all
  belongs to `auditor-architecture`; whether it is configured
  correctly for deployment is yours."

The contrast is pleasingly symmetric, but it relies entirely on a
single distinction — "exists" vs. "configured" — and never names a
worked example on either side.

### File-scope agreement

Rule 26 (auditor-architecture file scope) is "source files in the
project's module roots (`Sources/`, `server/src/`, or equivalent)."
Rule 32 (auditor-ops file scope) is deployment manifests, signing
files, configuration files, observability *config* files
(`**/logging.*`, OpenTelemetry collector configs, metrics exporter
configs), and CI workflow files. The two scopes do not overlap on
file paths.

This is the spec's strongest leg. The boundary is enforced
geographically — auditor-architecture cannot read the OTel collector
YAML, and auditor-ops cannot read the Swift `Logger` extension. So
even if the rule prose is fuzzy, the *findings* will tend to land in
the right cluster simply because the file path determines the
cluster.

### Skill loading

PLATFORM-SKILLS.md, "auditor-architecture" entry: loads
`apple-architecture-core`, `ios-architecture`, `macos-architecture`,
`python-architecture` — and observability *infrastructure* rules
"live inside these platform architecture skills." PLATFORM-SKILLS.md,
"auditor-ops" entry: loads `deployment-apple`, `deployment-python`,
which "cover the platform-specific deployment configuration rules and
observability *configuration*."

This is consistent with rule 21 / rule 15 and with the file-scope
rules. Architecture audits the source files using the architecture
skills (which contain "is the logger abstraction at the boundary?"
rules). Ops audits the deployment/config files using the deployment
skills (which contain "is the OTel exporter wired in the prod
config?" rules).

---

## Pre-emptive ambiguities

### Ambiguity 1 — code that *configures* observability at runtime

Many real services configure observability with Swift/Python *code*,
not YAML — e.g. a `bootstrap()` function that constructs an OTLP
exporter, sets the resource attributes, and installs a tracer
provider. The file path is in `Sources/` or `server/src/` (so the
file scope says auditor-architecture), but the *content* is "is the
exporter configured correctly for this deployment target?" (so the
rule wording says auditor-ops).

Concrete example: `server/src/observability/setup.py` containing

```python
def configure_tracing(env: str) -> None:
    exporter = OTLPSpanExporter(endpoint=os.environ["OTEL_ENDPOINT"])
    provider = TracerProvider(resource=Resource.create({"service.name": "ot"}))
    provider.add_span_processor(BatchSpanProcessor(exporter))
    trace.set_tracer_provider(provider)
```

A "missing `service.name` resource attribute" finding here is a
configuration-correctness concern (auditor-ops territory by rule
prose) but lives in a file that is in auditor-architecture's scope by
rule 26 / 32. Without explicit guidance, two subagents may either
both file it or neither will, and the consolidated report's
ownership-precedence step (rules 33–39) has no rule that resolves
"observability code in source vs. observability config in YAML."

### Ambiguity 2 — "wiring exists" can be tested two different ways

"Does the project have a logger abstraction at the boundary?"
(auditor-architecture) is a *static structural* question — does a
`Logger` protocol exist, do services depend on it, etc. But "does
the deployment install a logger at startup?" is *also* a wiring
question, and lives in the runtime bootstrap code (same file class
as Ambiguity 1). The current spec does not distinguish "wiring
exists in *types*" from "wiring exists in *runtime composition*."

A real audit will trip over this when a project has the Logger
protocol perfectly defined (auditor-architecture: pass) but never
calls `LoggerFactory.install()` at startup, so production runs with
the no-op default (clearly a finding, but neither cluster's rule
text claims it cleanly).

### Ambiguity 3 — `auditor-security` overlap on log content

Both auditor-architecture (logger abstraction at the boundary) and
auditor-ops (logging output format) touch logging. Neither rule
mentions the third related concern — *what gets written to the log*
(PII, secrets, tokens). Rule 33 "Security concern wins" suggests
auditor-security would own a "credentials in log output" finding,
but the spec does not say so. A first audit may file the same
finding three times.

This is small — the precedence rule does eventually attribute it to
security — but a single sentence in rule 21 acknowledging it would
make consolidation cleaner.

### Ambiguity 4 — trinity drift on rule numbering references

The Codex auditor-architecture file (`auditor-architecture.toml`,
"Scope" line) and auditor-ops file (`auditor-ops.toml`, "Scope"
line) reference `audit-methodology rule 15` and `rule 21`
respectively — same as the Claude/Gemini siblings. Spot-check is
clean. No trinity action needed for the rule references themselves.

---

## Recommended tightenings

These are small, additive edits. They do not change cluster
boundaries; they make the existing boundary *operationally*
unambiguous. Defer them to a fix-follow BD that lands before v11.0
ships if there is appetite, or roll them into BD-032 itself with
the understanding that the BD's real-world blocker remains
independently open.

### Edit 1 — add a worked example to rule 21

`project-template/skills/audit-methodology/SKILL.md`, rule 21.
Append to the rule body:

> **Boundary clarification.** Observability *code* that lives in
> source files (e.g., `Sources/Observability/Bootstrap.swift`,
> `server/src/observability/setup.py`) belongs to
> auditor-architecture if the finding is structural ("the
> `Logger` protocol is the wrong shape", "`configure_tracing`
> is not wired into the app entry point"). It belongs to
> auditor-ops if the finding is about deployment-target
> correctness ("the OTLP endpoint is hardcoded", "the resource
> `service.name` is missing for cloud deployment", "the
> exporter is not installed for the prod environment"). When
> uncertain, file under auditor-ops — operational findings
> almost always have a deployment-shaped fix.

### Edit 2 — mirror the clarification into both subagent files

Trinity-edit the same boundary clarification into:

- `project-template/.claude/agents/auditor-architecture.md` →
  observability bullet
- `project-template/.codex/agents/auditor-architecture.toml` →
  observability bullet
- `project-template/.gemini/agents/auditor-architecture.md` →
  observability bullet
- `project-template/.claude/agents/auditor-ops.md` →
  observability bullet
- `project-template/.codex/agents/auditor-ops.toml` → observability
  bullet
- `project-template/.gemini/agents/auditor-ops.md` → observability
  bullet

Wording (single sentence):

> Source-file observability *code* that configures the runtime
> for a deployment target (endpoint URLs, resource attributes,
> exporter installation gated on environment) is the auditor-ops
> bullet — the file path notwithstanding.

### Edit 3 — name PII / secret-in-log overlap explicitly

`project-template/skills/audit-methodology/SKILL.md`, rule 21,
append a single sentence:

> Findings about *log content* (credentials, tokens, PII in log
> messages) belong to auditor-security per rule 33; auditor-ops
> may surface them as deployment-config-shaped concerns and
> annotate `(also detected by: security)` per rule 33.

This is already implied by rules 21 + 33 read together, but stating
it inline avoids a new audit re-deriving it.

---

## Trinity check

| File | Claude | Codex | Gemini |
|---|---|---|---|
| auditor-architecture | observability bullet present, refers to rule 21 | observability bullet present, refers to rule 21 | observability bullet present (per diff) |
| auditor-ops | observability bullet present, refers to architecture | observability bullet present, refers to architecture | observability bullet present (per diff) |

Trinity is in agreement on the *current* wording. The Edit 2
recommendation above must be applied across all three CLI variants in
the same commit.

---

## Why the BD stays Open

The BD's blocker — "First v9 project with cloud-deployed
observability runs a full audit (PACK-FEEDBACK.md Q1)" — measures a
different thing: whether the boundary holds *under load* on real
observability code (OpenTelemetry, structured logging, distributed
tracing across language boundaries). The pre-emptive tightenings
above only address the *conceptual* sharpness of the rule. Even
after they ship, the BD remains the right tracking entry for
"validate against real audit data" and should remain Open until that
data arrives.

If the recommended tightenings are accepted, log a fix-follow note
in BD-032's Context block ("v11.0 added boundary-clarification
sentences in rules and subagent files; real-world validation still
pending") so the post-launch audit has the right baseline.
