# ARCHITECTURE-BD-195 — `## Project addenda` marker-comment pointer fix

**Scope:** the trinity `## Project addenda` HTML marker comment in
`project-template/{CLAUDE,AGENTS,GEMINI}.md`.
**Author:** pack-architect · **Branch:** v11-dev · **HEAD:** `5dc19c1` · **Date:** 2026-06-03
**Mode:** READ-ONLY analysis (this doc is the only write).

---

## VERDICT: **MODIFY** (forward-look the broken pointer; keep the semantic claim)

The marker's *semantic claim* — "project-original H2 sections that don't fit
pack-defined sections land under `## Project addenda` after a v10 → v11
migration" — is **TRUE for v11** and must be kept. Only the *pointer clause*
("See docs/pack/INSTALL-PROCEDURES.md Procedure 5-C.2 step 2.b …") is defective:
it cites a **sunset** procedure at a **non-existent** sub-step. Apply
`client-ref-delete-or-forward-look`: the asset is a genuine client-shipped
reference (case 2), so **forward-look** it to the live v11 reconciliation home
rather than delete the whole clause.

Not "leave as-is": the pointer is doubly wrong (sunset target + phantom step) —
a client following it lands on a v9.3→v10 historical procedure. Not "delete the
clause entirely": v11 reconciliation IS a manual client step (three-way sidecar
merge), so a live pointer to where that step is documented remains useful; the
clause has a correct forward-look target, so deletion would strip a working
reference. MODIFY is the minimal correct fix.

---

## Empirical evidence

### EE-1 — The marker is byte-identical across the three trinity files
- **Command:** `awk '/^## Project addenda/{c=1} c&&/-->/{...}' project-template/{CLAUDE,AGENTS,GEMINI}.md | md5`
- **Output:** all three → `f2a105dd990323df1b576b5ca68cb2aa`
- **HEAD/date:** `5dc19c1` / 2026-06-03
- **Interpretation:** the comment is identical in all three; the trinity rule requires the replacement be byte-identical ×3.
- **Conclusion:** SUPPORTED.

### EE-2 — Procedure 5-C is HISTORICAL / sunset in v11
- **Command:** `Read supporting-docs/INSTALL-PROCEDURES.md:223-236`
- **Output (verbatim, :225-231):** `> **HISTORICAL — sunset in v11.** The v9->v10 migrator and its MIGRATION-v9-to-v10.md guide were removed in v11; this procedure no longer fires for new migrations. The v11 N->N+1 migrator framework … handles customization reconciliation differently — see MIGRATION-v10-to-v11.md. Procedure 5-C is retained here as historical documentation only …`
- **HEAD/date:** `5dc19c1` / 2026-06-03
- **Interpretation:** Procedure 5-C is v9.3→v10 history; pointing a v11 client at it for a v10→v11 migration is wrong. The admonition itself names `MIGRATION-v10-to-v11.md` as the v11 home.
- **Conclusion:** SUPPORTED (problem #1 confirmed).

### EE-3 — "Procedure 5-C.2 step 2.b" does not exist (routing is at step 3.b)
- **Command:** `grep -n "5-C.2\|2\.b\|3\.b\|project-original" supporting-docs/INSTALL-PROCEDURES.md`
- **Output:** `389: ### Procedure 5-C.2 — Trinity prose (C1 / C2 / C3)` · `477:    b. **H2 is project-original (not in v10 template).**` — the project-original-H2 routing is sub-bullet **b under step 3** (line 477), and step 3.b's two routes both say "Land the section under `## Project addenda`" (lines 479, 484).
- **HEAD/date:** `5dc19c1` / 2026-06-03
- **Interpretation:** the comment cites "step 2.b"; the real location (in the sunset procedure) is step 3.b. The citation is wrong even within the historical doc. (Confirms the prior Pack-Chat mis-edit: version bumped v9.3→v10 ⇒ v10→v11 without re-checking that 5-C is historical, creating the pointer/target mismatch.)
- **Conclusion:** SUPPORTED (problem #2 confirmed).

### EE-4 — v11 routes project-original H2 under `## Project addenda` via MANUAL sidecar merge (claim still true)
- **Command:** `Read supporting-docs/MIGRATION-v10-to-v11.md:435-481` + `Read scripts/lib/migrate-v10-to-v11/checkpoint.sh:119-158`
- **Output:**
  - MIGRATION Step 2 (`## Step 2 — Review the migration report`, :435) — for `customization-detected-needs-reconciliation` files (the trinity), the migrator writes the new v11 template to the live file + saves a `<file>.v10-customized` sidecar; the user manually merges customizations into the new template (:452-481). The v11 template ships the `## Project addenda` H2 (empty); project-original sections that don't fit pack H2s land there during that manual merge.
  - `checkpoint_check_trinity_addenda` (:128-158) greps each trinity file for `^## (Project memory|Project addenda)` as the v11-shape proof — i.e. v11 SHIPS and verifies the `## Project addenda` H2.
- **HEAD/date:** `5dc19c1` / 2026-06-03
- **Interpretation:** v11 has no automated "route H2 under addenda" step; reconciliation is the three-way sidecar **manual** merge. But the destination of project-original H2 sections in that merge is still `## Project addenda`. The marker's semantic claim is therefore TRUE for v11 — only the workflow pointer needs to move from the sunset 5-C to the v11 Step 2.
- **Conclusion:** SUPPORTED.

### EE-5 — The v11 reconciliation anchor resolves
- **Command:** `grep -n "^## Step 2 — Review the migration report" supporting-docs/MIGRATION-v10-to-v11.md`
- **Output:** `435:## Step 2 — Review the migration report`
- **HEAD/date:** `5dc19c1` / 2026-06-03
- **Interpretation:** the forward-look anchor `MIGRATION-v10-to-v11.md § "Step 2 — Review the migration report"` exists. The trinity manual-merge workflow lives at :466-481 under that heading.
- **Conclusion:** SUPPORTED.

### EE-6 — Reference style: the migration guide is cited by BARE filename across client-shipped surfaces
- **Command:** `grep -rn "MIGRATION-v10-to-v11.md" project-template/ supporting-docs/` + `ls project-template/docs/pack/INSTALL-PROCEDURES.md` + `grep "INSTALL-PROCEDURES" scripts/init-project.sh`
- **Output:**
  - `MIGRATION-v10-to-v11.md` is referenced as a **bare filename** (no path prefix) in SETUP-NEW.md, SETUP-EXISTING.md, INSTALL-PROCEDURES.md:135, and the 5-C sunset admonition itself.
  - `MIGRATION-v10-to-v11.md` is NOT staged into a client tree (no `init-project.sh` install-map row); it lives only at pack `supporting-docs/` and is read during migration. So a `docs/pack/MIGRATION-…` path would NOT resolve client-side.
  - `INSTALL-PROCEDURES.md` IS staged to `docs/pack/INSTALL-PROCEDURES.md` (`init-project.sh:579/581/1187`) — which is why the current comment's `docs/pack/INSTALL-PROCEDURES.md` path is itself correct, only the *procedure* is wrong.
- **HEAD/date:** `5dc19c1` / 2026-06-03
- **Interpretation:** the correct forward-look target is the **bare filename** `MIGRATION-v10-to-v11.md` (matches established style, avoids asserting a non-existent client `docs/pack/` path).
- **Conclusion:** SUPPORTED.

### EE-7 — No validator / test / fixture asserts the broken pointer text (Check 16 only asserts the prefix)
- **Command:** `grep -rn "Project addenda go here\|5-C.2 step 2.b\|reconciliation workflow" scripts/ test-fixtures/` + `Read scripts/validate-pack.py:1840-1851`
- **Output:**
  - Check 16 (`validate-pack.py:1844`) asserts only the substring **`"<!-- Project addenda go here"`** (and `## Project addenda` H2 presence). It does NOT assert the "Procedure 5-C.2 step 2.b" tail.
  - `scripts/tests/test-validate-pack-check-16.sh` fixtures use truncated forms (`<!-- Project addenda go here. -->`) — they do not pin the full pointer string.
  - No occurrence of `5-C.2 step 2.b` anywhere in `scripts/` or `test-fixtures/`.
- **HEAD/date:** `5dc19c1` / 2026-06-03
- **Interpretation:** the MODIFY is safe as long as the replacement comment still OPENS with `<!-- Project addenda go here` and keeps the `## Project addenda` H2. No test/validator update required for the pointer change.
- **Conclusion:** SUPPORTED.

---

## Exact replacement text (byte-identical ×3 — paste into all three trinity files)

Replace the current 5-line comment block (the `<!-- … -->` after `## Project
addenda`) in `project-template/CLAUDE.md` (:450-454), `project-template/AGENTS.md`
(:426-430), and `project-template/GEMINI.md` (:479-483) with:

```
<!-- Project addenda go here. Project-original H2 sections that don't
fit into pack-defined sections above land under this heading when you
reconcile your customizations during a v10 → v11 migration. See
MIGRATION-v10-to-v11.md § "Step 2 — Review the migration report" for
the reconciliation workflow. New projects start with this H2 empty.
The marker is preserved across pack upgrades. -->
```

Notes on the wording change (beyond the pointer):
- Opening token `<!-- Project addenda go here` is preserved verbatim → Check 16 still passes (EE-7).
- "after a v10 → v11 migration" → "when you reconcile your customizations during a
  v10 → v11 migration" — aligns the prose with the v11 MANUAL sidecar-merge model
  (EE-4); v11 does not auto-route, the user lands the section during reconciliation.
- Pointer → bare-filename `MIGRATION-v10-to-v11.md` + a resolving `§` anchor (EE-5, EE-6).

---

## Governing-rule justification

- **`client-ref-delete-or-forward-look` (governing).** The marker is a
  client-shipped reference (trinity installs as the project-root `CLAUDE.md` /
  `AGENTS.md` / `GEMINI.md`). The referenced asset is a **genuine project-facing
  migration doc**, not a pack-only artifact → **case 2: forward-look**, not
  delete. The forward-look target is the live v11 reconciliation home
  (`MIGRATION-v10-to-v11.md § Step 2`), cited by the bare filename the rest of
  the client surface already uses (EE-6).
- **`bd-pack-only-operational-rule` / `pack-project-separation`.** The fix
  introduces no pack-self leak: `MIGRATION-v10-to-v11.md` is a version-history
  migration doc (an explicitly LEGITIMATE reference class per the pack-only
  rule), carries no BD / pack-* / maintenance-docs reference, and the comment
  stays in client vocabulary. No pack-operational concept crosses into the
  client surface.
- **`preliminary-triage-architect-challenge` (challenge performed).** Challenged
  leave-as-is (rejected: pointer doubly wrong, EE-2/EE-3) and delete-clause
  (rejected: v11 reconciliation is a real manual client step with a valid
  forward-look target, EE-4/EE-5). MODIFY stands.

---

## Ripple (complete)

1. **Trinity parity — 3 files, byte-identical.** Edit
   `project-template/{CLAUDE,AGENTS,GEMINI}.md` in ONE commit. No tool-specific
   asymmetry (this is prose, not a Claude-specific mechanism). (EE-1)
2. **Validators / tests — none required.** Check 16 asserts only the
   `<!-- Project addenda go here` prefix, preserved by the replacement; no
   test/fixture pins the pointer text. (EE-7)
3. **Manifest regen.** `project-template/` is a v11-surface; the coder/PM MUST
   regenerate `test-fixtures/manifest.txt` (`bash test-fixtures/build.sh --all
   --clean`) and stage it in the SAME commit if the manifest diff is non-empty
   (trinity `regenerate-manifest-v11-surface`).
4. **PM-only, Pack-Chat-direct.** `project-template/` trinity is PM-only per
   `PACK-AGENTS.md` § "PM-only files and directories" → Pack-Chat-direct edit
   (no pack-coder required); commit-subject keyword `PM-only` is valid (Check 36
   permits `project-template/` trinity under PM-only).
5. **Out-of-scope, do NOT touch:** `PM-CHAT.md:928` points at Procedure **5-C.3**
   (PM-CHAT sidecar reconciliation) — a *different* sub-procedure, correctly
   formed, unrelated to the addenda marker. Leave it. The sunset Procedure 5-C
   block in `supporting-docs/INSTALL-PROCEDURES.md` is correct as historical
   documentation — do not alter it for this finding.

---

## Rules-Applied Verification Block

| Rule | Evidence (quoted) | Conclusion |
|---|---|---|
| agents-never-commit | No `git add/commit/push/tag` run; only this doc written via `cat >`. Bash calls were `git rev-parse`/`grep`/`awk`/`ls` (read-only). | COMPLIANT |
| agents-read-rule-docs-in-full | Read IN FULL: pack-root `CLAUDE.md` (incl. `## Pack memory`), `pack-ops/PACK-AGENTS.md`, `pack-ops/PACK-CHAT.md`, `project-template/CLAUDE.md`, and the 9 curated memory files (`agents-read-rule-docs-in-full`, `client-ref-delete-or-forward-look`, `bd-pack-only-operational-rule`, `pack-project-separation`, `architect-planner-empirical-evidence`, `edit-in-place-not-full-rewrite`, `preliminary-triage-architect-challenge`, `scope-deliverables-to-the-ask`, `agent-output-rules-applied-block`). No skim/crop. | COMPLIANT |
| client-ref-delete-or-forward-look | Asset classified case 2 (genuine project doc) → forward-look to `MIGRATION-v10-to-v11.md § Step 2`; not deleted (EE-2/EE-5/EE-6). | COMPLIANT |
| empirical-evidence-blocks | EE-1…EE-7 each carry command + verbatim output + HEAD `5dc19c1`/2026-06-03 + interpretation + SUPPORTED. | COMPLIANT |
| preliminary-triage-architect-challenge | Challenged leave-as-is and delete-clause explicitly; decided MODIFY with rationale (Governing-rule justification §). | COMPLIANT |
| bd-pack-only-operational-rule + pack-project-separation | Replacement adds a version-history migration-doc reference (LEGITIMATE class); no BD / pack-* / maintenance-docs / pack-ops leak; client vocabulary preserved (Ripple #5, Justification §). | COMPLIANT |
| scope-deliverables-to-the-ask | Output = verdict + exact ×3 text + resolving anchor + governing-rule justification + ripple. No coverage tables / SUSPECTED / open-question sprawl. | COMPLIANT |
| rules-applied-verification-block | This table; every row has quoted evidence + terminal conclusion. | COMPLIANT |
| preflight-stop-means-stop | No fabrication; every state-claim backed by a run command; no parent stop received. | COMPLIANT |
