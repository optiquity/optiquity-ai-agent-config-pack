# ARCHITECTURE-BD-195-RESCOPE

**Author:** pack-architect (BD-195 RE-SCOPE design pass — option C already decided by user). **READ-ONLY design; PROPOSES a BD structure, assigns no numbers, answers no open decision.**
**Date:** 2026-05-31. **Branch:** v11-dev. **HEAD:** `add50dec0c6ff48890c2069d268480e46f9f5f6a` (`add50de`).
**Disposition (fixed input, not re-litigated):** Option C — split BD-195. This doc designs the split: slice boundaries, per-problem assignment, BLOCKER blocking-target, open-decision distribution, and the proposed BD structure + path to the BD-185 restart.

**Inputs read (all at `add50de`):** `AUDIT-BD-195-REFRESH-POST-BD196.md` (48 live + slice tags + 8 OQ verdicts + 4 NQ), `AUDIT-BD-195-RECONCILED-PROBLEM-LIST.md` (P-NN detail + couplings + OQ defs), `AUDIT-BD-195-LANDSCAPE-STATE.md` (reset history), `pack-ops/BACKLOG.md` (BD-195 + BD-185 entries), `PLAN-BD-195-EXECUTION.md` (Steps 0–9, esp. Step 9 contract).

**HEAD note.** The three audit docs were measured at `c73077d`. The only commit between `c73077d` and `add50de` is `add50de` itself (the audit-doc + BACKLOG-state commit — verified `git log --oneline c73077d..add50de` → 1 commit, doc-only). No source surface changed, so the audits' source-tree classifications carry to `add50de`. The load-bearing live-state claims (P-01, P-02, P-09, P-11, P-13) are independently re-measured at `add50de` in §7 (EB-1…EB-3).

---

## 1. Slice definitions + challenge of the preliminary boundary

### 1.1 The user's preliminary frame

The user's frame is a two-way cut: **(Slice 1) BD-185-precondition** — the minimum that gates the BD-185 restart per PLAN-BD-195-EXECUTION Step 9 — vs **(Slice 2) broad v11.0 repo cleanup** — everything else. The re-audit (`REFRESH-POST-BD196` §3) supplies a 5-way surface tag (BD-185-artifact 12 / pack-rule-corpus 2 / project-side 11 / product 8 / other 15 = 48) and a headline "12 BD-185-specific vs 34 broad."

### 1.2 The challenge: the re-audit's surface-tag is NOT the right cut for a re-scope

The re-audit's 5-way tag is a **surface-ownership** tag (which tree owns the fix). That is the correct lens for *sequencing a fix pass* but the WRONG lens for *slicing a re-scope*, because the re-scope question is not "which tree does this live in" but **"what does fixing this GATE, and what is its urgency."** Two problems on the same surface can have opposite gating roles:

- `P-13` (bare archive paths in V2 §10 / PLAN-V2 §6) is tagged **BD-185-artifact** by surface, but it gates `P-02` (a BLOCKER) — it is a *precondition mechanic*, not a BD-185-disposition input.
- `P-08`/`P-09`/`P-17`/`P-18` are tagged **BD-185-artifact** by surface, but they are exactly the Step-9 *disposition inputs* (the held/attempt records the user must rule wipe/prison/leave on). These are NOT "fixes" in the ordinary sense — Step 9 decides their fate.

So a clean re-scope cut must separate three roles, not two surfaces:

1. **Launch-blocking defects** — live, tracked, CI-executing or client-shipped contamination whose existence is itself a v11.0-quality defect, fixable mechanically now, independent of the BD-185 disposition. (The 2 BLOCKERs + the broad cleanup.)
2. **BD-185-restart preconditions** — the narrow set that MUST be true before a BD-185 restart can begin from a clean baseline, AND the Step-9 disposition inputs (the held/attempt records the user rules on).
3. **Precondition mechanics** — problems that gate a (1) or (2) problem and must land first (e.g., P-13 → P-02; OQ-8 → P-02).

### 1.3 The cut this design adopts

The cleanest cut that survives the challenge keeps the user's two-slice frame but **re-assigns by gating-role, not surface**, and isolates the precondition mechanics inside the slice they serve. This yields a cut that crosses the re-audit's surface tags (per the preliminary-triage-architect-challenge rule):

- **SLICE 1 — BD-185-restart precondition (the narrow gate).** The minimum set whose resolution Step 9 / the BD-185 restart depends on: the two epicenter contaminations that fractured the prior attempt (P-01, P-02) BECAUSE they are the exact mis-versioning the restart must not inherit; the precondition mechanics that gate them (P-13, and the SCHEMA-relocation coupling P-12); the propagation record that blessed the mislabel (P-08); and the Step-9 disposition inputs — the held + attempt BD-185 records (P-09, P-16, P-17, P-18) plus the framing/cosmetic artifacts on the BD-185 archive cut (P-31a, P-31b, P-31k). This is the slice that gates BD-185.
- **SLICE 2 — broad v11.0 repo cleanup (everything else).** All remaining live problems: client-shipped boundary/version-currency defects (project-side), pack product surfaces (README layout, companion templates, supporting-docs, client-path script logic), pack-self parity/precision, prison stale-refs not specific to BD-185, and the 2 pack-rule-corpus items BD-196 reshaped-but-did-not-fix. None of these gate the BD-185 restart; they are v11.0-launch-quality work.

**Why this beats a pure surface cut.** It puts P-01/P-02 (the fracture cause) and the Step-9 disposition inputs in ONE slice that maps 1:1 onto "what must be settled before BD-185 restarts," and leaves Slice 2 as a single homogeneous "make v11.0 clean" batch with no BD-185 entanglement. The re-audit's "BD-185-artifact 12" set maps almost exactly onto Slice 1 — the only surface-tag boundary this design CHANGES is keeping P-13 inside Slice 1 (it was already BD-185-artifact-tagged, so no cross-tag move) and confirming P-12 rides with P-02 (also already BD-185-artifact-tagged). **Net: Slice 1 = the 12 BD-185-artifact-tagged problems exactly; Slice 2 = the other 36 (2 pack-rule-corpus + 34 broad).** The challenge VALIDATES the re-audit's surface tag as also the correct gating cut for these 48 — a non-obvious result worth stating: here surface-ownership and gating-role coincide because the BD-185 epicenter contamination is co-located with the BD-185 artifacts.

### 1.4 Reconciling the re-audit's "34 vs 12" headline

The re-audit headline says "12 BD-185-specific vs 34 broad." That headline DROPS the 2 pack-rule-corpus items from the broad side (12 + 34 = 46, not 48). The honest partition is **12 (Slice 1) + 36 (Slice 2) = 48**, where Slice 2's 36 = 34 broad-cleanup + 2 pack-rule-corpus. P-29a (closed by BD-196) is NOT in either slice. Per-slice counts are reconciled exactly in §3.

---

## 2. Per-problem assignment (all 48 live + the 1 changed P-09)

Every live problem assigned to a slice with a one-line gating-role rationale. Severity from the reconciled list. "Surface tag" = the re-audit §3 tag (shown to make the cross-tag analysis auditable). P-29a is omitted (CLOSED-BY-BD-196 — not live; struck per NQ-2). P-09 is the CHANGED problem (provenance sub-claim resolved; prisoned-anchor + v11.1-framing sub-claims live).

| P-NN | Sev | Surface tag | Slice | Gating-role rationale (one line) |
|---|---|---|---|---|
| **P-01** | BLOCKER | BD-185-artifact | **1** | The exact v11.1 mislabel that fractured BD-185, in CI-executing pack code; the restart MUST not inherit it. FIRST fix in Slice 1. |
| **P-02** | BLOCKER | BD-185-artifact | **1** | The fictional `templates-archive/v11.1/` cut — the mislabel's archive embodiment; restart baseline must be the corrected v11.0 cut. Gated by P-13 + OQ-8. |
| P-08 | MUST | BD-185-artifact | **1** | BD-193 review/Phase-5 BLESSED + deepened the mislabel; correction-target that rides P-02; the propagation record the restart must see reversed. |
| P-09 | MUST (CHANGED) | BD-185-artifact | **1** | `PACK-REVIEW-BD-185-H.2.md` — a Step-9 disposition input (prisoned anchor + v11.1 framing live); OQ-3 disposition is a Slice-1 decision. |
| P-12 | SHOULD | BD-185-artifact | **1** | `check_template_archive_v11()` must add `phase-part` once P-02 relocates the SCHEMA into the v11.0 cut; lock-step ENCODING partner of P-02. |
| P-13 | SHOULD | BD-185-artifact | **1** | Bare `templates-archive/...` recipe paths; **precondition mechanic** — must land BEFORE a coder executes P-02 (OQ-8). |
| P-16 | SHOULD | BD-185-artifact | **1** | `ARCHITECTURE-BD-185-V2.md` lacks the forward ordering-addendum pointer; a held BD-185 design doc the restart reads — Step-9 input. |
| P-17 | SHOULD | BD-185-artifact | **1** | 6 BD-185 IMPL reports carry the mislabel + prisoned refs; Step-9 disposition inputs (Pattern-B vs edit is OQ-1). |
| P-18 | SHOULD | BD-185-artifact | **1** | `PACK-REVIEW-BD-185-H.1.md` blesses the mislabel + prisoned anchors; Step-9 disposition input + propagation record. |
| P-31a | NIT | BD-185-artifact | **1** | `v11.0/INDEX.md` "Frozen forms" + bare D16 framing on the archive cut P-02 corrects; rides the P-02 archive cleanup. |
| P-31b | NIT | BD-185-artifact | **1** | `AUDIT-INVENTORY-BD-TD-PATH.md` D16 "frozen" wrapper snapshot; BD-185-attempt-era record adjacent to the P-02 correction. |
| P-31k | NIT | BD-185-artifact | **1** | `ARCHITECTURE-V3.3-DELTA.md` D-22/D-4-V2 row overtaken-by-BD-193 note; BD-185-design-record currency, rides Slice-1 design-doc pass. |
| **P-11** | MUST | pack-rule-corpus | **2** | "Four pack agents" in PACK-CHAT.md — pack-self governance accuracy; PM-only fix; no BD-185 gating. |
| P-31i | NIT | pack-rule-corpus | **2** | "Task tool" vs "Agent tool" drift across PACK-AGENTS/PACK-CHAT vs trinity; pack-self terminology; no BD-185 gating. |
| P-03 | MUST | product | **2** | README `maintenance-docs/` layout stale after prison move; PM-only; whole-repo currency, no BD-185 gating. |
| P-04 | MUST | project-side | **2** | `PM-CHAT.md` cites uninstalled `docs/pack/MERGE-STRATEGY.md`; client dead-ref + separation; no BD-185 gating. |
| P-05 | MUST | project-side | **2** | `.mcp.json.example` cites uninstalled `supporting-docs/CLI-PM-SETUP.md`; client dead-ref; no BD-185 gating. |
| P-06 | MUST | project-side | **2** | `.codex/config.toml.example` leaks pack maintenance doc + SHA; client separation; no BD-185 gating. |
| P-07 | MUST | other | **2** | pack-help skill stale bare refs (Claude+Codex) vs correct Gemini; pack-self parity; no BD-185 gating. |
| P-10 | MUST | product | **2** | README pack-ops/ vs supporting-docs/ mis-filing; PM-only; whole-repo currency, no BD-185 gating. |
| P-28 | MUST | product | **2** | Xcode Codex companion declares 7 unshipped agents; companion-template defect; no BD-185 gating (OQ-6). |
| P-14 | SHOULD | other | **2** | 19c-family artifacts forward-ref prisoned docs; prison stale-ref, NOT BD-185-specific; no BD-185 gating (OQ-1). |
| P-15 | SHOULD | other | **2** | V3.x chain cites prisoned V3.2-DELTA as authoritative; prison stale-ref; no BD-185 gating (OQ-1). |
| P-19 | SHOULD | project-side | **2** | `PACK-FEEDBACK.md` stamped v9 throughout; client version-currency; no BD-185 gating (OQ-4). |
| P-20 | SHOULD | project-side | **2** | Three client surfaces v10-stale / misdirected migrator; client version-currency; no BD-185 gating. |
| P-22 | SHOULD | product | **2** | `tracker-migrate-forward.sh` client path resolution asymmetry; script client-path logic; no BD-185 gating (OQ-not; arch call). |
| P-23 | SHOULD | product | **2** | `tracker-migrate-forward.sh` dead `maintenance-docs/IMPLEMENTATION-PLAN.md` fallback; dead-ref; no BD-185 gating. |
| P-24 | SHOULD | product | **2** | Pack surfaces advertise sunset v9→v10 migrator as live verbs; user-facing currency; no BD-185 gating (OQ-7). |
| P-26 | SHOULD | other | **2** | pack-planner state-verifiable rule Claude-only; pack-self trinity parity; no BD-185 gating. |
| P-29b | SHOULD | other | **2** | CONCEPTUAL-REVIEW-METHODOLOGY dangling ARCHITECTURE-V1.md + bare shorthand; pack-self dead-ref; no BD-185 gating. |
| P-29c | SHOULD | project-side* | **2** | CONCEPTUAL-AREA-CUSTOMIZATION-PRESERVATION wrong methodology-dir cite; sharpened by NQ-4; no BD-185 gating. |
| P-29d | SHOULD | other | **2** | EXECUTION-PLAN-V11.0 stale status line; pack-maintenance currency; no BD-185 gating. |
| P-29e | SHOULD | other | **2** | RECOMMENDATIONS.md v9-era no banner, README presents current; currency; no BD-185 gating. |
| P-29f | SHOULD | other | **2** | project-template/README.md v10-stale; ship-vs-relabel is OQ-5; no BD-185 gating. |
| P-30b | SHOULD | other | **2** | `test-tracker-phase-task.sh` BD-NNN admission; leak-vs-fidelity is OQ-2 (boundary-class); no BD-185 gating. |
| P-31d | SHOULD | project-side | **2** | `.gemini/settings.json` local-rag manifest contradicts authoritative manifest; client ENCODING lock-step; no BD-185 gating. |
| P-31f | SHOULD | project-side | **2** | `bootstrap.sh` cites uninstalled `supporting-docs/SETUP-NEW.md`; client dead-ref; no BD-185 gating. |
| P-21 | NIT | other | **2** | lib headers cite prisoned V3.2-DELTA; prison stale-ref in scripts; no BD-185 gating (OQ-1). |
| P-25 | NIT | other | **2** | TOOL-COMPARISON.md cites prisoned analyses at pre-prison path; prison stale-ref; no BD-185 gating. |
| P-27 | NIT | other | **2** | commit-discipline cites pack-side `agent-run.sh`; pack-self precision; no BD-185 gating. |
| P-29g | NIT | project-side | **2** | PLATFORM-SKILLS.md cites pack-repo `## Pack memory` on client surface; client separation; no BD-185 gating. |
| P-29h | NIT | other | **2** | VERIFIED-NOTES undated + Xcode README "v9 policy"; currency; no BD-185 gating. |
| P-30a | NIT | other | **2** | HELP-FRAGMENT-TRACKER TD/phase verbs on pack render; deliverable-only adjudication; no BD-185 gating. |
| P-31c | NIT | project-side | **2** | AGENTS.md lacks `$XCODE_APP` relocation mechanism; trinity parity; no BD-185 gating. |
| P-31e | NIT | project-side | **2** | `.codex/config.toml.example` "v10 ships STDIO only" stale; bundles with P-06; no BD-185 gating. |
| P-31g | — | other | **2** | README presents RECOMMENDATIONS/VERIFIED-NOTES as current; compounds P-29e/P-29h; no BD-185 gating. |
| P-31h | NIT | product | **2** | Xcode Codex config.toml model gpt-5 lags gpt-5.4; companion parity drift; no BD-185 gating. |
| P-31j | NIT | product | **2** | `tracker.toml.pack-example` path-less ARCHITECTURE.md ref; pack usability; no BD-185 gating. |
| P-31l | NIT | other | **2** | INTAKE-GROUPINGS-V11 unverified-fidelity self-flag (legit v11.1+); optional; no BD-185 gating. |

\* P-29c surface tag is "project-side by subject / pack-maintenance by file location" (re-audit §3 footnote + NQ-4). Slice assignment (2) is unaffected — either reading is non-BD-185-gating.

---

## 3. Per-slice counts (reconciled exactly)

| Slice | Count | BLOCKER | MUST | SHOULD | NIT | other | P-NNs |
|---|---|---|---|---|---|---|---|
| **Slice 1 — BD-185 precondition** | **12** | 2 (P-01, P-02) | 2 (P-08, P-09) | 5 (P-12, P-13, P-16, P-17, P-18) | 3 (P-31a, P-31b, P-31k) | 0 | P-01, P-02, P-08, P-09, P-12, P-13, P-16, P-17, P-18, P-31a, P-31b, P-31k |
| **Slice 2 — broad repo cleanup** | **36** | 0 | 8 (P-03, P-04, P-05, P-06, P-07, P-10, P-11, P-28) | ~15 | ~12 | 1 (P-31g) | all remaining live P-NNs |
| **Total live** | **48** | 2 | 10 | ~20 | ~15 | 1 | — |
| Closed (not in any slice) | 1 | — | — | — | — | — | P-29a (CLOSED-BY-BD-196; struck per NQ-2) |

**Reconciliation of the "34 vs 12" headline.** The re-audit headline (REFRESH §3) reads "12 BD-185-artifact vs 34 broad," which sums to 46 and silently omits the 2 pack-rule-corpus items (P-11, P-31i). This design's honest partition is **12 (Slice 1) + 36 (Slice 2) = 48**: Slice 2's 36 = 11 project-side + 8 product + 15 other + 2 pack-rule-corpus, minus the 0 that moved to Slice 1 (no cross-tag moves occurred; surface-tag and gating-cut coincided). The "34" was the broad-without-pack-rule-corpus figure; the 2 pack-rule-corpus items belong to Slice 2 (pack-self governance, non-BD-185-gating). **Ratio: Slice 2 dominates Slice 1 by 3:1** (36:12), sharper than the re-audit's stated 2.8:1 once the 2 pack-rule-corpus items are correctly attributed.

**Severity note.** ALL launch-blocking severity (the 2 BLOCKERs) lives in Slice 1. Slice 2 carries 8 of the 10 MUSTs but 0 BLOCKERs — Slice 2 is broad and high-volume but contains no single defect that blocks v11.0 launch on its own. This asymmetry is load-bearing for the BD structure (§5): Slice 1 is small + gating + BLOCKER-bearing; Slice 2 is large + non-gating + no-BLOCKER.

---

## 4. BLOCKER blocking-target + sequencing (evidence-backed)

### 4.1 What P-01 actually blocks

**P-01** = the v11.1 mislabel in `scripts/validate-pack.py` (L1086/L1121/L1123) + `scripts/tests/test-issue-forms.sh` (6 comment blocks). Measured live at `add50de` (§7 EB-1). The runtime dict + assertions are CORRECT; only comments carry the mislabel.

**Blocking-target verdict: P-01 blocks the BD-185 RESTART, not the v11.0 launch-as-CI-gate.** Evidence:
- The defect is in **comments only** — `validate-pack.py` runtime logic and `test-issue-forms.sh` assertions are version-neutral and correct (reconciled list P-01 "do not touch" notes). So CI is GREEN with the mislabel present; the v11.0 CI gate does NOT fail on P-01. P-01 is therefore NOT a hard CI-launch blocker.
- It IS a BD-185-restart blocker because it is the **exact mis-versioning that fractured the prior attempt** (landscape §1): a restart that inherits "phase-parts = v11.1" comments in the validator it extends would re-seed the fracture. The restart's baseline must be mislabel-free.
- **Conclusion:** P-01 blocks **the BD-185 restart** (Slice-1 gate). It is a v11.0-quality defect (BLOCKER-rated for being CI-executing tracked contamination) but not a CI-failing launch gate. Assign to **Slice 1**; mark **first fix in Slice 1** (per the user's "resolve BLOCKERs first within their slice").

### 4.2 What P-02 actually blocks

**P-02** = the fictional `templates-archive/v11.1/` cut (INDEX.md + forms/work-item.yml + phase-part-v11.1/SCHEMA.md). Measured live at `add50de` (§7 EB-2): all 3 files present.

**Blocking-target verdict: P-02 blocks the BD-185 RESTART specifically, via the SCHEMA relocation.** Evidence:
- `phase-part-v11.1/SCHEMA.md` is the **SOLE live home of the user-approved phase-part grammar** (reconciled list P-02: "GRAMMAR SUBSTANCE is user-approved and FIXED … the SOLE live home"). A BD-185 restart that builds phase-parts MUST read this grammar from a correctly-versioned v11.0 location, not a fictional v11.1 cut.
- No script consumes the SCHEMA path (reconciled list P-02: "No script consumes the SCHEMA path (verified) — zero code-consumer blast radius"), so P-02 does NOT block CI or any runtime — it blocks only the BD-185 restart's need for a clean, correctly-located grammar source.
- **Conclusion:** P-02 blocks **the BD-185 restart**. Assign to **Slice 1**; mark **second fix in Slice 1** (after P-01; gated by its own preconditions below).

### 4.3 P-02's hard preconditions + couplings (load-bearing sequencing)

P-02 cannot be executed cleanly until its mechanics land first:

1. **OQ-8 / P-13 (precondition) — normalize bare archive paths FIRST.** The §10 / PLAN-V2 §6 recipes that drive the P-02 fix cite bare `templates-archive/...` paths (20 in V2, 12 in PLAN-V2 — re-measured live at `add50de`, §7 EB-3). A coder executing those recipes against a literal path would fail (no repo-root `templates-archive/`). **P-13 MUST land before P-02** (OQ-8 is a sequencing precondition, not a user decision). This is why P-13 sits in Slice 1 as a precondition mechanic.
2. **P-08 coupling — reverse the blessing in lock-step.** The BD-193 Phase-5 S-1 edits + Phase-4 §3.1.2 "CONFIRMED-CORRECT" verdict blessed the v11.1 cut; when P-02 retires `v11.1/INDEX.md`, P-08's blessing language is a correction-target that must be addressed (reconciled list P-08 coupling).
3. **P-12 coupling — SCHEMA-relocation ENCODING lock-step.** Once P-02 relocates the SCHEMA into `v11.0/phase-part-v11.0/SCHEMA.md`, `check_template_archive_v11()` must add `phase-part` as the 6th entry type (P-12) in the same lock-step. Touches `scripts/` → manifest regen + per-check tests.

**Slice-1 fix ordering (sequencing claim, evidence in §7):** P-13 (path normalization) → P-01 (validator/test comments) → P-02 (archive relocate/retire) + P-12 (validator 6th type, lock-step) + P-08 (blessing reversal, lock-step) → P-16/P-17/P-18/P-09 (BD-185 record disposition, gated on OQ-1/OQ-3) → P-31a/P-31b/P-31k (framing/cosmetic, ride the archive + design-doc passes). The two BLOCKERs (P-01, P-02) are first/second per the user's "BLOCKERs first within their slice," with P-13 as the unavoidable precondition mechanic ahead of P-02.

### 4.4 Net BLOCKER verdict for the re-scope

**Neither BLOCKER blocks the v11.0 CI launch gate today** (both are comment/archive-only; CI is green). **Both block the BD-185 restart.** Therefore both belong to **Slice 1**, and **Slice 1 is the slice that gates BD-185.** Slice 2 contains NO BLOCKER and does not gate the restart — it is v11.0-launch-quality cleanup that can proceed in parallel with or after Slice 1 without affecting the BD-185 timeline.

---

## 5. Open-decision distribution + sequencing (ASSIGNED, not answered)

12 open decision items: 7 fully-open OQ (OQ-1, OQ-2, OQ-4, OQ-5, OQ-6, OQ-7) + OQ-8 (precondition) + OQ-3 (partial — provenance half tree-resolved, disposition half open) + 4 NQ (NQ-1…NQ-4). Each is assigned to a slice and sequenced. **This design does NOT answer any of them** — the user resolves per-slice, after this design, per the agreed plan. Boundary-class items are flagged for the `boundary-investigation` discipline at resolution time.

| Decision | Topic | Slice | Sequence position | Boundary-class? | Why this slice / sequence |
|---|---|---|---|---|---|
| **OQ-8** | Normalize bare archive paths before P-02 | **1** | **FIRST in Slice 1** (before P-02 fix-design) | No (sequencing precondition) | Hard mechanic: P-13 must land before any coder executes the P-02 recipe (§4.3). Not a user decision — a fixed ordering. |
| **OQ-3** | Disposition of `PACK-REVIEW-BD-185-H.2.md` (track/prison/leave) | **1** | After P-01/P-02 fix-design, before Slice-1 record-disposition | No (disposition call) | The provenance half is tree-resolved (P-09 tracked at `3bef42b`, §7 EB-3); only the track-vs-prison-vs-leave half remains — a Step-9-adjacent disposition the user makes within Slice 1. |
| **OQ-1** | Prison stale-ref: per-doc edits vs Pattern-B ship-sweep | **1 + 2** | Per-slice: Slice-1 instances (P-09/P-17/P-18) before Slice-1 record disposition; Slice-2 instances (P-14/P-15/P-21/P-25) before Slice-2 fix-design | No (policy) | The policy spans both slices' prison stale-refs. Resolve the BD-185-record subset (P-09/P-17/P-18) in Slice 1; the non-BD-185 subset (P-14/P-15/P-21/P-25) in Slice 2. One policy, applied per-slice. |
| **NQ-1** | Re-anchor reconciled-list rule citations to post-BD-196 slugs/RATIONALE | **1 + 2** | **FIRST, before ANY fix-design pass in EITHER slice** | No (mechanic) | Both slices' fix recipes cite pack-memory rules by OLD prose/location (BD-196 C1/C2 reshaped them). Any Slice-1 or Slice-2 fix-design that quotes old rule text fails to resolve. Re-anchoring tax is paid once, up front, ahead of both slices' Step-5 equivalent. |
| **NQ-2** | Strike P-29a from the active work-surface (closed by BD-196) | **(neither)** | At re-scope finalization (Pack Chat, when authoring entries) | No (bookkeeping) | P-29a is CLOSED; it must not be carried into either slice's problem set. Bookkeeping for Pack Chat at entry-authoring time; recorded here so neither slice's fix-design re-implements a CI-enforced §6. |
| **NQ-3** | Are BD-196's new surfaces in-scope for BD-195's defect classes? | **2** | Before Slice-2 fix-design closes | No (scope) | BD-196 introduced 5 new surfaces (manifests, RATIONALE, allowlist) + Checks 44/45/46, unaudited by R1–R9. Scope question is broad-cleanup-class (does "pristine" require sweeping them) — lives in Slice 2, the broad-cleanup slice. |
| **NQ-4** | `CONCEPTUAL-AREA-CUSTOMIZATION-PRESERVATION.md` location-vs-subject (sharpens P-29c) | **2** | With P-29c fix-design | YES (boundary-investigation) | File lives at `v11-implementation/` but governs a project-side review methodology + cites wrong dir. Resolution requires `boundary-investigation` (is the SSOT pack-side or project-side?). Rides P-29c in Slice 2. |
| **OQ-2** | `BD-NNN` admission in tracker phase-task grammar: leak or fidelity? | **2** | With P-30b fix-design | YES (boundary-investigation) | Client-authoring-surface-vs-migration-fidelity is a pack/project boundary call (`feedback_bd_pack_only_operational_rule` vs round-trip fidelity). Flag for `boundary-investigation`; do not pre-decide. Slice 2 (P-30b). |
| **OQ-4** | v9-auditor seed-set currency in client `PACK-FEEDBACK.md` | **2** | With P-19 fix-design | Mild (project-side content) | Project-side content decision (is the v9-era Q1–Q6 seed still the v11 seed). Rides P-19 in Slice 2. |
| **OQ-5** | `project-template/README.md`: ship to clients or relabel pack-maintainer-only? | **2** | With P-29f fix-design | YES (boundary-investigation) | Ship-vs-relabel is a pack/project deliverable-boundary call (does this README belong on the client surface). Flag for `boundary-investigation`. Slice 2 (P-29f). |
| **OQ-6** | Xcode Codex companion: support sub-agents or strip the blocks? | **2** | With P-28 fix-design | Mild (product capability) | Companion-template capability decision (ship `agents/` dir vs strip `[agents.*]`). Product-surface; rides P-28 in Slice 2. |
| **OQ-7** | v9→v10 sunset-artifact scrub policy on live user-facing surfaces | **2** | With P-24 fix-design | No (policy) | Scrub-vs-retain-as-historical policy for sunset artifacts. User-facing-currency class; rides P-24 in Slice 2. |

**Sequencing summary (the load-bearing ordering claims):**
1. **NQ-1 is paid FIRST, ahead of both slices' fix-design.** It is the re-anchoring tax: the reconciled list cites pre-BD-196 rule prose; both slices' Step-5-equivalent fix-design must quote post-BD-196 slugs. Doing it once up front avoids re-paying it per slice.
2. **NQ-2 is bookkeeping at entry-authoring** (Pack Chat strikes P-29a so neither slice re-implements a closed finding).
3. **Within Slice 1:** OQ-8 (P-13 normalization) FIRST → then the BLOCKER fixes (P-01, P-02) → then OQ-3 + OQ-1(Slice-1 subset) gate the BD-185-record disposition (P-09/P-16/P-17/P-18).
4. **Within Slice 2:** OQ-1(Slice-2 subset), OQ-2, OQ-4, OQ-5, OQ-6, OQ-7, NQ-3, NQ-4 each ride their owning P-NN's fix-design; the four boundary-class ones (OQ-2, OQ-5, NQ-4, plus mild OQ-4/OQ-6) get `boundary-investigation` at resolution.

**Boundary-class flag (do-not-pre-decide).** Per the BD/pack-self boundary-discipline rule, OQ-2, OQ-5, and NQ-4 are pack/project boundary calls requiring `boundary-investigation` at resolution time (investigate whether a project-side SSOT exists before reaching for a pack-style default). OQ-4 and OQ-6 are milder project-side/product content calls. This design SURFACES + ASSIGNS + SEQUENCES them; it does NOT resolve them.

---

## 6. Proposed BD structure + path to the BD-185 restart

### 6.1 Recommended representation (PROPOSE only — no BD numbers, no entries)

**Proposal: BD-195 is re-scoped down to Slice 1; a NEW BD carries Slice 2.** Concretely:

- **BD-195 (re-scoped) = SLICE 1 — BD-185-restart precondition.** Keep the BD-195 identity, alias "Code Red 3," and its position as "precedes the BD-185 restart." Narrow its Goal/Scope/Steps to the 12 Slice-1 problems + the Step-9 disposition gate. This preserves the BD's load-bearing relationship: BD-195 has ALWAYS been "the thing that gates BD-185," and Slice 1 IS exactly that gate. BD-185's `Paused: … BD-195 Step 9 decides wipe-vs-salvage` line stays VALID with no edit — BD-195 still owns Step 9.
- **NEW BD (Pack Chat assigns the number) = SLICE 2 — broad v11.0 repo cleanup.** A fresh BD for the 36 non-gating cleanup problems. It does NOT gate BD-185. Its position is "v11.0-launch-quality; parallelizable with or after BD-195 Slice 1." It carries the 2 pack-rule-corpus items + all project-side/product/other cleanup.

**Why this shape (vs alternatives):**
- **vs sub-tracks under one BD-195:** rejected. Sub-tracks keep the 3:1-larger broad cleanup chained to the BD-185 gate, defeating the whole point of Option C (decouple the broad cleanup from the narrow BD-185 decision). A separate BD lets Slice 2 proceed on its own cadence without holding the BD-185 restart hostage to 36 cleanup fixes.
- **vs BD-195 = Slice 2 + new BD = Slice 1:** rejected. BD-195's existing identity, alias, BACKLOG position, and BD-185's pause-line all point at "the gate before BD-185." Moving the gate to a new number and leaving the broad cleanup on BD-195 would invert every existing cross-reference (BD-185 pause-line, BD-195 Position line, the execution plan's Step-9 contract). Keeping BD-195 = the gate (Slice 1) preserves all of them.
- **vs keeping one BD-195 with both slices (no split):** rejected — that is the status quo Option C exists to dissolve.

**This is a PROPOSAL.** Pack Chat (PM-only) assigns the new BD number (read the live BACKLOG for the highest BD-NNN first, per CLAUDE.md), authors both entries, edits the BD-195 entry to the narrowed scope, and flips the BD-185 pause-line only if it requires update (it likely does NOT — see §6.3). The architect does not assign numbers or write BACKLOG entries.

### 6.2 Does the fix pipeline (Steps 5–8) run per-slice?

**Yes — each slice runs its own Steps 5–8 (architect fix-design → fix-implementation plan → implement → review), but they share the NQ-1 re-anchoring done once up front.** Rationale:
- The PLAN-BD-195-EXECUTION pipeline (Steps 5–8) is defined for "ALL surfaced problems." Splitting into two BDs means each BD runs its own 5–8 cycle scoped to its slice's problem set. This is cleaner than one giant 5–8 over all 48 — it lets Slice 1 (small, gating, BLOCKER-bearing) complete and unblock BD-185 WITHOUT waiting for Slice 2's 36-problem cleanup.
- **NQ-1 (re-anchor rule citations) is paid ONCE, before either slice's Step 5** (§5 sequencing). It is not per-slice work — it is a one-time correction to the shared reconciled-list substrate both slices' fix-design reads from.
- **Slice 1's Steps 5–8** are small: ~12 problems, dominated by the 2 BLOCKERs + their mechanics (P-13/P-12/P-08) + the BD-185-record disposition (gated on OQ-3/OQ-1). The bounded review/fix cycle (max 2 review/fix pairs + 1 final reviewer per commit) applies.
- **Slice 2's Steps 5–8** are large (36 problems) but contain no BLOCKER and no BD-185 entanglement — a standard broad-cleanup batch (or several sub-batches), each problem riding its assigned OQ/NQ.

### 6.3 Which slice unblocks the BD-185 restart + the path from here

**Slice 1 (re-scoped BD-195) gates the BD-185 restart.** The path:

1. **Pack Chat finalizes the re-scope** (PM-only): assign the new Slice-2 BD number; author the new entry; narrow the BD-195 entry to Slice 1 + Step 9; strike P-29a (NQ-2). BD-185's pause-line needs NO edit — BD-195 still owns the Step-9 wipe-vs-salvage gate.
2. **NQ-1 re-anchoring** (one-time, ahead of both slices' fix-design).
3. **BD-195 (Slice 1) runs Steps 5–8** scoped to the 12 problems: OQ-8/P-13 first → P-01 → P-02 (+P-12/P-08 lock-step) → OQ-3/OQ-1-Slice-1-subset gate the BD-185-record disposition (P-09/P-16/P-17/P-18) → P-31a/b/k cosmetic. Reviews per the bounded cycle.
4. **BD-195 Step 9 fires** — the pristine baseline NOW exists for the BD-185-relevant surfaces (the epicenter is clean, the records are disposed). Step 9 runs as specified in PLAN-BD-195-EXECUTION §"Step 9": pure user decision, wipe vs salvage, complete-redo bias. **This is the terminal BD-195 gate and the BD-185-restart unblock.**
5. **BD-185 restarts** (separate BD) seeded by the Step-9 decision + Retained-Decisions doc.
6. **Slice 2 (new BD) runs Steps 5–8 in parallel or after** — it does not gate any of the above. v11.0 reaches full pristine when both slices complete.

**Critical reconciliation with the landscape doc's framing-gap.** Landscape §6.1 flagged that "Step 9 as specified cannot run yet" because its precondition ("after Steps 1–8, v11.0 is pristine") is unmet. This re-scope RESOLVES that gap for the BD-185 axis: Step 9's true precondition is not "the WHOLE repo is pristine" but "the BD-185-relevant surfaces are clean and the BD-185 records are disposed" — which is exactly **Slice 1 complete**. The broad cleanup (Slice 2) was never a genuine Step-9 precondition; it was bundled in by the original whole-repo scope. Decoupling it (Option C) lets Step 9 run after Slice 1 alone. The re-scope thus makes Step 9 executable without waiting for the 36-problem broad cleanup.

---

## 7. Empirical-Evidence Blocks

All measurements 2026-05-31 at HEAD `add50dec0c6ff48890c2069d268480e46f9f5f6a` (`add50de`), branch `v11-dev`.

**EB-0 — The audit-HEAD `c73077d` source claims carry to `add50de` (only a doc commit intervened).**
- *Command:* `git log --oneline c73077d..add50de | wc -l`; `git log --oneline c73077d..add50de`.
- *Output:* `1`; the single commit is `add50de docs: v11 — BD-195 re-audit (landscape + post-BD-196 refresh) + correct entry state … (pack-only)`.
- *Interpretation:* The only commit between the audit HEAD and the current HEAD is the audit-doc + BACKLOG-state commit itself (pack-only, doc-only). No `scripts/`, `project-template/`, `maintenance-docs/v11-research/`, `pack-ops/` runtime source surface changed, so the three audits' source-tree classifications (slice tags, P-NN liveness) are valid at `add50de`.
- *Conclusion:* SUPPORTED.

**EB-1 — P-01 (BLOCKER) live at `add50de`; comments-only, CI-green.**
- *Command:* `grep -n "v11.1" scripts/validate-pack.py`; `grep -c "v11.1" scripts/tests/test-issue-forms.sh`.
- *Output:* `scripts/validate-pack.py` L1086 "added at v11.1 (BD-185 H.2)", L1121 "added at v11.1 (BD-185 H.2)", L1123 "introduced at v11.1"; `test-issue-forms.sh` → `6`. All three validator hits are inside comments/docstring (the `# …` and docstring lines); runtime dict + test assertions unaffected.
- *Interpretation:* P-01 is STILL-LIVE at `add50de`. The mislabel is comment-only — CI does not fail on it. Supports §4.1: P-01 blocks the BD-185 restart (must not inherit), not the CI launch gate.
- *Conclusion:* SUPPORTED (Slice 1, first fix; blocks BD-185 restart, not CI).

**EB-2 — P-02 (BLOCKER) live at `add50de`; archive-only, no script consumer.**
- *Command:* `find maintenance-docs/v11-research/templates-archive/v11.1 -type f`.
- *Output:* `…/v11.1/INDEX.md`, `…/v11.1/forms/work-item.yml`, `…/v11.1/phase-part-v11.1/SCHEMA.md`.
- *Interpretation:* P-02 is STILL-LIVE at `add50de`; the fictional v11.1 cut is intact, including the SOLE live home of the phase-part grammar (`phase-part-v11.1/SCHEMA.md`). Supports §4.2: P-02 blocks the BD-185 restart's clean grammar source; no CI/runtime consumer → not a CI launch gate.
- *Conclusion:* SUPPORTED (Slice 1, second fix; blocks BD-185 restart).

**EB-3 — P-02 precondition mechanics (P-13 bare paths) live at `add50de`; P-09 tracked (provenance half resolved).**
- *Command:* `grep -c "templates-archive/v11" maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md maintenance-docs/v11-implementation/PLAN-BD-185-V2.md`; `git log --oneline --diff-filter=A -- maintenance-docs/v11-implementation/PACK-REVIEW-BD-185-H.2.md | wc -l`.
- *Output:* `ARCHITECTURE-BD-185-V2.md:20`, `PLAN-BD-185-V2.md:12`; P-09 add-count `1` (single add at `3bef42b`).
- *Interpretation:* P-13 is STILL-LIVE (32 bare-path occurrences across the two recipe docs) — supports §4.3: P-13/OQ-8 must land before P-02. P-09 has exactly one add commit → no provenance ambiguity, no same-named variant → the OQ-3 provenance half is tree-resolved; only the disposition half (track/prison/leave) is open (§5 OQ-3 assignment).
- *Conclusion:* SUPPORTED (P-13 = Slice-1 precondition mechanic, first; OQ-3 = disposition-half-only, Slice 1).

**EB-4 — Slice counts partition the 48 live problems exactly 12 + 36.**
- *Command:* manual tag of every live P-NN by gating-role (§2 table), cross-checked against the re-audit §3 surface tags.
- *Output:* Slice 1 = {P-01, P-02, P-08, P-09, P-12, P-13, P-16, P-17, P-18, P-31a, P-31b, P-31k} = 12 (= the re-audit's "BD-185-artifact 12" set exactly, no cross-tag moves). Slice 2 = the other 36 = 11 project-side + 8 product + 15 other + 2 pack-rule-corpus. 12 + 36 = 48. P-29a excluded (closed).
- *Interpretation:* The honest partition is 12 + 36 = 48; the re-audit's "12 vs 34" headline dropped the 2 pack-rule-corpus items, which belong to Slice 2. Surface-tag and gating-cut coincide for these 48 (the BD-185 epicenter is co-located with the BD-185 artifacts).
- *Conclusion:* SUPPORTED.

---

## 8. Rules-Applied Verification Block

| Rule (as named in prompt) | Verification evidence | Conclusion |
|---|---|---|
| Architect/planner state-claims require Empirical-Evidence Blocks | §7 EB-0…EB-4 back every load-bearing state-claim (audit-HEAD carry-over, P-01/P-02 liveness + CI-green, P-13 precondition count, P-09 single-add, the 12+36 partition) with command + verbatim output + HEAD `add50de` + date 2026-05-31 + interpretation + SUPPORTED. Slice assignments (§2) and BLOCKER-blocking-target claims (§4) and sequencing claims (§4.3/§5) each cite their EB. The re-audit's slice tags were re-verified, not trusted: the load-bearing source claims re-measured at `add50de` (EB-1/EB-2/EB-3); the "34 vs 12" headline was independently recounted (EB-4) and corrected to 12+36. | COMPLIANT |
| Pattern-matching out of context is an anti-pattern | §1.2 explicitly rejects the surface-name reflex: problems are assigned by gating-role (what fixing GATES), not by surface-name. P-13 (BD-185-artifact surface) is assigned to Slice 1 as a precondition mechanic for P-02, not by surface reflex; the §1.3 cut is justified by gating-role evidence, and the coincidence with the surface tag is stated as a non-obvious result (EB-4), not assumed. | COMPLIANT |
| Preliminary-triage + architect-challenge | §1.1–§1.4 treats the re-audit's 5-way tag + "34 vs 12" headline as PRELIMINARY and challenges it: re-derives the cut by gating-role (§1.2), reconciles the dropped 2 pack-rule-corpus items (§1.4, EB-4), and corrects the ratio to 3:1 (§3). The cleaner "gating-role" cut was designed and justified; it happened to coincide with the surface tag for these 48, which is reported, not assumed. | COMPLIANT |
| BD/pack-self boundary discipline + boundary-investigation | §5 flags OQ-2, OQ-5, NQ-4 as boundary-class requiring `boundary-investigation` at resolution (with OQ-4/OQ-6 mild); none is pre-decided. The design does not reach for a pack-style default on any project-side call. | COMPLIANT |
| No-recommendation on the deferred OQ/NQ answers | §5 ASSIGNS + SEQUENCES all 12 decision items (7 OQ + OQ-3 partial + OQ-8 precondition + 4 NQ) to slices, but answers none — each row gives slice + sequence + boundary-flag, never a chosen resolution. The disposition (Option C) was a fixed input, not re-litigated (§ header). | COMPLIANT |
| Agent output requires Rules-Applied Verification Block | This table. | COMPLIANT |
| Agents never commit / no destructive ops | All tool actions read-only (Read, grep, find, ls, git log/rev-parse/branch) + the single authorized Write to this report path (append-only `cat >>`; no edit to any other file; no `git add/commit/push/tag`; no `rm`/`mv`). No BD numbers assigned; no BACKLOG entry written (PM-only, left to Pack Chat). | COMPLIANT |
| PRISON RULE (membership noted, not imported) | Prison docs referenced only as STATE (e.g., P-09/P-17/P-18 anchor to prisoned docs; P-14/P-15/P-21/P-25 cite prisoned docs) to establish stale-ref liveness and slice assignment; no prison doc read as guidance or cited as a live source. | COMPLIANT |
| STOP-MEANS-STOP | No parent stop/halt/revert issued; work proceeded to the single authorized deliverable. | COMPLIANT (N/A trigger) |

**End of ARCHITECTURE-BD-195-RESCOPE.md.**
