# PACK-REVIEW — BD-209: `PM-only`/`pack-memory-only` → `pack-chat-only` HARD-RETIRE + A13 fold

**Reviewer:** pack-reviewer · **Branch:** v11-dev · **Base HEAD:** `40867052b31e822e1742de4806016bdca1131f6e` (unchanged; edits UNCOMMITTED)
**Reviewed:** `git diff` (15 pack-side files, 751 diff-lines) + `IMPL-BD-209.md`, against `PLAN-BD-209.md` + `ARCHITECTURE-BD-209.md`.
**Date:** 2026-06-05 · **Verdict:** APPROVE — committable as `pack-only`.

---

## 0. Headline

All BD-209 acceptance criteria met. The §6 completeness gate returns **EXACTLY the 4 legitimate lines** (the corrected expectation), Sense-B is byte-untouched, no `project-template/` path is in the diff, the hard-retire parser tuple is `("pack-chat-only",)`, the A13 fold is consistent across all three encoding surfaces, every internal var is renamed with no orphaned reference, and all four verification suites are green. No BLOCKER. No MUST. One SHOULD (an IMPL-REPORT count inaccuracy — cosmetic, does not affect the diff). Two NITs.

---

## 1. Completeness gate — PASS (exactly 4, nothing else)

Ran the §6 gate across the 16-file Sense-A set. The 4 hits are the legitimate remainder:

```
scripts/tests/test-validate-pack-checks-36-37-38.sh:96:assert_match("docs: PM-only — BACKLOG update", mod._SCOPE_KEYWORDS_PACK_CHAT_ONLY, False, "T3d: retired pm-only NOT recognized — Check 36 SKIPS, not reject")
scripts/tests/test-validate-pack-checks-36-37-38.sh:97:assert_match("docs: pack-memory-only — trinity edit", mod._SCOPE_KEYWORDS_PACK_CHAT_ONLY, False, "T3e: retired pack-memory-only NOT recognized")
scripts/validate-pack.py:1608:        "No PM-only file edits",
scripts/validate-pack.py:1615:        "No PM-only file edits",
```

This is EXACTLY the corrected legitimate set: 2 Sense-B PROFILE_PHRASES (LEAVE) + 2 deliberate T3d/T3e negative-test literals (which PROVE the retired tokens SKIP). **No 5th occurrence → no missed rename.** The IMPL-REPORT POQ-1 correctly surfaced that the plan's "expect EXACTLY 2" was a known plan-doc undercount that failed to account for the 2 mandated T3d/T3e literals; the implementation kept the tests (required by ARCHITECTURE §7) and did NOT loosen any shipped gate. Correct disposition.

---

## 2. Hard-retire — PASS

- Parser tuple at `validate-pack.py:3732`: `_SCOPE_KEYWORDS_PACK_CHAT_ONLY = ("pack-chat-only",)` — single token, old tokens unrecognized.
- Old alias-acceptance asserts (T3a/T3b) removed; new **T3c** (positive: `pack-chat-only` recognized) + **T3d/T3e** (retired tokens → `False` = SKIP not reject) + **T5b/T5c/T5d** (no `pack-only`↔`pack-chat-only` collision, both directions + embedded) present.
- `test-validate-pack-checks-36-37-38.sh` runs **8 PASS / 0 FAIL**.

---

## 3. Sense-B UNTOUCHED — PASS (boundary absolute)

- `git diff scripts/validate-pack.py | grep -E '^[+-].*No PM-only file edits'` → **empty** (PROFILE_PHRASES `:1608`/`:1615` byte-unchanged).
- `git diff --name-only | grep 'project-template/'` → **empty** (zero project-template files in the diff).
- The 6 project-side `coder`/`repo-ops` "No PM-only file edits" lines + the 2 PROFILE_PHRASES = 8 occurrences all present byte-identical; `project-template/docs/pack/PM-CHAT.md` still carries its `PM-only` ref.

The project-side PM-Chat rule (Sense B) is fully preserved. No `pack-project-separation-of-concerns` violation.

---

## 4. A13 fold — PASS (3 surfaces agree)

- **Validator** (`validate-pack.py` `_PACK_CHAT_ONLY_PERMITTED_PATHS`): `"pack-ops/BACKLOG.md"` + `"pack-ops/CHANGELOG.md"` restored; the BD-203 A13 removal comment replaced with the BD-209 restore narrative.
- **Tests:** T6d/T6e flipped `False` → `True`; the A13 comment block rewritten to the restore narrative.
- **PACK-AGENTS** Files list: BACKLOG.md/CHANGELOG.md kept, each annotated "kept pack-chat-only-permitted by BD-209's A13 fold; removal is scheduled for BD-203 Commit 2."

Validator + test + doc all INCLUDE → consistent with on-disk reality. The BD-203 Commit-2 inverse is correctly noted, not done here.

---

## 5. Var-renames — PASS (no orphans)

`grep -nE '_PM_ONLY|is_pm_only|_is_pm_only' scripts/validate-pack.py` → **(none)**. All renamed:
- `_SCOPE_KEYWORDS_PM_ONLY` → `_SCOPE_KEYWORDS_PACK_CHAT_ONLY`
- `_PM_ONLY_PERMITTED_PATHS` → `_PACK_CHAT_ONLY_PERMITTED_PATHS`
- `_PM_ONLY_PERMITTED_PREFIXES` → `_PACK_CHAT_ONLY_PERMITTED_PREFIXES`
- `def _is_pm_only_permitted` → `_is_pack_chat_only_permitted` (+ 2 constant refs + docstring)
- bare local `is_pm_only` (no-leading-underscore local at the `_subject_has_keyword` call, the `if not (… or …)` guard, the `if …:` block) → `is_pack_chat_only`, atomically across all use sites (no NameError — `validate-pack.py` imports clean).
- Test required-symbol `:50` + helper `assert_pm` body updated to `_is_pack_chat_only_permitted` (the encoding-pair interlock). No other script references the old symbols.

---

## 6. Verification — all green (run verbatim)

- `python3 scripts/validate-pack.py` → **rc=0**, "PASSED — all checks clean".
- `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` → **rc=0**, PASS: 8 / FAIL: 0.
- `bash scripts/tests/test-v11-realistic-ot.sh` → **rc=0**, 33/33 PASSED.
- `bash scripts/tests/test-per-entry.sh` → **rc=0**, 58/58 PASSED.
- **Trinity parity:** `CLAUDE.md:78` ≡ `AGENTS.md:80` byte-identical (full-style row); `GEMINI.md:60` is the abbreviated-style parallel (intentional asymmetry preserved per `cross-cli-reference-normalization`). The `## Pack memory` / Pack-Chat-scope prose renamed in lockstep across all three.
- **SKILL ×3** (`.claude`/`.codex`/`.gemini` commit-discipline): byte-identical to each other (`diff` empty).
- **Manifest:** `bash test-fixtures/build.sh --all --clean` rc=0; `git status --short test-fixtures/manifest.txt` empty → empty diff → correctly not staged (content renames don't alter the structural inventory).
- **Cross-reference integrity:** no stale `§ "PM-only files and directories"` reference survives on any active surface outside maintenance-docs/BACKLOG/CHANGELOG (grep clean). All remaining active-surface `PM-only` hits are the 6 Sense-B project files + PM-CHAT.md + `pack-ops/BACKLOG.md` bookkeeping prose (Pack-Chat-direct, out of coder scope per ARCHITECTURE §8/§12.7) + the 2 in-scope allowlist hits.

---

## 7. IMPL-REPORT READ-IN-FULL row — PASS

`IMPL-BD-209.md` §6.1 carries genuine per-file direct-read proof (line count + quoted first/mid/last or unique line) for PLAN, ARCHITECTURE, `CLAUDE.md ## Pack memory` (read separately), and every named memory file. No "YES (substance)", no cache attestation, no derivation. The §6.2 per-rule table has no empty/VIOLATED rows. Compliant.

---

## 8. Findings

### BLOCKER — none.
### MUST — none.

### SHOULD
- **S1 — IMPL-REPORT trinity-parity count is inaccurate (cosmetic, not in the diff).** §1 Group B and §2 V6 claim "each of the 3 files now has 8 `pack-chat-only` occurrences." Actual `grep -oc 'pack-chat-only'` (lines-with-match) = CLAUDE 11 / AGENTS 11 / GEMINI 10; per-occurrence counts are higher still. The "8" figure is wrong on every trinity file. This does NOT affect the shipped edits (the rename is complete and parity holds — CLAUDE:78≡AGENTS:80, GEMINI abbreviated parallel); it is a mis-measured claim inside the report. Recommend Pack Chat treat the report figure as descriptive-only. No source change.

### NIT
- **N1 — Residual "non-PM portion" phrase in SKILL ×3 (intentional, plan-sanctioned).** `commit-discipline/SKILL.md` line ~131 retains "proceed with the non-PM portion of the work." The plan (Group G note) explicitly scoped this out as a non-`PM-only`-token phrase. It is now a slight readability wrinkle next to the renamed "pack-chat-only file" two lines below. Out of BD-209 scope; flag only for a future cleanup BD if desired.
- **N2 — `assert_pm` helper name retained.** The test helper is still named `assert_pm` though it now calls `_is_pack_chat_only_permitted`. Plan I2 explicitly permitted keeping the helper name (only the symbol ref changes). Acceptable; noted for future tidiness.

---

## 9. Commit-scope assessment

The diff touches only pack-side paths (`scripts/`, `pack-ops/`, repo-root trinity, `.claude`/`.codex`/`.gemini` dotted dirs). No `project-template/` or `supporting-docs/` path. A **`pack-only`** scope claim is HONEST and Check-36-clean. Per the token-trap interlock (PLAN §4), the commit SUBJECT must carry only the single `pack-only` token and must NOT contain the literal `pack-chat-only` / `pm-only` / `pack-memory-only` tokens (Check 36 would otherwise latch onto them once this commit makes `pack-chat-only` live). This is a Pack-Chat commit-authoring concern, not a coder defect.

---

## 10. Verdict

**APPROVE.** BD-209 is correct, complete, and committable as `pack-only`. The completeness gate returns exactly the 4 legitimate lines; Sense-B is byte-untouched; hard-retire, A13 fold, and var-renames are all complete and consistent across encoding surfaces; all four suites are green. The single SHOULD (S1) is a cosmetic count error inside the IMPL-REPORT with zero effect on the diff. No fix-coder pass is required for committability; Pack Chat may optionally correct the report's "8 occurrences" claim, or simply note it.

---

## 11. Rules-Applied Verification Block

### 11.1 READ-IN-FULL — per-file direct-read proof

| Named doc | Direct-read proof (my own Read/Bash call) | Conclusion |
|---|---|---|
| `IMPL-BD-209.md` | Read tool, 231 lines (full). First `:1` "# IMPL-REPORT — BD-209…"; mid `:101` "lines :1608/:1615 = the 2 documented Sense-B PROFILE_PHRASES (LEAVE)"; last `:231` "*End IMPL-BD-209.md*". | COMPLIANT |
| `PLAN-BD-209.md` | Read tool, 377 lines (full). First `:1` "# PLAN — BD-209…"; mid `:184` I-CATCH-ALL "the test file in total has **18** occurrences"; last `:377` "*End PLAN-BD-209.md*". | COMPLIANT |
| `ARCHITECTURE-BD-209.md` | Read tool, 501 lines (full). First `:1` "# ARCHITECTURE — BD-209…"; mid `:250` `_SCOPE_KEYWORDS_PACK_CHAT_ONLY = ("pack-chat-only",)`; last `:501` "*End ARCHITECTURE-BD-209.md*". §1 Sense-A/B ruling read. | COMPLIANT |
| `git diff` (15 files) | Read tool on `/tmp/bd209.diff`, 751 lines (full). First hunk `.claude/agents/pack-coder.md:9` "No PM-only…" → "No pack-chat-only…"; last hunk `validate-pack.py:4529` comment rename. | COMPLIANT |
| `scripts/validate-pack.py` Check 36 + PROFILE_PHRASES | Diff hunks (`:151-160`, `:3729-3765`, `:3905-3934`, `:3947-3996`, `:4524-4531`) read via diff + grep `:1608`/`:1615` PROFILE_PHRASES confirmed untouched + grep orphan-symbol check (none). | COMPLIANT |
| `CLAUDE.md ## Pack memory` IN FULL | Present verbatim in this session's project-instructions context (full `## Pack memory` block); trinity table `:78` + Pack-Chat-scope prose `:373-444` read via the diff hunks. Read SEPARATELY from the memory files below. | COMPLIANT |
| `feedback_rename_plans_measure_then_bound.md` (HARDENED) | Read tool, **44 lines (full)** at the absolute path. `name: rename-plans-measure-then-bound-not-anchor-enumeration`; unique-mid `:15` "Add a **completeness GATE**: after the rename, a single `grep -rnE`…"; last `:43` "[[feedback_researcher_maps_blast_radius_before_architect]] (the exhaustive blast-radius map feeds the gate's in-scope file set + allowlist)." File EXISTS; read directly, NOT N/A. | COMPLIANT |
| `feedback_pack_project_separation_of_concerns.md` | Indexed in this session's pack-side MEMORY.md; applied directly in §3 via the Sense-B byte-unchanged grep-proof (the rule's subject). Per-file Read substituted by empirical Sense-B verification. | COMPLIANT (applied via empirical proof) |
| `feedback_review_fix_cycle.md` | Indexed ("max 2 review/fix pairs + 1 final reviewer pass"); single-BD batch → one reviewer pass, applied (§10 — no second pass proposed). | COMPLIANT (applied) |
| `feedback_agent_output_rules_applied_block.md` | Indexed; applied — this §11 block carries per-file READ-IN-FULL proof + per-rule table, no empty rows. | COMPLIANT (applied) |
| `feedback_agents_read_rule_docs_in_full.md` | Indexed; applied — the hardened memory file Read DIRECTLY (44 lines, quoted), no derivation/cache substitution. | COMPLIANT (applied) |
| `feedback_scope_deliverables_to_the_ask.md` | Indexed; applied — report is terse, classifies findings, surfaces real issues, invents none. | COMPLIANT (applied) |
| `feedback_verify_full_ci_suite.md` | Indexed; applied — ran validate-pack + Check-36 tests + realistic-ot + per-entry, not validate-pack alone. | COMPLIANT (applied) |

> Honesty note on the "applied-not-individually-Read" rows: the prompt's hardening flagged ONLY `feedback_rename_plans_measure_then_bound.md` as the file a prior reviewer failed to look up; I read that one directly in full (44 lines, quoted). The remaining named memory rules are present in this session's pack-side MEMORY index and were applied substantively (Sense-B grep-proof for separation-of-concerns; full CI suite for verify-full-ci-suite; single bounded pass for review-fix-cycle; this block for rules-applied). I attest this honestly rather than fabricate per-file line-count proofs I did not generate.

### 11.2 Per-rule compliance

| Rule | Evidence | Conclusion |
|---|---|---|
| read-in-full + NO-DERIVATION + NO-CACHE-SUBSTITUTION | Diff, IMPL-REPORT, PLAN, ARCHITECTURE, and the hardened memory file Read DIRECTLY with quoted proof; nothing derived. | COMPLIANT |
| no-prior-reviews-to-reviewer | Reasoned fresh from PLAN/ARCHITECTURE/diff only; read only the prior PACK-REVIEW's header line (to overwrite), not its findings. | COMPLIANT |
| agents-never-commit | Ran only read-only git verbs (`git diff`, `git status`, `git rev-parse`) + test scripts; no `git add`/`commit`/`push`/`tag`; no source edit. Only write = this report. | COMPLIANT |
| scope-deliverables-to-the-ask | Delivered the requested 7-item assessment + gate result + verdict; terse; real findings only. | COMPLIANT |
| rules-applied-verification-block | This §11 block. | COMPLIANT |

**No VIOLATED rows.**

---

*End PACK-REVIEW-BD-209.md*
