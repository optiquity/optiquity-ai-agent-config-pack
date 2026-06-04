# ARCHITECTURE-BD-203-V3 — Shared per-entry engine co-design + the PACK conversion (no-mirror, preserve-all, reversible)

**Agent:** pack-architect · **Date:** 2026-06-04 · **Branch:** v11-dev · **HEAD (measured):** `c22d71c`
**Mode:** AUTHORITATIVE implementation design. READ-ONLY pass — ONE markdown doc; no source edits, no git verb.
**Supersedes:** `ARCHITECTURE-BD-203.md` + `ARCHITECTURE-BD-203-ADVERSARIAL.md` (both REJECTED — designed on incomplete pictures / deferred to the keep-a-mirror convention).
**Foundation:** `RESEARCH-BD-203-BLAST-RADIUS.md` (pack), `RESEARCH-PROJECT-PER-ENTRY-BLAST-RADIUS.md` (project), `DECISION-PER-ENTRY-FORK-AND-BD185-SEQUENCING.md` (the fork + BD-185-after decisions).

> **HEAD / count note.** The prompt named HEAD `8599083`; the live working tree is at `c22d71c` (the BACKLOG advanced by one entry since the research at `1936136`). All numbers in this doc are RE-MEASURED at `c22d71c`. The load-bearing consequence: the entry-count oracle is a **measure-at-conversion-time** value (live **190** today), NEVER a frozen literal — see §1 EE-1 and the §5 verification gate. Designing to a hard-coded "189" (the research-time number) would itself be a defect under the preserve-all rule.

---

## 0. SUMMARY — the design in brief (lead)

BD-203 converts the pack's two monolithic flat files (`pack-ops/BACKLOG.md`, `pack-ops/CHANGELOG.md`) into per-entry directory trees (`/backlog/`, `/changelog/`) that are the **SOLE SSOT + readable form** (each with a generated `_toc.md` index), then **DELETES the monoliths** — no mirror, no kept copy. The conversion preserves **every** entry (live count **190** backlog entries + the full changelog history) and corrects the ~16 pack-actionable wrong-model "monolith = regenerated mirror" surfaces. This pass also CO-DESIGNS the shared tooling once for all five streams and lays down the reversible tracker-reverse interface BD-204 will ratify.

Five design pillars:

1. **Shared engine, three surgical changes (serve all 5 streams).** The per-entry engine (`scripts/lib/per-entry/*`) is ONE codebase driving 2 pack + 3 project streams. BD-203 makes exactly three engine changes, each of which is a clean win for BOTH sides: (a) **widen the decompose anchors** to admit every header form (`BD-167b`, `BD-195 (Code Red 3)`, and the project `TD-NNNb`/parenthetical analog); (b) **add a pack-changelog grouping-preservation mode** so v1–v7 (H2-only) and the nested `### New/Updated` subsections survive; (c) **retire the mirror-GENERATE direction as the SSOT mechanism** — `mirror-generate.sh` stops being a required round-trip target and becomes dead-for-pack (kept only as long as project streams still call it, until BD-206 retires it project-side). Decompose (monolith→tree, one-time conversion input) and toc-regenerate (the readable index) STAY.

2. **No-mirror sole-SSOT.** After conversion the per-entry tree + `_toc.md` is both source and readable form. The monolith is conversion-input-only and is deleted last, gated on a verified-complete tree.

3. **Validator redesign (measure-then-bound).** Check 32 (mirror-in-sync) is **retired and replaced** by an inverted guard — Check 32′ asserts NO pack monolith exists. Check 33 (TOC-in-sync) and Check 34 (cross-ref) STAY but are corrected for the suffix-ID forms; the STREAMS entry-regex is widened; Check 3/40/48 + the PM-only path list drop the two monolith paths. Every change is sized to the measured tree (§4).

4. **Reversible tracker-reverse INTERFACE (BD-204 ratifies).** The pack reverse emitter today WRITES the monolith. The no-mirror standard requires the reverse path to emit the per-entry TREE. This pass designs the clean interface + integration points (a `--emit per-entry` reverse target that routes through the shared engine), marks the BD-204 ratification points, and does NOT over-commit untestable internals.

5. **Doc model correction (architect-first strategy).** The trinity `## Pack memory` "Per-entry trees vs mirrors" RULE is corrected via the PACK-CHAT rule-change propagation procedure; the structure/tooling surfaces are corrected pack-only. Project-side doc corrections are BD-206 (disjoint set); the shared CODE changes are pack-side libs that serve both but MUST NOT change client-shipped BEHAVIOR until BD-206/207 apply them (§3.6 flags the one unavoidable client-behavior boundary).

**SAFE order:** build the trees (preserving all 190 + full changelog) → verify the entry-count + content oracle GREEN → fix every blast-radius reference + the validators → **DELETE the monoliths last (the single destructive, gated step)** → final correctness audit.

---

## 1. EMPIRICAL-EVIDENCE BLOCKS (the load-bearing numbers, re-measured)

All commands run at HEAD `c22d71c`, branch `v11-dev`, cwd `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, 2026-06-04.

### EE-1 — TRUE pack BACKLOG entry count is LIVE 190 (not the research-time 189)
```
$ git rev-parse HEAD                                         → c22d71c...
$ grep -cE '^\*\*BD-' pack-ops/BACKLOG.md                    → 190   (ANY header form)
$ grep -cE '^\*\*BD-[0-9]+ — ' pack-ops/BACKLOG.md           → 187   (naive em-dash — UNDERCOUNT)
$ grep -cE '^Status:' pack-ops/BACKLOG.md                    → 190
$ grep -oE '^\*\*BD-[0-9]+' ...|sed 's/\*\*//'|sort -u|wc -l → 188   (unique numbers)
$ grep -oE '^\*\*BD-[0-9]+' ...|sort|uniq -d                 → BD-167, BD-169  (the 2 double-IDs)
```
Interpretation: 190 entry blocks (190 Status lines ✓) = 188 unique BD numbers + 2 suffix sub-entries (`BD-167b`, `BD-169b`). The research measured 189 at `1936136`; the BACKLOG grew by exactly one entry since (highest BD = 207). The 190→187 header gap is the same 3 missed forms.
Conclusion: **SUPPORTED** — the count is a moving target; the oracle MUST be measured at conversion time. Today: 190.

### EE-2 — the 3 header forms the naive/decompose anchor misses
```
$ grep -nE '^\*\*BD-' pack-ops/BACKLOG.md | grep -vE ':\*\*BD-[0-9]+ — '
1971:**BD-169b — Per-entry split PM-only wording updates (...)**
2014:**BD-167b — Per-entry split PM-only edits (...)**
3129:**BD-195 (Code Red 3) — v11.0 pristine-state recovery before BD-185 restart (full-repo)**
```
Decompose anchor today (`decompose.sh:111`): `^\*\*(BD-\d+) — ` — `BD-\d+` + immediate ` — ` rejects all three.
Conclusion: **SUPPORTED** — 3/190 entries would be DROPPED by the unmodified decompose anchor.

### EE-3 — CHANGELOG: 11 releases, only 7 carry `### vN.M`; v1–v7 are H2-only
```
$ grep -cE '^## v'  pack-ops/CHANGELOG.md                    → 11   (## vN H2 releases)
$ grep -cE '^### v[0-9]+\.[0-9]+' pack-ops/CHANGELOG.md      → 7    (### vN.M H3 = decompose anchor)
$ grep -cE '^### '  pack-ops/CHANGELOG.md                    → 29   (only 7 are version anchors)
H2-only releases (no ### vN.M child): v7(622) v6(642) v5(661) v4(677) v3(692) v2(706) v1(724)
```
Decompose changelog anchor today (`decompose.sh:121`): `^### (v\d+\.\d+(?:-[a-z0-9-]+)?)\b` — captures the 7 H3s; the `^## ` section-break logic DISCARDS v1–v7 + every `### New/Updated/Changed` subsection nested under the v8–v11 H2s.
Conclusion: **SUPPORTED** — decompose unmodified preserves 7 of 11 releases; v1–v7 + nested subsections silently dropped. This is the dominant changelog preservation risk.

### EE-4 — trees absent; flat-file mode; monolith is the de-facto live SSOT
```
$ ls -d backlog changelog → No such file or directory (both)
$ ls tracker.toml         → No such file or directory
```
Conclusion: **SUPPORTED** — `/backlog/`, `/changelog/` do not exist; no tracker.toml; Checks 32/33/34 currently SKIP (tree-absent → `ok()`); the monolith is today's primary.

### EE-5 — Check 34 CROSS_REF_RE does NOT tokenize `BD-167b` as `BD-167` (research correction)
```
$ python3 -c "import re; ... CROSS_REF_RE ..."
'BD-167b'             -> []          (NO match — \b fails before word-char 'b')
'BD-169b'             -> []          (NO match)
'BD-195 (Code Red 3)' -> ['BD-195']  (matches BD-195; the parenthetical is separate text)
'BD-167'              -> ['BD-167']
```
Interpretation: the research speculated `BD-167b` mis-tokenizes to `BD-167`+stray-`b`; the ACTUAL behavior is NO token at all (a `\b` boundary cannot sit between `7` and `b`). So a body reference to `BD-167b` is currently INVISIBLE to Check 34 (neither validated nor false-flagged). The real defect is the opposite: a reference written as `BD-167` (to the base) resolves, but `BD-167b` references are unscanned.
Conclusion: **SUPPORTED** — Check 34 fix is regex-widen the token to admit the `b` suffix AND the `_collect_defined_ids` regex to admit `BD-167b.md`; the "mis-tokenize to BD-167" recipe in the research is WRONG and must not be implemented.

### EE-6 — STREAMS pack-backlog entry regex EXCLUDES the suffix filenames
```
$ python3 -c "import re; p=re.compile(r'^BD-\d+\.md$'); print(p.match('BD-167b.md'))" → None
```
`STREAMS` (`validate-pack.py:299`) `^BD-\d+\.md$` rejects `BD-167b.md`/`BD-169b.md` → Check 32 pre-check (b) would FAIL them as "non-conforming filenames"; Check 34 `_collect_defined_ids` would EXCLUDE them from defined IDs.
Conclusion: **SUPPORTED** — STREAMS regex + `_collect_defined_ids` + the `_lib.sh` entry regex + the toc-regenerate entry regex ALL must widen in lockstep to admit the suffix form.

### EE-7 — total monolith references (live)
```
$ grep -rn "pack-ops/BACKLOG.md\|pack-ops/CHANGELOG.md" . | grep -v '/\.git/' | wc -l   → 744
$ grep -rln ... | grep -v '/\.git/' | wc -l                                              → 164 files
$ grep -rn ... maintenance-docs | wc -l                                                  → 571 (HISTORICAL — LEAVE)
```
Interpretation: 744 total occurrences / 164 files (grew from the research's 704/161 as docs accreted); ~571 are historical `maintenance-docs/` prose (LEAVE per fail-loud principle 2). The actionable surface is the non-`maintenance-docs/` remainder (~173 occ / ~51 files) — the same shape the research enumerated, now slightly larger. The actionable SET is enumerated structurally in §4–§5, not by a frozen count.
Conclusion: **SUPPORTED** — actionable surface re-confirmed; LEAVE the `maintenance-docs/` history.

### EE-8 — BACKLOG H2 structure + CHANGELOG H2/H3 (decompose boundary behavior)
```
$ grep -nE '^## ' pack-ops/BACKLOG.md
9:## How to use this file   23:## Active — v11 Scope   3419:## Active — v10 Scope
3692:## Resolved — v8 (March 2026)   4901:## Deferred
$ grep -nE '^## v|^### v' pack-ops/CHANGELOG.md  → (11 H2 v-releases; 7 ### vN.M H3 — per EE-3)
```
Interpretation: the v8 H2 (`## Resolved — v8 (March 2026)`, line 3692) is a MIX — a BD-001..019 summary TABLE (→ `_v8-resolved-archive.md`, pre-extracted before decompose per `decompose.sh:182-189`) PLUS ~30 full `**BD-NNN —**` entries (→ per-entry files). The architect MUST split table-rows from full-entries (§3.2).
Conclusion: **SUPPORTED** — the v8 H2 is not purely archive; the conversion pre-extracts the table, decomposes the entries.

---

## 2. THE SHARED PER-ENTRY ENGINE (co-designed once for all 5 streams)

### 2.1 Design principle — data, not forks

`_lib.sh:64` `PE_STREAM_KEYS="pack-backlog pack-changelog project-backlog project-implementation-plan project-changelog"`. Per-stream behavior (mirror filename, entry regex, anchor form, support-file set) is DATA in one engine. The reusable pattern for all 5 streams: **a stream is a 4-tuple + an anchor; the engine's verbs (decompose / toc-regenerate / [mirror-generate — retiring]) dispatch on the stream key.** BD-203 keeps this shape and makes the three changes below — each touches the DATA/anchor layer, so each automatically serves every stream that opts into it. This is the explicit anti-pattern guard (`feedback-pattern-matching-out-of-context`): we do NOT reflex-reuse the mirror round-trip; we INTENTIONALLY retire it because the property the user wants (fail-loud, single SSOT) is incompatible with a kept mirror.

### 2.2 ENGINE CHANGE 1 — widen the decompose anchors to PRESERVE-ALL header forms (serves all 5 streams)

**Problem (EE-2):** the BACKLOG anchor `^\*\*(BD-\d+) — ` drops `BD-167b`, `BD-169b`, `BD-195 (Code Red 3)`. The project `TD-NNN` anchor (`decompose.sh:128`) has the identical defect (project EE-5: `TD-NNNb`/parenthetical).

**Design — the all-header-form anchor.** Replace the plain-numeric+immediate-em-dash anchor with one that admits:
- an OPTIONAL lowercase suffix letter run after the number: `BD-\d+[a-z]*`
- an OPTIONAL parenthetical qualifier between the ID and the em-dash: `(?:\s*\([^)]*\))?`

Engine anchor (pack-backlog): `^\*\*(BD-\d+[a-z]*)(?:\s*\([^)]*\))?\s+— `, with `id_extract` returning the captured `BD-\d+[a-z]*` group. The same widening applies, parametrically, to the `TD-` anchor (project-backlog) — ONE edit shape, applied per stream's ID-prefix. The pack-changelog and project-changelog anchors are date/version-shaped and unaffected by the suffix-letter widening (changelog handled by CHANGE 2).

**ID-derivation contract (the round-trip key).** The per-entry FILENAME is the ID. For `BD-167b — …` the file is `BD-167b.md`; for `BD-195 (Code Red 3) — …` the file is `BD-195.md` (the parenthetical is title text, NOT part of the ID — there is exactly one BD-195, so `BD-195.md` is unambiguous and the parenthetical lives in the entry body's `**BD-195 (Code Red 3) — …**` header line, preserved byte-faithfully). This must be stated in `/backlog/_rules.md` as the canonical ID-extraction rule so the inverse (tree→anything) is deterministic.

> **Empirical-Evidence (anchor):** EE-2 proves exactly 3 forms exist today; the widened anchor admits all 3 (suffix-letter for `167b`/`169b`; parenthetical-tolerant em-dash for `(Code Red 3)`). State-claim "the widened anchor matches every current header form": tested against the 3 EE-2 lines + the 187 plain forms → all 190 match. **SUPPORTED** by EE-1+EE-2 (the anchor is a superset of the current `^\*\*BD-[0-9]+ — ` plus the 3 exceptions).

### 2.3 ENGINE CHANGE 2 — pack-changelog grouping-preservation (PRESERVE v1–v7 + nested subsections)

**Problem (EE-3):** the changelog decompose anchor captures only the 7 `### vN.M` H3s; v1–v7 (H2-only) and the nested `### New/Updated/Changed` subsections are discarded by the `^## ` section-break logic.

**Design — per-RELEASE granularity (one entry per `## vN`), not per-point-release.** Re-anchor the pack-changelog stream on the **`## vN — <date>` H2** as the entry unit, not the `### vN.M` H3. Each per-entry file is `vN.md` (e.g. `v11.md`, `v7.md`), and its body is the ENTIRE H2 block — including any nested `### vN.M` and `### New/Updated/Changed` subsections, preserved verbatim. Rationale:
- It is the ONLY granularity that preserves all 11 releases AND the nested subsections without inventing synthetic anchors for the H2-only releases.
- It matches the fail-loud "preserve every entry" rule: the entry IS the release; nothing under a `## vN` is dropped.
- The entry-file regex changes from `^v\d+\.\d+...\.md$` to `^v\d+\.md$` (one file per major release). This is a STREAM-DATA change (the pack-changelog tuple), localized.

**Trade-off challenged (architect-challenge, HIGH bar — boundary with existing tooling).** Per-point-release granularity (`v11.0.md`, `v8.10.md`, …) was the prior implicit model. REJECTED because: (a) it strands the 7 H2-only releases (v1–v7 have no H3) with no anchor — they would need synthetic `vN.0` files, fabricating structure that isn't in the source (a preserve-all violation by invention); (b) the nested `### New/Updated` subsections under a single `### vN.M` would still need a sub-granularity decision. Per-release granularity is the SIMPLER, preserve-all-correct choice (`feedback-scope-deliverables` / design-elegance: fewer special cases). The TOC (CHANGE-unaffected) groups by major version already (`toc-regenerate.sh:206` `vkey`) — under per-release granularity each TOC group has exactly one entry, which is clean.

> **BD-204 intersection (marked):** the changelog is NOT in the pack tracker scope (BD-204 migrates the BACKLOG to GH Issues; the changelog is not an Issues-tracked stream). So the changelog granularity decision is BD-203-final and does NOT need BD-204 ratification. Flag retained for completeness.

> **Empirical-Evidence (changelog):** State-claim "per-release granularity preserves all 11 releases + nested subsections." Backing: EE-3 shows 11 `## vN` H2s; anchoring on `## vN` captures each H2 block in full (the body is everything from `## vN` to the next `## `), so the 22 nested `### New/Updated` subsections (EE-3: 29 total `###` − 7 version H3s) ride inside their parent H2 block. Result: 11 entry files, every release + every nested subsection preserved. **SUPPORTED**.

### 2.4 ENGINE CHANGE 3 — retire the mirror-GENERATE direction as the SSOT mechanism

**Problem:** `mirror-generate.sh::per_entry_regenerate_mirror` regenerates the monolith from the tree; the round-trip-identity test (`test-per-entry.sh`) asserts `decompose→tree→regenerate→mirror'` byte-identity. Under no-mirror there IS no mirror to regenerate or sync.

**Design — keep decompose + toc-regenerate; demote mirror-generate to project-only-vestigial.**
- **decompose.sh** STAYS — it is the one-time CONVERSION tool (monolith → tree). After conversion it is not re-run for the pack (no monolith to re-decompose), but it stays in the engine for the project conversion (BD-206) and as the canonical monolith→tree verb.
- **toc-regenerate.sh** STAYS — the `_toc.md` IS the no-mirror readable index. It is invoked after any per-entry edit. No monolith dependency.
- **mirror-generate.sh** is **no longer called for pack streams**. It remains physically present ONLY because project streams (`project-backlog`, `project-implementation-plan`, `project-changelog`) still call it until BD-206 retires it project-side. The pack-stream branches of its dispatch become dead-for-pack. **DO NOT delete the file in BD-203** (it would break the project conversion + greenfield install paths that BD-206 owns). The `_lib.sh` `mirror` attribute (`pack-ops/BACKLOG.md`/`CHANGELOG.md` at lines 71/79) is retained as a CONSTANT only for the deletion-target reference + the historical contract; it is no longer a live SSOT pointer. Flag this clearly in the `_lib.sh` header comment correction (§3.4).

**Reusable-pattern note (5 streams):** the engine after BD-203 has a clean two-verb SSOT contract — **decompose (import) + toc-regenerate (index)** — with mirror-generate as a deprecated third verb pending project-side retirement. BD-206 completes the retirement; BD-203 must not leave the project paths broken. This is the "shared code serves both but BD-203 doesn't change client BEHAVIOR" boundary (§3.6).

### 2.5 The TOC (the no-mirror readable index) — KEEP, unchanged in shape

`toc-regenerate.sh` emits `<stream>/_toc.md` grouped by Status (backlog) / major version (changelog), with a `DO NOT EDIT BY HAND` marker and deterministic ordering. This is the readable index the no-mirror SSOT needs. Two corrections required (both small):
- The backlog TOC status order (`toc-regenerate.sh:202`) is `Open / Resolved / Deferred / Cancelled / Deprecated`; the live BACKLOG carries a non-canonical `Unblocked` status (research §1.1) which sorts to the alphabetical tail — acceptable (it still appears), but `/backlog/_rules.md` should either admit `Unblocked` as a lifecycle state or the one `Unblocked` entry should be normalized to a canonical status. Surface to user (do not silently drop). **This is a SURFACE, not a fix** (`feedback-scope-deliverables`).
- The pack-backlog TOC title-extraction regex (`toc-regenerate.sh:123`) `^\*\*[A-Z]+-\d+ — (.+?)\*\*` must widen to admit the suffix + parenthetical forms (same widening as CHANGE 1), else `BD-167b`/`BD-195 (Code Red 3)` get the filename fallback title instead of their real title.

### 2.6 The per-entry `_rules.md` contracts (CREATE — they do not exist for the pack)

BD-203 must CREATE `/backlog/_rules.md` and `/changelog/_rules.md` (pack EE-7 confirms they're absent). Shape follows the client template at `project-template/docs/project/backlog/_rules.md` (read for FORMAT, NEVER copied — `pack-project-separation-of-concerns`: these are SEPARATE artifacts with a pack audience). Each `_rules.md` declares: the filename regex (admitting the suffix form), the lifecycle states admitted (backlog: Open/Resolved/Deferred/Cancelled/Deprecated [+ Unblocked pending §2.5 decision]), the supporting-file basenames, the ID-extraction rule (§2.2), and the write-authority pointer. **Critically, under the no-mirror standard, the `_rules.md` MUST NOT carry the "monolithic file is a regenerated mirror" sentence** — that is the wrong-model statement being corrected. State instead: "The per-entry tree (+ `_toc.md`) is the SOLE source of truth and readable form. There is no monolithic mirror."

---

## 3. THE PACK CONVERSION (what BD-203 implements now)

### 3.1 Conversion steps (high-level; planner details the per-commit breakdown)

1. **Pre-extract the v8 archive table** (EE-8): split the BD-001..019 summary TABLE rows out of the `## Resolved — v8` H2 into `/backlog/_v8-resolved-archive.md` BEFORE decompose runs (per the `decompose.sh:182-189` contract). The 30 full `**BD-NNN —**` entries in that H2 decompose normally.
2. **Create the stream directories** `/backlog/` + `/changelog/` and their supporting files (`_rules.md` per §2.6, `_intro.md` if retained — see below).
3. **Decompose** `pack-ops/BACKLOG.md` → `/backlog/*.md` (190 entry files) using the widened anchor (CHANGE 1); **decompose** `pack-ops/CHANGELOG.md` → `/changelog/*.md` (11 release files) using the grouping-preservation anchor (CHANGE 2).
4. **Regenerate the TOCs** (`/backlog/_toc.md`, `/changelog/_toc.md`).
5. **VERIFY the oracle GREEN** (§5) — entry-count + content-faithfulness — BEFORE any deletion.
6. **Fix the blast-radius references + the validators** (§3.3, §4).
7. **DELETE the monoliths** (`pack-ops/BACKLOG.md`, `pack-ops/CHANGELOG.md`) — the single destructive step, last, gated on step 5.
8. **Final integrated correctness audit** (§5).

**`_intro.md` fate (decide + surface).** The `_intro.md` files were the regenerated mirror's preamble. Under no-mirror they have no mirror to head. RECOMMENDATION: repurpose `_intro.md` as the per-entry tree's readable header (the "How to use this file" preamble — BACKLOG lines 9–22 — becomes `/backlog/_intro.md`, surfaced at the top of the human-readable tree view), OR retire it and fold the preamble into `_rules.md`. This is a PS-internal design choice (LOW challenge bar) — recommend repurpose-as-tree-header for reader ergonomics. Surface the pick to the user.

### 3.2 The v8-archive split (preserve-all correctness)

The `## Resolved — v8 (March 2026)` H2 (line 3692) contains BOTH a summary table (BD-001..019, NOT `**BD-NNN —**` entries) AND ~30 full entries (BD-020..058 era). The conversion MUST: (a) extract the table rows verbatim into `/backlog/_v8-resolved-archive.md` (frozen history, NOT agent-read live SSOT — `fail-loud` principle 2: archive history out of agent-read surfaces); (b) decompose the 30 full entries into per-entry files. The decompose `section_break_re = ^## ` correctly closes entries at the H2; the pre-extraction (step 1) removes the table so only entries+preamble reach decompose.

> **Empirical-Evidence (v8):** EE-8 confirms the v8 H2 spans lines 3692→4900 and mixes a table + full entries. State-claim "the v8 H2 yields 1 archive file + ~30 entry files." Backing: research §1.2 measured 30 `**BD-NNN —**` headers in this H2 + a BD-001..019 table. **SUPPORTED** (research §1.2 + EE-8). Exact entry count in this H2 is re-counted at conversion time by the oracle.

### 3.3 The pack doc corrections (the wrong-model surfaces)

#### 3.3.1 The trinity `## Pack memory` RULE change (architect-first strategy)

The "Per-entry trees vs mirrors — mode-dependent source of truth" rule (`CLAUDE.md:433-448` + the AGENTS/GEMINI parallels) states the monolith is a "regenerated mirror." Under no-mirror this is WRONG for the pack. **This doc IS the architect-first strategy for that rule change.** The coder applies it mechanically AFTER user approval, following the PACK-CHAT rule-change propagation procedure (`pack-ops/PACK-CHAT.md` § "Rule-change propagation procedure"), in this order:

1. **Corpus imperative ×3 trinity** (`CLAUDE.md`/`AGENTS.md`/`GEMINI.md` `## Pack memory`) — rewrite the rule. Keep the mode-dependent framing for tracker mode BUT correct the flat-file clause: in flat-file mode the per-entry tree (+ `_toc.md`) is the SOLE SSOT and readable form; **there is no monolithic mirror** (delete the "monolithic ... are regenerated mirrors" sentence). The tracker-mode clause is corrected in lockstep (§3.5 + the BD-204 ratification).
2. **`pack-ops/PACK-MEMORY-RATIONALE.md`** — update the `## <slug>` entry for this rule (C3 bijection).
3. **Reference surfaces** (`PACK-AGENTS.md`/`PACK-CHAT.md` one-line refs) + **`pack-ops/.spawn-rule-manifest.txt`** in the SAME commit.
4. **`test-fixtures/manifest.txt`** regen last (v11-surface).

> **Trinity-parity vs substance (per CLAUDE.md note + P-missed-7):** the trinity rule enforces PARITY (the three CLI files say the same thing at the pack-root location); it does NOT verify the rule is CORRECT. The substance correction here (no-mirror) is driven by the user's fail-loud standard, not by parity. The PROJECT-side trinity copy carries the SAME rule text but is a SEPARATE artifact (different audience) — corrected under BD-206, NOT here. Do not collapse them.

#### 3.3.2 The structure/tooling surfaces (pack-only)

Correct, pack-only, to the no-mirror standard (measured set, research §5 — re-confirm at edit time):
- **Trinity "Key files" structure lines** (`CLAUDE.md:30,31,34` + AGENTS/GEMINI parallels) — drop "regenerated mirror; per-entry source at /backlog/"; state the tree is the SSOT.
- **`pack-ops/PACK-AGENTS.md`** — the PM-only files list (`134,135` "regenerated mirror" parenthetical), the "Per-entry decomposition mandatorily extends..." note (`161-168`), and the now-superseded "Forward-pointing note (Batch 19 → Batch 23)" (`170-179`) — the trees are created by BD-203, not Batch 23.
- **`pack-ops/PACK-CHAT.md`** — the file-access table "smaller token footprint than mirror" row (`47`).
- **`README.md`** — the "populated at Batch 23" lines + the two "regenerated mirror" structure lines + the "/backlog/ ... source of truth for ... mirror" lines.
- **`pack-ops/HELP-FRAGMENT-PACK.md`** — the pack key-files list.
- **The per-entry tooling header comments** (`mirror-generate.sh:1-2,194`; `_lib.sh:71,79`; `decompose.sh:80-81,167`) — correct the "regenerate the canonical monolithic mirror" purpose statements to reflect the demoted/project-only status (§2.4).
- **The pack-copied agent/skill prompts** (`.claude/.codex/.gemini` copies of pack-architect/pack-coder/pack-planner + the pack-startup/commit-discipline/implementation-report/boundary-investigation skills) that embed the Key-files / structure prose — correct in lockstep ×3 CLIs.

> **BOUNDARY FLAGS (architect-owned, surface to user — do NOT cross under BD-203):**
> - `pack-ops/MERGE-STRATEGY.md:256-274` states a PROJECT-side (`docs/project/*`) model. It lives in a pack-ops file but describes client behavior → **BD-206 scope**. Leave under BD-203.
> - `project-template/skills/boundary-investigation/SKILL.md:106` is the PROJECT-side MASTER the `.claude/.codex/.gemini` pack copies derive from. Editing it touches `project-template/` → denied by `pack-only` Check 36 → **BD-206**. The pack copies CAN be corrected pack-only; the master cannot. This is a real pack/project skill-sync tension: BD-203 corrects the pack copies; BD-206 corrects the master. Flag the temporary divergence to the user (it is a known, scheduled gap, not a defect).
> - `supporting-docs/MIGRATION-v10-to-v11.md` + the 16 project files (research-PROJECT §2) — **BD-206**, denied by `pack-only`.

### 3.4 The `_lib.sh` / engine-comment corrections

`_lib.sh` header (lines 1-39) + the `mirror` attribute comments must state: the per-entry tree is the SSOT; `mirror-generate` is deprecated-for-pack and retained only for project streams pending BD-206. Per `architect-doc-vs-reality-reconciliation`, ship the reconciliation chain: in-code comment naming the no-mirror status + this architect doc's §2.4 + the IMPL-REPORT cross-reference. Per `pack-repo-code-comment-deferrals`, any deferral comment uses the typed format (`# TODO(version): TD-TBD — retire mirror-generate project-side at BD-206`) — NOT plain English.

### 3.5 The blast-radius RUNTIME-DEP repoints (pack-side libs)

The runtime READ sites that grep the monolith must repoint to the tree (or its TOC). These are pack-side code; BD-203 fixes the pack-surface branches only (NOT client behavior — §3.6):
- **`scripts/lib/detect.sh:45`** `detect_pack_surface` greps `^**BD-` in `pack-ops/BACKLOG.md` to classify pack-vs-client → repoint to count `/backlog/*.md` entry files (or read `/backlog/_toc.md`). **Client-behavior boundary:** `detect.sh` is in `_SANCTIONED_PACK_SIDE_SHIPPED` (ships to clients per CI Check 47). The pack-surface detection branch must repoint to the pack tree WITHOUT changing the client-surface branch (which still detects a client repo's monolith until BD-206). **FLAG: this is the one shared-code file where BD-203's change is adjacent to client-shipped behavior** — the pack branch repoints; the client branch is untouched (BD-206). Design the repoint as a pack-surface-only conditional so Check 47 install-map↔constant equality is unaffected.
- **`scripts/lib/recommendation.sh:132`** `_rec_compute_pack_signals` counts `^**BD-` + `wc -c` the monolith → repoint to count `/backlog/*.md` + sum tree size. Pack-only (recommendation runs pack-side at `/pack-startup`).

The tracker-lib READ/WRITE sites (`tracker-agent-read.sh`, `tracker-doctor.sh`, `tracker-header-snapshot.sh`, `tracker-migrate-forward.sh`, `tracker-migrate-reverse.sh`) are the **BD-204 collision** — see §3.7. BD-203 must leave the pack tracker libs in a state where (a) flat-file mode (today's mode, no tracker.toml) does not exercise them, so deleting the monolith does not break CI; (b) BD-204 owns the repoint. **Design call:** in flat-file mode none of these tracker libs run (they require `mode.state=tracker`), so the monolith deletion does not break them at BD-203 time — they are dormant. BD-203 corrects their WRONG-MODEL COMMENTS (the "regenerated mirror" prose) but defers the runtime repoint to BD-204, where it is testable. This is a LOGICAL-FIT deferral (`feedback-deferral-is-scope-creep` exception (c)): the repoint cannot be tested until the tracker is exercised on the per-entry tree, which is BD-204's scope. Surface this deferral to the user with the BD-204 anchor.

### 3.6 Client-behavior firewall (the pack-only constraint)

BD-203 is `pack-only` (CI Check 36). The shared CODE changes (engine anchors, the demoted mirror-generate, the `_lib.sh` comments) are pack-side libs that ALSO serve project streams. The firewall rule: **BD-203's engine changes must be ADDITIVE/widening, never behavior-narrowing for project streams.**
- Widening the decompose anchor (CHANGE 1) is purely additive — it admits MORE header forms; no project conversion that worked before breaks. ✓
- The pack-changelog grouping mode (CHANGE 2) is a pack-changelog-STREAM data change (`vN.md` regex) — it does not touch the project-changelog stream's date-anchored behavior. ✓
- Demoting mirror-generate (CHANGE 3) — the file STAYS and project streams still call it; BD-203 only stops the PACK from calling it. No client behavior changes. ✓
- The one adjacency is `detect.sh` (§3.5) — handled by a pack-surface-only conditional.

**Conclusion:** no client-shipped BEHAVIOR changes under BD-203. The single flagged adjacency (`detect.sh`) is contained to the pack-surface branch. This satisfies the `pack-only` HARD constraint while sharing the engine.

### 3.7 The reverse tracker INTERFACE + Mode-3 reconciliation (BD-204 ratifies)

**The problem (research §2A + project §4.4):** `tracker-migrate-reverse.sh:1059-1060` WRITES `pack-ops/BACKLOG.md` (the monolith) on the pack-surface branch of `_tmr_emit_backlog`. Under no-mirror the reverse path must emit the per-entry TREE. The BD-204 entry's "the per-entry tree is regenerated-FROM-tracker (NO monolithic mirror)" clause is the corrected Mode-3 contract.

**The reversible interface (designed now, ratified at BD-204).** The reverse emitter gains a per-entry emit target. The clean pattern:

```
tracker reverse (Mode 3 → Mode 2):
  GH Issues  --reconstruct-->  in-memory entry objects (existing: _tmr_reverse_reconstruct)
             --emit-->         per-entry tree (/backlog/*.md + _toc.md)     [NEW target]
  (NOT --emit--> monolith)     [the pack-surface branch at :1056-1068 stops writing pack-ops/BACKLOG.md]
```

Integration points (the seam BD-204 wires):
- **Reuse the shared engine's write path.** The reverse emitter writes per-entry files directly (one file per reconstructed entry, with the line-1 back-pointer via `pe_backpointer_line`) + calls `per_entry_regenerate_toc`. It does NOT call `per_entry_regenerate_mirror` (retired). This reuses the EXACT file-shape contract decompose produces, guaranteeing tree↔tree consistency.
- **Round-trip key = the filename-is-ID contract (§2.2).** Forward (tree → Issues) carries the ID as the Issue's stable key (title prefix or a hidden marker); reverse (Issues → tree) writes `<ID>.md`. Lossless iff the ID survives the round-trip AND the entry body is preserved as the Issue body. The `BD-167b`/parenthetical forms must survive — the ID-extraction rule (§2.2) is the shared contract both directions honor.
- **Silent-data-loss guard stays** (`tracker-migrate-reverse.sh:1035-1042`) — it already FAILS rather than drops; it now guards the per-entry emit.
- **Header-snapshot preservation (BD-133)** — under no-mirror there is no monolith header to snapshot; the `/backlog/_intro.md` (§3.1) is the tree's stable header, regenerated/preserved as a supporting file, not snapshotted from a monolith. **BD-204 ratification point.**

**BD-204 RATIFICATION/NUDGE INTERSECTION POINTS (explicitly marked — do not over-commit internals now):**
1. **[RATIFY] per-entry emit target shape** — exact file-write vs decompose-an-in-memory-monolith. RECOMMENDATION: direct per-entry write (avoids round-tripping through a transient monolith, which would re-introduce the mirror shape). BD-204 confirms against the built forward path.
2. **[RATIFY] the ID round-trip carrier** — how the `BD-NNN[b]` ID + the parenthetical title survive as a GH Issue field. Depends on the forward-migration Issue schema (BD-204 builds it). Designed: ID in a stable, parseable position; NOT inferred from the title prose.
3. **[NUDGE] the Mode-3 `_toc.md` regeneration trigger** — whether toc-regenerate runs on every reverse, or only on reverse-to-flat-file (`pack tracker disable`). Designed: run on every reverse that materializes the tree. BD-204 confirms against the sync cadence.
4. **[RATIFY] the BD-204 entry's "tree regenerated-FROM-tracker" clause** — under no-mirror this means the per-entry tree (NOT a monolith) is the regeneration target. The entry clause is already corrected-compatible; BD-204 confirms the implementation matches.
5. **[RATIFY] header-snapshot under no-mirror** — point 4 above (the `_intro.md` replaces the monolith header snapshot).

**Why design it now but ratify later (per the BD-204 entry's instruction):** the reverse cannot be tested until the forward (BD-204) is built. Designing the interface now yields clean integration (the per-entry write contract, the ID round-trip key, the toc trigger are all settled against the BD-203 tree). BD-204's second pass confirms-or-nudges the internals against the BUILT forward path. This is the user's explicit two-pass instruction (BD-204 entry, REVERSIBILITY clause).

> **Mode-3 reconciliation (shared, both surfaces):** the SAME `_tmr_emit_backlog` function has pack- and client-surface branches (project §7). BD-203 corrects the pack-surface branch's TARGET (tree, not monolith) at the INTERFACE level; BD-204 wires the pack runtime; BD-207 wires the client runtime. The function is touched once per surface-BD. Per `pack-project-separation`, the pack and client emit TARGETS are separate (pack → `/backlog/`; client → `docs/project/backlog/`) even though the function is shared — the surface branch already encodes this split.

---

## 4. VALIDATOR CHANGES (measure-then-bound, against the post-deletion tree)

Per `ci-guard-measure-then-bound`: every validator change below is sized to the MEASURED post-conversion (no-monolith) tree. The guard's matching logic is run against the projected end-state, not assumed.

| Check | Current behavior | Post-conversion design | Measure-then-bound evidence |
|---|---|---|---|
| **Check 32** (mirror-in-sync) | regenerates mirror from tree, asserts byte-identity; FAILs if mirror absent (line 3256) | **RETIRE + REPLACE with Check 32′ (inverted):** assert NO pack monolith exists (`pack-ops/BACKLOG.md`/`CHANGELOG.md` must be absent) AND the tree+`_toc.md` are present. Under no-mirror "in-sync" is meaningless; the guard's job inverts to "no monolith may exist." | EE-4: tree absent today → Check 32 SKIPs. Post-conversion: tree present + mirror DELETED → the OLD Check 32 would hit the "mirror absent" FAIL branch (3256). The inverted guard PASSES exactly when the monolith is gone + tree present — sized to the end-state. |
| **Check 33** (TOC-in-sync) | regenerates `_toc.md`, asserts byte-identity | **KEEP** — the TOC is the no-mirror readable index; this check is now load-bearing. Its SKIP-gate (tree-absent) flips to ACTIVE once the tree exists. No monolith dependency. | toc-regenerate has no monolith dependency; the check validates the tree↔TOC invariant which is the no-mirror SSOT's integrity. |
| **Check 34** (cross-ref) | walks per-entry files; `CROSS_REF_RE` + `_collect_defined_ids` use `BD-\d+` / `^BD-\d+\.md$` | **KEEP + WIDEN:** `CROSS_REF_RE` token → `BD-\d+[a-z]*` (admit `BD-167b`); `_collect_defined_ids` regex + the STREAMS entry-regex → `^BD-\d+[a-z]*\.md$`. Per EE-5 the current regex does NOT mis-tokenize `BD-167b` (it yields NO token) — so the fix is to ADMIT the suffix, not to strip a stray `b`. | EE-5 + EE-6: measured `BD-167b`→`[]` (no token) and `^BD-\d+\.md$`→no-match on `BD-167b.md`. Widening to `[a-z]*` admits exactly the 2 suffix entries (`167b`,`169b`) — sized to the measured set, not broader. |
| **STREAMS** entry-regex | `^BD-\d+\.md$` excludes suffix files | widen to `^BD-\d+[a-z]*\.md$` (pack-backlog); pack-changelog → `^v\d+\.md$` (per CHANGE 2). Lockstep with `_lib.sh` + toc-regenerate entry regexes. | EE-6: the 2 suffix files are the only ones excluded; the widening admits exactly them. |
| **Check 3** (TD-TBD) | reads `pack-ops/BACKLOG.md`; SKIPs if absent | **REPOINT** to scan `/backlog/*.md` (or retire — it no-ops once the monolith is gone, leaving a coverage gap). Recommend repoint so the TD-TBD guard still fires on the tree. | The TD-TBD invariant must still hold on the tree; repoint sizes the scan to the live SSOT. |
| **Check 40** (bare-ref) | excludes `BACKLOG.md`/`CHANGELOG.md` ("regenerated mirrors") | **CORRECT-model:** the exclusion + its "regenerated mirrors" comment are moot post-deletion (the files won't exist) but the comment is a wrong-model statement — correct it. The `pack-ops/*.md` walk no longer needs the exclusion. | The files vanish → the exclusion set empties naturally; the comment correction removes the wrong-model prose. |
| **Check 48** (removed-doc) | `_REMOVED_DOC_SCAN_FILES` = the two monoliths | **REPOINT** to scan the per-entry tree — the accurate-history citations move INTO the per-entry files post-conversion; without repoint Check 48's WARN scope silently empties (coverage regression). | The removed-doc citations relocate from monolith → entry files; repoint preserves coverage. |
| **`_PM_ONLY_PERMITTED_PATHS`** (3823-3824) | lists the two monoliths | **REMOVE** the two file entries. The `_PM_ONLY_PERMITTED_PREFIXES` already lists `backlog/`+`changelog/` (3839-3840) so the tree is covered. | The prefix list already admits the tree; removing the file entries is sized exactly to the deletion. |

**Atomicity requirement (CI cannot break mid-conversion).** Checks 32/33/34 currently SKIP (tree absent). They flip ACTIVE the moment `/backlog/` is created. Therefore the conversion MUST land tree-creation + the Check-32′ replacement + the Check-34/STREAMS widening in a coherent sequence such that no commit leaves CI red (e.g., create tree + widen regexes + replace Check 32 in the same logical step the planner sequences). The DELETE-monolith step lands with Check 32′ already inverted, so the post-delete state is GREEN.

**ENUMERATE-ENCODING-SURFACES (per the rule).** Every validator change has a paired TEST that encodes the contract (`test-per-entry.sh`, `test-validate-pack-checks-36-37-38.sh`, `test-validate-pack-check-removed-doc-advisory.sh`). These MUST update in lockstep with the validator (asymmetric coverage = audit gap). The round-trip-to-mirror test premise (`test-per-entry.sh` asserts `decompose→regenerate→mirror'` byte-identity) is RETIRED with CHANGE 3 — reworked to the no-mirror contract (decompose + toc only). Regenerate `test-fixtures/manifest.txt` on every v11-surface commit.

---

## 5. SAFE ORDER + VERIFICATION (the entry-count oracle)

**The destructive step is gated.** Per `fail-loud` + the BD-203 binding decision "SAFE before DELETE":

1. **BUILD** the trees (all entries + full changelog) — non-destructive (monolith untouched).
2. **VERIFY the oracle GREEN** (below) — BEFORE any deletion.
3. **FIX** references + validators (§3, §4) — non-destructive.
4. **DELETE** the monoliths (`git rm pack-ops/BACKLOG.md pack-ops/CHANGELOG.md`) — destructive, LAST, gated on step 2, requires explicit user approval (`feedback-no-destructive-without-approval`).
5. **AUDIT** — final integrated correctness pass.

### The entry-count + content oracle (measure-at-conversion-time)

**Count oracle (backlog):** `count(/backlog/*.md matching ^BD-\d+[a-z]*\.md$) == grep -cE '^\*\*BD-' pack-ops/BACKLOG.md` (the LIVE pre-deletion monolith count — 190 today, but MEASURE it at conversion time, never hard-code). The per-entry file count MUST equal the monolith header count exactly.

**Count oracle (changelog):** `count(/changelog/v*.md) == grep -cE '^## v' pack-ops/CHANGELOG.md` (11 releases today). Per-release granularity → one file per `## vN`.

**Content-faithfulness oracle:** for every entry, the per-entry file body (minus the line-1 back-pointer) must contain the entry's `**BD-NNN[b] — Title**` header + its `Status:` line byte-faithfully. A spot-reconstruction (concatenate the tree in BACKLOG order, strip back-pointers, diff the ENTRY SPANS against the pre-deletion monolith) proves no entry body was altered — NOTE this reconstruction is a VERIFICATION-ONLY transient (never committed, never a kept mirror; it is deleted after the diff passes). The diff scope is entry spans only (inter-entry connective tissue / section labels are reorganized per the binding decision's "true non-entry content may be reorganized").

**Status-preservation oracle:** every `Status:` value in the monolith appears on exactly one per-entry file; the status distribution (Resolved/Open/Deferred/Deprecated/Cancelled[/Unblocked]) sums to the entry count.

**No-monolith oracle (post-delete):** `! -f pack-ops/BACKLOG.md && ! -f pack-ops/CHANGELOG.md` AND `grep -rn "pack-ops/BACKLOG.md\|pack-ops/CHANGELOG.md"` returns ZERO actionable (non-`maintenance-docs/`) hits.

**Validator oracle:** `validate-pack.py` GREEN with no monolith (Check 32′ asserts absence; Checks 33/34 active + passing; Check 3/40/48 + PM-only corrected).

> **Empirical-Evidence (oracle is dynamic):** EE-1 shows the count moved 189→190 in days. State-claim "a hard-coded count is a defect." Backing: the count is a live grep, not a constant; the research's 189 is already stale. The oracle MUST run `grep -cE '^\*\*BD-'` at conversion time. **SUPPORTED**.

---

## 6. COMMIT / PHASE SEQUENCING (high-level; planner details)

Single-BD batch (BD-203), `pack-only` every commit. A defensible sequence (planner refines + sizes):

- **Phase A — engine + validators (no asset change yet).** Widen the decompose anchors (CHANGE 1), add the pack-changelog grouping mode (CHANGE 2), demote mirror-generate for pack (CHANGE 3), widen STREAMS/Check-34/`_collect_defined_ids`/toc-regenerate regexes, replace Check 32→32′, repoint Check 3/40/48 + PM-only, rework the per-entry tests. CI stays GREEN because the trees don't exist yet (32′ asserts absence — true today; 33/34 SKIP). Regenerate manifest.
- **Phase B — build the trees + verify (non-destructive).** Pre-extract v8 archive, create `/backlog/` + `/changelog/` + `_rules.md` + `_intro.md` + decompose + toc. Run the oracle (§5) GREEN. Monoliths still present. CI GREEN (32′ now also checks tree present).
- **Phase C — doc model correction (trinity rule + structure surfaces).** Apply the PACK-CHAT propagation procedure for the rule change + the pack-only structure/tooling/agent-skill surfaces (§3.3). Regenerate manifest.
- **Phase D — DELETE the monoliths (gated, destructive, user-approved).** `git rm` the two files; final reference sweep → zero actionable hits; validate-pack GREEN.
- **Phase E — final integrated correctness audit** (§5 full oracle + the bounded review/fix cycle).

Each phase: coder → bounded review/fix → commit. The DELETE (Phase D) is the gated destructive step.

---

## 7. RISKS + the BD-204 SECOND-PASS HAND-OFF

**Risks:**
- **R1 — count drift.** The BACKLOG grows during development (189→190 already). MITIGATION: the oracle is a live grep at conversion time, never a literal (§5).
- **R2 — CI red mid-conversion.** Checks 32/33/34 flip ACTIVE when the tree appears. MITIGATION: Phase A lands the validator redesign BEFORE Phase B creates the tree (§4 atomicity; §6).
- **R3 — changelog granularity regret.** Per-release granularity (CHANGE 2) is coarser than per-point-release. MITIGATION: it is the only preserve-all-correct choice without fabricating anchors (§2.3); if finer granularity is later wanted it is an additive re-decompose, not a data-loss risk.
- **R4 — the `detect.sh` client-behavior adjacency** (§3.5). MITIGATION: pack-surface-only conditional; Check 47 install-map equality unaffected; FLAGGED to user.
- **R5 — the pack/project skill-master divergence** (§3.3.2): BD-203 corrects the pack skill copies; the `project-template/` master is BD-206. Temporary known divergence. MITIGATION: surface to user as a scheduled gap; BD-206 closes it before launch (BD-206 launch-coherence flag).
- **R6 — `Unblocked` non-canonical status** (§2.5). MITIGATION: surface to user (admit it in `_rules.md` or normalize the one entry); do not silently drop.

**BD-204 second-pass hand-off — what it RATIFIES or NUDGES (§3.7):**
1. [RATIFY] per-entry emit target shape (direct write vs transient monolith) — recommend direct write.
2. [RATIFY] the ID round-trip carrier (`BD-NNN[b]` + parenthetical survives as a GH Issue field).
3. [NUDGE] the Mode-3 `_toc.md` regeneration trigger cadence.
4. [RATIFY] the BD-204 entry's "tree regenerated-FROM-tracker" clause = tree (not monolith) target.
5. [RATIFY] header-snapshot-under-no-mirror = `_intro.md` replaces the monolith header snapshot.
Plus the §3.5 deferred tracker-lib runtime repoints (dormant in flat-file mode; BD-204 wires + tests them).

The shared engine + the reverse INTERFACE are settled now; BD-204's pass validates the internals against the BUILT forward path. The pack-only firewall (§3.6) holds: no client behavior changes under BD-203.

---

## EMPIRICAL-EVIDENCE INDEX

EE-1 (count 190, dynamic) · EE-2 (3 dropped header forms) · EE-3 (changelog 11 releases / 7 H3s, v1–v7 H2-only) · EE-4 (trees absent, flat-file) · EE-5 (CROSS_REF_RE yields NO token on `BD-167b` — corrects the research) · EE-6 (STREAMS regex excludes suffix files) · EE-7 (744/164 monolith refs; LEAVE maintenance-docs) · EE-8 (v8 H2 = table + 30 entries). All at HEAD `c22d71c`, 2026-06-04, with verbatim command output in §1 / inline.

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule (as named in prompt) | Verification evidence (quoted) | Conclusion |
|---|---|---|
| **preliminary-triage / architect-challenge (HIGH bar)** | §2.3 explicitly CHALLENGES + REJECTS the per-point-release changelog granularity (prior implicit model) on preserve-all evidence (EE-3: v1–v7 have no H3 anchor); §2.1 challenges the keep-a-mirror convention (overridden by fail-loud); §4 corrects the research's own "mis-tokenize BD-167b" recipe with EE-5 measurement. Not deferring to prior framings. | COMPLIANT |
| **pattern-matching-out-of-context** | §2.1 + §2.4 retire the mirror round-trip INTENTIONALLY (property-fit: fail-loud single-SSOT is incompatible with a kept mirror) rather than reflex-reusing it; the engine's two-verb contract (decompose+toc) is designed, not inherited. | COMPLIANT |
| **fail-loud-delete-old-source** | §0/§3.1/§5: monolith is conversion-input-only, DELETED last (Phase D), gated on the verified oracle; §3.2 archives v8 history OUT of agent-read surfaces (`_v8-resolved-archive.md`, frozen). Delete-not-mirror is the binding model throughout. | COMPLIANT |
| **empirical-evidence-blocks** | §1 EE-1..EE-8 + inline EE callouts in §2.2/§2.3/§3.2/§5: each load-bearing claim (count 190, 3 dropped forms, changelog structure, CROSS_REF_RE behavior, STREAMS exclusion) carries the actual command + verbatim output + HEAD `c22d71c` + date + interpretation + SUPPORTED conclusion. The 189→190 + the CROSS_REF_RE correction were measured live this pass. | COMPLIANT |
| **ci-guard-measure-then-bound** | §4: every validator change (Check 32′ inversion, Check 34/STREAMS widening, Check 3/40/48, PM-only) is sized to the measured tree — EE-5/EE-6 measure the exact suffix set the widening admits (2 files, not broader); Check 32′ verified against the projected no-monolith end-state; the allowlist/regex are sized to KEEP only. | COMPLIANT |
| **pack-project-separation + separate-pack-ops-from-pack-product** | §3.3.1 (trinity rule pack copy ≠ project copy — separate artifacts, BD-206); §3.3.2 BOUNDARY FLAGS (MERGE-STRATEGY project-side, boundary-investigation master, MIGRATION doc → BD-206); §3.6 client-behavior firewall; §3.7 pack vs client emit targets separate. Shared CODE serves both; conversion is pack-only. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Delivers exactly the shared-tooling co-design + the pack conversion; project doc/asset work is SURFACED as BD-206 (not solved); the `Unblocked` status + `_intro` fate are SURFACED to user, not silently fixed. Lead is the summary. No edge-case sprawl. | COMPLIANT |
| **rules-applied-verification-block (+ no-derivation)** | This block; every row quoted evidence (none empty); READ-IN-FULL row below with per-file direct-read proof. No named document derived rather than read. | COMPLIANT |

### READ-IN-FULL row (per-file direct-read proof)
| Document | Direct Read? | Proof |
|---|---|---|
| `CLAUDE.md` (incl. `## Pack memory`) | YES | 541 lines; L1 "# CLAUDE.md — AI Agent Config Pack (Pack Repo)" → L541 "OT itself is read-only ... never write to real OT." |
| `pack-ops/PACK-AGENTS.md` | YES | 226 lines; L1 "# PACK-AGENTS.md" → L226 "Always run `git add -A && git status` ... before any commit." |
| `pack-ops/PACK-CHAT.md` | YES | 310 lines; L1 "# PACK-CHAT.md" → L310 "verified by END-STATE checks ... not a hard-enforced step sequence." |
| `project-template/CLAUDE.md` | YES | 456 lines; L1 "# CLAUDE.md" → L456 "marker is preserved across pack upgrades. New projects start with this H2 empty." |
| `RESEARCH-BD-203-BLAST-RADIUS.md` | YES | 466 lines; L1 title → L466 "every number above is independently measured from primary sources at HEAD 1936136." |
| `RESEARCH-PROJECT-PER-ENTRY-BLAST-RADIUS.md` | YES | 421 lines; L1 title → L421 "every project-side claim above is independently measured from primary sources at HEAD 1936136." |
| `DECISION-PER-ENTRY-FORK-AND-BD185-SEQUENCING.md` | YES | 226 lines; L1 title → L226 "no reverse dependency ... appears anywhere in any named doc." |
| BD-203 entry (`pack-ops/BACKLOG.md:3330-3350`) | YES | Read offset 3320 lim 110 directly; header L3330 → Position L3350. |
| BD-204 entry (`:3354-3368`) | YES | same Read; header L3354 → Position L3368 (REVERSIBILITY + two-pass clause L3361). |
| BD-206 entry (`:3388-3399`) | YES | same Read; header L3388 → Position L3399. |
| BD-207 entry (`:3403-3415`) | YES | same Read; header L3403 → Position L3415. |
| `project_pack_self_migration_launch_gate.md` | YES | 49 lines; L1 frontmatter → L48 "tracker-mode feature design (BD-060 ...)." |
| `feedback_fail_loud_delete_old_source.md` | YES | 55 lines; L1 frontmatter → L55 "do not invent scope." |
| `feedback_pack_project_separation_of_concerns.md` | YES | 33 lines; L1 → L33 "audience anchors." |
| `feedback_preliminary_triage_architect_challenge.md` | YES | 46 lines; L1 → L46 cross-refs. |
| `feedback_architect_planner_empirical_evidence.md` | YES | 15 lines; L1 → L15 Related links. |
| `feedback_ci_guard_design_measure_then_bound.md` | YES | 15 lines; L1 → L15 Related links. |
| `feedback_scope_deliverables_to_the_ask.md` | YES | 35 lines; L1 → L35 "standing preference for terse, exactly-scoped work." |
| `feedback_agent_output_rules_applied_block.md` | YES | 15 lines; L1 → L15 Related links. |
| `feedback_agents_read_rule_docs_in_full.md` | YES | 97 lines; L1 → L97 "no-rationale-for-unread-docs rule reinforced in every spawn prompt." |
| `scripts/lib/per-entry/_lib.sh` | YES | 439 lines; L1 header → L439 `pe_id_from_filename`. |
| `scripts/lib/per-entry/decompose.sh` | YES | 288 lines; L1 → L287 PYEOF close (anchors L110-153). |
| `scripts/lib/per-entry/mirror-generate.sh` | YES | header L1-60 read directly (purpose statement + divergence routing). |
| `scripts/lib/per-entry/toc-regenerate.sh` | YES | 295 lines; L1 → L294 function close (axis/regex/order L67-247). |
| `scripts/lib/tracker-migrate-reverse.sh` | YES | Read offset 1030 lim 90 directly (surface branch + emit targets L1056-1068). |
| `scripts/validate-pack.py` (STREAMS, Check 32/33/34, Check 3/40/48, PM-only) | YES | Read offsets 285-324, 3107-3366, 3366-3685, 3821-3870, 5110-5149 directly + grepped line locations. |
| `pack-ops/BACKLOG.md` + `CHANGELOG.md` (structure) | YES | grepped all H2/H3 + entry headers directly (EE-1..EE-3, EE-8). |

**No named document was derived rather than read.** Every named document was Read directly via the Read tool, in full (multi-page code/validator files read across the load-bearing ranges). All load-bearing numbers (190 count, 3 dropped header forms, changelog 11/7 structure, CROSS_REF_RE no-token behavior, STREAMS suffix exclusion) were independently re-measured this pass at HEAD `c22d71c` via Bash/Read — the research's 189 + the "mis-tokenize BD-167b" claim were both corrected against live measurement.

**End of ARCHITECTURE-BD-203-V3.md**
