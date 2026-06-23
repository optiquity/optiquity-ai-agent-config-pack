---
name: python-data-architecture
description: Use when assessing Python data and I/O architecture — repository pattern correctness, N+1 query detection, Pydantic placement at I/O boundaries, ML inference isolation, no-direct-driver enforcement.
allowed-tools: Read, Grep, Glob, Bash
---

## Applicability

This skill is loaded for `auditor-code`, `auditor-architecture`, and
`reviewer` whenever EITHER of the following holds (per
`docs/pack/PLATFORM-SKILLS.md` Dimension 2 / Dimension 3):

1. **Python server present** — the project serves requests over gRPC,
   REST, or another protocol from a Python process. All rules apply
   in this case. Server-specific rules (servicers, grpc.aio handlers,
   interceptors, background tasks) live in `python-server-architecture`
   and load alongside this skill.
2. **Non-trivial multi-file Python** — the project has Python source
   files exceeding a small CLI script and exercises any of: persistent
   data access (SQLite, ORM, files-as-DB), async I/O patterns,
   repository / service-layer separation, or ML inference. All rules
   in this skill apply. The server-specific rules in
   `python-server-architecture` do NOT apply and that skill is not
   loaded.

This skill covers data and I/O Python architecture (repository pattern,
N+1 prevention, Pydantic placement, ML isolation); it pairs with
`python-server-architecture` for server projects and loads alone for
non-server multi-file Python.

Foundational dependency-injection / statelessness rules (constructor
DI for services, stateless-by-default service objects) appear in both
this skill and `python-server-architecture` because they apply equally
to repository/data services and to server services. The duplication
is intentional and load-order-independent.

## Service layer foundations

1. Use constructor dependency injection. No module-level globals for services. *(Mirrored in `python-server-architecture` rule 2; foundational across data and server services.)*
2. Services are stateless by default. Any state must be documented with owner, lifecycle, and thread-safety guarantees. *(Mirrored in `python-server-architecture` rule 4; foundational across data and server services.)*

## Repository pattern

3. Verify repository pattern usage — data access logic belongs in repositories, not in service objects or servicers.
4. Prevent N+1 queries — use eager loading or batch queries at the repository layer.
5. Business logic never calls gRPC stubs, database drivers, or ORM methods directly. Only repository interfaces cross the data boundary.

## Domain model placement

6. Check Pydantic model placement — validation belongs at I/O boundaries (request ingress, external API responses). Domain objects should not be Pydantic models; use `@dataclass(frozen=True)`.
7. ML inference isolation — inference calls must not live in servicers or service objects. Isolate behind a protocol or interface.
