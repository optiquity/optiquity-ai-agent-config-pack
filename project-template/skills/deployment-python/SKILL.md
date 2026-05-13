---
name: deployment-python
description: Use for Python server deployment — Docker containerization, secrets management, health checks, graceful shutdown, and production configuration.
allowed-tools: Read, Grep, Glob, Bash
---

## Docker containerization

1. Use multi-stage builds: build dependencies in a builder stage, copy only the runtime into the final image.
2. Pin the base image to a specific digest or minor version. Never use `latest`.
3. Run the application as a non-root user. Create a dedicated user in the Dockerfile.
4. Do not copy `.env` files, credentials, or development configuration into the image.
5. Use `.dockerignore` to exclude `.git`, `__pycache__`, `*.pyc`, `.env`, and test files from the build context.
6. Set `PYTHONDONTWRITEBYTECODE=1` and `PYTHONUNBUFFERED=1` in the Dockerfile environment.

## Secrets management

7. Never store secrets in source code, environment files committed to git, or Docker image layers.
8. Use a secrets manager (AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager) for production.
9. Use `pydantic-settings` with `.env` files for local development only. The `.env` file is gitignored.
10. Rotate secrets on a documented schedule. Revoke immediately on suspected compromise.

## Health checks

11. Expose a health check endpoint (gRPC health checking protocol or HTTP `/healthz`).
12. Health checks verify actual service readiness — database connectivity, dependent service availability — not just process liveness.
13. Separate liveness probes (is the process running?) from readiness probes (can it serve traffic?).
14. Health check endpoints must not require authentication.

## Graceful shutdown

15. Handle `SIGTERM` to initiate graceful shutdown. Stop accepting new requests, finish in-flight requests, then exit.
16. Set a shutdown timeout. Force-kill after the timeout to prevent hanging deployments.
17. Close database connections, gRPC channels, and background task queues during shutdown.
18. Log shutdown events with timing for operational visibility.

## Production configuration

19. Use environment variables for all configuration that varies between environments (dev, staging, production).
20. Set gRPC server concurrency limits appropriate to the deployment target. Do not use unbounded concurrency.
21. Substantive observability rules — structured-log field set, metrics naming and cardinality, tracing setup, sampling, SLO definition shape, retention policy shape — live in `python-observability-patterns`. This skill (`deployment-python`) covers deployment-readiness concerns adjacent to observability: container layout, secrets, health checks, graceful shutdown, env-driven production config. Auditor-ops loads both skills for D2=python ∩ D5=linux-container projects.
22. Set appropriate resource limits (memory, CPU) in the container orchestrator. Monitor and alert on resource exhaustion.
23. Pin all Python dependencies to exact versions in the lock file. Verify the lock file is up to date before building the image.
