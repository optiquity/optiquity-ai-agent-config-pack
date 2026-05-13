# ARCHITECTURE — Per-Entry Flat-File Format for BACKLOG / IMPLEMENTATION_PLAN / STATUS / CHANGELOG

**Author:** pack-architect (v11-dev)
**Date:** 2026-05-12
**Branch:** v11-dev
**Status:** Architecture proposal; read-only deliverable; no implementation in this batch
**Output file:** `maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-FLAT-FILES.md`

---

## 0. TL;DR

The pack's PM docs (`BACKLOG.md`, `IMPLEMENTATION_PLAN.md`, `STATUS.md`,
`CHANGELOG.md`) are monolithic — one stream-sized file per concern. At v11-dev
the pack-repo BACKLOG is 3,556 lines / 140 entries (Bash inventory:
`wc -l BACKLOG.md` → 3556; `grep -c '^Status:' BACKLOG.md` → 140). This
proposal replaces each monolithic file with a directory of per-entry files
governed by (a) an immutable per-directory **rules** file and (b) a mutable
per-directory **TOC** file. The shape is fully usable standalone (no
tracker, no Graphify), interoperates with the existing v11 GH-issue tracker
through replacement of `tracker-mirror.sh` / `tracker-migrate-forward.sh` /
`tracker-migrate-reverse.sh` (4 BDs of new work; round-trip property
preserved), and is a strict improvement for Graphify Pass-3 LLM extraction
should it land in v12.

**Recommended version target:** v11.1 (minor). Reasoning in §14.

This is a single design satisfying three concurrent consumers simultaneously
(standalone flat-file readers, v11 GH-issue tracker, future Graphify graph
build). Where any consumer's needs conflict, §9 calls out the conflict and
shows how the design resolves it.

---

## 1. Cited reading

This proposal is grounded in the following materials. File:line references
are used throughout.

- `maintenance-docs/RESEARCH-GRAPHIFY-SYNTHESIS.md:14-17` — Graphify recommendation
  (opt-in, v12, not v11.0); `:32-38` — token-reduction range (5-10× pure code,
  50-70× mixed corpora); `:104` — "Don't introduce a new agent. The graph-query
  work fits as a skill loaded by existing agents."
- `maintenance-docs/RESEARCH-GRAPHIFY-PACK-INTEGRATION.md:29-37` — RAG manifest
  default = one file (`METHODOLOGY.md`); `:140-153` — artifact location stays
  trinity-symmetric, hook integration is per-CLI; `:188-211` — agent-by-agent
  benefit map; `:246-264` — Graphify ingesting tracker mirror; `:340-359` —
  trinity exemption shape.
- `BACKLOG.md:1-22` — preamble + section markers (`## How to use this file`,
  `## Active — v11 Scope`); `:33-46` — canonical entry shape (Title, Type,
  Status, Blockers, Unblocks, File/Symbol, Description, Resolved); section
  separators are `---` lines (4 spaces, two hyphens); entries span 12-50
  lines each.
- `CHANGELOG.md:1-40` — chronological-by-version flat structure; `## v11 —
  May 2026` headings with `### vN.M` subsections.
- `project-template/docs/pack/PM-CHAT.md:117-131` — File access strategy table:
  BACKLOG.md / STATUS.md / CHANGELOG.md / IMPLEMENTATION-PLAN.md / PLATFORM-SKILLS.md
  are all "Direct read"; `:133-170` — RAG ingestion manifest (single-file default);
  `:159-170` — additional-document manifest discriminator (RAG vs Direct).
- `supporting-docs/METHODOLOGY.md:140-184` — RAG hygiene principle (orphans
  are confidently-wrong retrievals); `:156-179` — `/pm-startup` Step 4
  reconciliation contract; design model for the TOC reconciliation in §3 below.
- `supporting-docs/CLI-PM-SETUP.md` — mcp-local-rag setup; `.pack-tracker/`
  gitignore convention (pack-root `.gitignore:9-15` per RESEARCH-GRAPHIFY-
  PACK-INTEGRATION §9.3).
- `scripts/lib/tracker-mirror.sh:1-105` — 105 lines; current monolithic
  mirror header write/strip (Python heredoc in bash); `tracker_mirror_header_emit`,
  `tracker_mirror_header_write`, `tracker_mirror_header_strip`.
- `scripts/lib/tracker-migrate-forward.sh:1-41` — 1,465 lines total;
  V1 §6.2 11-step algorithm; idempotency markers (title + body footer +
  mapping file); `forward.checkpoint.json` cadence.
- `scripts/lib/tracker-migrate-reverse.sh:1-47` — 954 lines total;
  V1 §6.5 9-step algorithm; emits BACKLOG.md + IMPLEMENTATION-PLAN.md +
  STATUS.md + CHANGELOG.md skeleton + sidecar.
- `scripts/lib/tracker-provider.sh:1-30` — provider abstraction (BD-060);
  18 operations + `raw(...)` escape hatch (V1 §2.1).
- `scripts/lib/tracker-provider-gh.sh` — GH backend (716 lines) — the
  reference shape for future backends (forgejo/linear/jira).
- `scripts/lib/tracker-config.sh:1-60` — `tracker.toml` schema reader;
  `tracker_mode()` returns `tracker` | `flat-file` (V1 §3.2 detection algorithm).
- `scripts/pack-tracker.sh:1-23` — verb dispatcher: `init` / `status` /
  `disable` / `doctor` / `update-templates` / `mirror-rebuild` /
  `enable-recommendations`.
- `scripts/validate-pack.py:1-113` — Check inventory (30 numbered + 2 informational);
  Check 28 = PM-startup parity, Check 29 = tracker-config schema, Check 24 =
  HELP-FRAGMENT-TRACKER byte-identity.
- BD-066 / BD-067 / BD-068 / BD-069 entries (`BACKLOG.md:120-175`) —
  the tracker mirror format and round-trip property established at v11.0;
  this proposal extends those rather than overrides them.

---

## 2. Problem decomposition

Three forces drive the change:

1. **Per-edit churn cost.** Editing one BD touches one paragraph in a
   3,556-line file. Concurrent agent writes (one BD-progressing coder,
   one BACKLOG-flipping Pack Chat) collide in the same file even though
   they touch semantically independent entries. Git's per-file blame
   model is defeated.
2. **Per-read token cost.** A `Read BACKLOG.md` Tool call ingests
   ~3,556 lines / ~90 KB / ~22,500 tokens (~6 tokens per line for
   prose) just to surface one BD's status. Mirror cost identical
   in tracker mode (`tracker-migrate-reverse.sh` writes the same
   shape). For every Pack Chat lookup of "is BD-156 still open,"
   the agent loads 139 unrelated entries.
3. **Topology-tool granularity.** Graphify Pass-3 (LLM extraction)
   chunks documents and infers `INFERRED` edges between chunks
   (`RESEARCH-GRAPHIFY-EXTERNAL.md` §§ 5, 6, 8 per the synthesis cross-
   reference at `RESEARCH-GRAPHIFY-SYNTHESIS.md:26`). When a BACKLOG is
   a single file, every BD becomes a chunk inside one node — edges
   between BDs lose structural typing and degrade into embedding
   neighbors. With one BD per file, every BD is a graph node and
   `Blockers:` / `Unblocks:` lines become typed edges with
   confidence 1.0 (the same `EXTRACTED` confidence Pass-1
   tree-sitter edges carry per `RESEARCH-GRAPHIFY-SYNTHESIS.md:25-26`).

These three forces apply whether or not the tracker is on and whether or
not Graphify ever lands. The shape change is independently justified by
force #1 + #2; #3 is a bonus that materializes in v12.

---

## 3. Decision-ready summary table (forward reference)

A summary table mapping each of the 14 success-criterion questions to
the section answering it is at the end of this document (§16).

---

## 4. File naming and directory layout (success criterion #1)

### 4.1 Directories

Per-entry files live in directories named after the stream they replace.
The directory itself replaces the monolithic file; the monolithic file
no longer exists.

```
docs/project/                    (client) | repo root (pack)
├── backlog/                     replaces BACKLOG.md
│   ├── _rules.md                immutable rules file (§5)
│   ├── _toc.md                  mutable TOC file (§6)
│   ├── BD-001.md                one file per BD entry
│   ├── BD-002.md
│   └── ...
├── implementation-plan/         replaces IMPLEMENTATION_PLAN.md
│   ├── _rules.md
│   ├── _toc.md
│   ├── phase-01.md              one file per phase
│   ├── phase-02.md
│   └── ...
├── status/                      replaces STATUS.md
│   ├── _rules.md
│   ├── _toc.md
│   ├── 2026-05-04.md            one file per status entry, ISO date
│   ├── 2026-05-11.md
│   └── ...
└── changelog/                   replaces CHANGELOG.md
    ├── _rules.md
    ├── _toc.md
    ├── v11.0.md                 one file per version
    ├── v11.1.md
    └── ...
```

In the pack repo, these directories are siblings of the existing trinity
files (`BACKLOG.md` → `backlog/`, etc.). In a client project, they live
under `docs/project/` per the current Document locations table
(`project-template/CLAUDE.md` § Document locations).

### 4.2 Filename conventions

Filenames are stable, unique, and prose-citable (consistent with the
project-wide filename-uniqueness heuristic recorded in MEMORY:
`feedback_filename_uniqueness`):

| Stream | Filename pattern | Example | Justification |
|---|---|---|---|
| Backlog | `<PREFIX>-NNN.md` | `BD-001.md`, `TD-042.md` | Same identifier the title carries; one stable file per ID for the life of the ID; renames forbidden (see §13). PREFIX comes from `tracker.toml` `id_namespace.prefix` (BD = pack, TD = client). |
| Implementation plan | `phase-NN.md` | `phase-01.md`, `phase-02.md` | Phase number is the granularity floor — tasks 1.1, 1.2, ... live *inside* the parent phase file (per brief constraint: "nothing smaller than a phase"). Two-digit zero-pad to keep filesystem sort = numerical sort up to 99 phases. Fractional phases (2.1, 2.2) per `METHODOLOGY.md:326` are sections within the parent phase file, not separate files. |
| Status | `YYYY-MM-DD.md` | `2026-05-04.md` | ISO-8601 date is a sortable filename; one entry per day (per current status practice). If multiple entries land on the same day, append `-N`: `2026-05-04-2.md`. |
| Changelog | `vN.M.md` | `v11.0.md`, `v11.1.md` | Matches the existing `### vN.M` heading shape (`CHANGELOG.md:9-11`). Major-only versions (e.g., `v11`) get their own roll-up file `v11.md` if used. |

**Case sensitivity.** BD prefixes are uppercase by current convention
(`BACKLOG.md:33` etc.). Filenames are uppercase BD prefix + zero-padded
number; case-insensitive filesystems (macOS HFS+ default, Windows NTFS)
treat `BD-001.md` and `bd-001.md` as the same file. The convention is
"all uppercase, three-digit zero-pad"; the validator (Check 31, §11)
rejects deviations.

**Reserved leading underscore.** Files beginning with `_` are reserved
for directory metadata (`_rules.md`, `_toc.md`, future `_archive.md`).
This separates metadata from entries cleanly at the sort level (`ls`
lists `_*` first on most systems with `--group-directories-first`-style
ordering, or with `LC_COLLATE=C`).

### 4.3 Where directories live in `project-template/`

Client projects: `project-template/docs/project/{backlog,implementation-plan,status,changelog}/`.

The `_rules.md` files ship from `project-template/docs/project/<stream>/_rules.md`
into the client tree on `init-project.sh` (and on `migrate-vN-to-vM.sh` runs
that include this batch).

The `_toc.md` files ship as **bootstrapped seeds** — the seed contains the
TOC of any seed entries shipped (e.g., a starter `phase-01.md` for the
implementation-plan stream, if the pack chooses to ship one). For fresh
projects, the seed `_toc.md` typically just contains the header table and
zero entries.

Pack repo: `backlog/`, `implementation-plan/`, `status/`, `changelog/` as
top-level directories in the pack root, replacing the existing `BACKLOG.md`,
`CHANGELOG.md`, etc. (the pack repo has no `IMPLEMENTATION_PLAN.md` at root
today — the v11 plans live in `maintenance-docs/v11-research/`. The
proposal does *not* relocate v11-research artifacts; they're a different
class of doc per `CLAUDE.md` pack-memory `## Repo conventions` ["Separate
pack ops from pack product"]).

Pack-self adopts only the streams it currently has — `backlog/` (replacing
`BACKLOG.md`) and `changelog/` (replacing `CHANGELOG.md`). Pack-self does
not grow `status/` or `implementation-plan/` directories; the v11-research
carve-out remains the authoritative location for pack development plan-class
artifacts. Source of decision: `ARCHITECTURE-PER-ENTRY-PACK-VS-CLIENT.md §1.4`.

### 4.4 init-project.sh placement

The `scripts/init-project.sh` script today copies `project-template/`
content into the target. The change is mechanical: copy the four directories
(`docs/project/{backlog,implementation-plan,status,changelog}/`) along with
everything else. No new init logic — the seed `_rules.md` and `_toc.md` are
just files like any other template file.

For `init-project.sh --update` (refresh mode, v11), the same directory-tree
delta applies, with **two** non-trivial cases handled by the migrator
framework (BD-119 / `scripts/lib/migrator-core.sh`):

1. Existing project at v11.0 with `BACKLOG.md` (monolithic): run the
   one-shot decomposer (§10) as a pre-update step.
2. Existing project at v11.0 with tracker on (no `BACKLOG.md` at all —
   only `.pack-tracker/mapping.json` plus the read-only mirror):
   regenerate the mirror in the new per-entry shape before continuing
   the update.

### 4.5 Git carriage

Per-entry files are tracked normally; the directories show up in `git status`
like any other directory. `git mv` is the supported rename mechanism (rarely
used — see §13 rename policy). `git log -- backlog/BD-001.md` gives the
per-BD history, restoring the per-file blame model that the monolithic shape
defeats. This is one of the standalone benefits independent of any tracker
or Graphify integration.

---

## 5. The `_rules.md` file — contents and immutability (success criterion #2)

### 5.1 Contents

`_rules.md` is the per-directory contract. It is short (~50-100 lines),
declarative, and audience-targeted at agents (both PM/Pack Chat and skill-
loaded sub-agents).

Required sections, in order:

1. **`# Rules: <stream-name>`** — H1 with the stream name (`backlog`, etc.).
2. **`## Filename convention`** — the regex + worked example (e.g.,
   `^BD-\d{3}\.md$` for backlog; `^phase-\d{2}\.md$` for implementation-plan).
3. **`## Required entry sections`** — the H2 sections every entry file must
   carry (e.g., for backlog: `Title` (H1), `Type`, `Status`, `Blockers`,
   `Unblocks`, `File/Symbol`, `Description`, `Resolved` — mapping
   one-to-one to the current `BACKLOG.md:33-46` shape).
4. **`## Cross-reference syntax`** — the canonical citation form for
   pointing to another entry from this stream or another (§7).
5. **`## Lifecycle`** — the legal statuses (`Open` / `Unblocked` /
   `Resolved` / `Cancelled` / `Deprecated` / `Deferred`) and transitions.
   For the backlog, these match the current `BACKLOG.md` taxonomy
   (`Status:` distribution from the v11-dev tip: Open 32, Resolved 94,
   Deferred 10, Cancelled 1, Deprecated 3).
6. **`## TOC contract`** — what the `_toc.md` file in this directory must
   contain and how it is regenerated (§6).
7. **`## Read-path semantics`** — what "read this stream" resolves to for
   each access pattern (single-entry lookup, status filter, blocker trace).
   The full read-path contract is §8.
8. **`## DO NOT EDIT`** — the immutability declaration (§5.2).

### 5.2 Immutability mechanism

The brief requires the design to choose an enforcement mechanism. The
shape uses **defense in depth**: convention + sentinel + validator check +
trinity-style review pressure. Specifically:

(a) **Sentinel marker** at the top of `_rules.md` — first non-blank line
after the H1:

```markdown
<!-- PACK-IMMUTABLE: v11.1 — do not edit. Updates ship via pack migration. -->
```

The sentinel encodes the pack version that owns the file. A pack migration
(BD-119 framework, `scripts/lib/migrator-core.sh`) updates this marker as
part of its file-replacement pass — the same way it currently handles
trinity-file scaffolding updates.

(b) **Validator Check 31 (new)** — `scripts/validate-pack.py` extension:
the sentinel must be present, well-formed, and the pack version on disk
must match the working tree's pack version. Violation: hard fail
(consistent with the existing Check 18 trinity-parity hard-fail pattern,
`validate-pack.py` header lines 43-45).

(c) **Agent skill enforcement** — the new `per-entry-flat-files` skill
(§11.2) carries the rule "Never write to `<stream>/_rules.md`" as a hard
rule in its `## Output policy` block, mirroring the existing
`Permission profile` patterns used in pack agents (e.g., `pack-architect`
output-policy section).

(d) **Trinity-style review pressure** — the rule "PM/Pack Chat may not
edit `_rules.md`" lands in `PACK-CHAT.md` (pack) and
`project-template/docs/pack/PM-CHAT.md` (client) — both `PM-CHAT.md`
copies — same edit pattern as the BACKLOG/CHANGELOG no-write rule already
codified at `PM-CHAT.md:36` (this is the same kind of rule, just a
different file set).

**Why not file mode (`chmod 444`)?** Filesystem permissions are not
git-tracked, are reset on every fresh clone, and are user-friendly only
on POSIX. The pack supports macOS + Linux + Windows-via-WSL; mode-based
immutability would be inconsistent. Rejected.

**Why not a separate read-only branch / submodule?** Adds a tier of
infrastructure (`git submodule` learning curve) for a single small file
per directory. Disproportionate. Rejected.

The chosen mechanism is "sentinel + validator + skill rule + chat rule" —
four independent guards, none of which require new infrastructure. A
violation by any single guard is caught by at least one of the others.

### 5.3 Updating the rules file across pack versions

The `_rules.md` files are owned by the pack template. A v11.1 → v11.2
migration that revises the entry-shape rules updates `_rules.md` in
`project-template/docs/project/<stream>/_rules.md`; the migrator copies
the new file into the client tree. **Collision avoidance:** because the
file is immutable in client projects, there is no "client edited
`_rules.md`" case to merge against — the file is overwritten unconditionally,
the same way `project-template/docs/pack/METHODOLOGY.md` overwrites the
client copy on update (consistent with `scripts/lib/customization-preserve.sh`
BD-088 three-way classifier's `client_unchanged_pack_changed` = `pack_wins`
disposition for unmodified pack files).

If a client *does* modify `_rules.md` despite all four guards, the
customization-preserve report flags it as a defect (BD-088 mechanism
already exists; this is a new file class but the same disposition table).
The conflict resolution is: pack wins, client edit is recorded in the
truthful migration report (BD-088 deliverable), human reviews.

---

## 6. The `_toc.md` file — format, generation, conflict resolution (success criterion #3)

### 6.1 Format

`_toc.md` is a compact, line-stable table mapping ID → status → title.
Format for `backlog/_toc.md`:

```markdown
# TOC: backlog

<!-- PACK-MANAGED: regenerated by Pack/PM Chat. Last regenerated: 2026-05-12T14:30:00Z -->

**Counts:** Open 32 · Unblocked 0 · Resolved 94 · Deferred 10 · Cancelled 1 · Deprecated 3 · Total 140

| ID | Status | Title |
|---|---|---|
| BD-001 | Resolved | Initial pack content |
| BD-002 | Resolved | ... |
| ... |
| BD-159 | Open | Per-entry flat-file format |
```

Stream-specific schemas:

- `implementation-plan/_toc.md`: columns `Phase | State | Title` where
  `State` ∈ {`Not started`, `In progress`, `Complete`}.
- `status/_toc.md`: columns `Date | Phase | Summary`.
- `changelog/_toc.md`: columns `Version | Date | Summary`.

### 6.2 Generation contract — auto-rebuilt, not hand-maintained

The TOC is **derived state**, not source of truth. Source of truth is the
union of per-entry files. The TOC is regenerated by a single helper —
proposed at `scripts/lib/per-entry-toc.sh` — exposing one function:

```
per_entry_toc_rebuild <stream-dir>
```

Implementation: scan `<stream-dir>/*.md` excluding `_*.md`, parse the
required H1 + `Status:` fields per `_rules.md` schema, emit the TOC table
sorted by ID (or phase number, or date, per stream), update the
`Last regenerated` timestamp, write `_toc.md`. Idempotent: two consecutive
runs without intervening edits produce byte-equal output (modulo the
timestamp line — same pattern as `tracker_mirror_header_write` at
`scripts/lib/tracker-mirror.sh:50-80`).

### 6.3 When the TOC is regenerated

Three triggers, in declining cadence:

1. **Eager** — every time a per-entry file is added, removed, or has its
   `Status:` or H1 line changed. Pack Chat / PM Chat does this as the final
   step of any entry edit, the same way it commits BACKLOG.md updates today.
   This is the common case.
2. **On `/pack-startup` and `/pm-startup`** — Step 4-adjacent reconciliation
   (mirroring the RAG manifest reconcile at `project-template/skills/pm-startup/SKILL.md:130-145`
   and the principle codified at `supporting-docs/METHODOLOGY.md:156-179`).
   The startup procedure does a "rebuild + diff against on-disk" check.
   If the diff is non-empty, the TOC is regenerated and the diff is
   surfaced in the startup summary (`TOC: 3 entries added, 0 removed`).
   This catches the case where a developer hand-edited an entry file
   between sessions.
3. **In tracker mirror writes** — when the v11 mirror regenerates the
   per-entry directory from issue state (§7 changes to `tracker-mirror.sh`),
   the helper calls `per_entry_toc_rebuild` as its final step.

### 6.4 Concurrent-edit pattern — the conflict cost does not relocate

The brief calls out the risk that the monolithic-file conflict cost merely
moves to the TOC. The design avoids that with two properties:

(a) **TOC writes are idempotent and ordered.** Because the TOC is derived,
two agents independently editing two different BD files and then each
running `per_entry_toc_rebuild` produce the **same** TOC — order does not
matter. The git merge of two TOC writes is byte-conflict-free for the
table body (both writers compute identical content); only the timestamp
line drifts. Resolution: a custom `.gitattributes` merge driver for
`_toc.md` files that takes "either timestamp, pick latest." This is the
same git-merge-driver pattern Graphify ships for `graph.json`
(`RESEARCH-GRAPHIFY-SYNTHESIS.md:144`).

(b) **Per-entry edits never collide.** Two agents editing BD-100 and
BD-200 touch two different files — git auto-merges. The cost goes from
"3,556-line file with two paragraph edits in the same patch" to "two
20-line files each with one patch." This is the standalone-mode win
(§9 standalone consumer).

The TOC reconciliation procedure is **always-on** and **does not require
user approval**, mirroring the RAG orphan-removal contract codified at
`supporting-docs/METHODOLOGY.md:167-169`: "The procedure runs unconditionally
on every startup — orphan removal does not require user approval, since
the manifest is the source of truth and orphans are by definition outside
it." Same principle here: per-entry files are the source of truth; the
TOC reconciles to them.

### 6.5 What if the TOC and entries disagree?

Two cases, both handled:

- **TOC has a row that has no entry file** — analogous to a RAG orphan.
  The reconciler logs a warning ("TOC references BD-NNN; no `BD-NNN.md`
  found") and removes the row. The warning surfaces in the startup summary
  so the user can investigate whether the entry was deleted intentionally
  or lost. Mirror of the orphan-deletion contract.
- **Entry file exists but is not in the TOC** — the reconciler adds the
  row. This is the "missing in index" case from `METHODOLOGY.md:163`.

In both cases the entry files (and the underlying git history) are
authoritative; the TOC is regenerated to match. This makes the TOC
disposable in the same way the RAG index is disposable.

---

## 7. Cross-doc reference syntax (success criterion #4)

### 7.1 Canonical form

Cross-references inside per-entry files use a stable, parseable syntax that
agents can grep and Graphify Pass-3 can extract as typed edges:

| Reference target | Syntax | Example |
|---|---|---|
| Backlog entry | `<PREFIX>-NNN` (bare, in any field) | `Blockers: BD-061` |
| Backlog entry, explicit path | ``backlog/BD-NNN.md`` (backticked) | ``See `backlog/BD-061.md` for the schema reader.`` |
| Phase | `phase-NN` (bare) or `implementation-plan/phase-NN.md` | `Blockers: phase-03` |
| Status entry | `status/YYYY-MM-DD.md` (backticked path) | ``See `status/2026-05-04.md`.`` |
| CHANGELOG entry | `vN.M` (bare) or `changelog/vN.M.md` | ``Shipped in `changelog/v11.0.md`.`` |
| File/Symbol field | ``backticked-path`` (existing convention) | `` File/Symbol: `scripts/lib/tracker-config.sh` `` |

This preserves the current `BACKLOG.md` convention (`Blockers: BD-061`,
`File/Symbol:` paths in backticks per the v11-dev entries, e.g.,
`BACKLOG.md:38`, `:52-54`).

### 7.2 Reverse references (Unblocks)

The existing `Unblocks:` line lists IDs that *this* entry unblocks (e.g.,
`BACKLOG.md:36`). With per-entry files, `Unblocks:` becomes the inverse
of `Blockers:` across the dataset — computable, redundant.

The design preserves `Unblocks:` as a **derived, optional** field. It
is regenerated as part of TOC rebuild (the helper performs the inverse
computation across all entries). This is exactly the pattern
`tracker-migrate-reverse.sh` already uses today (`scripts/lib/
tracker-migrate-reverse.sh:24` — "`Unblocks ← inverse of Blockers across
the dataset (pass 2)`").

If a per-entry edit sets `Blockers: BD-061` on `BD-062.md`, the next TOC
rebuild emits `Unblocks: BD-062` into `BD-061.md`. Hand-edits to
`Unblocks:` lines are tolerated but discarded on rebuild — `_rules.md`
documents this and Check 31 flags hand-edits that drift from the
computed value.

### 7.3 Why this matters for Graphify

Each per-entry file is one Pass-3 chunk. Within that chunk, the regex
`^Blockers: ([\w-]+(?:,\s*[\w-]+)*)$` extracts typed edges with
confidence 1.0 (these are author-declared, not LLM-inferred). The same
applies to `File/Symbol:` lines pointing at code paths — these become
typed `(BD) → (code file)` edges that bridge the doc and code subgraphs.
The chunk's content (`Description:` body) is the only material Pass-3
needs to LLM-extract; the structural edges are already typed at
parse time.

In the monolithic shape, every BD's `Blockers:` line is buried inside
one giant chunk; the LLM has to disambiguate "which BD does this
`Blockers:` line belong to" from prose context. Per-entry shape makes
that disambiguation structural.

---

## 8. Read-path contract (success criterion #5)

### 8.1 The mental model

"Read BACKLOG" no longer means "read one file." It means "resolve a query
against the backlog stream." The query shape determines the path.

### 8.2 Common access patterns and their resolutions

| Access pattern | Old path | New path |
|---|---|---|
| Single-BD lookup (`Is BD-156 still open?`) | Read whole `BACKLOG.md`, grep for `BD-156` | Read `backlog/BD-156.md` directly |
| Status filter (`List all Open BDs`) | Read whole `BACKLOG.md`, grep `Status: Open` | Read `backlog/_toc.md`, filter rows |
| Blocker trace (`What unblocks when BD-061 closes?`) | Read whole `BACKLOG.md`, scan `Blockers: BD-061` | Grep `backlog/*.md` for `Blockers: BD-061`, or read `BD-061.md`'s computed `Unblocks:` |
| Full audit (`Read every BD`) | Read `BACKLOG.md` once | Read `backlog/_toc.md` + Read each `BD-NNN.md` as needed |
| New BD ID assignment (`Highest BD?`) | Grep `BACKLOG.md` for `^\*\*BD-` | Read `backlog/_toc.md` last row |
| Phase status check (`Is phase 3 complete?`) | Read whole `IMPLEMENTATION_PLAN.md`, find `## Phase 3` | Read `implementation-plan/phase-03.md` |

### 8.3 Agent prompt language

The current PM-CHAT.md instruction at line 119 (`BACKLOG.md | Direct read |
Small, changes frequently, must always be current`) is updated to:

```
backlog/      | Direct read (TOC + targeted entries) | One file per BD; TOC enumerates
implementation-plan/ | Direct read (TOC + current phase) | One file per phase
status/       | Direct read (latest entry) | One file per status date
changelog/    | Direct read (last entry only) | One file per version
```

The line edit is parallel to the v11 trinity Source-column extension
(BD-062): one structural property added to an existing table; no semantic
shift for unaffected rows. The change applies trinity-wide: `CLAUDE.md`,
`AGENTS.md`, `GEMINI.md`, both pack-root and `project-template/` (§11
enumerates the file set).

### 8.4 Tracker-mode read path

When the tracker is on, the same per-entry directory exists *as a mirror*.
The read path is identical from the agent's perspective — agents read
`backlog/BD-156.md` regardless of mode. The difference is that in
tracker mode the file carries a read-only mirror header (the existing
mechanism at `scripts/lib/tracker-mirror.sh:50-80`, retargeted to per-entry
files — §9).

The `tracker_agent_read_entry` function at `scripts/lib/tracker-agent-read.sh`
(BD-071 deliverable) already abstracts the mode-aware read. With the new
shape, its flat-file branch simplifies: instead of `grep BD-156 BACKLOG.md`,
it `cat backlog/BD-156.md`. The tracker-mode branch is unchanged (still
calls `provider_get` via `gh issue view`). This is a net simplification.

---

## 9. v11 tracker integration — file changes and round-trip property (success criterion #6)

### 9.1 Files that change

The tracker libs at `scripts/lib/` are retargeted from "write one big file"
to "write a directory of small files." Specific changes:

**`scripts/lib/tracker-mirror.sh` (105 lines today).**
Public API today: `tracker_mirror_header_emit`, `tracker_mirror_header_write
<path>`, `tracker_mirror_header_strip <path>`. The header was a leading
HTML-comment block on a single monolithic file.

After the change, the header still exists *per per-entry file*. Each
`backlog/BD-NNN.md` mirror carries the same header block at the top.
This preserves the "this is a read-only mirror" signal at the read
granularity — an agent that reads only `BD-156.md` immediately sees the
mirror header without having to also load any sibling.

API extensions:

```
tracker_mirror_header_write_dir <stream-dir> <backend-slug>
    Walks <stream-dir>/*.md (excluding _*.md), applies header_write
    to each. Idempotent. Calls per_entry_toc_rebuild as final step.

tracker_mirror_header_strip_dir <stream-dir>
    Walks <stream-dir>/*.md, applies header_strip to each.
```

The existing per-file helpers are preserved as building blocks.
Estimated growth: +30 lines (single-file helpers are unchanged; new
directory walkers are thin loops).

**`scripts/lib/tracker-migrate-forward.sh` (1,465 lines today).**
The forward migration today reads `BACKLOG.md` (one file) and creates
issues. After the change it reads `backlog/*.md` (excluding `_*.md`).
The 11-step algorithm at `scripts/lib/tracker-migrate-forward.sh:12-24`
is structurally unchanged — only step 1 (Read flat-file source-of-truth)
changes from "read one file" to "glob a directory." All other steps
(parse, mapping load, provider_create, link blockers, write mapping)
are agnostic.

Forward migration's final step (regenerate flat-file mirror) becomes
"regenerate the per-entry mirror directory" — a directory walk that
emits one file per issue. The mapping file is unchanged
(`.pack-tracker/id-map.json`).

Estimated diff: ~80 lines added (directory walk + per-entry file write),
~30 lines removed (single-file emit). Net ~+50.

**`scripts/lib/tracker-migrate-reverse.sh` (954 lines today).**
The reverse migration today emits `BACKLOG.md`, `IMPLEMENTATION-PLAN.md`,
`STATUS.md`, `CHANGELOG.md` (4 monolithic files). After the change it
emits 4 directories. The 9-step algorithm at `scripts/lib/
tracker-migrate-reverse.sh:17-37` is structurally unchanged — only
the emit phase (steps 4-7) changes from "emit file" to "emit
directory of files plus `_toc.md`."

Sidecar emission (V1 §6.6, separate file) is unchanged — the sidecar is
a single file by design and stays so.

Header-strip step (step 8) changes from "strip header from 4 files" to
"strip header from 4 directories of files." The new
`tracker_mirror_header_strip_dir` helper handles the iteration.

Estimated diff: ~120 lines added, ~40 lines removed. Net ~+80.

**`scripts/pack-tracker.sh` verb dispatcher.** No change to the verb
surface (`init` / `status` / `disable` / `mirror-rebuild` / etc.) —
the verbs are mode-agnostic; only the under-the-hood implementations
change.

### 9.2 Forward + reverse round-trip determinism

BD-068 (`BACKLOG.md:147-159`) established the round-trip property:
forward → reverse → forward produces a byte-equivalent tracker
create-call signature. This property must hold under the new shape.

**New property statement:** Given a `backlog/` directory at state S0:
forward(S0) → tracker issues → reverse → `backlog/` at S1; then S1 ==
S0 modulo (a) the mirror-header timestamp on each file, (b) the
`Last regenerated` timestamp in `_toc.md`. The set of files in S0 and
S1 is identical (same filenames, same count, same `_toc.md` row set).

Equivalent fixture coverage: extend the BD-068 fixtures at
`scripts/tests/fixtures/roundtrip/bd-v11.0/` (currently 3 entries) to
also include a `backlog/` directory shape with 3 per-entry files +
seed `_rules.md` + `_toc.md`. The fixture additions are mechanical and
fit in the existing BD-068 test harness.

**Whitespace tolerance** (the BD-068 property at `BACKLOG.md:148-158`)
is preserved — round-trip determinism is whitespace-tolerant in the
per-file comparison just as it was in the monolithic comparison.

### 9.3 Mirror cadence

Three triggers, listed in priority order:

1. **Eager refresh on tracker write** — when forward migration creates
   or updates an issue, the matching `backlog/BD-NNN.md` is rewritten
   in the same operation, the same way the monolithic mirror was
   rewritten today (forward migration step 10 at
   `scripts/lib/tracker-migrate-forward.sh:23`). No deferred work.
2. **`pack tracker mirror-rebuild`** — explicit, on-demand full
   regeneration. Verb already exists (`scripts/pack-tracker.sh:17-19`);
   the implementation walks the issue set and writes the per-entry
   directory from scratch. Useful after `gh` rate-limit storms or
   after an out-of-band issue edit through the GH web UI.
3. **`/pack-startup` and `/pm-startup` — detect-only** — Step 4 reads
   the mapping file mtime + the directory mtime; if the directory is
   older than the mapping (stale mirror), the startup summary surfaces
   a `Mirror: stale (last rebuild 3d ago, M issues edited since)`
   line, mirroring the RAG-line shape at
   `project-template/skills/pm-startup/SKILL.md:198`. **No auto-rebuild
   in startup** — same posture as Graphify's `/pack-startup`
   detect-only stance recommended at
   `RESEARCH-GRAPHIFY-SYNTHESIS.md:57`.

### 9.4 The reverse-from-tracker case

`pack tracker disable` runs `tracker_migrate_reverse_run`. Today it
produces 4 monolithic files. Under the new shape it produces 4
directories. After `disable`, the project is back in flat-file mode
with the per-entry shape preserved — this is the brief's required
property ("reverse must reconstruct the per-entry directory, not a
monolithic file").

---

## 10. Future-tracker abstraction (success criterion #7)

### 10.1 The provider boundary stays where it is

The TrackerProvider abstraction at `scripts/lib/tracker-provider.sh`
(BD-060) exposes 18 operations over an abstract `Issue` shape. The new
per-entry shape does not touch the provider boundary — the mirror /
migration libs (which now read/write per-entry files) are *consumers*
of the provider, not extensions of it.

A future Forgejo / Linear / Jira backend (per `OPTIONAL-FEATURES.md:127-132`
and the BD-060 design) registers via `scripts/lib/tracker-provider-<name>.sh`
implementing the same 18-op contract. The per-entry mirror libs use
`provider_create` / `provider_get` / `provider_list` exactly as they do
today — they don't know which backend is bound.

### 10.2 What the per-entry shape adds to the abstraction

One small abstraction: a stream-name registry. The 4 streams (backlog,
implementation-plan, status, changelog) each correspond to a different
issue shape (BD vs phase epic vs status note vs version note). The
mapping today is implicit in `tracker-migrate-forward.sh` step 4 (BD
entries) and step 5 (phase epics) per `scripts/lib/tracker-migrate-
forward.sh:18-20`.

The change formalizes this as a small table at the top of
`scripts/lib/tracker-migrate-forward.sh`:

```
declare -rA PACK_PER_ENTRY_STREAMS=(
    [backlog]="BD work-item form, issue type=bd-entry"
    [implementation-plan]="phase epic form, issue type=phase-epic"
    [status]="status form (new in v11.x), issue type=status-entry"
    [changelog]="version form (new in v11.x), issue type=changelog-entry"
)
```

Adding STATUS and CHANGELOG as full tracker types is **optional** —
the brief's required shape says STATUS and CHANGELOG get per-entry
files for flat-file value, even if the tracker only round-trips
BACKLOG and IMPLEMENTATION_PLAN. The skeleton emission step
(`tracker-migrate-reverse.sh` step 7 at `:34`) acknowledges this:
CHANGELOG today is a "skeleton" emit. Per-entry shape doesn't change
that property — just changes the emit shape.

### 10.3 Capability surface

Existing capabilities at `scripts/lib/tracker-provider.sh` (V1 §2.7.2)
are unchanged. No new capability flag is needed for the per-entry
shape, because the per-entry shape is a *flat-file* concern (under the
provider abstraction, not over it). A backend that supports the
TrackerProvider 18-op contract automatically works with the per-entry
shape — the change is local to the mirror / migration libs above the
provider.

---

## 11. Graphify (v12) compatibility (success criterion #8)

### 11.1 Concrete improvement over monolithic

Pass 3 of Graphify (`RESEARCH-GRAPHIFY-SYNTHESIS.md:26`) is the
LLM-extraction pass. It chunks documents and infers `INFERRED` edges
between extracted concepts.

In the **monolithic** shape, `BACKLOG.md` is a single document. Graphify
chunks it (default chunk size in Pass 3 is on the order of 1-2KB per
chunk per `RESEARCH-GRAPHIFY-EXTERNAL.md` §5-6 cross-referenced in the
synthesis). At 3,556 lines / ~90KB, the file produces ~45-90 chunks.
The LLM sees each chunk in isolation and must reconstruct
"chunk-N belongs to BD-091" from prose context. Cross-BD references
(`Blockers: BD-061` inside BD-091's chunk) become `INFERRED` edges with
the discrete confidence buckets at `RESEARCH-GRAPHIFY-SYNTHESIS.md:26`
(0.95/0.85/0.75/0.65/0.55).

In the **per-entry** shape, `backlog/BD-091.md` is one document. Graphify
treats it as a single node. The chunker emits ≤1 chunk for the entry
body (entries are 12-50 lines / <1KB). The structural fields
(`Status:`, `Type:`, `Blockers:`, `Unblocks:`, `File/Symbol:`) are
extractable by regex *before* Pass 3 even runs — they're tagged
`EXTRACTED` (confidence 1.0, the same tier as Pass-1 tree-sitter edges
per `RESEARCH-GRAPHIFY-SYNTHESIS.md:25`).

### 11.2 Edge derivations

Concrete edge set, per-entry to per-entry:

| Edge type | Source | Confidence | Provenance |
|---|---|---|---|
| `(BD-A) blocks (BD-B)` | `BD-A.md` says `Unblocks: BD-B`; or `BD-B.md` says `Blockers: BD-A` | 1.0 | EXTRACTED |
| `(BD-A) references (file F)` | `BD-A.md` `File/Symbol: F` | 1.0 | EXTRACTED |
| `(BD-A) shipped-in (vN.M)` | `BD-A.md` `Resolved:` field + `changelog/vN.M.md` cross-cites `BD-A` | 1.0 | EXTRACTED |
| `(BD-A) in-phase (phase-NN)` | `phase-NN.md` lists `BD-A` as a deliverable | 1.0 | EXTRACTED |
| `(BD-A) semantic-similar-to (BD-B)` | LLM Pass-3 over Description bodies | 0.55-0.85 | INFERRED |

The first four edge classes are **purely structural** — they're
derivable without an LLM. Only the last (semantic similarity) needs
Pass 3. Compare to the monolithic shape, where every edge requires
the LLM to first segment the file into entries.

### 11.3 Token-cost trace

For the agent-side cost (which is the cost Graphify is built to reduce
per `RESEARCH-GRAPHIFY-SYNTHESIS.md:32-38`):

- **Monolithic, no Graphify:** "What blocks BD-091?" → Read 3,556-line
  BACKLOG.md → ~22,500 tokens. Agent extracts blocker line by reading
  the whole file.
- **Monolithic, with Graphify:** Pass-3 subgraph reply on "BD-091" →
  ~300 tokens (article's claim). Real-world 5-10× on pure code per
  the synthesis range.
- **Per-entry, no Graphify:** Read `backlog/BD-091.md` directly →
  ~250 tokens (one 30-line entry).
- **Per-entry, with Graphify:** Subgraph reply for "BD-091" + 2 hops →
  still ~300 tokens (Graphify's reply size is independent of source
  shape).

The per-entry shape captures most of Graphify's savings *without*
Graphify, for this access pattern. Graphify's marginal value is in the
N-hop blocker-graph traversal — "what closes when BD-091 and its
unblocks all close?" That's where the graph index pays for itself even
under per-entry shape.

### 11.4 Compatibility, not dependency

Per the brief, Graphify is deferred to v12 (`RESEARCH-GRAPHIFY-SYNTHESIS.md:156-160`).
Per-entry shape does not depend on Graphify being installed; it just
plays nicer with Graphify if/when Graphify ships. The pack ships the
per-entry shape, the project stays usable without Graphify; if v12
adds the Graphify opt-in, the existing per-entry directories
immediately benefit without any structural retrofit.

---

## 12. Union of three concurrent consumers (success criterion #9)

The brief requires the design to satisfy three consumers simultaneously:
**standalone flat-file**, **v11 GH-issue tracker**, **future Graphify**.

### 12.1 Consumer A — Standalone flat-file

Needs:
- Per-edit churn cost is small (one file per BD).
- Per-read cost is targeted (one file per BD; TOC for list views).
- Git blame works per BD.
- Concurrent edits on different BDs auto-merge.
- The shape works without `gh`, without internet, without Graphify.

The proposed design satisfies all five. The directory of small files
*is* the source of truth in this mode. The `_rules.md` and `_toc.md`
mechanisms work entirely with `bash` + `python3` (both already pack
dependencies per `supporting-docs/DEPENDENCIES.md` baseline) — no
external tools required.

### 12.2 Consumer B — v11 GH-issue tracker

Needs:
- Forward migration: per-entry files → GH issues, semantically
  equivalent to the current monolithic-file migration.
- Reverse migration: GH issues → per-entry files (not a monolithic
  file).
- Mapping file format unchanged (`.pack-tracker/id-map.json`).
- Provider abstraction (`scripts/lib/tracker-provider.sh`) unchanged.
- Capability flags unchanged.
- BD-068 round-trip determinism property still holds.

The proposed design satisfies all six. Forward migration parses
per-entry files instead of paragraphs; reverse migration emits
per-entry files instead of paragraphs. The provider boundary doesn't
move. §9 enumerates the file changes.

### 12.3 Consumer C — Future Graphify (v12)

Needs:
- Per-entry granularity (one BD = one node).
- Structural fields (Blockers, Unblocks, File/Symbol) extractable
  before Pass-3 LLM extraction runs.
- The shape is a strict improvement over monolithic for Pass-3
  quality.

The proposed design satisfies all three. §11 enumerates the
edge derivations and the Pass-3 quality argument.

### 12.4 Conflicts and resolutions

Three places where two consumers might pull in opposite directions:

(a) **TOC freshness vs. mirror freshness.**
   - Standalone consumer wants the TOC eagerly regenerated on every
     entry edit.
   - Tracker consumer wants the mirror regenerated on every issue
     write.
   - **Resolution:** these are the same operation in tracker mode. The
     tracker mirror walk *is* the entry-rewrite walk, and the mirror
     walk's final step is `per_entry_toc_rebuild`. One pass, one
     timestamp source-of-truth (the mirror header's
     `Last regenerated` line; the TOC inherits from it).

(b) **`_rules.md` immutability vs. tracker round-trip.**
   - Standalone consumer wants `_rules.md` to be immutable forever
     (sentinel + validator).
   - Tracker consumer round-trips per-entry files, which now include
     `_rules.md` in the directory — does it round-trip?
   - **Resolution:** `_rules.md` and `_toc.md` are **excluded** from
     forward migration (no issue is created for them) and **excluded**
     from reverse migration's entry-file emit (the directory walker
     skips `_*.md`). They live alongside per-entry files but are not
     mirrored. The tracker is unaware of them. This is the same
     pattern as `.pack-tracker/` being gitignored — local infrastructure
     adjacent to source files, not part of the issue set.

(c) **Filename uniqueness vs. tracker label semantics.**
   - Standalone consumer wants `BD-001.md` to be the canonical
     filename for entry `BD-001` forever.
   - Tracker consumer assigns GH issue numbers separately
     (`gh-issue/N`); the mapping file binds them.
   - **Resolution:** filenames are the pack-id, not the tracker-id.
     The mapping file (already exists, `.pack-tracker/id-map.json`)
     handles the bidirectional bind. No conflict — the existing
     boundary is preserved.

Result: the design is **union-feasible**. The three consumers coexist
without duplication, contradiction, or special-case branches.

---

## 13. Edge cases, risks, and mitigations (success criterion #13)

### 13.1 Case-insensitive filesystems

macOS HFS+ (default) and Windows NTFS are case-insensitive by default.
The convention is "all uppercase prefix" — so `BD-001.md` and `bd-001.md`
are the same file on case-insensitive FS, distinct on case-sensitive
FS. **Risk:** A developer on Linux creates `bd-001.md`, the file ships
to a macOS reviewer's clone, which sees `BD-001.md` — both refer to
the same on-disk file but git history may diverge. **Mitigation:**
validator Check 31 rejects entries not matching `^[A-Z]{2}-\d{3}\.md$`.
This catches the case at first push and prevents accidental
case-divergent commits. Tested in CI on ubuntu-latest (case-sensitive) —
the validator can detect a `bd-001.md` and emit the failure even when
the runner doesn't observe collision.

### 13.2 Atomicity under concurrent edits

Two agents writing two different BD files: trivially safe (filesystem
atomicity per file). Two agents writing the **same** BD file: same
behavior as today — last-writer-wins, git rejects conflicting commits.
TOC writes: the idempotency property (§6.4 (a)) means concurrent TOC
writes produce identical content modulo timestamp; the merge driver
resolves cleanly.

The dangerous case is two agents writing two different BDs *and* both
running `per_entry_toc_rebuild` — both writes touch `_toc.md`. The
content section is identical (rebuild reads the same on-disk entry
set); the timestamp lines differ; merge driver picks latest. No
manual conflict.

### 13.3 Rename / archive / delete on a single entry

**Rename a BD ID** is forbidden — `BD-IDs are stable for the life of
the ID` is added as a `_rules.md` rule. Validator Check 31 enforces:
once `BD-NNN.md` has been committed, that filename cannot disappear.

**Archive a BD** is supported via Status flip (`Status: Cancelled` or
`Status: Deprecated`); the file stays. This matches the v11-dev
`BACKLOG.md` taxonomy (Cancelled 1, Deprecated 3).

**Delete a BD** is not supported. The pack-memory rule "BACKLOG.md
has no Resolved section" applies here — entries resolve in place. The
`_rules.md` carries the equivalent: entries archive in place.

If a BD was opened in error and must truly be removed: the procedure
is to flip Status to `Cancelled`, write a one-line `Resolution:`
explaining the error, and leave the file. The `_toc.md` row stays
with the `Cancelled` status. This is a deliberate ergonomic friction
to prevent revisionism.

### 13.4 Bulk status flips

A batch of BDs that all resolve together (e.g., the 14 BDs in v11.0's
final batch) need to flip from `Open` to `Resolved` in one logical
operation. Today this is a multi-line edit to one file. Under
per-entry shape, it's one edit per file plus one TOC regeneration.

**Mitigation:** ship a small helper `scripts/lib/per-entry-bulk.sh`
exposing:

```
per_entry_bulk_status_flip <stream-dir> <pattern> <new-status> [<resolution>]
```

This walks the matched files, updates the `Status:` line in each,
appends a `Resolved:` line where needed, and rebuilds the TOC. Pack
Chat / PM Chat calls it as a single bash invocation; the diff in git
is one commit touching N entry files + 1 TOC update.

### 13.5 Sub-issue lifecycle when parent BD closes

Today's tracker sub-issue model (BD-067 reverse) maps parent-child:
phase epic → its task BDs. When the parent phase is closed (`Status:
Complete`), the child BDs' Status fields are independent. Per-entry
shape doesn't change this — each child has its own file with its own
`Status:` line.

`_rules.md` for the implementation-plan stream documents the
expectation: closing a phase requires every BD listed in the phase's
deliverables to already be Resolved. Validator extension (Check 32,
optional, soft warn) checks the invariant and reports violations.

### 13.6 Files-deleted-but-still-in-TOC and vice versa

Covered by the TOC reconciler at §6.5. Both orphan classes are
detected and auto-fixed; the diff is surfaced in the startup summary.

### 13.7 Round-trip determinism under concurrent agent + GH-issue edits

This is the BD-068 property under per-entry shape. The risk: an agent
edits `backlog/BD-100.md` locally while another developer edits the
GH issue body for BD-100 through the web UI. On the next
`mirror-rebuild`, the local edit is overwritten by the tracker state
(the mirror is read-only-by-contract; the tracker is source-of-truth
in tracker mode).

**Mitigation:** existing mirror header at `scripts/lib/tracker-mirror.sh`
already warns "Direct edits will be overwritten. Edit via Pack Chat /
PM Chat." This header lands on every per-entry file in tracker mode.
Combined with the read-only declaration in `_rules.md` ("In tracker
mode, entry files are read-only mirrors"), an agent has two
independent signals before writing.

### 13.8 Large directories on slow filesystems

If a project accumulates 1,000 BDs over time, `backlog/` has 1,000
files. macOS APFS, Linux ext4, and Windows NTFS all handle 10k+
files per directory without performance issues. The TOC rebuild
becomes O(N) but at N=1,000 still completes in well under a second
(file scan + parse). No special handling needed up to the
~10k-file ceiling.

### 13.9 Tool reads of large directories

An agent's `Read` tool can read individual files efficiently; an
agent's `Glob` tool can list directory contents efficiently
(per Claude Code's tool surface; equivalent on Codex / Gemini).
Neither requires reading the union of all files at once. The
read-path contract (§8) is structured to avoid that anti-pattern.

### 13.10 Migration mid-batch state

A v11.0-to-v11.1 migration may interrupt mid-batch (network failure,
user Ctrl-C). The migrator framework at `scripts/lib/migrator-core.sh`
(BD-119) already handles partial-state via the `_MIGRATOR_STATE_DIR`
checkpoint convention (lines 108-115). The per-entry decomposer (§10)
plugs into this framework: each per-entry file emission is a
checkpoint boundary. Resuming mid-decompose is a re-run that skips
files already created. The framework's idempotency guarantee carries
through.

---

## 14. Migration story for existing v11.0 monolithic projects (success criterion #10)

### 14.1 The one-shot decomposer

New script: `scripts/decompose-monolithic.sh`. Idempotent. Reads
`BACKLOG.md`, `IMPLEMENTATION-PLAN.md` (if present), `STATUS.md`,
`CHANGELOG.md`; emits the per-entry directory tree; preserves the
file headers as content for the seed `_rules.md` is overwritten by
pack template; emits the seed `_toc.md`; deletes the monolithic
file only after the decomposed tree is verified.

Verification: each entry round-trips. Take an entry from `BACKLOG.md`,
decompose, recompose (via a separate `recompose-monolithic.sh`
verifier), compare to the original — byte-equal (modulo a normalized
trailing newline).

The script sources `scripts/lib/migrator-core.sh` and supplies the
adapter contract (`MIGRATOR_FROM_VERSION=11.0`,
`MIGRATOR_TO_VERSION=11.1`, etc.) per the BD-119 framework. This is
the same pattern the existing `scripts/migrate-v10-to-v11.sh` uses;
the per-entry decompose is a single migrator stage in the v11.0→v11.1
migrator.

### 14.2 Behavior if BACKLOG is mid-flight

Mid-flight = some BDs Open, some Resolved, some referencing BDs that
haven't been created yet. Today's `BACKLOG.md` at v11-dev tip is in
exactly this state (94 Resolved, 32 Open, 10 Deferred, 4 other).

The decomposer is **state-blind**: it emits one file per entry,
regardless of Status. The `Status:` field is just one of the entry's
required sections. No special-case logic.

### 14.3 Behavior if project is already in tracker mode

If `tracker.toml` says `mode.state = "tracker"`, the project has no
monolithic `BACKLOG.md` at root — only the mirror file (which is
read-only per the mirror header). The decomposer detects this and:

1. Reads the mirror file's content directly (it is per-entry-shaped
   text, just inside one file).
2. Decomposes it into the per-entry directory.
3. Marks each entry file with a fresh mirror header (via
   `tracker_mirror_header_write_dir`).
4. Updates the mapping file's schema version if needed (no schema
   change needed for this — mapping format is unchanged).

The tracker stays on. The user does not need to `pack tracker
disable` to migrate to per-entry shape, because both shapes are
mode-agnostic mirror outputs.

### 14.4 Rollback story

If the user runs the decomposer and decides to roll back:

1. The decomposer's last step was deleting the monolithic file. The
   backup of that file is in `_MIGRATOR_BACKUP_DIR` (per BD-119
   framework convention).
2. Restore the monolithic file from backup; delete the per-entry
   directory.
3. The migrator framework already provides this as
   `scripts/restore-from-backup.sh` (pack-internal, v10→v11 legacy
   per README:189).

### 14.5 The migrator stage shape

The decomposer is one stage in the v11.0→v11.1 migrator (or whatever
version target ships the change, §14). The BD-119 framework provides
the sequencer + public API (`scripts/lib/migrator-core.sh:6, :30, :119`).
The decomposer's stage hook:

- Preflight: detect monolithic file(s); detect tracker mode; record
  initial state.
- Backup: copy monolithic file(s) to `_MIGRATOR_BACKUP_DIR`.
- Dispatch: per-stream decompose.
- Report: emit per-stream entry count + status histogram into the
  truthful customization-preserve report (BD-088 deliverable —
  the report machinery already exists).

This is exactly the framework BD-119 set up. No new framework
mechanics required.

---

## 15. Trinity / per-CLI implications (success criterion #11)

### 15.1 Trinity files (pack-root + project-template, both surfaces)

Per the trinity rule (`CLAUDE.md:68-79`, repeated in `project-template/CLAUDE.md`
and the AGENTS / GEMINI mirrors): any rule change applies to all three
files unless the change is provably tool-specific. The per-entry shape
is *not* tool-specific — it's filesystem layout that all three CLIs
read identically. So:

**Parallel-shape edits in all six files:**
- `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` at pack root.
- `project-template/CLAUDE.md`, `AGENTS.md`, `GEMINI.md`.

The pack-root trinity and the project-template trinity each get a
parallel-shape edit, but the edit shapes differ because the two surfaces
already differ in structure (key-files list at pack-root vs Document-locations
table in project-template). Source: `ARCHITECTURE-PER-ENTRY-PACK-VS-CLIENT.md §5.2`.

#### 15.1a Pack-root trinity (CLAUDE.md / AGENTS.md / GEMINI.md at repo root)

Edit the key-files list at `CLAUDE.md:24-32` and the parallel locations in
`AGENTS.md` / `GEMINI.md`. Specific edits:

- `BACKLOG.md` → `backlog/`
- `CHANGELOG.md` → `changelog/`

Pack-root does not reference `STATUS.md` or `IMPLEMENTATION_PLAN.md`
(pack-self has no such streams; see §4.3), so no row exists to update for
those two streams.

#### 15.1b Project-template trinity (project-template/CLAUDE.md / AGENTS.md / GEMINI.md)

Edit the `## Document locations` table at `project-template/CLAUDE.md:221-225`
and the parallel rows in `project-template/AGENTS.md` and
`project-template/GEMINI.md`. All four stream rows update to directory
references:

- `BACKLOG.md` → `docs/project/backlog/`
- `STATUS.md` → `docs/project/status/`
- `IMPLEMENTATION_PLAN.md` → `docs/project/implementation-plan/`
- `CHANGELOG.md` → `docs/project/changelog/`

Also add a one-line pointer: `Document streams use per-entry files; see
`<stream>/_rules.md` for each stream's contract.`

The `## Project memory` section's rule "PM chat handles BACKLOG / STATUS /
CHANGELOG" stays semantically; the file references update to directory
references.

**Asymmetry note.** The asymmetry between pack-root and project-template
trinity edit shapes is structural, not a trinity-rule exemption. The
trinity rule (`CLAUDE.md:68-79`) applies *within* each surface (pack-root
or project-template), not across surfaces. Pack-root and project-template
trinity having different content is the existing pattern, not a new one.

**No trinity exemptions needed.** The per-entry shape is filesystem
layout (read by all three CLIs via the same Read tool semantics).
This contrasts with Graphify's *hook integration* which is per-CLI
asymmetric (`RESEARCH-GRAPHIFY-PACK-INTEGRATION.md:143-148`); the
per-entry shape has no equivalent per-CLI surface.

### 15.2 Per-CLI agent files

The 16 per-CLI agent files at `project-template/.claude/agents/`,
`.codex/agents/`, `.gemini/agents/` reference `BACKLOG.md` / `STATUS.md`
/ `CHANGELOG.md` in two contexts:

1. **Write-prohibition** ("Do not write to BACKLOG.md") — covered today by
   the trinity-replicated rule. The text "Do not write to BACKLOG.md"
   becomes "Do not write to `backlog/*.md`." Validator Check 27 (agent
   canonical-phrase compliance, lines 73-77) catches drift.
2. **Read-pattern** ("Read BACKLOG entries") — the prompt-language change
   BD-071 already established (`BACKLOG.md:190-203`) at v11.0. That work
   added "Read BACKLOG entries (resolve via trinity Document locations)"
   to 3 files. Under per-entry shape, the same phrasing works — the
   trinity Document-locations table now points to `backlog/` (directory),
   and the agent uses the §8.2 access patterns. No new prompt language
   needed.

### 15.3 Per-CLI skill files

The pack-help skill (`HELP-FRAGMENT-PACK.md` per validator Check 23
and Check 24) gets a new row for any new script (e.g.,
`scripts/decompose-monolithic.sh`, `scripts/lib/per-entry-toc.sh` if
exposed via a `pack-toc` verb — debatable; could stay internal). The
pm-startup skill (validator Check 28) gets a new Step 4-adjacent
substep for TOC reconciliation. The pack-startup skill mirrors.

These per-CLI skills are trinity-replicated (Check 28 pattern).
Same edit pattern as the existing v11 work — no new infrastructure.

### 15.4 HELP-FRAGMENT-* impact

- `HELP-FRAGMENT-PACK.md`: add row for any new top-level script (only
  `scripts/decompose-monolithic.sh` is top-level; the rest are
  pack-internal libs under `scripts/lib/`).
- `HELP-FRAGMENT-TRACKER.md` (canonical + per-project, byte-identical
  per Check 24): no new row — the tracker verbs surface is unchanged
  (the change is under the hood).
- `project-template/docs/pack/HELP-FRAGMENT.md`: corresponding entry
  for any project-side verb (none new in this proposal — the
  decomposer is one-shot at migration time).

### 15.5 Validator extensions

New checks:

- **Check 31 — per-entry shape compliance (new):**
  - Every `<stream>/` directory contains `_rules.md` and `_toc.md`.
  - `_rules.md` carries the `PACK-IMMUTABLE` sentinel with current
    pack version.
  - Every `<stream>/<entry>.md` matches the stream's filename regex
    (from `_rules.md`).
  - `_toc.md` rows are in sync with on-disk entry files (orphan
    detection).

  Check 31 iterates over the stream directories present at each audited
  path. On pack-self root, this is `backlog/` and `changelog/` (2 streams).
  On `project-template/docs/project/`, this is `backlog/`,
  `implementation-plan/`, `status/`, and `changelog/` (4 streams). Iteration
  is driven by directory existence; no target-specific branching in the
  check itself. Source: `ARCHITECTURE-PER-ENTRY-PACK-VS-CLIENT.md §6.1`.
- **Check 32 — phase-completion invariant (new, soft warn):**
  - When `phase-NN.md` has `State: Complete`, every BD it lists as
    a deliverable has `Status: Resolved`.
- **Check 29 extension — tracker-config schema:**
  - Add a per-entry-mode flag to the schema (e.g.,
    `[mode].entry_shape = "per-entry"` defaulting to `"per-entry"`
    in v11.1+).

The other 30 numbered checks plus 2 informational checks (per
`scripts/validate-pack.py` header lines 5-110) are **unchanged**.

### 15.6 Documentation surface

- `supporting-docs/METHODOLOGY.md` § Part 7 (BACKLOG procedures, today
  at `:130-138` for the agent write-prohibition) gets paragraph-level
  edits replacing `BACKLOG.md` with the per-entry directory phrasing.
  Same for `## Procedure 5-S` and the prompt-authoring guidance.
- `project-template/docs/pack/PM-CHAT.md` § File access strategy
  (lines 117-131) gets the table-row updates per §8.3.
- `supporting-docs/MIGRATION-vN-to-vM.md` (the migration guide for
  whichever version ships this) gets a new section enumerating the
  decompose step + rollback path + per-entry directory structure.

### 15.7 Explicit list of touched files

The structural change touches (with approximate edit counts):

Pack-root:
- `BACKLOG.md` — deleted (after decompose).
- `CHANGELOG.md` — deleted (after decompose).
- `backlog/` — new directory, 140 files at v11-dev tip.
- `changelog/` — new directory, ~10 version files.
- `status/` — new directory (if the pack adopts; the pack repo today
  has no STATUS.md, so this may be skipped pack-side).
- `implementation-plan/` — new directory (pack-side, pack uses
  `maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md` per the
  research-vs-product separation rule — see §4.3).
- `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` — trinity edits.
- `PACK-CHAT.md` — Pack Chat rule additions per §5.2 (d).
- `scripts/lib/tracker-mirror.sh` — +30 lines (directory walkers).
- `scripts/lib/tracker-migrate-forward.sh` — +50 lines net.
- `scripts/lib/tracker-migrate-reverse.sh` — +80 lines net.
- `scripts/lib/per-entry-toc.sh` — new, ~80 lines.
- `scripts/lib/per-entry-bulk.sh` — new, ~50 lines.
- `scripts/decompose-monolithic.sh` — new, ~150 lines (adapter on
  the BD-119 framework).
- `scripts/validate-pack.py` — +2 checks (~80 lines total).
- `HELP-FRAGMENT-PACK.md` — 1 row (decomposer).

Project-template:
- `project-template/docs/project/{backlog,implementation-plan,status,changelog}/` —
  new directories with seed `_rules.md` + seed `_toc.md`.
- `project-template/CLAUDE.md`, `AGENTS.md`, `GEMINI.md` — trinity edits.
- `project-template/docs/pack/PM-CHAT.md` — File access table + rule
  additions.
- `project-template/docs/pack/HELP-FRAGMENT.md` — possibly 1 row if a
  client-side verb is added (probably not).

Tests:
- `scripts/tests/test-per-entry-toc.sh` — new (~200 lines).
- `scripts/tests/test-decompose-monolithic.sh` — new (~150 lines).
- `scripts/tests/fixtures/per-entry/` — new fixture set.
- `scripts/tests/tracker-migrate-roundtrip-test.sh` — extend BD-068
  fixtures with per-entry shape.

---

## 16. Token-usage baseline and projected reduction (success criterion #12)

### 16.1 Methodology

Token counts approximated at 4 characters per token (Claude's
historical heuristic; also typical for English prose tokenization).
Source files measured at v11-dev tip (HEAD = `4d93862` at session
start).

Baseline files (`wc -l` from session bash):

- `BACKLOG.md`: 3,556 lines, ~90 KB → ~22,500 tokens.
- `CHANGELOG.md`: 590 lines, ~14 KB → ~3,500 tokens.
- `IMPLEMENTATION-PLAN.md` (pack-side at
  `maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md`, not measured
  here but cited as the source plan): roughly 2,000 lines (similar
  density), ~50 KB → ~12,500 tokens.

### 16.2 Three access patterns

**Pattern 1: Read one BD.**
- Old: Read `BACKLOG.md` (22,500 tokens).
- New: Read `backlog/BD-091.md` (~250 tokens for a 30-line entry).
- **Reduction: 90× for this pattern.**

**Pattern 2: List open BDs.**
- Old: Read `BACKLOG.md` (22,500 tokens), agent grep `Status: Open`.
- New: Read `backlog/_toc.md` (~140 rows × ~50 chars/row =
  7,000 chars = 1,750 tokens; plus the table header and counts line).
- **Reduction: ~13× for this pattern.**

**Pattern 3: Trace blockers from BD-091.**
- Old: Read `BACKLOG.md` (22,500 tokens), agent scans for
  `Blockers: BD-091` and recursively reads matched entries (already
  loaded).
- New: Grep `backlog/*.md` for `Blockers: BD-091` (a Glob+Grep tool
  call, ~0 tokens for tool calls; results return ~50-200 tokens for
  matched paths), then Read each matched file (~250 tokens each).
  For a typical BD with 3 unblocks: ~50 tokens for matches + 3 × 250
  = ~800 tokens.
- **Reduction: ~28× for this pattern.**

### 16.3 Geometric mean

The three patterns are not equally frequent. Empirical Pack Chat
session traffic (informal observation, not measured):

- Pattern 1 (single BD lookup): ~10× per session.
- Pattern 2 (list open BDs): ~3× per session.
- Pattern 3 (blocker trace): ~1-2× per session.

Weighted reduction across 14-15 lookups per session:
(10×90 + 3×13 + 2×28) / 15 = (900 + 39 + 56) / 15 = ~66× weighted
reduction.

Conservative estimate: **30-50× reduction on the common-case access
pattern set.** This is independent of Graphify and independent of
tracker mode (the same pattern applies in both flat-file and tracker
mode — tracker-mode mirror reads benefit identically).

### 16.4 Comparison with Graphify

Per `RESEARCH-GRAPHIFY-SYNTHESIS.md:32-38`:
- Graphify on pure-code repos: 5-10×.
- Graphify on mixed corpora: 50-70×.
- Graphify article claim: 71.5×.

The per-entry shape *for the BACKLOG access patterns above* delivers
comparable per-pattern token savings to Graphify, **without an LLM**,
**without a graph build**, **without a Pass-3 cost budget**. Graphify's
incremental value over per-entry shape is in the N-hop graph
traversals over the *whole* doc + code corpus, not the BD lookups
that dominate Pack Chat traffic.

This is the architectural argument that per-entry shape is the
correct foundation for v11.1, and Graphify's v12 case rests on
genuinely cross-cutting structural queries that even per-entry
shape can't make cheap (e.g., "every code symbol referenced by an
Open BD whose blockers all close").

---

## 17. Version targeting recommendation (success criterion #14)

### 17.1 Recommendation: v11.1 (minor)

Per `README.md:52-57`:

> Major versions (v9, v10, …) mark large additions or breaking
> changes. Minor versions (v9.0, v9.1, …) mark incremental
> improvements — doc updates, new templates, prompt and workflow
> refinements.

The per-entry shape **is** a breaking change at the file-layout level:
existing projects' `BACKLOG.md` etc. disappear and are replaced by
directories. A v10→v11-grade major-version case could be made.

**However:** the v11.0 BACKLOG / IMPLEMENTATION_PLAN / STATUS /
CHANGELOG shape has migrator infrastructure (BD-119 framework) that
already handles file-level layout changes idempotently with backup
and rollback. The per-entry decompose is exactly the kind of
operation the BD-119 framework was built for. From the user's
perspective the migration is one command (`pack init --update` or a
fast-follow `bash scripts/migrate-v11.0-to-v11.1.sh`), one report,
and the same agent commands work afterward.

That puts this change in the same risk bucket as v11.0's tracker
opt-in (BD-066) — a structurally significant feature that ships as
opt-in / automatic-migration and does not warrant a major bump.
Recommendation: **v11.1 minor**.

If the planner determines the surface is too broad for v11.1 (e.g.,
the validator-check additions plus migrator stage plus trinity edits
add up to more than ~15 BDs), consider splitting:

- **v11.1**: per-entry shape for BACKLOG and CHANGELOG only. STATUS
  and IMPLEMENTATION-PLAN remain monolithic.
- **v11.2**: STATUS and IMPLEMENTATION-PLAN per-entry; mirror lib
  retargets.
- **v11.3**: validator hardening + Graphify-readiness markers.

Or, alternative recommendation: **v12.0 major**, batched with the
Graphify opt-in, so the two structural changes ship together and the
v11.x line stays stable for projects that don't want either change.
This is the conservative pick.

The strongest case is **v11.1 minor, single batch**, on the
following reasoning:
1. The BD-119 framework was explicitly built for this kind of change.
2. The migrator infrastructure already exists; running it for
   per-entry is just one new stage.
3. Deferring to v12 ties this change to Graphify's six-week-old
   upstream churn (`RESEARCH-GRAPHIFY-SYNTHESIS.md:118-131`) — a
   coupling that adds risk to a change that doesn't need Graphify
   at all.
4. The per-entry shape **prepares** v12 for Graphify without
   committing to Graphify; if v12 defers Graphify another version,
   v11.1 still pays off independently.

### 17.2 Impact on already-Resolved BDs

The proposal touches v11.0-Resolved BDs in two ways:

**BD-067 (reverse migration sidecar):** the reverse migrator now emits
a directory rather than a monolithic file. The sidecar format itself
is unchanged. BD-067's Definition of Done (`BACKLOG.md:143-145`) is
preserved — the reverse operation still reconstructs flat-file shape
from tracker state; the shape is just per-entry now. BD-067 stays
`Resolved`. The change to `tracker-migrate-reverse.sh` is a v11.1
delta over the BD-067 implementation.

**BD-068 (round-trip test fixture):** the fixture must gain per-entry
shape coverage. BD-068's existing fixtures (`scripts/tests/fixtures/
roundtrip/bd-v11.0/`, `bd-v11.1/`, `bd-v11.2/`) are extended; BD-068
stays `Resolved` with a note in the resolution about the per-entry
extension.

**BD-066 (init wrapper):** no direct change. The `pack tracker init`
verb is unchanged at the surface; the migration it triggers now
emits per-entry directories. Stays `Resolved`.

**BD-069 (template-version dual carrier):** template versioning lives
in `<!-- template_version: bd-v11.0 -->` HTML comments inside each
issue body. Per-entry shape preserves the comment at the top of each
per-entry mirror file — same carrier, just inside many files now.
Stays `Resolved`.

### 17.3 New BDs this change would add

Target mapping (pack-self / client / both / infrastructure) for each BD-X
below is in `ARCHITECTURE-PER-ENTRY-PACK-VS-CLIENT.md §9` and §13. Counts:
1 pack-only, 4 both-asymmetric, 7 infrastructure, 0 client-only.

Approximate new BDs in v11.1 scope to ship per-entry:

- BD-X1: `_rules.md` + `_toc.md` design + seed templates per stream
  (~4 stream-files × 2 = 8 small files + 1 helper).
- BD-X2: `scripts/lib/per-entry-toc.sh` helper + tests.
- BD-X3: Trinity + PM-CHAT.md edits for new Document locations.
- BD-X4: `scripts/lib/tracker-mirror.sh` directory-walker extension
  + tests.
- BD-X5: `scripts/lib/tracker-migrate-forward.sh` per-entry refactor
  + extended round-trip fixtures (extends BD-068's fixture set).
- BD-X6: `scripts/lib/tracker-migrate-reverse.sh` per-entry refactor
  + sidecar adjustments.
- BD-X7: `scripts/decompose-monolithic.sh` migrator stage on the
  BD-119 framework + tests.
- BD-X8: `scripts/validate-pack.py` Check 31 + Check 32 + Check 29
  extension.
- BD-X9: `HELP-FRAGMENT-PACK.md` + `HELP-FRAGMENT.md` per-CLI skill
  updates.
- BD-X10: `supporting-docs/MIGRATION-v11.0-to-v11.1.md` + dry-run
  story + rollback documentation.
- BD-X11: `scripts/lib/per-entry-bulk.sh` for batch status flips
  (deferrable to v11.2 if scope tight).
- BD-X12: Pack-repo decompose (the pack's own BACKLOG.md +
  CHANGELOG.md) + commit-discipline-skill cross-link.

Estimated 10-12 BDs. Comparable in scope to v11.0's Phase B tracker
batch (BD-072..BD-082 was ~10 BDs by inspection of `BACKLOG.md` IDs).
Fits a minor-version batch.

### 17.4 Concrete decision deliverables

For the user to pick from:

- **(a) v11.1 single batch** — recommended. 10-12 BDs. Ships per-entry
  shape end-to-end including tracker round-trip. Independent of Graphify.
- **(b) v11.1 narrow + v11.2 wide** — ship BACKLOG/CHANGELOG only in
  v11.1, defer STATUS / IMPLEMENTATION-PLAN to v11.2. Lower per-batch
  risk; two batches.
- **(c) v12.0 batched with Graphify** — defer until Graphify is also
  ready; ship the layout + graph integration as one major bump.
  Highest scope, highest cohesion, longest delivery window.

The architect's preference is (a). The user / pack-planner makes the
final call.

---

## 18. Decision-ready summary table

Maps each of the brief's 14 success-criterion questions to the section
in this document that answers it.

| # | Success criterion | Section | Anchor |
|---|---|---|---|
| 1 | File naming, directory layout | §4 | File naming and directory layout (success criterion #1) |
| 2 | Rules file: contents + immutability | §5 | The `_rules.md` file — contents and immutability (success criterion #2) |
| 3 | TOC file: format, generation, conflicts | §6 | The `_toc.md` file — format, generation, conflict resolution (success criterion #3) |
| 4 | Cross-doc reference syntax | §7 | Cross-doc reference syntax (success criterion #4) |
| 5 | Read-path contract | §8 | Read-path contract (success criterion #5) |
| 6 | v11 tracker integration | §9 | v11 tracker integration — file changes and round-trip property (success criterion #6) |
| 7 | Future-tracker abstraction | §10 | Future-tracker abstraction (success criterion #7) |
| 8 | Graphify (v12) compatibility | §11 | Graphify (v12) compatibility (success criterion #8) |
| 9 | Union of tracker + Graphify + standalone | §12 | Union of three concurrent consumers (success criterion #9) |
| 10 | Migration story for v11.0 monolithic projects | §14 | Migration story for existing v11.0 monolithic projects (success criterion #10) |
| 11 | Trinity / per-CLI implications | §15 | Trinity / per-CLI implications (success criterion #11) |
| 12 | Token-usage baseline + projected reduction | §16 | Token-usage baseline and projected reduction (success criterion #12) |
| 13 | Edge cases and risks | §13 | Edge cases, risks, and mitigations (success criterion #13) |
| 14 | Version targeting recommendation | §17 | Version targeting recommendation (success criterion #14) |

---

## 19. Open questions for pack-planner / Pack Chat

These are *not* solutions; they're decisions the architect deliberately
leaves to planner / user adjudication, framed as questions:

1. **Pack-side vs client-side rollout timing.** The pack repo's own
   BACKLOG.md is 3,556 lines; client projects' BACKLOG.md files are
   typically smaller (10-200 entries). Does v11.1 dog-food the change
   on the pack repo first and ship client-side support as a
   fast-follow, or do both ship together?

   **Answered** in `ARCHITECTURE-PER-ENTRY-PACK-VS-CLIENT.md §8.2`:
   pack-self first within the same v11.1 batch, gated on Stage A signals
   (decomposer clean run + Validate Pack PASS + round-trip verifier +
   Pack Chat per-entry read shake-down).
2. **Pack-side STATUS / IMPLEMENTATION-PLAN.** The pack repo today
   has no `STATUS.md` and no root-level `IMPLEMENTATION_PLAN.md` (v11
   plans live in `maintenance-docs/v11-research/`). Does the pack
   repo grow these streams as part of v11.1, or stay on the existing
   "research artifacts in maintenance-docs/" model?

   **Answered** in `ARCHITECTURE-PER-ENTRY-PACK-VS-CLIENT.md §1.4`: No.
   Pack-self stays at 2 streams (backlog, changelog) in v11.1 and beyond
   unless a future architect pass revisits the rule.
3. **`_toc.md` exposed as a verb?** `pack toc rebuild` would be the
   natural surface. Or keep TOC rebuild entirely automatic (eager +
   startup-detect). Verb adds one surface to validate; no-verb adds
   nothing.
4. **Bulk-flip helper scope.** §13.4 sketches `per_entry_bulk_status_flip`.
   Does v11.1 ship this in BD-X11 or defer to v11.2 / on-demand?
   The pattern is small enough to be replaced with a one-liner
   `for f in backlog/BD-{156,157,158}.md; do sed -i 's/Status: Open/Status: Resolved/' "$f"; done`
   plus a TOC rebuild call.
5. **Sentinel line wording exactness.** §5.2(a) proposes the sentinel
   `<!-- PACK-IMMUTABLE: v11.1 — do not edit. Updates ship via pack
   migration. -->`. Is the wording right? Should the version reference
   point to the pack version that *introduced* the file (stable
   reference) or the pack version that *most recently updated* it
   (the migrator-touched reference)? Either works; the choice affects
   how validator Check 31 emits diagnostics.
6. **Pack-Chat / PM-Chat rule placement.** §5.2(d) puts the "do not
   edit `_rules.md`" rule in `PACK-CHAT.md` and `PM-CHAT.md`. Should
   it instead live in each `_rules.md` itself (self-describing) with
   PACK-CHAT.md only carrying a one-line cross-reference? Cleaner
   ownership; one extra cross-reference. Architect's leaning is
   self-describing.

---

## 20. Out-of-scope (deliberately)

Things the brief did *not* ask about but might come up; recorded so the
planner can decide whether to fold them in:

- A web/HTML index UI over the per-entry directory. Out of scope —
  agents read markdown directly; humans use git log / GitHub web UI.
- A CSV / JSON export of the TOC. Out of scope — the TOC is itself
  a tabular text doc; agents that need machine-readable can parse
  the markdown table.
- Per-entry frontmatter (YAML) instead of inline `Status:` lines.
  Out of scope per the brief's "preserve existing `BACKLOG.md` entry
  shape" implication. Could be revisited in v12 if frontmatter
  proves useful for SKILL-style tooling.

---

	