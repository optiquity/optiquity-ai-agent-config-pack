# DESIGN-BD-238-PARITY-CHECK — pack-root trinity `## Pack memory` body-parity CI check: necessity decision

**Role:** pack-architect (RO), FRESH independent instance. I did NOT author DESIGN-BD-238 or DESIGN-BD-238-RECONCILED; I am NOT the adversarial reviewer. **BD:** BD-238 (LARGE). **Task:** the strict binary the user set 2026-06-23 — is a CI check enforcing pack-root trinity `## Pack memory` BODY parity NECESSARY (→ fold into BD-238, fully designed) or NOT NECESSARY (→ dropped entirely, no separate BD). A separate-BD deferral is NOT available. **Output:** this doc only (sole Write, under `/tmp`). Read-only git only. No memory store read/written (user MEMORY PROHIBITION 2026-06-23 honored).

---

## 0. Runtime regime (RO; verified)

| Field | Value |
|---|---|
| `pwd` | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` |
| `git rev-parse HEAD` | `e8ba9e7a4d1d3ea33ac3d4320d0aee77bf973381` (= expected `e8ba9e7`) |
| branch | `v11-dev` |
| `git status --short` | clean |
| graph | DISCOVERY queries attempted; the actual check algorithms + rule bodies are not graph-node-indexed → grep/Read for VERIFICATION (G2 fallback, sanctioned for exact-bytes/algorithm reads). |
| writes | EXACTLY ONE: this doc. No source edits. No state-changing git verb. |

---

## 1. VERDICT (lead)

### NOT NECESSARY — the check is DROPPED ENTIRELY.

A CI check enforcing pack-root trinity `## Pack memory` BODY parity is **NOT necessary** and should be **dropped from BD-238 entirely** (no separate BD, no scheduling). The evidence drives this — not anyone's lean:

1. **The gap is real but small and self-correcting.** No CI check byte-compares pack-root `## Pack memory` bodies (confirmed against the actual `validate-pack.py` algorithms). But the discipline is empirically HOLDING: of 26 slug-keyed `## Pack memory` rules, **23 are byte-identical ×3 at live HEAD** (measured). The 3 that diverge are ALL legitimate (CLI-name normalization — KEEP, not drift). There is ZERO measured illegitimate drift in the tree right now.

2. **A correct check is INFEASIBLE to bound cleanly — the measure-then-bound rule itself says do NOT ship it.** The pack's own `ci-guard-measure-then-bound` rule requires sizing an allowlist EXACTLY to the legitimately-divergent set and NOT widening it to admit unclassified hits. I measured the actual tree: legitimate ×3 divergence is NOT separable from drift by any structural signal (CLI tokens appear in BOTH the 3 divergent rules AND 2 currently-identical rules). The ONLY way to bound the check is a hand-maintained per-rule allowlist of exactly-which-slugs-may-diverge — which is a NEW discipline surface that must be updated on every CLI-normalization edit. **The check would replace one discipline (keep bodies parallel) with a strictly heavier discipline (keep bodies parallel EXCEPT maintain an allowlist of the exceptions AND keep that allowlist exact).** That is negative design ROI: more files, more conventions, more special cases, for a gap with zero current exposure.

3. **The blind-spot tax is large.** A slug-keyed check misses the **28-vs-23 unslugged bullets** (CLAUDE.md carries 28 untagged `## Pack memory` bullets; AGENTS/GEMINI carry 23 — a 5-bullet asymmetry, largely the Claude-only sub-agent rules). A check keyed on `[rationale:]` slugs cannot see the untagged pipeline rules (researcher-first, pack-architect-spawn, planner-to-coder) — exactly the rules BD-238 consolidates. A positional/textual check instead has to special-case the entire Claude-only `### Sub-agent behavior` section. Either way the check is mostly special-cases.

4. **The discipline was DELIBERATELY re-affirmed 3 days ago, on evidence, with no countervailing incident.** BD-244 (Resolved 2026-06-23) explicitly recorded a "trinity-parity-is-discipline correction" — the planner re-ruled, with the reconciled design's §10.1 also concurring, that pack-root parity is discipline-enforced. There is NO recorded incident of a pack-root `## Pack memory` body-parity drift ever shipping undetected. The reconciled §10.1 already dropped the unsupported "bitten twice" framing. Re-opening a 3-day-old evidence-based ruling to add a heavyweight guard, with no new adverse evidence, is unwarranted.

5. **The existing safeguards are sufficient for the actual risk.** The trinity rule (which explicitly covers "the pack-repo copies of these three files"), the reconciled design's SAFEGUARD-1 (planner byte-parity diff step, per-edit) and SAFEGUARD-2 (coder PREFLIGHT ×3 attestation, per-edit) already protect each NEW rule at the moment it lands — which is the only moment a NEW rule can drift. A standing whole-corpus CI check buys protection only against a SILENT drift to an EXISTING rule made OUTSIDE the per-edit safeguards; that scenario has never occurred and is itself a trinity-rule violation a reviewer/diff catches.

**This is NOT the §10.1 "defer to a separate BD" outcome the user rejected.** The user rejected SCHEDULING the work elsewhere as tech debt. My verdict is that the work should NOT EXIST: it is not unbuilt-necessary-work being punted; it is unnecessary-work whose correct design is a net complexity LOSS. Dropping it is the measure-then-bound-correct outcome, not a deferral.

The rest of this doc is the evidence that drives the verdict (§2 the gap, §3 the risk + the infeasible-bound analysis, §4 the discipline's reliability, §5 what stays as the sufficient safeguard). Because the verdict is NOT NECESSARY, the "IF NECESSARY — design the check" 6-point section is intentionally NOT a full check design; §6 records what a check WOULD have to look like (to PROVE the bound is infeasible, per `ci-guard-measure-then-bound`), which is itself part of the necessity evidence.

---

## 2. The actual gap (measure-then-bound — what CI DOES and does NOT enforce)

I re-verified every claim in the reconciled §7.1 directly against `scripts/validate-pack.py` at HEAD `e8ba9e7`. The §7.1 premise HOLDS, and I corrected one contradicting research claim.

| Check | What it actually does at pack-root | Byte-compares `## Pack memory` bodies ×3? |
|---|---|---|
| **Check 16** (`## Project addenda` H2) | Registered TWICE (project-template + pack-root); pack-root short-circuits via `_CHECK_16_EXEMPT_SURFACES = {"pack-root"}`. | NO (exempt at pack-root). |
| **Check 18** (Trinity H2 parity) | Registered TWICE; **DOES run at pack-root** (`check_trinity_h2_parity(REPO_ROOT, "pack-root")`, registry L11356). Collects ONLY `if line.startswith("## ")` (L1634-1638) — H2 heading lines, modulo `GEMINI_INTRINSIC_H2S = {"## Agent roster","## Antigravity CLI operating notes"}`. | **NO — H2 headings only, never bodies.** |
| **Check 19** (no body scaffolding) | Registered TWICE; runs at pack-root; forbids stray HTML comments only. | NO. |
| **Check 45** (rule↔rationale bijection) | `corpus_path = REPO_ROOT / "CLAUDE.md"` (L7359) — CLAUDE.md is the SOLE representative corpus; AGENTS/GEMINI `## Pack memory` slugs are never bijection-checked. | **NO — single-file corpus, no cross-file body diff.** |
| **Check 57** (trinity surfaces) | `_CHECK_57_TRINITY_SURFACES` = `project-template/` trinity only. | NO (pack-root not in surface set). |
| **Check 66** (bullet concision) | `_check_66_iter_bullets(path, marker)` per file independently; cap = 1300 chars each. Never cross-compares the three. | **NO — per-file cap, no cross-compare.** |

**CONCLUSION (gap confirmed):** there is NO CI check that byte-compares the pack-root `## Pack memory` rule BODIES across CLAUDE/AGENTS/GEMINI. Pack-root trinity body parity is a DISCIPLINE (the trinity rule, CLAUDE.md L113-114: "This rule also applies to the pack-repo copies of these three files"), not an auto-caught CI invariant. The reconciled §7.1/EB-E premise is SUPPORTED.

**Correction to the research census (RESEARCH Ambiguity #2):** the research doc speculated Checks 16/18/19 "are template-only … they DO NOT gate the pack-root SSOT." That is WRONG. The registry (L11297, L11344-11366) registers 16/18/19 TWICE — once at `project-template`, once at pack-root — and Check 18/19 RUN at pack-root (only Check 16 short-circuits via the exempt set). The reconciled design's claim (Check 18 runs at pack-root but compares H2 only) is the accurate one. This correction does NOT change the gap conclusion: even though Check 18 runs at pack-root, it compares H2 headings, not bodies.

---

## 3. The risk + the infeasible-bound analysis (the load-bearing evidence)

This is the measure the reconciled design DECLARED but never RAN. I ran it. The result is what flips the verdict from the reconciled "defer" to "drop": the actual tree state makes a CORRECT check impossible to bound cleanly, and the measure-then-bound rule says do not ship such a check.

### 3.1 MEASURE FIRST — the actual ×3 `## Pack memory` body state at live HEAD

Extracted every `## Pack memory` rule bullet from CLAUDE.md / AGENTS.md / GEMINI.md, keyed by its own `[rationale:]` tail tag, normalized (whitespace-collapsed), and compared ×3 (EB-1, EB-2):

| Category | Count | Detail |
|---|---|---|
| Slug-keyed rules byte-IDENTICAL ×3 | **23** | The discipline is holding for the bulk. |
| Slug-keyed rules DIVERGENT ×3 (in all three, differ) | **3** | `graph-first-context`, `reconciliation-instance-independence`, `spawn-unique-naming` |
| Claude-ONLY slug (present only in CLAUDE.md) | **1** | `spawn-registry-find` (lives in the documented `### Sub-agent behavior (Claude-only)` Trinity-exempt section) |
| UNSLUGGED bullets (no `[rationale:]` tag) | **28 / 23 / 23** | CLAUDE.md=28, AGENTS.md=23, GEMINI.md=23 — a 5-bullet asymmetry |

### 3.2 CATEGORIZE every divergence — KEEP vs STRIP

Per `ci-guard-measure-then-bound` step 2, I categorized each of the 3 ×3-divergent rules and the structural asymmetries:

| Divergence | KEEP / STRIP | Evidence |
|---|---|---|
| **`graph-first-context`** (lens C=4275 / A=3566 / G=3639) | **KEEP** (legitimate) | The CLAUDE.md body carries the Claude-only `**Path-injection under worktree isolation**` + `**Worktree path-injection is Claude-only**` sub-bullets — explicitly self-labeled Trinity-exempt ("Do NOT 'restore parity' by porting this injection contract"). Remainder diverges on CLI-name substitution (Claude Code session/skill auto-route vs Codex rule-applies vs Antigravity `agy`). This is exactly `cross-cli-reference-normalization`. |
| **`reconciliation-instance-independence`** (C=1260 / A=1214 / G=1175) | **KEEP** (legitimate) | Diverges ONLY on the per-CLI re-engage mechanism: Claude `SendMessage`; Codex `resume_agent` (where multi-agent messaging enabled); Antigravity known-ID / idle-rewake. Pure CLI-mechanism normalization. |
| **`spawn-unique-naming`** (C=898 / A=878 / G=856) | **KEEP** (legitimate) | Diverges on the per-CLI agent-name field + addressing (Claude `name`/Agent-tool; Codex `name` field + `nickname` display-only; Antigravity known-ID / named-role). CLI-mechanism normalization. |
| **28-vs-23 unslugged-bullet asymmetry** | **KEEP** (legitimate, structural) | The 5-bullet CLAUDE surplus is the Claude-only `### Sub-agent behavior` rules + the untagged pipeline rules — the documented Trinity-exempt section + rules that simply carry no rationale tag. |
| **`spawn-registry-find` Claude-only slug** | **KEEP** (legitimate, structural) | Lives in `### Sub-agent behavior (Claude-only)` — documented Trinity-exempt. |
| **STRIP set (illegitimate drift)** | **EMPTY** | ZERO occurrences. Nothing to strip. The tree carries no drift right now. |

**Result of measure-first:** the STRIP set is EMPTY. There is no contamination to remove. Every divergence is legitimate CLI-normalization or documented Trinity-exemption. This is the first half of the necessity answer: a check would have ZERO drift to catch in the current tree.

### 3.3 DESIGN THE BOUND — and prove it cannot be sized cleanly

`ci-guard-measure-then-bound` step 4: "Size the allowlist EXACTLY to the legitimate-set — no broader." Step 5: "Verify the guard runs clean against the projected post-fix state." I attempted both. The attempt FAILS the rule's own bar:

**Attempt A — auto-distinguish legitimate divergence by a structural signal (no allowlist).** Tested whether "the rule contains a CLI-name token" cleanly separates the 3 divergent (legitimate) rules from the 23 identical rules (EB-3):
- All 3 divergent rules carry CLI tokens (`Claude Code`, `Codex`, `Antigravity`, `SendMessage`, `worktree`, …) — good.
- BUT **2 of the 23 byte-identical rules ALSO carry CLI tokens** (`agents-never-commit` carries `worktree`; `cross-cli-reference-normalization` carries `CLI`). These ARE byte-identical ×3 today.
- **So "carries a CLI token" is NOT a clean separator.** Keying the check on it would (a) stop enforcing parity on `agents-never-commit` — a rule that MUST stay identical except where future CLI text might legitimately diverge — opening a real drift hole; and (b) admit a borderline/unclassified class. That is precisely the "widen the allowlist to admit borderline hits" anti-pattern the rule forbids ("treating contamination as legitimate by default — which defeats the guard's purpose").

**Attempt B — a hand-maintained per-rule divergence-allowlist (exactly 3 slugs today).** Size the allowlist to exactly `{graph-first-context, reconciliation-instance-independence, spawn-unique-naming}` + the Claude-only `### Sub-agent behavior` section + the untagged-bullet handling. This CAN be made to run clean post-design. But it is a NEW standing discipline surface with a worse cost profile than the discipline it replaces:
- Every time a rule's CLI-normalization text changes (which `cross-cli-reference-normalization` makes a routine, expected edit), the editor must remember to add/keep its slug in the divergence-allowlist — or the check false-positives and blocks a legitimate edit.
- The allowlist itself is a parity-discipline surface: it must be kept EXACT (per the rule). So the check converts "keep 26 rule bodies parallel by discipline" into "keep 23 rule bodies parallel by check + keep a 3-entry exception-allowlist exact by discipline + special-case the Claude-only section + handle the slugged/unslugged asymmetry by discipline." **Net: MORE discipline surfaces, not fewer.**
- It still has the §3.4 blind spot below.

**Attempt C — positional/whole-section ×3 byte-diff (the naive design the reconciled §10.1 flagged).** REJECTED outright: it false-positives on all 3 legitimate divergences + the entire Claude-only section + the 5-bullet asymmetry. The reconciled §10.1 was right that a naive whole-section diff is wrong; my measurement quantifies exactly how wrong (3 rules + 1 section + 5 bullets of false positives).

### 3.4 The blind-spot tax (independent of which attempt)

A slug-keyed check (Attempts A/B) is blind to the **28-vs-23 unslugged bullets**. The three rules BD-238 consolidates — `Researcher-first pipeline`, `Pack-architect spawn protocol`, `Planner output → user review → coder spawn` — carry NO `[rationale:]` tag (confirmed in RESEARCH B5 + the reconciled §5 "spawn-rule-manifest decision"). A slug-keyed parity check would NOT cover the very rules at the center of BD-238. To cover them, the check must switch to a positional/textual model, which re-imports the Claude-only-section special-casing of Attempt C. There is no design point that is both complete AND cleanly bounded.

### 3.5 The cost-of-being-wrong vs the discipline's reliability

- **Cost of being wrong (a drifted rule ships to clients):** the pack-root trinity is the PACK-OPS trinity — it is read by agents working ON the pack. It does NOT ship to clients (the client-facing trinity is `project-template/CLAUDE.md` etc., a path-disjoint surface — RESEARCH (d) proves disjointness; Check 18/57 already gate the project-template trinity). So a pack-root `## Pack memory` body drift degrades PACK-INTERNAL agent instruction, not a client deliverable. The "drifted rule shipping to clients via the trinity that ships" framing in the task prompt does not apply to the pack-root `## Pack memory` surface — that surface is pack-only.
- **The discipline's reliability:** 23/26 rules byte-identical, 0 drift, the trinity rule explicitly covers pack-repo copies, and the per-edit SAFEGUARD-1/SAFEGUARD-2 catch a NEW rule at landing. The one residual scenario — a silent edit to an EXISTING rule in one file only, made outside the per-edit safeguards — is itself a trinity-rule violation that a `git diff` review catches, and has NEVER occurred.

**The bound conclusion:** a correct check is infeasible to size to the legitimate set without ADDING discipline surfaces (the divergence-allowlist + section special-cases + the slugged/unslugged handling), it has a structural blind spot on the unslugged consolidated rules, it guards a pack-INTERNAL (non-shipping) surface, and the risk it covers has zero current exposure and a recoverable cost. `ci-guard-measure-then-bound` therefore says: do NOT ship it.

---

## 4. The discipline + safeguards ARE sufficient (why "drop", not "defer")

The user rejected the §10.1 separate-BD deferral as tech debt. The correct framing of my verdict: this is not "necessary work scheduled elsewhere" (tech debt) — it is "work whose correct form is a net complexity loss," so it should not exist. The existing layers cover the actual risk:

1. **The trinity rule (discipline, pack-root-explicit).** CLAUDE.md L113-114 binds the pack-repo trinity copies to express the same rules. This is the standing obligation; it is reviewable on every `git diff`.

2. **SAFEGUARD-1 — planner byte-parity verification step (per-edit, in the BD-238 plan).** The reconciled §10.2 already elevates this to a HARD, NAMED step: after inserting the umbrella bullet ×3, extract + normalized-diff the three copies; any difference HALTS the commit. This protects the NEW rule at the only moment it can drift (authoring).

3. **SAFEGUARD-2 — coder PREFLIGHT ×3-byte-identity attestation (per-edit).** The reconciled §10.2 requires the C1 coder's PREFLIGHT line to attest byte-identity ×3 by extract+diff. The reviewer confirms it ran.

4. **The bounded reviewer/fix cycle.** A pack-reviewer runs on every commit; a ×3 parity divergence in a touched rule is a grep-and-diff a reviewer performs.

**What a standing CI check would add over (1)-(4):** protection against a SILENT drift to an EXISTING (untouched) rule, made entirely outside a BD's per-edit cycle. That scenario (a) has never occurred, (b) is itself a trinity-rule violation, (c) is caught by any reviewer who diffs the trinity, and (d) degrades only pack-internal instruction, not a client deliverable. The marginal protection does not justify the new discipline surfaces the check requires (§3.3).

**`enumerate-encoding-surfaces` note (why drop is also cleaner here):** had the check landed, it would force lock-step maintenance of: `CHECK_REGISTRY_EXPECTED_COUNT` (validate-pack.py L504), `_build_check_registry()` (the new registry entry), the hardcoded `69` literal in `scripts/tests/test-validate-pack-check-64.sh` (L74 `!= 69` + L82 `(== 69)`), a NEW per-check test `scripts/tests/test-validate-pack-check-72.sh`, AND the divergence-allowlist file + its own parity discipline. Dropping the check avoids all of these. (These surfaces are enumerated here to satisfy the rule and to make concrete what the drop AVOIDS — they are NOT a build instruction.)

---

## 5. What BD-238 ships instead (no change to the reconciled design body)

Because the verdict is NOT NECESSARY, the reconciled DESIGN-BD-238-RECONCILED is left INTACT — with ONE edit the planner must make to its §10.1, replacing the "defer to a separate structural BD" disposition (which the user banned) with the "dropped on measure-then-bound evidence" disposition (this doc):

- **§10.1 disposition change:** strike "The planner should open (or the user should authorize opening) a tracked follow-up BD for the pack-root body-parity check" and replace with: "A pack-root `## Pack memory` body-parity CI check is DROPPED entirely (not deferred) — DESIGN-BD-238-PARITY-CHECK §1-§3 shows a correct check cannot be bounded to the legitimate ×3-divergence set without ADDING discipline surfaces, has a structural blind spot on the unslugged consolidated rules, guards a pack-internal (non-shipping) surface, and covers a zero-current-exposure recoverable risk; the trinity-rule discipline + SAFEGUARD-1/-2 (§10.2) are sufficient."
- **§10.2 stays verbatim.** SAFEGUARD-1 + SAFEGUARD-2 remain the named, load-bearing per-edit protection — now the SOLE-and-sufficient protection (not "sole because the check is deferred," but "sole because the check is correctly absent").
- **No registry count change.** Count stays 69 → 69. No new check, no new test, no lock-step surface churn.
- **No change to the C1/C2/C3 commit plan (§9), the rule text (§4.1), the propagation set (§5), or the size-tiering criterion (§3 of the reconciled doc).** This decision touches ONLY the §10.1 disposition.

The planner folds this one §10.1 disposition edit into the single BD-238 plan. BD-238 is COMPLETE without a parity check.

---

## 6. What a check WOULD require (recorded to PROVE the bound is infeasible — NOT a build spec)

`ci-guard-measure-then-bound` requires that a "do-not-ship" verdict be backed by the same measure-then-bound rigor as a "ship" design. This section records the minimum a correct check would need, demonstrating (not merely asserting) that the bound cannot be met cleanly. It is evidence FOR the NOT-NECESSARY verdict, not a design to implement.

1. **Matching/normalization.** Extract each `## Pack memory` bullet keyed by its TAIL `[rationale:]` tag (the FIRST `[rationale:]` is unreliable — `spawn-registry-find`'s body cross-references `[rationale: spawn-unique-naming]` mid-text, which mis-keys a first-match extractor, as my initial measurement pass demonstrated). Whitespace-collapse before comparison. Handle the 28-vs-23 unslugged bullets — which a slug-keyed model cannot see at all (§3.4 blind spot).
2. **The required allowlist (sized to the measured legitimate set, today):** exactly `{graph-first-context, reconciliation-instance-independence, spawn-unique-naming}` permitted to diverge ×3, PLUS the entire `### Sub-agent behavior (Claude-only)` section exempt (Claude-only slugs like `spawn-registry-find` + its untagged bullets), PLUS a rule for the slugged/unslugged asymmetry. This allowlist is itself a parity-discipline surface requiring exact maintenance on every CLI-normalization edit (§3.3 Attempt B) — the heavier-discipline trap.
3. **Coexistence with existing checks:** would sit beside Check 18 (H2 parity, pack-root) + Check 45 (bijection, CLAUDE.md-corpus) + Check 66 (per-file cap) with no overlap — but ALSO with no shared infrastructure, so it is net-new surface.
4. **Lock-step count surfaces (what the drop avoids):** `CHECK_REGISTRY_EXPECTED_COUNT` 69→70 (validate-pack.py L504); a new `_build_check_registry()` entry (number 72 — current max is 71); the hardcoded `69` in `test-validate-pack-check-64.sh` L74/L82 → 70; a new `test-validate-pack-check-72.sh`.
5. **Verify post-design:** the check CAN be made to run clean against the current tree IF the allowlist is hand-sized to the 3 + Claude-only-section exemptions — but only by building the heavier-discipline surface of (2). "Runs clean" is achievable; "cleanly bounded" is not.
6. **Integration cost:** it would ride in a paired commit alongside C1, bumping the size-tier signal count and the propagation set. None of this is warranted given §3's bound failure.

The fact that a correct check REQUIRES a hand-maintained divergence-allowlist (2) — which is itself a parity-discipline surface — is the proof: the check does not REMOVE the parity discipline, it ADDS a meta-discipline on top of it. That is the measure-then-bound disqualifier.

---

## 7. Empirical-Evidence Blocks

**EB-1 — the ×3 `## Pack memory` rule-body state at live HEAD (the core measure-first).**
- Command: Python — extract each trinity file's `## Pack memory` section (heading-bounded), iterate top-level bullets joining 2-space continuations, key each by its TAIL `[rationale:]` tag, whitespace-collapse, compare ×3.
- Output (verbatim): `distinct slugs: total=27 C=27 A=26 G=26`; `IDENTICAL ×3: 23`; `CLAUDE-ONLY slugs: [('spawn-registry-find', '### Sub-agent behavior (Claude-only)')]`; `DIVERGENT (in all 3, differ): ['graph-first-context','reconciliation-instance-independence','spawn-unique-naming']` with `lens C=4275 A=3566 G=3639` / `C=1260 A=1214 G=1175` / `C=898 A=878 G=856`.
- HEAD/date: `e8ba9e7` / 2026-06-23.
- Interpretation: 23 of 26 slug-keyed rules are byte-identical ×3 (discipline holding); 3 diverge; 1 slug is Claude-only (Trinity-exempt section). The reconciled design asserted parity-is-discipline but never ran this measure — it is non-zero divergence, all legitimate.
- Conclusion: SUPPORTED — the STRIP (drift) set is EMPTY; the KEEP (legitimate-divergence) set is the 3 rules + the Claude-only section.

**EB-2 — the slug-keying subtlety (why a naive extractor mis-measures).**
- Command: `grep -n "rationale: spawn-unique-naming\|rationale: spawn-registry-find\|Uniquely + descriptively name\|Record every spawn" CLAUDE.md AGENTS.md GEMINI.md`.
- Output (verbatim): CLAUDE.md L368 (`Uniquely + descriptively name` `[rationale: spawn-unique-naming]` L379), L451 (`Record every spawn`, cross-refs `[rationale: spawn-unique-naming]` at L454, own tag `[rationale: spawn-registry-find]` at L467); AGENTS.md L357 / L368 only; GEMINI.md L329 / L340 only.
- HEAD/date: `e8ba9e7` / 2026-06-23.
- Interpretation: CLAUDE.md has TWO bullets touching `spawn-unique-naming` text — the real rule (L368) and a cross-reference inside `spawn-registry-find` (L451). A first-match `[rationale:]` extractor mis-keys L451 to `spawn-unique-naming`; the tail-match extractor correctly keys it to `spawn-registry-find` (a Claude-only slug absent from A/G).
- Conclusion: SUPPORTED — a correct check must key on the TAIL `[rationale:]` tag (recorded in §6.1 as a non-trivial normalization requirement).

**EB-3 — CLI-token signal does NOT cleanly separate divergent from identical (Attempt A fails).**
- Command: Python — for the 3 divergent and 23 identical rules, test membership of CLI-token set (`Claude Code`, `Claude-only`, `Codex`, `Antigravity`, `SendMessage`, `resume_agent`, `agy`, `worktree`, `Agent tool`, `subagent_type`, `CLI`, …).
- Output (verbatim): divergent rules all carry CLI tokens; `=== IDENTICAL rules carrying CLI tokens ===  agents-never-commit: CLI-tokens=['worktree']  cross-cli-reference-normalization: CLI-tokens=['CLI']  (count=2 of 23 identical rules carry >=1 CLI token)`; clean (no-token) identical rules = 21.
- HEAD/date: `e8ba9e7` / 2026-06-23.
- Interpretation: "contains a CLI token" is true for BOTH divergent (legitimate) AND 2 byte-identical rules. So a token-presence heuristic cannot be the allowlist key — it would exempt `agents-never-commit`/`cross-cli-reference-normalization` from enforcement (a drift hole) and admit borderline hits (the forbidden widening).
- Conclusion: SUPPORTED — no clean structural separator exists; only a hand-maintained per-slug divergence-allowlist works, which is the heavier-discipline disqualifier.

**EB-4 — no CI check byte-compares pack-root `## Pack memory` bodies (gap confirmed).**
- Command: Read `scripts/validate-pack.py` Check 18 body (L1623-1683: `if line.startswith("## ")` only), registry L11344-11366 (16/18/19 register twice; 18/19 run at pack-root; 16 exempt via `_CHECK_16_EXEMPT_SURFACES={"pack-root"}`), Check 45 L7359 (`corpus_path = REPO_ROOT / "CLAUDE.md"`), Check 66 `_check_66_iter_bullets` per-file + `_CHECK_66_BULLET_SURFACE`, `_CHECK_57_TRINITY_SURFACES` (project-template only).
- Output (verbatim, key lines): Check 18 collects `[line.rstrip() for line in path.read_text().splitlines() if line.startswith("## ")]`; registry `(18, "check_trinity_h2_parity[pack-root]", lambda: check_trinity_h2_parity(REPO_ROOT, "pack-root"), W)`; Check 45 `corpus_path = REPO_ROOT / "CLAUDE.md"`; `_CHECK_57_TRINITY_SURFACES = ("project-template/CLAUDE.md","project-template/AGENTS.md","project-template/GEMINI.md")`.
- HEAD/date: `e8ba9e7` / 2026-06-23.
- Interpretation: Check 18 runs at pack-root but compares H2 headings only; Check 45 uses CLAUDE.md sole corpus; Check 66 is per-file; Check 57 is project-template only. None byte-compare pack-root `## Pack memory` bodies. (Research Ambiguity #2's "16/18/19 are template-only" is wrong — they register twice — but the gap conclusion stands.)
- Conclusion: SUPPORTED — the §7.1/EB-E gap premise holds; no body-parity check exists.

**EB-5 — registry count + the lock-step test literal (what a check would churn / the drop avoids).**
- Command: `sed -n '504p' scripts/validate-pack.py`; runtime `len(_build_check_registry())`; `grep -n "69" scripts/tests/test-validate-pack-check-64.sh`.
- Output (verbatim): `CHECK_REGISTRY_EXPECTED_COUNT = 69`; runtime `CHECK_REGISTRY_EXPECTED_COUNT = 69` / `len(_build_check_registry()) = 69` / `max check number = 71`; test L74 `if mod.CHECK_REGISTRY_EXPECTED_COUNT != 69:` + L82 `(== 69)`.
- HEAD/date: `e8ba9e7` / 2026-06-23.
- Interpretation: the count is 69 (max check num 71); a new check would bump the constant to 70 and require updating the hardcoded `69` in the check-64 test (L74/L82) + a new per-check test. The drop leaves all of these untouched.
- Conclusion: SUPPORTED — the count/test lock-step surfaces are enumerated; dropping the check avoids the churn.

**EB-6 — pack-root trinity is path-disjoint from the client-shipping trinity (cost-of-being-wrong is pack-internal).**
- Command (from RESEARCH (d), re-confirmed): `git ls-files | grep -E "^(CLAUDE|AGENTS|GEMINI)\.md$|^project-template/(CLAUDE|AGENTS|GEMINI)\.md$"`.
- Output (verbatim): `AGENTS.md / CLAUDE.md / GEMINI.md` (pack-root) and `project-template/{CLAUDE,AGENTS,GEMINI}.md` (client-shipping) are distinct paths; Check 18/57 already gate the project-template trinity.
- HEAD/date: `e8ba9e7` / 2026-06-23.
- Interpretation: the pack-root `## Pack memory` surface is pack-OPS, read by agents working on the pack; it is NOT the client deliverable trinity. A drift there degrades pack-internal instruction, not a shipped client file. The task prompt's "drifted rule shipping to clients" framing does not apply to this surface.
- Conclusion: SUPPORTED — the cost-of-being-wrong is pack-internal and recoverable, lowering the necessity case.

**EB-7 — BD-244 re-affirmed parity-is-discipline 3 days ago on the base pipeline, no incident.**
- Command: `grep -iE "Resolved:|Pipeline|adversarial|trinity-parity-is-discipline" backlog/BD-244.md`.
- Output (verbatim): Resolved 2026-06-23; Pipeline `pack-architect → pack-planner (… a trinity-parity-is-discipline correction) → pack-coder → pack-reviewer → fix-coder → post-fix reviewer CLEAN`; ZERO adversarial passes; CI green run 28039394721.
- HEAD/date: `e8ba9e7` / 2026-06-23.
- Interpretation: the most recent pack-memory BD explicitly recorded a deliberate "trinity-parity-is-discipline" ruling and shipped clean on the base pipeline. No recorded body-parity drift incident exists. Re-opening this 3-day-old evidence-based ruling without new adverse evidence is unwarranted.
- Conclusion: SUPPORTED — the discipline is a recent, deliberate, incident-free decision.

---

## 8. Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | **agents-never-commit** | Sole Write = `/tmp/pack-handoff-bd238-arch/DESIGN-BD-238-PARITY-CHECK.md` (Bash heredoc appends). All git read-only: `git rev-parse HEAD` → `e8ba9e7a4d1d3ea33ac3d4320d0aee77bf973381`, `git status --short` → clean, `git ls-files`/grep only. No `add/commit/push/checkout/restore/stash/branch/tag/worktree` or any state-changing verb. No memory store read/written (MEMORY PROHIBITION honored — §0). | COMPLIANT |
| 2 | **no-solutions-beyond-the-premise / honest call** | The verdict is mine on evidence: I ran the measure the reconciled design DECLARED but never RAN (EB-1), and that measurement (23 identical / 3 legitimate-divergent / 0 drift + the infeasible bound EB-3) flipped my call to NOT-NECESSARY — neither rubber-stamping the user's implied lean toward "necessary" nor defaulting to "not necessary" to avoid work. The verdict is grounded in the bound failure + the pack-internal cost + the recent incident-free ruling, not deference. | COMPLIANT |
| 3 | **ci-guard-design-measure-then-bound** | MEASURED the actual ×3 bodies FIRST (§3.1, EB-1); CATEGORIZED every divergence KEEP/STRIP (§3.2 — STRIP set EMPTY, 3 KEEP rules + Claude-only section); attempted to SIZE the allowlist EXACTLY (§3.3 Attempts A/B/C) and PROVED it cannot be bounded cleanly without ADDING discipline surfaces (EB-3: CLI tokens in both divergent + 2 identical rules); recorded what a check would require to demonstrate the disqualifier (§6). The "do-not-ship" verdict carries the same measure-then-bound rigor a "ship" design would. | COMPLIANT |
| 4 | **empirical-evidence-blocks** | §7 carries EB-1…EB-7: every state-claim (the 23/3/1 divergence counts, the slug-keying subtlety, the CLI-token non-separation, the no-body-parity-check gap, the registry count + test literal, the path-disjointness, the BD-244 ruling) backed by command + verbatim output + HEAD `e8ba9e7` + interpretation + SUPPORTED conclusion. | COMPLIANT |
| 5 | **enumerate-encoding-surfaces** | Enumerated ALL count-lock-step surfaces the check WOULD touch (so the verdict is fully informed + the drop's avoided-churn is concrete): `CHECK_REGISTRY_EXPECTED_COUNT` (validate-pack.py L504), `_build_check_registry()` entry, the hardcoded `69` in `test-validate-pack-check-64.sh` L74/L82, a new per-check test — §4 + §6.4 + EB-5. | COMPLIANT |
| 6 | **operating-docs-no-history-no-bloat** | No new operating-doc rule text is proposed (verdict = drop). The ONE planner edit (§5) is a §10.1 disposition change to a reference design doc, not an operating doc; it carries no history/dates. No Check-66-capped surface is added. | COMPLIANT (N/A — no new operating-doc text) |
| 7 | **deferral-is-scope-creep / no-deferral-without-user-direction** | The output is DROP (not defer): §1 + §3 + §5 establish the check is unnecessary work whose correct form is a net complexity loss, so it does not exist — NOT necessary work scheduled to a later BD (which the user banned). No new BD is proposed. The §10.1 "open a tracked follow-up BD" line is explicitly STRUCK (§5). | COMPLIANT |
| 8 | **rules-applied-verification-block** | This table — rules 1-8, each name + quoted evidence + terminal conclusion (no AMBIGUOUS; no empty evidence). | COMPLIANT |

---

*End of DESIGN-BD-238-PARITY-CHECK. Fresh independent pack-architect; verdict NOT NECESSARY — drop the check entirely (not defer); one Write (this doc) under /tmp; read-only git only; no memory store used. The verdict is driven by the measured tree state (23/26 byte-identical, 3 legitimate CLI-normalization divergences, 0 drift), the proven-infeasible clean bound (a correct check ADDS discipline surfaces rather than removing them), the pack-internal non-shipping cost-of-being-wrong, and the recent incident-free parity-is-discipline ruling. The reconciled design body is intact except the one §10.1 disposition edit in §5. Ready for the planner to fold into the single BD-238 plan.*
