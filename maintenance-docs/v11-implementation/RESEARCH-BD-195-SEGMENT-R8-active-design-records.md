# RESEARCH-BD-195-SEGMENT-R8-active-design-records

**Author:** pack-docs-researcher (read-only audit segment R8). **Date:** 2026-05-29.
**Branch:** v11-dev. **Repo HEAD at pass:** (read-only; not state-changed).
**Categorical fact applied (not re-litigated):** v11.0 UNRELEASED, never frozen;
phase-parts always v11.0; GH Projects + groupings legitimately v11.1+.

## Segment / owned paths (manifest)

Owned: `maintenance-docs/v11-implementation/` and `maintenance-docs/v11-research/`
docs NOT in R7's epicenter (BD-185 / BD-193 / BD-194 + groupings + templates-archive),
NOT under `prison/` or `archive/`, NOT BD-195 workflow artifacts; PLUS loose
`maintenance-docs/*.md` (TOOL-COMPARISON, VERIFIED-NOTES, RECOMMENDATIONS, V10-*,
origins/, guides/).

EXCLUDED (read for context only, no findings filed): all `prison/` (out of scope);
`archive/` (R9); BD-185/193/194 + groupings + templates-archive (R7); BD-195
workflow artifacts `PLAN-BD-195-*`, `AUDIT-BD-195-*`, `RESEARCH-BD-195-SEGMENT-*`.

## Coverage attestation

- Full read: `ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` (header + §A), all four untracked
  pre-19c docs (`ARCHITECTURE-PRE-19C-SALVAGEABILITY.md`,
  `ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md`, `ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY.md`,
  `AUDIT-PRE-19C-BOUNDARY-LEAKS.md`) headers, `TOOL-COMPARISON.md` (head + tail +
  all ref lines), `CONCEPTUAL-AREA-CUSTOMIZATION-PRESERVATION.md`, `EXECUTION-PLAN-V11.0.md`
  (header + version lines), `RECOMMENDATIONS.md`, `VERIFIED-NOTES.md`, V10-* headers,
  the V3.x-DELTA chain headers + supersession tables, the per-entry-split chain ref lines.
- Cross-reference resolution: ran a repo-wide grep of every prisoned-doc basename against
  the owned tree (prison membership is the dominant stale-ref source this segment surfaces,
  because the SUPERSEDED-MAP was authored when "the prison directory does not yet exist").
- Whole-tree greps for `v11.1` / `frozen` / `V3.2` / each prisoned basename across owned paths.
- Skimmed (enumerated, header-checked, not full-body-read): the ~60 BD-NNN IMPL-REPORTs /
  PACK-REVIEWs for resolved pre-19c BDs (BD-032..BD-169 family) — these are completed-batch
  workflow artifacts; headers confirmed historical labeling; spot greps for version/prison
  defects came back clean except where noted. Basis for skim: Pattern B sweep-at-ship + low
  defect density on header inspection.

## Findings count: BLOCKER 0 / MUST 0 / SHOULD 5 / NIT 4

---

## Findings

### R8-F01 — Live concept-scope doc cites CONCEPTUAL-REVIEW-METHODOLOGY.md at the wrong directory
- Severity: SHOULD
- Category: C (cross-reference / stale path) + filename-uniqueness
- Surface(s): `maintenance-docs/v11-implementation/CONCEPTUAL-AREA-CUSTOMIZATION-PRESERVATION.md` (line 3 header + the §"Trial review steps" item that re-cites it; both cite `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`)
- Side: maintenance-doc (live — trial review "scheduled after Batch 21b ships, before Batch 22")
- Evidence: Header: *"**Concept-scope doc** for the conceptual review methodology described in `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`."* and later *"Cite the methodology doc (`supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`)"*. The file actually lives at `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (`supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` does not exist; `ls` confirms only the `pack-ops/` copy).
- Why it's a problem: Cross-reference does not resolve at the cited location — this is a live doc (it governs a not-yet-run trial review), so the broken path is load-bearing, not historical. The SUPERSEDED-MAP §3 records that the methodology doc's placement was set to `pack-ops/` per `AUDIT-USER-CURATION.md` Override 6, so the `supporting-docs/` path is a stale pre-Override-6 location. Violates the CLAUDE.md filename/path-resolution expectation (a reader must be able to follow a cited path).
- Recommendation: Re-point both citations to `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`.
- Cross-segment touch points: none (target doc is pack-ops; not an R7/R9 owned doc).
- Confidence: high (filesystem-verified: file exists only at `pack-ops/`).

### R8-F02 — EXECUTION-PLAN-V11.0 status line is stale ("Awaiting user review before any commits")
- Severity: SHOULD
- Category: A (version/status currency)
- Surface(s): `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` (line 4 Status)
- Side: maintenance-doc (live planning surface)
- Evidence: *"**Status:** Drafted 2026-05-09. Awaiting user review before any commits."* The doc body has since been updated through 2026-05-25 — it sequences BD-189 ("added 2026-05-24 per user direction") and BD-192 ("added 2026-05-25"), and many BDs it sequences are now `Status: Resolved` in BACKLOG (BD-162, BD-095, BD-101, BD-111, BD-173, etc.). Commits have plainly happened.
- Why it's a problem: A live execution-plan whose status asserts "no commits yet / awaiting first review" misrepresents the actual state to any reader using it for sequencing. The labeling-vs-reality gap is exactly the "masquerading" risk this segment's core question targets, on the single most load-bearing live planning doc.
- Recommendation: Update the Status line to reflect actual state (in-flight; last-updated date; which groups have landed). At minimum bump the date and drop "Awaiting user review before any commits."
- Cross-segment touch points: none.
- Confidence: high (BACKLOG statuses + in-doc BD-189/BD-192 dates contradict the line).

### R8-F03 — RECOMMENDATIONS.md is a v9-era doc with no deprecation/currency banner, presented as current by README
- Severity: SHOULD
- Category: A (version) + B-adjacent (client-facing exposure) + labeling
- Surface(s): `maintenance-docs/RECOMMENDATIONS.md` (whole doc); compounded by `README.md` Repository Layout (lists it as *"Practical recommendations for new projects"* with no era qualifier)
- Side: maintenance-doc (root, undated) + cross (README)
- Evidence: Doc line 1-2: *"Practical recommendations for new projects using the AI Agent Config Pack v9."* No Status line, no date, no "Last verified", no successor pointer. README presents it alongside current files: `RECOMMENDATIONS.md  Practical recommendations for new projects`.
- Why it's a problem: The segment core question is whether deprecated docs are clearly labeled vs masquerading as current. This doc is explicitly scoped to pack **v9** yet sits at the live `maintenance-docs/` root with zero deprecation marker and is advertised by README as a current top-level reference. A reader has no signal it predates v11. (Contrast: every V10-* doc and TOOL-COMPARISON carry explicit Status/date headers.)
- Recommendation: Either add a deprecation/era banner ("v9-era; retained for history; see TOOL-COMPARISON.md / current methodology for v11") or move it to `archive/`. Whichever is chosen, fix the README description to not present a v9 doc as current.
- Cross-segment touch points: README.md edit is cross (R9/whole-repo); flag only.
- Confidence: high (in-doc "v9" + absence of any currency marker).

### R8-F04 — VERIFIED-NOTES.md carries undated CLI capability facts with no currency anchor
- Severity: NIT
- Category: A (version) + labeling + CLI-fact currency
- Surface(s): `maintenance-docs/VERIFIED-NOTES.md` (whole doc)
- Side: maintenance-doc (root)
- Evidence: Bullets assert tool facts ("Claude Code supports project instructions, settings, hooks, subagents, and skills", "Codex supports layered `AGENTS.md`...", "Xcode 26.3 uses separate customization directories...") with per-bullet "Source:" attributions but NO date, NO Status, NO "Last verified". CLI tools change frequently (per pack-docs-researcher standing guidance), so undated capability claims silently rot. README lists it as *"Verified facts from official docs."*
- Why it's a problem: Lens-A currency: a verified-facts doc with no verification date cannot be trusted for currency; TOOL-COMPARISON.md sets the right pattern with explicit "Last verified: April 2026 — verify currency before relying." This doc lacks the analogous guard.
- Recommendation: Add a "Last verified: <date>; verify currency before relying" header (matching TOOL-COMPARISON's convention), or fold it into TOOL-COMPARISON and deprecate.
- Cross-segment touch points: README.md description (cross).
- Confidence: medium (the facts may be accurate; the defect is the missing currency anchor, not a verified wrong fact).

### R8-F05 — TOOL-COMPARISON.md points at GEMINI-CLI-ANALYSIS.md / ANDROID-ANALYSIS.md at their pre-prison path
- Severity: NIT
- Category: C (stale path — prison)
- Surface(s): `maintenance-docs/TOOL-COMPARISON.md` (lines 5-6 "Supersedes:" header; lines 217-219 "Deprecated analysis documents")
- Side: maintenance-doc (live reference)
- Evidence: L5-6 *"Supersedes: GEMINI-CLI-ANALYSIS.md and ANDROID-ANALYSIS.md. Deprecation notices are added to those files in Step 2 of V9-DESIGN.md."* L217-219 *"`maintenance-docs/GEMINI-CLI-ANALYSIS.md` — content absorbed here / `maintenance-docs/ANDROID-ANALYSIS.md` — content absorbed here / Both files remain in the repo for historical reference..."* Both files are now at `maintenance-docs/prison/`, not `maintenance-docs/`; and `V9-DESIGN.md` is at `archive/`, not root.
- Why it's a problem: Per the BD-195 prison rule, in-tree references should point AWAY from prisoned docs, never describe them as live "in the repo for historical reference" at a path where they no longer sit. The supersession FACT is correct; the path and the "remain in the repo for historical reference" framing are now stale (the docs were quarantined, not retained-as-history). Low severity because the doc is supersession provenance.
- Recommendation: Update the references to note these are superseded-and-prisoned (or drop the path and keep only the "content absorbed here" statement). Do not cite the prison path as a live reference.
- Cross-segment touch points: GEMINI-CLI-ANALYSIS.md / ANDROID-ANALYSIS.md are prison (out of scope; do not edit). TOOL-COMPARISON edit is in-scope.
- Confidence: high (prison membership + path verified).

### R8-F06 — Completed-batch 19c workflow artifacts forward-reference now-prisoned 19c V1 / PRINCIPLE-CHECK / DISCARDED as live inputs
- Severity: SHOULD
- Category: C (stale-ref — prison) + E (lock-step: supersession map authored pre-prison)
- Surface(s): `ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` (line 7 "**Supersedes:** V1 at ...ARCHITECTURE-CLEANUP-BATCH-19C.md and its PRINCIPLE-CHECK sidecar... V1 is retained as a historical input"; §A.2 items 1-9 cite PRINCIPLE-CHECK); `ARCHITECTURE-PRE-19C-SALVAGEABILITY.md` (Scope line cites `ARCHITECTURE-CLEANUP-BATCH-19C.md` V1 + PRINCIPLE-CHECK as assessment targets); `AUDIT-PRE-19C-BOUNDARY-LEAKS.md`, `ARCHITECTURE-BATCH-19B-STRATEGIC-PRINCIPLES.md`, `RESEARCH-BATCH-19B-STRATEGIC-RULES.md` (all cite V1 / DISCARDED / PRINCIPLE-CHECK); `PLAN-CLEANUP-BATCH-19C.md`, `RESEARCH-19C-G-ITEMS-VERIFICATIONS.md`, and the `IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.*` set (cite 19C V1)
- Side: maintenance-doc (workflow artifacts for the now-Resolved BD-173 / Batch 19c)
- Evidence: `ARCHITECTURE-CLEANUP-BATCH-19C-V2.md:7` *"V1 is retained as a historical input; V2 is the implementation-ready design from this point forward."* `ARCHITECTURE-CLEANUP-BATCH-19C.md`, `...-PRINCIPLE-CHECK.md`, `...-DISCARDED.md` are all now in `maintenance-docs/prison/`. BD-173 is `Status: Resolved`.
- Why it's a problem: Per `PLAN-BD-195-EXECUTION.md` prison rule ("A finding that references a prisoned doc as authoritative is a defect... a fix may RE-POINT an in-scope reference AWAY from a prisoned doc, never INTO one"), live in-tree docs treating a prisoned doc as a "retained historical input" or active assessment target are stale-refs. The SUPERSEDED-MAP (R5/R6) recorded these supersessions when "the prison directory does not yet exist," so the supersession chain now resolves into prison. NOTE: these are completed-batch workflow artifacts that CLAUDE.md schedules to sweep to `archive/v11/` at version ship (Pattern B); the cleanest remediation may be the ship-time sweep rather than per-doc edits.
- Recommendation: Two viable paths — (a) at version-ship Pattern-B sweep, move the whole 19c-family artifact set to `archive/v11/` together (preferred; they are Resolved-batch records); or (b) if any remains in `v11-implementation/` as a live reference, annotate the prisoned-doc citations as "superseded; now in `maintenance-docs/prison/`". Do NOT leave live docs describing prisoned docs as "retained historical input." User decides (a) vs (b).
- Cross-segment touch points: prison docs are out of scope (never edit). `ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` is the superseding doc and is NOT itself recorded as superseded (per SUPERSEDED-MAP R6) — it stays live until the sweep.
- Confidence: high (prison membership verified; BD-173 Resolved verified).

### R8-F07 — Per-entry-split + V3.x chain reference ARCHITECTURE-V3.2-DELTA.md as "remains in the directory" / authoritative-design input
- Severity: SHOULD
- Category: C (stale-ref — prison)
- Surface(s): `maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md` (§0 line 7 "supersedes ARCHITECTURE-V3.2-DELTA.md in full. V3.2 is a historical proposal"); `maintenance-docs/v11-research/ARCHITECTURE-REVIEW-PASS3.md` (§4.2 line ~200 "V3.2-DELTA itself remains in the directory as historical record"; line 21 `superseded-historical` row); `maintenance-docs/v11-research/RESEARCH-PER-ENTRY-SPLIT.md` (front-matter `authoritative-design:` line 7 lists V3.2; §"corpus" lines 73, 962); `maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` (line 193 cites it as a 506-line input); `REVIEW-RESEARCH-PER-ENTRY-SPLIT.md` (lines 35/40/366/410); `PACK-REVIEW-CUMULATIVE-V11-POSTSWEEP.md` (line 7 cross-ref list); `PACK-REVIEW-BD-106.md` (lines 369-373)
- Side: maintenance-doc (workflow + design records)
- Evidence: `ARCHITECTURE-REVIEW-PASS3.md` ~L200: *"V3.2-DELTA itself remains in the directory as historical record per the architect's stated intent (V3.3 §1 '...It is not deleted; it stands as the prior-pass record')."* `RESEARCH-PER-ENTRY-SPLIT.md:7` front-matter lists `V3.1/V3.2/V3.3-DELTA.md` under `authoritative-design:`. `ARCHITECTURE-V3.2-DELTA.md` is now in `maintenance-docs/prison/`, NOT in `v11-research/`.
- Why it's a problem: The supersession is correctly recorded (V3.2 → V3.3), but multiple in-tree docs assert V3.2-DELTA "remains in the directory" / list it as authoritative-design — both now false (prisoned). The `RESEARCH-PER-ENTRY-SPLIT.md` front-matter `authoritative-design:` line is the sharpest: it presents a prisoned doc as authoritative. Same prison-stale-ref class as R8-F06.
- Recommendation: Where a doc asserts V3.2-DELTA "remains in the directory," correct to "superseded by V3.3-DELTA; now in `maintenance-docs/prison/`." Drop V3.2 from any `authoritative-design:` enumeration (V3.3 is authoritative; V3.2 is superseded). The cross-ref/consulted-list mentions inside completed review artifacts may instead ride the Pattern-B ship sweep. User decides per-surface.
- Cross-segment touch points: `ARCHITECTURE-V3.2-DELTA.md` is prison (out of scope). The V3.x chain + per-entry-split docs are R8-owned.
- Confidence: high (prison membership verified; quotes verbatim).

### R8-F08 — D-22 row in V3.3-DELTA records project-side work-item.yml options (bd/td/phase-*-skeleton) later removed by BD-193; no overtaken-by note
- Severity: NIT
- Category: A (version drift) + B-adjacent (project-side form, deliverable-only — NOT a leak)
- Surface(s): `maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md` (§1 supersession table, D-4-V2 extension row: *"the dropdown reaches 4 options (bd / td / phase-epic-skeleton / phase-task-skeleton)"*)
- Side: maintenance-doc (frozen V3.3 design record)
- Evidence: D-4-V2 row: *"Reaffirmed in V3.3 — the form-family pattern is the right home... the dropdown reaches 4 options (bd / td / phase-epic-skeleton / phase-task-skeleton)..."* BD-193 (Resolved) later removed `bd` from project-side forms and the pack-memory deliverable-only rule removed `td`/`phase-*-skeleton` from pack-side self-management forms.
- Why it's a problem: This is NOT a boundary leak — it is a pack-side architect doc designing the project-side `work-item.yml` deliverable, which the deliverable-only rule explicitly ALLOWS. The only issue is staleness: the design point was overtaken by BD-193, and the V3.3 doc has no forward note. Low severity because it is a point-in-time, superseded-in-part design record, not a live form spec.
- Recommendation: Optional — add a one-line "overtaken by BD-193 (bd/td/phase-skeleton options removed)" addendum note if this chain is kept live; otherwise rely on the Pattern-B ship sweep. Do not treat as a leak.
- Cross-segment touch points: BD-193 form/validator state is R7's territory (the actual form files) — flag only.
- Confidence: medium (BD-193 removal is established in pack memory; exact current form contents not re-read this pass — that surface is R7's).

### R8-F09 — D16 "v11.0 archive structural shape frozen" wrapper recorded verbatim in Code-Red-2 BD-TD-path inventory
- Severity: NIT
- Category: A (categorical contamination wrapper) + cross-with-R7
- Surface(s): `maintenance-docs/v11-implementation/AUDIT-INVENTORY-BD-TD-PATH.md` (D16 row, line ~743)
- Side: maintenance-doc (Code Red 2 audit record)
- Evidence: *"**D16** (User-driven 2026-05-26): Convention Y — v11.0 archive intra-file additive-extension allowed; structural shape frozen at 5 subdirs."*
- Why it's a problem: The "v11.0 archive structural shape frozen" phrasing is the exact contamination wrapper that `AUDIT-BD-195-RETAINED-DECISIONS.md` "NOT RETAINED" §D16 flags ("the 'frozen' wrapper is NOT retained"). BD-195 corrects this: v11.0 archive is MUTABLE while v11.0 is unshipped. The inventory is a point-in-time Code-Red-2 record (it captured state as it then stood), so this is a low-severity historical-snapshot of the wrapper, not a live assertion driving current action.
- Recommendation: Likely no edit — this audit doc is a historical Code-Red-2 record and is closely coupled to the BD-185/BD-193 epicenter (R7). If R7 reconciles the BD-TD-path audits, the D16 row should adopt the corrected v11.0-mutable framing. Surface to R7 for ownership.
- Cross-segment touch points: `AUDIT-INVENTORY-BD-TD-PATH.md` + `AUDIT-DISPOSITION-BD-TD-PATH.md` are Code Red 2 (BD-185/BD-193) artifacts — primary ownership is arguably R7; I file only the contamination-wrapper observation here to avoid double-coverage.
- Confidence: high (matches the RETAINED-DECISIONS NOT-RETAINED §D16 directly).

---

## Cross-segment touch points (no R8 finding filed; flagged for the owning segment)

- `IMPLEMENTATION-REPORT-ADDENDUM-RESOLUTION-NOTES.md` — its entire scope is annotating
  `PLAN-BD-185-ADDENDUM.md` (now prisoned) resolution notes. BD-185 epicenter → R7.
- `AUDIT-DISPOSITION-BD-TD-PATH.md` / `AUDIT-INVENTORY-BD-TD-PATH.md` — Code Red 2
  (BD-185/BD-193 boundary cleanup) audits; reference BD-185.md (prisoned). Primary owner R7;
  R8 filed only the D16 contamination-wrapper note (R8-F09).
- `README.md` Repository Layout (lines ~161-162) lists `VERIFIED-NOTES.md` /
  `RECOMMENDATIONS.md` as current top-level references — compounds R8-F03 / R8-F04.
  README is whole-repo/R9 surface; flag only.
- The prisoned-doc supersession FACTS recorded in `AUDIT-BD-195-SUPERSEDED-MAP.md`
  (R3/R5/R6/R7/R8/R4 → V10-PREDESIGN, 19C V1+PRINCIPLE-CHECK+DISCARDED, BD-185 family,
  V3.2-DELTA) are the upstream basis for R8-F06 and R8-F07. The map is a BD-195 workflow
  artifact (exempt); R8 only consumes it.

## Clean-on-inspection (read, no defect found)

- `EXECUTION-PLAN-V11.0.md` body — all `v11.1` usages are legitimate user-authorized
  deferrals (BD-189 groupings, BD-192 PS, GH Projects); no phase-parts mislabeling, no
  "v11.0 frozen" assertion.
- `ARCHITECTURE-BATCH-19B-STRATEGIC-PRINCIPLES.md` / `RESEARCH-BATCH-19B-STRATEGIC-RULES.md`
  `v11.1` usages — all cite the "No deferral to v11.1+" RULE itself (correct).
- `V10-CODEX-MCP-RESEARCH.md`, `V10-GEMINI-CONFIG-RESEARCH.md`, `V10-MIGRATION-FIX-DESIGN.md`,
  `V10-MIGRATION-FIX-PLAN.md`, `V10-PROCEDURE-5-C-DRAFT.md` — all carry explicit
  Status + Date + BD-059 headers; clearly labeled v10-era; internal cross-refs resolve
  (same-dir). Placement-in-root-vs-archive is an R9/archive-policy question, not a labeling
  defect. No "frozen v11.0" / "v11.1 cut" contamination.
- `ARCHITECTURE-V3.1-DELTA.md`, `ARCHITECTURE-V3.md`, `ARCHITECTURE-V2.md`, `ARCHITECTURE.md`,
  `ARCHITECTURE-REVIEW.md`, `ARCHITECTURE-REVIEW-PASS2.md` — refinement chain (not whole-doc
  supersession); SUPERSEDED-MAP S1/S2 confirm NOT-superseded; no prison stale-ref beyond the
  V3.2 mentions captured in R8-F07.
- `ARCHITECTURE-SKILL-DIMENSIONS.md`, `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`,
  `ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md`, `ARCHITECTURE-SIDECAR-LIFECYCLE.md`,
  `RELEASE-GATE.md` — Status/date headers present; `v11.1`/`frozen` hits are legitimate
  (frozen API surface, version-tag fixtures). No version-contamination, no prison stale-ref.
- `ARCHITECTURE-BD-119.md`, `ARCHITECTURE-BD-176.md`, `ARCHITECTURE-BD-179.md`,
  `ARCHITECTURE-BD-182.md` — "frozen" = frozen public API / frozen historical migration doc;
  correct usage.

## Coverage map (owned path → status)

| Owned path (or group) | Status |
|---|---|
| `ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` | R8-F06 |
| `ARCHITECTURE-PRE-19C-SALVAGEABILITY.md` | R8-F06 |
| `ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` | clean (notes architect inline-return anomaly, self-documented; not a defect) |
| `ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY.md` | clean |
| `AUDIT-PRE-19C-BOUNDARY-LEAKS.md` | R8-F06 |
| `ARCHITECTURE-BATCH-19B-STRATEGIC-PRINCIPLES.md` | R8-F06 (prison refs); v11.1 usage clean |
| `RESEARCH-BATCH-19B-STRATEGIC-RULES.md` | R8-F06 |
| `RESEARCH-19C-G-ITEMS-VERIFICATIONS.md` | R8-F06 |
| `PLAN-CLEANUP-BATCH-19C.md` | R8-F06 |
| `IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.*` (set) | R8-F06 (prison V1 refs) |
| `CONCEPTUAL-AREA-CUSTOMIZATION-PRESERVATION.md` | R8-F01 |
| `EXECUTION-PLAN-V11.0.md` | R8-F02 |
| `RECOMMENDATIONS.md` | R8-F03 |
| `VERIFIED-NOTES.md` | R8-F04 |
| `TOOL-COMPARISON.md` | R8-F05 |
| `V10-*` (5 docs) | clean (historical labeling adequate) |
| `ARCHITECTURE-V3.3-DELTA.md` | R8-F07, R8-F08 |
| `ARCHITECTURE-REVIEW-PASS3.md` | R8-F07 |
| `RESEARCH-PER-ENTRY-SPLIT.md` | R8-F07 |
| `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` (+ ADDENDUM/-2) | R8-F07 |
| `REVIEW-RESEARCH-PER-ENTRY-SPLIT.md`, `REVIEW-*-PER-ENTRY-SPLIT*` | R8-F07 |
| `PACK-REVIEW-CUMULATIVE-V11-POSTSWEEP.md`, `PACK-REVIEW-BD-106.md` | R8-F07 |
| `AUDIT-INVENTORY-BD-TD-PATH.md` | R8-F09 (cross-with-R7) |
| `AUDIT-DISPOSITION-BD-TD-PATH.md` | cross-with-R7 (flag only) |
| `IMPLEMENTATION-REPORT-ADDENDUM-RESOLUTION-NOTES.md` | cross-with-R7 (BD-185) |
| `ARCHITECTURE-V3.1/V3/V2/V1`, `ARCHITECTURE-REVIEW(-PASS2)` | clean (refinement chain; not superseded) |
| `ARCHITECTURE-SKILL-DIMENSIONS.md`, `-SKILL-AGENT-MAINTAINABILITY.md` | clean |
| `ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md` + PLAN/RESEARCH/REVIEW/IMPL-REPORT | clean (BD-162 Resolved; labeled workflow artifacts) |
| `ARCHITECTURE-SIDECAR-LIFECYCLE.md` + IMPL-REPORT/REVIEW | clean |
| `RELEASE-GATE.md` | clean |
| `ARCHITECTURE-BD-119/176/179/182.md` + PLAN-BD-119 | clean |
| `AUDIT-BD-032/033/034/035.md` + their IMPL-REPORTs | skimmed clean (resolved pre-19c) |
| BD-048/078/079/095/096/101/106/107/108/111/116/117/118/120/122/129/130/131/133/150/160-170/163/164/165/166/167/167b/168/169 IMPL-REPORTs + PACK-REVIEWs | skimmed clean (resolved-batch workflow artifacts; historical labeling confirmed on header inspection) |
| `IMPLEMENTATION-PLAN.md` + ADDENDUM/-2/-3/-4 (`v11-research`) | clean (SUPERSEDED-MAP S6: not superseded; "unchanged at BD-content level") |
| `DESIGN-BRIEF.md`, `INTERNAL-INVENTORY.md`, `RESEARCH-AUDIT.md`, `MAINTAINER-CHECK-AUDIT-2026-05-07.md` (`v11-research`) | skimmed clean (early-design historical research) |
| `RESEARCH-CLAUDE-REPOS-SURVEY.md`, `RESEARCH-GRAPHIFY-*` (3) | skimmed clean (external research, labeled) |
| `PACK-REVIEW-BD060-070/062-069-071/065/066-068/072-074/075-077`, `PACK-REVIEW-CUMULATIVE-V11.md` (`v11-research`) | skimmed clean (resolved-batch reviews) |
| `maintenance-docs/origins/`, `maintenance-docs/guides/` | enumerated; origins/guides are historical-by-name; no live-masquerade or version contamination on inspection |

