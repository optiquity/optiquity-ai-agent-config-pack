# Pack Frontier Dashboard — Build Specification

Instructions for generating the dashboard fresh, from live project state, on every request.
Produce a single HTML page each time; save nothing between runs. This document is the spec a
slash command or a plain text request executes — each invocation reruns the whole recipe in §2.

---

## 0. What to build

A **single self-contained HTML page** — inline CSS + JS, data-URI images only, no external
network calls — presenting a live, at-a-glance mirror of pack work: what is in motion, everything
in play, and each backlog item's pipeline. Page title: **"Pack frontier — Optiquity Config Pack
dashboard."** Brand mark: **◆ Pack frontier**.

---

## 1. Global requirements — every page and section must respect these

Invariants. They govern all pages and outrank any page-specific detail below.

- **R1 — The repo is the source of truth.** The dashboard is a presentational mirror and states so.
  It never claims authority over the data.
- **R2 — Fresh every time, no cache.** Each build collects the entire state payload from the current
  project and renders from scratch. Persist nothing between builds.
- **R3 — Include committed and uncommitted work.** Assemble state from committed repo files **and** a
  live git working-tree read taken at build time, so in-flight work that is not yet committed still
  appears. This live read drives every "editing now" / "in progress" / worktree signal.
- **R4 — Deterministic render.** No timestamps, no clock, no randomness. Every signal derives from the
  collected state; identical state produces identical output. When the live git read is unavailable,
  all live surfaces fall back to a defined idle form.
- **R5 — Self-contained.** Inline CSS + JS only; images as data-URIs; zero external references
  (CSP-safe).
- **R6 — One label and one color per state, used identically on every page.** The state vocabulary in
  §5 is fixed. A given status uses the same word and the same color wherever it appears — sidebar dot,
  pill, section header, breadcrumb, spotlight, BD page, Grand plan, Archive. No page renames or
  recolors a state.
- **R7 — Every backlog item has its own deep-linkable page.** Active, queued, and archived items each
  mount a page reachable at `#bd-nnn`. All navigation is client-side hash routing; no reloads.
- **R8 — Project-side content is structurally isolated.** Project-scoped content goes in its own
  bordered "Project-side" block, never mixed into or merely tagged within pack-side content.
- **R9 — Pages are separate views that may cross-reference.** Each page is an independent view;
  deep-links between pages are expected.
- **R10 — Theme-aware.** The page renders correctly in both light and dark. Honor the viewer's system
  preference (`prefers-color-scheme`) and an explicit root override (a `data-theme="light|dark"`
  attribute wins over system). Both themes use the same palette tokens (§4); only the token values
  differ.
- **R11 — Presence-driven rendering (full / degraded / removed).** Every page, section, and single
  field independently renders in one of three states, chosen at generation time by what the current
  project actually yields:
  - **Full** — the backing content is available → render the complete treatment described.
  - **Degraded** — the content is light or partial → render exactly what exists; never fabricate the
    missing parts.
  - **Removed** — no backing content right now → omit that surface for this render. Removal is
    **temporary and state-driven**: the surface returns automatically the next time content exists.
    Never bake "this does not exist" into the spec, and never assert a fixed structure is empty — the
    spec is written for any state of the project.
  The only *permanent* omissions are surfaces whose very rendering would break an invariant (for
  example, a persisted, timestamped cross-session registry breaks R2 + R4); those are out **by
  principle**, independent of what content is present. Everything else is presence-driven.

---

## 2. How to generate (the build recipe)

Run this whole sequence on every invocation:

1. **Collect state.** Read the committed sources and take the live git read (see §3), and assemble a
   single state object matching the state → source map in §3. The live git read is what pulls in
   uncommitted work.
2. **Emit one self-contained HTML file.** Structure:
   - `<head>`: title, viewport, and **inline CSS** implementing the palette in both themes (§4), the
     layout constants (§4), and the component styles (pills, cards, rows, tracks, step boxes, bars).
   - `<body>`: the shell — a sidebar (`aside`) with the brand + three nav groups, and a single `main`
     container into which all views mount.
   - Inline `<script>`: the **embedded state object**, the per-view render functions, and the hash
     router. All views read only from the embedded state object. No external `<script>`/`<link>`/
     font/image references.
3. **Stay deterministic.** Serialize the state with sorted keys; emit no timestamps and no random
   values (R4). Embed the payload as `<script type="application/json" id="state">…</script>` and read
   it with `JSON.parse(el.textContent)`; escape `<`, `>`, `&` so it cannot break out of the element.
   (If you instead inline `var STATE = {…}` in a plain script, also escape U+2028 and U+2029 — they
   terminate JS string/JSON literals.)
4. **Publish fresh, persist nothing.** Output the file (or publish it as an artifact) as the
   deliverable for this invocation. Do not cache it or a prior state between runs (R2).

The result need not be byte-identical across runs or to any prior build — only faithful to this spec
and to the current project state.

---

## 3. Data sources (satisfies R2–R5)

State is assembled from two tiers. Sources are named by **what they are**, not by a fixed path, so the
session finds them in the current project. Some are canonical structured surfaces that reliably exist
(the session-state snapshot, the backlog tree, the changelog tree, `README.md`, `CLAUDE.md`,
`PACK-AGENTS.md`); others are **ad-hoc work products** that exist only while work is in flight — most
importantly the current plan for in-scope work, which is typically a **planner agent's planning
document** placed wherever that session put it, not a standardized plan-file directory. Locate each by
its nature; when a source yields nothing at this time, the surfaces it feeds go to their degraded or
removed state per R11 — the spec never assumes a given source is populated.

- **Committed / canonical:** `pack-ops/session-state.json` (current schema `pack-session-state/1`;
  read whatever fields the live snapshot carries), the `/backlog/` tree, the `/changelog/` tree,
  `README.md` version table, `CLAUDE.md` § Pack memory, `PACK-AGENTS.md`.
- **In-flight work products:** the current plan for active work — a planner agent's planning doc, plan
  detail carried in the in-scope backlog entry, or session notes — found by content, not path.
- **Live git read (the `inflight` block):** `git status` + `git worktree list` at build time, yielding
  `dirty` (uncommitted work in the current tree), changed `files[]`, `worktrees[]`, and
  `boundaryFresh` (see the freshness rule below). **Worktree filter:** include only linked worktrees
  on the current branch that belong to this work; exclude the primary checkout and any other-branch
  checkout, and count a worktree as active only when it is itself dirty.

**Boundary freshness (ancestor-within-N).** `boundary_commit` records the last work commit; the
session-state bookkeeping commit that updates it is normally one ahead, so a clean idle repo has
`boundary_commit == HEAD~1`. Compute `boundaryFresh = true` when `boundary_commit` is `HEAD` **or** an
ancestor of `HEAD` reachable within N trailing commits that touch only bookkeeping paths
(`pack-ops/session-state.json` and other session-state-only files); otherwise `false`. Default N is a
small bound (1–2). When the git read is unavailable, `boundaryFresh` is undefined and the freshness
chip is omitted.

**Per-active cursor is optional (presence-driven).** The "current wave / step / status" for an active
item is a cursor: `{bd, wave?, step?, status?}` per active BD, sourced from the session-state snapshot
or the in-scope planning doc — wherever the current state records it. When present, the
cursor-authoritative surfaces render **full**. When it is light (say, only a wave), they render
**degraded** with what exists. When absent, they are **removed**: active BDs render id-only,
`youAreHere.current` falls back to the first not-yet-landed step, and `current.inProgress` is driven
solely by the dirty-tree read.

### State → source map

| State field | Feeds | Source |
|---|---|---|
| `version`, `qualifier`, `date` | brand, Landing, Metrics | README version table |
| `counts{open,resolved,total}` | Landing strip | backlog tally |
| `boundary_commit` | Landing, session band | session-state.json |
| `active[]` | in-flight surfaces | session-state.json |
| `active_cursors[]` *(optional)* | cursor surfaces | per-active cursor from the snapshot or in-scope planning doc, when recorded (R11) |
| `in_flight_agents[]` | Frontier "Running agents" | session-state.json |
| `queue[]`, `parallelization`, `wave`, `cycle_position`, `pending_decisions[]` | Frontier, sidebar, Grand plan | session-state.json |
| `motion[]` *(derived, not stored)* | Frontier, sidebar | computed = `active[]` ++ (`queue[]` minus `active[]`) |
| `inflight{}` | live "editing now" signals | **live git read (uncommitted)** |
| `bds{}` | every BD page, Archive, spotlights | `/backlog/` tree (`BD-NNN.md`) |
| `plans{}` *(optional)* | deep BD pages, Grand plan | the current plan for in-scope work (planner doc / backlog detail) — see note |
| `help{}` | Help & commands | `pack-help.sh` + command set |
| `methodology{}` | Methodology, BD pipeline spine | `CLAUDE.md` pipeline rules |
| `rules[]` | Pack rules, Methodology | `CLAUDE.md` § Pack memory |
| `agents[]` | Methodology roster | `PACK-AGENTS.md` § Pack agents |
| `changelog[]` | Recently landed | `/changelog/` tree (one file per major version) |
| `deps[]` | Dependencies | backlog `Blockers:` lines |
| `metrics{}` | Metrics | backlog tally + per-version |
| `rulings[]` *(optional)* | Rulings | design decisions in the in-scope plan (`decisions[]`) / dedicated ruling notes — NOT `pending_decisions` (§7.10) |
| `repo{branch}` | Metrics repo-context | current repo |

**Backlog Status → status token.** Map each backlog `Status:` value (the canonical set is defined in
`backlog/_rules.md`) to the §5.1 tokens: `Open → pending`, `Unblocked → unblocked`,
`Deferred → deferred`, `Resolved → done`, `Deprecated → deprecated`, `Cancelled → cancelled`. `active`
is not a backlog status — it is derived from `active[]` membership (§5.1). Extend the map the same way
only if the canonical vocabulary grows. `active` is not a backlog status — it is derived from membership in
`active[]`. `blocker`/Blocked is not a backlog status either; it arises only from a blocked plan step
(§5.2), so it appears only when a plan carrying such a step is present (R11).

**Populating `plans{}` (presence-driven).** `plans{}` drives the deep BD page, the Grand-plan
"Planned" cards, the pipeline "you are here", and the progress bars. Build one record per in-scope BD
by reading the **current plan for that work wherever it lives** — most often a planner agent's
planning doc for the active item, else plan detail in the item's backlog entry or session notes
(§3) — and mapping it into the shape below. Per R11: a BD with a full plan renders **full** (deep
depth); a BD with partial plan material renders **degraded** (only the waves/steps that exist); a BD
with no plan right now renders **removed** from the deep treatment — its page falls back to summary
depth (§7.4) and the Grand plan lists it under **"Awaiting planning"** (§7.3). None of this is
baked — every plan-driven feature lights up the moment plan material is found, and goes dark again
when it isn't.

**Recognizing the plan doc.** Treat a document as BD-NNN's plan only when it is unambiguously
identifiable, by either path:
- **(1) Explicit pointer — dormant today.** An optional plan-doc reference the snapshot or session
  records for that BD (e.g. a `plan_ref` field); when present it wins. `pack-session-state/1` carries
  no such field, so path (1) is **dormant** and activates only if that optional field is added —
  until then recognition always uses path (2). (Presence-driven, so the dormancy breaks nothing.)
- **(2) Marker match — the operative path.** The doc identifies itself as that BD's plan (its
  title/heading names the BD and says *plan* / *implementation plan*) **and** carries wave/step
  structure mappable to the shape below.
Use the single most-current match (an explicit `current`/latest marker, or the doc a pointer names).
If candidates conflict or none is clearly identifiable, the BD has no plan → summary depth (R11).
Recognition is deterministic: the same inputs always resolve to the same doc-or-none.

```
plans["BD-NNN"] = {
  sizeTier: "large" | "small",
  progress: { done, total },
  waves: [ { id, title, sub?, scope?, current?,
             steps: [ { tag, title, detail?, scope, ps?, gate?,
                        state: "done"|"pending"|"blocked"|"dropped",
                        dropped?: bool, deferral?, evidence?: { sha, verify } } ] } ],
  gaps: [ { id, title, detail, severity } ],
  decisions: [ { text } ],
  next: "…",
  youAreHere: { current: { wave, step, inProgress? }, wave, note }
}
```

`youAreHere.current` is cursor-authoritative when a cursor exists (§3), else the first not-yet-landed
step; `current.inProgress` is set only when the live git read reports the tree dirty on that step. A
step authored `dropped: true` has state `dropped`: excluded from progress totals and from "next", and
rendered struck-through.

**Field provenance.** Every authored field above — `sizeTier`, `scope`, `ps` (point-size), `gate`,
`deferral`, `evidence.sha` / `verify`, and the wave/step text — is read straight from the recognized
plan doc's records; a field the doc does not carry is simply absent and its chip omitted
(presence-driven, R11), never invented. Execution figures come from the plan's own recorded evidence
(a step's `done` state and its `evidence.sha`), so the BD masthead's **Commits landed** / **Reviews
clean** tiles (§7.4) degrade to 0 or omit when the plan holds no execution evidence yet.

---

## 4. Design system (satisfies R5, R10)

### 4.1 Layout constants

- Sidebar: fixed **248px**, sticky, full height, own scroll.
- Main content: **max-width ~900px**, generous responsive padding.
- Mobile breakpoint **≤760px**: sidebar becomes an off-canvas drawer toggled by a `☰  Menu` button;
  grid collapses to one column.
- Wide content (tracks, tables) scrolls inside its own container; the page body never scrolls
  horizontally.

### 4.2 Palette tokens (light / dark)

Implement as CSS custom properties; supply both a `prefers-color-scheme: dark` block and
`:root[data-theme="dark"]` / `:root[data-theme="light"]` overrides so the explicit toggle wins.

| Token | Role | Light | Dark |
|---|---|---|---|
| `--bg` | page background | `#f4f6f9` | `#0d1219` |
| `--surface` | cards / panels | `#ffffff` | `#151c26` |
| `--surface-2` | insets | `#eef1f6` | `#1a2230` |
| `--surface-3` | bar track | `#e6eaf1` | `#202a39` |
| `--line` | borders | `#dbe1ea` | `#28323f` |
| `--ink` | primary text | `#172231` | `#e6ecf3` |
| `--ink-mid` | secondary text | `#546072` | `#9aa5b4` |
| `--ink-faint` | faint text / neutral state | `#8b95a4` | `#6b7583` |
| `--accent` / `--accent-ink` / `--accent-soft` | teal operational accent (chips, links, version) | `#0e7488` / `#0a5768` / `#dceef1` | `#3cbdcf` / `#8fdbe7` / `#123039` |
| `--done` / `--done-soft` | Resolved (green) | `#1f9558` / `#e0f0e6` | `#43c489` / `#123026` |
| `--active` / `--active-soft` | Active (amber) | `#b26f0c` / `#f7ebd7` | `#e2a83f` / `#33270f` |
| `--pending` / `--pending-soft` | Open (grey) | `#96a0af` / `#edf0f4` | `#6b7583` / `#1c2431` |
| `--blocker` / `--blocker-soft` | Blocked (red) | `#c0473c` / `#f7e3e0` | `#e5786c` / `#331d1a` |
| `--gate` / `--gate-soft` | gate / project-only (purple) | `#6a51c0` / `#ebe6f8` | `#a08ee6` / `#241d3a` |

A pill is its `--x-soft` background with its `--x` text. The three neutral states (Deferred /
Deprecated / Cancelled) use `--ink-faint` text on `--pending-soft` — visibly distinct from grey Open,
which uses `--ink-mid` text. **Unblocked** also sits on `--pending-soft`, but it is an open-ish state,
not a neutral one: render it in Open's family (`--pending` / `--ink-mid` text), never the faint neutral
text — the shared background is the *only* thing it has in common with the trio.

---

## 5. State-tag standard (enforces R6)

Five tag families. Each is distinct; within each, the label and color are fixed and used identically
on every page. **These are the only permitted values — never invent a new one.**

### 5.1 BD status — the primary state tag

Each status uses exactly this label and color, everywhere it appears (sidebar dot, pill, Archive
section header, BD breadcrumb, spotlight, Grand plan, Frontier row):

| Status value | Label | Color token |
|---|---|---|
| `done` | **Resolved** | `--done` (green) |
| `active` | **Active** | `--active` (amber) |
| `pending` | **Open** | `--pending` (grey) |
| `unblocked` | **Unblocked** | `--pending` (grey — a pending-decision state between Open and Deferred; shares Open's family, distinct label) |
| `blocker` | **Blocked** | `--blocker` (red) |
| `deferred` | **Deferred** | neutral (`--ink-faint`) |
| `deprecated` | **Deprecated** | neutral (`--ink-faint`) |
| `cancelled` | **Cancelled** | neutral (`--ink-faint`) |

Source mapping (§3): backlog `Status:` values map to `done` / `pending` / `unblocked` / `deferred` /
`deprecated` / `cancelled` (full table in §3). `active` is derived from `active[]` membership, not a
backlog status; `blocker`/Blocked comes only from a blocked plan step (§5.2), so it appears only when
a plan carrying such a step is present (R11).

### 5.2 Plan step-state boxes

Steps render as glyph boxes, not clickable controls:

- `done` — green ✓
- `dropped` — grey ✕, text struck-through
- `blocked` — amber ring
- `in-progress` — amber ring with ●, shown only when the live git read reports the cursor's current
  step dirty
- default / not-started — empty outline

Box precedence when a step matches more than one: **done > dropped > blocked > in-progress >
default.** A "you are here" marker rides as a separate chip and never overrides the box state.

### 5.3 Scope pills

- `pack-only` — teal (`--accent`)
- `project-only` — purple (`--gate`)
- `pack-chat-only` — grey (`--pending`)

Scope color is in addition to the structural Project-side isolation block required by R8.

### 5.4 Session-cursor status enum

The per-active cursor status maps into the **same color families** as 5.1, so a cursor status never
reads as a different color than the equivalent BD status:

- `designing`, `planning`, `coding`, `review` — amber (work in flight)
- `blocked` — red
- `idle` — grey

Rendered only when a per-active cursor is present in the current state (§3); when absent, these
surfaces are removed for this render (R11) and return when a cursor is recorded again.

### 5.5 Utility chips

- version / evidence-SHA / point-size / "deep" marker — teal (`--accent`)
- gate (a review or approval gate) — purple (`--gate`)
- "you are here" (active BD / current step) — amber (`--active`)
- boundary freshness — green **✓ fresh** when `boundaryFresh` is true (boundary is `HEAD` or an
  ancestor within N trailing bookkeeping commits, §3); grey **↺ behind** when false; nothing when the
  live read is unavailable
- live-dot (uncommitted work indicator) — amber (`--active`)

### 5.6 Other fixed value sets

- `parallelization`: `serial` | `parallel` | `interleaved`
- `sizeTier`: `large` | `small`
- These, the statuses (5.1), step states (5.2), scopes (5.3), and cursor statuses (5.4) are the
  complete controlled vocabularies. Nothing outside them is rendered as a state.

---

## 6. Global chrome & navigation (satisfies R7, R9)

Single-page hash router. All views render into a single main container; navigation shows exactly one
view (toggling `hidden`) and marks the matching sidebar item active. No reloads.

**Sidebar** (sticky, full-height; collapses to an off-canvas drawer at ≤760px):

- **Brand** — `◆ Pack frontier` and a version line `<version> · <qualifier>`.
- **Frontier group** — Landing · Frontier · Grand plan.
- **Work items group** — generated from `motion[]` (active-first) or `queue[]`: each BD id, an
  optional "you are here" marker on the active item, and a status **dot** colored per §5.1.
- **Reference group** — Archive (All BDs) · Methodology · Pack rules · Dependencies · Recently
  landed · Rulings · Metrics · Help & commands. (A nav item whose page is in the **removed** state for
  this render, per R11, is omitted from the group.)

**Movement mechanics:**

- Hash grammar `#<route>` or `#<route>/<anchor>`: the first segment selects the view; the second
  scrolls to an element id within it. An unknown route falls back to Landing.
- Cards (Landing) and rows (Frontier, Archive, Grand plan) are deep-links carrying both a link target
  and an `href="#route"`.
- Every BD id resolves to `#bd-nnn` (lowercased); all items mount a page.
- Rule entries carry stable anchor ids, deep-linkable as `#rules/<anchor>`; the anchor is the rule's
  `[rationale: <slug>]` value (§7.7). Used by Methodology and the Pack-rules inline links.
- **Breadcrumb referrer:** a BD page opens with `Frontier › BD-NNN · <status>`; the leading word
  becomes `Archive` when the page was reached from the Archive view.
- **Mobile:** a `☰  Menu` button toggles the sidebar drawer.

---

## 7. Per-page specifications (satisfies R9 — each page separate)

### 7.1 Landing — `#landing`
Eyebrow "Optiquity AI Agent Config Pack", H1 **Landing**, lede.
- **Status strip** (four tiles): Version · Open items (`open of total`) · Resolved (`resolved` + %) ·
  Boundary (short-SHA).
- **Card grid** linking to Frontier, Grand plan, Archive, Methodology, Pack rules, Help & commands,
  Metrics.
- **"Where we are now"** → the Live session-state band (§7.2) + an **"In flight now"** active-BD
  spotlight (each active BD, its cursor wave/step, and an `editing now` / `idle` tag from the live
  read) + a **"Recently resolved"** spotlight (top five, ordered by each entry's committed `Resolved:`
  date when present, else descending id — committed data, not a wall-clock, per R4).
- Disclaimer: never a source of truth; snapshot at boundary `<sha>`; republished on change.

### 7.2 Frontier — `#frontier`
Eyebrow "In motion · N", H1 **Frontier**. The merged running-window + in-flight view.
- **Live session-state band** — key/value: Active BDs (each links to `#bd-nnn`, with cursor
  wave / step / status pill), Running agents (`N running` or none), Cycle position, Parallelization,
  Boundary commit (`boundary_commit`, with the `✓ fresh` / `↺ behind` chip per §3). Heading shows
  `editing now` when the tree is dirty.
- **Running window** — numbered rows from `motion[]` (active-first): index, id + title, "you are
  here" on the active item, cursor wave/step, an `in progress` badge on the dirty active row, a note
  line, and a status pill.
- **In-flight worktrees** panel (shown only when in-scope linked worktrees exist or the tree is
  dirty): `N active` / `N linked` counts, a main-tree clean/dirty line, and one row per **in-scope**
  linked worktree (current-branch, this work; the primary and other-branch checkouts are excluded per
  §3) marked `active`/`idle` (only a dirty worktree counts as active).
- **Running agents** panel — always shown; lists `in_flight_agents[]` with a role chip parsed from
  each name's leading token; empty → "No agents running."
- **Decisions & directives** panel — the live `pending_decisions[]` from the snapshot: the session's
  standing directives (already-decided constraints) and any genuinely open decisions alike. This is
  operational session state and lives **only here** — distinct from the design **Rulings** page
  (§7.10), which carries design rationale. (The underlying field is named `pending_decisions`, but its
  contents may be settled directives, so the panel is titled by content, not by the field name.)
- Disclaimer: mirrors `pack-ops/session-state.json`.

### 7.3 Grand plan — `#grand-plan`
Eyebrow "Everything in play · `<mode>`", H1 **Grand plan**. The running window as one view.
- **Sequencing** panel — the parallelization mode (`serial` / `parallel` / `interleaved`) with an
  explanatory note.
- **"Planned" (count)** — one rich card per BD that has a plan block: a deep-linked header (id +
  title + "you are here" + size-tier + current wave·step + status pill), a mini progress bar
  (`done / total · %`), then waves → steps. Each step shows its box glyph, tag + title, a "you are
  here" marker on the cursor's current step, and a right-aligned chip cluster (evidence-SHA / scope /
  point-size / gate). BD and wave headers deep-link to `#bd-nnn`.
- **"Awaiting planning" (count)** — compact rows for in-window BDs with no plan block yet.
- Disclaimer: reflects the snapshot; the full index lives on the Archive.

### 7.4 Per-BD page — `#bd-nnn` (one per backlog item)
Opens with the breadcrumb `Frontier/Archive › BD-NNN · <status>`, H1 = title, optional dek. Renders at
one of two depths.

**Summary depth** (no plan block): a progress bar if applicable + **Where we are** (key/value:
Type / Target / Blockers / Unblocks) + **What's next** + **Decisions on record** (`pending_decisions[]`
touching this BD — a BD-scoped context view, not the global Frontier panel).

**Deep depth** (whenever a `plans{}` record with waves is present for this BD; §3, R11) — eight
sections:
1. **Masthead** — title, dek, progress bar (`done / total steps landed (%)`), and a stat band: Waves
   (`done of total`) · Commits landed · Reviews clean · Current wave (cursor-authoritative, with
   `in progress` when dirty). **Commits landed** = steps bearing an `evidence.sha`; **Reviews clean** =
   `done` steps that carry a `gate` (a landed step's gate is cleared by definition — the `plans{}` step
   shape has no separate gate-state flag, so `done` + `gate` present *is* the cleared signal) — both
   derived from evidence in the plan, presence-driven (§3): they read 0, or the tile is omitted, when
   the plan carries no execution evidence yet. **Waves (`done of total`)**: `total` counts every wave;
   a wave is **done** when it has at least one non-dropped step and *all* its non-dropped steps are
   `done` (an all-dropped wave never counts as done, though it still counts in `total`). `wave.current`
   is only the current-wave marker — never a completion signal.
2. **Where we are** — the current wave and note, Current step (cursor wave/step + `in progress`), Next
   action, Blockers.
3. **Pipeline position** — the methodology spine track with "you are here" pinned to the **final stage
   (coder-waves)**. This is intentional and deterministic, not a cursor readout: a deep page exists
   only because a plan exists, and an authored plan means the design and planning stages are already
   cleared, so the BD sits at the implementation stage by construction. The spine carries more stages
   than the cursor's four statuses (`designing` / `planning` / `coding` / `review`), so it is *not* a
   1:1 cursor→stage map; the live cursor detail lives in the stat band and §2 "Where we are", not on
   this spine.
4. **Open vs closed** — two columns (Closed ✓ / Open).
5. **Waves & commits** — one panel per wave; each step shows box glyph, tag + title, `in progress`,
   detail, evidence (`sha · verify`), deferral note, and scope / point-size / gate chips.
6. **Gaps & blockers** — gaps (title + severity + detail) + a blocked/deferred step summary +
   open-decision count.
7. **Decisions** — the plan's recorded design decisions (✓) plus any `pending_decisions[]` touching
   this BD (BD-scoped).
8. **What's next** — the next step (tag + title + gate + detail), or "All planned steps have landed.
   Next: closeout (resolve + changelog)."

### 7.5 Archive · All BDs — `#archive`
Eyebrow "Permanent index · N items", H1 **Archive · All BDs**.
- A **"Recently resolved"** spotlight (top five) and a **client-side text filter**
  (`Filter by id or title…`) that hides non-matching rows live.
- **Status-grouped sections** in the repo's canonical status order (`backlog/_rules.md` / the
  user-ratified TOC order), with the derived **Active** group first: Active → Open → Unblocked →
  Deferred → Resolved → Deprecated → Cancelled, each with a count (empty groups omitted). Resolved is
  ordered by committed `Resolved:` date when present else descending id (committed data, not a clock;
  §7.1 — coverage is partial where entries lack a machine date, which is expected); other groups by
  descending id. Each row: id + title, a `deep` chip when the BD has a plan block, "you are here" when
  active, a snippet line, and a status pill. Rows deep-link to `#bd-nnn`. Section headers use the §5.1
  labels.

### 7.6 Methodology — `#methodology`
Eyebrow "How work moves", H1 **Methodology**.
- **Large-BD deterministic flow** track (with gate markers) · **Small-BD flow** track · **Size
  signals** checklist.
- **Agent roster** — the five pack agents (name + RW/RO class pill + role + mode): `pack-architect`,
  `pack-planner`, `pack-coder` (RW), `pack-reviewer`, `pack-docs-researcher`.
- **Agent spawning & parallelization** — the sub-agent-behavior rules, each deep-linking to
  `#rules/<anchor>`.

### 7.7 Pack rules — `#rules`
Eyebrow "Standing rules · N", H1 **Pack rules**. A live mirror of `CLAUDE.md` § Pack memory, grouped
by its `###` sub-sections. **Rule parse:** within the `## Pack memory` section, each top-level
`- **Title.**` bullet is one rule (its nested sub-bullets are body, not separate rules); the anchor is
the rule's `[rationale: <slug>]` value (fall back to a slug of the title when absent). A rule's bold
title or its `[rationale]` tag may wrap across source lines — match the whole bullet, not a single
line, or wrapped rules are silently dropped. Each rule is a
panel with that stable anchor id: title + optional `rule N` chip + body. **"Found in"** is a real check
that counts a trinity file only when it **defines** the rule, not when it merely references it: in each
of the three pack-root trinity files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`), require the rule's
`[rationale: <slug>]` to appear on a *rule-defining* `- **Title.**` bullet within that file's
Pack-memory section — a bare slug mention in prose (a cross-reference or pointer) does not count. List
the files that define it, with a `Claude-only` pill when only one does.

### 7.8 Dependencies — `#deps`
Eyebrow "Sequencing", H1 **Dependencies**. Edges come from each BD's prose `Blockers:` line in the
backlog. One panel per needing-BD (`from`): its verb + every prerequisite (`to`). The `why` is the
BD's single `Blockers:` prose line, shown **once** per panel (not repeated per prerequisite). Panels
are grouped by the needing-BD's own status into fixed sections — Open & queued → Deferred → Resolved →
Deprecated & superseded (empty sections omitted) — and deterministically sorted (by `from`, then
`to`). A needing-BD that is `Open`, `Unblocked`, or derived-active all sort into the first section
(**Open & queued**); `Cancelled` joins **Deprecated & superseded**.

### 7.9 Recently landed — `#changelog`
Eyebrow "Newest first", H1 **Recently landed**. The changelog is one file per major version; render one
panel per major-version file, newest first: version + date chip + a ✓ list of that version's items.

### 7.10 Rulings — `#rulings`
Eyebrow "Decisions on record", H1 **Rulings**. Design decisions (the *why* behind the current work) so
they are not re-litigated — sourced by content from the in-scope plan's recorded decisions (a plan's
`decisions[]`) or dedicated ruling notes (§3). **Not** the session's operational `pending_decisions` —
those are live session state shown only on Frontier (§7.2); Rulings never re-surfaces them, so no item
appears on both pages. Grouped by focus (with a Scope · Order line); each ruling: title + optional id +
detail + context + source pills. Presence-driven (R11): **full** when design decisions are recorded,
**degraded** when few or thinly-detailed, **removed** (page and nav item omitted) when none are on
record right now.

### 7.11 Metrics — `#metrics`
Eyebrow "Toward launch", H1 **Metrics**. Three panels: Resolution progress (bar + `resolved / total
(%)`, Open/unblocked, Running window queued) · Closeout shape (prose from counts) · Repo context
(Total items, Running window, Branch).

### 7.12 Help & commands — `#help`
Eyebrow "Pack-side commands", H1 **Help & commands**. Overview lede + a **"What the pack does"** ✓
feature list + pack commands grouped by source section (rows of name + description). Project-side
commands go in the isolated bordered **"Project-side — not pack commands"** block, per R8.
