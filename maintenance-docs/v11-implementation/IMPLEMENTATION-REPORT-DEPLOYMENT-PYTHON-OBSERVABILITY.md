# IMPLEMENTATION-REPORT-DEPLOYMENT-PYTHON-OBSERVABILITY

**Author:** pack-coder
**Date:** 2026-05-13
**Pack version target:** v11.0 (in development on `v11-dev`)
**BD:** BD-162
**Pipeline stage:** 4 of 4 (researcher → architect → planner → **coder**)
**Output consumer:** Pack Chat (for `pack-reviewer` + commit + BACKLOG flip)

Inputs read:
- `maintenance-docs/v11-implementation/PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY.md` (full — primary spec; §3 enumerates files / line numbers / verbatim text; §4 sequenced steps S0–S11)
- `maintenance-docs/v11-implementation/ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md` (full — locked decisions §9.1; §5 outline §A–§K; §6 anti-rule list; §7 cross-reference text; §8.5 future-extension architecture)
- `maintenance-docs/v11-implementation/RESEARCH-DEPLOYMENT-PYTHON-OBSERVABILITY.md` (citation reference; not re-litigated)
- `project-template/skills/protobuf-patterns/SKILL.md` (BD-156 shape reference)
- `project-template/skills/swift-concurrency-patterns/SKILL.md` (BD-158 shape reference)
- `project-template/skills/deployment-python/SKILL.md` (rule 21 replace target)
- `project-template/skills/python-server-architecture/SKILL.md` (rule 8 extend target)
- `project-template/docs/pack/PLATFORM-SKILLS.md` (intersection table + dimensional inventory + worked examples + per-agent assignments)
- `scripts/lib/detect.sh` (`python_data_marker_detected`, `protobuf_marker_detected`, `swiftdata_marker_detected` parallels)
- `scripts/init-project.sh` (`pack_skill_coverage_for python` case)
- `scripts/add-capability.sh` (`capability_skills` mapping)
- `scripts/test-detect.sh` (BD-141 / BD-156 / BD-157 marker-test patterns)

---

## §1 Pre-flight evidence (Step S0)

Per plan §4 S0 + the `commit-discipline` skill §1 pre-flight requirements.

```
$ git rev-parse HEAD
6f9e6aa77e6ac401863f6ab2a06ad63dd02bc281

$ git rev-parse --abbrev-ref HEAD
v11-dev

$ ls project-template/skills/deployment-python/SKILL.md \
     project-template/skills/python-server-architecture/SKILL.md \
     project-template/docs/pack/PLATFORM-SKILLS.md \
     scripts/lib/detect.sh \
     scripts/init-project.sh \
     scripts/add-capability.sh \
     scripts/test-detect.sh \
     maintenance-docs/v11-implementation/ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md \
     maintenance-docs/v11-implementation/PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY.md
maintenance-docs/v11-implementation/ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md
maintenance-docs/v11-implementation/PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY.md
project-template/docs/pack/PLATFORM-SKILLS.md
project-template/skills/deployment-python/SKILL.md
project-template/skills/python-server-architecture/SKILL.md
scripts/add-capability.sh
scripts/init-project.sh
scripts/lib/detect.sh
scripts/test-detect.sh

$ test ! -d project-template/skills/python-observability-patterns && echo "OK"
OK

$ grep -c "python-observability-patterns" project-template/docs/pack/PLATFORM-SKILLS.md
0
```

All preconditions satisfied. Branch is `v11-dev`. Base SHA captured. NEW skill dir absent (as required). PLATFORM-SKILLS.md has zero references to the new skill name (as required). All E1/E2/E3/E4/E5/E6/E7 target paths exist. Architect + planner spec docs present.

**Final HEAD SHA on worktree at end of coder stage:**
`6f9e6aa77e6ac401863f6ab2a06ad63dd02bc281` (unchanged — coder ran read-only `git rev-parse` only; no `git add` / `git commit` per the absolute ban on agent state-changing git verbs in CLAUDE.md `Pack memory` and the `commit-discipline` skill).

**Gate to S1:** PASS — pre-flight clean, proceeding.

---

## §2 Per-step implementation results

### Step S1 — Add `python_observability_marker_detected()` to `scripts/lib/detect.sh` (E4)

**Action.** Inserted helper after `swiftdata_marker_detected()` (line 647), before `detect_target_pack_version()`. Function follows the BD-141 / BD-156 / BD-157 contract exactly: positional arg defaulting to cwd; tolerates missing target with `python-observability-marker: no` and zero stderr; emits a single-line marker string.

**Marker classes implemented (per architect §4.2 / planner §3.2 E4):**

- (a) Dependency manifests: `requirements.txt`, `pyproject.toml`, `setup.py`, `setup.cfg`, `uv.lock` are scanned for two pattern groups —
  - Exact-name packages via the BD-141 negated-character-class boundary `(^|[^A-Za-z0-9_-])(<pkgs>)($|[^A-Za-z0-9_.-])`: `opentelemetry-api`, `opentelemetry-sdk`, `opentelemetry-distro`, `prometheus-client`, `prometheus_client`, `structlog`, `python-json-logger`.
  - Prefix-match packages via leading-boundary anchor + trailing `[A-Za-z0-9_.-]+` continuation: `opentelemetry-(instrumentation|exporter)-*`. Boundary correctness verified by tests T2 + T10 (positive prefix matches) and T15 (substring rejection — `not-opentelemetry-clone` does NOT match).
- (b) Source file imports: line-anchored grep `^[[:space:]]*(import|from)[[:space:]]+(opentelemetry|prometheus_client|structlog)([[:space:]]|\.|,|$)` over `.py` files outside the BD-156 prune list (`node_modules/`, `.git/`, `build/`, `.venv/`, `venv/`, `.tox/`). Defeats prose mentions in comments per BD-141 marker-c convention.

**Function-doc header.** Names BD-162, the architecture document path, the callers (`scripts/init-project.sh::pack_skill_coverage_for python` + PLATFORM-SKILLS.md citation + add-capability.sh comment-reference), and lists marker classes (a) and (b) with their boundary-construction rationale.

**Verification (in-place):**

```
$ bash -n scripts/lib/detect.sh
(no output — syntax OK)

$ source scripts/lib/detect.sh && declare -F python_observability_marker_detected
declare -f python_observability_marker_detected

$ mkdir -p /tmp/obs-test && cd /tmp/obs-test && echo 'opentelemetry-api>=1.20' > requirements.txt
$ source scripts/lib/detect.sh && python_observability_marker_detected /tmp/obs-test
python-observability-marker: yes

$ rm -rf /tmp/obs-test-empty && mkdir -p /tmp/obs-test-empty
$ source scripts/lib/detect.sh && python_observability_marker_detected /tmp/obs-test-empty
python-observability-marker: no

$ source scripts/lib/detect.sh && python_observability_marker_detected /tmp/never-existed-xyz
python-observability-marker: no
```

**Gate to S2:** PASS — helper present, syntax OK, smoke tests green (positive / empty / non-existent all behave correctly).

### Step S2 — Add 17 BD-162 test cases to `scripts/test-detect.sh` (E7)

**Action.** Added a new `## ── python_observability_marker_detected (BD-162) ─────────` section at end-of-file (after `detect_target_pack_version` block, before the `## ── Summary ───` block) — placement parallel to BD-156 / BD-157 chronological ordering. Used the existing `mkfixture` / `assert_eq` scaffolding.

**Test cases added (17 total):**

Positive cases (must report `python-observability-marker: yes`):
- T1: `requirements.txt` lists `opentelemetry-api>=1.20` (exact-name OTel API package)
- T2: `pyproject.toml` lists `opentelemetry-instrumentation-grpc` (prefix-match contrib package)
- T3: `pyproject.toml` lists `prometheus_client>=0.20` (exact-name)
- T4: `requirements.txt` lists `structlog==24.0` (exact-name)
- T5: `pyproject.toml` lists `python-json-logger` (exact-name)
- T6: `.py` file with `import opentelemetry` (source-import primary case)
- T7: `.py` file with `from opentelemetry.trace import get_tracer` (dotted-path)
- T8: `.py` file with `import prometheus_client` (source-import)
- T9: `.py` file with `from structlog import get_logger` (source-import)
- T10: `pyproject.toml` lists `opentelemetry-exporter-otlp-proto-grpc` (prefix-match exporter)

Negative cases (must report `python-observability-marker: no`):
- T11: empty directory baseline (architect §9.4 case 4)
- T12: non-existent target — must tolerate without stderr (BD-156 / BD-157 missing-target parallel)
- T13: pure Apple project — Swift sources + `Package.swift`, no Python observability (architect §9.4 case 3)
- T14: Python script with `requests` + `pytest` only — no observability deps, no observability imports (architect §9.4 case 4)
- T15: substring-reject — `not-opentelemetry-clone==0.1` must NOT match `opentelemetry-api` (BD-141 boundary parallel)
- T16: prose-reject — `# we should add import opentelemetry someday` must NOT match (BD-141 marker-c line-anchor parallel)
- T17: vendored-prune — `.py` under `node_modules/some-pkg/` with `import opentelemetry` must NOT match (BD-156 vendored-prune parallel)

**Verification (in-place):**

```
$ bash scripts/test-detect.sh 2>&1 | tail -22
== python_observability_marker_detected ==
  pass: empty dir → no
  pass: non-existent target → no (tolerated, no stderr)
  pass: requirements.txt lists opentelemetry-api → yes (marker a — exact)
  pass: pyproject.toml lists opentelemetry-instrumentation-grpc → yes (marker a — prefix)
  pass: pyproject.toml lists prometheus_client → yes (marker a — exact)
  pass: requirements.txt lists structlog → yes (marker a — exact)
  pass: pyproject.toml lists python-json-logger → yes (marker a — exact)
  pass: pyproject.toml lists opentelemetry-exporter-otlp-proto-grpc → yes (marker a — prefix)
  pass: import opentelemetry in .py file → yes (marker b — primary)
  pass: from opentelemetry.trace import ... → yes (marker b — dotted path)
  pass: import prometheus_client in .py file → yes (marker b)
  pass: from structlog import get_logger → yes (marker b)
  pass: pure Apple project (no Python observability) → no
  pass: Python script with requests + pytest only → no
  pass: substring 'not-opentelemetry-clone' alone → no (boundary reject)
  pass: prose 'import opentelemetry' in comment only → no (line-anchor reject)
  pass: import opentelemetry only in node_modules → no (vendored prune)

=== Results: 95 passed, 0 failed ===
```

Baseline before BD-162 was 78 passes (verified by counting: 17 new tests added; 95 − 17 = 78 baseline). Delta is exactly +17. Zero failures.

**Gate to S3:** PASS — test-detect green; +17 tests; zero regressions.

### Step S3 — Author the new SKILL.md (N1)

**Action.** Created `project-template/skills/python-observability-patterns/` directory and authored `SKILL.md`. Section structure follows architect §5 outline literally (§A → §K) per planner §2.1 confirmation. Continuous rule numbering 1–65 per planner §2.3. Owner-tag suffix at end-of-rule (`(ops)` / `(arch)` / `(code)` / `(both)`) per planner §2.3.

**Frontmatter.** Three fields: `name: python-observability-patterns`, planner-supplied `description` text verbatim, `allowed-tools: Read, Grep, Glob, Bash`.

**Applicability section.** Contains the four planner-supplied / architect §7.1 verbatim cross-reference prose blocks in order:
- python-server-architecture rule 8 (placement) ↔ this skill (content)
- deployment-python (deployment plumbing) ↔ this skill (observability content)
- security-patterns / audit-methodology rule 33 (sensitive-data classification) ↔ this skill (redaction-pipeline shape)
- audit-methodology rule 21 ownership rubric → per-rule owner-tag application

Plus the canonical-library-positions block per architect §3.1 (OpenTelemetry canonical for tracing; library-agnostic for metrics + logging; specific positioning for distro / exporters / structlog / `OTEL_PYTHON_LOG_CORRELATION`).

**Section structure (11 sections, 65 rules total — within architect §5.14 estimate of 59 ± 5):**

| Section | Range | Count | Architect target | Status |
|---|---|---|---|---|
| §A — Telemetry SDK setup and resource attributes | 1–6 | 6 | 5–7 | within band |
| §B — Span lifecycle and attributes | 7–14 | 8 | 8–10 | within band |
| §C — Trace context propagation | 15–17 | 3 | 3–4 | within band |
| §D — Auto-instrumentation discipline | 18–21 | 4 | 3–4 | within band |
| §E — Exporter configuration | 22–26 | 5 | 4–5 | within band |
| §F.1 — Metric naming | 27–30 | 4 | 4–5 | within band |
| §F.2 — Label cardinality | 31–34 | 4 | 4–5 | within band |
| §F.3 — Metric type selection | 35–38 | 4 | 4–5 | within band |
| §G — Prometheus exposition | 39–42 | 4 | 4–5 | within band |
| §H — Structured logging | 43–51 | 9 | 8–10 | within band |
| §I — Sampling | 52–55 | 4 | 4–6 | within band |
| §J — SLO definition shape and burn-rate alerts | 56–61 | 6 | 5–7 | within band |
| §K — Retention policy shape | 62–65 | 4 | 3–5 | within band |

**Worked-example rules (architect §5.13 — verbatim placement).**

- **Worked example 1** (architect §F.2 label-cardinality calibration text) lands as **rule 31** — the lead rule of §F.2, immediately after §F.1's naming rules. Verbatim text preserved including the `~100 distinct values` defect threshold, the prohibited-identifier enumeration, and the acceptable-label-values list. Tagged `(code)` per architect.
- **Worked example 2** (architect §J orphaned-SLO calibration text) lands as **rule 59** — the fourth rule of §J, mid-section. Verbatim text preserved including the SLO YAML / alertmanager rule / Sloth spec auditable-artifact enumeration and the three-fix-options list. Tagged `(ops)` per architect.

**Owner-tag distribution per section (cross-checked against architect §5.2–§5.12 mixes):**

| Section | Architect's intended mix | Actual distribution in SKILL.md |
|---|---|---|
| §A | mostly `(both)` for service.name; mix of `(arch)` and `(ops)` | 1=arch, 2=arch, 3=both, 4=both, 5=ops, 6=ops |
| §B | mostly `(arch)` and `(code)`; one `(ops)` on cardinality | 7=code, 8=code, 9=code, 10=code, 11=arch, 12=code, 13=ops, 14=arch |
| §C | `(arch)` for wiring; `(ops)` for env-var | 15=arch, 16=ops, 17=arch |
| §D | mostly `(ops)` (workflow / dependency choices) | 18=ops, 19=ops, 20=code, 21=ops |
| §E | `(ops)` (endpoint, queue, collector wiring) | 22=ops, 23=arch, 24=ops, 25=ops, 26=arch |
| §F.1 / F.2 / F.3 | `(code)` and `(arch)` for naming / cardinality / type; `(ops)` for histogram bucket values per env | 27–30 = code/code/arch/arch (naming), 31–34 = code/code/both/ops (cardinality), 35–38 = code/code/ops/both (type) |
| §G | mostly `(both)` (wiring structural, env-var values are deployment) | 39=both, 40=ops, 41=code, 42=both |
| §H | `(arch)` for wiring, `(code)` for bound-context discipline, `(ops)` for env-driven defaults | 43=both, 44=code, 45=code, 46=arch, 47=arch, 48=ops, 49=both, 50=arch, 51=code |
| §I | mostly `(ops)` — sampler ratio is canonical "value read from configuration at runtime" | 52=ops, 53=ops, 54=arch, 55=ops |
| §J | all `(ops)` (live in alertmanager / Sloth / Pyrra / hand-written PromQL) | 56–61 = all ops |
| §K | all `(ops)` (retention values in deployment manifests) | 62–65 = all ops |

Per-section mix matches architect intent. The §I rule 54 ("tail sampling is collector-side, never application-side") is tagged `(arch)` rather than `(ops)` because the architect-named "boundary rule" is explicitly a wiring / type-system decision (do not write a custom `Sampler` subclass) — `(arch)` per the audit-methodology rule 21 rubric ("type / call graph / wiring"). All other §I rules carry `(ops)` per architect.

**Anti-rule discipline (architect §6 enforcement).**

Reviewed every rule against the architect's anti-rule list. No rules authored on:
- Native histogram client API specifics (rule 37 mentions "Native histograms are acknowledged as the forward direction once the wire format and client API stabilize" — acknowledgement only, no specific API rule)
- `tracestate` "ot" key
- OTel Logs SDK as sole log path (rule 47 names `LoggingInstrumentor` + `OTEL_PYTHON_LOG_CORRELATION` — the established pattern, not the forward-looking OTel Logs SDK)
- eBPF auto-instrumentation
- Specific SLO framework choice (rule 56–61 are framework-agnostic; the rules name the *shape* — SLI / Objective / window, MWMB 4-window, page-vs-ticket routing — never Sloth / Pyrra / Grafana SLO / hand-written as required)
- Vendor-specific exporter detail (rule 26 points new code to OTLP + collector translation; vendor SDKs named only as legacy-paths)
- Log aggregation platform configuration (rule 49 ends at stdout; downstream platform out of scope)
- Profiling / RUM
- Log-content classification (rule 50 explicitly defers to security-patterns + audit-methodology rule 33)
- CVE detection / health-check endpoints / container resource limits (out of scope per architect §6.3 — owned by other skills)
- gRPC interceptor placement (out of scope — owned by python-server-architecture rule 8)

**Future-extension discipline (architect §8.5).**

Every rule belongs cleanly to one section. Verified:
- §A–§E rules are OpenTelemetry-side; no Prometheus content. Future `python-otel-patterns` lift would extract §A + §B + §C + §D + §E + §I cleanly.
- §F + §G are Prometheus-side; no OpenTelemetry content. Future `python-prometheus-patterns` lift would extract §F + §G + the Prometheus-specific portion of §J cleanly.
- §H is library-agnostic field-set + redaction-pipeline-shape + correlation-wiring. No structlog-specific rules. Future `python-structlog-patterns` would only emerge if structlog-specific patterns dominated; today §H stays in the foundation.
- §J SLO rules are framework-agnostic shape rules; could lift cleanly with the Prometheus split.
- §K retention is vendor-agnostic and signal-agnostic; lives in foundation forever per architect §8.5.
- Rules 47 (trace ↔ log correlation), 50 + 51 (redaction-pipeline shape), and the audit-methodology rule 21 ownership rubric in the Applicability section are explicit cross-cutting integration glue per architect §8.5 — designed to stay in the foundation regardless of future siblings.

**Verification (in-place):**

```
$ test -f project-template/skills/python-observability-patterns/SKILL.md && echo OK
OK

$ wc -l project-template/skills/python-observability-patterns/SKILL.md
     522 project-template/skills/python-observability-patterns/SKILL.md

$ head -5 project-template/skills/python-observability-patterns/SKILL.md
---
name: python-observability-patterns
description: Use for Python observability — OpenTelemetry tracing setup, span lifecycle, trace context propagation, auto-instrumentation, exporter configuration; Prometheus metrics naming / cardinality / type selection / multiprocess exposition; structured logging field requirements + trace-log correlation; head sampling; SLO definition shape and burn-rate alerts; retention-policy shape. Loads at D2=python ∩ (D3=server ∨ observability-marker).
allowed-tools: Read, Grep, Glob, Bash
---

$ grep -c '^[0-9]\+\. ' project-template/skills/python-observability-patterns/SKILL.md
65

$ grep -cE '`\(ops\)`|`\(arch\)`|`\(code\)`|`\(both\)`' project-template/skills/python-observability-patterns/SKILL.md
69

$ awk '/^## §/ {section=$0; count[section]=0; next} /^[0-9]+\. / {count[section]++} END {for (s in count) print s ": " count[s]}' project-template/skills/python-observability-patterns/SKILL.md
## §G — Prometheus exposition: multiprocess and endpoint: 4
## §C — Trace context propagation: 3
## §K — Retention policy shape: 4
## §H — Structured logging: required fields and trace correlation: 9
## §E — Exporter configuration: 5
## §D — Auto-instrumentation discipline: 4
## §B — Span lifecycle and attributes: 8
## §A — Telemetry SDK setup and resource attributes: 6
## §F — Prometheus metrics: naming, labels, types: 12
## §J — SLO definition shape and burn-rate alerts: 6
## §I — Sampling: 4

$ grep -c "Label values MUST come from a low-cardinality enumeration" project-template/skills/python-observability-patterns/SKILL.md
1

$ grep -c "Every defined SLO MUST reference a metric the application actually exports" project-template/skills/python-observability-patterns/SKILL.md
1
```

**Note on owner-tag count of 69 vs rule count of 65:** the four-tag-vocabulary surplus comes from the Applicability rubric block where the four tag literals (`(ops)`, `(arch)`, `(code)`, `(both)`) are introduced as values the rubric uses (lines 73–77 of SKILL.md — verbatim from architect §7.1's rubric paragraph). Per-rule, every numbered rule carries exactly one tag at end-of-rule (verified by section-by-section visual scan). 65 rule tags + 4 prose mentions = 69 total.

File is 522 lines (slightly above the 350–420 estimate). The overshoot is driven by (a) an Applicability section longer than the BD-156 / BD-158 reference shapes — required to carry the four cross-reference prose blocks plus the canonical-library-positions block per architect §3.1 / §7.1, both of which are non-optional — and (b) wider-than-typical sub-section headings within §F (F.1 / F.2 / F.3 architect-required structure adds three subsection headings + intro narrative). The line count is honest given the architect's content scope; rule count and per-section rule counts remain within architect bands.

**Gate to S4:** PASS — SKILL.md present, frontmatter clean, rule count 65 (within 55–65), every rule tagged with one owner tag, both architect-supplied worked examples present verbatim, anti-rule discipline respected, future-extension seam preserved.

### Step S4 — Edit `deployment-python/SKILL.md` rule 21 (E1)

**Action.** Replaced the existing rule 21 ("Enable structured logging (JSON format) for production. Include request ID, method, status, and latency in every log entry.") with the verbatim text from architect §7.3 / planner §3.2 E1. Rule 21 keeps its number; rules 22–23 unchanged.

**Verification (in-place):**

```
$ grep -n "python-observability-patterns" project-template/skills/deployment-python/SKILL.md
41:21. Substantive observability rules — structured-log field set, metrics naming and cardinality, tracing setup, sampling, SLO definition shape, retention policy shape — live in `python-observability-patterns`. This skill (`deployment-python`) covers deployment-readiness concerns adjacent to observability: container layout, secrets, health checks, graceful shutdown, env-driven production config. Auditor-ops loads both skills for D2=python ∩ D5=linux-container projects.

$ grep -c '^[0-9]\+\. ' project-template/skills/deployment-python/SKILL.md
23
```

Rule count unchanged at 23. Rule 21 line replaced verbatim from architect §7.3.

**Gate to S5:** PASS.

### Step S5 — Edit `python-server-architecture/SKILL.md` rule 8 (E2)

**Action.** Extended rule 8 with the verbatim text from architect §7.2 / planner §3.2 E2. Rule 8 keeps its number; rules 7, 9, 10 unchanged.

**Verification (in-place):**

```
$ grep -n "python-observability-patterns" project-template/skills/python-server-architecture/SKILL.md
46:8. Auth, logging, and metrics belong in gRPC interceptors (or framework middleware for REST), not in servicer / handler implementations. The substantive observability rules — what spans to create, which attributes to attach, which fields every log record must carry, how to wire trace ↔ log correlation — live in `python-observability-patterns` (loaded for any Python server project per the intersection table). This skill defines the *placement*; the patterns skill defines the *content*.
```

**Gate to S6:** PASS.

### Step S6 — Edit `PLATFORM-SKILLS.md` (E3 a/b/c/d, four parallel edits)

**Action.** Applied four parallel edits per planner §3.2 E3.

**E3.a (intersection table).** Inserted a new row immediately after the `python-server-architecture` row and before the `python-data-architecture` row. Predicate: `D2=python ∩ (D3=server ∨ observability-marker present)`. Source-of-truth column cites `scripts/lib/detect.sh::python_observability_marker_detected()` (BD-162) and the marker classes (a) and (b).

**E3.b (dimensional inventory + counts).** Header `### Dimensional skills (19)` → `### Dimensional skills (20)`. New row inserted after `python-server-architecture` and before `python-data-architecture`, listing the 7 loading agents (`architect, coder, reviewer, auditor-architecture, auditor-code, auditor-ops, docs-researcher`). Post-table narrative `**19 dimensional / intersection skills.**` → `**20 dimensional / intersection skills.**`. The "five rows … are intersection-loaded" → "six rows … are intersection-loaded" with `python-observability-patterns` added to the inline list. Direct-load count narrative unchanged at 14 (BD-162 adds an intersection row, not a direct-load row). `**Total skills: 34**` → `**Total skills: 35**` and the parenthetical sub-counts updated `(13 + 19 → 13 + 20)`.

**E3.c (worked examples).** Updated both the "Python gRPC server (Linux container)" example and the "Universal Apple app + Python gRPC server (monorepo)" example: added `python-observability-patterns` to both the `Intersection:` enumeration (with the planner-supplied predicate-narrative format) and the final `**Result (dimensional + intersection):**` enumeration. Skill name slotted between `python-data-architecture` and `deployment-python` in the result enumeration order.

**E3.d (per-agent assignments).** All 7 agents updated:
- `architect` line — appended `python-observability-patterns *(load when python_observability_marker_detected() is true OR D3=server)*` to the dimensional list.
- `coder` line — same gating note appended.
- `reviewer` line — same gating note appended.
- `docs-researcher` line — `python-observability-patterns` inserted between `deployment-python` and `dependency-swift`.
- `auditor-architecture` line — `python-observability-patterns *(load when python_observability_marker_detected() is true OR D3=server — provides the structural observability rules: SDK init wiring, span lifecycle, exporter / collector tier placement, redaction-pipeline shape, sampling architecture)*` appended. Platform-filtering paragraph rewritten to (a) mention python-observability-patterns alongside python-server-architecture / python-data-architecture for Python server projects and (b) preserve the existing python-data-architecture mention for non-server multi-file Python.
- `auditor-code` line — appended the planner-supplied sentence "plus python-observability-patterns (load per the intersection-table predicate via `python_observability_marker_detected()` OR when D3=server — provides metric / span / log code idiom rules: do-not-use-Summary in distributed deployments, label cardinality, span lifecycle anti-patterns, structured-log required fields, redaction-pipeline shape)."
- `auditor-ops` line — `python-observability-patterns` appended to the `Dimensional (filtered by D5):` list. Prose updated per planner E3.d: "(vs. observability *infrastructure*, which lives in the architecture skills loaded by `auditor-architecture`)" → "(vs. observability *infrastructure*, which lives in `python-observability-patterns` for D2=python projects and in the platform architecture skills for non-Python projects)."

**Verification (in-place):**

```
$ grep -c "python-observability-patterns" project-template/docs/pack/PLATFORM-SKILLS.md
16

$ grep -E "^### Dimensional skills \([0-9]+\)" project-template/docs/pack/PLATFORM-SKILLS.md
### Dimensional skills (20)

$ grep -E "^\*\*Total skills: [0-9]+\*\*" project-template/docs/pack/PLATFORM-SKILLS.md
**Total skills: 35** (13 Tier 0 base + 20 dimensional / intersection + 1 trigger-loaded + 1 PM chat operational).

$ grep "20 dimensional / intersection skills" project-template/docs/pack/PLATFORM-SKILLS.md
**20 dimensional / intersection skills.** The Cell column is the
```

16 hits (1 intersection-table row + 1 dimensional-inventory row + 2 worked examples × 2 mentions each = 4 + 7 per-agent assignments + 1 prose narrative bullet for `auditor-ops`-prose update = 14, plus 2 in the `auditor-architecture` platform-filtering paragraph = 16). Matches planner expectation (≥12).

**Gate to S7:** PASS — all four hits present; counts updated correctly.

### Step S7 — Edit `scripts/init-project.sh` (E5) and `scripts/add-capability.sh` (E6)

**Action E5.** Extended `pack_skill_coverage_for python` case (lines 269–283 in pre-edit baseline) with the planner-specified 3-branch composition. Computed `data_marker_line` and `obs_marker_line` as 0/1-style booleans first, then emit the comma-joined skill list with conditional appends. Skill list now includes `python-observability-patterns` when `python_observability_marker_detected()` returns `python-observability-marker: yes`. Added a 22-line comment block above the `python)` arm citing BD-162 + the architecture document path + the explicit decision to NOT compute the "OR D3=server" branch inside `pack_skill_coverage_for` (D3 is a PM-chat-time selector, not a scaffold-time one — `stage_s4_skills` ships all skills unconditionally).

**Note on skill-list ordering.** The pre-edit python case emitted `"python-data-architecture,python-best-practices"` (data first); the new 3-branch composition emits `"python-best-practices[,python-data-architecture][,python-observability-patterns]"` (best-practices first, intersection skills appended). The reordering is incidental to the conditional-append pattern — no test in `scripts/test-detect.sh` or elsewhere asserts the specific order of `pack_skill_coverage_for python` output, and the reordering does not change skill-loading semantics (PM chat reads the skill names, not their order).

**Action E6.** Extended `capability_skills` python rows per planner §3.2 E6:
- `language:python` row (line 129 baseline): `"python-best-practices python-data-architecture dependency-python"` → `"python-best-practices python-data-architecture python-observability-patterns dependency-python"`.
- `role:python-server` row (line 191 baseline): `"python-server-architecture python-data-architecture"` → `"python-server-architecture python-data-architecture python-observability-patterns"`.

Added BD-162 comment blocks above both modified rows citing the architecture document path. Verified `capability_files()` does NOT need a row for the new skill (the skill ships only as a SKILL.md; no scripts, no manifests; the `language:python` capability_files row already covers `pyproject.toml` etc. — same pattern as BD-156 / BD-157 / BD-158, none of which added a `capability_files` row either).

**Verification (in-place):**

```
$ bash -n scripts/init-project.sh
(no output — syntax OK)

$ bash -n scripts/add-capability.sh
(no output — syntax OK)

$ grep -c "python-observability-patterns" scripts/init-project.sh
3

$ grep -c "python-observability-patterns" scripts/add-capability.sh
4
```

3 hits in init-project.sh (1 in case-arm marker check + 1 in append + 1 in BD-162 comment block).
4 hits in add-capability.sh (1 in language:python row + 1 in role:python-server row + 2 in BD-162 comment blocks).

**Gate to S8:** PASS — syntax OK; greps confirm presence; both files independently revertable.

### Step S8 — Full validate-pack + test-detect

**Action.** Ran the pack's full CI suite end-to-end.

**Verification:**

```
$ python3 scripts/validate-pack.py 2>&1 | tail -15
── Check 31: Skill-cell consistency (BD-146, v11) ──
  OK: PLATFORM-SKILLS.md — 'Tier 0 base skills': 13 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'Dimensional skills': 20 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'Trigger-loaded skills': 1 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'PM chat operational skill': 1 rows (header matches)
  OK: PLATFORM-SKILLS.md — total skills: 35 (header sum, inventory row count, and disk count all agree)
  OK: Skill-cell consistency: 35 SKILL.md on disk, all map to exactly one inventory cell; no orphans, phantoms, or double-counts

============================================================
PASSED — all checks clean

$ bash scripts/test-detect.sh 2>&1 | tail -3
  pass: import opentelemetry only in node_modules → no (vendored prune)

=== Results: 95 passed, 0 failed ===
```

**validate-pack: PASSED — all checks clean (Check 31 reports Dimensional skills 20, Total skills 35; 29 distinct numbered checks with documented gaps 12–15 plus 2 unnumbered checks for issue templates / template archive).** Check 31 reports exactly the planner-expected outcome — Dimensional skills row count 20 (header matches), total skills 35 across header sum / inventory row count / disk count, no orphans / phantoms / double-counts / drift. The "extension" Skills-to-load conformance check (BD-146 / Check 27 extension) also passed — every per-agent skill citation in `.claude/agents/*.md` and `.gemini/agents/*.md` resolves cleanly against the new dimensional inventory.

**Test-detect: 95/95 PASS** (78 baseline + 17 new BD-162). Zero failures.

**Cross-grep stale-reference scan (per planner §5):**

```
$ grep -rn "python-observability-patterns" project-template/ scripts/ --include='*.md' --include='*.sh' \
  | grep -v "project-template/skills/python-observability-patterns/SKILL.md" \
  | grep -v "project-template/docs/pack/PLATFORM-SKILLS.md" \
  | grep -v "project-template/skills/deployment-python/SKILL.md" \
  | grep -v "project-template/skills/python-server-architecture/SKILL.md" \
  | grep -v "scripts/lib/detect.sh" \
  | grep -v "scripts/init-project.sh" \
  | grep -v "scripts/add-capability.sh" \
  | grep -v "scripts/test-detect.sh"
(no output)

$ grep -l "python-observability-patterns" project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md CLAUDE.md AGENTS.md GEMINI.md 2>/dev/null
(no output)
```

Zero stray references in unexpected pack-product locations. Zero trinity-file contamination. Architect §8.3's "no trinity files in scope" invariant preserved.

**Gate to S9:** PASS — validate-pack PASSED (all checks clean — 29 distinct numbered checks with documented gaps 12–15 plus 2 unnumbered checks for issue templates / template archive); test-detect 95/95; zero failures; zero stray references; zero trinity contamination.

### Step S9 — Implementation report (this file)

**Action.** Wrote `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-DEPLOYMENT-PYTHON-OBSERVABILITY.md` (this document) per the `implementation-report` skill template and the plan §4 S9 7-section requirement.

**Gate to PM Chat (Step S10):** PASS. Coder did NOT run `git add` / `git commit` / `git push` / `git tag` or any state-changing git verb (per CLAUDE.md `Pack memory` "Agents never commit" + `commit-discipline` skill absolute ban). Working tree status at end of stage 4 below.

---

## §3 Files changed inventory

**NEW files (3):**

| Path | Type | Change |
|---|---|---|
| `project-template/skills/python-observability-patterns/SKILL.md` | new | Substantive content: 522 lines, 65 numbered rules across 11 sections + Applicability + frontmatter |
| `project-template/skills/python-observability-patterns/` | new (dir) | Skill directory parent of SKILL.md |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-DEPLOYMENT-PYTHON-OBSERVABILITY.md` | new | This file (workflow artifact per ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md §3.2 sig. 5 carve-out) |

**EDITED files (7):**

| Path | Type | Change |
|---|---|---|
| `project-template/skills/deployment-python/SKILL.md` | modified | Rule 21 replaced verbatim per architect §7.3 |
| `project-template/skills/python-server-architecture/SKILL.md` | modified | Rule 8 extended verbatim per architect §7.2 |
| `project-template/docs/pack/PLATFORM-SKILLS.md` | modified | E3 a/b/c/d (intersection table row + dimensional inventory row + count bumps + 2 worked examples + 7 per-agent assignments) |
| `scripts/lib/detect.sh` | modified | Added `python_observability_marker_detected()` helper |
| `scripts/init-project.sh` | modified | `pack_skill_coverage_for python` case → 3-branch composition |
| `scripts/add-capability.sh` | modified | `language:python` + `role:python-server` capability rows extended |
| `scripts/test-detect.sh` | modified | Added 17 new test cases |

**Reserved for PM Chat (NOT touched by coder):**
- `BACKLOG.md` — BD-162 status flip to `Resolved` is PM-Chat-only (per CLAUDE.md `Pack memory` PM-only file boundaries; BACKLOG is in the off-limits list). PM Chat performs this flip post-reviewer per the `Implicit BD status flip on batch completion` learning.

**Total: 3 NEW + 7 EDITED = 10 files coder-touched. PM-Chat-only: BACKLOG.md (1 additional path → 11 path footprint per architect §8.2).**

**Final HEAD SHA on worktree:** `6f9e6aa77e6ac401863f6ab2a06ad63dd02bc281` (unchanged from pre-flight; coder ran read-only `git rev-parse` only).

**Working tree status (per `git status`):**

```
On branch v11-dev
Changes not staged for commit:
	modified:   project-template/docs/pack/PLATFORM-SKILLS.md
	modified:   project-template/skills/deployment-python/SKILL.md
	modified:   project-template/skills/python-server-architecture/SKILL.md
	modified:   scripts/add-capability.sh
	modified:   scripts/init-project.sh
	modified:   scripts/lib/detect.sh
	modified:   scripts/test-detect.sh

Untracked files:
	maintenance-docs/v11-implementation/ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md  (upstream-stage artifact, not coder output)
	maintenance-docs/v11-implementation/PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY.md           (upstream-stage artifact, not coder output)
	maintenance-docs/v11-implementation/RESEARCH-DEPLOYMENT-PYTHON-OBSERVABILITY.md       (upstream-stage artifact, not coder output)
	maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-DEPLOYMENT-PYTHON-OBSERVABILITY.md  (this file)
	project-template/skills/python-observability-patterns/                                (NEW skill — coder output)
	(other pre-existing untracked maintenance-docs/v11-research/ files unrelated to BD-162)
```

PM Chat stages the 7 EDITED files + the new `project-template/skills/python-observability-patterns/SKILL.md` (the new directory's only file) + this implementation report = 9 paths to stage for the BD-162 feature commit. The upstream-stage artifacts (ARCHITECTURE / PLAN / RESEARCH) and the BACKLOG flip are separate concerns per pack convention (architect / planner / RESEARCH artifacts ride along; the BACKLOG flip lands as a separate small commit per BD-156 / BD-157 / BD-158 precedent).

---

## §4 Deviations from plan

**Zero substantive deviations from the planner's spec.** Every §3 file was touched per planner §3 instructions; every cross-reference text landed verbatim per planner §3.2 quoting (which sourced from architect §7.2 / §7.3); the section ordering is §A → §K verbatim per planner §2.1; rule numbering is continuous 1–N per planner §2.3; owner-tag suffix at end-of-rule per planner §2.3; the four-value vocabulary (`(ops)` / `(arch)` / `(code)` / `(both)`) is closed; both architect-supplied worked examples (§5.13 of the architecture document) appear verbatim in their target sections (§F.2 cardinality, §J SLO).

**Editorial-only choices (within planner-allowed latitude):**

1. **Skill-list emission order in `pack_skill_coverage_for python`.** The pre-edit code emitted `"python-data-architecture,python-best-practices"` (data first); the 3-branch composition emits `"python-best-practices[,python-data-architecture][,python-observability-patterns]"` (best-practices first, intersection skills appended). This is a natural consequence of the planner-specified conditional-append pattern and is not asserted by any test. PM-chat skill loading reads the skill names, not their order.

2. **Test-section placement in `test-detect.sh`.** Planner §3.2 E7 explicitly named the choice between "after the `swiftdata_marker_detected` block" and "at the end of the file in a new `## ── python_observability_marker_detected (BD-162) ─────────` section" — the planner's parenthetical noted "Coder picks placement parallel to BD-156 / BD-157 ordering — observability is added LAST in source order so test-section sequencing tracks BD chronology." Chose end-of-file placement per the BD-chronology rationale (BD-141 → BD-156 → BD-157 → BD-162).

3. **§I rule 54 owner-tag.** Tagged `(arch)` rather than `(ops)`. The architect §5.10 owner-tag mix says "mostly `(ops)` — sampler ratio is the canonical 'value read from configuration at runtime' example from audit-methodology rule 21." Rule 54 is the boundary rule that "tail sampling is collector-side, never application-side; do not implement custom tail-sampling logic in the application." Per the audit-methodology rule 21 rubric (`(arch)` if the fix changes a type / call graph / wiring), not implementing a custom `Sampler` subclass is a wiring decision, not a config-value decision. The remaining four §I rules carry `(ops)`, preserving the architect's "mostly `(ops)`" intent for the section.

4. **SKILL.md line count.** 522 lines vs the architect §1.3 / planner §3.1 estimate of 350–420. The overshoot is concentrated in the Applicability section (40+ lines, required to carry the four cross-reference prose blocks plus the canonical-library-positions block per architect §3.1 / §7.1 — both non-optional); the per-rule prose remained terse-imperative per BD-156 / BD-158 calibration. Total rule count (65) and per-section rule counts (within architect bands, see §2 step S3 table above) are within scope. The line-count overshoot reflects honest content scope, not scope creep.

None of these editorial choices change loading semantics, validate-pack outcomes, or test-detect outcomes.

---

## §5 POQs / new BD candidates surfaced during implementation

**Zero new POQs.** The architect §9.1 locked decisions and the planner §2 resolutions of architect §9.2 covered every authoring decision encountered during stage 4. No SendMessage to the live BD-162 architect (UUID `abb1784cc4138af31`) or docs-researcher (UUID `aba8ef1124ab310ce`) was required.

**Architect §6.4 future-BD candidates re-surfaced (informational only, not new POQs):**

- `apple-observability-patterns` — symmetric Apple-platform observability skill. Out of scope per architect.
- `profiling-patterns` — continuous profiling. Out of scope per architect.
- `web-frontend-observability-patterns` (RUM) — out of scope per architect.
- Tier 0 `observability-architecture` — universal cross-language observability principles. Defer to v12+ per architect.
- `python-otel-patterns` / `python-prometheus-patterns` / `python-structlog-patterns` siblings — architect §8.5 explicitly says the v11 single-skill design stands; siblings deferred to first real demand signal. The §A–§K section structure was authored to make a future split mechanical (verified during S3 future-extension discipline check above).

**Architect §7.4 optional cleanup (NOT BD-162 scope):**

The architect named an optional sentence to append to `audit-methodology/SKILL.md` rule 21 boundary clarification ("For D2=python projects, the loaded skill that carries the substantive observability rules each cluster applies is `python-observability-patterns`. For D1 ∈ {ios, macos} projects, the equivalent Apple-platform skill is deferred (see future BD).") — explicitly out of BD-162 scope per architect §7.4 + planner §1 non-goals. PM Chat may open as a separate cleanup BD if desired; the planner did not propose one and the coder does not propose one (per CLAUDE.md `Pack memory` "BDs are reserved for new scope / new feature / new architecture; only the user can initiate a BD-for-fix").

---

## §6 Definition-of-Done checklist

| Item | Source | Status |
|---|---|---|
| All 11 plan §3 files touched correctly (10 by coder + 1 PM-Chat-only BACKLOG flip) | plan §3 | PASS — 7 EDITED + 3 NEW = 10 coder paths complete; BACKLOG.md untouched per PM-only boundary |
| New `python-observability-patterns/SKILL.md` follows architect §5 outline §A → §K | architect §5 / plan §2.1 | PASS — section structure verified by `awk` per-section rule count above |
| Rule counts within architect §5.2–§5.12 target bands | architect §5 | PASS — every section within band per S3 table |
| Two architect §5.13 worked-example rules present verbatim | architect §5.13 / plan §3.1 | PASS — `grep -c` returns 1 for each |
| Owner-tag scheme applied per planner §2.3 | planner §2.3 | PASS — every rule ends with one of `(ops)` / `(arch)` / `(code)` / `(both)` in lowercase parentheses; four-value vocabulary closed |
| Anti-rule list architect §6 respected | architect §6 / plan §4 S3 | PASS — anti-rule discipline scan performed per-section in S3 |
| Future-extension discipline architect §8.5 respected | architect §8.5 / plan §6 R9 | PASS — every rule belongs cleanly to one section; lift-out seam preserved |
| Cross-reference text verbatim from architect §7.2 / §7.3 | architect §7 / plan §3.2 E1 + E2 | PASS — `grep "python-observability-patterns"` returns the architect-supplied wording in deployment-python rule 21 and python-server-architecture rule 8 |
| PLATFORM-SKILLS.md intersection-table row + dimensional inventory row + count bumps + 2 worked examples + 7 per-agent assignments | architect §4.4 / plan §3.2 E3 a/b/c/d | PASS — 16 hits via grep; counts updated |
| `scripts/lib/detect.sh::python_observability_marker_detected()` helper | architect §4.2 / plan §3.2 E4 | PASS — function defined; smoke tests green |
| `scripts/init-project.sh pack_skill_coverage_for python` extended | plan §3.2 E5 | PASS — 3-branch composition; bash -n clean |
| `scripts/add-capability.sh capability_skills` mapping extended | plan §3.2 E6 | PASS — `language:python` + `role:python-server` rows updated; bash -n clean |
| `scripts/test-detect.sh` 17 new test cases | architect §9.4 / plan §3.2 E7 | PASS — 17/17 new tests green; zero regressions in 78 baseline |
| `python3 scripts/validate-pack.py` reports `PASSED — all checks clean` | plan §4 S8 / §5 | PASS — validate-pack: PASSED — all checks clean (29 distinct numbered checks with documented gaps 12–15 plus 2 unnumbered checks for issue templates / template archive); Check 31 reports `Dimensional skills: 20`, `Total skills: 35`, no orphans / phantoms / double-counts / drift; Check 27 extension green |
| `bash scripts/test-detect.sh` passes including new 17 cases | plan §4 S8 / §5 | PASS — 95/95 green |
| No `git add` / `git commit` / `git push` / `git tag` or any state-changing git verb | CLAUDE.md `Pack memory` + `commit-discipline` skill | PASS — coder ran read-only `git rev-parse` + `git status` only; HEAD SHA unchanged from pre-flight |
| No edits to BACKLOG.md / CHANGELOG.md / README.md / PACK-CHAT.md / PACK-AGENTS.md / CLAUDE.md / AGENTS.md / GEMINI.md / EXECUTION-PLAN-V11.0.md | CLAUDE.md "What agents must never modify without explicit instruction" + plan §1 non-goals | PASS — none of these paths edited; trinity sanity scan returns zero hits |
| No edits to upstream-stage PLAN-*.md / ARCHITECTURE-*.md / RESEARCH-*.md | plan §1 non-goals | PASS — upstream artifacts untouched |
| Stale-reference cross-grep clean | plan §5 | PASS — zero stray references in unexpected pack-product locations |
| Trinity-rule sanity scan clean | plan §5 / architect §8.3 | PASS — zero trinity-file contamination |
| Implementation report written per `implementation-report` skill | plan §4 S9 | PASS — this file |

**All 21 DoD items: PASS.**

---

## §7 Hand-off to Pack Chat

Per plan §4 S10 + S11:

1. **Step S10 (PM Chat).** Run `pack-reviewer` once with the architecture + plan + the new SKILL.md as inputs (NOT prior reviews — `feedback_no_prior_reviews_to_reviewer.md`). One fix cycle per CLAUDE.md "One review/fix cycle per batch." Reviewer spot-checks:
   - Right-fit calibration (10 random rules sampled — verify each is "not too vague, not too specific, properly covered" per the user's binding constraint quoted in architect §1).
   - Owner-tag mix per section (verify the per-section tag distribution matches architect intent, especially §I where 1 of 4 rules is `(arch)` per the deviation noted in §4 above).
   - Section-placement scan (10 random rules — verify each fits its section's topical scope per architect §8.5 future-extension discipline).
   - Anti-rule scan (verify no rule lands on architect §6 excluded topics).

2. **Step S11 (PM Chat).** Stage the 8 coder-touched paths (1 NEW SKILL.md + 7 EDITED files) plus this implementation report (9 staged paths total), commit with the suggested subject `feat: v11 — BD-162 python-observability-patterns skill + cross-references (Batch 8)`. After commit, flip BD-162 to `Resolved` in `BACKLOG.md` as a separate small commit per BD-156 / BD-157 / BD-158 precedent (commits `4d93862` / `5a286cb` / `8014186`). The Resolved-line text follows the planner §3.2 E8 template; PM Chat fills in the rule count (65), date (2026-05-13), and test-count delta (+17) from this report.

**Coder reports back:** ready for review.

---

## §8 Fix-pass appendix (post-reviewer; Pack Chat dispatch)

Per Pack Chat fix dispatch on 2026-05-13. User direction: "Fix all including nits. Nits become tech debt that confuse future agents reading files that are incorrect."

Four reviewer findings applied; verification re-run after each pass; Pack Chat owns staging and commit.

### Fix 1 — SH-1: PLATFORM-SKILLS.md intersection-table row placement

**Finding.** The `python-observability-patterns` intersection-table row landed at line 221 (between `python-server-architecture` at line 220 and `python-data-architecture` at line 222), which puts it before three rows the planner §3.2 E3.a anchor implies it should follow. The most literal reading of "before `apple-swiftdata-patterns`" is to land it immediately before that row.

**Action.** Moved the row from position 221 to position 223. New table order: `python-server-architecture` → `python-data-architecture` → `protobuf-patterns` → **`python-observability-patterns`** → `apple-swiftdata-patterns` → `deployment-python`.

**Verification.**

```
$ grep -nE "python-observability-patterns|python-data-architecture|protobuf-patterns|apple-swiftdata-patterns|python-server-architecture|deployment-python" project-template/docs/pack/PLATFORM-SKILLS.md \
    | sed -n '/^22[0-5]:/p'
220:| `python-server-architecture` | D2=python ∩ D3=server | PM chat reads D2 + D3 selections |
221:| `python-data-architecture` | D2=python ∩ ((D3=server) ∨ data-marker present) | …
222:| `protobuf-patterns` | (any host language) ∩ protobuf-marker present | …
223:| `python-observability-patterns` | D2=python ∩ (D3=server ∨ observability-marker present) | …
224:| `apple-swiftdata-patterns` | D1 ∈ {ios, macos} ∩ swiftdata-marker present | …
225:| `deployment-python` | D2=python ∩ D5=linux-container | …
```

Order matches Fix-1 spec. **Status: PASS.**

### Fix 2 — SH-2: PLATFORM-SKILLS.md auditor-ops Step 2 sentence

**Finding.** The `auditor-ops` prose at line 394 (post-edit) read "The deployment skills cover the platform-specific deployment configuration rules and observability *configuration*..." — which inaccurately groups `python-observability-patterns` as a "deployment skill" given that the row above lists three skills loaded by auditor-ops (`deployment-apple, deployment-python, python-observability-patterns`).

**Action.** Inserted " + observability" after "deployment" in that sentence. Updated wording: "The deployment + observability skills cover the platform-specific deployment configuration rules and observability *configuration* (vs. observability *infrastructure*, which lives in `python-observability-patterns` for D2=python projects and in the platform architecture skills for non-Python projects)."

This closes the planner §6 R6 risk explicitly — the editorial-judgment edit now matches loading reality. The semantic content of the parenthetical (what lives where) is unchanged.

**Verification.**

```
$ grep -n "deployment + observability skills" project-template/docs/pack/PLATFORM-SKILLS.md
395:- Always loaded for every audit because every project deploys somewhere. The deployment + observability skills cover the platform-specific deployment configuration rules and observability *configuration* (vs. observability *infrastructure*, which lives in `python-observability-patterns` for D2=python projects and in the platform architecture skills for non-Python projects).
```

**Status: PASS.**

### Fix 3 — N-1: implementation-report "31/31 PASS" phrasing

**Finding.** The implementation report referred to validate-pack outcomes as "31/31 PASS" / "validate-pack 31/31" / "passes 31/31" in three locations. The validator's actual structure is 29 distinct numbered checks (`Check 1`–`Check 11`, then `Check 16`–`Check 31` — gaps at `Check 12`–`Check 15`) plus 2 unnumbered checks (`Check: Issue template forms (BD-063)`, `Check: Template archive v11.0 integrity (BD-064; informational)`) — and the validator's exit-string is `PASSED — all checks clean`, not a count. The "31/31" loose phrasing miscounts and would confuse a future agent reading this report.

**Action.** Replaced all three instances with the validator's verbatim exit-string and the structurally accurate count narrative. Specific replacements:

- Line 423: `**Validate-pack: 31/31 PASS**` → `**validate-pack: PASSED — all checks clean (Check 31 reports Dimensional skills 20, Total skills 35; 29 distinct numbered checks with documented gaps 12–15 plus 2 unnumbered checks for issue templates / template archive).**`
- Line 447: `validate-pack 31/31` → `validate-pack PASSED (all checks clean — 29 distinct numbered checks with documented gaps 12–15 plus 2 unnumbered checks for issue templates / template archive)`
- Line 565 (DoD checklist row): "passes 31/31" → "reports `PASSED — all checks clean`"; PASS-cell text expanded to include the same accurate count narrative.

**Verification.**

```
$ grep -n "31/31" maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-DEPLOYMENT-PYTHON-OBSERVABILITY.md
(no output)
```

Zero remaining instances of "31/31" in the report. **Status: PASS.**

### Fix 4 — N-3: SKILL.md rule 41 (per-gauge multiprocess mode selection) calibration

**Finding.** Reviewer flagged borderline calibration. The pre-fix rule 41 text led with the `prometheus_client` mode-string vocabulary literals (`livesum`, `liveall`, `min`, `max`, `sum`, `all`) as the rule's authoritative target. Per architect §1's binding-constraint rubric (the user's verbatim "Not too vague... Not too specific... Cover the topic properly..."), a rule that authoritatively cites a contrib-library string-vocabulary will defect if a future contrib library revises that vocabulary. The auditable durable property — "selection MUST be deliberate, not default" — is what survives library evolution.

**Action.** Rewrote rule 41 to lead with the durable property (deliberate selection MUST be explicit; the auditable defect is a `Gauge` declared in fork-model deployment without an explicit `multiprocess_mode=` keyword argument) and present the `prometheus_client` mode-string literals as illustrative of the current canonical library rather than authoritative. The library-governed-vs-durable distinction is named explicitly in the rule's closing sentence ("The specific mode-string vocabulary is library-governed; the requirement to choose deliberately is durable.").

Owner-tag updated from `(code)` to `(both)` per the dispatch's recommended shape. The new shape fits the architect §5.8 §G owner-tag mix ("mostly `(both)` — the wiring is structural, the env var values are deployment-target") more cleanly than the original `(code)` tag did: the deliberate-selection requirement is structural (a code-shaped wiring choice — must declare with a kwarg) AND the chosen mode-string is environment-shaped (deployment-config-time choice for the worker model). The amendment to §G's per-section distribution: §G now reads 39=both, 40=ops, 41=both, 42=both (was 39=both, 40=ops, 41=code, 42=both). Three of four §G rules now carry `(both)` — closer to the architect's "mostly `(both)`" intent than the pre-fix mix.

**Verification (per-rule integrity preserved post-fix).**

```
$ grep -c '^[0-9]\+\. ' project-template/skills/python-observability-patterns/SKILL.md
65

$ wc -l project-template/skills/python-observability-patterns/SKILL.md
     527 project-template/skills/python-observability-patterns/SKILL.md

$ grep -c "Label values MUST come from a low-cardinality enumeration" project-template/skills/python-observability-patterns/SKILL.md
1

$ grep -c "Every defined SLO MUST reference a metric the application actually exports" project-template/skills/python-observability-patterns/SKILL.md
1

$ grep -c "Per-gauge multiprocess mode selection MUST be deliberate" project-template/skills/python-observability-patterns/SKILL.md
1
```

Rule count unchanged at 65; both architect §5.13 worked-example rules still verbatim; new rule 41 lead phrasing present. Line count moved from 522 → 527 (5-line increase from the rule-41 expansion). **Status: PASS.**

### Post-fix verification (validate-pack + test-detect)

Per dispatch — both must still pass after all four fixes.

```
$ python3 scripts/validate-pack.py 2>&1 | tail -3

============================================================
PASSED — all checks clean

$ bash scripts/test-detect.sh 2>&1 | tail -3
  pass: import opentelemetry only in node_modules → no (vendored prune)

=== Results: 95 passed, 0 failed ===
```

**validate-pack: PASSED — all checks clean.** Check 31 still reports `Dimensional skills: 20`, `Total skills: 35`, no orphans / phantoms / double-counts / drift (the Fix 1 row reordering preserved row count and the inventory mapping; Check 31 parses the inventory subsection rows, not the intersection-table predicate text). Check 27 extension still green (no per-agent skill-citation drift; Fix 2 was prose-only on the auditor-ops Step 2 line; the agent-file Skills-to-load citations were not touched).

**test-detect: 95/95 PASS.** Fix 4 was rule-text-only in `SKILL.md`; no change to `scripts/lib/detect.sh` or `scripts/test-detect.sh`. Zero regressions in 78-baseline tests; 17 BD-162 tests still green.

### Summary of fix-pass file changes

| Fix | File | Change |
|---|---|---|
| 1 (SH-1) | `project-template/docs/pack/PLATFORM-SKILLS.md` | Intersection-table row reordered to land before `apple-swiftdata-patterns` |
| 2 (SH-2) | `project-template/docs/pack/PLATFORM-SKILLS.md` | Auditor-ops Step 2 sentence: "deployment skills" → "deployment + observability skills" |
| 3 (N-1) | `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-DEPLOYMENT-PYTHON-OBSERVABILITY.md` | Three "31/31"-style phrasings replaced with validator's verbatim exit-string + accurate check-count narrative |
| 4 (N-3) | `project-template/skills/python-observability-patterns/SKILL.md` | Rule 41 rewritten — durable property leads, contrib-library mode-string vocabulary now illustrative; owner tag updated `(code)` → `(both)` |

Two product files modified (`PLATFORM-SKILLS.md`, `python-observability-patterns/SKILL.md`); one workflow-artifact updated (this report — N-1 + this §8 appendix). Total post-fix coder-touched-paths inventory:

- 1 NEW: `project-template/skills/python-observability-patterns/SKILL.md` (now 527 lines, still 65 rules)
- 7 EDITED (unchanged set): `project-template/skills/deployment-python/SKILL.md`, `project-template/skills/python-server-architecture/SKILL.md`, `project-template/docs/pack/PLATFORM-SKILLS.md`, `scripts/lib/detect.sh`, `scripts/init-project.sh`, `scripts/add-capability.sh`, `scripts/test-detect.sh`
- 1 NEW workflow-artifact: this `IMPLEMENTATION-REPORT-DEPLOYMENT-PYTHON-OBSERVABILITY.md`

Stage / commit / BACKLOG flip remain Pack Chat's. Coder did NOT run any state-changing git verb during this fix pass (read-only `git status` only — verified by re-running `git rev-parse HEAD` against pre-flight SHA `6f9e6aa77e6ac401863f6ab2a06ad63dd02bc281`; unchanged).

---

**End of implementation report.** BD-162 stage 4 (coder) complete; one fix-pass cycle applied per CLAUDE.md "One review/fix cycle per batch."

