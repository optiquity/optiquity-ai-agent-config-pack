---
name: audit-methodology
description: Use for full-codebase structural audits — audit report format, severity scale, subagent coordination model, file scope rules, ownership precedence, consolidated report structure, per-tool spawning mechanisms.
allowed-tools: Read, Grep, Glob, Bash
---

This skill is the canonical design document for the auditor agent and its
subagents. It is loaded by the parent auditor (for coordination) and by all
subagents (for report format, severity scale, and scope rules). If a subagent
file and this skill disagree, this skill wins.

## Audit scope

1. An audit is retrospective and periodic — run after substantial implementation, not per-phase.
2. The audit reads the entire codebase within the file-scope rules below. It does not modify any files.
3. The audit evaluates the codebase across multiple quality dimensions simultaneously, not just the most recent changes.

## When to run the auditor

4. Run the auditor on: (a) the end of a major phase group (three or more phases completed), (b) before starting major new feature work, or (c) before a release build. The auditor is not a per-phase or per-PR tool.
5. Do not run the auditor in the first three phases of a new project — there is not enough code to produce useful findings and the noise-to-signal ratio is high.
6. A full audit costs 7–8 subagent invocations (one per cluster plus the parent consolidation). Plan for this cost.

## Severity scale

7. **Critical** — must be fixed before the next release. Security vulnerabilities, data loss risks, crash-on-launch paths, broken build configurations, hardcoded secrets in production paths.
8. **Major** — should be fixed soon. Architecture violations that will compound, missing test coverage for core flows, incorrect documentation that could mislead, deployment readiness gaps, systemic error-handling inconsistencies, known CVEs in direct dependencies.
9. **Minor** — fix when convenient. Style inconsistencies, non-idiomatic patterns that work correctly, documentation gaps for edge cases, CVEs in transitive dependencies without a known exploit path.
10. **Info** — observations and recommendations. Patterns that could be improved in future iterations, potential simplifications, cluster-specific notes that do not warrant fixing but are worth tracking.

## Pass/fail thresholds

11. **pass** — zero Critical findings AND zero Major findings.
12. **pass with issues** — zero Critical findings AND one or more Major findings. A pass-with-issues audit is not a blocker but must be acknowledged by the PM chat and triaged.
13. **fail** — one or more Critical findings. A failing audit blocks release until Criticals are resolved.
14. Minor and Info findings never change the pass/fail verdict. They are recorded and tracked but do not block.

## Subagent clusters (7)

The auditor uses seven semantically coherent clusters. Each cluster has its own
subagent, its own file scope, its own skill set, and its own output format.

15. **auditor-architecture** — architecture compliance, layer discipline, design quality, module coupling, interface uniformity, LSP compliance, capabilities pattern adherence (LSP required; capabilities recommended), SOLID adherence, observability infrastructure completeness (are logs/metrics/traces wired up at the right layers?).
16. **auditor-code** — language-specific code quality, idiom adherence, dead code, unused imports, performance anti-patterns (N+1, blocking main thread, unnecessary allocations in hot paths), concurrency safety (race conditions, missing async handling, incorrect isolation annotations), and systemic error handling (boundary mapping consistency, retry policy uniformity). **Systemic threshold.** A finding is *systemic* when the same divergence or omission appears at three or more independent call sites, OR crosses module boundaries (the same defect in two different services / packages / modules). A single-site instance belongs to per-PR review (the `reviewer` agent), not to auditor-code. When the threshold is met, file once as a systemic finding listing all affected sites, not N separate per-site findings. The boundaries auditor-code audits for mapping consistency are exactly those defined in `error-handling` rule 4 (repository / service / external-API ingress) plus every transport the project uses per `grpc-patterns`, `rest-patterns`, or other loaded protocol skills. A project with multiple transports (e.g., gRPC, REST, message queue) must show consistent mapping across all of them. Per-function error-handling defects (empty catch blocks, swallowed errors, error types that lose context, missing re-raise after log) are language-idiom findings unless they recur at 3+ sites; tag them `[per-function — reviewer]` in the error-handling skill.
17. **auditor-tests** — test coverage gaps, test design quality, isolation, determinism, missing edge cases, non-deterministic tests, mocked vs. real boundary decisions.
18. **auditor-docs** — documentation accuracy vs. actual code, stale descriptions, wrong file paths, CHANGELOG drift, incorrect API examples, outdated setup instructions. Flags documented claims that do not match observed code facts.
19. **auditor-security** — credential exposure, unsafe deserialization, injection vectors, sensitive data in logs, AND supply chain review: known CVEs in direct and transitive dependencies, license compatibility (GPL contamination, incompatible licenses for the project's distribution model), abandoned or deprecated dependencies.
20. **auditor-ui** — UI/UX compliance: applies *every* UI rule defined in the loaded platform skills (`apple-architecture-core`, `ios-architecture`, `macos-architecture`, plus future per-platform skills). The cluster's signature concerns are: (a) view thickness (business logic embedded in views), (b) accessibility (labels, tap targets, keyboard navigation, Dynamic Type, contrast, screen-reader flow including grouping/traits/custom rotors, Reduce Motion, color-only meaning conveyance), (c) incomplete UI states (missing loading / empty / error renders), (d) platform-specific conventions (iOS 26 availability guards, macOS menu bar wiring, orientation/multitasking adaptation, drag-and-drop, system-gesture conflict), (e) localization and adaptation (string-length tolerance for translated labels, RTL layout where the platform supports it, locale-specific date/number/currency formatting, dark-mode / appearance support and contrast in both modes, iPad split-view / Stage Manager / multi-scene multitasking). **Any UI rule defined in a loaded platform skill but not enumerated here is in scope** — the enumeration above is illustrative, not exhaustive. The 4 default headings are the floor, not the ceiling. **Cross-platform UI checklist** (applies whenever any UI platform skill is loaded — Apple today; web / Android / embedded-MCU once those skills land in Phase 3):
    - **State source-of-truth** — every piece of visible UI state has one canonical owner; multiple writers to the same state without an explicit reconciliation policy is a defect.
    - **Interactive reachability** — every interactive element is reachable by the platform's primary input modalities (keyboard, pointer / touch, and assistive technology such as screen readers); unreachable controls are a defect.
    - **Externalized strings** — user-facing text is isolated in a localization layer (catalog, resource file, i18n table); hardcoded UI strings outside that layer are a defect.
    - **Layout adapts to translation growth** — layout tolerates ~30–40% string-length expansion (typical for German, Russian, Finnish, etc.) without truncation, overlap, or clipping; fixed-width text containers that cannot expand are a defect.

    Skipped for server-only projects that have no UI layer.
21. **auditor-ops** — deployment readiness, configuration management, and cross-cutting operational concerns. Covers: platform-specific deployment configuration correctness (signing, entitlements, notarization, container security, health checks, graceful shutdown), configuration management (env vars, feature flag defaults, per-environment config correctness, drift between environments), and observability configuration (logging output format, log retention, metrics endpoints, sampling rates, tracing exporter setup, alerting / SLO definitions). Always runs — every project deploys somewhere. **Boundary clarification — observability code in source files.** Observability *code* that lives in source files (e.g., `Sources/Observability/Bootstrap.swift`, `server/src/observability/setup.py`) belongs to auditor-architecture if the finding is structural ("the `Logger` protocol is the wrong shape", "`configure_tracing` is not wired into the app entry point"). It belongs to auditor-ops if the finding is about deployment-target correctness ("the OTLP endpoint is hardcoded", "the resource `service.name` is missing for cloud deployment", "the exporter is not installed for the prod environment", "the Prometheus histogram bucket boundaries are hardcoded for sub-millisecond local development", "the prod trace sampler ratio is hardcoded to 1.0", "no alert rule references the exported `http_request_duration_seconds` metric and no SLO is defined", "the log retention policy in the deployment manifest defaults to 1 day in prod"). **Named test (ownership rubric).** A finding is auditor-ops if the fix changes a *value* read from configuration at runtime (env var, manifest field, exporter parameter, sampler ratio, alert rule, retention setting) without changing source-file types or call graphs. A finding is auditor-architecture if the fix changes the *type* of an interface (e.g., adding `severity:` to a `Logger` protocol), the *call graph* between modules (e.g., registering an `OpenTelemetryClientInterceptor` on a previously-uninstrumented gRPC channel), or the *wiring* between components (e.g., calling `configure_tracing()` from the app entry point). Apply this test before falling back to enumerated examples. **When uncertain, file under auditor-ops** — operational findings almost always have a deployment-shaped fix. Uncertainty typically arises when (a) the same source-file location has both a structural shape (the abstraction or wiring is wrong) and a deployment-target shape (the wrong concrete value was chosen), (b) a finding could be fixed by either editing source or editing config without source change, or (c) the same code behaves differently in dev vs prod due to environment alone. Prefer ops in those cases — the deployment-shaped fix usually subsumes the structural fix; if not, the cross-detection annotation will surface the architecture half. Findings about *log content* (credentials, tokens, PII in log messages) belong to auditor-security per rule 33; auditor-ops may surface them as deployment-config-shaped concerns and annotate `(also detected by: security)` per rule 33.

## Cluster selection rationale

22. Clusters are split by three criteria that must all agree: (a) the skill set each needs, (b) the file scope each examines, and (c) the audit output cohesion. If two concerns share all three, combine them. If any differ, split them.
23. The seven clusters exist because no two share all three criteria. auditor-code and auditor-tests both examine source but need different skills and produce different report shapes. auditor-ui and auditor-ops both touch "how the project is delivered" but have disjoint file scopes (UI source vs. deployment manifests) and different skip conditions.
24. When adapting this pattern to a different multi-agent workflow (e.g., a release-prep agent with subagents), apply the same three criteria to select clusters.

## File scope rules

Every subagent must respect these scope rules. The parent passes the file scope
to each subagent in its spawn prompt.

25. **Always exclude** (all clusters): `**/.git/**`, `**/.build/**`, `**/DerivedData/**`, `**/node_modules/**`, `**/.venv/**`, `**/venv/**`, `**/Pods/**`, `**/__pycache__/**`, `**/*.egg-info/**`, `**/generated/**`, `**/*_pb2.py`, `**/*.pb.swift`, `**/*.pb.go`. Vendored dependencies and generated code produce noise, not signal.
26. **auditor-architecture** — scope: source files in the project's module roots (`Sources/`, `server/src/`, or equivalent per project layout). Examines layer boundaries, import graphs, and module structure. Does not audit `tests/`, docs, or config.
27. **auditor-code** — scope: all source files in language directories (`**/*.swift`, `**/*.py`, `**/*.c`, `**/*.cpp`, `**/*.m` as applicable). Excludes test files (those go to auditor-tests). Excludes generated code per rule 25.
28. **auditor-tests** — scope: all test files (`**/*Tests.swift`, `**/test_*.py`, `**/*_test.swift`, `**/tests/**/*.py`). Excludes test fixtures (`**/tests/fixtures/**`, `**/tests/data/**`).
29. **auditor-docs** — scope: `**/*.md`, `**/*.txt`, `**/README*`, inline doc comments (`///`, `"""..."""`, `/** ... */`). Cross-references documented claims against code in auditor-architecture's and auditor-code's scope but does not re-audit those files for anything other than documentation accuracy.
30. **auditor-security** — scope: all source files in auditor-code's scope PLUS config files (`**/*.env*`, `**/*.yml`, `**/*.yaml`, `**/*.toml`, `**/*.json` where relevant), dependency manifests (`Package.swift`, `Package.resolved`, `pyproject.toml`, `uv.lock`, `requirements*.txt`), and container definitions (`Dockerfile*`, `docker-compose*.yml`).
31. **auditor-ui** — scope: view and view-model files (`**/*View.swift`, `**/*ViewModel.swift`, `**/View/**/*.swift`, SwiftUI/UIKit/AppKit source files), resource catalogs, localization files, accessibility audit descriptors. Excludes backend-only code.
32. **auditor-ops** — scope: deployment manifests (`Dockerfile*`, `docker-compose*.yml`, `**/deploy/**`, `**/k8s/**`, `**/helm/**`, signing/entitlement files for Apple — `**/*.entitlements`, `**/Info.plist`, `**/PrivacyInfo.xcprivacy`), configuration files (`**/*.env*`, `**/config/**`), observability configuration (`**/logging.*`, OpenTelemetry collector configs, metrics exporter configs), and CI workflow files (`.github/workflows/*.yml`).

## Ownership precedence (duplicate resolution)

When two or more subagents could claim the same finding, the parent applies
this precedence to attribute it to exactly one cluster. The surviving entry
is annotated with `(also detected by: <other-clusters>)` so cross-cluster
visibility is preserved.

33. **Security concern wins.** If a finding is a security vulnerability (credential leak, injection, unsafe deserialization, sensitive data in logs, known CVE), auditor-security owns it regardless of which other cluster also detected it.
34. **Supply chain concern wins over code.** If a finding is a CVE or license issue in a dependency, auditor-security owns it over auditor-code and auditor-architecture.
35. **Architecture violation wins over code idiom.** If a finding violates a layer boundary or module discipline rule, auditor-architecture owns it over auditor-code. A missing protocol abstraction at a layer seam is architecture, not code.
36. **Test design issue wins over code.** If a finding is about test determinism, isolation, or coverage, auditor-tests owns it over auditor-code.
37. **Deployment readiness wins over ui.** If a finding is about how the project ships or runs in production (env vars, health checks, signing, notarization), auditor-ops owns it over auditor-ui even if the finding touches a UI file.
38. **Otherwise, first reporter wins in cluster order.** Cluster order for tie-breaking: security → architecture → tests → ops → code → ui → docs.
39. **Severity reconciliation.** When subagents assign different severities to the same finding, the higher severity wins. Never downgrade a Critical to Major during consolidation.

## Subagent coordination model

40. The parent auditor spawns one subagent per relevant audit cluster. Each subagent receives: the file scope for its cluster (computed from rules 25–32), the platform skills loaded for the project (from PLATFORM-SKILLS.md based on the project's skill profile), and the output format specification from rules 48–55 below.
41. Subagents operate independently — they do not communicate with each other. The parent is the only coordination point.
42. Each subagent produces a self-contained report for its cluster using the format in rules 48–55.
43. The parent does not modify subagent findings except to resolve duplicates per rules 33–39 and to assemble the consolidated report.

## Skip rules

44. **Skip `auditor-ui`** when the project has no UI layer. Detection: no `*.xcodeproj`, no SwiftUI/UIKit/AppKit source files, no `**/*View.swift` files, no frontend framework manifests. Pure backend / CLI / server projects skip this cluster. *Note:* the current detection list is Apple-centric. Non-Apple UI detection markers (web, Android, embedded) are added by the corresponding platform-architecture skills now in development for v11.0 (see `maintenance-docs/v11-implementation/RESEARCH-NON-APPLE-UI-SKILLS.md` for the in-flight design); once those skills land, this detection list extends to include their markers.
45. **Skip `auditor-tests`** only for the first audit of a brand-new project with no test suite yet. Detection: no `tests/` directory, no `*Tests.swift`, no `test_*.py`. On any subsequent audit, auditor-tests runs and reports the test-coverage gap as a Major finding.
46. **Never skip `auditor-ops`** — every project deploys somewhere. Even a purely local CLI tool has packaging, distribution, and configuration concerns.
47. **Never skip the other four** (architecture, code, docs, security).

## Report format

48. Each subagent report begins with a header line: `## [Cluster Name] Audit — [YYYY-MM-DD]`.
49. Findings within a cluster are grouped by severity (Critical → Major → Minor → Info).
50. Each finding includes four fields: severity, location (file path + symbol or line), description (what's wrong and why), recommended action (specific fix).
51. A cluster report that produces no findings still emits its header plus a single line: `No findings in this cluster.` This confirms the subagent ran and did not silently skip.
52. The consolidated parent report begins with an **Executive summary** section:
    - Total findings per severity (`Critical: 2, Major: 5, Minor: 11, Info: 3`)
    - Top 3 issues (highest severity first; tie-break by cluster order from rule 38)
    - Pass/fail verdict per rules 11–13
    - Any subagents that were skipped, with the reason (per rules 44–46)
53. After the executive summary, the consolidated report appends each subagent report in this cluster order: security → architecture → tests → ops → code → ui → docs. Reports are appended unmodified except for the duplicate-resolution annotations from rule 33–38.
54. When a finding is annotated with `(also detected by: X)`, the annotation is added to the surviving finding only; the duplicate is removed from the other cluster's report.
55. The consolidated report ends with a `## Next steps` section listing any Critical and Major findings as prioritized work, with a cross-reference to the PM chat's BACKLOG processing workflow.

## Per-tool spawning mechanism

The parent auditor uses different spawning mechanisms per CLI tool. The
behavioral outcome is identical — 7 isolated subagent contexts that report
back to the parent — but the implementation differs.

56. **Claude Code** — the parent auditor uses the Claude Code `Task` tool to spawn subagents in-process. Parent issues all Task calls in a single message so subagents run in parallel. The parent's agent file must include `Task` in its `tools:` frontmatter.
57. **Codex CLI** — the parent auditor spawns subagents via Codex's native subagent mechanism configured through `.codex/config.toml` (`[agents] max_depth = 2` allows one level of parent→subagent spawning). Parent invokes each registered subagent by name.
58. **Gemini CLI** — Gemini supports native subagents in `.gemini/agents/*.md` with YAML frontmatter, but subagents cannot call other subagents (Gemini design constraint). For the auditor, `agent-run.sh run_gemini_auditor` provides external orchestration: runs each non-skipped subagent in its own Gemini session (activated via `@agent-name` in `-p`), captures reports to temp files, then invokes the auditor parent with all reports as input via stdin (not inline — see rule 59). The agent files provide each subagent's system prompt, scope, and skill instructions; the script prompt adds project-specific context.
59. **Context budget.** Parent consolidation prompts can be large when subagent reports accumulate. Implementations must pass reports by file reference or chunked read, not by inline string concatenation, to avoid exceeding command-line length limits (`ARG_MAX` on macOS is approximately 256KB).
60. **Skip-rule passing.** Skip decisions originate with the PM chat or the developer. Claude and Codex parents receive skip rules as prose in their invocation prompt ("Skip auditor-ui and auditor-tests for this server-only project"). Gemini receives skip rules via the `agent-run.sh --skip` flag. All three mechanisms produce the same effect.

## Cost and parallelism

61. A full audit is expensive: 7 subagent invocations (or 8 counting the parent) per run. Parallelize where possible — Claude's Task tool and Codex's `max_depth=2` can run subagents concurrently; Gemini's external orchestration runs sequentially for log readability and to avoid rate limits.
62. Document the audit cost in each audit's executive summary (wall clock time, approximate token count if available) so teams can decide when the audit cadence is sustainable.

## Reference pattern: building other multi-agent workflows

The auditor is the pack's canonical reference example for parent+subagent
coordination. To adapt the pattern to a different workflow (e.g., a release
preparation agent, a migration coordinator, a cross-cutting refactor workflow):

63. **Define clusters using the three-criteria test** (rule 22). Each cluster must own a distinct skill set, file scope, and output cohesion. Combine only when all three agree.
64. **Write one subagent per cluster** following the same file structure as the auditor subagents: scope description, output format, skills to load. Cross-reference a shared methodology skill (like this one) for common rules.
65. **Write the parent** with coordination rules (spawning, skip rules, duplicate resolution, consolidated output format). Keep the parent small and delegate substance to subagents.
66. **Choose per-tool spawning.** For Claude use the Task tool with parallel calls; for Codex use `max_depth` in `config.toml`; for Gemini use native `@agent-name` subagent delegation from the main session, or `agent-run.sh` external orchestration for headless execution (subagents cannot call other subagents in Gemini).
67. **Document the cost.** Parent-subagent workflows are not free — every extra cluster multiplies cost. Prefer a small number of coherent clusters over many fine-grained ones.

## Post-audit processing

68. When the auditor finishes, the consolidated report is returned to the developer or PM chat. The auditor does not write to BACKLOG.md, STATUS.md, or any other project file.
69. The PM chat processes the consolidated report per METHODOLOGY.md Part 6: creates one BACKLOG entry per Critical finding (immediate work), one per Major finding (deferred but tracked), and summarizes Minor/Info findings as a single observations entry.
70. The developer may re-run a single subagent (e.g., `auditor-security` after fixing a CVE) to verify the fix without running a full audit. Use the per-subagent invocation paths: Claude `--agent auditor-security`, Codex `--agent auditor-security`, Gemini `./agent-run.sh gemini --agent auditor-security`.
