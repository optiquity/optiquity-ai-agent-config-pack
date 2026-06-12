# RESEARCH-REBASELINE-INVENTORY — full inventory of non-resolved backlog entries vs the BD-203/BD-204 as-built reality

> **Agent:** pack-docs-researcher. **Mode:** READ-ONLY inventory — evidence + disposition
> INPUTS only (labeled); NO disposition calls, NO entry edits, NO live GitHub calls.
> **HEAD:** `1c18b28` (branch `v11-dev`), with the known concurrent working-tree churn in
> `scripts/` + untracked BD-204 cycle docs (ignored per the calling prompt's concurrency note).
> **Date:** 2026-06-11.
> **Consumer:** the re-baseline architect (per-entry disposition calls: no change / full
> rewrite / merge / combine / other), then user-gated application via the Mode-3
> tracker-edit path.

---

## 1. Count reconciliation (stated first — the BD-203 lesson)

| Method | Open | Unblocked | Deferred | Non-resolved total |
|---|---|---|---|---|
| `_toc.md` section line-counts (lines 7-35 / 39 / 43-53) | 29 | 1 | 11 | **41** |
| `grep -l "^Status: <S>" backlog/BD-*.md` per state | 29 | 1 | 11 | **41** |
| Whole-tree complement: 213 entry files − 167 Resolved − 4 Deprecated − 1 Cancelled | — | — | — | **41** |
| External cross-check: BD-204 live flip created 213/213 issues, closed=172 (= 167 Resolved + 4 Deprecated + 1 Cancelled); open remainder | — | — | — | **41** |

This report's inventory rows: **27 IN-SCOPE + 14 OUT-OF-SCOPE = 41.** All four methods agree.

`_toc.md` Resolved section spans lines 57–223 = 167 rows; Deprecated lines 227–230 = 4; Cancelled line 234 = 1 — consistent with the per-file Status grep.

---

## 2. As-built baseline the entries were checked against

1. **No-monolith model (BD-203):** `/backlog/` + `/changelog/` per-entry trees are the sole
   flat representation; `pack-ops/BACKLOG.md` + `pack-ops/CHANGELOG.md` deleted (verified
   absent; Check 32′ enforces).
2. **BD-204 as-built:** gz64 verbatim-body blob carrier (`pack-entry-body-gz64`,
   field-faithful, fail-loud decode); TrackerProvider abstraction with capability
   declarations (`provider_body_limit`, `provider_body_storage_format`); identity on the
   `<!-- pack-id: BD-NNN -->` marker, never issue numbers; two-lane inbound (pack-owned vs
   `inbound`/`needs-triage`, never swept until promoted); Mode-3 one-way tree regeneration
   per `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md`
   (tracker → tree, NOT a sync; `pack tracker tree-rebuild` verb; status-truth-is-the-blob
   comparator; freshness keys; §5 R1–R8 project-side requirements).
3. **Mode state at inventory time:** the C-8 flip RAN (live repo in Mode 3; working-tree
   `tracker.toml` has `[mode] state = "tracker"`, `forward_complete = true`) but the C-8
   commit is NOT YET MADE (`tracker.toml` is untracked `??`; no dogfood-flip commit in
   `git log`). BD-204 closure is pending.
4. **BD-211 header grammar:** filename-is-ID; no letter-suffix entries; parentheticals are
   title text after the em-dash (codified in `/backlog/_rules.md`).
5. **BD-212/BD-213 reset split:** BD-103 Deprecated; pack-side verb (BD-212, researcher
   census DONE and committed at `84f6a83`) + project-side application (BD-213).
6. **File reality:** every path/symbol cited in a finding below was verified by
   `ls`/`grep`/`git ls-files` this session (MISSING/EXISTS noted per finding).

---

## 3. Inventory table (all 41 non-resolved entries)

| BD | Title (abbrev.) | Status | Class | One-line state |
|---|---|---|---|---|
| BD-020 | C++ server support analysis | Open | OUT | Analysis-only; no entry/tracker/project-template surface; no BD-204-class staleness. |
| BD-031 | Publish skills to skills.sh | Deferred | OUT | External publication evaluation; no pack files change; untouched by re-baseline reality. |
| BD-036 | IDE and editor coverage gaps | Open | OUT | Companion-template gap watch; touches trinity only as future targets; no entry-machinery overlap. |
| BD-037 | Platform update observability | Open | OUT | Skill/context staleness watch; no entry-machinery overlap. |
| BD-039 | Prototype / speed mode | Open | IN | Client-mode design; write-targets (BACKLOG.md) + dead `supporting-docs/PM-CHAT.md` ref are stale. |
| BD-040 | Autonomous execution mode | Open | IN | Same PM-CHAT ref defect; "new Procedure 5" collides with existing Procedure 5; STATUS.md stop-marker conflicts with one-way regen. |
| BD-055 | Codex surface-gate live run | Deferred | OUT | CLI live-run verification of METHODOLOGY procedures; no entry-machinery overlap. |
| BD-056 | Codex Form I escalation doc | Deferred | OUT | METHODOLOGY Procedure 7.3 paragraph; no entry-machinery overlap. |
| BD-057 | Gemini plan-mode detection | Deferred | OUT | METHODOLOGY Procedure 7.1 pre-flight; no entry-machinery overlap. |
| BD-058 | Desktop Commander MCP scope | Deferred | OUT | METHODOLOGY Procedure 7.2.4 paragraph; no entry-machinery overlap. |
| BD-093 | v11.0 release pin | Open | IN | Cites the deleted `CHANGELOG.md` monolith + dead line-anchors; release-time write channels now mode-split. |
| BD-100 | Milestone checkpoints (CP1-3) | Open | IN | CP windows passed, zero CHECKPOINT artifacts exist; BD-205 declares the fold-in; carry-forwards still live. |
| BD-102 | Pack-repo dog-food migration | Open | IN | Premise overtaken by BD-203/204 self-migration; §6.J "ships flat-file" contradicts the executed Mode-3 flip. |
| BD-105 | STATUS.md dual-link rendering | Open | IN | Dead doctor path; user ruling re-orbits it into BD-206/207 with DUAL-MODE links; ops-contract R6 binds it. |
| BD-109 | auditor-issue-tracking agent | Open | IN | Skip-rule presumes client monoliths; Check-28 numbering stale; audit subject must absorb BD-211 + field-faithful contract. |
| BD-110 | pack-auditor agent | Open | IN | Audit surface is now GH Issues Mode 3 + regenerated tree; BD-100 CP-prompt dependency dead. |
| BD-136 | Trinity marker preservation | Open | IN | Validator-count claim (30 → 47) stale; review doc moved to archive; batch positioning superseded; M-8 fixture dir already exists. |
| BD-151 | Tier 0 observability skill | Deferred | OUT | v12 skill-catalog work; no entry-machinery overlap. |
| BD-152 | Tier 0 accessibility skill | Deferred | OUT | v12 skill-catalog work; no entry-machinery overlap. |
| BD-153 | Tier 0 concurrency skill | Deferred | OUT | v12 skill-catalog work; no entry-machinery overlap. |
| BD-154 | Skill-versioning frontmatter | Deferred | OUT | v12 skill-catalog work; no entry-machinery overlap. |
| BD-155 | Naming-convention enforcement | Deferred | OUT | v12 skill-catalog work; no entry-machinery overlap. |
| BD-171 | Real-OT scratch-repo harness | Open | IN | v10.1 pin → v10.3 (anchored); `gh repo delete --yes` violates archive-only (anchored); dead memory-file ref; overlaps BD-206/207 OT inputs. |
| BD-172 | Gate 2 post-dispatch extension | Open | IN | All paths/symbols verified intact; only the Batch 21.5/22/23 positioning is superseded (BD-205). |
| BD-174 | Scratch-pack-clone harness | Open | IN | `gh repo delete --yes` violates archive-only (anchored); "v10→v11 on a pack clone" premise overtaken; C-7 oracle overlaps. |
| BD-185 | Phase parts + execution ordering | Open | IN | Dead Paused line (BD-195 resolved); "do not survive sync" premise must re-derive vs blob carrier; F9 glob defect goes live with it. |
| BD-187 | Entry-type instruction doc | Open | IN | "Shapes settled" set grew (BD-211 grammar + field-faithful contract); otherwise valid v11.1+ anchor. |
| BD-188 | Phase-Iteration sprint view | Open | IN | TrackerProvider extension should follow the as-built capability-declaration pattern; otherwise valid v11.1+ anchor. |
| BD-189 | v11.1+ groupings umbrella | Open | IN | Cites deleted `pack-ops/BACKLOG.md` as input; v11-research inputs in tension with BD-210 deletion pass. |
| BD-192 | v11.1+ PS umbrella | Open | IN | Same deleted-monolith input citation + BD-210 tension; otherwise outside the blast radius. |
| BD-197 | Worktree isolation | Unblocked | IN | Paths verified; the git-stash verb-enumeration deferral is anchored ONLY in a memory slated for deletion at BD-204 close. |
| BD-198 | PACK-MEMORY-RATIONALE pack-chat-only | Open | IN | Work appears LANDED (`cb460e6`); entry still Open and written in pre-BD-209 "PM-only" vocabulary; "trees not yet created" stale. |
| BD-201 | Antigravity MCP relocation | Deferred | OUT | External-blocked (Antigravity GA); no entry-machinery overlap. |
| BD-202 | `pack update` propagation engine | Open | IN | v11.1 target stands; reversal-trigger watch-point names superseded Batch 23 (→ BD-205); BD-206 changes the asset-class set. |
| BD-204 | Pack backlog → GH Issues (Mode 3) | Open | IN | Flip ran, commit pending; BD-094↔BD-095 data cycle still in tree; ops contract extends the closure scope beyond the entry text. |
| BD-205 | Final readiness audit | Open | IN | Launch-gate enumeration omits BD-206/207/212/213; folded trio (BD-100/102/171/174) carries its own staleness into the fold. |
| BD-206 | Project-side per-entry no-mirror | Open | IN | POST-BD-204 REFRESH anchor now FIRES; user-approved scope additions 1,3-9 + ops-contract R1/R3/R4/R6/R7 to fold; Target TBD effectively forced v11.0. |
| BD-207 | Project-side reversible tracker | Open | IN | REFRESH anchor FIRES; carrier/write-model "decisions pending" are now DECIDED as-built; consumes ops-contract §5 R1-R8 verbatim. |
| BD-210 | Maintenance-docs cleanup | Open | IN | Blocker BD-set enumeration drifted (omits BD-212/213); BD-189/192 v11.1-input LIVE-classification is a new constraint. |
| BD-212 | `pack tracker reset` (pack side) | Open | IN | Researcher step DONE + committed (`84f6a83`) — Position line says "decision pending"; named lib path violates flat `tracker-*.sh` convention. |
| BD-213 | reset, project-side application | Open | IN | All referenced client paths verified; lowest staleness of the tracker set; rides BD-207's refreshed shape. |

OUT-OF-SCOPE one-liners are complete in the table above (14 rows marked OUT) — listed so the
inventory is provably complete against the 41-entry census.

---

## 4. Per-entry findings — IN-SCOPE set (27 entries)

Finding tags: **STALE-REF** (path/symbol no longer exists or moved), **STALE-FACT** (claim
contradicted by as-built reality), **STALE-PLAN** (batch/order superseded), **DRIFT**
(line-number anchor drift), **DONE** (work already landed), **VERIFIED-STILL-TRUE**
(claim re-checked and intact), **INPUT** (disposition input, labeled, not a call).

### BD-039 — Prototype / speed mode
1. STALE-REF: File/Symbol cites `supporting-docs/PM-CHAT.md` — file ABSENT (verified);
   the project-side PM doc is `project-template/docs/pack/PM-CHAT.md`.
2. STALE-FACT: "Reviewer findings are logged to BACKLOG.md as tech debt items" /
   "BACKLOG.md tracks all accumulated tech debt" presumes a writable client monolith.
   As-built: client flat-file SSOT is the per-entry tree (`docs/project/backlog/`); the
   monolith is a regenerated mirror until BD-206 retires it; in client tracker mode writes
   go through tracker tooling (ops contract R1/R3). Write-target wording must become
   stream/mode-neutral.
3. INPUT: the gate-relaxation design itself is untouched by BD-203/204 — surface-vocabulary
   refresh, not redesign.

### BD-040 — Fully autonomous execution mode
1. STALE-REF: same dead `supporting-docs/PM-CHAT.md` citation as BD-039.
2. STALE-FACT: "new Procedure 5 — autonomous execution loop" — Procedure 5 already exists
   (`supporting-docs/METHODOLOGY.md:1391` "Procedure 5 — Custom agent and skill workflow",
   relocated to INSTALL-PROCEDURES.md, with the 5-C/5-R/5-S family in use). Numbering
   collision; the loop needs a different procedure number/name.
3. STALE-FACT: "write ⚠ AUTONOMOUS STOP to STATUS.md" — in tracker mode STATUS.md is a
   regenerated convenience view with one-way overwrite semantics (ops contract R6:
   hand-edits to generated rows are overwritten at materialization). The stop-marker
   convention does not survive Mode 3 as designed; same for the loop's "update STATUS.md,
   advance phase" step and IMPLEMENTATION-PLAN.md reads (regenerated mirror in tracker mode).
4. INPUT: mode design needs a mode-conditional write-channel statement; depends on the
   BD-206/207 landed shape. BD-039 → BD-040 dependency intact.

### BD-093 — v11.0 release pin
1. STALE-REF: File/Symbol cites `CHANGELOG.md` — no monolith exists anywhere
   (`pack-ops/CHANGELOG.md` deleted by BD-203; release history lives at `/changelog/v11.md`
   in the per-entry tree).
2. STALE-REF (dead anchor): "CHANGELOG lines 248-266 at BD-150 ship time" indexes the
   deleted monolith. The audit-artifacts consolidation instruction must be re-measured and
   restated against `/changelog/v11.md` (which carries "Carried over to future work" at
   line 84 in its current shape).
3. STALE-FACT: "Blockers: All BDs above (BD-060..BD-092)" — "above" presumes monolith
   positional ordering; the per-entry tree has no "above". Those BDs are all Resolved;
   the live blockers are the remaining launch-gate BDs.
4. INPUT (mode): release-time entry writes are mode-split — backlog status flips via the
   Mode-3 tracker tooling; `/changelog/` stays flat-file in BOTH modes (ops contract §1.2).
   The pin procedure should name both channels. EXECUTION-PLAN-V11.0.md (Pattern-B sweep
   target) verified EXISTS.

### BD-100 — Pack-implementation milestone checkpoints
1. DONE/OVERTAKEN: CP1/CP2/CP3 were never produced — `find . -name "CHECKPOINT*"` returns
   ZERO hits (including `maintenance-docs/archive/`); blockers BD-068/082/085 are all
   Resolved; the checkpoint windows have passed. BD-205 explicitly incorporates "the prior
   Batch 22 (BD-100) milestone-audit scope."
2. VERIFIED-STILL-TRUE: carry-forward (a) — `check_help_fragment_completeness` (Check 23)
   still iterates top-level `scripts/` only (`scripts_dir.iterdir()`, validate-pack.py
   ~:2147), so `scripts/persona-contracts/` markers remain unscanned. Carry-forwards
   (b)/(c): `scripts/persona-contracts/contract-greenfield.sh` + `contract-mid-dev.sh`
   exist (inline-note content not re-audited here).
3. INPUT: merge-into-BD-205 candidate; the three carry-forwards are concrete audit items
   that must survive any merge.

### BD-102 — Pack-repo dog-food migration
1. STALE-FACT (premise overtaken): "maintainer runs `migrate-v10-to-v11.sh` + `pack
   tracker init` against the pack's own real BACKLOG" — the pack self-migrated via
   dedicated BDs instead: BD-203 (Mode 1→2 per-entry) and BD-204 (Mode 2→3 flip, already
   RUN live: 213/213 issues created). There is no pack monolith and no v10-shaped pack
   repo left to migrate.
2. STALE-FACT (contradiction): "Per §6.J ship decision: pack ships v11.0 in flat-file mode
   (reverse before release pin)" — directly contradicted by the executed Mode-3 flip + the
   user-ratified Mode-3 ops contract (`tracker.toml [mode] state="tracker"`,
   `forward_complete=true`). Whether v11.0 ships in Mode 3 or reverses pre-pin is a USER
   decision the stale text pre-empts.
3. STALE-REF: `scripts/tests/dog-food-checkpoint.sh` does not exist (planned, never built);
   `DOG-FOOD-MIGRATION-REPORT.md` likewise.
4. STALE-PLAN: "Batch 23 ordering ... BD-174 FIRST ... BD-171 SECOND ... BD-102 THIRD" —
   superseded by BD-205's fold-in of the live-GH trio.
5. INPUT: candidates — merge into BD-205, or full rewrite as a "Mode-3 dogfood
   validation/closure" item; interacts with BD-171/BD-174 dispositions.

### BD-105 — STATUS.md phase-row dual-link rendering
1. STALE-REF: File/Symbol `scripts/lib/pack-tracker/doctor.sh` — path does not exist (no
   `scripts/lib/pack-tracker/` directory); the as-built doctor is
   `scripts/lib/tracker-doctor.sh` (`tracker_doctor_run`).
2. INPUT (anchored user ruling): BD-105 joins the BD-206/207 refresh orbit with DUAL-MODE
   links (memory item 8): entry/phase links render to per-entry flat files in Mode 2 and
   INTO the GH Issues in Mode 3, tested on real OT STATUS.md content. The current entry
   describes only the tracker-mode Option-A dual link + reverse strip — the Mode-2
   per-entry-file link half is absent from the entry.
3. As-built binding: ops contract R6 names BD-105 explicitly (STATUS.md never source of
   truth; one-way regeneration semantics; the four dispositioned edge cases bind there).
4. STALE-FACT (vocabulary): "Bidirectionality contract honored" — the as-built model is
   one-way regeneration (tracker → tree), NOT a sync (ops contract §1.3 item 3).
5. Blockers BD-065/067/068/066/084 all Resolved — mechanically unblocked; the real
   sequencing anchor is now the BD-206/207 orbit.

### BD-109 — Project-side `auditor-issue-tracking` sub-agent
1. STALE-FACT: skip rule "brand-new project (no BACKLOG.md and no IMPLEMENTATION-PLAN.md)"
   — detection target changes post-BD-206 (per-entry trees, no client mirror) and in Mode 3
   (tracker is SSOT). Must be restated stream/mode-aware.
2. STALE-REF (numbering): "Check 28 enforces" trinity replication — current Check 28 is
   PM-startup per-CLI parity (BD-126, verified validate-pack.py:2486-2511); the planned
   "BD-082 ext (Check 28)" never landed under that number. "step 23a/23b" EXECUTION-PLAN
   step numbering is likewise superseded.
3. INPUT: the audit subject (dependency-graph integrity, syntax conformance) must absorb
   the BD-211 header grammar, the field-faithful entry contract, and the per-entry tree
   shape — the syntactic surface it audits changed under BD-203/206/207.
4. Sibling overlap with BD-110; sequencing decision vs BD-206/207 landing.

### BD-110 — Pack-side `pack-auditor` agent
1. STALE-FACT: audit surfaces "BACKLOG dependency graph, BD entry semantic consistency ...
   tracker-mode health" — the pack backlog is now GH Issues (Mode 3) with a regenerated
   tree; an ongoing-state audit must read tracker-side (or the regenerated tree) and
   respect one-way semantics + the status-coherence comparator/doctor legs the ops
   contract adds.
2. STALE-REF: File/Symbol "`PACK-CHAT.md` Audit cadence section" — no such section exists
   in `pack-ops/PACK-CHAT.md` (grep empty); it is a to-create deliverable, but the entry
   reads as if extending an existing section.
3. STALE-FACT: "`BD-100` CP-prompt extensions" — the BD-100 checkpoint framework never
   materialized (zero CHECKPOINT artifacts) and BD-205 folds that scope in; this dependency
   is dead as written. Blocker BD-074 Resolved.
4. INPUT: re-anchor cadence/CP language to BD-205; coordinate with BD-109 disposition.

### BD-136 — Trinity marker-section preservation
1. STALE-REF: Description cites `maintenance-docs/v11-implementation/PACK-REVIEW-OT-TRINITY-PREP.md`
   — file now lives at `maintenance-docs/archive/v11/PACK-REVIEW-OT-TRINITY-PREP.md`
   (Pattern-B swept; verified). Note BD-210 may delete the archive entirely.
2. STALE-FACT: "new Check (next available number; current count is 30 per Batch 8/9 work)"
   — the validator now carries 47 `def check_` functions (numbering through 47, Check 24
   retired); next available is ≥48.
3. DRIFT: line anchors `customization-preserve.sh:145-179` and `INSTALL-PROCEDURES.md`
   lines 472-479 have drifted (the `[CONDITIONAL]` handling prose sits near but not at the
   cited lines). Symbol/heading anchors preferred.
4. As-built note: `test-fixtures/v11-trinity-marker-prepped/` ALREADY EXISTS (verified) —
   M-8's "once OT's re-prepped trinity files exist ... copy them into ..." is partially
   realized; the entry should reflect the fixture's current state.
5. STALE-PLAN: Position "Batch 20.5 — between Batch 20 (STATUS.md + tracker reset) and
   Batch 21 (auditor agents)" + "before Batch 23 BD-102 dog-food" — the batch sequence is
   superseded by the launch-gate ordering (BD-203 → BD-204 → BD-197 → BD-185 → BD-205) and
   the tracker-reset split moved to BD-212/213.
6. INPUT: OT-derived fixtures overlap the BD-206 census / BD-171 harness OT inputs (OT now
   v10.3); the M-8 provenance should pin the version.

### BD-171 — Real-OT scratch-GH-repo migration harness
1. STALE-PIN (anchored correction, user-approved): "clone real OT into `/tmp` at v10.1
   tag" + "v10.1 → v11.0 migration" — OT now runs v10.3 (memory housekeeping item 5:
   "BD-171 clone pin v10.1 → v10.3"). At v10.3 the OT plan monolith still carries the
   pre-BD-104 underscore name `IMPLEMENTATION_PLAN.md` (memory item 1).
2. CONTRACT-VIOLATION (anchored correction): Description "tears down the scratch repo via
   `gh repo delete --yes`" — violates the archive-only disposal contract
   (`reference_gh_pat_no_delete`; BD-204 as-built: the PAT has no repo-delete; the tool
   ARCHIVES, manual delete is a USER-only recommended step).
3. STALE-REF: cites pack-memory file `feedback_test_infra_self_provisioned.md` — no memory
   file of that name exists (full memory-dir listing verified); the rule lives in trinity
   CLAUDE.md § Repo conventions ("Test infra is self-provisioned"), whose "clean up after"
   must now be read against archive-only disposal.
4. STALE-FACT: the multi-toggle description (flat → `pack tracker init` → reverse → init;
   "BACKLOG entry survival"; `tracker.toml` correctness) predates the as-built verb set
   (tree-rebuild per ops contract R2, freshness keys R8) and the no-client-monolith end
   state (post-BD-206 there is no client BACKLOG.md to "survive" — entries live per-entry).
5. STALE-PLAN: "Batch 22b or 23" positioning superseded by BD-205 fold-in.
6. INPUT (overlap): the OT clone content is ALSO the BD-206 researcher-census prerequisite
   and the BD-207 Layer-2 round-trip input (memory items 1-2), with the generalization
   guard (item 3: OT = stress input, never spec) and committed scrubbed-snapshot fixtures
   confirmed viable (item 4). Candidate re-orbit/combine with the BD-206/207 refresh +
   BD-205 fold — architect's call.

### BD-172 — Gate 2 post-dispatch extension
1. VERIFIED-STILL-TRUE: all referenced surfaces exist — `scripts/lib/migrate-v10-to-v11/
   checkpoint.sh`, `gate-2-phase-a-verify.sh`, `apply.sh`/`resume.sh` (both containing
   `_v10_to_v11_orig_post_report`), `scripts/tests/test-migrate-v10-to-v11-gates.sh`.
2. STALE-PLAN: Position "Batch 21.5 between Batch 21 (auditor agents) and Batch 22
   (milestone audit)" and the "before Batch 22 (BD-100) / Batch 23 (BD-102)" motivation —
   both anchors superseded by BD-205 (which folds those scopes). The truthful-Gate-2
   requirement now serves BD-205's readiness audit.
3. INPUT: content scope intact; re-anchor only.

### BD-174 — Scratch-pack-clone migration + multi-toggle harness
1. CONTRACT-VIOLATION (anchored correction, the named one): File/Symbol "tear down scratch
   repo via `gh repo delete --yes`" — violates the archive-only contract
   (`reference_gh_pat_no_delete`), same correction class as BD-171.
2. STALE-FACT: "runs the actual v10 → v11.0 migration end-to-end ON THE SCRATCH CLONE" —
   a clone of today's pack repo is already per-entry + Mode-3 (post-BD-203/204); there is
   no v10-shaped pack state to migrate. A scratch-pack-clone test must exercise the
   Mode-2↔3 toggles (and `pack tracker tree-rebuild`), not a v10→v11 run.
3. STALE-FACT: "multi-toggle ... BACKLOG entry survival" monolith vocabulary; and the
   as-built C-7 oracle (`scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`, live,
   scratch-repo, archive-only, repeated-cycle CRUD legs, 66/0 green at rehearsal run 4)
   already covers much of this surface — duplication question for the architect.
4. STALE-REF: same dead `feedback_test_infra_self_provisioned.md` memory citation as BD-171.
5. STALE-PLAN: Batch 23 trio framing → BD-205.
6. INPUT: candidate merge with BD-171/BD-102 into a BD-205 live-GH leg set; the C-7 oracle
   is the prior art to build on, not around.

### BD-185 — Phase parts hierarchy + tracker-mode execution ordering
1. STALE-STATUS: "Paused: 2026-05-28 — PAUSED pending Code Red 3 (BD-195)" — BD-195
   Resolved 2026-06-03; the Blockers line was updated (2026-06-04 launch-gate order) but
   the Paused field was never removed. Dead state line.
2. DRIFT: "METHODOLOGY.md Part 3 § Multi-part phases (lines ~339-366)" — the section is now
   `### Multi-part phases` at line 414 (verified).
3. STALE-FACT (premise to re-derive): P3's "In tracker mode, IMPLEMENTATION-PLAN.md is a
   regenerated mirror — execution notes do not survive sync" — BD-204's as-built gz64
   verbatim-body blob is FIELD-FAITHFUL (whole entry body survives byte-for-byte); BD-207
   carries the same carrier class to client streams. Whether phase-entity execution notes
   survive now depends on the carrier applying to phase issues — the loss premise must be
   re-derived against the blob-carrier reality, not assumed.
4. STALE-FACT (vocabulary): SC7 "Bi-directional sync (BD-060 TrackerProvider, mirror
   semantics)" — the as-built model is ONE-WAY regeneration (tracker → tree, NOT a sync;
   ops contract §1.3 item 3). SC7 needs round-trip/regeneration vocabulary.
5. STALE-FACT: "V11.1-DISCUSSION-GITHUB-PROJECTS.md in main branch — not present on v11-dev
   yet" — the file EXISTS on v11-dev (verified).
6. DEFECT-COUPLING: the BD-108 F9 phase-glob defect (new-BD candidate, §6 item 1) is latent
   exactly because phase-tasks are never in the id-map at v11.0; BD-185 introduces the
   phase-entity machinery that makes it LIVE ("becomes live the day phase-task creation
   lands" — review evidence). Sequencing: the glob fix lands before-or-with BD-185.
7. VERIFIED-STILL-TRUE: `scripts/lib/tracker-provider-*.sh`, `work-item.yml` (×2 surfaces),
   `scripts/lib/per-entry/_lib.sh`, `_tmr_emit_implementation_plan`, and the queued
   researcher prompt all exist. Note: the ops contract's `tree_only` arm SKIPS
   `_tmr_emit_implementation_plan` on the PACK surface; the client arm (BD-185's concern)
   is untouched until BD-207.
8. INPUT: BD-185's phase/part entities are precisely what BD-207's client tracker must
   carry; BD-211 grammar + the two-lane model govern phase-entity headers and intake.

### BD-187 — Standalone entry-type instruction doc
1. STALE-FACT (incomplete basis): "Backlog / phase / task shapes already settled in v11.0"
   — the settled set GREW since authoring: BD-211 header grammar (filename-is-ID, no letter
   suffixes, parenthetical placement), the field-faithful entry contract
   (`/backlog/_rules.md` § Entry contract: common fields enumerated by METHODOLOGY Part 7;
   extension fields admitted + preserved). The future doc's content basis must cite these.
2. INPUT (adjacency, not scope growth): in Mode 3 the inbound lane (`inbound.yml`,
   two-lane separation) is how external parties file pack-compatible items — the doc's
   OUTPUT-only boundary is intact, but the architect may note the lane as the delivery
   adjacency.
3. v11.1+ deferral (user-approved 2026-05-24) intact; authoring blocker (BD-186 closed —
   it IS Resolved) is satisfied; scheduling judgment unchanged.

### BD-188 — Phase-Iteration sprint view
1. INPUT (alignment): "Per-backend Iteration primitive support via BD-060 TrackerProvider
   abstraction extension" — the as-built provider contract now carries DECLARED
   capabilities (`provider_body_limit`, `provider_body_storage_format`; BD-212 adds the
   `issues.delete` capability class). The Iteration extension should follow the
   capability-declaration pattern; the entry's C7 graceful-degradation language is
   compatible.
2. Light: the `pack tracker` verb namespace grew (tree-rebuild incoming; possibly
   edit/new-entry per OQ-A) — verb naming should clear the new namespace.
3. Blockers valid: BD-186 Resolved (authoring input exists); BD-189 not started (hard
   blocker stands).

### BD-189 — v11.1+ groupings implementation umbrella
1. STALE-REF: PRIMARY INPUTS cite "`pack-ops/BACKLOG.md` entries BD-186 + BD-187 + BD-188"
   — the monolith is DELETED (BD-203). Pointer must be `/backlog/BD-186.md` etc. (or the
   tracker in Mode 3).
2. TENSION (input for BD-210 + this entry): the PRIMARY INPUTS are
   `maintenance-docs/v11-research/*` docs; BD-210 deletes superseded maintenance-docs
   pre-launch. BD-189's inputs must be classified LIVE in BD-210's enumeration, or this
   entry's input list breaks at v11.1 start. All input docs verified EXIST today.
3. Otherwise valid v11.1+ anchor (blocker "v11.0 ships" unchanged).

### BD-192 — v11.1+ Product Specialist umbrella
1. STALE-REF: same deleted-monolith input citation ("`pack-ops/BACKLOG.md` entries BD-186 +
   BD-189 + BD-191") as BD-189.
2. TENSION: same BD-210 LIVE-classification dependency for its `v11-research/` input set
   (REQUIREMENTS-PS-V11.md etc. verified EXIST).
3. Otherwise outside the BD-203/204 blast radius (client-side v11.1+ feature).

### BD-197 — Worktree isolation (Unblocked)
1. ANCHOR-RISK (the load-bearing finding): the user-approved deferral "AT BD-197: add
   `git stash` (+ `reset`/`restore --staged`/`checkout --` class) to the prohibited-verb
   enumeration across trinity ×3 + PACK-AGENTS.md + commit-discipline ×3 + rationale doc;
   revisit mechanical enforcement" lives ONLY in
   `project_bd204_cycle_position.md` § "Deferred to BD-197" — a memory file whose own
   header says DELETE once BD-204 C-8 lands. If the memory is deleted before BD-197's
   entry absorbs the item, the deferral loses its anchor (deferred-work-tracked-anchor
   violation). The re-baseline should fold the item into the BD-197 entry text.
2. VERIFIED-STILL-TRUE: CLAUDE.md worktree-prohibition bullet present (§ Sub-agent
   behavior); `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`,
   `maintenance-docs/v11-implementation/PREWORK-BD-197-WORKTREE-ISOLATION-AUDIT-PROMPT.md`,
   `pack-ops/OPTIONAL-FEATURES.md`, `project-template/docs/pack/OPTIONAL-FEATURES.md`, and
   the commit-discipline skill dirs ×3 all exist.
3. INPUT (cross-entry consistency): BD-185's blocker text carries the launch-gate order
   (BD-203 → BD-204 → BD-197 → BD-185 → BD-205); BD-197's own Position text predates it
   ("user decides the exact start"). Harmonize at re-baseline.
4. Light: the P2 removal inventory is a self-declared non-binding starting reference with
   a fresh-audit requirement — robust to the BD-203/204 churn by design.

### BD-198 — Formalize PACK-MEMORY-RATIONALE.md (pack-chat-only surface)
1. DONE: the work appears LANDED at commit `cb460e6` ("feat: v11 — BD-198 formalize
   PACK-MEMORY-RATIONALE.md as a Pack-Chat-direct surface (pack-only)"). Verified all four
   acceptance criteria surfaces: `pack-ops/PACK-AGENTS.md` § "pack-chat-only files and
   directories" line 138 lists the doc with a "— BD-198" attribution;
   `scripts/validate-pack.py` `_PACK_CHAT_ONLY_PERMITTED_PATHS` (line 4014) contains
   `pack-ops/PACK-MEMORY-RATIONALE.md`; `scripts/tests/test-validate-pack-checks-36-37-38.sh`
   references the doc (2 hits). Entry Status remains Open.
2. STALE-VOCAB: the entry is written in pre-BD-209 vocabulary throughout — "PM-only"
   keyword, § "PM-only files and directories", `_PM_ONLY_PERMITTED_PATHS` (~:3788) —
   renamed by BD-209 (`b83c942`) to `pack-chat-only`, § "pack-chat-only files and
   directories", `_PACK_CHAT_ONLY_PERMITTED_PATHS` (now ~:4002).
3. STALE-FACT: "Out of scope: the per-entry `/backlog/`, `/changelog/` trees (not yet
   created)" — the trees exist (BD-203).
4. INPUT: likely disposition is a Resolved flip with a reconciling `Resolved:` line — via
   the Mode-3 tracker tooling; architect/user call.

### BD-202 — Universal `pack update` propagation engine
1. STALE-PLAN: REVERSAL TRIGGER watch-point "Watch the later v11.0 test phases (live-GH
   test trio / Batch 23)" — Batch 23 is superseded; the watch-point should name BD-205's
   test/audit cycle (where update-path failures would now surface).
2. VERIFIED-STILL-TRUE: `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` exists; HEAD `93a3337`
   is a historical measurement anchor (acceptable as provenance). The v11.1 target is an
   explicit user disposition (2026-06-04) and stands unless the trigger fires.
3. INPUT (forward note): BD-206's retirement of client mirrors changes the AC-2/AC-3 asset
   set the engine must classify (client per-entry tree files + retired monolith targets);
   the BD-200-pool co-design constraint already anchors the architect pass.

### BD-204 — Pack backlog → GH Issues (Mode 2 → 3)
1. STATE (closure pending, entry Open — correct but behind events): the flip RAN
   (213/213 issues created; closed=172, which reconciles exactly with tree states 167
   Resolved + 4 Deprecated + 1 Cancelled); the C-8 commit is NOT yet made (`tracker.toml`
   untracked; no dogfood-flip commit in `git log`; HEAD `1c18b28` = mirror-keys fix).
   Remaining at inventory time: the casing-cycle commit (working-tree churn in flight),
   the BD-094↔BD-095 data-cycle fix, a clean forward re-run, post-flip lossless verify,
   the C-8 commit gate, the ops-contract Commits 1-2, and the end-of-BD audit.
2. VERIFIED-STILL-TRUE (data defect pending): the real dependency cycle is STILL in the
   tree — `backlog/BD-094.md` Blockers lists BD-095 AND `backlog/BD-095.md` Blockers lists
   BD-094 (mutual). User-approved fix direction recorded in memory (remove BD-095 from
   BD-094's Blockers; first real Mode-3 tracker-edit dogfood).
3. NOTE-STATUS audit of the entry's dated notes: line-29 roundtrip-test comment NIT —
   DISCHARGED (recorded in entry, verified prose). Line-30 `pack-td.sh` advisory token —
   STILL LIVE (`scripts/pack-td.sh:259` carries `Resolution: n/a`). Line-31 live casing
   check — being discharged by the in-flight casing-cycle work (POQ-2 answered: live
   stateReason is UPPERCASE `NOT_PLANNED`; decoder fix in the uncommitted tree). Lines
   32-33 report-correction NITs — ride future commits as written.
4. INPUT: the Mode-3 ops contract (untracked architecture + plan docs) EXTENDS the
   closure scope beyond the entry's own Scope line: tree-rebuild verb, status-coherence
   comparator, doctor/validator repoints, freshness keys, and the user-gated OQ-A verbs
   (`pack tracker edit` / `new-entry`). The entry text predates the contract; the
   re-baseline should reconcile entry scope vs as-built closure scope.

### BD-205 — v11.0 final readiness audit
1. ENUMERATION DRIFT: Blockers "once every other launch-gate item (BD-195, BD-200, BD-203,
   BD-204, BD-197, BD-185) is Resolved" — omits BD-206/BD-207 (launch gates per their own
   entries: BD-207 user-confirmed "v11.0 is unshippable without it") and BD-212/BD-213
   (v11.0 targets opened 2026-06-11), plus BD-210 ("near/with BD-205"). The gate set needs
   re-enumeration after dispositions.
2. VERIFIED-STILL-TRUE: memory `project_batch23_test_coverage_gaps.md` exists (the
   coverage-gap pass precondition stands); the test-hygiene note (prefix-vulnerable
   `assert_contains "closed:     N"`) remains a valid audit item.
3. INPUT (fold interaction): the folded trio (BD-100, BD-102, BD-171, BD-174) each carry
   heavy staleness (above); whatever the architect merges into BD-205 must land WITH the
   corrections (v10.3 pin, archive-only disposal, Mode-3 premises, C-7-oracle prior art) —
   merging stale text verbatim would import the defects into the final gate.

### BD-206 — Project-side per-entry no-mirror application
1. ANCHORED REFRESH FIRES: the entry's own POST-BD-204 REFRESH anchor is now actionable
   (BD-204 as-built exists). User-approved scope additions to fold (memory § "BD-206/207
   POST-BD-204 REFRESH scope additions", items 1, 3, 4, 5, 6, 7, 8, 9): the OT-v10.3
   researcher-census prerequisite (exactly four monoliths: BACKLOG.md,
   IMPLEMENTATION_PLAN.md [underscore name at v10.3], CHANGELOG.md decompose subjects +
   STATUS.md census-only); generalized-only guard (OT = stress input, never spec, user
   re-emphasized twice); committed scrubbed snapshot fixtures viable + preferred; the
   BD-171 v10.3 re-pin + BD-174 archive-only housekeeping riding the same amendments;
   COMPLETE-SET confirmation; BD-105 orbit membership; and the project-side mode-contract
   elements (item 9) — which the ops contract formalizes as §5 R1 (mode-conditional client
   `_rules.md`), R3 (one-way-overwrite semantics), R4 (flat-file-ignores-issues), R6
   (STATUS.md dual-mode links), R7 (client changelog flat-file in both modes).
2. Target "TBD — likely v11.0" — effectively forced to v11.0: BD-207 is a confirmed v11.0
   launch gate and depends on BD-206 ("project per-entry trees must exist first").
   INPUT: needs explicit user confirmation, but TBD is stale-by-implication.
3. VERIFIED-STILL-TRUE (scope items intact): `scripts/lib/detect.sh` client-surface branch
   still reads the client monolith (`detect.sh:66-72`: `docs/project/BACKLOG.md` +
   `^\*\*TD-` grep) — the dual-use repoint remains pending exactly as scoped;
   `supporting-docs/MIGRATION-v10-to-v11.md` still carries monolith-as-mirror prose
   (lines ~247-311) — the doc-correction scope item remains accurate.
4. INPUT (encoding surfaces): when the client mirror retires, the retire/update set
   includes more than the entry's named Check-43 item — validate-pack Check 29 currently
   REQUIRES `[mirror]` on the client `tracker.toml.project-example` (pack omits, client
   requires — per the BD-204 amendment in the Check 29 docstring), plus
   `scripts/lib/tracker-mirror.sh` and the client legs of Checks 32/33. Enumerate at
   refresh per `enumerate-encoding-surfaces`.

### BD-207 — Project-side per-entry ↔ GH-Issues reversible tracker
1. ANCHORED REFRESH FIRES: the entry's "rewritten against the AS-BUILT BD-204 design"
   anchor is actionable. The decisions the entry lists as pending are now DECIDED
   as-built: overflow carrier = gz64 verbatim-body blob (raw-text-body-class; provider
   declares `provider_body_limit` + `provider_body_storage_format`; Jira-Cloud misfit
   documented); Mode-3 write model = one-way regenerated tree via tracker tooling;
   identity = pack-id marker; Pack-Feedback two-lane separation; surface-generalizable
   `(key, dir)` parameterization. The refresh consumes ops contract §5 R1-R8 VERBATIM
   (R2 hands the `tree-rebuild` verb shape to the client surface; R5 status-coherence with
   the CLIENT status vocabulary — Pending/In Progress/Done ARE states; R8 freshness keys,
   no mtime heuristics).
2. VERIFIED-STILL-TRUE (recorded scope items): `scripts/lib/tracker-sidecar.sh` +
   `scripts/lib/tracker-header-snapshot.sh` exist (dormant; BD-207 deletes);
   `TMF_SIZE_SAFETY_MARGIN` exists (`tracker-migrate-forward.sh:123-124`, default 2048 —
   the clamp tech-debt item is correctly anchored); the forward-test stderr artifact item
   remains anchored here.
3. INPUT (orbit + overlaps): BD-105 joins per R6 + the user ruling; BD-185's phase/part
   entities are the client streams this tracker must carry (and trigger the F9 glob
   defect, §6 item 1); BD-213 is sequenced with/after BD-207; memory item 2 makes the OT
   v10.3 content the Layer-2 scratch round-trip input.

### BD-210 — Pre-launch maintenance-docs cleanup
1. ENUMERATION DRIFT: Blockers "AFTER the remaining implementation BDs land (BD-204,
   BD-206, BD-207, BD-197, BD-185)" — omits BD-212/BD-213 (v11.0 targets opened after this
   entry) whose design/research docs will also exist; refresh the gate set after
   dispositions.
2. INPUT (new constraint from this pass): BD-189/BD-192's PRIMARY INPUTS are
   `maintenance-docs/v11-research/` docs needed at v11.1 start — BD-210's
   LIVE-vs-SUPERSEDED categorization must classify them LIVE (or the umbrellas'
   input lists break). The entry's enumerate-everything design already accommodates this;
   the constraint just needs to be visible at fire time.
3. VERIFIED-STILL-TRUE: `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` exists (the §11.3
   subsumption target). The BD-204 cycle has materially grown the deletion-candidate
   corpus (IMPL/REVIEW reports, ops-contract docs, this inventory) — volume note only.

### BD-212 — `pack tracker reset` verb (pack side)
1. DONE (pipeline stage): the researcher step ALREADY RAN and is COMMITTED —
   `maintenance-docs/v11-implementation/RESEARCH-BD-212-GH-ISSUE-DELETION.md`
   (`git ls-files` confirms; commit `84f6a83`), with live probes P1-P8 PASS. The Position
   line "the RESEARCHER step MAY run pre-C-8 as a C-8 de-risk (user decision pending at
   authoring time)" is stale — decision made, step done. Next stage is the architect.
2. INPUT (research findings to reconcile into the entry at refresh): deleteIssue is
   GA/personal/classic-scope OK; NO REST delete; BD-103's 100ms throttle NON-COMPLIANT
   (≥1s required — the entry's "≥ the provider's min-write interval" wording is
   compatible); no `issue.destroy` audit event → the verb writes its own deletion
   manifest; capability contract `issues.delete ∈ {hard, soft, none}` + preflight
   `repository.viewerCanAdminister`; issue numbers not reused; already-deleted classifier
   = `NOT_FOUND`.
3. NAMING-INPUT: File/Symbol names `scripts/lib/pack-tracker/reset.sh` — no
   `scripts/lib/pack-tracker/` directory exists; the as-built lib convention is flat
   `scripts/lib/tracker-*.sh` (the entry already defers final placement to the architect;
   the named default just doesn't match repo convention — same defect class as BD-105's
   doctor path).
4. VERIFIED-STILL-TRUE: the C-7 oracle pattern reference
   (`scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`) exists; the entry's
   archive-only + tracker-agnostic + generalizable language is already correct
   (authored post-BD-204 lessons).

### BD-213 — reset, project-side application
1. VERIFIED-STILL-TRUE: all referenced client surfaces exist —
   `project-template/docs/pack/PM-CHAT.md`, `.../OPTIONAL-FEATURES.md`,
   `.../HELP-FRAGMENT.md` + `HELP-FRAGMENT-TRACKER.md` (client copies),
   `supporting-docs/MIGRATION-v10-to-v11.md`, `pack-ops/HELP-FRAGMENT-TRACKER.md`
   (the S11-installed boundary item).
2. Lowest staleness of the tracker set (authored 2026-06-11 with the BD-204 lessons baked
   in: provider-terms prose, P-missed-7, Check-36 keywords post-BD-209).
3. INPUT: rides BD-212's architect output and BD-207's refreshed client-tracker shape;
   ordering only.

---

## 5. Overlap / dependency map

- **BD-105 ⊂ BD-206/BD-207 orbit** — user ruling (memory item 8) + ops contract R6 names
  BD-105; dual-mode link rendering is tested on real OT STATUS.md content.
- **BD-171 / BD-174 / BD-102 — shared live-GH harness trio**, all folded by BD-205's
  scope statement. BD-171 additionally shares OT-content inputs with the BD-206 census
  (memory item 1) and the BD-207 Layer-2 round-trip (item 2). BD-174 overlaps the as-built
  C-7 oracle. Disposition of any one constrains the others.
- **BD-100 ⊂ BD-205** (explicit fold of Batch-22 milestone-audit scope); the three BD-100
  carry-forwards must survive any merge.
- **BD-172 → BD-205 / BD-102 surface** — truthful Gate 2 is a precondition for the
  readiness audit relying on migration-gate verdicts.
- **BD-185 ⊃ phase entities BD-207 needs** — BD-185 defines the phase/part/task form
  family + ordering that BD-207's client tracker must carry; BD-185 consumes the
  per-entry substrate (BD-203) + the client reverse emit; BD-185 (or BD-207 phase
  creation) is the trigger that makes the F9 glob defect live (§6 item 1).
- **BD-206 → BD-207 → BD-213; BD-212 → BD-213** — strict chain; BD-212's capability
  contract (`issues.delete`) also feeds BD-207's provider abstraction and BD-188's
  Iteration capability pattern.
- **BD-186(Resolved) lineage → BD-187 / BD-188 / BD-189; BD-189 → BD-192** (PS follows
  groupings per user direction); **BD-189/BD-192 ↔ BD-210** (v11-research inputs must be
  LIVE-classified in the deletion pass).
- **BD-039 → BD-040** (autonomous mode references prototype gate definitions; both edit
  Procedure 1 and the same client write surfaces — sequence to avoid conflicts, per the
  entries themselves).
- **BD-109 ↔ BD-110** (project-side / pack-side auditor siblings); **BD-110 ↔ BD-100/
  BD-205** (CP-prompt language dead; cadence re-anchors to BD-205).
- **BD-202 ↔ BD-200(Resolved)** co-design constraint; reversal trigger now watches
  **BD-205**; BD-206's mirror retirement changes BD-202's asset-class set.
- **BD-093 terminal** — release pin runs after BD-205 + BD-210; consumes the `/changelog/`
  tree and the Mode-3 write channel for final status flips.
- **BD-197 ↔ the dying memory anchor** (git-stash enumeration; §4 BD-197 F1); BD-197 sits
  between BD-204 and BD-185 in the launch-gate order.
- **BD-204 → everything** — its as-built design + the ops contract (§5 R1-R8) is the
  baseline every IN-SCOPE entry above is measured against; the OQ-A verbs are a contingent
  anchor (§6 item 2).

## 6. New-BD candidates already identified (inventory items with evidence)

1. **Phase-task blocker-routing glob defect (BD-108 F9).** The step-7 link-arm case
   pattern `phase-[0-9][0-9]*.[0-9][0-9]*` (verified live at
   `scripts/lib/tracker-migrate-forward.sh:1713-1720`) matches only when BOTH N and M have
   ≥2 digits — `phase-3.2` and `phase-10.2` fall to the `phase-[0-9]*` PARENT arm
   (sub-issue path), not blocked-by. Latent on the pack at v11.0 (phase-tasks are never in
   the id-map per BD-108 §10.2; both arms silent-skip), REAL for client phase entities the
   day phase-task creation lands (BD-185 / BD-207). Evidence:
   `PACK-REVIEW-BD-204-CASING-CYCLE-REVIEW2.md` SHOULD-1 (lines 160-194, incl. the
   empirical glob demonstration and the regression provenance — the F9 "tightening"
   regressed the pre-F9 `phase-[0-9]*.[0-9]*` which DID match `phase-3.2`); the as-built
   `KNOWN GAP(functional): TD-TBD` comment now in the working tree at
   `tracker-migrate-forward.sh` (~lines 700-707, the SHOULD-1 comment-half fix). Status of
   the review's asked items: comment half FIXED (FIX2); NIT-2 stderr arm FIXED (FIX2); the
   GLOB FIX + a Group-6 assertion that actually distinguishes the arms remain un-anchored —
   the review explicitly asks Pack Chat to open a BD per `deferred-work-tracked-anchor`,
   and the in-code marker is a `TD-TBD` placeholder awaiting that anchor. Sequencing
   input: before-or-with BD-185/BD-207 phase-entity work.
2. **Contingent: `pack tracker edit` / `pack tracker new-entry` verb anchor (OQ-A).**
   `ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md` §0 flags the verb-surface gap
   (`tracker_edit_entry` exists as a sourced function; `pack-tracker.sh` exposes no `edit`
   verb and NO create path exists outside forward migration) and states: if the user
   defers the verbs out of the BD-204 commits, "a BD anchor is REQUIRED for the verbs."
   Contingent on the user's OQ-A decision; the in-flight Commit-2 work may absorb it.
3. **Anchor-preservation item (BD-197 git-stash enumeration)** — not necessarily a NEW BD:
   the user already assigned it to BD-197; the inventory finding (§4 BD-197 F1) is that
   its only current anchor is a memory file scheduled for deletion at BD-204 close. The
   re-baseline application should move it into the BD-197 entry body (or open an anchor)
   BEFORE the memory is deleted.

---

## 7. READ-IN-FULL attestation (per-file direct-read proof, this session)

| # | File | Proof (path + line count, read this session) |
|---|---|---|
| 1 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` | Read in full via Read tool, 579 lines (incl. the complete `## Pack memory` section, lines 140-579). |
| 2 | `/backlog/_toc.md` | Read in full, 234 lines (all six sections; section line-spans used for the §1 reconciliation). |
| 3 | All 41 non-resolved entry files listed by `_toc.md` Open/Unblocked/Deferred sections | Each read IN FULL via Read tool. Line counts: BD-020 21, BD-036 20, BD-037 19, BD-039 40, BD-040 53, BD-093 26, BD-100 15, BD-102 24, BD-105 14, BD-109 14, BD-110 17, BD-136 79, BD-171 42, BD-172 15, BD-174 36, BD-185 49, BD-187 23, BD-188 33, BD-189 41, BD-192 46, BD-198 18, BD-202 18, BD-204 33, BD-205 15, BD-206 14, BD-207 16, BD-210 13, BD-212 51, BD-213 32, BD-197 39, BD-031 16, BD-055 21, BD-056 19, BD-057 24, BD-058 25, BD-151 9, BD-152 9, BD-153 9, BD-154 9, BD-155 9, BD-201 12 (sum 1,038 — matches `wc -l` total). |
| 4 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md` | Read in full, 556 lines (incl. §5 R1-R8 project-side requirements + §0 OQ-A + §2 tree-rebuild design). |
| 5 | `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/project_bd204_cycle_position.md` | Read in full, 262 lines — covering BOTH named sections: § "BD-206/207 POST-BD-204 REFRESH scope additions" (items 1-9) and § "POST-BD-204 RE-BASELINE PASS" (plus § "Deferred to BD-197" and § "C-8 aftermath state", used as inputs). |
| 6 | `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_agent_output_rules_applied_block.md` | Read in full, 14 lines; its conditional MUST-READ honored — read § `rules-applied-verification-block` in `pack-ops/PACK-MEMORY-RATIONALE.md` (lines 206-233, format template applied in §8 below). |
| 7 | `/backlog/_rules.md` (consult-as-needed, read in full) | 94 lines — entry contract, BD-211 grammar, field-faithful carrier, lifecycle states, write authority. |
| 8 | Section/verification reads (as instructed, "grep don't assume") | `PACK-REVIEW-BD-204-CASING-CYCLE-REVIEW2.md` SHOULD-1 + NIT sections (lines 155-219, permitted-evidence exception); `IMPL-REPORT-BD-204-CASING-CYCLE-FIX2.md` (SHOULD-1/NIT-2 disposition greps); validate-pack.py check inventory (lines 25-135) + `_PACK_CHAT_ONLY_PERMITTED_PATHS` region + `check_help_fragment_completeness`; `scripts/lib/tracker-migrate-forward.sh` 694-706 + glob census; `scripts/lib/tracker-migrate-reverse.sh` emit-symbol grep; `scripts/lib/detect.sh` 66-72; `supporting-docs/METHODOLOGY.md` procedure headings; `supporting-docs/MIGRATION-v10-to-v11.md` mirror prose; `pack-ops/PACK-AGENTS.md` pack-chat-only list; `pack-ops/PACK-MEMORY-RATIONALE.md` 206-265; `tracker.toml`; existence checks for every path cited in §4 (two batched `ls`/`for` sweeps + targeted greps). |

No named document was derived rather than read; every file above was opened via Read/Bash
this session at HEAD `1c18b28` (+ the pending working-tree edits, per the concurrency note).

---

## 8. Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| **agents-never-commit** | Git verbs run this session: `git log --oneline` (×3 variants), `git status --short`, `git ls-files` — all read-only; zero `add/commit/push/tag/stash/reset/restore/checkout` invocations. Sole filesystem writes: the four chunked `cat >`/`cat >>` writes of THIS file (`maintenance-docs/v11-implementation/RESEARCH-REBASELINE-INVENTORY.md` — prompt-specified path, non-existent before this session); no repo file edited, no entry touched. | COMPLIANT |
| **no-live-mutations** | Zero `gh` invocations and zero GitHub MCP tool calls in this session's tool history; all evidence is local-file reads (`Read`, `ls`, `grep`, `sed`, `find`, `wc`, read-only git). The live-state claims in §4 BD-204 F1 (213/213 created, closed=172) are sourced from the named memory file + reconciled against LOCAL tree state, not a live call. | COMPLIANT |
| **preflight-stop-means-stop** | Emitted verbatim before the first write chunk: `PREFLIGHT: inventory complete; 41 entries inventoried (reconciled against _toc.md: 29 Open + 1 Unblocked + 11 Deferred = 41; cross-checked 4 ways); about to Write report to maintenance-docs/v11-implementation/RESEARCH-REBASELINE-INVENTORY.md`. No parent stop/halt/revert message received at any point; all commands ran FOREGROUND to completion (no background tasks armed). | COMPLIANT |
| **agent-output-rules-applied-block** | This table: 7 rows (one per "Rules in force" item), each with quoted measurement evidence; zero empty cells. Conditional MUST-READ honored before constructing the block: `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block` read (lines 206-233); its fenced `Rule | Verification evidence | Conclusion` format is the one applied here. | COMPLIANT |
| **agents-read-rule-docs-in-full** | §7 attestation: every prompt-named file read IN FULL with line counts (CLAUDE.md 579; `_toc.md` 234; 41 entry files summing 1,038 = `wc -l` total; ops contract 556; memory cycle-position 262 incl. both named sections; rules-applied memory 14; `_rules.md` 94), plus the instructed section-reads each verified directly (row 8). No named doc derived from summary. | COMPLIANT |
| **researcher-maps-blast-radius** | Exhaustive enumeration: 41/41 non-resolved entries inventoried (27 IN-SCOPE with per-entry findings, 14 OUT-OF-SCOPE one-liners — no sampling); counts reconciled FOUR independent ways (§1: `_toc.md` line-spans; per-file `Status:` grep 29/1/11; 213-file complement 213−167−4−1=41; external flip cross-check closed=172=167+4+1). Every cited path/symbol existence-verified (MISSING/EXISTS recorded per finding: e.g., `scripts/lib/pack-tracker/doctor.sh` MISSING, `scripts/tests/dog-food-checkpoint.sh` MISSING, `feedback_test_infra_self_provisioned.md` MISSING, `supporting-docs/PM-CHAT.md` MISSING; 40+ EXISTS confirmations). | COMPLIANT |
| **scope-deliverables-to-the-ask** | Deliverable contains exactly the asked sections: inventory table (§3, all 41), per-entry staleness findings for the IN-SCOPE set (§4), overlap map (§5), new-BD-candidate list with evidence (§6), count reconciliation (§1), plus attestation + this block. Disposition INPUTS are explicitly labeled `INPUT` and stop short of calls (e.g., BD-102 "candidates — merge ... or full rewrite ... architect's call"; BD-198 "likely disposition ... architect/user call"). Zero entry edits, zero `_toc.md` regeneration, zero tracker writes. | COMPLIANT |

---

**End of RESEARCH-REBASELINE-INVENTORY.md**
