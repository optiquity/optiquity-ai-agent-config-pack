# ARCHITECTURE-BD-291 — Per-entry conversion field-fidelity: the repaired conversion contract, the accounting gate, and the end-to-end migration proof (RECONCILED)

- Agent: pack-architect RECONCILIATION instance (`architect-bd291-reconcile`), read-only; fresh — neither the design's author nor the adversarial reviewer; worktree `…/.claude/worktrees/agent-ad313e07a831b5847` @ HEAD `0c2709e` (verified == injected canonical HEAD; `git worktree list` cross-checked)
- Date: 2026-08-25
- Inputs: `/backlog/BD-291.md`; census handoff `…/bd291-census-20260825T210547Z/`; original design `…/bd291-architect-20260825T212906Z/ARCHITECTURE-BD-291.md`; adversarial review `…/bd291-advarch-20260825T215356Z/ADVERSARIAL-REVIEW-BD-291.md`; own re-measurements (this run, §0 — reproduction rebuilt from byte-copies of the target monoliths in own scratch)
- Adjudication: all 13 adversarial findings ACCEPTED on independent evidence and folded; ONE reconciliation-discovered correction (R-1: the 7 Goal-less phases) folded beyond both prior passes. Per-finding rulings: `RECONCILIATION-BD-291.md` (same dir).
- Scope: architecture only. A planner and coders execute. This document is STANDALONE — the planner works from this doc + the census alone.

## §0 Evidence ledger

Every state claim cites an `E-n`. Each entry: command → captured output (quoted, condensed) → conclusion. All measurements RE-RUN this session at pack HEAD `0c2709e`, 2026-08-25, in this agent's own worktree/scratch. Target-app data derives from byte-copies of the three monoliths taken into own scratch this run; input identity with the census's pinned `472d931` inputs verified by exact line/anchor-count match (E-24). No git verb ran against any tree but this worktree (read-only).

- **E-1 (regime).** `pwd && git rev-parse HEAD && git worktree list` → `…/agent-ad313e07a831b5847`, `0c2709e7e59241a39b7892d31c219d3f5ec4cefd`, canonical + this worktree both at `0c2709e`. SUPPORTED.
- **E-2 (walker mechanics).** `sed -n` reads of `scripts/lib/per-entry/decompose.sh`: anchor/section tables (L116–179; project-changelog `id_extract` discards the slug when `Phase N` matches), the walk (L270–307: section-break → close + ignore-until-next-anchor; pre-first-anchor ignore), `normalize_entry` (L213–228: trailing-blank + `---` trim only), `write_entry` `os.replace` (L263–267), read semantics `open(…, encoding="utf-8", newline="")` + `text.splitlines(keepends=True)` (L77, L199); `grep -c 'fence\|\`\`\`'` → **0** (no fence awareness). SUPPORTED.
- **E-3 (migrator decompose sub-op).** `sed -n '74,87p;115,136p;185,195p' scripts/lib/migrate-v10-to-v11/decompose.sh`: 3-stream spec table with hyphen `docs/project/IMPLEMENTATION-PLAN.md` input; absent-input lenient `skip`; `_toc.md`-presence delete-gate + `rm -f "$mirror_path"`; sourcing block loads `_lib.sh`/`decompose.sh`/`toc-regenerate.sh` — NOT `index-generate.sh` (`grep -c "regenerate_index\|index-generate"` across migrator + init-project → 0/0/0). SUPPORTED.
- **E-4 (S4a root-only rename).** `sed -n '210,222p' scripts/migrate-v10-to-v11.sh` → `local src="$_MIGRATOR_TARGET/IMPLEMENTATION_PLAN.md"` (target ROOT only); absent → `info "no IMPLEMENTATION_PLAN.md at target root — nothing to rename"`; collision → typed error; tracked `git mv` / untracked `mv` fallback. SUPPORTED.
- **E-5 (helper-consumer census).** `grep -rln "per_entry_decompose\|per_entry_regenerate_toc\|per_entry_regenerate_index\|pe_entry_regex_for_stream"` outside `scripts/lib/per-entry/` → `migrate-v10-to-v11.sh`, `init-project.sh` (greenfield toc seeding), `lib/migrate-v10-to-v11/decompose.sh`, `lib/tracker-migrate-reverse.sh` (pack-backlog scope), `validate_checks/{per_entry_sync,core,boundary_refs}.py`, 10 test files, `test-fixtures/build.sh`. No consumer outside the migrator decomposes project streams except `build.sh` + tests. SUPPORTED.
- **E-6 (pack-only mirror in core.py).** `sed -n '55,75p' scripts/lib/validate_checks/core.py` → `STREAMS = [("pack-backlog", …), ("pack-changelog", …)]`; comment: project-side trees "are NOT loaded here". Regex tighten does not touch `core.py`. SUPPORTED.
- **E-7 (client validator surfaces).** Reads of `project-template/scripts/validate-docs.sh`: `IN_GLOBS` (L108–121) has the four stream `_rules.md`, NO loose `docs/project/*.md` glob, NO stream-entry glob; `_CONF_FORBIDDEN_SIDECARS = ("_format.md", "_scaffolding.md")` (L499); `_CONF_ENTRY_REGEX["changelog"] = ^\d{4}-\d{2}-\d{2}-[a-z0-9-]+\.md$` (L503); conformance walk silently `continue`s non-matching files (L1618–1630); groupings has a mis-named-GRP FAIL leg (`_conf_check_groupings_stream`, L1407+) — changelog has NO misname leg. SUPPORTED.
- **E-8 (index generator usable on real data).** This run: `per_entry_regenerate_index project-implementation-plan <rebuilt tree>` → rc=0, `_index.md` = **67 lines**. SUPPORTED.
- **E-9 (post-migration conformance census — CORRECTED count).** Rebuilt the migrated shell this run (full `project-template/` copy + reproduced trees + `_index.md`); `bash scripts/validate-docs.sh` → rc=1, `grep -c "\[conformance\]"` → **400**: `174 missing Entry-Type (113 backlog + 61 impl-plan) + 113 missing core field 'ID' + 113 missing core field 'Marker'`; changelog contributes **0**. Total failures in this full-template shell = exactly 400 (the census's minimal shell added 5 shell-artifact `[dangling]` failures — an artifact class run (ii) must not misread; a real migrated client has those files). The previously-recorded "403" was wrong. SUPPORTED.
- **E-10 (Entry-Type masks deeper phase requirements).** Probe (this run): `phase-6.md` + Entry-Type/ID/Blockers/Unblocks but NO Status → exactly one failure `phase-epic missing field 'Status'`; pre-synthesis the same file reports only `missing Entry-Type`. SUPPORTED.
- **E-11 (synthesis recipes sufficient — with the E-25 caveat).** Probes (this run): TD-001 + `Entry-Type: td`/`ID: TD-001`/`Marker: KNOWN GAP`/`Severity: functional` → **zero TD-001 failures**; `phase-5.md` + the 5-line synthesis → **zero phase-5 failures**. SUPPORTED.
- **E-12 (Type: distribution).** `grep -h "^Type:" <rebuilt TD tree> | sed 's/ — .*//' | sort | uniq -c` → 113 total: `KNOWN GAP(functional)` 52, `KNOWN GAP(polish)` 26, `TODO(feature)` 7, `VERIFY(schwab-api)` 4, `TODO(phase-34)` 4, `TODO(phase-33)` 3, `TODO(dependency)` 3, `VERIFY(public-api)` 2, `TODO(phase-37)` 2, `TODO(phase-31)` 2, **`TODO(architecture)` 2**, **`KNOWN GAP(dependency)` 2**, `VERIFY(etrade-api)` 1, `TODO(phase-52)` 1, `TODO(phase-27)` 1, `KNOWN GAP(critical)` 1. 109/113 fully mechanical; **4 out-of-enum** (carriers: `TD-057.md`, `TD-058.md`, `TD-070.md`, `TD-071.md`). Status distribution: `57 Open + 56 Resolved`, all in-enum. SUPPORTED.
- **E-13 (Status not derivable).** This run: 4 phase files contain an emoji somewhere in body; `grep -h "^## Phase" <monolith> | grep -c "✅"` → **0** annotated headings. SUPPORTED.
- **E-14 (completion-checklist shape).** Census appendix L219 (`| Phase | Deliverable | Build | Tests |`) + L257 (`| Phase | Deliverable | Milestone | Build | Tests |`) verified present; suggestion-grade only (unverifiable currency). SUPPORTED.
- **E-15 (groupings already seeded).** `sed -n '425,428p;448,460p' scripts/migrate-v10-to-v11.sh` → skeleton install loop + "seed the empty groupings `_toc.md` iff absent". NO-EDIT. SUPPORTED.
- **E-16 (backup exists; full-tree; re-run refusal semantics).** `grep -rn "_stage_backup" scripts/lib/migrator-core.sh` → called at L245; `migrator-stages.sh` defines it at L146; **L149–151: `fail_stage S1 "backup directory already exists …"`**; **L131–135: existing `dispositions.tsv` → `die … EXIT_ALREADY_MIGRATED` ("restore from the backup at $_MIGRATOR_BACKUP_DIR first")** — a plain re-run after any completed/failed-late run is REFUSED. SUPPORTED.
- **E-17 (fixtures mis-model the real layout).** `grep -rn "IMPLEMENTATION_PLAN" test-fixtures/build.sh` → no hits (hyphen-only persona); fixture TDs carry `Type: TODO(version)` ×5 (in-enum) and **zero `Context:` lines** (L370–440 region). SUPPORTED.
- **E-18 (filename uniqueness).** `find . -name accounting.sh / MIGRATION-TRIAGE.md / test-per-entry-fidelity.sh -not -path "./.git/*"` → all empty. SUPPORTED.
- **E-19 (open-BD set).** `grep -l "Status: Open" backlog/BD-*.md` → **17 entries**: BD-020, 036, 037, 039, 109, 110, 171, 172, 187, 192, 202, 223, 247, 254, 279, 289, 291. `ls project-template/docs/project/backlog/` → `_intro.md _rules.md` (entry-empty). SUPPORTED.
- **E-20 (graph coverage; G2 fallback).** This run: `graphify query "…payload enum contract…" --graph /Users/david/Developer/optiquity-ai-agent-config-pack/graphify-out/graph.json --backend claude-cli --budget 1500` → 30 nodes, ALL unrelated shell test functions (`payload()` in `test-deletion-boundary.sh` etc.) — no signal; per G2 fell back to grep. Referencer re-grep (`MIGRATION-v10-to-v11`): QUICKSTART.md, README.md, INSTALL-PROCEDURES.md, SETUP-EXISTING/NEW.md, MERGE-STRATEGY.md, DRY-RUN-MIGRATION.md, PRE-RECONCILE-v10-to-v11.md, PACK-MEMORY-RATIONALE.md, init-project.sh, 3 check tests + fixtures (+ internal history surfaces). SUPPORTED.
- **E-21 (harness structure).** `scripts/dry-run-migration.sh` header: "The original target is opened only via clone (URL) or read-only copy (local path); all migration work happens in /tmp on a disposable copy"; `--report-out` persistence. SUPPORTED.
- **E-22 (migration-doc anchors).** `grep -n` → `## Per-entry decomposition` L314, `### What the user does` L359, `### Backup and rollback` L370, `## Step 3 — Verify` L619. SUPPORTED.
- **E-23 (validator changelog pass + silent SKIP).** E-9's run: 0 changelog conformance failures (53/53 produced files pass); a bare-date file would be silently SKIPped at the entry-regex `continue` (E-7). SUPPORTED.
- **E-24 (input identity + reproduction identity).** Byte-copies from the read-only target checkout → `wc -l`: BACKLOG 1478, IMPLEMENTATION_PLAN 5342, CHANGELOG 2579; anchors 113 / 61 / 55 — ALL equal to the census's pinned `472d931` measurements. Decompose reproduction (real helpers, this run): "wrote 113 / 61 / 55", files produced **113 / 61 / 53** (D-2's two collisions reproduced). SUPPORTED.
- **E-25 (the TRUE post-synthesis validator set = 68, and the 7 Goal-less phases — reconciliation discovery R-1).** Full §3.3-recipe synthesis executed over the rebuilt trees (113 TDs incl. verbatim payloads, 61 phases WITHOUT `Status:`), then the shipped validator: **68 conformance failures = 61 × `phase-epic missing field 'Status'` + 7 × `phase-epic missing field 'Goal'`** (`phase-18.md`…`phase-24.md`); backlog contributes **0**. Cross-check against the monolith: 54 `**Goal**:` labels for 61 phases — the 7 are authored-without (e.g. phase-18 carries `**Prerequisite**:` but no Goal). Both prior passes' projections (65 declared; 61 claimed) were wrong. SUPPORTED.
- **E-26 (shipped validator has NO payload leg — the F-1 BLOCKER measurement).** `grep -n "severity-enum\|scope-enum\|Severity\|Verify-Source\|payload" project-template/scripts/validate-docs.sh` → **zero hits**; full read of `_conf_check_backlog_entry` (L602–646): Entry-Type, core-field presence, `Marker ∈ marker-enum`, `Status ∈ status-enum`, resolved-requires — no payload leg. Probes (this run, clean rebuilt tree): TD-002 + `Marker: KNOWN GAP`/`Severity: dependency` (out-of-enum) → **zero failures**; TD-003 + `Marker: TODO`/`Scope: architecture` (out-of-enum) → **zero failures**; TD-004 + `Marker: TODO` and **NO payload line** → **zero failures** (scan total 387 = 400 − 13, arithmetic-consistent with the probe insertions). SUPPORTED.
- **E-27 (contract DECLARES the payload legs — D-7).** `project-template/docs/project/backlog/_rules.md` L48–62 (read this run): schema keys `payload-by-marker: TODO=Scope "KNOWN GAP"=Severity VERIFY=Verify-Source`, `scope-enum`, `severity-enum`; enforcement paragraph: "the Marker-keyed payload field present + (for Scope/Severity) enum-valid"; `scope-enum`'s `phase-N` is "the templated pattern `phase-\d+`"; `verify-source` presence-checked open-string. Token blast radius: `grep -rln "payload-by-marker\|severity-enum\|scope-enum"` → the contract + `backlog/BD-272.md` (internal) ONLY. SUPPORTED.
- **E-28 (milestone H1s — the second destroyed association).** `grep -n '^# ' <plan monolith>` → 8 H1s: L1 title + `# Milestone 1 — Architecture Design` (L2640) … `# Milestone 7 — UI, Polish, and Documentation` (L4071). In the rebuilt tree, `grep -l '^# Milestone' phase-*.md` → **6 files**: phase-26, phase-28, phase-31, phase-32, phase-33, phase-36 (Milestone 1 falls in a D-3 dropped block). BACKLOG/CHANGELOG monoliths: line-1 H1 titles only. H1 is not a section break (`^## ` only) → in-span glue. SUPPORTED.
- **E-29 (the accounting gate passes a routing bug — gate-scope correction).** Counter simulation (this run): 7-line fenced-entry monolith walked fence-unaware WITH the capture sink → truncated tail lands in capture; `M == T + R : True`. The gate proves NO-LOSS, not correct routing. SUPPORTED.
- **E-30 (whole-suffix naming safe on all real anchors).** Slugified all 55 dated CHANGELOG anchors under the §2.3.4 rule (this run): **55 anchors → 55 distinct ids, 0 empty-suffix, 0 within-run duplicates** — neither fail-loud guard fires on the real migration. SUPPORTED.
- **E-31 (stale P14 claims + rename-test ownership).** `supporting-docs/MIGRATION-v10-to-v11.md` `### What changes` bullet (read this run): "`_intro.md` — the preamble extracted from the v10 monolithic file (lines 1–20 of the source on first migration)" — FALSE vs measured behavior (preamble dropped; `_intro.md` is an installed template) and vs §3.1's destination; stage-table S4a row: "rename … **at project root**" — stale under the two-location rename. `grep -rn "IMPLEMENTATION_PLAN" scripts/tests/*.sh` → `test-migrate-v10-to-v11.sh` Group 5 (L556+) owns the four rename branches with substring assertions `"S4a (rename)"` and `"nothing to rename"`. SUPPORTED.

## §1 Root cause per defect class

The walker is span-based and BOUNDARY-defined; every loss is a boundary defect, plus two contract gaps. Seven classes:

- **D-1 — whole-stream skip.** The underscore→hyphen rename is scoped to the TARGET ROOT only (E-4) while the decompose spec table takes the hyphen form at `docs/project/` as its sole input (E-3); the real v10 layout carries `docs/project/IMPLEMENTATION_PLAN.md` (E-24). The absent-input branch is a deliberate lenient skip for greenfield clients — correct design, wrong precondition. Compounding: no fixture models the underscore-at-`docs/project/` layout (E-17).
- **D-2 — changelog ID-collision overwrite.** (a) `id_extract` discards the distinguishing slug whenever `Phase N` matches (E-2); (b) `write_entry` `os.replace` silently overwrites (E-2); (c) the "wrote N" counter counts writes, not files (E-24: "wrote 55", 53 files). Two real entries destroyed (census §5.4).
- **D-3 — non-entry content destruction.** Walk step 3 discards the section-break line and everything until the next anchor, plus the preamble (E-2) — correct for the pack's own monoliths, wrong for client monoliths where those regions hold real content (~126 nonblank impl-plan lines, all 15 backlog section headings = phase-context of all 113 entries, 25 nonblank changelog Format-Rules lines; census §5.5). The migrator then deletes the monolith. The delete-gate gates on tree EXISTENCE, not content ACCOUNTING (E-3).
- **D-4 — `_index.md` never generated.** The sub-op never sources `index-generate.sh` (E-3) while the shipped contract declares `_index.md` GENERATED + VALIDATED and the shipped validator hard-fails a populated tree without it. The generator works on the real data (E-8: rc=0, 67 lines).
- **D-5 — project-changelog contract↔code divergence.** `_lib.sh` admits slug-optional (bare-date fallback) vs the shipped contract's mandatory slug; the contract's truncate-at-kind mapping example would itself collide 5 real same-date entries the code keeps distinct (census §5.6). The validator's silent-SKIP of misnamed changelog files (E-7/E-23) means neither side's violation surfaces.
- **D-6 — post-migration schema-conformance gap.** The migrator converts STRUCTURE, not GRAMMAR. Measured: **400 conformance failures** on the reproduced migrated trees (E-9) — a guaranteed red first client CI independent of D-1…D-5. Derivability proven: 4 mechanical lines per TD (109/113 payload-valid; E-11, E-12); per phase everything except `Status:` (E-13) — AND except `Goal:` on the 7 authored-without phases (E-25). The full post-synthesis remainder is exactly: 61 missing `Status` + 7 missing `Goal` + 4 out-of-enum payloads (E-25, E-26).
- **D-7 — shipped backlog contract↔validator divergence on the payload legs (adversary-found, verified).** The shipped contract DECLARES "the Marker-keyed payload field present + (for Scope/Severity) enum-valid" as enforcement (E-27); the shipped validator implements NO payload leg — a Marker with no payload line at all scans green (E-26). Same class as D-5, on the backlog stream, inside this BD's blast radius (C2 edits this validator; §3.3 synthesizes exactly these payload lines). Resolution direction: §3.2b (validator catches up to the contract — fail-loud, mirroring D-5's resolution direction).

**U-1 (what the observers saw) — root-caused by elimination.** Both audits measured zero in-span field drops (census §4, §5.3); the pack's own trees carry 23 entries authored without `Description:` (census §4.4, all verified authored-without). The observers' "missing fields" were authoring variance or D-1/D-2/D-3/D-6 boundary effects. §7 designs the client-facing resolution. The 7 Goal-less phases (E-25) are the same authoring-variance class surfacing under the v11 grammar — manual fill, never fabrication.

## §2 The repaired conversion contract

### §2.1 Design principle — a TOTAL walk plus an independent accounting gate

1. **The walker becomes TOTAL.** Every input line is routed to exactly one of three destinations: an ENTRY span, the DROPPED-CONTENT capture, or the SANCTIONED-STRUCTURAL trim class. Nothing is silently ignored.
2. **An independent, parser-free accounting gate** proves the routing lost nothing, BEFORE the source monolith may be deleted. Because the gate is a line-multiset equation, a walker bug cannot reproduce itself in the checker (no common-mode failure).

**Gate guarantee — stated exactly (corrected).** The gate guarantees ZERO UNACCOUNTED DROPS only. It does NOT guarantee correct ROUTING: a boundary bug that misroutes lines between an entry file and the capture passes the equation (proven, E-29). Routing correctness is carried by the P11 walker tests (§5.3) and by human triage of MIGRATION-TRIAGE §"From *" content (§7). No future actor may cite the gate to skip walker-routing tests.

### §2.2 The accounting gate — definition

New sourced helper `scripts/lib/per-entry/accounting.sh` (name unique, E-18), public API:

```
per_entry_accounting_check <stream_key> <mono_path> <stream_dir> <dropped_path>
```

Definitions (all as line MULTISETS, `collections.Counter`):

- `M` = lines of the monolith, EXCLUDING (i) blank/whitespace-only lines and (ii) lines that are exactly `---` (optionally whitespace-padded) — the SANCTIONED-STRUCTURAL class, the only shapes `normalize_entry` may trim (E-2) and the only shapes carrying zero content.
- `T` = lines of every `<stream_dir>` file matching the stream's entry regex, excluding each file's line-1 back-pointer (`pe_strip_backpointer_stdin` semantics, `_lib.sh` L290) and excluding blank/`---`-only lines.
- `R` = lines of `<dropped_path>` (empty multiset when absent/unset), excluding blank/`---`-only lines and provenance-delimiter lines matching exactly `^<!-- v10 monolith lines \d+–\d+ -->$` (the only line shape the capture sink ADDS).
- **Gate: `M == T ⊎ R` (multiset equality).** Direction 1 (coverage): zero unaccounted drops. Direction 2 (no fabrication): the tree + capture contain nothing the monolith did not.
- **Read symmetry (F-12 fold):** the accounting reader uses the IDENTICAL read + split semantics as the walker — `open(…, encoding="utf-8", newline="")` + `splitlines(keepends=True)` (E-2) — so no line-boundary class can produce an asymmetric false verdict.

On mismatch: print every line in `M − (T ⊎ R)` with its first monolith line number ("UNACCOUNTED") and every line in `(T ⊎ R) − M` with its file ("FABRICATED"); return non-zero. Cost: one pass per file, O(lines), no subprocess-per-entry, no tree walk beyond the stream dir (`ci-check-runtime-compounding`).

**Sequencing rule: the gate runs BEFORE field synthesis (§3.3)** — at gate time the tree is byte-faithful, so the equation needs no exclusions beyond the three fixed classes. Synthesis afterwards is insert-only and separately recorded, so end-state verification remains possible (§5.2).

This gate definition IS the BD-291 acceptance-criteria instrument: "100% content accounting with ZERO unaccounted drops" = `M == T ⊎ R` returning 0, per stream, on fixtures, in the migrator, and on the target-app scratch clone — with routing correctness carried by the §5.3 tests per the §2.1 scope statement.

### §2.3 Walker repairs (`scripts/lib/per-entry/decompose.sh`)

1. **Fence awareness — FIRST in classification order (fixes the census U-4/O-7 latent class; enables §2.3.3 safely).** The line loop tracks fenced-code state (a line starting with ``` toggles it); INSIDE a fence NO line is an anchor, a section break, or an H1 break — fence state is evaluated BEFORE any other line classification. Measured absent on both current data sets (census §4.2; census §5.5); this is a correctness completion whose necessity is sharpened by §2.3.3: a fenced `# comment` line (shell/Python comments at line start) must never be classified as an H1 break. Without the fence fix, a fenced `## ` would truncate an entry and PASS the gate as a misroute (E-29) — the fix prevents that silent misplacement; the gate is NOT its backstop (§2.1).
2. **Dropped-content capture (fixes D-3 at the mechanism).** New optional env `PE_DECOMPOSE_DROPPED` (absolute path). When set: **the walker TRUNCATES the capture file at decompose start** (F-6 fold — re-entry can never double-append), then the walk's ignore branches (pre-first-anchor preamble; section-break/H1-break line + following non-anchor lines) append those lines VERBATIM, in input order, each contiguous block preceded by one delimiter line `<!-- v10 monolith lines A–B -->`. When unset: behavior identical to today's ignore semantics (pack-self conversions and existing callers unaffected; E-5).
3. **H1-break class (fixes the E-28 milestone-glue loss — OI-R2 adopted).** Outside a fence, a non-preamble `^# ` line (an H1 after the first anchor) closes the current entry EXACTLY as a section break does: the H1 line + following non-anchor lines route to the ignore/capture branch. Measured population: the plan monolith's 7 `# Milestone` dividers (6 currently glued in-span into phase-26/28/31/32/33/36 — a destroyed milestone→phase association invisible to every prior mechanism); BACKLOG/CHANGELOG carry line-1 titles only (already preamble) (E-28). Pack-stream data: H1s are line-1 titles (preamble) — behavior unchanged on pack data. H1-break joins the EXISTING section-break semantics in both env modes (with capture: preserved; without: ignored — the pre-existing section-break contract; every real monolith-decomposing consumer is the migrator, which always sets the capture, E-5).
4. **project-changelog id model (fixes D-2 + D-5 in one rule).** Replace the two-branch `id_extract` with: `id = date + "-" + slugify(full heading suffix after the first " — ")` (slugify = lowercase, `[^a-z0-9]+`→`-`, trim `-`). The two colliding target pairs become four distinct files by construction. Fail-loud (`pe_die`, monolith untouched) on: (a) an empty/unslugifiable suffix (bare-date shape); (b) a within-run duplicate id (identical full headings), naming both monolith lines. Both guards measured non-firing on the real data: **55 anchors → 55 distinct ids, 0 empty-suffix, 0 duplicates** (E-30). The id is a pure function of the heading — no cross-entry state, no ordering dependence.
5. **Written-count integrity.** `written` increments only on a NEW id (the duplicate case dies first); the summary reports files written; the "wrote 55 / produced 53" class (E-24) is eliminated.

### §2.4 Stream-library repairs (`scripts/lib/per-entry/_lib.sh`, `toc-regenerate.sh`)

- project-changelog entry-regex tightened to `^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9-]+\.md$` — code matches the shipped contract's mandatory-slug rule (D-5a resolved code-ward per §3.2). The slug-optional comment block (L114–121 region) is DELETED, replaced by one line naming the contract as the rule's source (`fail-loud-delete-old-source`; `operating-docs-no-history-no-bloat`). Mirror edit at the `toc-regenerate.sh` project-changelog regex; both move in the same commit.
- `pe_die` remains the failure primitive; no signature changes; `core.py` untouched (pack streams only, E-6).

### §2.5 Migrator sub-op repairs (`scripts/migrate-v10-to-v11.sh`, `scripts/lib/migrate-v10-to-v11/decompose.sh`)

**S4a rename (fixes D-1).** `_v10_to_v11_rename_implementation_plan` iterates TWO locations — target root AND `docs/project/` — applying identical per-location logic: absent → info + continue; both-forms-present collision → the existing `migration-rename-collision` typed error naming the directory; tracked → `git mv`; untracked → `mv` fallback. The banner and the dry-run advisory line name both locations. (Alternative (b) — accepting the underscore path as a second decompose input — rejected: leaves a non-canonical filename alive; the rename convention exists; OI-A1.)

**S5d sub-op — per-stream pipeline order** (replacing decompose→toc→toc-gate→delete):

```
for each stream (backlog, implementation-plan, changelog):
  1. decompose        (PE_DECOMPOSE_DROPPED=<state-dir per-stream capture>;
                       sink truncates the capture at start — §2.3.2)
  2. accounting gate  (per_entry_accounting_check; FAIL → fail_stage S5;
                       monolith + tree + capture retained for diagnosis;
                       recovery procedure ships in §7)
  3. field synthesis  (backlog + implementation-plan only; §3.3; insert-only;
                       records every inserted line per file into the state dir)
  4. toc regenerate
  5. index regenerate (implementation-plan only; fixes D-4; E-8 proves usable)
  6. delete-gate      (all of: accounting PASSED in step 2; _toc.md present;
                       for impl-plan _index.md present) → rm -f monolith
after the loop:
  7. assemble docs/project/MIGRATION-TRIAGE.md (§3.1) from the per-stream
     captures + the derived membership maps + the synthesis record + the
     manual-fill list, and write the accounting verdicts into the report
```

The sub-op's helper-sourcing block additionally sources `index-generate.sh` and `accounting.sh` (same `type`-guard convention). The delete-gate upgrade replaces existence-gating with accounting-gating — the fail-safe philosophy the code already states (E-3) becomes mechanically true.

## §3 Destination model (D-3), reconciliation direction (D-5 + D-7), and grammar synthesis (D-6)

### §3.1 D-3 destination — one migration-transient triage file, not a stream sidecar

**Decision: all preserved non-entry content lands in ONE migrator-written file, `docs/project/MIGRATION-TRIAGE.md`** (name unique repo-wide, E-18), never in the stream dirs and never in `_intro.md`. Property-fit (HIGH pack-boundary bar):

- **`_intro.md` append — REJECTED.** The stream contracts define `_intro.md` as human-only, zero rules; the preserved content includes rule-bearing text — a contract violation; and it would turn a pack-installed template into a customized file on every migrated client (BD-202 CP-modify-customized class). NOTE: the shipped migration doc currently CLAIMS `_intro.md` carries the extracted preamble — a stale claim P14 fixes (E-31).
- **Per-stream `_migration-archive.md` sidecars — REJECTED.** Tolerated on disk (E-7) but contract-invisible or contract-bloating for a migration-transient concept; the pack-side `_v8-resolved-archive.md` precedent is a PERMANENT archive — different lifetime class, pattern does not transfer.
- **One loose `docs/project/` file — ADOPTED.** Measured safe: loose `docs/project/*.md` files are scanned by NO validator axis (E-7 — the operating-doc IN set has no such glob; conformance only enters the four stream subdirs; the adversary's history-rich probe file produced zero failures). Client-owned from birth (dependency-direction), self-describing, deletable when triage completes.

**File structure** (written by S5d step 7):

1. Header: purpose ("content your v10 monoliths carried outside entry spans, preserved verbatim for triage"), the instruction pointer (the procedure lives in MIGRATION-v10-to-v11.md §"What the user does", §7), and "delete this file when every section is triaged."
2. Per-stream sections (`## From BACKLOG.md`, `## From IMPLEMENTATION-PLAN.md`, `## From CHANGELOG.md`): the capture-file content verbatim, provenance delimiters included — now INCLUDING the captured `# Milestone` divider blocks (§2.3.3).
3. `## Derived: section membership` — for the backlog: each v10 `## <section>` heading with the ordered list of TD ids anchored under it (trivial second pass over the monolith: section-head + anchor lines in order; independent of the walker). Preserves the phase-context association without mutating any entry.
4. `## Derived: milestone membership` (NEW — OI-R2 fold) — for the implementation-plan: each v10 `# Milestone N — <title>` heading with the ordered list of phase ids anchored under it (same second-pass mechanism, over `^# ` heads + phase anchors). Preserves the milestone→phase association E-28 measured destroyed.
5. `## Synthesized fields` — the per-file list of every line §3.3 inserted (the load-bearing record §5.1(b) verifies against).
6. `## Manual fill required` — the validator-red remainder, CORRECTED to the measured set (E-25, E-26): (a) the 61 phase files missing `Status:` (with the E-14-derived per-phase SUGGESTION table, each row marked suggestion-review-before-applying); (b) the 7 phase files missing `Goal:` (phase-18…phase-24 on current data — narrative field, PM-chat-authored, never fabricated); (c) the 4 entries whose synthesized payload is out-of-enum (TD-057/058/070/071 on current data), listed by file with the offending value. All lists are computed by the migrator from the actual data at run time, never hard-coded.

Sections 3–6 are DERIVED/generated content outside the §2.2 accounting equation by construction (the equation reads the capture files, not MIGRATION-TRIAGE.md; the migrator test asserts section-2 content equals the captures).

### §3.2 D-5 reconciliation — contract follows the collision-avoiding code, then both tighten

Direction: **align the contract text to whole-suffix slugification (code's loss-avoiding behavior), and align the code to the contract's mandatory slug (dropping the bare-date fallback)** — each side adopts the other's safe half:

- The contract's truncate-at-kind mapping example is measurably loss-inducing (5 real same-date entries collide under it; 0 under whole-suffix — census §5.6, naming-rule verified E-30). The contract's § Filename mapping is rewritten: the slug mirrors the ENTIRE heading suffix, slugified; all three examples updated (`2026-04-20-phase-35-live-preview-sandbox.md`, `2026-03-20-architecture-iteration-notification-event-model.md`, `2026-07-04-release-boundary-v2-3-shipped.md`); one sentence added: filenames are unique by construction — two identical full headings are an authoring error (extend the newer heading). Terse, no history (`operating-docs-no-history-no-bloat`).
- The code's slug-optional regex + bare-date fallback: removed per §2.3.4/§2.4 (`fail-loud-delete-old-source`).
- The validator's silent-SKIP hole closes with a changelog misname leg (E-7/E-23): a `^\d{4}-\d{2}-\d{2}`-prefixed `.md` file in the changelog stream failing the entry regex is a mis-named ENTRY → FAIL (mirror of the groupings misname precedent, E-7). Measure-then-bound: candidate set = the file list the conformance leg already scans; measured population 0 post-fix (53/53 slugged, E-23/E-24); empty allowlist; bite: a `--self-test` synthetic `2026-01-01.md` must FAIL, and the self-test asserts the leg is REACHED for the changelog subdir.

**§3.2a Naming-rule scope note.** The whole-suffix rule changes the SHIPPED contract's phase-form example. No client tree exists yet (v11.0 unlaunched; template streams entry-empty, E-19; fixtures regenerate). Alternative (collision-triggered disambiguation) rejected: order-dependent naming + a permanent special case. Adjudicated OI-A2, recommendation ALWAYS-FULL-SLUG; user confirmation requested (shipped-contract examples change).

**§3.2b D-7 resolution — the payload legs land in the shipped validator (C2; OI-R1 option (a) adopted).** `_conf_check_backlog_entry` gains the contract-declared legs, schema-driven from the SAME `_rules.md` keys the contract already ships (E-27 — the CONTRACT TEXT NEEDS NO EDIT; the validator catches up):

- **Payload-by-marker presence:** when `Marker` is present and ∈ marker-enum, the marker-keyed payload field line (`Scope:` / `Severity:` / `Verify-Source:` per `payload-by-marker`) must be present → else FAIL naming the missing field.
- **Scope enum-validity:** `Scope` value ∈ scope-enum, where the `phase-N` member is the templated pattern `phase-\d+` (matched literally OR as an enum member, per the contract's own wording — 13 real entries carry phase-N scopes, E-12, and MUST pass).
- **Severity enum-validity:** `Severity` value ∈ severity-enum.
- **Verify-Source:** presence-only (open-string per the contract).

Measure-then-bound (E-26, E-12, E-17): measured population on the real data post-synthesis = **4 out-of-enum** (TD-057/058/070/071: `Scope: architecture` ×2, `Severity: dependency` ×2), **0 missing-payload** (all 113 `Type:` lines parse); pack fixture TDs carry `Type: TODO(version)` — in-enum, post-synthesis green (E-17); allowlist: none (empty legitimate-violation set); fix-recipe: none needed repo-side (no current tree violates it — the 4 are client-data manual-fill items the leg exists to NAME). Bite (self-test): out-of-enum `Severity` → FAIL; `Marker` with no payload line → FAIL; valid `Scope: phase-12` → PASS (template direction); plus the reached-for-backlog assertion (absence-of-backing direction). Runtime: rides the existing per-entry conformance pass, O(1) additional field lookups per entry (`ci-check-runtime-compounding`).

This restores the design's load-bearing chain measured broken at E-26: out-of-enum payloads are now validator-RED ("the validator names them — loud" becomes TRUE), the honest-loud rationale of OI-A3/OI-A4/OI-A12 holds, and §5.1(d)'s set-equality instrument is exact again (§5.1).

### §3.3 D-6 grammar synthesis — mechanical where derivable, loud + instructed where not

A new adapter-private helper (inside `scripts/lib/migrate-v10-to-v11/decompose.sh`; no new file) `_v10_to_v11_synthesize_form_family`, run per §2.5 step 3. INSERT-ONLY by construction; every inserted line is recorded (file → lines) into the state dir for MIGRATION-TRIAGE §5 and §5.1(b). Recipes (proven E-11, E-25):

- **project-backlog, per entry** — insert directly after the bold-header line: `Entry-Type: td`; `ID: TD-NNN` (from the filename); and iff a `^Type:\s*(TODO|KNOWN GAP|VERIFY)\(([^)]+)\)` line parses: `Marker: <kind>` plus the marker-keyed payload line with the parenthetical value VERBATIM. The original `Type:` line is preserved untouched (the form-family schema admits extras — E-11). No parseable `Type:` → no Marker synthesis; the entry joins the manual-fill list. Out-of-enum payloads (the 4, E-12) are synthesized verbatim — the §3.2b validator leg then names them (loud, measured-true post-C2), and MIGRATION-TRIAGE §6 lists them; fabricating an in-enum guess is prohibited (declare-verify-backing).
- **project-implementation-plan, per entry** — insert directly after the H2: `Entry-Type: phase-epic`; `ID: phase-N`; `Blockers:` / `Unblocks:` derived from the SAME dependency grammar `index-generate.sh` reads (`field_value` over `Blockers`/`Dependencies`/`Prerequisite`/`Unblocks` + phase-ref extraction; `none` when empty) — derivation from the entry's own declared data, the identical parse that orders `_index.md` (E-8). **`Status:` is NOT synthesized** (E-13: zero mechanical source; E-14: checklists suggestion-grade). **`Goal:` is NOT synthesized** for the 7 authored-without phases (E-25: narrative field, zero mechanical source). The 61 phases join the manual-fill list with the suggestion table; the 7 Goal-less phases join it as a distinct item class. Adjudicated OI-A3.
- **project-changelog** — no synthesis (E-9/E-23: 0 conformance failures).

Reconciliation chain (`architect-doc-reality-reconciliation`): the synthesis helper's docstring names `index-generate.sh` `parse_phase_refs` / `field_value` as the semantic twin (file + symbol, no line numbers); this doc is the design anchor; the IMPL-REPORT cross-links both.

## §4 Per-surface edit map

Census of encoding surfaces = census §3 + E-5 (helper consumers) + E-7/E-26 (validator) + E-20 (doc referencers) + E-31 (rename-test ownership). Mirror-but-customize: pack and client twins separate; no dual-use file; `_SANCTIONED_PACK_SIDE_SHIPPED` does not grow (the one NEW pack-side file, `accounting.sh`, is a migrator runtime dependency — pack-side by dependency direction, never shipped).

**Pack-side (code + fixtures + tests + ops docs):**

| # | Surface | Edit |
|---|---|---|
| P1 | `scripts/lib/per-entry/decompose.sh` | §2.3: fence state (first-order), dropped-capture env + truncate-at-start, H1-break class, changelog id rewrite, count integrity |
| P2 | `scripts/lib/per-entry/_lib.sh` | §2.4: changelog regex tighten; comment replaced |
| P3 | `scripts/lib/per-entry/toc-regenerate.sh` | §2.4: mirrored regex tighten |
| P4 | `scripts/lib/per-entry/accounting.sh` | NEW: §2.2 gate (incl. the symmetric-read semantics sentence) |
| P5 | `scripts/migrate-v10-to-v11.sh` | §2.5: S4a two-location rename; dry-run advisory names both locations + the triage file |
| P6 | `scripts/lib/migrate-v10-to-v11/decompose.sh` | §2.5 pipeline (accounting, synthesis, index, delete-gate, TRIAGE assembly incl. both membership maps); sources index-generate + accounting |
| P7 | `scripts/dry-run-migration.sh` | §5.1: `--apply-sandbox` mode |
| P8 | `pack-ops/DRY-RUN-MIGRATION.md` | document the new mode (operating doc: terse, zero history) |
| P9 | `test-fixtures/build.sh` | §5.3: v10 persona → underscore plan filename at `docs/project/`, hazard shapes (incl. a milestone-H1 divider + ONE out-of-enum-payload TD), `Context:` lines (E-17) |
| P10 | `test-fixtures/manifest.txt` | regenerated at push by `manifest-sync.sh` (orchestrator; `regenerate-manifest-v11-surface` — NOT per-commit) |
| P11 | `scripts/tests/test-per-entry.sh` | §5.3 walker cases (fence, capture, H1-break, naming, fail-louds) |
| P12 | `scripts/tests/test-per-entry-fidelity.sh` | NEW: §5.3 accounting unit + bite mutations m1–m3 |
| P13 | `scripts/tests/test-migrate-v10-to-v11-decompose.sh` | §5.3 migrator cases (D-1…D-7 + gate-refusal + TRIAGE assembly) |
| P14 | `supporting-docs/MIGRATION-v10-to-v11.md` | §7 instructions (extends existing anchors, E-22) **+ E-31 stale-claim repairs: the `### What changes` `_intro.md` bullet (preamble goes to MIGRATION-TRIAGE.md, `_intro.md` is an installed template), the same list gains `_index.md` + MIGRATION-TRIAGE.md as migration outputs, and the stage-table S4a row states BOTH rename locations** |
| P15 | `backlog/BD-291.md` | status flip at batch close (Pack Chat; bookkeeping) |
| P16 | `scripts/tests/test-migrate-v10-to-v11.sh` | **NEW ROW (F-8 fold): Group 5 (owner of the S4a rename branches, E-31) gains the second location's branches — collision-at-`docs/project/` typed error + untracked-`mv`-fallback there — and its substring assertions (`"S4a (rename)"`, `"nothing to rename"`) are re-checked against P5's per-location wording** |

**Client-side (shipped) twins:**

| # | Surface | Edit |
|---|---|---|
| C1 | `project-template/docs/project/changelog/_rules.md` | §3.2 Filename-mapping rewrite |
| C2 | `project-template/scripts/validate-docs.sh` | §3.2 changelog misname leg + self-test case; **§3.2b payload-by-marker presence + Scope/Severity enum legs (phase-\d+ template honored) + their self-test bite cases** |
| C3 | `docs/project/MIGRATION-TRIAGE.md` (client-side, migrator-GENERATED) | not a template file; produced at migration time (§3.1) |

**NO-EDIT surfaces (justification each):**

- `scripts/lib/per-entry/index-generate.sh` — proven correct on real data as-is (E-8); D-4 is a caller omission, fixed at P6.
- `scripts/lib/validate_checks/core.py` — pack-stream regexes only (E-6); BD-289's count ledger untouched (no new validate-pack check, §6).
- `scripts/lib/validate_checks/per_entry_sync.py`, `boundary_refs.py`, `scripts/init-project.sh`, `scripts/lib/tracker-migrate-reverse.sh` — consumers of toc/regex surfaces only (E-5); no behavioral contact.
- `/backlog/_rules.md`, `/changelog/_rules.md` (pack streams) — the field-faithful contract is correct and unchanged; Audit A measured zero pack-side conversion drops (census §4): BD-291 scope item 3 closes with **NO repair needed**; §5.3's fidelity test permanently encodes the property.
- `project-template/docs/project/backlog/_rules.md` — **stays NO-EDIT under D-7**: the contract already declares the payload legs (E-27); the VALIDATOR catches up (C2), not the contract down. `implementation-plan/_rules.md`, `groupings/_rules.md` — schemas already express the target state (E-11/E-25); no migration-transient concept admitted.
- `supporting-docs/METHODOLOGY.md` Part 7 — the field-template SSOT is unchanged.
- Migrator groupings handling — already seeded (E-15). `_intro.md` templates — rejected as destination (§3.1); unchanged.
- `QUICKSTART.md`, `README.md`, `INSTALL-PROCEDURES.md`, `SETUP-*.md`, `MERGE-STRATEGY.md`, `PRE-RECONCILE-v10-to-v11.md`, `PACK-MEMORY-RATIONALE.md` (E-20 referencers) — they reference the migration doc's existence, not the decompose semantics; the ONE referencer with stale in-body claims is P14 itself, now covered (E-31). The coder re-verifies at implementation time via the same grep.

## §5 Verification harness + tests design

### §5.1 The sandbox-apply harness (BD-291's own verification path; BD-171 untouched)

**Extend `scripts/dry-run-migration.sh` with an `--apply-sandbox` flag** (OI-A5). Existing machinery reused wholesale (E-21: fixture/local/URL intake, `$TMPDIR`-only enforcement, neutered push URL, EXIT-trap cleanup, `--report-out`). Mode behavior after working-copy setup:

1. Snapshot the three v10 monolith paths (both plan spellings) from the working copy into the harness's results dir (self-contained; the full-tree tar also exists — E-16).
2. Run the real adapter with `--apply` on the disposable working copy. Harness-internal git verbs run only inside the self-provisioned `$TMPDIR` clone; the source path/URL is never touched.
3. Verification battery on the migrated copy: (a) migrator rc==0; (b) re-run `per_entry_accounting_check` per stream against the step-1 snapshots, with the tree-side multiset reduced by EXACTLY the inserted-line record from MIGRATION-TRIAGE §"Synthesized fields" (a record entry with no matching tree line, or a tree addition outside the record, FAILS — declare-verify-backing both directions); (c) `_toc.md` per stream + `_index.md` for impl-plan present; (d) run the SHIPPED `validate-docs.sh` from the migrated copy and assert the failure set is EXACTLY the manual-fill set MIGRATION-TRIAGE §"Manual fill required" declares (set equality — one unexpected failure or one undelivered expected failure fails the harness). **Corrected arithmetic (E-25/E-26): on the current target data the declared set and the measured post-C2 validator set are BOTH exactly 72 = 61 missing-Status + 7 missing-Goal + 4 out-of-enum-payload; pre-C2 the instrument was broken (68 measured ≠ 65 previously declared — neither number was right).** (e) MIGRATION-TRIAGE.md exists iff (captures ∪ synthesis ∪ manual-fill) nonempty.
4. Render a verification report (`--report-out`) with per-stream accounting verdicts + the validate-docs delta.

"End-to-end green" for the BD-291 AC = harness rc 0 under (a)–(e), treating the DECLARED manual-fill remainder as green-with-instructions (user sign-off at OI-A4). Runs: (i) fixture mode (`test-fixtures/v10-realistic-ot`) — CI-wirable, deterministic; (ii) the launch-gate run against a read-only copy of the real target checkout — user-approved, results into BD-291 batch evidence; run (ii) is a MEASURED precondition of flipping BD-291 to Resolved. The census-shell dangling-artifact class (E-9) is a known non-signal in minimal shells; run (ii) executes against a full working copy where it does not arise.

### §5.2 Why accounting-before-synthesis + record-verified end state is sound

At §2.5 step 2 the tree is byte-faithful, so `M == T ⊎ R` needs no synthesis exclusions. Synthesis then inserts recorded lines only; §5.1(b) re-proves at end state that (tree − record) still equals the snapshot multiset. A synthesis bug (mutating instead of inserting) surfaces as FABRICATED/UNACCOUNTED lines in §5.1(b). No window exists in which content can vanish UNACCOUNTED: the monolith is deleted only after step 2 passed, and steps 3–5 are covered by §5.1(b). Scope reminder (§2.1/E-29): the equations prove no-loss; routing correctness is the §5.3 walker tests' job.

### §5.3 Tests + fixtures (closing census O-6)

- **`scripts/tests/test-per-entry-fidelity.sh` (NEW).** Unit-tests `per_entry_accounting_check`: PASS on a clean decompose+capture; then three BITE mutations, each asserting non-zero rc + the naming output: (m1) delete one line from one entry file → UNACCOUNTED; (m2) append one fabricated line to an entry → FABRICATED; (m3) truncate the capture file → UNACCOUNTED.
- **Harness-leg bites (F-10 fold), in the fixture-mode `--apply-sandbox` run:** (m4) mutate one recorded synthesis line in the migrated copy → §5.1(b) must FAIL both-directions; (m5) introduce one undeclared validator failure (e.g. remove a `Context:` line post-migration) → §5.1(d) set-equality must FAIL. The two legs that gate the Resolved flip are thereby bite-proven, not asserted.
- **`scripts/tests/test-per-entry.sh` (extend).** Walker cases on inline fixtures: fenced `## ` AND fenced `# ` stay in-span; dropped-capture receives preamble + section blocks + H1 blocks with correct delimiters; re-running decompose truncates-then-rewrites the capture (no double-append); unset-env preserves legacy behavior; H1-break closes an entry and routes to capture; changelog whole-suffix naming (two same-date/same-phase pair shapes → two files); identical-heading pair → `pe_die` naming both lines; empty-suffix anchor → `pe_die`.
- **`scripts/tests/test-migrate-v10-to-v11-decompose.sh` (extend).** Real-helper cases: underscore plan at `docs/project/` renamed then decomposed (D-1); `_index.md` generated (D-4); synthesis fields present + original lines untouched (D-6, insert-only assertion); the out-of-enum fixture TD appears in TRIAGE §Manual-fill AND fails the shipped validator's §3.2b leg (D-7 end-to-end); MIGRATION-TRIAGE.md assembled with section-2 == captures and both membership maps present; via the existing stub-helper pattern: accounting-FAIL → delete refused, monolith retained, `fail_stage S5`.
- **`scripts/tests/test-migrate-v10-to-v11.sh` (extend — P16).** Group 5 gains the second rename location's collision + untracked-fallback branches; existing substring assertions re-checked against the per-location wording.
- **`test-fixtures/build.sh` (v10 persona).** Model reality (E-17): plan file becomes `docs/project/IMPLEMENTATION_PLAN.md`; hazard shapes — a same-date same-phase changelog pair, non-entry `## ` sections with content in backlog + plan, a `# Milestone`-style H1 divider in the plan, a preamble per monolith, one fenced `## ` inside a TD body, ONE TD with an out-of-enum payload value (synthetic, neutral vocabulary), `Context:` on all TDs. Fixture content stays synthetic/neutral (public-bound-no-leak). Manifest regenerates at push (P10).
- **Battery.** Coder + reviewer run the full wired battery (both CI jobs + `PACK_VALIDATE_DEEP=1` + fixture-dependent tests) per `verify-full-ci-suite`; the fixture-mode `--apply-sandbox` run joins the fixture-dependent set.

## §6 CI guard design — no new validate-pack check (justified)

**No new `validate-pack.py` check is added.** The defect class is MIGRATION-TIME behavior on CLIENT data; the pack repo carries no repo state a PR-time check could verify (pack trees clean, census §4; template streams entry-empty, E-19). The enforcement points with something real to bite: the migrator's internal accounting gate, the client-side validator legs, and the pack test battery — all designed above. A repo-state check would be pure runtime cost (`ci-check-runtime-compounding`) and would collide with BD-289's reserved Check-ID/ledger surfaces for zero coverage. **TWO client-side legs are added (both in C2), each measure-then-bound:** the changelog misname leg (§3.2 — population 0 post-fix, empty allowlist, reached-assertion bite) and the backlog payload legs (§3.2b — population 4 out-of-enum + 0 missing-payload on real data, 0 on fixtures post-P9-recipe, empty allowlist, three bite cases incl. the phase-N template PASS direction).

## §7 Client instructions deliverable (+ U-1 resolution)

All edits to `supporting-docs/MIGRATION-v10-to-v11.md` are PROCEDURAL, present-tense, zero incident narration (`operating-docs-no-history-no-bloat`); they extend the existing anchors (E-22) plus the E-31 repairs (P14):

- **`### What the user does` (L359 anchor)** gains the post-migration triage procedure, written against MIGRATION-TRIAGE.md: (1) work through `## From *` sections — relocate kept content to its proper home (`ARCHITECTURE.md`, `docs/reference/`, an entry body) or delete superseded v10 boilerplate (the old Format-Rules / how-to-use blocks are superseded by each stream's `_rules.md`); (2) apply the `## Derived: section membership` AND `## Derived: milestone membership` maps if the phase-context / milestone structure should live on (options stated: fold into entry `Context:` lines, or adopt groupings); (3) review + apply the `Status:` suggestion table (each value is the PM chat's decision; the migration backup and git history remain available — E-16); (4) author the missing `Goal:` line for each listed Goal-less phase (PM-chat knowledge; narrative — never auto-filled); (5) correct the listed out-of-enum payload values to a valid enum member (the validator names each, §3.2b); (6) regenerate `_toc.md` (+ `_index.md`), run `scripts/validate-docs.sh` to zero; (7) delete MIGRATION-TRIAGE.md; (8) commit.
- **Gate-failure recovery (NEW — OI-R3 fold, same section).** If the migrator halts at the accounting gate (S5): the failing stream's monolith, partial tree, and capture are retained for diagnosis; a completed-then-failed-late state REFUSES a plain re-run (`EXIT_ALREADY_MIGRATED` when `dispositions.tsv` exists — E-16) and `_stage_backup` refuses when the backup dir exists — the procedure states: inspect the UNACCOUNTED/FABRICATED lines in the gate output, restore the tree from `<state-dir>-backup` (and move the backup dir aside per the S1 message), then re-run. One paragraph, procedural.
- **`## Step 3 — Verify` (L619 anchor)** gains the fidelity check + the U-1 resolution, phrased procedurally: entry content is span-faithful and accounting-gated — the migrator refuses to delete a monolith any of whose content lines are unaccounted; therefore a field absent from a migrated entry was absent from the v10 monolith (authoring variance, not loss — on the current data that is exactly the 61 missing `Status:`, the 7 missing `Goal:`, and nothing else; E-25). One verification command is given (compare an entry against the backup monolith). Communicating the closure to the specific observers is a user-relay step (OI-A11).
- **`### Backup and rollback` (L370 anchor)** — verified accurate (full-tree tar, E-16); the coder reconciles wording only if drifted (single-stale-element rule).
- **`pack-ops/DRY-RUN-MIGRATION.md`** — the `--apply-sandbox` mode documented (pack-operator audience), terse.

## §8 Cross-BD design-time collision scan (Empirical-Evidence Block)

**Measurement (re-run this session).** `grep -l "Status: Open" backlog/BD-*.md` → 17 open entries (E-19); per-entry File/Symbol reads; `ls project-template/docs/project/backlog/` → entry-empty (empty project-side intersection by construction). Date 2026-08-25, HEAD `0c2709e`. BD-291's blast-radius set = §4's P1–P16 + C1–C2.

| Open BD | Path intersection with §4 set | Verdict |
|---|---|---|
| BD-171 (harness; kept SEPARATE by user decision) | ∅ file overlap (its set: NEW `test-real-ot-migration.sh`, NEW fixture README, `validate-pack.yml` gated job, `test-fixtures/README.md`) — DOMAIN-ADJACENT to P7 | **COORDINATE (note)** — BD-291 does NOT absorb, edit, or depend on BD-171; §5.1 is a distinct path (local `$TMPDIR` sandbox vs BD-171's scratch-GH-repo pattern). BD-171 may later REUSE `--apply-sandbox`; nothing here presumes it. |
| BD-172 (Gate-2 verification helpers) | ∅ file overlap — but its planned `_cp_verify_bd104_rename_outcome` verifies the RENAME OUTCOME P5 extends | **COORDINATE** — planner note: if BD-172 lands after BD-291, its verifier spec must cover BOTH rename locations; record in BD-172's entry at BD-291 close (Pack-Chat bookkeeping). |
| BD-223 (committed fixture suite; v11.1, after BD-219) | `test-fixtures/build.sh` + manifest (P9/P10) | **COORDINATE** — temporal separation (BD-291 lands in v11.0; BD-223 inherits the hazard fixtures as content). No co-editing window. |
| BD-247 (pack backlog form-family; v11.1) | ∅ (pack `/backlog/` tree + `_rules.md` — both NO-EDIT here) | **NONE (note)** — BD-247 will meet the same synthesis concepts (§3.3); pointer for its future architect. |
| BD-289 (Check 95/96; `core.py` ledger; v11.1) | §6 adds NO validate-pack check; `core.py` NO-EDIT (E-6) — but BD-289's File/Symbol names `supporting-docs/` broadly (the 45 bareness qualifications) and P14 edits `supporting-docs/MIGRATION-v10-to-v11.md` | **COORDINATE (note — F-11 fold)** — family-level contact: any NEW bare `MIGRATION-TRIAGE.md` prose reference P14 adds lands in Check 95's future walk; temporal separation (v11.1) makes it note-grade. IDs/ledger untouched. |
| BD-202 (v11.1 `pack update` engine) | ∅ file overlap; conceptual contact only (MIGRATION-TRIAGE.md is migration-transient + client-owned → not a pack-managed asset class) | **NONE (note)** |
| BD-020, BD-036, BD-037, BD-039, BD-109, BD-110, BD-187, BD-192, BD-254, BD-279 | ∅ (skills/companion-templates/agents/methodology-mode/graphify/optimization surfaces — none in §4) | **NONE** |

**Conclusion:** four COORDINATE signals (BD-171 non-absorption, BD-172 sequencing, BD-223 temporal, BD-289 family-level note), zero co-editing conflicts inside v11.0. SUPPORTED.

## §9 Parallelization map (rule 10)

Same-file commits serialize; disjoint-file work parallelizes. Wave structure for the planner (each wave = one or more commits, each commit its own fresh coder + bounded review/fix cycle):

| Wave | Work | Files | Depends on |
|---|---|---|---|
| **A1** (parallel) | Walker + libs + walker tests + hazard fixtures: §2.3, §2.4, P1–P4, P9, P11, P12 | `per-entry/*` (4 files), `build.sh`, 2 test files | — |
| **A2** (parallel with A1) | Client validator + contract: §3.2, §3.2b, C1, C2 | `changelog/_rules.md`, `validate-docs.sh` | — (disjoint from A1) |
| **B** (serial after A1) | Migrator integration: §2.5, §3.3, P5, P6, P13, P16 | `migrate-v10-to-v11.sh`, `migrate-v10-to-v11/decompose.sh`, 2 migrator test files | A1 (capture env, accounting.sh, id model); A2's fixture-shape agreement (naming + payload validity) |
| **C** (serial after B) | Harness + ops/user docs: §5.1, §7, P7, P8, P14 | `dry-run-migration.sh`, `DRY-RUN-MIGRATION.md`, `MIGRATION-v10-to-v11.md` | B (documents + drives the built behavior) |
| **D** (gate, after C) | Proof runs: fixture-mode sandbox in the battery (incl. m4/m5 bites); the user-approved real-target sandbox run (§5.1 run ii); then BD-291 flip + coordination notes (P15, §8) | — (evidence only) | C |

Notes: A1 and A2 have zero shared files (verified against §4). Within A1, the four `per-entry/*` files stay in a single coder (they co-define the walker contract); `build.sh` + `test-per-entry.sh` may split to a second parallel coder at the planner's discretion. Wave D's real-target run is user-gated (per-action approval; read-only source). **Check 36 keyword eligibility (F-13 fold): A1 and B commits are `pack-only`-eligible; A2 commits are `project-only`-eligible; Wave C commits are NECESSARILY keyword-less (they span `scripts/` + `pack-ops/` + `supporting-docs/` — `pack-only` denies `supporting-docs/`); do not frame a Wave C commit `pack-only`.**

## §10 Open items (each: context → options → evidence-based recommendation)

Census items O-1…O-7 and the adversarial OI-R1…R3 are adjudicated; none defers work out of v11.0. The CONSOLIDATED user-decision list is in `RECONCILIATION-BD-291.md` §4 (one place, per the design-review contract).

- **OI-A1 (census O-1, D-1).** ADOPTED (a) extended: rename covers BOTH root and `docs/project/` (§2.5). (b) rejected — leaves a non-canonical filename alive; (c) manual instructions rejected — mechanical fix measured-possible. Evidence: E-4, E-24.
- **OI-A2 (census O-2, D-2) — naming rule.** Options: (a) always-full-slug (pure function; no collision path; contract example changes); (b) collision-triggered suffixing (order-dependent + permanent special case); (c) fail-loud only (blocks a migration the data proves clean — E-30). **Recommendation: (a)**; evidence: 5-way contract-mapping collision (census §5.6), zero client trees (E-19), 55/55 distinct under the rule (E-30). USER CONFIRMATION requested (shipped-contract examples change).
- **OI-A3 (D-6) — phase `Status:` + `Goal:` policy (AMENDED).** Context: 61 phases lack `Status:` (no mechanical source, E-13/E-14) and 7 lack `Goal:` (narrative, E-25). Options: (a) leave absent → validator names all 68; suggestion table (Status) + authored fill (Goal) via MIGRATION-TRIAGE; (b) synthesize Status from checklists → silently wrong where stale; Goal unfabricatable regardless; (c) blanket `not-started` → wrong for ~28 measured-✓ phases. **Recommendation: (a)** — honest-red-with-precise-instructions; declare-verify-backing forbids fabricated records. USER DECISION requested (first-run experience).
- **OI-A4 — the "end-to-end green" definition (AMENDED).** Options: (a) set-equality green (§5.1(d)); (b) strict-zero green (forces fabrication). **Recommendation: (a)**; evidence RE-DERIVED this session: the residual set is precisely enumerable and mechanically assertable — measured 68 pre-C2, exactly 72 = declared post-C2 (E-25/E-26); the instrument is exact only WITH §3.2b. USER SIGN-OFF requested (operationalizes the AC wording).
- **OI-A5 (harness home).** ADOPTED (a): extend `dry-run-migration.sh` (reuses containment machinery, E-21); (b) new sibling duplicates ~200 lines. Documented prominently (P8).
- **OI-A6 (census O-3, D-3).** ADOPTED: mechanical preservation floor as the single triage file (§3.1) + BOTH derived membership maps (§3.1.3/§3.1.4); instructions ship as the TRIAGE procedure (§7), not as a substitute for preservation. Evidence: E-7 (destination safety), census §5.5, E-28.
- **OI-A7 (census O-4, D-4).** ADOPTED (a): migrator calls the generator; availability PROVEN (E-8).
- **OI-A8 (census O-5, D-5).** ADOPTED (a) with the §3.2 refinement + the misname-leg closure of the silent-SKIP hole (E-7/E-23).
- **OI-A9 (census O-6).** ADOPTED (a): §5.3 encodes the field-census as a permanent line-multiset test + hazard fixtures + bite mutations m1–m5.
- **OI-A10 (census O-7).** ADOPTED beyond the census minimum: full fence-aware walk (§2.3.1), justified as misplacement-prevention (E-29 corrected the old "gate catches it" claim) and as the safety precondition of the H1-break class.
- **OI-A11 (U-1 closure relay).** Options: (a) user relays the §7 Step-3 guarantee + check to the target-app PM chat and the second pack chat; (b) nothing (stale observation resurfaces). **Recommendation: (a)** — one message; the in-doc guarantee is the durable half regardless. USER ACTION item.
- **OI-A12 (out-of-enum payload values — AMENDED).** Options: (a) synthesize verbatim → the §3.2b leg flags → client fixes with judgment (recommendation, now measured-true: E-26 proves the leg was ABSENT, §3.2b adds it); (b) pack-side enum extension — rejected (client vocabulary drift must not widen the shipped schema); (c) migrator guess-maps — fabrication, rejected. Evidence: E-12, E-26, E-27.
- **OI-A13 (target HEAD drift).** ADOPTED (a): §5.1 run (ii) re-measures at migration-day HEAD by construction. Input identity at this pass verified byte-count-exact (E-24).
- **OI-A14 (graph coverage gap).** ADOPTED (a): fold E-20 (re-confirmed this session: zero subsystem signal, unrelated-node noise) as evidence into BD-254 (existing open graphify-adoption anchor) at its architect stage — BD-254's live scope, not BD-291 work. Pack Chat records the pointer at batch close.

## §11 Rules-Applied Verification Block

1. **agents-never-commit** — Evidence: every git invocation this session was read-only in this worktree (`pwd` → `…/agent-ad313e07a831b5847`; `git rev-parse HEAD` → `0c2709e…`; `git worktree list`; `git status --porcelain`); the platform additionally refused compound commands; zero state-changing git verbs in any tree; the target checkout was touched only by plain `cp` reads. **COMPLIANT**
2. **empirical-evidence-blocks** — Evidence: §0's E-1…E-31 ledger — every entry re-run THIS session (commands + captured outputs quoted; HEAD `0c2709e`, 2026-08-25); every state claim in §§1–10 cites an E-n; §8 is itself an EEB re-measured this session. **COMPLIANT**
3. **cross-bd-collision-scan** — Evidence: §8 — structured-path intersection of §4's P1–P16+C1–C2 against all 16 other open BDs (E-19), project-side stream entry-empty; four COORDINATE signals incl. the F-11-corrected BD-289 row. **COMPLIANT**
4. **ci-guard-measure-then-bound + declare-verify-backing** — Evidence: §6 (no-new-check decision measured); §3.2 misname leg (population 0, empty allowlist, reached-assertion); §3.2b payload legs (population 4+0 measured at E-26/E-12, phase-N template preserved for the 13 real carriers, empty allowlist, three bite cases); §5.1(b/d) records-style legs now bite-proven by m4/m5 (§5.3). **COMPLIANT**
5. **design-discipline-challenge** — Evidence: every folded correction was re-derived, not inherited — the F-1 chain re-measured (E-26) and its arithmetic CORRECTED beyond the adversary's own number (E-25: 68, not 61); the gate-scope claim replaced on my own simulation (E-29); the H1-break class verified safe for pack data before adoption (E-28). **COMPLIANT**
6. **verify-availability-not-existence** — Evidence: load-bearing capabilities RUN this session — the shipped validator on rebuilt real trees (400/387/68), the index generator (rc=0/67), the synthesis recipes (probe-green), the negative payload probes (green — capability measured ABSENT, E-26), slug uniqueness (55/55, E-30); the remaining unmeasured step (run ii) stays an explicit Resolved-precondition gate. **COMPLIANT**
7. **dependency-direction-placement** — Evidence: `accounting.sh` pack-side (migrator runtime dep, never shipped; `_SANCTIONED_PACK_SIDE_SHIPPED` untouched); MIGRATION-TRIAGE.md migrator-GENERATED client content (no template file; no pack runtime dependency on it); no dual-use file (§4 preamble). **COMPLIANT**
8. **ci-check-runtime-compounding** — Evidence: gate O(lines)/Counter, migration-time-only (§2.2); both C2 legs ride the already-scanned conformance listing (§3.2/§3.2b); §6 adds no validate-pack check. **COMPLIANT**
9. **fail-loud-delete-old-source** — Evidence: slug-optional comment + bare-date fallback DELETED (§2.4); contract mapping example REPLACED (§3.2); monolith deletion retained and made safe by the gate (§2.5); superseded original-design text REPLACED outright in this document, not annotated around. **COMPLIANT**
10. **architect-doc-reality-reconciliation** — Evidence: §3.3's chain preserved (synthesis docstring names `index-generate.sh` `field_value`/`parse_phase_refs` — file + symbol, no line numbers; this doc is the anchor; IMPL-REPORT cross-links specified). **COMPLIANT**
11. **operating-docs-no-history-no-bloat** — Evidence: every specified doc/contract edit is procedural, present-tense (§3.2 rewrite, §7 procedure + recovery paragraph, P8, P14 repairs); the E-31 stale `_intro.md` claim is FIXED, not narrated; no incident/SHA text enters any operating surface. **COMPLIANT**
12. **open-item-surfacing** — Evidence: §10's 14 items each carry context + options + an evidence-cited recommendation (three AMENDED with this session's measurements); none recommends from memory; none defers BD-291 work. **COMPLIANT**
13. **memory-not-an-ssot** — Evidence: every rule/contract claim cites a live in-repo path read this run (`project-template/scripts/validate-docs.sh`, the four project `_rules.md`, `scripts/lib/per-entry/*.sh`, the migrator files, `scripts/lib/migrator-stages.sh`, `scripts/lib/validate_checks/core.py`, `supporting-docs/MIGRATION-v10-to-v11.md`, `backlog/BD-*.md`, pack-root `CLAUDE.md` keyword table) or a handoff artifact by path. **COMPLIANT**
14. **public-bound-no-leak** — Evidence: this doc lives out-of-repo; target-app vocabulary appears only inside verbatim-quoted measurement evidence; every IN-REPO deliverable specified is neutral (synthetic fixture content mandated at §5.3; contract examples are the shipped placeholder style). **COMPLIANT**
15. **no-deferral-without-user-direction + deferral-is-scope-creep** — Evidence: all seven defect classes land in v11.0 (§9 waves A–D); the D-7 fix and the R-1 manual-fill class land inside existing waves (A2/B/C); OI-A14 anchors to an already-open BD's live scope; the USER-tagged items are decision requests, not deferrals. **COMPLIANT**
16. **rules-applied-verification-block** — Evidence: this block; the fuller 18-rule attestation with per-rule quoted evidence closes `RECONCILIATION-BD-291.md` (same handoff dir). **COMPLIANT**

