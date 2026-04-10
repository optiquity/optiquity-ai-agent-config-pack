---
name: dependency-python
description: Use alongside dependency-intake when evaluating Python dependencies — PyPI health, wheel availability, version pinning, type stub support.
allowed-tools: Read, Grep, Glob, Bash
---

## PyPI health signals

1. Check PyPI download statistics and release frequency. A package with consistent releases and high download counts is lower risk.
2. Check the number of maintainers on PyPI. A single maintainer with no organizational backing is a bus-factor risk.
3. Verify the package is not archived, deprecated, or superseded by another package. Check the README and PyPI page for deprecation notices.

## Wheel and platform compatibility

4. Verify pre-built wheels exist for all target platforms (macOS, Linux, Windows as required). Source-only packages require a compilation toolchain and may fail in CI environments.
5. For packages with native C/C++ extensions: verify wheels exist for the required Python version AND platform. Missing wheels mean compilation from source, which introduces build dependencies.
6. Check Python version compatibility range. Verify the package supports the project's minimum Python version.

## Version pinning and lock files

7. Pin all dependencies to exact versions in the lock file. Use `uv lock` or equivalent to generate reproducible lock files.
8. Pin the `grpcio` family (`grpcio`, `grpcio-tools`, `grpcio-status`, `grpcio-reflection`) to the same version. Version drift causes code generation mismatches.
9. After adding a dependency, regenerate the lock file and inspect the transitive dependency diff. Flag unexpected new transitive dependencies.

## Type checking and tooling

10. Check whether the package provides inline type annotations or a `py.typed` marker. Packages without type support degrade `pyright --strict` coverage.
11. If the package lacks inline types, check whether a `types-*` stub package exists on PyPI (e.g., `types-requests`).
12. Verify the package is compatible with `ruff` linting. Some packages use import patterns that require `ruff` configuration adjustments.

## Security scanning

13. Run `pip-audit` to check for known vulnerabilities in the package and its transitive dependencies.
14. Check the package's GitHub security advisories and CVE history.
15. For packages that handle sensitive data (auth, crypto, serialization): verify the package follows security best practices and has a responsible disclosure policy.

## Environment and deployment

16. Verify the package works in the project's deployment environment (Docker container, serverless, etc.). Some packages have runtime dependencies on system libraries not available in minimal container images.
17. Check the package's memory and CPU footprint. Packages that load large models or datasets at import time affect container startup.
