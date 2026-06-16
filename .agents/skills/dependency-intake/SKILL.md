---
name: dependency-intake
description: Use before adding any third-party package, framework, SDK, or external API wrapper. Platform-agnostic evaluation methodology.
allowed-tools: Read, Grep, Glob, Bash
---

## Necessity check

1. Can the need be met with platform or standard library APIs? Check before looking at third-party options.
2. Can a local wrapper around platform APIs solve the problem more simply and with less risk than an external dependency?
3. Is the dependency solving a current requirement, or is it speculative? Do not add dependencies for hypothetical future needs.

## Maintenance health

4. When was the last release? A package with no release in 12+ months is a risk signal.
5. How responsive are maintainers to issues and pull requests? Check the open issue count and median response time.
6. What is the bus factor? A single-maintainer project with no organizational backing is higher risk than one with multiple active contributors.
7. Is the project archived, deprecated, or in maintenance-only mode? Check the README and repository status.

## License and legal

8. What is the license? Is it compatible with the project's license and distribution model?
9. Are there commercial use restrictions, attribution requirements, or copyleft provisions that affect how the project can be distributed?
10. Do any transitive dependencies introduce license conflicts?

## Security posture

11. Check for known security advisories: CVE database, GitHub security advisories, and tool-specific vulnerability scanners.
12. Does the project have a security policy and responsible disclosure process?
13. How quickly have past security issues been patched? Check the advisory timeline.

## Technical fit

14. What is the transitive dependency count? Each transitive dependency is an additional attack surface and maintenance burden.
15. Does the dependency force architectural decisions (specific patterns, runtime requirements, framework coupling) that conflict with the project's architecture?
16. What platforms and language versions does it support? Verify compatibility with the project's targets.
17. Is the API surface well-documented and stable? Check for breaking changes in recent version history.

## Exit plan

18. What is the rollback plan if the dependency becomes unmaintained, incompatible, or compromised?
19. How deeply does it integrate? A dependency used in one file is easier to remove than one woven through the architecture.
20. Are there alternative packages that could serve as a drop-in replacement?

## Output format

Report for each evaluated dependency:
- Recommendation: adopt / reject / investigate further
- Rationale: evidence-based assessment against the criteria above
- Rejected alternatives: what else was considered and why it was not chosen
- Integration risks: what could go wrong and how to mitigate
