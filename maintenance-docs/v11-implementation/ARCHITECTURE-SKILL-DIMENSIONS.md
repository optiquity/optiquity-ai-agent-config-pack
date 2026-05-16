# ARCHITECTURE — Skill Dimensions and Organization Model (v11)

**Type:** Read-only architecture design (pack-architect output).
**Status:** Draft for pack-planner sequencing. No implementation in this doc.
**Date:** 2026-05-11.
**Branch context:** `v11-dev`.

This design replaces the implicit four-dimension framing in
`project-template/docs/pack/PLATFORM-SKILLS.md` with an explicit
five-dimension model plus a small set of skill-organization patterns. It
also enumerates every downstream surface that must change and surfaces
gaps and risks that prior in-flight v11 work did not address.

The design must be read together with:

- `project-template/docs/pack/PLATFORM-SKILLS.md` (current dimensions and
  skill inventory)
- `maintenance-docs/v11-implementation/RESEARCH-NON-APPLE-UI-SKILLS.md`
  (Phase 1 input for web / Android / embedded)
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-PYTHON-SKILL-SPLIT.md`
  (just-shipped split that this design partially reframes)

---

## 0. Executive summary

1. **Five dimensions, not four.** Add **D5 — Deployment surface** and
   reframe D2 (Languages) to be a true derived/auxiliary axis layered on
   top of D1+D3, not an independent selection. Treat
   `audit-methodology` and the `auditor-*` cluster as **trigger-loaded**,
   not dimension-loaded, and call that out explicitly.
2. **Recognize a base tier.** Several skills (`error-handling`,
   `documentation`, `dependency-intake`, `repo-ops`, `planning`,
   `architecture-review`, `api-design`, `security-patterns`) load
   regardless of D1–D5. Promote them from "Tier 1 role skills" to a new
   **Tier 0 base tier** so the dimension tables stop carrying skills that
   never actually depend on the project shape.
3. **Three skill-organization patterns, with explicit selection rules.**
   `core+layers`, `siblings-without-core`, and `standalone`. The Apple
   pattern is the right choice only when there are 2+ leaf platforms in
   the same family with substantial shared substrate (~10+ rules). The
   recently shipped Python split is correctly a `siblings-without-core`
   case; do **not** retroactively introduce `python-architecture-core`.
4. **The biggest downstream impact** is not the skill renames themselves —
   it is the migrator. Every dimension reframe creates a v10.1→v11 (or
   v11→v12) skill-rename / skill-split / skill-retire surface that the
   migrator must handle without losing customizations. The
   `python-architecture` → `python-server-architecture` +
   `python-data-architecture` migrator code (S5b) is the prototype; the
   plan must generalize it to a **skill-evolution adapter** in
   `scripts/lib/migrator-skills.sh` rather than open-code each rename.

---

## 1. Diagnosis of the current four dimensions

This section evaluates the existing model in
`project-template/docs/pack/PLATFORM-SKILLS.md` lines 30–113.

### 1.1 D1 Platform targets — sound, but conflates two concepts

D1 is the closest thing the model has to a clean axis: it answers "what
OS / runtime substrate does this code execute on?" It is sound for iOS,
macOS, and the planned Android / web. Two concerns:

- **Embedded conflation.** `embedded` as a single D1 entry lumps MCU
  bare-metal, RTOS-hosted MCU, and embedded-Linux. These three share
  less substrate than iOS and macOS do (embedded-Linux runs glibc + a
  kernel scheduler; an MCU does not). The
  `RESEARCH-NON-APPLE-UI-SKILLS.md` Risk 1 (lines 552–561) already
  surfaces this and recommends scoping the proposed
  `embedded-architecture` to MCU-class only. Disposition (recommended in
  §3 below): treat `embedded-mcu` and `embedded-linux` as separate D1
  entries from the start; do not paper over the difference.
- **"No platform"** (the Python-server-only case at PLATFORM-SKILLS.md
  line 125) is currently elided. It should be explicit — `linux-server`
  is a D1 value with its own (currently empty) skill set; representing
  it as `(none)` makes the matrix non-uniform. See §3.

### 1.2 D2 Languages — leaky; mostly derived, not independent

D2 is the most problematic dimension. Inspect the current rows
(PLATFORM-SKILLS.md lines 50–58):

- Swift, C, C++, Objective-C are **derived from D1** in every realistic
  project: choosing iOS/macOS forces Swift; embedded forces C/C++; an
  Apple project may add ObjC for legacy interop. They never appear
  independently of a platform that requires them.
- Python is the conspicuous exception — it is selected independently of
  any platform target (Python on Linux, Python embedded inside a
  Swift-on-macOS app, Python as a CLI tool on any OS).
- Future Kotlin will be derived from Android; future TypeScript from
  web; C# from Windows; Rust is independent (cross-platform like
  Python).

The honest framing is: **D2 is an independent axis only for languages
that are not bound to a single D1 family** (Python, Rust, future
cross-platform languages). For everything else, D2 entries are
*consequences* of D1 selections, and listing them as a separate user
question creates the false impression of orthogonality.

### 1.3 D3 Component roles — does double duty

D3 currently mixes two concepts (PLATFORM-SKILLS.md lines 80–94):

- **App-layer role** — client / server / embedded library. This is
  about the code's position in a deployed system and influences which
  *server-side* or *data-side* concerns apply. `Python server` is this
  shape.
- **Functional concern** — auth, search, payments. This is about
  domain functionality cutting across whatever layer the code is in.
  No D3 entries today are functional concerns, but the BD-119
  framework descriptions and the `x-brokerage-api` example
  (PLATFORM-SKILLS.md line 341) presume custom skills will fill this
  slot.

The split is real but currently latent. App-layer roles are what D3
should formally be; functional concerns are properly **custom skills**
(the `x-` prefix family) and should not pollute D3. The "Role adds a
skill only when ALL three conditions are true" gate at lines 88–93 is
fine, but it tries to do too much by also gating functional concerns.

### 1.4 D2 ∩ D3 collapses into a single matrix

The cell that loads `python-server-architecture` and
`python-data-architecture` (PLATFORM-SKILLS.md line 82) is not "D3 adds
skills"; it is "**(language=Python) ∩ (role=server)** loads
`python-server-architecture`, and **(language=Python) ∩ (role=any
multi-file Python with data access)** loads
`python-data-architecture`." The skills are language-specialized
specializations of a role. Apple has no equivalent today only because
the Apple skills (apple-architecture-core / ios-architecture /
macos-architecture) are organized D1-first; if a Swift server skill
were added, it would similarly be `(language=Swift) ∩
(role=server)` → `swift-server-architecture`.

This is not evidence that D2 and D3 should collapse into one
dimension. It is evidence that **the loading model is a sparse
matrix, not a set of independent rows.** Each dimension contributes a
*selector*; some skills are loaded by a single selector, others by an
intersection of selectors. The PLATFORM-SKILLS.md tables should make
that explicit (skills declare their selector predicate; the loader
unions them) instead of pretending each dimension owns a flat list.

### 1.5 D4 Communication protocols — sound

D4 is clean. `gRPC`, `REST`, future `GraphQL`, future
`realtime-patterns` (WebSocket/SSE) and `messaging-patterns` are
genuinely independent of D1, D2, and D3. A project can mix them; each
adds its own skill. No change needed here.

### 1.6 Missing D5 — Deployment surface

`deployment-apple` and `deployment-python` exist today (and are loaded
by `auditor-ops` per PLATFORM-SKILLS.md line 224). They do not fit
cleanly under D1–D4:

- They are not D1: deployment-apple covers code signing and
  notarization, which is a *distribution* concern, not a runtime
  concern.
- They are not D2: deployment-python is the same packaging /
  observability concerns regardless of which Python version.
- They are not D3.
- They are not D4.

The model needs **D5 — Deployment surface** with values like
`apple-distribution` (App Store / notarization / privacy manifest),
`linux-container` (Docker / health checks / observability config),
`apple-enterprise` (TestFlight / ad-hoc distribution), future
`android-distribution`, `web-static-cdn`, `web-edge`, etc. The current
`deployment-aws` and `deployment-k8s` planning would fit here too,
under `linux-container` sub-values.

### 1.7 Audit-methodology and auditor-* — different trigger model

`audit-methodology` is loaded by every auditor invocation
(PLATFORM-SKILLS.md line 270, 194). It is not selected by D1/D2/D3/D4 —
it is selected by **who is invoking it** (the auditor agent and its
seven subagents). Likewise `architecture-review` is selected by the
architect agent regardless of project shape.

This is a **trigger model**: skills load because of *agent role*, not
project shape. The model should call this out as a third selection
mechanism, sitting alongside dimension-based selection and
intersection-based selection. The current PLATFORM-SKILLS.md hides this
by mixing role-loaded skills into the Tier 1 table without flagging
them as "always on for agent X regardless of project."

---

## 2. Skill-organization patterns

Three patterns exist in the catalog today; the design must name them
explicitly so future skill authors can choose correctly.

### 2.1 Pattern A — `core+layers` (the Apple pattern)

A shared core skill plus per-leaf-platform skills, loaded as a *set*.
Today: `apple-architecture-core` + `ios-architecture` +
`macos-architecture`. The core carries the substrate-shared rules
(SwiftUI defaults, layer discipline, actor isolation); each leaf
specializes for its OS surface (iOS scene lifecycle, macOS NSDocument).

**Use this pattern when ALL are true:**

1. Two or more leaf platforms exist *today* (not "might exist
   eventually") in the same D1 family.
2. The shared substrate is substantial — roughly 10+ rules that would
   otherwise be duplicated across leaves.
3. Leaves have non-trivial platform-specific surfaces (~10+ rules each).
4. Leaves are cleanly separable — a project targeting one leaf does not
   need the other leaf's rules.

**Do NOT use this pattern when:**

- Only one leaf exists (the "core" is just the only skill — adds
  indirection without de-duplication benefit).
- The "shared core" is fewer than ~5 rules (better to inline duplicate
  rules into each leaf and accept the redundancy — the BD-035 split
  consciously did this with rules 2 and 4).
- Leaves overlap so much that selecting between them is artificial
  (this is the embedded-MCU vs embedded-Linux risk — they are
  superficially in the same D1 family but share little substrate).

### 2.2 Pattern B — `siblings-without-core`

Two or more peer skills with intentionally duplicated foundational
rules and no umbrella. Today: `python-server-architecture` +
`python-data-architecture`. Each is independently loadable; the small
overlap (DI, stateless services) is duplicated by design and the two
SKILL.md Applicability sections call out the duplication so future
maintainers do not "deduplicate" by deleting one copy.

**Use this pattern when:**

- The two skills serve genuinely different agent contexts (a non-server
  CLI tool wants the data rules, not the server rules).
- The shared substrate is so small (≤5 rules) that an intermediate
  `*-core` skill would be a thin wrapper.
- Independent loadability matters more than DRY.

**Do NOT use this pattern when:**

- The shared substrate exceeds ~10 rules and keeps growing — promote to
  Pattern A.
- One sibling is always loaded with the other in practice — collapse
  into a single skill.

### 2.3 Pattern C — `standalone`

A single self-contained skill with no peers and no core. Today:
`grpc-patterns`, `rest-patterns`, `c-language`, `cpp-language`,
`objc-language`, `swift-best-practices`, `python-best-practices`,
`security-patterns`, etc.

**Use this pattern by default.** Standalone is the right shape unless
Pattern A or B explicitly applies. Most skills are standalone and stay
that way.

### 2.4 Pattern selection — the `web-architecture` decision

The Phase 1 RESEARCH-NON-APPLE-UI-SKILLS.md (Risk 2, lines 562–573)
asks whether `web-architecture` should be Pattern A
(`web-architecture-core` + `web-react` + `web-vue` + `web-angular` +
`web-svelte`) or Pattern C (single skill with framework-conditional
rules).

**Recommendation: Pattern C now.** The proposed rule set is 12 rules
and most are framework-agnostic (hydration mismatch, accessibility tap
target, CLS, web fonts, modal trap). The framework-specific rules
(`react-hooks/exhaustive-deps`, Vue ref/reactive, Angular OnPush,
Svelte stores) are conditional bullets *within* a single skill — like
`apple-architecture-core` lumps SwiftUI + UIKit + AppKit together
without splitting per UI framework. **Reassess to Pattern A when the
total rule count exceeds ~25 OR when a single framework's rule subset
exceeds ~15.** Same threshold the Apple skills passed before being
split.

### 2.5 Pattern selection — the `embedded-architecture` decision

`embedded-architecture` is *prima facie* a Pattern A candidate
(`embedded-architecture-core` + `embedded-mcu` + `embedded-linux`)
because the two leaves have different substrates. But the substrates
share so little (memory layout, watchdog, refresh budget on MCU; ELF
loaders, systemd, glibc on Linux) that a shared core would be near
empty.

**Recommendation: two standalone Pattern C skills** —
`embedded-mcu-architecture` and `embedded-linux-architecture` — and
ship only `embedded-mcu-architecture` in v11.0 (matches the proposed
11 rules in RESEARCH-NON-APPLE-UI-SKILLS.md §4, lines 371–446).
Defer `embedded-linux-architecture` to a later minor when demand
materializes. Do **not** create a `core` for a family of two when the
shared rule count would be under 5.

### 2.6 The Python split was correct — leave it alone

The recently shipped Python split (`python-server-architecture` +
`python-data-architecture` with no core) is the right shape per these
rules: ~5 shared rules duplicated, two genuinely different load
contexts (server vs non-server multi-file Python). **Do not
retroactively introduce `python-architecture-core`.** The
IMPLEMENTATION-REPORT-PYTHON-SKILL-SPLIT.md "Pre-Open Questions" §1
asked exactly this; the answer per the patterns above is: keep the
sibling shape.


---

## 3. Recommended dimension scheme

Five dimensions plus three orthogonal load mechanisms (base, role-trigger,
custom). Each dimension has a **framing rule** precise enough to classify
a new skill without further design discussion.

### 3.1 D1 — Runtime / OS substrate

**Framing rule.** "What OS or hardware substrate does this code execute
on at runtime?" One value per executable target. Multi-target projects
select multiple values (e.g., universal Apple app selects iOS and
macOS).

| D1 value | Skills loaded |
|---|---|
| `ios` | `apple-architecture-core`, `ios-architecture` |
| `macos` | `apple-architecture-core`, `macos-architecture` |
| `android` | `android-architecture` |
| `web-browser` | `web-architecture` |
| `linux-server` | (none — Python / Rust language skills cover) |
| `embedded-mcu` | `embedded-mcu-architecture` |
| `embedded-linux` (deferred) | `embedded-linux-architecture` (deferred) |
| `windows` (deferred) | `windows-architecture` (deferred) |

Note: D1 explicitly enumerates `linux-server` as a value (replacing the
elided "no platform" case). It loads no D1 skill but satisfies the
matrix.

### 3.2 D2 — Cross-platform languages

**Framing rule.** "Which programming languages are present in the
codebase that are NOT already implied by the D1 selection?" Languages
implied by D1 (Swift⇐Apple, Kotlin⇐Android, TypeScript/JavaScript⇐web,
C/C++⇐embedded-MCU) load via D1. D2 carries only languages that can
appear in *any* D1 (Python, future Rust, future Go).

| D2 value | Skills loaded |
|---|---|
| `python` | `python-best-practices`, `dependency-python` |
| `rust` (deferred) | `rust-best-practices`, `dependency-rust` |
| `go` (deferred) | `go-best-practices`, `dependency-go` |

The Apple-family languages (Swift, ObjC, C, C++) load via D1, not D2.
The current "C / C++ / ObjC" rows in PLATFORM-SKILLS.md
(lines 56–58) become **D1-implied skills** under iOS / macOS /
embedded-MCU; no separate D2 selection is needed because no project
has C without an underlying D1 that implies it.

This reframing fixes the leaky D2 axis and is the most consequential
single change in this design.

### 3.3 D3 — Component role (app-layer)

**Framing rule.** "What architectural role does this component play in
the deployed system?" One value per component. Monorepos select
multiple values, one per component. Functional concerns (auth, search,
payments) are NOT D3 — they belong to custom skills.

| D3 value | Skills loaded |
|---|---|
| `client-app` | (none additional) |
| `server` | (D1 + D2 specific — see intersection table) |
| `embedded-runtime` | (none additional — D1+D2 carry it) |
| `shared-library` | (none additional — D2 carries it) |
| `cli-tool` | (none additional) |

D3 is mostly a *predicate* for intersections, not a skill loader on its
own. The intersection table (§3.7 below) carries the actual skill
loading.

### 3.4 D4 — Communication protocols

**Framing rule.** "How do components communicate with each other or
with external systems?" Multiple values per project are normal.

| D4 value | Skills loaded |
|---|---|
| `grpc` | `grpc-patterns` |
| `rest` | `rest-patterns` |
| `graphql` (deferred) | `graphql-patterns` |
| `realtime` (deferred) | `realtime-patterns` |
| `messaging` (deferred) | `messaging-patterns` |
| `none` | (none) |

No change from current D4 except the explicit `none` value.

### 3.5 D5 — Deployment surface (NEW)

**Framing rule.** "Where and how is this component distributed and
operated in production?" Multiple values per project are normal
(monorepo with Apple app + Linux container backend selects two D5
values).

| D5 value | Skills loaded |
|---|---|
| `apple-distribution` | `deployment-apple` |
| `linux-container` | `deployment-python` (when D2=python), future `deployment-container-base` |
| `android-distribution` (deferred) | `deployment-android` |
| `web-static-cdn` (deferred) | `deployment-web-static` |
| `web-edge` (deferred) | `deployment-web-edge` |
| `embedded-firmware` (deferred) | `deployment-embedded` |

This dimension absorbs the orphan deployment skills (`deployment-aws`,
`deployment-k8s` from BACKLOG-style mentions) cleanly. The current
`deployment-python` skill is technically a `(D2=python ∩
D5=linux-container)` intersection skill; in v11 it stays under D5 with
a D2 precondition documented in its Applicability section.

### 3.6 Tier 0 — Base skills (load for every project, every agent)

**Framing rule.** "Does this skill encode methodology or rules that
apply regardless of D1–D5?" If yes, it is base-tier; the loader
includes it for every relevant agent without consulting any dimension.

| Skill | Why base |
|---|---|
| `architecture-review` | Universal architecture methodology |
| `api-design` | Protocol-agnostic contract design |
| `dependency-intake` | Universal evaluation methodology |
| `documentation` | Universal research methodology + drift-detection |
| `error-handling` | Universal error philosophy |
| `planning` | Universal scoping / sequencing |
| `repo-ops` | Universal git workflow rules |
| `security-patterns` | Universal credential / injection / log-safety rules |
| `testing` | Universal test pyramid |
| `review` | Universal review priorities |
| `implementation` | Universal code-change workflow |
| `debugging` | Universal root-cause methodology |
| `ui-test-strategy` | Universal UI test selection (only loaded when a UI exists — see §3.8) |

The current "Tier 1 role skills" table at PLATFORM-SKILLS.md
lines 246–263 conflates two things: skills that are universal
methodology (above) and skills that are role-triggered. This design
separates them.

### 3.7 The intersection table — sparse cells

Some skills load only at the intersection of two or more dimensions.
The intersection table is the authoritative source for these:

| Skill | Predicate |
|---|---|
| `python-server-architecture` | D2=python ∩ D3=server |
| `python-data-architecture` | D2=python ∩ ((D3=server) ∨ (multi-file Python with data access)) |
| `deployment-python` | D2=python ∩ D5=linux-container |
| (future) `swift-server-architecture` | D2-implies-Swift via D1=macos ∩ D3=server |
| (future) `node-server-architecture` | D2-implies-TS via D1=web-browser server-side ∩ D3=server |

This makes the implicit cell-loading model explicit. The PM chat (or
future loader script) walks D1–D5 selectors plus the intersection
table; each skill's predicate is evaluated against the selected
values.

### 3.8 Trigger-loaded skills (load by agent role, not project shape)

| Skill | Trigger |
|---|---|
| `audit-methodology` | Loaded by `auditor` parent and all `auditor-*` subagents |
| `pm-startup` | Loaded by PM chat at session start |
| `verification-harness` | Loaded by `pack-coder` for verification runs |
| `implementation-report` | Loaded by `pack-coder` for report generation |
| `commit-discipline` | Loaded by every pack-* agent |

These are not in any dimension table because no project shape can
suppress them — the agent's role implies them.

### 3.9 What dimension count we end up with

**Five dimensions** (D1 substrate, D2 cross-platform-language,
D3 role, D4 protocol, D5 deployment) **plus three orthogonal load
mechanisms** (Tier 0 base, role-triggered, intersection-cell). The
"4 dimensions" framing in current docs collapses several distinct
things into one number; the honest count is "5+3."


---

## 4. Complete skill mapping (every existing skill → cell + agents)

This table classifies every SKILL.md present in
`project-template/skills/` (verified against the directory listing on
2026-05-11) under the five-dimension model. "Cell" identifies which
selection mechanism loads the skill. "Primary agents" lists agents that
should load it under the recommended scheme; this differs in places
from the current PLATFORM-SKILLS.md assignments and those differences
are listed in §5.

| Skill | Cell | Primary agents |
|---|---|---|
| `api-design` | Tier 0 base | architect, grpc-schema, reviewer |
| `architecture-review` | Tier 0 base | architect, reviewer, auditor-architecture |
| `audit-methodology` | Trigger (auditor cluster) | auditor parent + 7 subagents |
| `debugging` | Tier 0 base | coder, reviewer |
| `dependency-intake` | Tier 0 base | docs-researcher, auditor-security |
| `documentation` | Tier 0 base | docs-researcher, auditor-docs, every agent (passive) |
| `error-handling` | Tier 0 base | coder, reviewer, auditor-code |
| `implementation` | Tier 0 base (coder-triggered) | coder |
| `planning` | Tier 0 base (planner-triggered) | planner, architect |
| `repo-ops` | Tier 0 base (repo-ops-triggered) | repo-ops |
| `review` | Tier 0 base (reviewer-triggered) | reviewer |
| `security-patterns` | Tier 0 base | reviewer, auditor-security, auditor-code |
| `testing` | Tier 0 base (tester-triggered) | tester, auditor-tests |
| `ui-test-strategy` | Tier 0 base (when UI present) | tester, auditor-tests, auditor-ui |
| `pm-startup` | Trigger (PM chat) | PM chat only (not an agent) |
| `apple-architecture-core` | D1 ∈ {ios, macos} | architect, reviewer, auditor-architecture, auditor-ui |
| `ios-architecture` | D1=ios | architect, reviewer, auditor-architecture, auditor-ui, tester |
| `macos-architecture` | D1=macos | architect, reviewer, auditor-architecture, auditor-ui, tester |
| `swift-best-practices` | D1 ∈ {ios, macos} (D1-implied) | architect, coder, reviewer, auditor-code, auditor-ui |
| `objc-language` | D1 ∈ {ios, macos} (D1-implied, conditional on ObjC files) | coder, reviewer, auditor-code |
| `c-language` | D1=embedded-mcu (D1-implied) OR (D2=python ∩ embedded-Python via C API) | architect, coder, reviewer, auditor-code |
| `cpp-language` | D1=embedded-mcu (D1-implied, conditional) | coder, reviewer, auditor-code |
| `python-best-practices` | D2=python | architect, coder, reviewer, auditor-code |
| `dependency-python` | D2=python | docs-researcher, auditor-security |
| `dependency-swift` | D1 ∈ {ios, macos} | docs-researcher, auditor-security |
| `python-server-architecture` | Intersection: D2=python ∩ D3=server | architect, reviewer, auditor-architecture, auditor-code |
| `python-data-architecture` | Intersection: D2=python ∩ data-bearing | architect, reviewer, auditor-architecture, auditor-code |
| `grpc-patterns` | D4=grpc | architect, grpc-schema, coder, reviewer |
| `rest-patterns` | D4=rest | architect, coder, reviewer |
| `deployment-apple` | D5=apple-distribution | auditor-ops, docs-researcher |
| `deployment-python` | D5=linux-container ∩ D2=python | auditor-ops, docs-researcher |

**31 skills total.** All map cleanly. The reframing has moved many
skills out of "Tier 1 role" (where they were not actually
role-specific) into Tier 0 base; the dimension tables are now smaller
and more honest.

### 4.1 Skills that did not map cleanly (findings)

- **`security-patterns`** is currently "Tier 2 platform" in
  PLATFORM-SKILLS.md line 285, but its content is platform-agnostic
  (credential exposure, injection, deserialization, log safety apply
  everywhere). Recommend Tier 0 base. The "supply chain (CVEs,
  licenses)" sub-section is what couples it to D2-driven dependency
  skills, but that coupling is internal to the skill — the skill itself
  belongs in Tier 0.
- **`ui-test-strategy`** is Tier 1 today but only loads for projects
  with a UI. Treat it as Tier 0 with a UI-presence precondition,
  rather than Tier 1. Same effect, clearer model.
- **`api-design`** is Tier 1 today and assigned to architect +
  grpc-schema. It is universal contract-design methodology and belongs
  in Tier 0; it should also load for `reviewer` (for cross-protocol
  review consistency) which is missing today.
- **`debugging`** is Tier 1 today and assigned to coder. Reviewer
  often debugs inside review (especially for architect-flagged
  defects); add reviewer to its primary-agents list.

These are reclassifications, not skill rewrites. No SKILL.md content
changes; only PLATFORM-SKILLS.md tables and per-agent skill
assignments change.

---

## 5. Agent ↔ skill assignments — re-derivation under the new model

This section re-derives the per-agent skill list in
PLATFORM-SKILLS.md lines 162–225 under the recommended scheme.

### 5.1 `architect`

- **Tier 0 base:** architecture-review, api-design, planning,
  documentation, error-handling, security-patterns
- **Dimensional:** apple-architecture-core, ios-architecture,
  macos-architecture, swift-best-practices, python-best-practices,
  python-server-architecture, python-data-architecture, grpc-patterns,
  rest-patterns, c-language, cpp-language, objc-language — load those
  that match the project's D1/D2/D3/D4 selectors.

Differences from current: adds planning (currently architect does not
declare it but the BD-119 work shows architects use planning skill
constantly), documentation, error-handling, security-patterns
(currently missing).

### 5.2 `coder`

- **Tier 0 base:** implementation, debugging, error-handling,
  documentation
- **Dimensional:** swift-best-practices, python-best-practices,
  grpc-patterns, rest-patterns, c-language, objc-language, cpp-language

No major change; documentation added (coder verifies API behavior
inline).

### 5.3 `reviewer`

- **Tier 0 base:** review, error-handling, security-patterns,
  api-design, debugging
- **Dimensional:** swift-best-practices, python-best-practices,
  python-server-architecture, python-data-architecture, grpc-patterns,
  rest-patterns, apple-architecture-core, ios-architecture,
  macos-architecture, c-language, objc-language, cpp-language

Differences from current: adds api-design, debugging.

### 5.4 `tester`

- **Tier 0 base:** testing, ui-test-strategy (when UI present)
- **Dimensional:** swift-best-practices, python-best-practices,
  grpc-patterns, rest-patterns, ios-architecture, macos-architecture,
  c-language, objc-language, cpp-language

No change.

### 5.5 `planner`

- **Tier 0 base:** planning, architecture-review (for cross-checking
  architectural sequencing)

Adds architecture-review (currently missing); planner needs to
understand the architectural shape to sequence correctly.

### 5.6 `repo-ops`

- **Tier 0 base:** repo-ops

No change.

### 5.7 `docs-researcher`

- **Tier 0 base:** documentation, dependency-intake
- **Dimensional:** deployment-apple, deployment-python,
  dependency-swift, dependency-python

No change.

### 5.8 `grpc-schema`

- **Tier 0 base:** api-design
- **Dimensional:** grpc-patterns

No change.

### 5.9 `auditor` parent and subagents

Auditor parent loads only `audit-methodology` (trigger) and relays
per-subagent skill lists. Subagent loads:

- **`auditor-architecture`** — audit-methodology + apple-architecture-core +
  ios-architecture + macos-architecture + python-server-architecture +
  python-data-architecture (filtered by project D1/D2/D3)
- **`auditor-code`** — audit-methodology + error-handling + Tier 0
  security-patterns + language skills (swift-best-practices,
  python-best-practices, c-language, cpp-language, objc-language) +
  python-data-architecture / python-server-architecture as predicates
  match
- **`auditor-tests`** — audit-methodology + testing + ui-test-strategy
  + language skills
- **`auditor-docs`** — audit-methodology + documentation
- **`auditor-security`** — audit-methodology + security-patterns +
  dependency-swift / dependency-python as D2 selects
- **`auditor-ui`** — audit-methodology + apple-architecture-core +
  ios-architecture + macos-architecture + (future) android-architecture
  / web-architecture / embedded-mcu-architecture + swift-best-practices
- **`auditor-ops`** — audit-methodology + deployment-apple +
  deployment-python (filtered by D5)

Differences from current: auditor-code gets `security-patterns` from
Tier 0 (today it does not, even though log-safety and injection rules
overlap with code-level audit findings); auditor-ui gets the future
non-Apple platform skills as D1 expands.


---

## 6. Downstream impact catalog

This is the comprehensive list of files / scripts / rules that change
when the design in §3–§5 lands. The pack-planner sequences these into
commits.

### 6.1 Documentation surfaces

| File | Change required |
|---|---|
| `project-template/docs/pack/PLATFORM-SKILLS.md` | Major rewrite. New §"How skill selection works" describing 5 dimensions + 3 load mechanisms. New tables for D1–D5 (replacing the current four-question section). New §"Tier 0 base skills" table. New §"Trigger-loaded skills" table. New §"Intersection table" for sparse cells. Worked examples updated. Per-agent skill assignments updated per §5. Total skill count unchanged at 31. |
| `project-template/docs/pack/PM-CHAT.md` | Update the "skill selection at prompt-generation time" prose so the PM chat reads the new dimension tables and intersection table in the right order. |
| `project-template/CLAUDE.md` (`AGENTS.md`, `GEMINI.md` — trinity) | Update §"Skill loading" prose to describe the 5+3 model and point at PLATFORM-SKILLS.md as the authoritative reference. The "Active skills" line format does not change. Trinity rule applies — same edit in all three. |
| `supporting-docs/MIGRATION-v10-to-v11.md` | Add a new section "Skill model changes" that names every skill rename, every dimension reframe, and the migrator step that handles each. Reference the advisory file (§6.4) for ambiguous cases. |
| `supporting-docs/METHODOLOGY.md` | If it references "four dimensions" anywhere, update to "five dimensions plus base / trigger / intersection mechanisms." Spot-check; may not need changes. |
| `maintenance-docs/v11-implementation/RESEARCH-NON-APPLE-UI-SKILLS.md` | No changes; this design absorbs its outputs as the inputs they were. Phase 2 (architecture for the three new skills) under that research doc becomes redundant — this doc IS Phase 2 for the dimension question. The skill-content design (rule lists per skill) Phase 2 still needs to happen for the three new skills, but with different scoping per §6.6. |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-PYTHON-SKILL-SPLIT.md` | No content changes; classify retroactively as a Pattern B (siblings-without-core) example. The "Pre-Open Questions" §1 is answered "no, do not introduce a core." |
| `README.md` | The "30 skills" / "31 skills" mentions in the Repository Layout section need updating once skill counts shift (after web/Android/embedded-MCU/embedded-linux are added: 35 total). Version table v11.0 row may want a "skill model reframed (BD-NNN)" mention. |
| `BACKLOG.md` | New BD entries for the dimension reframe, the migrator skill-evolution adapter, and each new skill to be added. Existing BD-035 stays Resolved. |
| `CHANGELOG.md` | Single v11.0 entry mentioning the dimension reframe and the new skills. |

### 6.2 Scripts

| Script | Change required |
|---|---|
| `scripts/init-project.sh` | The `pack_skill_coverage_for()` table at lines 219–229 currently lists only language→skills coverage. It needs to be extended to consider D1/D5 selectors (current behavior infers Apple via Swift presence, which is approximate). Detection logic should consult the new D1 marker tables (the markers RESEARCH-NON-APPLE-UI-SKILLS.md proposes for web/Android/embedded). The post-install hint that mentions BD-136 trinity markers needs an extra line pointing the PM chat at the new D1–D5 tables. |
| `scripts/add-capability.sh` | The `capability_skills()` table at lines 107–125 already encodes a near-equivalent of the recommended scheme (language: / platform: / protocol: / role:) — extend to include `deployment:` (D5) values: `deployment:apple`, `deployment:linux-container`. Add `platform:android`, `platform:web-browser`, `platform:embedded-mcu` rows. The Python-language row already lists `python-data-architecture`; add intersection logic so `role:python-server` correctly adds both `python-server-architecture` AND `python-data-architecture` (currently it adds server only, leaving the data skill to come from the language row). |
| `scripts/validate-pack.py` | **Check 21** today validates per-CLI pack-help surface parity, not skill canonical phrases. The agent-canonical-phrase check is **Check 27** (per the file at line 1303). For this redesign, Check 27 needs a new conformance: every agent file's "Skills to load" block must enumerate skills consistent with PLATFORM-SKILLS.md's per-agent assignment for that agent. Add a new **Check 31** (allocated at BD-146 landing time; this paragraph said "Check 32 (next free)" at architect-write time, but the BD-146 landing took the next-free slot which was 31; subsequently BD-168 renumbered the pre-existing Check 32 phase-task-lib check to Check 35 and allocated new Checks 32/33/34 for the per-entry split validators) that parses PLATFORM-SKILLS.md tables and verifies (a) every skill in `project-template/skills/` appears in exactly one cell, (b) every skill name referenced in any agent file exists as a SKILL.md directory, (c) intersection-table predicates are syntactically well-formed. |
| `scripts/migrate-v10-to-v11.sh` | The S5b BD-035 rename helper at the bottom of this script is the prototype for skill-rename handling. The dimension reframe will produce additional renames / skill removals: e.g., if `audit-methodology` ever moved out of `project-template/skills/` (it does not under this design — keep), or if a future v12 retires deprecated D2 entries. **Recommendation: extract the BD-035 helper into a generic adapter at `scripts/lib/migrator-skills.sh`** (see §6.5) so the migrator does not open-code each new rename. For v11.0, S5b stays where it is (already shipped); the lib extraction is a v11.x or v12.0 follow-up. |
| `scripts/pack-tracker.sh` and `scripts/lib/tracker-*.sh` | No changes — tracker is dimension-agnostic. |

### 6.3 Skill files (SKILL.md changes)

| Skill | Change |
|---|---|
| `audit-methodology/SKILL.md` | The Subagent Clusters section (line 38) lists 7 clusters including `auditor-ui` whose detection markers are currently Apple-only. Rule 20 (the auditor-ui trigger) needs extension to include the new D1 markers per RESEARCH-NON-APPLE-UI-SKILLS.md detection criteria (web markers, Android markers, embedded markers). Per Phase-1 §5 recommendation (lines 530–548), add a short cross-platform UI checklist as a sub-bullet under rule 20 listing the 4 cross-platform concerns (state source-of-truth, interactive reachability, externalized strings, layout adapts to translation growth). |
| `architecture-review/SKILL.md` | Currently lists the platform-architecture skills it expects to be loaded with (line 7 mentions apple-architecture-core, python-server-architecture, python-data-architecture, grpc-patterns). Update that list as new platform skills (web-architecture, android-architecture, embedded-mcu-architecture) ship. Already in 4 surfaces (template + 3 distributed copies); change all four. |
| `documentation/SKILL.md` | No content change required, but reclassify as Tier 0 base in PLATFORM-SKILLS.md. |
| `error-handling/SKILL.md` | No content change required; reclassify as Tier 0 base. |
| `security-patterns/SKILL.md` | No content change required; reclassify as Tier 0 base. |
| `python-server-architecture/SKILL.md`, `python-data-architecture/SKILL.md` | Applicability sections already reference the predicate model implicitly. Add a one-line note to each: "Loaded via the PLATFORM-SKILLS.md intersection table; see that file for the exact predicate." |
| **NEW** `web-architecture/SKILL.md` | Author per RESEARCH-NON-APPLE-UI-SKILLS.md §2 (12 rules + 6 localization rules). Standalone skill (Pattern C). |
| **NEW** `android-architecture/SKILL.md` | Author per RESEARCH-NON-APPLE-UI-SKILLS.md §3 (13 rules + 6 localization rules). Standalone skill (Pattern C). |
| **NEW** `embedded-mcu-architecture/SKILL.md` | Author per RESEARCH-NON-APPLE-UI-SKILLS.md §4 (11 rules + 5 localization rules), renamed from `embedded-architecture` to make scope explicit. Standalone (Pattern C). |
| **DEFERRED** `embedded-linux-architecture/SKILL.md` | Stub-defer to v11.x or later minor; Linux-class embedded UI is out of v11.0 scope per §2.5. |

### 6.4 Migrator surface (v10 → v11 client adoption)

The migrator (`scripts/migrate-v10-to-v11.sh`) must handle these
client-side adjustments without losing customizations:

1. **Skill split (already shipped, S5b).** v10.x `python-architecture`
   → v11 `python-server-architecture` + `python-data-architecture`. The
   advisory file pattern ships unchanged.
2. **PLATFORM-SKILLS.md table reshape.** The four-dimension tables in
   v10.1 client copies become five-dimension tables. PLATFORM-SKILLS.md
   is a `transform` target in the migrator manifest — the reshape is
   pack-managed, not user-managed. Customizations live only in the
   `## Custom agents` and `## Custom skills` sections (lines 310–346),
   which the BD-136 trinity-marker preservation pattern already covers.
3. **Active skills line in CLAUDE.md / AGENTS.md / GEMINI.md.** The
   line format does not change. Skill *names* in the line might change
   only for the Python split case (handled by S5b). Web / Android /
   embedded skills are additive — clients adopting them do so by
   running `add-capability.sh --add platform:web-browser` after
   migration.
4. **No retroactive skill migrations needed for the dimension
   reframe.** Renaming "Tier 1 / Tier 2" to "Tier 0 base / dimensional
   / trigger / intersection" is a doc-level relabeling. Clients see
   identical skill files in identical directories.

### 6.5 New shared library — `scripts/lib/migrator-skills.sh`

Extract the BD-035 rename helper (`_v10_to_v11_rename_python_architecture_refs`)
into a generic adapter:

```
migrator_skill_rename
  --from <old-skill-name>
  --to-server <server-skill> --to-data <data-skill>  # for splits
  --to <new-skill-name>                              # for renames
  --advisory <path>
  --files <space-separated-file-list>
  --server-signal <regex>
  --data-signal <regex>
```

The function carries the per-line disambiguation logic (server signal,
data signal, advisory fallback). v11.0 keeps the BD-035 implementation
inline; v11.x or v12.0 extracts and rewrites S5b to call the shared
helper. **This belongs in BD-119's migrator framework family** — it is
a sibling to `migrator-stages.sh` and `migrator-manifest.sh`.

### 6.6 Phase-2 follow-on for non-Apple UI skills

`RESEARCH-NON-APPLE-UI-SKILLS.md` was paused pending this dimensions
pass. Phase 2 (architecture of the three new skills) now decomposes
into:

- **Phase 2A** — pack-architect produces a per-skill rule design for
  `web-architecture`, `android-architecture`,
  `embedded-mcu-architecture` (the 11–18 rules each with localization).
  Inputs: §2 / §3 / §4 of RESEARCH-NON-APPLE-UI-SKILLS.md and the
  detection markers in those sections.
- **Phase 2B** — pack-planner sequences the writing of the three
  SKILL.md files plus PLATFORM-SKILLS.md table edits plus
  audit-methodology rule 20 extension into approve-able commits.
- **Phase 3** — pack-coder implements per the plan.

The web-architecture / android-architecture / embedded-mcu-architecture
skills can land independently of the dimension reframe (they fit
either model). But the dimension reframe should ship FIRST, so the new
skills land in the new model rather than being retro-fitted. The
pack-planner schedules accordingly.

### 6.7 BD-136 trinity-marker interaction

BD-136 (trinity marker-section preservation, BACKLOG.md line 1385)
introduces Shape A / Shape B markers and a `renamed-from` annotation
for project Shape B sections that override pack canonical sections.
This dimension reframe creates two new marker-relevant scenarios:

1. **Skill rename via pack update** (Python split is the prototype):
   project's `## Active skills` line in trinity files contains the old
   skill name. The migrator's S5b advisory handles this today; the
   trinity-marker mechanism does NOT — markers preserve project-owned
   sections, but the `**Active skills:**` line is inside a Shape A
   pack-canonical section. The S5b advisory is the right tool;
   marker-based preservation is the wrong tool here. **Action:** none
   needed; the two mechanisms are non-overlapping. Document the
   non-overlap in MIGRATION-v10-to-v11.md.
2. **Custom skills section in PLATFORM-SKILLS.md.** That file's
   `## Custom agents` and `## Custom skills` sections are project-owned
   but are NOT inside trinity files (PLATFORM-SKILLS.md lives at
   `docs/pack/`, not at project root). They are preserved by the
   migrator's customization-preserve.sh sidecar mechanism (BD-088),
   not by BD-136 markers. **Action:** verify
   `customization-preserve.sh` continues to treat these sections as
   project-owned after the dimension reframe; the section header names
   do not change so this should be a no-op.


---

## 7. Gaps and risks not previously discussed

### 7.1 Gap — no observability skill, despite an "observability infrastructure" rule scattered across skills

`ios-architecture`, `macos-architecture`, and
`python-server-architecture` each carry "observability infrastructure"
as a sub-bullet (see PLATFORM-SKILLS.md lines 278, 279, 282).
`auditor-ops` reads `deployment-apple` / `deployment-python` for
"observability *configuration*" (line 224). Two adjacent concerns
(infrastructure rules vs. config rules) are split across four skills.

**Recommended disposition:** Defer. A dedicated `observability` skill
would be Tier 0 base (universal) and would absorb the scattered
sub-bullets. But absorption requires re-numbering rules in the
existing platform skills (which `auditor-architecture` cites by
number), and the audit-methodology cluster boundary between
`auditor-architecture` (infrastructure) and `auditor-ops` (config)
would have to be redrawn. Park as BD for v12 consideration.

### 7.2 Gap — no accessibility skill

Accessibility rules live in `apple-architecture-core`,
`ios-architecture`, `macos-architecture`, and the proposed
`web-architecture` / `android-architecture`. The proposed cross-platform
audit-methodology rule 20 extension (§6.3) addresses the audit side.
The skill side does not have a Tier 0 home for the universal
principles (semantic landmarks, focus order, screen reader
announcements as design constraints).

**Recommended disposition:** Defer to v12. Adding an accessibility
skill before the non-Apple UI skills land would force premature
factoring; once web + Android + embedded-MCU are in, the shared
patterns will be visible and the right factoring obvious.

### 7.3 Gap — no concurrency skill

Concurrency rules are spread across `swift-best-practices` (Swift 6
strict concurrency), `python-best-practices` (asyncio), and
`apple-architecture-core` (actor isolation). A Tier 0
`concurrency-architecture` skill would carry the universal principles
(actor model, structured concurrency, cancellation propagation,
backpressure). Same risk as observability — reorganization cost.

**Recommended disposition:** Defer to v12. Note in BACKLOG as a known
factoring opportunity.

### 7.4 Risk — D5 ambiguity for monorepos

A monorepo with an Apple app + Linux container backend has D5 =
{`apple-distribution`, `linux-container`}. The deployment skills
loaded must apply *to the right component* — `deployment-apple` is
not relevant to the backend's containerization. The current loader
model loads both skills globally and trusts the agent prompt to scope
correctly. This is acceptable for v11 (the agent prompts already
handle multi-component scoping), but worth documenting as a known
gotcha in PLATFORM-SKILLS.md.

**Recommended disposition:** Document the monorepo-scoping convention
in the new D5 section. No skill change.

### 7.5 Risk — `python-data-architecture` predicate is fuzzy

The current Dimension 2 row says "multi-file Python with data access,
async I/O, or ML inference; otherwise omit" (PLATFORM-SKILLS.md line
54). The init-project.sh `pack_skill_coverage_for python` row at line
224 unconditionally lists it. The agent assignment for
`auditor-architecture` (line 198) tries to thread the conditional
through prose. The result is that detection inconsistency between
init-project, add-capability, and the PM chat is possible.

**Recommended disposition:** Make the predicate concrete: load
`python-data-architecture` if any of these markers are true: (1)
`requirements.txt` or `pyproject.toml` lists `sqlalchemy`,
`alembic`, `pydantic`, `aiohttp`, `httpx`, `psycopg`, `aiomysql`,
`asyncpg`, `redis`, `pymongo`, `motor`, `boto3`, `aioboto3`,
`grpc-tools`, `protobuf`, `pyarrow`, `pandas`, `numpy`,
`scikit-learn`, `torch`, `tensorflow`; (2) `>= 5` `.py` files outside
`tests/`. Otherwise omit. Encode this as a function in `lib/detect.sh`
and call it from init-project, add-capability, and reference it in
PLATFORM-SKILLS.md. Belongs in BD for v11.0 batch.

### 7.6 Risk — D2 reframe creates a cross-version skill-detection drift

If Swift / C / C++ / ObjC move from "D2 selection" to "D1-implied
loading," any external tooling or doc that reads the old D2 table will
report incorrect skill counts for Apple projects. Migration impact is
limited (the skills loaded per project do not change; only the *labeling*
of which dimension causes the load) but the BD-035-style migrator
advisory may need to mention the relabeling for clients who have
locally edited PLATFORM-SKILLS.md (rare but possible).

**Recommended disposition:** Add a one-line note to the migrator
output: "PLATFORM-SKILLS.md tables reshape from 4 dimensions to 5
dimensions; if you have locally edited that file, re-apply your edits
manually." Treat as an advisory, not a blocking error.

### 7.7 Risk — auditor-ui detection logic must consume PLATFORM-SKILLS.md

Per RESEARCH-NON-APPLE-UI-SKILLS.md Risk 3 (line 575), the auditor
currently has Apple markers hardcoded. The new D1 markers (web,
Android, embedded-MCU) need a mechanism that the auditor can consult.
The cleanest design (which that doc proposes) is for the auditor to
read PLATFORM-SKILLS.md to find applicable UI skills.

**Recommended disposition:** Adopt that design. Add a contract section
to `audit-methodology/SKILL.md` describing the auditor's read of
PLATFORM-SKILLS.md and its handling of "no UI skill matched"
(skip auditor-ui with logged reason).

### 7.8 Risk — the dimension reframe is a pack-product change masquerading
as a doc change

PLATFORM-SKILLS.md edits affect every consuming PM chat session; they
are not just documentation. If a PM chat read v10.x PLATFORM-SKILLS.md
once and cached the dimensions in its context, then upgrades to v11.0,
the cache is wrong. **Actual impact is minimal** — PM chat sessions
re-read PLATFORM-SKILLS.md every time they generate a prompt, per the
file's own header instruction (line 4). But it is worth flagging that
the reframe is a behavioral change, not a doc-only change, and the
v11.0 release notes should call it out.

**Recommended disposition:** Surface in MIGRATION-v10-to-v11.md and in
CHANGELOG.md as a behavioral note, not a doc note.

### 7.9 Gap — no skill-versioning convention

Skills do not carry a version stamp in their frontmatter. When the
Python split happened, a project on v10.x reading
`python-architecture/SKILL.md` and a project on v11.0 reading
`python-server-architecture/SKILL.md` had no machine-readable way to
know which version of the skill ruleset they were on. The migrator's
S5b advisory pattern catches the rename, but if a SKILL.md gets a
content-only major revision (no name change), there is no signal.

**Recommended disposition:** Defer to v12. Add a BACKLOG entry.

### 7.10 Risk — naming inconsistency: `*-best-practices` vs `*-language` vs `*-architecture` vs `*-patterns`

Today the catalog has all four suffixes in active use:

- `swift-best-practices`, `python-best-practices` (language style)
- `c-language`, `cpp-language`, `objc-language` (language structure)
- `ios-architecture`, `macos-architecture`, `python-server-architecture`,
  `python-data-architecture`, `apple-architecture-core` (architecture)
- `grpc-patterns`, `rest-patterns`, `security-patterns` (cross-cutting
  patterns)

Why is Swift `best-practices` but C `language`? Why is Python's
architecture split into `*-architecture` skills while Swift's is split
into `*-architecture-core` + leaf `*-architecture`? The convention is
not enforced.

**Recommended disposition:** Document the naming convention explicitly
in PLATFORM-SKILLS.md "Extending this file" section: `*-best-practices`
for languages with idiomatic-style rules; `*-language` for languages
where ownership / memory / interop dominate; `*-architecture` for
platform-specific structural rules; `*-patterns` for cross-cutting
concerns. Do **not** rename existing skills — the cost of breaking
external references outweighs the consistency benefit. New skills must
follow the convention.

---

## 8. Retroactive adjustments to already-shipped v11 work

### 8.1 Python split (IMPLEMENTATION-REPORT-PYTHON-SKILL-SPLIT.md)

**No retroactive changes required.** The split is correctly classified
as Pattern B (siblings-without-core) per §2.6 and §2.2. Pre-Open
Question §1 in that report ("should we add a python-architecture-core?")
is answered NO under this design.

The Pre-Open Question §3 ("should init-project.sh include
`python-server-architecture` in the Python language coverage?") is
answered NO — server is intersection-cell-loaded (D2=python ∩
D3=server) and `add-capability.sh role:python-server` correctly adds
it. init-project.sh's language-coverage table does not need server
detection.

The S5b migrator helper stays as-is for v11.0. Extraction into the
shared `migrator-skills.sh` library is a v11.x or v12.0 follow-up per
§6.5.

### 8.2 In-flight non-Apple UI research (RESEARCH-NON-APPLE-UI-SKILLS.md)

**Re-scope per §6.6.** Phase 2 is split into Phase 2A (per-skill rule
design — separate pack-architect pass) and Phase 2B (planning).
`embedded-architecture` renames to `embedded-mcu-architecture` per
§2.5; `embedded-linux-architecture` is deferred. `web-architecture`
stays single-skill (Pattern C) per §2.4. `android-architecture` stays
single-skill (Pattern C). The cross-platform UI checklist proposed in
that doc §5 lands as an extension to `audit-methodology` rule 20 per
§6.3.

### 8.3 BD-035 (Resolved) — does not need re-opening

BD-035 covered the Python split scope. The dimension reframe is BD-NNN
(new), not a BD-035 revisit. Leave BD-035 Resolved.

---

## 9. Summary for pack-planner

What the planner is sequencing:

1. **PLATFORM-SKILLS.md rewrite** under the 5+3 model — single commit
   touching that file plus the trinity (CLAUDE.md / AGENTS.md /
   GEMINI.md "Skill loading" section).
2. **Validator updates** — new Check 31 for skill-cell consistency (allocated at BD-146 landing time as the then-next-free slot; this entry said "Check 32" at architect-write time but landed as Check 31 since BD-146 reached the validator before any other "Check 32" candidate);
   Check 27 extension for per-agent skill-list conformance.
3. **Script updates** — `add-capability.sh` D5 row; `init-project.sh`
   detection extensions; `lib/detect.sh` new
   `python_data_marker_detected()` per §7.5.
4. **Skill reclassification** — no SKILL.md content changes for
   reclassification, but the four "promotion to Tier 0" skills
   (security-patterns, api-design, debugging, ui-test-strategy) get
   their PLATFORM-SKILLS.md rows moved.
5. **Documentation** — MIGRATION-v10-to-v11.md gets a "Skill model
   changes" section; CHANGELOG.md gets a behavioral-note entry;
   README.md skill counts updated.
6. **Phase 2A for non-Apple UI** — separate pack-architect pass
   producing per-skill rule designs.
7. **Phase 2B + 3 for non-Apple UI** — pack-planner + pack-coder
   sequence the new SKILL.md files plus PLATFORM-SKILLS.md table
   additions plus audit-methodology rule 20 extension.
8. **Deferred** — observability skill, accessibility skill, concurrency
   skill, skill versioning, embedded-linux-architecture, naming-convention
   migration. Each gets a BACKLOG entry, not a v11.0 batch.

The planner sequences (1)–(5) before (6)–(7) so the new skills land in
the new model rather than the old.

---

## 10. Open questions for the pack-coder / pack-planner / user

These are decisions the design intentionally leaves to downstream
sequencing because they depend on schedule, not on architecture:

1. **Is the dimension reframe a v11.0 batch or a v11.1 follow-up?** It
   is a documentation reshape that does not change which skills load
   for any project. v11.0 is the right home if there is schedule;
   v11.1 is acceptable if v11.0 is already over-scoped. The new
   skills (web, Android, embedded-MCU) can land independently.
2. **Should the `web-architecture` / `android-architecture` /
   `embedded-mcu-architecture` skills ship with the dimension reframe
   commit or as separate commits per skill?** Recommend separate
   commits per skill (one new SKILL.md + PLATFORM-SKILLS.md row per
   commit) for review tractability.
3. **Does the BD-035 S5b helper extraction into `migrator-skills.sh`
   ship in v11.0 or wait?** Recommend wait — the helper is shipped and
   working; extraction is a refactor that adds risk without
   user-visible value until a second skill rename is needed.
4. **Should `linux-server` D1 row exist if it loads no skill?**
   Recommend yes (matrix uniformity); it lets the new D5 dimension
   distinguish "Linux container backend" from "embedded Linux runtime"
   cleanly.

---

**Doc path:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md`

