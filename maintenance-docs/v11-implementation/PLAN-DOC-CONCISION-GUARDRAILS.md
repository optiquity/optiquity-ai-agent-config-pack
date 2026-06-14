# PLAN — Document Concision + Boundary-Completeness Guardrails

**Type:** Read-only implementation plan (pack-planner output). Sequences the approved design `maintenance-docs/v11-implementation/ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` (v9, locked) into a commit-by-commit run. No file edits except this plan doc; no git state changes.
**Scope class:** STRUCTURAL (the architect design is the justification). No BD assigned (explicit user direction) — see §SC8 flag.
**HEAD at planning:** `3bef42b6117ffa16a42b0ad5094acdaa1ff6aa42`, 2026-05-30. `python3 scripts/validate-pack.py` = PASSED (clean) at this HEAD.
**Working-state invariant (load-bearing):** `validate-pack.py` (all 38 invoked checks) AND every per-check test under `scripts/tests/test-validate-pack-check*.sh` MUST pass at EVERY commit boundary. Every new check is wired LIVE only in a commit where the tree it scans is already clean (§SC2).

---

## 0. Locked constraints I sequence (NOT redesign)

C1 (imperative two-clause + `[rationale: slug]` + `[roles:]` tag); C3 (single `pack-ops/PACK-MEMORY-RATIONALE.md` + bijection check); B5 (`.boundary-pointer-manifest.txt` + reference-resolution check); C2 (SHAs/dates forbidden in durable docs, mandatory in reports); M1–M4 (proof-leaves-deliverable / corpus-split / finding-record-cap / concision gate); D1 (companion templates project-side-governed, Check 37 walk extended); D2 (purpose-classifies, drop "(new top-level pack-only dir)"); §4.2-DROP (no new separated-not-combined check; Check 37 + opt-in convention suffice); §9 single-source (`## Pack memory` is the spawn-source; 6 restatements collapse to references; `.spawn-rule-manifest.txt` + anti-restate scan); §9.7 thin memory-cache (out-of-repo, NO pack generator); §11 discoverability (index DROPPED; one-line routing pointers folded into B5 manifest); §12 propagation table (EXTEND PACK-CHAT "Keeping current", compose existing checks); §8 step list incl. 7b blast-radius sweep.

These are FIXED. Where the design left a sequencing decision (which it does not resolve), I resolve it here with an Empirical-Evidence Block and flag it for the user (§9).

---

## 1. Empirical baseline (the facts that drive the ordering)

> **EE-P1 — current state of the surfaces this work touches.** HEAD `3bef42b`, 2026-05-30.
> - `validate-pack.py`: 6174 lines, 38 checks dispatched in `main()` (L6058–6162); last check is Check 42 (CI-wiring guard, L6162). New checks append after Check 42's callsite. Highest check ID in use = 43 (Check 43 is `check_project_side_bare_internal_refs`, defined before Check 41/42 but a distinct ID). Next free IDs = 44, 45, 46.
> - `CLAUDE.md` `## Pack memory` = 45 top-level bullets (L136–916). `AGENTS.md` = 41 bullets (877 lines). `GEMINI.md` = 41 bullets (857 lines). ZERO `[rationale:` / `[roles:` tags exist today (grep count 0/0/0). Trinity sub-sections: `### Workflow` L143, `### Agent invocation rules` L252, `### Sub-agent behavior (Claude-only)` L498, `### Pack Chat scope` L537, `### Repo conventions` L668, `### Project goals (v11)` L911.
> - 7 durable `pack-ops/` non-mirror docs (M4 target class): BOUNDARY-DEFINITION 255, CONCEPTUAL-REVIEW-METHODOLOGY 298, DRY-RUN-MIGRATION 199, HELP-FRAGMENT-PACK 42, HELP-FRAGMENT-TRACKER 49, MERGE-STRATEGY 484, OPTIONAL-FEATURES 235, PACK-AGENTS 259, PACK-CHAT 291. (BACKLOG.md / CHANGELOG.md are regenerated mirrors, NOT in the M4 class.)
> - **M4 forbidden-pattern probe (dates / 7-40-hex-SHA / `Commit N` / `Override N` / `post-Commit` / `will `) line-hit counts:** BOUNDARY=15, CONCEPTUAL-REVIEW=11, MERGE-STRATEGY=6, OPTIONAL-FEATURES=4, DRY-RUN=2, HELP-FRAGMENT-PACK=0, HELP-FRAGMENT-TRACKER=0. **Conclusion: the M4 gate would FAIL on 5 of 7 durable docs at HEAD.** It CANNOT be wired live until those docs are cleaned (drives the §SC2 ordering: clean BOUNDARY in its reshape commit + the other docs in commit C9 BEFORE M4 goes live).
> - `pack-ops/.boundary-exempt-root.txt` exists (1 entry: `tracker.toml.pack-example`). NO `.boundary-pointer-manifest.txt` and NO `.spawn-rule-manifest.txt` exist yet (both are new this work).
> - PACK-AGENTS.md L190–228 = the PREFLIGHT block: it carries the imperative TEXT and already ends with "Authoritative full text: trinity `## Pack memory` …". This is EE-6's "PARTIAL restate" — a §9.6 anti-restate substring scan WOULD FAIL on it today even though it already references. (SC7 evidence.)
> - `scripts/tests/`: 10 per-check test files; CI workflow `.github/workflows/validate-pack.yml` wires all 10 (Check 42 green). New checks need new test files + new workflow wiring lines, or Check 42 FAILs.
> - `test-fixtures/manifest.txt`: 6 fixture rows; `bash test-fixtures/build.sh --all --clean` is the regen command; the manifest does NOT enumerate pack-ops/ paths but pack-ops/ edits ARE v11-surface (manifest-regen trigger fires; diff likely empty for non-installed pack-ops docs but the rebuild+stage-if-diff discipline is mandatory).
> Conclusion: **SUPPORTED.** The dominant ordering constraint is the M4 clean-tree-before-live rule + the new-check-needs-test+wiring rule (Check 42).

---

## 2. The four new validator checks + their wiring dependencies

The design adds exactly THREE new validator checks (the §4.2 check is DROPPED). Each follows an existing pattern and each needs a per-check test + a CI-workflow wiring line (or Check 42 fails):

| New check | Next free ID | Pattern reused | Scans | Clean-tree precondition |
|---|---|---|---|---|
| M4 concision gate | Check 44 | new pattern-scan + per-doc advisory length + allowlist file | the 7 durable `pack-ops/` non-mirror docs | ALL 7 docs forbidden-pattern-count = 0 outside allowlist (today: 5 FAIL) |
| C3 rule↔rationale bijection | Check 45 | Check 32 `check_mirror_in_sync` (set-equality) | `[rationale: slug]` set in CLAUDE.md `## Pack memory` vs `## <slug>` set in PACK-MEMORY-RATIONALE.md | both sides authored + equal (commit C2/C3) |
| B5 pointer-manifest + spawn-rule anti-restate/reference-resolution | Check 46 (combined) OR Check 46 + 47 | Check 34 `check_cross_reference_integrity` (reference-resolution) + Check 32 (set-compare) | `.boundary-pointer-manifest.txt` surfaces resolve; `.spawn-rule-manifest.txt` refs resolve; NO canonical imperative text duplicated in 2+ surfaces | manifests authored + all pointers present + 6 restatements collapsed |

> **Design-gap G-A (resolved + flagged, §9).** §8 step 4b describes the spawn-rule check as "(a) reference-resolution + (b) anti-restate substring scan" and §4.3/§5.2 describe B5 (pointer-manifest reference-resolution) and C3 (bijection) as separate checks. The design does NOT fix the exact NUMBER of new check functions (could be 3 or 4 depending on whether B5 + spawn-rule-reference-resolution share one function). I sequence them as **3 new check IDs** (44 M4, 45 C3-bijection, 46 B5+spawn combined as one reference-resolution + anti-restate function over two manifest files) to minimize surface; the coder MAY split 46 into 46+47 if the implementation is cleaner — that is a coder/reviewer call, NOT a design change. Either way the wiring + test + clean-tree rules below hold per-check. Flagged for user awareness; does not block.

---
## 3. Commit sequence (SC1)

The ordering principle (SC2): **author/clean the scanned tree, THEN wire the check that scans it — never wire a check against a violating tree.** Restatement collapse + manifest authoring happen in the SAME commit as (or a prior commit to) the check that asserts them. Step 7b (blast-radius sweep) is a COMPLETION CRITERION of every reshape/removal commit (SC6), not a trailing step.

Twelve commits (C1–C12). Each is a pack-coder run + the bounded per-commit review/fix cadence (§4).

### C1 — Pack-memory corpus: add `[roles:]` tags + `[rationale: slug]` pointers + two-clause imperatives (TRINITY lock-step) — NO check wired
- **Files:** `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (`## Pack memory` only). TRINITY lock-step — all three in the SAME commit (SC5).
- **Changes:** For each spawn-relevant imperative bullet (~22 of 45 per EE-6), (a) rewrite the imperative line to the two-clause `<DIRECTIVE>+<TRIGGER>` application-grade contract (C1-(i)); (b) append `[roles: …]` controlled-vocab tag (C1/§9.4); (c) append `[rationale: <slug>]` pointer (C1/§5.1). Why/example bodies STAY in place this commit (they leave in C2) — the imperative line edit is additive here so the corpus is never half-split.
- **Why here:** the slug vocabulary must exist BEFORE the rationale file (C2) and BEFORE the bijection check (C3) can assert set-equality. Tagging first establishes the SSOT slug-set.
- **Working state:** NO new check wired. Existing trinity-parity Check 18/19/16 + Check 11 run against the edited corpus — they assert H2 structure / scaffolding / addenda, NOT the new tags, so they stay green. `[rationale:]`/`[roles:]` are inline text the trinity rule already governs (parity holds by construction). Manifest-regen trigger: `CLAUDE.md` etc. at pack-root are NOT under the 4 trigger dirs (`project-template/`/`scripts/`/`pack-ops/`/`supporting-docs/`) — pack-root trinity is C3, not v11-surface; **no manifest regen.** (Verify: pack-root `CLAUDE.md` is not copied by init-project.sh.)
- **7b sweep:** none — additive, removes nothing.
- **Trinity:** YES (the defining trinity-lock-step commit).

### C2 — Author `pack-ops/PACK-MEMORY-RATIONALE.md`; move Why/How/example bodies out of corpus (M2/C3) — NO check wired yet
- **Files:** `pack-ops/PACK-MEMORY-RATIONALE.md` (NEW); `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` (`## Pack memory` bodies stripped to imperative + tags + slug). TRINITY lock-step on the corpus strip.
- **Changes:** create one `## <slug>` section per tagged rule = Why + How-to-apply-worked-example + rejected-alternatives. Strip those same bodies from the three corpus files (M2 split). Slug-set in rationale file == slug-set in corpus (C3 bijection precondition).
- **Why here:** rationale file must exist + be in bijection BEFORE C3's bijection check goes live (C3 commit). Splitting AFTER tagging (C1) means slugs already exist to key on.
- **Working state:** NO new check wired. Manifest-regen trigger FIRES (`pack-ops/` touched): run `bash test-fixtures/build.sh --all --clean`; stage `manifest.txt` if diff non-empty (likely empty — RATIONALE.md is not installed by init-project.sh — but the rebuild+check is mandatory). The bijection is NOT yet asserted, so a transient mismatch here cannot fail CI; but the coder authors it 1:1 so C3 lands clean.
- **7b sweep:** any in-repo cite of "the Why in `## Pack memory`" / "see the rationale in the corpus" must repoint to `[rationale: slug]`. Grep whole repo (excl. prison/, archive/) for `## Pack memory.*Why|Why.*## Pack memory|rationale in.*Pack memory`; fix-or-remove each. (Completion criterion of THIS commit.)
- **Trinity:** YES (corpus strip is trinity'd).

### C3 — Wire C3 bijection check (Check 45) + per-check test + CI wiring — tree already clean from C2
- **Files:** `scripts/validate-pack.py` (add `check_pack_memory_rationale_bijection`, callsite after Check 42); `scripts/tests/test-validate-pack-check-45.sh` (NEW); `.github/workflows/validate-pack.yml` (wire the test); possibly `pack-ops/.boundary-exempt-root.txt` unaffected.
- **Changes:** Check 45 parses `[rationale: slug]` from CLAUDE.md `## Pack memory` and `## <slug>` headings from RATIONALE.md; FAILs on set-inequality (Check 32 pattern). Per-check test exercises pass + injected-orphan-fail cases.
- **Why here:** C1 (slugs) + C2 (rationale file, 1:1) make the bijection PASS at this HEAD. Wiring against the clean tree honors the "never wire against a violating tree" rule.
- **Working state:** `validate-pack.py` touched → run the relevant per-check tests (45, plus 32/34 because Check 45 reuses the set-compare helper pattern — run all per-check tests when in doubt, ~5-15s). Check 42 (CI-wiring) sees the new test wired → stays green. Manifest trigger FIRES (`scripts/` + `pack-ops/` touched) → rebuild + stage-if-diff.
- **7b sweep:** none new (additive check).
- **Trinity:** no (validator/test/CI only).

### C4 — Reshape `BOUNDARY-DEFINITION.md` to §7 target (clean its 15 forbidden-pattern hits) + add §2.2/§2.3/§3-WHEN/HOW/§5 content; relocate §5/§6/§7 history — NO M4 wired yet
- **Files:** `pack-ops/BOUNDARY-DEFINITION.md` (reshape to ~80–95 lines); relocation target (a rationale sibling or `maintenance-docs/archive/v11/`) for old §5 anti-pattern catalog + §7 worked examples + §4 "Why only 1 entry" override-history. Possibly `pack-ops/.boundary-pointer-manifest.txt` NOT yet (B5 lands C7).
- **Changes:** per §7 target — keep §1/§2 matrix (+ §2.2 companion note + §2.3 purpose-classifies sentence)/§3 four-step (+ WHEN/HOW addendum table)/§4 exemption/§5 NEW content-rules (Bans A/B/C + separated-not-combined named, each + check name); DELETE §6 cross-ref-network prose → one line "Pointer network is CI-asserted (`.boundary-pointer-manifest.txt`)"; relocate §5/§7 history; drop ALL dates/`Commit N`/`Override N`/`post-Commit`/`will` (the 15 M4 hits → 0). Drop the stale "(new top-level pack-only dir)" wording (D2).
- **Why here:** BOUNDARY must be M4-clean BEFORE M4 (C9) goes live. Reshaping it early (and sweeping its orphaned refs now) de-risks the M4 wiring. It lands before B5 (C7) because the deleted §6 prose is what B5's manifest replaces — but the manifest FILE + check land in C7; this commit leaves the one-line forward reference to it (resolvable as plain prose until C7 asserts it).
- **Working state:** NO new check wired. Check 37/38/40 run against reshaped BOUNDARY (it is a pack-ops/*.md doc — Check 40 bare-ref scanner applies): the relocation must not introduce bare-refs Check 40 fails on (the 7b sweep covers this). Manifest trigger FIRES → rebuild + stage-if-diff. Existing checks stay green.
- **7b sweep (MANDATORY completion criterion):** grep whole repo for inbound cites of BOUNDARY `§5`/`§6`/`§7` (e.g., "see `BOUNDARY-DEFINITION.md` §6", "the discoverability invariant", "cross-reference network", "(new top-level pack-only dir)"); the source-of-design header of BOUNDARY itself; any agent-file/PACK-CHAT/PACK-AGENTS/README pointer that names a now-deleted section. FIX-OR-REMOVE each. NOTE: BOUNDARY §6 currently claims it is "referenced from every operating-doc entry point" — that §6 cross-reference network was ASPIRATIONAL, never real. Measured at HEAD: of the surfaces §6 names (README, PACK-CHAT, PACK-AGENTS, pack-* agents, project PM-CHAT), ONLY README carries a `BOUNDARY-DEFINITION.md` pointer; PACK-CHAT / PACK-AGENTS / pack-root trinity / pack-* agents / project PM-CHAT carry ZERO. The B5 manifest (C6) binds to the 8 surfaces that ACTUALLY resolve (README + the 3 CLI + project-template `boundary-investigation` skills + the project-template trinity), not the aspirational §6 set. So the 7b sweep does NOT need to re-validate aspirational inbound pointers that never existed — it confirms the README pointer (the one real §6-named inbound) still resolves to a live section, and that no in-repo prose still asserts the aspirational §6 network.
- **Trinity:** no (single pack-ops doc) — UNLESS the 7b sweep requires editing a pack-root trinity pointer line, in which case that edit is trinity-lock-step within this commit.

### C5 — Author `.spawn-rule-manifest.txt`; collapse the 6 PACK-AGENTS/PACK-CHAT restatements to one-line references (incl. the PREFLIGHT block) — NO check wired yet
- **Files:** `pack-ops/.spawn-rule-manifest.txt` (NEW: slug → {canonical: `## Pack memory`, references: [PACK-AGENTS.md §x, PACK-CHAT.md §y]}); `pack-ops/PACK-AGENTS.md` (collapse the 3 restatements incl. L190–228 PREFLIGHT block); `pack-ops/PACK-CHAT.md` (collapse the 3 restatements).
- **Changes:** each restatement → one-line "X — see trinity `## Pack memory` `[rationale: <slug>]`". The PREFLIGHT block (EE-6 PARTIAL restate) drops its imperative TEXT, keeps only the reference (it already has the "Authoritative full text" line — extend that to the canonical one-liner form).
- **Why here:** the anti-restate substring scan (C6) FAILs if any canonical imperative text still appears verbatim in PACK-AGENTS/PACK-CHAT. Collapse MUST precede or co-locate with wiring (SC7). Authored here; check goes live next commit (C6) against the now-collapsed tree.
- **Working state:** NO new check wired. Manifest trigger FIRES (`pack-ops/`) → rebuild + stage-if-diff. Existing Check 40 (pack-ops bare-ref scanner) runs against the edited PACK-AGENTS/PACK-CHAT — the new one-line references must carry resolvable cites (7b/Check 40 anchor allowlist).
- **7b sweep (completion criterion):** any in-repo cite of "as restated in PACK-AGENTS" / "PACK-CHAT restates the cadence" must repoint to the canonical corpus line. Grep for the 6 restated rule names across the repo.
- **Trinity:** no (pack-ops docs only; corpus untouched this commit).

### C6 — Wire B5 + spawn-rule check (Check 46: pointer-manifest + spawn-rule reference-resolution + anti-restate scan) + test + CI wiring — tree clean from C4/C5
- **Files:** `scripts/validate-pack.py` (add `check_boundary_and_spawn_pointer_manifests` — or split per G-A; callsite after Check 45); `pack-ops/.boundary-pointer-manifest.txt` (NEW — the B5 entry-point manifest, replacing deleted BOUNDARY §6 prose; binds ONLY the surfaces that actually carry a `BOUNDARY-DEFINITION.md` pointer at HEAD — measured: 8 surfaces. The §11.3 per-actor routing pointers are NOT folded here; they are authored in C8); `scripts/tests/test-validate-pack-check-46.sh` (NEW); `.github/workflows/validate-pack.yml` (wire it).
- **Changes:** reference-resolution over BOTH manifests (Check 34 pattern): every named surface carries its expected pointer; anti-restate substring scan (the C5 collapse makes this PASS). The B5 manifest binds ONLY the surfaces that actually resolve at HEAD (measured: 8 surfaces — README, the 3 CLI `boundary-investigation` SKILL.md, the project-template trinity, and the project-template `boundary-investigation` SKILL.md). The §11.3 per-actor routing pointers are authored + folded into the manifest in C8 — NOT here; Check 46's reference-resolution is the shared mechanism both commits ride (no separate check).
- **Why here:** C4 deleted BOUNDARY §6 (manifest is its replacement); C5 collapsed the restatements (anti-restate scan passes). Wiring now hits a clean tree. **SC7 MITIGATION (load-bearing):** before the coder wires the anti-restate substring predicate LIVE, it MUST MEASURE the predicate against the real surfaces (run the candidate substring scan of every canonical imperative against PACK-AGENTS/PACK-CHAT/skills) and confirm 0 hits post-C5-collapse. If the predicate false-positives on a legitimate one-line reference that NAMES a rule (the §4.2 12/12-storm shape), the coder reports it INSTEAD of wiring — the predicate is re-scoped (anchor-window/length-threshold) before going live. This is the measure-then-bound rule applied to the anti-restate predicate.
- **Working state:** `validate-pack.py` + `pack-ops/` + `scripts/tests/` + workflow touched → run per-check tests (46 + 32 + 34 for shared pattern; when in doubt all). Check 42 sees new test wired → green. Manifest trigger FIRES → rebuild + stage-if-diff.
- **7b sweep:** none new (the C4/C5 sweeps already repaired the deleted §6 + collapsed restatements; C6 only asserts them).
- **Trinity:** no.

### C7 — Extend Check 37 walk to companion-template dirs (D1) + update Check 37 test — dirs already clean
- **Files:** `scripts/validate-pack.py` (`_iter_client_installed_files()` or the Check 37 walk set extended to include `xcode-companion-templates/` + `vscode-companion-templates/`); `scripts/tests/test-validate-pack-checks-36-37-38.sh` (update expected walk-set count); `.github/workflows/validate-pack.yml` (no new line — test already wired). Possibly `pack-ops/BOUNDARY-DEFINITION.md` §2.2 note already authored in C4 (no re-edit).
- **Changes:** add the two dirs to Check 37's walk. Per EE-2/§2.2: both dirs are grep-verified clean (0 deny-list hits) → forward-protection only, zero cleanup.
- **Why here:** independent of the corpus/manifest work; placed after the manifest checks so the validator's check-set is stable. Could move earlier, but grouping all `validate-pack.py` check changes around C3/C6/C7 keeps per-check-test runs batched.
- **Working state:** `validate-pack.py` + a `_iter_*` inventory helper touched → MUST run the per-check test files exercising Check 37 AND any test that exercises the same `_iter_client_installed_files()` helper (Check 41 + Check 43 reuse the parse) — run `test-validate-pack-checks-36-37-38.sh`, `test-validate-pack-check-41.sh`, `test-validate-pack-check-43.sh`; ALL must pass. **RISK (flag):** if extending the walk changes the file-count that Check 41 (`_CLIENT_INSTALLED_FILES` inventory) or Check 43 asserts, those tests/inventories update in lock-step (the "enumerate ENCODING surfaces" rule — validator + tests + any inventory). Coder verifies whether companion-template dirs are in `_CLIENT_INSTALLED_FILES`; if Check 37's walk is a SEPARATE set from the install inventory (likely — companion templates are NOT installed by init-project.sh), Check 41 is unaffected. Empirical check is a coder PREFLIGHT obligation.
- **7b sweep:** none (additive walk extension).
- **Trinity:** no.

### C8 — §11.3 routing pointers (PACK-CHAT "File access strategy" + review skill) + §12 propagation table (PACK-CHAT "Keeping current") + CLAUDE.md stale-entry pointer — index stays DROPPED
- **Files:** `pack-ops/PACK-CHAT.md` (§ "File access strategy" gains 4 routing pointers; § "Keeping … current" EXTENDED with the §12 ordered surfaces-1-6 propagation table); `.claude/skills/review/SKILL.md` (existing SSOT cites gain `[roles: reviewer]`+universal pointer); `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` (`## Pack memory` stale-entry rule gains a one-line pointer to the §12 procedure — TRINITY lock-step); `pack-ops/.boundary-pointer-manifest.txt` (the §11.3 per-actor routing pointers — PACK-CHAT "File access strategy" pointers + the `review` skill pointer + BOUNDARY self-homed — are authored THIS commit and folded into the manifest THIS commit; extend the manifest with each new routing-pointer surface and re-verify Check 46 stays green in THIS commit. C6 authored ONLY the B5 entry-point manifest — the 8 surfaces that already resolved at HEAD).
- **Changes:** per §11.3/§12. Index DROPPED (Decision B) — NO new index file, NO new view, NO new check. Pointers are one-line references riding Check 46's existing reference-resolution.
- **Why here:** depends on C6's `.boundary-pointer-manifest.txt` + Check 46 existing (the routing pointers must resolve under that check). The §12 table composes existing checks (C3 bijection, anti-restate, trinity-parity, manifest gate) — no new check.
- **Working state:** NO new check. Check 46 re-runs against the new/edited routing pointers → they must resolve (manifest updated same commit). Trinity-parity checks run against the CLAUDE.md stale-entry pointer edit (parity holds — trinity lock-step). Manifest trigger FIRES (`pack-ops/` + skill under no trigger dir — `.claude/skills/` is NOT one of the 4 trigger dirs; PACK-CHAT IS pack-ops) → rebuild + stage-if-diff. Per-check test for Check 46 re-run (manifest content changed).
- **7b sweep (completion criterion):** the WITHDRAWN discoverability index (§11.2) — grep for any cite of "the rule×audience index" / "the unified index" / "the discoverability index" (the v6 proposal); FIX-OR-REMOVE (these are design-doc-internal mostly, but sweep the repo). Any cite of "see PACK-CHAT for the index" repoints to "query the SSOT directly".
- **Trinity:** YES (CLAUDE.md stale-entry pointer is `## Pack memory` — trinity lock-step).

### C9 — Reshape the other 6 durable `pack-ops/` docs (clean forbidden-patterns) + collapse M3 finding-record — tree made M4-clean
- **Files:** `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (11 hits→0), `MERGE-STRATEGY.md` (6→0), `OPTIONAL-FEATURES.md` (4→0), `DRY-RUN-MIGRATION.md` (2→0), `HELP-FRAGMENT-PACK.md` (0 — verify), `HELP-FRAGMENT-TRACKER.md` (0 — verify). (BOUNDARY already cleaned in C4.) Plus the M3 finding-record collapse target — per PLAN-BD-195-INVESTIGATION.md §3.2 the finding-record shape is defined in that PLAN doc (a `maintenance-docs/v11-implementation/` artifact), NOT a durable pack-ops doc; the M3 hard-cap applies to the finding-record TEMPLATE wherever the durable copy lives.
- **Changes:** strip dates/SHAs/`Commit N`/`Override N`/temporal claims; relocate any history to rationale/archive; collapse finding-record per-field to one-line evidence + rule-by-name (M3).
- **Why here:** the LAST tree-cleaning commit before M4 (C10) goes live. After C9 ALL 7 durable docs have forbidden-pattern-count 0 outside the allowlist — the M4 "0-outside-allowlist proof is a coder obligation" is dischargeable here (the coder greps + proves 0).
- **Working state:** NO new check (M4 not yet live). Check 40 (pack-ops bare-ref) runs against reshaped docs. Manifest trigger FIRES → rebuild + stage-if-diff.
- **7b sweep (completion criterion):** any inbound cite of the relocated history sections in these 6 docs; the M3 cite of "the 12-field record"/"PLAN-BD-195 §3.2 record shape" if collapsed. FIX-OR-REMOVE.
- **Trinity:** no (pack-ops docs) — unless a trinity pointer to a relocated section needs repair (then lock-step in-commit).

### C10 — Wire M4 concision gate (Check 44) + per-doc allowlist + advisory length + test + CI wiring — tree clean from C4+C9
- **Files:** `scripts/validate-pack.py` (add `check_durable_doc_concision`, callsite after Check 42/45/46); `pack-ops/.concision-allowlist.txt` (NEW — per-doc forbidden-pattern allowlist, sized to KEEP-only per measure-then-bound); `scripts/tests/test-validate-pack-check-44.sh` (NEW); `.github/workflows/validate-pack.yml` (wire it).
- **Changes:** M4 = forbidden-pattern count 0 outside allowlist (the teeth) + per-doc advisory length (derived from measured legitimate content, NOT round-number). **measure-then-bound (load-bearing):** the coder MEASURES the post-C4/C9 tree, categorizes every residual forbidden-pattern hit KEEP (→allowlist) or STRIP (→must already be 0 from C4/C9), sizes the allowlist to KEEP-only, and proves the gate runs clean against the actual tree BEFORE wiring. The allowlist is NOT widened to make the gate pass — any residual STRIP hit means C4/C9 was incomplete (route back, do not widen).
- **Why here:** C4 (BOUNDARY) + C9 (other 6) made all 7 docs clean. This is the FIRST commit where M4 can be wired against a non-violating tree (the dominant SC2 constraint — EE-P1 shows 5/7 docs FAIL at HEAD).
- **Working state:** `validate-pack.py` + `pack-ops/` (allowlist) + `scripts/tests/` + workflow touched → run all per-check tests (44 + neighbors). Check 42 sees new test wired → green. Manifest trigger FIRES → rebuild + stage-if-diff. **This commit's PREFLIGHT MUST include the coder's grep-proof that M4 = 0-outside-allowlist on the live tree (the v1 EE-5 coder obligation).**
- **7b sweep:** none new.
- **Trinity:** no.

### C11a — Restore fenced format templates + manifest base-case to `PACK-MEMORY-RATIONALE.md` (mid-execution fix commit)
- **Files:** `pack-ops/PACK-MEMORY-RATIONALE.md` (restore the fenced format templates + the manifest base-case content that earlier reshaping had dropped).
- **Changes:** completes the rationale SSOT so it carries the full set of fenced format templates + the manifest base-case BEFORE the C11 out-of-repo cache-thinning references it. Inserted mid-execution after the C12 audit/review surfaced the gap; not part of the original SC1 sequence.
- **Why here:** the thin cache pointers (C11) point into the rationale SSOT, so the rationale SSOT must be complete first. This commit closes the SSOT before C11's thin-pointer model takes effect — it precedes C11 in effect even though it was authored after the C10–C11 ordering was first sequenced.
- **Working state:** `pack-ops/` touched → run full `validate-pack.py`; manifest trigger fires → rebuild + stage-if-diff.
- **Trinity:** no.

### C11 — §9.7 thin memory-cache (OUT-OF-REPO; NOT a commit) — Pack-Chat upkeep note
- **Files:** NONE in the pack repo. **Realized scope (measured):** the out-of-repo memory dir at `~/.claude/projects/<slug>/memory/*.md` holds 27 per-rule files; only 4 were genuine trinity-rule-with-rationale duplicates (`agent-output-rules-applied-block`, `architect-planner-empirical-evidence`, `ci-guard-design-measure-then-bound`, `manifest-regen-on-v11-surface`) and were thinned to one-line-imperative + `[rationale: slug]` pointers; the other 23 are standalone SSOT memory (project state / references / feedback not in the trinity corpus) and were left intact; 14 of the 18 rationale slugs have no cache file. Maintained by Pack Chat as memory upkeep — NO pack-side generator, NO commit touching `~/.claude/`. (Matches ARCHITECTURE §9.7 "Realized scope.")
- **Why here:** sequenced AFTER the corpus (C1) + rationale (C2) are stable so the thin pointers reference live slugs. This is a Pack-Chat-direct memory-upkeep action (Pack Chat CAN edit its own memory files), NOT a coder commit, NOT in the commit count. Listed for completeness/ordering only.
- **Working state:** N/A (out-of-repo). Drift control = thin-pointers + trinity-wins disclaimer (already in MEMORY.md) + Pack-Chat upkeep. NO validator gate possible (§9.7).
- **Trinity:** N/A.

### C12 — End-of-batch REVIEW (whole C1–C11 series) + whole-repo COMPLETENESS AUDIT + mechanical re-prove
C12 is REVIEW + AUDIT, not just mechanical verification. It has THREE parts. These are C12 steps for THIS work; they introduce NO new standing rule — part 1 is the EXISTING "review/fix per BD AND per batch" rule scoped correctly, part 2 composes the architect's existing discovery/blast-radius sweep methodology, part 3 is the mechanical re-prove already present.

**Part 1 — End-of-batch REVIEW (judgment; existing rule made explicit).** The standing "review/fix per BD AND per batch" rule requires a reviewer pass over the FULL series after all per-commit cycles complete. C12's reviewer pass (the §4 cadence, run here) is scoped to the WHOLE C1–C11 series for cross-commit correctness — NOT C12's near-empty diff. The reviewer looks for: cross-commit regressions (a later commit silently undid an earlier commit's edit); semantic errors that span commits (e.g., a `[rationale: slug]` tagged in C1 whose rationale body landed in C2 under a mismatched slug); missed findings that no single per-commit review could see because they only manifest across the series (e.g., a rule collapsed in C5 whose canonical corpus line was edited in C1 such that the C5 reference no longer matches). This is the end-of-batch reviewer rule, made explicit — no new rule.

**Part 2 — Whole-repo COMPLETENESS AUDIT (no surface missed; architect-style sweep).** BROADER than the 7b dangling-reference reconciliation (which REPAIRS orphaned refs): this AUDIT confirms COMPLETENESS — that nothing which SHOULD have changed was missed, the way the architect's EE-1/EE-6/EE-7/EE-8 discovery + blast-radius sweeps confirmed coverage. The audit confirms, with grep/measurement evidence: (a) every durable doc in the M4 class (the 7 `pack-ops/` non-mirror docs) is actually 0-outside-allowlist; (b) every spawn-relevant `## Pack memory` rule is actually `[roles:]`-tagged AND single-sourced (`[rationale: slug]` present + bijection-equal + no surviving restatement in PACK-AGENTS/PACK-CHAT/skills); (c) every reference resolves (the two manifests + Check 34/40 surfaces); (d) every ENCODING surface updated in lock-step with the surface it asserts — for each of Check 44/45/46 + the extended Check 37: its validator function, its per-check test, its CI-workflow wiring line, and the manifest/allowlist file it reads are all present and consistent (the enumerate-ENCODING-surfaces methodology applied as a final completeness pass); (e) no stale content or refs anywhere repo-wide (the WITHDRAWN index, the deleted BOUNDARY §6, the dropped "(new top-level pack-only dir)" wording, the collapsed restatements — none resurface). A missed surface here routes back to the owning commit's coder via a fix-coder pass (§4 cadence), not a silent patch.
- **Files:** none authored by C12 itself — it produces an AUDIT record (in the C12 IMPL-REPORT/review report, archived on ship), plus any fix-coder edits the audit surfaces (charged to the owning commit's surface).

**Part 3 — Mechanical re-prove (retained).** The §8 step-7 "re-run pattern scan against reshaped tree; prove 0-outside-allowlist" (discharged in C10's PREFLIGHT) is re-confirmed whole-tree; the FINAL 7b whole-repo dangling-reference reconciliation sweep runs across ALL moved/deleted/reshaped surfaces (confirms C2/C4/C5/C8/C9 per-commit sweeps left nothing dangling repo-wide); manifest verify clean.
- **Files:** none (verification) OR `test-fixtures/manifest.txt` only if a prior commit's stage-if-diff was somehow deferred (it must not have been — each commit stages its own). Workflow artifacts (this PLAN, the architect doc, IMPL-REPORTs, reviews) sweep to `maintenance-docs/archive/v11/` at version ship (Pattern B) — NOT this work's commit (existing standing process).

- **Working state:** full `validate-pack.py` + all per-check tests green; manifest verify clean. C12's own diff is near-empty unless the audit/sweep surfaces residue (then fix-coder edits land, charged to the relevant surface).
- **7b sweep:** subsumed into Part 3 (the final cross-commit reconciliation).
- **Trinity:** no (unless an audit-surfaced fix touches a trinity surface, then lock-step in the owning fix-coder commit).

### §8-step → commit map (coverage proof, SC1)

| §8 step | Description | Commit(s) |
|---|---|---|
| 1 | Corpus C1 imperatives + `[roles:]` + `[rationale: slug]` (trinity) | C1 |
| 2 | Author RATIONALE.md; split Why/examples | C2; C11a (mid-execution fix — restore fenced format templates + manifest base-case, completing the rationale SSOT before C11) |
| 3 | Reshape BOUNDARY to §7 target + §2.2/§2.3/§3-WHEN/HOW/§5 content | C4 |
| 4 | Add M4 + C3-bijection + B5 checks (no §4.2 check) | C3 (bijection), C6 (B5), C10 (M4) |
| 4b | `.spawn-rule-manifest.txt` + collapse 6 restatements + spawn-rule check | C5 (author/collapse), C6 (check) |
| 4c | Extend Check 37 walk to companion templates + update test | C7 |
| 4e | §11.3 routing pointers; index DROPPED; fold into B5 manifest | C8 (pointers authored + folded into manifest) — C6 authored ONLY the B5 entry-point manifest |
| 4f | §12 propagation table; CLAUDE.md stale-entry pointer | C8 |
| 4d | Thin memory-cache (out-of-repo, no commit) | C11 (Pack-Chat upkeep) |
| 5 | Wire each new check's per-check test + CI (Check 42/43) | C3, C6, C7, C10 (each wires its own) |
| 6 | Reshape other 6 durable docs; collapse M3 finding-record | C9 |
| 7 | Re-run pattern scan; prove 0-outside-allowlist; manifest regen | C10 PREFLIGHT + C12 Part 3 (mechanical re-prove) + C12 Part 2 (completeness audit confirms no M4 doc missed) |
| 7b | Stale-reference blast-radius sweep | completion criterion of C2,C4,C5,C8,C9 + final cross-commit reconciliation in C12 Part 3 (SC6) |
| 8 | (Optional/deferred) `_build_fence_skip_lineset` 2nd-marker refactor | NOT in scope (design defers) |

All 14 §8 steps covered. Step 8 is design-deferred (explicit "not in this work").

---

## 4. Per-commit bounded review/fix cadence (SC3) — applies to EVERY coder commit C1–C10, and to C12 (whose reviewer pass is the end-of-batch review scoped to the WHOLE C1–C11 series, not C12's near-empty diff — see C12 Part 1)

For each commit, Pack Chat runs the bounded cycle (max 3 reviewer / 2 fix-coder spawns):

1. **Coder** (fresh per commit; `run_in_background:true`; in-place by default, with opt-in worktree isolation per BD-197; rules-in-force enumerated inline; progress marker `**Coder C<N> of 12**`; STOP-MEANS-STOP preamble) → working-tree edits + IMPL-REPORT + Rules-Applied Verification Block + PREFLIGHT line.
2. **Reviewer pass 1** (`pack-reviewer` fresh; rules-in-force; PLAN+design only, NO prior reviews). Clean → step 7. Findings → 3.
3. Pack Chat triages every finding to user (default FIX-ALL; SKIP needs rationale+approval) → **Fix-coder pass 1**.
4. **Reviewer pass 2** (fresh). Clean → 7. Findings → 5.
5. Triage → **Fix-coder pass 2 (FINAL)**.
6. **Reviewer pass 3** (fresh, FINAL). Clean → 7. Issues remain → **STOP; architect escalation** (no fix-coder pass 3).
7. Pack Chat brings commit-approval to user with the latest clean reviewer report + the next-steps plan.

Pack Chat does NO coder review and NO fixes; agents never commit; no commit without explicit user approval; each approval ask carries the next-steps plan.

**End-of-batch review (existing rule, no new rule).** Per the standing "review/fix per BD AND per batch" rule, C12's reviewer pass is the end-of-batch reviewer over the FULL C1–C11 series — it reviews cross-commit correctness (regressions, cross-commit semantic errors, findings invisible to any single per-commit review), NOT C12's own diff. C12 Part 1 states the scope; C12 Part 2 adds the whole-repo completeness audit.

---

## 5. Per-commit trigger matrix (SC4 manifest-regen + SC5 trinity + per-check-test)

| Commit | Touches `validate-pack.py`? | Per-check tests to run | Manifest-regen trigger? | TRINITY lock-step? |
|---|---|---|---|---|
| C1 | no | trinity-parity (18/19/16) via full validate-pack | NO (pack-root trinity = C3, not v11-surface) | **YES** |
| C2 | no | full validate-pack (bijection not yet live) | YES (`pack-ops/`) | YES (corpus strip) |
| C3 | **yes** (Check 45) | 45 + 32/34 (shared pattern); when in doubt all | YES (`scripts/`+`pack-ops/`) | no |
| C4 | no | 40 (pack-ops bare-ref) via full validate-pack | YES (`pack-ops/`) | conditional (only if 7b edits a trinity pointer) |
| C5 | no | 40 via full validate-pack | YES (`pack-ops/`) | no |
| C6 | **yes** (Check 46) | 46 + 32/34; SC7 predicate measurement first | YES (`scripts/`+`pack-ops/`) | no |
| C7 | **yes** (Check 37 walk + `_iter_*` helper) | 36-37-38 + 41 + 43 (helper-sharing) | YES (`scripts/`) | no |
| C8 | no | 46 (routing pointers resolve) via full validate-pack | YES (`pack-ops/`; not `.claude/skills/`) | **YES** (stale-entry pointer) |
| C9 | no | 40 via full validate-pack | YES (`pack-ops/`) | conditional (7b trinity-pointer repair) |
| C10 | **yes** (Check 44) | 44 + neighbors; M4 0-outside-allowlist grep-proof in PREFLIGHT | YES (`scripts/`+`pack-ops/`) | no |
| C11 | N/A out-of-repo | — | NO | N/A |
| C12 | no (verify) | full suite + manifest verify | only if residue | no |

Manifest discipline per commit: `bash test-fixtures/build.sh --all --clean` → `git diff test-fixtures/manifest.txt` → stage IF non-empty. pack-ops docs touched here (RATIONALE, BOUNDARY, PACK-AGENTS, PACK-CHAT, the 6 durable docs, the manifest .txt files) are largely NOT installed by init-project.sh, so the manifest diff is expected-empty — but the rebuild+check is mandated by the inclusive trigger.

---

## 6. Working-state proof summary (SC2)

The single dominant constraint: **a new check is wired only against a clean tree.**

- **M4 (Check 44, C10):** EE-P1 proves 5/7 durable docs FAIL the forbidden-pattern probe at HEAD (BOUNDARY 15, CONCEPTUAL-REVIEW 11, MERGE-STRATEGY 6, OPTIONAL-FEATURES 4, DRY-RUN 2). BOUNDARY is cleaned in C4; the other 5+1 in C9. M4 wires in C10 — AFTER both. The coder's C10 PREFLIGHT discharges the "0-outside-allowlist proof is a coder obligation" by grepping the live post-C9 tree.
- **C3 bijection (Check 45, C3):** the slug-set is authored in C1 (corpus tags) and made 1:1 with RATIONALE.md in C2. C3 wires against the equal sets → PASS.
- **B5 + spawn-rule (Check 46, C6):** the `.boundary-pointer-manifest.txt` replaces BOUNDARY §6 (deleted C4); the `.spawn-rule-manifest.txt` + collapsed restatements authored C5. C6 wires against the resolvable-and-collapsed tree → PASS. The anti-restate substring predicate is MEASURED before wiring (SC7).
- **Check 37 walk extension (C7):** both companion-template dirs are clean today (EE-2: 0 deny-list hits) → extension is non-breaking, wires against an already-clean tree.
- **Every commit also keeps Check 42 green:** any commit adding a new validator check (C3/C6/C7/C10) wires its per-check test in the SAME commit (C3→test-45, C6→test-46, C7→update 36-37-38, C10→test-44), so Check 42 (CI-wiring guard) never sees an unwired test.

Result: `validate-pack.py` + all per-check tests are GREEN at every commit boundary C1→C12. C12 then runs the end-of-batch REVIEW over the whole C1–C11 series (judgment) + the whole-repo COMPLETENESS AUDIT (no surface missed — every M4 doc cleaned, every rule tagged + single-sourced, every reference resolves, every ENCODING surface in lock-step) + the mechanical re-prove (0-outside-allowlist + final 7b reconciliation + manifest verify). See C12 Parts 1/2/3.

---

## 7. SC7 — anti-restate-predicate risk (FLAGGED)

The §9.6 anti-restate substring scan keys on "canonical imperative text appears verbatim in 2+ surfaces." EE-P1 shows the PACK-AGENTS PREFLIGHT block (L190–228) carries the imperative TEXT today (a PARTIAL restate that already references). After the C5 collapse the verbatim text is gone — but the predicate can STILL false-positive on a legitimate one-line reference that NAMES a rule (e.g., a reference reading "Agents never commit — see `## Pack memory` `[rationale: agents-never-commit]`" contains the substring "Agents never commit"). This is the SAME false-positive shape as the §4.2 12/12 storm.

**Mitigation (baked into C6):** the coder MUST MEASURE the candidate predicate against the real post-C5 surfaces (PACK-AGENTS, PACK-CHAT, the 4 spawn-relevant skills) and confirm acceptable hit behavior BEFORE wiring it live. If legitimate name-bearing references storm the predicate, the coder re-scopes it (require a multi-clause/length threshold so a one-line reference that merely NAMES the rule does not match a multi-line imperative restatement; or anchor on the two-clause `<DIRECTIVE>+<TRIGGER>` shape) and reports the measurement in the PREFLIGHT — it does NOT wire a storming predicate. This is measure-then-bound applied to the anti-restate predicate. Surfaced for user awareness; it does not block C6 but governs HOW C6's check is built.

---

## 8. SC8 — BD / commit-tracking (RESOLVED — BD-196)

**RESOLVED.** The user created **BD-196** (`pack-ops/BACKLOG.md`, 2026-05-30) to track this work. The 11 coder commits + the trinity/PM-only edits carry the standard `feat: v11 — BD-196 …` subject form (CLAUDE.md approved vocabulary); the prior BD-less open question is CLOSED. (Note: CI Check 36 scope-keyword convention (`pack-only`) remains available and most commits here are `pack-only` — C1/C2/C8 touch only pack-root trinity + pack-ops, C3–C10 touch `scripts/`+`pack-ops`; none touch `project-template/` or `supporting-docs/` EXCEPT verify C7's companion-template-dir question, which is `pack-only` since the walk extension edits `scripts/` not the template dirs. The scope-keyword is orthogonal to the BD anchor and composes with the `BD-196` subject.)

---

## 9. Design gaps / contradictions surfaced (SC9)

- **G-A (resolved in §2 + flagged):** the design does not fix the exact NUMBER of new check functions for B5 + spawn-rule. Sequenced as 3 IDs (44/45/46), 46 combining B5 + spawn reference-resolution + anti-restate; coder may split 46→46+47 (implementation call, not design change). Each split still wires its own test + clean-tree rule.
- **G-B (resolved + flagged):** §8 lists steps out of numeric order (1,2,3,4,4b,4c,4d,4e,4f,5,6,7,7b,8) and 4d (thin cache) is out-of-repo. I sequenced by DEPENDENCY (corpus→rationale→bijection→reshape→manifests→checks→other-docs→M4), which reorders the literal §8 numbering; the §8→commit map (§3) proves all steps are covered. The reorder is a sequencing decision, not a design change.
- **G-C (resolved + flagged):** §8 step 7b is written as one step but the SC6 directive + the "completion criterion of EVERY reshape" framing require it distributed across C2/C4/C5/C8/C9 + a final C12 reconciliation. Sequenced as distributed completion criteria (§3), with C12 as the cross-commit backstop — consistent with the architect's "NOT an afterthought / NOT a post-work final audit" framing.
- **G-D (flag, no block):** §2.2 D1 extends Check 37's walk to companion-template dirs. Whether that changes Check 41's `_CLIENT_INSTALLED_FILES` inventory count (and thus Check 41/43 tests) depends on whether the companion dirs are in the install inventory — they are NOT installed by init-project.sh (they are dev-environment configs a developer applies), so Check 41 is expected unaffected, but the coder's C7 PREFLIGHT must empirically confirm (enumerate-ENCODING-surfaces rule). Flagged so the reviewer checks Check 41/43 test deltas in C7.
- **G-E (SURFACED for user/architect — DESIGN question, NOT resolved here).** The v8 §11.3 discovery re-architecture re-homes boundary discoverability to PACK-CHAT "File access strategy" + BOUNDARY self-homed + the `review` skill (C8), but it does NOT re-add a project `docs/pack/PM-CHAT.md` boundary pointer. The old §6 prose called the project PM-CHAT pointer "critical for the V1 regression pattern," yet — measured at HEAD — `project-template/docs/pack/PM-CHAT.md` carries ZERO `BOUNDARY-DEFINITION.md` references (the §6 claim was aspirational; the pointer was never real), and the v8 §11.3 design does not re-home it anywhere. **Whether this drop is correct or a real discoverability gap is a DESIGN question I do not resolve here.** My recommendation (advisory only, for the architect to weigh): the drop is likely CORRECT per P-missed-7 (boundary discipline) — `BOUNDARY-DEFINITION.md` is a PACK-ONLY doc, and a project-side surface (`PM-CHAT.md` ships to clients) should NOT point at a pack-only artifact that does not exist at client install; pointing project PM-CHAT at pack-only BOUNDARY would be the same boundary-leak class P-missed-7 names. **Routed to user/architect for the decision** before C8 authors the §11.3 routing pointers — if the architect rules it a real discoverability gap, the fix is a project-side re-home (a project-side SSOT pointer), NOT re-adding a pack-only-doc pointer to a project surface. Surfaced, not resolved.
- **No true contradictions found.** §0 of the architect doc already cleared the C2-location apparent contradiction (D2); EE-P1 found no competing index/procedure doc to reconcile.

---

## 10. Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| 1 Trinity | C1/C8 flagged TRINITY lock-step (corpus + stale-entry pointer ×3 in same commit); §5 matrix per-commit column; C4/C9 conditional trinity-pointer repair noted | COMPLIANT |
| 2 Agents never commit | Plan bakes coder=report+working-tree-edits, Pack Chat commits, into §4 cadence; this pass ran only read-only `git rev-parse/ls-files`, `grep`, `wc`, `sed`, `cat`, `ls` + one Write (this doc) | COMPLIANT |
| 3 No destructive op | Read-only source; single in-place Write to OUTPUT path; no git state change | COMPLIANT |
| 4 Separate pack ops/product | All commits are pack-ops/pack-root/scripts (C2/C3); §11.3 pointers live in existing pack-ops C2 docs; no project-template/supporting-docs touched (SC8 scope-keyword `pack-only`) | COMPLIANT |
| 5 BOUNDARY SSOT | C4 reshapes BOUNDARY per §7 target; 7b sweeps inbound pointers; not byte-aligned across surfaces | COMPLIANT |
| 6 No solutions invented | Sequenced the LOCKED decisions; G-A/G-B/G-C/G-D are sequencing resolutions + flags, not redesigns; did not author any design artifact | COMPLIANT |
| 7 Empirical-Evidence Blocks | EE-P1 = command-derived counts (validate-pack PASS, 45/41/41 bullets, 0/0/0 tags, M4 probe 15/11/6/4/2/0/0, 10 tests, 6 manifest rows) + HEAD 3bef42b + 2026-05-30 + SUPPORTED | COMPLIANT |
| 8 Measure-then-bound | M4 probe MEASURED before sequencing M4 live (C10 after C4+C9); SC7 anti-restate predicate measure-before-wire baked into C6; C10 allowlist sized to KEEP-only | COMPLIANT |
| 9 Working-state guarantee | §6 proves clean-tree-before-check-wire for all 4 checks; §5 keeps Check 42 green per commit | COMPLIANT |
| 10 Per-commit bounded review/fix + end-of-batch review | §4 sequences the max-3-reviewer/2-fix cadence for every coder commit; C12 Part 1 scopes the end-of-batch reviewer to the whole C1–C11 series; C12 Part 2 adds the whole-repo completeness audit (architect-style sweep, no new rule) | COMPLIANT |
| 11 Concision/dogfood | No section expanded beyond need; commit table is terse; this plan IS the deliverable scoped to the ask | COMPLIANT |
| 12 Never silently resolve | G-A..G-D surfaced + flagged; SC7 + SC8 surfaced; no contradiction silently filled | COMPLIANT |
| 13 Structural scope | Top-matter STRUCTURAL; architect design is the justification | COMPLIANT |
| 14 Chunk Writes >300 | This doc written in 4 incremental chunks via append | COMPLIANT |
| P-missed-7 boundary discipline | D1 companion-template walk keyed to project-side Check 37, not a pack mechanism; pack/project surfaces kept separate | COMPLIANT |
| Manifest-regen on v11-surface | §5 per-commit manifest-trigger column; rebuild+stage-if-diff baked into every pack-ops/scripts commit | COMPLIANT |
| Per-check test runs | §5 per-check-test column (45→C3, 46→C6, 36-37-38+41+43→C7, 44→C10); Check 42 wiring per commit | COMPLIANT |
| Plan-doc edits go to planner | This pass IS the planner; output is the plan doc only | COMPLIANT |
| Enumerate ENCODING surfaces | G-D flags Check 41/43 + tests as ENCODING surfaces of the Check 37 walk; C7 PREFLIGHT confirms | COMPLIANT |

**End of PLAN-DOC-CONCISION-GUARDRAILS.md.**
