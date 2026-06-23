# ADVERSARIAL REVIEW — PLAN-BD-243.md

Reviewer: FRESH independent adversarial pack-planner (RO). Did NOT author PLAN-BD-243.md. Charge: challenge the plan before user + coder. Runtime HEAD `a847f120e4ada06456bec4e2bf6d275fdd8c0742`, branch v11-dev, 2026-06-21, repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, clean tree. Inputs read in full: `/tmp/pack-handoff-bd243-plan/PLAN-BD-243.md` (target); `/tmp/pack-handoff-bd243-arch/DESIGN-BD-243-FINAL-V2.md` + carried `DESIGN-BD-243-FINAL.md` §B/§C/§D/§E/§F/§G/§H (authoritative design); `/backlog/BD-243.md` (spec). Did NOT read the prior architect adversarial review (`ADVERSARIAL-REVIEW-BD-243.md`) per charge. Every load-bearing claim re-measured at runtime HEAD.

---

## OPEN QUESTIONS FOR USER

No genuinely NEW unanswerable ambiguity surfaced. G1/G2 are carried OQs the plan correctly surfaces (do not re-litigate; the already-settled rulings are applied — see "ALREADY-SETTLED verification" below). The defects below are state-verifiable plan errors, not user judgment calls.

---

## VERDICT: **NEEDS-REWORK**

Three BLOCKERs, all in the green-at-every-commit invariant. The most severe (BLOCKER-1) is the exact hazard the charge flagged: the gate (Check 65) is added LIVE at C1 BEFORE the strip waves, so C1 — and every commit until the LAST strip lands — would fail Check 65 against the still-unstripped IN docs. The plan's per-commit verification (`validate-pack.py` exit 0, full run) is impossible from C1 onward as written. BLOCKER-2: the plan's wave partition OMITS 16 IN-set surfaces (11 pack skills + 5 pack agents), 6 of which carry history hits the gate flags — so Check 65 can never reach green even after all planned strips. BLOCKER-3: C2 is not green-atomic — `pack-ops/OPTIONAL-FEATURES.md` (in Check 22's prose doc set) carries a `` `pack tracker` `` verb token that C2 strips coverage for but does not strip the token (that strip is C6, a later wave) → Check 22 fails between C2 and C6.

The design (FINAL-V2 + FINAL §E.5/§G) is the root source of BLOCKER-1 (it says "W0 runs FIRST … gate-verified as it lands" AND "Check 65 scans clean … after B.2 strips land" — a contradiction). The plan faithfully copied the contradiction without resolving it. A reconciliation planner must add an explicit activation-ordering mechanism. BLOCKER-2/3 are plan-partition + plan-atomicity defects.

ALREADY-SETTLED verification (all correctly applied): **G1=STRIP** → plan C14 strips `backlog/_intro.md:19` (line 78, "CONDITIONAL on G1=STRIP", default STRIP — correct). **G2=OQV2-2a** → plan C2 marks `pack-tracker.sh` + `tracker-migrate.sh` `# pack-internal: true`, NOT `pack-td.sh`, relocates `pack td` rows (line 53 — correct). **G3=4 docs** → plan uses OPTIONAL-FEATURES/PACK-FEEDBACK/PLATFORM-SKILLS/PM-CHAT (lines 21, 114 — correct; METHODOLOGY/INSTALL/SETUP-EXISTING confirmed non-existent at `project-template/docs/pack/`). **G4=live --only-check 45** → plan C3 asserts `--only-check 45` exit 0 not a hard integer (lines 24, 165 — correct).

---

## FINDINGS BY SEVERITY

### BLOCKER-1 — C1 (and every commit C1..last-strip) FAILS Check 65: the gate is added LIVE before the IN docs are stripped clean.

**Claim challenged.** Plan §2 C1 (line 44-48): adds `check_operating_doc_no_history` (65) in W0/S1, FIRST, "BEFORE any strip." Plan §4 C1 verification (line 150): "`python3 scripts/validate-pack.py` exit 0 (esp. Checks 44, 59, 65, 43, 45)." Plan §2 line 39 + §4 line 147: every commit lands green = full `validate-pack.py` exit 0.

**Why it is impossible.** A full `validate-pack.py` run (no `--only-check`) executes EVERY registered check against the LIVE tree (confirmed: checks `.read_text()` the live files). The moment Check 65 is registered at C1, it scans the ~136 frozen IN docs — which are STILL UNSTRIPPED at C1 (strips are W2/W3/W4 = S4/S5, all AFTER S1). The K1-K11 allowlist is sized EXACTLY to ~12 content-anchored snippets (live doc-refs + format examples + `until BD-206`) — it does NOT cover the bulk of pre-strip history. So Check 65 FAILS at C1.

**Independent measurement (runtime HEAD a847f12):**
```
$ grep -cE "20[0-9]{2}-[0-9]{2}-[0-9]{2}" pack-ops/PACK-MEMORY-RATIONALE.md   → 12   (dates, not allowlisted)
$ grep -cE "\b[0-9a-f]{7,40}\b" pack-ops/PACK-MEMORY-RATIONALE.md            → 11   (SHAs, not allowlisted)
$ grep -cE "\(BD-[0-9]+\)" CLAUDE.md                                          → 6    (bare BD-NNN provenance)
$ grep -cE "BD-[0-9]+" CLAUDE.md                                              → 20   (inline BD provenance)
$ grep -cE "20[0-9]{2}-[0-9]{2}-[0-9]{2}" CLAUDE.md                           → 2    (dates)
$ grep -cE "\bBD-[0-9]+|20[0-9]{2}-[0-9]{2}-[0-9]{2}" CLAUDE.md (total)       → 22
```
Check 65's detect set (design §E.4) flags date `20\d\d-\d\d-\d\d`, sha `\b[0-9a-f]{7,40}\b`, `per BD-\d+`, `BD-\d+ (deleted|added|…)`, bare/inline `BD-\d+`. None of the 22 CLAUDE.md hits nor the 23 RATIONALE date/SHA hits are in K1-K11 (those are live doc-refs like `ARCHITECTURE-BD-119.md`, format examples, and `until BD-206`). At C1 these hits are ALL live → Check 65 FAILS.

**Design root cause (contradiction the plan inherited).**
```
DESIGN-FINAL §G L334: "W0 + W1 are the functional spine (gate then rule) and run FIRST/serial
                       so every later strip wave is gate-verified as it lands."
DESIGN-FINAL §E.5.4:  "after B.2 strips … land, the only surviving forbidden tokens in IN docs
                       are K1-K11 ⇒ Check 65 scans clean. The 0-outside-allowlist proof is the
                       coder's PREFLIGHT obligation … coder runs Check 65 green before IMPL-REPORT."
```
The design wants the gate added FIRST (W0) yet only proves it green AFTER the strips. These cannot both hold for a FULL validate-pack run at C1. The plan copied "W0 first" + "C1 validate-pack exit 0" without resolving how Check 65 stays green over the C1..last-strip interval.

**Propagation (not just C1).** C3 (S3) adds the new rule to CLAUDE.md while CLAUDE.md still carries its 22 history hits (CLAUDE.md is not stripped until C15/W3/S5). A full validate-pack at C3 also fails Check 65. EVERY commit between C1 and the last IN-doc strip would fail Check 65. The plan has ZERO mitigation language — grep of the plan for `disabled|empty.scope|stub|inert|fold.*strip into c1|activate.*65 after strip|no-op until` returns NOTHING.

**Note — the new rule TEXT itself is self-safe (the plan's narrow claim is true, but insufficient).** Literal `BD-NNN`/`YYYY-MM-DD` do NOT match Check 65's digit patterns (verified: `date.search('YYYY-MM-DD')→False`, `bd.search('BD-NNN')→False`). So C3's rule placeholders won't trip Check 65 — but that addresses only the rule's own text, NOT the surrounding unstripped CLAUDE.md, which is the actual failure.

**Required fix (reconciliation planner — pick ONE, surface to user; this is an ordering-mechanism choice the plan must make explicit, per ci-guard-measure-then-bound "Check 65 cannot be added live before its IN docs are clean OR it must ship green at C1"):**
- **Option A (activation-last).** Register Check 65 with an EMPTY/stub `_CHECK_65_OPERATING_DOCS` scope at C1 (gate exists, scans nothing → green), then POPULATE the frozen IN list to the full ~136 in a FINAL "activation" commit that runs AFTER every strip wave (S4-S7). The activation commit's verification is the first point validate-pack must pass Check 65 against the live tree. EXPECTED_COUNT bumps at C1 (Check 65 IS registered); the scope-population is a one-line constant edit, green only post-strip.
- **Option B (incremental scope).** Scope `_CHECK_65_OPERATING_DOCS` to ONLY the files already-stripped-clean as of each commit, growing the frozen list commit-by-commit so the gate is green at every step. (Heavier per-commit churn; touches validate-pack repeatedly — many same-file serial commits.)
- **Option C (strip-then-gate).** Move Check 65 ADD to AFTER all strips; do the strips W2/W3/W4 with the gate ABSENT (relying on reviewer P-DEF/clause-set-diff during strips), then add Check 65 last as the enforcing backstop. (Loses "gate-verified as it lands" — but that property was never achievable anyway given the contradiction.)

In all options, C1's verification line "`validate-pack.py` exit 0 (esp. … 65)" must change: at C1 Check 65 is present-but-empty-scope (green vacuously) OR Check 65 is not yet added. The plan's current claim that C1 runs the full gate green over the LIVE unstripped tree is false.

---

### BLOCKER-2 — 16 IN-set surfaces (11 pack skills + 5 pack agents) have NO strip commit; 6 carry history hits the gate flags → Check 65 cannot reach green.

**Claim challenged.** Plan §2.118 (commit-count reconciliation): "EVERY in-scope file gets EXACTLY ONE commit." Plan waves W2 (C4-C14) = `pack-ops/*.md` + `_rules` + `_intro` ONLY; W3/W4 = trinity; W5 = PROJECT agent defs (`project-template/.claude/agents/*.md`); W6 = PROJECT skills (`project-template/skills/*`). **The 11 pack `.claude/skills/*/SKILL.md` and 5 pack `.claude/agents/pack-*.md` appear in NO plan wave.**

**Why it matters.** Design §A (FINAL-V2 L55-56) classifies pack `.claude/skills/*/SKILL.md` (11) and `.claude/agents/pack-*.md` (5) as **IN** (gate-scanned). They are in Check 65's frozen ~136 IN set. If they carry history hits and never get a strip commit, Check 65 stays RED forever.

**Independent measurement (runtime HEAD a847f12):**
```
$ for f in .claude/skills/*/SKILL.md .claude/agents/pack-*.md; do n=$(grep -cE "20[0-9]{2}-[0-9]{2}-[0-9]{2}|\bBD-[0-9]+|\b[0-9a-f]{7,40}\b|per BD-" "$f"); [ "$n" -gt 0 ] && echo "$n  $f"; done
2  .claude/skills/boundary-investigation/SKILL.md
1  .claude/skills/commit-discipline/SKILL.md
1  .claude/skills/implementation-report/SKILL.md
4  .claude/skills/pack-startup/SKILL.md
1  .claude/skills/review/SKILL.md
3  .claude/skills/verification-harness/SKILL.md
```
pack-startup line detail:
```
38:  monolithic mirror — BD-203 deleted `pack-ops/BACKLOG.md` +     (P2 past-action)
107: the BD-237 "no CI gate, no                                     (P3 provenance)
115: surface additions. (Step 5 is now the BD-237 graph-freshness   (P3 provenance)
123: The D-19 tracker opt-in recommendation is DEFERRED (BD-214)    (deferred-feature — C2 Step-8 strip touches THIS one only)
```
commit-discipline: `112: … The BD-119 C-2 incident was` (P8 incident narration). The C2 nuclear strip only touches pack-startup's deferred-feature Step 8 (L121-129 + reserved comment) — it does NOT strip pack-startup L38/L107/L115, nor any history hit in the other 5 pack skills. The 5 pack agents measured 0 hits (e.g. `pack-architect.md` = 0), so they need only the BLOAT axis, not history — but they are STILL IN-scope per BD-243 (terseness) and per spec line 18 ("pack: .claude/skills/*/SKILL.md (11); .claude/agents/pack-*.md (5)").

**Spec corroboration.** BD-243.md File/Symbol line 18 explicitly lists "Pack (~34): … .claude/skills/*/SKILL.md (11); .claude/agents/pack-*.md (5)." These are in-scope deliverables the plan dropped.

**Required fix.** Add a pack-skills wave (11 commits or 1-per-file) + a pack-agents wave (5 commits) to the partition, scheduled parallel (distinct files), pack-only scope, dep on the gate. The 6 history-bearing pack skills MUST be stripped before Check 65 can go green; all 16 get the bloat pass. Update §2.118 reconciliation + the §3 S1-S7 schedule (these slot into a pack-parallel wave like S4 or a new stage). Note boundary-investigation appears as BOTH a pack skill (`.claude/skills/boundary-investigation/SKILL.md`, 2 hits, UNPLANNED) and a project skill (`project-template/skills/boundary-investigation/SKILL.md`, plan C23) — they are DIFFERENT files; the plan handles only the project copy. The pack copy is unaddressed.

---

### BLOCKER-3 — C2 is NOT green-atomic: a `` `pack tracker` `` verb token in `pack-ops/OPTIONAL-FEATURES.md` (a Check-22 prose doc) loses its coverage in C2 but is not stripped until C6.

**Claim challenged.** Plan §2 C2 (line 51): "ATOMIC, ONE commit … lands green." Plan §4 C2 (line 157): "`validate-pack.py` exit 0 (esp. Checks 22, 23, …)." Design §N.2 (FINAL-V2 L139) WARNS: "After tracker verbs leave the prose docs … verify no surviving `pack tracker` verb token in the Check-22 doc set." The plan does NOT fold the `pack-ops/OPTIONAL-FEATURES.md` tracker-section strip into C2 — that strip is C6 (Wave W2 / Stage S4), AFTER C2 (S2).

**Why it fails.** Check 22 (`check_help_fragment_freshness`) scans a fixed prose doc set and requires every backtick-fenced verb-shape token to be present in `frag_text` (= help fragment text). C2 deletes the tracker fragment and sets `frag_text = HELP-FRAGMENT-PACK only` (tracker rows removed). Check 22's doc set includes `pack-ops/OPTIONAL-FEATURES.md`, which still contains the verb token until C6.

**Independent measurement (runtime HEAD a847f12):**
```
$ # Check 22 prose doc set (scripts/validate-pack.py L2058-2075):
    pack-ops/PACK-CHAT.md, QUICKSTART.md, pack-ops/OPTIONAL-FEATURES.md,
    supporting-docs/INSTALL-PROCEDURES.md  (pack surface)
    project-template/docs/pack/PM-CHAT.md  (project surface)
$ grep -nE "\`pack tracker\`" pack-ops/OPTIONAL-FEATURES.md
326:`pack tracker` flip verbs refuse with a deferred message). Resumption is gated
```
`` `pack tracker` `` matches `_VERB_RE` shape `pack(?:\s\w+)+` (a non-script verb token → the existence-filter does NOT apply; it is added to `verbs_referenced` unconditionally). Then `missing = v not in frag_text`. After C2 removes the tracker rows from HELP-FRAGMENT-PACK, `` `pack tracker` `` is absent from `frag_text` → **Check 22 FAILS** ("verbs referenced in prose but absent from help fragment") for the whole interval C2(S2)..C6(S4).

The two script-path tokens in the same section ARE saved by C2's `# pack-internal: true` marking (verified: Check 22 existence-filter calls `_is_pack_internal` and `continue`s):
```
320:`scripts/pack-tracker.sh`   → skipped (pack-internal after C2)   OK
321:`scripts/tracker-migrate.sh`→ skipped (pack-internal after C2)   OK
326:`pack tracker`              → NOT a script path → NOT skipped → FAILS
```
So C2's internal-marking handles the scripts but NOT the bare `` `pack tracker` `` verb token.

**Required fix.** Fold the `pack-ops/OPTIONAL-FEATURES.md` "## Tracker integration (deferred)" section strip (currently C6) INTO C2 (or, at minimum, strip the L326 `` `pack tracker` `` verb token in C2). Same-file rule then makes C6 unnecessary for OPTIONAL-FEATURES (its remaining W2 history/bloat strip folds into the C2 edit, OR OPTIONAL-FEATURES gets one combined commit). Re-derive the partition so `pack-ops/OPTIONAL-FEATURES.md` has EXACTLY one commit that is green-atomic with the fragment deletion. Also re-confirm `QUICKSTART.md` (Check-22 pack doc) carries no `pack tracker` verb token — measured 0, clean.

---

### MINOR-1 — Commit-count reconciliation (§2.118) is self-contradictory and arithmetically loose.

Line 118 states "Total distinct-file commits = 33 logical commit-IDs" then immediately computes "W0(1)+W-NUCLEAR(1)+W1(1)+W2(11)+W3(1)+W4/W-LEAK(8)+W5(17)+W6(49) = 89" and calls the C-numbering "illustrative." The header (line 6) and title say "33 commits"; the body computes ~89 file-commits. After BLOCKER-2 adds 16 pack skill/agent commits the count grows again. The plan must state ONE authoritative number (the executable file→commit partition count, ~89+16) and stop calling it 33. A coder/Pack-Chat scheduling off "33" will under-provision. Re-derive after BLOCKER-2/3 fixes.

### MINOR-2 — Scope-keyword commit-subject token trap not flagged for C2/C3 prose.

Plan marks C2/C3 NEUTRAL (correct — both touch pack + `project-template/` paths; verified C2 touches `project-template/docs/pack/HELP-FRAGMENT*.md` and C3 touches `project-template/` trinity). But Check 36 parses the commit SUBJECT for the literal tokens `pack-only`/`project-only`. The plan's own prose discusses "split-option C2a pack-only / C2b project-only." If a coder/Pack-Chat lets the words "pack-only" leak into the C2/C3 commit SUBJECT line, Check 36 fires a false scope claim (a denying token wins). Add an explicit note: C2/C3 subjects must contain NO scope-keyword token (neutral framing only). [reference: commit-subject-keyword-token-trap]

### MINOR-3 — C1 verification asserts "Check 59 … 63 entries" as a hard integer; consistent with EE-P2 but verify against the live registry.

Plan §4 C1 line 153: "`--only-check 59` asserts '63 entries == constant'." Measured `CHECK_REGISTRY_EXPECTED_COUNT = 62` at HEAD; +1 for Check 65 → 63 is correct IF Check 44's reduction adds no registry entry (confirmed: a pattern-tuple reduction is +0). The integer is right, but per the G4 lesson (prefer the live gate over a literal) the verification should also assert `--only-check 59` exit 0 after the bump, not just the integer label.

---

## GREEN-AT-EVERY-COMMIT VERDICT

**FAIL.** The plan's central invariant ("each commit lands green, validate-pack exit 0") is violated from C1 onward:

1. **C1 + every commit C1..last-strip — Check 65 RED (BLOCKER-1).** The gate scans the unstripped IN docs (PACK-MEMORY-RATIONALE 12 dates + 11 SHAs; CLAUDE.md 22 BD/date hits; the 6 pack skills; the W2/W3/W4 targets before their strip lands). No commit between C1 and the final IN-doc strip can pass a full validate-pack with Check 65 active over the live tree.
2. **Terminal state never green (BLOCKER-2).** Even after ALL planned strips, the 11 pack skills + 5 pack agents are never stripped → Check 65 stays RED on the 6 history-bearing pack skills permanently. There is no green terminal commit.
3. **C2 RED for the C2..C6 interval (BLOCKER-3).** Check 22 fails on the orphaned `` `pack tracker` `` verb token in `pack-ops/OPTIONAL-FEATURES.md` until C6 strips it.

The C1-Check-65-pre-strip hazard (the charge's named "single most likely plan defect") is CONFIRMED and is the dominant defect. The plan offers no activation-ordering mechanism; it inherited the design's W0-first-vs-clean-after-strip contradiction verbatim. A reconciliation planner MUST add an explicit Check-65 activation-ordering mechanism (BLOCKER-1 Options A/B/C), add the 16 pack skill/agent commits (BLOCKER-2), and make C2 atomic with the OPTIONAL-FEATURES verb-token strip (BLOCKER-3) before this plan reaches a coder.

What the plan got RIGHT (verified, no rework): C1 `pack-only` scope (Check 36 checks `git show --name-only` paths, not data strings — the project paths in `_CHECK_65_OPERATING_DOCS` are data; verified `(36, "check_commit_scope_honesty")` uses `git show --name-only`). C2/C3 NEUTRAL keyword. Trinity serialization C3→C15 / C3→C16 (same-file). Tri-family lock (16 roles ×3). Project partition: 37 skills − 2 (C21/C23 fold) = 35; 10 prompts = auditor(C19)+coder(C20)+8; 4 docs/pack IN (G3); 4 stream-meta (3 `_rules` + 1 `_format`, only changelog has `_format.md`); 3 project `_intro` (C22 EXEMPT-leak). Nuclear ref counts: 23 validate-pack HELP-FRAGMENT-TRACKER refs (exact), 5 init-project logical hits (L14/949-956/960-961/1260/1437 — exact). Next-free check = 65 (highest = 64). Check 54 = `check_optional_features_presence` (not tracker → C17 strip is Check-54-safe, verified). Checks 29/35/51 dormant-code guards untouched (BD-214). Manifest push-time plan (§7) correct. Literal placeholders Check-65-safe.

---

## EMPIRICAL-EVIDENCE BLOCK

Runtime: HEAD `a847f120e4ada06456bec4e2bf6d275fdd8c0742`, branch v11-dev, 2026-06-21, clean tree. Graph queried for discovery first (`graphify-out/graph.json`); STALE for BD-243-era surfaces (the design's own EE-P7/EE-V10 record the same) → G2 fallback to grep/Read/git for every exact-state claim. All git verbs read-only (`rev-parse`, `status`, `show`-pattern N/A here).

**EE-1 — runtime HEAD = BD-243 commit, clean.** Cmd `git rev-parse HEAD; git branch --show-current; git status --short`. Output `a847f120e4ada06456bec4e2bf6d275fdd8c0742` ; `v11-dev` ; (empty). Conclusion: SUPPORTED.

**EE-2 (BLOCKER-1) — pre-strip IN docs carry abundant non-allowlisted history.** Cmd (verbatim above): RATIONALE 12 dates + 11 SHAs + 1 P2; CLAUDE.md 6 bare `(BD-NNN)` + 20 inline BD + 2 dates = 22 total. None in K1-K11. Interpretation: Check 65, if added live at C1, FAILs on these. Conclusion: SUPPORTED.

**EE-3 (BLOCKER-1) — full validate-pack runs every check vs the live tree.** Cmd `grep -nE "_build_check_registry|read_text\(\)" scripts/validate-pack.py`. Output: `_build_check_registry()` builds the no-flag full-run sequence (L9893/L9914); checks `.read_text()` live files (L543, L865, L1470, … L2090). Interpretation: registering Check 65 at C1 means a full run scans the live unstripped IN docs. Conclusion: SUPPORTED.

**EE-4 (BLOCKER-1) — design contradiction is the root; plan offers no mitigation.** Cmd `grep -n "run FIRST\|gate-verified as it lands" FINAL.md` → L334 "W0 … run FIRST … gate-verified as it lands"; FINAL §E.5.4 "Check 65 scans clean … after B.2 strips land." Cmd `grep -niE "disabled|empty.scope|stub|inert|activate.*65 after strip|no-op until" PLAN-BD-243.md` → (empty). Interpretation: design wants gate-first AND green-after-strip (impossible together for a full run); plan copied it with no activation-ordering. Conclusion: SUPPORTED.

**EE-5 (BLOCKER-1) — propagation: CLAUDE.md still dirty at C3 (rule add) before C15 (strip).** Cmd `grep -cE "\bBD-[0-9]+|20[0-9]{2}-[0-9]{2}-[0-9]{2}" CLAUDE.md` → 22. Plan: C3=S3 adds rule to CLAUDE.md; C15=S5 strips it. Interpretation: full validate-pack at C3 also fails Check 65. Conclusion: SUPPORTED.

**EE-6 (BLOCKER-1, narrow-claim-true) — literal placeholders are Check-65-safe.** Cmd `python3 -c "..."` → `date.search('YYYY-MM-DD')=False`, `bd.search('BD-NNN')=False`, `date.search('2026-06-21')=True`, `bd.search('BD-243')=True`. Interpretation: the new rule's own text won't trip Check 65; the surrounding unstripped doc will. Conclusion: SUPPORTED (the plan's narrow self-safe claim holds; it does not rescue the commit).

**EE-7 (BLOCKER-2) — 16 pack IN surfaces unplanned; 6 carry history.** Cmd (verbatim above): boundary-investigation 2, commit-discipline 1, implementation-report 1, pack-startup 4, review 1, verification-harness 3. pack-startup hits L38 `BD-203 deleted`, L107/115 `BD-237`, L123 `BD-214`. C2 strips only pack-startup Step 8 (L121-129). pack agents = 0 history (e.g. pack-architect.md=0) but in-scope for bloat. Spec L18 lists both families. Plan waves contain neither. Conclusion: SUPPORTED.

**EE-8 (BLOCKER-3) — Check-22 doc set + orphaned verb token.** Cmd `sed -n '2058,2075p' validate-pack.py` → doc set incl. `pack-ops/OPTIONAL-FEATURES.md`, project `PM-CHAT.md`. Cmd `grep -nE "\`pack tracker\`" pack-ops/OPTIONAL-FEATURES.md` → `326:\`pack tracker\` flip verbs …`. Cmd reading Check 22 body L2090-2135: `_VERB_RE` `pack(?:\s\w+)+` adds non-script verb tokens unconditionally; `missing = v not in frag_text`; script paths skipped via `_is_pack_internal`. Interpretation: after C2 removes tracker rows from HELP-FRAGMENT-PACK, `` `pack tracker` `` is uncovered → Check 22 fails until C6 strips it. Conclusion: SUPPORTED.

**EE-9 — nuclear ref counts exact.** Cmd `grep -c "HELP-FRAGMENT-TRACKER" scripts/validate-pack.py` → 23 (plan claims 23). Cmd `grep -n "HELP-FRAGMENT-TRACKER" scripts/init-project.sh` → L14, 949-956, 960-961, 1260, 1437 (plan's 5 logical sites — exact). Conclusion: SUPPORTED.

**EE-10 — next-free check + EXPECTED_COUNT + Check 54.** Cmd `grep -oE "^\s*\(6[0-9], \"check_"` → highest 64; `grep -n "CHECK_REGISTRY_EXPECTED_COUNT = "` → 62 (L500); `grep -nE "\(54, \"check_"` → `check_optional_features_presence`. Interpretation: 65 free, 62→63 correct, Check 54 not tracker (C17 Check-54-safe). Conclusion: SUPPORTED.

**EE-11 — project IN counts (G3) + Check 36 mechanism + tracker-script markers.** Cmd `ls … | wc -l`: project skills 37, prompts 10, claude/codex/plugin agents 16/16/16, project docs/pack operating IN = 4 (OPTIONAL-FEATURES/PACK-FEEDBACK/PLATFORM-SKILLS/PM-CHAT; HELP-FRAGMENT{,-TRACKER} EXEMPT). Cmd `grep -n "(36," + range_spec` → Check 36 uses `git show --name-only` on commit paths. Cmd `grep -l "pack-internal: true" scripts/pack-tracker.sh scripts/tracker-migrate.sh scripts/pack-td.sh` → (empty; C2 must add to the first two). Conclusion: SUPPORTED.

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **reconciliation-instance-independence** | Fresh adversarial instance; did NOT author PLAN-BD-243.md; did NOT read the prior architect adversarial review (`ADVERSARIAL-REVIEW-BD-243.md` left unread per charge). Challenged independently; re-measured every load-bearing claim at HEAD a847f12 (EE-1..EE-11). NEEDS-REWORK findings written for a SEPARATE fresh reconciliation planner (BLOCKER-1 Options A/B/C, BLOCKER-2 add-16-commits, BLOCKER-3 fold-OPTIONAL-into-C2). | COMPLIANT |
| **agents-never-commit** | Git verbs run: `git rev-parse HEAD`, `git branch --show-current`, `git status --short` (all read-only). Sole write = this review doc via `cat >` to `/tmp/pack-handoff-bd243-plan/ADVERSARIAL-REVIEW-PLAN-BD-243.md`. No repo-file edit; no patch; no state-changing git verb; no OptiquityTrader write. | COMPLIANT |
| **empirical-evidence-blocks [planner]** | §EMPIRICAL-EVIDENCE EE-1..EE-11: each = command + verbatim output + HEAD a847f12 + 2026-06-21 + interpretation + SUPPORTED. The charge's required re-measurements done: C1-Check-65-pre-strip hazard (EE-2/3/4/5 — the unstripped tree FAILS Check 65); the 23+5 nuclear refs (EE-9); the file→commit partition (EE-7/11 + §findings — missed 16 pack files, double-coverage of OPTIONAL-FEATURES via C2/C6). | COMPLIANT |
| **ci-guard-measure-then-bound** | Measured the gate's matching logic against the actual current tree FIRST (EE-2/3/7): Check 65 cannot be added live before its IN docs are clean (BLOCKER-1) — the plan's "W0 first + C1 validate-pack green" violates measure-then-bound (the gate is unbounded against the unstripped state). Required fix bounds the gate to a green-at-every-commit activation order (Options A/B/C). The 16 unplanned pack IN docs (EE-7) mean the allowlist+scope is not yet sized to a clean projected post-fix state. | COMPLIANT |
| **enumerate-encoding-surfaces** | Verified plan pairs edited check bodies with tests (C1: 44/65 + their tests; C2: 22/23/39/40/41/43/44-durable + pack-help-test + migrate + init-project). Verified trinity ×2 (C3/C15 pack-root; C3/C16 project) + tri-family ×3 (C24-C39). BLOCKER-2 found a MISSED encoding surface class: the 11 pack skills + 5 pack agents are IN-set (gate-encoded by `_CHECK_65_OPERATING_DOCS`) but have no commit; BLOCKER-3 found Check 22's doc-set coupling (`pack-ops/OPTIONAL-FEATURES.md`) not enumerated into C2. | COMPLIANT |
| **commit-subject-scope-keyword (Check 36)** | Verified each boundary commit's keyword vs file set: C1 pack-only (Check 36 = `git show --name-only`, data strings don't count — VALID); C2 NEUTRAL (touches pack + `project-template/docs/pack/HELP-FRAGMENT*` — VALID); C3 NEUTRAL (pack trinity+RATIONALE + project trinity — VALID); C15 pack-only (pack trinity only — VALID); C16 project-only (project trinity only — VALID). MINOR-2: subject-token-trap risk on C2/C3 prose flagged. | COMPLIANT |
| **graph-first-context** | Discovery attempted via graphify (per design EE-V10, graph STALE for BD-243-era) → G2 fallback to grep/Read/git immediately for every exact-state claim; never blocked. Injected absolute `--graph` path form honored; QUERY-only (no build). | COMPLIANT |
| **verify-full-ci-suite** | Verified the plan's §4 per-commit verification runs the FULL `validate-pack.py` battery (not just touched checks) + integration tests (C2: pack-help-test + test-migrate ×4 + test-init-project; C1: check-44 + check-65 tests; C3: check-45). The FULL-battery requirement is precisely what exposes BLOCKER-1 (the full run executes Check 65 against the live tree at C1). | COMPLIANT |
| **rules-applied-verification-block** | This table. | COMPLIANT |

**END — ADVERSARIAL-REVIEW-PLAN-BD-243.md**
