# PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY

**Author:** pack-planner
**Date:** 2026-05-13
**Pack version target:** v11.0 (in development on `v11-dev`)
**BD:** BD-162
**Pipeline stage:** 3 of 4 (researcher → architect → **planner** → coder)
**Output consumer:** `pack-coder` (for `IMPLEMENTATION-REPORT-DEPLOYMENT-PYTHON-OBSERVABILITY.md`)

Inputs read:
- `ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md` (full — locked decisions §9.1; open decisions §9.2; future-extension notes §8.5)
- `RESEARCH-DEPLOYMENT-PYTHON-OBSERVABILITY.md` (context only; not re-litigated)
- `BACKLOG.md` BD-162 (lines 1377–1383) and BD-161 (lines 1388–1402, for cross-reference verification)
- `project-template/skills/protobuf-patterns/SKILL.md` (BD-156 reference shape — frontmatter + Applicability + numbered rules)
- `project-template/skills/swift-concurrency-patterns/SKILL.md` (BD-158 reference shape — D1-implied loading, larger 14-section / 66-rule layout)
- `project-template/skills/deployment-python/SKILL.md` (the 23-rule scope being trimmed at rule 21)
- `project-template/skills/python-server-architecture/SKILL.md` (rule 8 placement-rule extension target)
- `project-template/docs/pack/PLATFORM-SKILLS.md` (intersection table line 213; dimensional inventory line 439; per-agent assignments line 312; worked examples line 252)
- `scripts/lib/detect.sh` (BD-141 `python_data_marker_detected`, BD-156 `protobuf_marker_detected`, BD-157 `swiftdata_marker_detected` — three living parallels)
- `scripts/init-project.sh` (`stage_s4_skills` line 461; `pack_skill_coverage_for` line 235)
- `scripts/add-capability.sh` (`capability_skills` line 121)
- `scripts/test-detect.sh` (BD-156 / BD-157 / BD-141 marker-test patterns at lines 315 / 411 / 548)
- `scripts/validate-pack.py` (Check 31 skill-cell consistency, line 2380)
- `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.1 / §3.2 / §3.3 (mechanical-vs-structural thresholds)
- BD-156 commit `af2f651`, BD-157 commit `c2beaa0`, BD-158 commit `8c117cf` (single-commit batch precedents)

---

## §1 Goal and BD scope

**Goal.** Sequence the architect's design (`ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md` §1–§9) into a step-by-step implementation plan that the coder (stage 4) can execute mechanically — preserving every §9.1 locked decision verbatim, resolving every §9.2 open decision with explicit rationale, and enumerating the 11-file footprint from architect §8.2 as a sequenced touch order with verbatim cross-reference text from architect §7.2 / §7.3.

**BD addressed.** BD-162 (single BD; the cross-cutting follow-up to BD-032's audit-methodology rule 21 expansion). No other BDs are in scope. BD-161 is referenced (architect §8.4) but does not require any edit in this BD — its enumeration-driven discovery picks up `python-observability-patterns` mechanically once both BDs land.

**Non-goals (explicit).**
- No re-litigation of any §9.1 locked decision (skill placement, loading semantics, scope envelope, library citation policy, cross-reference text, boundary handling, anti-rule list).
- No `BACKLOG.md` edit by the coder (PM Chat owns the Resolved flip per CLAUDE.md pack memory).
- No `BD-161` edit (its File/Symbol field already promises enumeration-driven discovery).
- No `audit-methodology/SKILL.md` edit (architect §7.4 — informational pointer flagged for a separate cleanup BD, not BD-162).
- No new `validate-pack.py` check (architect §8.1 condition 5 — Check 31 already covers the new intersection-table row; verified in §3.4 below).

---

## §2 Resolution of architect §9.2 open decisions

All four open decisions are resolved here so the coder receives unambiguous instructions.

### 2.1 Section ordering within `python-observability-patterns/SKILL.md` — **CONFIRMED as architect §A → §K**

**Decision.** The coder writes the SKILL.md sections in the exact order the architect proposed in §5 of the architecture document:

1. Frontmatter + Applicability (front matter; §5.1)
2. §A — Telemetry SDK setup and resource attributes (§5.2; 5–7 rules)
3. §B — Span lifecycle and attributes (§5.3; 8–10 rules)
4. §C — Trace context propagation (§5.4; 3–4 rules)
5. §D — Auto-instrumentation discipline (§5.5; 3–4 rules)
6. §E — Exporter configuration (§5.6; 4–5 rules)
7. §F — Prometheus metrics: naming, labels, types (§5.7; 12–15 rules across F.1 / F.2 / F.3)
8. §G — Prometheus exposition: multiprocess and endpoint (§5.8; 4–5 rules)
9. §H — Structured logging: required fields and trace correlation (§5.9; 8–10 rules)
10. §I — Sampling (§5.10; 4–6 rules)
11. §J — SLO definition shape and burn-rate alerts (§5.11; 5–7 rules)
12. §K — Retention policy shape (§5.12; 3–5 rules)

**Rationale for confirming, not reordering.** The architect's proposed order is the canonical signal-trinity narrative (traces → metrics → logs → sampling → SLO → retention). Reordering for editorial flow would (a) detach §A–§E (OpenTelemetry tracing) from §I (sampling), which is OTel-shaped; (b) detach §F–§G (Prometheus metrics) from §J (SLO, which is Prometheus-shaped — recording rules, alertmanager); and (c) break the architect §8.5 future-extension seam (the §A–§K sequence was deliberately chosen so a future `python-otel-patterns` lift takes §A+§B+§C+§D+§E+§I and a future `python-prometheus-patterns` lift takes §F+§G+the Prometheus portion of §J). Editorial reordering would entangle those seams.

**Coder instruction.** Write the sections strictly in the order above. Do not reorder. If a rule feels like it could plausibly live in two sections, place it in the section the architect §5 outline names first; flag the ambiguity to the architect via SendMessage rather than choosing unilaterally.

### 2.2 Per-section batch decomposition — **DECIDED: single commit (architect's recommendation)**

**Decision.** All 10 file edits land in **one commit**, parallel to BD-156 (`af2f651`), BD-157 (`c2beaa0`), and BD-158 (`8c117cf`). The 11th touched path — `BACKLOG.md` Resolved flip — is a separate post-coder PM Chat commit per pack memory (BACKLOG is a PM-only file; coder cannot touch it).

**Rationale for confirming, not splitting.**

1. **Half-installed-skill failure mode.** A two-commit decomposition (commit 1 = SKILL.md content + cross-references; commit 2 = PLATFORM-SKILLS.md + scripts) leaves the pack in a state where validate-pack Check 31 fails between the commits — the new SKILL.md is on disk but no inventory row claims it, so Check 31's "orphan SKILL.md" failure mode fires. The architect's success criterion (validate-pack must pass at every intermediate step) is incompatible with two-commit decomposition unless commit 1 ships scripts/PLATFORM-SKILLS.md updates first and commit 2 ships SKILL.md content second — which inverts the conceptual order and is hard to review.
2. **BD-156 / BD-157 / BD-158 precedent.** All three predecessors shipped as single commits with the new skill + cross-references + scripts + PLATFORM-SKILLS.md updates + (where applicable) new marker helper + new test cases atomically. BD-162's footprint (10 file edits + 1 NEW SKILL.md = 11 touched paths) is within the BD-158 envelope (which touched a similar count).
3. **Coder workflow fit.** The coder runs validate-pack after the full edit pass; a single coherent commit is the natural unit. Splitting into two commits requires running validate-pack twice with intermediate state reasoning, which adds review burden without compensating benefit.

**Coder instruction.** Stage all 10 edits together. Do not push intermediate WIP. Run `python3 scripts/validate-pack.py` once after the full edit pass, before writing the implementation report. If the validator fails, fix in place and re-run; do not split the commit to "isolate" a failure.

### 2.3 Worked-example rule numbering — **DECIDED: continuous numbering, section-anchored**

**Decision.** Rules in `python-observability-patterns/SKILL.md` are numbered **continuously across sections** (1, 2, 3, … through ~59), parallel to BD-156 protobuf-patterns and BD-158 swift-concurrency-patterns. Section headings (§A, §B, …) are organizational markers in the heading text only — they do not appear in the rule numbers themselves.

**Concrete coder rule.** Each rule is a numbered list item under its section's `## Section <name>` heading. Numbering restarts at 1 only at the top of the file and increments through every section sequentially.

**Worked example.** If §A (SDK setup) has 5 rules, they are numbered 1–5. If §B (span lifecycle) follows with 8 rules, they are numbered 6–13. If §C (propagation) follows with 3 rules, they are numbered 14–16. Continue through §K.

**Why continuous (not §A.1 / §A.2 / §B.1 …).** Three reasons:
1. **Pack-wide convention.** Every existing `*-patterns` and `*-architecture` skill uses continuous numbering (verified in `protobuf-patterns/SKILL.md` rule 11 → "Run `buf breaking`…"; `swift-concurrency-patterns/SKILL.md` rule 66; `deployment-python/SKILL.md` rule 23). Auditor citations follow this convention ("rule 17 of `python-observability-patterns`").
2. **Future-sibling lift compatibility.** When a future BD lifts §A–§E into `python-otel-patterns` (architect §8.5), the lift renumbers within the new sibling — no in-foundation renumbering required. Section-anchored numbering (§A.3 → §B.1 …) would force reformatting at lift time and increase lift cost.
3. **Worked-example rule placement.** The architect's two illustrative rules in §5.13 (the cardinality rule from §F.2; the orphaned-SLO rule from §J) get their *final* numbers assigned at coder authoring time. Their placement within their respective sections is fixed (§F.2 cardinality block; §J body), but the absolute numbers depend on rule counts in preceding sections.

**Owner-tag placement within rule body.** Per architect §9.5 (the architect-flagged ambiguity), the planner sets the convention: the parenthetical owner tag — `(ops)`, `(arch)`, `(code)`, `(both)` — appears at the **end of the final sentence** of each rule body (after the closing period or before, as grammar dictates), in lowercase, single set of parentheses, no further qualifiers. This matches the architect's two §5.13 worked examples literally (rule ends with "`(code)`" or "`(ops)`"). Use `(both)` (not `(ops, arch)`) when both apply — the four-value scheme is closed; do not invent compound tags.

**Coder instruction.** When writing a rule, decide which owner-tag value applies, then suffix the final sentence with a single space and the tagged literal (`` `(ops)` ``, `` `(arch)` ``, `` `(code)` ``, `` `(both)` ``). Do not modify the tag values; do not add new tag values; do not omit the tag. Auditor-facing tools rely on the four-value vocabulary being closed.

### 2.4 Validate-pack discovery — **CONFIRMED: Check 31 covers the new intersection-table row; no new check needed**

**Decision.** No new `check_*` function is added to `scripts/validate-pack.py`. The existing Check 31 (BD-146 skill-cell consistency) auto-validates the new intersection-table row.

**Verification (read-only — performed during planning).**
- `scripts/validate-pack.py` line 2380 (`check_skill_cell_consistency`) parses the four `### <subsection> (NN)` headers in PLATFORM-SKILLS.md's `## Full skill inventory` section: Tier 0 base skills, **Dimensional skills**, Trigger-loaded skills, PM chat operational skill.
- The check enforces five failure modes (lines 2435–2446): orphan SKILL.md (on disk, missing from inventory), phantom cell (in inventory, no SKILL.md on disk), double-counted (same skill in multiple subsections), header drift (declared count ≠ row count), total drift.
- When the coder ADDS the `python-observability-patterns` row to the Dimensional skills subsection AND bumps its header count from 19 to 20 AND the on-disk `project-template/skills/python-observability-patterns/SKILL.md` exists, all five failure modes are satisfied: skill present on disk; row present in inventory; row appears in exactly one subsection; declared count (20) matches row count (20); total skills line bumps from 34 to 35.
- The intersection table at PLATFORM-SKILLS.md line 213 is referenced by the new skill row's "Cell" column ("D2=python ∩ (D3=server ∨ observability-marker)") — Check 31 does not parse the intersection table predicate text, only the inventory subsection rows; the predicate string is human-readable and informational. No new validator logic is required to assert the predicate text.
- The new marker helper `python_observability_marker_detected()` in `scripts/lib/detect.sh` is paralleled by BD-141 `python_data_marker_detected` and BD-156 `protobuf_marker_detected` and BD-157 `swiftdata_marker_detected` — none of those four required a new validate-pack check (verified by reading `scripts/validate-pack.py` and finding zero references to those four function names). Test coverage lives in `scripts/test-detect.sh`, not in validate-pack.

**Coder instruction.** Do NOT add a new `check_*` function to `scripts/validate-pack.py`. Do NOT modify the existing checks. After the full edit pass, run `python3 scripts/validate-pack.py` and confirm Check 31 reports `Dimensional skills: 20 rows (header matches)` and the total-skills assertion reports 35 (was 34). Any other Check 31 output is a defect — surface it in the implementation report and do not work around it.

---

## §3 Affected files (complete enumeration, including cross-references)

This list is exhaustive — the architect §8.2 footprint (3 NEW + 8 EDITED = 11 paths) is reproduced here with planner-added per-file touch instructions. The 11th path (BACKLOG.md) is PM-Chat-only and listed as the post-coder finalization step, not a coder touch.

### 3.1 NEW files (3)

**N1. `project-template/skills/python-observability-patterns/SKILL.md`** (~350–420 lines, ~55–65 rules across 11 sections)
- Sole substantive content authoring of the BD.
- Created in step S2 (§4).
- Frontmatter shape: `name`, `description`, `allowed-tools` (parallel to `protobuf-patterns/SKILL.md` lines 1–5 and `swift-concurrency-patterns/SKILL.md` lines 1–5).
- `description` field text (planner-supplied for coder verbatim use): *"Use for Python observability — OpenTelemetry tracing setup, span lifecycle, trace context propagation, auto-instrumentation, exporter configuration; Prometheus metrics naming / cardinality / type selection / multiprocess exposition; structured logging field requirements + trace-log correlation; head sampling; SLO definition shape and burn-rate alerts; retention-policy shape. Loads at D2=python ∩ (D3=server ∨ observability-marker)."*
- `allowed-tools: Read, Grep, Glob, Bash` (parallel to existing skills).
- Owner-tag scheme: per §2.3 above.
- Rule count target: 55–65 (architect §5.14 estimate is 59; final count emerges during authoring).
- Cross-references to other skills appear in the Applicability block (planner-supplied verbatim text at §5 below).

**N2. `maintenance-docs/v11-implementation/PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY.md`** (this file)
- Workflow artifact; carve-out per ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md §3.2 sig. 5.
- Created at planning stage (now). Not edited by the coder.

**N3. `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-DEPLOYMENT-PYTHON-OBSERVABILITY.md`**
- Workflow artifact; carve-out per ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md §3.2 sig. 5.
- Created by the coder at end of stage 4 (per `implementation-report` skill).
- Names shape: pre-flight evidence, per-step results, validate-pack output, test-detect output, deviations, POQs.

### 3.2 EDITED files (7 product/script paths + 1 PM-Chat-only)

**E1. `project-template/skills/deployment-python/SKILL.md`** — replace rule 21 with the cross-reference text from architect §7.3 verbatim.
- Current rule 21 (line 41) reads: `21. Enable structured logging (JSON format) for production. Include request ID, method, status, and latency in every log entry.`
- Replacement text (verbatim from architect §7.3, lines 432–434 of `ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md` — coder uses this without rewriting):
  > 21. Substantive observability rules — structured-log field set, metrics naming and cardinality, tracing setup, sampling, SLO definition shape, retention policy shape — live in `python-observability-patterns`. This skill (`deployment-python`) covers deployment-readiness concerns adjacent to observability: container layout, secrets, health checks, graceful shutdown, env-driven production config. Auditor-ops loads both skills for D2=python ∩ D5=linux-container projects.
- Rule numbering: rule 21 keeps its number; rules 22–23 stay where they are (architect §7.3 explicit).
- Touched section: `## Production configuration` (rules 19–23).

**E2. `project-template/skills/python-server-architecture/SKILL.md`** — extend rule 8 with the cross-reference text from architect §7.2 verbatim.
- Current rule 8 (line 46) reads: `8. Auth, logging, and metrics belong in gRPC interceptors (or framework middleware for REST), not in servicer / handler implementations.`
- Replacement text (verbatim from architect §7.2, lines 420–422 — coder uses this without rewriting):
  > 8. Auth, logging, and metrics belong in gRPC interceptors (or framework middleware for REST), not in servicer / handler implementations. The substantive observability rules — what spans to create, which attributes to attach, which fields every log record must carry, how to wire trace ↔ log correlation — live in `python-observability-patterns` (loaded for any Python server project per the intersection table). This skill defines the *placement*; the patterns skill defines the *content*.
- Rule numbering: rule 8 keeps its number; rule 9 (`Flag middleware and interceptor correctness…`) stays where it is.

**E3. `project-template/docs/pack/PLATFORM-SKILLS.md`** — four parallel edits per architect §4.4:

E3.a — Intersection table (table at line 213): insert a new row immediately after the `python-server-architecture` row (current line 220) and before the `apple-swiftdata-patterns` row (current line 223). New row text (planner-supplied for coder verbatim use):
> `| python-observability-patterns | D2=python ∩ (D3=server ∨ observability-marker present) | scripts/lib/detect.sh::python_observability_marker_detected() is the canonical predicate (see BD-162); checks for OpenTelemetry / Prometheus client / structured-logging dependencies in requirements.txt / pyproject.toml / setup.py / setup.cfg / uv.lock and for source-file imports of opentelemetry / prometheus_client / structlog. Server projects (D3=server) load unconditionally even without the marker so observability rules apply during new-code review. |`

E3.b — Full skill inventory dimensional table (table at line 439, header `### Dimensional skills (19)` at line 439): bump header count from 19 to 20; insert a new row immediately after the `python-server-architecture` row (current line 462) and before the `python-data-architecture` row (current line 463). New row text (planner-supplied for coder verbatim use):
> `| python-observability-patterns | D2=python ∩ observability-marker *(intersection — see scripts/lib/detect.sh::python_observability_marker_detected())* | OpenTelemetry tracing setup, span lifecycle, trace context propagation, auto-instrumentation, exporter configuration; Prometheus metrics naming / cardinality / type selection / multiprocess exposition; structured logging field requirements + trace-log correlation; head sampling; SLO definition shape; retention-policy shape | architect, coder, reviewer, auditor-architecture, auditor-code, auditor-ops, docs-researcher |`
- Bump the post-table count narrative line (currently `**19 dimensional / intersection skills.**` at line 466) to `**20 dimensional / intersection skills.**`.
- Bump the intersection-loaded count: the line currently reads "five rows … are intersection-loaded" — change "five" → "six" and add `python-observability-patterns` to the inline list (currently `python-server-architecture, python-data-architecture, protobuf-patterns, apple-swiftdata-patterns, deployment-python`).
- Bump the direct-load count phrase if present (architect's BD-158 commit `8c117cf` notes "direct-load count 13 → 14 (intersection count unchanged at 5)"; this BD goes the other way — intersection count 5 → 6, direct-load count unchanged at 14). Verify the exact wording in PLATFORM-SKILLS.md and adjust accordingly.
- Bump the `**Total skills: 34**` line (line 493) to `**Total skills: 35**`.

E3.c — Worked examples (block at line 252):
- Update the "Python gRPC server (Linux container)" worked example (lines 270–278): add `python-observability-patterns` to both the "Intersection:" enumeration and the "**Result (dimensional + intersection):**" enumeration. New result string: `python-best-practices, dependency-python, grpc-patterns, protobuf-patterns, python-server-architecture, python-data-architecture, python-observability-patterns, deployment-python`.
- Update the "Universal Apple app + Python gRPC server (monorepo)" worked example (lines 280–288): same addition pattern. New result string ends with `…, python-observability-patterns, deployment-apple, deployment-python`.
- Both updates parallel BD-156 / BD-157 / BD-158's worked-example updates exactly — same insertion technique, same predicate-narrative format.

E3.d — Step 2 per-agent skill assignments (block at line 312): add `python-observability-patterns` to the dimensional-filtered list of seven agents per architect §4.3:
- **architect** (line 323) — append to the dimensional list with the gating note `python-observability-patterns *(load when python_observability_marker_detected() is true OR D3=server)*`.
- **coder** (line 327) — append to the dimensional list with the same gating note.
- **reviewer** (line 331) — append to the dimensional list with the same gating note.
- **auditor-architecture** (line 360) — append to the dimensional list with the same gating note. Update the "Platform filtering:" paragraph (line 361) to mention the new skill loads alongside `python-server-architecture` for D3=server Python projects (parallel to the existing `python-data-architecture` mention).
- **auditor-code** (line 366) — append to the dimensional list with the same gating note. The existing prose "plus python-data-architecture (load per the intersection-table predicate via `python_data_marker_detected()` …)" gives the planner-confirmed insertion model: add an analogous sentence "plus python-observability-patterns (load per the intersection-table predicate via `python_observability_marker_detected()` OR when D3=server — provides metric / span / log code idiom rules: do-not-use-Summary in distributed deployments, label cardinality, span lifecycle anti-patterns, structured-log required fields, redaction-pipeline shape)."
- **auditor-ops** (line 393) — append to the dimensional list. The existing line `Dimensional (filtered by D5): deployment-apple, deployment-python` becomes `Dimensional (filtered by D5): deployment-apple, deployment-python, python-observability-patterns`. Also update the prose at line 394 ("Always loaded for every audit because every project deploys somewhere. The deployment skills cover the platform-specific deployment configuration rules and observability *configuration* (vs. observability *infrastructure*, which lives in the architecture skills loaded by `auditor-architecture`).") — the prose was written before BD-162 split the observability content into its own patterns skill; replace the parenthetical with: "(vs. observability *infrastructure*, which lives in `python-observability-patterns` for D2=python projects and in the platform architecture skills for non-Python projects)." This is editorial-only — does not change loading semantics.
- **docs-researcher** (line 345) — extend `Dimensional (filtered): deployment-apple, deployment-python, dependency-swift, dependency-python` to `Dimensional (filtered): deployment-apple, deployment-python, python-observability-patterns, dependency-swift, dependency-python`.

E4. **`scripts/lib/detect.sh`** — add the new `python_observability_marker_detected()` helper paralleling `python_data_marker_detected` (line 356) and `swiftdata_marker_detected` (line 585). Insertion point: immediately after `swiftdata_marker_detected()` (line 647) and before `detect_target_pack_version()` (line 668), so the four marker helpers are grouped contiguously. Helper specification (planner-supplied for coder implementation):
- Function name: `python_observability_marker_detected`.
- Single positional argument: target project directory; defaults to cwd.
- Tolerates missing target as `python-observability-marker: no` (no error to stderr).
- Output: single line `python-observability-marker: yes` or `python-observability-marker: no`.
- Markers (any one true → yes):
  - **(a) Dependency manifests.** `requirements.txt`, `pyproject.toml`, `setup.py`, `setup.cfg`, `uv.lock` lists any of: `opentelemetry-api`, `opentelemetry-sdk`, `opentelemetry-distro`, `opentelemetry-instrumentation*` (prefix match — any package starting with `opentelemetry-instrumentation`), `opentelemetry-exporter-*` (prefix match), `prometheus-client`, `prometheus_client`, `structlog`, `python-json-logger`. Use the BD-141 / BD-156 negated-character-class boundary construction `(^|[^A-Za-z0-9_-])(<pkgs>)($|[^A-Za-z0-9_.-])` for the exact-name packages; for prefix-match packages (`opentelemetry-instrumentation*`, `opentelemetry-exporter-*`), use a leading-boundary anchor with a trailing `[A-Za-z0-9_-]*` consumed continuation (e.g., `(^|[^A-Za-z0-9_-])opentelemetry-(instrumentation|exporter)-[A-Za-z0-9_.-]+`). Test fixture for boundary correctness: `opentelemetry-distro-extension` should match (legitimate sub-package); `not-opentelemetry-api-clone` should NOT match (substring inside another name). Coder verifies both behaviors in test-detect.sh.
  - **(b) Source file imports.** Any `.py` file in the project tree (excluding `node_modules/`, `.git/`, `build/`, `.venv/`, `venv/`, `.tox/` per the BD-156 prune list) contains a line matching `^[[:space:]]*(import|from)[[:space:]]+(opentelemetry|prometheus_client|structlog)([[:space:]]|\.|,|$)`. Line-anchored to defeat prose mentions in comments / docstrings (per BD-141 marker-c convention). The pattern matches `import opentelemetry`, `from opentelemetry import …`, `from opentelemetry.foo import …` (via the `\.` alternative), `import prometheus_client`, `from prometheus_client import …`, `import structlog`, `from structlog import …`.
- Function-doc header above the helper (parallel to BD-156 / BD-157 doc headers): explain the predicate, name BD-162 + the architecture document, name the callers (`scripts/init-project.sh::pack_skill_coverage_for python` and PLATFORM-SKILLS.md citation), and list the marker classes (a) and (b).

E5. **`scripts/init-project.sh`** — extend `pack_skill_coverage_for()` (line 235) python case to include `python-observability-patterns` when the marker fires OR when D3=server is in scope. Touch points (the python case currently reads lines 269–283):
- Add a `local obs_marker_line` capture using `python_observability_marker_detected "$target_dir"`.
- Branch matrix (current python case has 2 branches — with/without data marker; new case has 4 logical branches — with/without each of {data, observability}):
  - To minimize the case-arm explosion and stay parallel to the BD-141 / BD-156 / BD-157 model, the planner specifies a **3-branch composition**: compute `data_yes` and `obs_yes` as 0/1 booleans first, then emit the comma-joined skill list with conditional appends. Pseudocode for the coder:
    ```
    local data_marker_line obs_marker_line
    data_marker_line=$(python_data_marker_detected "$target_dir")
    obs_marker_line=$(python_observability_marker_detected "$target_dir")
    local skills="python-best-practices"
    [[ "$data_marker_line" == "python-data: yes" ]] && skills="$skills,python-data-architecture"
    [[ "$obs_marker_line" == "python-observability-marker: yes" ]] && skills="$skills,python-observability-patterns"
    echo "$skills"
    ```
  - The "OR D3=server" branch is intentionally NOT computed inside `pack_skill_coverage_for`. `init-project.sh` does not have a D3 selector — it auto-detects from language markers only. The D3=server load path applies at PM-chat skill-selection time (PLATFORM-SKILLS.md drives the agent prompts), not at scaffold-time skill copying. `stage_s4_skills` (line 461) copies ALL pack skills to the per-CLI directories unconditionally, so `python-observability-patterns/SKILL.md` is always physically present after init; PM-chat decides which agents load it per project shape. The architect §4.1 "D3=server branch" is a PM-chat / agent-loading concern, not an init-project.sh concern. **Coder instruction.** Implement the 3-branch composition as shown — do not invent a D3=server check inside `pack_skill_coverage_for`.
- Add an explanatory comment block above the python case branch citing BD-162 and pointing at `scripts/lib/detect.sh::python_observability_marker_detected`, parallel to the existing BD-141 / BD-157 / BD-158 comment blocks above the swift / python cases.

E6. **`scripts/add-capability.sh`** — extend `capability_skills()` (line 121) Python-side mapping. Two touch points:
- `language:python` row (line 129) currently reads: `language:python)    echo "python-best-practices python-data-architecture dependency-python" ;;` — extend to `language:python)    echo "python-best-practices python-data-architecture python-observability-patterns dependency-python" ;;`. Rationale: the `language:python` capability is the coarse-tool path (explicit user intent to add Python); BD-141 set the precedent that data-architecture lands here even though it is intersection-loaded. The same logic applies to observability — when a developer explicitly opts into Python via add-capability, they get the full Python-skill family declaratively. The marker-gated intersection load still applies at PM-chat time.
- `role:python-server` row (line 191) currently reads: `role:python-server) echo "python-server-architecture python-data-architecture" ;;` — extend to `role:python-server) echo "python-server-architecture python-data-architecture python-observability-patterns" ;;`. Rationale: this row encodes the D2=python ∩ D3=server intersection (architect §3.7); architect §4.1 says the D3=server branch loads observability unconditionally. Adding the skill to this row matches that semantics for the explicit-D3 declaration path.
- Add a comment block above each modified row citing BD-162 + the architecture document, parallel to the existing BD-141 / BD-157 / BD-158 comment blocks already in place above lines 124 / 130 / 143 / 154 / 178 / 186.
- **Verify (read-only).** No other `case` arm in `capability_skills` references python-observability-patterns. The `capability_files` function (line 218) does NOT need a row for the new skill — the skill ships only as a SKILL.md file (no scripts, no manifests), and the `python` capability_files row already covers `pyproject.toml` etc. for the language-level setup. Skipping `capability_files` mirrors the BD-156 / BD-157 / BD-158 precedent (none of those skills added a `capability_files` row either).

E7. **`scripts/test-detect.sh`** — add test coverage for `python_observability_marker_detected`. Insertion point: immediately after the `swiftdata_marker_detected` block (currently ends near line 547) and before the `python_data_marker_detected` block (begins at line 548), or alternatively at the end of the file in a new `## ── python_observability_marker_detected (BD-162) ─────────` section. Coder picks placement parallel to BD-156 / BD-157 ordering — observability is added LAST in source order so test-section sequencing tracks BD chronology (BD-141 → BD-156 → BD-157 → BD-162). New test cases (planner-specified — these are the architect §9.4 success-criteria cases plus boundary-correctness cases parallel to BD-156 / BD-157):

  Positive cases (must report `python-observability-marker: yes`):
  - **T1.** `requirements.txt` lists `opentelemetry-api>=1.20`. (manifest marker — primary OTel package)
  - **T2.** `pyproject.toml` lists `opentelemetry-instrumentation-grpc` (prefix-match contrib package).
  - **T3.** `pyproject.toml` lists `prometheus_client>=0.20`.
  - **T4.** `requirements.txt` lists `structlog==24.0`.
  - **T5.** `pyproject.toml` lists `python-json-logger`.
  - **T6.** A `.py` file outside `tests/` contains `import opentelemetry` (source-import marker primary case).
  - **T7.** A `.py` file outside `tests/` contains `from opentelemetry.trace import get_tracer` (source-import dotted-path).
  - **T8.** A `.py` file outside `tests/` contains `import prometheus_client`.
  - **T9.** A `.py` file outside `tests/` contains `from structlog import get_logger`.
  - **T10.** `pyproject.toml` lists `opentelemetry-exporter-otlp-proto-grpc` (prefix-match exporter package).

  Negative cases (must report `python-observability-marker: no`):
  - **T11.** Empty directory — no manifests, no `.py` files. (Empty-dir baseline — architect §9.4 case 4.)
  - **T12.** Non-existent target — must tolerate without stderr (parallel to BD-156 / BD-157 missing-target tests at lines 322–325 / 418–419).
  - **T13.** Pure Apple project — Swift sources, `Package.swift`, no Python observability deps (architect §9.4 case 3).
  - **T14.** Python script with `requests` + `pytest` only — observability deps absent and no `import opentelemetry|prometheus_client|structlog` (architect §9.4 case 4).
  - **T15.** Boundary reject — `requirements.txt` lists `not-opentelemetry-clone==0.1` (substring-in-other-package; must NOT match `opentelemetry-api`).
  - **T16.** Boundary reject — a `.py` file contains a comment line `# we should add import opentelemetry someday` (line-anchored grep must reject prose mentions per BD-141 marker-c convention).
  - **T17.** Vendored prune — a `.py` file under `node_modules/some-pkg/` contains `import opentelemetry`; must NOT match (parallel to BD-156 vendored-prune test at lines 340–344).

  Test scaffolding: use the existing `mkfixture` / `assert_eq` helpers (parallel to BD-156 lines 318–410 and BD-157 lines 414–546). Each test gets its own isolated fixture directory.

E8. **`BACKLOG.md`** — flip BD-162 status to `Resolved` with batch-completion note. **PM-Chat-only.** Coder MUST NOT touch this file (CLAUDE.md commit-discipline §4 PM-only file boundaries; BACKLOG is in the off-limits list). Pack Chat performs this edit as the final post-coder step after the reviewer pass + fix cycle.
- Resolved-line text (PM-Chat-supplied at flip time): `Resolved: 2026-05-XX — python-observability-patterns skill (NN rules across 11 sections), intersection-loaded at D2=python ∩ (D3=server ∨ python_observability_marker_detected); deployment-python rule 21 + python-server-architecture rule 8 cross-referenced; PLATFORM-SKILLS.md updated (intersection-table row + dimensional inventory 19→20 + worked examples + 7 per-agent assignments + total 34→35); python_observability_marker_detected helper + N test cases; validate-pack 31/31; test-detect with new BD-162 cases passing.` (PM-Chat fills NN, XX, N from coder's implementation report.)

### 3.3 Cross-reference audit (no edits required, but planner-verified)

The following files were checked for stale-reference risk and are confirmed clean:

- **`README.md`** — read for the Repository Layout section. No skill names appear in the layout — only top-level directory names (`project-template/`, `scripts/`, `supporting-docs/`, `maintenance-docs/`). Adding a new skill subdirectory under `project-template/skills/` does not require README edit. **No edit required.**
- **`CHANGELOG.md`** — version-boundary file; coder MUST NOT touch (CLAUDE.md "What agents must never modify without explicit instruction"). PM Chat may add a v11.0 entry at version-ship time (separate workflow). **No edit required by this BD.**
- **`PACK-AGENTS.md`** — agent routing table. Reviewed: it does not enumerate per-agent skill loads (those live in PLATFORM-SKILLS.md Step 2). **No edit required.**
- **`PACK-CHAT.md`** — PM chat operating rules. Reviewed: it does not enumerate skills. **No edit required.**
- **Trinity files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` at pack-repo root or `project-template/` root)** — architect §8.3 confirms zero trinity files in scope. The new skill ships at the single canonical path; per-CLI fan-out is install-time. Confirmed by reading `project-template/CLAUDE.md` — no skill names are enumerated in the trinity body; the `## Skill loading` block points at PLATFORM-SKILLS.md as the authoritative source. **No edit required.** No trinity parallel-edit discipline applies.
- **`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md`** — referenced by Check 31 and by PLATFORM-SKILLS.md "Extending this file" prose. Architect §8.1 condition 3 confirms the new skill fits the existing intersection-cell pattern (predicate `D2=python ∩ (D3=server ∨ marker)`). **No edit required by this BD.** A future architecture-doc refresh might add a worked-example row, but BD-162 does not own that refresh.
- **`scripts/migrate-v10-to-v11.sh`** — architect §8.4 explicit: BD-161 (open) handles the install-gap closure for net-new v11 skills; its enumeration-driven discovery picks up `python-observability-patterns` mechanically. **No edit required by this BD.** Planner-verified: `BACKLOG.md` BD-161 entry (line 1394) describes the implementation as "enumerates skills from `project-template/skills/<name>/` against what's currently installed in the target's `<cli>/skills/` trees" — that enumeration is BD-skill-list-agnostic, so when BD-161's coder writes the migrator stage, the new skill ships through automatically without an edit to BD-161 itself.
- **`scripts/persona-contracts/contract-migration.sh`** — BD-161's File/Symbol field commits to extending this contract with a post-migration v11 skill-inventory parity assertion. Once that lands, the new skill is covered by enumeration. **No edit required by this BD.**
- **`maintenance-docs/v11-implementation/RELEASE-GATE.md`** — read for v11.0 release-gate item enumeration. Item count is locked at 5 per BD-159 (architect §3.2 sig. 5 carve-out). Adding a new skill is not a new gate item. **No edit required.**

**Net cross-reference footprint.** Zero additional files beyond architect §8.2's enumeration. The architect's "11 paths total" footprint is exhaustive.

---

## §4 Ordered implementation steps with approval gates

The coder executes the steps below in order. Each step has an explicit verification gate. The single commit lands after all 7 coder steps complete and validate; the 8th step is the PM-Chat-only post-coder finalization.

### Step S0 — Pre-flight checks (mandatory; commit-discipline skill §1)

Run all checks BEFORE any edit. Paste the output verbatim into the implementation report's pre-flight section.

```bash
pwd                                    # Must end in worktree path or v11-dev cwd
git rev-parse HEAD                     # Capture base SHA — paste into report
git rev-parse --abbrev-ref HEAD        # Verify v11-dev (or worktree-agent-* if running under worktree isolation)
git log --oneline -10                  # Verify expected ancestor commits present
ls project-template/skills/deployment-python/SKILL.md     # Must exist (E1 target)
ls project-template/skills/python-server-architecture/SKILL.md  # Must exist (E2 target)
ls project-template/docs/pack/PLATFORM-SKILLS.md          # Must exist (E3 target)
ls scripts/lib/detect.sh scripts/init-project.sh scripts/add-capability.sh scripts/test-detect.sh
ls maintenance-docs/v11-implementation/ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md  # Architect's locked decisions
ls maintenance-docs/v11-implementation/PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY.md  # This plan
test ! -d project-template/skills/python-observability-patterns  # NEW skill dir must NOT exist yet
grep -c "python-observability-patterns" project-template/docs/pack/PLATFORM-SKILLS.md  # Expect 0
```

**Failure mode handling.** If any check fails, STOP and write the failure into the implementation report's deviations section. Do not work around — the prompt is either wrong or the working tree drifted; resolution is Pack Chat's.

**Gate to S1.** Pre-flight clean — proceed.

### Step S1 — Add the new marker helper to `scripts/lib/detect.sh` (E4)

Edit `scripts/lib/detect.sh`. Insert `python_observability_marker_detected()` per the §3.2 E4 specification immediately after `swiftdata_marker_detected()` (currently ends at line 647) and before `detect_target_pack_version()` (currently begins at line 668).

**Verification (in-place):**
```bash
bash -n scripts/lib/detect.sh                               # Syntax check
source scripts/lib/detect.sh && declare -F python_observability_marker_detected  # Function defined
( cd /tmp && mkdir -p obs-test && cd obs-test && echo 'opentelemetry-api>=1.20' > requirements.txt \
  && bash -c 'source '"$PWD"'/../../scripts/lib/detect.sh && python_observability_marker_detected .' )
# Expect: python-observability-marker: yes
( cd /tmp && rm -rf obs-test-empty && mkdir -p obs-test-empty \
  && bash -c 'source '"$PWD"'/../../scripts/lib/detect.sh && python_observability_marker_detected /tmp/obs-test-empty' )
# Expect: python-observability-marker: no
```

**Rollback.** Revert the helper-insertion hunk; the file is well-defined function-by-function so a clean revert is straightforward. No state outside the file is mutated.

**Gate to S2.** Helper present, syntax OK, smoke test passes — proceed.

### Step S2 — Add new test cases to `scripts/test-detect.sh` (E7)

Add the 17 test cases per §3.2 E7. Use the existing `mkfixture` / `assert_eq` scaffolding parallel to the BD-156 protobuf section (lines 315–410) and the BD-157 swiftdata section (lines 411–547).

**Verification (in-place):**
```bash
bash scripts/test-detect.sh    # Must be 0 failures; total test count rises by 17
echo "Exit: $?"
```

**Note on intentional ordering.** S1 + S2 ship the helper + tests together so that test-detect.sh exercises the new helper from the moment it lands. If S1 ships alone, the next test-detect run still passes (no test references the new function); the gap is benign but the architect §8.1 cond. 5 contract assumes the helper has matching test coverage.

**Rollback.** Revert the test-detect.sh hunk only. S1 stays.

**Gate to S3.** test-detect.sh passes (positive count rises by 17, zero failures) — proceed.

### Step S3 — Author the new SKILL.md (N1) — the substantive content step

Create `project-template/skills/python-observability-patterns/` directory. Write `SKILL.md` per architect §5 outline + §2 / §3 decisions + planner §2.3 owner-tag convention + §5 (Applicability text below).

**Section order (per §2.1):** Frontmatter + Applicability → §A (SDK setup, 5–7 rules) → §B (span lifecycle, 8–10 rules) → §C (propagation, 3–4 rules) → §D (auto-instrumentation, 3–4 rules) → §E (exporters, 4–5 rules) → §F (metrics naming/labels/types, 12–15 rules across F.1/F.2/F.3) → §G (exposition, 4–5 rules) → §H (logging, 8–10 rules) → §I (sampling, 4–6 rules) → §J (SLO shape, 5–7 rules) → §K (retention, 3–5 rules).

**Per-rule discipline.**
- Continuous numbering 1–N (§2.3); section headings are `## §<letter> — <title>` (architect uses `## §F — Prometheus metrics: naming, labels, types` etc. — coder follows that exact heading shape).
- Each rule ends with one of `(ops)`, `(arch)`, `(code)`, `(both)` per §2.3.
- Library citation per architect §3.1 / ADP-1: OpenTelemetry canonical for tracing; library-agnostic for metrics + logging; cite the *shape* not specific method signatures.
- Two architect-supplied worked-example rules (§5.13 of the architecture doc) MUST appear verbatim — one in §F.2 (label cardinality) and one in §J (orphaned-SLO). Their final continuous numbers depend on the rule counts in preceding sections.
- Anti-rule discipline: do NOT author rules on any topic in architect §6 (native histogram client API specifics, `tracestate "ot"` key, OTel Logs SDK as sole log path, eBPF auto-instrumentation, specific SLO framework choice, vendor-specific exporter detail, log aggregation platforms, profiling, RUM, log-content classification, CVE detection, health-check endpoints, container resource limits, gRPC interceptor placement). If during authoring a rule feels like it should exist on an excluded topic, SendMessage the architect — do NOT add it unilaterally.

**Cross-reference text (verbatim from architect §7.1 — coder uses without rewriting).** The Applicability section MUST contain these four prose blocks in order (planner-supplied; literal text from architect §7.1):

> Where observability concerns are *placed* in the request flow (interceptors, middleware, app-entry-point hooks, layer boundaries) is governed by `python-server-architecture` rule 8. This skill defines the substantive *content* of those wirings — span shape, metric type, log field set.
>
> Deployment-readiness concerns adjacent to observability — Docker layout, secrets management, health checks, graceful shutdown, container resource limits, env-var-driven production config — live in `deployment-python`. The cross-reference is bidirectional: this skill rules observability content; that skill rules deployment plumbing.
>
> Sensitive-data classification ("which keys count as credentials / tokens / PII?") is owned by `security-patterns` per `audit-methodology` rule 33. This skill rules the *redaction-pipeline shape* (a processor exists; it runs early; it is testable); the security skill rules the *content classification*. Auditor-security cross-detects log-content findings and annotates them per audit-methodology rule 33.
>
> Audit-methodology rule 21's ownership rubric (`(ops)` if the fix changes a value read from configuration; `(arch)` if the fix changes a type / call graph / wiring) determines which loading agent applies which rules. Each rule below is tagged `(ops)`, `(arch)`, `(code)`, or `(both)` — the loading agent applies its tagged subset.

**Verification (in-place):**
```bash
test -f project-template/skills/python-observability-patterns/SKILL.md   # Exists
wc -l project-template/skills/python-observability-patterns/SKILL.md     # Expect 350–420 lines
head -5 project-template/skills/python-observability-patterns/SKILL.md   # Frontmatter present (---, name, description, allowed-tools, ---)
grep -c '^[0-9]\+\. ' project-template/skills/python-observability-patterns/SKILL.md  # Expect 55–65 (rule count)
grep -c '`(ops)`\|`(arch)`\|`(code)`\|`(both)`' project-template/skills/python-observability-patterns/SKILL.md
# Expect approximately equal to rule count — every rule should carry exactly one tag
```

If chunked authoring is required (file is >300 lines), use multiple Write calls — first call creates the file with frontmatter through §C; subsequent calls Edit-append the remaining sections. (Per the chunk-long-outputs convention in `feedback_chunk_long_outputs.md`.)

**Rollback.** `rm -r project-template/skills/python-observability-patterns/`. The new directory is self-contained; no other state changes.

**Gate to S4.** SKILL.md present, frontmatter clean, rule count in 55–65, every rule tagged with one of the four owner tags — proceed.

### Step S4 — Edit `deployment-python/SKILL.md` rule 21 (E1)

Replace rule 21 (line 41) with the verbatim cross-reference text per §3.2 E1. Do not change rules 19, 20, 22, 23. Do not change the `## Production configuration` section heading.

**Verification (in-place):**
```bash
grep -n "python-observability-patterns" project-template/skills/deployment-python/SKILL.md
# Expect 1 hit on the new rule 21 line
grep -c '^[0-9]\+\. ' project-template/skills/deployment-python/SKILL.md   # Expect 23 (unchanged total)
sed -n '41p' project-template/skills/deployment-python/SKILL.md            # Spot-check the new rule 21 line
```

**Rollback.** Revert the single-rule diff hunk.

**Gate to S5.** Rule 21 replaced; rule count unchanged at 23 — proceed.

### Step S5 — Edit `python-server-architecture/SKILL.md` rule 8 (E2)

Replace rule 8 (line 46) with the verbatim extension text per §3.2 E2. Do not change rules 7, 9, 10, etc.

**Verification (in-place):**
```bash
grep -n "python-observability-patterns" project-template/skills/python-server-architecture/SKILL.md
# Expect 1 hit on the new rule 8 line
sed -n '46p' project-template/skills/python-server-architecture/SKILL.md   # Spot-check
```

**Rollback.** Revert the single-rule diff hunk.

**Gate to S6.** Rule 8 extended — proceed.

### Step S6 — Edit `PLATFORM-SKILLS.md` (E3 a/b/c/d, four parallel edits)

Apply E3.a (intersection table row), E3.b (dimensional inventory row + count bumps + total-skills bump + intersection-count narrative bump), E3.c (two worked examples), E3.d (seven per-agent assignments). All four edits in one file in one step — no intermediate validation between sub-edits because all four are required for Check 31 to pass.

**Verification (in-place):**
```bash
grep -c "python-observability-patterns" project-template/docs/pack/PLATFORM-SKILLS.md
# Expect ~12+ hits (1 intersection-table row + 1 dimensional-inventory row + 2 worked examples + 7 per-agent assignments + scattered prose)
grep -E "^### Dimensional skills \([0-9]+\)" project-template/docs/pack/PLATFORM-SKILLS.md
# Expect: ### Dimensional skills (20)
grep -E "^\*\*Total skills: [0-9]+\*\*" project-template/docs/pack/PLATFORM-SKILLS.md
# Expect: **Total skills: 35**
```

**Rollback.** Revert the four hunks. They are non-overlapping; revert is straightforward.

**Gate to S7.** All four hits present; counts updated — proceed.

### Step S7 — Edit `scripts/init-project.sh` (E5) and `scripts/add-capability.sh` (E6)

Apply E5 (init-project.sh `pack_skill_coverage_for python` 3-branch composition) and E6 (add-capability.sh `language:python` + `role:python-server` capability rows). Both edits are in the python skill-mapping logic; group them in a single editorial step.

**Verification (in-place):**
```bash
bash -n scripts/init-project.sh                # Syntax check
bash -n scripts/add-capability.sh              # Syntax check
grep -c "python-observability-patterns" scripts/init-project.sh        # Expect ≥2 (case body + comment)
grep -c "python-observability-patterns" scripts/add-capability.sh      # Expect ≥2 (language:python row + role:python-server row, plus comments)
```

**Rollback.** Revert both file hunks. They are independent; reverting one does not affect the other.

**Gate to S8.** Syntax checks pass; greps confirm presence — proceed.

### Step S8 — Full validate-pack + test-detect run

Run all pack-level CI checks. Every check must pass before the coder writes the implementation report.

**Verification:**
```bash
python3 scripts/validate-pack.py 2>&1 | tail -50    # Expect "31/31 PASS" or equivalent green result
echo "validate-pack exit: $?"
bash scripts/test-detect.sh 2>&1 | tail -10         # Expect 0 failures, test count up by 17
echo "test-detect exit: $?"
```

**Specific Check 31 expectation.** The Dimensional skills subsection should report `20 rows (header matches)`; the total-skills assertion should report 35; no orphan / phantom / double-counted / drift failures.

**Failure mode handling.** If validate-pack fails, fix the underlying defect in place (do NOT split the commit, do NOT skip the check). Common failure modes the planner anticipates:
- Check 31 dimensional count mismatch → header text "Dimensional skills (20)" not bumped from 19 → 20. Fix: bump E3.b header literal.
- Check 31 total-skills mismatch → `**Total skills: 35**` line not updated. Fix: bump E3.b total bump.
- Check 27 extension (Skills-to-load conformance, line 1379) failure → a per-agent assignment in E3.d points at `python-observability-patterns` but the skill name does not appear in the dimensional inventory subsection (or vice versa). Fix: ensure E3.b row is present AND E3.d assignments use the exact skill name.

**Gate to S9.** validate-pack 31/31 PASS; test-detect zero failures; +17 test count delta — proceed.

### Step S9 — Coder writes the implementation report (N3)

Per the `implementation-report` skill, the coder writes `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-DEPLOYMENT-PYTHON-OBSERVABILITY.md` with:
1. Pre-flight evidence (paste S0 output verbatim).
2. Per-step results (paste S1–S8 verifications).
3. Validate-pack output verbatim (full Check 31 block).
4. test-detect output verbatim (last block confirming +17 tests, zero failures).
5. Deviations from this plan (any step that needed adjustment).
6. POQs (any architect-locked decision the coder questioned during authoring; SendMessage to architect; record outcome).
7. Final file count: 1 NEW + 7 EDITED = 8 files staged for commit (BACKLOG.md is the PM-Chat-only 9th, not staged by coder).

**Gate to PM Chat.** Implementation report written; working tree clean of any uncommitted scratch files. Coder DOES NOT run `git add` / `git commit` (commit-discipline §3 absolute ban). Coder reports back to Pack Chat with: "ready for review."

### Step S10 — Pack Chat: reviewer pass + fix cycle (per CLAUDE.md pack memory)

PM Chat runs `pack-reviewer` once with the architecture + plan as inputs (NOT prior reviews — `feedback_no_prior_reviews_to_reviewer.md`). One fix cycle per CLAUDE.md "One review/fix cycle per batch." Reviewer spot-checks rule right-fit calibration per architect §9.4.

### Step S11 — Pack Chat: stage + commit + BACKLOG flip

PM Chat stages the 8 coder-touched paths (1 NEW + 7 EDITED) plus the implementation report, commits with the message format below, and flips BD-162 to Resolved in BACKLOG.md as the final post-batch action (CLAUDE.md "Implicit BD status flip on batch completion").

**Suggested commit subject (PM Chat may polish):**
```
feat: v11 — BD-162 python-observability-patterns skill + cross-references (Batch 8)
```

The Resolved-flip line follows the §3.2 E8 template. The full BACKLOG flip is a separate small commit per pack convention (see BD-156 / BD-157 / BD-158 commits where the Resolved flip landed in commits `4d93862` / `5a286cb` / `8014186` separate from the feature commits).

---

## §5 Verification plan summary

| Verification | Where | When | Pass criterion |
|---|---|---|---|
| Pre-flight checks | S0 (coder) | Before any edit | All `ls` / `git rev-parse` / `grep -c` results match expectations |
| Helper smoke test | S1 (coder) | After E4 | `python_observability_marker_detected /tmp/obs-test` returns `yes`; missing-target returns `no` |
| test-detect green | S2, S8 (coder) | After E7; final | Exit 0; +17 tests vs. baseline; zero failures |
| SKILL.md shape | S3 (coder) | After N1 | Frontmatter present; 55–65 numbered rules; every rule tagged with one of (ops)/(arch)/(code)/(both); two architect-supplied worked examples present verbatim |
| Cross-reference verbatim | S4 (E1), S5 (E2) | After cross-ref edits | `grep "python-observability-patterns"` returns exactly the architect §7.2 / §7.3 wording |
| validate-pack 31/31 | S8 (coder) | Final | Check 31 reports `Dimensional skills: 20 rows (header matches)`; total-skills 35; no orphan/phantom/double-counted/drift |
| Check 27 extension green | S8 (coder) | Final | Skills-to-load conformance: every per-agent assignment of python-observability-patterns matches the dimensional inventory |
| Implementation report complete | S9 (coder) | Final | All 7 sections of the implementation-report skill template populated |
| Reviewer one-pass + fix | S10 (PM Chat) | Post-coder | Reviewer report shows no critical defects after fix; right-fit calibration spot-check (10 random rules) clean |
| BACKLOG flip | S11 (PM Chat) | Post-review | BD-162 Status: Resolved with the §3.2 E8 line; CHANGELOG update deferred to v11.0 ship |

**Manual / cross-grep audits (PM Chat or reviewer):**
```bash
# Stale-reference scan: nothing in pack-product files mentions python-observability-patterns
# at a path other than the new canonical one.
grep -rn "python-observability-patterns" project-template/ scripts/ --include='*.md' --include='*.sh' \
  | grep -v "project-template/skills/python-observability-patterns/SKILL.md" \
  | grep -v "project-template/docs/pack/PLATFORM-SKILLS.md" \
  | grep -v "project-template/skills/deployment-python/SKILL.md" \
  | grep -v "project-template/skills/python-server-architecture/SKILL.md" \
  | grep -v "scripts/lib/detect.sh" \
  | grep -v "scripts/init-project.sh" \
  | grep -v "scripts/add-capability.sh" \
  | grep -v "scripts/test-detect.sh"
# Expect: zero output (no stray references in unexpected locations)

# Trinity-rule sanity scan: the new skill must NOT appear in any trinity body.
grep -l "python-observability-patterns" project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md CLAUDE.md AGENTS.md GEMINI.md 2>/dev/null
# Expect: zero output (architect §8.3: no trinity files in scope)
```

---

## §6 Open risks and unknowns

The planner names every risk surfaced during planning. Each carries a mitigation; none block coder execution.

### R1 — Owner-tag distribution may drift from architect intent
**Risk.** The architect §5.2–§5.12 names per-section owner-tag mixes (e.g., §A "mostly `(both)`"; §F "mostly `(code)` and `(arch)`"; §J "all `(ops)`"). The coder authoring 55–65 rules may distribute tags differently than intended.
**Mitigation.** S10 reviewer spot-check (architect §9.4) samples 10 random rules and verifies the tag matches the rule's actual ownership semantics under the audit-methodology rule 21 rubric. Mis-tagged rules are surfaced as fix-pass items.
**Rollback.** Owner-tag fixes are in-place text edits to single rule lines; no structural rework needed.

### R2 — Rule count outside 55–65 band
**Risk.** Architect §5.14 estimates 59 rules; the coder may write fewer (under-specified) or more (over-specified). Architect §5.14 explicitly allows "discovery during coder authoring; final count likely 50–65."
**Mitigation.** The 55–65 envelope is the architect-locked scope (§9.1 "comprehensive"). If the coder exceeds 65, the reviewer flags scope creep; if the coder writes fewer than 50, the reviewer flags coverage gaps relative to architect §3.4 sub-domain rule-count targets. Either case → fix in S10.
**Rollback.** Rule additions/deletions are line-level; no structural rework.

### R3 — Owner-tag vocabulary discovery
**Risk.** During authoring, the coder may discover a rule that doesn't fit any of `(ops)` / `(arch)` / `(code)` / `(both)` cleanly (e.g., a rule about a deployment-config value that also implies a code-level structural change).
**Mitigation.** Architect §9.5 names this exact ambiguity as still-clarifiable. Coder SendMessages the architect (UUID `abb1784cc4138af31`); architect resolves; coder applies. Do NOT invent a fifth tag value.
**Rollback.** N/A — resolution lands as a normal in-rule text fix.

### R4 — Marker prefix-match implementation correctness
**Risk.** The `opentelemetry-instrumentation*` and `opentelemetry-exporter-*` prefix-match marker patterns (E4 marker (a)) are more complex than the BD-141 / BD-156 / BD-157 exact-name patterns. A grep regex error could over- or under-match.
**Mitigation.** Test cases T2 (`opentelemetry-instrumentation-grpc`) and T10 (`opentelemetry-exporter-otlp-proto-grpc`) are positive prefix-match tests; T15 (`not-opentelemetry-clone`) is the substring-rejection negative. The coder must verify all three pass before S8. If the prefix-match regex misbehaves, fall back to listing common contrib packages explicitly (e.g., `opentelemetry-instrumentation-grpc|opentelemetry-instrumentation-fastapi|opentelemetry-instrumentation-django|opentelemetry-instrumentation-flask|opentelemetry-instrumentation-logging|opentelemetry-instrumentation-requests|opentelemetry-instrumentation-sqlalchemy|opentelemetry-instrumentation-psycopg2|opentelemetry-exporter-otlp|opentelemetry-exporter-prometheus`) using the BD-141 negated-character-class boundary construction. Document the choice in the helper docstring.
**Rollback.** Marker pattern fix is a one-liner in `scripts/lib/detect.sh`.

### R5 — Validate-pack Check 27 extension surprise
**Risk.** Check 27's BD-146 extension (Skills-to-load conformance, line 1379 in validate-pack.py) cross-checks per-agent assignments against the dimensional inventory. If E3.b and E3.d disagree on the skill name spelling (typo: `python-observabilty-patterns`), Check 27 fires.
**Mitigation.** S8 explicitly runs full validate-pack. The exact failure mode is named in the Step S8 failure-handling block. Fix in place.

### R6 — `auditor-ops` prose update editorial subjectivity
**Risk.** E3.d's `auditor-ops` prose update (rewriting "(vs. observability *infrastructure*, which lives in the architecture skills loaded by `auditor-architecture`)" to a python-observability-patterns-aware variant) is the only editorial-judgment edit in the plan. The reviewer may have a different preference.
**Mitigation.** The planner-supplied wording preserves the rule 21 ownership rubric semantics and adds the new-skill mention. If the reviewer prefers different phrasing, fix in S10 — the wording is editorial-only, not load-semantic.

### R7 — Live architect / docs-researcher sub-agents stay alive across the coder run
**Risk.** Architect (UUID `abb1784cc4138af31`) and docs-researcher (UUID `aba8ef1124ab310ce`) are alive per architect §9.5 and the prompt. If they are torn down before the coder finishes (e.g., session timeout), POQs that need their input fall through to user-initiated resolution, slowing the batch.
**Mitigation.** Pack Chat keeps both sub-agents alive through coder run + reviewer pass + fix cycle (per `feedback_agent_teams_stage_lifecycle.md`). If a sub-agent is torn down, the POQ surfaces in the implementation report and PM Chat re-spawns or escalates to user.

### R8 — BD-161 enumeration is currently-untested; new skill correctness is conditional on BD-161 landing well
**Risk.** Architect §8.4 says BD-161's enumeration-driven discovery picks up the new skill mechanically. If BD-161's coder mis-implements the enumeration (e.g., hardcodes the four current new-v11 skills instead of enumerating), the new BD-162 skill ships only to greenfield init-project users, not to v10→v11 migrating clients.
**Mitigation.** Out of scope for BD-162 (architect explicit: "BD-162 coder does not need to edit BD-161"). Surface as a follow-up assertion in BD-161's tests when that BD lands. The PM-Chat post-batch BACKLOG flip note for BD-162 mentions the BD-161 dependency for traceability.

### R9 — Section-placement defects per architect §8.5
**Risk.** Architect §8.5 explicitly names placement defects: a Prometheus-specific rule in §A (SDK setup) or §I (sampling); an OTel-specific rule in §F (metrics naming) or §G (exposition); a structlog-specific rule outside §H. These would entangle the future-sibling-lift seam.
**Mitigation.** S10 reviewer spot-check includes a section-placement scan (10 random rules; verify each fits the section's topical scope). Mis-placed rules → fix in S10.

---

## §7 Architect / docs-researcher escalation channels

Per architect §9.5 and the prompt, both sub-agents stay alive across this stage:

- **BD-162 architect** — UUID `abb1784cc4138af31`. SendMessage for: section-placement clarifications, owner-tag mix questions on borderline rules, rule wording calibration questions, anti-rule clarifications.
- **BD-162 docs-researcher** — UUID `aba8ef1124ab310ce`. SendMessage for: research deepening (e.g., specific OpenTelemetry semconv namespace updates since the research date; SLO framework adoption signals; Prometheus naming-convention edge cases).

The coder uses these channels for genuine ambiguity. Decisions already locked in §9.1 of the architecture or in §2 of this plan are NOT escalation material — those are final and the coder applies them mechanically.

---

## §8 Out-of-scope items surfaced during planning (informational)

Not BD-162 work; flagged so Pack Chat has the option:

1. **`audit-methodology/SKILL.md` rule 21 informational pointer** (architect §7.4). Optional sentence appending the new-skill name. Not BD-162 — open as a separate cleanup BD if Pack Chat wants the explicit pointer.
2. **`apple-observability-patterns` symmetric Apple skill** (architect §6.4). Future BD if a real Apple project surfaces a defect the pack can't catch today.
3. **`profiling-patterns`** (architect §6.4). Future BD if continuous profiling becomes a documented pack concern.
4. **Tier 0 `observability-architecture`** (architect §6.4). Defer to v12+ once enough language-specific observability skills exist to factor commonality from.
5. **Sibling-skill split** (architect §8.5: `python-otel-patterns`, `python-prometheus-patterns`, `python-structlog-patterns`). Architect §8.5 explicitly says the v11 single-skill design stands; siblings are deferred to first real demand signal. The §A–§K section structure is the seam along which a future split is mechanical.

These items are NOT new BDs proposed by the planner — they are architect-flagged future considerations preserved here for traceability.

---

## §9 BD scope verification — every architect §9.1 locked decision is addressed

| Architect §9.1 locked decision | Plan section that preserves it |
|---|---|
| Skill placement (NEW skill at `project-template/skills/python-observability-patterns/SKILL.md`) | §3.1 N1 + §4 S3 |
| Loading semantics (intersection-cell `D2=python ∩ (D3=server ∨ python_observability_marker_detected())`) | §3.2 E3.a + §3.2 E4 + §4 S1 + §4 S6 |
| Scope envelope (comprehensive ~55–65 rules across 11 sections) | §2.1 + §3.1 N1 + §4 S3 + §6 R2 |
| Library citation policy (OpenTelemetry canonical for tracing; library-agnostic for metrics + logging; rule the *shape*) | §4 S3 (per-rule discipline block) |
| Cross-reference text verbatim (architect §7.2 / §7.3) | §3.2 E1 + §3.2 E2 + §4 S4 + §4 S5 |
| Boundary handling (in-skill-body per-rule `(ops)` / `(arch)` / `(code)` / `(both)` tagging) | §2.3 + §4 S3 + §6 R1 / R3 |
| Anti-rule list (architect §6 final) | §4 S3 (per-rule discipline block, anti-rule subsection) |

Every locked decision maps to a concrete plan element. No locked decision is silently ignored or re-litigated.

---

**End of plan.** Coder proceeds in stage 4. Pack Chat owns the post-coder reviewer pass, fix cycle, commit, and BACKLOG flip.
