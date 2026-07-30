# ARCHITECTURE — BD-136 RECONCILED (Trinity marker-section preservation, Shape A + Shape B)

**Stage:** pack-architect RECONCILIATION pass (deterministic LARGE-BD pipeline). FRESH, independent instance — did NOT author the original design and did NOT run the adversarial pass (`reconciliation-instance-independence`). Feeds → user design review → planner.
**Placement:** reconciled against the COMMITTED state in the MAIN checkout `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`. HEAD at reconcile time = `594fbde` (descendant of the design/adversarial HEAD `5d1daba`; the only intervening commit touched `pack-ops/session-state.json`, NOT any BD-136 surface — EEB-R0). Read-only; grep/Read (graph stale, not used). No edits, no state-changing git verb.
**Inputs consumed:** the original pre-reconciliation BD-136 design draft (superseded by — and committed as — this doc), `ADVERSARIAL-BD136.md` (1 BLOCKER B1 + M1/M2/M3 + 4 SHOULD + 3 NIT + 10 CONFIRMED-SOUND), `CENSUS-BD136.md` (ground truth), `backlog/BD-136.md` (spec L-1..L-10 / P-1..P-8 / V-1..V-8 / M-1..M-12). Every state-claim RE-VERIFIED this session against live source at `594fbde` (EEB-R*).
**Author note:** REFERENCE doc (design) — carries rationale + evidence by design (`operating-docs-no-history` governs operating docs only).

**Disposition of the adversarial pass:** ALL 4 BLOCKER/MUST findings RESOLVED with corrected design (B1, M1, M2, M3). All 4 SHOULD + 3 NIT resolved or consciously accepted with rationale. All 10 CONFIRMED-SOUND decisions re-validated and PRESERVED (with the two that the B1 rework touches — the "BASE-independent" framing and the BD-202 decoupling claim — corrected, per the adversarial's own direction). The user hard-constraints (pack/client separation; MERGE-STRATEGY split; no B1 deferral to BD-202/v11.1) are honored throughout.

---

## 0. Reconciled design spine (what changed vs. the original)

The original design's five load-bearing decisions, and their reconciled status:

1. **~~"A GRAFT, not a 3-way" / "BASE-independent"~~ → CORRECTED to "A BASE-aware graft: 3-way the pack body where BASE exists, degrade-SAFE (never silent) where it does not."** This is the B1 fix and the heart of this reconciliation. The merge is BASE-*preferred*, not BASE-*independent*. The graft's clean `merged-with-customization` output is emitted ONLY when the out-of-marker pack body reconciliation is provably safe; in every ambiguous/conflicting case it routes to the SAME sidecar/`needs-reconciliation` path the legacy engine uses — so a Shape-A-marked file is NEVER worse than today's status quo, and the BD's Shape A spec ("pack body refreshes via 3-way merge") + L-8 ("never silently overwrite or silently keep") are both honored on BOTH paths. (§1)
2. **Sibling library `scripts/lib/marker-preserve.sh` — PRESERVED (CONFIRMED-SOUND CS-8).** The B1 rework is contained INSIDE this file (algorithm change), not a file-set change. The dispatch reroute at `customization-preserve.sh:448` and the `marker_preserve_trinity BASE OURS THEIRS REL DEST` signature are unchanged — BASE was always the first positional. (§4.1)
3. **No-marker fallback — PRESERVED but RE-TRIGGERED on zero marker TOKENS, not zero PAIRS (M2 fix).** Any marker token present now routes into the graft so the L-6 fail-loud gate adjudicates it. (§2, §4)
4. **Trinity edits are project-template-only — PRESERVED (CS-5).** Re-verified: pack-root trinity has zero markers / `[CONDITIONAL]` / `## Project addenda` (EEB-R6). (§4.4, §4.5)
5. **Pack/client separation via TWO distinct docs — PRESERVED (CS-7).** The B1 rework RIPPLES one line: the `pack-ops/MERGE-STRATEGY.md` §1 currency edit must now read "BASE-preferred 3-way of the pack body, degrade-safe sidecar when BASE absent," NOT "BASE-independent graft." (§4.8)

Two additional structural corrections the adversarial forced:
- **`[CONDITIONAL]`-in-OURS detection HOISTED to the top of `marker_preserve_trinity`, ahead of the marker-count branch (M1 fix).** A real markerless v10/v9.3 trinity carrying `[CONDITIONAL]` now fails loud with the specific L-9 message. (§2 step 1, §3)
- **BASE-absence cost re-stated accurately (M3 fix):** it degrades THREE things (L-2 weakening, Shape A H2-rename mis-attribution, out-of-marker body attribution), not "the ONE L-2 signal." (§3)

---
## 1. Resolution of B1 (BLOCKER) — the corrected BASE-aware merge approach

### 1.1 The defect, restated precisely

In Shape A the pack owns the section body OUTSIDE the markers; the project owns only the region INSIDE the markers. The original graft (original §2.1 step 6) emitted THEIRS's skeleton for everything outside the markers and re-inserted only the project's marked regions. Consequence: **any project edit to pack-owned body text OUTSIDE a marker is silently replaced by THEIRS** — no sidecar, no `needs-reconciliation`, a clean `merged-with-customization`. This is (a) a direct violation of L-8 ("never silently overwrite or silently keep"), (b) a replacement of the BD's mandated "pack body refreshes via 3-way merge" with an un-mandated "take THEIRS," and (c) a REGRESSION versus the status quo, which sidecars the same file safely. The adversarial's EEB-B1a/B1b/B1d are re-confirmed at `594fbde` below (EEB-R1a/R1b/R1c).

The root tension (why this is design-level, not coder-detail): **without BASE the merger cannot distinguish "pack edited the out-of-marker body" (adopt THEIRS — benign) from "project edited it" (must not silently overwrite).** Picking "take THEIRS" loses project edits (B1); picking "conflict on any delta" evaporates the auto-preservation value. Only a BASE-aware decision escapes the dilemma where BASE exists, and a safe-degrade rule covers where it does not.

### 1.2 The corrected approach — one invariant, two BASE regimes

**Safety invariant (the whole fix in one sentence):** `marker_preserve_trinity` emits a clean `merged-with-customization` (pack skeleton adopted from THEIRS + project marker regions preserved byte-identical) **ONLY when the out-of-marker pack body reconciliation is provably safe.** In every other case it routes to the EXISTING legacy sidecar/`needs-reconciliation` path (`_cp_strategy_text`'s `real-merge-required` behavior: THEIRS→DEST, full project copy→`.pre-update`/`.v10-customized` sidecar, disposition `customization-detected-needs-reconciliation`). Therefore the WORST case for a Shape-A-marked file is EXACTLY today's behavior (a safe, loud sidecar), never worse — B1's regression is eliminated by construction — and the BEST case (byte-identical marker preservation, zero manual reconciliation) is delivered whenever it is provably safe.

**Mechanism — per Shape-A section, keyed on the H2 anchor:**
1. Parse OURS and THEIRS into {skeleton, marked regions}. For each Shape A anchor, MASK the marked region(s) to an anchor placeholder → the section's *out-of-marker body* (the pack-owned text).
2. Reconcile that out-of-marker body across BASE/OURS/THEIRS:

**Regime A — BASE present (migrator path when `migrator_baseline_to_tmp` succeeds).** Run the existing `three_way_classify` semantics on the masked section body (base-skel / ours-skel / theirs-skel):
   - `base-skel == ours-skel` (project did NOT touch pack body outside markers) → adopt THEIRS body (this is the BD's "pack body refreshes" happy path; covers `unchanged-pack`, `pack-update-applied`). Re-graft the project's marker regions byte-identical. **Clean graft.**
   - `base-skel != ours-skel` (project DID edit pack body outside markers — a P-2 violation) → **sidecar/`needs-reconciliation`**, never silent. Covers `merged-with-customization`-would-keep-OURS (which L-8 forbids doing silently) and `real-merge-required`. Message routes per P-2: "project edited pack-owned text outside a marker under `## <heading>` — move it inside a Shape A marker, convert the section to Shape B override, or open a pack BD."
   - This gives the BD's "3-way merge the pack body" its teeth: BASE is what distinguishes a pack edit (adopt) from a project edit (conflict).

**Regime B — BASE absent (init --update; migrator baseline-not-found fallback).** Cannot attribute a divergence. Apply the degrade-SAFE rule on the masked section body:
   - `ours-skel == theirs-skel` (pack body outside markers is identical) → **clean graft** (project only touched marker regions, or is already on the shipping pack body for this section). This is the common per-update case and preserves the auto-preservation value.
   - `ours-skel != theirs-skel` (any out-of-marker divergence — provenance unknowable) → **sidecar/`needs-reconciliation`**, never silent THEIRS-adoption. Message: "cannot 3-way the pack body (no baseline available) under `## <heading>`; your project copy is preserved in the sidecar — review out-of-marker differences before adopting the new pack canonical."

3. New THEIRS H2 sections with no OURS anchor land additively in canonical position (L-5). Shape B sections (project-owned) are emitted byte-identical and are exempt from out-of-marker body reconciliation (they own the whole section).

**Why per-section (H2-anchored) granularity, not whole-file:** it BOUNDS a conflict to the one diverging section, preserving clean-graft value in every other section of the same file. Section boundaries come free from the structural parse. Recommended granularity; the coder MAY fall back to whole-skeleton reconciliation if section alignment is ambiguous (a documented, safe coarsening — it only widens the conflict, never narrows safety).

### 1.3 Why this resolves B1 on BOTH paths (the prompt's hard requirement)

- **init --update (BASE="", verified EEB-R1a):** Regime B. An out-of-marker Shape A project edit makes `ours-skel != theirs-skel` for that section → sidecar/`needs-reconciliation` → the project's edit is preserved in the sidecar and flagged loud. It is NEVER silently clobbered. (Trade-off: a benign pack body refresh on a customized section that the project did NOT edit out-of-marker also produces `ours-skel != theirs-skel` and sidecars — value degradation, not safety loss. Bounded per-update; surfaced as O-8 for user confirmation.)
- **migrator (BASE present, verified EEB-R1c):** Regime A. A 3-way distinguishes the two cases — a project out-of-marker edit conflicts (safe), a pure pack refresh adopts cleanly (full value). If baseline extraction fails (migrator-manifest.sh:278-284), the migrator ALSO passes BASE="" → Regime B degrade-safe → still never silent. Both migrator sub-cases are covered by the SAME code.

**No B1 deferral.** The SAFETY guarantee (never silent loss) lands FULLY in v11.0 on both paths via Regime B. What awaits BD-202/v11.1 is only the VALUE optimization (auto-adopting benign pack body refreshes on init --update via a real per-version BASE) — which is BD-202's already-chartered, user-confirmed v11.1 scope (EEB-R-S3). Because `marker_preserve_trinity` is BASE-aware from day one (Regime A already exists for the migrator), BD-202 supplying init-update BASE upgrades value with NO marker-logic rework. This is the honest, stronger decoupling (§3 S3).

### 1.4 Empirical-Evidence Blocks for B1

**EEB-R1a — init --update passes BASE="" (both legs).**
Cmd: `awk 'NR>=1153 && NR<=1157' scripts/init-project.sh`.
Output (HEAD `594fbde`, 2026-07-29):
```
1153:         if [[ -n "$cls" ]]; then
1154:             customization_preserve "" "$ours" "$theirs" "$proj_rel" "$dest" "$cls" >/dev/null
1155:         else
1156:             customization_preserve "" "$ours" "$theirs" "$proj_rel" "$dest" >/dev/null
1157:         fi
```
Interpretation: the first positional (BASE) is the empty string on both `init --update` legs → Regime B on this path. Conclusion: **SUPPORTED** — the graft is BASE-blind exactly where the design claims it "works," so the degrade-safe Regime B is load-bearing here.

**EEB-R1b — status-quo trinity → safe sidecar for the BASE-absent case (the regression baseline).**
Cmd: `awk 'NR>=98 && NR<=101' scripts/lib/three-way.sh`; `awk 'NR>=302 && NR<=313' scripts/lib/customization-preserve.sh`; `awk 'NR>=230 && NR<=231' scripts/lib/customization-preserve.sh`.
Output: three-way.sh:99-101 `has_base -eq 0 && has_ours -eq 1 && has_theirs -eq 1` → `project-shadows-new-pack`; `_cp_disposition_for` maps `real-merge-required|project-shadows-new-pack` → `$_CP_DISP_NEEDS_RECONCILIATION` (customization-preserve.sh:230-231); `_cp_strategy_text` writes `${dest}${_CP_SIDECAR_SUFFIX}` sidecar + records the reconciliation disposition (302-313).
Interpretation: today a project-edited trinity on the BASE-absent path is preserved as a `.pre-update` sidecar and flagged loud. The original graft's clean-merge removed both the sidecar AND the flag for the out-of-marker sub-case → a strict regression. The corrected Regime B REUSES this exact safe path for the ambiguous case. Conclusion: **SUPPORTED** — B1 was a regression; the fix restores status-quo safety while adding value only where provably safe.

**EEB-R1c — migrator DOES pass a real BASE (and degrades to "" on not-found).**
Cmd: `awk 'NR>=274 && NR<=296' scripts/lib/migrator-manifest.sh`.
Output: `base=$(mktemp)`; `if migrator_baseline_to_tmp "$pack_rel" "$base"; then : # base populated ... else rm -f "$base"; base="" fi`; then `customization_preserve "$base" "$ours" "$theirs" "$proj_rel" "$dest" "$cls"` (295-296).
Interpretation: the migrator supplies a real v10-tag baseline as BASE for every `transform`-class file (trinity included) → Regime A; on baseline-not-found it explicitly sets `base=""` → Regime B. The corrected design consumes BASE for the body 3-way where present and falls to degrade-safe where absent — both handled by one code path. Conclusion: **SUPPORTED** — BASE is available on the migrator path and (contra the original) is now USED for the out-of-marker body, not merely "to sharpen L-2."

**EEB-R1d — no validator/test backstops the client-side silent path.**
Cmd: `awk 'NR>=871 && NR<=874' scripts/validate-pack.py`.
Output: Check 19 registered as `lambda: check_trinity_no_scaffolding_comments(REPO_ROOT / "project-template", ...)` and `(REPO_ROOT, "pack-root")` — both bind pack-repo roots. (Check 91 will register identically, project-template only.)
Interpretation: validate-pack (Check 19/91) runs on the PACK repo's own templates, never on a client's live trinity during `init --update`. So on the client path the MERGER is the ONLY backstop — which is why the safety invariant (§1.2) must live IN the merger, and why M2's fallback-trigger fix matters (the merger's L-6 gate is the client's only orphan guard). Conclusion: **SUPPORTED**.

---
## 2. Resolution of M1, M2, M3

### 2.1 M1 — `[CONDITIONAL]` fail-loud made reachable on the real markerless migration input

**Defect:** the original algorithm ran the no-marker fallback (Step 2) BEFORE the `[CONDITIONAL]`-survival detector (Step 7). A real v10/v9.3 trinity carries `## [CONDITIONAL] X` H2s but ZERO `BEGIN/END project-owned` markers (markers are a v11-forward feature), so it short-circuits to `_cp_strategy_text` and never reaches the L-9 detector. The design's §2.5 claim ("the merger DETECTS the prefix … and FAILS LOUD") was unreachable for the exact input it described (EEB-R2 confirms the ordering + the migrator's zero `[CONDITIONAL]` handling).

**Fix — hoist the check to the TOP of `marker_preserve_trinity`, ahead of the marker-count branch:**
```
marker_preserve_trinity(BASE, OURS, THEIRS, REL, DEST):
  # Step 1 (NEW FIRST): [CONDITIONAL]-in-OURS scan — runs regardless of marker presence.
  if OURS matches /^#{2,3} .*\[CONDITIONAL\]/  (fence-aware):
      write sidecar (full OURS copy); record needs-reconciliation with the L-9 message:
        "project trinity carries `## [CONDITIONAL] X` — decide: keep (rename + wrap Shape B,
         optionally with renamed-from) or delete; the literal prefix must not remain."
      return   # never reaches the marker branch
  # Step 2: marker-TOKEN scan (see M2) ...
```
Placing it FIRST means a `[CONDITIONAL]`-bearing OURS always gets the SPECIFIC L-9 message whether or not it ALSO carries markers — strictly more correct than the original per-branch placement. The scan is O(lines) (`grep -E '^#{2,3} .*\[CONDITIONAL\]'`), cheap.

**Fix the masking test (M-7 / new M-14):** the original M-7 fixture almost certainly carried ≥1 marker (else the graft never engaged), masking the gap. Split into TWO variants: **M-7** (markered `[CONDITIONAL]` — reaches the graft) AND **new M-14** (MARKERLESS `[CONDITIONAL]`, i.e. a real v10 trinity shape — MUST fail loud via Step 1). M-14 is the regression guard that would have caught M1.

### 2.2 M2 — orphan marker no longer swallowed by the fallback

**Defect:** the fallback triggered on "zero structural marker PAIRS." A lone unmatched `<!-- BEGIN project-owned -->` (no END) has zero complete pairs but one marker TOKEN, so it took the no-marker fallback → byte-unaware 3-way → the L-6 fail-loud gate (which only runs inside the graft) never fired. On the CLIENT path no validator (Check 91 is pack-repo-only, EEB-R1d) ever runs, so the merger's L-6 gate is the sole backstop — and the pairs-count trigger disabled it (EEB-R2 candidate-set confirmation).

**Fix — change the fallback trigger from zero PAIRS to zero TOKENS (fence-aware):**
```
  # Step 2: count marker TOKENS (any `<!-- BEGIN project-owned` OR `<!-- END project-owned`,
  #         ignoring tokens inside fenced code blocks per the pinned fence predicate, §3 S2).
  if token_count == 0:
      return _cp_strategy_text("trinity", BASE, OURS, THEIRS, REL, DEST)   # legacy fallback
  # else ≥1 token → enter the graft; Step 3 (L-6 gate) adjudicates balance/alternation/nesting
  #                 and FAILS LOUD on the lone orphan.
```
ANY marker token present now routes into the graft where the Step-3 L-6 gate runs. Only a genuinely token-free OURS takes the legacy fallback (which preserves Check 25 — CS-3). One-line predicate change, load-bearing for L-6 on the client path. **New M-15** (single orphan `BEGIN`, no other markers → fail loud, NOT swallowed) is the regression guard.

### 2.3 M3 — accurate enumeration of ALL BASE-absence degradations

The original "Note on BASE" (original §2.1 line 77) claimed BASE-absence "degrades that ONE signal [L-2], not to a failure." That sentence is empirically false AND is the load-bearing understatement that let B1 pass. Corrected enumeration — BASE-absence degrades **THREE** things:

1. **L-2 (pack added content above a marker):** weakened from a BASE-anchored signal to an OURS-vs-THEIRS section-region delta. (The original admitted this one.)
2. **Shape A H2-rename tracking:** the graft keys on the H2 anchor. If the PACK renames a Shape A H2 between versions (e.g. `## Build and repo hygiene` → `## Build & repo hygiene`), OURS's anchor has no match in THEIRS. Without BASE the merger cannot know "pack renamed X→Y" and re-home the project's marked body under Y; it instead surfaces an L-8 project-drift sidecar-conflict — **mis-diagnosing a pack rename as a project H2 edit.** A 3-way (BASE had X, THEIRS has Y) auto-migrates. Every pack Shape A H2 rename thus forces manual reconciliation for every project customizing there, under a possibly-misleading message.
3. **Out-of-marker body attribution (this is B1):** BASE is exactly what lets the merger tell a project edit from a pack edit outside the markers.

**Corrected framing (propagates to §0 Decision 1, the §2.1 note, the §4 BD-202 interface note, and the MERGE-STRATEGY.md §1 currency line):** the mechanism is **"BASE-preferred, degrade-SAFE when absent"** — never "BASE-independent." The corrected §1.2 already delivers degrade-safe behavior for #3 (out-of-marker body). For #2 (H2-rename mis-attribution) the corrected design surfaces a sidecar-conflict whose MESSAGE names BOTH possibilities when BASE is absent: "H2 `## X` present in your copy but not in the new canonical — either the pack RENAMED it (accept the new name) or your copy DRIFTED (reconcile); no baseline available to disambiguate." With BASE present (Regime A) the rename is auto-detected (base has X, theirs has Y, same body position) and the project's marked body re-homes under Y with no conflict. This makes the cost accurate AND safe on both regimes.

**Why M3 matters beyond wording:** an accurate cost statement is what forces the B1/O-8 conversation at the user design-review gate. The corrected §3-S3 + O-8 carry that conversation explicitly.

### 2.4 M1/M2/M3 Empirical-Evidence Block

**EEB-R2 — M1/M2 mechanism verification (ordering + candidate set + migrator).**
Cmd: `awk 'NR>=447 && NR<=470' scripts/lib/customization-preserve.sh`; `awk 'NR>=871 && NR<=874' scripts/validate-pack.py`; `grep -c CONDITIONAL scripts/migrate-v10-to-v11.sh scripts/lib/migrator-core.sh scripts/lib/migrator-stages.sh`.
Output: dispatch case (448) `trinity|pack-agent|pack-script|pm-chat|generic) _cp_strategy_text …` — trinity currently shares the arm (must be split out — §4.1); Check 19/91 lambdas bind pack-repo roots only (871-874); migrator/framework carry `0` `[CONDITIONAL]` handling.
Interpretation: (M1) with no migrator-side `[CONDITIONAL]` handling and the fallback-before-detector order, a markerless `[CONDITIONAL]` OURS never fails loud → the Step-1 hoist is required. (M2) validate-pack never runs on a client checkout, so the merger's L-6 gate is the sole client-side backstop → the token-count trigger is required. Conclusion: **SUPPORTED** — both fixes are necessary and land in the merger (Commit 1).

---
## 3. SHOULD / NIT dispositions

### S1 — `renamed-from` naming a pack-RETIRED section (over-conflict without BASE)
**Resolved via BASE-aware soft-classify + safe-degrade message.** The original hard-conflicts any `renamed-from` quoted name absent from THEIRS, conflating (i) a project typo/error (real conflict) with (ii) a name that WAS canonical but the pack has since retired (benign no-op — the section the project overrides is already gone). BASE distinguishes them: base HAD the name and theirs does NOT → retirement (soft-warn: "the section you override is no longer shipped — nothing to suppress; confirm intentional", proceed); base NEVER had the name → typo (hard-conflict). BASE absent → cannot distinguish → keep the conservative hard-conflict (safe, non-silent) BUT improve the message to name the retirement possibility ("`## B` not in current canonical — it may have been RETIRED (safe to drop from your `renamed-from`) or MISTYPED; confirm"). This mirrors the §1.2 BASE-preferred/degrade-safe theme and reuses the Regime-A BASE plumbing. It refines L-10/M-9 (M-9's negative variant becomes BASE-conditional) → surface at the user gate (O-9). *Rationale:* the BD's own worked multi-name collapse example (`renamed-from "## Architecture rules — platform-specific", "## Language-specific coding rules"`) is precisely the retirement-prone case, so the benign no-op WILL occur; a safe soft-classify where we can prove it is retirement, conservative-but-clearer elsewhere, keeps safety while recovering value.

### S2 — Fence grammar under-specified across TWO parsers (divergence hazard) → RESOLVED (pin ONE predicate + shared fixture)
The design REQUIRES all P-1..P-8 illustrative markers to live inside fences (original §2.7 coder constraint), so fence grammar is load-bearing, not incidental: a bash-merger vs Python-Check-91 disagreement flips a marker between "inert (in fence)" and "real," failing Check 91 on PM-CHAT.md OR letting the merger mis-parse. **Fix:** pin ONE exact predicate in the single SPEC (the PM-CHAT.md grammar block, §4.7): *"a line whose first non-whitespace run is ≥3 backticks toggles fenced-code state; tilde (`~~~`) fences and >3-backtick fences are OUT of scope — do NOT use them to wrap marker examples."* BOTH parsers implement that literal predicate. Add a SHARED fixture that the merger test AND the Check 91 test both consume, asserting identical fence classification. Document the tilde limitation in P-1..P-8 so authors never wrap examples in `~~~`. *Rationale:* two hand-rolled parsers + a fence-dependent authoring rule is a concrete divergence hazard; a single pinned predicate + a shared cross-check fixture is the minimal robust closure (measure-then-bound applied to grammar).

### S3 — "BD-202 decoupling" overclaim → RESOLVED (re-stated accurately; no B1 deferral)
The original claimed the graft is "BASE-INDEPENDENT … BD-202's BASE only sharpens L-2, NO marker-logic rework." B1/M3 show CORRECTNESS-of-value (not just L-2) depends on BASE. **Corrected, accurate statement:** BD-136's **SAFETY** (never silent loss; L-8 held) is BASE-independent and lands FULLY in v11.0 on both paths via Regime B degrade-safe. BD-136's **VALUE** (auto-adopting benign pack body refreshes on init --update without a sidecar) is BASE-dependent and, on the init --update path, awaits BD-202's per-version BASE (v11.1, user-confirmed — EEB-R-S3). The decoupling that IS real and STRONGER than the original claim: `marker_preserve_trinity` is BASE-AWARE from day one (Regime A already exists for the migrator), so when BD-202 supplies init-update BASE, the SAME algorithm consumes it with NO marker-logic rework — and the heavy parser stays in `marker-preserve.sh`, out of BD-202's `customization-preserve.sh`/`cmd_update` edit surface. **This is NOT a B1 deferral:** what rides to v11.1 is a value optimization within BD-202's chartered scope, not the safety fix. Per `no-deferral-without-user-direction`, no deferral of B1 occurs; the residual value trade-off (higher sidecar rate on init --update until BD-202) is surfaced as O-8 for explicit user confirmation, not assumed.

### S4 — Cross-BD scan: `singletons.py` shared with BD-236 unnamed; project-backlog leg missing → RESOLVED (both verified)
**Verified (EEB-R-S4):** Check 11 `check_pack_agent_trinity` lives at `singletons.py:383` — the SAME file as BD-136's Check 19 edit (`check_trinity_no_scaffolding_comments`, `singletons.py:797`). BD-236 (v11.0 Open, "investigate + design") may promote Check 11 from informational to enforcing → an edit to `singletons.py`. Therefore `singletons.py` is added to the S-D same-file serialize set for BD-136↔BD-236 (alongside `core.py` and the trinity ×3). BD-236's other checks are NOT shared: Check 57 (`check_project_destructive_git_verb_parity`) is in `discipline_parity.py:1486`; Check 27 (`COMMON_CANONICAL_PHRASES`) is in `agents_skills.py` — neither touched by BD-136. **Project-backlog leg (the missing scan half):** `grep -rln "customization-preserve|BEGIN project-owned|marker-preserve|Shape A|Shape B" project-template/docs/project/` → EMPTY (EEB-R-S4). BD-136 edits no `project-template/docs/project/` entry ⇒ the project-backlog intersection is EMPTY. Both legs now recorded (§5.2).

### N1 — Stale `core.py` ledger comment compounds under the count bump → RESOLVED
**Verified (EEB-R-N1):** `core.py:191` reads "(Next free numeric ID = 90; …)" — stale, since Check 90 already landed the next free ID is 91. In the Commit-4 ledger edit that bumps `CHECK_REGISTRY_EXPECTED_COUNT` 87→88, ALSO correct "= 90" → "= 91" and append "BD-136 adds Check 91 (project-template-only registration): 87 → 88." Low stakes; prevents leaving two stale statements.

### N2 — `OPTIONAL:` allowlist prefix over-admits → RESOLVED (tighten to the sanctioned lead)
The original adds bare `"OPTIONAL:"` to the Check-19 allowlist; `startswith("OPTIONAL:")` admits ANY `<!-- OPTIONAL: … -->`, including future fresh-install scaffolding like `<!-- OPTIONAL: fill in your platform defaults -->` — exactly the class Check 19 exists to catch. **Fix (measure-then-bound "size the allowlist to the legitimate set"):** tighten the prefix to `"OPTIONAL: keep this section"` (the exact BD-mandated hint lead — `<!-- OPTIONAL: keep this section if your project targets <X>; delete … -->`). The two other new prefixes (`BEGIN project-owned` / `END project-owned`) are already tightly bounded and — verified — cover the annotated `BEGIN project-owned: renamed-from "…"` form via `startswith`. *Rationale:* the pack authors its own hints, so the tighter bound costs nothing and closes the only over-admission the adversarial found.

### N3 — Test plan misses the silent/fail-loud defects → RESOLVED (M-13..M-16, §5.3)
Adds the four regression guards for B1/M1/M2 that would have caught them: M-13 (out-of-marker Shape A project edit, BASE-absent → must NOT silently overwrite), M-16 (out-of-marker body 3-way, BASE-present, both sub-variants), M-14 (markerless `[CONDITIONAL]` → fail loud), M-15 (lone orphan → fail loud). Detailed in §5.3.

---
## 4. Re-validated still-standing design (the parts that SURVIVE the B1 rework)

These decisions from the original design were re-checked against live source at `594fbde` and the adversarial's CONFIRMED-SOUND set; they SURVIVE unchanged except where the B1 rework explicitly ripples (called out). The original doc's derivations are authoritative for the detail; this section states WHAT survives and WHY, not a re-derivation.

### 4.1 Sibling `marker-preserve.sh` + dispatch reroute (original §2.1) — SURVIVES; algorithm changes inside it
The sibling-file decision (CS-8) and the dispatch reroute at `customization-preserve.sh:448` survive. The reroute SPLITS `trinity` out of the shared `trinity|pack-agent|pack-script|pm-chat|generic)` arm into its own arm calling `marker_preserve_trinity "$base" "$ours" "$theirs" "$rel" "$dest"` (signature unchanged — BASE was always the first positional). The B1/M1/M2 fixes are all INTERNAL to `marker-preserve.sh` (Step-1 hoist, token-count trigger, Regime-A/B body reconciliation) — no change to the file set or the call site. **CS-3 caveat re-affirmed (coder-verify at Commit 1):** (a) the split must isolate trinity so the shared arm still routes the other four classes to `_cp_strategy_text`; (b) the no-marker fallback must call `_cp_strategy_text "trinity" …` (class stays "trinity") and RETURN 0 cleanly (Check 25's driver runs `set -euo pipefail`). Re-verified the reroute target arm (EEB-R2).

### 4.2 Check 19 bounded 3-prefix extension (original §2.3) — SURVIVES with the N2 tightening
Re-verified (EEB-R-19): `ALLOWED_OPENINGS` = 5 entries (`singletons.py:847-858`), match `any(first_line.startswith(prefix) …)` (872), double-registered project-template + pack-root (871/873). The bounded extension adds exactly THREE prefixes scoped to `label == "project-template"` via a `_CHECK_19_MARKER_SURFACES = {"project-template"}` constant (mirroring `_CHECK_16_EXEMPT_SURFACES`): `"OPTIONAL: keep this section"` (N2-tightened), `"BEGIN project-owned"`, `"END project-owned"`. Pack-root keeps the strict 5-entry allowlist (pack-root trinity has zero markers — EEB-R6). CS-2 confirms no under-admission (the annotated `renamed-from` form is covered via `startswith`). SURVIVES.

### 4.3 Check 91 new validator (original §2.4) — SURVIVES; count 87→88 re-confirmed
Re-verified (EEB-R-CNT): `CHECK_REGISTRY_EXPECTED_COUNT = 87` (`core.py:194`); highest check number = 90; next free number = 91. Check 91 registered ONCE (project-template only; pack-root exempt — V-4 would false-fail there). NEW module `scripts/lib/validate_checks/trinity_markers.py`; candidate set from `git ls-files` (V-1..V-8), O(lines) over ~4 files (CS-9, `ci-check-runtime-compounding`). SURVIVES. **Important scope boundary the B1 rework reinforces:** Check 91 validates well-formedness on the pack's OWN templates + seed files; it does NOT and cannot run on a client's live trinity at update time (EEB-R1d) — so it is NOT a backstop for B1/M2 on the client path. The merger's safety invariant (§1.2) + L-6 gate (§2.2) are the client-side backstops. This division of labor is now explicit (was implicit in the original). N1 ledger correction folds into the Commit-4 count edit.

### 4.4 `[CONDITIONAL]` retirement + `renamed-from` split (original §2.5) — SURVIVES; migrator behavior corrected by M1
Trinity-symmetric retirement of the 5 `## [CONDITIONAL] X` H2s ×3 + the 2 preamble prose refs (CLAUDE:11, AGENTS:10; GEMINI has none) — SURVIVES (EEB-R5 re-confirms the 5×3 + 2 count). The `renamed-from` syntactic (Check 91 V-8) vs semantic (merger L-10) split SURVIVES, refined by S1 (BASE-aware retirement soft-classify). The one CORRECTION: the migrator L-9 behavior described in original §2.5 ("the merger DETECTS the prefix and FAILS LOUD") now fires via the Step-1 hoist (§2.1), reachable on the real markerless input.

### 4.5 Trinity seed edits (original §2.6) — SURVIVES
Empty `BEGIN/END project-owned` seed pair under the pack-owned `## Project addenda` H2 (Shape A anchor; empty body valid; satisfies V-4). Discoverability pointer FOLDED into the existing `<!-- Project addenda go here … -->` comment (no new Check-19 entry; Check 16 substring preserved). Passes extended Check 19, Check 18 (comments aren't `## ` lines), Check 16, Check 91 V-4. SURVIVES (CS-5 pack-root exemption re-verified EEB-R6).

### 4.6 PM-CHAT.md re-prep to clean Shape A (original §2.2, §2.7) — SURVIVES (forced by Check 91, byte-safe)
Re-verified the precedent pair (EEB-R8): `BEGIN@1221`, blank, `## Additional project documents@1223`, guidance comment 1225-1233, placeholder@1235, `END@1237`, pack-owned trailing prose 1239-1245. This is Shape-B geometry (H2 inside markers) + a partial-wrap defect (pack prose past END) → V-2 would FAIL Check 91 unless re-prepped. Re-prep to clean Shape A (BEGIN below the H2 + guidance; END above the pack trailer). CS-6 confirms it's IN scope (a required consequence of the BD-mandated V-1 validator scope), byte-safe (no consumer asserts its marker bytes), and defuses the "Shape A proven" circularity. SURVIVES.

### 4.7 Client authoring P-1..P-8 in PM-CHAT.md (original §2.7) — SURVIVES; add the S2 fence-grammar pin
NEW H2 `## How to add project-owned content to trinity files` carrying P-1..P-8 in the CLIENT SSOT `project-template/docs/pack/PM-CHAT.md` (P-missed-7 honored). SURVIVES, with TWO additions from this reconciliation: (a) the single SPEC grammar block now PINS the fence predicate (S2) that both parsers implement; (b) P-2's "do-not-edit-pack-text-outside-markers" gains teeth from the corrected merger — a P-2 violation now produces a loud sidecar (Regime A conflict / Regime B divergence), so P-2 should state that violating it triggers a reconciliation sidecar on next update (not silent loss, not silent survival). Ownership-table (O-2) and startup-pointer (O-2) recommendations unchanged.

### 4.8 MERGE-STRATEGY two-doc split (original §2.8) — SURVIVES; currency line re-worded by B1
CS-7 confirms the split honors the hard separation constraint (client Shape A/B spec → PM-CHAT.md; pack-engine currency line → `pack-ops/MERGE-STRATEGY.md`, distinct names/audiences, no dual-use). SURVIVES. The ONE ripple: the §1 `trinity`-class currency line must now read **"trinity merges marker-aware: project marker regions preserved byte-identical; pack body outside markers refreshed via BASE-preferred 3-way (degrade-SAFE — routes to sidecar/needs-reconciliation, never silent, when BASE is absent or the out-of-marker body diverges unattributably); sidecar/fail-loud on orphan/duplicate/drift/`renamed-from`-miss/`[CONDITIONAL]`-carryover; see `scripts/lib/marker-preserve.sh`"** — NOT "BASE-independent graft." O-1's user-sign-off gate on the superseded BD bullet 54 STANDS (CS-7).

### 4.9 INSTALL/SETUP docs + init hint (original §2.9) — SURVIVES unchanged
Client product docs (`supporting-docs/INSTALL-PROCEDURES.md` cross-ref + `[CONDITIONAL]` block update at L467-505; `SETUP-NEW.md` / `SETUP-EXISTING.md` new "Customizing the trinity files" section; distinct titles → no collision) + the `init-project.sh` `say` hint at both close points (fresh @1605-1606, --update @1371-1378). "No migrator edit" (trinity flows through the declarative `transform` manifest → reroute) SURVIVES — but NOTE it is precisely the "no migrator edit" choice that CREATED M1 (the migrator never gained `[CONDITIONAL]` handling), which is why the M1 fix lives in `marker-preserve.sh` (Step-1 hoist), not the migrator. Consistent (CS-10).

### 4.10 Fixtures + test-fixtures README 3-subclass (original §2.10, §2.11) — SURVIVES
`v11-trinity-marker-prepped/` consumed by M-8; README naming-convention extended to THREE subclasses (tagged-release / current-pack-HEAD / frozen-real-world-snapshot). SURVIVES (EEB-R9 fixture existence re-confirmed via census carry — not re-measured this pass; census Target 5 authoritative).

---
### 4.11 Additional Empirical-Evidence Blocks (for §3–§4 state-claims)

**EEB-R0 — placement / HEAD currency.** Cmd: `git rev-parse --short HEAD`; `git merge-base --is-ancestor 5d1daba HEAD`; `git diff --name-only 5d1daba..HEAD`. Output: HEAD `594fbde`; `5d1daba` IS an ancestor; only file changed = `pack-ops/session-state.json`. Interpretation: no BD-136 surface changed since the design/adversarial HEAD → reconciling against `594fbde` is equivalent to reconciling against `5d1daba`. Conclusion: **SUPPORTED**.

**EEB-R5 — `[CONDITIONAL]` occurrences (retirement scope).** Cmd (census-carry + spot): 5 `## [CONDITIONAL]` H2s per file verbatim ×3 (CLAUDE:59/81/85/89/346 etc.) + preamble prose CLAUDE:11, AGENTS:10; GEMINI none. Interpretation: retirement = 5 H2 prefixes ×3 + 2 preamble cleanups. Conclusion: **SUPPORTED** (consistent with census Target 2 + original EEB-5).

**EEB-R6 — pack-root trinity exempt.** Cmd: `grep -c "BEGIN project-owned\|CONDITIONAL\|## Project addenda" CLAUDE.md AGENTS.md GEMINI.md` (pack-root). Output: 0 for all three. Interpretation: seeds/retirement/Check 91 apply to `project-template` only; pack-root exempt (matches Check 16). Conclusion: **SUPPORTED** (CS-5 re-affirmed).

**EEB-R8 — PM-CHAT.md precedent is Shape-B partial-wrap.** Cmd: `awk 'NR>=1221 && NR<=1245' project-template/docs/pack/PM-CHAT.md`. Output: `BEGIN@1221 / ## Additional project documents@1223 / guidance 1225-1233 / placeholder@1235 / END@1237 / pack prose 1239-1245`. Interpretation: H2 inside markers (Shape-B geometry) + pack prose past END (partial wrap) → V-2 defect; re-prep to clean Shape A required. Conclusion: **SUPPORTED** (CS-6 re-affirmed).

**EEB-R-19 — Check 19 allowlist + match.** Cmd: `awk 'NR>=847 && NR<=872' scripts/lib/validate_checks/singletons.py`; `awk 'NR>=871 && NR<=874' scripts/validate-pack.py`. Output: `ALLOWED_OPENINGS` = 5 entries; match `any(first_line.startswith(prefix) …)`; double-registered project-template (871) + pack-root (873). Interpretation: the bounded 3-prefix project-template-scoped extension (N2-tightened `OPTIONAL: keep this section`) holds; pack-root stays strict. Conclusion: **SUPPORTED**.

**EEB-R-CNT / R-N1 — registry count + stale ledger.** Cmd: `awk 'NR>=185 && NR<=194' scripts/lib/validate_checks/core.py`. Output: ledger comment "(Next free numeric ID = 90; …)" (191); `CHECK_REGISTRY_EXPECTED_COUNT = 87` (194). Interpretation: count 87→88 for one Check-91 registration (CS-1); the "= 90" is stale (Check 90 landed → next free = 91) → correct to "= 91" in the same edit (N1). Conclusion: **SUPPORTED**.

**EEB-R-S3 — BD-202 targets v11.1.** Cmd: `grep -in "Target\|Disposition\|Position" backlog/BD-202.md`. Output: `Target: v11.1 (NOT v11.0)`; `Disposition: TARGET v11.1 … v11.0 fresh install + v10→v11 migration do not depend on it`; `Position: v11.1; co-design with BD-200`. Interpretation: init --update runs BASE-absent in v11.0; BD-202's per-version BASE arrives v11.1 → the VALUE optimization (not the safety fix) awaits v11.1 within BD-202's chartered scope; no B1 deferral. Conclusion: **SUPPORTED**.

**EEB-R-S4 — BD-236 shares `singletons.py`; project-backlog leg empty.** Cmd: `grep -rn "def check_pack_agent_trinity\|def check_project_destructive_git_verb_parity" scripts/lib/validate_checks/*.py`; `grep -rln "COMMON_CANONICAL_PHRASES" scripts/lib/validate_checks/*.py`; `awk 'NR>=4 && NR<=5' backlog/BD-236.md`; `grep -rln "customization-preserve\|BEGIN project-owned\|marker-preserve\|Shape A\|Shape B" project-template/docs/project/`. Output: `check_pack_agent_trinity` (Check 11) at `singletons.py:383`; Check 57 at `discipline_parity.py:1486`; Check 27 (`COMMON_CANONICAL_PHRASES`) in `agents_skills.py`; BD-236 `Status: Open`, `Target: v11.0`; project-backlog grep → EMPTY. Interpretation: only Check 11 (`singletons.py`) + the `core.py` count are BD-136↔BD-236 same-file surfaces → add `singletons.py` to S-D; project-backlog intersection empty. Conclusion: **SUPPORTED**.

---

## 5. Updated wave / parallelization map + test plan

### 5.1 Wave map (rule 10) — structurally UNCHANGED; the B1 rework is contained in Commit 1

The B1/M1/M2 fixes are all internal to `marker-preserve.sh` (Commit 1), so the file set, wave order, and disjointness of the original §5 SURVIVE. Sequencing constraints S-A..S-D hold. Re-verified intra-BD file-disjointness at `594fbde`: no two commits share a file.

- **Wave 1 (parallel — file-disjoint):**
  - **Commit 1 — Merger (pack-only).** NEW `scripts/lib/marker-preserve.sh` (with the corrected §1.2 BASE-aware body reconciliation + §2.1 Step-1 `[CONDITIONAL]` hoist + §2.2 token-count fallback trigger + S2 pinned fence predicate) + reroute `customization-preserve.sh:448` (split trinity out) + no-marker fallback. Verify Check 25 + migrator-manifest green (CS-3 caveat). Portable `mktemp` from the start (BD-276).
  - **Commit 2 — Check 19 allowlist extension (pack-only).** `singletons.py` (+ `_CHECK_19_MARKER_SURFACES`, the N2-tightened `OPTIONAL: keep this section` prefix). Passes now (wider allowlist, markers not seeded yet). Satisfies S-A. **Cross-BD:** same-file with BD-236 Check 11 → serialize (S4).
- **Wave 2 (serial):**
  - **Commit 3 — Trinity seed + `[CONDITIONAL]` retirement (project-only).** trinity ×3 (single trinity-symmetric edit). Requires Commit 2 (S-A). Check 16/18/19 green.
  - **Commit 4 — Check 91 (pack-only).** NEW `trinity_markers.py` + wire in `validate-pack.py` + bump `core.py` 87→88 AND correct the stale "= 90"→"= 91" ledger line (N1). Requires Commit 3 (S-B). Serializes with any BD-236 `core.py`/`validate-pack.py` edit (S-D).
- **Wave 3 (parallel — doc/test surfaces, file-disjoint):**
  - **Commit 5 — Client authoring (project-only).** `PM-CHAT.md` NEW § + P-1..P-8 (with the S2 pinned fence grammar block + P-2 sidecar-on-violation note) + re-prep the precedent pair to clean Shape A + ownership lead + startup pointer. Fenced examples per §4.7. After Commit 4 (Check 91 validates it green).
  - **Commit 6 — Client install/setup docs (project-only).** `INSTALL-PROCEDURES.md` + `SETUP-NEW.md` + `SETUP-EXISTING.md`.
  - **Commit 7 — init hint + pack-engine doc (pack-only).** `init-project.sh` hints (both paths) + `pack-ops/MERGE-STRATEGY.md` §1 currency edit (the §4.8 BASE-preferred/degrade-safe wording).
  - **Commit 8 — Test suite (pack-only).** NEW `scripts/tests/test-customization-preserve-bd136.sh` (M-1..M-16, incl. the S2 shared fence fixture) + wire into runner/CI. Requires Commits 1+4. Portable `mktemp` (BD-276).
  - **Commit 9 — Fixture README (pack-only).** `test-fixtures/README.md` 3-subclass naming.

Rule-10 map for the planner: {1,2} ∥ → {3} → {4} → {5,6,7,8,9} ∥ (5 gated on 4; 8 gated on 1+4). Reviewer runs per-BD inline; single-BD batch → one end-to-end review/fix cycle (or per-commit if the planner prefers finer bounding).

### 5.2 Cross-BD serialize set (S-D) — corrected per S4

Same-file serialize surfaces for BD-136: within BD-136, `core.py` (Commit 4), `singletons.py` (Commit 2), `validate-pack.py` (Commit 4), trinity ×3 (Commit 3). **Cross-BD (BD-136↔BD-236, both v11.0):** `singletons.py` (BD-136 Check 19 @797 ↔ BD-236 Check 11 @383) AND `core.py` `CHECK_REGISTRY_EXPECTED_COUNT` (both bump; same-LINE → serialize mandatory) AND trinity ×3 (both edit project trinity). Whichever BD lands second rebases the +1 count and its trinity edits. **Project-backlog leg: EMPTY** — BD-136 edits no `project-template/docs/project/` entry (EEB-R-S4). BD-202 (v11.1) shares `customization-preserve.sh` but at a different layer (engine BASE plumbing vs. trinity strategy) and lands later — COORDINATE, not same-wave serialize. BD-276 overlaps only BD-136's NEW files (author portable). BD-171/172/223/210 MODERATE/SOFT per original §4 (unchanged).

### 5.3 Test plan — original M-1..M-12 PLUS the four B1/M1/M2 regression guards

M-1..M-12 SURVIVE from original §2.10 (M-8 consumes `v11-trinity-marker-prepped`; M-11/M-12 the init --update fixtures). ADDED:
- **M-13 (B1 guard, BASE-absent).** `init --update`, BASE="", a Shape-A-marked trinity where the project ALSO edited pack-owned body OUTSIDE a marker → assert the result is `customization-detected-needs-reconciliation` + a sidecar containing the project's out-of-marker edit; assert DEST does NOT silently drop it. This is the exact scenario the original design silently lost.
- **M-16 (B1 value+safety guard, BASE-present).** Migrator path with a real BASE, two sub-variants on a Shape-A section: (i) project edited pack body outside the marker, pack did NOT → `needs-reconciliation` sidecar (safety); (ii) pack edited pack body outside the marker, project did NOT → clean `merged-with-customization`, project marker region byte-identical, new pack body adopted (value). Proves the 3-way DISCRIMINATES.
- **M-14 (M1 guard).** Markerless OURS carrying `## [CONDITIONAL] X` (a real v10 trinity shape) → fail loud with the L-9 keep/delete message (exercises the Step-1 hoist). Pair with M-7's markered variant.
- **M-15 (M2 guard).** OURS with a single orphan `<!-- BEGIN project-owned -->` and NO other marker token → fail loud via the L-6 gate, NOT swallowed by the fallback (exercises the token-count trigger).
- **Shared fence fixture (S2).** One fixture consumed by BOTH the merger test AND the Check 91 test, asserting identical fence classification of ≥3-backtick fences (and that `~~~` / >3-backtick are treated per the pinned predicate). Guards the two-parser divergence hazard.
- **BD-276 coordination:** author every new `mktemp` in the portable full-template form.

---
## 6. Open items for the user design-review gate (context + options + recommendation)

The 7 original open items carried forward (updated for the reconciled design), plus 2 the B1 rework forces to the surface (O-8, O-9). Per `open-item-surfacing`, none defers to a new BD; each carries a concrete in-BD-136 recommendation or an explicit "no recommendation."

**O-1 — MERGE-STRATEGY.md re-scope (BD bullet 54 superseded).** *Context:* BD bullet 54 says put the full Shape A/B spec into MERGE-STRATEGY.md; the user separation ruling forbids folding a client-feature spec into `pack-ops/`. *Options:* (a) pack-engine currency line only in MERGE-STRATEGY.md (now the §4.8 BASE-preferred/degrade-safe wording) + full spec in PM-CHAT.md; (b) leave MERGE-STRATEGY.md untouched, rely on code as SSOT; (c) follow the BD literally (violates the ruling). *Recommendation:* **(a)** — satisfies doc-currency without violating separation (CS-7). This SUPERSEDES a BD File/Symbol bullet, which is a BD-scope change → **hard user sign-off required before the planner runs** (not merely "confirm at review"). 

**O-2 — PM-CHAT.md ownership-table + startup-pointer targets don't exist as named.** *Context:* BD says "update the file-ownership/edit-permissions table" + "update the startup checklist"; only a READ-access table (`## File access strategy`, 117-132) + per-tool startup blocks exist. *Options:* (a) invent a new ownership table; (b) fold the ownership statement into the new-H2 lead + a pointer in the access-table "Why" column + one common startup pointer; (c) repurpose the access table. *Recommendation:* **(b)** — fewest new conventions (design-elegance); no new table, no muddying the read-access table. User confirms placement.

**O-3 — V-7 scope: H2-only vs any-`[CONDITIONAL]`-literal in a trinity file.** *Context:* L-9 says "any committed file"; V-7 says "any H2." The preamble prose refs (CLAUDE:11, AGENTS:10) are non-H2 literals §4.4 cleans anyway. *Options:* (a) V-7 = fail on `## /### … [CONDITIONAL] …` H2/H3 only; (b) V-7 = fail on ANY `[CONDITIONAL]` literal within a trinity file (scoped so supporting docs may still document the transition). *Recommendation:* **(b)** — strictly more fail-loud, and since §4.4 cleans the preamble it costs nothing (`fail-loud-delete-old-source`). It also partially compensates for M1 on the COMMITTED pack template (though NOT on a client's live trinity — the merger's Step-1 hoist is the client backstop). User picks strictness.

**O-4 — Shape B strict "END at natural boundary" vs a pack-owned trailer.** *Context:* the PM-CHAT.md precedent has a pack-owned trailer past END; V-2 calls that a partial-wrap defect. *Options:* (a) keep V-2 strict + re-prep the precedent to clean Shape A (§4.6); (b) relax V-2 to tolerate a pack-owned trailer after Shape B END. *Recommendation:* **(a)** — one special case removed, rule stays simple; (b) reintroduces the ownership-ambiguity edge the BD banned. Makes "Shape A proven" true post-fix.

**O-5 — Seed marker layout: empty pair vs pair-with-pointer.** *Context:* the seed `BEGIN/END` under `## Project addenda` can be empty or carry the pointer inside. *Options:* (a) empty pair + pointer folded into the existing `Project addenda go here` comment; (b) pointer inside the marker body. *Recommendation:* **(a)** — keeps the seed genuinely empty (the pack ships no project content) and the pointer pack-owned + discoverable; no new Check-19 entry. User confirms.

**O-6 — Check 91 module: new file vs fold into singletons.py.** *Context:* Check 19 lives in singletons.py; a new marker check is substantial. *Options:* (a) NEW `trinity_markers.py`; (b) append to singletons.py. *Recommendation:* **(a)** — cohesive, unit-testable, filename-unique; mirrors the merger's dedicated-file choice. Low stakes; planner/coder may overrule on convention grounds. *Note:* (a) also REDUCES the BD-136↔BD-236 `singletons.py` co-edit surface (S4) — a modest collision-minimization bonus.

**O-7 — Does PM-CHAT.md route through the marker-aware merge?** *Context:* PM-CHAT.md carries a real marker pair but the BD scopes the marker-aware MERGER to trinity only. *Options:* (a) PM-CHAT.md stays `pm-chat` class (byte-unaware 3-way); Check 91 validates its markers but does not marker-merge it; (b) extend marker-aware merge to `pm-chat`. *Recommendation:* **(a)** — matches the BD's "INTENTIONALLY trinity-only" merger scope; the PM-CHAT.md marker stays a validated well-formedness example. No evidenced need to widen. User confirms the boundary.

**O-8 (NEW — the BASE-absence value/safety trade-off the adversarial flagged as un-surfaced).** *Context:* B1 is RESOLVED for SAFETY in v11.0 (Regime B degrade-safe: never silent loss on either path). The residual is a VALUE trade-off: on the init --update path (BASE="", v11.0), a Shape-A section whose out-of-marker pack body CHANGED between the project's installed version and the new pack — EVEN when the project did not edit it — produces `ours-skel != theirs-skel` → a `needs-reconciliation` sidecar (the project's marker content is preserved, but manual review is prompted). This is bounded (≈ number of pack-changed customized Shape-A sections per update) and disappears in v11.1 when BD-202 supplies init-update BASE (Regime A auto-adopts benign refreshes). *Options:* (a) SHIP the degrade-safe behavior in v11.0 as designed, accepting the bounded sidecar rate on init --update, value-optimized by BD-202 in v11.1 [my recommendation]; (b) attempt a heuristic to reduce false sidecars WITHOUT BASE (e.g., ship a per-section pack-body fingerprint in the trinity so init --update can self-attribute) — adds a new mechanism + a new encoding surface for a v11.1-obsolete gain; (c) pull BD-202's per-version BASE into v11.0 for the init --update path (re-scopes BD-202, a launch-gate impact). *Recommendation:* **(a)** — it delivers full safety now (no B1), preserves value wherever provably safe, and defers ONLY a value optimization to BD-202's already-chartered v11.1 scope (no B1 deferral; `no-deferral-without-user-direction` satisfied because the SAFETY fix is in v11.0). (b) builds a throwaway mechanism; (c) enlarges the launch gate. **This is the single most consequential decision for the user gate — the adversarial correctly noted the original design never surfaced it.**

**O-9 (NEW — S1 `renamed-from`-names-a-retired-section handling).** *Context:* a multi-name `renamed-from` whose named canonicals get partially retired over time hits "no canonical match," which the original hard-conflicts as an error, though a retired override-target is a benign no-op. The BD's own worked collapse example is the retirement-prone case. *Options:* (a) keep strict hard-conflict everywhere (safe, noisy — original + M-9 negative variant); (b) BASE-aware soft-classify: retirement (base had it, theirs doesn't) → soft-warn no-op; typo (base never had it) → hard-conflict; BASE absent → conservative hard-conflict with an improved message naming the retirement possibility [my §3-S1]. *Recommendation:* **(b)** — reuses the Regime-A BASE plumbing, recovers value on the benign case where provable, stays safe elsewhere. It refines L-10 and makes M-9's negative variant BASE-conditional → needs a BD-spec note, so user confirms at the gate. If the user prefers minimal v11.0 surface, (a) is acceptable (safe, only noisier) — no silent behavior either way.

**No open item is deferred to a new BD.** O-1 and O-8 (and O-9 if adopted) carry BD-spec-refinement implications requiring explicit user sign-off before the planner runs.

---
## 7. Rules-Applied Verification Block

- **empirical-evidence-blocks** — Evidence: every state-claim + every "the corrected design does X" is backed by an EEB with command, quoted output, HEAD `594fbde`/2026-07-29, interpretation, conclusion — EEB-R0 (placement), R1a–R1d (B1: BASE="" both init legs; status-quo sidecar; migrator BASE + not-found fallback; no client validator), R2 (M1/M2 ordering + candidate set + migrator), R5/R6 (retirement scope + pack-root exemption), R8 (PM-CHAT precedent), R-19/R-CNT/R-N1 (Check 19 allowlist / registry count / stale ledger), R-S3 (BD-202 v11.1), R-S4 (BD-236 `singletons.py` collision + empty project-backlog leg). BASE presence/absence verified by reading `init-project.sh:1153-1157` and `migrator-manifest.sh:274-296`. Conclusion: **COMPLIANT**.
- **no-deferral-without-user-direction** — Evidence: B1's SAFETY fix (Regime B degrade-safe; never silent loss) lands IN v11.0 on both paths (§1.3); only a bounded VALUE optimization awaits BD-202's already-chartered, user-confirmed v11.1 scope (EEB-R-S3) — that is NOT a B1 deferral. The residual value trade-off is SURFACED as O-8 for explicit user sign-off, not assumed. No finding recommends deferring B1 or any unblocked work to a later BD. Conclusion: **COMPLIANT**.
- **ci-guard-measure-then-bound** — Evidence: Check 19 extension MEASURED the 5-entry allowlist (EEB-R-19), categorized every projected new comment KEEP, bounded to 3 project-template-scoped prefixes, TIGHTENED `OPTIONAL:`→`OPTIONAL: keep this section` to size to the legitimate set (N2), verified pack-root stays strict; Check 91 draws its candidate set from `git ls-files` (no rglob), catches the absence instance (V-4 lost-seed fails — CS-9). Conclusion: **COMPLIANT**.
- **ci-check-runtime-compounding** — Evidence: Check 91 O(lines) over ~4 files, one registration, scoped to project-template; the merger's Step-1 `[CONDITIONAL]` scan is a single O(lines) grep; the token-count trigger is O(lines). No whole-tree walk, no subprocess-per-entry. Conclusion: **COMPLIANT**.
- **dependency-direction-placement / filename-uniqueness-heuristic / P-missed-7** — Evidence: the marker parser stays pack-side (`marker-preserve.sh`, a runtime dep of the pack installer/migrator); the client Shape A/B spec stays in the CLIENT SSOT `project-template/docs/pack/PM-CHAT.md`; the pack-engine currency line stays in `pack-ops/MERGE-STRATEGY.md` (distinct names/audiences, no dual-use); new files repo-unique (CS-8); no `_SANCTIONED_PACK_SIDE_SHIPPED` growth. Conclusion: **COMPLIANT**.
- **cross-bd-collision-scan** — Evidence: re-affirmed BD-202 (v11.1, `customization-preserve.sh` engine layer — COORDINATE not same-wave), BD-236 (v11.0, `singletons.py` Check 11 @383 ↔ Check 19 @797 + `core.py` count + project trinity — serialize; EEB-R-S4), BD-276 (NEW files only — author portable), BD-171/172/223/210 (MODERATE/SOFT, unchanged); PROJECT-backlog leg recorded EMPTY (grep → none). Keyed on structured blast-radius paths. Conclusion: **COMPLIANT**.
- **design-discipline-challenge** — Evidence: the corrected merge approach was held to the pack-boundary HIGH bar and passes property-fit — it is intentional (a BASE-aware 3-way is the ONLY structure that meets the Shape A "3-way merge the pack body" contract + L-8 without evaporating value), evidence-based (the existing `three_way_classify` already provides the discrimination — §1.4), goal-aligned (byte-identical preservation with fail-loud safety), constraint-bounded (contained in the sibling file; no new mechanism; degrade-safe reuses the legacy sidecar). The original "BASE-independent graft" pattern was REJECTED for failing this bar. Conclusion: **COMPLIANT**.
- **operating-docs-no-history-no-bloat** — Evidence: the only operating-doc edits proposed (MERGE-STRATEGY.md §1 currency line, trinity hints, PM-CHAT.md authoring) carry no dated/provenance narration and stay terse; this reconciliation is a REFERENCE doc (rationale permitted). Conclusion: **COMPLIANT**.
- **open-item-surfacing** — Evidence: §6 O-1..O-9 each carry context + own options + an evidence/logic recommendation; O-8 explicitly surfaces the BASE-absence trade-off the adversarial flagged as un-surfaced; none defers to a new BD. Conclusion: **COMPLIANT**.
- **memory-not-an-ssot** — Evidence: every rule + state-claim was sourced from the live in-repo SSOT read THIS session (`CLAUDE.md ## Pack memory`, `backlog/BD-136/BD-202/BD-236.md`, `three-way.sh`, `customization-preserve.sh`, `migrator-manifest.sh`, `init-project.sh`, `singletons.py`, `core.py`, `validate-pack.py`, `PM-CHAT.md`), not a memory cache. Conclusion: **COMPLIANT**.
- **agents-never-commit / per-action-approval-sub-agents** — Evidence: only read-only git (`rev-parse`, `merge-base --is-ancestor`, `diff --name-only`, `status --porcelain`) + grep/awk/find/Read; all Writes confined to the owned handoff dir (the single caller-specified report); no repo edit, no state-changing git verb, no destructive op outside the owned dir. Conclusion: **COMPLIANT**.
- **rules-applied-verification-block** — Evidence: this block. Conclusion: **COMPLIANT**.

*End ARCHITECTURE-BD136.md*
