# AUDIT-BD-033 — Auditor systemic error handling threshold

**Verdict:** (b) Findings — fix-follow recommended pre-launch.

The "systemic vs. per-function" boundary in auditor-code rule 16 is
qualitative ("cross-cutting consistency, not individual
error-handling bugs inside one function") and never quantified. A
real audit will struggle on the in-between cases — three handlers
with the same shape, two services with subtly different retry
policies, one method missing a domain-error mapping at a boundary.
The error-handling skill itself is well-ordered and ships clear
universal rules, but it does not currently mark which rules are
"systemic" (cluster-shaped) versus "per-function" (review-shaped).
Three small spec edits would let auditor-code make the call without
inventing a private rubric on the fly. The BD itself stays Open with
its PACK-FEEDBACK Q2 blocker — real-world validation still requires
a project with substantial domain code.

---

## Spec assessment

### audit-methodology rule 16 (auditor-code scope)

The relevant excerpt:

> auditor-code — language-specific code quality, idiom adherence,
> dead code, unused imports, performance anti-patterns (N+1, blocking
> main thread, unnecessary allocations in hot paths), concurrency
> safety (race conditions, missing async handling, incorrect
> isolation annotations), and **systemic error handling** (boundary
> mapping consistency, retry policy uniformity).

Two scope markers — "boundary mapping consistency" and "retry policy
uniformity" — are the only specifics for the systemic dimension.
Both terms are intuitive but neither is operationalized. The rule
gives no count threshold ("flag when 3+ handlers diverge"), no scope
threshold ("flag when divergence crosses module boundaries"), and no
named contrast against the per-function findings that explicitly
*belong to other clusters or to per-PR review*.

### auditor-code subagent file

`project-template/.claude/agents/auditor-code.md`, "Systemic error
handling" bullet, expands rule 16:

> boundary mapping consistency (are external errors uniformly mapped
> to domain errors at the boundary?), retry policy uniformity (do
> all transient-failure paths use the same backoff strategy?), empty
> catch blocks, swallowed errors, error types that lose context.
> This is about *cross-cutting consistency*, not individual
> error-handling bugs inside one function.

Trinity check: the same wording appears in
`project-template/.codex/agents/auditor-code.toml` and
`project-template/.gemini/agents/auditor-code.md` — confirmed via
`grep` on "Systemic error handling" / "boundary mapping". All three
agree.

The bullet introduces *additional* targets — "empty catch blocks",
"swallowed errors", "error types that lose context" — that are NOT
in rule 16. These are obviously per-function (one block, one site).
The bullet then closes with the disclaimer that this is "not
individual error-handling bugs." So the bullet is internally
inconsistent: it lists per-function shapes (empty catch) under a
cluster-shaped header.

### error-handling skill (the substantive rule source)

`project-template/skills/error-handling/SKILL.md` ships 14 rules
across four sections. Mapping each rule to systemic vs. per-function:

- Rule 1 (one typed error per domain layer) — **structural**;
  systemic if missing across multiple layers.
- Rule 2 (transport errors mapped at boundary) — **systemic**;
  this is precisely "boundary mapping consistency."
- Rule 3 (error type changes are versioned) — **systemic**.
- Rule 4 (map at repository/service boundary) — **systemic**.
- Rule 5 (every catch handles, logs, or re-raises) — **per-function**;
  one block, one site.
- Rule 6 (logging at boundary includes structured context) —
  **per-function** when applied to one site, **systemic** when
  applied across all boundaries.
- Rule 7 (don't leak transport detail to user) — **per-function** at
  one site, **systemic** when violated everywhere.
- Rule 8 (retry only transient) — **systemic** (policy uniformity).
- Rule 9 (never retry client errors) — **systemic** (policy).
- Rule 10 (exponential backoff with jitter) — **systemic** (policy).
- Rule 11 (cap retries via named constants) — **systemic**.
- Rule 12 (per-operation retry config) — **systemic**.
- Rule 13 (cancellation cleanup) — **per-function**.
- Rule 14 (cancellation language-specific) — **n/a — meta**.

This is a clean split, but it is not encoded in the skill. The
auditor-code subagent loads `error-handling` for "systemic
error-handling rules" (per its skills-to-load section) but receives
all 14 rules undifferentiated. Per-function rules (5, 13) will get
filed by auditor-code as systemic findings — which crosses the
spec's own boundary.

---

## Pre-emptive ambiguities

### Ambiguity 1 — no count threshold for "systemic"

Rule 16 says "consistency" and "uniformity." Neither has a
numerator. If two services do retry differently, is that a
finding? Three? Five out of six? The spec is silent.

A real audit on a 30-handler Python service will face this question
many times. Without a threshold the auditor will either over-file
(every divergence becomes a finding) or under-file (only file when
the divergence is "obvious"), with no defensible rule either way.

### Ambiguity 2 — empty catch / swallowed error miscategorized

The auditor-code subagent file's bullet lists "empty catch blocks,
swallowed errors, error types that lose context" under "Systemic
error handling." These are textbook per-function defects. They
should either:

- Be re-categorized under "Language idiom adherence" in the same
  scope bullet (cleanest), or
- Stay in the systemic bullet with explicit gating ("file as
  systemic only when the same pattern recurs across N+ sites").

Today they will get filed as systemic findings even when they occur
once — which conflicts with the bullet's closing sentence ("not
individual error-handling bugs inside one function").

### Ambiguity 3 — auditor-code vs. reviewer scope overlap

The pack's `reviewer` agent also loads `error-handling` per
PLATFORM-SKILLS.md ("reviewer" Tier 1: review, error-handling).
Reviewer is per-PR; auditor-code is full-codebase. Without a
threshold, the systemic findings auditor-code files will overlap
with what reviewer should have caught individually. The spec does
not say "auditor-code escalates a per-function defect to systemic
when it appears in 3+ places."

A real audit on a code base that's been review-clean will surface
either nothing (everything was caught by reviewers) or everything
(every divergence is now a finding). Both extremes are wrong.

### Ambiguity 4 — boundary-mapping coverage

"Boundary mapping consistency" — across which boundaries? The
error-handling skill defines the *type* of boundary (transport,
repository, service) but the auditor-code spec doesn't say "must
audit every boundary listed in error-handling rules 2 and 4." A
project with three transport types (gRPC, REST, message queue) needs
the auditor to know each is in scope.

---

## Recommended tightenings

### Edit 1 — quantify "systemic" with a count threshold

`project-template/skills/audit-methodology/SKILL.md`, rule 16.
Append:

> **Systemic threshold.** A finding is systemic when the same
> divergence or omission appears at three or more independent call
> sites, or crosses module boundaries (the same defect in two
> different services / packages / modules). A single-site instance
> belongs to per-PR review, not to auditor-code. When the threshold
> is met, file once as a systemic finding listing all affected
> sites, not N separate per-site findings.

### Edit 2 — split the systemic bullet from the per-function items

`project-template/.claude/agents/auditor-code.md`,
`project-template/.codex/agents/auditor-code.toml`,
`project-template/.gemini/agents/auditor-code.md` — trinity-edit
the "Systemic error handling" bullet:

Replace current wording with:

> - **Systemic error handling** — *cross-cutting* consistency only
>   (per audit-methodology rule 16's threshold): boundary mapping
>   uniformly applied at every transport boundary the project uses
>   (gRPC, REST, message queue, filesystem, OS process boundary);
>   retry policy uniformity (same backoff curve, same maxAttempts,
>   same retryable-vs.-non-retryable taxonomy across all transient
>   paths); error-type hierarchy completeness (every domain layer
>   has its typed error per error-handling rule 1; every boundary
>   maps per error-handling rule 4).
> - **Per-function error-handling defects** (empty catch blocks,
>   swallowed errors, error types that lose context, missing
>   re-raise after log) — file under "Language idiom adherence"
>   above unless the same defect occurs at three or more sites,
>   in which case escalate to systemic.

### Edit 3 — annotate error-handling skill with cluster tags

`project-template/skills/error-handling/SKILL.md` — add a one-line
tag at the end of each rule indicating systemic vs. per-function:

- Rules 1, 2, 3, 4, 6 (cross-boundary), 8, 9, 10, 11, 12 → tag:
  `[systemic — auditor-code]`
- Rules 5, 7 (per-site), 13 → tag: `[per-function — reviewer / coder]`

This makes the skill self-routing. Auditor-code knows which rules to
audit at the cluster level; reviewer knows which to enforce per-PR.
No new rules; just a routing annotation.

### Edit 4 — name the boundaries explicitly

`project-template/skills/audit-methodology/SKILL.md`, rule 16,
append after the systemic-threshold sentence:

> The boundaries auditor-code must audit for mapping consistency are
> exactly those defined in `error-handling` rule 4 (repository /
> service / external API ingress) plus every transport the project
> uses per `grpc-patterns`, `rest-patterns`, or other loaded
> protocol skills. A project with multiple transports must show
> consistent mapping across all of them.

---

## Trinity check

| File | Claude | Codex | Gemini | Agreement |
|---|---|---|---|---|
| `auditor-code` "Systemic error handling" bullet | present | present | present | wording aligned (same paragraph structure, identical key phrases) |
| Reference to `audit-methodology rule 16` | yes | yes | yes | aligned |
| Skills-to-load list | identical | identical | identical | aligned |

No trinity drift today. All Edit 2 changes must apply to all three
files in the same commit.

---

## Why the BD stays Open

BD-033's blocker — "First v9 project with non-trivial error handling
runs a full audit (PACK-FEEDBACK.md Q2)" — is the real validation:
does the threshold of "3 or more sites or crosses module
boundaries" cleanly distinguish auditor-code's findings from what
reviewer would have caught? Pre-emptive tightenings sharpen the
rule but do not validate it. The BD remains the correct tracker for
"prove the threshold works on real code"; only first-real-audit
data closes it.

If the recommended tightenings are accepted, log a fix-follow note
in BD-033's Context block ("v11.0 introduced 3-site systemic
threshold and per-function vs. systemic split; real-world threshold
validation still pending"). Calibrating the count (is it 3? 5? a
percentage of total sites?) is exactly what first-audit data will
inform.
