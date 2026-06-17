# CX1 re-plan — reconciliation (post-adversarial review, 2026-06-17)

**Adversarial verdict: SOUND-with-corrections.** `PLAN-BD-221-CX1-REPLAN.md` STANDS — the
2 state-corrections (CX1 unwritten; validate-pack GREEN at HEAD both modes) and the DAG /
sequence (CX1→C9→C10→C8→C11→C12→C13) / scope keywords / design-doc attribution / manifest
co-ownership / green-stays-green / grep-zero allowlist sizing / C9-C10 saved patches / all 6
frozen OQs + FIX-FORWARD were all CONFIRMED by independent re-measurement. Apply these
corrections at implementation (none re-sequences the DAG or touches a frozen decision):

## MUST
- **C-1 (CX1 coder):** the CX1 Group-6 test exercises `_v10_to_v11_retire_gemini` IN ISOLATION
  (no bundle install / no custom-lift), so a "custom landed in the bundle" assertion added there
  as-built would FAIL. Restructure Group 6 (or add a new group, or fold the lift into the retire
  helper) so the bundle-custom assertion runs against a state where the lift actually happened.

## SHOULD
- **C-2 (CX1 coder):** the custom-lift INTO the bundle is a DIRECT `cp` (Gemini→Claude source per
  OQ-1), NOT engine-routed — `customization_preserve`'s `custom-agent` branch returns
  `removed-everywhere` with no copy when `ours` is absent. Implement as a direct cp.
- **C-3 (C8 redo):** note that CX1 resolves the C8-review NIT-#2 (the MERGE-STRATEGY class-7 prose
  is now TRUE because CX1 makes custom→bundle real).
- **C-6 (C11 redo / orchestrator):** sharpen the manifest order-gate — the C11 cumulative manifest
  is regenerated in MAIN AFTER C10 is committed, NEVER from the C11 isolated worktree. The C11
  coder does NOT produce a manifest; the orchestrator regens it post-C10+C11.

## NIT / awareness
- **C-4 (C9):** the C9 saved patch ACTIVELY writes a stale "(4)" agent count on a converted line —
  already tracked as POQ-C9-1 (out-of-scope, fix after the cluster); note it to the C9 reviewer as
  a known carried-forward token, do NOT fix in C9.
- **C-5/C-7/C-8/C-OPT:** loose-leg-left-as-is note; the plan's `§6.1 row N` cites the design's
  blast-radius table (not the §5.x spec); confirm the C8 token is covered by the existing class-2;
  optional micro-reorder (C8 after C11) — not adopted (the DAG order stands).

→ Plan stands + these corrections baked into the per-commit coder prompts. User-review gate next;
on approval, CX1 coder (with C-1 + C-2) in a fresh isolated worktree.
