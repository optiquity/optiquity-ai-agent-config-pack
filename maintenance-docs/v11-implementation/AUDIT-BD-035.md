# AUDIT-BD-035 — python-architecture skill loading for non-server Python

**Branch:** v11-dev | **HEAD:** 9c7f56a | **Auditor:** pack-architect (Batch 14, EXECUTION-PLAN-V11.0.md) | **Date:** 2026-05-12 | **Mode:** desk-audit (no non-server Python project in repo)

---

## §0 One-line summary

**CLEAN WITH NITS** — the post-reframe split (`python-server-architecture` + `python-data-architecture` + `python-best-practices`) closes the original BD-035 gap for the canonical "non-server multi-file Python" cases (data pipelines, ML, ETL, async I/O scripts), but two real gaps remain: (a) the `python_data_marker_detected()` predicate has a marker blind-spot for pure-stdlib Python CLI/script projects with <5 `.py` files (or ≥5 with no listed deps) where useful `python-data-architecture` rules still apply, and (b) two narrow performance anti-patterns (blocking I/O in `async def` outside servers; accidental O(n²) iteration / GIL-bound CPU work) live in `python-best-practices` rules 6/26 only at the *idiom* level, with no skill home for the *audit-level* rule.

---

## §1 Audit scope + methodology

**Original BD-035 scope (v10 era).** Validate that `python-architecture` (single skill at the time) is loaded for `auditor-code` on non-server multi-file Python projects, where N+1 queries, blocking I/O in async, and similar anti-patterns apply just as much as in server projects. The deferral required "first v9 non-server multi-file Python project runs a full audit" — no such project exists in the pack repo or its known consumers, so audit is desk-only.

**Post-reframe scope (this audit).** During v11.0 the skill was split (per BD-141 + BD-156 cluster) into:

- `python-server-architecture` — server-only rules (servicers, grpc.aio handlers, interceptors, background tasks). Loads at **D2=python ∩ D3=server**.
- `python-data-architecture` — data and I/O rules (repository pattern, N+1 prevention, Pydantic placement, ML inference isolation). Loads at **D2=python ∩ ((D3=server) ∨ data-marker present)** via `scripts/lib/detect.sh::python_data_marker_detected()`.
- `python-best-practices` — language idioms, async patterns, error handling, capabilities, dead code. Loads unconditionally at **D2=python**.

The post-split design materially shifts the BD-035 question. It is no longer "does `python-architecture` load for non-server?" but rather:

1. Does `python-data-architecture` load reliably for the non-server-but-multi-file cases the original BD-035 named (data pipelines, ML, ETL)?
2. Are the rule clusters split correctly — i.e., do any genuinely non-server-specific rules still live in `python-server-architecture` where they'd be missed on non-server projects?
3. Does the marker predicate `python_data_marker_detected()` catch the realistic "non-server multi-file Python" universe, or are there blind-spots?
4. Are the auditor-code agent files (.claude / .codex / .gemini) and the per-agent table in PLATFORM-SKILLS.md mutually consistent for D2=python?

**Method.** Read the post-reframe sources (PLATFORM-SKILLS.md tables, the three python-* SKILL.md files, the marker predicate, init-project.sh's `pack_skill_coverage_for python)` case, and the trinity auditor-code files). Walk the loading chain for representative non-server Python project shapes. Cross-check rule placement against the original BD-035 anti-pattern list (N+1, blocking I/O in async, etc.). Identify finding by severity per `audit-methodology` rules 48-51. No source files modified; no code proposals beyond the disposition menu.

---

## §2 Current loading rule for D2=python + auditor-code

Walking the chain in priority order:

**PLATFORM-SKILLS.md D2=python row (line 100):**
> `python` | python-best-practices, dependency-python *(plus python-data-architecture via the intersection table when `python_data_marker_detected()` is true; plus python-server-architecture via the intersection table when D3=server)*

**Intersection table (lines 220-221):**
> `python-server-architecture` — Predicate: D2=python ∩ D3=server
> `python-data-architecture` — Predicate: D2=python ∩ ((D3=server) ∨ data-marker present); canonical predicate `scripts/lib/detect.sh::python_data_marker_detected()`

**Per-agent assignment for `auditor-code` (PLATFORM-SKILLS.md lines 363-367):**
> Tier 0 base: error-handling, security-patterns
> Dimensional (filtered): swift-best-practices, swift-concurrency-patterns *(D1-implied)*, **python-best-practices**, c-language, objc-language, cpp-language; **plus python-data-architecture (load per the intersection-table predicate via `python_data_marker_detected()`)**; **plus python-server-architecture (load only when D3=server)**; plus protobuf-patterns; plus apple-swiftdata-patterns.

**`python_data_marker_detected()` (scripts/lib/detect.sh lines 341-393).** Returns `python-data: yes` if **any** of:
- (a) `requirements.txt` / `pyproject.toml` / `setup.py` / `setup.cfg` lists any of: `sqlalchemy, alembic, pydantic, aiohttp, httpx, psycopg, psycopg2, aiomysql, asyncpg, redis, pymongo, motor, boto3, aioboto3, grpc-tools, protobuf, pyarrow, pandas, numpy, scikit-learn, torch, tensorflow` (case-insensitive, name-boundary anchored).
- (b) ≥5 `.py` files outside `tests/` (excluding `test_*.py` / `*_test.py`).

**`scripts/init-project.sh::pack_skill_coverage_for python` (lines 269-283):** echoes `python-data-architecture,python-best-practices` when the marker fires; otherwise `python-best-practices` alone. This is the *coverage advertisement* — the per-agent rule above is the actual loader at audit time.

**Concrete walk — non-server Python data-pipeline (e.g. ETL with pandas):**
1. D2=python → python-best-practices, dependency-python.
2. D3=cli-tool (no server). No `python-server-architecture` (correct — server rules don't apply).
3. `python_data_marker_detected()` → yes (pandas in pyproject.toml) → python-data-architecture loads.
4. auditor-code loads: audit-methodology (trigger), error-handling + security-patterns (Tier 0), python-best-practices, python-data-architecture. **N+1 + repository-pattern + ML-isolation rules covered.**

**Concrete walk — non-server Python CLI tool, pure stdlib, 3 `.py` files (e.g. an `argparse` log-grep utility):**
1. D2=python → python-best-practices, dependency-python.
2. D3=cli-tool. No server.
3. `python_data_marker_detected()` → no (no listed deps; <5 files).
4. auditor-code loads: audit-methodology, error-handling + security-patterns, python-best-practices only.
5. **`python-data-architecture` does NOT load.** Repository-pattern + N+1 rules are out of scope (no DB), so this is mostly correct — but rule 6 (Pydantic placement at I/O boundaries) and rule 7 (ML inference isolation) are not loaded. For this shape neither rule applies, so the elision is justified. **Risk window:** a small CLI tool that *grows* a single `subprocess` or single `requests.get()` call without ever crossing the 5-file or marker-package threshold — see §5.

**Concrete walk — non-server async multi-file Python script using stdlib `asyncio` + `urllib.request` (no httpx/aiohttp), 6 `.py` files:**
1. D2=python.
2. D3=cli-tool.
3. Marker (b) fires (≥5 files) → `python-data-architecture` loads.
4. python-best-practices rule 6 ("All I/O-bound operations use `async def`") + rule 26 ("Blocking synchronous I/O in async handlers is an anti-pattern — offload or convert") catch the `urllib.request` blocking call.
5. Coverage is sufficient. **Note** the rule lives in `python-best-practices` not `python-data-architecture` — see Finding F2.

---

## §3 Findings

### F1 — Marker predicate misses small pure-stdlib Python with data-shaped concerns
**Severity:** SHOULD-FIX
**Evidence:** `scripts/lib/detect.sh::python_data_marker_detected()` lines 341-393; `project-template/skills/python-data-architecture/SKILL.md` Applicability §2 ("Non-trivial multi-file Python — exceeding a small CLI script and exercises any of: persistent data access (SQLite, ORM, files-as-DB), async I/O patterns, repository / service-layer separation, or ML inference").

The predicate uses two markers: (a) listed data-tooling dependency, or (b) ≥5 `.py` files outside `tests/`. The skill's own applicability prose calls out **SQLite via stdlib `sqlite3`** as an in-scope case ("files-as-DB"). But `sqlite3` is stdlib — it never appears in `requirements.txt` / `pyproject.toml`. A 4-file CLI tool that uses `sqlite3` to persist user state will:

- fail marker (a) — no listed dep,
- fail marker (b) — 4 files < 5 threshold,
- not load `python-data-architecture`,
- miss N+1 / repository-pattern / no-direct-driver findings even though the skill's own applicability statement says it should apply.

Same gap applies to: stdlib `json` / `csv` / `pickle` flat-file data stores; stdlib `urllib.request` / `http.client` external-API calls; stdlib `asyncio` without third-party async lib. All are explicitly named in the skill's applicability prose ("files-as-DB", "async I/O patterns") but invisible to the marker.

**Disposition:** Extend the `python_data_marker_detected()` predicate (predicate-extension disposition from the menu). Add marker (c): grep `*.py` files for `import sqlite3`, `import asyncio`, `import urllib`, `import http.client`, `import csv`, `import json` (the last two are too noisy on their own — restrict to combinations with file-write operations, or accept them only when ≥3 `.py` files exist as a softer threshold). The exact marker set is a planner/coder decision; what matters here is the gap is real and the predicate is the right place to fix it.

Alternative disposition: **No change needed** — accept that very small pure-stdlib CLIs are below the audit signal-to-noise floor. The skill applicability prose ("multi-file Python project") implicitly excludes single-file or 2-3 file scripts. Document the decision in the predicate's header comment so future maintainers don't re-litigate it.

### F2 — "Blocking I/O in async handler" rule lives in python-best-practices, not python-data-architecture
**Severity:** NIT (placement only — loading is correct)
**Evidence:** `project-template/skills/python-best-practices/SKILL.md` rules 6, 8, 26 carry async I/O rules (`async def` for I/O-bound; `CancelledError` handling; "Blocking synchronous I/O in async handlers is an anti-pattern"). `project-template/skills/python-server-architecture/SKILL.md` rule 5 carries the *server-handler-specific* form ("no blocking synchronous I/O inside async handlers"). `project-template/skills/python-data-architecture/SKILL.md` carries no async-I/O rule. The original BD-035 anti-pattern list named "blocking I/O in async handlers" as a non-server-applicable concern.

For non-server multi-file async Python, the rule is loaded — via `python-best-practices` rule 26, which loads unconditionally for D2=python — so coverage is intact. The NIT is that the rule is filed as a *style anti-pattern* (line 26: "Style and idioms" section header) rather than an *architectural performance anti-pattern*, which is where `auditor-code` rule 16 looks for it ("Performance anti-patterns — identifiable patterns causing measurable problems: N+1 queries, blocking the main thread (Apple), blocking synchronous I/O in async handlers (Python)…" — `project-template/.claude/agents/auditor-code.md` Scope §3, lines 21-22).

So the auditor-code agent is told to look for blocking-I/O-in-async as a performance anti-pattern, but the only skill-rule home for it (outside servers) is filed as a style/idiom rule. Two minor consequences: (a) finding-severity drift — auditors may file it as Minor (idiom) when it should be Major (perf); (b) future maintainers may move the rule and not realize auditor-code depends on it being loaded.

**Disposition:** **No change in v11.0** — coverage is intact, severity drift is recoverable via the auditor-code agent's own performance-anti-pattern bullet. **Optional v11.1 / v12 disposition:** add a one-line cross-reference in `python-data-architecture/SKILL.md` ("performance anti-patterns at the I/O boundary — async handler blocking I/O — see python-best-practices rule 26"); OR move rule 26 to `python-data-architecture` and add a back-reference in `python-best-practices`. Both are documentation-only and not load-rule changes.

### F3 — `python-data-architecture` SKILL.md cites BD-035 as "completed in v11"; the BD is still Open
**Severity:** NIT (doc drift)
**Evidence:** `project-template/skills/python-data-architecture/SKILL.md` line 26-27: "This skill is the *data and I/O* half of the v10.x `python-architecture` skill (split per BD-035, completed in v11)." Same claim in `project-template/skills/python-server-architecture/SKILL.md` lines 18-21.
`BACKLOG.md` line 2506-2522 BD-035 entry: `Status: Open`, `Resolved: n/a`, blocker still cites the v9 deferral premise.

The split itself (the "completed in v11" half) was actually done by BD-141 + the Python-skill-split implementation report (`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-PYTHON-SKILL-SPLIT.md`, referenced in BD-154 line 3579). BD-035 itself was never resolved — it asks the broader question "does the skill loading rule cover non-server multi-file Python?" which is what this audit answers.

The SKILL.md attribution to BD-035 is incorrect. The work was BD-141 (predicate) and the python-skill-split report.

**Disposition:** **Documentation correction.** Update both SKILL.md files to attribute the split to BD-141 + the implementation report, not BD-035. BD-035 itself either resolves on the basis of this audit (if the user accepts that post-split coverage is sufficient modulo F1) or stays Open pending an F1 fix. Either way, the SKILL.md "completed in v11" wording is misleading and should be tightened.

### F4 — Trinity discipline check passes for auditor-code
**Severity:** OBSERVATION (no action)
**Evidence:** `.claude/agents/auditor-code.md` Skills-to-load section (lines 73-78), `.codex/agents/auditor-code.toml` Skills section (line 36-37), `.gemini/agents/auditor-code.md` Skills-to-load section (lines 75-80) all carry identical Skills-to-load wording: *"Load `audit-methodology`, the language best-practice skills the parent specifies (`swift-best-practices`, `python-best-practices`), and `error-handling` (for systemic error-handling rules). The language skills contain the dead-code detection rules — load both."*

All three trinity files cite **`python-best-practices`** explicitly and rely on the calling parent (auditor) to add `python-data-architecture` and `python-server-architecture` per PLATFORM-SKILLS.md. This is consistent with the per-agent table in PLATFORM-SKILLS.md (lines 363-367) which carries the conditional intersection loading. The agent-file Skills-to-load list is intentionally narrower than the per-agent assignment table — the table is the authoritative loader; the agent-file list is the *pre-load floor* the agent always loads regardless of project shape.

**No trinity defect.** Three files are mutually consistent.

### F5 — `python_data_marker_detected()` package list has a stale entry: `protobuf` and `grpc-tools` overlap with the BD-156 protobuf-marker
**Severity:** OBSERVATION (architectural, cross-cutting; surface only)
**Evidence:** `scripts/lib/detect.sh::python_data_marker_detected()` line 365 lists `grpc-tools` and `protobuf` among the data-marker packages. `protobuf_marker_detected()` (BD-156, line 463) lists the same packages on its Python side.

A pyproject.toml that declares only `protobuf` (a wire-format library, not a data-architecture concern) will cause `python_data_marker_detected()` to fire and load `python-data-architecture` — which has no rules about protobuf. The data-marker list was authored before the protobuf-marker existed and inherited those packages from the original "any data-shaped Python dep" list.

This is an **OBSERVATION** because it falls in the cross-cutting BD-156 / protobuf-marker lane (parallel BD-033 territory) rather than the BD-035 lane proper. It is not a coverage gap — it's an over-trigger that loads `python-data-architecture` for protobuf-only projects. Cost is small (an extra skill file read); benefit is low. Surfacing it for the user to decide whether to remove `protobuf` and `grpc-tools` from the data-marker package list now that they have their own marker.

**Disposition:** None within BD-035 scope. Cross-cutting → observation. User may open a follow-on BD if desired.

---

## §4 Performance anti-pattern coverage matrix

| Anti-pattern | python-server-architecture | python-data-architecture | python-best-practices | NONE |
|---|---|---|---|---|
| N+1 queries (ORM relationship traversal) | — | **rule 4** ("Prevent N+1 queries — use eager loading or batch queries at the repository layer") | — | — |
| Blocking I/O in async handler (server context) | **rule 5** ("no blocking synchronous I/O inside async handlers") | — | rule 26 (style-level cross-ref) | — |
| Blocking I/O in async function (non-server, e.g. CLI async script) | — | — | **rule 6** ("All I/O-bound operations use `async def`") + **rule 26** ("Blocking synchronous I/O in async handlers is an anti-pattern") | — |
| Accidental O(n²) iteration over collections | — | — | — | **NONE** (see note below) |
| GIL-blocking pure-Python in I/O-bound code | — | — | rule 7 (partial — `run_in_executor` with ProcessPoolExecutor for CPU-bound) | partial — no audit rule for "this looks I/O-bound but is actually GIL-bound" |
| Large in-memory data without chunking / streaming | — | — | — | **NONE** |
| Missing `__slots__` for high-cardinality value objects | — | — | rule 2 (`@dataclass(frozen=True)` mentioned but not `slots=True`) | partial |
| Leaked file handles / connections (missing context manager) | — | — | rule 9 ("Use async context managers for resource lifecycle (database connections, gRPC channels)") | partial — sync handles, file objects not explicitly covered |
| Missing eager loading at repository boundary | — | **rule 4** | — | — |
| Pydantic at domain layer (validation in hot path) | — | **rule 6** ("Pydantic model placement — validation belongs at I/O boundaries") | rule 3 (Pydantic for input validation at I/O boundaries) | — |
| ML inference inline in request handler | **(implicit)** | **rule 7** ("ML inference isolation") | — | — |
| Unbounded query result sets / missing pagination | — | — | — | **NONE** (analogous to `apple-swiftdata-patterns` "unbounded `FetchDescriptor` results") |

**Note on O(n²) iteration and unbounded query results:** these are genuine Python performance anti-patterns named by `auditor-code.md` Scope §3 ("Performance anti-patterns — identifiable patterns causing measurable problems"). Neither has a skill-rule home today. Counter-argument: O(n²) iteration is universal across all languages (not Python-specific) — placing it in any python-* skill would be the wrong granularity; a future cross-cutting `performance-patterns` skill (analogous to `security-patterns`) would be the right home. **Cross-cutting** → not a BD-035 fix.

**Coverage summary for the BD-035 question:** the post-split skill set covers the original BD-035 anti-pattern list (N+1, blocking I/O in async) for non-server multi-file Python. The remaining gaps are either (a) skill-placement nits (F2), (b) cross-cutting universal anti-patterns that don't belong in any python-* skill (O(n²), unbounded results), or (c) marker blind-spot for very small pure-stdlib CLIs (F1).

---

## §5 Marker-gap analysis

Concrete non-server Python scenarios + whether `python_data_marker_detected()` catches them:

| Scenario | Files | Listed deps | Marker (a) hit | Marker (b) hit | Loads python-data? | Should it? |
|---|---|---|---|---|---|---|
| ETL pipeline with pandas + sqlalchemy, 12 files | 12 | pandas, sqlalchemy | yes | yes | yes | yes — correct |
| FastAPI server | 8 | fastapi, pydantic | yes (pydantic) | yes | yes | yes — correct (also loads server) |
| async-aiohttp web scraper, 6 files | 6 | aiohttp | yes | yes | yes | yes — correct |
| ML training script with torch, 3 files | 3 | torch | yes | no | yes | yes — correct |
| Pure-stdlib argparse CLI, 3 files | 3 | (none) | no | no | no | no — correct (below noise floor) |
| Pure-stdlib `sqlite3` user-DB CLI, 4 files | 4 | (none) | **no** | **no** | **no** | **arguably yes** — repository pattern + N+1 still apply |
| Pure-stdlib async CLI using `urllib`, 4 files | 4 | (none) | **no** | **no** | **no** | **arguably yes** — blocking-I/O-in-async still applies (covered by python-best-practices rule 26 anyway) |
| Pure-stdlib JSON-flat-file CLI, 6 files | 6 | (none) | no | yes (≥5) | yes | yes — but only because ≥5 file count, not because of data signal |
| Pure-stdlib `csv` ETL, 4 files | 4 | (none) | no | no | no | **arguably yes** — N+1 + repository rules apply if `csv.reader` is wrapped |
| Protobuf-only library, 8 files | 8 | protobuf | yes | yes | yes | **arguably no** — see F5 (over-trigger) |
| Library project, 4 files, no I/O | 4 | (none) | no | no | no | no — correct |

**Real-world risk profile.** The CLI-with-`sqlite3` shape (rows 6 and 9) is the most realistic blind-spot because `sqlite3` is the canonical stdlib persistence story for small Python tools and is explicitly named in the skill's own applicability prose. The async-with-`urllib` shape is rescued by `python-best-practices` rule 26, which always loads. The marker fix scope is therefore narrow: stdlib data-access detection (`sqlite3`, `csv`, file-write `open()`) — see F1 disposition.

---

## §6 Trinity discipline check

`auditor-code` agent files: `.claude/agents/auditor-code.md`, `.codex/agents/auditor-code.toml`, `.gemini/agents/auditor-code.md`.

**Skills-to-load wording:** all three files carry identical wording — *"Load `audit-methodology`, the language best-practice skills the parent specifies (`swift-best-practices`, `python-best-practices`), and `error-handling` (for systemic error-handling rules)."* python-data-architecture and python-server-architecture are NOT named in the agent file (correctly) — they're added by the calling parent based on the per-agent table in PLATFORM-SKILLS.md and the marker predicate evaluation.

**Scope wording (Performance anti-patterns):** identical across the three: "N+1 queries, blocking the main thread (Apple), blocking synchronous I/O in async handlers (Python), unnecessary allocations in hot paths, missing caching where data is fetched repeatedly."

**No trinity defect for the python row.** All three files are byte-for-byte (modulo trinity-allowed format differences: `.toml` developer_instructions wrapping vs. `.md` markdown structure; gemini's slightly more compact Hard rules block) consistent on the python loading guidance.

---

## §7 Overall verdict

**CLEAN WITH NITS.**

- The post-reframe split (BD-141 + BD-156 cluster) materially closes the original BD-035 gap. Non-server multi-file Python projects — the canonical cases the BD names (data pipelines, ML, ETL, async I/O scripts) — get `python-data-architecture` loaded reliably via the marker predicate. N+1, repository-pattern, Pydantic-placement, and ML-isolation rules are covered.
- One **SHOULD-FIX** finding: marker blind-spot for pure-stdlib Python (F1) — `sqlite3`-using CLIs, `csv` ETLs, and similar small projects miss the marker but the skill's own applicability prose says they're in scope. Disposition options on the menu: extend the predicate, OR document the noise-floor decision and accept the gap.
- Two **NIT** findings: skill-placement of "blocking I/O in async" (F2) is in the right loaded skill but tagged as style-not-perf; SKILL.md attribution to BD-035 (F3) is misleading and should be re-attributed to BD-141 + the python-skill-split report.
- One **OBSERVATION**: data-marker package list overlaps with protobuf-marker (F5) — over-triggers `python-data-architecture` for protobuf-only projects. Cross-cutting → user discretion.
- Trinity discipline check (F4) **passes** — auditor-code.md / .toml / .md mirrors are mutually consistent.

**On BD-035 itself.** The original BD asked "if the loading rule misses findings on a non-server Python audit, expand it." The post-reframe answer is: **mostly yes, expand it for the stdlib-`sqlite3` case** (F1). Either (a) ship the F1 fix and resolve BD-035, or (b) ship F3 (doc fix) + leave BD-035 Open pending the first real non-server Python audit (the original deferral premise still holds).

---

**End of audit. Standing by for SendMessage follow-ups.**
