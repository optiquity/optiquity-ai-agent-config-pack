# IMPL-BD-208 — Pack Chat editing-actor rule (`pack-chat-minor-edits-only`)

**Actor:** pack-coder (scoped in to the PM-only governance files for BD-208).
**Branch:** `v11-dev`. **HEAD at impl (unchanged — agents never commit):** `2cc92b92e49e95799e44ffe4113d38ae634a85ba`.
**Date:** 2026-06-04.
**Plan:** `maintenance-docs/v11-implementation/PLAN-BD-208.md` (T1–T8).
**Design (FIXED):** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-208.md` (Option B + ID-history closure).
**Commit shape:** ONE atomic `pack-only` commit (per plan §C). Pack Chat does the commit; this report is the deliverable.

---

## 1. Edit summary (lead)

Landed the new trinity `## Pack memory` editing-actor rule
`pack-chat-minor-edits-only` and propagated it lock-step across every governance +
encoding surface, in ONE atomic pack-only change set. All 8 tasks complete; all
verification GREEN; trinity parity byte-identical; Check 45 bijection 21→22 both
sides; Check 46 anti-restate 0 violations + spawn-rule resolution 7 rules.

| Task | File | Change type | Line delta |
|---|---|---|---|
| T1 | `CLAUDE.md` | modified (insert rule bullet) | +32 |
| T2 | `AGENTS.md` | modified (insert rule bullet, byte-identical) | +32 |
| T3 | `GEMINI.md` | modified (insert rule bullet, byte-identical) | +32 |
| T4 | `pack-ops/PACK-MEMORY-RATIONALE.md` | modified (append `## pack-chat-minor-edits-only`) | +36 |
| T5 | `pack-ops/PACK-AGENTS.md` | modified (insert NAME-only reference line) | +5 |
| T6a/T6b | `pack-ops/PACK-CHAT.md` | modified (Behavioral-rules ref bullet + 2 Role in-place replacements) | +21 / −3 |
| T7 | `pack-ops/.spawn-rule-manifest.txt` | modified (append record) | +5 |
| T8 | `test-fixtures/manifest.txt` | NO-OP (regen diff empty — see §4) | 0 |

`git diff --stat` (7 in-scope files): **160 insertions, 3 deletions.**

---

## 2. Per-task detail

### T1–T3 — Trinity corpus insert (design §3.1)
Inserted the §1 rule bullet (ARCHITECTURE-BD-208 L98–129) immediately after the
`- Pack Chat may NOT edit … those go to pack-coder.` sub-bullet (the byte-identical
end of "What Pack Chat CAN edit directly") and before
`- **Commit-approval requests include next-steps plan.**`, in all three pack-root
trinity files. Anchor was byte-identical across the three (CLAUDE L383 / AGENTS
L349 / GEMINI L316 pre-edit); the same insertion applied 3× with NO per-CLI
variation (the rule is `[roles: universal]`, no CLI-specific content).

- **Parity proof:** extracted the inserted bullet from each file (awk from the
  bold name through `[rationale: pack-chat-minor-edits-only]`); `diff CLAUDE↔AGENTS`
  and `diff CLAUDE↔GEMINI` both report IDENTICAL.
- **Slug uniqueness/count:** `grep -c 'pack-chat-minor-edits-only'` = 1 per file.
- **Re-read evidence:** post-edit the bullet sits between the
  `those go to pack-coder.` sub-bullet and the `Commit-approval requests include
  next-steps plan` bullet in all three (no other content displaced).

### T4 — Rationale section append (design §3.2)
Appended `## pack-chat-minor-edits-only` (Why + How-to-apply + Rejected-alternative,
the established 3-part shape; ARCHITECTURE-BD-208 L285–319) to the END of
`pack-ops/PACK-MEMORY-RATIONALE.md`, immediately after the
`## dependency-direction-placement` section (the prior last slug). This is the
bijection partner for the T1 corpus token; landed same-commit so Check 45 never
sees an orphan.

### T5 — PACK-AGENTS.md reference line (design §3.3)
Inserted a NAME+slug paraphrase reference line immediately after the existing
scope-in clause (`pack-coder MAY scope a per-entry directory in …`). The line
names the rule + slug and points to the corpus SSOT; it does NOT restate the
imperative body (anti-restate-safe — Check 46 PASS, 0 violations). The existing
"off-limits unless scoped in" base wording is untouched.

### T6a/T6b — PACK-CHAT.md (design §3.4)
- **T6a (Behavioral rules):** inserted a NAME+slug reference bullet after the
  `Real fixes only — no green-the-test band-aids` bullet. Paraphrase pointer to
  the corpus; anti-restate-safe.
- **T6b (Role section, OOS-2 folded in-scope):** two minimal in-place replacements
  of stale "directly at any depth" framing —
  - `- Write files directly to the repo (CLI: native file write and git)` →
    bookkeeping + new-entry-authoring-direct / route-MAJOR-to-coder framing with
    the slug pointer.
  - `You plan and execute pack changes directly, with explicit approval before any
    commit.` → "You plan pack changes; you apply bookkeeping edits + new-entry
    authoring … and route every MAJOR (landed-content / rule / out-of-set) edit to
    a pack-coder, with explicit approval before any commit."
  Neither restates the corpus body.

### T7 — Spawn-rule manifest record (design §3.5)
Appended the 4-line record (`slug:` / `canonical:` / `corpus:` / `references:`)
to `pack-ops/.spawn-rule-manifest.txt`, matching the existing record format
(7-space `slug:` padding, blank-line-separated). The `references:` line names
exactly the three surfaces edited in T5/T6a/T6b — Check 46 reference-resolution
verifies each names `## Pack memory` + the slug (PASS, 7 spawn rules resolve).

### T8 — Manifest regen (design §3.7)
Ran `bash test-fixtures/build.sh --all --clean`. `git diff test-fixtures/manifest.txt`
is **EMPTY** — the fixture manifest does not hash the four `pack-ops/` governance
files that BD-208 touched. Per plan §E G-1 (the regen non-empty/empty branch is
pre-handled) and the `regenerate-manifest-v11-surface` rule ("stage … when the
diff is non-empty"), T8 is a **NO-OP** — nothing to stage. Recorded here, no
manifest change in the commit.

---

## 3. Verification (verbatim results)

### `python3 scripts/validate-pack.py` — PASSED (exit 0)
Final line: `PASSED — all checks clean`. Key checks:
- **Check 45 (bijection):** `22 corpus [rationale: slug] pointer(s); 22 rationale
  ## <slug> section(s); sets are equal (bijection holds, no orphans in either
  direction).` (was 21/21; new slug added cleanly.)
- **Check 46 (anti-restate + manifests):** `boundary manifest: 11 surface(s)
  resolve …; spawn manifest: 7 rule(s) resolve to ## Pack memory; anti-restate:
  0 verbatim imperative-body restatements across 6 spawn-relevant surface(s)
  (47 candidate bodies scanned, >= 60 chars).` (spawn rules 6→7; 0 anti-restate
  violations — my T5/T6 reference lines stay under the 60-char body threshold.)
- **Check 18 (trinity H2 parity):** GREEN (no new H2 added; rule is a bullet
  inside the existing `### Pack Chat scope`).
- **Check 43 (project-side leak sweep):** GREEN — `zero pack-internal bare
  cross-references`.
- **Check 47 (sanctioned pack-side-shipped freeze):** GREEN — set unchanged
  `{scripts/lib/detect.sh, scripts/pack-help.sh}`.

### Parametric tests (re-run, no edits — design E-5)
- `bash scripts/tests/test-validate-pack-check-45.sh` → `PASS: 3 / FAIL: 0` — All tests passed.
- `bash scripts/tests/test-validate-pack-check-46.sh` → `PASS: 3 / FAIL: 0` — All tests passed.

### Trinity parity (T1/T2/T3)
- `diff` of the extracted inserted bullet: CLAUDE↔AGENTS IDENTICAL; CLAUDE↔GEMINI IDENTICAL.
- `grep -c 'pack-chat-minor-edits-only'` → CLAUDE 1, AGENTS 1, GEMINI 1.

### Bijection counts (manual cross-check)
- `grep -oE '\[rationale: [a-z0-9-]+\]' CLAUDE.md | sort -u | wc -l` → 22.
- Check 45 authoritative count (rationale `## <slug>` sections) → 22.

### Manifest regen (T8)
- `git diff --stat test-fixtures/manifest.txt` → empty (no-op, as detailed §2 T8).

---

## 4. Files-changed inventory

In-scope (BD-208, all 7 modified — `test-fixtures/manifest.txt` unchanged):

```
 M AGENTS.md
 M CLAUDE.md
 M GEMINI.md
 M pack-ops/.spawn-rule-manifest.txt
 M pack-ops/PACK-AGENTS.md
 M pack-ops/PACK-CHAT.md
 M pack-ops/PACK-MEMORY-RATIONALE.md
```

All 7 paths are pack-root trinity + `pack-ops/` — none under `project-template/`
or `supporting-docs/`, so the `pack-only` scope claim is honest (Check 36 / Check
43 GREEN). `test-fixtures/manifest.txt` regenerated → no diff → not in the change set.

---

## 5. Plan deviations

**ZERO functional deviations.** All 8 tasks implemented exactly per plan, on the
byte-quoted anchors (plan line-number drift notice honored — anchored on TEXT).

One plan EXPECTATION resolved to its alternate branch:
- **T8 manifest regen → EMPTY diff (no-op), not non-empty.** Plan §E G-1 flagged
  the regen result as indeterminate at plan-time and EXPECTED non-empty; the
  actual regen produced an empty diff (the manifest does not hash `pack-ops/`
  governance files). The plan pre-handled both branches; the empty branch is a
  no-op per the `regenerate-manifest-v11-surface` "stage when non-empty" clause.
  Not a deviation — a pre-specified branch.

---

## 6. New POQs introduced

None.

---

## 7. Boundary discipline check

All 7 edited files are pack-side governance (pack-root trinity + `pack-ops/`).
No `project-template/` / `supporting-docs/` / client-shipped surface was touched,
so the project-side SSOT pre-flight (P-missed-7) does not apply to any edit. The
new rule's references stay on pack-side surfaces citing pack-side SSOT (trinity
`## Pack memory` corpus). No boundary-discipline STOP.

---

## 8. Out-of-scope issue SURFACED (not fixed)

**OOS-A — pre-existing unrelated dirty file in the working tree:
`maintenance-docs/v11-implementation/PLAN-BD-203.md` is modified (`M`, +94/−75).**
This file is NOT a BD-208 task file and I did NOT edit it. It was already
modified in the working tree out-of-band (a concurrent session / Pack Chat
edit between the conversation-start "clean" snapshot and now). The diff is
BD-203-content (RESOLUTION-A re-sequencing of the dependency graph), unrelated to
BD-208. **I left it untouched** (scope-deliverables-to-the-ask; not my file).
**Action for Pack Chat:** when committing BD-208, commit ONLY the 7 BD-208
pathspecs (`git commit CLAUDE.md AGENTS.md GEMINI.md pack-ops/PACK-MEMORY-RATIONALE.md
pack-ops/PACK-AGENTS.md pack-ops/PACK-CHAT.md pack-ops/.spawn-rule-manifest.txt -m …`)
so the stray PLAN-BD-203.md change does NOT get swept into the BD-208 commit.
Disposition of PLAN-BD-203.md is a separate Pack-Chat decision, out of BD-208 scope.

**OOS-B (informational — already handled by Pack Chat).** OOS-1 (memory-cache
reconciliation of `review-cycle-position-checkpoint` #3 + `pack-chat-boundaries`
#2) is out-of-repo upkeep already DONE by Pack Chat per the spawn prompt — not a
coder deliverable. No action.

---

## 9. Definition-of-Done checklist

| DoD item | Status |
|---|---|
| T1 CLAUDE.md rule bullet inserted at correct anchor | PASS |
| T2 AGENTS.md rule bullet (byte-identical) | PASS |
| T3 GEMINI.md rule bullet (byte-identical) | PASS |
| Trinity parity — 3 bullets byte-identical (diff) | PASS |
| Slug appears exactly once per trinity file | PASS |
| T4 RATIONALE `## pack-chat-minor-edits-only` appended | PASS |
| T5 PACK-AGENTS.md NAME-only reference line (<60-char body, no restate) | PASS |
| T6a PACK-CHAT.md Behavioral-rules ref bullet | PASS |
| T6b PACK-CHAT.md Role-section 2 in-place replacements (OOS-2) | PASS |
| T7 .spawn-rule-manifest record appended, format-matched | PASS |
| T8 manifest regen run (empty diff → no-op) | PASS |
| validate-pack.py full GREEN (Checks 18/43/45/46/47) | PASS |
| test-45 parametric PASS (3/0) | PASS |
| test-46 parametric PASS (3/0) | PASS |
| Check 45 bijection 22==22 | PASS |
| Check 46 anti-restate 0 violations + 7 spawn rules resolve | PASS |
| Scope = pack-only (no project-template/ or supporting-docs/) | PASS |
| No git verbs run (agents never commit) | PASS |
| Only scoped-in files edited (7 BD-208 files) | PASS |

All DoD items PASS.

---

## 10. Rules-Applied Verification Block

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| read-in-full + NO-DERIVATION | Every named doc Read DIRECTLY via the Read tool this session — see READ-IN-FULL proof row. PLAN-BD-208 (L1–291 full) + ARCHITECTURE-BD-208 (L1–776 full) read before any edit; every edited file's region read before editing; CLAUDE.md `## Pack memory` read (incl. the new bullet); 5 curated memory files read full. No content derived. | COMPLIANT |
| preflight-stop-means-stop | Emitted the single PREFLIGHT line `PREFLIGHT: 8/8 in-scope tasks complete; verification PASS; HEAD 2cc92b9; about to Write IMPL-REPORT …` ONLY after all 8 edits + validate-pack (exit 0) + test-45 (3/0) + test-46 (3/0) PASSED. No parent stop message received. | COMPLIANT |
| agents-never-commit | Ran only read-only git verbs (`git rev-parse HEAD`, `git status`, `git diff`). No `git add`/`commit`/`push`/`tag` or any state-changing verb. HEAD unchanged at `2cc92b9`. | COMPLIANT |
| edit-in-place-not-full-rewrite | All edits TARGETED Edit calls on exact byte-quoted anchors (insert/replace); T4/T7 are APPENDS to ordered-list files; no full-file Write of any source. Re-read evidence reported per task (§2). | COMPLIANT |
| trinity parity | `diff` of the inserted bullet: CLAUDE↔AGENTS IDENTICAL, CLAUDE↔GEMINI IDENTICAL; `grep -c` = 1 per file. The bullet is `[roles: universal]` — no CLI-specific content, full parity, no exemption. | COMPLIANT |
| enumerate-encoding-surfaces | Every encoding surface moved/verified: Check 45 (bijection 22/22), Check 46 (anti-restate 0 + 7 spawn rules), Check 18 (H2 parity), test-45 (3/0), test-46 (3/0), `.spawn-rule-manifest.txt` (record added), `PACK-MEMORY-RATIONALE.md` (section added), `manifest.txt` (regen, empty). | COMPLIANT |
| manifest-regen-on-v11-surface | Ran `bash test-fixtures/build.sh --all --clean`; `git diff --stat test-fixtures/manifest.txt` empty → no-op, nothing to stage (the "stage when non-empty" clause is not triggered). Recorded §2 T8 + §5. | COMPLIANT |
| scope-deliverables-to-the-ask | Implemented exactly T1–T8; report leads with the edit summary (§1); no edge-case sprawl. The stray PLAN-BD-203.md dirty file left UNTOUCHED and surfaced (§8), not fixed. | COMPLIANT |
| rules-applied-verification-block | This block (per-rule evidence + conclusion, no empty rows, no AMBIGUOUS) + the READ-IN-FULL proof row below. | COMPLIANT |

### READ-IN-FULL proof (direct-read evidence per doc)

| Doc | Direct-read proof (first / last or range) |
|---|---|
| `PLAN-BD-208.md` | Read L1–291 (full). First: `# PLAN-BD-208 — Pack Chat editing-actor rule…` (L1); last: READ-IN-FULL row `feedback_edit_in_place_not_full_rewrite.md` (L291). |
| `ARCHITECTURE-BD-208.md` | Read L1–776 (full). First: `# ARCHITECTURE-BD-208 — Pack Chat editing-actor rule…` (L1); last: READ-IN-FULL row `feedback_scope_deliverables_to_the_ask.md` (L776). §1 rule text L97–130, §3.2 rationale L285–319 used verbatim. |
| `CLAUDE.md` `## Pack memory` | Read L376–389 (insert anchor region) pre-edit; post-edit verified the new bullet between `those go to pack-coder.` and `Commit-approval requests include next-steps plan`. Slug-set grepped (21→22). |
| `AGENTS.md` (anchor) | Read L343–354 pre-edit (anchor `those go to pack-coder.` L349 + following bullet L350); insert applied + diff-verified identical to CLAUDE. |
| `GEMINI.md` (anchor) | Read L310–321 pre-edit (anchor L316 + following bullet L317); insert applied + diff-verified identical to CLAUDE. |
| `pack-ops/PACK-MEMORY-RATIONALE.md` | Read L560–565 (file tail) pre-edit; appended after `## dependency-direction-placement`; Check 45 confirms 22 sections. |
| `pack-ops/PACK-AGENTS.md` | Read L155–164 pre-edit (scope-in clause L157–159); reference line inserted after it. |
| `pack-ops/PACK-CHAT.md` | Read L9–22 (Role) + L83–96 (Behavioral / Real-fixes-only) pre-edit; anchors `Write files directly…` (L14), `execute pack changes directly` (L20–21), Real-fixes-only bullet end (L94). All three edits applied in place. |
| `pack-ops/.spawn-rule-manifest.txt` | Read L44–52 (tail) pre-edit; trailing-byte check (`)\n`); record appended matching `bounded-review-fix-cycle` format. |
| `feedback_agents_read_rule_docs_in_full.md` | Read full (L1–97). First `name: agents-read-rule-docs-in-full`; last no-derivation clause `…required the consequences + the no-rationale-for-unread-docs rule reinforced in every spawn prompt.` |
| `feedback_agent_output_rules_applied_block.md` | Read full (L1–15). First `name: agent-output-rules-applied-block`; last `Related: [[agent-prompt-enumerates-rules]], [[architect-planner-empirical-evidence]].` |
| `feedback_edit_in_place_not_full_rewrite.md` | Read full (L1–15). First `name: edit-in-place-not-full-rewrite`; last `…[[feedback_pack_chat_no_coder_review]] (independent verification).` |
| `feedback_manifest_regen_on_v11_surface.md` | Read full (L1–16). First `name: manifest-regen-on-v11-surface`; last `Related: test-infra self-provisioning (distinct concern).` |
| `feedback_scope_deliverables_to_the_ask.md` | Read full (L1–35). First `name: scope-deliverables-to-the-ask-no-noise`; last `…the user's standing preference for terse, exactly-scoped work.` |
