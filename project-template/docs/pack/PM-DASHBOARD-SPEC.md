# Project Frontier Dashboard — Build Specification

Instructions for generating the client project dashboard fresh, from live project state, on
every request. Produce a single HTML page each time. This document is the LOGIC contract the
committed client renderer scripts/pm-dashboard-render.py executes (`build` mode);
`/pm-dashboard` invokes it. State is collected fresh and never cached between builds. This
board COEXISTS with `docs/project/STATUS.md` — the markdown snapshot stays; the HTML board is
an additional, richer view.

This is the client's OWN copy of the render contract. It mirrors the pack's dashboard behavior
but is a separate, customized surface: the entries are project TD items and phases, the source
paths are project paths, and nothing here depends on or imports a pack-side file.

---

## 0. What to build

A **single self-contained HTML page** — inline CSS + JS, data-URI images only, no external
network calls — presenting a live, at-a-glance mirror of project work: what is in motion,
everything in play, and each TD item's pipeline. Page title: **"Project frontier —
dashboard."** Brand mark: **◆ Project frontier**.

---

## 1. Global requirements — every page and section must respect these

Invariants. They govern all pages and outrank any page-specific detail below.

- **R1 — The repo is the source of truth.** The dashboard is a presentational mirror and says
  so. It never claims authority over the data.
- **R2 — Fresh state every build; never stale.** The STATE payload is collected fresh on every
  build and never cached. The page's *data-free* SHELL (spec-derived CSS / JS / structure,
  carrying no project data) MAY be reused across builds as a spec-fingerprinted cache and
  regenerated only when the spec changes — reuse is safe precisely because the shell holds no
  state.
- **R3 — Include committed and uncommitted work.** Assemble state from committed repo files
  **and** a live git working-tree read taken at build time, so in-flight work not yet committed
  still appears. This live read drives every "editing now" / "in progress" / worktree signal.
- **R4 — Deterministic render.** No timestamps, no clock, no randomness. Every signal derives
  from the collected state; identical state produces identical output. When the live git read
  is unavailable, live surfaces fall back to a defined idle form.
- **R5 — Self-contained.** Inline CSS + JS only; images as data-URIs; zero external references
  (CSP-safe).
- **R6 — One label and one color per state, used identically on every page.** The state
  vocabulary in §5 is fixed. A given status uses the same word and color wherever it appears.
- **R7 — Every TD item has its own deep-linkable page.** Active, queued, and archived items
  each mount a page reachable at `#td-nnn`. All navigation is client-side hash routing; no
  reloads.
- **R8 — Pack-side content is structurally isolated.** Any pack-self reference goes in its own
  bordered block, never mixed into project content.
- **R9 — Pages are separate views that may cross-reference.** Each page is an independent view;
  deep-links between pages are expected.
- **R10 — Theme-aware.** The page renders correctly in both light and dark. Honor the viewer's
  `prefers-color-scheme` and an explicit `data-theme="light|dark"` root override (the explicit
  toggle wins). Both themes use the same palette tokens (§4); only values differ.
- **R11 — Presence-driven rendering (full / degraded / removed).** Every page, section, and
  field independently renders in one of three states, chosen at generation time by what the
  current project actually yields:
  - **Full** — the backing content is available → render the complete treatment.
  - **Degraded** — the content is light or partial → render exactly what exists; never
    fabricate the missing parts.
  - **Removed** — no backing content right now → omit that surface for this render. Removal is
    temporary and state-driven: the surface returns automatically the next time content exists.

---

## 2. How to generate (the build recipe)

The renderer runs this whole sequence on every `build`:

1. **Collect state.** Read the committed sources and take the live git read (§3), and assemble
   a single state object matching the §3 state → source map. The live git read pulls in
   uncommitted work.
2. **Emit one self-contained HTML file.** Structure: `<head>` with title, viewport, and inline
   CSS (both themes + layout constants + component styles); `<body>` shell — a sidebar (`aside`)
   with the brand + three nav groups, and a single `main` container into which all views mount;
   inline `<script>` with the embedded state object, the per-view render functions, and the
   hash router. All views read only from the embedded state object. No external references.
3. **Stay deterministic.** Serialize the state with sorted keys; emit no timestamps and no
   random values (R4).

   **Targeted state injection.** Inject the serialized state ONLY into the state element — a
   single-count replace of the `<script id="state">…</script>` content. The shell carries the
   `__PM_DASHBOARD_STATE__` sentinel in TWO places (the inert state element AND the router's
   defensive boot-guard); a global token-replace clobbers the guard and blanks the board. After
   injection the produced page MUST still carry the sentinel exactly once (in the JS guard) and
   NOT in the state element.

   **ASCII-safe output.** Emit pure-ASCII HTML: serialize JSON with `ensure_ascii` and write
   static glyphs as HTML numeric entities. The produced page carries zero bytes outside
   `0x09,0x0A,0x0D,0x20–0x7E`.
4. **Write the board, atomically.** The renderer writes the state-injected page to
   `docs/project/dashboard-approvals/dashboard.html` — rendered into a temp path, `verify`'d,
   and renamed into place ONLY on a PASS (a shortfall deletes the temp and exits non-zero,
   leaving no board on disk). Do not cache the state or a prior render between builds (R2 — the
   data-free shell MAY be reused). When the build reuses a spec-fingerprinted shell, its
   provenance line is pinned to line 2 (immediately after `<!DOCTYPE html>`) with shape
   `<!-- pm-dashboard shell · spec: <path> · spec-sha: <40-hex> -->`; the `spec:` field is the
   caller-named spec doc path, never hardcoded.

**Provenance — shell fingerprint.** The renderer authors the shell
(`docs/project/dashboard-approvals/dashboard-shell.html`) from its committed CSS/JS constants
and stamps the provenance line with `spec-sha` = `git hash-object` of THIS spec (the LOGIC
contract). A spec change flips the fingerprint and regenerates the shell; a matching fingerprint
reuses it byte-unchanged.

**Status vocabulary shape.** The render reads the canonical Status set from the live
`docs/project/backlog/_rules.md` `## Lifecycle states admitted` section, parsing ONLY the
`` - `X` — <gloss> `` bullet shape (dash + single backticked word + em-dash), section-scoped; a
new canonical status the tier-map cannot place is a fail-closed condition — the renderer's
`verify` fail-closes rather than render an unmapped status.

---

## 3. Data sources

State is assembled from the live project tree. Sources are named by what they are; locate each
by its nature; when a source yields nothing, the surfaces it feeds go to their degraded or
removed state per R11.

### State → source map

| State field | Feeds | Source |
|---|---|---|
| `version`, `qualifier`, `date` | brand, Landing, Metrics | `README.md` version table (when present) |
| `counts{open,resolved,total}` | Landing strip | TD backlog tally |
| `boundary_commit` | Landing, session band | `docs/project/pm-session-state.json` |
| `active[]` | in-flight surfaces | `docs/project/pm-session-state.json` |
| `in_flight_agents[]` | Frontier "Running agents" | `docs/project/pm-session-state.json` |
| `queue[]`, `parallelization`, `wave`, `cycle_position`, `pending_decisions[]` | Frontier, sidebar, Grand plan | `docs/project/pm-session-state.json` |
| `motion[]` *(derived, not stored)* | Frontier, sidebar | computed = `active[]` ++ (`queue[]` minus `active[]`) |
| `inflight{}` | live "editing now" signals | **live git read (uncommitted)** |
| `tds{}` | every TD page, Archive, spotlights | `docs/project/backlog/` tree (`TD-NNN.md`) |
| `plans{}` *(optional)* | deep TD pages, Grand plan | committed `git log` feat/fix landings per TD |
| `help{}` | Help & commands | `docs/pack/HELP-FRAGMENT.md` verb tables |
| `rules[]` | Project rules, Methodology | `CLAUDE.md` § Project rules |
| `agents[]` | Methodology roster | `docs/pack/PM-CHAT.md` profile-assignment table |
| `changelog[]` | Recently landed | `docs/project/changelog/` tree (one file per event, `YYYY-MM-DD-<slug>.md`) |
| `metrics{}` | Metrics | TD backlog tally |
| `repo{branch}` | Metrics repo-context | current repo — worktree-isolation branch names sanitized |

**Backlog Status → status token.** Map each TD `Status:` value (the canonical set is defined in
`docs/project/backlog/_rules.md`) to the §5 tokens: `Open → pending`, `Unblocked → unblocked`,
`Deferred → deferred`, `Resolved → done`, `Deprecated → deprecated`, `Cancelled → cancelled`.
The resolution date for a `Resolved` TD is read from its `Resolution:` line (`YYYY-MM-DD` when
present, else empty). `active` is derived from `active[]` membership, not a backlog status.

**Counts vs. the Active overlay.** Every display bucket derives from the backlog `Status:`
TOKENS, never re-bucketed by the derived-`active` overlay: a TD that is derived-active but still
`Status: Open` is counted under **Open**. The `active` grouping/pill is a presentation overlay,
not a separate count bucket — it never double-counts.

### Payload thinning — the deep-detail set

`tds{}` is **presence-tiered** so the embedded state stays small without dropping any item —
every backlog item is represented; only DETAIL DEPTH varies.

- **Full / deep set** `E_full` = **(every TD not yet `Resolved`, except the terminal-dead states
  `Deprecated` / `Cancelled`)** ∪ **(the 10 most-recently-`Resolved` TDs — selected
  `Resolution:`-date descending, then id descending)**. These carry a **full** record (every
  field the deep page needs, plus a source-anchored body) and a full `plans{}` record.
- **Minimal set** = everything else. A minimal record is `id`, `num`, `title`, `status`, short
  `snippet` / `Type` / `Target` / `Blockers` / `Unblocks`, plus `resolved_date` on `Resolved`
  records (the committed `Resolution:` date, or empty) — the sort key the §7 recency ordering
  reads. Bound minimal-field WIDTH (`snippet` ≤ ~160 chars; each meta field to its first line).

**Per-record `tier` field (named).** Every `tds{}` record carries a `tier` field with value
`"full"` or `"minimal"` — the single authoritative discriminator the render and the renderer's
`verify` read; it is not inferred from field-presence heuristics.

**Conformance floor (deterministic — HARD-FAIL).** The full set is DETERMINISTIC: the render
MUST carry exactly `|E_full|` records with `tier:"full"`, each with a source-anchored body (≥40
normalized chars, not a title/snippet echo, sharing content with the live `TD-NNN.md`
Description/Context). A shortfall means deterministic work was skipped: the renderer's `verify`
HARD-FAILS and the board is regenerated, never published short.

### Recency ordering (MANDATORY — inherited)

The two Resolved surfaces (Landing "Recently resolved" + the Archive Resolved group) sort by
`resolved_date` **descending**, then id descending — NEVER pure id/num-sort. The renderer emits
`resolved_date` on every `Resolved` record (the datum), and `verify` floors both the datum (a
dropped/mismatched `resolved_date` bites) and the comparator (a render-token smoke asserts the
date-descending comparator appears on both resolved surfaces). This ordering is a mandatory
inheritance — a resolved item must never be buried below an older one.

### The complete DATA floor (what `verify` covers)

`verify` re-derives the expected board INDEPENDENTLY from the live tree (re-reading disk), parses
the produced `dashboard.html` `#state`, and asserts: the session layer (each presence-conditional
field), every backed section (`tds{}` total-accountability + `tier:"full"` source-anchored bodies
+ `resolved_date` on every Resolved record, `plans{}`, `rules[]`, `changelog[]`, `agents[]`,
`metrics{}`, `help{}`, and `inflight{}` structure, plus the README-version-table-backed
`version`/`qualifier`/`date` floor when present), the parse/encoding invariants (targeted state
injection + ASCII-safe output + status-token counts), and the render-token smoke. The build runs
`verify` inline and atomically (temp render → `verify` → `os.replace` only on PASS). `verify` is
SKIP-lenient off a git work tree.

---

## 4. Design system (satisfies R5, R10)

- **Layout.** Sidebar fixed **248px**, sticky, full height, own scroll. Main content max-width
  **~900px**, responsive padding. Mobile breakpoint **≤760px**: sidebar becomes an off-canvas
  drawer toggled by a `☰ Menu` button; grid collapses to one column.
- **Palette tokens (light / dark).** CSS custom properties with a `prefers-color-scheme: dark`
  block and `:root[data-theme="dark"|"light"]` overrides (explicit toggle wins). A pill is its
  `--x-soft` background with its `--x` text.

---

## 5. State-tag standard (enforces R6)

**These are the only permitted values — never invent a new one.**

### 5.1 TD status — the primary state tag

| Status value | Label | Color token |
|---|---|---|
| `done` | **Resolved** | `--done` (green) |
| `active` | **Active** | `--active` (amber) |
| `pending` | **Open** | `--pending` (grey) |
| `unblocked` | **Unblocked** | `--pending` (grey — pending-decision state; shares Open's family, distinct label) |
| `blocker` | **Blocked** | `--blocker` (red) |
| `deferred` | **Deferred** | neutral (`--ink-faint`) |
| `deprecated` | **Deprecated** | neutral (`--ink-faint`) |
| `cancelled` | **Cancelled** | neutral (`--ink-faint`) |

`active` is derived from `active[]` membership, not a backlog status.

### 5.2 Other fixed value sets

- `parallelization`: `serial` | `parallel` | `interleaved` | `none` | `idle`. Often prose
  (`"none — TD-041 in the review gate"`); when not an exact enum member, render the leading
  token as the mode and the remainder as an inline note. Never render a raw prose blob as the
  whole mode.
- `sizeTier`: `large` | `small`.

---

## 6. Global chrome & navigation (satisfies R7, R9)

Single-page hash router. All views render into a single main container; navigation shows exactly
one view and marks the matching sidebar item active. No reloads.

- **Brand** — `◆ Project frontier` and a version line.
- **Frontier group** — Landing · Frontier · Grand plan.
- **Work items group** — generated from `motion[]` (active-first): each TD id, an optional "you
  are here" marker on the active item, and a status **dot** colored per §5.1.
- **Reference group** — Archive (All TDs) · Methodology · Project rules · Dependencies · Recently
  landed · Metrics · Help & commands.
- Hash grammar `#<route>` or `#<route>/<anchor>`; an unknown route falls back to Landing. Every
  TD id resolves to `#td-nnn` (lowercased).

---

## 7. Per-page specifications

- **Landing (`#landing`)** — status strip (Version · Open items · Resolved · Boundary), a card
  grid, the live session-state band, an "In flight now" active-TD spotlight, and a "Recently
  resolved" spotlight (top five, ordered by committed `Resolution:` date, else descending id).
- **Frontier (`#frontier`)** — live session-state band, running window from `motion[]`, in-flight
  worktrees panel, running-agents panel (prose-tolerant), and a Decisions & directives panel.
- **Grand plan (`#grand-plan`)** — sequencing mode + Planned cards (with progress + landed
  evidence) + Awaiting-planning rows.
- **Per-TD page (`#td-nnn`)** — breadcrumb, masthead, where-we-are, waves & commits (from the
  committed landing evidence), and decisions on record. Summary depth when no plan block exists.
- **Archive (`#archive`)** — a Recently-resolved spotlight, a client-side text filter, and
  status-grouped sections (Active → Open → Unblocked → Deferred → Resolved → Deprecated →
  Cancelled), Resolved ordered by `Resolution:` date then descending id.
- **Methodology (`#methodology`)** — the flow tracks + the agent roster (from
  `docs/pack/PM-CHAT.md`).
- **Project rules (`#rules`)** — a live mirror of `CLAUDE.md` § Project rules.
- **Dependencies (`#deps`)** — best-effort edges from each TD's `Blockers:` prose.
- **Recently landed (`#changelog`)** — one panel per changelog entry, newest first.
- **Metrics (`#metrics`)** — resolution progress, repo context (branch sanitized).
- **Help & commands (`#help`)** — project commands from `docs/pack/HELP-FRAGMENT.md`; any
  pack-self reference lives in its own isolated block (R8).

---

## 8. The approvals directory contract (the render output home)

The renderer writes into `docs/project/dashboard-approvals/`. This directory **does not exist
until a board first renders** — it is created by the renderer on the first `build`, not shipped
in the template. When a real project board is built, the directory carries three files, committed
together on the first render:

- `dashboard-shell.html` — the data-free, spec-fingerprinted shell (reused byte-unchanged while
  the spec-sha matches; regenerated on a spec change).
- `dashboard.html` — the state-injected board (rewritten every render).
- `dashboard-url.txt` — the published claude.ai Artifact URL (one line), written on the first
  publish.

Later renders commit `dashboard.html` always, plus `dashboard-shell.html` only when a spec change
flipped its `spec-sha`; the URL record is unchanged. Because `dashboard.html` is a
frequently-rewritten generated artifact, a project SHOULD mark it non-diffing / non-merging in
`.gitattributes` when the board is first committed — a repository hygiene convenience set up with
the first real board, not before.

---

## 9. Publish & commit

Publishing the board to claude.ai is a **foreground, orchestrator-only** step (a spawn-driven
publish is denied by the auto-mode classifier). On a CLI without the claude.ai publish
capability, the render is the deliverable (opened locally); there is no URL step. Commit the
approvals-dir files under the project's normal commit-approval gate; agents never auto-commit.
