# IMPL-REPORT-BD-197 — In-session-correction doc-consistency fixes (S-1, S-2, N-1, N-2, N-3)

**Role:** pack-coder (fresh). **Mode:** doc-consistency edits only (two maintenance docs).
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev.
**HEAD (unchanged — agents never commit):** `05ad61b4ca86a743d27230ec86a8252a55c064d4` (`05ad61b`).
**Date:** 2026-06-14. **Regime:** in-place (against the parent chat's working tree; no isolated worktree).
**PREFLIGHT emitted:** `PREFLIGHT: S-1/S-2/N-1/N-2/N-3 applied; design↔plan consistent; grep checks clean; HEAD 05ad61b…; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-INSESSION-FIX.md`

## Scope

Applied EXACTLY the five fixes from `PACK-REVIEW-BD-197-INSESSION-CORRECTION.md` (S-1, S-2, N-1, N-2, N-3). Edited ONLY the two named docs:
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` (the design)
- `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md` (the plan)

No source, no test, no validator, no commit sequence, no BD entry touched. `backlog/BD-197.md` was already MODIFIED (Note 14) by Pack Chat at session start — I did NOT touch it. The two `??` untracked files (PACK-REVIEW + RESEARCH) are inputs, not my output.

## Read attestation (read in full, no derivation)

- `PACK-REVIEW-BD-197-INSESSION-CORRECTION.md` — full (127 lines; S-1, S-2, N-1, N-2, N-3 with exact locations + the chartered-question verdicts + the independent re-measurement table).
- `ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` §5.3 (292-316), §13.1a (535-539), §16 RAVB (584-616), §18 (876-1178 incl. §18.2 layer-map 1032-1055, §18.4 1077-1111, §18.R 1163-1178), §14 D-NEW-2 (399-401) — read in full at the cited ranges; F1–F5 (896-917).
- `PLAN-BD-197-WORKTREE-ISOLATION.md` — full (488 lines; §A–§K + the two RAVBs); esp. §B C4 (102-113), §B C8b (157-161), §E (218-253), §F EE-1/EE-3/EE-8 (261-330), §I C4/C5 (407-408), §J2/J4/J-resolved (418-449), §K (452-457).
- `backlog/BD-197.md` Note 14 (the user's 2026-06-14 Guard-A′-extension approval — "Guard-A′ extension MANDATED (user-approved 2026-06-14)" — the citation S-1 needs). Read in full (all 14 notes).
- `CLAUDE.md ## Pack memory` — full (from system context): `edit-in-place-not-full-rewrite`, `ci-guard-design-measure-then-bound`, `scope-deliverables-to-the-ask`, `empirical-evidence-blocks`, `agents-never-commit`, `rules-applied-verification-block`, `preflight-stop-means-stop`. Memory file `feedback_edit_in_place_not_full_rewrite.md` read in full.

---

## FIX S-1 — design↔plan mandate contradiction (Guard-A′ `permissions.deny`-token extension)

**Problem:** design §18.4 + §18.R called the extension "optional (P3-architect call), not mandated"; the plan treated it as binding; neither cited the user approval. BD-197 Note 14 now records the 2026-06-14 user approval. **Resolution:** brought the DESIGN up to MANDATED with the Note 14 citation (4 design loci), and grounded the PLAN's binding claim in the Note 14 citation (2 plan loci). The plan was NOT weakened.

**Design loci updated (all now cite "MANDATED (user-approved 2026-06-14; see BD-197 Note 14)"):**

1. **§18.4 "Guard implications" paragraph** (before/after):
   - BEFORE: *"Guard implications: none new. Guard-A′ (C8b) already asserts both OPTIONAL-FEATURES surfaces document `baseRef` + `bgIsolation`; the planner MAY (optional, P3-architect call) extend the bounded presence-check to also assert the `permissions.deny` recipe token … but that is a measure-then-bound decision at guard-author time, **not mandated here** (scope-deliverables-to-the-ask)."*
   - AFTER: *"Guard implications: Guard-A′ (C8b) already asserts … `baseRef` + `bgIsolation`; the bounded presence-check is **MANDATED (user-approved 2026-06-14; see BD-197 Note 14)** to ALSO assert the `permissions.deny` recipe token … (this SUPERSEDES this section's earlier 'optional (P3-architect call)' framing). It remains a measure-then-bound decision at guard-author time …, but the EXTENSION ITSELF is now binding, not an architect's call."*

2. **§18.R RAVB scope-deliverables row** (before/after):
   - BEFORE: *"… the optional Guard-A′ extension is flagged as a P3-architect call, not mandated."*
   - AFTER: *"… the Guard-A′ `permissions.deny`-token extension is MANDATED (user-approved 2026-06-14; see BD-197 Note 14) — sized measure-then-bound to the authored recipe token at C8b commit-time."*

3. **§13.1a Guard A′ "Asserts" + "Asserted tokens" + "Measure" + "Runtime"** — the bounded check (previously sized to "the two settings keys") now asserts THREE tokens (`baseRef` + `bgIsolation` + the `permissions.deny` recipe token):
   - "Asserts" AFTER: *"BOTH OPTIONAL-FEATURES surfaces … DO mention `baseRef` AND `bgIsolation` AND the `permissions.deny` recipe token … The `permissions.deny`-token assertion is **MANDATED (user-approved 2026-06-14; see BD-197 Note 14; §18.4)**, not an optional architect call."*
   - "Asserted tokens" AFTER (sizing): *"all THREE tokens … legitimately appear in each file after P3, and the presence-check is sized to EXACTLY those three (the third token = the exact `permissions.deny` recipe string C5/C8a author, RE-MEASURED at C8b commit-time, NOT a broad pattern) … the bounded presence-check stays sized to the two settings keys + the one recipe token, no broader."* (was: *"sized to the two settings keys"*).
   - "Measure" AFTER: baseline = 0 mentions of any of the three tokens (`baseRef`/`bgIsolation` 0/0 + `permissions.deny` 0/0). "Runtime" AFTER: *"six single-file `rg -c` reads (3 tokens × 2 files)"* (was "two").

4. **§16 RAVB row 5 (ci-guard-design-measure-then-bound)** — updated from "sized to exactly those two settings keys" to the three tokens with the MANDATED + Note 14 citation.

**Plan loci grounded in Note 14 (mandate preserved, citation added):**

- **§B C8b** BEFORE: *"§18.4 made the `permissions.deny`-token assertion an OPTIONAL P3-architect call; the USER APPROVED it, so it is BINDING here."* — AFTER: *"the design's §18.4 originally framed the `permissions.deny`-token assertion as an optional P3-architect call, but the **USER APPROVED extending Guard-A′ on 2026-06-14 (see `backlog/BD-197.md` Note 14)**, so it is BINDING here — and the reconciled design §18.4/§18.R/§13.1a now MANDATE it (design↔plan agree)."*
- **§J2** — appended the citation: *"MANDATED — user-approved 2026-06-14; see `backlog/BD-197.md` Note 14; reconciled design §18.4/§18.R/§13.1a."*

**Verification (design↔plan agree, no live "optional/not-mandated" framing for the extension):**
```
$ grep -rniE "optional.{0,30}p3-architect call|not mandated here" <design> <plan> | grep -iE "permissions.deny|guard-a|recipe token|extend"
  (only hit = plan §B C8b, which is the narrative-of-correction "originally framed … as optional … but USER APPROVED … now MANDATE it" — not a live optional claim)
$ grep -ncF "MANDATED (user-approved 2026-06-14; see BD-197 Note 14)" <design>  → 3 (plus §18.4 line-wrapped variant + §13.1a "; §18.4)" variant = 4 mandate loci total)
$ grep -ncE "Note 14" <plan>  → 2
```

---

## FIX S-2 — shipped-hook inconsistency (the pack does NOT ship a PreToolUse hook or settings file)

**Problem:** design §5.3 + the D-NEW-2 traceability line + plan §B C4 framed a *shipped pack* PreToolUse hook as the in-session mechanical backstop, contradicting §18.2's verified resolution (in-session mechanical hard-deny = documented-optional user `permissions.deny`, NOT shipped; user PreToolUse hook = SECONDARY, fails-open, NOT shipped; pack ships no settings file). **Resolution:** reconciled §5.3 + D-NEW-2 + plan §B C4 / §I C4 / §J4 to §18.2. §18.2's layer-map needed no change (already correct). J4 = NO new shipped pack-side file stays true.

**Design loci updated:**

1. **§5.3 "Mechanical backstop" bullet** — reframed from *"adversarial D-NEW-2 — the load-bearing addition"* with a **Pack-side PreToolUse hook** as the backstop, to **"RECONCILED to §18.2 — the in-session backstop model"**:
   - Pack-side (in-session): (i) shipped PROSE deny-list; (ii) the in-session MECHANICAL hard-deny is the **documented-OPTIONAL user-configured `permissions.deny` recipe** (documented in OPTIONAL-FEATURES; *"the pack does NOT ship it"*); (iii) a user-configured **PreToolUse hook is SECONDARY** (fails-open F2), *"and like `permissions.deny`, the hook is NOT shipped by the pack (the user adds it)"*. *"No new shipped pack-side file (§18.2 EB-D; Check-47 … frozen)."*
   - Project-side (LAUNCHER, layer iii): the `agent-run.sh --disallowedTools` extension *"covers the `claude --agent` launcher path ONLY (NOT the in-session Agent-tool path, which is layer ii)"*. Adversarial-§7 reconciliation nuance preserved.

2. **§14 D-NEW-2 traceability line** BEFORE: *"folded verb-hardening also lands in `agent-run.sh --disallowedTools` (project) + a pack PreToolUse hook …"* — AFTER: *"D-NEW-2 (RECONCILED to §18.2, 2026-06-14): … (in-session, both surfaces) the documented-OPTIONAL user `permissions.deny` recipe (NOT shipped; a user-configured PreToolUse hook is SECONDARY/fails-open, also NOT shipped) … The pack ships NO PreToolUse hook and NO settings file (J4 = NO; §18.2 EB-D)."*

**Plan loci updated:**

- **§B C4 mechanical-backstop bullet** BEFORE: *"a pack-side PreToolUse hook (or `--disallowedTools` …) for spawned agents …"* (framing a pack hook as the C4 backstop) — AFTER: *"Mechanical backstop (RECONCILED to design §18.2 …; J4 = NO new shipped pack-side file). The C4 pack-side IN-SESSION backstop is: (i) the always-on shipped PROSE deny-list … + (ii) documented-OPTIONAL user `permissions.deny` … the pack ships NO settings file + (iii) a user-configured PreToolUse hook is SECONDARY (fails-open, F2) — also NOT shipped … The pack ships NO PreToolUse hook and NO settings file for the in-session path (§18.2 EB-D). … The LAUNCHER mechanical layer (layer iii) is the project `agent-run.sh --disallowedTools` extension, which lands project-side in C7a — NOT a pack-side file."* The decision-5 NEW-pack-side-script GATE is retained as a safety net, now annotated *"per §18.2 the F1–F5 model needs NO new pack-side file (J4 = NO), so this gate is expected to resolve as NO-new-file."*
- **§I C4 rules-in-force row** — inserted the §18.2 backstop framing: *"in-session backstop per §18.2 (pack ships NO PreToolUse hook, NO settings file): (i) shipped PROSE deny-list + (ii) documented-OPTIONAL user `permissions.deny` [C5, NOT shipped] + (iii) SECONDARY user PreToolUse hook [fails-open, NOT shipped]; the launcher `--disallowedTools` layer is project-side C7a, not pack-side."* The NEW-pack-side-script GATE clause annotated with "per §18.2 the F1–F5 model needs NO new pack-side file (J4 = NO)."
- **§J4** — reframed: *"Per design §18.2 (EB-D), the in-session backstop is 'shipped PROSE deny-list + documented-OPTIONAL user `permissions.deny` recipe' — the pack ships NO PreToolUse hook and NO settings file, and the F1–F5 model needs NO new pack-side file (J4 = NO; Check-47 untouched). … The gate is RETAINED as a safety net …"*

**Verification (no live claim the pack SHIPS a hook/settings file; J4=NO preserved):**
```
$ grep -rniE "pack(-side)? PreToolUse hook" <design> <plan> | grep -viE "NOT shipped|secondary|fails-open|user-configured|user adds|J4|no new pack"
  CLEAN — every pack PreToolUse hook mention is framed NOT-shipped / secondary
$ grep -cE "J4 = NO|J4=NO|J4 stays NO" <design> <plan>  → design 9, plan 12 (preserved)
```
§18.2 layer-map (design lines 1034-1038) inspected — already consistent (in-session path mechanical layer = `permissions.deny` optional; launcher = `--disallowedTools`; hook secondary) — NO change needed.

---

## FIX N-1 — plan §F EE-3 stale HEAD (re-measured live; 0 active non-process carriers remain)

**Problem:** EE-3 was measured at the pre-C1 HEAD `ae3d932` and named 3 active non-process EXCISE targets; C1 (landed, 220b6c7) excised all 3.

**Re-measure (command + verbatim output):**
```
$ rg -l 'feedback_worktree_isolation_broken_from_v11_clone' -g '!.git'   # HEAD 05ad61b, 2026-06-14
  → 15 total = 4 archive + 11 active, ALL BD-197-process/allowlist:
    ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md, ARCHITECTURE-BD-197-WORKTREE-ISOLATION.md,
    ARCHITECTURE-BD-197-ADVERSARIAL-REVIEW.md, ARCHITECTURE-BD-197-ADVERSARIAL-REVIEW-2.md,
    RESEARCH-BD-197-P1-WORKTREE-ISOLATION.md, PLAN-BD-197-WORKTREE-ISOLATION.md,
    PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-2.md, PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-3.md,
    IMPL-REPORT-BD-197-C1.md, PACK-REVIEW-BD-197-C1.md, backlog/BD-197.md  (+ 4 archive: PLAN-CLEANUP-BATCH-19B,
    IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-6, ARCHITECTURE-CLEANUP-BATCH-19B, -19B-V2)

$ for f in ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md RESEARCH-19C-G-ITEMS-VERIFICATIONS.md RESEARCH-CLAUDE-REPOS-SURVEY.md; do ...; done
  → all three = 0 matches (the 3 SECOND-pass EXCISE targets are ABSENT — C1 excised them)
```
HEAD/date of measurement: `05ad61b` / 2026-06-14.

**Edit:** EE-3 rewritten (command, output, HEAD, interpretation, conclusion) to the post-C1 state. New conclusion: *"0 active non-process EXCISE targets remain at `05ad61b` (C1 done); the SECOND-pass '3 EXCISE targets' figure is SUPERSEDED by this measured 0. No C1 action remains; this block is now an audit-honest record of the post-C1 state."*

---

## FIX N-2 — plan §F EE-8 line drift (re-located by SYMBOL/string)

**Problem:** EE-8 cited drifted line numbers (`.claude:37`/`.codex.toml:21`/`.gemini:39`). Immaterial — the coder re-locates by symbol.

**Re-measure:**
```
$ grep -c 'checkout -- <path>' .claude/agents/pack-coder.md .codex/agents/pack-coder.toml .gemini/agents/pack-coder.md
  .claude/agents/pack-coder.md:1   .codex/agents/pack-coder.toml:1   .gemini/agents/pack-coder.md:1   (total = 3)
```
**Edit:** EE-8 retitled *"located by SYMBOL/string; line numbers illustrative"*; command changed to `grep -c` with the by-string locator; output references each site by the carve-out STRING + the Codex mid-sentence-embedding note; illustrative line numbers labeled *"drift expected; NOT anchors"*; interpretation/conclusion state the coder re-locates by the STRING at commit-time and PREFLIGHT-greps `checkout -- <path>` == 0.

---

## FIX N-3 — budget 186 → 202 (live runtime-guard lines)

**Problem:** runtime-guard budget prose still cited the battery as 186.

**Re-measure (command + verbatim output):**
```
$ grep -rcE 'validate-pack\.py' scripts/tests/*.sh | awk -F: '{s+=$2} END{print s}'   # HEAD 05ad61b, 2026-06-14
  → 202
```
**Edits — 7 live budget lines updated 186 → 202** (each with a `[re-measured at 05ad61b, §F EE-1; was 186 at the 2nd pass]` note where it reads as a current budget):
- §B C3 budget (line 98), §B C5 budget (line 118), §E intro "battery runs validate-pack 202×" (line 220), §E C0-runtime "across the 202" (line 227), §I C0 row "across 202 invocations" (line 403), §I C5 row "×202 budget" (line 408), §J-resolved-10 (line 429). Plus §J-resolved-14 (line 434) — its stale "already budgeted at 186" updated to 202 while preserving the historical "battery-vs-design-~155 delta" record.

**LEFT (correct historical-progression mentions — per the ask):** attestation lines ("battery 202 (was 186)", SECOND-pass "battery=186"), §F THIRD-pass header "battery 186 → 202", EE-1 "was 186"/"186 → 202", §K HEAD-ADVANCED "was 186", §16-RAVB row 2 "was 186", PLAN-READY "186 → 202".

**Verification:**
```
$ grep -nE "186" <plan> | grep -ivE "was 186|186 → 202|battery=186|2nd pass|SECOND" | grep -iE "186"
  → (no non-historical 186 budget lines remain)
$ 8 budget/runtime lines now cite 202
```

---

## Empirical-Evidence Block (the two re-measures backing N-1 + N-3)

**EB-1 — EE-3 dangling-ref active non-process carriers.**
- Command: `rg -l 'feedback_worktree_isolation_broken_from_v11_clone' -g '!.git'`
- Output: 15 files (4 archive + 11 active, all BD-197-process/allowlist); the 3 SECOND-pass EXCISE targets (`ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`, `RESEARCH-19C-G-ITEMS-VERIFICATIONS.md`, `RESEARCH-CLAUDE-REPOS-SURVEY.md`) each return 0 matches.
- HEAD/date: `05ad61b` / 2026-06-14.
- Interpretation: C1 excised all 3 active non-process carriers; 0 remain. Conclusion: **SUPPORTED.**

**EB-2 — validate-pack battery invocation count.**
- Command: `grep -rcE 'validate-pack\.py' scripts/tests/*.sh | awk -F: '{s+=$2} END{print s}'`
- Output: `202`. HEAD/date: `05ad61b` / 2026-06-14.
- Interpretation: the battery invokes validate-pack 202× (was 186 at the 2nd pass at `ae3d932`). Conclusion: **SUPPORTED.**

---

## Section-map-intact confirmation (edit-in-place)

```
$ grep -nE "^## [0-9]+\.|^## 18\." <design>
  §0 Executive summary … §1 … §2 … §3 … §4 … §5 Git-permission contract … §6 … §7 … §8 …
  §9 … §10 … §11 … §12 … §13 New validators/CI guards … §14 … §15 … §16 RAVB … §17 Check-36 carve-out … §18 In-session spawn symmetry  — §0–§18 ALL present, in order.
$ grep -nE "^## " <plan>
  attestation, A, B, C, D, E, F, G, H, I, J, K, Rules-Applied Verification Block — §A–§K ALL present, in unchanged order.
```
- Design net line delta: 1181 → 1185 (+4) — surgical S-1/S-2 prose, no section dropped.
- Plan net line delta: 488 → 487 (−1) — surgical EE-3/EE-8 rewrites + budget tokens, no section dropped.
- Each edit was a targeted `old_string→new_string` replacement (Edit tool, unique-match). No wholesale rewrite. Re-read of each edited region confirmed the surrounding section text intact.
- NOTE on `git diff --stat` inflation: the design file was already MODIFIED (uncommitted §18 + §2.1-scrub from the prior scope-correction pass) at session start, so `git diff` vs HEAD shows the whole §18 block (`@@ -875,0 +876,308 @@`) + the §2.1 lines 145/147 as part of the uncommitted delta — those are PRIOR-PASS work, NOT my edits. My edits are the 7 design hunks at 145(no)/308/401/536/609 + the in-§18 mandate edits (1107 §18.4, 1177 §18.R) and the plan hunks; the net +4 / −1 line deltas confirm no content explosion.

## Design↔plan agreement confirmation

- **Guard-A′ mandate:** design (§18.4, §18.R, §13.1a, §16-RAVB) and plan (§B C8b, §J2) now BOTH state the `permissions.deny`-token extension is MANDATED (user-approved 2026-06-14; BD-197 Note 14). No live "optional/not-mandated" framing for the extension remains in either doc.
- **No-shipped-hook framing:** design (§5.3, §14 D-NEW-2, §18.2) and plan (§B C4, §I C4, §J4) now BOTH state the pack ships NO PreToolUse hook and NO settings file; the in-session mechanical layer = documented-optional user `permissions.deny`; the user PreToolUse hook is SECONDARY/fails-open/not-shipped; the launcher `--disallowedTools` is project-side (C7a). J4 = NO new shipped pack-side file preserved (design 9×, plan 12×).

## Verification commands + results

| Check | Command | Result |
|---|---|---|
| validate-pack (all checks, incl. Check 43 doc-ref integrity) | `python3 scripts/validate-pack.py` | exit `0` — "PASSED — all checks clean" |
| validate-pack deep | `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | exit `0` — "PASSED — all checks clean" |
| EE-3 re-measure | `rg -l 'feedback_worktree_isolation_broken_from_v11_clone' -g '!.git'` | 0 active non-process carriers (3 targets absent) |
| Battery count | `grep -rcE 'validate-pack\.py' scripts/tests/*.sh \| awk -F: '{s+=$2} END{print s}'` | `202` |
| Carve-out sites | `grep -c 'checkout -- <path>' …pack-coder.{md,toml,md}` | 3 (one per file) |
| S-1 live-optional check | grep for "optional P3-architect"/"not mandated here" re the extension | only the plan's narrative-of-correction; no live optional claim |
| S-2 shipped-hook check | grep for "pack PreToolUse hook" not framed not-shipped/secondary | CLEAN |
| Scope | `git diff --name-only <design> <plan>` | exactly the 2 target docs |

## Plan deviations

ZERO. The five fixes were applied exactly as specified. No scope creep. S-1 brought the design up to MANDATED (did not weaken the plan); S-2 reconciled §5.3 + plan C4 to §18.2 (kept J4=NO); N-1/N-2/N-3 are the measured corrections requested.

## New POQs introduced

None.

## Surfaced (not fixed) — out of scope

- The design's `git diff --stat` shows the uncommitted §18 + §2.1-scrub block from the PRIOR scope-correction pass (the design file was MODIFIED at session start). This is expected pre-existing work the orchestrator commits as part of the scope-correction bundle — NOT introduced by this fix pass. Noted for the orchestrator's commit-staging awareness; no action by me.
- No other issues observed.

## Definition-of-Done checklist

| Item | Status |
|---|---|
| S-1: design §18.4 + §18.R + §13.1a + §16-RAVB say MANDATED + cite Note 14 | PASS |
| S-1: plan binding claim grounded in Note 14 (not weakened) | PASS |
| S-1: design↔plan agree on the Guard-A′ mandate | PASS |
| S-1: §13.1a bounded check sized to the 3 tokens (measure-then-bound; third = authored recipe, re-measured at C8b) | PASS |
| S-2: design §5.3 + D-NEW-2 reconciled to §18.2 (hook secondary/not-shipped; permissions.deny = in-session mechanical) | PASS |
| S-2: plan §B C4 / §I C4 / §J4 reconciled; no framing implies pack ships a hook/settings file | PASS |
| S-2: J4 = NO new shipped pack-side file stays true | PASS |
| S-2: §18.2 layer-map consistent (no change needed) | PASS |
| N-1: EE-3 re-measured live; 0 active non-process carriers; command+output quoted | PASS |
| N-2: EE-8 references sites by SYMBOL/string; line numbers labeled illustrative | PASS |
| N-3: 186→202 on live budget lines; historical "was 186/186→202" preserved | PASS |
| edit-in-place: targeted edits, section maps (§0–§18 / §A–§K) intact, no rewrite | PASS |
| scope: only the 2 target docs edited; nothing else | PASS |
| validate-pack (+ deep) exit 0 | PASS |
| agents-never-commit: no state-changing git verb; HEAD unchanged | PASS |
| PREFLIGHT line emitted before this report | PASS |

## Files changed inventory

| Path | Change type |
|---|---|
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` | modified (S-1: §18.4, §18.R, §13.1a×3, §16-RAVB; S-2: §5.3, §14 D-NEW-2) |
| `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md` | modified (S-1: §B C8b, §J2; S-2: §B C4, §I C4, §J4; N-1: §F EE-3; N-2: §F EE-8; N-3: 7 budget lines + §J-resolved-14) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-INSESSION-FIX.md` | new (this report) |

(`backlog/BD-197.md` was MODIFIED by Pack Chat before this session — NOT touched by me.)

---

## Rules-Applied Verification Block

| Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| edit-in-place-not-full-rewrite [universal] | All edits were targeted `old_string→new_string` Edit-tool replacements (unique-match). Section maps re-counted post-edit: `grep -nE "^## [0-9]+\.\|^## 18\." <design>` → §0–§18 all present, in order; `grep -nE "^## " <plan>` → attestation + §A–§K + Rules-Applied, unchanged order. Net line delta: design 1181→1185 (+4), plan 488→487 (−1) — surgical, no section dropped. | COMPLIANT |
| empirical-evidence-blocks [coder] | EE-3 re-measure: `rg -l 'feedback_worktree_isolation_broken_from_v11_clone' -g '!.git'` → 15 (4 archive + 11 process/allowlist; 3 targets = 0); HEAD `05ad61b`, 2026-06-14; SUPPORTED. Battery: `grep -rcE 'validate-pack\.py' scripts/tests/*.sh \| awk -F: '{s+=$2} END{print s}'` → `202`; HEAD `05ad61b`, 2026-06-14; SUPPORTED. Both embedded as EB-1/EB-2 above with command + verbatim output + HEAD-SHA + date + interpretation + conclusion. | COMPLIANT |
| ci-guard-design-measure-then-bound [coder] | S-1: design §13.1a + §18.4 + §16-RAVB now state Guard-A′'s extension is MANDATED AND sized measure-then-bound — the third asserted token = the EXACT `permissions.deny` recipe string C5/C8a author, RE-MEASURED at C8b commit-time, not a broad pattern; baseline measured 0/0 (§F EE-12). Consistent with the plan §B C8b / §E Guard-A′ step 3 / §J2. | COMPLIANT |
| scope-deliverables-to-the-ask [universal] | `git diff --name-only` = exactly `ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` + `PLAN-BD-197-WORKTREE-ISOLATION.md`. Only S-1/S-2/N-1/N-2/N-3 applied; the `git diff --stat` §18/§2.1 inflation surfaced (not fixed) as pre-existing prior-pass work. No source/test/BD/commit-sequence touched. | COMPLIANT |
| preflight-stop-means-stop [universal] | Emitted the single PREFLIGHT line — `PREFLIGHT: S-1/S-2/N-1/N-2/N-3 applied; design↔plan consistent; grep checks clean; HEAD 05ad61b…; about to Write IMPL-REPORT to …` — only AFTER all edits + re-greps + validate-pack (+ deep) passed exit 0. No parent stop/halt received. | COMPLIANT |
| agents-never-commit [universal] | Ran only read-only git (`git rev-parse`, `git status`, `git diff`) + read-only `rg`/`grep`/`python3 validate-pack.py`; writes were two Edit-target docs + this IMPL-REPORT. NO `git add`/`commit`/`push`/etc. HEAD unchanged: `05ad61b4ca86a743d27230ec86a8252a55c064d4`. | COMPLIANT |
| rules-applied-verification-block [universal] | This block; every row carries quoted/measured evidence; no empty cell; no AMBIGUOUS terminal state. | COMPLIANT |

---

*End of IMPL-REPORT-BD-197-INSESSION-FIX.md — S-1/S-2/N-1/N-2/N-3 applied; design↔plan agree on the Guard-A′ mandate (MANDATED, BD-197 Note 14) + the no-shipped-hook framing (J4=NO); section maps intact; validate-pack (+ deep) exit 0; HEAD unchanged (agents never commit).*
