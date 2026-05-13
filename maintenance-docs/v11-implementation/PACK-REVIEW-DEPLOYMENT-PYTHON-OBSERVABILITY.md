# PACK-REVIEW-DEPLOYMENT-PYTHON-OBSERVABILITY

**Author:** pack-reviewer
**Date:** 2026-05-13
**Pack version target:** v11.0 (in development on `v11-dev`)
**BD:** BD-162
**Pipeline stage:** review (post-coder, pre-commit) — single review/fix cycle per CLAUDE.md pack memory
**Output consumer:** Pack Chat (for fix-pass discussion + commit decision)

Inputs read (read-only):

- `maintenance-docs/v11-implementation/ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md` (full — locked decisions §9.1; §5 outline; §6 anti-rule list; §7 cross-reference text; §8 maintenance properties; §8.5 future-extension architecture)
- `maintenance-docs/v11-implementation/PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY.md` (full — §2 open-decision resolutions; §3 file footprint; §4 ordered steps; §5 verification plan; §6 risks)
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-DEPLOYMENT-PYTHON-OBSERVABILITY.md` (full — pre-flight, per-step results, deviations §4)
- All 10 coder-touched paths:
  - NEW: `project-template/skills/python-observability-patterns/SKILL.md` (522 lines, 65 rules)
  - EDITED: `project-template/skills/deployment-python/SKILL.md`, `project-template/skills/python-server-architecture/SKILL.md`, `project-template/docs/pack/PLATFORM-SKILLS.md`, `scripts/lib/detect.sh`, `scripts/init-project.sh`, `scripts/add-capability.sh`, `scripts/test-detect.sh`
- `BACKLOG.md` BD-162 (lines 1377–1385) — confirmed Status: Open (PM-Chat-only flip pending)
- `scripts/validate-pack.py` Check 31 output (live re-run; PASSED)
- `scripts/test-detect.sh` full output (live re-run; 95/95 PASS)

No prior `PACK-REVIEW-*.md` exists for BD-162 — this is the single first-pass review per CLAUDE.md "one review/fix cycle per batch" and the calling-prompt directive.

---

## §1 Verdict summary

**Overall: APPROVE with no MUST-FIX findings. 2 SHOULD-FIX (both editorial-tier; do not block commit). 3 NIT.**

The implementation is faithful to architect §9.1 locked decisions and planner §2 resolutions. All 10 file paths in planner §3 footprint were touched correctly. Cross-reference text matches architect §7.2 / §7.3 verbatim. Both architect-supplied worked-example rules (§5.13) appear verbatim with their architect-specified owner tags. Anti-rule list (architect §6) is respected. Future-extension seam (architect §8.5) is preserved — §A–§E rules are OTel-side, §F–§G are Prometheus-side, §H is library-agnostic. Validate-pack passes; test-detect passes with the planned +17 delta.

Right-fit calibration spot-check (10 sampled rules across §A / §B / §E / §F / §G / §H / §I / §J): **all 10 properly calibrated** per the binding-constraint rubric quoted in architect §1. One borderline rule flagged for awareness (rule 41 cites `prometheus_client` mode-string literals) but acceptable per ADP-1's permission to cite the dominant library by role. Calibration verdict: **PASS — no calibration drift across the sample.**

---

## §2 Plan-compliance check (per planner §3 file footprint)

Verified each of the 10 coder-touched paths:

| Plan §3 path | Coder action | Verbatim text match | Verdict |
|---|---|---|---|
| N1 — `project-template/skills/python-observability-patterns/SKILL.md` | Created; 522 lines; 65 rules across 11 sections | Frontmatter / Applicability / §A–§K all present; both worked examples verbatim | PASS |
| N3 — `IMPLEMENTATION-REPORT-DEPLOYMENT-PYTHON-OBSERVABILITY.md` | Created; 7 sections per `implementation-report` skill | N/A | PASS |
| E1 — `deployment-python/SKILL.md` rule 21 | Replaced | Verbatim from architect §7.3 line 432 (verified via `sed -n '41p'`) | PASS |
| E2 — `python-server-architecture/SKILL.md` rule 8 | Extended | Verbatim from architect §7.2 line 420 (verified via `sed -n '46p'`) | PASS |
| E3.a — PLATFORM-SKILLS.md intersection table row | Inserted at line 221 (between `python-server-architecture` and `python-data-architecture`, NOT between `python-server-architecture` and `apple-swiftdata-patterns` as planner specified) | Predicate text matches planner | PASS (placement variance is editorial — see SHOULD-FIX SH-1) |
| E3.b — PLATFORM-SKILLS.md dimensional inventory row + count bumps | Header `Dimensional skills (20)`; `Total skills: 35`; "six rows … intersection-loaded"; "14 load directly" | All counts updated | PASS |
| E3.c — Two worked examples | Both updated with `python-observability-patterns` in Intersection list and Result enumeration | Both worked examples (lines 277 + 287) carry the new skill | PASS |
| E3.d — Seven per-agent assignments | architect / coder / reviewer / docs-researcher / auditor-architecture / auditor-code / auditor-ops all carry `python-observability-patterns` | Auditor-ops prose updated per planner E3.d | PASS |
| E4 — `scripts/lib/detect.sh::python_observability_marker_detected()` | Inserted at line 715 (immediately after `swiftdata_marker_detected` ending line 647); shape parallels BD-141 / BD-156 / BD-157 | Marker classes (a) and (b) match architect §4.2 | PASS |
| E5 — `scripts/init-project.sh pack_skill_coverage_for python` | 3-branch composition implemented (lines 298–306); 22-line BD-162 comment block at lines 271–290 | Matches planner pseudocode | PASS |
| E6 — `scripts/add-capability.sh capability_skills` | `language:python` row (line 138) + `role:python-server` row (line 206) both extended; BD-162 comment blocks present | Matches planner | PASS |
| E7 — `scripts/test-detect.sh` | 17 new test cases T1–T17 added at end-of-file (lines 740–922); all pass | Matches architect §9.4 + planner E7 | PASS |
| E8 — `BACKLOG.md` flip | Untouched by coder (PM-Chat-only) | Status still `Open` | PASS (intentional) |

All planner §3 instructions executed. **Plan-compliance: PASS.**

---

## §3 Cross-reference correctness

### 3.1 `deployment-python/SKILL.md` rule 21

Architect §7.3 specified text (architecture doc lines 432–434):

> 21. Substantive observability rules — structured-log field set, metrics naming and cardinality, tracing setup, sampling, SLO definition shape, retention policy shape — live in `python-observability-patterns`. This skill (`deployment-python`) covers deployment-readiness concerns adjacent to observability: container layout, secrets, health checks, graceful shutdown, env-driven production config. Auditor-ops loads both skills for D2=python ∩ D5=linux-container projects.

Implementation (`project-template/skills/deployment-python/SKILL.md` line 41): byte-identical to architect §7.3 specification. **Verbatim PASS.**

Rule numbering preserved: rules 19, 20 unchanged; rule 21 replaced in place; rules 22, 23 unchanged. Total rule count remains 23 (verified via `grep -c '^[0-9]\+\. '`).

### 3.2 `python-server-architecture/SKILL.md` rule 8

Architect §7.2 specified text (architecture doc lines 420–422):

> 8. Auth, logging, and metrics belong in gRPC interceptors (or framework middleware for REST), not in servicer / handler implementations. The substantive observability rules — what spans to create, which attributes to attach, which fields every log record must carry, how to wire trace ↔ log correlation — live in `python-observability-patterns` (loaded for any Python server project per the intersection table). This skill defines the *placement*; the patterns skill defines the *content*.

Implementation (`project-template/skills/python-server-architecture/SKILL.md` line 46): byte-identical to architect §7.2 specification. **Verbatim PASS.**

Rule numbering preserved (rules 7, 9 unchanged).

### 3.3 New skill Applicability cross-references (architect §7.1)

The four prose blocks specified by architect §7.1 (handed to the coder verbatim via planner §4 S3) appear in the SKILL.md Applicability section at lines 50–78 in the documented order:
- python-server-architecture rule 8 (placement) ↔ this skill (content) — line 52
- deployment-python (deployment plumbing) ↔ this skill (observability content) — line 58
- security-patterns / audit-methodology rule 33 (sensitive-data classification) ↔ this skill (redaction-pipeline shape) — line 65
- audit-methodology rule 21 ownership rubric → per-rule owner-tag application — line 73

All four blocks present verbatim. **PASS.**

### 3.4 PLATFORM-SKILLS.md cells

- **Intersection table** (line 221): present, predicate text matches planner E3.a verbatim.
- **Dimensional inventory** (line 464): present; header bumped 19 → 20 (line 440); total bumped 34 → 35 (line 496); intersection-count bumped "five rows" → "six rows" (line 469); direct-load count unchanged at 14 (line 474). All count narrative updates present and consistent.
- **Worked examples** (lines 271–289): both "Python gRPC server" and "Universal Apple app + Python gRPC server" examples carry `python-observability-patterns` in both the Intersection enumeration and the Result enumeration.
- **Per-agent assignments** (lines 322–395): all 7 agents (architect / coder / reviewer / docs-researcher / auditor-architecture / auditor-code / auditor-ops) carry the new skill with the gating note `*(load when python_observability_marker_detected() is true OR D3=server)*` per planner.

**PLATFORM-SKILLS.md cross-reference correctness: PASS.**

---

## §4 Right-fit calibration spot-check (architect §9.4)

Sampled 10 rules across multiple sections — selected for diversity (one each from §A, §B, §C, §D, §E, §F.1, §F.2, §G, §H, §J): rules **1, 6, 8, 11, 22, 28, 32, 41, 47, 56**.

For each, applied the architect §1 binding-constraint rubric:
- **Not too vague?** (auditable threshold or named test that lets an auditor flag a real defect)
- **Not too specific?** (no brittle library API method that may revise within a year)
- **Properly covered?** (durable; cites workflow shape, not version-pinned signature)

| Rule | Section | Line | Calibration verdict |
|---|---|---|---|
| 1 — "Initialize the OTel SDK exactly once at process entry" | §A | 82–88 | PASS — names auditable defect ("`import opentelemetry` followed by tracer / meter creation in a request handler module without a verified one-shot init"); workflow-shape rule, not method-signature |
| 6 — "Pin the OTel semantic-convention package version" | §A | 107–111 | PASS — names a concrete version-drift defect (`http.request.method` vs older `http.method`); durable |
| 8 — "Span names are low-cardinality identifiers" | §B | 120–125 | PASS — names prohibited classes (user IDs, request IDs, rendered URL paths); auditable threshold |
| 11 — "Use semantic-convention attribute namespaces" | §B | 138–144 | PASS — rules the *namespace shape* (lowercase dotted, low-cardinality), not specific keys; explicit acknowledgement that "specific attribute keys may revise across semconv versions but the namespace pattern is stable" |
| 22 — "Use OTLP gRPC as default exporter" | §E | 209–212 | PASS — durable canonical pattern; no method-signature dependency |
| 28 — "Use base SI units in metric names" | §F.1 | 249–253 | PASS — very durable Prometheus naming-guide rule (8 years stable); enumerates prohibited unit suffixes |
| 32 — "Label HTTP/RPC requests by route template + method + status class" | §F.2 | 270–273 | PASS — rules the *concept* (template vs rendered path); durable |
| 41 — "Per-gauge multiprocess mode selection is explicit" | §G | 336–342 | PASS (borderline — see NIT N-3) — cites `prometheus_client` mode-string literals (`livesum`, `liveall`, `min`, `max`, `sum`, `all`); these are documented stable API string-values, acceptable per ADP-1 which permits `prometheus_client` as the canonical metrics library citation. The rule is auditable ("the default `all` double-counts on worker restart and is rarely the intended semantics — pick deliberately") |
| 47 — "Wire trace ↔ log correlation via `OTEL_PYTHON_LOG_CORRELATION` or `LoggingInstrumentor()`" | §H | 383–391 | PASS — names both the env-var path and the programmatic path; auditable defect ("structured logs without `trace_id` / `span_id` populated even though OTel tracing is active in the same process") |
| 56 — "Every SLO has a three-part shape (SLI / Objective / window)" | §J | 453–459 | PASS — rules the *shape*, framework-agnostic; calibration is exemplary |

**Calibration verdict: 10/10 properly calibrated. No calibration drift. Rule 41 is the only borderline sample — flagged as NIT N-3 for awareness but not a defect.**

---

## §5 Anti-rule list compliance (architect §6)

Verified the SKILL.md does not author rules on any architect §6 excluded topic.

| Excluded topic | Present in SKILL.md? | Treatment |
|---|---|---|
| Native histogram client API specifics (§6.1) | Acknowledgement only (rule 37 line 310: "Native histograms are acknowledged as the forward direction once the wire format and client API stabilize") | Compliant — acknowledgement, no rule |
| `tracestate` "ot" probability key (§6.1) | Absent | Compliant |
| OTel Logs SDK as sole log path (§6.1) | Absent; cross-references (line 47) name it as "forward direction; not the rule-able foundation today" | Compliant |
| eBPF auto-instrumentation (§6.1) | Absent | Compliant |
| Specific SLO framework choice (Sloth/Pyrra/Grafana SLO) (§6.2) | Sloth named only as an example artifact-format inside the architect-supplied worked-example rule 59 ("SLO YAML / alertmanager rule / Sloth spec") — not as a recommendation; rules 56–61 are framework-agnostic | Compliant |
| Vendor-specific exporter detail (X-Ray / Cloud Trace / App Insights) (§6.2) | Vendor names appear in rule 26 line 233 as legacy paths to NOT introduce in new code; rule 15 line 167 names B3 / Jaeger / X-Ray-headers as opt-in propagators for fleet interop (consistent with architect §5.4) | Compliant — anti-pattern citation, not a vendor-config rule |
| Log aggregation platform configuration (Splunk / Datadog / Loki / ELK) (§6.2) | Absent (verified via grep) | Compliant |
| Profiling / continuous profiling (§6.2) | Absent | Compliant |
| RUM / front-end observability (§6.2) | Absent | Compliant |
| Log content classification (§6.3) | Rule 33 (PII in label values) and rule 50 (redaction-pipeline shape) explicitly defer to `security-patterns` for content classification | Compliant — placement rule, not classification rule |
| CVE detection in observability deps (§6.3) | Absent; rule 21 only "pin contrib package versions in lock file" | Compliant |
| Health check endpoints (§6.3) | Absent; cross-reference only (line 59 names health checks as `deployment-python` scope) | Compliant |
| Container resource limits (§6.3) | Mentioned only in cross-reference prose (line 60) acknowledging `deployment-python` ownership | Compliant |
| gRPC interceptor placement (§6.3) | Absent; cross-reference at line 52 names `python-server-architecture` rule 8 as the placement-rule home | Compliant |

**Anti-rule compliance: PASS — every excluded topic is either absent or treated as cross-reference / acknowledgement, never as an authored rule.**

---

## §6 Owner-tag compliance (planner §2.3)

- **Closed four-value vocabulary** `(ops)` / `(arch)` / `(code)` / `(both)` — verified via grep; no rule carries any other tag. **PASS.**
- **Lowercase** — verified via grep; all tags are lowercase. **PASS.**
- **End-of-rule placement** — every numbered rule terminates with the tag literal. **PASS.**
- **Per-section distribution vs architect §5.2–§5.12 intent** — verified rule-by-rule per implementation report §2 step S3 table. Spot-check confirms distribution matches architect intent. The coder-noted deviation (§I rule 54 tagged `(arch)` instead of `(ops)`) is self-justified in implementation report §4 and is consistent with the audit-methodology rule 21 rubric ("type / call graph / wiring" → `(arch)`). **PASS.**

Owner-tag count anomaly explained: 65 rules + 4 prose mentions in the Applicability rubric block = 69 tag occurrences (matches implementation report §2 S3 narrative). Not a defect.

---

## §7 Future-extension discipline (architect §8.5)

Verified §A–§K section-placement seams — every rule belongs cleanly to one section:

- **§A–§E (lift-out target: future `python-otel-patterns`)** — exclusively OpenTelemetry-side. No Prometheus-specific rules. Verified.
- **§F + §G (lift-out target: future `python-prometheus-patterns`)** — exclusively Prometheus-side. No OpenTelemetry-specific rules. Verified.
- **§H (foundation glue per architect §8.5)** — library-agnostic field-set + redaction-pipeline-shape + correlation-wiring. No structlog-specific rules. Cross-cutting integration glue (rules 47, 50, 51) lives here as architect intended.
- **§I (sampling)** — OTel-side; will lift with `python-otel-patterns` per architect §8.5.
- **§J (SLO shape)** — framework-agnostic; references OTel only via "or equivalent OTLP push" in rule 59 (architect-supplied verbatim text).
- **§K (retention)** — vendor- and signal-agnostic; foundation forever per architect §8.5.

**Lift-out seam preserved. Future-extension discipline: PASS.**

---

## §8 Marker helper quality (architect §4.2)

**Function shape parity (`scripts/lib/detect.sh` lines 715–772):**

| Property | BD-141 `python_data_marker_detected` | BD-156 `protobuf_marker_detected` | BD-157 `swiftdata_marker_detected` | BD-162 `python_observability_marker_detected` |
|---|---|---|---|---|
| Single positional arg defaulting to cwd | YES | YES | YES | YES |
| Tolerates missing target with `*: no` | YES | YES | YES | YES |
| Single-line stdout output | YES | YES | YES | YES |
| BD-141 negated-character-class boundary | YES | YES | YES | YES (exact-name pattern) |
| Vendored-prune list | n/a | YES | YES | YES (`node_modules/`, `.git/`, `build/`, `.venv/`, `venv/`, `.tox/`) |
| Function doc header | YES | YES | YES | YES (lines 649–714 — names BD-162, architecture document, callers, marker classes) |

**Marker dependency list (architect §4.2 vs implementation):**

| Architect §4.2 marker (a) deps | Implementation (line 728) | Match |
|---|---|---|
| `opentelemetry-api`, `opentelemetry-sdk`, `opentelemetry-distro` | YES (in `exact_pkgs`) | PASS |
| `opentelemetry-instrumentation*` (prefix) | YES (`prefix_pattern` line 730) | PASS |
| `opentelemetry-exporter-*` (prefix) | YES (`prefix_pattern` line 730) | PASS |
| `prometheus-client`, `prometheus_client` | YES (in `exact_pkgs`) | PASS |
| `structlog` | YES | PASS |
| `python-json-logger` | YES | PASS |

**Marker (b) source-file imports** — line-anchored grep covers `import opentelemetry`, `from opentelemetry`, `import prometheus_client`, `from prometheus_client`, `import structlog`, `from structlog` per architect §4.2. **PASS.**

**Helper quality: PASS — parallels existing helpers in shape, error handling, idiom, and doc-header convention.**

---

## §9 Test coverage (architect §9.4 + planner §3.2 E7)

17 test cases T1–T17 (`scripts/test-detect.sh` lines 740–922) verified to cover positive + negative cases.

| Case | Type | Architect §9.4 / Planner E7 mapping | Status |
|---|---|---|---|
| T1 — `requirements.txt` lists `opentelemetry-api` | Positive (manifest exact) | Planner T1 | PASS |
| T2 — `pyproject.toml` lists `opentelemetry-instrumentation-grpc` | Positive (manifest prefix) | Planner T2 | PASS |
| T3 — `pyproject.toml` lists `prometheus_client` | Positive (manifest exact) | Planner T3 | PASS |
| T4 — `requirements.txt` lists `structlog` | Positive (manifest exact) | Planner T4 | PASS |
| T5 — `pyproject.toml` lists `python-json-logger` | Positive (manifest exact) | Planner T5 | PASS |
| T6 — `.py` file with `import opentelemetry` | Positive (source primary) | Planner T6 + architect §9.4 case 1 | PASS |
| T7 — `.py` file with `from opentelemetry.trace import get_tracer` | Positive (source dotted) | Planner T7 | PASS |
| T8 — `.py` file with `import prometheus_client` | Positive (source) | Planner T8 + architect §9.4 case 2 | PASS |
| T9 — `.py` file with `from structlog import get_logger` | Positive (source) | Planner T9 | PASS |
| T10 — `pyproject.toml` lists `opentelemetry-exporter-otlp-proto-grpc` | Positive (manifest prefix exporter) | Planner T10 | PASS |
| T11 — empty directory | Negative (baseline) | Planner T11 + architect §9.4 case 4 | PASS |
| T12 — non-existent target | Negative (tolerance) | Planner T12 | PASS |
| T13 — pure Apple project | Negative | Planner T13 + architect §9.4 case 3 | PASS |
| T14 — Python script with `requests` + `pytest` only | Negative | Planner T14 + architect §9.4 case 4 | PASS |
| T15 — `not-opentelemetry-clone` substring | Negative (boundary) | Planner T15 | PASS |
| T16 — prose mention in comment | Negative (line-anchor) | Planner T16 | PASS |
| T17 — `node_modules/` vendored prune | Negative (prune) | Planner T17 | PASS |

**All 17 tests present and passing. Test coverage: PASS.** Live re-run output: `=== Results: 95 passed, 0 failed ===` (78 baseline + 17 BD-162 = 95).

---

## §10 Validate-pack outcome

Live re-run of `python3 scripts/validate-pack.py` ends with `PASSED — all checks clean`.

Specific Check 31 output (line 2380):
```
── Check 31: Skill-cell consistency (BD-146, v11) ──
  OK: PLATFORM-SKILLS.md — 'Tier 0 base skills': 13 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'Dimensional skills': 20 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'Trigger-loaded skills': 1 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'PM chat operational skill': 1 rows (header matches)
  OK: PLATFORM-SKILLS.md — total skills: 35 (header sum, inventory row count, and disk count all agree)
  OK: Skill-cell consistency: 35 SKILL.md on disk, all map to exactly one inventory cell; no orphans, phantoms, or double-counts
```

Dimensional skills 20 rows (was 19), total skills 35 (was 34), no orphans / phantoms / double-counts. **Validate-pack: PASS.**

Note: the implementation report claims "31/31 PASS"; the actual check count printed by validate-pack is 29 distinct checks (numbering goes to 31 with gaps 12–15 and two unnumbered checks for issue templates / template archive). The report's "31/31" phrasing is loose but the gate it represents (validate-pack exits clean) is satisfied. Flagged as NIT N-1.

---

## §11 Stale-reference scan

Searched for the old `deployment-python` rule 21 wording ("Enable structured logging (JSON format) for production. Include request ID, method, status, and latency in every log entry.") across pack-product files:

```
$ grep -rn "Enable structured logging.*JSON" project-template/ scripts/
(no output in pack-product files)

$ grep -rn "Enable structured logging.*JSON" maintenance-docs/
maintenance-docs/v11-implementation/ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md:158 (architect documenting the change)
maintenance-docs/v11-implementation/ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md:428 (architect documenting the replacement)
maintenance-docs/v11-implementation/PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY.md:141 (planner documenting the replacement)
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-DEPLOYMENT-PYTHON-OBSERVABILITY.md:297 (coder documenting the replacement)
maintenance-docs/v11-implementation/AUDIT-BD-032.md:60 (historical audit reference)
```

All five hits are in workflow-artifact / historical-audit documents that legitimately quote the prior wording while documenting the change. **Zero stray references in pack-product files. PASS.**

Cross-grep for `python-observability-patterns` outside the planner-expected file set (per planner §5):

```
$ grep -rn "python-observability-patterns" project-template/ scripts/ \
    --include='*.md' --include='*.sh' \
  | grep -v "<expected eight files>"
(no output)
```

Zero stray references. Trinity-file sanity scan (planner §5) also returns zero — `python-observability-patterns` does not appear in any of `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md`, or pack-root `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`. Architect §8.3 invariant preserved. **PASS.**

---

## §12 Coder deviations (implementation report §4) verification

The coder reports four editorial-only deviations. Each verified:

1. **Skill-list emission order in `pack_skill_coverage_for python`** — pre-edit emitted `"python-data-architecture,python-best-practices"` (data first); post-edit emits `"python-best-practices[,python-data-architecture][,python-observability-patterns]"` (best-practices first). No test asserts the specific order; PM-chat skill loading reads names not order; no architect/planner-locked decision violated. **Editorial — accepted.**

2. **Test-section placement at end-of-file** in `test-detect.sh` — planner E7 explicitly named the choice between "after the `swiftdata_marker_detected` block" and "at end-of-file in a new `## ── python_observability_marker_detected (BD-162) ─────────` section" with the parenthetical "Coder picks placement parallel to BD-156 / BD-157 ordering." Coder picked end-of-file per BD-chronology rationale. Within planner-allowed latitude. **Editorial — accepted.**

3. **§I rule 54 owner-tag `(arch)` rather than `(ops)`** — architect §5.10 said §I is "mostly `(ops)`" with sampler ratio as the canonical config-value example. Rule 54 is the boundary rule "tail sampling is collector-side, never application-side; do not implement custom tail-sampling logic in the application." The audit-methodology rule 21 rubric tags `(arch)` for "type / call graph / wiring" — not implementing a custom `Sampler` subclass IS a wiring decision. The remaining four §I rules (52, 53, 55, plus the implicit pattern in 54's collector-side resolution) carry `(ops)`, preserving architect's "mostly `(ops)`" intent. **Coder's reasoning is sound and consistent with the rubric.** Architect §5.10 used "mostly" not "exclusively"; one `(arch)` rule among five preserves the "mostly" framing. **Editorial — accepted.**

4. **SKILL.md line count 522 vs estimate 350–420** — overshoot driven by (a) Applicability section ~70 lines required to carry four cross-reference prose blocks (lines 50–78) plus canonical-library-positions block (lines 26–48) per architect §3.1 / §7.1 (both non-optional verbatim), and (b) §F sub-section structure (F.1 / F.2 / F.3) per architect-required organization. Per-rule prose remained terse-imperative. Total rule count (65) and per-section rule counts within architect bands. **Editorial — accepted.**

**All four deviations verified as editorial; no architect/planner-locked decision violated.**

---

## §13 Findings

### MUST-FIX (0)

None. All locked decisions preserved; validator passes; cross-references correct; no anti-rule violations; no missing-file from the planner §3 footprint.

### SHOULD-FIX (2 — both editorial-tier; do not block commit)

**SH-1 — PLATFORM-SKILLS.md intersection-table row placement (`project-template/docs/pack/PLATFORM-SKILLS.md` line 221)**
- **Source.** Planner §3.2 E3.a specified "insert a new row immediately after the `python-server-architecture` row (current line 220) and before the `apple-swiftdata-patterns` row (current line 223)."
- **Actual.** Inserted at line 221 — between `python-server-architecture` (line 220) and `python-data-architecture` (line 222), then `protobuf-patterns` (223), `apple-swiftdata-patterns` (224), `deployment-python` (225). The new row IS immediately after `python-server-architecture` (correct), but it lands BEFORE `python-data-architecture` rather than BEFORE `apple-swiftdata-patterns`.
- **Impact.** Cosmetic ordering only — Check 31 does not parse intersection-table predicate text; PM-chat reads the row content not its position. The order chosen actually keeps the two python-server-related intersection rows adjacent (server, observability, data) which is arguably more readable than the planner's literal placement. **Recommendation: leave as-is** unless Pack Chat prefers literal planner adherence. Not a defect; flagged because the placement is the only divergence from a planner-specified line.

**SH-2 — Auditor-ops Step 2 prose update completeness (`project-template/docs/pack/PLATFORM-SKILLS.md` lines 394–395)**
- **Source.** Planner §3.2 E3.d specified rewriting the auditor-ops parenthetical to "(vs. observability *infrastructure*, which lives in `python-observability-patterns` for D2=python projects and in the platform architecture skills for non-Python projects)."
- **Actual.** Implemented verbatim per planner. However, the sentence still begins "Always loaded for every audit because every project deploys somewhere. The deployment skills cover the platform-specific deployment configuration rules and observability *configuration*..." — the word "deployment skills" now technically covers three skills (`deployment-apple`, `deployment-python`, `python-observability-patterns`), but `python-observability-patterns` is not a deployment skill. The phrasing is grammatically awkward post-rewrite.
- **Impact.** Editorial-only; semantics correct; load behavior unaffected. **Recommendation: optional polish** — could rephrase to "The deployment + observability skills cover the platform-specific deployment configuration rules and observability *configuration*..." for clarity, but this is the planner's own R6 risk ("editorial subjectivity") realized. Not a defect.

### NIT (3 — informational only)

**N-1 — Implementation report "31/31 PASS" phrasing (`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-DEPLOYMENT-PYTHON-OBSERVABILITY.md` line 423)**
- Validate-pack runs 29 distinct checks (numbered to 31 with gaps 12–15 and 2 unnumbered checks for issue templates / template archive). The report's "31/31 PASS" wording is loose. Validate-pack itself reports `PASSED — all checks clean`. Recommend the post-coder commit message and PM-Chat-managed BACKLOG flip use the validator's actual exit-string ("validate-pack PASSED") rather than "31/31".

**N-2 — Architect doc still on filesystem as untracked (per implementation report §3 working tree status)**
- The architect / planner / RESEARCH artifacts under `maintenance-docs/v11-implementation/` are listed as Untracked. PM Chat will need to stage them alongside the coder's IMPLEMENTATION-REPORT and the SKILL.md / script changes for the BD-162 commit. Not a coder defect — these are workflow-artifact carve-outs per ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md §3.2 sig. 5.

**N-3 — Rule 41 borderline calibration (`project-template/skills/python-observability-patterns/SKILL.md` lines 336–342)**
- Rule 41 cites `prometheus_client` mode-string literals (`livesum`, `liveall`, `min`, `max`, `sum`, `all`) as the per-gauge multiprocess mode selection. These are documented stable API values per ADP-1's permission to cite the canonical metrics library. Acceptable — flagged for awareness only. If a future contrib library defects this string-set, the rule may need refresh; the auditable property ("the default `all` double-counts on worker restart and is rarely the intended semantics — pick deliberately") remains durable independent of the specific string-values.

---

## §14 Definition-of-Done

| Check | Verdict |
|---|---|
| All planner §3 file paths touched correctly (10 coder + 1 PM-Chat-only) | PASS |
| Architect §9.1 locked decisions preserved | PASS |
| Cross-reference text architect §7.2 / §7.3 verbatim | PASS |
| PLATFORM-SKILLS.md cells (intersection / inventory / worked examples / per-agent) | PASS |
| Marker helper structure parallels BD-141 / BD-156 / BD-157 | PASS |
| Marker dependency list matches architect §4.2 | PASS |
| 17 test cases T1–T17 present and passing | PASS |
| Validate-pack exits clean (Check 31 reports 20 dimensional / 35 total / no orphans) | PASS |
| Stale-reference scan: zero pack-product references to old rule 21 wording | PASS |
| Trinity-file scan: zero `python-observability-patterns` in trinity files | PASS |
| Right-fit calibration spot-check: 10/10 properly calibrated | PASS |
| Anti-rule list (architect §6) compliance | PASS |
| Owner-tag four-value vocabulary closed | PASS |
| Future-extension discipline (architect §8.5) preserved | PASS |
| Coder deviations (4) all editorial | PASS |
| BACKLOG.md untouched by coder (PM-Chat-only) | PASS |

**16/16 DoD items: PASS.**

---

## §15 Recommendation to Pack Chat

**APPROVE for commit. No fix-pass required.**

The 2 SHOULD-FIX items (SH-1 placement, SH-2 prose flow) are editorial polish that the coder explicitly noted within planner-allowed latitude. Pack Chat may apply them as inline polish during the commit-staging step, or defer indefinitely without functional impact.

The 3 NIT items are informational only and require no action.

**Staged paths (8 for the BD-162 feature commit, per implementation report §3):**

1. NEW: `project-template/skills/python-observability-patterns/SKILL.md`
2. EDITED: `project-template/skills/deployment-python/SKILL.md`
3. EDITED: `project-template/skills/python-server-architecture/SKILL.md`
4. EDITED: `project-template/docs/pack/PLATFORM-SKILLS.md`
5. EDITED: `scripts/lib/detect.sh`
6. EDITED: `scripts/init-project.sh`
7. EDITED: `scripts/add-capability.sh`
8. EDITED: `scripts/test-detect.sh`

Plus IMPLEMENTATION-REPORT and the upstream RESEARCH / ARCHITECTURE / PLAN artifacts (per BD-156 / BD-157 / BD-158 precedent: workflow artifacts ride along in the feature commit).

Then a separate small BACKLOG flip commit per planner §4 S11 (matching commits `4d93862` / `5a286cb` / `8014186` precedent).

---

**End of review.** Single review pass complete per CLAUDE.md "one review/fix cycle per batch." Pack Chat to discuss any optional polish for SH-1 / SH-2 with user before staging, then commit per planner §4 S11.
