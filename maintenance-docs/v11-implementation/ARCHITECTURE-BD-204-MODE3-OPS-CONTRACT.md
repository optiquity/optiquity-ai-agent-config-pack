# ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT — Mode-3 (and flat-file) entry-management operational contract

> **Agent:** pack-architect (fresh instance). **Mode:** DESIGN ONLY — no repo file edits other
> than this one strategy doc; no git state-changing verbs; no live GitHub calls. **HEAD
> (verified):** `1c18b28` (`git rev-parse HEAD` → `1c18b28c4d149d3e80565beafccc84f8d25b32f2`),
> branch `v11-dev`, **with uncommitted working-tree edits** to the tracker libs (the BD-204 C-8
> commit-pending state; `git status --short` shows `scripts/lib/tracker-*.sh` +
> `scripts/tests/tracker-*` modified). All code reads below reflect the WORKING TREE.
> **Date:** 2026-06-11.
>
> **What this doc realizes.** The two USER-RATIFIED RULE SETS (2026-06-11) for flat-file mode
> and tracker Mode 3 are FIXED constraints — this design specifies where they land on
> session-load surfaces, what machinery realizes them, and what enforces them. Nothing in the
> ratified sets is relitigated; the only challenge mechanism is the CONTRADICTION-FOUND
> section (§7 — empty).
>
> **Consumers:** pack-planner (sequencing), pack-coder (mechanical application), BD-206/BD-207
> refresh (§5 verbatim).

---

## 0. As-built verification + one correction to the calling prompt's AS-BUILT FACTS

Every AS-BUILT FACT in the calling prompt was independently re-verified against the working
tree. All hold, with ONE precision correction (per `architect-doc-vs-reality`):

**Correction (mirror-rebuild pack-surface failure shape).** The prompt states the
`mirror_only` arm "still targets the deleted monolith `BACKLOG.md` … on the pack surface it
errors 'BACKLOG.md not found'." As-built, the pack surface NEVER reaches the
`BACKLOG.md not found` branch: `tracker_migrate_forward_run`'s `mirror_only` arm
(`scripts/lib/tracker-migrate-forward.sh`) opens with a `surface == "pack"` guard (BD-204
C-6 / POQ-1) that fails loud with `"forward --mirror-only: mirror-rebuild is not applicable
on the no-mirror pack surface — … BD-203 deleted pack-ops/BACKLOG.md."` and returns 1. The
`BACKLOG.md not found` error is the CLIENT arm (`backlog_path="$repo_root/BACKLOG.md"`). The
prompt's SUBSTANCE is unchanged and confirmed: there is NO working pack-surface routine
tree-refresh verb — `pack tracker mirror-rebuild` is a deliberate dead end on the pack
surface, and the only tree materialization is the full reverse path.

> **Empirical-Evidence Block (mirror_only pack guard).**
> `CMD`: `sed -n '1367,1395p' scripts/lib/tracker-migrate-forward.sh`
> `OUT`: `if [[ "$surface" == "pack" ]]; then tracker_error_emit "validation" "forward
> --mirror-only: mirror-rebuild is not applicable on the no-mirror pack surface — …"; return 1;
> fi` precedes the client `backlog_path="$repo_root/BACKLOG.md"` + `_tmf_regen_mirror` branch.
> `AT`: HEAD `1c18b28` + pending working-tree edits, 2026-06-11. `INTERP`: pack arm fails loud
> by design; client arm still drives `_tmf_regen_mirror`. `CONCL`: SUPPORTED (prompt fact
> PARTIAL — corrected above).

**Verified as stated (key facts, by file + symbol):**

- `tracker_edit_entry` (`scripts/lib/tracker-edit.sh`) mutates THE ISSUE ONLY: recomposes
  H2 + `pack-entry-body-gz64` blob atomically via `tmf_compose_issue_body`, swaps `status:*`
  labels via `provider_update`, crosses the open↔closed boundary via
  `provider_close`/`provider_reopen`. It writes NO local per-entry file and NO `_toc.md`.
- The tree materializes ONLY via `tracker_migrate_reverse_run` → `_tmr_emit_pack_tree` →
  `per_entry_regenerate_toc` (`scripts/lib/tracker-migrate-reverse.sh`). DP-4 is realized
  INSIDE `_tmr_emit_pack_tree` (its final action is the `_toc.md` regen), so any caller of the
  pack tree emit inherits the `_toc.md` coupling by construction.
- A NON-FLIPPING reverse already exists mechanically: `scripts/tracker-migrate.sh` `cmd_reverse`
  (no `--disable`) calls `tracker_migrate_reverse_run` with `flip_mode=0`;
  `_tmr_update_tracker_toml` flips `mode.state` ONLY when `flip=1` (it always stamps
  `migration.last_reverse_run`). But this path is NOT exposed on the `pack tracker` verb
  surface (`scripts/pack-tracker.sh` dispatch: `init/status/mirror-rebuild/disable/doctor/
  update-templates/enable-recommendations` — no regen verb), and it over-emits (next bullet).
- The pack-surface reverse emit is NOT tree-only: `tracker_migrate_reverse_run`'s pack branch
  also calls `_tmr_emit_implementation_plan` (writes `$repo_root/IMPLEMENTATION-PLAN.md`,
  skip-if-exists) and `_tmr_emit_status` (writes `$repo_root/STATUS.md`, every run) at the
  PACK ROOT. Neither file exists at the pack root today (`ls` confirms absent). A routine
  regen verb that deposits a root `STATUS.md` + `IMPLEMENTATION-PLAN.md` skeleton on every
  run would create stray top-level files the pack repo has never carried. §2 designs
  around this.
- Forward Step-10 is client-surface-gated (`if [[ "$surface" != "pack" ]]` around
  `_tmf_regen_mirror`) — confirmed.
- Status decode vs blob: at reverse, `status=$(_tmr_decode_status "$issue")` derives status
  from labels + state + state_reason, while the regenerated file's `Status:` line is the
  BLOB's verbatim `raw_body` (`_tmr_emit_pack_tree` writes `raw_body` byte-for-byte). A
  GH-UI label/state-only flip therefore diverges the two SILENTLY today — no comparator leg
  covers status (the existing `_tmr_check_blob_h2_divergence` covers body H2 only). §3 closes
  this.
- `tracker-doctor.sh` leg (d) pack arm is repointed (C7b) to `_toc.md` mtime vs
  `migration.last_forward_run` — but mtime is unreliable across fresh checkouts (git does not
  preserve mtime), and the recovery verb it names on the CLIENT arm (`pack tracker
  mirror-rebuild`) is correct only for clients. §4 repoints the pack leg to committed
  timestamps.
- `/backlog/_rules.md` § "Source of truth — no mirror" + § "Write authority" carry
  Mode-2-only write language ("to change an entry, edit its per-entry file and regenerate
  `_toc.md`"; "After any entry edit, regenerate `_toc.md` via `per_entry_regenerate_toc …`
  before staging") with NO mode conditionality. `/changelog/_rules.md` likewise.
  `pack-ops/PACK-CHAT.md` § "File access strategy" describes per-entry reads/edits with no
  Mode-3 arm. The trinity `## Pack memory` "Per-entry trees — sole SSOT" bullet states the
  high-level mode-dependent contract but no operational procedure and no
  one-way-overwrite warning.
- Live mode state: `./tracker.toml` (pack root) has `[mode] state = "tracker"`,
  `forward_complete = true`, `last_forward_run = "2026-06-11T20:03:47Z"` — the pack IS in
  Mode 3 in the working tree.

**One flagged machinery gap surfaced by the contract itself (OQ-A — user decision; not
silent scope growth).** The ratified rule "ALL entry creates/edits/status-flips go through
the tracker tooling" has an incomplete verb surface: `tracker_edit_entry` exists as a
SOURCED FUNCTION but `pack-tracker.sh` exposes NO `edit` verb, and NO create path exists
outside the forward migration (no verb composes a new Issue + `pack-id` marker + id-map
entry for a new BD opened in Mode 3). The contract docs (§1) cannot truthfully say "use the
tooling" for creates until a create path exists. **Recommendation:** Commit 2 (§6) includes
a thin `pack tracker edit` verb (a flag-parsing wrapper over `tracker_edit_entry` — trivial
surface) and a thin `pack tracker new-entry` verb (compose via `tmf_compose_issue_body` +
`provider_create` + label set + id-map append + tree-rebuild). Per the no-deferral default
this belongs in v11.0; the user gates whether both verbs ride this work or land under a
separate anchor. §1's PACK-CHAT.md text is written to name the verbs; if the user defers
them, the planner substitutes the documented sourced-function invocation for `edit` and a
documented manual create procedure, and a BD anchor is REQUIRED for the verbs
(`deferred-work-tracked-anchor`).

---

## 1. Element 1 — Doc surfaces + text shape

**Design principle (anti-restate, one-hop SSOT).** The per-stream `_rules.md` is the SOLE
per-stream contract (its own header says so); it carries the FULL mode-conditional write
procedure. `pack-ops/PACK-CHAT.md` carries Pack Chat's OPERATING workflow (when to regen,
what to stage, how minor-edit authority maps to Mode 3) and POINTS at `_rules.md` for the
per-stream contract. The trinity `## Pack memory` bullet carries the one-line imperative +
pointer. No rule text is duplicated across the three layers.

### 1.1 `/backlog/_rules.md` — mode-conditional rewrite (two sections)

**Replace § "Source of truth — no mirror"** with a mode-conditional section. Proposed shape
(planner may tighten wording; semantic content is fixed):

```markdown
## Source of truth — mode-dependent (no monolith in either mode)

The stream operates in one of two modes, read from the pack
`tracker.toml` (`[mode] state` + `[migration] forward_complete`;
absent file = flat-file):

**Flat-file mode (default).** The per-entry tree at `/backlog/` (plus
its generated `/backlog/_toc.md` index) is the SOLE source of truth
and readable form. There is no monolithic mirror — the former
`pack-ops/BACKLOG.md` was deleted at BD-203; do not recreate it. GH
Issues are IGNORED by all tooling in this mode; inbound-feedback
issues are a human/PM triage channel only. Validation runs against
the tree.

**Tracker mode (`state = "tracker"` + `forward_complete = true`).**
The tracker is the SOLE source of truth. Entry identity is the
`<!-- pack-id: BD-NNN -->` body marker — never an issue number. The
per-entry tree + `_toc.md` are a REGENERATED MIRROR of tracker state:
read-stable, never hand-written. A hand-edit to any `BD-NNN.md` or to
`_toc.md` is INVALID and is OVERWRITTEN WITHOUT DETECTION at the next
tree rebuild — the write direction is one-way (tracker → tree,
always); this is a regeneration, NOT a sync. There is still no
monolith, ever. `_toc.md` regenerates on EVERY tree materialization.
```

**Replace § "Write authority"** (keep the Pack-Chat-authority sentence verbatim; make the
procedure mode-conditional):

```markdown
## Write authority

Writes are Pack-Chat authority (the pack-backlog tree is a
pack-chat-only directory per `pack-ops/PACK-AGENTS.md` § "pack-chat-only
files and directories"; agents edit it only when a caller scopes it in
for an explicit BD). The write PROCEDURE is mode-dependent (mode per
§ "Source of truth"):

- **Flat-file mode:** edit the per-entry file directly; entries
  resolve in place. After any entry edit, regenerate `_toc.md` via
  `per_entry_regenerate_toc pack-backlog /backlog` before staging.
  Never hand-edit `_toc.md` (derived index).
- **Tracker mode:** ALL entry creates / edits / status flips go
  through the tracker tooling (`pack tracker` verbs /
  `tracker_edit_entry`), which recomposes the H2 projection + the
  `pack-entry-body-gz64` blob atomically. NEVER edit a `BD-NNN.md`
  file or `_toc.md` by hand — the edit is overwritten without
  detection at the next rebuild. Direct GH-web edits are NOT a write
  path: body edits are blocked loudly by the divergence comparator at
  the next rebuild (`--force` = blob-wins); label/state-only flips
  are a coherence defect detected by `pack tracker doctor` and at
  rebuild. After any tracker write batch — and ALWAYS before
  committing tree state — run `pack tracker tree-rebuild`, then stage
  the regenerated tree + `_toc.md` + `tracker.toml` +
  `.pack-tracker/id-map.json` through the normal commit gates.
```

### 1.2 `/changelog/_rules.md` — mode-invariance statement (small additive edit)

The changelog stream is flat-file in BOTH modes (ratified set, tracker item 7). Add to
§ "Source of truth — no mirror" (one paragraph; the rest of the file is unchanged):

```markdown
**Mode invariance.** The pack-changelog stream is FLAT-FILE IN BOTH
modes: pack tracker mode (BD-204) applies to the pack-backlog stream
only. The tracker migration neither reads nor writes `/changelog/`
(the pack reverse emits no changelog). The write procedure below
applies regardless of the pack's tracker mode.
```

§ "Write authority" is otherwise unchanged (its flat-file procedure is correct in both
modes for this stream).

### 1.3 `pack-ops/PACK-CHAT.md` — new § "Backlog write paths by mode (Mode-3 operations)"

Placement: immediately after § "File access strategy" (it is the write-side complement of
that read-side table). Content requirements (the coder writes prose realizing ALL of these;
one-hop pointers to `_rules.md` for the per-stream contract, no restatement of §1.1's text):

1. **Mode detection.** At session start / before any backlog write, read `tracker.toml`
   (`[mode] state` + `forward_complete`). The pack is currently Mode 3.
2. **Write channel per mode.** Flat-file: per-entry file edit + `_toc.md` regen per
   `/backlog/_rules.md`. Tracker: ALL creates/edits/status-flips via the tracker tooling —
   `pack tracker edit` / `pack tracker new-entry` (OQ-A) — NEVER the Edit/Write tools against
   `/backlog/`.
3. **The one-way-overwrite statement (verbatim semantic).** "In tracker mode the tree +
   `_toc.md` are a one-way regenerated mirror (tracker → tree, always — NOT a sync). A
   hand-edit is invalid and is OVERWRITTEN WITHOUT DETECTION at the next
   `pack tracker tree-rebuild`."
4. **The flat-file-ignores-issues statement.** "In flat-file mode GH Issues are IGNORED by
   all tooling; inbound feedback remains a human/PM triage channel only."
5. **Regen cadence.** After any tracker write batch, and ALWAYS before committing tree
   state, run `pack tracker tree-rebuild`. The regenerated tree, `_toc.md`, `tracker.toml`,
   and `.pack-tracker/id-map.json` are committed artifacts flowing through the normal
   commit gates (staged-file review + user approval).
6. **GH-web is not a write path.** Body edits → divergence comparator blocks loudly at
   rebuild; `--force` = explicit blob-wins override. Label/state-only flips → coherence
   defect (§3); recovery = re-apply the status via the tracker tooling (blob is truth).
7. **Two lanes.** Pack-owned issues (`work-item` + resolved `pack-id`) reverse into the
   tree; inbound-feedback issues (`inbound` + `needs-triage` / `pack-id: PENDING`) are NEVER
   swept until promoted at triage.
8. **Minor-edit authority mapping.** The trinity `pack-chat-minor-edits-only` boundary is
   UNCHANGED; only the write CHANNEL changes in Mode 3. A bookkeeping edit Pack Chat may
   apply directly (a `Status:`/`Resolved:` flip; a new-BD author) is performed via the
   tracker tooling commands (Bash), not via Edit-tool writes to the tree. MAJOR edits still
   route to pack-coder — the coder likewise mutates via the tooling and runs the rebuild.
9. **Changelog unaffected.** The `/changelog/` stream stays flat-file in both modes; its
   write procedure never changes with tracker mode.
10. **File-access-strategy table touch-up.** In the existing table, the
    `/backlog/<ID>.md` per-entry row's "Why" cell gains a mode caveat: direct READ stays
    valid in both modes (the mirror is read-stable); the "read one entry file for one-entry
    edits" phrase becomes flat-file-only (Mode 3 edits go through the tooling).

PACK-CHAT.md edits are PM-owned; per the architect-spawn protocol this strategy doc is the
user-approved design and the coder applies mechanically (rule edits are MAJOR →
pack-chat-only file scoped into the coder prompt — the supported path).

### 1.4 Trinity `## Pack memory` bullet — parity edit (needed: YES, minimal)

The "Per-entry trees — sole SSOT (pack: no mirror)" bullet (`[roles: universal]`, no
rationale slug) is substantively correct but lacks the operational imperative. Append two
sentences to the bullet's tracker-mode arm, identical across `CLAUDE.md` / `AGENTS.md` /
`GEMINI.md` (no tool-specific content → full parity):

> "In tracker mode the tree + `_toc.md` are a ONE-WAY regenerated mirror — never hand-edit
> them; a hand-edit is overwritten without detection at the next `pack tracker
> tree-rebuild`, and all entry writes go through the tracker tooling. Write procedure per
> `<stream>/_rules.md`."

Routing per `pack-ops/PACK-CHAT.md` § "Rule-change propagation procedure": this is a
CONTENT REFRESH of an existing corpus bullet, not a new rule — surface 1 (corpus ×3 trinity)
applies; surface 2 (PACK-MEMORY-RATIONALE.md) is N/A (the bullet carries no
`[rationale:]` slug and this design adds none — adding a slug would grow the bijection for
a bullet whose rationale lives in `_rules.md`, violating fewer-conventions); surface 4
(reference surfaces) is satisfied by the §1.3 PACK-CHAT.md section; surface 5
(`.spawn-rule-manifest.txt`) updates only if that manifest lists this bullet (planner
verifies; expected N/A — no slug); surface 6 (fixture manifest) per §6. All in the same
commit (Commit 1).

---

## 2. Element 2 — The routine regen-trigger design (`pack tracker tree-rebuild`)

**Decision: RETIRE `mirror-rebuild` permanently on the pack surface (keep the existing
fail-loud guard, repoint its message at the new verb); ADD a new verb `pack tracker
tree-rebuild` = reverse-driven one-way tree materialization with NO mode flip and
TREE-ONLY emission.** The client surface keeps `mirror-rebuild` unchanged (BD-207 owns the
client repoint; §5 R2 hands the same verb shape to the client surface).

**Why a new verb rather than overloading `mirror-rebuild` (considered & rejected):**
`mirror-rebuild` is a FORWARD-path mirror-header refresh by name, wiring
(`tracker_migrate_forward_run … mirror_only=1`), and help text; the pack tree rebuild is a
REVERSE-path materialization. Overloading one verb to dispatch forward machinery on one
surface and reverse machinery on the other is exactly the special-case complexity the
design-elegance focus forbids, and the name "mirror" collides with the pack's no-monolith
vocabulary (Check 32′, `_rules.md`). `tree-rebuild` names what it does, is
surface-generalizable (BD-207 reuses the name for client trees), and lets `mirror-rebuild`
die with the client monolith at BD-206/207.

**Verb mechanics (planner recipe):**

- `cmd_tree_rebuild` in `scripts/pack-tracker.sh` (+ usage/help rows; `scripts/
  tracker-migrate.sh` help text gains the pointer). Flags: `--repo-root PATH`, `--force`
  (blob-wins override for the comparator legs, §3).
- **Mode gate (fail loud):** requires `tracker_mode == "tracker"` AND
  `migration.forward_complete == true`; otherwise
  `"tree-rebuild: not in tracker mode — the per-entry tree is the SSOT in flat-file mode;
  nothing to rebuild from"`. (`tracker_migrate_reverse_run` itself only checks
  `tracker.toml` existence; the gate lives in the verb wrapper.)
- **Engine:** `tracker_migrate_reverse_run "$repo_root" 0 0 0 "$force"` extended with a
  `tree_only` parameter (6th positional, default 0). With `tree_only=1` the pack-surface
  branch runs ONLY: roster build → reconstruct (silent-data-loss guard intact) →
  `_tmr_emit_pack_tree` (which already ends with `per_entry_regenerate_toc` — DP-4
  inherited by construction) → timestamp stamp. It SKIPS `_tmr_emit_implementation_plan`,
  `_tmr_emit_status`, and the header-strip calls — the routine regen must NOT deposit a
  root `STATUS.md` / `IMPLEMENTATION-PLAN.md` on the pack repo (§0; neither exists today,
  and creating them would trip the no-new-top-level-doc structural signal +
  filename-uniqueness conventions). `tree_only=1` is pack-surface-only at v11.0 (the verb
  wrapper passes it; the client branch is untouched — BD-207).
- **No flip:** `flip_mode=0` throughout; `_tmr_update_tracker_toml` never flips
  `mode.state` when `flip=0` (verified, §0).
- **Freshness bookkeeping (replaces the mtime heuristic):** two new committed
  `tracker.toml` `[migration]` keys —
  - `last_tracker_write` — stamped by `tracker_edit_entry` after its mutation sequence
    succeeds (and by the new-entry verb, OQ-A) via the existing `set_in_section` writer
    pattern;
  - `last_tree_regen` — stamped by every pack tree materialization (the `tree_only` arm
    AND the full reverse/disable path).
  Both survive fresh checkouts (committed artifacts — the user requirement that killed
  memory-as-home applies equally to mtime-as-signal). Doctor consumes them (§4.1).
- **When it runs (the operating cadence, stated in §1's docs):** after any tracker write
  batch; ALWAYS before committing tree state; on doctor's stale-tree WARN; and as the
  routine refresh whenever the chat wants a current readable tree.
- **Idempotence:** by construction — the blob is deterministic (gzip `mtime=0`),
  `pe_write_atomic` writes per file, `_toc.md` regenerates every pass (DP-4), and a
  re-run against unchanged tracker state is byte-stable (the §3.2 BD-204 fixed-point
  property). Failure safety: the `n_skipped` silent-data-loss guard fires BEFORE any tree
  write; a mid-emit failure leaves per-file-atomic partial state that the next successful
  run overwrites (the tracker is SSOT; regen converges) — and uncommitted regen output is
  recoverable through the normal commit gate (nothing stages without review).
- **Ride-along message fixes (same commit):** (a) the pack-surface `mirror-rebuild`
  fail-loud message gains "run `pack tracker tree-rebuild` instead"; (b) the reverse
  silent-data-loss guard's `"Reconstructing BACKLOG.md now would drop…"` line is
  surface-neutralized (the pack surface reconstructs the tree, not `BACKLOG.md`); (c) the
  doctor pack-arm WARN recovery verb becomes `pack tracker tree-rebuild` (§4.1).

---

## 3. Element 3 — The GH-UI coherence rule (label/state-only changes)

**The stated rule (lands in §1.1's tracker-mode text + §1.3 item 6):**

> **Status truth is the blob.** The entry's `Status:` line inside the
> `pack-entry-body-gz64` blob is the round-trip source; the `status:*` label + GH
> open/closed state + `state_reason` are PROJECTION (DP-3). The ONLY valid status write is
> the tracker tooling (`tracker_edit_entry`), which updates blob + H2 + label + state
> atomically. A label/state-only change made in the GH UI does not change the entry — it
> creates a PROJECTION-DIVERGENCE defect that the tooling detects loudly; it is never
> silently honored and never silently discarded.

**Enforcement shape — two layers (parallel to the existing body comparator):**

1. **Blocking comparator at every tree materialization** (tree-rebuild AND full
   reverse/disable). New `_tmr_check_status_coherence` in
   `scripts/lib/tracker-migrate-reverse.sh`, invoked where `_tmr_check_blob_h2_divergence`
   runs: per entry, compare `_tmr_decode_status(issue)` (labels/state projection) against
   the first `Status:` line of the decoded blob body. Mismatch → FAIL LOUD naming the
   pack-ids + both values + the recovery instruction; `--force` = blob-wins (the tree gets
   the blob's `Status:`, consistent with the body comparator's `--force` semantics and
   DP-1's loud-not-silent mitigation). **Recovery instruction text:** "re-apply the status
   via the tracker tooling (`pack tracker edit --status <blob-status> …`) so label/state
   re-converge with the blob — the doctor WARN clears once they match."
2. **Doctor advisory leg** (§4.1 leg (h)): enumerate pack-owned issues via `provider_list`
   (labels + state + body in one paginated read — no per-issue `provider_get` sweep),
   decode both sides, WARN per mismatch with the same recovery text. Doctor is advisory
   (WARN, rc=1) because doctor never mutates entry state; the BLOCKING gate is the
   materialization comparator, which is the moment divergence could otherwise reach disk.

**Why blob-wins (not label-wins, not newest-wins — considered & rejected):** label-wins
would let a UI mis-click rewrite entry content through the back door (a second write path —
exactly what DP-1(A) rejected); newest-wins needs trustworthy event ordering the provider
floor does not guarantee. Blob-wins matches the already-shipped body-comparator contract
(`ARCHITECTURE-BD-204.md` §2.4.1: "the blob is authoritative … `--force` = explicit
operator blob-wins override") — one consistent rule, zero new conventions.

---

## 4. Element 4 — Validation additions (which surfaces enforce the contract)

### 4.1 `tracker-doctor.sh` (`tracker_doctor_run`)

- **Repoint leg (d), pack arm:** replace the `_toc.md`-mtime vs `last_forward_run`
  comparison (mtime does not survive fresh checkouts) with the committed-key comparison:
  WARN when `migration.last_tracker_write > migration.last_tree_regen` → `"tree is stale
  relative to tracker writes → Run: pack tracker tree-rebuild"`. Keep the
  `_toc.md`-present INFO/OK lines. Client arm untouched (BD-207).
- **New leg (h) — status coherence (tracker mode, pack surface only):** per §3 layer 2.
  Skipped (INFO) in flat-file mode and when `gh`/network is unavailable (doctor already
  degrades gracefully on provider failures — follow the leg-(g) pattern).

### 4.2 `scripts/validate-pack.py`

- **Extend Check 32′** (`check_no_pack_monolith` region — it already asserts `_rules.md` +
  `_toc.md` presence per stream) with a per-stream required-marker assertion:
  `/backlog/_rules.md` must contain the two mode headings/markers ("Flat-file mode" and
  "Tracker mode" within § Source of truth, + the mode-conditional Write-authority bullets);
  `/changelog/_rules.md` must contain the "Mode invariance" marker. Heading/marker-presence
  ONLY — never prose-pinning (anti-fragility). Measure-then-bound: measured ABSENT at HEAD
  `1c18b28` (the sections do not exist yet) → the check lands in Commit 2, AFTER Commit 1
  writes the sections (§6 ordering), and is verified green against the projected
  post-Commit-1 state. Allowlist sized exactly to the two pack streams; project streams
  excluded (BD-206/207 add theirs — §5 R1).
- **Enumerate-encoding-surfaces lock-step:** the Check 32′ per-check test
  (`scripts/tests/` test pinning 32′ banners) updates in the same commit; CI workflow
  unchanged (32′ already runs).

### 4.3 Test legs (all mock-based — unattended battery; no live GH)

In `scripts/tests/tracker-migrate-reverse-test.sh` (or a sibling `test-pack-tracker-
tree-rebuild.sh` if the planner prefers a dedicated file — filename-uniqueness check
required either way):

1. `tree-rebuild` happy path (mock `gh`): tree files + `_toc.md` regenerated;
   `last_tree_regen` stamped; `mode.state` UNCHANGED; **no `STATUS.md` /
   `IMPLEMENTATION-PLAN.md` created at the fixture root**; no monolith (Check 32′-shape
   assert).
2. `tree-rebuild` flat-file-mode refusal (fail-loud message asserted).
3. Pack-surface `mirror-rebuild` fail-loud message NAMES `tree-rebuild` (repointed text).
4. Client-surface `mirror-rebuild` behavior byte-unchanged (regression leg).
5. Status-coherence comparator: divergent label vs blob `Status:` → fail loud listing the
   pack-id; `--force` → blob's `Status:` reaches the tree file.
6. `tracker_edit_entry` stamps `last_tracker_write` on success (and not on failure).
7. Doctor legs: stale-tree WARN fires on `last_tracker_write > last_tree_regen`; status-
   coherence WARN fires on a mocked divergent issue; both name the recovery verbs.
8. Hand-edit overwrite demonstration leg (the contract's teeth): hand-edit a tree file in
   tracker mode, run `tree-rebuild`, assert the hand-edit is gone (one-way write proven by
   test, not prose).

CI: all of the above are mock-based and join the unattended battery; the live C-7 oracle is
untouched (manual, gated — `ARCHITECTURE-BD-204.md` §3.4 model unchanged).

---

## 5. Element 5 — PROJECT-SIDE REQUIREMENTS (the BD-206/BD-207 handoff — consume verbatim)

> **Status: REQUIREMENTS, not implementation.** BD-206/BD-207's POST-BD-204 REFRESH consumes
> this section verbatim. Per P-missed-7, every requirement is stated in PROJECT form: the
> client SSOTs are `docs/pack/PM-CHAT.md` (the client PM-chat operating doc), the client
> stream `_rules.md` files under `docs/project/{backlog,implementation-plan,changelog}/`,
> and the client trinity — NEVER `pack-ops/` files, Pack Chat, pack-* agent names, or
> `maintenance-docs/` records. BD-204's pack realization is the REFERENCE
> IMPLEMENTATION, not the import source.

- **R1 — Mode-conditional client stream contracts.** Each client stream `_rules.md`
  (project-backlog `TD-NNN.md`; project-implementation-plan `phase-N.md`) carries the same
  two-mode Source-of-truth + Write-authority shape as §1.1, in client vocabulary (PM chat /
  project agents as the write authority; `docs/pack/PM-CHAT.md` as the operating doc). The
  client changelog `_rules.md` carries the §1.2 mode-invariance statement (R7).
- **R2 — Client tree-rebuild path.** The SAME `pack tracker tree-rebuild` verb, surface-
  generalized: on the client surface it materializes the client per-entry trees (stream
  keys `project-backlog` / `project-implementation-plan` via the same `per_entry_*` engine,
  per `ARCHITECTURE-BD-204.md` §4.2's `(key, dir)` parameterization), regenerates each
  stream's `_toc.md` on every materialization (DP-4 parity), and performs NO mode flip.
  `mirror-rebuild` retires entirely when BD-206 removes the client monolith (the client arm
  of the `mirror_only` short-circuit + `_tmf_regen_mirror` + the doctor client-arm monolith
  check + `tracker-sidecar.sh` + `tracker-header-snapshot.sh` deletions are BD-207's
  recorded scope — see `backlog/BD-207.md` SCOPE ADDITION).
- **R3 — One-way-overwrite semantics on client surfaces.** The client `_rules.md` files +
  `docs/pack/PM-CHAT.md` state the §1.3-item-3 semantic verbatim (tracker → tree, one-way,
  hand-edits overwritten without detection, NOT a sync), in client vocabulary.
- **R4 — Flat-file-ignores-issues on client surfaces.** Client flat-file mode ignores GH
  Issues for all tooling purposes; client inbound intake remains a human/PM triage channel
  until promoted. Stated in the client `_rules.md` + PM-CHAT.md.
- **R5 — GH-UI coherence parity.** The §3 blob-truth rule + the blocking materialization
  comparator + the doctor advisory leg apply to client-surface entries (TD/phase) with the
  same blob-wins `--force` semantics. The status vocabulary maps per the client taxonomy
  (where `Pending / In Progress / Done` ARE states — `ARCHITECTURE-BD-204.md` DP-3's
  shared-form note); the comparator compares against the CLIENT status set, not the pack's.
- **R6 — STATUS.md dual-mode links (BD-105).** STATUS.md is a convenience view, NEVER
  source of truth (existing disclaimer rule). In client tracker mode, phase rows render the
  BD-105 Option-A dual-link form (`[Phase Title](IMPLEMENTATION-PLAN.md#anchor) ·
  [#N](issue-URL)`); reverse / tree-rebuild strips ` · [#N](URL)` back to single-link form
  in flat-file materialization. STATUS.md regeneration follows the same one-way semantics
  (regenerated on materialization; hand-edits to generated rows are overwritten). BD-105's
  four dispositioned edge cases (orphan / multi-epic / direct edits / closed) bind here.
- **R7 — Client changelog stream stays flat-file in both modes** (same decision as the pack
  stream, stated in the client changelog `_rules.md`; the client reverse's legacy
  `CHANGELOG.md` skeleton-if-absent emit is dispositioned by BD-206's no-mirror
  application).
- **R8 — Freshness-key parity.** `migration.last_tracker_write` + `migration.last_tree_regen`
  are stamped/consumed identically on the client surface; the client doctor leg names the
  client recovery verb. No mtime heuristics.

---

## 6. Element 6 — Commit shaping (recommendation to the planner)

**Two commits, docs-contract FIRST.** Rationale: the §4.2 Check 32′ extension asserts the
`_rules.md` mode sections exist — code-before-docs would land a RED check; docs-before-code
is green at every point. Both commits under the BD-204 anchor (this work realizes BD-204's
operational contract — same-contract LOGICAL FIT; a new-BD-open would require
user-discussion per OQ-1, and none is needed unless the user splits OQ-A out).

| # | Commit | Contents | Check-36 keyword | Manifest |
|---|---|---|---|---|
| 1 | `docs: v11 — BD-204 Mode-3 ops contract on session-load surfaces (pack-chat-only)` | `/backlog/_rules.md` (§1.1), `/changelog/_rules.md` (§1.2), `pack-ops/PACK-CHAT.md` (§1.3), trinity `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` at pack root (§1.4) | `pack-chat-only` — every touched path is in the `PACK-AGENTS.md` § "pack-chat-only files and directories" list (the `/backlog/`+`/changelog/` directories, PACK-CHAT.md, root trinity) | `pack-ops/` touched → run `bash test-fixtures/build.sh --all --clean`; expected EMPTY diff (PACK-CHAT.md / root trinity / `_rules.md` are not fixture-affecting) → stage nothing; if non-empty, stage it |
| 2 | `feat: v11 — BD-204 tree-rebuild verb + status-coherence + doctor/validator repoints (pack-only)` | `scripts/pack-tracker.sh` (verb + OQ-A verbs if approved), `scripts/lib/tracker-migrate-reverse.sh` (`tree_only` arm, `last_tree_regen` stamp, `_tmr_check_status_coherence`, guard-message neutralization), `scripts/lib/tracker-edit.sh` (`last_tracker_write` stamp), `scripts/lib/tracker-migrate-forward.sh` (mirror-only message repoint), `scripts/tracker-migrate.sh` (help), `scripts/lib/tracker-doctor.sh` (legs d/h), `scripts/validate-pack.py` (32′ extension), `scripts/tests/*` (§4.3 legs), `test-fixtures/manifest.txt` | `pack-only` — `scripts/` + `test-fixtures/` are outside `project-template/` + `supporting-docs/` (precedent: HEAD `1c18b28` itself is a `(pack-only)` tracker-libs commit) | `scripts/**` is fixture-affecting (mass-copied) → manifest WILL drift; regenerate + stage in the SAME commit (the two-incident rule) |

Constraints the planner must hold:

- **Neither commit touches `project-template/` or `supporting-docs/`** — the project-side
  analogs are §5 REQUIREMENTS handed to BD-206/207. If any project-side file creeps in, the
  keyword must drop (mixed-scope, no keyword) — but the correct response is to remove the
  creep, not the keyword.
- **Routing:** both commits are MAJOR edits (rule/contract changes; code) → pack-coder
  scoped in, per-commit fresh coder, each followed by the bounded review/fix cycle. The
  Commit-1 trinity edit follows the §1.4 propagation-procedure ordering within the commit.
- **Commit-message shapes** are the approved `docs:` / `feat:` forms; the Commit-2 subject
  binds to BD-204.
- **Sequencing with the pending C-8 commit:** the working tree carries uncommitted BD-204
  C-8 tracker-lib edits (§0). Those land FIRST (their own commit, already in flight);
  Commits 1–2 stack after. The coder for Commit 2 edits the SAME tracker-lib files — fresh
  coder after C-8 lands avoids interleaving.

---

## 7. CONTRADICTION-FOUND (ratified-set conflicts)

**NONE.** Every design element realizes the ratified flat-file + tracker-mode rule sets
without deviation. The single as-built discrepancy found is with the calling prompt's
AS-BUILT FACTS (the mirror-rebuild pack-surface error shape), corrected with evidence at
§0 — it does not touch any ratified rule. The OQ-A verb-surface gap (§0) is a flagged
machinery incompleteness surfaced BY the ratified write-path rule, not a challenge to it.

---

## 8. READ-IN-FULL attestation (per-file direct-read proof, this session)

| # | File | Proof (path + line count, read this session) |
|---|---|---|
| 1 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` | Read in full via Read tool, 579 lines (incl. the complete `## Pack memory` section, lines 140–579). |
| 2 | `/backlog/_rules.md` | Read in full, 95 lines. |
| 3 | `/changelog/_rules.md` | Read in full, 66 lines. |
| 4 | `pack-ops/PACK-CHAT.md` | Read in full, 325 lines (incl. § "File access strategy" lines 44–57 and § "Keeping CLAUDE.md…current" + the rule-change propagation procedure lines 300–325). |
| 5 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md` | Read in full (1271 lines per `wc -l`), three passes: 1–576, 577–1026, 1027–end — covering §2.1, §2.4–2.5, §2.12, DP-1/DP-4, §7 and everything between. |
| 6 | `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_agent_output_rules_applied_block.md` | Read in full, 15 lines. |
| 7 | Section-reads (verified directly, as instructed): `scripts/lib/tracker-edit.sh` (FULL, 347 lines — `tracker_edit_entry`); `scripts/lib/tracker-doctor.sh` (FULL, 304 lines); `scripts/lib/tracker-migrate-forward.sh` (`mirror_only` arm 1321–1410 + Step-10 1955–1999 + grep census); `scripts/lib/tracker-migrate-reverse.sh` (`_tmr_emit_pack_tree` 1000–1129, `_tmr_update_tracker_toml` 1199–1245, orchestrator 1247–1366 + 1455–1646); `scripts/pack-tracker.sh` (FULL, 456 lines — verb table); `scripts/tracker-migrate.sh` (reverse/doctor arms 100–160 + grep); `scripts/lib/per-entry/toc-regenerate.sh` (30–100); `scripts/validate-pack.py` (Check 32′/33 region via grep census); `pack-ops/PACK-AGENTS.md` § pack-chat-only list (130–161); `backlog/BD-206.md`, `backlog/BD-207.md`, `backlog/BD-105.md` (heads); `tracker.toml` (mode keys). |

No named document was derived rather than read; every file above was opened via the
Read/Bash tools this session at HEAD `1c18b28` (+ the pending working-tree edits).

---

## 9. Rules-Applied Verification Block

| Rule (as named in the prompt) | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Bash history this session: git verbs run were `git rev-parse HEAD`, `git status --short`, `git log --oneline -3` — read-only. The sole filesystem writes are the chunked `cat >/>>` writes of THIS file (`maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md`); no other repo file edited; no `add/commit/push/tag/stash/reset/restore/checkout` run. | COMPLIANT |
| **per-action-approval-sub-agents** | No destructive operation run (no `rm -rf`, no `git rm`, no overwrite of any trusted file — the output path was non-existent before this session: `find . -name "ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md"` had no pre-existing hit; filename-uniqueness verified by name construction against the `ARCHITECTURE-BD-204*.md` set). No live GitHub call of any kind: zero `gh` invocations, zero GitHub MCP tool calls; all evidence is local-file reads. | COMPLIANT |
| **preflight-stop-means-stop** | Emitted before the first Write chunk, verbatim: `PREFLIGHT: design complete; 6 elements decided (+1 as-built correction, +1 flagged gap OQ-A); about to Write to maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md`. No parent stop/halt/revert message was received at any point; work ran to completion. | COMPLIANT |
| **agent-output-rules-applied-block** | This table: 8 rows (one per "Rules in force" item), each with quoted measurement evidence; zero empty cells. Per the memory's MUST-READ pointer, the conditional read of `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block is noted: the memory file itself (read in full, 15 lines) supplies the fenced format contract applied here (name + quoted evidence + conclusion per rule; empty = VIOLATED). | COMPLIANT |
| **agents-read-rule-docs-in-full** | §8 attestation table: 6 named files read IN FULL with line counts (CLAUDE.md 579; /backlog/_rules.md 95; /changelog/_rules.md 66; pack-ops/PACK-CHAT.md 325; ARCHITECTURE-BD-204.md 1271 across three contiguous passes; memory file 15) + the instructed section-reads each verified directly (row 7). No named doc's content was derived from summary. | COMPLIANT |
| **architect-doc-vs-reality** | Every as-built claim cites file + symbol, never line numbers, throughout §§0–4 (e.g., `tracker_edit_entry` / `tmf_compose_issue_body`; `tracker_migrate_reverse_run` → `_tmr_emit_pack_tree` → `per_entry_regenerate_toc`; `_tmr_update_tracker_toml` flip-gating; `_tmf_regen_mirror` client-gated Step-10; doctor `tracker_doctor_run` leg (d)). The ONE contradiction with the prompt's AS-BUILT FACTS (mirror-rebuild pack-surface error shape) is stated explicitly with an Empirical-Evidence Block at §0, per the rule's "say so explicitly with evidence" clause. | COMPLIANT |
| **user-prescriptive-authority** | Both ratified rule sets are realized without deviation: §1 lands the flat-file items (1)–(5) and tracker items (1)–(9) on the named surfaces verbatim-semantically; §2 realizes the "working lean" regen cadence and DP-4 item (5); §3 realizes item (4)'s comparator + the requested coherence rule; §7 CONTRADICTION-FOUND is the only challenge channel and is EMPTY ("NONE"). No ratified decision was re-argued; rejected alternatives (§2 verb overload, §3 label-wins/newest-wins) are design-internal choices BELOW the ratified layer. | COMPLIANT |
| **scope-deliverables-to-the-ask** | The doc contains exactly the six prompt elements as §§1–6 (one section per element, each with decision + rationale + exact target surfaces), plus the prompt-required CONTRADICTION-FOUND section (§7), attestation (§8), and this block (§9). The two additions beyond the six elements are both prompt-mandated behaviors, not invention: the §0 as-built correction (rule 6's explicit-discrepancy duty) and OQ-A (flagged as a user-gated gap surfaced by element 1's "who writes what" requirement — with a fallback that keeps it OUT of scope if declined). No project-side implementation, no new check beyond the elements' named surfaces. | COMPLIANT |

---

**End of ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md**
