# PACK-REVIEW-BD-197 — In-session spawn symmetry + unified-backstop correction (adversarial, fresh)

**Role:** pack-reviewer (fresh, adversarial; read-only on the codebase — this report is the sole write).
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev · **HEAD:** `05ad61b4ca86a743d27230ec86a8252a55c064d4` (`05ad61b`).
**Date:** 2026-06-14. **Scope:** verify the §18 in-session-symmetry + unified-backstop re-plan is real, complete, grounded in F1–F5, green-per-commit, and isolation/rule-capture-clean. Re-measured independently; did NOT read any prior PACK-REVIEW.

---

## VERDICT: APPROVE-WITH-FIXES

The §18 correction is real and the project-side in-session under-scope IS genuinely closed (C7a now mandates the full 5-element in-session Agent/Task-tool spawn contract in PM-CHAT.md, client-native — independently confirmed absent today). The backstop is grounded ONLY in verified F1–F5 facts (no phantom capability). Green-per-commit, isolation, and rule-capture hold across the unchanged 12-commit sequence. ONE traceability defect (SHOULD): the plan elevates the design's **explicitly-optional** Guard-A′ `permissions.deny`-token extension to a **"user-approved BINDING"** mandate without an in-artifact citation that the user approved THIS specific extension — the design and BD-197 both say it is optional / not-mandated. Fix = reconcile the design↔plan mandate status (or cite the approval). Plus minor NITs.

---

## Read attestation (read in full, no derivation)

- `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md` — full (488 lines; esp. C4/C5/C7a/C8a/C8b + §A/§C/§D/§E/§F/§G/§H/§I/§J/§K).
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` — §18 (full, 876–1180) + §2 (scrubbed UC-1) + §3 + §4 + §5 + §9 + §10 + §13 + §14 + §15.
- `maintenance-docs/v11-implementation/RESEARCH-BD-197-INSESSION-BACKSTOP.md` — full (188 lines; F1–F5, availability matrix, Q1–Q5, BOTTOM LINE).
- `pack-ops/PACK-CHAT.md` — full (342 lines). `project-template/docs/pack/PM-CHAT.md` — `## Permission profiles` (390–516) + EE-11 loci.
- `backlog/BD-197.md` — full incl. Notes 11/12/13. `backlog/BD-218.md` — referenced (the bgIsolation axis). `CLAUDE.md ## Pack memory` — full (from system context).

---

## Findings by severity

### BLOCKER
None.

### MUST
None. (The mandate-status divergence below is a SHOULD because the extension itself is harmless and green-on-arrival; only its traceability/grounding is defective.)

### SHOULD

**S-1 — Plan claims the Guard-A′ `permissions.deny`-token extension is a "user-approved BINDING" mandate; the design says it is OPTIONAL / "not mandated," and neither the design nor BD-197 carries an in-artifact citation of user approval for THIS extension.**
- Location — PLAN §A line 33 ("C8b … Guard-A′ … (baseRef+bgIsolation+permissions.deny recipe)"), §A line 37(5), §B C8b line 158 ("§18.4 made the `permissions.deny`-token assertion an OPTIONAL P3-architect call; **the USER APPROVED it, so it is BINDING here**"), §E Guard-A′ step 3, §I C8b, §J2/J-resolved-15.
- The design says the opposite. RECONCILED §18.4 line 1106–1108: *"the planner MAY (optional, P3-architect call) extend the bounded presence-check to also assert the `permissions.deny` recipe token … but that is a measure-then-bound decision at guard-author time, **not mandated here** (scope-deliverables-to-the-ask)."* §18.R line 1173: *"the optional Guard-A′ extension is flagged as a P3-architect call, **not mandated**."* §13.1a line 537 sizes the bounded check to *"exactly those two settings keys"* and explicitly does NOT fold the third token.
- Evidence — independent grep of the design for the approval attribution: the only `user-approved` hits are (a) the top Update-log note (line 8) and (b) the G-1/G-2 gate-fix (line 454) — NEITHER is the `permissions.deny` Guard-A′ extension. BD-197 grep for `permissions.deny|Guard-A|18.4|user-approved.*extension` → only Note 8 (the git-permission contract, unrelated to the guard token). So "the USER APPROVED it" for the third-token assertion is a planner state-claim with no traceable in-artifact citation (violates `feedback_prompts_grounded_in_facts` / the empirical-evidence standard for a "the user decided X" claim).
- Why it matters — `scope-deliverables-to-the-ask`: the re-plan's mandate was to fold §18 + the (design-)optional extension. Promoting an architect-optional item to a hard coder mandate is a scope decision that the design routes to guard-author time, not the planner. If the user did approve it in chat, the artifact must SAY SO (cite the date/decision) so a fresh coder/reviewer can verify; if not, the plan should restore the design's "optional, measure-then-bound at C8b" framing and let the C8b coder make the architect-call.
- Concrete fix — EITHER (a) add a one-line dated citation in §J2/§J-resolved-15 ("user approved the §18.4 third-token extension <date>, in chat") AND have the design §18.4 updated to MANDATE it (so design↔plan agree — currently they contradict), OR (b) downgrade the plan's framing from "BINDING" back to the design's "optional P3-architect call; if shipped, measure-then-bound to the authored recipe token." Note: this is the SAME class of gap the review was chartered to catch — an un-grounded "the user wants X" claim slipping through; here it slipped INTO the artifact rather than out of scope.

**S-2 — §18.2 layer-map omits the C4 pack-side PreToolUse hook for the in-session path, while §5.3 + plan C4 DO carry it — a latent design-internal inconsistency the plan inherits.**
- Location — RECONCILED §18.2 layer-to-path map (lines 1034–1038): the "IN-SESSION Agent-tool (Pack Chat)" row lists only layer (i) prose + layer (ii) `permissions.deny` + "(iii) N/A (not a launcher)". But §5.3 (lines 313–316) + plan C4 (§B line 110, J4) BOTH provision a pack-side PreToolUse hook as the C4 mechanical backstop.
- Evidence — §5.3: *"Pack-side: a PreToolUse hook (or `--disallowedTools` …) for spawned agents."* Plan §B C4 line 110 schedules exactly this (J4-gated). The §18.2 map does not show the hook as an in-session pack layer.
- Why it matters — a fresh C4/C8b coder reading §18.2 alone would conclude the pack in-session path has NO hook layer; reading §5.3 they'd add one. The two are reconcilable (F2 says the PreToolUse `if`-matcher fails open, so `permissions.deny` is THE authoritative layer and a hook is defence-in-depth/secondary), but the artifacts should say so consistently.
- Concrete fix — the plan is the downstream artifact and already carries both correctly (C4 hook + C5 recipe). Add a one-line note in §B C4 or §J that the pack PreToolUse hook is the §5.3 defence-in-depth layer (secondary, fails-open per F2) and the `permissions.deny` recipe (C5) is the authoritative in-session mechanical layer per §18.2(ii) — so the C4 J4 gate and the §18.2 map don't read as contradictory. (Design-side reconciliation is owned by the architect, not this plan; flag for the architect.)

### NIT

**N-1 — §F EE-3 (dangling-ref) is measured at the stale HEAD `ae3d932` and is now inaccurate at `05ad61b`.** The plan's EE-3 names 3 active non-process EXCISE targets (`RESEARCH-CLAUDE-REPOS-SURVEY.md`, `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`, `RESEARCH-19C-G-ITEMS-VERIFICATIONS.md`). Independent re-measure at `05ad61b`: all three are NOW ABSENT from the dangling-ref matcher (C1 landed + excised them). The remaining 11 hits are all BD-197-process/allowlist docs. No action needed for C4+ (C1 is landed), but EE-3 should carry a one-line "superseded at `05ad61b` — C1 excised all 3" note for audit honesty (the plan already notes HEAD advanced; EE-3 just wasn't re-run like EE-1/EE-2/EE-6 were).

**N-2 — Plan EE-8 line numbers for the carve-out drift (`.toml:21`/`.claude:37`/`.gemini:39`); actual at `05ad61b` are `.toml:23`/`.claude:47`/`.gemini:49`.** Immaterial — the plan correctly says the coder re-locates by symbol/string and PREFLIGHT-greps `checkout -- <path>` == 0. The M-2 prose-coherence concern is REAL and correctly captured: the Codex `.toml:23` embeds the carve-out mid-sentence (`git checkout (except \`git checkout -- <path>\` … ). These are forbidden …`), so a naive parenthetical excision leaves `git checkout (except )` — the plan's C4 task §B line 108 mandates the read-back. Well handled.

**N-3 — §E/§I budget prose still cites "battery = 186 invocations" in three runtime-guard lines** (§E Guard-A step 1 "×186 budget", §E Guard-A′ "186 invocations", §I C5) even though §F EE-1 was correctly updated to 202. Harmless (a tighter-than-actual budget number for a trivial `rg -c` check), but the 186→202 update wasn't swept into every budget mention. Cosmetic.

---

## Explicit verdicts on the two chartered questions

**Is the in-session PM-Chat spawn path genuinely closed?  YES.**
- Current-state gap is REAL (independently reproduced): `grep -ciE "isolation|worktree|/tmp|handoff|merge-back" project-template/docs/pack/PM-CHAT.md` → **0**; the `## Permission profiles` section (§397, read in full) documents spawning ONLY via the three `agent-run.sh` flag-profile blocks (Claude `:455`, Codex `:484`, coder `:501`) — zero in-session Agent/Task-tool contract.
- The plan closes it: C7a (§B line 136 + §I C7a) MANDATES a new client-native PM-CHAT.md subsection with all FIVE §18.1 elements — (1) two paths (in-session PRIMARY + `agent-run.sh` SECONDARY), (2) `isolation:"worktree"` for RW only / RO in-place keyed off the `## Permission profiles` RW/RO SSOT (D2), (3) background spawning (client-native phrasing, no pack-self `run_in_background` citation), (4) the `/tmp`-patch merge-back, (5) conflict/degradation at project homes — authored CLIENT-NATIVE, NOT a byte-copy, ZERO pack-self refs. This is the full in-session contract, not merely the post-return apply. Design §18.1 (lines 936–977) backs it. The gap that slipped past three prior reviews is addressed.

**Is the backstop grounded only in verified facts?  YES.**
- The three layers map exactly to F1–F5 (RESEARCH read in full): (i) prose deny-list = always-on shipped (F3 honest-limit acknowledged — out-of-box only prose + behavioral contract); (ii) `permissions.deny` recipe = the in-session mechanical hard-deny, session-scoped + sub-agent-inherited + deny-first (F2), documented-optional / NOT shipped (F3); (iii) launcher `--disallowedTools` = project `agent-run.sh` only (F4). The plan does NOT rely on any capability F1–F5 deny: it does NOT claim agent-file `tools:` can deny a git verb (F1 — plan §B C5/C8a state `permissions.deny` is the ONLY in-session mechanical layer), and it does NOT treat the PreToolUse hook as the hard-deny (F2 fail-open — plan §B C5/C8a/§18 mark the hook SECONDARY/fails-open). **J4 = NO new shipped pack-side file** is confirmed: Check-47 `_SANCTIONED_PACK_SIDE_SHIPPED` measured intact at `scripts/validate-pack.py:4460` = exactly `{scripts/lib/detect.sh, scripts/pack-help.sh}`; all three layers edit EXISTING surfaces (prose / OPTIONAL-FEATURES docs / `agent-run.sh`).

---

## Independent re-measurement table (vs the plan's §F, at `05ad61b`, 2026-06-14)

| Item | My measurement (command) | Plan §F claim | Delta |
|---|---|---|---|
| HEAD / branch | `05ad61b…` / `v11-dev` (`git rev-parse`) | `05ad61b` / `v11-dev` | MATCH |
| Battery invocations | `202` (`grep -rcE 'validate-pack\.py' scripts/tests/*.sh`) | EE-1 = 202 | MATCH |
| Highest Check # | `52` (`grep -oE 'Check [0-9]+' validate-pack.py`) | EE-6 = 52 | MATCH |
| validate-pack exit | `0` ("PASSED — all checks clean") | EE-6 = 0 | MATCH |
| Prohibition matcher | `25` files = `9 archive + 16 active` (rg) | EE-2 = 25 (9+16) | MATCH |
| C1/C2 STRIP done | CLAUDE.md / PLAN-SKILL-DIMENSIONS / CONCEPTUAL-REVIEW-METHODOLOGY / ARCHITECTURE-BD-196-S1 all `0` | EE-2 (STRIP empty) | MATCH |
| OPTIONAL-FEATURES `baseRef`/`bgIsolation` | `0/0` (rg exit 1, both files) | EE-4 = 0/0 | MATCH |
| OPTIONAL-FEATURES `permissions.deny` | `0/0` (grep -c both files) | EE-12 = 0/0 | MATCH |
| PACK-CHAT.md in-session | `1` (benign "handoff at Batch") | EE-11 = 1 | MATCH |
| PM-CHAT.md in-session | `0` | EE-11 = 0 | MATCH |
| Check-47 frozen allowlist | `{scripts/lib/detect.sh, scripts/pack-help.sh}` (`:4460`) | J4 = untouched | MATCH |
| pack-coder carve-out sites | `3` (`.toml:23`, `.claude:47`, `.gemini:49`) | EE-8 = 3 (stale line #s) | MATCH (count); line #s drifted (N-2) |
| Checks 53–59 landed? | none (`grep 'Check 5[3-9]'` empty) | (unlanded) | MATCH |
| Dangling-ref active non-process EXCISE | `0` (all 3 now absent — C1 excised) | EE-3 = 3 (at `ae3d932`) | STALE (N-1; C1 landed) |
| §2.1 residue (bgIsolation-as-trigger) | `0` active assertions (all hits are supersession/scrub records) | EB-C = 0 | MATCH |
| `RESEARCH-…-INSESSION-BACKSTOP.md` matches either matcher? | NO (prohibition exit 1, dangling exit 1) | (not allowlisted — correct) | MATCH |

No load-bearing measurement diverges from the plan. Two stale-HEAD blocks (EE-3, EE-8 line #s) are bookkeeping, not correctness.

---

## Three-axis check

**Axis 1 — In-session symmetry (the lens the prior 3 reviews lacked).** PASS.
- Pack side (C4) and project side (C7a) now BOTH carry the in-session Agent/Task-tool spawn procedure as the PRIMARY documented path, with the launcher as SECONDARY — symmetric mechanism, separate client-native/pack artifacts (not byte-copies). Confirmed absent on both surfaces today (EE-11: PACK-CHAT.md 1 benign hit, PM-CHAT.md 0). The PROJECT under-scope (PM-CHAT.md had only the launcher) is the exact gap §18 closes, and C7a's 5-element mandate closes it. `pack-project-separation` held: §I C7a/C8a require "PM Chat" orchestrator, client paths, ZERO pack-self refs, "NOT a byte-copy."

**Axis 2 — Green-per-commit.** PASS.
- The `permissions.deny` recipe lands in C5 (pack) + C8a (project) BEFORE C8b asserts it; baseline measured 0/0 in both files (EE-12), so C8b's 3-token Guard-A′ is GREEN ON ARRIVAL (pack token from C5 + project token from C8a both committed before the C8b guard). Data-first split (C6a→C6b, C7a→C7b, C8a→C8b) preserved; C0 carve-out (landed) keeps the project DATA halves cleanly `project-only`. No new check landed yet (53–59 absent), so no premature-guard red. The C8b test covers positive (all 3 present both files) + negative (recipe absent → FAIL) per §B C8b line 159 / §H. Measure-then-bound: §B/§E/§I size the third token to the EXACT recipe string C5/C8a author, re-measured at C8b commit-time — not a broad pattern.

**Axis 3 — Isolation + rule-capture.** PASS.
- Every commit single-surface with the correct Check-36 keyword (C4/C5/C8b `pack-only`; C7a/C8a `project-only`); C7a/C8a stay `project-only` via the C0 manifest carve-out (the only pack-side path, scope-neutral). No pack-self concept smuggled into `project-template/` (§I C7a/C8a enforce zero pack-self refs; background-spawn phrasing client-native). `agents-never-commit` + the destructive-verb ban is RETAINED for ALL agents incl. RW on both surfaces (§I intro + C4/C7a state RW is spawned isolated `isolation:"worktree"` and the ban is LOAD-BEARING — "no platform safety net," FACT-4). The in-session instructions explicitly state RW-spawned-isolated / no-platform-safety-net (§B C4 line 103, C7a line 136; design §3.1 FACT-4 backs it).

**Did the fix introduce a new gap / contradiction?** One inherited contradiction (S-1, design says optional ↔ plan says binding; S-2, §18.2 map vs §5.3 hook). No orphans found: every backstop layer has a commit (i=C2/C4 pack + C7a project; ii=C5 pack + C8a project; iii=C7a launcher); every in-session spawn instruction has its merge-back half (C4/C7a both pair spawn + `/tmp`-patch apply); the Guard-A′ extension has its test (C8b `test-validate-pack-check-54.sh`, run-before-wire, positive+negative). No double-documentation introduced — pack vs project OPTIONAL-FEATURES recipes are separate client-native artifacts by mandate.

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| pack-project-separation-of-concerns | §I C7a/C8a mandate PM-CHAT.md + project OPTIONAL-FEATURES "client-native, NOT a byte-copy / not a fallback," "PM Chat" orchestrator, client paths; C7a/C8a single-surface `project-only` (the pack-side validator Guard-A′ is the separate `pack-only` C8b). Design §18.1 line 968–972 ("Symmetry, not copy"). | COMPLIANT |
| bd-pack-only-operational-rule | §I C7a/C8a explicitly require "ZERO pack-self refs (no BD-NNN, `maintenance-docs/`, `pack-*`, Pack Chat, `pack-ops/`)" in every `project-template/` edit; §18.1 element-3 background-spawn note is client-native (no pack-self `run_in_background` citation). | COMPLIANT |
| verify-availability-not-just-existence | Backstop layers map exactly to F1–F5 (RESEARCH read in full): (ii) `permissions.deny` GA + session-inherited (F2), (iii) `--disallowedTools` GA-local-confirmed (F4); plan does NOT use F1-denied agent-file `tools:` verb-deny, marks the PreToolUse `if`-matcher SECONDARY/fails-open (F2). No phantom capability. J4=NO (Check-47 measured intact `:4460`). | COMPLIANT |
| verify-full-ci-suite | §D enumerates every wired script (validate ×2 + the full `tests` job list) + the NEW per-check tests; §B C8b + §H require Guard-A′ test authored → RUN (quote exit 0) → wired into `validate-pack.yml` → full battery re-run SAME commit (run-before-wire), positive+negative for all 3 tokens. Battery re-measured 202 (EE-1, my measure = 202). | COMPLIANT |
| ci-guard-design-measure-then-bound | §B/§E/§I C8b size the 3-token Guard-A′ to EXACTLY the authored tokens (third = the exact recipe string C5/C8a land, re-measured at C8b); EE-12 establishes 0/0 baseline; the `isolation` param prose is NOT folded in. Green-per-commit (recipe lands C5/C8a before C8b asserts). | COMPLIANT |
| commit-subject-keyword-token-trap | §A table + §C: every commit single-surface with one exclusive keyword (C4/C5/C8b `pack-only`; C7a/C8a `project-only`); no neutral framing; the C0 carve-out makes the project DATA halves' staged manifest scope-neutral so `project-only` is clean (Check 36). | COMPLIANT |
| enumerate-encoding-surfaces | §H adds the in-session spawn surfaces (PACK-CHAT.md C4, PM-CHAT.md C7a) + the `permissions.deny` recipe rows + the extended Guard-A′ + its test, each with validator/test/CI-ref/cross-ref in lockstep; §D/§I move in step (test covers all 3 tokens, positive+negative). | COMPLIANT |
| agents-never-commit + destructive-verb ban (ALL agents incl RW) | §I intro + C4/C7a: RW agents spawned isolated (`isolation:"worktree"`), ban LOAD-BEARING ("no platform safety net," FACT-4); orchestrator alone applies + commits; agent runs only `git diff > /tmp/...`. Design §3.1/§4.1 back it. **This review ran ZERO state-changing git verbs** — only `git rev-parse`/`git rev-parse --abbrev-ref` reads + read-only `rg`/`grep`/`sed`/`python3 validate-pack.py`; sole write = this report. | COMPLIANT |
| scope-deliverables-to-the-ask | The re-plan folds §18 + the Guard-A′ extension; sequence C0–C8b unchanged. HOWEVER the plan elevates the design-OPTIONAL `permissions.deny` Guard-A′ token to a "user-approved BINDING" mandate with no in-artifact citation (design §18.4/§18.R say "not mandated") — this is a scope/grounding divergence flagged S-1. | VIOLATED: see S-1 (plan promotes a design-optional item to a binding mandate without traceable user-approval citation; design↔plan contradict on mandate status). |
| rules-applied-verification-block | This block; every row carries quoted/measured evidence; no empty cell; one VIOLATED (S-1) reported honestly. | COMPLIANT |

---

*End of PACK-REVIEW-BD-197-INSESSION-CORRECTION.md — VERDICT APPROVE-WITH-FIXES (1 SHOULD grounding fix S-1, 1 SHOULD design↔plan reconciliation S-2, 3 NITs). The in-session PM-Chat path IS genuinely closed; the backstop IS grounded only in F1–F5; green-per-commit + isolation + rule-capture hold.*
