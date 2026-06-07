# ARCHITECTURE-BD-204 — Pack backlog tree ↔ GH Issues reversible tracker migration (Mode 2 ↔ Mode 3)

> **Agent:** pack-architect. **Mode:** DESIGN ONLY (no source edits, no git verbs, no
> status flips, no implementation). A planner then a coder execute this. **HEAD (verified):**
> `e83aed7` (`git rev-parse HEAD` → `e83aed72a25b5c3033c901b1ff0727f4a5258bae`). **Branch:**
> `v11-dev`. **Date:** 2026-06-05.
>
> **What this doc is.** The implementation design for BD-204 — the pack DOGFOODS moving its
> own backlog SSOT from the per-entry tree (`/backlog/`, BD-203 Mode 2) to GitHub Issues
> (Mode 3), losslessly reversible, built ON the LOCKED tracker/form corpus ADAPTED to the
> no-monolith per-entry world. The design is bounded by the BD-204 three-tier calibration
> (`backlog/BD-204.md:13-16`): HARD constraints satisfied; DEFAULT-from-locked choices adopted
> as the evidence-backed baseline (alternatives surfaced as marked DECISION POINTS only);
> OPEN mechanics resolved here.
>
> **What this doc is NOT.** It is not a re-debate of any LOCKED decision. The form family
> (D-4-V2 / D-16), the `extra_fields` overflow CONCEPT (D-8 / DELTA A2 — carried in the Issue body,
> NOT a sidecar file per DP-2 RESOLVED §2.4.1), the structure split (D-17),
> the template_version dual carrier (D-18), the identifier carrier (V3.3 §6.4), the status
> mapping shape (V3.3 §6.3), the provider abstraction (D-1, BD-060), the no-mirror standard,
> and the D1 doc-governance standard are all USED AS-IS. The prior BD-204 attempt was rolled
> back for silently ignoring the locked form family and reinventing a base64/sidecar carrier;
> this design uses forms-as-primary + the in-body Issue-body carrier for overflow (the
> `.pack-tracker/reverse.sidecar.*` FILE is DROPPED for v11.0 per DP-2 RESOLVED, user 2026-06-06)
> and re-debates nothing.

---

## 0. How to read this doc

- **§1 DECISION POINTS** collects EVERY choice that needs the user: HARD-tier challenges
  (none — see DP-0), DEFAULT-tier alternatives (the write model, the overflow boundary, the
  status matrix, the `_toc.md` cadence), and the COMPLETE status matrix for approval. The
  user adjudicates these before the planner spawns.
- **§2** is the 12 required design areas, each with an Empirical-Evidence Block per state-claim.
- **§3** is the reversibility / lossless audit + the live-scratch-repo test approach.
- **§4** is the tracker-agnostic + surface-generalizable design.
- **§5** is the Rules-Applied Verification Block + the per-READ-IN-FULL-doc attestation.

**Evidence convention.** Every state-claim carries an Empirical-Evidence Block:
`CMD` (the command run) · `OUT` (verbatim output — counts/paths/lines, not paraphrase) ·
`AT` (HEAD `e83aed7`, 2026-06-05) · `INTERP` · `CONCL` (SUPPORTED / NOT-SUPPORTED / PARTIAL).

---

## 1. DECISION POINTS (resolve BEFORE the planner spawns)

These are the ONLY questions that need the user. Everything in §2's OPEN-mechanics tier is
resolved by the architect and does not appear here.

### DP-0 — HARD-tier challenges: NONE

After independently re-measuring the corpus and the built code, the architect raises **zero**
HARD-tier challenges. Every HARD constraint (`backlog/BD-204.md:14`) is satisfiable as written:
pack-only ✓; lossless reversibility incl. repeated on/off + interleaved CRUD ✓ (§2.11); tracker-
agnostic via the provider abstraction ✓ (§4); GA + personal-account features ONLY ✓ (§2.10); NO
monolith ✓ (§2.1/§2.2); the form family is the locked structured carrier ✓ (§2.4); anti-drift
guardrails ✓ (§2.2 Check 29′); full-CRUD true-SSOT ✓ (§2.3); issue-number independence ✓ (§2.7);
surface/tree-generalizable ✓ (§4). The architect therefore challenges nothing in the HARD tier.
The DEFAULT-tier choices below DO need user adjudication because the brief reserves them
(`backlog/BD-204.md:15`).

---

### DP-1 — Mode-3 WRITE MODEL (DEFAULT-tier; `backlog/BD-204.md:15`)

**The choice.** In Mode 3 the tracker is SSOT; the per-entry tree is its regenerated mirror.
Two models for how the tree relates to writes:

- **(A) Read-only regenerated mirror** — the tree is regenerated FROM the tracker on demand;
  all writes go to the tracker via full CRUD (`provider_create/update/close/comment/link`); the
  tree is never hand-edited in Mode 3. Hand-editing a tree file in Mode 3 is a no-op (next
  regen overwrites it).
- **(B) Editable-and-synced mirror** — tree files remain hand-editable in Mode 3 and a sync
  step pushes edits back to the tracker.

**Architect recommendation: (A) read-only regenerated mirror.** Rationale (evidence-backed):

1. **(B) re-creates the dual-writer consistency problem the tracker exists to solve.**
   `DESIGN-BRIEF.md:61` states the tracker "takes over consistency-enforcement duty … the chat
   orchestrates; the tracker is the system of record." An editable tree is a second writer; a
   second writer needs conflict resolution, which is exactly the flat-file decay (`DESIGN-BRIEF.md:34-39`)
   the design eliminates.
2. **(A) keeps full CRUD intact** — the HARD true-SSOT requirement (`backlog/BD-204.md:14`) is
   satisfied because writes target the tracker, and (A) routes ALL writes there. The brief
   gates (A) acceptable "ONLY if writes against the tracker SSOT stay fully CRUD-capable"
   (prompt §5); (A) does exactly that.
3. **(A) is the no-mirror standard's natural Mode-3 form.** `backlog/_rules.md:18-26` makes the
   tree "regenerated from tracker state" in tracker mode; a read-only regenerated mirror IS that.

**Tradeoff (the case for B, surfaced adversarially):** (A) means a pack maintainer who edits a
`/backlog/BD-NNN.md` file in Mode 3 by habit (muscle memory from flat-file mode) loses the edit
on next regen. Mitigation: the regenerated tree carries a per-file banner
(`<!-- regenerated from tracker; edits are overwritten — edit via the chat/tracker -->`) and
`pack tracker doctor` warns on a tree file mtime newer than the last regen. This makes the
no-op LOUD, not silent (consistent with `feedback_fail_loud_delete_old_source.md`).

**RESOLVED (user 2026-06-06): (A) read-only regenerated mirror.** Writes go to the tracker via
full CRUD (`provider_create/update/close/comment/link`); the per-entry tree is a read-only
regenerated mirror of tracker state, never hand-edited in Mode 3. **(B) editable-and-synced —
considered & rejected:** it re-creates the dual-writer consistency problem the tracker exists to
solve (the adversarial case + its banner/doctor mitigation are kept above for the planner's record).

---

### DP-2 — Overflow CARRIER — RESOLVED (user-prescriptive, 2026-06-06): form family + Issue body; NO sidecar file

**RESOLVED (FIXED constraint, user 2026-06-06; not re-debated).** The overflow carrier is the
**FORM FAMILY (structured fields) + the GH Issue BODY (prose + the in-body `pack-extra-fields`
HTML-comment block)**. The separate `.pack-tracker/reverse.sidecar.*` FILE is **DROPPED ENTIRELY
for BD-204 / v11.0.** NOTHING rides a sidecar file.

**HARD INVARIANT (user-imposed):** ALL flat-file / entry content MUST be preserved using the form
family + the entry body (including the in-body `pack-extra-fields` block for `Target:`/`Position:`/
etc.). Nothing rides a sidecar.

**Rationale (user, fixed — recorded, not re-argued):** flat-file mode has no
comments/attachments/logs; the design must be tracker-AGNOSTIC and a GH-specific sidecar format
would not port across trackers (Jira/Linear/etc.). Therefore anything GH-Issues-specific that is
NOT part of the entry body is DROPPED (not preserved) for v11.0. A future, multi-tracker-agnostic
preservation mechanism may be designed later (a future BD), but this is the wrong time.

**Consequence — the field-overflow BOUNDARY** (which fields ride a form field vs the Issue body vs
the in-body `pack-extra-fields` block) is resolved in §2.4 / §2.4.1 bounded by this constraint —
the "spill to a sidecar file" option is GONE. **No user decision remains on DP-2.**

---

### DP-3 — COMPLETE status mapping (DEFAULT-tier; every state → tracker representation)

The LOCKED V3.3 §6.3 BD/TD status table (`ARCHITECTURE-V3.3-DELTA.md:343-350`) covers Open,
Unblocked, Resolved-direct, Resolved-via-promotion, Cancelled, Deprecated. It has **no
`Deferred` row** (C6) — and the pack has **11 live `Deferred` entries**. The form `wi-status`
dropdown ALSO carries `Pending / In Progress / Done` (`work-item.yml:45-53`) which the pack
backlog vocabulary does NOT admit. The built reverse decoder (`tracker-migrate-reverse.sh:192-239`)
has NO `Deferred` branch — it would silently map a deferred entry to Open or Resolved (a
lossless-round-trip FAILURE on 11 entries).

**The COMPLETE matrix proposed (every pack-backlog state covered; for user approval):**

| Flat-file `Status:` | Live count | GH state | `state_reason` | `status:*` label | Lossless reverse decode |
|---|---|---|---|---|---|
| `Open` | 28 | open | — | `status:open` | open + (no/other label) → Open |
| `Unblocked` | 1 | open | — | `status:unblocked` | open + `status:unblocked` → Unblocked |
| **`Deferred`** (NEW) | **11** | **open** | — | **`status:deferred`** | **open + `status:deferred` → Deferred** [NEW reverse branch] |
| `Resolved` | 167 | closed | `completed` | `status:resolved` | closed + completed → Resolved |
| `Deprecated` | 3 | closed | `not_planned` | `status:deprecated` | closed + not_planned + `status:deprecated` → Deprecated |
| `Cancelled` | 1 | closed | `not_planned` | `status:cancelled` | closed + not_planned + (no deprecated label) → Cancelled |

**Design rationale for the `Deferred` row (the C6 gap fill, WITHIN the locked carrier):**

- **`Deferred` is OPEN, not closed.** A deferred entry is deliberately postponed but still live
  (`backlog/_rules.md:59` "deliberately postponed (user-authorized)"). Closing it would assert
  "not happening," which contradicts the lifecycle semantics and would mis-sort it out of
  open-work queries. The disambiguator from `Open`/`Unblocked` is the `status:deferred` label
  (the same mechanism §6.3 already uses for `status:unblocked` to disambiguate two OPEN states).
- **Reverse decode (the built `_tmr_decode_status` extension):** add a `status:deferred → Deferred`
  case in `_tmr_decode_status`'s **open-state `case "$label"` block** (the canonical-object branch's
  trailing `# Open: derive from label` switch — the one the production reverse path reaches),
  parallel to the existing `status:unblocked → Unblocked` case. This is a label-driven
  disambiguation of an OPEN issue — it needs no new GH capability. (The function has a SECOND,
  legacy labels-only switch; see §2.6 for why it is test-only and how it is handled.)

**`Pending / In Progress / Done` reconciliation (the form-vs-vocabulary mismatch):** these three
dropdown options (`work-item.yml:47,48,50`) are NOT pack-backlog states (`backlog/_rules.md:54-62`
admits only Open/Unblocked/Deferred/Resolved/Deprecated/Cancelled). They exist in the shared form
because the form is a SHARED intake surface (BD + the project-side phase-task taxonomy where
`In Progress`/`Done`/`Pending` ARE states per `ARCHITECTURE-V3.3-DELTA.md:322,352-354`). For the
PACK migration: the forward migrator NEVER emits these three for a BD (it maps from the entry's
real `Status:` only); they remain dormant-valid dropdown options for hand-filed intake that the
chat normalizes at triage. **This is a pack-only no-op** — the architect does NOT prune the
shared form (pruning would be a project-side touch → pack-only VIOLATION, and the form is shared).

**RESOLVED (user 2026-06-06): APPROVED — the 6-row matrix is the COMPLETE pack-backlog status
mapping.** The net-new `Deferred` row (open + `status:deferred`, parallel to `status:unblocked`)
is adopted; the `Pending/In Progress/Done` dropdown options are dormant-valid shared-form options
(not pack-backlog states, **not pruned**). **Pruning the shared form — considered & rejected:** it
would be a project-side touch (pack-only VIOLATION) and the form is shared with the project-side
phase-task taxonomy where those three ARE states. Every live pack state is covered; the status
distribution sums to 211 (`28+1+11+167+3+1`).

---

### DP-4 — `_toc.md` regeneration cadence (DEFAULT/NUDGE-tier; BD-203 §3.7 NUDGE #3)

**The choice.** When does `_toc.md` regenerate in Mode 3? `ARCHITECTURE-BD-203-V3.md:266`
nudges: "run on every reverse that materializes the tree."

**Architect recommendation: regenerate `_toc.md` on EVERY tree-materialization in Mode 3** —
i.e., whenever the tree is regenerated from the tracker (per DP-1(A), that is every regen pass,
not only `pack tracker disable`). Rationale: `_toc.md` is a derived index of the tree
(`per_entry_regenerate_toc`, `toc-regenerate.sh:36`); if the tree is regenerated and `_toc.md`
is not, Check 33 (TOC-in-sync) goes RED. Coupling them keeps the no-mirror invariant (tree ⟺
`_toc.md`) always satisfied. This is the cheap, always-correct cadence.

**Tradeoff:** regenerating `_toc.md` on every regen costs one `python3` pass per regen
(`toc-regenerate.sh:57`). At 211 entries this is sub-second; the cost is negligible vs the
RED-CI risk of decoupling. No adversarial alternative survives the cost/benefit.

**RESOLVED (user 2026-06-06): regenerate `_toc.md` on EVERY Mode-3 tree-materialization** (every
regen pass, not only `pack tracker disable`). **The looser "only on disable" cadence — considered &
rejected:** it decouples the tree from `_toc.md` between regens and risks Check 33 (TOC-in-sync)
going RED; the every-regen cost is sub-second at 211 entries, so the looser cadence buys nothing.

---

### DP-5 — Header-snapshot under no-mirror (DEFAULT/RATIFY-tier; BD-203 §3.7 RATIFY #5)

**The choice.** BD-133's header-snapshot (`tracker-header-snapshot.sh`) preserved the monolith's
`# BACKLOG` preamble across reverse round-trips. Under no-mirror there is no monolith header.
`ARCHITECTURE-BD-203-V3.md:268` asks: does a regenerated header belong in human-only `_intro.md`?

**Architect recommendation: RETIRE the header-snapshot mechanism for the pack surface; do NOT
write any regenerated content into `_intro.md`.** Rationale:

- The no-mirror tree has NO monolith preamble to preserve — the per-entry files each carry their
  own line-1 back-pointer (`pe_backpointer_line`, `_lib.sh:300`); there is no shared header.
- `_intro.md` is HUMAN-ONLY with ZERO agent/regenerated content (D1 governance,
  `ARCHITECTURE-BD-203-V3-AMENDMENT.md:179-180`; `backlog/_rules.md:7`). Writing a regenerated
  header into it would VIOLATE D1. The header-snapshot mechanism therefore has no valid
  destination on the pack surface and is retired (not repointed).
- `_intro.md` and `_rules.md` are pack-authored static files; they are NOT tracker-derived and
  do not change across a round-trip. They are simply preserved on disk (the reverse path does
  not touch them).

**Tradeoff:** retiring (vs repointing) means if a future need for a tracker-derived tree header
arises, it needs a new non-`_intro.md` home. That is a future BD, not BD-204 — no live need exists.

**RESOLVED (user 2026-06-06): RETIRE the header-snapshot for the pack surface;** `_intro.md` stays
human-only and is untouched by reverse. **Repointing the snapshot into `_intro.md` — considered &
rejected:** `_intro.md` is human-only with zero regenerated content (D1 governance), so a
regenerated header has no valid destination there; a future tracker-derived-header need is a future
BD, not BD-204.

---

> **DECISION POINTS summary — ALL FIVE RESOLVED (user 2026-06-06).** DP-1 → (A) read-only
> regenerated mirror (writes via full CRUD to the tracker). DP-2 → carrier = form family + Issue
> body incl. the in-body `pack-extra-fields` block; the sidecar FILE is DROPPED for v11.0. DP-3 →
> APPROVED: the 6-row status matrix incl. the NEW `Deferred` row (`Pending/In Progress/Done` =
> dormant-valid shared-form options, not pruned). DP-4 → regenerate `_toc.md` on EVERY Mode-3
> tree-materialization. DP-5 → RETIRE the header-snapshot for the pack surface (`_intro.md` stays
> human-only, untouched by reverse). No HARD-tier challenges; every decision point is resolved.
> The §2 OPEN mechanics are architect-resolved.

---

## 2. The 12 design areas

### 2.1 SSOT / mirror model realized

**Model (all three modes):**

- **Flat-file mode (Mode 1 — pre-BD-203, gone):** monolith was SSOT. Deleted at BD-203. N/A here.
- **Per-entry flat mode (Mode 2 — today):** the per-entry tree `/backlog/BD-NNN.md` + `_toc.md`
  is the SOLE SSOT and readable form. NO monolith.
- **Tracker mode (Mode 3 — BD-204 target):** GH Issues is the SSOT. The per-entry tree is a
  **read-only regenerated mirror** of tracker state (DP-1(A)). NO monolith, ever.

**How the tree is regenerated FROM the tracker (the Mode-3 regen path):**

1. `provider_list` (the read op, `tracker-provider.sh:125`) enumerates pack-owned Issues
   (filtered by the `work-item` label + `pack-id` marker — lane separation, §2.8).
2. For each Issue, `_tmr_reverse_reconstruct` (`tracker-migrate-reverse.sh:506`) builds an
   in-memory entry object (`pack_id/title/status/type/blockers/unblocks/description/context/
   resolution` + the in-body `pack-extra-fields` block overflow — no sidecar file).
3. The reverse emitter writes the per-entry tree DIRECTLY (one file per entry via
   `pe_write_atomic` + `pe_backpointer_line`, §2.2) — NOT a monolith.
4. `per_entry_regenerate_toc pack-backlog /backlog` regenerates `_toc.md` (DP-4).

This is the SAME reverse reconstruction the disable path uses; in Mode 3 it is the routine
regen-from-SSOT (DP-1(A)), and at `pack tracker disable` it is the final materialization that
hands SSOT back to the tree (Mode 3 → Mode 2).

> **Empirical-Evidence Block (no-mirror standard is landed + the tree is the SSOT today).**
> `CMD`: `grep -n "no monolithic mirror\|SOLE source of truth" backlog/_rules.md`
> `OUT`: `_rules.md:18-26` — "The per-entry tree at `/backlog/` (plus its generated
> `/backlog/_toc.md` index) is the **SOLE source of truth and readable form** … **There is no
> monolithic mirror.** The former `pack-ops/BACKLOG.md` monolith was deleted at BD-203."
> `AT`: HEAD `e83aed7`, 2026-06-05. `INTERP`: the no-mirror Mode-2 SSOT is the landed standard;
> Mode 3 layers tracker-as-SSOT on top with the tree as regenerated mirror. `CONCL`: SUPPORTED.

> **Empirical-Evidence Block (the per-entry write API exists for the direct-emit path).**
> `CMD`: `grep -n "pe_write_atomic\|pe_backpointer_line\|per_entry_regenerate_toc" scripts/lib/per-entry/_lib.sh scripts/lib/per-entry/toc-regenerate.sh`
> `OUT`: `_lib.sh:300 pe_backpointer_line()`, `_lib.sh:393 pe_write_atomic()`,
> `toc-regenerate.sh:36 per_entry_regenerate_toc()`. `AT`: HEAD `e83aed7`, 2026-06-05.
> `INTERP`: the engine exposes atomic per-file write + back-pointer + toc regen — the reverse
> emitter reuses these (no new file-shape contract invented). `CONCL`: SUPPORTED.

---

### 2.2 Monolith-machinery retire/repoint, per site (measure-then-bound)

Per `ci-guard-measure-then-bound`, every monolith site is MEASURED first, categorized
KEEP/STRIP/REPOINT/RETIRE, given a fix-recipe, and the projected post-design state is verified
to have NO site still expecting a monolith.

> **Empirical-Evidence Block (complete monolith-site census in the tracker libs).**
> `CMD`: `grep -rn "pack-ops/BACKLOG.md\|pack-ops/CHANGELOG.md\|BACKLOG.md\|CHANGELOG.md" scripts/lib/tracker-migrate-forward.sh scripts/lib/tracker-migrate-reverse.sh scripts/lib/tracker-agent-read.sh scripts/lib/tracker-doctor.sh scripts/lib/tracker-header-snapshot.sh`
> `OUT` (load-bearing runtime sites, not comments): forward READ `tracker-migrate-forward.sh:733`
> (`backlog_path="$repo_root/pack-ops/BACKLOG.md"`); forward Step-10 mirror regen `:1202`
> (`_tmf_regen_mirror "$backlog_path"`); reverse EMIT `tracker-migrate-reverse.sh:1059-1060`
> (`backlog_out=".../pack-ops/BACKLOG.md"`, `changelog_out=".../pack-ops/CHANGELOG.md"`);
> agent-read `tracker-agent-read.sh:264,267` (`mirror_path=".../pack-ops/BACKLOG.md"`);
> doctor `tracker-doctor.sh:122` (`backlog_path=".../pack-ops/BACKLOG.md"`);
> header-snapshot `tracker-header-snapshot.sh:1-28` (snapshots `# BACKLOG` monolith preamble).
> `AT`: HEAD `e83aed7`, 2026-06-05. `INTERP`: 6 distinct runtime monolith sites on the pack
> surface, all dormant in flat-file mode (none runs without `mode.state=tracker` + `forward_complete`).
> `CONCL`: SUPPORTED.

**The retire/repoint table (every site; pack-surface branch ONLY — `surface=="pack"`):**

| # | Site (`file:line`) | Current behavior | Category | Fix-recipe |
|---|---|---|---|---|
| C1a | `tracker.toml.pack-example:33-40` `[mirror]` table | declares `location_backlog="BACKLOG.md"` etc. | **RETIRE (pack)** | The pack Mode-3 `tracker.toml` OMITS the `[mirror]` table (no monolith to point at). The EXAMPLE file's `[mirror]` table stays for the client surface (BD-207 owns it); but Check 29's schema validator must stop REQUIRING `[mirror]` for the pack live config — see C1b. |
| C1b | `validate-pack.py:2626-2643` (`[mirror]` required keys) + `:2699-2778` (`_check_mirror_staleness`) = Check 29 | requires `mirror.location_*`; FAILs if live tracker.toml is tracker-mode + the mirror file is missing/stale | **REPOINT (Check 29′)** | See §2.2.C1 below — Check 29 must not fail the no-mirror pack config. |
| C2a | `tracker-migrate-forward.sh:733` (forward READ input) | reads `pack-ops/BACKLOG.md` as migration source | **REPOINT** | pack-surface branch reads the TREE: enumerate `/backlog/*.md` (via `pe_list_entry_files`), parse each entry → the same entries-JSON `tmf_parse_backlog` produces. The monolith parse path stays for the client branch (BD-207). |
| C2b | `tracker-migrate-forward.sh:1202` (Step-10 mirror regen) | regenerates `pack-ops/BACKLOG.md` after forward | **RETIRE (pack)** | pack-surface branch SKIPS Step-10 entirely (no mirror to regen under no-mirror; regenerating one VIOLATES `feedback_fail_loud_delete_old_source.md`). The tree IS the mirror and is regenerated by the reverse/regen path, not by a forward mirror-write. |
| C3 | `tracker-migrate-reverse.sh:1059-1060` (reverse EMIT target) | writes `pack-ops/BACKLOG.md` + `CHANGELOG.md` | **REPOINT** | pack-surface branch emits the per-entry TREE directly (§2.1 path); `_tmr_emit_backlog` pack branch calls `pe_write_atomic` per entry instead of writing the `# BACKLOG` monolith. CHANGELOG is OUT of scope (stays flat-file per `backlog/BD-204.md:21`); the pack reverse does not emit a changelog monolith. |
| C4 | `tracker-agent-read.sh:264,267` (agent read) | greps `pack-ops/BACKLOG.md` for a BD block | **REPOINT** | pack-surface branch reads `/backlog/BD-NNN.md` directly (the file IS the entry; no grep-a-monolith needed). |
| C7b | `tracker-doctor.sh:122` + `:145-154` (mirror-freshness check) | mtime-checks `pack-ops/BACKLOG.md` mirror header | **REPOINT** | pack-surface branch checks the TREE's regen-state (last regen marker / `_toc.md` freshness) instead of a monolith mtime; the "mirror header" concept maps to the tree-regen cadence (DP-4). |
| C7c | `tracker-header-snapshot.sh:1-28` (header preserve) | snapshots `# BACKLOG` preamble | **RETIRE (pack)** | Per DP-5: no monolith header under no-mirror; `_intro.md` is human-only (D1) and cannot host regenerated content. The reverse pack-surface path does NOT call `tracker_header_snapshot_capture` (`tracker-migrate-reverse.sh:1109`). |

**§2.2.C1 — the BLOCKER (Check 29 `[mirror]` + staleness) reconciliation.** This is the net-new
surface the restart doc under-scoped (`PACK-REVIEW-BD-203-VS-LOCKED-COMPATIBILITY.md:57-66`).
Measure-then-bound:

> **Empirical-Evidence Block (where a no-mirror live config hard-FAILs inside `_check_mirror_staleness`).**
> `CMD`: `sed -n '2733,2760p' scripts/validate-pack.py` (the `_check_mirror_staleness`
> mirror-handling region).
> `OUT`: after the `mode='tracker'` + `forward_complete=true` gates, `_check_mirror_staleness`
> FAILs at the `last_forward_run` branch (`fail("...migration.last_forward_run is missing/empty;
> cannot compare mirror timestamps")`), then at the `[mirror]` table branch
> (`if not isinstance(mirror, dict): fail("[mirror] table missing/malformed; cannot check
> mirror-staleness")`), then per missing mirror FILE (`if not mirror_path.is_file(): fail("mirror
> file ... does not exist on disk")`). `AT`: HEAD `e83aed7`, 2026-06-06. `INTERP`: a live no-mirror
> pack `tracker.toml` (`mode='tracker'` + `forward_complete=true`, `[mirror]` pointing at the
> deleted monoliths or `last_forward_run` unset) hard-FAILs inside `_check_mirror_staleness` at
> these branches — NOT at the schema `is_file()` leg primarily; the guard must be added at the TOP
> of `_check_mirror_staleness`, ahead of these branches. (The schema leg `_require("mirror", dict)`
> validates the EXAMPLE files only; those KEEP `[mirror]` — see below.) `CONCL`: SUPPORTED.

- **The EXAMPLE files** (`tracker.toml.pack-example`, `tracker.toml.project-example`) are
  validated by Check 29's schema leg (`:2814-2815`). These are NOT live configs; they are shipped
  templates. **KEEP** the `[mirror]` table in BOTH example files (the client surface still uses it
  until BD-206/207; pruning the project example is a project-side touch = pack-only VIOLATION).
- **The LIVE pack `tracker.toml`** (created by BD-204's forward migration) is validated by the
  staleness leg (`_check_mirror_staleness`, `:2820-2822`). **REPOINT Check 29′:** the staleness
  leg must recognize the no-mirror pack surface — when the live config has NO `[mirror]` table (or
  a `mirror.enabled=false` / `mirror.location_backlog` absent), the staleness check is **N/A**
  (soft-pass), exactly as it already soft-passes for flat-file mode (`:2722-2725`). The fix-recipe:
  add a guard at the top of `_check_mirror_staleness` — `if "mirror" not in cfg or not cfg["mirror"].get("enabled"): ok("no [mirror] table / mirror disabled — no-mirror surface, staleness N/A"); return`.
- **Allowlist sizing (measure-then-bound step 4):** the only legitimate live-config shapes are
  (a) flat-file [already N/A], (b) tracker + no `[mirror]` [the no-mirror pack surface — NEW N/A],
  (c) tracker + `[mirror]` pointing at real files [the client surface, unchanged]. The guard is
  sized to soft-pass (a) and (b), and to keep enforcing staleness for (c). It does NOT widen to
  swallow a tracker config that CLAIMS a mirror but is missing it (that still FAILs — correct).

**ENUMERATE-ENCODING-SURFACES for Check 29′.** The surfaces that encode Check 29's expected state:
the validator function (`_check_mirror_staleness` + `_validate_tracker_toml`), its test
(`grep` for the Check-29 test — the planner enumerates `test-*tracker*`/`test-validate-pack*`
that pin Check 29 output banners), the `tracker.toml.pack-example` schema, and any CI workflow
referencing Check 29. All update in lock-step (asymmetric coverage = audit gap, per
`enumerate-encoding-surfaces`).

**Check 32′ interaction (no-monolith guard MUST stay green).** Check 32′
(`validate-pack.py:3178-3264`) asserts `pack-ops/BACKLOG.md` is ABSENT. The C2b/C3 retire-recipes
guarantee the pack forward/reverse paths NEVER write a monolith, so Check 32′ stays green through
forward + reverse + regen.

> **Empirical-Evidence Block (Check 32′ forbids a pack monolith — the retire-recipes must honor it).**
> `CMD`: `sed -n '3178,3188p;3222,3229p' scripts/validate-pack.py`
> `OUT`: `:3185-3187` "Assert the monolith file (the stream's former `mirror_relative`) … FAIL if
> the monolith is present"; `:3222-3229` inverted assertion: tree present ⇒ monolith MUST be absent.
> `AT`: HEAD `e83aed7`, 2026-06-05. `INTERP`: any retire-recipe that regenerated a monolith would
> trip Check 32′ RED — so C2b (skip Step-10) and C3 (emit tree not monolith) are REQUIRED, not
> optional. `CONCL`: SUPPORTED.

**Projected post-design state:** after the 7 retire/repoint recipes, NO pack-surface runtime site
reads or writes a monolith; Check 32′ green (no monolith), Check 29′ green (staleness N/A for the
no-mirror live config), Check 33 green (tree ⟺ `_toc.md`). VERIFIED against the projected state.

---

### 2.3 Full CRUD provider surface

> **Empirical-Evidence Block (the provider exposes CRUD ops but the forward path is create-only).**
> `CMD`: `grep -n "provider_create\|provider_update\|provider_close\|provider_delete\|provider_get\|provider_list" scripts/lib/tracker-provider.sh` then `grep -rn "provider_update" scripts/lib/`
> `OUT`: provider surface present — `:125 provider_list`, `:126 provider_get`, `:128 provider_create`,
> `:129 provider_update`, `:130 provider_close`, `:132 provider_comment`, `:136 provider_link`. But
> `provider_update` is called ONLY in `tracker-promote.sh:801,1215` (project-side TD-promotion) —
> NOT in `tracker-migrate-forward.sh` (forward is create-only: Step 4/5 create + Step 10 mirror).
> No `provider_delete` exists. `AT`: HEAD `e83aed7`, 2026-06-05. `INTERP`: the abstraction has
> create/read/update/close/comment/link but the MIGRATION forward path wires only create; for the
> tracker to be a true SSOT, ongoing CRUD must be wired. `CONCL`: SUPPORTED.

**Design — wire CRUD against the tracker SSOT (Mode 3 steady-state ops):**

- **Create** — already wired (forward migration Step 4/5; `provider_create`). New BD opened in
  Mode 3: the chat calls `provider_create` with the form field shape, then regenerates the tree
  (DP-1(A)).
- **Read** — `provider_list` / `provider_get` (already exist); the regen path (§2.1) and
  agent-read (C4 repoint) use these. Identity is keyed on the `pack-id` marker, NOT issue number
  (§2.7).
- **Update** — wire `provider_update` (exists, `:129`, currently unwired for BD) into the Mode-3
  edit path: a `Status:` flip, a `Resolution:` fill, an edited `Description:` → `provider_update`
  on the issue body/labels + a `provider_close`/reopen when the status crosses the open/closed
  boundary (DP-3 matrix). This is the new wiring BD-204 adds (parallel to how
  `tracker-promote.sh:801` already calls it project-side — reuse that call shape).
- **Delete** — the pack lifecycle has NO hard-delete (entries resolve in place by status flip,
  `backlog/_rules.md:64-66`; deprecation/cancellation are CLOSED states, not deletions). So the
  CRUD "D" maps to **close-with-state_reason** (`provider_close`, the Cancelled/Deprecated rows of
  DP-3), NOT a destructive `provider_delete`. The architect does NOT add a `provider_delete` op —
  it has no lifecycle use and adding it widens the abstraction with no consumer (anti-pattern).
  This is a property-fit decision: the pack's "delete" semantic IS close-with-reason.

**Tracker-agnostic note:** all four CRUD verbs are provider ops (`provider_*`), never direct `gh`
calls — the migration machinery calls the abstraction (§4), so a Jira/Linear backend implements
the same four verbs. `close` (not `delete`) as the terminal op is portable: every tracker has a
close/resolve transition; not every tracker permits issue deletion (GH `gh issue delete` exists
but Jira "delete issue" is a restricted permission) — so close-as-terminal is the safer cross-
tracker floor (`DESIGN-BRIEF.md:252` status-taxonomy-is-backend-declared).

---

### 2.4 Overflow carrier — field-overflow boundary (carrier = form family + Issue body; NO sidecar file)

The carrier is RESOLVED at DP-2 (user 2026-06-06): the **form family + the GH Issue BODY** (prose +
the in-body `pack-extra-fields` HTML-comment block). The `.pack-tracker/reverse.sidecar.*` FILE is
DROPPED for v11.0 — nothing rides a sidecar. The architect resolves the BOUNDARY: which fields ride
a form field vs the Issue body vs the in-body `pack-extra-fields` block. There is NO "spill to a
sidecar file" option.

> **Empirical-Evidence Block (the built reverse reconstruct field-set vs real pack-entry fields).**
> `CMD`: `grep -n "pack_id\|status\|type\|scope\|severity\|blockers\|unblocks\|description\|context\|resolution" scripts/lib/tracker-migrate-reverse.sh | sed -n '1,12p'` and inspection of `backlog/BD-195.md`/`BD-204.md`.
> `OUT`: reconstruct carries `pack_id,title,body,labels,status,type,scope,severity,blockers,
> unblocks,description,context,resolution` (`tracker-migrate-reverse.sh:506,527,553-565`). Real pack
> entries ALSO carry `Target:`, `Position:`, `Blockers:`-with-prose, parenthetical titles
> (`BD-195 (Code Red 3)`), and large multi-block bodies (`Segments:`/`Steps:`/`State:`). `AT`: HEAD
> `e83aed7`, 2026-06-05. `INTERP`: the form field-set covers the common BD fields; pack-specific
> fields (`Target:`/`Position:`) and structured sub-blocks exceed it. `CONCL`: SUPPORTED.

**Field-overflow boundary table (USER confirms per DP-2):**

| Pack entry field | Carrier | Rationale |
|---|---|---|
| `Type:` (kind) | form dropdown `wi-kind` → no label (informational) / body | finite enum, METHODOLOGY Part 7 |
| `Status:` | form dropdown → `status:*` label + open/closed (DP-3) | drives the state machine (D-17 structured) |
| `Blockers:` | first-class `blocked-by` links (BD-111) + `wi-blockers` body | finite ID refs drive links |
| `Unblocks:` | `wi-unblocks` body (informational) | inverse of blockers; no link semantics |
| `File/Symbol:` | `wi-file-symbol` input → body | free-form (D-17 textarea) |
| `Description:`/`Context:`/`Resolution:` | `wi-description`/`wi-context`/`wi-resolution` body | free-text prose (D-17) |
| **`Target:`** (e.g. "v11.0") | **in-body `pack-extra-fields` block** (Issue body) | pack-specific, no form field; lives IN the Issue (SSOT); rendered inline into the regenerated entry |
| **`Position:`** | **in-body `pack-extra-fields` block** (Issue body) | pack-specific ordering hint, no form field; in-Issue, rendered inline |
| **`Alias:`/`Surfaced:`/`Paused:`/`Problem:`/`Out of scope:`/`References:`/`Quality bar:`** (any other named entry field) | **Issue BODY** (free-text section) or in-body `pack-extra-fields` (named scalar) | every leading-label entry field maps to the body; none is orphaned (§2.4.1 census) |
| **structured sub-blocks** (`Segments:`/`Steps:`/`State:`/`Goal:`/`Scope:`/`Quality bar:` in large entries) | **Issue BODY verbatim** (D-17 free-text); any NAMED scalar field needing parseable recovery → the in-body `pack-extra-fields` block | the body is the faithful free-text carrier; prose preserved verbatim; no sidecar |
| parenthetical title (`(Code Red 3)`) | identity carrier (§2.7), NOT a field | title text, round-trips via the ID carrier |

**Boundary principle (the locked model, property-fit-verified):** a field rides a FORM field iff
a finite enum drives a label/link/state-transition (D-17, `ARCHITECTURE-V3.3-DELTA.md:312`);
otherwise it rides the Issue BODY (free-text prose, byte-faithful) or, if it is a named pack field
the form grammar cannot name, the in-body `pack-extra-fields` HTML-comment block (which lives IN
the Issue body, the SSOT). There is NO sidecar file. No pack field has "nowhere to go" — every
named entry field maps to a form field or the Issue body (§2.4.1 census proves zero orphaned
fields). The large-entry stress case (BD-195's `Segments:`/`Steps:`/`Goal:`/`Scope:`) rides the
Issue body verbatim — the body-faithfulness audit (§3) proves it.

### 2.4.1 Overflow physical home — DROP the sidecar file; carrier = form family + Issue body (DP-2 RESOLVED)

> **RESOLVED, FIXED constraint (user 2026-06-06).** DROP the `.pack-tracker/reverse.sidecar.*`
> file ENTIRELY for BD-204 / v11.0. ALL flat-file / entry content is preserved using the FORM
> FAMILY (structured fields) + the GH Issue BODY (prose + the in-body `pack-extra-fields`
> HTML-comment block). NOTHING rides a sidecar file. This section RESOLVES DP-2; it replaces the
> earlier "retain the sidecar for non-round-tripping artifacts" position, which is withdrawn.

**Why the sidecar is dropped (user rationale, recorded — not re-debated).** The locked sidecar was
a v10-monolith-era construct (`ARCHITECTURE.md` §6.6 / §6.6.1) for data the FLAT GRAMMAR could not
hold. Two facts make it the wrong choice for v11.0: (a) flat-file mode has no
comments/attachments/logs, so there is nothing flat-side for a sidecar to "preserve"; (b) a
GH-Issues-specific sidecar FORMAT would NOT port across trackers (Jira/Linear/etc.), violating the
HARD tracker-agnostic requirement (`backlog/BD-204.md:14`). So anything GH-Issues-specific that is
NOT part of the entry body is DROPPED for v11.0 (§2.4.2). A future, multi-tracker-agnostic
preservation mechanism is a FUTURE BD, not v11.0.

**The carrier, stated once.** Round-tripping NAMED pack fields (`Target:`/`Position:`/any future
v11.x named field) live IN the GH Issue BODY as a hidden HTML-comment block, parallel to the
existing marker trio (`work-item.yml:103-105`):

```
<!-- pack-extra-fields:
Target: v11.0
Position: v11.0 launch gate; after BD-203, before BD-197
-->
```

This block IS in the Issue body — so the tracker is the SOLE SSOT for these fields (HARD true-SSOT,
`backlog/BD-204.md:14`) and they cannot go missing independently of the Issue. On regen, the block
is read back and rendered INLINE into `/backlog/BD-NNN.md` (one-file-read; §3.1 byte-faithful). The
prose sub-blocks (`Description:`/`Context:`/`Resolution:`/`Goal:`/`Scope:`/`Steps:`/`Segments:`/
`State:`/`Problem:`/`Out of scope:`/`References:`/`Quality bar:`) ride the visible Issue body
verbatim (D-17 free-text). No sidecar file is written or read on the pack surface.

**§2.4.2 — Zero-orphaned-fields verification (every entry field maps to a form field or the body).**

Per the HARD invariant, every leading-label field in a real pack entry must land in a form field or
the Issue body — none may be orphaned by the sidecar drop.

> **Empirical-Evidence Block (every named field across the stress set maps to form/body; zero orphaned).**
> `CMD`: `for f in backlog/BD-195.md backlog/BD-204.md backlog/BD-167.md backlog/BD-185.md; do grep -nE '^[A-Z][A-Za-z/ -]*:' "$f"; done` (BD-167b deleted by BD-211 — its FORMER fields now live as an in-body section of BD-167; the field census is unchanged because folding preserved every field, so BD-167 is read in its place)
> `OUT` (distinct leading-label fields found): `Type:`, `Status:`, `Resolved:`, `Alias:`,
> `Surfaced:`, `Goal:`, `Scope:`, `Quality bar:`, `Steps:`, `Position:` (BD-195, the large entry);
> `Type:`, `Status:`, `Target:`, `Blockers:`, `Unblocks:`, `Problem:`, `Scope:`, `Out of scope:`,
> `References:`, `Resolved:`, `Position:` (BD-204); `Type:`, `Status:`, `Blockers:`, `Unblocks:`,
> `Description:`, `Resolved:` (BD-167, incl. the folded former-167b sub-entry section — same field
> set, no suffix); `Type:`, `Status:`, `Paused:`, `Blockers:`,
> `Unblocks:`, `File/Symbol:`, `Description:`, `Resolved:` (BD-185). `AT`: HEAD
> `9fb29a5`, 2026-06-06. `INTERP`: mapping — `Type:`/`Status:`/`Blockers:`/`Unblocks:`/`File/Symbol:`/
> `Description:`/`Context:`/`Resolution:` → form fields (`wi-*`, §2.4 table); `Resolved:` → form
> `wi-resolution`/body; `Target:`/`Position:` → in-body `pack-extra-fields` block; `Alias:`/`Surfaced:`/
> `Paused:`/`Goal:`/`Scope:`/`Quality bar:`/`Steps:`/`Problem:`/`Out of scope:`/`References:` → Issue
> BODY (free-text sections, verbatim). EVERY field lands in a form field or the Issue body; NONE
> requires a sidecar; ZERO orphaned. `CONCL`: SUPPORTED.

**`template_version` + `template_archive_path` survive without a sidecar.** `template_version` is a
DUAL carrier per D-18 — its in-body marker `<!-- template_version: work-item-v11.0 -->`
(`work-item.yml:104`) is already IN the Issue body (no sidecar needed). `template_archive_path` is
NOT stored at all: it is DERIVABLE from `template_version` by the documented archive-path convention
(`maintenance-docs/v11-research/templates-archive/<version>/`, `ARCHITECTURE-V3.1-DELTA.md:215-217`),
so it needs no carrier.

> **Empirical-Evidence Block (`template_version` is an in-body marker; `template_archive_path` is derivable).**
> `CMD`: `grep -n 'template_version\|pack-extra-fields\|pack-id' .github/ISSUE_TEMPLATE/work-item.yml` ; `sed -n '213,217p' maintenance-docs/v11-research/ARCHITECTURE-V3.1-DELTA.md`
> `OUT`: `work-item.yml:104 <!-- template_version: work-item-v11.0 -->` (in the body markdown
> trailer, `:100-105`); `ARCHITECTURE-V3.1-DELTA.md:215-217` documents the archive path as
> `templates-archive/<template_version>/SCHEMA.md`. `AT`: HEAD `e83aed7`, 2026-06-06. `INTERP`:
> `template_version` rides the Issue body marker (D-18 dual carrier) — no sidecar; the archive path
> is a deterministic function of `template_version`, so it is recomputed, not stored. Both survive
> the sidecar drop. `CONCL`: SUPPORTED.

**§2.4.3 — GH-only NON-entry artifacts are DROPPED on reverse (by decision, v11.0).** Reactions,
comment threads, attachment URLs, and the event/audit log (`ARCHITECTURE.md:1160-1168` — the §6.6
"does not roundtrip" data) are NOT preserved on reverse for v11.0. They are dropped by decision —
they are GH-Issues-specific, not entry content, and would not port across trackers. *Future-version
deferral note:* a tracker-agnostic preservation mechanism for such non-entry artifacts is a FUTURE
BD, not v11.0 (per the user's DP-2 rationale).

**The lossless contract (refined by the drop).** The contract covers ENTRY content only:
`flat entry → (form fields + Issue body) → flat entry == original`. GH-only extras are OUT of the
contract by decision (§2.4.3). No sidecar file participates in the round-trip.

#### Rules-Applied mini-block (§2.4.1 — DP-2 RESOLVED, sidecar dropped)

| Rule | Evidence | Conclusion |
|---|---|---|
| **Empirical-Evidence Blocks (zero-orphaned-fields claim)** | §2.4.2 block: the leading-label field census across BD-195 (large + parenthetical title) / BD-204 / BD-167 (incl. the folded former-167b section; post-BD-211 suffix-free) / BD-185 maps EVERY field to a form field or the Issue body — `Type/Status/Blockers/Unblocks/File-Symbol/Description/Context/Resolution`→form; `Target/Position`→in-body `pack-extra-fields`; `Alias/Surfaced/Paused/Goal/Scope/Quality bar/Steps/Problem/Out of scope/References`→Issue body. ZERO orphaned. Plus the `template_version` in-body marker + derivable `template_archive_path` block. All at HEAD `9fb29a5`, 2026-06-06, verbatim, SUPPORTED. | COMPLIANT |
| **HARD invariant honored (form family + entry body; nothing on a sidecar)** | All content rides the form family + the Issue body (incl. the in-body `pack-extra-fields` block); the `.pack-tracker/reverse.sidecar.*` file is DROPPED; §2.4.3 explicitly drops GH-only non-entry artifacts (reactions/comments/attachments/audit log) with a future-BD deferral note. | COMPLIANT |
| **Tracker-agnostic (the drop's own rationale)** | The dropped sidecar FORMAT was GH-specific and non-portable; the in-body `pack-extra-fields` block is a plain HTML comment in the issue body/description — a field every tracker has — so the carrier ports (Jira/Linear/etc.). No GH-specific non-entry format survives in the contract. | COMPLIANT |
| **Pattern-matching out of context** | Property-fit verified: the v10-monolith sidecar FILE's "flat grammar cannot hold it" rationale does NOT hold (the inline per-entry tree holds named scalars; flat mode has no comments/logs); the in-body HTML-comment carrier is reused because it MATCHES the sibling `pack-id`/`template_version` markers' property (`work-item.yml:103-105`). | COMPLIANT |
| **Scope held** | DP-2 RESOLVED + every sidecar reference swept (§2.1/§2.4/§2.4.1/§2.10/§2.11/§2.12/§3.1/§3.2/§4.3/§5); DP-1/DP-3/DP-4/DP-5 untouched; code remove-vs-dormant flagged to planner/coder, not decided. | COMPLIANT |

---

### 2.5 Mode-3 write model

Resolved at DP-1 (user 2026-06-06): **read-only regenerated mirror (A)**, with full CRUD against
the tracker SSOT (§2.3). The tree is regenerated from tracker state; tree files are not
authoritative in Mode 3. The brief reserved the write model to the DEFAULT tier; the user adopted
(A) and the adversarial alternative (B) was considered & rejected (its failure mode is recorded at
DP-1 for the planner).

---

### 2.6 Complete status mapping

Resolved at DP-3: the 6-row matrix, with the NEW `Deferred` row (open + `status:deferred`, parallel
to `status:unblocked`) and the `Pending/In Progress/Done` disposition (dormant-valid shared-form
options, not pack states, not pruned). The reverse decoder gains a `status:deferred → Deferred`
case in `_tmr_decode_status`'s **open-state `case "$label"` block** (the canonical-object branch's
`# Open: derive from label` switch), parallel to the existing `status:unblocked → Unblocked` case
(see §2.6.1 for the two-switch determination).

> **Empirical-Evidence Block (the built reverse decoder has NO `Deferred` branch — the gap is real in code).**
> `CMD`: `sed -n '192,239p' scripts/lib/tracker-migrate-reverse.sh`
> `OUT`: in `_tmr_decode_status`, the canonical-object **open-state `case "$label"`** (the
> `# Open: derive from label` switch) maps `status:unblocked→Unblocked`, else `Open`; the
> closed-state `case "$state_reason"` maps `completed→Resolved`,
> `not_planned`+`status:deprecated`→`Deprecated`, else `Cancelled`. NO `Deferred` case in either.
> `AT`: HEAD `e83aed7`, 2026-06-06.
> `INTERP`: a deferred BD forward-migrated as open+`status:deferred` would reverse-decode to `Open`
> (the open-branch default) — a lossless FAILURE on all 11 deferred entries unless the new branch is
> added. `CONCL`: SUPPORTED.

> **Empirical-Evidence Block (status distribution sums to the entry count).**
> `CMD`: `grep -rh "^Status:" backlog/*.md | sort | uniq -c | sort -rn` ; `ls backlog/ | grep -cE '^BD-[0-9]+\.md$'`
> `CMD`: `for f in backlog/BD-[0-9]*.md; do awk '/^Status:/{print; exit}' "$f"; done | sort | uniq -c` (ENTRY-LEVEL — the first `^Status:` line per file; a bare `grep -h '^Status:'` would double-count BD-167/BD-169, which each carry a second in-body `Status:` from their folded former-167b/169b sub-entry sections)
> `OUT`: `167 Resolved, 28 Open, 11 Deferred, 3 Deprecated, 1 Unblocked, 1 Cancelled`; entry-file
> count `211`. `28+1+11+167+3+1 = 211`. `AT`: HEAD `9fb29a5`, 2026-06-06 (re-measured post-BD-211 —
> the canonical count regex is `^BD-\d+\.md$`, no suffix admission; BD-211 folded BD-167b/BD-169b
> into their parents, so the count is 211 not 212 and the entry-level Resolved total is 167 not 168 —
> 168 was a line-count artifact double-counting the two folded sub-entry `Status: Resolved` lines).
> `INTERP`: the DP-3 matrix covers every live state with zero unmapped entries; the count reconciles
> exactly at the entry level. `CONCL`: SUPPORTED.

#### §2.6.1 — `_tmr_decode_status` has TWO label switches; which is in-scope for the pack round-trip

`_tmr_decode_status` contains TWO switches that BOTH map `status:unblocked` and BOTH lack a
`Deferred` case: (1) a **legacy labels-only** `case "$label"` reached only when the input's first
char is `[` (a JSON label-array), and (2) the **canonical-object open-state** `case "$label"`
(`# Open: derive from label`) reached when the input is a full Issue JSON object. The design's
`Deferred`-insert must target the switch that is ON the live pack reverse path.

**Determination (evidence-backed): insert the `Deferred` case in the CANONICAL-OBJECT open-state
switch ONLY; the legacy labels-only switch is test-only and OUT of the pack round-trip path — but
its test fixture should gain a `Deferred` case for enumerate-encoding-surfaces symmetry.**

> **Empirical-Evidence Block (the legacy `[`-branch is not on the production reverse path; the
> canonical-object branch is the live one).**
> `CMD`: `grep -rn "_tmr_decode_status" scripts/ test-fixtures/` ; `sed -n '524,527p' scripts/lib/tracker-migrate-reverse.sh` ; `sed -n '190,192p' scripts/lib/tracker-migrate-reverse.sh`
> `OUT`: the ONLY production call is `_tmr_reverse_reconstruct`'s `status=$(_tmr_decode_status "$issue")`
> where `$issue` is the full canonical Issue JSON object (`.title`/`.body`/`.labels` read just above
> it) — first char `{`, so the dispatch takes the canonical-object path, NOT the legacy `[`-array
> path. Every other call is in `scripts/tests/tracker-migrate-reverse-test.sh` (Group 1, lines
> 133-150), where the legacy path is invoked with literal `'["status:..."]'` arrays. The function's
> own header comment confirms: "Legacy/test path is preserved for the existing labels-only test
> fixtures in tracker-migrate-reverse-test.sh Group 1." `AT`: HEAD `e83aed7`, 2026-06-06.
> `INTERP`: the production reverse path NEVER enters the legacy `[`-branch — so for the pack
> round-trip, the single REQUIRED `Deferred`-insert site is the canonical-object open-state switch
> (SHOULD-1). The legacy switch cannot silently mis-decode a real deferred entry (it is never
> reached at runtime), so it is OUT of the round-trip lossless contract. `CONCL`: SUPPORTED.

**Enumerate-encoding-surfaces note (test symmetry, not a round-trip requirement).** Because the
legacy switch encodes the SAME `status:* → state` contract, the planner should ALSO add a
`status:deferred → Deferred` case to the legacy switch AND a Group-1 fixture assertion
(`_tmr_decode_status '["status:deferred"]'` → `Deferred`) so the two switches and their tests stay
symmetric — per the `enumerate-encoding-surfaces` rule (asymmetric coverage = audit gap). This is a
test-surface completeness fix, not part of the load-bearing live round-trip path.

---

### 2.7 Identity carrier

**Design.** Identity = the `<!-- pack-id: BD-NNN -->` body marker (V3.3 §6.4,
`ARCHITECTURE-V3.3-DELTA.md:364-366`) as the round-trip KEY, NEVER the GH issue number (issue
numbers are non-portable + non-stable across delete/recreate, `backlog/BD-204.md:11`). The
filename-is-ID contract (`backlog/_rules.md:35-43`) is the tree-side identity; the marker is the
tracker-side identity; they are the same `BD-\d+` token (canonical per BD-211 — no `[a-z]*` suffix
admission; the reverse marker reader at `tracker-migrate-reverse.sh` (the `pack-id` extraction in
the roster loop) uses `[A-Za-z]+-\d+(?:\.\d+)?`, which admits the `phase-N.M` form but no
letter-suffix run — already suffix-free, consistent with the validator's `_CANON_HEADER_RE`).

**The parenthetical round-trip (OPEN mechanic, BD-203 §3.7 RATIFY #2 — architect resolves):**

- **Suffix sub-entries: ELIMINATED (BD-211).** The letter-suffix sub-entry form (`BD-167b` /
  `BD-169b`) was retired entirely by BD-211 (2026-06-06): the two suffix files were folded into
  their parents as in-body sections, the shared per-entry grammar engine + `backlog/_rules.md` were
  simplified to canonical `^BD-\d+\.md$` (no suffix admission), and `scripts/validate-pack.py`'s
  `_CANON_HEADER_RE` (in Check 32′) now FAILS any non-canonical header (a suffix or a pre-em-dash
  parenthetical). The marker therefore carries a suffix-free base ID — `<!-- pack-id: BD-NNN -->` —
  and the reverse marker reader (`tracker-migrate-reverse.sh`, the `pack-id` extraction in the
  roster loop) uses `[A-Za-z]+-\d+(?:\.\d+)?`, which admits the `phase-N.M` form but no
  letter-suffix run, so it is already consistent with the canonical grammar. No suffix entry can
  exist to round-trip; the migrator and the validator agree on the suffix-free grammar.
- **Parenthetical (`BD-195 (Code Red 3)`):** the parenthetical is TITLE TEXT, not part of the ID
  (`backlog/_rules.md:39-43`). It rides the Issue TITLE verbatim (`BD-195: (Code Red 3) <title>` →
  body header `**BD-195 (Code Red 3) — <title>**`). The marker carries `BD-195` (base ID, the
  filename); the parenthetical is preserved byte-faithfully in the title/body-header, NOT inferred
  from prose. Reverse reconstructs the bold-header line from the title + marker.

> **Empirical-Evidence Block (the post-BD-211 suffix-free stress set).**
> `CMD`: `ls backlog/ | grep -E '^BD-[0-9]+[a-z]+\.md$' || echo ZERO` ; `for f in backlog/BD-*.md; do sed -n '2p' "$f" | grep -qE '^\*\*BD-[0-9]+ — .*\(Code Red' && echo "$f"; done`
> `OUT`: suffix files: `ZERO` (BD-211 folded BD-167b/BD-169b into their parents and deleted the two
> files). The sole entry whose canonical line-2 header carries a `(Code Red ...)` qualifier
> parenthetical is `backlog/BD-195.md` (`**BD-195 — v11.0 pristine-state recovery before BD-185
> restart (full-repo) (Code Red 3)**`; a post-em-dash parenthetical is admissible TITLE TEXT —
> the canonical guard forbids only a PRE-em-dash parenthetical). `AT`: HEAD `9fb29a5`, 2026-06-06. `INTERP`: there is NO suffix entry left to
> stress; the identity stress set reduces to the title-parenthetical case (`BD-195` — also the
> large multi-block entry) plus a `Deferred` entry (status stress, §3.2). The parenthetical rides
> the Issue title verbatim with a suffix-free base-ID marker; that single mechanism covers the only
> surviving non-trivial identity case. `CONCL`: SUPPORTED.

---

### 2.8 Pack Feedback two-lane separation

**Design.** The one Issues surface carries TWO lanes, distinguished by intake form + label:

- **Pack-owned lane** — Issues created by the forward migration / Mode-3 CRUD from
  `work-item.yml` (label `work-item` + `pack-id: BD-NNN`). These REVERSE BACK into the tree (the
  regen path, §2.1, filters on `work-item` + a resolved `pack-id` marker).
- **Inbound-feedback lane** — Issues filed via `inbound.yml` (label `inbound` + `needs-triage`,
  `inbound.yml:4-7`; D-11 / D-14). These are NOT swept into the tree. The regen `provider_list`
  filter EXCLUDES `inbound`/`needs-triage` issues and any issue whose `pack-id` marker is still
  `PENDING` (`work-item.yml:103`, `inbound.yml:74`). An inbound issue is promoted into the tree
  ONLY when the chat triages it: assigns a real `BD-NNN` (replacing `PENDING`), swaps
  `template:inbound-v11.0` → `template:work-item-v11.0`, and drops `needs-triage`. After
  promotion it is a pack-owned issue and reverses into the tree on the next regen.

**The filter (the lane boundary, concrete):** regen selects issues WHERE `work-item` label present
AND `pack-id` marker matches `BD-\d+` (not `PENDING`) AND `needs-triage` absent. This is a
provider-side label/marker filter (tracker-agnostic — labels are a `DESIGN-BRIEF.md:248`
capability-flag floor every backend has).

**Boundary (pack-only ✓):** the feedback form + triage live in the PACK repo
(`.github/ISSUE_TEMPLATE/inbound.yml` is pack-side; `config.yml` is pack-side). Any client-side
submission convenience is project-side and OUT of BD-204 (`backlog/BD-204.md:17,21`). BD-204
touches NO project-side feedback surface.

---

### 2.9 Tracker-agnostic + surface-generalizable

See §4 (full treatment). Summary: GH-specific logic stays behind `provider_*` (BD-060); the
migration machinery is parameterized by `surface` (pack vs client) so BD-207 reuses it unchanged;
BD-204 wires ONLY the `surface=="pack"` branch.

---

### 2.10 Capability matrix (GA + personal-account ONLY)

The design space is GA + personal-account only (`verify-availability-not-just-existence`). The pack
account is personal (`DShaneNYC/optiquity-ai-agent-config-pack`).

| Capability | GA? | Personal? | In BD-204 design? | Use |
|---|---|---|---|---|
| GH Issue Forms (`.github/ISSUE_TEMPLATE/*.yml`) | YES | YES | **YES — locked substrate** | the form family carries structured BD fields |
| GH Issue Dependencies (blocked-by) | YES (2025-08-21) | YES (Free+) | **YES** | `Blockers:`/`Unblocks:` first-class links (BD-111) |
| GH Sub-issues | YES | YES | YES (minimal — pack BDs are flat L1) | not load-bearing for the pack backlog |
| GH labels (status/template/scope) | YES | YES | **YES** | status mapping (DP-3) + lane filter (§2.8) |
| GH custom Issue Fields | NO (preview) | NO (org-only) | **EXCLUDED** | the prior phantom fork; NOT used |
| GH custom Issue Types | partial | NO (org-only) | **EXCLUDED** | NOT used |

**No design element needs a capability outside the verified set.** The structured carrier is the
form-family body + labels + the in-body `pack-extra-fields` block (NOT custom Issue Fields, NOT a
sidecar file). The status machine is labels + GH
open/closed `state_reason` (all GA + personal). The identity carrier is a body HTML comment (no
capability needed). If a future need for a typed field arises, it is a future-option-when-GA, not a
BD-204 fork. **No researcher availability pass is triggered** — the design stays inside the
verified GA + personal set.

---

### 2.11 Reversibility (lossless round-trip + repeated on/off + interleaved CRUD)

The reversibility design + audit + test approach is §3 (full treatment). Summary of the guarantee:
`per-entry tree → GH Issues → per-entry tree == original`, byte-faithful on entry spans, correct
under repeated on/off/on/off with interleaved CRUD. The lossless contract rests on: (a) identity
keyed on `pack-id` (§2.7, stable across delete/recreate); (b) the in-body `pack-extra-fields` block
(in the Issue body, the SSOT) for any named field the form grammar cannot name — no sidecar file (§2.4.1); (c) the silent-data-loss guard that FAILs rather
than drops (`tracker-migrate-reverse.sh:1032-1042`); (d) the complete status mapping incl. the
`Deferred` row (§2.6, the round-trip-completeness fix).

---

### 2.12 On/off transition design (heavyweight, infrequent, lossless)

Mode transitions are heavyweight + infrequent + lossless by design (`backlog/BD-204.md:10`), NOT a
hot path:

- **ON (forward, Mode 2 → 3):** `pack tracker init --forward` — reads the tree (C2a repoint),
  creates an Issue per entry (`provider_create` via the form shape), writes the `pack-id` markers,
  creates dependency links (BD-111), sets `tracker.toml` (`mode.state="tracker"`,
  `forward_complete=true`), SKIPS the monolith mirror regen (C2b). One-shot, idempotent (existing
  checkpoint markers, BD-065/131). The tree is then regenerated FROM the tracker (now SSOT).
- **OFF (reverse, Mode 3 → 2):** `pack tracker disable` — reconstructs entries from Issues, emits
  the per-entry TREE directly (C3 repoint), regenerates `_toc.md` (DP-4), flips `tracker.toml` back
  to flat-file. The silent-data-loss guard + the atomic backup/restore loop
  (`tracker-migrate-reverse.sh:1085-1098`) make the flip atomic (no split state).
- **Repeated on/off/on/off:** each ON re-creates Issues keyed on the SAME `pack-id` markers (not
  issue numbers, §2.7); each OFF re-emits the SAME tree files (filename-is-ID). Named overflow
  fields cross the gap IN the Issue body (the `pack-extra-fields` block + the `template_version`
  marker) — no sidecar file. Idempotency + identity-stability
  make repeated cycles converge to the original — proven by the §3 audit.

---
## 3. Reversibility / lossless audit + test approach

### 3.1 The lossless contract (what "== original" means)

`per-entry tree → GH Issues → per-entry tree` is lossless iff, for every entry, the
reconstructed `/backlog/BD-NNN.md`:

1. **Same filename** (identity preserved) — keyed on the `pack-id` marker (§2.7), incl. the
   parenthetical-title entry (`BD-195`; post-BD-211 the tree is suffix-free — no suffix entry exists).
2. **Byte-faithful entry span** — the bold-header `**BD-NNN — <Title>**` (incl.
   parenthetical title text), the `Status:` line, and every body field/sub-block, byte-identical
   to the original (the line-1 back-pointer is regenerated, not compared — it is a derived
   supporting artifact per `_lib.sh:300`).
3. **Status round-trips** — every `Status:` value decodes back to itself (the DP-3 matrix +
   the new `Deferred` branch close the one gap that breaks 11 entries).
4. **Overflow recovered** — `Target:`/`Position:`/structured-sub-blocks recovered from the Issue
   body (the visible sections + the in-body `pack-extra-fields` block; §2.4.1), byte-faithfully.
   NO sidecar file participates. GH-only non-entry artifacts (reactions/comments/attachments/audit
   log) are OUT of the contract by decision (§2.4.3).

"Lossless" applies to LIVE content only (`feedback_fail_loud_delete_old_source.md:35`); the
back-pointer + `_toc.md` are derived, regenerated each cycle, not round-trip-compared.

### 3.2 The lossless audit (the oracle)

The audit is a deterministic diff, modeled on the BD-203 entry-count + content-faithfulness oracle
(`ARCHITECTURE-BD-203-V3.md:307-321`), adapted to tree↔Issues↔tree:

- **Count oracle:** `count(/backlog/*.md matching ^BD-\d+\.md$)` BEFORE == `count` AFTER ==
  `count(pack-owned Issues)` (the `work-item` lane only; inbound issues excluded). Measured live at
  audit time (the count is dynamic — 211 today, post-BD-211; never hard-coded, per BD-203 EE-1). The
  count regex is the canonical suffix-free `^BD-\d+\.md$` (BD-211; no `[a-z]*` admission).
- **Identity oracle:** the SET of `pack-id`s in the tree BEFORE == the SET AFTER == the SET of
  `pack-id` markers across pack-owned Issues. Stress set (post-BD-211, suffix-free): the
  parenthetical-title entry (`BD-195`), a `Deferred` entry, and the large multi-block entry
  (`BD-195`) appear in all three sets — there is no longer any suffix entry to stress.
- **Content-faithfulness oracle:** for each entry, `diff <(original entry span, back-pointer
  stripped via pe_strip_backpointer_stdin) <(reconstructed entry span, back-pointer stripped)` is
  EMPTY. The large-entry stress case (BD-195's `Segments:`/`Steps:`/`State:` blocks) is in scope —
  its body must diff clean.
- **Status oracle:** the status distribution BEFORE (`167 Resolved, 28 Open, 11 Deferred, 3
  Deprecated, 1 Unblocked, 1 Cancelled`) == AFTER. The `Deferred` count (11) is the canary for the
  DP-3 gap-fix.
- **No-monolith / no-sidecar oracle:** `! -f pack-ops/BACKLOG.md` throughout (Check 32′ green); no
  monolith is ever written by forward (C2b) or reverse (C3); AND no `.pack-tracker/reverse.sidecar.*`
  file is written on the pack surface (the sidecar is dropped for v11.0, §2.4.1) — the round-trip
  reads/writes only form fields + the Issue body.
- **Repeated-cycle oracle:** run `tree → Issues → tree → Issues → tree` (on/off/on/off); the final
  tree == the original (idempotent convergence). With interleaved CRUD: open a BD via
  `provider_create`, flip a status via `provider_update`, then reverse — the new BD appears in the
  tree, the status change round-trips, and re-forward re-creates the same state.

### 3.3 The silent-data-loss guard (lossless enforcement, already built)

> **Empirical-Evidence Block (the reverse path FAILs rather than drops — the lossless backstop).**
> `CMD`: `sed -n '1032,1042p' scripts/lib/tracker-migrate-reverse.sh`
> `OUT`: `:1032-1041` — when `n_skipped > 0` and not `--force`, `tracker_error_emit "partial-write"
> "reverse: $n_skipped issue(s) failed to reconstruct (silent-data-loss guard)"` … `return 1`. `AT`:
> HEAD `e83aed7`, 2026-06-05. `INTERP`: the reverse refuses to write a partial tree (BD-132's
> ~33%-data-loss class is guarded); this guard now protects the per-entry emit (C3) the same way it
> protected the monolith emit. `CONCL`: SUPPORTED.

**BD-132 data-loss class under the tree target (the UNMARKED flag, resolved).** BD-132 fixed a
close-step race that destroyed ~33% of entries on disable/init. The per-entry emit (C3) does NOT
re-open the class: the guard (`:1032-1042`) fires on `n_skipped` BEFORE any tree write, and the
atomic backup/restore loop (`:1085-1098`) snapshots the destination paths — for the pack tree, the
backup loop must snapshot the `/backlog/*.md` SET (not the single monolith path). The fix-recipe:
the pack-surface backup loop iterates the tree files (the planner wires `_emit_path_list` to the
tree set on the pack branch). This is the architect's lossless-audit coverage of T8.

### 3.4 The test approach (live scratch repo, self-provisioned)

Reversibility cannot be proven without a live GH repo (BD-111's "Live GH repo access" blocker;
`test-infra-self-provisioned`). The dogfood test sequence (gated per `backlog/BD-204.md:20`,
"scratch-repo proof → archive → real flip"):

1. **Scratch-repo proof** — provision a personal-account scratch repo via `gh repo create`
   (per-step user approval, `test-infra-self-provisioned`), install the form family, run
   `tree → Issues → tree` against it, run the §3.2 oracle, then `gh repo delete` (cleanup). NEVER
   touch the real pack repo as a test target. The scratch run uses a FIXTURE tree (a small
   representative set incl. a parenthetical-title entry, a Deferred entry, and a large
   multi-block entry — the three stress cases; post-BD-211 there is no suffix case) so the oracle is
   fast + deterministic.
2. **Archive** — after the scratch proof is green, the audit artifacts (the oracle diffs) are
   recorded in the IMPL-REPORT (not committed as a kept mirror).
3. **Real flip** — the actual pack-repo Mode-2→3 migration, gated on the scratch proof + explicit
   user approval (heavyweight, infrequent, §2.12). This is the dogfood: the pack's OWN 211 entries
   (post-BD-211; measured live at flip time, never hard-coded) move to the pack's real GH Issues.

**Cleanup contract:** every scratch repo created is deleted in the same test run (trap-on-exit +
explicit `gh repo delete`); a scratch repo is never left dangling. The test asserts the scratch
repo is gone at the end.

**C-7 CI-execution model — MANUAL-ONLY, gated, with a default-SKIP guard (the test never runs
`gh repo create` unattended).** The C-7 lossless oracle is the ONE test in the pack that requires a
LIVE GH repo (the §3.4 EE block: forward/reverse shell out to real `gh issue create/list`). Every
OTHER tracker test in the battery is mock-based (a fake `gh` on `PATH`; no live GitHub state is
touched). Wiring a live `gh repo create` test into the unattended CI `tests` job would (a) create
real GitHub repos on every push (cost, rate-limit, dangling-repo risk) and (b) violate
`test-infra-self-provisioned`, which gates every scratch-repo create/delete on PER-STEP user
approval — impossible in unattended CI. The decision is therefore:

- **The C-7 oracle test is NOT part of the automated CI `tests` job.** It is a MANUAL, user-gated
  test, run locally with per-step `gh` approval as the C-8 dress rehearsal — exactly the
  `test-infra-self-provisioned` contract. The `validate-pack.py` + the mock-based tracker battery
  remain the unattended CI gate; C-7 sits OUTSIDE it.
- **The test carries a default-SKIP guard so it can never run live unattended.** At the top of
  `tracker-bd204-lossless-roundtrip-test.sh` the test (1) requires an explicit opt-in env var
  (e.g. `PACK_TRACKER_LIVE_GH=1`) AND (2) requires authenticated `gh` (`gh auth status` OK); if
  EITHER is absent it prints a clean `SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth
  to run)` and exits 0. So if the test is ever invoked by a generic `scripts/tests/*.sh` sweep in
  CI, it SKIPs cleanly rather than attempting `gh repo create`. The guard is a fail-safe; the
  PRIMARY control is that C-7 is not enumerated in the CI battery at all.
- **Consequence for the planner.** The C-7 recipe must (a) NOT add the test to any CI workflow /
  unattended `run-all` test list; (b) implement the env-var + `gh auth` SKIP guard as the test's
  first action; (c) state that C-7's `**FULL CI battery**` per-commit verification means the
  EXISTING mock-based battery + `validate-pack.py` (which run green unattended), PLUS the live
  oracle run MANUALLY with the opt-in env var + per-step `gh` approval — these are two distinct
  runs, not one. The ambiguity in PLAN §C-7's `"FULL CI battery + the new oracle test"` resolves
  to: the battery is unattended-CI; the oracle is the manual gated run.

> **Empirical-Evidence Block (the audit needs a live repo — provider ops shell out to gh).**
> `CMD`: `grep -n "provider_create\|provider_list\|gh issue" scripts/lib/tracker-provider-gh.sh | head`
> `OUT`: the GH backend dispatches to `gh issue create/list/...` (the LCD write mechanism, D-9
> `ARCHITECTURE-V3.md:169`). `AT`: HEAD `e83aed7`, 2026-06-05. `INTERP`: forward/reverse exercise
> real Issue create/list, so the lossless round-trip requires a live GH repo — the scratch-repo
> provisioning is mandatory for the audit. `CONCL`: SUPPORTED.

---

## 4. Tracker-agnostic + surface-generalizable design

### 4.1 Tracker-agnostic (the provider abstraction stays GH-free)

Per `feedback-tracker-portability` + D-1 (BD-060): all GH-specific logic lives behind the
`provider_*` ops (`tracker-provider.sh:125-140`, dispatched to `tracker-provider-gh.sh`). The
migration machinery (forward/reverse/regen) calls `provider_create/update/close/list/get/comment/
link` — NEVER raw `gh`. A Jira/Linear/Redmine backend implements the same op-set + capability
flags (`DESIGN-BRIEF.md:245-252`) and plugs in with no migration-machinery change.

**BD-204 adds no GH-specific leak into the agnostic layer:**

- The `Deferred` status row (DP-3) maps to `open + status:deferred` — a label + open-state, both
  capability-flag floors every backend declares (`DESIGN-BRIEF.md:248,252`). It is NOT a GH-specific
  construct.
- The lane filter (§2.8) is label/marker-based — labels are a cross-tracker floor.
- The CRUD wiring (§2.3) calls `provider_update`/`provider_close`, not `gh issue edit`. The
  "delete = close-with-reason" choice (§2.3) is the cross-tracker-safe terminal op (not every
  tracker permits hard-delete).
- The `pack-id` identity carrier (§2.7) is a body HTML comment — tracker-agnostic (every tracker
  has an issue body / description field).

The ONE place GH appears is the provider implementation + the form family (`.github/ISSUE_TEMPLATE/`,
which is inherently GH — a Jira backend would supply Jira's own intake template; the form family is
the GH realization of the D-4-V2 structured-intake decision, not the abstraction).

### 4.2 Surface-generalizable (parameterized by `surface`, pack-only instance)

> **Empirical-Evidence Block (the migration machinery is already surface-branched).**
> `CMD`: `grep -n 'surface == "pack"\|"$surface"' scripts/lib/tracker-migrate-reverse.sh scripts/lib/tracker-migrate-forward.sh | head`
> `OUT`: reverse `:1056 if [[ "$surface" == "pack" ]]` (pack → `pack-ops/`, else root/client);
> forward `:709,:732 if [[ "$surface" == "pack" ]]`. `AT`: HEAD `e83aed7`, 2026-06-05. `INTERP`:
> the shared functions already split pack vs client by `surface`; BD-204 edits ONLY the
> `surface=="pack"` branch (tree target); the client branch is untouched (BD-207). `CONCL`: SUPPORTED.

**The generalization design:** the Mode-2↔3 machinery is parameterized by `surface` (already) AND,
for the tree target, by the stream key + dir (`pack-backlog` / `/backlog/`). The pack-surface
branch emits to `/backlog/` via `per_entry_*` (stream key `pack-backlog`); BD-207's client branch
will emit to `docs/project/backlog/` via the same `per_entry_*` engine with stream key
`project-backlog`. The reverse emitter's tree-write is therefore a parameterized call:
`per_entry_emit <stream_key> <stream_dir> <entries>` + `per_entry_regenerate_toc <stream_key>
<stream_dir>` — the SAME code path, different `(key, dir)`. BD-204 wires the pack instance; the
shared layer carries NO pack-specifics (no hard-wired `/backlog/`, no BD-only assumption — the
stream key drives the entry regex `^BD-\d+\.md$` vs the client's `^TD-\d+\.md$` (both canonical,
suffix-free per BD-211).

**Pack/project separation (`feedback_pack_project_separation_of_concerns`):** the pack and client
emit TARGETS are SEPARATE (pack → `/backlog/`; client → `docs/project/backlog/`); the shared
function's surface branch encodes the split. BD-204's pack-branch edit must NOT regress the client
branch (the client branch keeps emitting its monolith until BD-206/207 — that is the client's
current contract, not BD-204's to change). T6 is honored: pack-only edit, client branch untouched.

### 4.3 Dependency-direction placement (no project deliverable as a pack runtime dep)

Per `dependency-direction-placement`: the tracker libs (`scripts/lib/tracker-*.sh`) + the per-entry
engine (`scripts/lib/per-entry/*`) are pack-side shared libs that serve BOTH surfaces (a pack
operation depends on them at runtime — `pack tracker init` sources them). They stay pack-side. No
new file BD-204 introduces ships to clients (BD-204 wires existing pack-side libs; the form family
is already pack-side at `.github/ISSUE_TEMPLATE/`). The `_SANCTIONED_PACK_SIDE_SHIPPED` allowlist
(`{scripts/lib/detect.sh, scripts/pack-help.sh}`) is NOT grown by BD-204 — no design element
requires it.

**Code implication of the sidecar drop (FLAG — planner/coder decides remove-vs-dormant).** Per
DP-2 RESOLVED (§2.4.1), the pack forward/reverse paths must NOT write or read any
`.pack-tracker/reverse.sidecar.*` file: the pack-surface reverse must NOT call `tracker_sidecar_emit`
(the reverse orchestrator's Step-7.5 `sidecar_path=$(tracker_sidecar_emit ...)` call in
`tracker-migrate-reverse.sh` currently invokes it — the pack branch drops that call), and
no pack path reads a sidecar. Consequently the built `scripts/lib/tracker-sidecar.sh` is UNUSED on
the pack surface for v11.0. Whether to DELETE `tracker-sidecar.sh` outright or leave it DORMANT (it
may still serve the client surface / a future tracker-agnostic mechanism) is a remove-vs-dormant
call left to the planner/coder — the architect flags it, does not decide it. The in-body
`pack-extra-fields` block is emitted/parsed on the existing entry-body path (forward writes it into
the Issue body; reverse renders it inline into `/backlog/BD-NNN.md`), needing no sidecar lib.

---

## 5. Rules-Applied Verification Block

| Rule (as named in prompt / CLAUDE.md) | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **Empirical-Evidence Blocks (architect)** | Every state-claim carries a block: §2.1 (no-mirror landed `_rules.md:18-26`); §2.2 (6-site monolith census, grep verbatim); §2.2.C1 (Check 29 `_check_mirror_staleness` hard-fails a no-mirror live config at its `last_forward_run`/`[mirror]`-table branches — symbol-anchored, not line); §2.3 (`provider_update` unwired except `tracker-promote.sh:801,1215`, no `provider_delete`); §2.4 (reconstruct field-set); §2.6 (no `Deferred` branch `:192-239`; distribution sums to 211 post-BD-211); §2.7 (suffix-free post-BD-211; parenthetical-title `BD-195`); §3.3 (guard `:1032-1042`); §3.4 (gh shell-out); §4.2 (surface branch `:1056,:709`). All at HEAD `e83aed7` (`git rev-parse HEAD → e83aed72a25b...`), 2026-06-05, verbatim output, SUPPORTED. | COMPLIANT |
| **CI-guard measure-then-bound** | §2.2 measures all 6 runtime monolith sites FIRST (grep census), categorizes each KEEP/REPOINT/RETIRE, gives a fix-recipe per site, and §2.2.C1 sizes the Check 29′ soft-pass allowlist exactly to the 3 legitimate live-config shapes (flat-file / tracker-no-mirror / tracker-with-mirror), refusing to widen to swallow a claims-mirror-but-missing config; verified clean against the projected post-fix state (Check 32′/29′/33 green). | COMPLIANT |
| **Architect reaches own conclusions** | The 12 areas + 5 DECISION POINTS are resolved from the brief's CONSTRAINTS (the tiers) + independent re-measurement, not an imported solution. DP-1's (A) recommendation, the §2.3 "delete = close-with-reason" call, and the DP-5 retire-not-repoint call are the architect's own reasoning. | COMPLIANT |
| **Pattern-matching out of context** | Each locked-mechanism reuse is property-fit-verified: the overflow carrier (§2.4) is the form family + the in-body `pack-extra-fields` block (the locked sibling-marker carrier, `work-item.yml:103-105`) — the v10-monolith sidecar FILE is DROPPED (DP-2 RESOLVED, user 2026-06-06) because its flat-grammar-overflow rationale does not hold and a GH-specific sidecar would not port across trackers; `provider_delete` REJECTED (§2.3) because the pack lifecycle has no hard-delete property (close-with-reason is the fit); the `Deferred` row mapped to OPEN (not closed) by lifecycle-semantics fit, not by resemblance to Resolved. | COMPLIANT |
| **Preliminary-triage + architect-challenge** | Re-measured independently rather than trusting the analysis docs: the C6 `Deferred` gap re-verified IN BUILT CODE (`_tmr_decode_status:192-239` has no branch — not just the V3.3 §6.3 table); the 11-count re-grepped (not taken from the AMENDMENT); the `provider_update`-unwired claim re-grepped across `scripts/lib/`. The compat-report conclusions confirmed against source, not adopted. | COMPLIANT |
| **Verify availability, not just existence** | §2.10 capability matrix: design uses ONLY GA + personal-account capabilities (Issue Forms / Dependencies / Sub-issues / labels / open-closed state_reason); GH custom Issue Fields + Issue Types EXCLUDED (org-only/preview — the prior phantom fork). No design element needs an unverified feature; no researcher pass triggered. Account verified personal (`DShaneNYC/...`). | COMPLIANT |
| **Adversarial review on a major gap** | DEFAULT-tier alternatives are presented adversarially WITH the failure mode they fix, for the user: DP-1 surfaces (B) editable-synced with its dual-writer failure; DP-3 surfaces the `Pending/In Progress/Done` mismatch + the silent-Deferred-loss failure. Not self-adopted; user adjudicates. | COMPLIANT |
| **Fail-loud / delete the old source** | §2.2 NEVER recreates a monolith mirror: C2b RETIRES the forward Step-10 mirror regen (pack); C3 emits the TREE not a monolith; Check 32′ green throughout (§2.2 EE block); DP-5 retires the header-snapshot rather than reviving a monolith preamble. The no-mirror tree is the only flat representation. | COMPLIANT |
| **Pack/project separation of concerns** | §4.2: pack + client emit targets are SEPARATE; BD-204 edits ONLY the `surface=="pack"` branch (`:1056`); the client branch (and the project `tracker.toml.project-example` `[mirror]` table, §2.2.C1) is UNTOUCHED. The agnostic layer carries no pack-specifics (stream-key parameterized). Pack version is never a client fallback. | COMPLIANT |
| **Dependency-direction placement** | §4.3: tracker libs + per-entry engine stay pack-side (a pack operation depends on them at runtime); BD-204 introduces no client-shipped file; `_SANCTIONED_PACK_SIDE_SHIPPED` not grown; the sidecar-drop code implication (`tracker-sidecar.sh` unused on the pack surface) is FLAGGED with remove-vs-dormant left to planner/coder. | COMPLIANT |
| **Tracker portability** | §4.1: all GH-specific logic behind `provider_*`; the migration machinery calls the abstraction, never raw `gh`; the `Deferred`/lane/CRUD/identity designs use cross-tracker floors (labels, open/closed, body marker), no GH leak into the agnostic layer. | COMPLIANT |
| **Enumerate ENCODING surfaces** | §2.2 enumerates, per retired/repointed mechanism, every encoding surface: the lib (`tracker-*.sh`), the validator Check (29′ / 32′ / 33), the tests (planner enumerates `test-*tracker*`/`test-validate-pack*` that pin Check banners — per `verify-full-ci-suite`), the example schema, CI workflow — all in lock-step. | COMPLIANT |
| **Architect-doc-vs-reality reconciliation** | This doc realizes the BD-203 §3.7 anticipated interface; it names the realized consumers by file + symbol (never line numbers): `_tmr_emit_backlog` (pack branch → `per_entry_*`), `_tmr_decode_status` (+`Deferred` branch), `_check_mirror_staleness` (→ Check 29′ no-mirror guard), `tracker_header_snapshot_capture` (retired pack-side). | COMPLIANT |
| **Rules-Applied Verification Block + Read-docs-in-full** | This block + the READ-IN-FULL attestation below; every row quoted evidence (none empty). | COMPLIANT |
| **Agents never commit** | No `git add/commit/push/tag` or any state-changing verb run; the sole write is this ONE design doc (`maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md`). | COMPLIANT |

### READ-IN-FULL attestation (per-file direct-read proof, this session)

| # | File | Direct-read proof |
|---|---|---|
| 1 | `backlog/BD-204.md` | Read full (1-26) — the binding three-tier brief. |
| 2 | `backlog/_rules.md` | Read full (1-86) — no-mirror, lifecycle states, ID-extraction, write authority. |
| 3 | `DESIGN-BRIEF.md` | Read full (1-333) — §1 hard exclusions, §3.1 mandatory-reverse, §6.3 abstraction floors, OQ-16/17/18. |
| 4 | `RESEARCH-BD-204-RESTART-INTEGRATION.md` | Read full (1-448 + 449-542) — D-1 corpus map, D-2.1 LOCKED, D-2.2 OPEN, D-3.0 availability matrix, D-3.2 T1–T9. |
| 5 | `PACK-REVIEW-BD-203-VS-LOCKED-COMPATIBILITY.md` | Read full (1-184) — C1–C8 with file:line both sides; C1 BLOCKER, C6 Deferred gap. |
| 6 | `ARCHITECTURE-V3.3-DELTA.md` §6 | Read directly (300-440) — §6.1 form-family, §6.3 status mapping, §6.4 identifier, §6.5/§6.R carrier matrix. |
| 7 | `ARCHITECTURE-V3.1-DELTA.md` §3 | Read directly (180-274) — DELTA A2 `extra_fields` + §6.6.1 round-trip behavior (the locked SIDECAR-FILE home is superseded for the pack surface by the in-body carrier per DP-2 RESOLVED; the `extra_fields` CONCEPT + the derivable `template_archive_path` convention are retained). |
| 8 | `ARCHITECTURE-V3.md` §16/§4 | Read directly (via RESEARCH §D-2.1 verbatim D-1..D-20 lock-table quotes + DESIGN-BRIEF OQ defenses). |
| 9 | `work-item.yml` / `inbound.yml` / `config.yml` | Read full (work-item 1-106, inbound 1-77, config 1-9) — the locked form family. |
| 10 | `ARCHITECTURE-BD-203-V3.md` §3.5/§3.7/§4/§5/§7 | Read directly (220-378) — deferred repoints, reverse interface, RATIFY/NUDGE points, validator changes, BD-204 hand-off. |
| 11 | Built tracker libs | `tracker-migrate-forward.sh` (700-744, 1195-1215), `tracker-migrate-reverse.sh` (178-239, 600-674, 1000-1129), `tracker-agent-read.sh`/`tracker-doctor.sh`/`tracker-header-snapshot.sh` (grep census), `tracker-provider.sh` (CRUD ops), `tracker.toml.pack-example` (full) read directly. |
| 12 | `validate-pack.py` Check 29 + Check 32′ | Read directly (2600-2670, 2682-2826, 3136-3264) — `_validate_tracker_toml`, `_check_mirror_staleness`, Check 32′ no-monolith. |
| 13 | per-entry engine | `scripts/lib/per-entry/_lib.sh` + `toc-regenerate.sh` + `decompose.sh` (write-API grep) read directly. |
| 14 | `CLAUDE.md` `## Pack memory` | Read in full (provided in session context — no-mirror SSOT, pack-project-separation, dependency-direction, enumerate-encoding-surfaces, ci-guard-measure-then-bound). |
| 15 | Memory files | `feedback_architect_planner_empirical_evidence.md`, `feedback_ci_guard_design_measure_then_bound.md`, `feedback_pattern_matching_out_of_context_antipattern.md`, `feedback_preliminary_triage_architect_challenge.md`, `feedback_verify_availability_not_just_existence.md`, `feedback_adversarial_architect_review_on_major_gap.md`, `feedback_fail_loud_delete_old_source.md`, `feedback_pack_project_separation_of_concerns.md`, `feedback_tracker_portability.md` — each read full this session. |

**No named document was derived rather than read.** Every brief, contract, locked-corpus doc,
analysis doc, built-code file, and memory file above was opened directly via the Read/Bash tools
this session at HEAD `e83aed7`. The locked design is grounded in the SOURCES (form-family files,
V3.3-DELTA §6, V3.1-DELTA §3, BD-203 §3.7), not a summary.

---

## 6. Consistency-review fix pass (2026-06-06) — Rules-Applied mini-block

Four non-blocking precision fixes applied; no design substance or resolved DP changed. Cited code
sites re-anchored by SYMBOL (line numbers drift / were wrong at HEAD `e83aed7`).

| Finding | Fix | Conclusion |
|---|---|---|
| **SHOULD-1** (Deferred-insert anchor wrong) | DP-3 bullet + §2.6: re-anchored the insert from `tracker-migrate-reverse.sh:213-219` (a setup block) to "`_tmr_decode_status`'s open-state `case "$label"` block (the canonical-object `# Open: derive from label` switch), parallel to `status:unblocked → Unblocked`" — by symbol, no bare line. | FIXED |
| **SHOULD-2** (second switch — RESOLVED w/ evidence) | Added §2.6.1 + EE block: determined the legacy labels-only `[`-switch is NOT on the production reverse path (the sole production call passes the canonical Issue object; the `[`-array path is only hit by `tracker-migrate-reverse-test.sh` Group 1). REQUIRED insert = canonical-object switch only; legacy switch is test-only/out-of-round-trip, with an enumerate-encoding-surfaces note to add the case + a Group-1 fixture assertion for test symmetry. | FIXED |
| **NIT-3** (Check-29 EE wrong fail-line) | §2.2.C1 EE block re-anchored to the `_check_mirror_staleness` mirror-handling region (the `last_forward_run` + `[mirror]`-table-missing/malformed branches) where a no-mirror live config actually hard-FAILs — not the schema `is_file()` leg; fix-recipe (guard at the TOP of `_check_mirror_staleness`) unchanged; §5 summary cite corrected too. | FIXED |
| **NIT-4** (sidecar call-site drift) | §4.3 re-anchored `tracker-migrate-reverse.sh:1126-1128` → "the reverse orchestrator's Step-7.5 `sidecar_path=$(tracker_sidecar_emit ...)` call" (by symbol; the actual call is the single Step-7.5 invocation). | FIXED |
| **Architect-doc-reality-reconciliation** | All four re-anchors name the realized consumer by file + symbol, never line number (the rule the unifying recipe applies). | COMPLIANT |
| **Empirical-Evidence Blocks** | SHOULD-2 carries an EE block (call-site census + dispatch-path proof + header-comment confirmation, HEAD `e83aed7`, 2026-06-06, SUPPORTED); NIT-3 EE re-measured the real fail-branches. | COMPLIANT |
| **Scope held** | Only the 4 cited sites + their §5 summary echoes touched; DP-1..DP-5 resolutions byte-unchanged; no design substance altered. | COMPLIANT |

**End of ARCHITECTURE-BD-204.md**
