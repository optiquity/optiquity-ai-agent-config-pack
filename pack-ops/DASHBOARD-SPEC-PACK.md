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
- **R2 — Fresh state every build; never stale.** The STATE payload is collected fresh from the current
  project on every build and never cached. The page's *data-free* SHELL (spec-derived CSS / JS /
  structure, carrying no project data) MAY be reused across builds as a spec-fingerprinted cache and
  regenerated only when the spec changes — reuse is safe precisely because the shell holds no state.
  Freshness is a property of the state, not the shell; no state persists between builds.
- **R3 — Include committed and uncommitted work.** Assemble state from committed repo files **and** a
  live git working-tree read taken at build time, so in-flight work that is not yet committed still
  appears. This live read drives every "editing now" / "in progress" / worktree signal.
- **R4 — Deterministic render.** No timestamps, no clock, no randomness. Every signal derives from the
  collected state; identical state produces identical output. When the live git read is unavailable,
  all live surfaces fall back to a defined idle form. **Scoped exception — the best-effort deep tier
  (§3):** deep-detail discovery may read uncommitted / machine-local sources (scratch docs, volatile
  `session-state.json` prose, git history), so the deep tier is explicitly best-effort and MAY vary by
  machine and drift as work progresses. Determinism is guaranteed for the committed-state surfaces; the
  deep tier trades strict R4 for richness, by owner directive (§3).
- **R5 — Self-contained.** Inline CSS + JS only; images as data-URIs; zero external references
  (CSP-safe).
- **R6 — One label and one color per state, used identically on every page.** The state vocabulary in
  §5 is fixed. A given status uses the same word and the same color wherever it appears — sidebar dot,
  pill, section header, breadcrumb, spotlight, BD page, Grand plan, Archive. No page renames or
  recolors a state.
- **R7 — Every backlog item has its own deep-linkable page.** Active, queued, and archived items each
  mount a page reachable at `#bd-nnn`. All navigation is client-side hash routing; no reloads. "Mounts
  a page" guarantees reachability, not up-front construction — a build MAY lazily build each per-BD page
  on first route (and cache it), so a 271-item board need not materialize all 271 pages eagerly (O12).
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
   values (R4). The escape set is **path-dependent** (O9): for the recommended
   `<script type="application/json" id="state">…</script>` + `JSON.parse(el.textContent)` path, only
   `<` (specifically the `</script` sequence, which could close the element early) can break out, so escaping `<` is
   sufficient (escaping `>` / `&` is harmless but not required). Only if you instead inline
   `var STATE = {…}` in a plain executable script must you also escape `&`, `>`, U+2028 and U+2029
   (which terminate JS string/JSON literals). Prefer the JSON-script path.
4. **Publish fresh, persist nothing.** Output the file (or publish it as an artifact) as the
   deliverable for this invocation. Do not cache the state or a prior render between runs (R2 — the
   data-free shell MAY be reused). **If the build reuses a spec-fingerprinted shell (R2), pin the
   provenance/fingerprint comment to a fixed position** — line 2, immediately after `<!DOCTYPE html>` —
   so the reuse check reads it with a stable, cheap regex (O10). Its shape is
   `<!-- <renderer> shell · spec: <path> · spec-sha: <40-hex> -->`; the `spec:` field is the
   **caller-named spec doc path** (the render is generic and is reused for other dashboards with
   different specs), never a hardcoded path (R2-H). Use a **repo-relative** path when the spec lives
   inside the repo and the **verbatim `~`/absolute** path when it is external; an out-of-repo spec
   yields a non-portable provenance line by construction — the `spec-sha` remains the reproducible key
   (OBS-6).

The result need not be byte-identical across runs or to any prior build — only faithful to this spec
and to the current project state.

**Provenance — dual fingerprint.** The sanctioned build script (`scripts/dashboard-build.py`) and the
runtime shell (`pack-ops/dashboard-approvals/dashboard-shell.html`) each carry a provenance line with TWO
fingerprints: `spec-sha` = `git hash-object` of THIS spec (the LOGIC contract), and `structure-sha` = a
sha256 fold of the FORMAT contract (the two per-entry `_rules.md` hashes + the session-state `schema` token
+ the session-state required-keys tuple value). A spec OR format-contract change flips a fingerprint and
forces a reviewed script edit + a shell regenerate (Check 88); the script is committed source, regenerated
only on such a change, reused every render otherwise.

**Status vocabulary shape (oracle input).** The oracle reads the canonical Status set from the live
`backlog/_rules.md` `## Lifecycle states admitted` section, parsing ONLY the `` - `X` — <gloss> `` bullet
shape (dash + single backticked word + em-dash), section-scoped; a new canonical status the tier-map cannot
place is a fail-closed condition.

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
  checkout, and count a worktree as active only when it is itself dirty. **Exclude the render's own
  footprint** (O1): drop `pack-ops/dashboard-approvals/` and any render output/scratch artifacts from
  the read, so a board never reports *itself* as "editing now" and successive renders stay
  deterministic despite the render writing files. The read is a **pre-write snapshot** (G4): it runs
  before the render writes its HTML, so the output file's own dirtying never appears as `dirty` — that
  is correct, not a bug.

**Prose-tolerant session-state consumption (FIX 4 — the umbrella principle).** Pack Chat authors
several `session-state.json` fields as free-text **prose**, not the idealized structured shape:
`in_flight_agents[]` may hold a status note ("none live. NEXT: …"), `parallelization` may hold
`"none — <reason>"`, and `active[]` / `pending_decisions[]` may hold long descriptive strings. Every
field this spec consumes from `session-state.json` MUST define its behavior when the value is
descriptive prose rather than the structured value, via one of: **(a) sentinel detection** — recognize
`none` / `no agents` / negations and render the empty/idle state; **(b) leading-token parsing** — take
the first token as the value, the remainder as an inline note; or **(c) graceful raw display** — show
the prose verbatim, length-bounded (see thinning O4). Each §7 consumer names which it uses; the
default when unspecified is (c). This umbrella governs the Running-agents sentinel (§7.2), the
`parallelization` fallback (§5.6 / §7.3), and the prose-sourced deep-page synthesis — `gaps` /
`youAreHere` / `next` (§7.4).

**Boundary freshness (ancestor-within-N).** `boundary_commit` records the last work commit; the
session-state bookkeeping commit that updates it is normally one ahead, so a clean idle repo has
`boundary_commit == HEAD~1`. Compute `boundaryFresh = true` when `boundary_commit` is `HEAD` **or** an
ancestor of `HEAD` reachable within N trailing commits that touch only bookkeeping paths
(`pack-ops/session-state.json` and other session-state-only files); otherwise `false`. Default N is a
small bound (1–2). When the git read is unavailable, `boundaryFresh` is undefined and the freshness
chip is omitted.

**Per-active cursor is optional (presence-driven).** The "current wave / step / status" for an active
item is a cursor: `{bd, wave?, step?, status?}` per active BD, sourced from the session-state snapshot
or the in-scope planning doc — wherever the current state records it. **When no structured cursor
exists, the prose `session-state.wave` / `cycle_position` MAY drive `youAreHere` and the deep page's
`next`** (interpreted per the prose-tolerance principle above) — this is the blessed source for the
"you are here" and "what's next" surfaces (G2 / G3). When present, the cursor-authoritative surfaces
render **full**. When it is light (say, only a wave), they render **degraded** with what exists. When
absent, they are **removed**: active BDs render id-only, `youAreHere.current` falls back to the first
not-yet-landed step, and `current.inProgress` is driven solely by the dirty-tree read.

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
| `plans{}` *(optional)* | deep BD pages, Grand plan | assembled best-effort from any reachable source, committed or not — see "Discovering the plan" |
| `help{}` | Help & commands | `pack-help.sh` + command set; `features[]` from the README pack-overview section, however titled (O8 / OBS-5) |
| `methodology{}` | Methodology, BD pipeline spine | `CLAUDE.md` pipeline rules |
| `rules[]` | Pack rules, Methodology | `CLAUDE.md` § Pack memory |
| `agents[]` | Methodology roster | `PACK-AGENTS.md` § Pack agents |
| `changelog[]` | Recently landed | `/changelog/` tree (one file per major version) |
| `deps[]` | Dependencies | structured blocked-by field if present, else prose `Blockers:` lines (best-effort — §7.8) |
| `metrics{}` | Metrics | backlog tally + per-version |
| `rulings[]` *(optional)* | Rulings | plan `decisions[]` / a dedicated decisions doc (committed or uncommitted-scratch, §3) — NOT `pending_decisions` (§7.10) |
| `repo{branch}` | Metrics repo-context | current repo — resolved base/upstream branch, worktree-isolation names sanitized (O6) |

**Backlog Status → status token.** Map each backlog `Status:` value (the canonical set is defined in
`backlog/_rules.md`) to the §5.1 tokens: `Open → pending`, `Unblocked → unblocked`,
`Deferred → deferred`, `Resolved → done`, `Deprecated → deprecated`, `Cancelled → cancelled`. Extend
the map the same way only if the canonical vocabulary grows. `active` is not a backlog status — it is
derived from `active[]` membership (§5.1); `blocker`/Blocked is not one either — it arises only from a
blocked plan step (§5.2), so it appears only when a plan carrying such a step is present (R11).

**Counts vs. the Active overlay (O11).** `counts` are computed from backlog `Status:` values, so a BD
that is derived-active but still `Status: Open` is counted under **Open** in the tally; the board's
`active` grouping/pill is a presentation overlay, **not** a separate count bucket — it never
double-counts. State this on the Open/Resolved tiles (§7.1, §7.11) so the overlap isn't misread.

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
(a step's `done` state and its `evidence.sha`), so the BD masthead's **Commits landed** / **Gates
cleared** tiles (§7.4) degrade to 0 or omit when the plan holds no execution evidence yet.

### Payload thinning — the deep-detail set (owner directive)

`bds{}` is **presence-tiered** so the embedded state stays small without dropping any item — every
backlog item is represented; only DETAIL DEPTH varies.

- **Full / deep set** = **(every BD not yet `Resolved`, except the two terminal-dead states
  `Deprecated` / `Cancelled`)** ∪ **(the 10 most-recently-`Resolved` BDs — selected `Resolved:`-date
  descending, then id descending, OBS-8)**. Concretely: all `Open`,
  `Unblocked`, `Deferred`, and derived-`active` BDs, plus the 10 newest `Resolved`. These carry a
  **full** `bds{}` record (every field the §7.4 deep page + spotlights need) **and** a full assembled
  `plans{}` deep record. The set is sized by the rule — typically a few dozen items, not the whole
  tree. *(`Deferred` is included — it is unresolved and revivable; `Deprecated` / `Cancelled` are
  terminal-dead and treated like `Resolved`, per owner decision.)*
- **Minimal set** = everything else — older `Resolved`, plus `Deprecated` / `Cancelled`. A **minimal**
  record is exactly `id`, `num`, `title`, `status`, and short `snippet` / `Type` / `Target` /
  `Blockers` / `Unblocks` — the fields the Archive rows (§7.5) and the summary-depth BD page (§7.4)
  consume. No deep plan, no deep-only fields.
- **Bound the minimal fields (O4).** Minimality caps DEPTH; also cap WIDTH — `snippet` ≤ ~160 chars,
  and each of `Type` / `Target` / `Blockers` / `Unblocks` to its first line / first sentence — so 240+
  minimal records don't re-inflate the payload with uncapped prose.

**Per-record tier field (named).** Every `bds{}` record carries a `tier` field with value `"full"` or
`"minimal"` — `"full"` for a full/deep-set record, `"minimal"` for everything else. `tier` is the single
authoritative discriminator the render, the `verify` oracle, and CI Check 89 read; it is not inferred
from field-presence heuristics. (`tier` — not `depth` — deliberately: `depth` names the §7.4 summary/deep
PAGE depth; `tier` names the full/minimal RECORD tier, matching the "full/minimal record" wording already
used here.)

**Conformance floor (deterministic — HARD-FAIL).** The full set is DETERMINISTIC, not best-effort: the
render MUST carry exactly `|E_full|` records with `tier:"full"`, where `E_full` = (every non-terminal BD)
∪ (the 10 most-recently-`Resolved`, selected `Resolved:`-date descending then id descending — **OBS-8** is
the tie-break selection key for the newest-10 arm). Every `tier:"full"` record MUST carry a source-anchored
body (≥40 normalized chars, not a title/snippet echo, sharing content with the live `backlog/BD-NNN.md`
Description/Context). A shortfall means deterministic work was skipped: `dashboard-build.py verify`
(render-time) AND the mechanical CI floor (Check 89) BOTH HARD-FAIL — the render is regenerated, never
committed short.

Every invariant holds — **R7** (a minimal record still mounts its summary-depth `#bd-nnn` page; never
*removed*), **R2** (every item present; minimal is representation, not omission), **R11** (a BD with no
deep detail renders summary depth, never a fabricated deep page). A BD that re-enters the full set
lights back up to full automatically. Tiering keeps the payload small — full detail only where anyone
reads it, minimal elsewhere — a large token saving with no fidelity loss, without pinning a volatile
byte or count figure.

### Discovering the plan / deep detail (multi-source, best-effort — owner directive)

**Best-effort applies to plan/deep-detail SOURCE discovery ONLY — not to full-set membership or bodies.**
The SWEEP that assembles a full-set BD's deep PLAN structure is best-effort: a plan may live in an
uncommitted or prose source, or not exist yet, in which case that ONE BD summary-degrades (§7.4). What is
NOT best-effort: (a) full-set MEMBERSHIP (the deterministic `E_full` rule above), and (b) each full-set
record's source-anchored BODY (drawn from the BD's own live backlog entry, which always exists). The SWEEP
is mandatory (every in-scope BD is swept); the full-BODY set is deterministic and floored. The
committed-history plans floor (each derived-active / newest-Resolved BD with real `git log --grep=BD-NNN`
landings MUST appear in `plans{}`) keys on committed data only and is likewise HARD-floored; the
richest-doc-wins merge remains best-effort above that floor.

The deep detail for each **full-set** BD is assembled **best-effort from wherever it exists, committed
or not** — because a plan mid-flight often lives in an uncommitted or prose source, and requiring a
committed marker-match blanks the deep page for visibly-active work (the regression this fixes: O3).
**Sweep** these sources for **every** in-scope BD — resolved BDs included, not only the active one
(R3-LEAD / OBS-9):
  1. a **committed** plan/design doc — the backlog entry body, `docs/project/implementation-plan/`,
     `maintenance-docs/`, or an architecture/plan doc (identified per "Recognizing the plan doc" above);
  2. an **uncommitted** plan/design doc — glob **every** per-BD scratch plan / handoff dir across the
     scratch tree for that BD's `PLAN-*.md` / `ARCHITECTURE-*.md` / impl-report / review (e.g.
     `~/Developer/_tmp/pack-handoff-bd261/PLAN-BD261-FINAL.md`), same recognition test. The sweep is
     per-in-scope-BD, not active-BD-only — a resolved BD's rich handoff doc must be found, not skipped;
  3. **`session-state.json` prose** — `wave`, `cycle_position`, `pending_decisions`, active notes (per
     the prose-tolerance principle);
  4. **git history of the BD's OWN implementation work** — `git log --grep=BD-NNN` restricted to the
     commits that actually implemented / landed this BD (their messages + evidence SHAs); exclude
     bookkeeping-only commits **and, critically, incidental cross-reference mentions** from other BDs'
     work.

**Merge rule — richest doc wins, git supplies evidence (R2-C / R2-G / OBS-9).** Take the **structure**
(waves and steps) from the **structurally-richest doc** — the one with the most waves / steps / detail
— **regardless of commit status**: a richer uncommitted scratch plan beats the thinner committed
backlog skeleton (choosing the skeleton is exactly what under-populated the resolved pages). Fall to
session-state prose (source 3) only when no doc exists. **Layer `evidence.sha` from git history
(source 4) on top** wherever present — the doc supplies structure, git supplies the landed SHAs; they
are complementary, and the merge is deterministic given the same sources. When the winning structure
came from an uncommitted scratch doc (or prose), the page carries the machine-local chip (§5.5); a
committed-doc structure does not.

**Umbrella / delegating BDs (R3-LEAD / OBS-3).** A BD that delegated its implementation to children
(its own `git log` is design-gate rulings + "delegated to BD-NNN…", not code) must not read
near-empty. Bless its **design-gate + delegation commits** as its legitimate own record, **and**
surface the children's landed work — rolled up, or explicitly linked ("delivered via BD-262–268 →") —
so the page reflects the feature it drove. Do **not** re-count child evidence as the umbrella's own
authored code steps (no double-counting).

**Fabrication guard — the R11 boundary (R2-B / OBS-2).** Git history *alone* (no doc, no plan prose)
may drive a deep plan **only** for a BD that is `Resolved` **or derived-`active`** — i.e. work actually
happened. The guard keys on **membership, not backlog `Status:`**: "queued" means **neither `Resolved`
nor derived-`active`**; an `Open`-status BD that is derived-active (e.g. BD-224, whose `Status:` is
`Open` while it sits in `active[]`) is **not** "queued" and keeps its deep page. A truly queued BD
(neither resolved nor active) with only cross-reference mentions and no real plan source has genuinely
**found nothing** in the plan sense: it must **summary-degrade**, never synthesize `done` steps from
incidental mentions (that fabricates progress, violating R11).

If no source yields a genuine plan, degrade to summary depth **for that one BD only** — never blank the
page. This is the **best-effort deep tier** of the R4 exception: a page whose structure came from an
**uncommitted scratch doc or volatile session-state prose** can differ by machine and drift as work
progresses (surfaced by the machine-local chip, §5.5 / R2-D). **Git history does not count as a
machine-local source** — it is committed and reproduces on any clone (OBS-1). This tier also makes the
prose→structure synthesis (`gaps` / `youAreHere` / `next`, §7.4) **required and named**, not improvised.

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
- best-effort deep-tier marker — a neutral **"best-effort · machine-local"** chip on a deep page whose
  **structure/detail** came (even partly) from an **uncommitted scratch doc or volatile session-state
  prose**, signaling it may not reproduce on another machine (§3, R4 exception, R2-D). **Git history
  does not trigger the chip** — it is committed and reproduces on any clone (OBS-1). A deep page sourced
  entirely from committed data (committed doc + git evidence) is strictly deterministic and carries
  **no** chip.

### 5.6 Other fixed value sets

- `parallelization`: `serial` | `parallel` | `interleaved` | `none` | `idle`. This value is often
  **prose** (`"none — BD-224 in the command-testing gate"`); when it is not an exact enum member,
  degrade per §3's prose-tolerance rule — render the **leading token** as the mode and the remainder as
  an inline note (FIX 3). Never render a raw prose blob as if it were the whole mode.
- `sizeTier`: `large` | `small`.
- **Gap severity** (§7.4.6 `gaps[].severity`): `gate` | `blocker` | `note`. `gate` uses the §5.5 gate
  purple; `blocker` the §5.1 red; `note` the neutral faint. A synthesized gap that borrows a color
  names one of these — never an ad-hoc value (G1).
- These, the statuses (5.1), step states (5.2), scopes (5.3), cursor statuses (5.4), and the gap
  severities above are the complete controlled vocabularies. An out-of-enum value degrades per §3's
  prose-tolerance rule; it is never invented into a new token.

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
- **Running agents** panel — always shown; prose-tolerant (§3). Render a row only for an entry that
  parses as a real spawn name (`<role>-<bd>-<facet>`), taking the leading token as the role chip. An
  entry that is a **no-agents sentinel** — begins `none` / `no agents`, or does not parse as a spawn
  name (e.g. a status note like "none live. NEXT: …") — is **not** a row; when no entry parses as an
  agent, render **"No agents running."** (FIX 2).
- **Decisions & directives** panel — the live `pending_decisions[]` from the snapshot: the session's
  standing directives (already-decided constraints) and any genuinely open decisions alike. This is
  operational session state and lives **only here** — distinct from the design **Rulings** page
  (§7.10), which carries design rationale. (The underlying field is named `pending_decisions`, but its
  contents may be settled directives, so the panel is titled by content, not by the field name.)
- Disclaimer: mirrors `pack-ops/session-state.json`.

### 7.3 Grand plan — `#grand-plan`
Eyebrow "Everything in play · `<mode>`", H1 **Grand plan**. The running window as one view.
- **Sequencing** panel — the parallelization mode (`serial` / `parallel` / `interleaved` / `none` /
  `idle`) with an explanatory note. When `parallelization` is prose, show the leading token as the mode
  and the remainder as the note (§5.6 / §3 prose-tolerance) — never a raw prose blob as the mode.
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
sections. When this BD's structure came from an **uncommitted scratch doc or session-state prose** (§3
discovery), the page carries the **best-effort · machine-local** chip (§5.5, R2-D); a page sourced from
committed data (committed doc + git evidence) carries none — git history is committed (OBS-1).
1. **Masthead** — title, dek, progress bar (`done / total steps landed (%)`), and a stat band: Waves
   (`done of total`) · Commits landed · Gates cleared · Current wave (cursor-authoritative, with
   `in progress` when dirty). **Commits landed** = steps bearing an `evidence.sha`; **Gates cleared** =
   `done` steps that carry a plan-authored `gate` (a landed step's gate is cleared by definition — the
   `plans{}` step shape has no separate gate-state flag, so `done` + `gate` present *is* the cleared
   signal). The tile measures *plan-authored gates that landed* (R2-F): **omit** it when the plan has
   **no `gate` field at all** (e.g. a git-history-sourced plan) — that is not "no reviews," just nothing
   to count; show an explicit **"0"** when the plan **does** author gates but none have landed (OBS-4). Both tiles derive from evidence in the plan, presence-driven
   (§3): they read 0, or the tile is omitted, when the plan carries no execution evidence yet. **Waves (`done of total`)**: `total` counts every wave;
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
   open-decision count. Gaps come from the plan's `gaps[]` when present; when the plan has none, a gap
   MAY be **synthesized from `session-state.json` prose** (e.g. a `pending_decisions[]` gate item →
   `{severity: gate, …}`) per §3's prose-tolerance — this source is blessed (G1). `severity` must be
   one of the §5.6 gap-severity set (`gate` / `blocker` / `note`); `gate` borrows the §5.5 gate color.
7. **Decisions** — the plan's recorded design decisions (✓) plus any `pending_decisions[]` touching
   this BD (BD-scoped).
8. **What's next** — the next step (tag + title + gate + detail). When the plan carries no explicit
   next, it MAY be sourced from `session-state.json` prose (`cycle_position` / `pending_decisions`)
   per §3's prose-tolerance (G3), else fall back to "All planned steps have landed. Next: closeout
   (resolve + changelog)."

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
Pack-memory section — a bare slug mention in prose (a cross-reference or pointer) does not count.
**When a rule carries no `[rationale:]` tag at all** (many pack-memory rules don't), fall back to
matching its bold `- **Title.**` on a rule-defining bullet in each file — the same title fallback used
for the anchor — otherwise every rationale-less rule falsely reports as defined in **no** trinity file
(FIX 1). List the files that define it, with a `Claude-only` pill when only one does.

### 7.8 Dependencies — `#deps`
Eyebrow "Sequencing", H1 **Dependencies**. Edges are **best-effort from prose** (R4 deep-tier caveat):
prefer a structured blocked-by field if the backlog provides one; otherwise parse each BD's `Blockers:`
line. **Extract a `to` only for a genuine prerequisite** — a `BD-NNN` the prose frames as blocking /
waiting-on / gated-on — and **exclude** incidental mentions: explicit negations ("no blockers"),
sequencing-only notes, and coordination pointers (O5). One panel per needing-BD (`from`): its verb +
every prerequisite (`to`). The `why` is the BD's `Blockers:` prose shown **once** per panel (not per
prerequisite); when it is a long multi-sentence paragraph, **truncate to its first sentence / ~200
chars with an expand affordance**, the full text living on the BD page (G5). Panels are grouped by the
needing-BD's own status into fixed sections — Open & queued → Deferred → Resolved → Deprecated &
superseded (empty sections omitted) — deterministically sorted (by `from`, then `to`). A needing-BD
that is `Open`, `Unblocked`, or derived-active sorts into **Open & queued**; `Cancelled` joins
**Deprecated & superseded**.

### 7.9 Recently landed — `#changelog`
Eyebrow "Newest first", H1 **Recently landed**. The changelog is one file per major version; render one
panel per major-version file, newest first: version + date chip + a ✓ list of that version's
**shipped** items. **Scope the ✓ list (O7):** take the top-level shipped bullets only; **exclude**
"Carried over" / dormant / not-yet-shipped sections. **Join wrapped bullets:** a bullet whose text
wraps across source lines is one item — join the continuation lines, never emit a mid-sentence
fragment.

### 7.10 Rulings — `#rulings`
Eyebrow "Decisions on record", H1 **Rulings**. Design decisions (the *why* behind the current work) so
they are not re-litigated — sourced by content from the in-scope plan's recorded decisions (a plan's
`decisions[]`) or dedicated ruling notes (§3). **Not** the session's operational `pending_decisions` —
those are live session state shown only on Frontier (§7.2); Rulings never re-surfaces them, so no item
appears on both pages. Grouped by focus (with a Scope · Order line); each ruling: title + optional id +
detail + context + source pills. The decisions doc may be **committed or an uncommitted/scratch doc**
reachable by the deep-tier discovery (§3); extract each ruling's `detail` (the rationale text) when
present. Presence-driven (R11): **full** when decisions are recorded with detail, **degraded**
(title-only) when detail is thin/absent, **removed** (page and nav item omitted) when none are on
record right now.

### 7.11 Metrics — `#metrics`
Eyebrow "Toward launch", H1 **Metrics**. Three panels: Resolution progress (bar + `resolved / total
(%)`, Open/unblocked, Running window queued) · Closeout shape (prose from counts) · Repo context
(Total items, Running window, Branch). **Branch (O6):** show the resolved base / upstream work branch,
not a worktree-isolation branch — omit or substitute when it matches a worktree name (e.g.
`worktree-agent-*`). Counts follow the §3 O11 rule (status-based; the Active overlay never
double-counts an active-but-`Open` BD).

### 7.12 Help & commands — `#help`
Eyebrow "Pack-side commands", H1 **Help & commands**. Overview lede + a **"What the pack does"** ✓
feature list (**sourced from the README pack-overview section, however titled** — e.g. "What is this?";
O8 / OBS-5; omit the list when that source is absent, per R11) + pack commands grouped by source
section (rows of name + description).
Project-side commands go in the isolated bordered **"Project-side — not pack commands"** block, per R8.
