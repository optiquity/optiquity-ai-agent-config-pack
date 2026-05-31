# ARCHITECTURE-BD-195-SEGMENTATION

**Author:** pack-architect (BD-195 SEGMENTATION pass — design the optimal work-segmentation for the FULL v11.0 sweep). **READ-ONLY design; PROPOSES segment/BD structure, assigns no numbers, answers no open decision.**
**Date:** 2026-05-31. **Branch:** v11-dev. **HEAD:** `add50dec0c6ff48890c2069d268480e46f9f5f6a` (`add50de`).

**This doc SUPERSEDES `ARCHITECTURE-BD-195-RESCOPE.md`.** The RESCOPE doc designed the work-split around the **BD-185-restart gate** (Slice 1 = "what gates BD-185" vs Slice 2 = "everything else"). The user has **REJECTED that axis**: it does not serve the launch goal and it scatters work that is actually similar. This doc re-designs the segmentation around **launch value + work-similarity + dependency-correctness**, with provably complete coverage of all live problems (49 — corrected from the prompt's/REFRESH's 48; see §2.3 mis-count finding) + all 12 open decisions. Where RESCOPE reached correct sub-findings (the BLOCKER blocking-target verdict; the P-13 → P-02 precondition; the P-09 provenance-half tree-resolution), this doc reuses them and says so inline.

**Goal restated (the user's hard requirement):** launch v11.0 with the FULL BD-195 sweep completed — **no coverage gaps**. The default is **all-in-v11.0**; deferral is not designed (a deferral-candidate flag is provided for the user to decide, §4.3).

**Inputs read (all measured at `add50de`):** `AUDIT-BD-195-REFRESH-POST-BD196.md` (48 live + surface tags + 8 OQ verdicts + 4 NQ), `AUDIT-BD-195-RECONCILED-PROBLEM-LIST.md` (P-NN detail + cross-surface couplings + OQ defs), `ARCHITECTURE-BD-195-RESCOPE.md` (the REJECTED gate-axis design, superseded here), `pack-ops/BACKLOG.md` BD-195 + BD-185 entries, the held `ARCHITECTURE-BD-185-V2.md` / `PLAN-BD-185-V2.md` (read for FEATURE touch-surfaces only; their v11.1 framing treated as contaminated per the PRISON RULE — extracted the feature's likely surfaces, not the contaminated specifics).

**HEAD carry-over.** RESCOPE EB-0 established that the only commit between the audit HEAD `c73077d` and `add50de` is the audit/BACKLOG-state commit itself (doc-only, pack-only). The load-bearing live claims (P-01, P-02, P-12, P-13) are independently re-measured at `add50de` in §7 (EB-1…EB-3) and all confirm STILL-LIVE.

---

## 1. Clusters (segments) + justification + challenge of the candidate cuts

### 1.1 What the segmentation must optimize (the axis the user chose)

The user rejected the BD-185-gate axis and named three drivers: **launch value**, **work-similarity** ("similar work at the same time" — one fixer works one shape; one reviewer checks one shape), and **dependency-correctness** (a segment can only run after the things it depends on land). The right cut is the one that lets a fixer and a reviewer operate on **one coherent shape of work per segment**, with the segments ordered so no segment is blocked on a later one.

A segment is therefore defined by **work-shape similarity** — the kind of edit + the kind of verification + the rule corpus in force — NOT by surface-ownership (which tree the file lives in) and NOT by gating-role (what it blocks). Surface-ownership was the REFRESH §3 lens; gating-role was the RESCOPE lens. Both are rejected here as the *primary* cut (they remain useful secondary annotations, carried in §2 and §5).

### 1.2 Pack Chat's candidate clusters (PRELIMINARY) — adopt / merge / replace

Pack Chat suggested four candidate themes: **(a) v11.1-mis-versioning contamination**; **(b) prison/dead-ref**; **(c) v9/v10-staleness**; **(d) client-shipped vs internal**. Per the preliminary-triage + architect-challenge rule these are PRELIMINARY. Verdict on each:

- **(a) v11.1-mis-versioning — ADOPT as a segment, and SHARPEN.** The reconciled list's own headline is "**one underlying mis-versioning spread across surfaces**" (RECONCILED §"The headline"). That is the single strongest work-similarity cluster in the corpus: P-01 (validator + test comments), P-02 (the fictional `v11.1/` cut), P-08 (the review/Phase-5 that blessed it), P-09/P-17/P-18 (the contaminated BD-185 attempt records), P-12 (the validator's missing 6th type once the cut is corrected), P-13 (the bare-path precondition for executing the P-02 recipe), P-16 (the V2 forward-pointer gap), P-31a/P-31b/P-31k (the "frozen"/D16 cosmetic residue on the same archive). **The RESCOPE doc SCATTERED this:** it left P-01/P-02/P-08/P-09/P-12/P-13/P-16/P-17/P-18/P-31a/b/k in "Slice 1" but only because they were BD-185-artifact-tagged — it never recognized them as ONE de-contamination work-shape, and it would have had a fixer touching the validator for P-01, then again for P-12, in two different gating-role buckets. This segment keeps the whole contamination theme together, exactly as the user demanded.

- **(b) prison/dead-ref — ADOPT, but SPLIT by edit-shape.** "Dead reference" spans two genuinely different work-shapes: **(i) stale-ref-to-a-prisoned-or-moved-doc** (P-14, P-15, P-21, P-25 — fix = re-point or annotate "superseded; now in prison/") and **(ii) client-shipped-pack-only-doc-leak** (P-04, P-05, P-06, P-31f — fix = remove/repoint a pack-only path that resolves to nothing AT A CLIENT INSTALL, governed by `feedback_pack_project_separation_of_concerns` + client token economy). These look alike ("a reference that doesn't resolve") but the **rule corpus, the audience, and the verification are different**: (i) is pack-internal hygiene verified by `grep` against the tree; (ii) is a client-install boundary defect verified against `init-project.sh _CLIENT_INSTALLED_FILES` + the fixture. Merging them would force a fixer to switch rule-frames mid-segment. **MERGE (i) with the broader prison/version-staleness internal-hygiene work** (they share the "pack-internal doc currency" shape); keep (ii) as its own **client-surface integrity** segment.

- **(c) v9/v10-staleness — MERGE, do not stand alone.** Version-currency staleness has two homes by audience: **client-shipped** v-stamps (P-19 v9, P-20 v10, P-29g, P-31c, P-31d, P-31e — these ride the client-surface segment because the fixer is already in `project-template/` with the client rule-frame loaded) and **pack-internal** v-stamps (P-29d, P-29e, P-29f, P-29h, P-24, P-31h, P-31j — these ride the pack-internal-hygiene segment). A standalone "v-staleness" segment would force the fixer to cross the client/pack boundary repeatedly, which is exactly the boundary the trinity + separation rules say to keep loaded consistently. So v-staleness is a *property* that gets resolved inside the audience-correct segment, not its own segment.

- **(d) client-shipped vs internal — ADOPT as the PRIMARY split for the non-contamination work.** This is the strongest work-similarity axis after the contamination cluster, because it maps 1:1 onto the rule corpus a fixer/reviewer must hold: client-shipped work loads `feedback_pack_project_separation_of_concerns` + client token economy + the trinity client-audience rules + manifest-regen + fixture checks; pack-internal work loads pack-self governance + prison hygiene + pack-doc currency. A reviewer checking "one shape" is checking *one of these two rule corpora*, not both.

**Net:** Pack Chat's four candidates collapse into **three work-shapes** — (1) the mis-versioning contamination cluster; (2) the client-surface integrity + currency cluster; (3) the pack-internal hygiene + parity + currency cluster — plus a small **pack-self governance/parity** sub-shape that is distinct enough in rule-frame (it touches PM-only governance docs and the pack-agent trinity) to warrant its own segment so a single PM-only / trinity reviewer can check it in one pass.

### 1.3 The cut this design adopts — FOUR segments

| Seg | Name | Work-shape (what the fixer/reviewer holds) | Verification frame |
|---|---|---|---|
| **S1** | **Mis-versioning de-contamination** | Strip the "phase-parts = v11.1 / v11.0 frozen" mislabel everywhere it is encoded: shipped code comments (validator + test), the fictional `templates-archive/v11.1/` cut + its SCHEMA relocation, the reviews/reports that blessed it, the precondition path-normalization, and the cosmetic "frozen"/D16 residue. ONE categorical fact in force ("phase-parts was always v11.0"). | `grep "v11.1"` clean on the in-scope surfaces; `check_template_archive_v11()` 6-type; `test-issue-forms.sh` + Check 43 green; manifest regen (scripts touched). |
| **S2** | **Client-surface integrity + currency** | Everything a client install actually receives (`project-template/` trees + the scripts/libs that resolve client paths): dead pack-only refs, leaked maintenance-doc/SHA provenance, v9/v10 version stamps, contradictory RAG manifests, trinity client-audience asymmetries, client-path resolution logic. ONE rule-frame in force (pack/project separation + client token economy + client-audience trinity). | Each ref resolves at a client install (cross-check `init-project.sh _CLIENT_INSTALLED_FILES` + `test-fixtures/`); trinity parity; manifest regen + fixture/per-check tests where scripts touched. |
| **S3** | **Pack-internal hygiene + currency** | Pack-maintenance + pack-product surfaces NOT shipped to clients: prison stale-refs in live docs/scripts, README layout currency, pack-doc deprecation banners + dates, sunset-migrator scrub, companion-template defects, pack-side bare-doc-shorthand → concrete-command. ONE rule-frame (pack-internal doc currency + prison hygiene + filename/path resolution). | `grep` clean for prisoned-path refs; README layout matches `BOUNDARY-DEFINITION.md §5` (content rules; §5.1 collapsed into flat §5 by BD-196); companion install blocks consistent; pack-side renders advertise only live verbs. |
| **S4** | **Pack-self governance + agent/skill parity** | PM-only governance docs + the pack-agent/skill trinity: the agent-count contradiction, the Task/Agent-tool terminology drift, pack-help skill stale refs, pack-planner Claude-only rule, commit-discipline `agent-run.sh` example, HELP-FRAGMENT-TRACKER deliverable-only adjudication. ONE rule-frame (pack-self governance accuracy + trinity parity + deliverable-only test). | PM-only edits (PACK-CHAT/PACK-AGENTS); `.{claude,codex,gemini}` agent/skill parity (trinity-style); deliverable-only adjudication recorded. |

**Why four, not two (vs RESCOPE) and not three.** Four is the smallest set in which **each segment has exactly one rule-corpus a reviewer must hold**. S2 and S3 cannot merge — they are the client/pack boundary itself, the single most-enforced boundary in this repo (P-missed-7, the separation-of-concerns memory). S4 is split out from S3 because PM-only governance + agent-trinity parity is a *different reviewer pass* (PM-only direct-edit + trinity-quad check) than pack-doc hygiene (`grep`/layout check) — folding them would make one reviewer hold two frames. S1 stands alone because the mis-versioning contamination is one categorical fact that must be expunged in lock-step across code + archive + records, and a single fixer holding that fact is faster and less error-prone than scattering it (the demonstrated RESCOPE failure mode). This honors the design-elegance bar: fewer segments than problems, one convention (work-shape = rule-frame) with no special cases.

### 1.4 What this cut does that the RESCOPE cut did not

- **Keeps the contamination theme together (S1).** RESCOPE's gating-role cut happened to co-locate the 12 BD-185-artifact problems, but it justified that by "what gates BD-185," not "this is one de-contamination job." The distinction matters for the BD-185 interleave (§5): once you see S1 AS the de-contamination job, you see that the held BD-185-V2 design's own §10 Groups A–G **are the S1 fix recipes** — i.e., S1 and the BD-185 feature-restart's first commits are the SAME edits. RESCOPE missed this entirely (it deferred the interleave question, §5).
- **Splits the non-contamination work by the client/pack boundary** (S2 vs S3/S4) rather than by "does it gate BD-185" (which lumped 36 heterogeneous problems into one undifferentiated Slice 2 with mixed rule-frames). A reviewer of RESCOPE's Slice 2 would have to switch between client-separation rules and pack-self governance rules within one pass; here S2/S3/S4 each carry one frame.

---

## 2. Complete-coverage proof (49 live problems + 12 open decisions → segments)

Every live leaf-problem and every open decision is assigned to exactly one segment. P-29a is STRUCK (CLOSED-BY-BD-196, REFRESH §2 / NQ-2) with a note; it is in no segment. Severity from the reconciled list.

### 2.1 Problem → segment (all 49 live)

| P-NN | Sev | Segment | One-line work-shape rationale |
|---|---|---|---|
| P-01 | BLOCKER | **S1** | v11.1 mislabel in `validate-pack.py` + `test-issue-forms.sh` comments — core contamination, shipped code. |
| P-02 | BLOCKER | **S1** | Fictional `templates-archive/v11.1/` cut + SCHEMA relocation — core contamination, archive. |
| P-08 | MUST | **S1** | BD-193 review/Phase-5 blessed + deepened the mislabel — correction-target, rides P-02. |
| P-09 | MUST | **S1** | `PACK-REVIEW-BD-185-H.2.md` v11.1 framing + prisoned anchor — contamination record (OQ-3 disposition). |
| P-12 | SHOULD | **S1** | `check_template_archive_v11()` 6th `phase-part` type once P-02 relocates SCHEMA — ENCODING lock-step partner of P-02. |
| P-13 | SHOULD | **S1** | Bare `templates-archive/...` recipe paths — precondition mechanic; normalize BEFORE the P-02 recipe runs (OQ-8). |
| P-16 | SHOULD | **S1** | `ARCHITECTURE-BD-185-V2.md` missing forward ordering-addendum pointer — contamination-era design-doc currency. |
| P-17 | SHOULD | **S1** | 6 BD-185 IMPL reports carry the mislabel + prisoned refs — contamination records (OQ-1 disposition). |
| P-18 | SHOULD | **S1** | `PACK-REVIEW-BD-185-H.1.md` blesses the mislabel + prisoned anchors — contamination record. |
| P-31a | NIT | **S1** | `v11.0/INDEX.md` "Frozen forms" + bare D16 framing on the corrected archive — cosmetic residue, rides P-02. |
| P-31b | NIT | **S1** | `AUDIT-INVENTORY-BD-TD-PATH.md` D16 "frozen" wrapper snapshot — contamination-era record. |
| P-31k | NIT | **S1** | `ARCHITECTURE-V3.3-DELTA.md` D-22/D-4-V2 overtaken-by-BD-193 note — contamination-era design-doc currency. |
| P-04 | MUST | **S2** | `PM-CHAT.md` cites uninstalled `docs/pack/MERGE-STRATEGY.md` — client dead-ref + separation. |
| P-05 | MUST | **S2** | `.mcp.json.example` cites uninstalled `supporting-docs/CLI-PM-SETUP.md` — client dead-ref + separation. |
| P-06 | MUST | **S2** | `.codex/config.toml.example` leaks pack maintenance doc + SHA — client separation. |
| P-19 | SHOULD | **S2** | `PACK-FEEDBACK.md` stamped v9 throughout — client version-currency (OQ-4 seed-set). |
| P-20 | SHOULD | **S2** | Three client surfaces v10-stale / misdirected migrator — client version-currency. |
| P-29g | NIT | **S2** | `PLATFORM-SKILLS.md` cites pack-repo `## Pack memory` on client surface — client separation. |
| P-31c | NIT | **S2** | `AGENTS.md` lacks `$XCODE_APP` relocation mechanism — client trinity parity. |
| P-31d | SHOULD | **S2** | `.gemini/settings.json` local-rag manifest contradicts authoritative manifest — client ENCODING lock-step. |
| P-31e | NIT | **S2** | `.codex/config.toml.example` "v10 ships STDIO only" stale — client version-currency; bundles with P-06. |
| P-31f | SHOULD | **S2** | `bootstrap.sh` cites uninstalled `supporting-docs/SETUP-NEW.md` — client dead-ref. |
| P-22 | SHOULD | **S2** | `tracker-migrate-forward.sh` client BACKLOG/PLAN path resolution asymmetry — client-path logic in a shipped lib. |
| P-23 | SHOULD | **S2** | `tracker-migrate-forward.sh` dead `maintenance-docs/IMPLEMENTATION-PLAN.md` fallback — client-path logic dead-ref. |
| P-30b | SHOULD | **S2** | `test-tracker-phase-task.sh` BD-NNN grammar admission — client-authoring-vs-fidelity boundary (OQ-2). |
| P-03 | MUST | **S3** | README `maintenance-docs/` layout stale after prison move — pack-layout currency (PM-only). |
| P-10 | MUST | **S3** | README `pack-ops/`-vs-`supporting-docs/` mis-filing — pack-layout currency (PM-only). |
| P-28 | MUST | **S3** | Xcode Codex companion declares 7 unshipped agents — companion-template defect (OQ-6). |
| P-14 | SHOULD | **S3** | 19c-family artifacts forward-ref prisoned docs — pack prison stale-ref (OQ-1 subset). |
| P-15 | SHOULD | **S3** | V3.x chain cites prisoned V3.2-DELTA as authoritative — pack prison stale-ref (OQ-1 subset). |
| P-24 | SHOULD | **S3** | Pack surfaces advertise sunset v9→v10 migrator as live verbs — pack user-facing currency (OQ-7). |
| P-29b | SHOULD | **S3** | `CONCEPTUAL-REVIEW-METHODOLOGY` dangling `ARCHITECTURE-V1.md` + bare shorthand — pack dead-ref. |
| P-29c | SHOULD | **S3** | `CONCEPTUAL-AREA-CUSTOMIZATION-PRESERVATION` wrong methodology-dir cite — pack dead-ref (NQ-4 sharpening). |
| P-29d | SHOULD | **S3** | `EXECUTION-PLAN-V11.0` stale status line — pack-maintenance currency. |
| P-29e | SHOULD | **S3** | `RECOMMENDATIONS.md` v9-era no banner, README presents current — pack-doc currency. |
| P-29f | SHOULD | **S3** | `project-template/README.md` v10-stale; ship-vs-relabel — pack-maintenance doc (OQ-5; not client-installed today). |
| P-29h | NIT | **S3** | `VERIFIED-NOTES` undated + Xcode README "v9 policy" — pack-doc currency. |
| P-21 | NIT | **S3** | lib headers cite prisoned V3.2-DELTA — pack prison stale-ref in scripts (OQ-1 subset). |
| P-25 | NIT | **S3** | `TOOL-COMPARISON.md` cites prisoned analyses at pre-prison path — pack prison stale-ref. |
| P-31g | — | **S3** | README presents `RECOMMENDATIONS`/`VERIFIED-NOTES` as current — pack-layout currency; compounds P-29e/h. |
| P-31h | NIT | **S3** | Xcode Codex `config.toml` model `gpt-5` lags `gpt-5.4` — companion parity drift. |
| P-31j | NIT | **S3** | `tracker.toml.pack-example` path-less `ARCHITECTURE.md` ref — pack usability bare-shorthand. |
| P-31l | NIT | **S3** | `INTAKE-GROUPINGS-V11` unverified-fidelity self-flag (legit v11.1+) — pack-doc optional review. |
| P-11 | MUST | **S4** | `PACK-CHAT.md` "Four pack agents" (should be five) — pack-self governance accuracy (PM-only). |
| P-07 | MUST | **S4** | pack-help skill stale bare refs (Claude+Codex) vs correct Gemini — pack-agent/skill trinity parity. |
| P-26 | SHOULD | **S4** | pack-planner state-verifiable rule Claude-only — pack-agent trinity parity. |
| P-27 | NIT | **S4** | commit-discipline cites pack-side `agent-run.sh` — pack-skill precision (trinity-byte-identical). |
| P-30a | NIT | **S4** | HELP-FRAGMENT-TRACKER TD/phase verbs on pack render — deliverable-only adjudication. |
| P-31i | NIT | **S4** | "Task tool" vs "Agent tool" drift across PACK-AGENTS/PACK-CHAT vs trinity — pack-self terminology (PM-only + trinity). |

**P-29a — STRUCK (in no segment).** CLOSED-BY-BD-196 (C4/C6/C8: `BOUNDARY-DEFINITION.md §6` is now a CI-asserted manifest at `pack-ops/.boundary-pointer-manifest.txt`; REFRESH §2 EB-B). NQ-2 (§2.2) is the bookkeeping that strikes it so no segment re-implements a CI-enforced §6.

### 2.2 Open decision → segment (all 12)

12 items = 6 fully-open OQ (OQ-1, OQ-2, OQ-4, OQ-5, OQ-6, OQ-7) + OQ-3 (partial) + OQ-8 (precondition) + 4 NQ (NQ-1…NQ-4). Assigned + sequenced; **not answered** (the user resolves per-segment). Boundary-class items flagged for `boundary-investigation`.

| Decision | Topic | Segment | Boundary-class? | Why this segment |
|---|---|---|---|---|
| **OQ-8** | Normalize bare archive paths before P-02 | **S1** | No (sequencing precondition) | Hard mechanic inside S1: P-13 must land before the P-02 recipe executes (RESCOPE §4.3, re-confirmed §3). Not a user decision. |
| **OQ-3** | Disposition of `PACK-REVIEW-BD-185-H.2.md` (track/prison/leave) | **S1** | No (disposition) | Provenance half tree-resolved (P-09 single add at `3bef42b`, EB-3); only track-vs-prison-vs-leave remains — a contamination-record disposition inside S1. |
| **OQ-1** | Prison stale-ref: per-doc edits vs Pattern-B ship-sweep | **S1 + S3** | No (policy) | One policy, two segments: the BD-185-record subset (P-09/P-17/P-18) resolves in S1; the non-contamination subset (P-14/P-15/P-21/P-25) in S3. Resolve the policy ONCE; apply per-segment. |
| **OQ-2** | `BD-NNN` admission in tracker phase-task grammar: leak or fidelity? | **S2** | **YES** | Client-authoring-surface-vs-migration-fidelity is a pack/project boundary call. Flag for `boundary-investigation`; rides P-30b in S2. |
| **OQ-4** | v9-auditor seed-set currency in client `PACK-FEEDBACK.md` | **S2** | Mild (project content) | Project-side content decision; rides P-19 in S2. |
| **OQ-5** | `project-template/README.md`: ship to clients or relabel pack-maintainer-only? | **S3** | **YES** | Ship-vs-relabel is a deliverable-boundary call (is this README a client deliverable?). Flag for `boundary-investigation`; rides P-29f. NOTE: assignment depends on the answer — if "ship," P-29f's FIX migrates to S2 (§3.4 contingency). |
| **OQ-6** | Xcode Codex companion: support sub-agents or strip the blocks? | **S3** | Mild (product capability) | Companion-template capability decision; rides P-28 in S3. |
| **OQ-7** | v9→v10 sunset-artifact scrub policy on live user-facing surfaces | **S3** | No (policy) | Scrub-vs-retain policy for pack user-facing surfaces; rides P-24 in S3. |
| **NQ-1** | Re-anchor reconciled-list rule citations to post-BD-196 slugs/RATIONALE | **ALL (S0 pre-pass)** | No (mechanic) | The reconciled list cites pack-memory rules by PRE-BD-196 prose/location (BD-196 C1/C2 reshaped them + split bodies to `PACK-MEMORY-RATIONALE.md`). EVERY segment's fix-design quotes these rules. Pay the re-anchoring tax ONCE, up front, ahead of all four segments (the "S0" pre-pass, §3.1). |
| **NQ-2** | Strike P-29a from the active work-surface (closed by BD-196) | **(none — entry-authoring)** | No (bookkeeping) | Pack Chat strikes P-29a at entry-authoring so no segment re-implements a CI-enforced §6. |
| **NQ-3** | Are BD-196's new surfaces in-scope for BD-195's defect classes? | **S3** | No (scope) | BD-196 introduced 5 new pack-internal surfaces + Checks 44/45/46, unaudited by R1–R9. "Does pristine require sweeping them" is a pack-internal-hygiene scope question — S3. |
| **NQ-4** | `CONCEPTUAL-AREA-CUSTOMIZATION-PRESERVATION.md` location-vs-subject (sharpens P-29c) | **S3** | **YES** | File at `v11-implementation/` governs a project-side review methodology + cites wrong dir. `boundary-investigation` (is the SSOT pack-side or project-side?). Rides P-29c in S3. |

### 2.3 Coverage sums + a CORRECTED LIVE-PROBLEM COUNT (mis-count finding)

**Finding: the live-problem count is 49, not 48.** The prompt's stated count (and the REFRESH §6 headline, and RESCOPE §3) says **48 live**. Re-measured at `add50de`, the correct figure is **49 live leaf-problems** (50 leaf rows in REFRESH §2 − 1 closed P-29a). The "48" is an undercount that **silently drops P-29h** from the slice partition.

- **Evidence (EB-5, §7):** REFRESH §2 carries 50 distinct leaf-rows (P-01…P-28 = 28; P-29a…P-29h = 8; P-30a/b = 2; P-31a…P-31l = 12). P-29a is CLOSED → 49 live. But REFRESH §3's five slices (`12 + 2 + 11 + 8 + 15 = 48`) enumerate only 48 of those 49 leaves: `comm -23` of {49 live leaves} vs {48 slice-members} returns exactly **P-29h** — present as a STILL-LIVE classification row in REFRESH §2, absent from every REFRESH §3 slice. RESCOPE inherited the 48 total: its §2 per-problem table DOES assign P-29h (to Slice 2), so its enumeration is complete, but its §3 count "Slice 2 = 36 / Total = 48" is wrong — Slice 2 is **37** and the total is **49**.
- **Why it matters for coverage:** the user's hard requirement is zero dropped problems. P-29h (`VERIFIED-NOTES.md` undated CLI facts + `xcode-companion-templates/README.md` "v9 policy" — REFRESH §2, RECONCILED P-29h) is a real live pack-internal-currency defect. This segmentation assigns it to **S3** and counts it. The corrected denominator is **49**, used everywhere below.

**Per-segment exact counts (corrected denominator 49):**

| Segment | Count | Member P-NNs |
|---|---|---|
| **S1 — Mis-versioning de-contamination** | **12** | P-01, P-02, P-08, P-09, P-12, P-13, P-16, P-17, P-18, P-31a, P-31b, P-31k |
| **S2 — Client-surface integrity + currency** | **13** | P-04, P-05, P-06, P-19, P-20, P-22, P-23, P-29g, P-30b, P-31c, P-31d, P-31e, P-31f |
| **S3 — Pack-internal hygiene + currency** | **18** | P-03, P-10, P-14, P-15, P-21, P-24, P-25, P-28, P-29b, P-29c, P-29d, P-29e, P-29f, P-29h, P-31g, P-31h, P-31j, P-31l |
| **S4 — Pack-self governance + agent/skill parity** | **6** | P-07, P-11, P-26, P-27, P-30a, P-31i |
| **Total live** | **49** | (12 + 13 + 18 + 6) |
| Closed (no segment) | 1 | P-29a (CLOSED-BY-BD-196; struck per NQ-2) |

**No-double-count check (EB-5):** the four member-lists are pairwise disjoint and their union is exactly the 49 live leaves — `comm` of the union against the 49-leaf set returns empty both directions (§7 EB-5). Every live problem is in exactly one segment; zero gaps, zero doubles.

**Open-decision coverage (12 of 12):**

| Item | Segment(s) |
|---|---|
| OQ-1 | S1 + S3 (one policy, applied per-segment) |
| OQ-2 | S2 (boundary-class) |
| OQ-3 | S1 |
| OQ-4 | S2 |
| OQ-5 | S3 (boundary-class; contingent re-home, §3.4) |
| OQ-6 | S3 |
| OQ-7 | S3 |
| OQ-8 | S1 (sequencing precondition) |
| NQ-1 | S0 pre-pass (ahead of all four) |
| NQ-2 | entry-authoring (Pack Chat bookkeeping) |
| NQ-3 | S3 |
| NQ-4 | S3 (boundary-class) |

All 12 accounted for; none answered (assignment + sequencing only). **Boundary-class flagged for `boundary-investigation`:** OQ-2, OQ-5, NQ-4 (mild: OQ-4, OQ-6).

---

## 3. Dependency graph + segment ordering

### 3.1 S0 — the NQ-1 re-anchoring pre-pass (runs FIRST, before any segment's fix-design)

NQ-1 is not segment work; it is a **one-time correction to the shared substrate** every segment reads. The reconciled list cites pack-memory rules as fix-coupling drivers (e.g. P-01/P-12 cite "Enumerate ENCODING surfaces"; P-05/P-06/P-31f cite `feedback_pack_project_separation_of_concerns`; P-31d cites `feedback_manifest_regen_on_v11_surface`) **by their PRE-BD-196 prose/location**. BD-196 C1/C2 reshaped pack memory into two-clause imperatives + `[rationale: slug]` tags and split bodies to `pack-ops/PACK-MEMORY-RATIONALE.md`. Any fix-design that quotes OLD rule text will fail to resolve it in trinity. **S0 re-anchors the reconciled-list citations to the post-BD-196 slugs + RATIONALE locations ONCE, ahead of all four segments' fix-design.** Paying it per-segment would re-pay it four times. (This reuses RESCOPE §5's NQ-1 sequencing verdict — correct, retained.)

### 3.2 Intra-segment dependencies (from RECONCILED cross-surface couplings)

**S1 (the only segment with hard internal ordering):**
- **P-13 → P-02** (OQ-8): the `ARCHITECTURE-BD-185-V2.md §10` / `PLAN-BD-185-V2.md §6` recipes that drive the P-02 fix cite bare `templates-archive/...` paths (32 occurrences live at `add50de`, EB-3). P-13 normalizes them; it MUST land before a coder executes the P-02 recipe, or the recipe steps fail against a non-existent repo-root path. (RESCOPE §4.3 — correct, retained.)
- **P-02 ↔ P-12** (ENCODING lock-step): once P-02 relocates the SCHEMA to `v11.0/phase-part-v11.0/SCHEMA.md`, `check_template_archive_v11()` must add `phase-part` as the 6th type (P-12) in the SAME commit (V2 §10 Group E = exactly P-12's fix). Touches `scripts/` → manifest regen + per-check tests.
- **P-02 ↔ P-08** (lock-step): P-02 retires `v11.1/INDEX.md`; P-08's "CONFIRMED-CORRECT"/Phase-5 blessing language is a correction-target reversed in lock-step.
- **P-02 → P-31a** (rides): the `v11.0/INDEX.md` "Frozen forms"/D16 cosmetic reword rides the P-02 archive cleanup (V2 §10 Group G).
- **P-01 is independent** within S1 (validator + test comments; no precondition) — first fix per "BLOCKERs first."
- **P-09/P-16/P-17/P-18/P-31b/P-31k** are disposition/currency records — they resolve AFTER the epicenter fixes (P-01/P-02), gated on OQ-1(S1 subset)/OQ-3.

**S2:** P-22 ↔ P-23 share `tracker-migrate-forward.sh` (same function — edit together); P-06 ↔ P-31e share `.codex/config.toml.example` (bundle in one edit); P-31d touches three ENCODING surfaces (`.gemini/settings.json` + `.mcp.json.example` + pm-startup) that align in lock-step. No cross-problem hard ordering — all parallelizable within S2.

**S3:** P-29e ↔ P-31g and P-29h ↔ P-31g compound (README descriptions follow the underlying doc banners — fix the doc, then the README line). P-03 ↔ P-10 ↔ P-31g all touch the README layout (PM-only; one editor). No hard ordering otherwise.

**S4:** P-11 ↔ P-31i both touch PACK-CHAT.md (PM-only; one editor, one commit). P-07/P-26/P-27 are independent trinity-parity fixes.

### 3.3 Inter-segment dependencies + the segment ordering

There is **no fix-content dependency between S1, S2, S3, S4** — they touch disjoint surfaces (the §2.3 disjointness proof is also a no-cross-surface proof: S1 = scripts-comments + archive + contamination records; S2 = `project-template/` + client-path libs; S3 = pack docs + companion + prison-ref scripts; S4 = PM-only governance + pack-agent trinity). The only shared upstream is **S0 (NQ-1)**, which all four consume.

**Therefore the segments are parallelizable after S0.** The ordering driver is **launch value + the BD-185 interleave (§5)**, not fix-dependency:

```
        ┌────────────────────────────────────────────┐
S0 ──▶  │  (NQ-1 re-anchoring; entry-authoring NQ-2)   │
        └───┬───────┬───────────┬───────────┬─────────┘
            │       │           │           │
            ▼       ▼           ▼           ▼
           S1      S2          S3          S4
       (de-contam) (client)  (pack-int)  (pack-self)
            │
            │  P-13 → P-02 → {P-12,P-08,P-31a} lock-step
            │  → {P-09,P-16,P-17,P-18,P-31b,P-31k} (gated OQ-1/OQ-3)
            ▼
   [BD-185 interleave decision — §5]
```

**Recommended ordering (launch-value priority, no hard inter-segment edge):**
1. **S0** (re-anchoring) — unavoidably first.
2. **S1 first among the four.** Not because it gates S2/S3/S4 (it does not), but because (a) it holds both BLOCKERs, (b) it is the contamination the launch exists to expunge, and (c) it is the segment that interleaves with the BD-185 feature restart (§5) — settling it first lets the BD-185 decision proceed. Within S1: **P-13 → P-01 → P-02(+P-12,P-08,P-31a lock-step) → P-09/P-16/P-17/P-18 (gated OQ-1/OQ-3) → P-31b/P-31k.**
3. **S2, S3, S4 in any order or in parallel** after S0. Suggested priority by launch-value: **S2 next** (client-shipped defects are what a v11.0 client actually sees — highest external-visibility), then **S3** (pack-internal + product, includes the 3 README MUSTs + companion-template MUST), then **S4** (pack-self governance; lowest external visibility, all PM-only/trinity). This is a *priority* recommendation, not a dependency — the user may run them concurrently.

### 3.4 Contingencies + contention (no cycles)

- **No cycle exists.** The only hard edge is intra-S1 (P-13 → P-02); all inter-segment edges are absent. The graph is a DAG (S0 → {S1,S2,S3,S4}, with a linear chain inside S1).
- **OQ-5 contingency (P-29f re-home).** P-29f is in S3 on the assumption `project-template/README.md` is a pack-maintainer artifact (it is NOT client-installed today — RECONCILED P-29f). IF the `boundary-investigation` for OQ-5 concludes "ship to clients," P-29f's FIX work migrates to S2 (it becomes a client-surface fix under the client rule-frame) and S3 drops to 17 / S2 rises to 14. This is the ONE assignment that an open decision can move; flagged so the user sees it. The coverage total (49) is invariant either way.
- **OQ-1 contention (one policy, two segments).** OQ-1 (per-doc edit vs Pattern-B ship-sweep) governs prison stale-refs in BOTH S1 (P-09/P-17/P-18) and S3 (P-14/P-15/P-21/P-25). Resolve the POLICY once (a single user decision) and apply it in each segment. If the policy is "Pattern-B ship-sweep at version boundary," both segments' record-disposition work becomes a single deferred sweep action rather than per-doc edits — but the policy decision is the same one item, not two.

---

## 4. Launch-gate classification + deferral-candidate flags

### 4.1 Classification per segment + per problem

**Default per the user's hard requirement: ALL 49 in v11.0.** This classification informs *priority/ordering*, not exclusion.

| Class | Definition | Problems |
|---|---|---|
| **L-BLOCK (launch-blocking, client-visible contamination)** | A v11.0 client install would receive contaminated/dead/wrong content the moment it ships. | **All of S2** (P-04, P-05, P-06, P-19, P-20, P-29g, P-31c, P-31d, P-31e, P-31f — client-shipped dead refs / version lies / contradictory manifests); the client-path script-logic defects P-22, P-23 (a v11 client's forward-migration silently parses zero entries); the client-authoring grammar P-30b. **13 problems.** |
| **L-CONTAM (launch-quality, the contamination the launch exists to expunge)** | Not a hard CI-gate failure (both BLOCKERs are comment/archive-only, CI is green — RESCOPE §4, EB-1/EB-2 re-confirmed) but the exact mis-versioning the v11.0 release must not carry, and the BD-185-restart baseline. | **All of S1** (12 problems). |
| **L-INT (internal hygiene; not client-visible)** | Pack-maintenance / pack-product / pack-self surfaces a client never receives; defects degrade maintainer experience + audit integrity, not the shipped client. | **All of S3 + S4** (24 problems). |

**Why the two BLOCKERs are L-CONTAM, not L-BLOCK.** RESCOPE §4.1/§4.2 established (and EB-1/EB-2 re-confirm at `add50de`) that P-01 is comment-only (CI green) and P-02 has no script consumer (no runtime/CI consumer). Neither fails the v11.0 CI launch gate today. They are launch-CRITICAL by the user's "expunge the contamination" goal, but not launch-BLOCKING in the CI-gate sense. This verdict is reused from RESCOPE unchanged.

### 4.2 Launch-gate-informed priority (confirms §3.3 ordering)

L-BLOCK (S2) is the highest *external-visibility* class — it is what a client sees. L-CONTAM (S1) is the highest *goal-priority* class — it is the launch's reason for being, and it interleaves with BD-185. L-INT (S3/S4) is internal. The §3.3 ordering (S1 first by goal + interleave, then S2 by client-visibility, then S3/S4) is consistent with this.

### 4.3 Deferral-candidate flags (for the USER to decide — NOT deferred here)

Per `no-deferral-without-user-direction`, the default is all-in-v11.0 and this design defers nothing. The following are *flagged* as the only items a user MIGHT reasonably consider deferring past launch, with the blast-radius for the user's decision. **The design's recommendation is to keep all in v11.0**; these are surfaced because the prompt asks for the candidate list:

- **P-31l (S3) — `INTAKE-GROUPINGS-V11` unverified-fidelity self-flag.** Genuinely v11.1+ scope (groupings is v11.1 per project memory `project_v11_1_approved_scope`). Its caveat is legitimate, not contamination (RECONCILED P-31l). LOGICAL-FIT defer-candidate: it belongs to the v11.1 groupings work-stream. *Blast-radius if deferred:* zero — it is a self-flagged caveat on a doc that v11.1 owns. **Strongest defer-candidate.**
- **P-31h (S3) — Xcode companion `gpt-5` vs `gpt-5.4` model drift.** Cosmetic parity drift on a companion template. *Blast-radius if deferred:* a companion-template user gets an older cloud model default until fixed. SIZE-trivial (one-line bump) — argues AGAINST deferral (cheaper to just do it).
- **NQ-3 scope (S3) — sweeping BD-196's new surfaces for BD-195 defect classes.** If the user decides BD-196's CI-guarded surfaces are "BD-196-owned and out of BD-195 scope," this is a scope-narrowing, not a deferral. *Blast-radius:* the 5 new surfaces (manifests, RATIONALE, allowlist) are CI-guarded by Checks 44/45/46 already; the residual risk is only the BD-195 defect classes those checks don't cover (stale refs, version labels). **This is a SCOPE question for the user, surfaced not pre-decided.**

No other item is a defensible defer-candidate (none passes SIZE/BLOCKED/LOGICAL-FIT with concrete evidence per `feedback-deferral-is-scope-creep`). The two BLOCKERs and all 13 L-BLOCK client-visible defects are NOT deferrable.

---

## 5. BD-185 interleave analysis (the question RESCOPE skipped)

The prompt asks the load-bearing question RESCOPE deferred: **which surfaces will BD-185's phase-parts feature work touch/rewrite, and does any cleanup segment touch a surface BD-185 will rewrite — creating double-work or re-contamination risk if ordered wrong?** This is a DEPENDENCY question (sequencing), NOT a gating question (BD-195 was never about gating BD-185 per the rejected axis).

### 5.1 BD-185's likely touch-surfaces (from the BACKLOG File/Symbol list + the held V2 design, contamination stripped)

Reading the BD-185 BACKLOG entry's File/Symbol list and the held `ARCHITECTURE-BD-185-V2.md` for FEATURE surfaces (treating its v11.1 framing as contaminated per the PRISON RULE — extracting the feature's surfaces, not the contaminated specifics), BD-185's restart will touch/rewrite:

| BD-185 feature surface | Source | S-segment overlap |
|---|---|---|
| `scripts/validate-pack.py check_issue_template_forms()` — comments + new part/ordering checks | BACKLOG File/Symbol; V2 §1.3, §10 Group D | **S1 / P-01** (Group D IS P-01's fix) |
| `scripts/validate-pack.py check_template_archive_v11()` — extend to 6 entry types | V2 §10 Group E | **S1 / P-12** (Group E IS P-12's fix) |
| `maintenance-docs/v11-research/templates-archive/v11.0/` cut — phase-part SCHEMA relocation + INDEX 6-type | V2 §10 Groups A/B/C, D-2/D-4 | **S1 / P-02** (Groups A–C ARE P-02's relocation) |
| `scripts/tests/test-issue-forms.sh` — comments + new assertions | V2 §10 Group F | **S1 / P-01** (Group F IS P-01's test half) |
| `project-template/.github/ISSUE_TEMPLATE/work-item.yml` (Part field) + pack-root form | BACKLOG; V2 §2.C, §4.4 | none (S2 touches other `project-template/` files, not this form's Part field) |
| `supporting-docs/METHODOLOGY.md` § Multi-part phases | BACKLOG; V2 §1.3 | none (no S-segment problem touches METHODOLOGY substance) |
| `project-template/docs/pack/PM-CHAT.md` (phase-to-parts orchestration) | BACKLOG | none (S2/P-04 touches PM-CHAT's MERGE-STRATEGY ref, a DIFFERENT line) |
| `scripts/lib/tracker-provider-*.sh` + NEW `scripts/lib/tracker-phase-part.sh` | BACKLOG; V2 D-11, §4.5/§5 | partial — S2/P-22/P-23 touch `tracker-migrate-forward.sh` (a SIBLING lib, different file) |
| `scripts/migrate-v10-to-v11.sh` + v11.0 forward-migrator (whole-number phase passthrough + ordering backfill) | BACKLOG; V2 D-10, §5.5 | none directly (S2/P-22/P-23 touch the forward-migrate path-resolution, not the ordering backfill) |
| NEW pack verbs (`pack phase split/reorder`, `pack task supersede`) + their HELP fragments | V2 D-11 | partial — S4/P-30a adjudicates HELP-FRAGMENT-TRACKER TD/phase verbs (adjacent, not identical) |
| `pack-ops/BACKLOG.md` BD-185/BD-193 narrative paths | V2 §10 Group H | **S1-adjacent** (PM-only; BD-185 entry prose normalization) |

### 5.2 The decisive finding: S1 and BD-185's first commits are the SAME edits

**The held `ARCHITECTURE-BD-185-V2.md §10` Groups A–G ARE the S1 fix recipes.** This is not coincidental overlap — the V2 design was authored to de-contaminate the v11.1 mislabel AS the first step of the phase-parts feature work. Concretely (V2 §10, re-read at `add50de`):
- **Group A/B/C** = relocate `phase-part-v11.1/SCHEMA.md` → `v11.0/phase-part-v11.0/`, retire `v11.1/INDEX.md`, retire the duplicate form = **exactly P-02's recommended action** (RECONCILED P-02).
- **Group D** = de-contaminate `check_issue_template_forms()` comments = **exactly P-01's validator half.**
- **Group E** = extend `check_template_archive_v11()` to 6 types = **exactly P-12's fix.**
- **Group F** = de-contaminate `test-issue-forms.sh` comments = **exactly P-01's test half.**
- **Group G** = reword `v11.0/INDEX.md` "Frozen forms"/D16 = **exactly P-31a's fix.**

So **S1 IS the de-contamination prologue of the BD-185 feature restart.** RESCOPE missed this because its gating-role lens asked "what does S1 block" (answer: the BD-185 restart) rather than "what work IS S1" (answer: the same edits the BD-185 V2 design opens with).

### 5.3 Double-work / re-contamination risk by surface

| Surface | If S1 runs, then BD-185 rewrites it later | Risk |
|---|---|---|
| `validate-pack.py check_issue_template_forms()` | S1 de-contaminates the comments (P-01); BD-185 then ADDS new part/ordering checks to the same function | **LOW double-work, ZERO re-contamination** — S1's edit is comment-only; BD-185's edit is additive (new checks). They compose. No re-contamination because S1 removes the "v11.1" string and BD-185's new code is born v11.0-correct. |
| `check_template_archive_v11()` | S1 adds the 6th `phase-part` type (P-12); BD-185 relies on that 6th type existing | **NEGATIVE double-work (S1 HELPS BD-185)** — P-12 is literally a BD-185 prerequisite that S1 lands early. |
| `templates-archive/v11.0/` cut | S1 relocates the SCHEMA to the v11.0 cut (P-02); BD-185 reads the grammar FROM that location | **NEGATIVE double-work (S1 HELPS BD-185)** — P-02 produces the clean, correctly-located grammar source BD-185 needs. |
| `test-issue-forms.sh` | S1 de-contaminates comments (P-01); BD-185 adds part/ordering assertions | **LOW double-work, ZERO re-contamination** — composes, same as the validator. |
| `tracker-migrate-forward.sh` (S2/P-22/P-23) | BD-185 touches `tracker-provider-*.sh` + a NEW `tracker-phase-part.sh`, NOT `tracker-migrate-forward.sh` | **NONE** — different files; BD-185's migrator work is the ordering-backfill path, S2's is the BACKLOG/PLAN path-resolution. Could touch the same file IF BD-185's migration design extends forward-migrate; flag as UNCERTAIN (§5.5). |

**The critical re-contamination risk is the REVERSE ordering: BD-185 BEFORE S1.** If the BD-185 restart fires before S1 de-contaminates, BD-185's coder reads the phase-part grammar from the fictional `v11.1/` cut, extends the validator whose comments say "v11.1," and re-seeds the exact mislabel that fractured the prior attempt (the V2 §0 supersession notice exists precisely because the prior attempt inherited this). **S1 MUST precede the BD-185 restart.**

### 5.4 Interleave conclusion

**BD-185 runs AFTER S1, and S1 IS its de-contamination prologue.** Specifically:

1. **S1 must complete before the BD-185 restart begins** (re-contamination risk, §5.3) — this is a hard ordering edge.
2. **S2, S3, S4 have NO interleave relationship with BD-185** — they touch disjoint surfaces (the one near-miss, S2's `tracker-migrate-forward.sh` vs BD-185's `tracker-provider`/`tracker-phase-part`, is different-file; flagged UNCERTAIN below). They may run before, during, or after the BD-185 restart without double-work or re-contamination.
3. **S1's later problems (P-09/P-16/P-17/P-18) ARE the BD-185 record-disposition** — these are exactly the held/attempt records BD-185's restart must rule on (track/prison/wipe). They are S1 work AND the BD-185-restart's own first decision. This is why S1 and the BD-185 restart are coupled: S1 ends where the BD-185 restart's disposition decision begins.

**Where this is UNCERTAIN (pending BD-185's own not-yet-done design):**
- **The validator/test additive-edit composition** assumes BD-185's new checks are additive to the de-contaminated function. If BD-185's design instead RESTRUCTURES `check_issue_template_forms()` (e.g., splits it), S1's comment edits would be partially overwritten — LOW-cost re-work (re-applying comment de-contamination to the restructured function), never re-contamination. UNCERTAIN until BD-185's architect pass exists.
- **Whether BD-185's migrator work extends `tracker-migrate-forward.sh`** (S2/P-22/P-23's file). The BACKLOG names `tracker-provider-*.sh` + `migrate-v10-to-v11.sh`; the V2 design names a NEW `tracker-phase-part.sh`. If BD-185 ends up editing forward-migrate's phase-handling, S2's path-resolution fix should land first so BD-185 builds on the corrected resolution. UNCERTAIN until BD-185's plan exists; LOW-cost either way.

**Net:** the only hard interleave edge is **S1 → BD-185 restart**. The other three segments are interleave-free. This is the dependency answer; it does not gate the launch (the launch needs all four segments + BD-185), it orders them.

---

## 6. Proposed execution + BD structure + path to launch

### 6.1 Recommended representation (PROPOSE only — no BD numbers)

The user rejected the BD-185-gate axis, which means the RESCOPE proposal ("BD-195 = the narrow gate, new BD = the broad cleanup") is also rejected — it was built on that axis. This design proposes a representation built on the work-similarity axis:

**Proposal: BD-195 carries the four segments as ordered, internally-tracked sub-work; OR four BDs, one per segment. Recommend the latter (four BDs) — here is why, and the fallback.**

- **Primary recommendation — FOUR BDs, one per segment (S1/S2/S3/S4), all children of the v11.0 launch effort.** Each BD = one work-shape = one fixer/reviewer rule-frame = one bounded review/fix cycle scope. Rationale: the segments are parallelizable (§3.3) and a reviewer checks one shape per BD (the user's "similar work at the same time"). BD-195 keeps its identity as the **umbrella / S1 owner** (it has always been "Code Red 3, the contamination recovery," and S1 IS the contamination recovery + the BD-185-restart prologue). The three non-contamination segments get fresh BDs.
  - Concretely: **BD-195 (re-scoped) = S1** (de-contamination; owns the Step-9-equivalent BD-185-record disposition; keeps the BD-185 pause-line valid — BD-185 still waits on BD-195/S1). **Three NEW BDs (Pack Chat assigns numbers from the live BACKLOG) = S2 / S3 / S4.**
- **Fallback — ONE BD-195 with four tracked sub-segments** if the user prefers a single tracking surface. Acceptable because the segments are coverage-tracked in §2.3; the cost is that the bounded review/fix cycle would run four times under one BD (workable but less clean for parallelism).

**Why four BDs beats RESCOPE's two-BD shape:** RESCOPE's two BDs split on "gates BD-185 / does not," which the user rejected. Four BDs split on work-shape, which the user chose. Four BDs also let S2 (the highest client-visibility / L-BLOCK segment) run on its own cadence in parallel with S1, rather than being lumped into one undifferentiated "broad cleanup" BD with mixed rule-frames.

**This is a PROPOSAL.** Pack Chat (PM-only) assigns the three new BD numbers (read the live BACKLOG for the highest BD-NNN first per CLAUDE.md), authors the entries, narrows BD-195 to S1 + the BD-185-record disposition, and strikes P-29a (NQ-2). The architect assigns no numbers and writes no entries.

### 6.2 Does each segment run its own Steps 5–8 fix pipeline?

**Yes — each BD/segment runs its own architect-fix-design → fix-plan → implement → bounded-review cycle, sharing the S0 (NQ-1) re-anchoring done once up front.** (Reuses RESCOPE §6.2's per-slice-pipeline structure, re-scoped to four segments.) Per the bounded review/fix cycle (max 2 review/fix pairs + 1 final reviewer per commit; architect escalation if still dirty), each segment's commits run the full cycle. S1's fix-design also reads the held `ARCHITECTURE-BD-185-V2.md §10` Groups A–G as the recipe substrate (§5.2) — but those recipes' bare-path defect (P-13) must be normalized first (S0-adjacent / intra-S1 first step).

### 6.3 Path to the v11.0 launch (full sweep + BD-185, optimally ordered)

1. **Pack Chat finalizes the representation** (PM-only): assign three new BD numbers; author S2/S3/S4 entries; narrow BD-195 to S1; strike P-29a (NQ-2). BD-185 pause-line needs no edit (BD-195/S1 still owns the disposition gate).
2. **S0 — NQ-1 re-anchoring** (one-time, ahead of all four segments' fix-design).
3. **S1 (BD-195) runs Steps 5–8:** P-13 → P-01 → P-02(+P-12/P-08/P-31a lock-step) → P-09/P-16/P-17/P-18 (gated OQ-1/OQ-3) → P-31b/P-31k. Bounded cycle per commit. **S1 complete = the contamination is expunged AND the BD-185-restart prologue is done.**
4. **S2, S3, S4 run Steps 5–8 in parallel with each other** (and may overlap S1 since surfaces are disjoint), priority S2 → S3 → S4 by client-visibility (§4.2). The boundary-class OQs (OQ-2, OQ-5, NQ-4) get `boundary-investigation` at their problem's fix-design; OQ-5 may re-home P-29f S3→S2 (§3.4).
5. **BD-185 restarts** (separate BD) AFTER S1 completes (the hard interleave edge, §5.4) — seeded by the S1 BD-185-record disposition + the Retained-Decisions doc. The validator/archive/test surfaces it extends are now v11.0-clean (S1 produced exactly the clean baseline V2 §10 Groups A–G describe).
6. **v11.0 launches when all four segments + BD-185 complete.** All 49 problems resolved, all 12 decisions made, the contamination expunged, the client surfaces clean, and the phase-parts feature shipped on a clean baseline.

**The launch gate is: S1 ∧ S2 ∧ S3 ∧ S4 ∧ BD-185, all complete.** S1 is the critical path (it precedes BD-185); S2/S3/S4 are parallel and bounded only by reviewer/coder throughput. No segment can be dropped without violating the user's no-coverage-gap requirement.

---

## 7. Empirical-Evidence Blocks

All measurements 2026-05-31 at HEAD `add50dec0c6ff48890c2069d268480e46f9f5f6a` (`add50de`), branch `v11-dev`.

**EB-1 — P-01 (BLOCKER) STILL-LIVE at `add50de`; comment-only.**
- *Command:* `grep -c "v11.1" scripts/validate-pack.py`; `grep -c "v11.1" scripts/tests/test-issue-forms.sh`.
- *Output:* `scripts/validate-pack.py` → `3`; `scripts/tests/test-issue-forms.sh` → `6`.
- *Interpretation:* P-01 mislabel present in both surfaces, unchanged from the audit. Matches RESCOPE EB-1 (comment-only; runtime/assertions correct). Supports S1 membership + first-fix.
- *Conclusion:* SUPPORTED.

**EB-2 — P-02 (BLOCKER) STILL-LIVE at `add50de`; the fictional v11.1 cut intact.**
- *Command:* `find maintenance-docs/v11-research/templates-archive/v11.1 -type f`.
- *Output:* `…/v11.1/INDEX.md`, `…/v11.1/forms/work-item.yml`, `…/v11.1/phase-part-v11.1/SCHEMA.md`.
- *Interpretation:* The fictional cut + the SOLE live home of the phase-part grammar are present. Supports S1 membership; supports §5.3 (BD-185 reads this grammar → must be relocated by S1 first).
- *Conclusion:* SUPPORTED.

**EB-3 — P-13 precondition (32 bare paths) + P-12 5-type loop live at `add50de`.**
- *Command:* `grep -c "templates-archive/v11" maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md maintenance-docs/v11-implementation/PLAN-BD-185-V2.md`; `grep -n '("bd", "td", "phase-epic", "phase-task", "inbound")' scripts/validate-pack.py`.
- *Output:* `ARCHITECTURE-BD-185-V2.md:20`, `PLAN-BD-185-V2.md:12` (= 32 bare-path occurrences); `validate-pack.py:1237` carries the 5-type loop `("bd", "td", "phase-epic", "phase-task", "inbound")`.
- *Interpretation:* P-13 live (32 bare paths in the S1 recipe substrate → must normalize before P-02 executes, §3.2). P-12 live (5-type loop, no `phase-part` → ENCODING lock-step partner of P-02). Supports intra-S1 ordering.
- *Conclusion:* SUPPORTED.

**EB-4 — BD-185 feature surfaces overlap S1 surfaces (the §5.2 decisive finding).**
- *Command:* `grep -nE "validate-pack|check_template_archive|check_issue_template|templates-archive/v11.0|test-issue-forms" maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md` (§10 Groups D/E/F/A-C); cross-read BACKLOG BD-185 File/Symbol list.
- *Output:* V2 §10 Group D = `check_issue_template_forms()` comment de-contamination (= P-01); Group E = `check_template_archive_v11()` extend to 6 types (= P-12); Groups A–C = `templates-archive/v11.0/` SCHEMA relocation (= P-02); Group F = `test-issue-forms.sh` comment de-contamination (= P-01 test half); Group G = `v11.0/INDEX.md` reword (= P-31a). BACKLOG File/Symbol lists `validate-pack.py` new checks, `work-item.yml`, `METHODOLOGY.md`, `tracker-provider-*.sh`, `migrate-v10-to-v11.sh`, `PM-CHAT.md`.
- *Interpretation:* BD-185-V2's own §10 fix-groups ARE the S1 fix recipes for P-01/P-02/P-12/P-31a. S1 is the BD-185 restart's de-contamination prologue. The reverse order (BD-185 before S1) re-seeds the mislabel (§5.3). Confirms the hard interleave edge S1 → BD-185.
- *Conclusion:* SUPPORTED.

**EB-5 — The live count is 49 (not 48); P-29h is the dropped leaf; the four segments partition the 49 exactly.**
- *Command:* (1) `grep -oE "\*\*P-[0-9]+[a-z]?\*\*"` over REFRESH §2 → distinct leaf rows; (2) `comm -23` {49 live leaves (50 rows − P-29a)} vs {REFRESH §3 slice members}; (3) `comm` of the union of the four S-segment member-lists vs the 49-leaf set, both directions.
- *Output:* (1) 50 distinct leaf rows in REFRESH §2; minus P-29a = 49 live. (2) `comm -23` returns exactly `P-29h` (live in §2, absent from every §3 slice → the source of the "48" undercount; RESCOPE inherited it: RESCOPE §3 says Slice 2 = 36 / total 48, but its §2 table assigns P-29h, so the true Slice 2 = 37 / total 49). (3) S1(12) ∪ S2(13) ∪ S3(18) ∪ S4(6) = 49 leaves; `comm` both directions empty → disjoint + complete.
- *Interpretation:* The correct denominator is 49. P-29h is recovered into S3. The four segments are a partition (no gaps, no doubles).
- *Conclusion:* SUPPORTED (mis-count finding surfaced; coverage proven complete at 49).

**EB-6 — Segment surfaces are pairwise disjoint (the no-cross-segment-dependency basis for §3.3).**
- *Command:* manual surface-tag of each segment's member problems against the RECONCILED "Surfaces" lines, cross-checked against the REFRESH §3 surface tags; verified no file path appears in two segments' fix-targets (S1 = `scripts/validate-pack.py` comments + `test-issue-forms.sh` comments + `templates-archive/` + contamination records; S2 = `project-template/` + `tracker-migrate-forward.sh` + `test-tracker-phase-task.sh`; S3 = pack docs + companion + `tracker-{migrate-forward,phase-task}.sh` HEADER refs [P-21] + README; S4 = PACK-CHAT/PACK-AGENTS + pack-agent/skill trinity).
- *Output:* One near-collision: `scripts/lib/tracker-migrate-forward.sh` appears in S2 (P-22/P-23, client-path LOGIC) and `scripts/lib/tracker-{migrate-forward,phase-task}.sh` in S3 (P-21, prisoned-doc HEADER comment). These are DIFFERENT edits to the same file (logic vs header comment) — flagged: if S2 and S3 both touch `tracker-migrate-forward.sh`, sequence S2's logic edit and S3's P-21 header edit to land in coordinated commits (or assign P-21 to whichever segment edits the file first). This is the single cross-segment file-touch; it is comment-vs-logic, not a content dependency.
- *Interpretation:* Segments are surface-disjoint except the one flagged comment-vs-logic co-touch on `tracker-migrate-forward.sh`. No fix-content dependency between segments → the §3.3 parallelizability holds.
- *Conclusion:* SUPPORTED (with the one flagged co-touch to coordinate at commit time).

---

## 8. Rules-Applied Verification Block

| Rule (as named in prompt) | Verification evidence | Conclusion |
|---|---|---|
| Architect state-claims require Empirical-Evidence Blocks | §7 EB-1…EB-6 back every load-bearing claim — P-01/P-02 liveness (EB-1/EB-2), P-13/P-12 precondition (EB-3), the BD-185↔S1 surface overlap (EB-4), the 49-count + P-29h drop + partition (EB-5), segment-surface disjointness (EB-6) — each with command + verbatim output + HEAD `add50de` + date 2026-05-31 + interpretation + SUPPORTED. The cluster boundaries (§1.3), every dependency edge (§3), the launch-gate classes (§4), the BD-185 interleave (§5), and the coverage proof (§2.3) each cite their EB. REFRESH/RESCOPE figures were NOT trusted: the "48" was re-measured and corrected to 49 (EB-5). | COMPLIANT |
| Complete coverage is mandatory | §2.1 assigns all 49 live leaf-problems to exactly one segment; §2.2 assigns all 12 open decisions; §2.3 gives per-segment counts (12+13+18+6=49) + the no-double-count proof (EB-5). P-29a struck with a note (CLOSED-BY-BD-196). A mis-count was found and surfaced (the live count is 49, not 48; P-29h was the dropped leaf — §2.3, EB-5). Zero dropped, zero double-counted. | COMPLIANT |
| Pattern-matching out of context is an anti-pattern | §1.1 defines the cut by work-shape = rule-frame (what makes the fix faster/more-accurate/dependency-correct), explicitly rejecting both the surface-name reflex (REFRESH §3 tag) and the rejected BD-185-gate axis (RESCOPE). §1.2 evaluates each candidate cluster on property-fit (audience/rule-frame/verification), merging or splitting on evidence (e.g., splitting "dead-ref" into client-leak vs pack-stale by rule corpus), not surface name. | COMPLIANT |
| Preliminary-triage + architect-challenge | §1.2 treats Pack Chat's four candidates as PRELIMINARY and challenges each (adopt/sharpen/merge/replace with justification): (a) adopted+sharpened, (b) split by edit-shape, (c) merged not standalone, (d) adopted as the primary non-contamination split. §1.4 challenges RESCOPE's gating-role cut. The cut is justified by couplings + rule-frames, not reflex. | COMPLIANT |
| No-deferral-without-user-direction | The design defers nothing — all 49 are in v11.0 across the four segments (§2.3). §4.3 FLAGS three deferral-candidates (P-31l strongest, P-31h, NQ-3 scope) with blast-radius for the USER to decide, and explicitly recommends keeping all in v11.0; treats the architect-level "looks deferrable" as a flag, not authority. | COMPLIANT |
| No-recommendation on OQ/NQ answers | §2.2 + §3 ASSIGN + SEQUENCE all 12 decision items (6 OQ + OQ-3 partial + OQ-8 precondition + 4 NQ) to segments, answering none. Boundary-class items (OQ-2, OQ-5, NQ-4; mild OQ-4/OQ-6) flagged for `boundary-investigation` at resolution time. OQ-5's contingent re-home of P-29f (§3.4) is surfaced, not pre-decided. | COMPLIANT |
| Agent output requires Rules-Applied Verification Block | This table. | COMPLIANT |
| PRISON RULE (membership noted, not imported) | The held BD-185-V2 / PLAN-V2 docs (untracked, prison-adjacent) were read ONLY to extract the FEATURE's touch-surfaces (§5.1) and the §10 fix-recipe overlap (§5.2/EB-4); their v11.1 framing was treated as contaminated and NOT adopted as guidance. Prisoned docs (P-09/P-14/P-15/P-17/P-18/P-21/P-25 anchors) referenced only as STATE to establish stale-ref liveness + segment assignment; no prison doc cited as a live source. `maintenance-docs/prison/` not read. | COMPLIANT |
| Agents never commit / no destructive ops | All tool actions read-only (Read, grep, find, ls, git log/rev-parse/branch, python3 read+single-write to the deliverable) + the single authorized Write to this report path (built via `cat >>` append + one in-place truncate of MY OWN in-progress draft; no edit to any other file; no `git add/commit/push/tag`; no `rm`/`mv` of any tracked file). No BD numbers assigned; no BACKLOG entry written (PM-only, left to Pack Chat). | COMPLIANT |
| STOP-MEANS-STOP | No parent stop/halt/revert issued; work proceeded to the single authorized deliverable. | COMPLIANT (N/A trigger) |

**End of ARCHITECTURE-BD-195-SEGMENTATION.md.**
