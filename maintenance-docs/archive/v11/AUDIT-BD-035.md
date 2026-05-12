# AUDIT-BD-035 — python-architecture skill loading for non-server Python

**Verdict:** (b) Findings — fix-follow recommended pre-launch.

The current load rule for `python-architecture` ties it to "Python
server present" via the Component Roles dimension in
PLATFORM-SKILLS.md. A read of the skill itself shows mixed content:
some rules ARE server-specific (grpc.aio handlers, gRPC interceptor
shape, ML inference isolation), but others apply to any non-trivial
multi-file Python codebase (N+1 queries, repository pattern,
constructor DI, no module-level globals, async I/O discipline).
Today a non-server Python project (CLI tool, library, ETL script
collection, embedded Python in a Swift app) loads
`python-best-practices` but not `python-architecture`, and so loses
the architecture rules that would have applied. The cleanest fix is
not "always load python-architecture for any Python project" — that
imports server-specific rules into client contexts where they are
noise — but to split the skill or add a load condition. The BD
stays Open with PACK-FEEDBACK Q4 as the real-validation blocker.

---

## Spec assessment

### PLATFORM-SKILLS.md load rule

Dimension 3 (Component roles) table:

> Python server → python-architecture, deployment-python …
> Embedded Python → c-language …
> Shared native library → (none additional)

So `python-architecture` loads only when "Python serves requests
(gRPC, REST, or other protocol)." Embedded Python (Python runtime
in a Swift app via the C API) gets `c-language` for the bridge but
NO `python-architecture`.

For auditor-code, the "auditor-code" entry adds:

> Tier 2: audit-methodology + language skills from Step 1
> (swift-best-practices, python-best-practices, …) +
> python-architecture (when Python server in project — provides
> performance anti-pattern rules like N+1 query detection)

This is the conditional load BD-035 calls out. The note "provides
performance anti-pattern rules like N+1 query detection" is
self-aware that the rules apply more broadly than the load
condition supports.

For the auditor-architecture entry:

> Platform filtering: load only the architecture skills that match
> the project's platform profile from Step 1. A pure Python server
> loads python-architecture only.

Same restriction.

### python-architecture skill content

Read of `project-template/skills/python-architecture/SKILL.md`
(14 rules, four sections):

| Section | Rules | Applies to |
|---|---|---|
| Service layer boundaries | 1–4 | Server-specific (rule 1: "servicers"; rule 3: "gRPC servicer signatures"; rule 4: services-stateless-by-default applies more broadly but is framed as server) |
| Repository pattern | 5–7 | Mostly broad — rule 5 (repository pattern), rule 6 (N+1), rule 7 (no direct DB driver calls) all apply to any multi-file Python with data access |
| Async handler structure | 8–10 | Server-specific (rule 8: "async handlers"; rule 9: grpc.aio; rule 10: idempotent background tasks — server context but applies to any Python async I/O) |
| Domain model placement | 11–12 | Mostly broad — rule 11 (Pydantic at I/O boundaries, dataclasses for domain) and rule 12 (ML inference isolation) apply to any Python project doing I/O or ML |
| Middleware and cross-cutting | 13–14 | Server-specific (rule 13: gRPC interceptors; rule 14: grpc.aio.ServerInterceptor) |

Net: 6 of 14 rules are unambiguously server-specific (1, 3, 9, 10,
13, 14). The other 8 apply to any non-trivial Python project. The
skill is currently 60-70% server-specific by content but 100%
server-gated by load.

### python-best-practices content

`project-template/skills/python-best-practices/SKILL.md` ships 36
rules covering type system, async patterns, error handling,
capabilities pattern, tooling, style, and dead code. None of them
overlap with python-architecture's repository/N+1/DI rules. So a
non-server Python project today loses access to those entirely —
they are not redundantly available elsewhere.

### auditor-code skills loaded for a non-server Python project

Apply the load rules to "Python CLI tool, no server":

- Dimension 1 (platform): no Apple → no platform skill.
- Dimension 2 (language): Python → `python-best-practices`,
  `dependency-python`.
- Dimension 3 (role): client app → none additional.
- Dimension 4 (protocol): none → none.

So auditor-code loads `audit-methodology`, `error-handling`,
`python-best-practices`. It does NOT load `python-architecture`,
which means rules 5 (repository pattern), 6 (N+1), 7 (no direct DB
driver calls), 11 (Pydantic placement), 12 (ML inference isolation)
are out of scope. A multi-file CLI tool with a SQLite back end
that does N+1 queries today gets no finding from auditor-code —
exactly the BD-035 hypothesis.

---

## Pre-emptive ambiguities

### Ambiguity 1 — the skill conflates two things

`python-architecture` is currently two skills in one trench coat:
"server architecture" rules (1, 3, 9, 10, 13, 14) and "Python data
& I/O architecture" rules (5, 6, 7, 11, 12). The load rule says
"Python server present" because of the first half; the BD's worry
is the second half being unavailable elsewhere.

### Ambiguity 2 — "Python server present" detection is imprecise

PLATFORM-SKILLS.md says "Python serves requests (gRPC, REST, or
other protocol)." A real project might:

- Have a Python script that exposes a `subprocess` IPC interface to
  another local process — is that "serving requests"?
- Embed a small `aiohttp` admin endpoint in an otherwise-CLI tool —
  server present?
- Be a library that *can* be hosted in a server but ships standalone
  — load `python-architecture` for the library alone?

The detection is human-judgment-dependent and there is no script or
detector to support init-project.sh.

### Ambiguity 3 — N+1 / repository belongs in language, not platform

The argument the BD makes implicitly: "performance anti-patterns
apply to any multi-file Python." This is correct. N+1 is a database
access pattern — it lives wherever there is data access, server or
not. The current load rule effectively gates a language-level rule
behind a role-level condition, which is a layering inversion.

### Ambiguity 4 — embedded-Python case is silent on architecture

PLATFORM-SKILLS.md "Embedded Python" loads `c-language` only. A
Python codebase embedded in a Swift app can be substantial (hundreds
of files), with its own internal architecture concerns. The load
rule today loads zero architecture rules for this case, which is
likely too sparse.

---

## Recommended tightenings

Two viable shapes, in order of preference:

### Edit 1 (preferred) — split `python-architecture` into two skills

Rename and split:

- `python-architecture` → keep server rules only (1, 3, 4, 9, 10,
  13, 14). Rename optional but clearer if renamed to
  `python-server-architecture`.
- New skill: `python-data-architecture` (or fold into
  `python-best-practices` if scope is small enough to absorb).
  Contains rules 2, 5, 6, 7, 11, 12. Loaded whenever Python is
  present (Dimension 2).

This is the cleanest design — one skill per concern, each with a
clean load rule. The cost is a real skill-library refactor (file
move, validate-pack.py count change, PLATFORM-SKILLS.md table
edits, mention in MIGRATION-v10-to-v11.md if a v10 project's
prompts referenced the old name).

A skill-rename / skill-split is a non-trivial v11.0 change. If it
does not fit in the remaining v11.0 window, defer to v11.1 and use
Edit 2 below as the pre-launch fix.

### Edit 2 (lighter) — broaden the load rule via Dimension 2

`project-template/docs/pack/PLATFORM-SKILLS.md`, Dimension 2
(Languages) table — modify the Python row:

> Python → python-best-practices, dependency-python,
> python-architecture (when project has multi-file Python with
> data access, async I/O, or ML inference; otherwise omit)

Then update the "auditor-code" Tier 2 line and "auditor-architecture"
Platform-filtering line to drop the "when Python server in project"
qualifier and reference the Dimension 2 load condition instead.

The trade-off: server-specific rules (gRPC interceptor shape,
grpc.aio servicer correctness) get loaded into non-server contexts
where they are noise. Mitigate by adding a one-paragraph
preamble to the skill stating "rules 1, 3, 4, 9, 10, 13, 14 apply
only to server contexts; skip if no server present."

This is lighter than Edit 1 but still brittle.

### Edit 3 (lightest, defensible as pre-launch only) — annotate

`project-template/skills/python-architecture/SKILL.md` — add a
header section above rule 1:

> ## Applicability
>
> This skill currently mixes Python server architecture rules
> (servicers, grpc.aio, interceptors) with Python data-and-I/O
> architecture rules (repository pattern, N+1 prevention,
> Pydantic placement, ML inference isolation). Pending split (see
> BD-035), the load rule in PLATFORM-SKILLS.md is "Python server
> present," which means non-server Python projects miss the
> data-and-I/O rules. If you are reviewing or auditing a
> non-server Python project, manually load this skill and apply
> rules 2, 5, 6, 7, 11, 12 only.

This documents the gap without changing load behavior. The
annotation is a stop-gap and BD-035 remains Open as the real
validation point.

### Edit 4 — embedded-Python row

`project-template/docs/pack/PLATFORM-SKILLS.md`, Dimension 3
(Component roles), Embedded Python row — add:

> If the embedded Python codebase exceeds ~10 files or implements
> non-trivial data access, add `python-architecture` (rules 2, 5,
> 6, 7, 11, 12 — see Applicability section in the skill).

---

## Trinity check

This BD's spec sources are *not* the trinity files (CLAUDE/AGENTS/
GEMINI). The relevant files are:

- `project-template/docs/pack/PLATFORM-SKILLS.md` (single-source —
  no trinity siblings)
- `project-template/skills/python-architecture/SKILL.md` (single-
  source skill)
- `project-template/skills/python-best-practices/SKILL.md` (single-
  source skill)

Skills are distributed at init time to `.claude/skills/`,
`.codex/skills/`, `.gemini/skills/` from the canonical
`project-template/skills/` source — so there is exactly one source
of truth per skill and no trinity coordination required for skill
edits.

If Edit 1 (rename / split) is taken, validate-pack.py "skill count"
checks must update accordingly.

---

## Why the BD stays Open

BD-035's blocker — "First v9 non-server multi-file Python project
runs a full audit (PACK-FEEDBACK.md Q4)" — is the real
validation: does extending the load rule (or splitting the skill)
actually surface findings auditor-code would otherwise miss? The
pre-emptive tightenings above guarantee the *availability* of the
rules but cannot validate their *value* on real code without a
non-server Python project to audit.

If Edit 3 (lightest) is accepted as the pre-launch action, log in
BD-035's Context block: "v11.0 added Applicability annotation to
python-architecture skill documenting the server vs. data-and-I/O
mix; PLATFORM-SKILLS.md load rule unchanged pending real-audit
validation."

If Edit 2 (broaden load) or Edit 1 (split) is taken before v11.0
ships, log accordingly and update MIGRATION-v10-to-v11.md to flag
the load-rule change for projects on v10.
