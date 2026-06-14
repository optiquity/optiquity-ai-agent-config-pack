# PACK-REVIEW-BD-197 — In-session-correction doc-consistency fixes (S-1, S-2, N-1, N-2, N-3) — fresh focused verification

**Role:** pack-reviewer (fresh, focused; read-only on the codebase — this report is the sole write).
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev · **HEAD:** `05ad61b4ca86a743d27230ec86a8252a55c064d4` (`05ad61b`).
**Date:** 2026-06-14. **Scope:** independently verify the five fixes (S-1, S-2, N-1, N-2, N-3) landed correctly, design↔plan AGREE, and no collateral change — BEFORE the scope-correction bundle is committed. Re-ran every measurement; did NOT trust the coder's IMPL-REPORT.

---

## VERDICT: APPROVE

All five fixes landed correctly and surgically; the design and plan now AGREE on both the Guard-A′ mandate (MANDATED, BD-197 Note 14) and the no-shipped-hook backstop model (J4 = NO); BD-197 Note 14 exists and records the 2026-06-14 user approval; the three numeric re-measures match (dangling-ref 0 active non-process EXCISE targets, battery 202, carve-out 3 sites); collateral is exactly the 3 modified tracked files (design + plan + Pack-Chat's Note 14) + 3 untracked input artifacts; commit sequence C0–C8b is unchanged; validate-pack + DEEP exit 0; section maps intact (§0–§18 / §A–§K).

---

## Read attestation (read in full / at the cited ranges, no derivation)

- `PACK-REVIEW-BD-197-INSESSION-CORRECTION.md` — full (127 lines; the 5 findings being fixed + chartered-question verdicts).
- `IMPL-REPORT-BD-197-INSESSION-FIX.md` — full (258 lines; coder claims; NOT trusted — re-ran).
- `ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` — §5.3 (270–316), §13.1a (526–540), §14 D-NEW-2 (551–572), §16 RAVB Block C (584–614), §18.2 layer-map (1020–1055), §18.3 (1057–1075), §18.4 (1077–1115), §18.E (1117–1165), §18.R (1167–1180); section-header map (full).
- `PLAN-BD-197-WORKTREE-ISOLATION.md` — §A (16–49), §B C4/C5/C8b (100–119), §E Guard-A′ (230–256), §F EE-1/EE-3/EE-8/EE-11/EE-12 (257–345), §H (371–396 spot), §I C4/C5/C8b (397–415), §J (418–449), §K (452–457); section-header map (full).
- `backlog/BD-197.md` — full (57 lines; Note 14 confirmed present + its git diff).
- `CLAUDE.md ## Pack memory` — full (system context).

---

## Per-fix re-verification (command + verbatim output + HEAD + date)

### S-1 — design↔plan mandate AGREEMENT (Guard-A′ `permissions.deny`-token extension). PASS.

**BD-197 Note 14 exists and records the approval** (`backlog/BD-197.md:56`, verbatim): *"**Guard-A′ extension MANDATED (user-approved 2026-06-14):** the user approved extending Guard-A′ (Check 54, C8b) to ALSO assert the `permissions.deny` recipe token in BOTH OPTIONAL-FEATURES files (in addition to `baseRef`+`bgIsolation`) — this SUPERSEDES the design's earlier 'optional (P3-architect call)' framing; it is now a mandated C8b deliverable."* The Note 14 line is the ONLY change in the BD-197.md diff (single `+` line, Pack-Chat-added — coder did NOT touch it).

**Design now MANDATES it with the Note 14 citation at 4 loci** (`grep -ncF "user-approved 2026-06-14"` design = `4`):
- §18.4 (1107–1108): *"the bounded presence-check is **MANDATED (user-approved 2026-06-14; see BD-197 Note 14)** to ALSO assert the `permissions.deny` recipe token … this SUPERSEDES this section's earlier 'optional (P3-architect call)' framing … the EXTENSION ITSELF is now binding, not an architect's call."*
- §18.R RAVB scope-deliverables row (1177): *"the Guard-A′ `permissions.deny`-token extension is MANDATED (user-approved 2026-06-14; see BD-197 Note 14) — sized measure-then-bound to the authored recipe token at C8b."*
- §13.1a (536): *"The `permissions.deny`-token assertion is **MANDATED (user-approved 2026-06-14; see BD-197 Note 14; §18.4)**, not an optional architect call."* + the bounded check resized to THREE tokens (537).
- §16 RAVB Block C row 5 (609): the ci-guard row now cites the MANDATED three-token check + Note 14.

**Plan still treats it BINDING + cites Note 14 (NOT weakened):** §B C8b (158) — *"the design's §18.4 originally framed the `permissions.deny`-token assertion as an optional P3-architect call, but the **USER APPROVED extending Guard-A′ on 2026-06-14 (see `backlog/BD-197.md` Note 14)**, so it is BINDING here — and the reconciled design §18.4/§18.R/§13.1a now MANDATE it (design↔plan agree)."* §J2 (442) — *"MANDATED — user-approved 2026-06-14; see `backlog/BD-197.md` Note 14; reconciled design §18.4/§18.R/§13.1a."* Plan `Note 14` refs = 2 (§B C8b, §J2). Downstream three-token consistency holds across §E step 3 (240), §F EE-12 (343), §H (390), §I C8b (414), RAVB row 6 (472).

**No live "optional/not-mandated" framing for the EXTENSION remains.**
```
$ grep -rniE "optional.{0,40}p3-architect call|not mandated here" <design> <plan> | grep -iE "permissions.deny|guard-a|recipe token|extend"
  → exactly 1 hit: PLAN §B C8b line 158 — the narrative-of-correction ("originally framed … as optional … but USER APPROVED … now MANDATE it")
$ grep -niE "guard-a.{0,60}optional|optional.{0,60}guard-a" <design>
  → 0 live-optional hits (only the §18-pass "sections touched" summary + the MANDATED supersession narrative)
```
The single hit is the legitimate supersession narrative, NOT a live optional claim. **Design↔plan AGREE; the contradiction the correction review flagged (S-1) is resolved.** The mandate is sized measure-then-bound (third token = the exact recipe string C5/C8a author, re-measured at C8b) — `ci-guard-design-measure-then-bound` honored.

> Distinction confirmed correct: the §18.2 layer-map column header "(ii) `permissions.deny` (optional)" (1034) correctly describes the *backstop LAYER* as documented-optional/user-configured (not shipped). That is a DIFFERENT axis from the Guard-A′ *EXTENSION* being mandated (the guard asserts the recipe is DOCUMENTED). No conflict — the layer stays user-optional while the doc-presence guard is mandated.

### S-2 — no-shipped-hook reconciliation (§5.3 + §14 D-NEW-2 + plan C4 ↔ §18.2). PASS.

Design §5.3 (308) now reads *"RECONCILED to §18.2 … The pack ships NO settings file and NO new pack-side file (J4 = NO; §18.2 EB-D), so the IN-SESSION mechanical layer is NOT a shipped pack PreToolUse hook"*; layer (ii) = documented-OPTIONAL user `permissions.deny`; the PreToolUse hook is SECONDARY/fails-open and *"also NOT shipped by the pack."* §14 D-NEW-2 (401): *"The pack ships NO PreToolUse hook and NO settings file (J4 = NO; §18.2 EB-D)."*

Plan §B C4 (110), §I C4 (407), §J4 (446) all reconciled: the C4 in-session backstop = (i) shipped PROSE + (ii) documented-OPTIONAL user `permissions.deny` (NOT shipped) + (iii) SECONDARY user PreToolUse hook (fails-open, NOT shipped); launcher `--disallowedTools` is project-side C7a. J4 = NO new shipped pack-side file retained.

```
$ grep -rniE "pack(-side)? PreToolUse hook" <design> <plan> | grep -viE "NOT shipped|secondary|fails-open|user-configured|user adds|J4|no new pack|does NOT ship|never ship"
  → empty (every pack-hook mention is framed not-shipped / secondary)
$ grep -cE "J4 = NO|J4=NO|J4 stays NO" <design>  → 9 ;  <plan>  → 12
```
§18.2 layer-map (1034–1038) unchanged (already correct: in-session mechanical = `permissions.deny` optional; launcher = `--disallowedTools`; hook secondary). **J4 = NO preserved; Check-47 `_SANCTIONED_PACK_SIDE_SHIPPED` untouched** (independently confirmed at `validate-pack.py:4460–4463` = exactly `("scripts/lib/detect.sh", "scripts/pack-help.sh")`). No framing implies the pack SHIPS a hook/settings file.

### N-1 — plan §F EE-3 re-measured to current state. PASS.

```
$ rg -l 'feedback_worktree_isolation_broken_from_v11_clone' -g '!.git'   # HEAD 05ad61b, 2026-06-14
  → 16 files, ALL BD-197-process/allowlist (12 active + 4 archive); incl. the coder's own new IMPL-REPORT-BD-197-INSESSION-FIX.md and this report's predecessor docs
$ per-target: ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md=0  RESEARCH-19C-G-ITEMS-VERIFICATIONS.md=0  RESEARCH-CLAUDE-REPOS-SURVEY.md=0
```
EE-3 (276–281) is rewritten to the post-C1 state with command + output + HEAD `05ad61b` + date + interpretation + conclusion *"0 active non-process EXCISE targets remain at `05ad61b` (C1 done) … the SECOND-pass '3 EXCISE targets' figure is SUPERSEDED by this measured 0."* **The load-bearing claim (0 active non-process EXCISE targets) is verified** — all 3 named targets are absent; every carrier is a BD-197-process/allowlist doc. (My total is 16 vs EE-3's stated "15 = 4 archive + 11 active" — benign +1 drift: the coder's own IMPL-REPORT joined the token set after the coder measured. Expected per the re-measure-at-commit mandate; not a defect in the fix.)

### N-2 — plan §F EE-8 located by SYMBOL/string, not line numbers. PASS.

```
$ grep -c 'checkout -- <path>' .claude/agents/pack-coder.md .codex/agents/pack-coder.toml .gemini/agents/pack-coder.md   # 05ad61b
  → .claude/agents/pack-coder.md:1  .codex/agents/pack-coder.toml:1  .gemini/agents/pack-coder.md:1   (total 3)
```
EE-8 (311–316) retitled *"located by SYMBOL/string; line numbers illustrative"*; the command + interpretation say the coder re-locates each site by the `git checkout -- <path>` STRING and PREFLIGHT-greps `== 0`; illustrative line numbers are labelled *"drift expected; NOT anchors."* The Codex mid-sentence-embedding nuance (M-2 prose-coherence) is preserved. **By-symbol locator confirmed; 3 sites confirmed.**

### N-3 — budget lines 186 → 202; historical mentions preserved. PASS.

```
$ grep -rcE 'validate-pack\.py' scripts/tests/*.sh | awk -F: '{s+=$2} END{print s}'   # 05ad61b, 2026-06-14
  → 202
$ grep -nE "186" <plan> | grep -ivE "was 186|186 → 202|battery=186|2nd pass|SECOND|design-~155|already budgeted at 186"
  → empty (no live 186 budget claim remains)
```
Live budget/runtime lines cite 202: §E (220 "battery runs validate-pack 202×"), §I C0 (403), §I C5 (408), §J-resolved-10 (429), §J-resolved-14 (434). Historical-progression "186" mentions are all preserved as such (attestation lines 10/12, EE-1 265/266 "186 → 202", §F header 259, §16-RAVB 468 "was 186", §15 PLAN-READY 485). **186 → 202 applied to live lines; history intact.**

---

## Collateral / scope (PASS)

```
$ git status --short
 M backlog/BD-197.md
 M maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md
 M maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-INSESSION-FIX.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-197-INSESSION-CORRECTION.md
?? maintenance-docs/v11-implementation/RESEARCH-BD-197-INSESSION-BACKSTOP.md
$ git diff --name-only  → exactly the 3: backlog/BD-197.md + design + plan
```
- **3 modified tracked files**: design (S-1/S-2 edits), plan (all 5 fixes), `backlog/BD-197.md` (Note 14, Pack-Chat-added — single `+` line). **NO source / test / validator / commit-sequence change.**
- **3 untracked** = the prior-pass §18 / research / correction-review input artifacts named in the prompt (IMPL-REPORT, PACK-REVIEW-INSESSION-CORRECTION, RESEARCH-INSESSION-BACKSTOP). Expected.
- **Commit sequence unchanged** — plan §A still 12 commits C0–C8b (11 if C7b folds); §18 content-sharpen explicitly *"NO new commit, NO sequence change."*
- **validate-pack** exit `0` ("PASSED — all checks clean"); **PACK_VALIDATE_DEEP=1** exit `0`.
- **Design diff +330 / plan +203 deltas**: the design's large insertion is the prior-pass uncommitted §18 + §2.1-scrub block (part of the scope-correction bundle vs HEAD, NOT this fix pass), exactly as the IMPL-REPORT disclosed; `git diff --name-only` confirms the fix touched only the 2 docs. Not a collateral defect.

## Section maps intact (PASS)
- Design: `## ` headers = Correction-pass note + §0–§18 (all present, in order).
- Plan: `## ` headers = attestation + §A–§K + Rules-Applied Verification Block (all present, in order).

---

## Findings

None (BLOCKER / MUST / SHOULD / NIT all clear). The two informational deltas above (EE-3 16-vs-15 carrier count; design diff-stat inflation) are pre-disclosed, benign, and require no action — the load-bearing claims hold.

---

## Rules-Applied Verification Block

| Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| empirical-evidence-blocks [reviewer] | Every check ran a quoted command with verbatim output at HEAD `05ad61b` / 2026-06-14: dangling-ref `rg -l` (16, 3 targets=0); battery `grep -rcE … awk` = 202; carve-out `grep -c` = 3 (1/file); validate-pack + DEEP exit 0; `git status --short` + `git diff --name-only` for scope; `grep -ncF "user-approved 2026-06-14"` design=4; J4 `grep -c` design 9 / plan 12; Check-47 read at `:4460–4463`. | COMPLIANT |
| ci-guard-design-measure-then-bound [verify] | Design §13.1a (537) + §18.4 (1112–1114) + §16-RAVB (609) + plan §B C8b (158) / §E step 3 (240) / §J2 (442): the MANDATED Guard-A′ extension is sized to EXACTLY three tokens, the third = the exact `permissions.deny` recipe string C5/C8a author, RE-MEASURED at C8b commit-time, not a broad pattern; baseline measured 0/0 (EE-12). | COMPLIANT |
| scope-deliverables-to-the-ask [universal] | Verified ONLY S-1/S-2/N-1/N-2/N-3 + collateral-absence. `git diff --name-only` = exactly design + plan + BD-197.md (Note 14). No source/test/commit-sequence touched; section maps intact. No out-of-scope findings invented; the 2 benign deltas surfaced honestly. | COMPLIANT |
| agents-never-commit [universal] | Ran only read-only git (`git rev-parse`, `git status`, `git diff --name-only/--stat`, `git diff <path>`) + read-only `rg`/`grep`/`sed`/`python3 validate-pack.py`. NO `add/commit/push/stash/reset/restore/checkout/mv/rm/apply`. HEAD unchanged `05ad61b…`. Sole write = this report. | COMPLIANT |
| rules-applied-verification-block [universal] | This block; every row carries quoted/measured evidence; no empty cell; no AMBIGUOUS terminal state. | COMPLIANT |

---

*End of PACK-REVIEW-BD-197-INSESSION-FIX.md — VERDICT APPROVE. All five fixes landed correctly; design↔plan AGREE (Guard-A′ MANDATED via BD-197 Note 14; pack ships NO hook/settings file, J4=NO); the three numeric re-measures match (0 active non-process dangling-refs, battery 202, 3 carve-out sites); collateral is exactly the 3 tracked docs + 3 untracked inputs; commit sequence C0–C8b unchanged; validate-pack + DEEP exit 0; section maps intact.*
