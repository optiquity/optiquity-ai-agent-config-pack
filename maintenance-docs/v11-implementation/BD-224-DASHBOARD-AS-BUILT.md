# BD-224 — pack frontier dashboard, AS BUILT (pack-side)

**Scope.** A factual, consolidated description of the pack-side BD-224
`/pack-dashboard` subsystem exactly as committed at `2bc8e5a`. Every claim is
grounded in the committed code (renderer / spec / CI checks / test), not the
design docs; where a design doc and the code differ, the code is authoritative
(divergences are called out inline — see the Appendix). References are anchored
by file + symbol, never line number (line numbers drift).

**What this doc is NOT.** It carries no project-side design and no "how to adapt
it" recipe. It describes the PACK side only. Consumers: (1) the BD-257
project-side adapter designer, who builds a SEPARATE project design (the
project-side analog client dashboard) from this; (2) a source for updating
user-facing docs so pack users know what is installed and used. Project-side
concepts appear ONLY in the §6 BD-257 transplant-coordinate framing.

**Companion.** This is the second half of BD-224's pack as-built. The first half
is `maintenance-docs/v11-implementation/BD-224-MODE-ENFORCEMENT-AS-BUILT.md`
(operating modes + Claude-only hook enforcement). The two are independent
subsystems that shipped under the same BD.

**As-built surface (files this doc describes):**

| Surface | Path | Role |
|---|---|---|
| Logic-contract SSOT | `pack-ops/DASHBOARD-SPEC-PACK.md` | the build spec (what to render, thinning, floors) — the fingerprinted LOGIC contract |
| Renderer | `scripts/dashboard-render.py` | the ONE committed realization: `build` / `verify`, state collection, the `CSS`/`JS` shell constants, `assemble_state`, `verify_floor` |
| Runtime board (untracked) | `pack-ops/dashboard-approvals/` | per-clone render output: `dashboard-shell.html`, `dashboard.html`, `dashboard-url.txt` |
| Render+publish skill | `.claude/skills/pack-dashboard/SKILL.md` | the `/pack-dashboard` render → foreground publish → commit flow |
| CI hygiene guards | `scripts/lib/validate_checks/pack_ops_hygiene.py` | Checks 86 / 87 / 88 (approvals-dir cap, session-config not committed, shell spec-sha sync) |
| Floor test | `scripts/tests/test-dashboard-render.sh` | proves `verify` BITES on every droppable component |

---

## 1. Overview — a self-contained board over a fingerprinted render cache

The pack dashboard is a **single self-contained HTML file** that mirrors the pack
frontier: what is in motion, everything in play, and each backlog item's
pipeline. It is a client-side app — one `<style>`, one inline `<script>`, an
embedded JSON `#state`, and a hash router — with **no external `<script>` /
`<link>` / font / image references** (`DASHBOARD-SPEC-PACK.md` §2 step 2). There
is no server: every view reads only from the embedded `#state`.

The render is a **two-part cache** (`DASHBOARD-SPEC-PACK.md` §2, § "Rendering
surface"):

- **A spec-fingerprinted, state-independent HTML SHELL** — the doctype, head,
  inline CSS, the empty `main`/`aside` chrome, an inert `<script id="state">`
  placeholder, and the whole JS (router + render functions). The shell is
  authored from the renderer's committed `CSS` / `JS` string constants and is
  **byte-deterministic** across no-op builds. Its provenance line (emitted by
  `build_shell` immediately after `<!DOCTYPE html>`) stamps `spec-sha` =
  `git hash-object` of the spec. On
  a build the renderer regenerates the shell only when the fresh shell differs
  byte-for-byte from the committed one; a matching fingerprint **reuses it
  unchanged** (`scripts/dashboard-render.py::do_build`, `build_shell`).
- **A live-state payload** injected into the shell's `#state` element. Payload
  is **thinned by tier** so it stays small without dropping any item: every
  backlog BD is represented, but only DETAIL DEPTH varies — a **full** record
  for the in-window set (every non-terminal BD ∪ the 10 newest `Resolved`) and a
  **minimal** record for everything else (`DASHBOARD-SPEC-PACK.md` § "Payload
  thinning"; `assemble_state`, `compute_e_full`, `NEWEST_RESOLVED_N`).

The shell is presentation (versioned, diff-able, reused); the payload is data
(re-collected fresh every build). Because the shell is data-free, a spec-stable
render reuses the exact same shell and only the injected `#state` changes.

---

## 2. The render pipeline (`scripts/dashboard-render.py`)

The renderer is **pack-side only, stdlib-only, never shipped to clients**
(dependency-direction: a pack operation invokes it, no client surface depends on
it, so it is OFF `_SANCTIONED_PACK_SIDE_SHIPPED`). It is generic via `--repo-root`
/ `--spec` (defaults: the script's git toplevel and `pack-ops/
DASHBOARD-SPEC-PACK.md`) so the same engine can render another spec later. Two
argparse modes: `build` and `verify`.

**Step 1 — collect state** (`assemble_state`). Three input classes:

- The **`/backlog/` tree** — `parse_backlog` reads every git-TRACKED
  `backlog/BD-\d+\.md` (via `tracked_bd_files` → `git ls-files backlog/`, never
  a raw FS walk) for `Status:` / `Resolved:` date / title / `Type` / `Target` /
  `Blockers` / `Unblocks` / a substantive body.
- A **live git working-tree read** — `git_status_files` (`git status
  --porcelain`, EXCLUDING the render's own `pack-ops/dashboard-approvals/`
  footprint so a board never reports itself as churn) and `worktrees` (`git
  worktree list`, filtered to in-scope current-branch linked worktrees). This is
  a **pre-write snapshot**: it runs before the HTML is written, so the output
  file's own dirtying never appears as `dirty`.
- **`pack-ops/session-state.json`** — `load_session` reads the committed
  frontier snapshot; the session layer (`active`, `queue`, `parallelization`,
  `wave`, `cycle_position`, `in_flight_agents`, `pending_decisions`,
  `boundary_commit`) is consumed **prose-tolerantly** (sentinel detection /
  leading-token parse / raw-display), matching the spec's FIX-4 umbrella
  (`parse_parallelization`, `parse_agents`, `derived_active`).

**Step 2 — thin the payload** (`assemble_state`, `compute_e_full`). Each `bds{}`
record carries an explicit **`tier` field** (`"full"` / `"minimal"`) — the single
authoritative discriminator, not a presence heuristic. `E_full` = (every BD whose
status is in `NON_TERMINAL` = {Open, Unblocked, Deferred}) ∪ (derived-active BDs)
∪ (the `NEWEST_RESOLVED_N`=10 most-recently-`Resolved`, selected by `Resolved:`
date descending then id descending). Full records add a source-anchored `body`;
minimal records carry only the Archive/summary fields.

**Step 3 — author or reuse the shell** (`build_shell`, `do_build`). The renderer
builds a fresh shell from `CSS` + `JS` and stamps the `spec-sha` provenance line;
if the committed `dashboard-shell.html` is byte-identical it is reused, else
regenerated. State is injected by a **targeted single-count replace** of the
`>__PACK_DASHBOARD_STATE__</script>` placeholder (`inject_state`,
`STATE_PLACEHOLDER`) — never a global token replace, which would also clobber the
JS boot-guard's own `indexOf('__PACK_DASHBOARD_STATE__')` sentinel and blank the
board. `serialize` emits the JSON with `ensure_ascii=True` and replaces every `<`
with the JSON escape `\u003c` (the committed `serialize` `.replace` target; the
produced HTML carries `\u003c`, which `JSON.parse` decodes back to `<`
client-side), so (a) no value's `</script>` can close the state element early and
(b) the whole page is pure ASCII.

**Step 4 — atomic write + complete-floor verify** (`do_build`, `verify_floor`).
The board is rendered into a temp file in the approvals dir, `verify`'d THERE,
and `os.replace`d into `dashboard.html` **only on PASS**; a shortfall deletes the
temp and exits non-zero, leaving **no board on disk** (complete-or-loud-abort).
The shell is written/reused only after the board passes. `verify` re-derives the
expected board INDEPENDENTLY from the live tree (re-reading disk, not trusting
build's in-memory objects) and fail-closes on any dropped DATA component (§4).

**Publish (skill Step 2, orchestrator-only).** Publishing to claude.ai is
Claude-only and **foreground / orchestrator-only** — a spawn-driven publish is
denied by the auto-mode classifier. The claude.ai Artifact body is derived from
`dashboard.html` on the fly by **stripping the outer HTML document wrapper**
(doctype / html / head / body — the Artifact tool supplies its own, and the page
is ASCII-safe, so the stripped body publishes cleanly); no separate body file is
written. First publish records the returned URL into `dashboard-url.txt`;
subsequent renders **republish the freshly-derived body to that same recorded
URL** (an already-approved artifact does not re-prompt). On a CLI without the
publish capability the render is the deliverable, opened locally, and no URL is
recorded (`.claude/skills/pack-dashboard/SKILL.md`).

---

## 3. The state model + the recency-ordering fix

`assemble_state` returns one `state` dict. Its top-level keys: `version` /
`qualifier` / `date` (README version table), `counts` / `metrics` (backlog
tally), `boundary` / `boundaryFresh`, `active` / `activeNotes` / `motion` /
`queue` / `parallelization` / `wave` / `cyclePosition` / `inFlightAgentsRaw` /
`agentsRunning` / `pendingDecisions` (session layer), `inflight{files,worktrees,
dirty}` (live git read), `bds{}`, `plans{}`, `rules[]`, `changelog[]`,
`agents[]`, `help{}`, `repo{branch}`.

**Per-BD record (`bds{}`).** Each record carries `id`, `num`, `title`, `status`,
`backlogStatus`, `tier`, `snippet`, `type`, `target`, `blockers`, `unblocks`;
full-tier records add `body`; **`Resolved` records (both tiers) add
`resolved_date`**.

**Status → tag mapping.** Backlog `Status:` maps to a token via `STATUS_TOKEN`
(`Open→pending`, `Unblocked→unblocked`, `Deferred→deferred`, `Resolved→done`,
`Deprecated→deprecated`, `Cancelled→cancelled`). A record's `status` is the token
UNLESS the BD is derived-active, in which case it is `"active"` (an overlay);
`backlogStatus` always keeps the underlying token. The `active` overlay is
**presentation only — never a count bucket**: `counts` tally by `backlogStatus`
token, so an active-but-`Open` BD is counted under Open (`assemble_state`; the
`JS::LBL` map turns each token into a `[label, pill-class]` at render time).

**Recency ordering (the BD-224 fix, commit `2bc8e5a`).** `resolved_date` is the
committed `Resolved:` date (`YYYY-MM-DD`, or `""` when the entry carries none),
and it is the sort key for the resolved surfaces. Three rendered surfaces show
resolved items in recency order:

- **Landing "Recently resolved"** and **Archive "Recently resolved"** — both call
  `JS::recentResolved`, which sorts `(b.resolved_date||'').localeCompare(
  a.resolved_date||'')||b.num-a.num` (date-descending, then id-descending).
- **Archive "Resolved" group** — `JS::pArchive` sorts the `done` group with the
  same comparator; every other group sorts by `num` descending.

The floor asserts the datum: `verify_floor` group **B12** requires
`resolved_date` on EVERY `Resolved` record, and a render-token smoke asserts the
`(b.resolved_date||'').localeCompare(a.resolved_date||'')` comparator appears
at least twice (a `< 2` floor; the produced shell carries exactly 2 — one per
resolved surface: `recentResolved` + the `pArchive` Resolved group). The spec
was reconciled in the same commit (`DASHBOARD-SPEC-PACK.md` §3
"Payload thinning" now names `resolved_date`; §7.1 Landing and §7.5 Archive
already mandated committed-`Resolved:`-date ordering).

**Why the fix was needed (as recorded in `2bc8e5a`).** The renderer already
PARSED each BD's `Resolved:` date into its internal `records` (used by
`compute_e_full` and the `plans{}` newest-10 selection) but **dropped it from
`#state`** — so the shell had no date to sort on and fell back to `b.num`
(BD-number descending). Just-resolved low-number BDs were buried (BD-224 itself,
number 224 among 200+ tracked, never surfaced in the 5-item card despite carrying
the newest resolution date). The fix emits `resolved_date`, sorts date-desc, and
floors the datum. Grounding: `assemble_state` (the `if r["status"] ==
"Resolved": rec["resolved_date"] = ...` emit), `JS::recentResolved`,
`JS::pArchive`, `verify_floor` (B12 + the comparator smoke),
`DASHBOARD-SPEC-PACK.md` §3 / §7.1 / §7.5.

**Other panels** (all in `#state`, floored in §4): `plans{}` (committed-history
cards from a single `git_landings_map` `git log` pass), `rules[]` (`parse_rules`
from `CLAUDE.md` § Pack memory — populated title/anchor/group/body, never index
stubs), `changelog[]` (`parse_changelog` from the `/changelog/` tree, excluding
non-feature `DEFERRED`/`Audit artifacts`/`Carried over` sub-sections), `agents[]`
(`parse_agents_roster` from `PACK-AGENTS.md`), `help{}` (`parse_help` from
`HELP-FRAGMENT-PACK.md`), `metrics{}`, and the `inflight{}` structure.

---

## 4. CI guards + the verify floor

**CI hygiene guards** live in `scripts/lib/validate_checks/pack_ops_hygiene.py` —
three cheap git-TRACKED-state screens (own connected-component module per the FIRM
own-module-per-new-check convention). All three enumerate via a shared
`_git_ls_files` helper (one `git ls-files` subprocess, O(one dir), never a raw FS
walk) and are **SKIP-lenient off a git work tree**. Critically, all three also
**SKIP while the board is untracked** — at HEAD `pack-ops/dashboard-approvals/`
is absent, so each guard's tracked set is empty and it passes vacuously:

- **Check 86** (`check_dashboard_approvals_file_cap`) — caps the git-TRACKED
  approvals set at EXACTLY `{dashboard.html, dashboard-url.txt,
  dashboard-shell.html}`. An extra tracked file (registry creep) FAILs; a strict
  subset FAILs too — the missing-file teeth enforce all-three-or-none
  first-commit atomicity.
- **Check 87** (`check_session_config_not_committed`) — asserts the per-clone
  runtime `pack-ops/session-config.json` is NEVER git-tracked (verifies the
  load-bearing reality, not just a `.gitignore` line).
- **Check 88** (`check_dashboard_approvals_spec_shell_sync`) — when the shell is
  tracked, asserts its embedded `spec-sha` HTML comment equals `git hash-object`
  of the tracked `pack-ops/DASHBOARD-SPEC-PACK.md` (via `_git_hash_object`). A
  mismatch = a committed stale shell (spec changed without a re-render); a
  declared spec-sha whose spec cannot be hashed also FAILs (declare-verify-backing
  catches the absence-of-backing instance).

**The `verify` DATA floor** (`scripts/dashboard-render.py::verify_floor`) is a
separate, render-time gate (NOT a validate-pack check). It re-derives the expected
board from the live tree and asserts three groups plus a render-token smoke:

- **Group A — the 9-field session layer:** `boundary`, `active`,
  `inFlightAgentsRaw`+`agentsRunning`, `queue`, `parallelization` (leading-token
  mode, never a raw blob), `wave`, `cyclePosition`, `pendingDecisions` (each
  presence-conditional), plus the derived `motion` = `active ++ (queue - active)`
  (unconditional).
- **Group B — every backed section:** B1 `bds{}` total-accountability +
  status-vocab closure, B2 the `tier:"full"` set equals `E_full` with
  source-anchored bodies, B3 the committed-history `plans{}` floor, B4 `rules[]`
  populated (not stubs), B5/C4 the `changelog` v11 panel populated and
  non-feature-marker-free, B6 `agents[]` roster, B7 `metrics`, B8 `help` (when a
  source exists), B9 `inflight{}` structure, B11 README-backed
  `version`/`qualifier`/`date`, and **B12 `resolved_date` on every `Resolved`
  record** (the recency sort key).
- **Group C — parse/encoding invariants:** C1 injection sentinel survival + no
  `</script>` breakout, C2 status-token counts (buckets sum to total; the active
  overlay never re-buckets), C3 pure-ASCII output.
- **Render-token smoke:** the 10 nav route tokens, the 11 `p*` render functions,
  the state boot, the escape helper, and the resolved-comparator (a `< 2` floor;
  the shell carries exactly 2). String-presence only (no JS engine) — catches a WHOLESALE-dropped
  route/function or a wholesale revert to num-sort, not a subtly-broken-but-present
  one (that stays diff-review).

**B10 carve-out (explicit).** `deps` / `methodology` / `rulings` are deliberately
NOT floored at Level 2: `deps`/`methodology` are JS render-time derivations from
already-floored upstream data, and `rulings` is spec-optional and UNIMPLEMENTED in
the render layer (no `#state` key, no nav token — see `NAV_ROUTE_TOKENS` /
`RENDER_FN_TOKENS`).

**The floor test** `scripts/tests/test-dashboard-render.sh` builds a populated
`git init` fixture and drives a complete tamper matrix — one non-vacuous row per
floor assertion (T-A1..A9; T-B1..B9 + T-B11 + T-B12 — B10 is the deliberate
unfloored carve-out, so there is no T-B10; T-C1..C4; the smoke) — asserting `verify`
exits non-zero on each single-component drop, plus the S2 atomic-build fail-closed
and determinism (byte-identical shell reuse).

---

## 5. What is installed / used (for user-facing docs)

| Artifact | Committed? | What it is at runtime |
|---|---|---|
| `scripts/dashboard-render.py` | tracked | The committed renderer; `python3 scripts/dashboard-render.py build` renders + verifies; `verify` re-checks the floor. Pack-side only, never shipped. |
| `pack-ops/DASHBOARD-SPEC-PACK.md` | tracked | The LOGIC contract; its `git hash-object` is the shell's `spec-sha`. |
| `.claude/skills/pack-dashboard/SKILL.md` | tracked | The `/pack-dashboard` verb: render → foreground claude.ai publish → commit. |
| `pack-ops/dashboard-approvals/dashboard.html` | **untracked at HEAD** | The rendered board; regenerated every render; committed only when a user runs the render+commit flow. |
| `pack-ops/dashboard-approvals/dashboard-shell.html` | **untracked at HEAD** | The spec-fingerprinted reusable shell; regenerated only on a spec change. |
| `pack-ops/dashboard-approvals/dashboard-url.txt` | **untracked at HEAD** | The recorded claude.ai artifact URL (one line); written on first publish, reused after. |
| `scripts/lib/validate_checks/pack_ops_hygiene.py` | tracked | Checks 86/87/88 (SKIP-lenient while the board is untracked). |
| `scripts/tests/test-dashboard-render.sh` | tracked | The complete-floor test (CI + local). |

**What a pack user does.** Run `/pack-dashboard` (Claude) or `python3
scripts/dashboard-render.py build` directly. The renderer writes the three
approvals-dir files under `pack-ops/dashboard-approvals/`. Under Claude, the skill
then publishes the board to claude.ai in the foreground (first publish is the
permission gate) and records the URL; later renders republish to the same URL.
The approvals-dir files are committed only via the skill's Step 3, with user
approval — the first render commits all three together; later renders commit
`dashboard.html` always and `dashboard-shell.html` only when the spec-sha flipped.
`/pack-dashboard` also participates in the general Check 89 help↔skill parity gate
like every `/pack-*` command (that is a help-fragment check, not a dashboard-floor
check — see the Appendix).

---

## 6. Findings + constraints (honest)

- **Client-render architecture + payload size.** The board is a single
  self-contained client-rendered HTML file — no server, all views read the
  embedded `#state`. Payload is bounded by tier thinning (full only for the
  in-window set + newest-10 resolved; minimal, width-capped, for the rest), so it
  stays small on a 200+ BD tree without dropping any item. The cost is that the
  whole state ships inline in every board.
- **claude.ai publish is foreground / orchestrator-only.** The publish path is
  Claude-only and cannot run from a spawned sub-agent (auto-mode classifier denies
  a spawn-driven publish). It derives the Artifact body by stripping the outer
  HTML wrapper each publish; there is no separate body file. On a non-Claude CLI
  the render is the deliverable and there is no publish/URL step.
- **Untracked-board posture.** At HEAD the approvals dir is absent, so Checks
  86/87/88 SKIP and the reuse cache is byte-exact but has nothing committed to
  drift against. The board is per-clone runtime state; keep-vs-remove is a user
  decision at commit time (the skill's Step 3 commits it only on approval). An
  adapter must NOT assume a committed board — the guards are written to run clean
  against BOTH the absent and the present-three-file states.
- **`verify` is a DATA floor, not a render-correctness proof.** It parses `#state`
  and never executes JS, so it catches dropped/mis-shaped DATA and wholesale-dropped
  render tokens, but a subtly-broken-but-present render function is caught only by
  committed-source diff-review + the boot-guard, not by `verify`.

**BD-257 transplant coordinate (project-side, deliverable-only).** BD-257's
project-side client dashboard adopts this SAME render-cache foundation — the
spec-fingerprinted state-independent shell + tier-thinned live payload + the
atomic-build complete-floor `verify` — and MUST inherit the **corrected recency
ordering**: emit the resolution date on resolved records and sort the resolved
surfaces date-descending (then id-descending), NOT the superseded pure num-sort
this BD replaced. The adaptation is element- and surface-substitution, not a
redesign:

- **Elements:** project TD entries + phases/waves in place of pack BD entries +
  coder waves; the project status vocabulary in place of the backlog one.
- **Surfaces:** a client build-spec in place of `DASHBOARD-SPEC-PACK.md`; a client
  approvals dir; a client dangling-ref / spec-sha token in place of the pack ones.
- **Placement:** the client ships its OWN copy of the render skill under the
  project template (dependency-direction: a client-shipped deliverable defaults
  project-side and must never be a runtime dependency of a pack operation).

This is a POINTER for the BD-257 designer only — it prescribes no project-side
design here.

---

## Appendix — code-vs-history divergences found

1. **Superseded OPTION-2 render-floor apparatus (git history, not HEAD).** Earlier
   BD-224 commits shipped a heavier design — a three-way `{spec-sha,
   structure-sha}` fingerprint on Check 88 plus a NEW DEEP "Check 89 independent
   committed-render floor." That apparatus was **ripped out** before this HEAD. At
   `2bc8e5a` the committed reality is the simpler design this doc describes: **Check
   88 is a single `spec-sha` == `git hash-object` match** (no structure-sha), and
   there is **no dashboard render-floor Check 89**. The as-built code is
   authoritative; the git-log subjects mentioning the three-way fingerprint / DEEP
   floor describe the superseded design.

2. **"Check 89" is a different, unrelated check.** `scripts/lib/validate_checks/
   help_fragments.py` DOES define a Check 89 — but it is the **HELP-FRAGMENT
   `/pack-*` command ↔ backing-skill parity** gate (also opened under BD-224). It
   is not part of the dashboard render floor; it covers `/pack-dashboard` only as
   one of many `/pack-*` verbs. Do not conflate it with the dashboard guards
   (86/87/88).

3. **Check 88 docstring points at design-doc sections.** `check_dashboard_
   approvals_spec_shell_sync` cites "architecture §3/§4/§9" — those are sections in
   the BD-224 dashboard architecture design doc (the render-cache design), not the
   build spec (`DASHBOARD-SPEC-PACK.md` has no §9). This is a cross-reference, not
   a behavior divergence.
