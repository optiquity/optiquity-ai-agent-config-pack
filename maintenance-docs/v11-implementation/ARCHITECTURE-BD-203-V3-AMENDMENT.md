# ARCHITECTURE-BD-203-V3-AMENDMENT — pre-normalize the monolith; convert BD-001..019; flatten the version-grouping scaffolding

**Agent:** pack-architect · **Date:** 2026-06-04 · **Branch:** v11-dev · **HEAD (measured):** `c22d71c`
**Mode:** DESIGN-ONLY amendment to `ARCHITECTURE-BD-203-V3.md`. READ-ONLY pass — ONE markdown doc; no source edits, no git verb, no BACKLOG/CHANGELOG edit.
**Governing directive:** the user amendment of 2026-06-04 (D1–D4). It SUPERSEDES any stale BD-203 BACKLOG scope text; that entry is updated to match AFTER this amendment lands.
**Amends:** V3 §2.5 (Unblocked), §2.6 (`_rules.md`), §3.1 (`_intro.md`), §3.2 (v8-archive split — **reversed**), §5 (oracle/count), §6 (sequencing), §4 (STREAMS regex). Everything in V3 not named here STANDS.

---

## A. DECISION (lead)

**A1 — MECHANISM: PRE-NORMALIZE the monolith into uniform full entries FIRST, then run the existing decompose engine uniformly with zero special-casing.** I adopt the user's offered candidate and design it as the mechanism. A coder-agent edit pass rewrites `pack-ops/BACKLOG.md` in place so that (1) the 19 BD-001..019 summary-table rows become 19 real `**BD-00N — …**` full entries (Status: Resolved, with the commit hash carried as a one-line provenance field), and (2) all version-grouping scaffolding (`## Active — v11 Scope`, `## Active — v10 Scope`, `## Resolved — v8 (March 2026)`, `## Deferred`, the `## How to use this file` preamble bloat, and the per-section prose blurbs) is removed, leaving a flat list of uniform `**BD-NNN — …**` entries. THEN the V3 decompose engine (with the V3 widened anchor) runs against a monolith that has exactly ONE shape — full entries separated by `---` — and needs NO v8-archive pre-extraction, NO table special-casing, NO section-aware logic.

**A2 — This REVERSES V3 §3.2 (archive-the-table) per decision D3.** V3 sent BD-001..019 to `_v8-resolved-archive.md` (frozen history). D3 overrides: they are REAL resolved entries and become real per-entry files (`BD-001.md` … `BD-019.md`, Status: Resolved). `_v8-resolved-archive.md` is therefore NOT created; the `_v8-resolved-archive.md` supporting-file slot is RETIRED from the pack-backlog stream (see §F reconciliation). This is consistent with the fail-loud principle-2 nuance the prompt states: a numbered BD entry, however abbreviated, is an ENTRY (preserve as a per-entry file), NOT history to archive — only the table WRAPPER/section scaffolding is dropped.

**A3 — Post-conversion structure: a FLAT per-entry tree + a status-grouped regenerated TOC.** No version-grouping survives. Status lives in each entry's `Status:` line; the TOC (regenerated, the only organizational view) groups by Status. Version-era is recoverable from each entry's content/provenance, not from directory structure.

**Why pre-normalize beats decompose-time special-casing** (the user asked me to weigh it against the SAFE order + content oracle):
- **Zero special-casing in the engine.** Decompose-time handling would require the engine to recognize a table, a section mislabel, and a preamble — bespoke logic that serves exactly one input (the pack's own monolith) and then is dead. Pre-normalization keeps the shared engine uniform (the V3 design-elegance goal: fewer special cases) and means the SAME engine path the project conversion (BD-206) uses is exercised, not a pack-only branch.
- **The content oracle gets STRONGER, not weaker.** Pre-normalization is a monolith→monolith edit; it is fully diffable BEFORE any decompose or deletion. The oracle (§E) gains a new gate — the pre-normalization diff is reviewed (every dropped line is scaffolding; every added line is a real entry body) — and only then does decompose run. The destructive monolith DELETE is still last and still gated. The pre-normalized monolith is itself a verification artifact (the human-reviewable "this is exactly what will become the tree").
- **It fits the SAFE order cleanly** — pre-normalization is a NEW non-destructive Phase B0 BEFORE tree-build (§G), entirely reversible (it edits the monolith, which is not deleted until Phase D).

The cost — a hand/coder edit of the monolith — is bounded (19 new entries + ~5 scaffolding deletions, §D) and is exactly the "real work" the user wants done once, up front, so the decompose run is trivial.

---

## B. THE PRECISE BOUNDARY — entry CONTENT preserved; only NON-entry scaffolding normalized

The content-faithfulness oracle (V3 §5) governs EVERY entry body, including the 19 new ones. The boundary:

| Class | Examples (measured §D) | Disposition |
|---|---|---|
| **ENTRY (preserve faithfully)** | every `**BD-NNN — …**` full entry (190 today) + the 19 BD-001..019 currently-table rows (become full entries) + the v10 section's 5 entries (BD-059/020/021/022/023) | survives as a per-entry file; body byte-faithful (for the 19, the body is the NEW canonical short entry — §C) |
| **NON-entry scaffolding (normalize/drop)** | the 4 version-grouping H2s (`## Active — v11 Scope`, `## Active — v10 Scope`, `## Resolved — v8 …`, `## Deferred`); the `## How to use this file` preamble; the per-section prose blurbs ("The v11.0 implementation surface…", "All BD-001 through BD-019 items resolved…"); the v8 table WRAPPER (the `| Item | Description | Commit |` header + separator row) | dropped from the per-entry tree; the useful "how to use" content moves to `_intro.md`/`_rules.md` per D1 (§D) |

**Red line honored:** every BD number present in the monolith — BD-001..019 (table), BD-020..059 era, BD-060..207 era, the v10 section's 5, the Deferred 11, the two suffix entries (BD-167b/169b) — exists as exactly one per-entry file post-conversion. Removing/omitting ANY = violation. The §E count oracle enforces it (post-D3 count = 209, §E).

**Embedded-entry guarantee:** any entry that happens to live inside an "odd" section survives. The v10 "Active" section's 5 entries (3 Deprecated + 1 Resolved + 1 Open — §D EE-A2) are NOT "active" but ARE real entries; they become per-entry files with their true `Status:` unchanged. The section LABEL is dropped; the ENTRIES are kept.

---

## C. THE 19 BD-001..019 ENTRIES — canonical shape (simple, no reconstruction)

Per D3: "They can be very simple. No research is necessary and they don't have to be reconstituted from history." The canonical shape for each `BD-00N.md` body, derived ONLY from the existing table row (no history mining):

```
**BD-001 — Rename ios-architect → apple-architect**
Type: TODO(version)
Status: Resolved
Resolved: commit 08f7158 (v8, March 2026)
Description: Rename ios-architect → apple-architect.
```

- **Title** = the table's Description cell (verbatim) OR a short canonical title; the table's "Description" column IS the title text today, so use it verbatim as the `**BD-00N — <Description>**` header and restate it as the one-line `Description:`.
- **Status: Resolved** (D3).
- **Resolved:** carries the table's Commit cell (the only provenance datum) + the v8/March-2026 era. This preserves the table's sole information (item, description, commit) with zero invention.
- These 19 are the SIMPLEST valid entries; they satisfy the per-entry `_rules.md` contract (header + Status + Resolved) and the content oracle (their body IS their canonical content — there is no prior full-entry body to be faithful to, so the oracle's faithfulness target for these 19 is "the table row's three fields are preserved," not "byte-identical to a prior full entry").

> The content-faithfulness oracle (§E) treats the 19 specially-and-correctly: for the 187+2 pre-existing FULL entries the target is byte-faithful-to-prior-body; for the 19 NEW entries the target is "the table row's (Item, Description, Commit) triple is preserved in the entry." Both are checkable; neither drops data.

---

## D. MEASURED ENUMERATION OF EVERY ODDITY (Empirical-Evidence Blocks)

All commands at HEAD `c22d71c`, branch `v11-dev`, cwd `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, 2026-06-04.

### EE-A1 — the 4 version-grouping H2s + the preamble H2 (the scaffolding to flatten)
```
$ grep -nE '^## ' pack-ops/BACKLOG.md
9:## How to use this file
23:## Active — v11 Scope
3419:## Active — v10 Scope
3692:## Resolved — v8 (March 2026)
4901:## Deferred
```
Interpretation: 5 H2s total — 1 preamble (`How to use this file`, L9) + 4 version/status-grouping sections. NO `## v9` section exists (the v9-era entries live in other sections); confirms the grouping is inconsistent/strange (D4). All 5 H2s are NON-entry scaffolding → flatten.
Conclusion: **SUPPORTED** — exactly 5 scaffolding H2s; none is an entry.

### EE-A2 — the v10 "Active" section is mislabeled (5 entries, NOT active)
```
$ sed -n '3419,3691p' pack-ops/BACKLOG.md | grep -E '^\*\*BD-|^Status:'
**BD-059 — v10 migration silently destroys project customization**   Status: Resolved
**BD-020 — C++ server support analysis**                              Status: Open
**BD-021 — Redesign Apple platform architecture skills (three-tier)** Status: Deprecated
**BD-022 — C project template and c-language skill**                  Status: Deprecated
**BD-023 — Mixed-language skills for Apple projects (...)**           Status: Deprecated
```
Interpretation: the `## Active — v10 Scope` header labels 5 entries whose real statuses are 1 Resolved + 1 Open + 3 Deprecated — NONE is "Active." The doubly-anomalous mislabel D4 names. All 5 are real entries → preserve with true status; drop the "Active — v10 Scope" label.
Conclusion: **SUPPORTED** — the v10 section's label is false; its 5 entries survive per-entry with statuses {Resolved, Open, Deprecated×3}.

### EE-A3 — the v8 table = 19 rows (BD-001..019), NOT currently full entries
```
$ sed -n '3692,4900p' pack-ops/BACKLOG.md | grep -cE '^\| BD-0'      → 19   (table rows)
$ sed -n '3696,3717p' pack-ops/BACKLOG.md | grep -oE 'BD-0[0-9][0-9]'
BD-001 BD-002 ... BD-019   (19 distinct)
$ for n in 001 002 003 019; do grep -cE "^\*\*BD-$n — " pack-ops/BACKLOG.md; done → 0 0 0 0
```
Interpretation: BD-001..019 exist ONLY as table rows (`| BD-00N | desc | commit |`); ZERO of them has a `**BD-00N — **` full-entry header today. So converting them to full entries ADDS 19 entries (no duplication risk). The table WRAPPER (`| Item | Description | Commit |` + separator) is scaffolding → drop after the rows become entries.
Conclusion: **SUPPORTED** — 19 table rows, currently non-entries, become 19 new full entries; no dup.

### EE-A4 — the v8 H2 also holds 30 EXISTING full entries (BD-024..058 era)
```
$ sed -n '3692,4900p' pack-ops/BACKLOG.md | grep -cE '^\*\*BD-'   → 30
```
Interpretation: the v8 H2 mixes the 19-row table AND 30 real full entries. The 30 decompose normally (they're already full-shape); only the table needs the C-conversion. Confirms V3 §3.2's "table + 30 entries" measurement.
Conclusion: **SUPPORTED** — 30 existing full entries in the v8 H2 are unaffected by the table conversion.

### EE-A5 — the Deferred section = 11 real entries (a status bucket, not a version)
```
$ sed -n '4901,$p' pack-ops/BACKLOG.md | grep -E '^\*\*BD-|^Status:'
BD-031, BD-055, BD-056, BD-057, BD-058, BD-151, BD-152, BD-153, BD-154, BD-155, BD-201
  — all Status: Deferred (11 entries)
```
Interpretation: `## Deferred` groups 11 real entries by STATUS, duplicating what each entry's `Status: Deferred` line already says. Redundant grouping → drop the H2; the entries survive; the TOC's Status grouping reproduces the "Deferred" view losslessly.
Conclusion: **SUPPORTED** — 11 Deferred entries preserved; the `## Deferred` H2 is redundant scaffolding.

### EE-A6 — section reconciliation: 190 full entries today; +19 = 209 post-D3
```
$ sed -n '23,3418p'   ... grep -cE '^\*\*BD-'   → 144   (v11)
$ sed -n '3419,3691p' ... grep -cE '^\*\*BD-'   → 5     (v10)
$ sed -n '3692,4900p' ... grep -cE '^\*\*BD-'   → 30    (v8 full entries)
$ sed -n '4901,$p'    ... grep -cE '^\*\*BD-'   → 11    (Deferred)
$ grep -cE '^\*\*BD-' pack-ops/BACKLOG.md       → 190   (total full entries)
  + 19 new BD-001..019 (currently table rows)   = 209   (projected post-D3)
```
Interpretation: today 190 full entry-blocks (144+5+30+11). Converting the 19 table rows adds 19. Post-normalization the monolith has 209 uniform full entries → 209 per-entry files.
Conclusion: **SUPPORTED** — post-D3 count = **209** (measure live at conversion time; the BACKLOG may still grow).

### EE-A7 — status distribution (whole BACKLOG, sums to 190; +19 Resolved = 209)
```
$ grep -E '^Status:' pack-ops/BACKLOG.md | sort | uniq -c
  1 Cancelled   11 Deferred   3 Deprecated   28 Open   146 Resolved   1 Unblocked   (=190)
```
Interpretation: post-D3 the 19 new entries are all Resolved → 165 Resolved; full distribution {Open 28, Resolved 165, Deferred 11, Deprecated 3, Cancelled 1, Unblocked 1} = 209. `Unblocked` (1) confirmed live → D2 admits it as canonical.
Conclusion: **SUPPORTED** — 6 distinct statuses incl. `Unblocked`; post-D3 sums to 209.

### EE-A8 — CHANGELOG needs NO normalization beyond V3's per-release vN.md
```
$ grep -nE '^## ' pack-ops/CHANGELOG.md | grep -vE '## v'   → (no output)
```
Interpretation: EVERY `## ` H2 in the CHANGELOG is a version release (`## vN`); there is NO scaffolding H2 (no "How to use", no status bucket). By-release grouping is the LEGITIMATE, conventional changelog organization (a changelog IS chronological-by-release). So the CHANGELOG carries no "strange structure" to flatten — V3's per-release `vN.md` design (one file per `## vN`) is the correct + sufficient normalization. Verified, not assumed.
Conclusion: **SUPPORTED** — CHANGELOG by-release grouping is legitimate; no change beyond V3 §2.3.

---

## E. THE TARGET UNIFORM STRUCTURE + TOC (for user ratification)

### E1 — per-entry tree (flat)
- `/backlog/` — 209 flat `BD-NNN[b].md` files (one per entry; no version subdirectories). Filename = ID (V3 §2.2 contract).
- `/backlog/_toc.md` — the ONLY organizational view (regenerated, `DO NOT EDIT BY HAND`).
- `/backlog/_rules.md` — the SOLE rules source (D1); `/backlog/_intro.md` — human-only (D1).
- `/changelog/` — 11 flat `vN.md` files + `_toc.md` + `_rules.md` + `_intro.md` (unchanged from V3 §2.3).
- **No `_v8-resolved-archive.md`** (reversed per A2/D3).

### E2 — TOC grouping + sort (PROPOSED — surface to user for ratification)
The backlog TOC replaces version-grouping with **STATUS grouping** (status is the entry's real axis; version-era is entry content). Proposed group order + within-group sort:

```
## Open          (28)   — by BD number ascending
## Unblocked     (1)    — by BD number ascending   [NEW group per D2]
## Deferred      (11)   — by BD number ascending
## Resolved      (165)  — by BD number ascending
## Deprecated    (3)    — by BD number ascending
## Cancelled     (1)    — by BD number ascending
```

- **Group ORDER rationale:** actionable-first (Open → Unblocked → Deferred) then terminal (Resolved → Deprecated → Cancelled). This is the toc-regenerate canonical order (`toc-regenerate.sh:202` = Open/Resolved/Deferred/Cancelled/Deprecated) with `Unblocked` inserted after Open (D2: a pending-decision state between Open and Deferred) — surface the exact slot to the user. NOTE: the current `toc-regenerate.sh:202` order puts Resolved second; the proposed order (actionable-first) is a NUDGE to that constant — flag for user ratification (either order is valid; pick one).
- **Within-group sort:** BD-number ascending (stable, deterministic, matches `entry_sort_key` `toc-regenerate.sh:228`).
- **Changelog TOC:** by major version descending (V3 §2.5, unchanged) — legitimate per EE-A8.

> This TOC organization is the structure that REPLACES the version-grouping H2s. The user ratifies the group order + the Unblocked slot.

---

## F. D1 DOC-GOVERNANCE STANDARD (fold in; BD-206 inherits)

Per D1, the pack meta-docs follow this standard (applied to `/backlog/` + `/changelog/` now; noted for the project streams BD-206 inherits):

1. **`_rules.md` is the SOLE rules source for its directory.** No rule is duplicated or fragmented across `_intro.md`/`_toc.md`/another doc. (Amends V3 §2.6: the `_rules.md` carries the filename regex, the admitted lifecycle states incl. Unblocked, the supporting-file basenames, the ID-extraction rule, the write-authority pointer, AND the no-mirror statement — ALL rules in one place.)
2. **`_intro.md` is HUMAN-ONLY; agents may ignore it.** Nothing of agent-value goes in it. (Amends V3 §3.1: `_intro.md` is repurposed as the human "How to use this tree" header — the useful parts of the dropped `## How to use this file` preamble (BACKLOG L9-19) move here — but it carries ZERO rules and ZERO agent-load-bearing content. An agent reading only `_rules.md` + the entry files + `_toc.md` has everything.)
3. **Every meta-doc states AUDIENCE + PURPOSE at the very top.** `_intro.md` ("Audience: humans. Purpose: orientation; not read by agents."), `_rules.md` ("Audience: agents + PM Chat. Purpose: the sole contract for this directory's per-entry files."), `_toc.md` ("Audience: humans + agents. Purpose: generated index; DO NOT EDIT."), and `_order.md` if ever used.

This RESOLVES V3's open `_intro.md` question (V3 §3.1 left it "decide + surface"): `_intro.md` is human-only orientation, `_rules.md` is the sole rules SSOT. The split is now governed, not optional.

---

## G. RECONCILIATION WITH THE REST OF V3 (every change noted)

| V3 element | Amendment change |
|---|---|
| **§3.2 v8-archive split** | **REVERSED.** No `_v8-resolved-archive.md`; the 19 rows become real entries (A2/D3). |
| **§3.1 conversion steps** | Insert **Phase B0 — pre-normalize the monolith** BEFORE tree-build: (1) convert the 19 table rows → 19 full `**BD-00N —**` entries (§C); (2) delete the 4 grouping H2s + the preamble H2 + the table wrapper + section blurbs; (3) leave a flat uniform-entry monolith. Phase B0 is non-destructive (edits the monolith; monolith not deleted until Phase D) and DIFF-REVIEWED before decompose. |
| **§3.1 `_intro.md` fate** | RESOLVED per D1/§F: human-only orientation; not "decide + surface." |
| **§2.6 `_rules.md`** | Now the SOLE rules source (D1/§F); admits `Unblocked` as a canonical state (D2); drops the `_v8-resolved-archive.md` basename from the pack-backlog support set. |
| **§2.5 Unblocked (was "surface to user")** | DECIDED per D2: ADMIT as canonical lifecycle state; add to `_rules.md` legal states + the TOC group order (§E2). No longer an open surface. |
| **§4 STREAMS / Check 32 known-supporting** | the pack-backlog `known_supporting` set (`validate-pack.py:3186`) DROPS `_v8-resolved-archive.md` (no longer emitted). The v8-archive SKIP in Check 34 (`validate-pack.py:3606` `v8_archive_basenames`) becomes dead → remove it (the 19 are now normal entries, scanned normally). STREAMS entry-regex stays `^BD-\d+[a-z]*\.md$` (V3 §4) — admits BD-001.md..BD-019.md (plain numeric) + the suffix forms. |
| **§5 count oracle** | the backlog count oracle target changes: post-Phase-B0 the LIVE monolith count is **209** (190 + 19), measured by `grep -cE '^\*\*BD-'` AFTER pre-normalization. The oracle gains a **Phase-B0 diff gate**: the pre-normalization diff must show ONLY (a) +19 new entry blocks, (b) −5 scaffolding H2s + the table wrapper + blurbs — and NO change to any existing entry body. Decompose runs only after this gate passes. |
| **§5 content oracle** | extended per §C: 187+2 pre-existing entries → byte-faithful-to-prior-body; 19 new → (Item, Description, Commit) triple preserved. No entry dropped (209 files). |
| **§6 sequencing** | Phase B gains the B0 pre-normalization step FIRST; the rest of the phase order (build → verify → fix refs/validators → DELETE last → audit) is unchanged. CI stays green (B0 edits the monolith only; trees not yet created). |
| **§3.3 doc corrections** | unchanged; the dropped `## How to use this file` preamble's useful content moves to `_intro.md` (§F), not lost. |
| **Everything else in V3** | STANDS (engine changes 1/2/3, validator redesign, reverse-tracker interface + BD-204 ratification points, pack-only firewall, changelog per-release design). |

**Net count change across the design:** V3 said 190; this amendment makes the post-conversion tree **209** backlog entry files (live-measured: 190 existing + 19 converted, growing if the BACKLOG advances). The changelog stays 11 `vN.md` files (EE-A8: no further normalization).

---

## H. OUT-OF-SCOPE ITEMS SURFACED (not silently fixed)

- **TOC group-order NUDGE (§E2):** the proposed actionable-first order differs from the current `toc-regenerate.sh:202` constant (Resolved-second). Both valid; user ratifies which + the `Unblocked` slot. SURFACED, not silently changed.
- **The v8 table's Commit cells** (`08f7158`, etc.) are short hashes from v8; carried verbatim into each new entry's `Resolved:` line as provenance. No validation that they still resolve in git history is performed (D3: "no research necessary"). SURFACED as a deliberate non-action.
- **`Cancelled` (1 entry)** is already canonical in `toc-regenerate.sh:202`; no change needed — noted for completeness.
- **BD-206 inheritance of D1:** the project meta-docs (`docs/project/*/{_rules,_intro}.md`) must adopt the same D1 governance; that is BD-206 scope (project-side, `pack-only` denies it here). FLAGGED, not done.

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule (as named in prompt) | Verification evidence (QUOTED) | Conclusion |
|---|---|---|
| **fail-loud-delete-old-source (principle-2 nuance)** | §A2: "a numbered BD entry, however abbreviated, is an ENTRY (preserve as a per-entry file), NOT history to archive — only the table WRAPPER/section scaffolding is dropped." V3 §3.2 archive-the-table is REVERSED; the 19 become real `BD-00N.md` files (D3). Monolith still DELETED last (§G §6 unchanged). | COMPLIANT |
| **preserve-every-entry (red line)** | §B + EE-A6: every BD number (BD-001..019 table rows + v10 section's 5 + Deferred 11 + 187+2 full + suffix BD-167b/169b) → exactly one per-entry file; post-D3 count = 209 enforced by the §G/§E count oracle + the Phase-B0 diff gate ("NO change to any existing entry body"). | COMPLIANT |
| **empirical-evidence-blocks** | EE-A1..EE-A8: every state-claim (5 scaffolding H2s; v10 mislabel statuses {Resolved,Open,Deprecated×3}; 19 table rows non-entries with 0 full headers; 30 v8 full entries; 11 Deferred; 190→209; status distribution; CHANGELOG zero non-version H2s) carries the actual command + verbatim output + HEAD `c22d71c` + interpretation + SUPPORTED. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Leads with the DECISION (§A: pre-normalize mechanism). Delivers exactly (a) mechanism, (b) boundary, (c) target structure + TOC, (d) measured oddities, (e) V3 reconciliation. Out-of-scope items SURFACED in §H, not solved. No edge-case sprawl. | COMPLIANT |
| **rules-applied-verification-block (+ no-derivation)** | This block; every row QUOTED evidence (none empty); READ-IN-FULL row below with per-file direct-read proof (line count or first+last line). | COMPLIANT |

### READ-IN-FULL row (per-file direct-read proof)
| Document | Direct Read? | Proof |
|---|---|---|
| `ARCHITECTURE-BD-203-V3.md` (my own prior doc) | YES | 413 lines (Read in full this pass); L1 "# ARCHITECTURE-BD-203-V3 — Shared per-entry engine co-design ..." → L413 "**End of ARCHITECTURE-BD-203-V3.md**". |
| `pack-ops/BACKLOG.md` preamble (L1-22) | YES | Read offset 1 lim 30; L1 "# Backlog" → L22 (blank before `## Active — v11 Scope` at L23); preamble + `## How to use this file` captured. |
| `pack-ops/BACKLOG.md` v11 section header (L23) | YES | same Read; L23 "## Active — v11 Scope" → L29 plan-corpus blurb. |
| `pack-ops/BACKLOG.md` v10 section (L3419-3478) | YES | Read offset 3419 lim 60; L3419 "## Active — v10 Scope" → BD-059 body; statuses grepped (EE-A2). |
| `pack-ops/BACKLOG.md` v8 table + entries (L3692-3771) | YES | Read offset 3692 lim 80; L3692 "## Resolved — v8 (March 2026)" → table rows L3696-3717 → BD-024.. full entries; table+30 entries grepped (EE-A3/A4). |
| `pack-ops/BACKLOG.md` Deferred section (L4901-EOF) | YES | grepped offset 4901→EOF directly; 11 entries + Status lines (EE-A5). |
| `pack-ops/BACKLOG.md` full structure (counts/statuses) | YES | grepped all `^## `, per-section `^\*\*BD-`, `^Status:` directly (EE-A1/A6/A7). |
| `pack-ops/CHANGELOG.md` H2 structure | YES | grepped `^## ` minus `## v` → empty (EE-A8); confirms zero non-version scaffolding. |
| `feedback_fail_loud_delete_old_source.md` | YES | 55 lines; L1 frontmatter "name: fail-loud-delete-old-source-on-migration" → L55 "do not invent scope." (principle-2 nuance applied in §A2). |
| `scripts/lib/per-entry/decompose.sh` (anchors/section-break) | YES | 288 lines read in full in the V3 pass; anchors L110-153 + `section_break_re = ^## ` L114/130/137 — basis for the "flat monolith needs no section logic" claim. |
| `scripts/lib/per-entry/toc-regenerate.sh` (status order/sort) | YES | 295 lines read in full in the V3 pass; `order_groups` L198-221 (canonical L202) + `entry_sort_key` L228 — basis for §E2 TOC order + the Unblocked-slot NUDGE. |
| `scripts/validate-pack.py` (STREAMS, Check 32 known_supporting, Check 34 v8_archive) | YES | Read in the V3 pass; STREAMS L297-301, `known_supporting_for` L3185-3189, `v8_archive_basenames` L3606 — basis for the §G validator reconciliation. |

**No named document was derived rather than read.** Every doc relied on was Read directly via the Read tool (my own V3 doc + the BACKLOG sections + CHANGELOG + the fail-loud memory this pass; the engine/validator files in full during the V3 pass, re-cited by exact line here). All amendment numbers (5 scaffolding H2s; v10 mislabel; 19 table rows = non-entries; 30 v8 full; 11 Deferred; 190→209; `Unblocked`=1; CHANGELOG zero non-version H2s) were independently measured this pass at HEAD `c22d71c` via Bash/Read.

**End of ARCHITECTURE-BD-203-V3-AMENDMENT.md**
