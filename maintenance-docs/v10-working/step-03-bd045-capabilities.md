# Step 03 — BD-045 Capabilities Pattern Draft Text

*Report type: Phase-1 / Step 3 deliverable for V10-DESIGN-PROCESS-PLAN.md.*
*Author: pack-architect (read-only session).*
*Date: 2026-04-21.*
*Scope: Produce concrete, ready-to-use draft text for all nine locations
named in BD-045. The drafts below are sized to be copy-paste inputs to
Phase 4 implementation; an implementer should not need to make design-
level decisions to apply them.*

---

## 0. Summary of what this report delivers

BD-045 lists nine locations that must receive new capabilities-pattern
content. Mapped to files:

| # | File | Change type |
|---|---|---|
| 1 | `project-template/CLAUDE.md` | New section + anti-pattern bullet |
| 2 | `project-template/AGENTS.md` | New section + anti-pattern bullet |
| 3 | `project-template/GEMINI.md` | New section + anti-pattern bullet |
| 4 | `project-template/skills/apple-architecture-core/SKILL.md` | New section (4 rules) |
| 5 | `project-template/skills/python-best-practices/SKILL.md` | New section (4 rules) |
| 6 | *(placeholder template for future language skills)* | Drop-in template |
| 7 | `project-template/skills/architecture-review/SKILL.md` | New section (4 rules) |
| 8 | `project-template/.claude/agents/auditor-architecture.md` | New scope bullet |
| 9 | `project-template/.codex/agents/auditor-architecture.toml` | New scope bullet |
|10 | `project-template/.gemini/agents/auditor-architecture.md` | New scope bullet |

(The "nine locations" in BD-045 group the three auditor files as one
location; this report breaks them out because each file is a separate
edit. Total files touched: 10. The trinity-rule pairing for CLAUDE /
AGENTS / GEMINI is preserved everywhere it applies.)

---

## 1. Design principles applied in these drafts

These principles shape every draft below:

- **LSP and capabilities are independent required practices.** The
  wording used is exactly what BACKLOG BD-045 specifies: they are
  "both required coding practices, applied independently. Neither is a
  prerequisite for the other, and neither is the motivation for the
  other … They work well together when both are present, but this is a
  benefit of using both — not a dependency between them. Each stands on
  its own merits and is required regardless of whether the other is in
  use."

- **Two complementary forms.** Value-based (bitmask / flag set /
  enum set) and interface-based (small focused interface that a type
  adopts only when it supports the behavior) are always named as a
  pair. Neither is privileged over the other.

- **Language-agnostic in trinity files and in architecture-review;
  language-specific in per-language skills.** The pattern's *intent*
  is language-agnostic ("make what a type supports explicit and
  queryable"). The *implementation mechanism* varies by language and
  only appears in per-language skills.

- **Trinity symmetry.** The section wording in CLAUDE.md, AGENTS.md,
  and GEMINI.md is identical. The anti-pattern bullet is identical.
  No tool-specific deviation is justified for this content — every
  rule here is purely about coding practice, not about tool behavior.

- **Proactive, not reactive.** Every draft explicitly instructs the
  reader to reach for the pattern during architecture design, not only
  when fixing an LSP violation. This is the central intent of BD-045.

---

## 2. Location 1–3 — Trinity files (CLAUDE.md, AGENTS.md, GEMINI.md)

### 2.1 New section — identical wording in all three files

**Placement.**
- `project-template/CLAUDE.md`: insert as a new top-level section
  **immediately after** `## Liskov Substitution Principle` (current
  lines 172–178) and **before** `## Dependency intake policy`
  (current line 180).
- `project-template/AGENTS.md`: insert as a new top-level section
  **immediately after** `## Liskov Substitution Principle` (current
  lines 95–99) and **before** `## Dependency intake` (current line
  101).
- `project-template/GEMINI.md`: insert as a new top-level section
  **immediately after** `## Liskov Substitution Principle` (current
  lines 129–134) and **before** `## Dependency intake policy`
  (current line 136).

**Section text (identical in all three files — copy verbatim):**

```markdown
## Capabilities pattern

Make what a type supports explicit and queryable. Callers check support
before invoking behavior; they do not discover unsupported operations
through exceptions, silent no-ops, or branching on concrete types.
Reach for this pattern during design, not only when fixing an LSP
violation.

The pattern takes two complementary forms:

- **Value-based capabilities.** A type exposes a value (bitmask, flag
  set, enum set, or similar) enumerating the operations it supports.
  Callers check the capability value before invoking the corresponding
  operation. Validate capability compatibility at association or
  initialization time — reject incompatible pairings before they can
  produce runtime errors.
- **Interface-based capabilities.** A type declares conformance to a
  small, focused interface (protocol, trait, abstract base, or
  equivalent) only when it genuinely supports that behavior. Callers
  query for the interface before invoking. Types that do not support a
  behavior simply do not expose the interface — no silent no-ops, no
  unconditional throws.

Both forms share the same intent: make supported behaviors explicit
and queryable, eliminating the need for callers to discover
limitations through runtime surprises. The specific language mechanism
varies (compile-time or runtime conformance checks, structural
subtyping, flag values, enum sets, etc.), but the design intent is
consistent across any typed system.

**Relationship to LSP.** LSP and the capabilities pattern are both
required coding practices, applied independently. LSP is a correctness
constraint on interface design — every method declared in an interface
must have a meaningful implementation in every conforming type. The
capabilities pattern is an architectural tool for making supported
behaviors explicit and queryable. Neither is a prerequisite for the
other, and neither is the motivation for the other. They work well
together when both are present, but this is a benefit of using both —
not a dependency between them. Each stands on its own merits and is
required regardless of whether the other is in use.
```

**Tool-specific framing — justified deviations.** None. The section is
pure coding guidance; every sentence applies identically to work done
under Claude Code, Codex, or Gemini CLI. No deviation between the
three files is warranted.

### 2.2 Anti-pattern bullet — identical wording in all three files

**Placement.**
- `project-template/CLAUDE.md`: append as a new bullet to the
  universal (non-conditional) anti-patterns list under
  `## [CONDITIONAL] Anti-patterns — never introduce these` (current
  lines 338–344). The list begins "Massive view controllers …" and
  ends "Editing generated Protobuf or gRPC code by hand." The new
  bullet is added as the final bullet of that universal list, **before**
  the `[PLATFORM_ANTIPATTERNS — fill in from loaded skills]`
  placeholder on line 364.
- `project-template/AGENTS.md`: append as a new bullet to the
  anti-patterns list under `## [CONDITIONAL] Anti-patterns — never
  introduce` (current lines 227–233). The list begins "Calling gRPC
  stubs directly from ViewModels or Views." and ends "Editing
  generated Protobuf or gRPC code by hand." The new bullet is added as
  the final bullet of that list, **before** the
  `[PLATFORM_ANTIPATTERNS — fill in from loaded skills]` placeholder
  on line 235.
- `project-template/GEMINI.md`: append as a new bullet to the
  anti-patterns list under `## [CONDITIONAL] Anti-patterns — never
  introduce these` (current lines 285–293). The list begins "Massive
  view controllers …" and ends "Editing generated Protobuf or gRPC
  code by hand." The new bullet is added as the final bullet of that
  list, **before** the `[PLATFORM_ANTIPATTERNS — fill in from loaded
  skills]` placeholder on line 295.

**Anti-pattern bullet text (identical in all three files — copy
verbatim):**

```markdown
- Branching on concrete types to discover what an abstraction supports, instead of querying a capability value or interface.
```

**Tool-specific framing — justified deviations.** None.

---

## 3. Location 4 — apple-architecture-core/SKILL.md

**Placement.** Insert as a new section **immediately after** the
existing `## Protocol abstractions` section (current rules 8–10) and
**before** the existing `## Actor isolation and state` section
(current rules 11–13).

**Renumbering instruction.** Existing rules 11–23 shift to 15–27. The
new section introduces rules 11–14.

**New section text (copy verbatim, then renumber the file's
subsequent rules accordingly):**

```markdown
## Capabilities pattern

11. Make what a type supports explicit and queryable. Callers do not
discover unsupported operations through `fatalError`, `throw`, or
`switch` on concrete types. Reach for this pattern proactively during
architecture — not only when fixing an LSP violation. Capabilities and
LSP are independent required practices; apply each on its own merits.

12. **Value-based form in Swift.** Expose supported operations as an
`OptionSet` (bitmask), a `Set<Enum>` of a focused operation enum, or a
frozen struct of `Bool` flags, exposed on the abstraction as a
read-only property. Validate capability compatibility at the
*composing* type's initializer — reject incompatible pairings at
construction time, not at call time. Example: a `Broker` protocol
declares `var capabilities: BrokerCapabilities { get }` where
`BrokerCapabilities` is an `OptionSet` (`.placeOrder`, `.cancelOrder`,
`.streamQuotes`, …). Callers check
`broker.capabilities.contains(.streamQuotes)` before invoking the
streaming call.

13. **Interface-based form in Swift.** Split behavior into small,
focused protocols. A type adopts only the protocols it genuinely
supports. Callers query with a downcast to the capability protocol
(`if let streaming = broker as? StreamingQuoteProvider { … }`), never
to the concrete type. Compose protocols via protocol inheritance or
generic constraints (`where Broker: StreamingQuoteProvider`). Do not
emulate capabilities by throwing from stub conformances — a type that
does not stream must not conform to `StreamingQuoteProvider` at all.

14. **Where capability validation belongs.** Initializers of the
composing type (account ⇠ broker, order router ⇠ broker, quote
aggregator ⇠ provider) reject incompatible pairings at construction
time. Call sites query capabilities only for behavior that legitimately
varies across conforming types — never as a substitute for
LSP-compliant method implementations.
```

**Tool-specific framing — justified deviations.** N/A (this file is a
single skill, not part of the trinity).

---

## 4. Location 5 — python-best-practices/SKILL.md

**Placement.** Insert as a new section **immediately after** the
existing `## Error handling` section (current rules 10–13) and
**before** the existing `## Tooling` section (current rules 14–20).

**Renumbering instruction.** Existing rules 14–32 shift to 18–36. The
new section introduces rules 14–17.

**New section text (copy verbatim, then renumber the file's
subsequent rules accordingly):**

```markdown
## Capabilities pattern

14. Make what a type supports explicit and queryable. Callers do not
discover unsupported operations through `NotImplementedError`, silent
`pass`, `hasattr` probes, or `isinstance` branching on concrete types.
Reach for this pattern proactively during architecture — not only when
fixing an LSP violation. Capabilities and LSP are independent required
practices; apply each on its own merits.

15. **Value-based form in Python.** Expose supported operations as a
class-level attribute — an `enum.Flag` (bitwise capabilities), a
`frozenset[Operation]` over an `enum.Enum`, or a frozen
`@dataclass(frozen=True)` of boolean fields. Validate capability
compatibility in the composing type's `__init__` — raise early on
incompatible pairings, not at call time. Example: a `Broker`
`Protocol` declares `capabilities: ClassVar[BrokerCapability]` where
`BrokerCapability` is an `enum.Flag` (`PLACE_ORDER | CANCEL_ORDER |
STREAM_QUOTES | …`). Callers check
`BrokerCapability.STREAM_QUOTES in broker.capabilities` before
invoking the streaming call.

16. **Interface-based form in Python.** Split behavior into small
`typing.Protocol` classes (structural subtyping). A type satisfies
only the protocols whose behavior it genuinely implements. Use
`@runtime_checkable` on protocols only when a runtime check is
required at a boundary; prefer static `isinstance` with generic bounds
when the check is compile-time. Callers do
`if isinstance(broker, StreamingQuoteProvider): …`. A broker that does
not stream simply omits `stream_quotes` — it is not a
`StreamingQuoteProvider` by structural typing. Do not emulate
capabilities by raising `NotImplementedError` from stub implementations.

17. **Where capability validation belongs.** The composing class's
`__init__` (account ⇠ broker, router ⇠ broker, service factory)
raises a domain error on incompatible pairings. `try/except
NotImplementedError` at call sites, and `hasattr(obj, "method")`
probing, are anti-patterns — they are not substitutes for a capability
query. Never raise `NotImplementedError` for operations that could
instead be gated by a capability check.
```

**Tool-specific framing — justified deviations.** N/A.

---

## 5. Location 6 — Placeholder rule for future language skills

The pack currently has two architecture-adjacent language skills
targeted by BD-045 (`apple-architecture-core`,
`python-best-practices`). Future language skills
(`swift-best-practices`, `cpp-language`, `c-language`, `objc-language`,
and any language skill added later) should include an equivalent
capabilities-pattern section. To avoid design-level decisions at the
time a new language skill is written, a drop-in template follows.

**Template (copy into the new language skill, substitute the five
`<LANGUAGE-SPECIFIC>` slots, renumber as needed):**

```markdown
## Capabilities pattern

N1. Make what a type supports explicit and queryable. Callers do not
discover unsupported operations through exceptions, silent no-ops, or
branching on concrete types. Reach for this pattern proactively during
architecture — not only when fixing an LSP violation. Capabilities and
LSP are independent required practices; apply each on its own merits.

N2. **Value-based form in <LANGUAGE>.** <LANGUAGE-SPECIFIC: name the
idiomatic mechanism for a flag-set, bitmask, or enum set in this
language. Give one concrete example of a capability value declared on
an abstraction and one example of a caller querying it.> Validate
capability compatibility at association or initialization time —
reject incompatible pairings before the capability is needed.

N3. **Interface-based form in <LANGUAGE>.** <LANGUAGE-SPECIFIC: name
the idiomatic mechanism for small, focused interfaces, traits,
protocols, or structural types in this language. Give one concrete
example of a type adopting a capability interface and one example of a
caller querying for it.> Types that do not support a behavior do not
advertise the interface — no silent no-ops, no unconditional throws.

N4. **Where capability validation belongs.** <LANGUAGE-SPECIFIC:
identify the typical composing-type construction point for this
language — constructor, initializer, factory, builder.> Call sites
query capabilities only for behavior that legitimately varies across
conforming types — never as a substitute for LSP-compliant method
implementations.
```

This template is also the authoritative reference for any future audit
that checks language skills for capabilities-pattern coverage
(see §7 architecture-review rule 15 below).

---

## 6. Location 7 — architecture-review/SKILL.md

**Placement.** Insert as a new section **immediately after** the
existing `## Abstraction quality` section (current rules 11–13) and
**before** the existing `## Navigation and control flow` section
(current rule 14).

**Renumbering instruction.** Existing rules 14–15 shift to 18–19. The
new section introduces rules 14–17.

**New section text (copy verbatim, then renumber the file's subsequent
rules accordingly):**

```markdown
## Capabilities pattern

14. Verify the code reaches for the capabilities pattern proactively —
not only when fixing an LSP violation. Capabilities and LSP are
independent required practices; both must be present where each
applies. A codebase that applies both avoids a wide class of runtime
surprises — callers know what an abstraction supports before invoking
it, and every declared interface method is meaningfully implemented.

15. Flag absence of any capability mechanism in any abstraction whose
conforming types have variable supported operation sets. If two or
more conforming types differ in what operations they support, some
form of capability query must exist for callers to check before
invoking — either value-based (enum set, bitmask, flag struct) or
interface-based (small focused protocol, trait, or structural type).
Loaded language skills supply the idiomatic mechanism for this
language.

16. Flag interface implementations that throw "not supported" (or an
equivalent runtime error, e.g. `NotImplementedError`, `fatalError`,
silent no-op) for operations that could instead be gated by a
capability check. The conforming type should either implement the
operation meaningfully (LSP), not declare the method (interface-based
capability), or the caller should gate the call upstream with a
capability query (value-based).

17. Flag caller code that branches on the concrete type behind an
abstract reference to discover what the abstraction supports. Callers
must use the capability mechanism — query a capability value, or
conditionally downcast to a capability protocol — never inspect the
concrete type.
```

**Tool-specific framing — justified deviations.** N/A.

---

## 7. Location 8–10 — auditor-architecture agent (three tool files)

**Placement.** In each of the three auditor-architecture files, insert
a new scope bullet in the Scope list, **immediately after** the
existing `LSP compliance` bullet and **before** the existing
`Observability infrastructure` bullet.

Keeping LSP and Capabilities as two separate bullets (rather than
extending the LSP bullet) reflects BD-045's "independent required
practices" language and ensures a finding from one category is not
miscategorized as the other in the auditor's output.

### 7.1 `project-template/.claude/agents/auditor-architecture.md`

Insert after line 21 (end of the `LSP compliance` bullet, which ends
with "domain code branching on concrete types.") and before line 22
(the blank line preceding `Observability infrastructure`).

**New bullet text (markdown, copy verbatim):**

```markdown
- **Capabilities pattern adherence** — abstractions whose conforming
  types have variable supported operation sets but expose no
  capability mechanism (value-based flag set or interface-based query);
  "not supported" throws or silent no-ops that indicate a missing
  capability gate rather than a legitimate LSP-compliant
  implementation; caller code that interrogates the concrete type
  behind an abstract reference instead of querying a capability.
  Capabilities and LSP are independent required practices — file
  capability findings under this bullet, not under LSP.
```

### 7.2 `project-template/.codex/agents/auditor-architecture.toml`

Insert inside the `developer_instructions = """…"""` block, in the
`Scope (per audit-methodology rule 15):` bulleted list, **immediately
after** the `LSP compliance` bullet (which ends
"domain code branching on concrete types.") and **before** the
`Observability infrastructure` bullet.

**New bullet text (plain bullet, no markdown bold, to match the
surrounding TOML-embedded list style):**

```
- Capabilities pattern adherence — abstractions whose conforming types have variable supported operation sets but expose no capability mechanism (value-based flag set or interface-based query); "not supported" throws or silent no-ops that indicate a missing capability gate rather than a legitimate LSP-compliant implementation; caller code that interrogates the concrete type behind an abstract reference instead of querying a capability. Capabilities and LSP are independent required practices — file capability findings under this bullet, not under LSP.
```

**Tool-specific framing — justified deviation.** The Codex file embeds
its scope list inside a TOML triple-quoted string and uses plain
bullets without markdown bold (consistent with every other bullet in
that block). The semantic content is identical to the Claude and
Gemini versions — only the formatting matches the surrounding style of
each file. This matches the existing trinity pattern in these three
auditor files.

### 7.3 `project-template/.gemini/agents/auditor-architecture.md`

Insert after line 21 (end of the `LSP compliance` bullet, which ends
with "domain code branching on concrete types.") and before line 22
(the blank line preceding `Observability infrastructure`).

**New bullet text (markdown, copy verbatim — identical to the Claude
version in §7.1):**

```markdown
- **Capabilities pattern adherence** — abstractions whose conforming
  types have variable supported operation sets but expose no
  capability mechanism (value-based flag set or interface-based query);
  "not supported" throws or silent no-ops that indicate a missing
  capability gate rather than a legitimate LSP-compliant
  implementation; caller code that interrogates the concrete type
  behind an abstract reference instead of querying a capability.
  Capabilities and LSP are independent required practices — file
  capability findings under this bullet, not under LSP.
```

---

## 8. Trinity symmetry audit

The following wording is identical across the three trinity files
(CLAUDE.md, AGENTS.md, GEMINI.md):

- The complete `## Capabilities pattern` section text in §2.1,
  including the "Relationship to LSP" subsection.
- The anti-pattern bullet text in §2.2.

The following wording is identical across the two markdown auditor
files (Claude, Gemini):

- The scope bullet text in §7.1 and §7.3.

The Codex auditor file (§7.2) carries semantically identical content,
with formatting adjusted to match the plain-bullet, non-bold style of
its existing TOML-embedded scope list. This is the same deviation
pattern already present for every other scope bullet in the three
auditor files and is therefore justified.

No other tool-specific deviations are required, and none are proposed.

---

## 9. LSP-vs-capabilities relationship — exact language reference

Wherever the drafts above speak to the relationship between LSP and
the capabilities pattern, the wording uses the BD-045 formulation:

> "LSP and the capabilities pattern are both required coding
> practices, applied independently. Neither is a prerequisite for the
> other, and neither is the motivation for the other. They work well
> together when both are present, but this is a benefit of using both
> — not a dependency between them. Each stands on its own merits and
> is required regardless of whether the other is in use."

Instances in this report where the relationship is stated explicitly:

- §2.1 — "Relationship to LSP" subsection in the trinity section
  (the full formulation, verbatim from BD-045).
- §3 rule 11 (apple-architecture-core) — "Capabilities and LSP are
  independent required practices; apply each on its own merits."
- §4 rule 14 (python-best-practices) — same.
- §5 (language-skill placeholder) rule N1 — same.
- §6 rule 14 (architecture-review) — "Capabilities and LSP are
  independent required practices; both must be present where each
  applies."
- §7 (auditor-architecture, all three files) — "Capabilities and LSP
  are independent required practices — file capability findings under
  this bullet, not under LSP."

The formulation is never softened, and in no draft is the pattern
presented as an LSP escape hatch. The pattern is presented in every
location as a first-class proactive design tool.

---

## 10. Open points and handoffs for Phase 3 / Phase 4

The drafts above are ready for implementation. Two small items are
intentionally deferred to later steps, not left for an implementer to
decide:

1. **Renumbering in per-language skills and in architecture-review.**
   Each skill uses sequential rule numbering. The drafts above specify
   the insertion point and the shift explicitly. Phase 4 implementation
   will update all internal cross-references to renumbered rules. A
   grep sweep for `rule N` or `rule 1[14-9]` against the pack at
   implementation time is the verification step; no new design
   decision is required.

2. **Back-reference from `audit-methodology` to the new capability
   scope bullet.** The auditor-architecture files reference
   `audit-methodology` rule 15 as the source of their scope. If
   Phase 3 finds that rule 15 in `audit-methodology/SKILL.md` needs a
   matching extension naming "capabilities pattern adherence" as part
   of the architecture cluster's scope, that is a Phase 3 decision
   surfaced here for the Step 8 touch-point inventory. It is *not* a
   BD-045 location requirement and is noted only because it may
   surface in the structural review at Step 11.

Neither item blocks the BD-045 drafts themselves. All nine locations
have ready-to-use text.

---

## 11. Cross-reference — BD-045 "What to add" to report sections

| BD-045 "What to add" location | This report |
|---|---|
| 1. Trinity files: Capabilities pattern section | §2.1 |
| 1. Trinity files: LSP relationship statement | §2.1 (Relationship to LSP) |
| 1. Trinity files: anti-pattern bullet | §2.2 |
| 2. apple-architecture-core language-specific rules | §3 |
| 2. python-best-practices language-specific rules | §4 |
| 2. Placeholder rule for future language skills | §5 |
| 3. architecture-review rule extension | §6 |
| 4. auditor-architecture (Claude / Codex / Gemini) extension | §7.1 / §7.2 / §7.3 |

---

*End of step-03-bd045-capabilities.md.*
