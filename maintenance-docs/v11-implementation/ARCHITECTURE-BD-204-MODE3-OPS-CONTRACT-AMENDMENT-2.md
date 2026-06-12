# ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT-2 — local-opt-in tracker mode (the repo's committed state is ALWAYS flat-file)

> **Agent:** pack-architect (fresh instance). **Mode:** DESIGN ONLY — repo read-only; the
> sole write is this amendment doc. **HEAD (verified):** `9127907`
> (`git rev-parse HEAD` → `9127907edd27a53e7504e5896365a8d01ff5561f`), branch `v11-dev`.
> Working tree: clean except untracked `maintenance-docs/` BD-204 design docs, untracked
> live `tracker.toml`, and the gitignored `.pack-tracker/` live Mode-3 state (untouched).
> **Date:** 2026-06-11 session.
>
> **What this amends.** `ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md` (556 lines) + its
> id-map placement amendment `ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT.md`
> (384 lines) + the pending commit recipes in `PLAN-BD-204-MODE3-OPS-CONTRACT.md`
> (451 lines), BEFORE the plan's two commits execute.
>
> **THE FOUR USER RULINGS (2026-06-12 — FIXED; this design realizes them, never
> relitigates them):**
> 1. **Pack surface:** the REPO's committed state is ALWAYS flat-file mode — every
>    checkout and every version bump ships flat-file. Tracker mode is a **LOCAL opt-in**;
>    a user who switches locally keeps that state across pulls and version bumps (sticky).
> 2. **Project surface, same UX promise:** first install defaults to flat-file tree mode;
>    the default state of the pack-shipped project-side assets is flat-file; a pack-version
>    upgrade/migration must NOT revert whatever mode the user had set.
> 3. **Well documented so users understand** — on both surfaces.
> 4. This SUPERSEDES the earlier-ratified tracker-mode rule 9 ("the regenerated tree,
>    `_toc.md`, `tracker.toml`, and id-map.json are committed artifacts") **with respect to
>    `tracker.toml`**: it is NOT a committed artifact. Recorded at §B10 (user authority —
>    not a contradiction).
>
> **Consumers:** the user (approval), Pack Chat (recipe-delta application + C-8 state
> commit + disposition pass), pack-coder ×2 (Commits 1–2 with the §B8 deltas),
> pack-reviewer (per-commit review), BD-206/BD-207 refresh (§B6 verbatim).

---

## B0. As-built verification + precision corrections to the calling prompt

Every mechanical claim below cites file + symbol (never line numbers). Three precision
corrections to names/states used in the calling prompt (substance unaffected):

1. **Symbol name.** The prompt's `tracker_config_path` is as-built
   `tracker_config_resolve_path` (`scripts/lib/tracker-config.sh`): pack arm
   `echo "$root/tracker.toml"`, client arm `echo "$root/docs/pack/tracker.toml"`.
   `grep -rn "tracker_config_path" scripts/` → zero hits; no such symbol exists. (The
   prior amendment carried the same mis-name; same correction applies there.)
2. **`tracker.toml` is currently UNTRACKED, not gitignored.** The prompt's "pulls never
   touch it (gitignored)" is the TARGET state this design creates, not the as-built state.

   > **Empirical-Evidence Block (live-file ignore state).**
   > `CMD`: `git check-ignore -v tracker.toml .pack-tracker/id-map.json`
   > `OUT`: `.gitignore:12:.pack-tracker/	.pack-tracker/id-map.json` — ONE line only;
   > `tracker.toml` produced no match. `git status --short` shows `?? tracker.toml`.
   > `AT`: HEAD `9127907`, 2026-06-11. `INTERP`: the id-map is ignored (via the
   > `.pack-tracker/` directory rule); the live `tracker.toml` is merely untracked — a
   > `git add -A` would stage it today. `CONCL`: SUPPORTED — the design must ADD the
   > ignore rule (§B1.2), and the rule must be **anchored** (`/tracker.toml`), see EE
   > below.
3. **Mode detection already realizes "absent = flat-file" (prompt verification request).**
   `tracker_mode()` (`scripts/lib/tracker-config.sh`) returns `flat-file` when the path
   is empty/missing, when the file fails to parse, when `mode.state != "tracker"`, or
   when `migration.forward_complete != "true"` — always rc=0, deliberately tolerant. A
   fresh checkout (no `tracker.toml`) is therefore flat-file BY CONSTRUCTION with zero
   code change. `tracker_init_run` → `_tracker_init_write_config`
   (`scripts/lib/tracker-init.sh`) writes the local file at
   `tracker_config_resolve_path`'s surface path — `pack tracker init` IS the local
   opt-in switch, also with zero code change.

> **Empirical-Evidence Block (anchored gitignore pattern is REQUIRED).**
> `CMD`: `git ls-files | grep "tracker.toml"`
> `OUT`: 5 committed files: `project-template/tracker.toml.project-example`,
> `tracker.toml.pack-example`, and THREE committed test fixtures named exactly
> `tracker.toml`: `scripts/tests/fixtures/roundtrip/bd-v11.0/tracker.toml`,
> `scripts/tests/fixtures/tracker-bd204-lossless/tracker.toml`,
> `scripts/tests/fixtures/tracker-migrate/tracker.toml`.
> `AT`: HEAD `9127907`, 2026-06-11. `INTERP`: an UNanchored `.gitignore` pattern
> `tracker.toml` matches at every depth and would ignore future fixture additions named
> `tracker.toml` (already-tracked files stay tracked, but new fixtures would need
> `git add -f` and `git status` would hide them). The rule MUST be `/tracker.toml`
> (root-anchored). `CONCL`: SUPPORTED.

---

## B1. Element 1 — Pack-surface mechanics

**Decision (realizing ruling 1):**

1. **`tracker.toml` is LOCAL + gitignored.** Add root-anchored `/tracker.toml` to the
   pack `.gitignore`, extending the existing "Tracker-mode local state (BD-061)" comment
   block (which already ignores `.pack-tracker/`). With the ignore in place: pulls never
   touch it (git never tracks it), version bumps never touch it (tags are commits; the
   file is outside every commit), and `git add -A` cannot accidentally stage it. The
   switch is sticky by construction. Commit placement: **Commit 2**, NOT C-8 — see §B4
   for the ordering argument (the ignore must land before the first state commit so
   `git add -A` at the state commit physically cannot stage the live file).
2. **The committed example stays the opt-in template.** `tracker.toml.pack-example`
   (pack root, §4-exempted root file per `pack-ops/BOUNDARY-DEFINITION.md`) remains the
   only committed tracker-config artifact. Its header gains the local-opt-in model text
   (§B5 surface 5). No change to its `migration.mapping_file` value — see §B2.
3. **`pack tracker init` creates the local file** — as-built, verified §B0 item 3. The
   `flat-file` default for absent file — as-built, verified §B0 item 3. Zero detection
   code changes.
4. **The committed per-entry tree (+ `_toc.md`) is the PUBLISHED flat-file SSOT.** In
   every checkout that has not opted in locally, the committed `/backlog/` tree IS
   flat-file source of truth, exactly per the existing flat-file contract. The
   locally-tracker-mode maintainer PUBLISHES tracker state into that committed tree by
   running `pack tracker tree-rebuild` (the ops-contract §2 verb, unchanged) and
   committing the regenerated tree + `_toc.md` through the normal commit gates. The
   write direction remains one-way (tracker → tree); the COMMIT is the publication act.
5. **Single-writing-authority caveat (documented, §B5 surfaces 1–3).** This model is
   safe for the pack because exactly ONE writing authority exists: the maintainer's
   Pack Chat on the machine that holds the local Mode-3 state. Everyone else reads the
   committed tree. The caveat text (semantic content fixed; coder words it):

   > While the maintainer's local state is tracker mode, the committed tree is a
   > PUBLISHED MIRROR of the tracker even though the repo's committed state is formally
   > flat-file. A second writer must NOT (a) hand-edit `/backlog/` entry files or
   > `_toc.md` and commit — the edit is silently CLOBBERED at the maintainer's next
   > tree-rebuild publication (the tracker, not the committed tree, is what the
   > maintainer's rebuild reads); nor (b) opt in to tracker mode on a second machine
   > and publish concurrently — two publishers race on the committed tree. Entry-state
   > changes route through the tracker (GH Issues) or through the maintainer. If the
   > single-writer assumption ever breaks, the safe degradation is `pack tracker
   > disable` back to flat-file, where the committed tree is directly writable again.

   This caveat is the pack-side analog of why the CLIENT default differs (§B6 R11):
   a client team has no single-writer guarantee, so the client's mode file is
   team-shared (committed) by default.

**Why this satisfies ruling 1 with the fewest moving parts:** mode = presence of one
local file; absence is already the flat-file default in every reader
(`tracker_mode()`); stickiness = gitignore; publication = the already-designed
tree-rebuild verb + the normal commit gate. No new state files, no new modes, no
environment variables, no per-checkout config protocol.

---

## B2. Element 2 — The id-map under the new model: **LOCAL** (stays at `.pack-tracker/id-map.json`)

**Decision: the pack id-map is NOT a committed artifact. It stays exactly where it
lives today — `.pack-tracker/id-map.json`, inside the wholesale-gitignored
`.pack-tracker/` directory, zero carve-outs.** The prior amendment's relocation to
`pack-ops/tracker-id-map.json` was conditioned on the id-map being committed ("the
prior amendment's placement stands IF committed" — calling prompt); with LOCAL decided,
that amendment's placement work is re-dispositioned below.

**Weighing (the prompt's two arms):**

- **Committed map (rejected).** The bootstrap benefit ("opted users start without a
  live scan") is real but tiny and already covered: the issue-body
  `<!-- pack-id: BD-NNN -->` markers are the source of truth and the forward migration
  skip-recovers the map from them (`scripts/lib/tracker-migrate-forward.sh` header:
  mapping file is the fast path; markers are the source of truth). The costs are
  structural: (a) a committed tracker-mode artifact contradicts the MODEL ruling 1 just
  established — "every checkout ships flat-file" is cleanest when the committed tree
  contains NOTHING that is tracker-mode state; (b) the committed map goes stale for
  every non-opted reader the moment the maintainer's local tracker moves between
  commits — a permanently-possibly-stale committed file invites exactly the
  convenience-view drift the repo's SSOT discipline exists to prevent; (c) it drags the
  prior amendment's full blast radius (surface-aware resolver, 11 recipe items, a
  BOUNDARY-DEFINITION C2-row rule extension) into Commit 2 for no operational gain.
- **Local map (adopted).** ONE uniform convention: ALL tracker-mode state is local
  (`tracker.toml` at root by tool mandate; everything else under `.pack-tracker/`).
  The map is regenerable; the pack has a single Mode-3 instance and a single writing
  authority (§B1.5), so multi-machine bootstrap is rare and has a tooling path
  (re-run forward; markers recover). Zero code changes, zero ignore-rule changes
  (`.gitignore` line `.pack-tracker/` already covers it), and the
  `migration.mapping_file = ".pack-tracker/id-map.json"` values + "(gitignored)"
  comments in BOTH example files are TRUE as written — no edits.

**Re-disposition of the prior amendment (`-AMENDMENT.md`), item by item:**

- §A1 (location `pack-ops/tracker-id-map.json`) + §A2 (rename) — **DISSOLVED with their
  premise.** The 2026-06-12 relocation decision was scoped to "the committed id-map";
  with the map local, there is no committed id-map to relocate. `.pack-tracker/`'s
  ignored-runtime semantics stay uniform with zero carve-outs — the user's
  no-`!negation` decision is honored MORE simply (nothing to negate).
- §A1's BOUNDARY-DEFINITION C2-row extension — **DROPPED** (no committed machine-state
  artifact is being placed; no matrix gap is exercised). `pack-ops/
  .boundary-pointer-manifest.txt` untouched.
- §A3 (R9 — client committed id-map at `docs/pack/tracker-id-map.json`) — **WITHDRAWN
  as written**; re-stated for BD-207 under the new model at §B6.
- §A4 (live-file migration mechanics + zero-window ordering + fail-loud no-fallback) —
  **MOOT**: no file moves. The Pack-Chat live-ops `cp`/repoint/delete sequence is
  cancelled.
- §A5 (blast radius: resolver + 10 code files + 15 test files + example values +
  validate-pack allowlists + `.gitignore` comment edit) — **CANCELLED in full.** Every
  group-(a) literal stays as-built and correct. The `scripts/validate-pack.py`
  basename-allowlist entry `"id-map.json": "Generated tracker-mode metadata (not in
  pack repo)"` stays TRUE (the map is not in the committed pack repo).
- §A5 OQ-B (decorative `migration.mapping_file` key; dead `tracker_mapping_file()`
  getter) — **MOOT as a decision-forcing item**: with no path change, option (i)
  (keep the key as documentation) is realized with ZERO edits. The dead getter
  (`scripts/lib/tracker-config.sh` `tracker_mapping_file()`, zero non-test callers)
  remains harmless as-built; no edit in these commits.
- PLAN OQ-1 (gitignore-vs-staging-text conflict for the id-map) — **CLOSED**: the
  §1.1/§1.3 staging lists drop BOTH `tracker.toml` AND `.pack-tracker/id-map.json`
  (§B5 delta 1/3). Authority: ruling 4 supersedes rule 9 for `tracker.toml`; the
  calling prompt explicitly delegates the id-map's committed-vs-local re-decision to
  this design (this section), so the id-map's removal from the staging list is a
  DECIDED-BY-DELEGATION consequence, not a second supersession.

---

## B3. Element 3 — Freshness keys, redesigned per mode

The ops-contract §2 put `last_tracker_write` / `last_tree_regen` in `tracker.toml` with
the rationale "Both survive fresh checkouts (committed artifacts)". That rationale
dissolves — a fresh checkout has NO `tracker.toml`. **The keys themselves survive
unchanged; only the rationale and the audience change.** Redesign:

1. **The keys stay in `tracker.toml` — now the LOCAL file.** `tracker_edit_entry`
   (`scripts/lib/tracker-edit.sh`) stamps `migration.last_tracker_write` on success;
   every pack tree materialization (the `tree_only` arm AND the full reverse path in
   `scripts/lib/tracker-migrate-reverse.sh`) stamps `migration.last_tree_regen` —
   exactly as the ops-contract §2 + PLAN §3.1 specify, zero mechanical delta. The keys
   survive pulls and version bumps because the LOCAL file is never touched by git
   (§B1.1) — the same stickiness that protects the mode protects the bookkeeping.
2. **Who consumes what, per mode:**
   - **The local tracker-mode operator** (the only actor with freshness questions):
     `pack tracker doctor` leg (d) pack arm compares `last_tracker_write` vs
     `last_tree_regen` and WARNs "tree is stale relative to tracker writes → Run:
     pack tracker tree-rebuild" — unchanged from the ops-contract §4.1 / PLAN §3.1,
     including the absent-key INFO tolerance (PLAN R4). The doctor runs only where a
     local `tracker.toml` exists (mode gate) — which is exactly where the keys live.
     Coherent by construction.
   - **A non-opted checkout** verifies NOTHING tracker-specific — and nothing needs
     verifying: with no local `tracker.toml` the checkout IS flat-file, the committed
     tree IS its SSOT, and tree integrity is already gated by Check 32′ (tree shape,
     `_rules.md`/`_toc.md` presence, filename + header conformance — all static,
     `scripts/validate-pack.py` `check_mirror_in_sync`). There is no committed
     freshness key for it to read, by design.
   - **Freshness of the PUBLISHED tree** (how stale is the committed tree relative to
     the maintainer's tracker?) is governed PROCEDURALLY, not by a committed marker:
     the §1.3/PLAN write-procedure rule "ALWAYS run `pack tracker tree-rebuild` before
     committing tree state" plus the doctor stale-tree WARN on the maintainer's
     machine. Git history is the publication record (the tree is as fresh as its last
     publication commit).
3. **What the tree-rebuild/commit procedure stamps: nothing committed.** Deliberately
   NO committed timestamp marker (no "Last regenerated:" header on `_toc.md`, no
   freshness sidecar): (a) the regenerated tree stays byte-deterministic for unchanged
   tracker state (the ops-contract §2 idempotence/fixed-point property — a timestamp
   would churn every regen and pollute diffs at the commit gate); (b) a committed
   timestamp is a convenience view that can drift — the class of artifact the SSOT
   discipline avoids; (c) Check 29's `Last regenerated:` machinery is the CLIENT
   monolith-mirror contract (`_check_mirror_staleness` walks `mirror.location_*`),
   N/A on the no-mirror pack surface (verified §B7).

**Architecture-doc supersession (recorded):** the ops-contract §2 sentence "Both
survive fresh checkouts (committed artifacts — the user requirement that killed
memory-as-home applies equally to mtime-as-signal)" is superseded by this section:
they survive AS LOCAL STATE on the opted machine; fresh checkouts are flat-file and
have no freshness question. The mtime-rejection half stands unchanged.

---

## B4. Element 4 — The C-8 state-commit shape (itemized)

The PLAN's OQ-2 ("when to commit the live `tracker.toml` + id-map + first regenerated
tree") is CLOSED by this amendment: the live `tracker.toml` is NEVER committed
(ruling 4); the id-map is NEVER committed (§B2). What remains of the state commit:

**C-8 state commit (Pack Chat, normal commit gates, after Commit 2 lands):**

| # | Content | In/Out | Why |
|---|---|---|---|
| 1 | Regenerated `/backlog/` per-entry tree + `/backlog/_toc.md` (output of the first real `pack tracker tree-rebuild`) | **IN** | The first PUBLICATION of tracker state into the committed flat-file SSOT (§B1.4). The diff is reviewed at the commit gate like any tree edit. |
| 2 | `tracker.toml` | **OUT** | Ruling 4. Gitignored by Commit 2 (item below); `git add -A` cannot stage it. |
| 3 | `.pack-tracker/id-map.json` (or any relocation of it) | **OUT** | §B2 — local; already ignored via `.pack-tracker/`. |
| 4 | `.gitignore` additions | **OUT — moved to Commit 2** | Ordering: the `/tracker.toml` ignore must exist BEFORE the state commit so the state commit's `git add -A && git status` physically cannot stage the live file. A rule edit also belongs in a reviewed coder commit, not a Pack-Chat state commit. See §B8 Commit-2 delta D2-6. |
| 5 | Doc edits | **OUT** | All doc surfaces land in Commit 1 (pack-chat-only set) or Commit 2 (pack-only set) per §B5; C-8 stays a pure state-publication commit. |
| 6 | `/changelog/` tree | **OUT** | Mode-invariant flat-file stream (ops-contract §1.2); the pack reverse emits no changelog. |
| 7 | `test-fixtures/manifest.txt` | **OUT (expected)** | C-8 touches only `/backlog/` + `_toc.md` — neither is in the 4-directory manifest trigger (`project-template/`, `scripts/`, `pack-ops/`, `supporting-docs/`). No rebuild required for this commit. |

Commit subject (proposed; user's call at the gate):
`docs: v11 — BD-204 first Mode-3 tree publication (pack-chat-only)` — every touched
path is under `/backlog/` (pack-chat-only prefix per PLAN EE-3). Precondition carried
over from PLAN B2: a tree-rebuild over the real tracker state must succeed — the
known fail-loud-at-parse constraint until the BD-094/BD-095 data fix is unchanged by
this amendment; C-8 lands when that precondition holds, at the user's direction.

---

## B5. Element 5 — Doc-surface deltas for the pending Commit 1 / Commit 2 recipes

Ruling 3 ("well documented so users understand") binds. The model statement every
surface must carry, in its own audience's vocabulary (semantic content fixed):

> The pack repo's COMMITTED state is always flat-file — every checkout and every
> version bump ships flat-file. Tracker mode is a LOCAL opt-in: `pack tracker init`
> writes a local, gitignored `tracker.toml`; your switch survives pulls and version
> bumps; no one else's checkout changes. The committed per-entry tree (+ `_toc.md`)
> is the published flat-file SSOT that the (single) tracker-mode maintainer keeps
> current by committing regenerated trees.

**Pack surfaces (numbered; Commit assignment per §B8):**

1. **`/backlog/_rules.md`** (Commit 1) — ops-contract §1.1 fenced text, two deltas:
   (a) the mode-detection parenthetical "(… absent file = flat-file)" grows the
   local-opt-in clause: mode is read from the LOCAL pack `tracker.toml`; the file is
   gitignored and never committed; the repo's committed state is always flat-file.
   (b) the tracker-mode paragraph gains the publication + single-writing-authority
   text (§B1.4/§B1.5): committed tree = published flat-file SSOT; one writing
   authority; what a second writer must not do.
2. **`/changelog/_rules.md`** (Commit 1) — ops-contract §1.2 "Mode invariance"
   paragraph, one clause added: tracker mode is a LOCAL opt-in of the maintainer's
   checkout; in every checkout without a local `tracker.toml`, this stream — like
   every committed stream — is simply flat-file.
3. **`pack-ops/PACK-CHAT.md`** (Commit 1) — ops-contract §1.3 deltas: item 1 (mode
   detection) states the local-opt-in model + "the pack is currently Mode 3 ON THE
   MAINTAINER'S MACHINE; every other checkout is flat-file"; item 5 (regen cadence)
   staging list becomes "the regenerated tree + `_toc.md`" ONLY — explicitly: the
   local `tracker.toml` and `.pack-tracker/` are NEVER staged (gitignored); NEW item
   11: the single-writing-authority caveat + publication cadence (one-hop pointer to
   `/backlog/_rules.md` for the full caveat text — anti-restate).
4. **Trinity `## Pack memory` bullet ×3** (Commit 1) — the ops-contract §1.4 appended
   sentences gain one clause: "(tracker mode is a per-checkout LOCAL opt-in — the
   committed repo is always flat-file; `tracker.toml` is local and gitignored)".
   Byte-identical across the three root files (no tool-specific content).
5. **`tracker.toml.pack-example` header + `[mode]` comments** (Commit 2 — NOT
   pack-chat-only; pack root example file) — rewrite the opt-in steps to state: the
   copy you create is LOCAL and gitignored; it is never committed; your mode survives
   pulls/version bumps; the repo always ships flat-file; single-writer note pointer
   to `/backlog/_rules.md`. (The `mapping_file` value + "(gitignored)" comment are
   already true — untouched, §B2.)
6. **`.gitignore` comment block** (Commit 2) — the new `/tracker.toml` entry's comment
   is itself a user-facing doc surface: "Local tracker-mode opt-in (BD-204): the
   repo's committed state is always flat-file; your local mode survives pulls."
7. **`pack-ops/HELP-FRAGMENT-TRACKER.md`** (Commit 2) — the `pack tracker init` row
   ("Opt-in: write `tracker.toml` …") gains "(pack repo: local + gitignored — your
   checkout only; the repo always ships flat-file)". This file is the PACK-side
   audience copy (the client-shipped copy is the separate
   `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` — §B6 R12; per the S11
   comment in `scripts/init-project.sh` `stage_s11_v11_artifacts`, pack-side
   substitution is forbidden, so the two edit independently).
8. **`pack-ops/HELP-FRAGMENT-PACK.md`** (Commit 2) — already in the PLAN for the verb
   rows (`tree-rebuild`/`edit`/`new-entry`); no additional mode-model prose here (the
   mode model lives in the TRACKER fragment — one-hop, anti-restate).
9. **`pack-ops/OPTIONAL-FEATURES.md`** (Commit 2) — its tracker section ("`tracker.toml`
   lives at … pack root (pack repo)") gains the local-gitignored clause, one sentence.

**Found by census, deliberately NOT edited:** archived reports and resolved-era backlog
entries stating the old committed-artifact intent (history, not live instruction);
`supporting-docs/MIGRATION-v10-to-v11.md` + `project-template/**` surfaces (project
side — §B6; Commits 1–2 must not touch them).

> **Empirical-Evidence Block (surface census for the model statement).**
> `CMD`: `grep -n "flat-file\|opt-in\|tracker.toml" pack-ops/HELP-FRAGMENT-TRACKER.md
> pack-ops/OPTIONAL-FEATURES.md` + reads of `tracker.toml.pack-example` (74 lines,
> FULL), `/backlog/_rules.md` (95 lines, FULL), `.gitignore` (66 lines, FULL).
> `OUT`: HELP-FRAGMENT-TRACKER.md carries the init/disable opt-in rows (no
> local-vs-committed statement); OPTIONAL-FEATURES.md states the file "lives at …
> pack root" (no local statement); the pack example's header says "Copy this file to
> `tracker.toml` in the pack root" (no local/gitignored statement); `_rules.md` and
> `.gitignore` as quoted above. `AT`: HEAD `9127907`, 2026-06-11. `INTERP`: exactly
> the nine surfaces above need the model text; no other live pack surface instructs
> on pack tracker-mode setup. `CONCL`: SUPPORTED.

---

## B6. Element 6 — Project-side R-section delta (BD-206/BD-207 requirements; project form per P-missed-7)

> **Status: REQUIREMENTS, not implementation.** Appended to / amending the
> ops-contract §5 R1–R8 set. Client SSOTs investigated FIRST (quoted); client
> vocabulary throughout (PM chat, `docs/pack/PM-CHAT.md`, TD namespace). Commits 1–2
> touch NONE of these surfaces.

**R9 (prior amendment) — WITHDRAWN as written.** "Committed client id-map at
`docs/pack/tracker-id-map.json`" was premised on the committed pack id-map; the
premise dissolved (§B2). Replacement constraint for BD-207's design pass: the client
id-map DEFAULT is the as-built state — client `.pack-tracker/id-map.json`, gitignored
via the shipped `project-template/.gitignore` `.pack-tracker/` rule, regenerable from
the issue-body markers. BD-207 MAY revisit a committed team map (a client team,
unlike the pack, has multiple machines that could benefit from a shared bootstrap)
but must carry: regenerable-from-markers makes local sufficient; committing is team
convenience, never a correctness requirement; and zero `.pack-tracker/` carve-outs
(the no-`!negation` decision applies in client form).

**R10 (NEW) — Client mode default + stickiness (ruling 2).**

- **Install default = flat-file by example-only — VERIFIED as-built.**
  `scripts/init-project.sh` `stage_s11_v11_artifacts` step 2 copies
  `project-template/tracker.toml.project-example` → client-root
  `tracker.toml.example`; NO stage writes a live `docs/pack/tracker.toml`.
  `tracker_mode()` on the absent canonical client path
  (`tracker_config_resolve_path` client arm → `$root/docs/pack/tracker.toml`) →
  `flat-file`. The example itself ships `state = "flat-file"` +
  `forward_complete = false` (double cover). Requirement: BD-206/207 PRESERVE this
  shape — opt-in remains `pack tracker init` (client surface), never a default-on
  install.
- **Upgrade/migration NEVER resets the client's live `tracker.toml` — VERIFIED
  as-built, but only BY OMISSION; the requirement makes it a tested contract.**
  As-built facts: (a) `scripts/init-project.sh` `cmd_update`'s explicit `entries`
  mapping carries exactly ONE tracker row —
  `project-template/tracker.toml.project-example:tracker.toml.example:generic` — the
  live `docs/pack/tracker.toml` is NOT enumerated, and `_cmd_update_iter_dir` walks
  only `project-template/scripts` + per-CLI `agents/` directories; (b)
  `scripts/migrate-v10-to-v11.sh` copies the example skip-if-exists
  (`! -f "$_MIGRATOR_TARGET/tracker.toml.example"` guard) and only ever READS a live
  `tracker.toml` (`scripts/lib/migrate-v10-to-v11/checkpoint.sh`
  `checkpoint_check_mirror_freshness` / `checkpoint_tracker_mode_active` — probes,
  no writes); (c) `scripts/lib/customization-preserve.sh` `customization_classify`
  has NO `tracker.toml` arm — and that is load-bearing: if the live file were ever
  enumerated with the update path's empty BASE, `three_way_classify` would yield
  `project-shadows-new-pack` and `_cp_strategy_text` would sidecar OURS and install
  THEIRS — i.e., RESET the user's mode, the exact forbidden outcome. **Requirement:**
  (i) the live client `tracker.toml` is NEVER an update/migration copy target — state
  it in the client `_rules.md`/PM-CHAT.md surfaces and as a comment at the
  `cmd_update` entries list; (ii) **test obligation:** a leg in the update/migrator
  suites seeding a client fixture with a live `docs/pack/tracker.toml`
  (`state = "tracker"`, `forward_complete = true`) and asserting BYTE-IDENTITY after
  `init-project.sh --update` AND after the migrator, while `tracker.toml.example`
  still refreshes; (iii) any future migrator step that must touch the live file
  classifies it as USER STATE (merge/preserve semantics), never as a pack template.
- **Path-discrepancy flag (BD-207 must reconcile):** the migrator probes
  `$target/tracker.toml` (target ROOT — `checkpoint_check_mirror_freshness`,
  `checkpoint_tracker_mode_active`) while the canonical client location is
  `docs/pack/tracker.toml` (`tracker_config_resolve_path` client arm; the
  project-example header "Lives at `<project-root>/docs/pack/tracker.toml`").
  `project-template/docs/pack/OPTIONAL-FEATURES.md` also says "lives at your project
  root". Vestigial-defensive today (a v10 client cannot have a tracker.toml), but
  BD-207's R-refresh must converge every client surface on the
  `tracker_config_resolve_path` client arm.

**R11 (NEW) — Client `.gitignore` treatment: the live client `tracker.toml` ships
COMMITTED-BY-DEFAULT (NOT gitignored). The pack/client asymmetry is deliberate.**

- As-built: `project-template/.gitignore` ignores `.pack-tracker/` only; no
  `tracker.toml` entry exists → a client's `docs/pack/tracker.toml` is trackable and
  will be committed by normal team flow. **Decision: KEEP this.**
- Rationale for the asymmetry the calling prompt flagged: (a) a client team has NO
  single-writing-authority guarantee (§B1.5) — per-user mode on a team repo is a
  split-brain hazard (a flat-file teammate hand-edits the tree believing it SSOT
  while a tracker-mode teammate's rebuild clobbers it); the mode must be a TEAM
  decision, and committing the file is how a team shares a decision; (b) a client
  repo is not a published template — ruling 1's "every checkout ships flat-file"
  constraint is about the PACK as a distributed artifact and does not transfer;
  (c) ruling 2 is fully satisfied without local-only: default flat-file comes from
  example-only install (R10), stickiness comes from never-touch (R10) — a committed
  client `tracker.toml` survives pack upgrades precisely BECAUSE the upgrade
  machinery never targets it.
- Requirement: BOTH example headers (`tracker.toml.pack-example`,
  `project-template/tracker.toml.project-example`) document the asymmetry in one
  sentence each ("pack repo: local per-maintainer, gitignored / client project:
  team-shared, committed"); the client header additionally states that a team
  WANTING per-user behavior takes on the split-brain coordination burden themselves
  (not a supported default).

**R12 (NEW) — Client doc surfaces for the model statement (ruling 3, client half).**
In client vocabulary, the §B5 model statement's CLIENT form ("first install is
flat-file; enabling the tracker is `pack tracker init`; your team's mode lives in
the committed `docs/pack/tracker.toml`; pack upgrades never change your mode"):
`project-template/tracker.toml.project-example` header;
`project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` init/disable rows;
`project-template/docs/pack/OPTIONAL-FEATURES.md` tracker section (+ the R10 path
fix); `docs/pack/PM-CHAT.md` (client PM operating doc); the client stream
`_rules.md` files (R1's mode-conditional text gains the same default+sticky
clauses); the project trinity "Document locations" Source-column note;
`supporting-docs/MIGRATION-v10-to-v11.md` (mode-preservation statement in the
upgrade narrative). All BD-206/207 scope; none in Commits 1–2.

---

## B7. Element 7 — CI implications (verified under BOTH local states)

**The structural consequence of ruling 1: CI checkouts NEVER carry a `tracker.toml`**
(untracked today; gitignored after Commit 2) — so CI always exercises the flat-file
arms of every check. Verified check-by-check:

- **Check 29 (`check_tracker_config`, `scripts/validate-pack.py`):** (a) CI / fresh
  checkout: `live_cfg.is_file()` false → the explicit soft-pass `ok("tracker.toml
  absent at pack root — … lazy-create is by design")`. (b) Maintainer's local Mode-3
  state: `_check_mirror_staleness` reaches the BD-204 Check 29′ no-mirror guard —
  the live pack config has NO `[mirror]` table (verified: live `tracker.toml`, 23
  lines, no `[mirror]`) → soft-pass `"no [mirror] table / mirror disabled"`. Both
  states green; the example-schema legs are state-independent. **No adjustment
  needed.**
- **Check 32′ (`check_mirror_in_sync`) + the pending mode-marker extension:** the
  check reads ONLY committed tree files (`_rules.md`, `_toc.md`, entry files) — it
  never reads `tracker.toml`. The pending extension asserts marker HEADINGS in
  `_rules.md`; the §B5 delta keeps both headings ("Flat-file mode" / "Tracker mode")
  intact, so the extension lands exactly as the PLAN specifies. Identical behavior
  in CI and on the maintainer's machine. **No adjustment needed** (the marker text
  the coder writes must still carry both headings — §B8 D1-1).
- **Check 36 (scope keywords):** path-walk only; unaffected.
- **One NEW guard the Commit-2 recipe gains (D2-7): Check 29″ never-tracked leg.**
  Ruling 1 currently has no CI enforcement — if the maintainer ever `git add -f`'d
  (or pre-ignore, plain `git add -A`'d) the live `tracker.toml`, CI would happily
  pass and the repo would ship a tracker-mode default. Add to
  `check_tracker_config`: FAIL if `tracker.toml` is TRACKED at the pack root
  (`git ls-files --error-unmatch tracker.toml` succeeds ⇒ fail with "the pack's
  committed state is always flat-file — `tracker.toml` is a local opt-in; untrack
  it"). Measure-then-bound: measured UNTRACKED at HEAD `9127907` (EE §B0) → lands
  green; CI (no file, untracked-by-absence) green; maintainer local state
  (untracked) green. Per-check test leg rides in the existing Check-29 host suite
  per the PLAN's enumerate-encoding-surfaces row. This is the CI realization of
  ruling 1, not invention.
- **Test fixtures:** the three committed `scripts/tests/fixtures/**/tracker.toml`
  files and `test-fixtures/` trees are unaffected by the ANCHORED `/tracker.toml`
  ignore (EE §B0) and by Check 29″ (which tests the pack-root path only).

---

## B8. Element 8 — Commit reshaping: the Commit 1 / Commit 2 split SURVIVES; itemized deltas; NO planner re-run

**The call, explicit:** the docs-first/code-second split and its rationale
(Check 32′ measure-then-bound, D2 ordering) are untouched by the rulings. The deltas
below are itemized to coder precision and are NET-SIMPLIFYING (the prior amendment's
entire 11-item Commit-2 delta is cancelled, §B2). **A planner re-run is NOT
warranted.** This section is NORMATIVE over `PLAN-BD-204-MODE3-OPS-CONTRACT.md`
§§2–3 where they conflict; everything not named below stands as planned. PLAN
OQ-1/OQ-2 are closed (§B2/§B4); PLAN OQ-3 (subject wording) remains the user's call.

### D1 — Commit 1 deltas (docs/contract commit; keyword `pack-chat-only` UNCHANGED — file set unchanged)

| # | PLAN/ops-contract anchor | Delta |
|---|---|---|
| D1-1 | §1.1 `/backlog/_rules.md` Source-of-truth fenced text | Mode-detection parenthetical gains the local-opt-in + always-flat-file-committed clauses; tracker-mode paragraph gains the published-tree + single-writing-authority text (§B5 surface 1). BOTH "Flat-file mode" and "Tracker mode" headings PRESERVED verbatim (Check 32′ markers, §B7). |
| D1-2 | §1.1 Write-authority fenced text | Staging list "the regenerated tree + `_toc.md` + `tracker.toml` + `.pack-tracker/id-map.json`" → "the regenerated tree + `_toc.md`" (ruling 4 + §B2). |
| D1-3 | §1.2 `/changelog/_rules.md` Mode-invariance paragraph | One added clause: tracker mode is a local opt-in of the maintainer's checkout (§B5 surface 2). "Mode invariance" marker PRESERVED. |
| D1-4 | §1.3 PACK-CHAT.md section | Item 1 + item 5 rewrites + NEW item 11 per §B5 surface 3. Item 5's committed-artifact list becomes tree + `_toc.md` only, with the explicit never-staged statement for `tracker.toml`/`.pack-tracker/`. |
| D1-5 | §1.4 trinity bullet append ×3 | One added clause per §B5 surface 4; byte-identical ×3. |
| D1-6 | PLAN §2.2 "OQ-1 wording dependency" bullet | DELETED — OQ-1 closed; the staging-list wording is fixed by D1-2. |
| D1-7 | PLAN §2.2 forward-naming transient | Unchanged in kind; now ALSO covers the docs naming `tracker.toml` as "gitignored" one commit before the Commit-2 `.gitignore` edit lands (same accepted one-commit-window class). |

### D2 — Commit 2 deltas (code commit; keyword `pack-only` UNCHANGED — all added paths are outside `project-template/` + `supporting-docs/`)

| # | PLAN anchor | Delta |
|---|---|---|
| D2-1 | PLAN §3.1 rows: verbs (`tree-rebuild`/`edit`/`new-entry`), `tree_only` engine arm, status-coherence comparator, doctor legs (d)/(h), Check 32′ extension, test legs 1–11, HELP-FRAGMENT-PACK.md verb rows, manifest regen | **UNCHANGED** — land as planned. Freshness-key stamping unchanged mechanically (§B3.1); only doc/rationale wording says "local" not "committed". |
| D2-2 | Prior amendment's Commit-2 recipe delta items 1–11 (resolver `tracker_mapping_path`, group-(a) literal rerouting, init heredoc surface-conditional value, pack-example `mapping_file` value, validate-pack basename-allowlist edits, BOUNDARY-DEFINITION C2 extension, `.gitignore` "Mapping file" comment drop, group-(c) path tests, live-ops `cp` sequence) | **CANCELLED IN FULL** (§B2). `scripts/lib/tracker-init.sh` heredoc, all id-map literals, and both examples' `mapping_file` lines stay as-built. |
| D2-3 | PLAN §3.1 `.gitignore` row ("IFF OQ-1 option (a)") | REPLACED: add root-anchored `/tracker.toml` + the §B5 surface-6 comment to the existing BD-061 block. ANCHORED is mandatory (EE §B0 — three committed fixture `tracker.toml` files). |
| D2-4 | (new file rows) | ADD: `tracker.toml.pack-example` header/[mode]-comment rewrite (§B5 surface 5); `pack-ops/HELP-FRAGMENT-TRACKER.md` init-row clause (§B5 surface 7); `pack-ops/OPTIONAL-FEATURES.md` one-sentence clause (§B5 surface 9). All pack-only-clean. |
| D2-5 | `scripts/validate-pack.py` | ADD Check 29″ never-tracked leg per §B7 + its per-check test leg + the Check-29 header-docstring lock-step update. The PLANNED Check 32′ extension is unchanged. |
| D2-6 | Ordering note | The `.gitignore` edit MUST land in Commit 2 (before C-8) — §B4 item 4 rationale. |
| D2-7 | Manifest expectation | Unchanged in kind (`scripts/**` + `pack-ops/` trigger fires; rebuild + stage same commit). The added pack-ops files are not client-copied (S11 copies the project-template TRACKER fragment, not the pack-ops one — `stage_s11_v11_artifacts`), so the manifest diff drivers remain the `scripts/**` edits; `git diff test-fixtures/manifest.txt` after rebuild stays the canonical authority. |
| D2-8 | Architecture-doc reconciliation | The Commit-2 IMPL-REPORT cross-references THIS amendment (supersession of ops-contract §2 freshness rationale + §1.1/§1.3 staging text + prior amendment §A1–§A5) per architect-doc-vs-reality reconciliation. |

### Sequencing (unchanged shape)

Casing+cycle base state is LANDED (HEAD `9127907`, clean tree) → Commit 1 → Commit 2 →
C-8 state commit (§B4, Pack Chat, when the tree-rebuild precondition holds) →
disposition pass (§B9 + the BD-206/207 R-row updates via the tracker tooling).

---

## B9. Element 9 — BD-102 dissolution (disposition-pass input)

`backlog/BD-102.md` (read in full, 24 lines) carries: "Per §6.J ship decision: pack
ships v11.0 in flat-file mode (reverse before release pin)." Under ruling 1 the
ship-mode contradiction DISSOLVES BY CONSTRUCTION: the repo's committed state is
always flat-file, so "pack ships v11.0 in flat-file mode" is satisfied at every
commit and every tag with NO reverse migration — the maintainer's tracker mode is
local and invisible to the shipped artifact. The "(reverse before release pin)" step
is OBSOLETE: running `pack tracker disable` before the release pin is no longer
required (and would needlessly destroy the maintainer's local opt-in, violating the
stickiness ruling). **Disposition-pass action (Pack Chat, via the tracker tooling
per the Mode-3 write contract, user-approved):** amend BD-102's Description to
strike the reverse-before-release step and record "resolved by construction —
BD-204 local-opt-in model (ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT-2 §B9)".
BD-102's remaining dog-food validation procedure (dry-run → apply → init → doctor →
disable → round-trip diff → report) is UNAFFECTED — it tests the machinery, not the
ship mode.

---

## B10. CONTRADICTION-FOUND

**NONE beyond the one RECORDED SUPERSESSION (user authority, ruling 4):** ratified
tracker-mode rule 9's committed-artifact list LOSES `tracker.toml` (never committed,
gitignored). Consequential recorded amendments riding on delegated authority (the
calling prompt's element 2) rather than on a ruling: the id-map ALSO leaves the
committed-artifact list (§B2 decision); the ops-contract §1.1/§1.3 staging text and
§2 freshness-rationale sentence are superseded as itemized at D1-2/D1-4/§B3; the
prior amendment (`-AMENDMENT.md` §A1–§A5) dissolves with its committed-map premise
(§B2). The rulings themselves were checked against the ratified flat-file set and
the remaining tracker-mode rules: no further conflict — the one-way write model,
blob-status truth, comparator semantics, DP-4 `_toc.md` coupling, and the no-monolith
contract are all mode-internal and orthogonal to WHERE `tracker.toml` lives.

**Flagged observations (disposition-pass notes, NOT contradictions with the rulings,
NOT Commits-1/2 scope):**

1. Pack-root trinity `## Pack memory` manifest-regen bullet says
   "`pack-ops/HELP-FRAGMENT-TRACKER.md` (`scripts/init-project.sh` stage S11 copies
   to client `docs/pack/`)" — as-built, S11 copies
   `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` and forbids pack-side
   substitution (`stage_s11_v11_artifacts` comment). Pre-existing trinity-text-vs-code
   drift; surfaced for Pack Chat triage (PM-only surface).
2. The client tracker.toml LOCATION discrepancy (migrator probes target root;
   canonical is `docs/pack/`) — recorded as the R10 path-discrepancy flag for BD-207.

---

## B11. READ-IN-FULL attestation (per-file direct-read proof, this session)

| # | File | Proof (path + line count, read this session) |
|---|---|---|
| 1 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md` | Read IN FULL via Read tool, 556 lines (`wc -l` verified), §0–§9. |
| 2 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT.md` | Read IN FULL via Read tool, 384 lines (`wc -l` verified), §A1–§A8. |
| 3 | `maintenance-docs/v11-implementation/PLAN-BD-204-MODE3-OPS-CONTRACT.md` | Read IN FULL via Read tool, 451 lines (`wc -l` verified), §0–§9 incl. EE-1..EE-8 + OQ-1..OQ-3. |
| 4 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` | Read IN FULL via Read tool, 579 lines (`wc -l` verified), incl. the complete `## Pack memory` section. |
| 5 | `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_agent_output_rules_applied_block.md` | Read IN FULL via Read tool, 15 lines; its conditional MUST-READ honored — `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block` (+ adjacent `empirical-evidence-blocks`) read directly this session (lines-195–264 region of the 601-line file). |
| 6 | Instructed section-reads, each verified directly: `scripts/lib/tracker-config.sh` FULL (333 lines — `tracker_mode`, `tracker_config_resolve_path`, `tracker_gh_repo_setup`, `tracker_mapping_file`, `tracker_config_auto_surface`); `scripts/lib/tracker-init.sh` FULL (447 lines — `tracker_init_run`, `_tracker_init_write_config` heredoc); `scripts/lib/customization-preserve.sh` FULL (558 lines — `customization_classify` has NO tracker.toml arm; strategy dispatch verified); `scripts/init-project.sh` (1563 lines total): `stage_s11_v11_artifacts` region + `cmd_update`/`_cmd_update_iter_dir`/`entries` list + `_CLIENT_INSTALLED_FILES` head + tracker greps; `scripts/validate-pack.py`: Check 29 (`check_tracker_config` + `_check_mirror_staleness` incl. the BD-204 29′ no-mirror guard) + Check 32′ (`check_mirror_in_sync`) + header docstring rows; `scripts/lib/migrate-v10-to-v11/checkpoint.sh` (`checkpoint_check_mirror_freshness`, `checkpoint_tracker_mode_active`) + `gate-3-phase-b-verify.sh` (Gate-3 SKIP arm); `scripts/migrate-v10-to-v11.sh` tracker.toml.example copy guard (grep + cited lines-class); `.gitignore` FULL (66); `project-template/.gitignore` FULL (101); `tracker.toml.pack-example` FULL (74); `project-template/tracker.toml.project-example` FULL (75); live `tracker.toml` FULL (23); `/backlog/_rules.md` FULL (95); `backlog/BD-102.md` FULL (24); `backlog/BD-206.md` + `backlog/BD-207.md` heads (entry bodies through scope/AC); `pack-ops/HELP-FRAGMENT-TRACKER.md`, `pack-ops/HELP-FRAGMENT-PACK.md`, `pack-ops/OPTIONAL-FEATURES.md`, `project-template/docs/pack/OPTIONAL-FEATURES.md`, `supporting-docs/MIGRATION-v10-to-v11.md` — targeted greps for tracker/mode prose; `backlog/_toc.md` head; `git ls-files` tracker.toml census; `pack-ops/` listing. |

No named document was derived rather than read; every file above was opened via the
Read/Bash tools this session at HEAD `9127907`.

---

## B12. Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| **agents-never-commit** | Git verbs run this session: `git rev-parse HEAD`, `git status --short`, `git check-ignore -v`, `git ls-files` — all read-only. Sole filesystem writes: the chunked `cat >`/`cat >>` writes of THIS file; zero `add/commit/push/tag/stash/reset/restore/checkout` invocations; no other repo file edited; the live `tracker.toml` and `.pack-tracker/` untouched. | COMPLIANT |
| **per-action-approval-sub-agents** | Zero destructive ops (no `rm`, no `git rm`, no overwrite of any trusted file — output path verified non-existent pre-write: `find . -name "ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT-2.md" -not -path "./.git/*"` → empty). Zero live GitHub calls: no `gh` invocations, no GitHub MCP tool calls; all evidence is local reads. The C-8 live-ops and BD-102 disposition actions are DESIGNED as Pack-Chat-with-user-approval steps, not performed. | COMPLIANT |
| **preflight-stop-means-stop** | Emitted before the first write chunk, verbatim: `PREFLIGHT: amendment complete; 9 elements decided; about to Write to maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT-2.md`. All commands ran FOREGROUND to completion (zero background tasks armed). No parent stop/halt/revert message was received at any point. | COMPLIANT |
| **agent-output-rules-applied-block** | This table: 8 rows (one per prompt "Rules in force" item), each with quoted command/output evidence; zero empty cells. Format per `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block` (read this session per its MUST-READ line — §B11 row 5). | COMPLIANT |
| **agents-read-rule-docs-in-full** | §B11: the four prompt-named read-in-full files attested with `wc -l`-verified line counts (556 / 384 / 451 / 579 + memory 15); every instructed section-read enumerated with file + symbol in §B11 row 6. | COMPLIANT |
| **boundary-investigation-precedes-defaults** | §B6 opens from CLIENT SSOTs, quoted: `tracker_config_resolve_path` client arm (`$root/docs/pack/tracker.toml`), `stage_s11_v11_artifacts` step 2, `cmd_update` `entries` mapping, `customization_classify` (no tracker.toml arm), `project-template/.gitignore`, `tracker.toml.project-example` header — requirements stated in client vocabulary (PM chat, `docs/pack/PM-CHAT.md`, TD); no pack mechanism imported (pack realization named only as reference implementation). The R11 asymmetry decision is grounded in a client-side property (no single-writer guarantee), not a pack-style default. | COMPLIANT |
| **user-prescriptive-authority** | The four rulings are restated as FIXED in the header and realized, never re-argued: §B1 (ruling 1), §B6 R10/R11/R12 (ruling 2), §B5+R12 (ruling 3), §B10 (ruling 4 recorded as supersession). The prior amendment's dissolution (§B2) rides on the calling prompt's explicit element-2 delegation ("re-decide committed-vs-local … the prior amendment's placement stands IF committed"), with the IF-condition's failure stated — no fixed decision relitigated. | COMPLIANT |
| **scope-deliverables-to-the-ask** | The doc contains exactly the nine prompt elements as §B1–§B9 (+ §B0 as-built corrections, a prompt-required behavior), CONTRADICTION-FOUND (§B10), attestation (§B11), and this block. The phase-routing fold-in and numeric-sort items: ZERO occurrences in this doc (grep "phase-routing\|numeric-sort" → only this sentence) — left to the disposition pass as instructed. The single addition beyond the elements is Check 29″ (§B7/D2-5), which is the CI realization of ruling 1 surfaced BY element 7's "what (if any) check adjustments the Commit-2 recipe needs" — answered, not invented. | COMPLIANT |

---

**End of ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT-2.md**
