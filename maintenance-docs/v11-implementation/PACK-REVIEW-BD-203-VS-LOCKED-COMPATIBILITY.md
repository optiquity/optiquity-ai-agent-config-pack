# PACK-REVIEW — BD-203 (landed) vs the LOCKED tracker/form design — compatibility assessment

**Agent:** pack-reviewer · **Mode:** READ-ONLY assessment (no source edits, no fixes, no design, no git verb).
**HEAD (verified):** `ed47be4` (`git rev-parse HEAD` → `ed47be4159c80fafe02bdc5ad3a4f8026004590e`). **Branch:** `v11-dev`. **Date:** 2026-06-05.
**Checklist source:** `RESEARCH-BD-204-RESTART-INTEGRATION.md` §D-2.1 LOCKED table (NOT re-derived).
**Scope of judgement:** the PACK surface only (`/backlog/`, `/changelog/`, `scripts/lib/`, `scripts/validate-pack.py`, `pack-ops/`, `.github/ISSUE_TEMPLATE/`). Where a mechanism is shared pack/client (e.g. `_tmr_emit_backlog`'s surface branch), only the PACK branch is judged.

---

## 1. Verdict summary (headline)

BD-203's design and its shipped implementation are **broadly compatible** with the LOCKED tracker/form design at the **strategy/interface** level: BD-203 deliberately ANTICIPATED the Mode-3 hand-off (§3.7 of `ARCHITECTURE-BD-203-V3.md`), marked the ratify/nudge points, and the no-mirror `_rules.md` + per-entry contract are a clean SSOT the forms can target. The form-family substrate, the sidecar overflow model, and the provider abstraction are all carrier-level mechanisms that the per-entry tree neither blocks nor contradicts.

**HOWEVER, the LOCKED corpus contains a built-and-shipped MONOLITH-MIRROR layer that BD-203 deleted the target of.** The conflicts are NOT in the *form family* (the piece BD-204 famously missed) — the forms are fully compatible. The conflicts are concentrated in the **D-7 / D-8 mirror-and-reverse machinery**: the LOCKED design's `tracker.toml [mirror]` table, the Check 29 mirror-staleness guard, and the BUILT forward/reverse libs all read/write/validate `pack-ops/BACKLOG.md` + `pack-ops/CHANGELOG.md` + a `mirror.location_*` monolith model that **BD-203 deleted and forbade recreating**. These are the *expected, BD-203-flagged* Mode-3 wiring collisions — but several go BEYOND the "dormant-in-flat-file, BD-204 repoints" set BD-203 scoped, because the **`tracker.toml` schema + Check 29 are LOCKED-design ARTIFACTS that encode a mirror as a first-class config citizen**, not merely runtime read sites.

**Count: 1 BLOCKER, 3 MAJOR, 4 MINOR.** No FUNDAMENTAL conflict (BD-203's landed work CAN host the locked design without changing BD-203 itself — the conflicts are all on the tracker-side wiring/config, not the per-entry tree shape). The BLOCKER is that the locked `[mirror]` config model + its CI guard have **no destination under no-mirror** and BD-203 left them un-reconciled — BD-204's entry must explicitly own retiring or repointing them, or BD-204 inherits a contradiction the prior attempt's restart did not name.

---

## 2. Per-locked-decision verdict table (§D-2.1 checklist, one row each)

Severity on CONFLICT rows = derail-risk for a BD-204 built naively on both.

| LOCKED decision (§D-2.1) | Locked-source `file:line` | BD-203 evidence `file:line` | Verdict |
|---|---|---|---|
| DESIGN-BRIEF §1 hard exclusions | `DESIGN-BRIEF.md:20` | BD-203 is pack-only, opt-in-agnostic; touches no excluded surface (`ARCHITECTURE-BD-203-V3.md:26`, `:234`) | **COMPATIBLE** |
| D-1 Provider surface (18 ops) | `ARCHITECTURE-V3.md:160` | BD-203 does not touch the provider; per-entry tree is provider-agnostic input/output (`_lib.sh:34-42`) | **COMPATIBLE** |
| D-2 `tracker.toml` single config | `ARCHITECTURE-V3.md:161` | BD-203 adds no tracker.toml; flat-file mode (`ARCHITECTURE-BD-203-V3.md:68-73` EE-4). BUT the LOCKED `tracker.toml` carries a `[mirror]` table (`tracker.toml.pack-example:33-39`) whose `location_backlog="BACKLOG.md"` model no-mirror voids — see C1 | **CONFLICT (BLOCKER)** |
| D-3 Migrate script surface | `ARCHITECTURE-V3.md:162` | BD-203 leaves `scripts/lib/tracker-migrate-*.sh` present; pack-surface emit/read targets still monolith (`tracker-migrate-reverse.sh:1059`, `tracker-migrate-forward.sh:733`) — see C2 | **CONFLICT (MAJOR)** |
| D-4-V2 FORM FAMILY (the locked exemplar) | `ARCHITECTURE-V3.md:164`, `:105` | `work-item.yml:1-106` intact; per-entry body is faithful Issue-body source; ID/title carriable. Form fields vs ~full BD field-set has overflow boundary but the sidecar (D-8) is the designed catch — see C5 (MINOR, not a form conflict) | **COMPATIBLE** |
| D-5 Mode detection = `tracker.toml` presence | `ARCHITECTURE-V3.md:165` | BD-203 unaffected; detect.sh pack branch repointed to tree (`detect.sh:48-52`) without touching mode-detection semantics | **COMPATIBLE** |
| D-6 Trinity Document-locations table | `ARCHITECTURE-V3.md:166` | BD-203 corrected trinity structure lines to no-mirror SSOT (`ARCHITECTURE-BD-203-V3.md:209`); a Source column is additive | **COMPATIBLE** |
| D-7 Failure-mode UX — "mirror as fallback when fresh" | `ARCHITECTURE-V3.md:167` | "mirror as fallback" presumes a mirror EXISTS to fall back to; BD-203 deleted it + forbade recreation (`backlog/_rules.md:20-23`, `feedback_fail_loud_delete_old_source.md:13-24`). Check 29 staleness guard (`validate-pack.py:2699-2778`) encodes the mirror-fallback model — see C3 | **CONFLICT (MAJOR)** |
| D-8 Reverse migration + sidecar | `ARCHITECTURE-V3.md:168` | Reverse exists (BD-067); sidecar model compatible. But the reverse EMIT TARGET is the monolith (`tracker-migrate-reverse.sh:1056-1060`); BD-203 §3.7 designs the per-entry emit INTERFACE but defers the wiring — see C2/NEEDS-WIRING | **NEEDS-WIRING** (interface designed `ARCHITECTURE-BD-203-V3.md:244-272`) |
| D-9 Agent reads = LCD `gh` | `ARCHITECTURE-V3.md:169` | `tracker-agent-read.sh` flat-file branch still greps `pack-ops/BACKLOG.md` (`:264,:267`) — deleted file — see C4 | **CONFLICT (MINOR)** |
| D-10 Auth = single `gh auth` | `ARCHITECTURE-V3.md:170` | Untouched by BD-203 | **COMPATIBLE** |
| D-11 PACK-FEEDBACK upstream | `ARCHITECTURE-V3.md:171` | `inbound.yml` untouched; per-entry tree is BD-only, no inbound coupling | **COMPATIBLE** |
| D-12 Pre-existing tracker deferred | `ARCHITECTURE-V3.md:172` | Untouched | **COMPATIBLE** |
| D-13 License = none new | `ARCHITECTURE-V3.md:173` | Untouched | **COMPATIBLE** |
| D-14 External-issue triage | `ARCHITECTURE-V3.md:174` | Untouched (label/triage queue is tracker-side) | **COMPATIBLE** |
| D-15 Token measurement | `ARCHITECTURE-V3.md:175` | Untouched | **COMPATIBLE** |
| D-16 Multi-template = form family | `ARCHITECTURE-V3.md:176` | Same as D-4-V2 — form family intact | **COMPATIBLE** |
| D-17 Structure-vs-free-text split | `ARCHITECTURE-V3.md:177` | Per-entry body preserves prose verbatim; structured fields (Status/Blockers) are parseable from the entry — fits the split | **COMPATIBLE** |
| D-18 `template_version` dual carrier | `ARCHITECTURE-V3.md:178` | Pack BD entries carry NO `template_version` field today (`backlog/BD-167b.md`, `backlog/BD-195.md` — none present); the dual carrier is created at forward-time, not lost — see C8 (MINOR) | **NEEDS-WIRING** |
| DELTA A2 sidecar `extra_fields` | `ARCHITECTURE-V3.1-DELTA.md:182,:258` | Sidecar emitter built (`tracker-sidecar.sh`); `template_archive_path` points into `templates-archive/` which exists for v11.0 (`maintenance-docs/v11-research/templates-archive/v11.0`). Compatible; overflow boundary is C5 | **COMPATIBLE** |
| V3.3 §6.1 form-family extended | `ARCHITECTURE-V3.3-DELTA.md:310` | Phase-task extension is project-side; pack BDs are flat L1 — no pack conflict | **COMPATIBLE** (project-side, out of pack judgement) |
| V3.3 §6.3 status mapping | `ARCHITECTURE-V3.3-DELTA.md:341-358` | Maps Open/Unblocked/Resolved/Cancelled/Deprecated. **`Deferred` (a BD-203-admitted state, `backlog/_rules.md:59`; 11 live entries, AMENDMENT EE-A7) has NO BD/TD row in §6.3** — confirmed absent from V3.3/V2/V1 — see C6 | **CONFLICT (MAJOR)** |
| V3.3 §6.4 identifier carrier | `ARCHITECTURE-V3.3-DELTA.md:360-369` | `<!-- pack-id: BD-NNN -->` marker model fits. Suffix `BD-167b` + parenthetical `BD-195 (Code Red 3)` need a stable carrier — BD-203 §3.7 RATIFY #2 flags it as OPEN — see C7 (MINOR) | **NEEDS-WIRING** (`ARCHITECTURE-BD-203-V3.md:265`) |
| BD-203 D1 doc-governance (`_rules.md` SOLE / `_intro.md` human-only) | `ARCHITECTURE-BD-203-V3-AMENDMENT.md:179-180` | Landed (`backlog/_rules.md:1-7`, `changelog/_rules.md:1-7`). `_intro.md` human-only collides with BD-133 header-snapshot wanting a regenerated header home — see C7b (MINOR) | **NEEDS-WIRING** |
| BD-203 no-mirror standard | `backlog/_rules.md:20-23` | This IS the BD-203 landed standard; it is the SOURCE of the C1/C2/C3/C4 collisions against the locked mirror machinery | **COMPATIBLE** (it is the anchor; the locked mirror layer is what conflicts with it) |
| BD-203 `Unblocked` canonical state | `ARCHITECTURE-BD-203-V3-AMENDMENT.md:195`; `backlog/_rules.md:57-58` | `Unblocked` IS in V3.3 §6.3 (`:346` `open + status:unblocked`) — clean match | **COMPATIBLE** |

---

## 3. Ranked CONFLICT list (severity + BD-204-entry implication — NO fix proposed)

### C1 — BLOCKER — the LOCKED `tracker.toml [mirror]` model + Check 29 staleness guard have NO destination under no-mirror

**Locked side:** `tracker.toml.pack-example:33-39` declares a first-class `[mirror]` table:
`location_backlog = "BACKLOG.md"`, `location_status = "STATUS.md"`, `location_changelog = "CHANGELOG.md"`, plus a `# "tracker" = use tracker as source-of-truth; mirrors regenerated.` comment (`:26`). `validate-pack.py:2699-2778` (Check 29, `_check_mirror_staleness`) FAILS CI when `mode.state="tracker"` + `forward_complete=true` and any `mirror.location_*` file is missing or its `Last regenerated:` header is stale. This is the concrete realization of D-7 "mirror as fallback when fresh."

**BD-203 side:** `backlog/_rules.md:20-23` — "**There is no monolithic mirror.** The former `pack-ops/BACKLOG.md` monolith was deleted at BD-203; do not recreate it." The fail-loud rule (`feedback_fail_loud_delete_old_source.md:13-24`) makes recreating a regenerated mirror an explicit VIOLATION of the user-imposed standard.

**Why BLOCKER:** the LOCKED Mode-3 design REQUIRES a regenerated monolith mirror to exist (config points at it; CI guard fails without it). The no-mirror standard FORBIDS one. A BD-204 that runs the BUILT forward path on the pack in tracker mode would either (a) regenerate `pack-ops/BACKLOG.md` (violating no-mirror + the deletion rule), or (b) leave `mirror.location_*` dangling and trip Check 29 RED. This is not a runtime read-site repoint — it is a **LOCKED config-schema + CI-guard contradiction** that BD-203 did NOT enumerate in its §3.5 deferred-repoint set (§3.5 covers `tracker-agent-read`/`doctor`/`header-snapshot`/`forward`/`reverse` runtime, not the `tracker.toml` schema or Check 29).

**BD-204 entry implication:** the entry MUST explicitly state that the pack's Mode-3 `tracker.toml` either omits the `[mirror]` table or repoints `location_*` to the per-entry tree, AND that Check 29's staleness model is retired/repointed for the no-mirror pack surface — and must name this as a LOCKED-design reconciliation, not a free redesign (the `[mirror]` config is part of D-2/D-7). It cannot be silent: the prior attempt's restart doc (§D-2.2/§D-3.2 T7) lists the runtime libs but does NOT list the `tracker.toml [mirror]` schema or Check 29 as collision surfaces.

### C2 — MAJOR — BUILT forward+reverse pack-surface emit/read targets are the deleted monoliths

**Locked side (built):** forward reads `backlog_path="$repo_root/pack-ops/BACKLOG.md"` (`tracker-migrate-forward.sh:733`) and regenerates it at Step 10 (`:1202` `_tmf_regen_mirror "$backlog_path"`). Reverse emits `backlog_out="$repo_root/pack-ops/BACKLOG.md"` / `changelog_out=".../CHANGELOG.md"` (`tracker-migrate-reverse.sh:1059-1060`) and the disable-backup loop snapshots those paths (`:1082-1097`).

**BD-203 side:** monoliths deleted; reverse must emit the per-entry TREE (`ARCHITECTURE-BD-203-V3.md:246`).

**Why MAJOR (not BLOCKER):** BD-203 EXPLICITLY designed this hand-off — §3.7 (`:244-272`) marks `[RATIFY] per-entry emit target shape` and the reverse-INTERFACE; the runtime repoint is a `LOGICAL-FIT` deferral to BD-204 (`:232`). It is dormant in flat-file mode (no tracker.toml today), so it does not break CI now. It is the KNOWN, scoped Mode-3 wiring. It is MAJOR rather than MINOR because it is the load-bearing lossless-round-trip path and the forward READ side (`:733`) is a NEW collision beyond what §3.5/§3.7 enumerated (§3.7 names the reverse emit; the forward READ of `pack-ops/BACKLOG.md` as migration INPUT is equally dead and must source from the tree).

**BD-204 entry implication:** already substantially covered (the corrected entry draft `RESEARCH-...:480` lists `[WIRE+TEST] the deferred tracker-lib runtime repoints`). The entry should additionally name the **forward READ-side input** (`tracker-migrate-forward.sh:733`) as a repoint target, not only the reverse emit — forward now reads the tree, not the monolith.

### C3 — MAJOR — D-7 "mirror as fallback when fresh" is structurally unrealizable under no-mirror

**Locked side:** `ARCHITECTURE-V3.md:167` — failure UX includes "mirror as fallback when fresh." The mechanism is the Check 29 staleness gate (C1) + the read-only mirror header written by `tracker-mirror.sh` (`validate-pack.py:2673-2697` `_read_mirror_last_regenerated`).

**BD-203 side:** there is no mirror, fresh or stale, to fall back to (`backlog/_rules.md:20-23`).

**Why MAJOR:** distinct from C1 (the config artifact) — this is the DESIGN PRINCIPLE D-7 names. Under no-mirror, agent reads fall back to the per-entry TREE (which IS the SSOT, always "fresh"), not a mirror. The locked failure-UX wording assumes a two-tier (tracker + mirror) read model; the pack now has a two-tier (tracker + tree) model. Semantically reconcilable but the locked wording is wrong for the pack surface.

**BD-204 entry implication:** the entry must state that for the no-mirror pack surface, the D-7 "mirror fallback" reads the per-entry tree (the SSOT), and the freshness/staleness concept maps to tree-regeneration cadence (BD-203 §3.7 NUDGE #3, `ARCHITECTURE-BD-203-V3.md:266`), not a mirror timestamp.

### C4 — MINOR — `tracker-agent-read.sh` flat-file branch reads the deleted monolith

**Locked side (built):** `tracker-agent-read.sh:264` `BD-*) mirror_path="$repo_root/pack-ops/BACKLOG.md"`; `:267` default also points there; header `:7` "flat-file mode: greps the BACKLOG.md mirror."

**BD-203 side:** `pack-ops/BACKLOG.md` deleted.

**Why MINOR:** dormant unless agent-read is exercised; BD-203 §3.5 explicitly lists `tracker-agent-read.sh` as a deferred repoint (`ARCHITECTURE-BD-203-V3.md:143`). Known + scoped.

**BD-204 entry implication:** covered by the existing `[WIRE+TEST] deferred tracker-lib runtime repoints` clause; no new entry text needed beyond confirming `tracker-agent-read.sh` is in the repoint set.

### C5 — MINOR — form field-set vs full BD field-set overflow boundary (NOT a form conflict)

**Locked side:** `work-item.yml:16-99` carries Type/Kind/Status/Blockers/Unblocks/File-Symbol/Description/Context/Resolution.

**BD-203 side:** real pack entries also carry `Target:`, `Position:`, `Surfaced:`, `Alias:`, `Goal:`, `Scope:`, `Steps:`, `Segments:`, multi-line `Resolved:` (`backlog/BD-195.md:5-44` is a ~40-line entry with Segments/Steps/State blocks; `backlog/BD-204.md:5-16` carries Target/Position/HARD CONSTRAINT/REVERSIBILITY).

**Why MINOR (and why NOT a form conflict):** the LOCKED model is explicitly forms-as-primary + **sidecar-as-overflow** (`ARCHITECTURE-V3.1-DELTA.md:182`; `RESEARCH-...D-3.1`). Fields beyond the form set ride the Issue BODY (free-text, D-17) or sidecar `extra_fields`. No pack field has "nowhere to go." This is the designed overflow boundary (BD-203 §3.7 / T1), not a surprise.

**BD-204 entry implication:** the entry should confirm the OPEN mechanic "which fields ride form body vs sidecar `extra_fields`" is an architect decision bounded by the locked forms+sidecar carrier — already in the corrected draft (`RESEARCH-...D-3.2 T1`). Note the **large free-text entries** (BD-195's Steps/Segments) as the stress case for body-faithfulness.

### C6 — MAJOR — `Deferred` BD/TD status has NO row in the LOCKED V3.3 §6.3 status mapping

**Locked side:** `ARCHITECTURE-V3.3-DELTA.md:341-358` maps TD/BD Open, Unblocked, Resolved-direct, Resolved-via-promotion, Cancelled, Deprecated. There is **no `Status: Deferred` → tracker row for BD/TD.** Verified absent from V3.3, and `grep` found no `status:deferred` BD/TD mapping in V2 or V1. `Deferred` appears in §6.3 ONLY as a phase-task state (`:355`), and in the `work-item.yml` `wi-status` dropdown (`:51`) — but the dropdown is intake-only; the round-trip STATE mapping table is §6.3, which omits it for BD/TD.

**BD-203 side:** `Deferred` is a canonical admitted lifecycle state (`backlog/_rules.md:59`) with **11 live entries** (`ARCHITECTURE-BD-203-V3-AMENDMENT.md:132` status distribution: `11 Deferred`).

**Why MAJOR:** 11 of the pack's entries have a status the LOCKED forward-status-mapping table does not cover. A forward migration of the pack's OWN backlog (the dogfood) hits this on day one. It is not a per-entry-tree defect — it is a gap in the LOCKED §6.3 table relative to the pack's real status vocabulary. Note the inverse asymmetry too: the form `wi-status` enum (`work-item.yml:45-53`) carries `Pending / In Progress / Done` which BD-203's `_rules.md` does NOT admit — the two vocabularies are not aligned.

**BD-204 entry implication:** the entry must surface that the LOCKED §6.3 status mapping lacks a BD/TD `Deferred` row (and that the form's `Pending/In Progress/Done` are not pack-backlog states), and flag it as a status-vocabulary reconciliation the architect must resolve WITHIN the locked carrier (a `status:deferred` label + closed/open state choice) — NOT a free redesign of the status model. This is an UNMARKED-adjacent gap the restart doc did not catch.

### C7 — MINOR — suffix/parenthetical ID round-trip carrier is OPEN (BD-203-flagged)

**Locked side:** `ARCHITECTURE-V3.3-DELTA.md:360-369` — ID carrier = title prefix + `<!-- pack-id: BD-NNN -->` body marker, base-ID only.

**BD-203 side:** `BD-167b` (suffix; `backlog/BD-167b.md:2`) and `BD-195 (Code Red 3)` (parenthetical; `backlog/BD-195.md:2`, where `_rules.md:39-43` declares the parenthetical is TITLE TEXT not ID). The base marker carries `BD-195`/`BD-167`; the suffix `b` and the parenthetical must survive in a stable parseable position.

**Why MINOR:** BD-203 §3.7 RATIFY #2 (`ARCHITECTURE-BD-203-V3.md:265`) explicitly marks this OPEN and designs the constraint ("ID in a stable parseable position, NOT inferred from title prose"). Known + designed-against.

**BD-204 entry implication:** already in the corrected draft (`RESEARCH-...:480` `[RATIFY] the ID + parenthetical-title round-trip carrier`). Confirm the 2 suffix entries + the 1 parenthetical entry are the exact stress set.

### C7b — MINOR — BD-133 header-snapshot vs `_intro.md` human-only (D1)

**Locked side (built):** `tracker-header-snapshot.sh:17-28` snapshots the `# BACKLOG` monolith header and re-prepends it on reverse emit; reverse calls `tracker_header_snapshot_capture` (`tracker-migrate-reverse.sh:1109`).

**BD-203 side:** no monolith header exists; `_intro.md` is the tree's human header but is HUMAN-ONLY with ZERO agent/regenerated content (`ARCHITECTURE-BD-203-V3-AMENDMENT.md:180`; `backlog/_rules.md:7`).

**Why MINOR:** BD-203 §3.7 RATIFY #5 (`:268`) flags exactly this re-map and asks whether a regenerated header belongs in human-only `_intro.md`. Dormant; known.

**BD-204 entry implication:** the entry should note the header-snapshot mechanism re-maps to the no-mirror tree and that writing a regenerated header into human-only `_intro.md` is a D1-governance tension to resolve (RATIFY #5) — already gestured at in the corrected draft.

### C8 — MINOR — `template_version` dual carrier is created-not-lost (NEEDS-WIRING)

**Locked side:** D-18 (`ARCHITECTURE-V3.md:178`) + form trailer `<!-- template_version: work-item-v11.0 -->` (`work-item.yml:104`).

**BD-203 side:** pack entries carry no `template_version` field (none in `backlog/BD-167b.md` / `BD-195.md`).

**Why MINOR:** the dual carrier is MINTED at forward-time (the form/migration adds it); the per-entry tree's absence of it today is expected, not a loss. The sidecar `template_archive_path` resolves into `templates-archive/v11.0/` which EXISTS (note: BD-195 deleted only the fictional `v11.1` cut; `v11.0` is intact).

**BD-204 entry implication:** no special handling beyond confirming forward mints `template_version: bd-v11.0` and reverse round-trips it via the sidecar (DELTA A2). Low risk.

---

## 4. Fundamental conflicts

**None found.** BD-203's landed work (the per-entry tree shape, the no-mirror `_rules.md` contract, the deleted monoliths, the engine + validator changes) **can host the locked tracker/form design without modifying BD-203 itself.** Every conflict above lives on the TRACKER-SIDE wiring or config (the libs, `tracker.toml [mirror]`, Check 29, the §6.3 status table) — surfaces BD-204 owns — not on the per-entry tree BD-203 built. The per-entry tree is a clean forward-migration SOURCE and a clean reverse-emit TARGET; the form family is fully compatible with it; the sidecar overflow model accommodates every pack field.

The BLOCKER (C1) is loud but is NOT fundamental: it does not require un-doing BD-203's no-mirror deletion. It requires BD-204 to RECONCILE the LOCKED `[mirror]` config + Check 29 to the no-mirror reality (retire or repoint), which is squarely BD-204's Mode-3 scope — the same shape as the reverse-emit repoint BD-203 already deferred. The single thing the restart doc under-scoped is that this reconciliation extends BEYOND the runtime libs into the **`tracker.toml` schema and the Check 29 CI guard** — C1 names that gap so BD-204's entry can describe a realistic approach that owns it up front.

**One loud note for the user (not a fix, a flag):** the famous prior-attempt failure was *missing the form family*. This assessment finds the form family is the LEAST of the compatibility problems — it is fully compatible. The REAL incompatibility surface is the **monolith-mirror machinery (D-2 `[mirror]` config / D-7 fallback / D-8 reverse emit / Check 29)** that the locked design built and BD-203 deleted the target of. A BD-204 that fixates on "use the forms this time" and treats the mirror layer as already-handled would walk into C1/C3/C6 — the inverse of the prior miss. The restart's §D-2.2 OPEN set + §D-3.2 tensions (T1–T9) capture C2/C4/C5/C7 well, but do NOT name C1 (the `[mirror]` config + Check 29) or C6 (the `Deferred` §6.3 gap) — those two are the assessment's net-new surfaces for the BD-204 entry to absorb.

---

## 5. Rules-Applied Verification Block

| Rule / Read-in-full doc | Verification evidence (quoted / path / measurement) | Conclusion |
|---|---|---|
| **Empirical evidence for every state-claim (both sides, HEAD `ed47be4`)** | Every §2 row + §3 conflict cites `file:line` on the locked side AND the BD-203 side (e.g. C1: `tracker.toml.pack-example:33-39` + `validate-pack.py:2699-2778` vs `backlog/_rules.md:20-23`; C6: `ARCHITECTURE-V3.3-DELTA.md:341-358` vs `ARCHITECTURE-BD-203-V3-AMENDMENT.md:132`). HEAD verified `git rev-parse HEAD → ed47be4159c80...`. C2/C4 line cites confirmed by direct grep (`tracker-migrate-reverse.sh:1059`, `tracker-migrate-forward.sh:733`, `tracker-agent-read.sh:264`). | COMPLIANT |
| **Scope deliverables to the ask — no noise** | Output = verdict headline + per-locked-decision table + ranked CONFLICT list + fundamental-conflict callout + this block. No redesign, no proposed fixes (every C row ends in "entry implication," not a patch), no speculative findings. | COMPLIANT |
| **Pattern-matching out of context** | Each verdict property-fit-checked, not thematic: form family judged COMPATIBLE by field/body/sidecar fit (not "both use structure"); `[mirror]` judged CONFLICT by destination-existence (not "both have BACKLOG.md"); §6.3 judged CONFLICT by row-presence measurement (Deferred absent), not resemblance. | COMPLIANT |
| **Pack/project separation of concerns** | Judged PACK branch only: V3.3 §6.1 phase-task extension marked project-side/out-of-judgement; `_tmr_emit_backlog` judged on the `surface == "pack"` branch (`tracker-migrate-reverse.sh:1056-1060`), client branch noted not judged. | COMPLIANT |
| **Fail-loud / delete-the-old-source** | Applied as the lens for C1–C4: every locked decision referencing a monolith/mirror (`[mirror]` config, D-7 fallback, reverse emit, agent-read) scrutinized against `backlog/_rules.md:20-23` + `feedback_fail_loud_delete_old_source.md:13-24` "DELETE ... do not recreate." Identified the mirror layer as the dominant conflict source. | COMPLIANT |
| **Enumerate ENCODING surfaces** | For each locked decision with an enforcing surface, checked that surface's BD-203 state: Check 29 (`validate-pack.py:2699-2778`) for `[mirror]`; Check 32′ (`validate-pack.py:124-138`) for no-mirror; the built libs (`tracker-migrate-forward/reverse.sh`, `tracker-agent-read.sh`, `tracker-header-snapshot.sh`) for D-3/D-8/D-9; `tracker.toml.pack-example:33-39` for D-2. | COMPLIANT |
| **Read-in-full: `RESEARCH-BD-204-RESTART-INTEGRATION.md` §D-2.1 (checklist)** | Read full doc (lines 1-448 + 449-542); §D-2.1 LOCKED table `:201-230` used verbatim as the §2 row set. | COMPLIANT |
| **Read-in-full: `backlog/BD-204.md`** | Read lines 1-17 (full); current entry's line 9 RATIFY/NUDGE framing assessed vs the corrected draft. | COMPLIANT |
| **Read-in-full: `backlog/_rules.md` + `changelog/_rules.md`** | Read full (1-86 / 1-67); no-mirror `:18-26`, lifecycle states `:54-66`, ID-extraction `:36-43` cited. | COMPLIANT |
| **Read-in-full: BD-203 design (`ARCHITECTURE-BD-203-V3.md` + `-AMENDMENT`)** | Read full (V3 1-413; AMENDMENT 1-245); §3.7 hand-off `:244-272`, §3.5 deferred repoints `:226-232`, AMENDMENT §F D1 `:175-184` + EE-A7 status dist `:132` cited. (No other `ARCHITECTURE-BD-203*-AMENDMENT` companion exists beyond `-V3-AMENDMENT`.) | COMPLIANT |
| **Read shipped BD-203 impl (tree + engine + validator + libs)** | `backlog/_rules.md`, `BD-167b.md`, `BD-195.md`, `_lib.sh:1-100`, `validate-pack.py` Check 29/32 + `_check_mirror_staleness`, `tracker-migrate-forward.sh:722-766/1195-1230`, `tracker-migrate-reverse.sh:1045-1119/750-770`, `detect.sh`, `recommendation.sh`, `tracker-agent-read.sh`, `tracker-header-snapshot.sh`, `tracker.toml.pack-example` all read directly this session. | COMPLIANT |
| **Read locked corpus (`work-item.yml`, V3.3 §6, V3.1-DELTA §3, DESIGN-BRIEF §1/§3.1)** | `work-item.yml:1-106` full; `ARCHITECTURE-V3.3-DELTA.md:308-437` (§6); `ARCHITECTURE-V3.1-DELTA.md:180-274` (§3); `DESIGN-BRIEF.md:18-30,55-75` read directly. | COMPLIANT |
| **Read memory: `feedback_fail_loud_delete_old_source.md`** | Read full (1-64); principles 1+2 + "do not recreate" + safe-before-delete cited in C1/C3 + the fail-loud rule row. | COMPLIANT |
| **Read memory: `feedback_pattern_matching_out_of_context_antipattern.md`** | Read full (1-41); property-fit discipline applied per-verdict. | COMPLIANT |
| **Read memory: `feedback_verify_availability_not_just_existence.md`** | Read full (1-47); confirmed assessment stays within GA + personal-account substrate (no Issue Fields/Types phantom invoked — out of scope here, none referenced). | COMPLIANT |
| **Read memory: `feedback_scope_deliverables_to_the_ask.md`** | Read full (1-35); report scoped to verdict table + ranked conflicts + fundamental callout; no sprawl. | COMPLIANT |

**No named document was derived rather than read.** Every checklist, contract, design, shipped-impl, locked-corpus, and memory file above was opened directly via the Read/Bash tools this session at HEAD `ed47be4`.

**End of PACK-REVIEW-BD-203-VS-LOCKED-COMPATIBILITY.md**
