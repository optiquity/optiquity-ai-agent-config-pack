# ARCHITECTURE-BD-203 — Pack self-migration Phase 1 (Mode 1 → Mode 2)

**BD:** BD-203 — monolithic flat files → per-entry directory trees.
**Branch:** v11-dev · **HEAD at design:** `da304ca` · **Date:** 2026-06-04.
**Scope keyword:** `pack-only`. **Destructiveness:** this is the data-
destructive phase of the two-phase pack self-migration (BD-204 is not).
**Author role:** pack-architect (read-only; design doc only).

---

## 1. Summary / recommended design (lead)

The pack already SHIPS the entire machinery this BD needs, and that
machinery already treats the pack's own backlog/changelog as first-class
streams. `scripts/lib/per-entry/{_lib.sh,decompose.sh,mirror-generate.sh,
toc-regenerate.sh}` define `pack-backlog` and `pack-changelog` streams
whose canonical mirrors are exactly `pack-ops/BACKLOG.md` and
`pack-ops/CHANGELOG.md`; `scripts/validate-pack.py` Check 32/33/34 already
iterate a `STREAMS` table containing those two streams and already SKIP
gracefully while the trees are absent (today's state). **BD-203 is
therefore a wiring + content-extraction + verification task, NOT a
tooling-build task.** Do not write new decompose/regenerate code; reuse
the BD-164 helpers.

The recommended design, in dependency order:

1. **Two streams only** — `pack-backlog` (→ `/backlog/`) and
   `pack-changelog` (→ `/changelog/`). **Drop `/implementation-plan/`
   from BD-203 scope**: the pack has NO `IMPLEMENTATION-PLAN.md` monolith
   and the tooling defines no `pack-implementation-plan` stream
   (EEB-2, EEB-6). Including it would mean inventing a monolith to
   decompose — out of scope and unrealizable as phrased. Surface to user
   (§8).
2. **Author the `_intro.md` + supporting files BEFORE decompose** so that
   the regenerated mirror is byte-faithful to today's monolith — the
   section labels, intra-section prose, the v8 Resolved table, and the
   pre-`### vN.M` changelog history are NOT entries and MUST be carried in
   supporting files, or they are lost (EEB-7, EEB-8).
3. **Build + verify the trees and the round-trip FIRST; retire the hand-
   maintained monolith LAST**, gated on a proven-lossless round-trip
   (the destructive step, per binding constraint 1).
4. **Monolith disposition (OQ-1, HIGH bar): REPLACED in place by a
   regenerated mirror at the same path, NOT deleted.** The repo
   convention ("Per-entry trees vs mirrors") makes the monolith a
   regenerated mirror in Mode 2; deleting it would break `CLAUDE.md`,
   `README.md`, `PACK-AGENTS.md`, `PACK-CHAT.md`, and Check 32's mirror
   target, all of which name `pack-ops/BACKLOG.md`/`CHANGELOG.md` as the
   read-stable mirror. The user's "removes the monolith flat files"
   phrasing means *retire the HAND-MAINTAINED primary*, not *delete the
   file*. See §4.1.
5. **CI ripple is minimal**: Check 32/33/34 already exist and already
   target these streams; they flip from SKIP to ACTIVE the moment the
   trees land. The only new guard worth adding is a **lossless-bijection
   assertion** run once during the conversion commit (design §5; it is a
   one-shot verification, not a standing CI check — measure-then-bound
   says do not add a standing check the regenerator's idempotency already
   covers).

Net: small, mechanical, reuse-driven; the entire risk is concentrated in
the supporting-file authoring (step 2) and the lossless gate (step 3).

---

## 2. Current-state measurement (Empirical-Evidence Blocks summarized; full EEBs in §9)

| Fact | Evidence (full EEB) | Conclusion |
|---|---|---|
| Pack is fully monolithic; `/backlog/`,`/changelog/`,`/implementation-plan/` absent; no `tracker.toml` | EEB-1 | SUPPORTED |
| Per-entry tooling exists at `scripts/lib/per-entry/` (4 files) and defines `pack-backlog`+`pack-changelog` streams → `pack-ops/*.md` mirrors | EEB-2 | SUPPORTED |
| No `pack-implementation-plan` stream; no pack `IMPLEMENTATION-PLAN.md` monolith | EEB-2, EEB-6 | SUPPORTED |
| Client per-entry streams + `_rules.md` shipped at `project-template/docs/project/{backlog,implementation-plan,changelog}/` (reference shape) | EEB-3 | SUPPORTED |
| `validate-pack.py` Check 32/33/34 already iterate a `STREAMS` table with the two pack streams; SKIP when tree absent | EEB-4 | SUPPORTED |
| Decompose extracts all 185 BD entries content-faithfully (incl. BD-203 with correct back-pointer) | EEB-5 | SUPPORTED |
| BACKLOG has 4 H2 section labels + intra-section prose + a v8 Resolved TABLE (not entries) that decompose drops | EEB-7 | SUPPORTED |
| CHANGELOG v1–v7 are bare `## vN` blocks with `### New`/`### Updated` children — the `### vN.M` anchor does NOT match them → dropped unless carried in a supporting file; pack-changelog has no archive basename | EEB-8 | SUPPORTED |
| No duplicate BD IDs (per-entry filenames will not collide) | EEB-9 | SUPPORTED |
| Doc-vs-reality gap: `CLAUDE.md` ~ll.30/31/34 + README Repository Layout describe the trees as already existing | EEB-10 | SUPPORTED |

---

## 3. The per-entry mechanism — what exists and how it maps to BD-203

### 3.1 Helper contract (reuse, do not reinvent)

`scripts/lib/per-entry/_lib.sh` hard-codes a 5-stream table. Two are
pack-self (EEB-2):

```
pack-backlog    mirror=pack-ops/BACKLOG.md    entry-regex=^BD-[0-9]+\.md$
                support=_rules.md _intro.md _toc.md _v8-resolved-archive.md
                dir-suffix=backlog
pack-changelog  mirror=pack-ops/CHANGELOG.md  entry-regex=^v[0-9]+\.[0-9]+(-[a-z0-9-]+)?\.md$
                support=_rules.md _intro.md _toc.md
                dir-suffix=changelog
```

Public API (all sourced, bash 3.2 / BSD-clean):

- `per_entry_decompose <key> <mono_path> <stream_dir>` — splits the
  monolith into `<id>.md` files with a line-1 HTML-comment back-pointer.
- `per_entry_regenerate_mirror <key> <stream_dir> <mirror_path>` —
  concatenates `_intro.md` + entries (back-pointer stripped, `\n---\n\n`
  separated) + trailing supporting files (`_v8-resolved-archive.md` for
  pack-backlog) into the mirror; divergence-routes on hand-edits.
- `per_entry_regenerate_toc <key> <stream_dir>` — regenerates `_toc.md`.

The decompose drops (a) pre-first-anchor preamble (→ `_intro.md`), (b)
section-break lines and the non-anchor content between them (→ supporting
files), keeping only the byte-identical entry spans. The mirror generator
re-injects `_intro.md` and the trailing supporting files. **Round-trip
byte-identity holds only when every non-entry byte of today's monolith is
captured in a supporting file the generator re-emits** — that is the whole
design problem of BD-203 (§4.3).

### 3.2 Reference shape — the client streams

`project-template/docs/project/{backlog,changelog,implementation-plan}/`
each ship `_rules.md` + `_intro.md` (changelog also `_format.md`)
(EEB-3). These are the pack-shipped canonical templates and the exact
shape the pack-self `_rules.md`/`_intro.md` must follow — same
`## Supporting files` section the `_lib.sh` awk parser reads at runtime
(`pe_supporting_files_admitted`). The pack-self streams are the
*pack-internal* analog (separate artifact, separate audience per
`pack-project-separation-of-concerns` — the pack `_rules.md` speaks of
BD entries + `pack-ops/` mirrors, not TD entries).

---

## 4. Resolution of the six open design questions

### 4.1 OQ-1 — Monolith disposition (HIGH bar; destructive; boundary with shipped convention)

**Decision: the hand-maintained PRIMARY is RETIRED and REPLACED IN PLACE
by a regenerated mirror at the same path. The file is NOT deleted.**

Challenge of the user's "removes the monolith flat files" phrasing
(`preliminary-triage-architect-challenge`, HIGH bar because this is
destructive and sits on the boundary with the shipped per-entry
convention):

- The repo convention is explicit (CLAUDE.md `## Pack memory` → "Per-entry
  trees vs mirrors"): in flat-file mode the monolithic `BACKLOG.md`/
  `CHANGELOG.md` "are regenerated mirrors — read-stable but never source
  of truth." A mirror by definition continues to EXIST at its canonical
  path; "removed" cannot mean "deleted" without contradicting the
  convention.
- Deleting the files would break four PM-only surfaces that name them as
  the read-stable mirror — `CLAUDE.md` ll.30–34, `README.md` Repository
  Layout ll.262/280–281, `PACK-AGENTS.md` Files list (BACKLOG.md /
  CHANGELOG.md "(regenerated mirror; per-entry source at …)"),
  `PACK-CHAT.md` File-access table — AND Check 32's `mirror_rel`
  comparison target. Per binding constraint 4, the trinity stays
  untouched; that constraint is only coherent if the mirror file persists.
- The destructive act is therefore: **the file stops being hand-edited and
  starts being generated.** Concretely the conversion commit (a) builds
  the trees, (b) regenerates `pack-ops/BACKLOG.md`/`CHANGELOG.md` from the
  trees, (c) the regenerated content REPLACES the hand-maintained content
  at the same path. From that commit forward, edits flow through the
  per-entry files and the mirror is regenerated — the de-facto SSOT moves
  from the monolith to the tree.

This is the "likely reading" the prompt anticipated, now confirmed against
the convention and the four naming surfaces.

### 4.2 OQ-2 — Reuse vs new tooling

**Reuse. No new tooling.** The `pack-backlog`/`pack-changelog` streams,
their mirrors, their entry regexes, the `_v8-resolved-archive.md`
supporting-file slot, and Check 32/33/34 already exist and already point
at the pack (EEB-2, EEB-4). The empirical round-trip already runs the
unmodified helpers against the live `pack-ops/BACKLOG.md` and extracts all
185 entries (EEB-5). BD-203 needs: author the supporting files, run the
existing decompose, run the existing regenerator, verify, retire the
hand-maintained primary. The ONLY tooling question is *invocation wiring*:
there is no pack-self driver that calls these helpers today (the migrator
calls them for the project side only). BD-203 may add a thin pack-side
invocation (e.g., a `pack-tracker.sh mirror-rebuild` pack-self path, or a
small `scripts/lib/per-entry/`-driving wrapper) — that is a planner-level
mechanical decision, sized small, NOT a reinvention.

### 4.3 OQ-3 — `_rules.md` per-stream contracts

Each pack stream needs `_rules.md` declaring the Mode-dependent SSOT
contract, mirroring the client streams' `_rules.md` shape (EEB-3) but with
pack-internal audience/vocabulary. Required content per stream (the
`_lib.sh` awk parser hard-requires a `## Supporting files` bullet list —
that section is load-bearing, not prose):

- **Mode-dependent SSOT clause** — flat-file mode (current): the tree is
  SSOT, `pack-ops/BACKLOG.md`/`CHANGELOG.md` is the regenerated mirror;
  tracker mode (post-BD-204): tracker is SSOT, both regenerated.
- **Filename regex** — `^BD-[0-9]+\.md$` (backlog) /
  `^v[0-9]+\.[0-9]+(-[a-z0-9-]+)?\.md$` (changelog).
- **Lifecycle states admitted** — backlog: `Open` / `Resolved` /
  `Deferred` (no separate Resolved section — entries resolve in place per
  the `pack-ops/BACKLOG.md` convention).
- **`## Supporting files` list** — backlog: `_rules.md _intro.md _toc.md
  _v8-resolved-archive.md`; changelog: `_rules.md _intro.md _toc.md`
  (PLUS a new archive basename — see §4.5 changelog gap).
- **Write-authority pointer** — PM-only per `PACK-AGENTS.md` (the
  `/backlog/`,`/changelog/` directories are already on the PM-only
  Directories list).

These `_rules.md` files become PM-only pack-shipped supporting files
(updated on version bump). The decompose/regenerate read them at runtime
only for the supporting-file basename list.

### 4.4 OQ-4 — Verification design (load-bearing; gates the destructive step)

The destructive monolith-retirement is gated on a **proven-lossless
round-trip**. The gate is a three-part assertion run during the conversion
work, BEFORE the hand-maintained primary is overwritten:

1. **Decompose → regenerate → byte-diff against a frozen copy of the
   ORIGINAL monolith.** Snapshot the current `pack-ops/BACKLOG.md`/
   `CHANGELOG.md` to a temp path; decompose into the trees; author the
   supporting files; regenerate the mirror to a SECOND temp path;
   `cmp -s ORIG REGEN`. **Byte-identical is the pass bar.** Any diff
   means a non-entry byte was not captured in a supporting file — fix the
   supporting file and re-run (do NOT widen tolerance; byte-identity is
   the contract the mirror generator already promises, EEB-5 path).
2. **Entry-count bijection.** `# of **BD-NNN — anchors in ORIG` ==
   `# of /backlog/BD-*.md files` (185, EEB-5/EEB-9); changelog: `# of
   ### vN.M anchors` == `# of /changelog/v*.md files` (7, EEB-8). No
   duplicate IDs (EEB-9) so the map is a true bijection.
3. **Content-faithfulness spot-audit** — the END-OF-BD full correctness
   audit (acceptance criteria) confirms a sample of entries (newest,
   oldest, a Deferred, a Resolved) are content-faithful and that the
   section labels / v8 table / v1-v7 history survive via supporting files.

The byte-diff (part 1) IS the lossless proof. It is run as a one-shot
verification in the conversion commit and is ALSO permanently enforced
going forward by the EXISTING Check 32 (the regenerated mirror must equal
what the generator produces from the tree). No NEW standing CI check is
required for losslessness — Check 32 already is it.

### 4.5 OQ-5 — Stream order + scope

- **Backlog and changelog convert in BD-203.** Order is independent;
  recommend backlog first (larger, exercises the v8-archive supporting
  slot), changelog second (exercises the v1-v7 gap, §4.6).
- **Implementation-plan is OUT of BD-203 scope** (EEB-6): no monolith
  exists, no stream defined. The pack's "implementation plan" lives as
  `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` + per-BD
  `PLAN-*.md` docs — a different artifact class (design records, not a
  tracked per-entry stream). Converting it would require (a) inventing a
  canonical `pack-ops/IMPLEMENTATION-PLAN.md` monolith and (b) adding a
  `pack-implementation-plan` stream to `_lib.sh` + the `STREAMS` table +
  Check 32 `known_supporting_for`. That is new scope, not dogfood-of-an-
  existing-feature. **Surface to user as out-of-scope (§8); do not solve.**
  Note: the BD-203 entry's Scope line names "implementation-plan"; this
  design flags that as unrealizable-as-phrased and recommends the user
  drop it from BD-203 (the `project_pack_self_migration_launch_gate`
  memory and BD-204 both speak only of backlog/changelog as the operative
  trees — the implementation-plan mention is a carryover).

### 4.6 OQ-6 — Validator / CI ripple (measure-then-bound)

Measured against the actual repo (EEB-4): Check 32/33/34 already iterate
the two pack streams and already SKIP-when-absent. The ripple:

- **No new standing check needed for losslessness** — Check 32 is the
  standing tree↔mirror byte-identity guard; it activates automatically
  when the trees land. Adding a second check would be the "widen to
  swallow" anti-pattern the rule forbids.
- **Check 33 (`_toc.md` in-sync)** activates → the conversion MUST
  generate `_toc.md` via `per_entry_regenerate_toc` and commit it, else
  Check 33 fails. Mechanical.
- **Check 34 (cross-reference integrity)** activates → every BD-NNN
  cross-reference inside an entry must resolve to an existing
  `/backlog/BD-NNN.md` (or be exempt per §11.3). MEASURE-THEN-BOUND
  ACTION FOR THE PLANNER/CODER: before the conversion commit, run Check 34
  against the projected tree and categorize every dangling BD reference as
  KEEP-and-exempt (legitimate historical/external ref) or FIX (typo /
  truly-missing). Size the exemption to the legitimate set only. (This
  design cannot pre-enumerate the dangling set without building the tree;
  the requirement is recorded as a binding pre-commit step.)
- **`test-fixtures/manifest.txt`** — the conversion commit touches
  `pack-ops/` (and adds `/backlog/`,`/changelog/`), a v11-surface, so the
  manifest must be regenerated in the same commit
  (`regenerate-manifest-v11-surface`).
- **The changelog v1-v7 gap requires a new supporting-file basename**
  (§4.6.1) — a one-line additive change to `_lib.sh` pack-changelog
  `support` list AND the Check 32 `known_supporting_for["pack-changelog"]`
  set AND the `STREAMS`/`enumerate-encoding-surfaces` lockstep. This is
  the only *code* edit to the helpers, and it is additive (a new admitted
  basename), not a rewrite.

#### 4.6.1 The changelog v1-v7 frozen-history gap (the real risk)

EEB-8: the changelog's v1–v7 entries are bare `## vN — date` blocks whose
children are `### New` / `### Updated`, NOT `### vN.M`. The pack-changelog
decompose anchors only on `### vN.M`, so v1–v7 (and the `## vN` grouping
headers for v8+) are non-entry content that decompose drops. The
pack-changelog stream has NO archive supporting-file basename to hold
them (only backlog has `_v8-resolved-archive.md`). Two design options for
the planner (this design states the constraint; the choice is a
planner/user call):

- **(A) Carry v1-v7 in `_intro.md`** (preamble re-emitted verbatim) — zero
  helper change, but conflates "intro" with "frozen history."
- **(B) Add a `_pre-v8-archive.md` (or `_vN-frozen-archive.md`)
  supporting basename to pack-changelog** mirroring the backlog v8 slot —
  one additive helper change (§4.6 bullet 5), cleaner separation,
  symmetric with backlog. Recommended, but flagged for user/planner
  confirmation because it is the one helper edit.

Whichever option: the byte-diff gate (§4.4 part 1) is the proof it worked.

---

## 5. The safe conversion design + ORDER

Per binding constraint 1 (proven-lossless + tested BEFORE the destructive
step) and constraint 2 (BD-203 is the data-destructive phase), the order
is: **build + verify, THEN retire.** Commit boundaries are a planner
decision; the dependency order is fixed:

1. **(non-destructive) Author the pack-self `_rules.md` + `_intro.md` for
   both streams**, plus the v8 backlog archive content and the chosen
   changelog frozen-history carrier (§4.6.1). Create empty `/backlog/`,
   `/changelog/` directories with these supporting files. Add the
   changelog archive basename to the helpers if option B (§4.6.1).
2. **(non-destructive) Snapshot ORIG** — freeze copies of today's
   `pack-ops/BACKLOG.md` / `CHANGELOG.md`.
3. **(non-destructive) Decompose** ORIG → per-entry files in the trees
   (existing helper). Generate `_toc.md` (existing helper).
4. **(non-destructive, GATE) Regenerate mirror to a TEMP path; byte-diff
   vs ORIG snapshot.** This is the lossless proof (§4.4). Iterate
   supporting files until `cmp -s` passes. Entry-count bijection +
   no-dupe checks (§4.4 parts 2/3). **Do not proceed past this gate until
   byte-identical.**
5. **(non-destructive) Run `validate-pack.py`** — Check 32/33/34 now
   ACTIVE and must pass; resolve Check 34 dangling-ref exemptions
   (§4.6 measure-then-bound).
6. **(DESTRUCTIVE — gated on step 4 passing) Replace the hand-maintained
   primary in place** by writing the regenerated mirror over
   `pack-ops/BACKLOG.md` / `CHANGELOG.md` (OQ-1: replace, not delete). At
   this point the de-facto SSOT moves to the trees. Regenerate
   `test-fixtures/manifest.txt`. Commit `pack-only`.
7. **(verification) END-OF-BD full correctness audit** (acceptance
   criteria) — losslessness re-confirmed, reality now matches the docs,
   validate-pack green.

The destructive step (6) is last and is gated on the byte-identical
round-trip (4) — a data-loss outcome is structurally prevented because the
ORIG snapshot is the diff oracle and the primary is only overwritten after
the regenerated content is proven byte-equal to it.

---

## 6. Validator / CI ripple (measure-then-bound, consolidated)

| Surface | State today (measured) | BD-203 action | Bound |
|---|---|---|---|
| Check 32 (mirror in-sync) | SKIPs (tree absent), EEB-4 | Activates; commit regenerated mirror | Existing — IS the lossless standing guard; no new check |
| Check 33 (`_toc.md` in-sync) | SKIPs | Activates; generate + commit `_toc.md` | Existing |
| Check 34 (cross-ref integrity) | SKIPs | Activates; exempt legitimate dangling refs, fix typos | Exemption sized to legitimate set only (KEEP); planner measures against built tree |
| `_lib.sh` pack-changelog `support` | `_rules.md _intro.md _toc.md` | +archive basename IF option B (§4.6.1) | Additive single basename; lockstep w/ Check 32 `known_supporting_for` + STREAMS comment |
| `test-fixtures/manifest.txt` | present | Regenerate in conversion commit | v11-surface rule |
| New standing CI check | n/a | NONE | measure-then-bound: do not add what Check 32 covers |

`enumerate-encoding-surfaces`: if the changelog archive basename is added,
the lockstep set is `_lib.sh` (PE pack-changelog support) +
`validate-pack.py` `known_supporting_for["pack-changelog"]` (l.3188) + the
`STREAMS` comment + any `test-validate-pack-checks-32-33-34.sh` fixture
that asserts the pack-changelog supporting set. All update in one commit.

---

## 7. Risks / sign-offs

- **R1 (HIGH) — changelog v1-v7 frozen-history loss.** Mitigation: §4.6.1
  carrier + §4.4 byte-diff gate. Sign-off: user picks option A vs B.
- **R2 (HIGH) — section labels / intra-section prose / v8 table loss in
  backlog.** The `## Active — v11 Scope` prose carries the live launch-gate
  text (EEB-7); the v8 Resolved TABLE is 30 historical rows. Mitigation:
  capture in `_intro.md` (preamble + section labels) and
  `_v8-resolved-archive.md` (v8 table); §4.4 byte-diff proves capture.
- **R3 (MED) — Check 34 dangling cross-refs fail CI on activation.**
  Mitigation: §4.6 measure-then-bound exemption pass before the commit.
- **R4 (LOW) — invocation wiring choice (OQ-2).** A thin pack-self driver
  vs hand-invocation; planner-sized; no reinvention.
- **Destructive-step sign-off:** the user (or Pack Chat per
  `no-destructive-without-approval`) approves the commit that overwrites
  `pack-ops/BACKLOG.md`/`CHANGELOG.md`; that commit is gated on the §4.4
  byte-identical pass being demonstrated in the IMPL-REPORT.

---

## 8. Out-of-scope observations (surfaced, NOT solved)

1. **Implementation-plan stream (OQ-5).** No pack monolith, no stream
   defined (EEB-6). The BD-203 Scope line names it but it is unrealizable
   as phrased without inventing a monolith + a new stream. RECOMMEND the
   user strike "implementation-plan" from BD-203 scope (the launch-gate
   memory + BD-204 reference only backlog/changelog). NOT solved here.
2. **BD-204 boundary.** BD-204 (Mode 2→3, per-entry → GH Issues) does NOT
   remove the per-entry files — they remain as regenerated-from-tracker.
   BD-203 must leave the trees as the durable SSOT artifact BD-204 builds
   on; nothing in BD-203 should assume the trees are transient. BD-203
   does NOT create `tracker.toml` (that is BD-204). Out of scope here.
3. **CHANGELOG mirror header.** The pack `CHANGELOG.md` today has no
   `Last regenerated:` mirror header (it is hand-maintained, EEB-8); the
   tracker-mode staleness check reads that header. Whether the Mode-2
   regenerated mirror should gain one is a BD-204-adjacent question — not
   required for Mode-2 losslessness. Surfaced, not solved.
4. **`pack-project-separation`.** The pack-self `_rules.md`/`_intro.md` are
   SEPARATE artifacts from the client `project-template/docs/project/*`
   ones — author them pack-audience (BD entries, `pack-ops/` mirror), do
   NOT byte-copy the client templates (coincidental similarity is not a
   substitution license).

---

## 9. Empirical-Evidence Blocks

### EEB-1 — pack is fully monolithic; trees + tracker.toml absent
- **Command:** `ls -la backlog changelog implementation-plan tracker.toml`
  (from repo root).
- **Output (verbatim):** `ls: backlog: No such file or directory` /
  `ls: changelog: No such file or directory` /
  `ls: implementation-plan: No such file or directory` /
  `ls: tracker.toml: No such file or directory`.
- **HEAD/date:** `da304ca` / 2026-06-04.
- **Interpretation:** none of the three per-entry trees nor `tracker.toml`
  exist; pack is in Mode 1 (flat-file, hand-maintained).
- **Conclusion:** SUPPORTED.

### EEB-2 — per-entry tooling exists; defines pack-backlog/pack-changelog → pack-ops mirrors; no pack-implementation-plan stream
- **Command:** `ls scripts/lib/per-entry/` and read `_lib.sh` `pe__stream_attr`.
- **Output (verbatim):** `_lib.sh decompose.sh mirror-generate.sh
  toc-regenerate.sh`. `_lib.sh` cases: `pack-backlog) mirror→pack-ops/BACKLOG.md
  entry-regex→^BD-[0-9]+\.md$ support→_rules.md _intro.md _toc.md
  _v8-resolved-archive.md dir-suffix→backlog`; `pack-changelog)
  mirror→pack-ops/CHANGELOG.md entry-regex→^v[0-9]+\.[0-9]+(-[a-z0-9-]+)?\.md$
  support→_rules.md _intro.md _toc.md dir-suffix→changelog`.
  `PE_STREAM_KEYS="pack-backlog pack-changelog project-backlog
  project-implementation-plan project-changelog"` — NO `pack-implementation-plan`.
- **HEAD/date:** `da304ca` / 2026-06-04.
- **Interpretation:** the helpers already treat the pack backlog/changelog
  as first-class with the exact `pack-ops/*.md` mirror targets; there is no
  pack implementation-plan stream.
- **Conclusion:** SUPPORTED.

### EEB-3 — client per-entry streams + `_rules.md` (reference shape)
- **Command:** `grep -rl "_rules" project-template/` + `ls
  project-template/docs/project/{backlog,changelog,implementation-plan}/`.
- **Output (verbatim):** lists include
  `project-template/docs/project/{backlog,changelog,implementation-plan}/_rules.md`
  and `_intro.md`; changelog additionally `_format.md`. Directory listings
  show backlog `{_intro.md,_rules.md}`, changelog
  `{_format.md,_intro.md,_rules.md}`, implementation-plan
  `{_intro.md,_rules.md}` (no entries — canonical templates).
- **HEAD/date:** `da304ca` / 2026-06-04.
- **Interpretation:** the client streams are the pack-shipped reference
  shape for the pack-self `_rules.md`/`_intro.md` to mirror (separate
  audience).
- **Conclusion:** SUPPORTED.

### EEB-4 — Check 32/33/34 iterate the two pack streams; SKIP-when-absent
- **Command:** read `scripts/validate-pack.py` ll.297–301 (`STREAMS`) and
  ll.3191–3201 (Check 32 loop + SKIP branch).
- **Output (verbatim):** `STREAMS = [("pack-backlog","backlog",
  "pack-ops/BACKLOG.md", r"^BD-\d+\.md$"), ("pack-changelog","changelog",
  "pack-ops/CHANGELOG.md", r"^v\d+\.\d+(?:-[a-z0-9-]+)?\.md$")]`; loop:
  `if not stream_dir.is_dir(): ok(f"{stream_rel}/ — not present (skipping;
  pre-v11.0 client or pre-BD-102 dog-food pack-self …)"); continue`.
- **HEAD/date:** `da304ca` / 2026-06-04.
- **Interpretation:** the standing CI guards already target these streams
  and already SKIP cleanly today; they activate the moment the trees land.
- **Conclusion:** SUPPORTED.

### EEB-5 — decompose extracts all 185 BD entries content-faithfully
- **Command:** copied `pack-ops/BACKLOG.md` to a temp file, sourced the
  three helpers, ran `per_entry_decompose pack-backlog <tmp> <tmpdir>`.
- **Output (verbatim):** `per-entry decompose: wrote 185 entry file(s) to
  <tmpdir>/backlog`; `entry files written: 185`; spot file
  `<tmpdir>/backlog/BD-203.md` line 1
  `<!-- per-entry source: /backlog/BD-203.md; contract: /backlog/_rules.md -->`
  line 2 `**BD-203 — Pack self-migration Phase 1: …**`.
- **HEAD/date:** `da304ca` / 2026-06-04.
- **Interpretation:** the unmodified helper splits the live monolith into
  185 content-faithful per-entry files with correct back-pointers — the
  core conversion already works against real data.
- **Conclusion:** SUPPORTED.

### EEB-6 — no pack-side IMPLEMENTATION-PLAN monolith
- **Command:** `ls pack-ops/*PLAN*` + `find . -not -path "./project-template/*"
  -iname "*IMPLEMENTATION-PLAN*"`.
- **Output (verbatim):** `pack-ops/*PLAN*` → `no matches found`. The
  `find` hits are all under `maintenance-docs/` (archive/, v11-research/)
  and `test-fixtures/` — design records / fixtures, none at a canonical
  pack-ops mirror location.
- **HEAD/date:** `da304ca` / 2026-06-04.
- **Interpretation:** the pack has no tracked `IMPLEMENTATION-PLAN.md`
  monolith to decompose; the implementation-plan stream is out of scope
  (§4.5, §8.1).
- **Conclusion:** SUPPORTED.

### EEB-7 — BACKLOG has section labels + prose + v8 TABLE (non-entry content decompose drops)
- **Command:** `grep -nE '^## ' pack-ops/BACKLOG.md`; `grep -cE
  '^\| BD-[0-9]+ \|'`; `sed -n '23,30p'`.
- **Output (verbatim):** H2s at ll.9/23/3379/3652/4861 =
  `## How to use this file`, `## Active — v11 Scope`, `## Active — v10
  Scope`, `## Resolved — v8 (March 2026)`, `## Deferred`; 19 `| BD-0NN |`
  table rows under the v8 section; ll.23–30 = `## Active — v11 Scope`
  followed by the launch-surface prose ("The v11.0 implementation surface.
  53 BD entries …").
- **HEAD/date:** `da304ca` / 2026-06-04.
- **Interpretation:** section labels, intra-section prose, and the v8
  Resolved table are non-`**BD-NNN —` content the decompose drops; they
  must be carried in `_intro.md` + `_v8-resolved-archive.md` for the
  round-trip to be byte-faithful.
- **Conclusion:** SUPPORTED.

### EEB-8 — CHANGELOG v1-v7 bare-H2 history not matched by the vN.M anchor
- **Command:** `grep -nE '^## v|^### v'` + `sed -n '622,734p' | grep -nE
  '^## v|^### '`.
- **Output (verbatim):** `### vN.M` anchors present for v8.10/v8.9/v8.8/
  v9.3/v10.0/v10.0-post/v11.0 (7 total per `grep -cE '^### v[0-9]+\.[0-9]+'`
  = 7); v7→v1 are `## vN — date` with children `### New` / `### Updated` /
  `### Changed` / `### Included` (e.g. `## v7 — March 23, 2026` then
  `### New`). pack-changelog known support =
  `_rules.md _intro.md _toc.md` (no archive basename).
- **HEAD/date:** `da304ca` / 2026-06-04.
- **Interpretation:** the pack-changelog decompose (anchor `^### vN.M`)
  captures only the 7 `### vN.M` entries; v1–v7 bare-H2 history is dropped
  unless carried in a supporting file, and pack-changelog has no archive
  slot today → §4.6.1 carrier required.
- **Conclusion:** SUPPORTED.

### EEB-9 — no duplicate BD IDs
- **Command:** `grep -oE '^\*\*BD-[0-9]+ — ' pack-ops/BACKLOG.md |
  grep -oE 'BD-[0-9]+' | sort | uniq -d`.
- **Output (verbatim):** (empty — no lines).
- **HEAD/date:** `da304ca` / 2026-06-04.
- **Interpretation:** every BD ID is unique; per-entry filenames
  `/backlog/BD-NNN.md` will not collide; the entry↔file map is a bijection.
- **Conclusion:** SUPPORTED.

### EEB-10 — doc-vs-reality gap (docs describe trees as existing)
- **Command:** read `CLAUDE.md` ll.30/31/34 + `README.md` Repository
  Layout ll.185–188 / 280–281.
- **Output (verbatim):** CLAUDE.md l.34 `- /backlog/, /changelog/ —
  per-entry source-of-truth trees (read /backlog/_rules.md …)`;
  README l.280 `/backlog/  Pack per-entry tree (BD-NNN entries; source of
  truth for pack-ops/BACKLOG.md mirror)`, l.281 same for changelog.
- **HEAD/date:** `da304ca` / 2026-06-04.
- **Interpretation:** the governance docs already describe the post-Mode-2
  state; creating the trees (per binding constraint 4, without editing the
  docs) makes the docs accurate on their own.
- **Conclusion:** SUPPORTED.

---

## 10. Rules-Applied Verification Block

**READ-IN-FULL (per-file proof — each named doc Read directly via the Read tool):**
- `CLAUDE.md` — Read in full, 541 lines (l.1 `# CLAUDE.md — AI Agent Config
  Pack (Pack Repo)` … l.541 `testing (use /tmp clones …)`). COMPLIANT.
- `pack-ops/PACK-AGENTS.md` — Read in full, 226 lines (l.1 `# PACK-AGENTS.md
  — AI Agent Config Pack (Pack Repo)` … l.226 `… confirm staged files
  before any commit.`). COMPLIANT.
- `pack-ops/PACK-CHAT.md` — Read in full, 310 lines (l.1 `# PACK-CHAT.md —
  Pack Chat Startup and Operating Instructions` … l.310 `… not a hard-
  enforced step sequence.`). COMPLIANT.
- `project-template/CLAUDE.md` — Read in full, 456 lines (l.1 `# CLAUDE.md`
  … l.456 `… preserved across pack upgrades. -->`). COMPLIANT.
- BD-203 entry (`pack-ops/BACKLOG.md` ll.3330–3342) — Read directly. COMPLIANT.
- BD-204 entry (`pack-ops/BACKLOG.md` ll.3346–3359) — Read directly. COMPLIANT.
- `README.md` Repository Layout (ll.85–294) — Read directly. COMPLIANT.
- Curated memory (all Read directly, in full):
  `project_pack_self_migration_launch_gate.md` (49 ll.),
  `feedback_architect_planner_empirical_evidence.md` (15 ll.),
  `feedback_ci_guard_design_measure_then_bound.md` (15 ll.),
  `feedback_preliminary_triage_architect_challenge.md` (46 ll.),
  `feedback_pack_project_separation_of_concerns.md` (33 ll.),
  `feedback_scope_deliverables_to_the_ask.md` (35 ll.),
  `feedback_agent_output_rules_applied_block.md` (15 ll.),
  `feedback_agents_read_rule_docs_in_full.md` (97 ll.). All COMPLIANT.
- INVESTIGATE docs Read directly: `scripts/lib/per-entry/_lib.sh` (439 ll.),
  `decompose.sh` (288 ll.), `mirror-generate.sh` (337 ll.);
  `scripts/validate-pack.py` STREAMS + Check 32 region. COMPLIANT.

| Rule | Evidence (quoted/measured) | Conclusion |
|---|---|---|
| empirical-evidence-blocks [architect] | §9 EEB-1..EEB-10: each carries command + verbatim output + HEAD `da304ca` + date 2026-06-04 + interpretation + SUPPORTED. Live decompose run produced "wrote 185 entry file(s)". | COMPLIANT |
| ci-guard-measure-then-bound [architect] | Measured Check 32/33/34 already exist + SKIP (EEB-4); declared NO new standing check (Check 32 IS the lossless guard, §4.6); Check 34 exemption "sized to the legitimate set only … planner measures against built tree"; changelog archive basename additive + lockstep-bounded (§6). No allowlist widened without measurement. | COMPLIANT |
| preliminary-triage / architect-challenge (HIGH bar) | OQ-1 (§4.1) challenged the user's "removes" phrasing at HIGH bar against the convention + 4 naming surfaces + Check 32 target → REPLACE-in-place not delete. §4.5 challenged the BD-203 Scope line's "implementation-plan" as unrealizable (EEB-6) → surfaced. | COMPLIANT |
| separate-pack-ops-from-pack-product + pack-project-separation | Design touches only `pack-ops/`, pack-root `/backlog/`,`/changelog/`, `scripts/`, validators (§3,§5,§6); §8.4 mandates pack-audience `_rules.md`/`_intro.md` NOT byte-copied from `project-template/`. Zero `project-template/`/`supporting-docs/` edits proposed. | COMPLIANT |
| scope-deliverables-to-the-ask | Designed exactly BD-203 (Mode 1→2, backlog+changelog); implementation-plan + BD-204 (GH Issues) + tracker.toml + mirror-header explicitly OUT of scope and SURFACED not solved (§8). No edge-case sprawl. | COMPLIANT |
| rules-applied-verification-block (+ no-derivation) | This §10 table + the READ-IN-FULL per-file proof block above; every named doc attested COMPLIANT with direct-Read proof (line count / first+last line); no doc derived. Empty-evidence rows: none. | COMPLIANT |

**Output:** written to
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-203.md` (this file)
via the harness; markdown only; no source edits; no git state change.
