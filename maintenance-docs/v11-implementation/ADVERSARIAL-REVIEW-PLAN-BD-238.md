# ADVERSARIAL-REVIEW-PLAN-BD-238 — independent adversarial review of PLAN-BD-238

**Role:** pack-planner (RO), FRESH independent ADVERSARY. I did NOT author PLAN-BD-238, DESIGN-BD-238, DESIGN-BD-238-RECONCILED, or DESIGN-BD-238-PARITY-CHECK. I am not the original planner nor any architect. I re-measured every load-bearing claim from the live tree; I did not defer to the plan's assertions. **BD:** BD-238 (LARGE). **Output:** this review only (sole Write, under `/tmp`). **Next stage:** Pack-Chat triage → [reconciliation planner if NEEDS-REWORK] → user planner-to-coder gate → coder.

---

## 0. Runtime regime (RO; verified)

| Field | Value |
|---|---|
| `pwd` | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` |
| `git rev-parse HEAD` | `e8ba9e7a4d1d3ea33ac3d4320d0aee77bf973381` (= expected `e8ba9e7`) |
| branch | `v11-dev` |
| graph | DISCOVERY queried (`graphify query` against the injected graph path); the propagation/rule-body/check-algorithm granularity is not node-indexed (the graph returns IMPL-REPORTs + migrator tests, not the rule-propagation surfaces) → grep/Read for VERIFICATION (G2 fallback, sanctioned for exact-bytes/algorithm reads). |
| writes | EXACTLY ONE: this review doc. No source edits. Read-only git only. No memory store read/written (user MEMORY PROHIBITION 2026-06-23 honored — my only context is this prompt, the repo, the injected graph). |

I read all four inputs in full (BD-238.md; DESIGN-BD-238-RECONCILED.md L1-485; PLAN-BD-238.md L1-415; DESIGN-BD-238-PARITY-CHECK.md L1-234).

---

## 1. Verdict (lead)

### VERDICT: READY

The plan faithfully sequences the reconciled design and honors the locked parity-check DROP. I independently re-measured every load-bearing claim — the 1289-char body, the placement anchors ×3, the Check 45/46/66 algorithms, the registry count, the CI trigger, the anti-restate cleanliness of both one-liners, the pack-only scope — and ALL hold at the live HEAD. The two parity safeguards are encoded HARD and NAMED. There are **ZERO BLOCKERs and ZERO MAJORs**. The findings below are MINOR/NIT: corrections of over-stated coupling and a few precision gaps that a coder should be told about, none of which break green or misimplement the design.

I actively hunted for: a drifted rule-body char count; a stale or mis-parallel anchor; a false MANDATORY/ELECTIVE split; an anti-restate trap on the new one-liners; a Check-46 reference-resolution obligation the plan under-states; a residual deferral; a Check-36 keyword trap; a missed encoding surface; a manifest push-time mis-claim. Each is addressed below with quoted evidence. The plan survives all of them.

---

## 2. Faithfulness to the reconciled design (re-measured)

### 2.1 Rule body — verbatim + char count (re-measured independently) — FAITHFUL

I extracted the §3.1 canonical body from the plan, replicated `_check_66_iter_bullets` exactly (`joined = " ".join(s.strip() for s in cur); len(joined)`), and measured:

```
num lines in bullet: 18
char_len (whitespace-collapsed): 1289
cap: 1300 -> UNDER
margin: 11
```

The plan's body is **byte-identical to the design §4.1 body** (I diffed the two — same 18 lines, same arrows/em-dashes/`≥`). The char count is **1289 < 1300** (margin 11), confirming plan EB-P3 and design EB-R6. The size-tiering wording (signals + decoupled consequence "launch-gate fires OR ≥2 signals", tightened L4 "a single-clause amend … does NOT mandate them", "When in doubt, LARGE") is the reconciled design's MAJOR-2 wording carried verbatim — **the plan SEQUENCES, it did not redesign.** FAITHFUL.

### 2.2 Placement anchors ×3 — re-measured at live HEAD — CORRECT + byte-parallel

```
=== CLAUDE.md ===  288:- **Researcher-first pipeline …   296:- **Planner output → user review …
=== AGENTS.md ===  277:- **Researcher-first pipeline …   285:- **Planner output → user review …
=== GEMINI.md ===  249:- **Researcher-first pipeline …   257:- **Planner output → user review …
```

I read the surrounding region in all three files: the Researcher-first bullet ends at CLAUDE.md L295 / AGENTS.md L284 / GEMINI.md L256, and the Planner-output bullet opens at L296/L285/L257. The insertion slot (after Researcher-first, before Planner-output) is a clean bullet boundary, byte-parallel ×3 (the Researcher-first bullet is itself byte-identical ×3). The plan's EB-P1 anchors match the live HEAD exactly — NOT stale. CORRECT.

### 2.3 Slug is free; tag format matches convention — CORRECT

`grep -rn "large-bd-pipeline-standard" CLAUDE.md AGENTS.md GEMINI.md pack-ops/` → EMPTY (the slug is unused). The body's tag line `\`[roles: universal] [rationale: large-bd-pipeline-standard]\`` matches the existing convention (CLAUDE.md L202/L207/L320 use the identical `[roles: universal] [rationale: …]` shape). CORRECT.

---

## 3. Propagation split — re-verified against the ACTUAL Check 45 + Check 46 algorithms

This was the adversarial mandate's hardest target. I read the real algorithms and replicated them.

### 3.1 MANDATORY = corpus ×3 + rationale section — CORRECT (Check 45 bidirectional)

`scripts/validate-pack.py:7398-7402`:
```
corpus_set = set(corpus_slugs)            # from CLAUDE.md ## Pack memory only (L7359 corpus_path)
rationale_set = set(rationale_slugs)      # from PACK-MEMORY-RATIONALE.md ## headings
orphan_corpus_slugs = sorted(corpus_set - rationale_set)
orphan_rationale_headings = sorted(rationale_set - corpus_set)
```
Both must be empty (FAIL on either). So a new corpus slug WITHOUT a rationale section ⇒ orphan corpus slug ⇒ FAIL; a rationale section WITHOUT the corpus slug ⇒ orphan rationale heading ⇒ FAIL. Corpus ×3 (Edits 1-3) + rationale section (Edit 4) are genuinely MANDATORY and inseparable. The plan §4.1 is CORRECT. (Note: Check 45 reads the slug from **CLAUDE.md only** — see Finding M-1 below for the parity implication.)

### 3.2 ELECTIVE = manifest record + 2 one-liners — CORRECT; Check 46 does NOT require a record per tagged rule

`grep -c "^slug:" pack-ops/.spawn-rule-manifest.txt` → `7`; `grep -c "^## " pack-ops/PACK-MEMORY-RATIONALE.md` → `29`. The manifest is a curated 7-of-29 subset; Check 46 (`_parse_manifest_records`, L7654-7714) iterates **only records that EXIST** — it never enumerates tagged rules and demands a record per rule. So omitting the manifest record does NOT fail Check 46. The ELECTIVE labeling is CORRECT. Plan §4.1 is faithful to design §5 / EB-R4.

### 3.3 Does including the manifest record ADD a Check-46 reference-resolution obligation that could FAIL? — NO (and this exposes Finding M-2)

The adversarial mandate asked this directly. I read Check 46 (a2) reference-resolution (L7652-7714). For each spawn-manifest record it requires: (i) `canonical:` contains `## Pack memory` (L7676); (ii) the `references:` field names a known surface (`PACK-AGENTS.md` or `PACK-CHAT.md`, L7660-7663); (iii) each named surface **exists** AND **contains the substring `## Pack memory`** (L7704). It does **NOT** check that the new one-liner exists, nor that the surface contains the rule name or slug.

I measured the surfaces:
```
## Pack memory in pack-ops/PACK-AGENTS.md → 7 occurrences (already present)
## Pack memory in pack-ops/PACK-CHAT.md  → 13 occurrences (already present)
```

**Consequence:** the new manifest record's reference-resolution is satisfied by the PRE-EXISTING `## Pack memory` substrings in both surfaces — it does NOT require Edits 6-7 at all. So:
- Including Edit 5 (manifest record) is **SAFE** — it cannot fail reference-resolution (the surfaces already resolve). Answer to the mandate: **NO, the manifest record adds no failing obligation.**
- BUT the plan's claim that Edits 5-7 are an "all-or-nothing bundle" because "Check 46 reference-resolution catches a record naming a missing reference" (§9 risk row; §3.3; §4.1 "only required IF Edit 5 names them") is **technically OVER-STATED** → Finding M-2.

### 3.4 Anti-restate (MAJOR-1 carryover) — re-measured against the 6 surfaces — CORRECT

I replicated `_check_46_extract_pack_memory_imperative_bodies(60)` and the substring scan over `_CHECK_46_ANTI_RESTATE_SURFACES` (verbatim from L7469-7476: PACK-AGENTS.md, PACK-CHAT.md, + the 4 skills; **trinity NOT in the set**):
```
candidate count: 53
PACK-AGENTS one-liner: existing-body windows present? 0 -> CLEAN
PACK-CHAT anchor:      existing-body windows present? 0 -> CLEAN
new rule leading-120 window absent from ALL 6 surfaces (False ×6)
```
Both proposed one-liners (§3.4/§3.5) carry ZERO 60+-char existing-body leading-windows; the new rule's own window does not appear in any scan surface. The plan's retarget (§6.1 step 2, EB-P5) is the CORRECT property — it targets the 6 surfaces + the two new one-liners, NOT a trinity-vs-trinity diff. The MAJOR-1 carryover is sound. CORRECT.

---

## 4. Safeguards — are SAFEGUARD-1/-2 genuinely HARD, NAMED, executable?

### 4.1 SAFEGUARD-1 (byte-parity diff) — HARD, NAMED, method CORRECT

Plan §6.3 encodes it verbatim from design §10.2 as a "NAMED, REQUIRED plan step, not advisory," with the concrete mechanic (§6.3 closing para): extract the bullet block from each file (from the `- **Large-BD pipeline standard` line through the `[rationale: large-bd-pipeline-standard]` line inclusive), write each to `/tmp`, `diff` pairwise, require 0 diff ×3. I verified the extraction anchors are unambiguous: `grep -rn "Large-BD pipeline standard"` → EMPTY (new, no collision); `[rationale: large-bd-pipeline-standard]` is a unique terminus. The method is sound and STRICTER than Check 66 — it strips only trailing whitespace (true byte-parity), so it catches an internal-whitespace divergence (e.g., a 3-space continuation indent in one file) that Check 66's whitespace-collapse would MISS. This is exactly right because the trinity rule requires byte-identity, which no CI check enforces (§4.2 / Finding M-1). HARD + NAMED + CORRECT.

### 4.2 SAFEGUARD-2 (PREFLIGHT ×3 attestation) — HARD, NAMED, gating

Plan §6.4 requires the C1 coder's PREFLIGHT line to carry an explicit ×3-byte-identity attestation, and states "An IMPL-REPORT lacking the ×3-byte-identity attestation is incomplete and is rejected," with the reviewer confirming BOTH safeguards ran. This is a genuine rejection gate, not advisory. HARD + NAMED.

### 4.3 The safeguards are load-bearing because Check 45 reads CLAUDE.md ONLY — Finding M-1

I confirmed Check 45's corpus is `corpus_path = REPO_ROOT / "CLAUDE.md"` (L7359). **Implication the plan states but could state more forcefully:** if the C1 coder edits CLAUDE.md + the rationale section but FORGETS AGENTS.md or GEMINI.md, **Check 45 still PASSES** (it never reads AGENTS/GEMINI slugs), Check 18 still passes (H2-only), and the ONLY thing that catches the omission is Check 66 (per-file — but a MISSING bullet isn't over-cap, so Check 66 is silent too) and SAFEGUARD-1/-2. So a forgotten AGENTS/GEMINI edit would slip ALL CI checks and ship a ×3-asymmetric corpus. This makes SAFEGUARD-1/-2 not merely "the parity protection" but the SOLE protection against an OMITTED trinity copy, not just a DIVERGENT one. The plan's §9 risk row "×3 body drift" frames the risk as drift; it should also name the OMISSION case (a missing copy in one file) explicitly — see Finding M-1.

---

## 5. Commit sequence + rule-10 — re-verified

### 5.1 SERIAL verdict — CORRECT; rationale CORRECT

CI trigger: `.github/workflows/validate-pack.yml:103: on: push` — confirms CI is push-time end-state, NOT per-commit. The plan's §8.2 binding reason (propagation-atomicity + trinity-rule + no-disjoint-concurrency, explicitly NOT a CI-cadence gate) is the corrected MINOR-2 rationale carried faithfully from design §9.2 / EB-R5. SERIAL is the right verdict for a single logical bijection unit with no disjoint-file concurrency. CORRECT.

### 5.2 C1/C2/C3 scoping — CORRECT

- **C1** (the standard) — one serial coder commit; corpus ×3 + rationale (MANDATORY) + electively manifest + 2 refs. CORRECT.
- **C2** (out-of-repo memory reconciliation) — Pack-Chat upkeep, AFTER C1, NOT a coder commit. CORRECT (the planner does not touch memory; the MEMORY PROHIBITION binds the planner, and C2 is the BD's acceptance-criteria work done by Pack-Chat upkeep — design §6 boundary note carried faithfully).
- **C3** (audit-doc move) — paired pack-only coder commit, immediately after C1; move the BD-238 pipeline docs `/tmp` → `maintenance-docs/v11-implementation/`. I verified the target dir EXISTS, there is NO BD-238 filename collision there today, and **no pack-memory check (45/46/66) scans maintenance-docs/** (their surfaces are fixed tuples), so the audit docs — which DO contain the verbatim rule body — cannot trip anti-restate when they land. C3 is safe. CORRECT.

### 5.3 Rule-10 parallelization map — CORRECT (no parallel waves)

The plan produces its own rule-10 map (§8): no multi-disjoint-file concurrency, so no parallel coder waves; one C1 coder commit + one paired C3 doc commit + out-of-repo C2 upkeep. This is the right rule-10 verdict for this BD. CORRECT.

---

## 6. Commit-scope keyword (Check 36) — CORRECT, no trap

The plan §6.6 sets C1 + C3 = `pack-only`. I confirmed the BD-238 edit set is pack-root trinity + `pack-ops/` + `maintenance-docs/` — NO `project-template/`, NO `supporting-docs/`. Check 36 for `pack-only` denies `project-template/` + `supporting-docs/`; the edit set is denied-set-clear. The plan's EB-P8 is accurate.

**Keyword-trap audit (commit-subject keyword-token trap):** I inspected the two proposed subjects:
- C1: `feat: v11 — BD-238 codify large-BD pipeline standard (pack-only)`
- C3: `docs: v11 — BD-238 audit-set preservation → maintenance-docs (pack-only)`

Neither subject contains a DENYING token (`project-template`, `project-only`, `supporting-docs`, `pack-chat-only`). The only scope token present is `pack-only` (the intended claim). NO trap. The plan §6.6 already flags the trap explicitly ("do NOT let a denying token appear in the subject prose"). CORRECT. (NIT-1: the C3 subject contains a literal `→` arrow; harmless for Check 36, but see NIT-1 for a cosmetic note.)

---

## 7. Missed surfaces (enumerate-encoding-surfaces) — none material

I cross-checked the plan's §2.4 "surfaces NOT touched" against the actual check surfaces:
- Check 45 corpus = CLAUDE.md only; Check 46 = 6 fixed surfaces; Check 66 = trinity + project-template + PACK-MEMORY-RATIONALE; Check 18 = H2 lines ×3; Check 64 = registry count.
- The plan correctly identifies: agent defs (grep-zero, 15 parity edits avoided), skills (anti-restate TARGETS — must NOT receive the body), migration docs (out of blast radius), `test-fixtures/manifest.txt` (no fixture input), `scripts/validate-pack.py` + count (parity check DROPPED, count stays 69).

I found NO encoding surface the plan omits. The graph discovery query returned no rule-propagation surface beyond what grep/Read enumerated. enumerate-encoding-surfaces is satisfied.

One half-surface worth a NIT: the manifest comment header (`pack-ops/.spawn-rule-manifest.txt` L1-19) states the manifest records rules whose restatements were **COLLAPSED** to references (BD-196 C5) — i.e. rules that once HAD a restatement. The new umbrella rule was NEVER restated; adding it is a mild semantic stretch of the manifest's stated purpose (it is a NEW reference, not a collapsed one). This does not fail any check (the record resolves), and it is ELECTIVE, but it is a reason to lean toward DROPPING the manifest record specifically — see NIT-2.

---

## 8. Manifest push-time NOOP — CORRECT

Plan §6.5: BD-238 touches NO fixture input (trinity + pack-ops docs only; no `scripts/` change, no agent-def/skill FIXTURE change). `test-fixtures/manifest.txt` is regenerated only at push when a fixture input changed; for BD-238 `manifest-sync.sh` is a NOOP. I confirmed the edit set carries no fixture input. CORRECT — the coder does not touch the manifest.

---

## 9. Findings (each tagged, with evidence + concrete fix)

### MINOR-1 (M-1) — the ×3-OMISSION case is under-named in the safeguard rationale + risk table
**Evidence:** Check 45 corpus = `REPO_ROOT / "CLAUDE.md"` (L7359) — AGENTS/GEMINI slugs are never bijection-checked; Check 18 = H2 lines only; Check 66 = per-file over-cap (silent on a MISSING bullet). A coder who edits CLAUDE.md + rationale but omits the AGENTS.md or GEMINI.md copy passes ALL CI checks; only SAFEGUARD-1/-2 catch it. The plan's §9 risk row frames the unguarded risk as "×3 body **drift**" (divergent copies) but does not explicitly name the "one copy entirely **missing**" failure, which is the more likely coder error and is equally invisible to CI.
**Why it matters:** the reader/coder could believe Check 45 protects trinity completeness (it does not). Making the omission case explicit sharpens why SAFEGUARD-1 must extract from all THREE files and FAIL if any extraction is empty.
**Concrete fix:** in §6.3 SAFEGUARD-1, add one clause: "If the extraction from ANY of the three files is EMPTY (the bullet is absent), that is a FAILURE (a forgotten trinity copy) — HALT; Check 45/18/66 do NOT catch a missing copy." And in the §9 risk table, rename the row to "×3 body drift OR a missing trinity copy" and note Check 45 reads CLAUDE.md only.

### MINOR-2 (M-2) — the "Edits 5-7 are all-or-nothing" coupling is over-stated
**Evidence:** Check 46 (a2) reference-resolution (L7704) requires only that each named reference surface **exists** and **contains `## Pack memory`** (a substring). Both PACK-AGENTS.md (7×) and PACK-CHAT.md (13×) ALREADY contain `## Pack memory` independent of BD-238. So the new manifest record (Edit 5) resolves WITHOUT Edits 6-7. The plan's framing — §3.3 "include all three or none," §4.1 "only required IF Edit 5 names them," §9 risk row "Edits 5-7 are an all-or-nothing ELECTIVE bundle … Check 46 reference-resolution catches a record naming a missing reference" — implies Edit 5 hard-requires Edits 6-7. It does not: Check 46 would pass with Edit 5 alone (record present, surfaces already contain `## Pack memory`, no new one-liner needed).
**Why it matters:** the coupling claim is the plan's stated reason for bundling; it is technically false. The bundle is a DISCOVERABILITY choice, not a CI necessity. (It is a conservative over-statement — the plan ships MORE than required, so it does not break green — but a coder should not be told a false dependency.)
**Concrete fix:** in §3.3 / §4.1 / §9, restate the coupling as: "Edits 6-7 are the human-meaningful payload of Edit 5 (a record pointing at surfaces that don't carry the pointer is misleading though CI-green); include them together for discoverability — but Check 46 reference-resolution does NOT require the one-liners (the surfaces already carry `## Pack memory`). The genuine all-or-nothing reason is editorial coherence, not a CI gate." (Then the include/drop decision is purely editorial.)

### MINOR-3 (M-3) — UTF-8 / Check-66 margin (11 chars) deserves a sharper coder warning
**Evidence:** the body measures 1289/1300 (margin 11). It contains 9 `→`, several `—`, and `≥` as single-codepoint UTF-8 literals. Python `len()` counts each as 1; an ASCII substitution (`→`→`->`, `—`→`--`, `≥`→`>=`) ADDS one char per substitution. Nine arrows alone would push 1289→1298 (still under), but combined with the em-dashes/`≥` an inadvertent global ASCII-ization could exceed 1300 AND break byte-parity. The plan §3.1 authoring discipline does say "copy byte-for-byte; do not ASCII-substitute," and §9 has a UTF-8 risk row — adequate, but the thin 11-char margin is not quantified.
**Why it matters:** an editor/tool that "normalizes" Unicode (a common autoformatter behavior) could silently push over-cap; the SAFEGUARD-1 byte-diff catches the parity break, but the over-cap would surface as a Check-66 FAIL only at validate-pack time.
**Concrete fix:** in §3.1, add: "Margin to the Check-66 cap is only 11 chars — do NOT add words; an autoformatter that ASCII-izes the 9 arrows + dashes + `≥` would both break byte-parity (SAFEGUARD-1 catches) AND risk exceeding 1300 (Check 66 catches). Verify char count = 1289 in PREFLIGHT (SAFEGUARD-2 already attests this)."

### NIT-1 — the C3 commit subject's literal `→` arrow is cosmetic noise
**Evidence:** §5.2 / §8.1 propose `docs: v11 — BD-238 audit-set preservation → maintenance-docs (pack-only)`. The `→` is harmless for Check 36 (it is not a scope token) and for the commit-message format (the approved `docs:` form has no arrow ban), but a plain `to` reads cleaner and avoids any terminal/log rendering oddity.
**Fix (optional):** `docs: v11 — BD-238 audit-set preservation to maintenance-docs (pack-only)`.

### NIT-2 — the manifest record is a mild semantic stretch (lean DROP it specifically)
**Evidence:** `pack-ops/.spawn-rule-manifest.txt` L1-19 states the manifest records rules whose restatements were **COLLAPSED** to one-line references (BD-196 C5). The umbrella rule was never restated; its references are NEW, not collapsed. Adding a record is CI-valid (it resolves) but stretches the manifest's documented purpose.
**Fix (optional):** the plan already makes Edits 5-7 ELECTIVE; given the semantic stretch + M-2 (no CI necessity), the planner/user could lean toward the MINIMAL footprint (Edits 1-4) for the manifest record specifically, while still adding the two one-liners (Edits 6-7) as plain discoverability pointers WITHOUT a manifest record. (Edits 6-7 do not require a manifest record — they are just text; Check 46 anti-restate scans them either way and they pass.) This is a footprint refinement, not a defect.

### NIT-3 — "slug order consistent with the file's existing ordering convention" overstates a convention that does not exist
**Evidence:** `grep -n "^## " pack-ops/PACK-MEMORY-RATIONALE.md` shows the sections are NOT alphabetical (order: `agents-never-commit`, `per-action-approval-sub-agents`, `deferred-work-tracked-anchor`, … `operating-docs-no-history-no-bloat`) — it is thematic/append order. The plan §3.2 says "place it in slug order consistent with the file's existing ordering convention" then correctly notes "any in-file position is Check-45-valid."
**Fix (optional):** drop "in slug order" — say "append the new section in a position consistent with the file's thematic grouping (any position is Check-45-valid; set-equality is order-insensitive)."

---

## 10. What I CONFIRMED accurate (so the coder/user can rely on it)

- Body = 1289 chars < 1300; byte-identical to design §4.1; no allowlist record needed. (replicated Check-66)
- Anchors CLAUDE.md 288/296, AGENTS.md 277/285, GEMINI.md 249/257 — live-current, byte-parallel insertion slot. (read all 3)
- Slug `large-bd-pipeline-standard` is free; tag format matches convention.
- Check 45 is bidirectional ⇒ corpus ×3 + rationale = genuinely MANDATORY + inseparable; manifest + refs = genuinely ELECTIVE (7-of-29 curated). (read algorithm)
- Both one-liners + the new rule window are anti-restate CLEAN against all 6 surfaces. (replicated Check-46 scan)
- SAFEGUARD-1 extraction anchors unambiguous; method stricter than Check-66 (true byte-parity). (verified)
- CI is `on: push` end-state ⇒ SERIAL rationale (propagation-atomicity, not CI cadence) is correct. (read workflow)
- Registry count = 69 (constant + runtime registry); parity check DROPPED, no churn; check-64 `69` literals untouched. (ran the registry)
- pack-only keyword correct for C1+C3; no denying token in either subject; no Check-36 trap.
- maintenance-docs/ is in NO pack-memory check surface ⇒ C3 audit docs (which carry the verbatim body) cannot trip anti-restate. (verified surfaces)
- Manifest push-time NOOP (no fixture input). (verified edit set)
- Parity check DROPPED (not deferred), count stays 69, no follow-up BD — honors the locked decision; no residual deferral anywhere in the plan. (grepped the plan)

---

## 11. Empirical-Evidence Blocks

All measured at HEAD `e8ba9e7a4d1d3ea33ac3d4320d0aee77bf973381`, 2026-06-23, branch `v11-dev`.

**EB-A1 — rule body char count under the exact Check-66 measure.**
- Command: replicate `_check_66_iter_bullets` join (`" ".join(s.strip() for s in cur)`, `len()`) over the plan §3.1 body written to `/tmp/bd238-body.txt`.
- Output (verbatim): `num lines in bullet: 18` / `char_len (whitespace-collapsed): 1289` / `cap: 1300 -> UNDER` / `margin: 11`.
- Interpretation: the canonical body is 1289 chars, 11 under the cap; reproduces plan EB-P3 + design EB-R6; no allowlist record needed.
- Conclusion: SUPPORTED — body is faithful + Check-66-fit; thin margin noted (M-3).

**EB-A2 — placement anchors ×3 at live HEAD + byte-parallel insertion slot.**
- Command: `grep -n "Researcher-first pipeline\|Planner output → user review" CLAUDE.md AGENTS.md GEMINI.md` + Read of L288-302 (CLAUDE), L277-288 (AGENTS), L249-260 (GEMINI).
- Output (verbatim): `CLAUDE.md:288 / :296`, `AGENTS.md:277 / :285`, `GEMINI.md:249 / :257`; Researcher-first bullet byte-identical ×3; slot between them is a clean bullet boundary.
- Interpretation: the plan's EB-P1 anchors match the live HEAD; the insertion is byte-parallel-feasible ×3.
- Conclusion: SUPPORTED — anchors correct, not stale.

**EB-A3 — Check 45 is bidirectional + corpus = CLAUDE.md only.**
- Command: Read `scripts/validate-pack.py` L7359, L7398-7402.
- Output (verbatim): `corpus_path = REPO_ROOT / "CLAUDE.md"`; `orphan_corpus_slugs = sorted(corpus_set - rationale_set)`; `orphan_rationale_headings = sorted(rationale_set - corpus_set)` (both must be empty).
- Interpretation: corpus ×3 + rationale section are MANDATORY + inseparable; AGENTS/GEMINI slugs are NOT bijection-checked ⇒ a missing AGENTS/GEMINI copy passes Check 45 (Finding M-1).
- Conclusion: SUPPORTED — MANDATORY split correct; parity-omission gap is real (M-1).

**EB-A4 — Check 46 reference-resolution requires only surface-exists + `## Pack memory` substring; surfaces already satisfy it.**
- Command: Read `scripts/validate-pack.py` L7652-7714; `grep -c "## Pack memory" pack-ops/PACK-AGENTS.md pack-ops/PACK-CHAT.md`.
- Output (verbatim): L7704 `if "## Pack memory" not in ref_path.read_text(): fail(...)`; PACK-AGENTS.md = `7`, PACK-CHAT.md = `13`.
- Interpretation: the new manifest record resolves via PRE-EXISTING `## Pack memory` substrings — it does NOT require Edits 6-7. Including Edit 5 adds no failing obligation (answers the mandate); the plan's "all-or-nothing" coupling is over-stated (M-2).
- Conclusion: SUPPORTED — manifest-record inclusion safe; coupling claim over-stated (M-2).

**EB-A5 — anti-restate scan: both one-liners + the new rule window are CLEAN against all 6 surfaces.**
- Command: replicate `_check_46_extract_pack_memory_imperative_bodies(60)` (53 candidates) + substring scan of the two §3.4/§3.5 one-liners and the new rule's leading-120 window over `_CHECK_46_ANTI_RESTATE_SURFACES`.
- Output (verbatim): `candidate count: 53`; `PACK-AGENTS one-liner: existing-body windows present? 0 -> CLEAN`; `PACK-CHAT anchor: existing-body windows present? 0 -> CLEAN`; new-rule window in all 6 surfaces `False`.
- Interpretation: the MAJOR-1 retarget is correct; the one-liners are anti-restate-safe; the new rule cannot trip the check (trinity isn't scanned anyway).
- Conclusion: SUPPORTED — anti-restate PASSES post-implementation.

**EB-A6 — CI is push-time end-state (SERIAL rationale).**
- Command: `grep -n "^on:" .github/workflows/validate-pack.yml`.
- Output (verbatim): `103:on: push`.
- Interpretation: CI checks the push end-state, not per-commit; the SERIAL verdict's binding reason (propagation-atomicity + trinity-rule, NOT CI cadence) is correct.
- Conclusion: SUPPORTED — plan §8.2 rationale faithful.

**EB-A7 — registry count = 69; parity check DROPPED; no churn.**
- Command: load `scripts/validate-pack.py` as a module; print `CHECK_REGISTRY_EXPECTED_COUNT` + `len(_build_check_registry())`; `grep -n "69" scripts/tests/test-validate-pack-check-64.sh`.
- Output (verbatim): `CHECK_REGISTRY_EXPECTED_COUNT = 69` / `len(_build_check_registry()) = 69`; check-64 test L74 `!= 69`, L82 `(== 69)`.
- Interpretation: count is 69; no new check; check-64 literals stay untouched; plan EB-P7 accurate.
- Conclusion: SUPPORTED — count stays 69, no lock-step churn.

**EB-A8 — pack-only scope + no Check-36 trap; C3 target exists + collision-free + un-scanned.**
- Command: enumerate the plan's edit set; inspect the two proposed subjects; `ls -d maintenance-docs/v11-implementation/`; `ls maintenance-docs/v11-implementation/ | grep -i 238`; confirm maintenance-docs absent from Check 45/46/66 surfaces.
- Output (verbatim): edit set = pack-root trinity + `pack-ops/*` + `maintenance-docs/v11-implementation/*`, no `project-template/`/`supporting-docs/`; subjects carry only `pack-only` (no denying token); target dir exists; `grep -i 238` → empty; maintenance-docs in NO pack-memory check surface.
- Interpretation: `pack-only` correct for C1+C3; no keyword trap; C3 safe (no collision, the verbatim-body audit docs cannot trip anti-restate).
- Conclusion: SUPPORTED — scope + keyword + C3 all correct.

**EB-A9 — slug free; manifest comment-header purpose is "collapsed restatements" (NIT-2).**
- Command: `grep -rn "large-bd-pipeline-standard" CLAUDE.md AGENTS.md GEMINI.md pack-ops/`; Read `pack-ops/.spawn-rule-manifest.txt` L1-19.
- Output (verbatim): slug grep → EMPTY; header L4-6 "The 6 former restatements … have been collapsed (BD-196 C5) to one-line REFERENCES. This manifest records, for each collapsed rule, its canonical home + the reference surfaces…".
- Interpretation: the slug is free (no collision); the manifest's documented purpose is collapsed restatements, so the new (never-restated) rule's record is a mild semantic stretch — a reason to lean toward dropping the manifest record specifically (NIT-2).
- Conclusion: SUPPORTED — slug free; manifest record stretches purpose (NIT-2, non-blocking).

---

## 12. Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | **agents-never-commit** | Sole Write = `/tmp/pack-handoff-bd238-plan/ADVERSARIAL-REVIEW-PLAN-BD-238.md` (Bash heredoc append). All git read-only: `git rev-parse HEAD` → `e8ba9e7a4d1d3ea33ac3d4320d0aee77bf973381`, `git branch --show-current` → `v11-dev`. No `add/commit/push/checkout/restore/stash/branch/tag/worktree/merge/rebase` or any state-changing verb. No memory store read/written (MEMORY PROHIBITION honored — §0). | COMPLIANT |
| 2 | **reconciliation-instance-independence / fresh-agent-default** | I am a FRESH adversary — not the plan's author, not any architect. I re-measured every load-bearing claim independently (EB-A1…A9: replicated Check-66/45/46 algorithms, ran the registry, read the workflow) rather than deferring to the plan's EBs; I OVERRULED the plan's coupling claim (M-2) on my own measurement (PACK-AGENTS/PACK-CHAT already carry `## Pack memory`) and surfaced a gap the plan under-states (M-1). | COMPLIANT |
| 3 | **empirical-evidence-blocks** | §11 carries EB-A1…EB-A9: every state-claim (char count, anchors, Check 45/46 algorithm behavior, anti-restate cleanliness, CI trigger, registry count, scope, slug, manifest purpose) backed by command + verbatim output + HEAD `e8ba9e7` + interpretation + SUPPORTED conclusion. Each finding (M-1/M-2/M-3/NITs) cites its evidence. | COMPLIANT |
| 4 | **operating-docs-no-history-no-bloat** | I judged the rule text against the cap: 1289 < 1300 (EB-A1, re-measured), terse, ZERO history/dates/provenance (verified the body carries no dated notes / BD-narration). The plan correctly enforces the terse body verbatim. | COMPLIANT |
| 5 | **deferral-is-scope-creep / no-deferral-without-user-direction** | I grepped the plan for residual deferral: all `defer`/`follow-up BD` language is NEGATIVE ("NOT deferred, NO follow-up BD"); the parity check is DROPPED (not deferred), count stays 69; no other deferral introduced. The plan honors the locked DROP decision. | COMPLIANT |
| 6 | **enumerate-encoding-surfaces** | §7: I cross-checked the plan's §2.4 NOT-touched list against the ACTUAL check surfaces (Check 45 corpus = CLAUDE.md; Check 46 = 6 surfaces; Check 66 = trinity+project-template+RATIONALE; Check 18 = H2; Check 64 = count); found NO omitted surface. Graph discovery returned no additional surface. The manifest-purpose stretch (NIT-2) is the only edge, non-material. | COMPLIANT |
| 7 | **rules-applied-verification-block** | This table — rules 1-7, each name + quoted evidence + terminal conclusion (no AMBIGUOUS; no empty evidence). | COMPLIANT |

---

*End of ADVERSARIAL-REVIEW-PLAN-BD-238. Fresh independent adversarial pack-planner; one Write (this review) under /tmp; read-only git only; no memory store used. VERDICT: READY (0 blocking/major). The plan faithfully sequences the reconciled design, honors the locked parity-check DROP (count stays 69), and encodes SAFEGUARD-1/-2 HARD + NAMED. Three MINOR + three NIT findings are precision/coupling refinements, none green-breaking: M-1 (name the ×3-OMISSION case in the safeguard — Check 45 reads CLAUDE.md only), M-2 (the "Edits 5-7 all-or-nothing" coupling is over-stated — Check 46 resolves via pre-existing `## Pack memory` substrings), M-3 (sharpen the 11-char Check-66 margin warning vs UTF-8 ASCII-ization). Ready for Pack-Chat triage → user planner-to-coder gate → coder.*
