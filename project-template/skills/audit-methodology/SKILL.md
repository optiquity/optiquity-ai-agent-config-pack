---
name: audit-methodology
description: Use for full-codebase structural audits — audit report format, severity scale, subagent coordination model, consolidated report structure.
allowed-tools: Read, Grep, Glob, Bash
---

## Audit scope

1. An audit is retrospective and periodic — run after substantial implementation, not per-phase.
2. The audit reads the entire codebase. It does not modify any files.
3. The audit evaluates the codebase across multiple quality dimensions simultaneously, not just the most recent changes.

## Severity scale

4. **Critical** — must be fixed before the next release. Security vulnerabilities, data loss risks, crash-on-launch paths.
5. **Major** — should be fixed soon. Architecture violations that will compound, missing test coverage for core flows, incorrect documentation that could mislead.
6. **Minor** — fix when convenient. Style inconsistencies, non-idiomatic patterns that work correctly, documentation gaps for edge cases.
7. **Info** — observations and recommendations. Patterns that could be improved in future iterations, potential simplifications.

## Subagent coordination model

8. The parent auditor spawns one subagent per audit cluster. Each subagent receives: the list of files relevant to its cluster, the platform skills loaded for the project, and the output format specification.
9. Subagents operate independently — they do not communicate with each other. The parent is the only coordination point.
10. Each subagent produces a self-contained report for its cluster. The parent does not modify subagent findings.

## Subagent clusters

11. **auditor-architecture** — architecture compliance, design quality, layer boundaries, LSP compliance, SOLID adherence, coupling.
12. **auditor-code** — coding best practices, language-specific idioms, error handling, dead code, performance anti-patterns.
13. **auditor-tests** — test coverage gaps, test design quality, isolation, missing edge cases.
14. **auditor-docs** — documentation accuracy vs. actual code, stale descriptions, wrong file paths, CHANGELOG drift.
15. **auditor-security** — credential exposure, unsafe deserialization, injection vectors, sensitive data in logs.
16. **auditor-ui** — UI/UX compliance, view thickness, accessibility, incomplete states, deployment readiness.

## Report format

17. Each subagent report begins with a header line: `## [Cluster Name] Audit — [date]`.
18. Findings are grouped by severity (Critical → Major → Minor → Info).
19. Each finding includes: severity, file and symbol, description, and recommended action.
20. The consolidated report begins with an executive summary: total findings by severity, top 3 issues, and overall assessment (pass / pass with issues / fail).
21. The consolidated report appends all subagent reports in cluster order, unmodified.
22. No finding is duplicated across subagent reports — the parent resolves overlaps during consolidation.
