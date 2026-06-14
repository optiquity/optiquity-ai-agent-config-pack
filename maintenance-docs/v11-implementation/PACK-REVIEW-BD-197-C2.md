# PACK-REVIEW — BD-197 C2 (P2 removal of the worktree-isolation prohibition + bug-era guardrails)

**Role:** pack-reviewer (fresh). **Date:** 2026-06-14.
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev.
**HEAD at review:** `220b6c7a77a7d7cc384195fd737ade3cd6eeb672` (C2 is UNCOMMITTED — 10 working-tree `M` files + the untracked IMPL-REPORT; `agents-never-commit` honored).
**Review basis:** working-tree diff vs HEAD; all commands re-run independently (coder IMPL-REPORT NOT trusted).

---

## VERDICT: APPROVE

C2 mechanically realizes design §12.1(a)/§12.4/§11.2 and plan §B C2 exactly within the C2/C4 boundary: the prohibition bullet is replaced by the enable-opt-in bullet, the bug-era hard-asserts are removed, the regime-aware redesign matches the design, the trinity exemption holds, zero C4 work leaked, and the full CI sample (validate-pack general+DEEP + 8 representative tests incl. realistic-ot 33/33 + template-translations) is green. POQ-1 (no new rationale slug) is correctly disposed — slug-less is CI-safe and consistent with the slug-less predecessor — with one residual SHOULD: the disposition diverges from §12.1(a)'s LITERAL "+ new rationale slug" text, an unreconciled design-vs-impl ambiguity Pack Chat/user should adjudicate (not a blocker).

---

## Read attestation
Read directly + in full before findings: design RECONCILED §11 (P2 removal plan), §11.1 (disposition table), §11.2 (operational-coupling), §11.5 (prohibition-only gate + measured allowlist), §12.1(a)/(b)/(c) (rule change + literal enable bullet), §12.4 (commit-discipline ×3 redesign), §13.1/13.1a/13.2/13.3 (guards), §14 (reconciliation, incl. the C4 carve-out-drop directive); plan §A commit sequence + §B C2 (lines 79-88) + §B C4 (lines 98-109, the boundary); `pack-ops/PACK-CHAT.md` § "Rule-change propagation procedure" (lines 328-342); `scripts/validate-pack.py` Check 45 bijection (lines 6775-6900); `pack-ops/.spawn-rule-manifest.txt` header + records; the `git diff` of all 10 C2 files; `IMPL-REPORT-BD-197-C2.md` (incl. §9 POQ-1); `CLAUDE.md` `## Pack memory`.

---

## Independent re-verification (command + verbatim output + HEAD + date)

All at HEAD `220b6c7…`, 2026-06-14.

**V1 — Prohibition bullet replaced (design §12.1(a)).** `git diff CLAUDE.md`: the `### Sub-agent behavior (Claude-only)` "Spawn all sub-agents with no worktree isolation" bullet is REPLACED by "**Sub-agents run in-place by default; isolation is opt-in.**" matching the §12.1(a) literal (sub-agent hyphenation normalized; benign). No `[rationale:]` slug on the new bullet. PASS.

**V2 — Trinity exemption HOLDS.** `grep -c worktree`: `CLAUDE.md`=4, `AGENTS.md`=0, `GEMINI.md`=0. `grep -n "Sub-agent behavior|isolation" AGENTS.md GEMINI.md` → exit 1 (no matches). The enable bullet was NOT propagated to root AGENTS/GEMINI; the Claude-only exemption is preserved. PASS.

**V3 — Propagation procedure + POQ-1.** See POQ-1 verdict below. Surface-by-surface: corpus (CLAUDE.md) edited; rationale/references/manifest NO-OP for this rule (verified V3b). PASS.

**V3b — Rationale/manifest consistency.** `grep -in "worktree|isolation|two-class|sub-agent"` on `pack-ops/.spawn-rule-manifest.txt` → no matches; on `pack-ops/PACK-MEMORY-RATIONALE.md` (via Check 45 set) → no worktree/isolation slug. `git status --short pack-ops/` → empty (none modified). The enable bullet was never a collapsed reference (manifest header: records exist only "for each collapsed rule"), so no reference/manifest record is owed. No propagation surface left stale. PASS.

**V4 — commit-discipline ×3 redesign (§12.4).** `git diff .claude/skills/commit-discipline/SKILL.md` confirms: §1 pre-flight now regime-DETECTING, non-fatal both directions ("The pre-flight DETECTS your execution regime — it is non-fatal in both directions"); the bug-era asserts `pwd # Must end in worktree path` and `Must start with worktree-agent-` REMOVED (replaced with regime-detecting comments + ground-truth-not-settings directive); §2 regime-aware with the absolute main-checkout-retarget ban KEPT ("**Absolute prohibition (both regimes): NEVER retarget another agent's main checkout.**" + "This is a cautionary guard, NOT a blanket 'every Write must be under `pwd`'"); §3 gained the read-only-only PRINCIPLE line + `git diff > <file>` noted as read-only patch-emit; §6 "/tmp = wrong path" anti-pattern RETIRED ("Writing the report to `/tmp` is CORRECT when you are isolated…"). Byte-identity: all three byte-identical at HEAD (`diff -q` IDENTICAL ×2) AND after edit (IDENTICAL ×2) → byte-identical-after is the correct cross-cli treatment (no per-CLI difference to preserve). PASS.

**V5 — implementation-report ×3 (§11.2).** `git diff .claude/skills/implementation-report/SKILL.md`: regime-aware throughout — in-place ⇒ parent base; isolated ⇒ `git diff` patch persisted to `/tmp` handoff dir; §1 gained "(and regime)"; "see the worktree" → "see the working tree"; "diff against the worktree base" → "diff against the base recorded in section 1". Bug-era worktree-model prose grep → exit 1 (none remain). All three byte-identical at HEAD and after edit. PASS.

**V6 — pack-coder ×3.** `git diff` ×3: ONLY worktree-MODEL prose updated (frontmatter `description`, "# What you do", report-contents, Pre-flight), audience-correct per-CLI (`.codex` `.toml` edited in its own structure; `.gemini` `description:` quoting + extra frontmatter preserved). `grep -c "checkout -- <path>"` = 1 each (carve-out PRESENT, NOT dropped). `git diff | grep -i "checkout|git state|No git|forbidden"` → no git-permission lines in any of the three C2 diffs (verb block UNCHANGED). PASS.

**V7 — C4 boundary.** Verb denylist NOT expanded (commit-discipline §3 "Forbidden verbs" list unchanged by C2 — the diff hunk begins at "Allowed read-only verbs"; the forbidden list above is untouched). `git checkout -- <path>` carve-out NOT dropped (V6, count 1 each). `### Workflow` `agents-never-commit` bullet NOT touched (the only "agents never commit" string in the CLAUDE.md diff is prose INSIDE the new enable bullet, not the Workflow rule). PACK-CHAT.md merge-back NOT codified (`grep -in "merge-back|handoff dir|git apply --check|--3way" pack-ops/PACK-CHAT.md` → no matches; `git status pack-ops/` empty). No backstop hook created (`git status --short` shows only the 10 C2 files + IMPL-REPORT). PASS.

**V8 — enumerate-encoding-surfaces.** `grep -rn` for all removed strings ("Must end in worktree", "Must start with worktree-agent", "wrong path; re-issue", "the worktree is lost", "unchanged from the worktree base", "see the worktree", "Spawn all sub-agents", "no worktree isolation", "in/on your/its worktree") across `scripts/` + `.github/` → NO matches. The only `worktree` hits in `validate-pack.py` are §17-carve-out code comments naming the design doc (from C0), not prohibition assertions. `test-validate-pack-check-46.sh` line 165 uses "commit-discipline"/"implementation-report" only as skill-NAMES in a synthetic fabricated tree (writes its own bodies) — does not pin real content. No encoding surface left stale. PASS.

**V9 — Full CI (independently re-run).**
- `python3 scripts/validate-pack.py` → `EXIT 0` — "PASSED — all checks clean".
- `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → `EXIT 0` — "PASSED — all checks clean".
- Representative sample, all `EXIT 0`: check-45 (bijection — POQ-1-relevant) "All tests passed"; check-46 (anti-restate) "All tests passed"; check-16/18/19 (trinity parity) "All tests passed" ×3; checks-36-37-38 (scope keyword) "All tests passed"; `test-v11-realistic-ot.sh` "All v11-realistic-ot integration tests PASSED (33/33)"; `template-translations-test.sh` "Failed: 0 / All tests passed".
My sample reproduces green; nothing contradicts the coder's claimed 60/60. PASS.

**V10 — Scope / manifest.** `git status --short` = exactly the 10 C2 files (`M`) + `?? IMPL-REPORT-BD-197-C2.md`; NO `project-template/` / `supporting-docs/` (pack-only honored). `bash test-fixtures/build.sh --all --clean` → exit 0; `git diff --quiet test-fixtures/manifest.txt` → CLEAN (empty diff; C2 touches no v11-surface dir; pack-self skill/agent dirs don't feed client fixtures). PASS.

---

## POQ-1 verdict (no new rationale slug for the enable bullet)

**Verdict: disposition ACCEPTED (no-slug is correct + CI-safe), with one residual SHOULD flagged to Pack Chat/user.**

- **(a) Was the pre-edit prohibition bullet slug-less?** YES. `git show HEAD:CLAUDE.md` over the "Spawn all sub-agents" bullet → no `[rationale:]` and no `[roles:]` tag.
- **(b) Does the procedure permit a slug-less corpus rule?** YES, conclusively. Check 45 (the "C3 bijection" named in PACK-CHAT.md surface 2) docstring, `scripts/validate-pack.py:6796-6797`: "Rules that carry NO `[rationale:]` tag are simply not in the set — the check does not require every spawn-rule to have a rationale." The `.spawn-rule-manifest.txt` header format note (line ~25) likewise allows "the rule-name token for rules without a `[rationale:]` slug in the corpus." Manifest records exist only for COLLAPSED rules (header lines 13-17); this corpus-only, never-collapsed bullet correctly has none.
- **(c) Is the no-slug default correct, or does the bullet genuinely need a slug?** No-slug is CI-correct and self-consistent (matches the slug-less predecessor; zero Check 45 / Check 46 / manifest impact, verified green in V9). The disposition is sound.

**Residual SHOULD (design-vs-impl literal mismatch).** §12.1(a)'s final sentence — "Propagate ×3 trinity **+ new rationale slug**" — attaches LITERALLY to the (a) enable bullet, and §12.1(b) separately carries its OWN named slug (`agent-two-class-model`). So the design text, read literally, directs a new slug FOR the enable bullet; the coder instead reads "(a)'s + new rationale slug" as referring to (b)'s slug — a reasonable-but-strained reading that the literal text does not support. This is a genuine unreconciled ambiguity in the design (the architect wrote "+ new rationale slug" for (a) but never named one), not a coder error: the binding instruction for the coder is the PLAN, and plan §B C2 line 81 directs NO slug authoring and routes only the `## Pack memory` edit through propagation. The coder ESCALATED rather than silently authoring or dropping — exactly per `skill-agent-maintenance-mechanical` (rule-structure changes escalate). Recommendation: Pack Chat surfaces to the user whether an `agent-isolation-opt-in` slug + rationale entry is wanted (fold into C4 or a C2b); if not, no action — the current state is shippable as-is. NOT a blocker.

---

## Findings by severity

**BLOCKER:** none.

**MUST:** none.

**SHOULD-1 (design-vs-impl ambiguity; flagged, not a code defect).** §12.1(a)'s literal "+ new rationale slug" for the enable bullet was not honored (no slug authored). The coder correctly escalated as POQ-1; the disposition is CI-safe. Pack Chat/user adjudicates whether to author `agent-isolation-opt-in` (fold to C4/C2b) or accept slug-less. Concrete fix if adjudicated YES: add a `## agent-isolation-opt-in` entry to `pack-ops/PACK-MEMORY-RATIONALE.md` + a `[rationale: agent-isolation-opt-in]` tag on the enable bullet (×3 trinity is moot — Claude-only, so CLAUDE.md only) in the SAME commit (Check 45 bijection), routed via the full propagation procedure. No fix required to ship C2 as planned.

**NIT:** none material. (The IMPL-REPORT §5 cites the prohibition matcher at "23 files"; my independent run at this HEAD returns 24 — the delta is the now-present `IMPL-REPORT-BD-197-C2.md` + other BD-197-process artifacts that accrued; ALL 24 are LEAVE-allowlist members (9 archive + 15 process/review/research/history), and NONE of the 10 C2 files match — per-file count 0 each. The "23" is a snapshot drift, not a defect, and the gate is not a CI check at C2.)

---

## Conclusions on the prompt checklist
1. Prohibition bullet replaced — PASS (V1).
2. Trinity exemption holds (AGENTS/GEMINI worktree=0) — PASS (V2).
3. Propagation + POQ-1 — PASS; POQ-1 disposition ACCEPTED with SHOULD-1 (V3, POQ-1 verdict).
3b. Rationale/manifest consistency — PASS (no stale surface) (V3b).
4. commit-discipline ×3 §12.4 redesign + bug-era asserts removed + byte-identity correct — PASS (V4).
5. implementation-report ×3 regime-aware — PASS (V5).
6. pack-coder ×3 worktree-MODEL prose only; checkout carve-out PRESENT; denylist not expanded — PASS (V6).
7. C4 boundary respected (no verb expansion / carve-out drop / Workflow bullet / merge-back / backstop) — PASS (V7).
8. enumerate-encoding-surfaces — PASS (V8).
9. Full CI green (independent) — PASS (V9).
10. Scope + manifest — PASS (V10).

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **edit-in-place-not-full-rewrite** | `git diff --stat` shows targeted hunks (CLAUDE.md 24± over one bullet; commit-discipline 118± confined to §1/§2/§3/§6 per the read diff; no wholesale rewrites). CLAUDE.md section map intact: `### Sub-agent behavior (Claude-only)` retains all 3 bullets + `### Trinity exemption.` note, flows into `### Pack Chat scope`. | COMPLIANT |
| **cross-cli-reference-normalization** | Enable bullet Claude-only, NOT propagated (`grep -c worktree` AGENTS=0/GEMINI=0). Skills byte-identical at HEAD AND after (no per-CLI value → identical content is the correct lockstep). pack-coder `.codex .toml` edited in its own prose (not byte-copied); `.gemini` quoting/frontmatter preserved. | COMPLIANT |
| **skill-agent-maintenance-mechanical** | Redesign matches design §12.4/§11.2 mechanically; no invented structural change. The one structural ambiguity (a slug for the enable bullet) was ESCALATED as POQ-1, not improvised. Frontmatter `name`/`description`/`allowed-tools`/`tools` contracts intact. | COMPLIANT |
| **enumerate-encoding-surfaces** | `grep -rn` over `scripts/` + `.github/` for all removed strings → NO matches; check-46 test uses skill-NAMES only (synthetic tree); rationale (no slug) + manifest (not collapsed) + references (0) are NO-OP encoders. Corpus + 6 skills + 3 agents updated in lockstep. | COMPLIANT |
| **verify-full-ci-suite** | Independently ran validate-pack general (`EXIT 0`) + DEEP (`EXIT 0`) + 8 representative tests incl. `test-v11-realistic-ot.sh` (33/33) + `template-translations-test.sh` (Failed: 0) + check-45/46/16/18/19/36-37-38 — all `EXIT 0`. | COMPLIANT |
| **regenerate-manifest-v11-surface** | `bash test-fixtures/build.sh --all --clean` exit 0; `git diff --quiet test-fixtures/manifest.txt` → CLEAN (empty). No v11-surface dir touched → no stage owed. | COMPLIANT |
| **empirical-evidence-blocks** | Every claim carries command + verbatim output + HEAD `220b6c7a77a7d7cc384195fd737ade3cd6eeb672` + date 2026-06-14 (V1-V10; prohibition matcher 24/per-file-0; AGENTS/GEMINI counts; byte-parity diffs; manifest empty; CI exits). | COMPLIANT |
| **scope-deliverables-to-the-ask** | Reviewed exactly the C2/C4 boundary; surfaced the one real residual (SHOULD-1) without inventing nits; verified no C4 leak. | COMPLIANT |
| **agents-never-commit** | Ran only read-only git (`status`/`diff`/`show`/`rev-parse`/`log`) + the build (manifest empty, manifest restored via the yml's own `git checkout HEAD -- test-fixtures/manifest.txt` verify-harness path, not a scope-edit state change). HEAD unchanged `220b6c7…`. Wrote ONLY this review doc. | COMPLIANT |
| **rules-applied-verification-block** | This block. | COMPLIANT |
