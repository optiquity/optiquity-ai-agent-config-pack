# PLAN-BD-203 — Implementation plan: pack self-migration Phase 1 (monolith → per-entry sole-SSOT)

**Agent:** pack-planner · **Date:** 2026-06-04 · **Branch:** v11-dev · **HEAD (measured):** `a630a31`
**Mode:** PLANNING ONLY — no source edits, no git verb. This plan implements the FIXED design pair
`ARCHITECTURE-BD-203-V3.md` + `ARCHITECTURE-BD-203-V3-AMENDMENT.md` (the amendment SUPERSEDES V3 where they
differ). It does NOT redesign; it sequences, assigns actors, names verification, and SURFACES every open
boundary decision for Pack Chat / user.

**Single-BD batch.** Every commit is `pack-only` (CI Check 36). Agents never commit — only Pack Chat
stages/commits, with explicit per-commit user approval (`agents-never-commit`, `no-prestaging-until-commit-approval`).

---

## 0. GOAL + BD ITEM ADDRESSED (lead)

**Goal.** Convert the pack's two monolithic flat files (`pack-ops/BACKLOG.md`, `pack-ops/CHANGELOG.md`)
into per-entry directory trees (`/backlog/`, `/changelog/`) that are the SOLE SSOT + readable form (each
with a generated `_toc.md`), DELETE the monoliths (no mirror), and correct every wrong-model
"monolith = regenerated mirror" surface — all `pack-only`.

**BD addressed:** BD-203 (in full). Out of scope and NOT pulled in: BD-204 (tracker Mode 2→3),
BD-206 (project-side no-mirror), BD-207 (project reversible tracker). Per `no-deferral-without-user-direction`,
NO pack-side BD-203 work is deferred — all of it is planned here.

**Mechanism (amendment A1, ratified).** PRE-NORMALIZE the monolith in place into one uniform shape (flat
full entries — a reviewable monolith→monolith diff, Phase B0) THEN run the existing decompose engine with
zero special-casing. The 19 BD-001..019 v8 summary-table rows become REAL `BD-00N.md` resolved entries
(amendment A2/D3); the version-grouping scaffolding flattens to a flat tree + STATUS-grouped TOC.

**Live oracle (re-measured at HEAD `a630a31`, EE-P1 below): 190 full entries + 19 v8 table rows = 209
projected per-entry backlog files; 11 changelog releases.** The count is a measure-at-conversion-time value,
NEVER hard-coded.

---

## 1. EMPIRICAL-EVIDENCE BLOCKS (planner state-claims, re-measured)

All commands at HEAD `a630a31`, branch `v11-dev`, cwd `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, 2026-06-04.

### EE-P1 — backlog 190 full entries + 19 table rows = 209; status distribution
```
$ git rev-parse HEAD                              → a630a312...
$ grep -cE '^\*\*BD-' pack-ops/BACKLOG.md          → 190   (full-entry headers; == Status lines)
$ grep -cE '^Status:' pack-ops/BACKLOG.md          → 190
$ grep -cE '^\| BD-0' pack-ops/BACKLOG.md          → 19    (v8 summary-table rows BD-001..019)
$ grep -E '^Status:' ... | sort | uniq -c
   1 Cancelled  11 Deferred  3 Deprecated  28 Open  146 Resolved  1 Unblocked   (= 190)
```
Interpretation: 190 existing full entries; +19 table-row promotions = **209** projected. Post-D3 Resolved =
146 + 19 = **165**; full post-conversion distribution {Open 28, Unblocked 1, Deferred 11, Resolved 165,
Deprecated 3, Cancelled 1} = 209. `Unblocked` (1) confirmed live (D2 admits it canonical).
Conclusion: **SUPPORTED** — count moved 190 (vs amendment's c22d71c measurement of 190 too); oracle MUST
re-measure at conversion time, never hard-code 209.

### EE-P2 — the 5 scaffolding H2s + 3 suffix header forms
```
$ grep -nE '^## ' pack-ops/BACKLOG.md
9:## How to use this file   23:## Active — v11 Scope   3420:## Active — v10 Scope
3693:## Resolved — v8 (March 2026)   4902:## Deferred
$ grep -nE '^\*\*BD-' pack-ops/BACKLOG.md | grep -vE ':\*\*BD-[0-9]+ — ' | wc -l   → 3
```
Interpretation: 5 scaffolding H2s to flatten (1 preamble + 4 grouping); 3 non-plain header forms
(`BD-167b`, `BD-169b`, `BD-195 (Code Red 3)`) the widened anchor must admit.
Conclusion: **SUPPORTED** — matches amendment EE-A1/EE-A2 and V3 EE-2.

### EE-P3 — changelog 11 releases, zero non-version H2s
```
$ grep -cE '^## v' pack-ops/CHANGELOG.md                  → 11
$ grep -nE '^## ' pack-ops/CHANGELOG.md | grep -vE '## v' → (none)
```
Conclusion: **SUPPORTED** — every `## ` H2 is a version release; CHANGELOG needs NO normalization beyond
per-release `vN.md` (amendment EE-A8). 11 → 11 `vN.md` files.

### EE-P4 — trees absent; flat-file mode; Checks 32/33/34 currently SKIP
```
$ ls -d backlog changelog tracker.toml → (all ENOENT)
```
Conclusion: **SUPPORTED** — `/backlog/`, `/changelog/` do not exist; Checks 32/33/34 SKIP on tree-absent
(`validate-pack.py:3195` is_dir gate). CI is GREEN today with the monolith present.

### EE-P5 — the trinity rule being corrected carries NO rationale slug
```
$ sed -n '433,448p' CLAUDE.md   → "- **Per-entry trees vs mirrors ...** ... `[roles: universal]`"   (NO [rationale: <slug>])
$ grep -nE 'Per-entry trees vs mirrors|trees-vs-mirrors' pack-ops/PACK-MEMORY-RATIONALE.md → (no hit)
```
Interpretation: the "Per-entry trees vs mirrors" rule has `[roles: universal]` only — no `[rationale: slug]`.
The PACK-CHAT rule-change propagation steps gated on a slug (step 2 RATIONALE.md C3 bijection; step 5
`.spawn-rule-manifest.txt`) DO NOT apply to this rule. Propagation reduces to: corpus ×3 trinity (step 1)
+ reference surfaces PACK-AGENTS/PACK-CHAT (step 4) + manifest regen (step 6).
Conclusion: **SUPPORTED** — do NOT invent a RATIONALE.md or spawn-manifest edit for this rule.

### EE-P6 — CI enumerates the 5 affected test files (must stay green every commit)
```
$ grep -nE 'test-per-entry|checks-32-33-34|removed-doc|checks-36-37-38|check-40' .github/workflows/validate-pack.yml
156: test-per-entry.sh   159: test-validate-pack-checks-32-33-34.sh   162: test-validate-pack-checks-36-37-38.sh
168: test-validate-pack-check-40.sh   198: test-validate-pack-check-removed-doc-advisory.sh
```
Conclusion: **SUPPORTED** — these 5 tests run in CI; each is an ENCODING surface that must update in
lockstep with its validator (`enumerate-encoding-surfaces`).

### EE-P7 — round-trip-to-mirror test premise + mirror-filename asserts (to retire/rework)
```
$ grep -n 'regenerate_mirror\|canonical_mirror\|round-trip' scripts/tests/test-per-entry.sh
  220 "1.1 pack-backlog mirror filename" == "pack-ops/BACKLOG.md"   (and 1.2..1.5)
  285 "Group 3: pack-backlog round-trip identity"   338 "3.7 round-trip byte-identity (mirror == mirror')"
  (Groups 3,4-empty-tree,5-supporting,6-divergence,7-toc all call per_entry_regenerate_mirror)
```
Conclusion: **SUPPORTED** — `test-per-entry.sh` Groups 3 + the divergence/empty/supporting groups assert the
mirror round-trip premise CHANGE-3 retires for PACK. These groups exercise SYNTHETIC fixtures (not the live
pack-ops monolith), so they can stay testing the engine's mirror verb for PROJECT streams (mirror-generate
is NOT deleted — V3 §2.4) — the planner does NOT delete them; it removes only the PACK-stream mirror-filename
asserts that name the deleted files, and reworks any assert that presumes a live pack monolith. (See Step T1.)

---

## 2. TASK BREAKDOWN (atomic, ordered) — Section (A)

Each task: WHAT it changes · WHICH files · WHY. Tasks are grouped into phases (§4 dependency graph) and
commits (§5). Actor per §6.

### Phase A — engine + validators (NO asset/tree exists yet; CI stays green because trees absent)

- **A1 — Widen the decompose backlog anchor (ENGINE CHANGE 1).** Replace `decompose.sh:111`
  `^\*\*(BD-\d+) — ` with `^\*\*(BD-\d+[a-z]*)(?:\s*\([^)]*\))?\s+— ` + matching `id_extract` (capture
  `BD-\d+[a-z]*`). Apply the SAME widening, parametrically, to the project `TD-` anchor (`decompose.sh:128`)
  — additive, fixes project too (V3 §3.6 firewall: widening never narrows). WHY: admit `BD-167b`, `BD-169b`,
  `BD-195 (Code Red 3)` (EE-P2) so no entry drops. File: `scripts/lib/per-entry/decompose.sh`.
- **A2 — Pack-changelog grouping-preservation (ENGINE CHANGE 2).** Re-anchor pack-changelog on the
  `## vN — <date>` H2 (entry unit = one `vN.md` per major release); body = the entire H2 block (nested
  `### vN.M` / `### New/Updated` preserved verbatim). File: `scripts/lib/per-entry/decompose.sh`
  (pack-changelog branch). WHY: preserve all 11 releases incl. v1–v7 H2-only (EE-P3 / V3 EE-3).
- **A3 — Pack-changelog stream tuple regex → `^v\d+\.md$`.** Update `_lib.sh:80` (pack-changelog
  `entry-regex`), `toc-regenerate.sh:85` (entry_regex_for_stream pack-changelog), and `validate-pack.py:300`
  (STREAMS pack-changelog regex) in LOCKSTEP. WHY: per-release granularity = one `vN.md` file per release.
- **A4 — Widen pack-backlog entry regex to admit the suffix form `^BD-\d+[a-z]*\.md$`.** Update in lockstep:
  `_lib.sh:72` (pack-backlog entry-regex), `toc-regenerate.sh:84`, `validate-pack.py:299` (STREAMS), and
  `validate-pack.py` Check 34 `_collect_defined_ids` (uses the STREAMS regex). WHY: admit `BD-167b.md` /
  `BD-169b.md` (EE-P2 / V3 EE-6) — sized to exactly the 2 suffix entries, not broader.
- **A5 — Widen Check 34 `CROSS_REF_RE` token to `BD-\d+[a-z]*`.** `validate-pack.py:3496`. WHY: per V3 EE-5
  the current regex yields NO token on `BD-167b` (a `\b` cannot sit between `7` and `b`) — the fix is to
  ADMIT the suffix, NOT strip a stray `b` (the research's mis-tokenize recipe is WRONG). File:
  `scripts/validate-pack.py`.
- **A6 — Widen pack-backlog TOC title regex.** `toc-regenerate.sh:123` `^\*\*[A-Z]+-\d+ — (.+?)\*\*` →
  admit the suffix + parenthetical so `BD-167b`/`BD-195 (Code Red 3)` get their real title, not the filename
  fallback. File: `scripts/lib/per-entry/toc-regenerate.sh`.
- **A7 — TOC backlog status order + admit `Unblocked`.** `toc-regenerate.sh:202` `order_groups` canonical
  list. RATIFIED order (BD-203 entry + amendment E2): `Open → Unblocked → Deferred → Resolved → Deprecated
  → Cancelled`. WHY: D2 admits `Unblocked`; user-ratified actionable-first order (a NUDGE to the current
  `Open/Resolved/Deferred/Cancelled/Deprecated`). File: `scripts/lib/per-entry/toc-regenerate.sh`.
  **BOUNDARY NOTE:** the BD-203 entry states this exact order as ratified, so it is FIXED, not surfaced.
- **A8 — Retire mirror-generate as the PACK SSOT mechanism (ENGINE CHANGE 3, comment-level only).**
  Correct the wrong-model purpose statements in `mirror-generate.sh:1-2` header, `_lib.sh:1-39` header +
  the `mirror) printf 'pack-ops/BACKLOG.md'/CHANGELOG.md` attr comments (lines 71/79), and
  `decompose.sh:80-81,167` round-trip-to-mirror comments — state: per-entry tree is the SSOT; mirror-generate
  is deprecated-for-pack, retained ONLY for project streams pending BD-206. DO NOT DELETE `mirror-generate.sh`
  (project streams still call it; deleting breaks BD-206/greenfield — V3 §2.4/§3.6). Per
  `pack-repo-code-comment-deferrals` any deferral comment uses the typed form
  `# TODO(version): TD-TBD — retire mirror-generate project-side at BD-206`. Files:
  `scripts/lib/per-entry/{mirror-generate.sh,_lib.sh,decompose.sh}`.
- **A9 — Replace Check 32 with inverted Check 32′ (assert NO pack monolith).** `validate-pack.py:3107-3344`.
  New contract: for each pack stream, if the tree dir is present then assert the monolith file is ABSENT and
  `_toc.md` + `_rules.md` present; never regenerate a mirror. WHY: under no-mirror "in-sync" is meaningless;
  the OLD Check 32 hits its "mirror absent → FAIL" branch (`:3256`) once the tree exists without a mirror.
  Sized to the projected no-monolith end-state. File: `scripts/validate-pack.py`.
- **A10 — Repoint Check 3 (TD-TBD) to scan the `/backlog/` tree.** `validate-pack.py:457-476`. Scan
  `/backlog/*.md` entry bodies for `**TD-TBD —` headers instead of `pack-ops/BACKLOG.md`. Keep SKIP-on-absent.
  WHY: preserve the TD-TBD guard once the monolith is gone. File: `scripts/validate-pack.py`.
- **A11 — Correct Check 40 wrong-model exclusion + comment.** `validate-pack.py:5113-5143`. The
  `excluded_basenames = {"BACKLOG.md","CHANGELOG.md"}` + "regenerated mirrors" docstring/comment become moot
  post-deletion; correct the wrong-model prose (the files won't exist). File: `scripts/validate-pack.py`.
- **A12 — Repoint Check 48 removed-doc scan to the per-entry tree.** `validate-pack.py:317-320`
  `_REMOVED_DOC_SCAN_FILES` (the two monoliths) → scan the `/backlog/` + `/changelog/` entry files. WHY: the
  accurate-history citations relocate INTO the per-entry files; without repoint Check 48's WARN scope silently
  empties (coverage regression). File: `scripts/validate-pack.py`.
- **A13 — Remove the two monolith paths from `_PM_ONLY_PERMITTED_PATHS`.** `validate-pack.py:3823-3824`.
  The `_PM_ONLY_PERMITTED_PREFIXES` already lists `backlog/` + `changelog/` (`:3839-3840`), so the tree is
  covered. WHY: sized exactly to the deletion. File: `scripts/validate-pack.py`.
- **A14 — Repoint the pack-side RUNTIME-DEP read sites.** (a) `recommendation.sh:131-132`
  `_rec_compute_pack_signals` — count `/backlog/*.md` entry files + sum tree size instead of grepping/`wc`-ing
  the monolith (pack-only; runs at `/pack-startup`). (b) `detect.sh:45` `detect_pack_surface` — repoint the
  PACK-surface branch to count `/backlog/*.md` (or read `/backlog/_toc.md`) WITHOUT touching the client-surface
  branch (still detects a client monolith until BD-206). **CLIENT-BEHAVIOR ADJACENCY (V3 §3.5, R4):** `detect.sh`
  is in `_SANCTIONED_PACK_SIDE_SHIPPED` (CI Check 47); design the repoint as a pack-surface-only conditional so
  Check 47 install-map↔constant equality is unaffected. Files: `scripts/lib/recommendation.sh`,
  `scripts/lib/detect.sh`. **SURFACE (§8 G-2): the detect.sh client-adjacency is flagged for user confirmation
  before the coder touches it.**
- **A15 — Rework the affected validator/engine TEST files in lockstep (ENCODING surfaces).** (T1)
  `test-per-entry.sh`: remove the pack-stream mirror-filename asserts (1.1/1.2 name the deleted files) and any
  assert presuming a LIVE pack monolith; keep the synthetic-fixture engine groups that still exercise
  mirror-generate for project-stream coverage; add a pack-changelog `vN.md` round-trip group reflecting CHANGE
  2. (T2) `test-validate-pack-checks-32-33-34.sh`: rewrite Group A (Check 32 → Check 32′ inverted: green =
  tree present + NO monolith; red = monolith present); update fixtures to the widened regexes + the suffix
  entry; add a `BD-167b.md` cross-ref case (Check 34). (T3) `test-validate-pack-check-removed-doc-advisory.sh`:
  re-target Check 48 to per-entry-tree fixtures. (T4) `test-validate-pack-checks-36-37-38.sh`: drop the T6d/T6e
  asserts that the two monoliths are PM-only (they no longer exist post-deletion). (T5)
  `test-validate-pack-check-40.sh`: update if it asserts the mirror-exclusion. Files under `scripts/tests/`.
  WHY: `enumerate-encoding-surfaces` — validator + its TEST must move together or audit gap.
- **A16 — Regenerate `test-fixtures/manifest.txt`.** Run `bash test-fixtures/build.sh --all --clean`; stage
  iff non-empty diff. WHY: Phase-A diff touches `scripts/` (v11-surface) — `manifest-regen-on-v11-surface`.

### Phase B0 — PRE-NORMALIZE the monolith in place (non-destructive; reviewable diff) — amendment A1/G

- **B0a — Promote the 19 BD-001..019 v8 table rows to full entries.** In `pack-ops/BACKLOG.md`, convert each
  `| BD-00N | <desc> | <commit> |` row to the canonical short entry (amendment §C):
  `**BD-00N — <desc>**` / `Type: TODO(version)` / `Status: Resolved` / `Resolved: commit <hash> (v8, March 2026)`
  / `Description: <desc>.` No history mining (D3). WHY: they ARE entries → 19 real `BD-00N.md` files (EE-P1).
- **B0b — Flatten the scaffolding.** Remove the 4 grouping H2s (`## Active — v11/v10 Scope`,
  `## Resolved — v8 (March 2026)`, `## Deferred`) + the `## How to use this file` preamble + the v8 table
  WRAPPER (`| Item | Description | Commit |` header + separator) + per-section prose blurbs — leaving a flat
  list of uniform `**BD-NNN —**` entries separated by `---`. The useful "how to use" content is RELOCATED to
  `/backlog/_intro.md` in Phase B (human-only, amendment §F). The v10 section's 5 entries (BD-059/020/021/022/023)
  survive with their TRUE statuses; only the false "Active — v10 Scope" LABEL drops (EE-A2). WHY: a uniform
  monolith lets decompose run with zero special-casing.
- **B0c — VERIFY the Phase-B0 diff gate.** The monolith→monolith diff must show ONLY (a) +19 new entry blocks,
  (b) −5 scaffolding H2s + the table wrapper + blurbs, and NO change to any existing entry body. (Verification
  task; gates B0 before any decompose.)
- File touched by B0a/B0b: `pack-ops/BACKLOG.md` (PM-only — see §6 actor tension).

### Phase B — build the trees + verify (non-destructive; monoliths still present)

- **B1 — Create `/backlog/` + `/changelog/` directories.**
- **B2 — Author `/backlog/_rules.md` + `/changelog/_rules.md`** (the SOLE rules SSOT per D1/amendment §F).
  Each declares: filename regex (admitting the suffix form for backlog `^BD-\d+[a-z]*\.md$`; changelog
  `^v\d+\.md$`); admitted lifecycle states (backlog: Open/Unblocked/Deferred/Resolved/Deprecated/Cancelled —
  `Unblocked` admitted per D2; changelog: none — append-by-release); supporting-file basenames (backlog:
  `_rules.md _intro.md _toc.md` — NO `_v8-resolved-archive.md`, reversed per A2/D3; changelog: same);
  the ID-extraction rule (V3 §2.2: filename = ID; `BD-167b.md`; parenthetical lives in the body, not the ID);
  the write-authority pointer; AND the no-mirror statement ("The per-entry tree (+ `_toc.md`) is the SOLE
  source of truth and readable form. There is no monolithic mirror."). Shape follows the client template at
  `project-template/docs/project/backlog/_rules.md` for FORMAT ONLY (read, NEVER copied —
  `pack-project-separation-of-concerns`). Every meta-doc states AUDIENCE + PURPOSE at top (D1).
- **B3 — Author `/backlog/_intro.md` + `/changelog/_intro.md`** (human-only; agent-ignorable; carries ZERO
  rules — D1/amendment §F). Backlog `_intro.md` receives the relocated useful "How to use this file" preamble
  content (BACKLOG L9-19). Audience+Purpose header at top.
- **B4 — Decompose** `pack-ops/BACKLOG.md` → `/backlog/*.md` (209 files) with the A1 widened anchor; **decompose**
  `pack-ops/CHANGELOG.md` → `/changelog/*.md` (11 `vN.md` files) with the A2 grouping anchor. (Run the engine —
  a coder-driven invocation, output staged as the tree.)
- **B5 — Regenerate the TOCs** (`/backlog/_toc.md`, `/changelog/_toc.md`) via toc-regenerate (the A6/A7 regexes
  + order).
- **B6 — VERIFY the oracle GREEN** (§7 full oracle: count == measured 209; content-faithfulness; status; toc;
  cross-ref) BEFORE any deletion. Monoliths still present.
- **B7 — Regenerate `test-fixtures/manifest.txt`** (the new tree files are under `/backlog/` `/changelog/` —
  NOT one of the four v11-surface dirs `project-template/`/`scripts/`/`pack-ops/`/`supporting-docs/`; **but**
  Phase B0 touched `pack-ops/BACKLOG.md` so the B0+B commit IS v11-surface — regenerate + stage iff non-empty).
- **B8 — DROP the `_v8-resolved-archive.md` residue in lockstep (carry-forward: C-1 review SHOULD-1,
  user-approved 2026-06-04).** Remove `_v8-resolved-archive.md` from: (a) the pack-backlog `support` attr in
  `scripts/lib/per-entry/_lib.sh:73`; (b) `known_supporting_for["pack-backlog"]` in
  `scripts/validate-pack.py:3186-3187`; (c) the dead `v8_archive_basenames` SKIP in Check 34
  (`scripts/validate-pack.py:3606,3623`). Update the lockstep ENCODING test
  `scripts/tests/test-validate-pack-checks-32-33-34.sh` if it asserts the archive basename. WHY: amendment §G
  reverses V3 §3.2 — the 19 BD-001..019 become real entries and NO `_v8-resolved-archive.md` is emitted, so
  these allowlist/SKIP references are DEAD; A1–A16 did not schedule the removal (plan gap). Lands in Phase B
  lockstep with B2's `_rules.md` basename set (which already omits the archive — §2 B2) so no dead
  allowlist/SKIP lingers. v11-surface (`scripts/`) → manifest regen (B7).
- **B9 — WIDEN the pack-backlog TOC `entry_sort_key` for the suffix form (carry-forward: C-1 review NIT-1,
  user-approved 2026-06-04).** `scripts/lib/per-entry/toc-regenerate.sh:230` `^[A-Z]+-(\d+)$` →
  `^[A-Z]+-(\d+)[a-z]*$` so `BD-167b` sorts ADJACENT to `BD-167` within its status group (the current regex
  returns 0 for a suffix ID, sending it to the group TOP). WHY: completes the suffix-handling family the A4/A6
  widenings began; the sort effect is observable only once the tree exists (Phase B), so it lands here.
  Cosmetic TOC ordering. v11-surface (`scripts/`) → manifest regen (B7).

### Phase C — doc model correction (trinity rule + structure surfaces; the ~16 wrong-model surfaces)

- **C1 — Trinity `## Pack memory` "Per-entry trees vs mirrors" RULE rewrite ×3.** `CLAUDE.md:433-448` +
  `AGENTS.md` + `GEMINI.md` parallels. Correct the FLAT-FILE clause: the per-entry tree (+ `_toc.md`) is the
  SOLE SSOT and readable form; delete the "monolithic ... are regenerated mirrors" sentence FOR THE PACK.
  Keep mode-dependent framing; correct the tracker-mode clause in lockstep (BD-204 ratifies the implementation).
  Follows the PACK-CHAT propagation procedure (§9). **EE-P5: this rule has NO rationale slug → NO RATIONALE.md
  / NO spawn-manifest edit.** PM-only (trinity = Pack-Chat-direct).
- **C2 — Trinity "Key files" structure lines ×3.** `CLAUDE.md:30,31,34` + AGENTS/GEMINI parallels (GEMINI is a
  prose form — `cross-cli-reference-normalization`, audience-correct value not byte-copy). Drop "regenerated
  mirror; per-entry source at /backlog/"; state the tree is the SSOT. PM-only.
- **C3 — `pack-ops/PACK-AGENTS.md` corrections.** (a) PM-only files list `134,135` "regenerated mirror"
  parenthetical → the monolith entries are REMOVED (the files are deleted in Phase D); the `/backlog/`+`/changelog/`
  Directories block already covers the tree. (b) Drop/retire the "Forward-pointing note (Batch 19 → Batch 23)"
  block (`170-179`) — the trees are created by BD-203 NOW, not Batch 23. (c) Correct the "Per-entry decomposition
  mandatorily extends..." note (`161-168`) wording to reflect the now-existing trees. PM-only.
- **C4 — `pack-ops/PACK-CHAT.md` corrections.** File-access table `47` "smaller token footprint than mirror"
  row → no-mirror wording. PM-only.
- **C5 — `README.md` corrections.** The "populated at Batch 23" lines (`185-187`), the two "regenerated mirror"
  rows (`262,263`), and the "source of truth for ... mirror" rows (`280,281`). PM-only (README structure/version
  lines = Pack-Chat-direct).
- **C6 — `pack-ops/HELP-FRAGMENT-PACK.md`.** Key-files list `40,41` — the two monolith refs become the tree.
  NOT a trinity/README/PACK-AGENTS file → see §6 actor (pack-product? PM-only? — SURFACE G-3).
- **C7 — Pack-copied agent/skill prompts ×3 CLIs.** `.claude/.codex/.gemini` copies of pack-architect/
  pack-coder/pack-planner + the pack-startup / commit-discipline / implementation-report / boundary-investigation
  skills that embed the Key-files / structure prose (research §5 enumerates the lines). Correct in lockstep ×3.
  pack-product (coder). **BOUNDARY (V3 §3.3.2 / R5): the `project-template/skills/boundary-investigation/SKILL.md`
  MASTER is PROJECT-side (denied by `pack-only`) → BD-206; the pack copies CAN be corrected pack-only. The
  temporary pack-vs-project skill-master divergence is a KNOWN scheduled gap — SURFACE G-4.**
- **C8 — Regenerate `test-fixtures/manifest.txt`** (Phase C touches `pack-ops/` + `.claude/.codex/.gemini` +
  README — v11-surface for the `pack-ops/`/`scripts` parts; regenerate + stage iff non-empty).

### Phase D — DELETE the monoliths (gated, destructive, user-approved)

- **D1 — `git rm pack-ops/BACKLOG.md pack-ops/CHANGELOG.md`.** GATED on B6 oracle GREEN + the Phase-B0 diff
  gate + Phases A+C landed. The single destructive step; explicit user approval required
  (`feedback-no-destructive-without-approval`). Actor: Pack Chat (the monoliths are PM-only — §6 tension).
- **D2 — Final reference sweep → zero ACTIONABLE hits.** `grep -rn "pack-ops/BACKLOG.md\|pack-ops/CHANGELOG.md"`
  returns only `maintenance-docs/` historical prose (LEAVE — fail-loud principle 2). validate-pack GREEN with
  Check 32′ asserting absence + tree present.
- **D3 — Regenerate `test-fixtures/manifest.txt`** (deletion touches `pack-ops/` — v11-surface).

### Phase E — final integrated correctness audit (end-of-batch reviewer)

- **E1 — Full oracle re-run + the END-OF-BD acceptance audit** (§7 + BD-203 acceptance criteria): tree is the
  sole SSOT + readable form; every entry preserved + status-flagged (count == measured 209); monoliths gone;
  ~16 wrong-model surfaces corrected; every reference fixed (validate-pack GREEN, NO monolith); NO new client
  doc-vs-implementation gap; all 5 CI tests green. End-of-batch reviewer runs once on the full batch.

---

## 3. AFFECTED FILES (complete list, incl. cross-references)

**Engine (`scripts/lib/per-entry/`):** `decompose.sh` (A1, A2, A8), `_lib.sh` (A3, A4, A8),
`toc-regenerate.sh` (A3, A4, A6, A7), `mirror-generate.sh` (A8 comment-only).
**Validators (`scripts/`):** `validate-pack.py` (A3 STREAMS, A4, A5, A9 Check 32′, A10 Check 3, A11 Check 40,
A12 Check 48, A13 PM-only), `lib/recommendation.sh` (A14a), `lib/detect.sh` (A14b — client-adjacent).
**Tests (`scripts/tests/`):** `test-per-entry.sh`, `test-validate-pack-checks-32-33-34.sh`,
`test-validate-pack-check-removed-doc-advisory.sh`, `test-validate-pack-checks-36-37-38.sh`,
`test-validate-pack-check-40.sh` (A15).
**Monolith (`pack-ops/`):** `BACKLOG.md` (B0a/B0b pre-normalize; D1 delete), `CHANGELOG.md` (D1 delete).
**New trees:** `/backlog/{_rules,_intro,_toc}.md` + 209 `BD-NNN[b].md`; `/changelog/{_rules,_intro,_toc}.md`
+ 11 `vN.md` (B2–B5).
**Trinity (PM-only):** `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (C1 rule + C2 structure).
**Pack-ops governance (PM-only):** `PACK-AGENTS.md` (C3), `PACK-CHAT.md` (C4), `README.md` (C5).
**Pack-ops product/help:** `HELP-FRAGMENT-PACK.md` (C6 — actor SURFACE G-3).
**Pack-copied prompts/skills ×3 CLIs (pack-product):** `.claude/.codex/.gemini` agent + skill files (C7).
**Fixtures:** `test-fixtures/manifest.txt` (A16, B7, C8, D3 — regenerated, never hand-edited).

**Cross-reference audit (must move WITH the deletion so no commit half-corrects):** the trinity `## Pack
memory` rule (C1), README layout (C5), PACK-AGENTS PM-only + forward-note (C3), PACK-CHAT file-access (C4),
the per-entry tooling header comments (A8), HELP-FRAGMENT-PACK (C6), pack-copied skill prose (C7). These are
the "~16 surfaces" — all corrected in the SAME atomic Commit 2 as the deletion (§4 RESOLUTION A; no commit leaves them half-corrected).

**NOT touched (BD-206 boundary, denied by `pack-only`):** `supporting-docs/MIGRATION-v10-to-v11.md`,
`pack-ops/MERGE-STRATEGY.md:256-274` (project-side model in a pack-ops file — V3 flag),
`project-template/skills/boundary-investigation/SKILL.md` master, the 16 project-side wrong-model files
(project research §2). **NOT touched (BD-204, dormant in flat-file mode):** the tracker libs
(`tracker-agent-read/doctor/header-snapshot/migrate-forward/migrate-reverse.sh`) — their wrong-model COMMENTS
are corrected for the pack-surface where adjacent, but their runtime repoint is BD-204 (testable only when the
tracker is exercised) — SURFACE G-5.


---

## 4. FILE-DEPENDENCY ANALYSIS + SAFE ORDER — Section (B)

### Dependency graph (RE-SEQUENCED 2026-06-04 — RESOLUTION A atomic conversion)

**THE CONTRADICTION that forced this re-sequence (user-found, RESOLVED A 2026-06-04).** C-1's landed
Check 32′ (`validate-pack.py:3215`) FAILs when a per-entry tree dir is present AND the monolith file still
exists (`"<mirror> still present while <stream>/ tree exists → FAIL"`). The OLD staged order (build trees →
fix doc refs → delete) left the tree + monolith COEXISTING at the build and doc-fix commit end-states →
Check 32′ RED → no green PREFLIGHT reachable. **Check 32′ forbids exactly the tree+monolith window the
staged order needed.** RESOLUTION A collapses build + ref-fix + delete into ONE atomic commit so the
tree+monolith window never persists across a commit boundary.

```
COMMIT 1 (pre-normalize, B0)                COMMIT 2 (ATOMIC convert)
  B0a promote 19 rows ─┐                      EDITS (pack-coder, scoped in):
  B0b flatten scaffolding ─┤                    B1 mkdir → B2 _rules → B3 _intro
  B0c diff gate ───────────┘                    → B4 decompose (NEEDS A1/A2 + B0 uniform monolith)
        │ edits pack-ops/BACKLOG.md ONLY        → B5 toc (NEEDS A6/A7) → B8/B9 carry-fwd
        │ NO tree yet → 32′/33/34 SKIP          → C1–C8 fix ALL ~16 doc-model refs
        │ → GREEN                               → B6 ORACLE GREEN (gate) + manifest
        ▼                                       │ coder PREFLIGHT: oracle GREEN +
  (commit; Pack Chat)                           │ validate-pack GREEN EXCEPT 32′
        │                                       │ (32′ expected-RED: tree built, monolith
        └──────────────────────────────────►   │  still present — by design, §6 split)
                                                ▼
                                          DELETE + FINAL VERIFY (Pack-Chat-direct):
                                            D1 git rm pack-ops/BACKLOG.md + CHANGELOG.md
                                            → D2 ref sweep → D3 manifest
                                            → FULL validate-pack (NOW GREEN incl. 32′:
                                               tree present + monolith ABSENT)
                                            → commit the ATOMIC commit (Pack Chat)
                                                ▼
                                          Phase E (end-of-batch reviewer)
```

(Phase A engine + validators + tests landed at C-1 already — `A1` anchor, `A2` changelog grouping,
`A3/A4` regex lockstep, `A5` Check-34 token, `A6/A7` TOC, `A8` mirror-demote, `A9` Check 32′, `A10-13`
Check3/40/48/PM, `A14` runtime repoint, `A15` tests, `A16` manifest. C-1 was GREEN because the tree was
absent → 32′ SKIPs. C-1 is unchanged by this re-sequence.)

### Ordering justification (RESOLUTION A — atomicity is the invariant; SUPERSEDES the old staged order)

**State-claim (SUPPORTED, measured at `validate-pack.py:3215`):** Check 32′ has exactly THREE satisfiable
states — (i) tree-absent → SKIP (`is_dir` gate, `:3206`); (ii) tree present + monolith ABSENT → PASS; (iii)
tree present + monolith PRESENT → **FAIL** (`:3215-3221`). State (iii) is the tree+monolith COEXISTENCE
window. Any commit whose END-STATE is (iii) is RED. The old staged order's build-commit and doc-fix-commit
both ended in state (iii) → the old §4 "tree+monolith → both-present OK" claim (former point 3/5) was FALSE
against the landed guard. This re-sequence eliminates state (iii) as a commit end-state.

1. **C-1 (Phase A) — landed, GREEN, unchanged.** Engine + validators + tests landed while the tree was absent
   (state i → SKIP). Not re-touched.
2. **Commit 1 (pre-normalize, B0a–B0c) — monolith→monolith, GREEN.** Edits `pack-ops/BACKLOG.md` only; NO
   tree yet → 32′/33/34 SKIP (state i); Check 3 (A10-repointed) SKIPs on tree-absent. The B0c diff gate is a
   coder/review artifact (preserved), not a CI gate. Commit end-state = (i) → GREEN.
3. **Commit 2 (ATOMIC: build B1–B9 + ref-fix C1–C8 + delete D1–D3) — the ONLY state-(ii) end-state.** The
   EDITS (build trees, author `_rules`/`_intro`, decompose, toc, B8/B9, fix the ~16 refs) transit through
   state (iii) WITHIN the commit's working tree — but the commit is NOT taken there. The destructive
   `git rm` (D1) removes the monoliths in the SAME commit, so the commit's END-STATE is (ii): tree present +
   monolith absent → 32′ PASS; 33 toc-in-sync PASS (B5); 34 cross-ref PASS (widened defined-ID set); the ref
   sweep (D2) confirms zero actionable hits → FULL validate-pack GREEN. The oracle (B6) gates the deletion
   (safe-before-delete) INSIDE the commit.

**Why atomic is irreducible here:** the no-mirror invariant (Check 32′) and the "verify-before-delete"
invariant (the oracle must run while the monolith still exists, to diff the tree against it) are jointly
satisfiable ONLY if build-verify-delete share one commit. Splitting them re-introduces state (iii) at a
commit boundary. No commit leaves CI red because Commit 1 ends in state (i) and Commit 2 ends in state (ii);
state (iii) exists only transiently inside Commit 2's working tree, never as a committed end-state. The
coder/Pack-Chat verification boundary inside Commit 2 is specified in §5/§6 (the coder reaches "GREEN except
the expected-RED 32′"; Pack Chat's post-`git rm` run reaches FULL GREEN before the commit).

---

## 5. COMMIT SEQUENCING — Section (C)

**Actor model (user decision 2026-06-04).** A **pack-coder does ALL editing** for BD-203 — every major
edit, INCLUDING the PM-only files (`pack-ops/BACKLOG.md`/`CHANGELOG.md`, the trinity, `README.md`,
`PACK-AGENTS.md`, `PACK-CHAT.md`), which Pack Chat scopes INTO the coder's prompt via the existing
PACK-AGENTS.md "PM-only off-limits UNLESS explicitly scoped in" clause (PACK-AGENTS.md:130-131,157-159).
**Pack Chat does ONLY:** the git commits (`agents-never-commit`) + the irreducible destructive DELETION of the
two monoliths in Commit 2 (destructive, user-approved). This RESOLVES former TENSION 1/2/3 + G-3 + G-6 — they all
collapse to "coder edits (scoped in); Pack Chat commits + deletes."

**RE-SEQUENCED 2026-06-04 — RESOLUTION A (atomic).** The old 4-commit staged order (build → ref-fix →
delete) is REPLACED by a 2-commit atomic structure: the landed Check 32′ (`validate-pack.py:3215`) FAILs on
the tree+monolith coexistence window the staged order required (see §4). C-1 (engine + validators, already
landed) is unchanged; the former C-2/C-3/C-4 collapse into **Commit 1 (pre-normalize)** + **Commit 2 (atomic
convert: build + ref-fix + delete)**.

Per-commit cadence: **fresh pack-coder per commit** → **bounded review/fix cycle** (`review-fix-cycle`:
review-1 → [clean ⇒ commit | findings ⇒ fix-1 → review-2 → [clean ⇒ commit | fix-2 → review-3 →
architect-escalate if dirty]]; max 3 reviewer / 2 fix-coder per commit). Pack Chat restates cycle position at
each coder/fix completion (`review-cycle-position-checkpoint`) and NEVER self-reviews. **Commit 2's coder does
all EDITS but NOT the `git rm` (`per-action-approval-sub-agents` forbids a coder running a destructive
deletion on its own authority); Pack Chat performs the `git rm` + the FULL post-delete validate-pack run
before committing (§6 verification split).** End-of-batch reviewer (Phase E) runs once on the full batch.
Approval gate before EACH commit; Commit 2 additionally needs explicit destructive approval for the `git rm`.

| # | Commit subject (proposed) | Keyword | Tasks | File set | Actor + verification |
|---|---|---|---|---|---|
| **C-1** (landed) | `feat: v11 — BD-203 per-entry engine + validator redesign (no asset change) (pack-only)` | `pack-only` | A1–A16 | `scripts/lib/per-entry/{decompose,_lib,toc-regenerate,mirror-generate}.sh`, `scripts/validate-pack.py`, `scripts/lib/{recommendation,detect}.sh`, `scripts/tests/{test-per-entry,test-validate-pack-checks-32-33-34,test-validate-pack-check-removed-doc-advisory,test-validate-pack-checks-36-37-38,test-validate-pack-check-40}.sh`, `test-fixtures/manifest.txt` | pack-coder; GREEN (tree absent → 32′ SKIPs) |
| **Commit 1** (pre-normalize) | `feat: v11 — BD-203 pre-normalize monolith to uniform entries (pack-only)` | `pack-only` | B0a–B0c | `pack-ops/BACKLOG.md` (pre-normalize), `test-fixtures/manifest.txt` | **pack-coder** (Pack Chat scopes `pack-ops/BACKLOG.md` IN). Monolith→monolith; NO tree → 32′/33/34 SKIP → GREEN. B0c diff gate is a coder review artifact. |
| **Commit 2** (ATOMIC convert) | `feat: v11 — BD-203 convert to per-entry sole-SSOT; delete monolith (pack-only)` | `pack-only` | B1–B9, C1–C8, D1–D3 | `/backlog/**` + `/changelog/**` (new trees), trinity ×3, `pack-ops/{PACK-AGENTS,PACK-CHAT,HELP-FRAGMENT-PACK}.md`, `README.md`, `.claude/.codex/.gemini` agent+skill copies, `pack-ops/BACKLOG.md` + `pack-ops/CHANGELOG.md` (`git rm`), `test-fixtures/manifest.txt` | **SPLIT (§6):** pack-coder does ALL EDITS (build trees, `_rules`/`_intro`, decompose, toc, B8/B9, fix ~16 refs) — scoped into the trees + the PM-only doc surfaces; coder PREFLIGHT = §7 oracle GREEN + validate-pack GREEN **EXCEPT** the expected-RED Check 32′. Then **Pack-Chat-direct** `git rm` the two monoliths (destructive, user-approved) + FULL validate-pack (NOW GREEN incl. 32′) BEFORE committing. |

**Keyword verification (Check 36).** Every commit is `pack-only`. `pack-only` DENIES `project-template/` +
`supporting-docs/`. NONE of C-1 / Commit 1 / Commit 2 touches those prefixes (project-side surfaces are
BD-206 — §3); the new trees `/backlog/`+`/changelog/` are at repo root (not under the denied prefixes) →
permitted; the `git rm` of the two `pack-ops/` monoliths in Commit 2 is also within `pack-only`. **Keyword-token
trap (`commit-subject-keyword-token-trap`):** the ONLY scope-keyword token in each subject is the trailing
`(pack-only)`; even though Commit 2 is scoped to a coder over PM-only files, the SUBJECT must never carry the
literal `PM-only`/`project-only`/`pack-memory-only` token (it would DENY `scripts/`/non-project paths and FAIL
the gate) — describe the work with non-keyword words ("convert", "per-entry", "delete monolith"). **Commit 2
fixes all ~16 wrong-model surfaces + the skill/agent copies in ONE commit** (no split). The coder applies the
trinity `## Pack memory` rule correction MECHANICALLY (architect-defined in the approved design pair) and
follows the §8 lockstep trinity/PACK-AGENTS propagation.

**Commit-shape note (`PACK-CHAT.md` "Batch close commit shapes").** Single-BD batch → the final fix +
status-flip combine into one commit. BD-203's `Status: Open → Resolved` flip lands in `pack-ops/BACKLOG.md`
— BUT that file is `git rm`'d in Commit 2. **The status flip must instead land in the new per-entry file
`/backlog/BD-203.md`** (the post-conversion SSOT). SURFACE G-7: sequence the BD-203 status flip as an edit to
`/backlog/BD-203.md` AFTER Commit 2 (or fold into the implicit batch-completion flip), since the monolith no
longer exists. This is a real consequence of self-migrating the very backlog that tracks this BD.

---

## 6. ACTOR ASSIGNMENT — Section (D) — RESOLVED (user decision 2026-06-04)

**USER DECISION (2026-06-04).** A **pack-coder does ALL editing** for BD-203 — every major edit, INCLUDING
the PM-only files — which Pack Chat scopes INTO the coder's prompt via the existing PACK-AGENTS.md "PM-only
off-limits to all agents UNLESS the caller's prompt explicitly scopes them in" clause (PACK-AGENTS.md:130-131)
+ the "`pack-coder` MAY scope a per-entry directory in for an explicit BD" clause (PACK-AGENTS.md:157-159).
**Pack Chat does ONLY** the git commits (`agents-never-commit`) and the irreducible destructive DELETION of
the monoliths in Commit 2. This RESOLVES former TENSION 1/2/3 + G-3 + G-6.

**Authority recap (PACK-AGENTS.md § "PM-only files and directories").** PM-only files
(`pack-ops/BACKLOG.md`/`CHANGELOG.md`, the pack-root trinity `CLAUDE.md`/`AGENTS.md`/`GEMINI.md`,
`README.md`, `PACK-AGENTS.md`, `PACK-CHAT.md`, `PACK-MEMORY-RATIONALE.md`) + the `/backlog/`+`/changelog/`
per-entry trees are off-limits to agents EXCEPT when the caller scopes them in — which is exactly what Pack
Chat does here for every BD-203 edit. `pack-product` (engine, validators, tests, `.claude/.codex/.gemini`
copies, manifest) was never restricted from the coder.

### RESOLVED dispositions (former tensions/surfaces collapse to "coder edits, scoped in")
- **TENSION 1 (B0 pre-normalize + the EDIT side of the delete) → pack-coder, scoped in.** Pack Chat scopes
  `pack-ops/BACKLOG.md` into the Commit-1 coder prompt (B0 pre-normalization in place). The `git rm` DELETION
  (Commit 2) is the only PM-only action Pack Chat retains (destructive, irreducible).
- **TENSION 2 (the 209+11 generated per-entry files) → pack-coder, scoped in.** The coder runs the decompose
  engine (scoped the `/backlog/`+`/changelog/` directories in) and stages the generated tree.
- **TENSION 3 (`_rules.md`/`_intro.md`/`_toc.md`) → pack-coder, scoped in.** The coder authors `_rules.md` +
  `_intro.md` (per the design's no-mirror contract + D1 audience/purpose headers) and regenerates `_toc.md`,
  all within the scoped-in directories.
- **G-3 (`HELP-FRAGMENT-PACK.md` actor) → pack-coder, scoped in.** Folded into the Commit-2 coder scope; no
  separate decision needed.
- **G-6 (split-vs-combine) → ONE atomic commit.** A single Commit-2 coder corrects all ~16 surfaces + the
  skill/agent copies in one `pack-only` commit; no split.

The trinity `## Pack memory` rule correction is still **architect-defined** (fixed in the approved design
pair); the coder applies it MECHANICALLY and follows the §8 lockstep trinity/PACK-AGENTS propagation. Because
the coder (not Pack Chat) makes every edit, the standard bounded review/fix cycle (fresh coder + reviewer per
commit) applies cleanly — no Pack-Chat-direct edit needs the `review-cycle-position-checkpoint`
"Pack-Chat-edit-is-an-implementation" carve-out.

### Commit-2 verification split (load-bearing — the coder cannot reach FULL green at its stage)
Commit 2 is atomic in the COMMITTED end-state, but its work is performed by two actors with DIFFERENT
verification boundaries (per `per-action-approval-sub-agents`: a coder may NOT run a destructive `git rm` on
its own authority):

1. **pack-coder (ALL edits, scoped in).** Builds the trees, authors `_rules.md`/`_intro.md`, decomposes,
   regenerates TOCs, applies B8/B9, and fixes the ~16 doc-model refs. After the edits the working tree is in
   state (iii) — tree built + monoliths STILL PRESENT — so **Check 32′ is RED BY DESIGN**. The coder therefore
   CANNOT reach full validate-pack GREEN. **Coder PREFLIGHT contract:** (a) the §7 ORACLE is GREEN — the tree
   captures every entry, content-faithful, count == measured (B6 safe-before-delete); AND (b) `validate-pack`
   is GREEN on EVERY check EXCEPT Check 32′, which is EXPECTED-RED-until-deletion (the coder asserts the ONLY
   failing check is 32′ with the "monolith still present while tree exists" message, and no other). The coder
   reports this expected-32′-RED state explicitly; it is NOT a PREFLIGHT failure.
2. **Pack-Chat-direct (the destructive delete + final verify).** Pack Chat performs
   `git rm pack-ops/BACKLOG.md pack-ops/CHANGELOG.md` (user-approved), runs the D2 ref sweep, regenerates the
   manifest (D3), and runs the **FULL `validate-pack` — now GREEN incl. Check 32′** (tree present + monolith
   ABSENT = state (ii)) — BEFORE taking the commit. Only this FULL-green run authorizes the commit.

**No Check-32′ design change is needed** — Resolution A keeps the guard strict (it correctly forbids the
tree+monolith coexistence END-STATE); the split simply assigns the transient-RED window to the coder's
edit stage and the GREEN-restoring `git rm` to Pack Chat within the SAME commit. (If a reviewer judges a
guard change IS needed, that is an architect escalation, not a planner invention — SURFACE, do not invent.)

**Net actor map:**
| Commit | Tasks | Actor |
|---|---|---|
| C-1 (landed) | A1–A16 (engine/validator/test/manifest) | pack-coder |
| Commit 1 | B0a–B0c (pre-normalize monolith) | pack-coder (Pack Chat scopes `pack-ops/BACKLOG.md` IN) |
| Commit 2 — edits | B1 (mkdir), B4 (decompose), B5 (toc), B8/B9 carry-fwd | pack-coder (scoped `/backlog/`+`/changelog/` IN) |
| Commit 2 — edits | B2 (`_rules.md`), B3 (`_intro.md`) | pack-coder (scoped `/backlog/`+`/changelog/` IN) |
| Commit 2 — edits | C1/C2 trinity, C3 PACK-AGENTS, C4 PACK-CHAT, C5 README, C6 HELP-FRAGMENT, C7 `.claude/.codex/.gemini` copies, C8 manifest | pack-coder (Pack Chat scopes the PM-only doc surfaces IN) |
| Commit 2 — coder PREFLIGHT | B6 oracle GREEN + validate-pack GREEN EXCEPT expected-RED Check 32′ | pack-coder (verification boundary; reviewer confirms) |
| Commit 2 — delete + final verify | D1 `git rm` monoliths → D2 sweep → D3 manifest → FULL validate-pack GREEN | **Pack-Chat-direct** (destructive, user-approved — the ONLY non-coder action; the GREEN-restoring step) |
| BD-203 status flip → `/backlog/BD-203.md` (G-7) | pack-coder (scoped IN) or Pack-Chat-direct per batch-close shape |


---

## 7. VERIFICATION STRATEGY — Section (E)

### The oracle suite (run at Phase B6, BEFORE deletion; re-run at Phase E)

All counts are MEASURED at conversion time, NEVER hard-coded (EE-P1: the count is a moving target).

1. **Count oracle (backlog).** `count(/backlog/*.md matching ^BD-\d+[a-z]*\.md$)` ==
   `grep -cE '^\*\*BD-' pack-ops/BACKLOG.md` (the LIVE post-Phase-B0 monolith count — 209 today, MEASURE it).
   Per-entry file count == monolith header count exactly.
2. **Count oracle (changelog).** `count(/changelog/v*.md matching ^v\d+\.md$)` ==
   `grep -cE '^## v' pack-ops/CHANGELOG.md` (11 today).
3. **Phase-B0 diff gate** (B0c). The pre-normalization monolith→monolith diff shows ONLY +19 new entry blocks
   + −5 scaffolding H2s/wrapper/blurbs, NO change to any existing entry body. Reviewed before decompose.
4. **Content-faithfulness oracle.** For the 187+2 pre-existing entries: per-entry body (minus line-1
   back-pointer) is byte-faithful to the prior monolith span (`**BD-NNN[b] — Title**` + `Status:` + body). For
   the 19 NEW entries: the table row's (Item, Description, Commit) triple is preserved (amendment §C — there is
   no prior full-entry body, so the target is triple-preservation). Plus the v10 section's 5 entries
   (BD-059/020/021/022/023) byte-faithful with TRUE statuses. Method: concatenate the tree in BACKLOG order,
   strip back-pointers, diff the ENTRY SPANS against the post-B0 monolith — a VERIFICATION-ONLY transient
   (never committed, deleted after the diff passes; NOT a kept mirror).
5. **Status-preservation oracle.** Every `Status:` value appears on exactly one per-entry file; the
   distribution {Open 28, Unblocked 1, Deferred 11, Resolved 165, Deprecated 3, Cancelled 1} sums to 209.
6. **No-monolith oracle (post-delete, Phase D).** `! -f pack-ops/BACKLOG.md && ! -f pack-ops/CHANGELOG.md`
   AND `grep -rn "pack-ops/BACKLOG.md\|pack-ops/CHANGELOG.md"` returns ZERO ACTIONABLE (non-`maintenance-docs/`)
   hits.
7. **Validator oracle.** `python3 scripts/validate-pack.py` GREEN with no monolith: Check 32′ asserts absence
   + tree present; Check 33 toc-in-sync active+passing; Check 34 cross-ref active+passing (admits `BD-167b`);
   Check 3 (repointed) / Check 40 (corrected) / Check 48 (repointed) / PM-only (corrected) all pass.

### ENCODING SURFACES per changed check (`enumerate-encoding-surfaces` — lock-step update required)

| Validator / surface changed | Its TEST file (lockstep) | CI workflow line | Cross-ref docs |
|---|---|---|---|
| Check 32 → 32′ (A9) | `scripts/tests/test-validate-pack-checks-32-33-34.sh` Group A (A15-T2) | validate-pack.yml:159 | trinity rule (C1), README (C5) describe the invariant |
| Check 33 (active; KEEP) | same test file Group B | validate-pack.yml:159 | `_rules.md` no-mirror statement (B2) |
| Check 34 token widen (A5) + `_collect_defined_ids` (A4) | same test file Group C + new `BD-167b` case (A15-T2) | validate-pack.yml:159 | `_rules.md` ID-extraction rule (B2) |
| STREAMS regex widen (A3/A4) | same test file fixtures (`:145`) (A15-T2) | validate-pack.yml:159 | `_rules.md` filename regex (B2); `_lib.sh`/`toc-regenerate.sh` regexes (A3/A4) |
| Check 3 repoint (A10) | (no dedicated test today — verify manual scan; consider adding) | validate-pack.yml:97 | — |
| Check 40 correct (A11) | `scripts/tests/test-validate-pack-check-40.sh` (A15-T5) | validate-pack.yml:168 | — |
| Check 48 repoint (A12) | `scripts/tests/test-validate-pack-check-removed-doc-advisory.sh` (A15-T3) | validate-pack.yml:198 | — |
| PM-only path list (A13) | `scripts/tests/test-validate-pack-checks-36-37-38.sh` T6d/T6e (A15-T4) | validate-pack.yml:162 | PACK-AGENTS PM-only list (C3) |
| Engine mirror-demote (A8) | `scripts/tests/test-per-entry.sh` Groups 3/4/5/6 (A15-T1) | validate-pack.yml:156 | `_lib.sh`/`mirror-generate.sh` headers (A8) |

**Manifest discipline (`manifest-regen-on-v11-surface`).** Every commit (C-1, Commit 1, Commit 2) touches a v11-surface
dir (`scripts/`, `pack-ops/`) → each regenerates `test-fixtures/manifest.txt` (`bash test-fixtures/build.sh
--all --clean`) and stages it iff the diff is non-empty. (The new `/backlog/`+`/changelog/` trees are NOT
v11-surface dirs, but Commit 1 + Commit 2 also edit `pack-ops/` (pre-normalize / `git rm`), so each IS v11-surface.)

### CI-guard measure-then-bound (`ci-guard-design-measure-then-bound`)
The validator redesign was MEASURED against actual state (EE-P1/P2 + V3 EE-5/EE-6): Check 34/STREAMS widening
admits EXACTLY the 2 suffix entries (`BD-167b`,`BD-169b`) — not broader; Check 32′ verified against the
projected no-monolith end-state; `_collect_defined_ids` sized to the live tree. No allowlist is widened to
swallow unclassified hits.

---

## 8. CROSS-DOC CONSISTENCY — Section (F)

The ~16 wrong-model surfaces are corrected in **Phase C, BEFORE the Phase-D deletion**, so no commit leaves a
half-corrected state. Sequencing rationale: no validator asserts doc PROSE, so C is CI-neutral; landing C
before D means at the moment the monolith is deleted, every doc already states the no-mirror model — there is
never a window where the files are gone but the docs still call them "regenerated mirrors," nor a window where
the docs say no-mirror but the files still exist as a live mirror (the monolith is conversion-input-only after
Phase B, never a live mirror).

**The trinity `## Pack memory` rule change (C1) follows the PACK-CHAT.md "Rule-change propagation procedure"
(§ "Keeping CLAUDE.md, AGENTS.md, GEMINI.md, and PACK-AGENTS.md current"):**
| Step | Surface | Applies to BD-203? |
|---|---|---|
| 1 | Corpus imperative ×3 trinity (`CLAUDE.md`/`AGENTS.md`/`GEMINI.md` `## Pack memory`) incl. `[roles:]` tag | **YES** — C1 |
| 2 | `pack-ops/PACK-MEMORY-RATIONALE.md` `## <slug>` entry (C3 bijection) | **NO** — EE-P5: this rule has NO `[rationale: slug]` → not in the bijection set. Do NOT invent a RATIONALE.md edit. |
| 3 | Thin memory-cache pointer (out-of-repo) | Pack-Chat upkeep (no validator gate) |
| 4 | Reference surfaces (`PACK-AGENTS.md`/`PACK-CHAT.md` one-line refs) | **YES** — C3/C4 (same commit as C1) |
| 5 | `pack-ops/.spawn-rule-manifest.txt` slug→canonical+references | **NO** — gated on a slug (EE-P5: no slug for this rule) |
| 6 | `test-fixtures/manifest.txt` regen | **YES** — C8 |
- **Order:** corpus (1) → references (4) in the SAME commit (Commit 2) → cache (3) Pack-Chat upkeep → manifest (6)
  regen. Order is END-STATE-verified (trinity-parity), not gate-sequenced — a commit is atomic.
- **Trinity-parity vs substance (V3 §3.3.1 / CLAUDE.md note + P-missed-7):** the trinity rule enforces PARITY
  (the 3 CLI files say the same thing at pack-root); it does NOT verify correctness. The no-mirror substance
  is driven by the user's fail-loud standard, not parity. The PROJECT-side trinity copy carries the same rule
  text but is a SEPARATE artifact (`pack-project-separation-of-concerns`) — corrected under BD-206, NOT here.

**`cross-cli-reference-normalization`:** when editing C2 structure lines in the trinity, GEMINI uses a prose
"Key docs:" form (research §5 trinity asymmetry) — substitute the audience-correct canonical value, not a
byte-identical copy.

---

## 9. SURFACE, DO NOT RESOLVE — Section (G) — open gaps / boundary decisions for Pack Chat / user

- **G-1 — RESOLVED (user decision 2026-06-04).** The pack-coder does ALL editing, scoped in (incl. the B0
  pre-normalization of `pack-ops/BACKLOG.md`); Pack Chat performs ONLY the Commit-2 `git rm` deletion +
  commits. See §6. No open decision.
- **G-2 — `detect.sh` client-behavior adjacency (§2 A14b / V3 §3.5 R4).** Repointing the pack-surface branch
  of `detect_pack_surface` touches a `_SANCTIONED_PACK_SIDE_SHIPPED` file (CI Check 47). Must be a
  pack-surface-only conditional leaving the client branch + the install-map↔constant equality untouched.
  Confirm the approach before the coder edits it.
- **G-3 — RESOLVED (user decision 2026-06-04).** `pack-ops/HELP-FRAGMENT-PACK.md` (C6) is edited by the Commit-2
  pack-coder, scoped in. No actor decision needed. See §6.
- **G-4 — pack-vs-project skill-master divergence (C7 / V3 R5).** BD-203 corrects the pack-copied
  `.claude/.codex/.gemini` boundary-investigation/pack-startup/etc. skill prose, but the
  `project-template/skills/*/SKILL.md` MASTER is PROJECT-side (denied by `pack-only`) → BD-206. A KNOWN,
  scheduled temporary divergence (pack copies corrected, master pending). BD-206 closes it before launch
  (launch-coherence). Surface the divergence to the user.
- **G-5 — tracker-lib runtime repoint deferred to BD-204 (V3 §3.5).** The tracker libs
  (`tracker-agent-read/doctor/header-snapshot/migrate-forward/migrate-reverse.sh`) read/WRITE the monolith but
  are DORMANT in flat-file mode (today's mode — no `tracker.toml`), so the deletion does not break them at
  BD-203 time. Their runtime repoint to the tree is BD-204 (testable only when the tracker is exercised) — a
  LOGICAL-FIT deferral. BD-203 corrects only any wrong-model COMMENT adjacent to the pack-surface. Confirm
  the BD-204 anchor with the user (the BD-204 entry already carries the second-pass ratification clause).
- **G-6 — RESOLVED (user decision 2026-06-04).** Commit 2 is ONE `pack-only` commit by a single coder (scoped
  the PM-only files in); no split. See §6.
- **G-7 — BD-203's own `Status: Open → Resolved` flip has no monolith to land in (§5).** The flip normally
  edits `pack-ops/BACKLOG.md`, which Commit 2 `git rm`s. The flip must land in the new `/backlog/BD-203.md`
  post-conversion (or be folded into the implicit batch-completion flip). A self-migration artifact — confirm
  sequencing.
- **G-8 — `_intro.md` content scope (resolved by amendment, noted).** The amendment §F RESOLVED the V3 open
  `_intro.md` question (human-only orientation; not "decide + surface"). No open decision — recorded so a
  reviewer does not re-open it.
- **G-9 — verification-transient hygiene.** The content-faithfulness oracle's concatenated reconstruction
  (§7 #4) is a transient that MUST be deleted after the diff and NEVER committed (it would re-introduce a
  mirror shape). Flag to the coder/Pack Chat as a hard no-commit artifact.
- **G-10 — Reviewer prompt hygiene.** Per `### Agent invocation rules` "No prior reviews to pack-reviewer":
  the reviewer prompts for C-1 / Commit 1 / Commit 2 reference THIS plan + the design pair ONLY, never a prior
  `PACK-REVIEW-*.md`.

These are SURFACED, not resolved. The plan implements the FIXED V3+amendment design; it does not redesign or
resolve gaps (`scope-deliverables-to-the-ask`).

---

## 10. RISKS (carried from V3 §7, re-confirmed at HEAD a630a31)

- **R1 — count drift.** BACKLOG grows during development. MITIGATION: the oracle is a live grep at conversion
  time, never a literal (EE-P1; §7 #1-2).
- **R2 — CI red mid-conversion.** Checks 32/33/34 flip ACTIVE when the tree appears. MITIGATION: Phase A lands
  the validator redesign BEFORE Phase B creates the tree (§4 atomicity).
- **R3 — changelog granularity regret** (per-release coarser than per-point-release). MITIGATION: it is the
  only preserve-all-correct choice without fabricating anchors (V3 §2.3); finer granularity later is an
  additive re-decompose, not data loss.
- **R4 — `detect.sh` client-behavior adjacency** (G-2).
- **R5 — pack/project skill-master divergence** (G-4).
- **R6 — `Unblocked` status** — RESOLVED (D2 admits it canonical; A7 + B2 encode it). Noted as closed.
- **R7 — self-migration status-flip** (G-7) — the BD being implemented tracks itself in the file being
  deleted.

---

## RULES-APPLIED VERIFICATION BLOCK

**REVISION 1 (2026-06-04, single-actor):** §5 + §6 updated per user decision — a pack-coder does ALL editing (PM-only files scoped in); Pack Chat does only the commits + the monolith deletion. §9 G-1/G-3/G-6 marked RESOLVED. (The commit STRUCTURE in this note was subsequently re-sequenced — see RE-SEQUENCE below; the actor principle stands.)

**CARRY-FORWARD (2026-06-04, C-1 review, user-approved):** §2 Phase B gained B8 (drop the dead `_v8-resolved-archive.md` residue across `_lib.sh` + `validate-pack.py` Check 32 allowlist + Check 34 SKIP — review SHOULD-1) and B9 (widen pack-backlog TOC `entry_sort_key` for the suffix form — review NIT-1). Both LOGICAL-FIT (observable/testable only at Phase B). No §5/§6 change forced.

**RE-SEQUENCE (2026-06-04, RESOLUTION A, user-approved):** §4/§5/§6 re-sequenced to a 2-commit ATOMIC structure (Commit 1 pre-normalize; Commit 2 build+ref-fix+delete). Driver: the landed Check 32′ (`validate-pack.py:3215`, re-verified this pass) FAILs on the tree+monolith coexistence window the old staged order required. §6 adds the Commit-2 verification split (coder reaches GREEN-except-expected-RED-32′; Pack Chat `git rm`s + reaches FULL GREEN before committing). Preserved: B0c diff gate, B6 oracle, B8/B9 + FLAG-(b) carry-forwards, manifest discipline. No Check-32′ design change (guard stays strict). Design / verification strategy / EE-P1..P7 UNCHANGED.

| Rule (as named in prompt) | Verification evidence (QUOTED, not summarized) | Conclusion |
|---|---|---|
| **read-in-full + no-derivation** | READ-IN-FULL row below: every named doc + memory file Read DIRECTLY via the Read tool with per-file proof (line count or first/last line); the design PAIR, both research docs, BD-203/204/206 entries, trinity `## Pack memory`, PACK-AGENTS, PACK-CHAT, the 4 per-entry tooling files, the validator checks, and all 15 curated memory files. No named doc derived. | COMPLIANT |
| **empirical-evidence-blocks (planner state-claims)** | §1 EE-P1..EE-P7 + §4 re-sequence: every state-claim carries command + verbatim output + HEAD + interpretation + SUPPORTED. The Check-32′-FAILs-on-coexistence claim driving RESOLUTION A was re-verified DIRECTLY this pass at `validate-pack.py:3215` (`if mirror_path.is_file(): fail("<mirror> still present while <stream>/ tree exists")`) → SUPPORTED. | COMPLIANT |
| **bounded-review-fix-cycle** | §5/§6 (re-sequenced) per-commit cadence for C-1/Commit-1/Commit-2: fresh pack-coder → review-1 → [clean⇒commit \| fix-1 → review-2 → [clean⇒commit \| fix-2 → review-3 → architect-escalate]]; max 3 reviewer/2 fix-coder; fresh coder per commit; Commit-2's coder PREFLIGHT is GREEN-except-expected-RED-32′ (§6 split) and Pack Chat's post-`git rm` run is FULL-GREEN before commit; end-of-batch reviewer (Phase E). | COMPLIANT |
| **agents-never-commit** | §0 + §5/§6 (re-sequenced): the coder edits but NEVER commits and NEVER runs the destructive `git rm` (`per-action-approval-sub-agents`); Pack Chat stages/commits every commit + performs the Commit-2 `git rm` (user-approved). The plan plans commits; runs no git. | COMPLIANT |
| **per-action-approval-sub-agents** | §6 Commit-2 verification split: the coder may NOT run the destructive `git rm` on its own authority → the delete + FULL-green verify is Pack-Chat-direct (user-approved); the coder's PREFLIGHT stops at GREEN-except-expected-RED-32′. | COMPLIANT |
| **manifest-regen-on-v11-surface** | §2 A16/B7/B8/B9/C8/D3 + §7: every commit (C-1, Commit 1, Commit 2) touches a v11-surface dir (`scripts/`/`pack-ops/`) — incl. the B8/B9 `scripts/` edits — → regenerate `test-fixtures/manifest.txt` via `bash test-fixtures/build.sh --all --clean`, stage iff non-empty. | COMPLIANT |
| **ci-guard-measure-then-bound** | §7 "CI-guard measure-then-bound": Check 34/STREAMS widening sized to EXACTLY the 2 measured suffix entries (V3 EE-5/EE-6); Check 32′ verified against projected no-monolith end-state; §2 B8 SHRINKS the Check 32 `known_supporting` allowlist + Check 34 SKIP to drop the now-DEAD `_v8-resolved-archive.md` (no longer emitted post-amendment-§G) — allowlist sized to KEEP-only, never swallowing a dead entry. | COMPLIANT |
| **separate-pack-ops-from-pack-product** | §3/§5/§6 (re-sequenced): one atomic Commit 2 `pack-only`; pack-ops governance (trinity/README/PACK-AGENTS/PACK-CHAT) and pack-product (skill/agent copies) are both edited by the scoped-in coder but tracked as distinct surfaces in the §3 file list; no pack-ops file mixed into a `project-only`/`PM-only` scope claim (the commit claims `pack-only`, which permits both). | COMPLIANT |
| **pack-project-separation + no-deferral-without-user-direction** | §3 "NOT touched (BD-206 boundary)"; §8 trinity pack-copy ≠ project-copy (separate artifacts, BD-206); NO pack-side BD-203 work deferred (all in §2 Phases A–E). | COMPLIANT |
| **filename-uniqueness-heuristic** | This plan is `PLAN-BD-203.md` (repo-unique — `find` confirms no collision). New per-stream `_rules.md`/`_intro.md`/`_toc.md` are structurally-required collisions (per-stream) — prose carries `/backlog/`+`/changelog/` path context throughout. | COMPLIANT |
| **pack-repo-code-comment-deferrals** | §2 A8: any deferral comment uses the typed `# TODO(version): TD-TBD — retire mirror-generate project-side at BD-206`, never plain `# TODO`/`# FIXME`. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Leads with goal + task breakdown + sequencing; SURFACES gaps (§9) rather than resolving; no redesign, no edge-case sprawl. | COMPLIANT |
| **rules-applied-verification-block (+ no-derivation)** | This block; every row QUOTED evidence (none empty); READ-IN-FULL row below with direct-read proof per named doc + memory file. | COMPLIANT |

### READ-IN-FULL row (per-file direct-read proof)
| Document | Direct Read? | Proof |
|---|---|---|
| `ARCHITECTURE-BD-203-V3.md` | YES | 413 lines; L1 "# ARCHITECTURE-BD-203-V3 — Shared per-entry engine co-design ..." → L413 "**End of ARCHITECTURE-BD-203-V3.md**". |
| `ARCHITECTURE-BD-203-V3-AMENDMENT.md` | YES | 244 lines; L1 "# ARCHITECTURE-BD-203-V3-AMENDMENT ..." → L244 "**End of ARCHITECTURE-BD-203-V3-AMENDMENT.md**". |
| `RESEARCH-BD-203-BLAST-RADIUS.md` | YES | 466 lines; L1 title → L466 "every number above is independently measured from primary sources at HEAD 1936136." |
| `RESEARCH-PROJECT-PER-ENTRY-BLAST-RADIUS.md` | YES | 421 lines; L1 title → L421 "every project-side claim above is independently measured from primary sources at HEAD 1936136." |
| BD-203 entry (`pack-ops/BACKLOG.md:3330-3351`) | YES | Read offset 3330 lim 90; header L3330 → Position L3351. |
| BD-204 entry (`:3355-3369`) | YES | same Read; header L3355 → Position L3369 (REVERSIBILITY second-pass clause L3362). |
| BD-206 entry (`:3389-3400`) | YES | same Read; header L3389 → Position L3400. |
| `CLAUDE.md` (incl. `## Pack memory`) | YES | Provided in full via system context; the "Per-entry trees vs mirrors" rule Read directly at L433-448 (`[roles: universal]`, NO rationale slug — EE-P5). |
| `pack-ops/PACK-AGENTS.md` | YES | 226 lines; L1 "# PACK-AGENTS.md" → L226 "Always run `git add -A && git status` ... before any commit." PM-only list L130-159 + forward-note L170-179 read. |
| `pack-ops/PACK-CHAT.md` | YES | 310 lines; L1 "# PACK-CHAT.md" → L310 "... not a hard-enforced step sequence." Rule-change propagation procedure L295-309 read. |
| `scripts/lib/per-entry/_lib.sh` | YES | 439 lines; L1 header → L439 `pe_id_from_filename`; stream tuples L64-122. |
| `scripts/lib/per-entry/decompose.sh` | YES | 288 lines; L1 → L287 PYEOF; anchors L110-153. |
| `scripts/lib/per-entry/toc-regenerate.sh` | YES | 295 lines; L1 → L294; order_groups L198-221, title regex L123, entry regex L83-90. |
| `scripts/lib/per-entry/mirror-generate.sh` | YES | header L1-60 read directly (purpose statement). |
| `scripts/validate-pack.py` | YES | Read STREAMS L296-355, Check 32 L3142-3345, Check 33/34 L3490-3649, PM-only L3821-3859, Check 3 L457-496, Check 40 L5113-5172, Check 48 L7140-7194 directly. **Re-sequence pass: re-read the LANDED Check 32′ L3195-3249 directly — L3215 `if mirror_path.is_file(): fail(...)` is the coexistence-FAIL that drives RESOLUTION A.** |
| `scripts/lib/detect.sh` | YES | L38-62 read directly (`detect_pack_surface` + DENY-LIST markers). |
| `scripts/lib/recommendation.sh` | YES | monolith read sites grepped L131-132,152-153 directly. |
| `scripts/tests/test-per-entry.sh` | YES | L1-100 read + mirror/round-trip lines grepped (220-524). |
| `scripts/tests/test-validate-pack-checks-32-33-34.sh` | YES | mirror/Group-A lines grepped (3-399). |
| `.github/workflows/validate-pack.yml` | YES | grepped test enumeration L156-198 (EE-P6). |
| `feedback_fail_loud_delete_old_source.md` | YES | 55 lines; L1 frontmatter → L55 "do not invent scope." |
| `feedback_researcher_maps_blast_radius_before_architect.md` | YES | 41 lines; L1 → L41 "[[adversarial-architect-review-on-major-gap]]." |
| `feedback_review_fix_cycle.md` | YES | 33 lines (32 + reminder); L1 → L32 cross-refs. |
| `feedback_review_cycle_position_checkpoint.md` | YES | 57 lines; L1 → L56 "(Pack Chat does no fixes / never reviews coder output)." |
| `feedback_manifest_regen_on_v11_surface.md` | YES | 16 lines; L1 → L15 "Related: test-infra self-provisioning." |
| `feedback_commit_subject_keyword_token_trap.md` | YES | 39 lines; L1 → L38 cross-refs. |
| `feedback_no_prestaging_until_commit_approval.md` | YES | 24 lines; L1 → L24 "default assumption." |
| `feedback_scope_deliverables_to_the_ask.md` | YES | 35 lines; L1 → L35 "standing preference for terse, exactly-scoped work." |
| `feedback_agent_output_rules_applied_block.md` | YES | 15 lines; L1 → L15 Related links. |
| `feedback_architect_planner_empirical_evidence.md` | YES | 15 lines; L1 → L15 Related links. |
| `feedback_ci_guard_design_measure_then_bound.md` | YES | 15 lines; L1 → L15 Related links. |
| `feedback_pack_project_separation_of_concerns.md` | YES | 33 lines; L1 → L33 "audience anchors." |
| `feedback_bd_pack_only_operational_rule.md` | YES | 35 lines; L1 → L35 cross-refs. |
| `feedback_agents_read_rule_docs_in_full.md` | YES | 97 lines; L1 → L97 "... reinforced in every spawn prompt." |
| `project_pack_self_migration_launch_gate.md` | YES | 49 lines; L1 frontmatter → L48 "tracker-mode feature design (BD-060 ...)." |

**No named document was derived rather than read.** Every named document was Read directly via the Read tool;
all load-bearing numbers (209 projected count, 5 scaffolding H2s + 3 suffix forms, 11 changelog releases,
trees-absent, the no-rationale-slug fact, the CI test enumeration) were independently re-measured this pass at
HEAD `a630a31` via Bash/Read.

**End of PLAN-BD-203.md**
