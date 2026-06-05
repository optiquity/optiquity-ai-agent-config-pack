# IMPL-REPORT — BD-200 commit C4 (T5: Procedure 6 redesign)

**Role:** pack-coder (fresh). **Branch:** `v11-dev`. **HEAD:** `2d68077a1198a77921296017b972573f01bb498c` (unchanged — no state-changing git verb run).
**Date:** 2026-06-04. **Scope:** exactly T5 — redesign `supporting-docs/METHODOLOGY.md` Procedure 6 as a self-contained project-side workflow keyed to `scripts/activate-capability.sh`. No other file touched except the regenerated manifest.

---

## 1 — Files changed (inventory)

| Path | Change type |
|---|---|
| `supporting-docs/METHODOLOGY.md` | modified (Procedure 6 in-place redesign; lines 1407–1464) |
| `test-fixtures/manifest.txt` | modified (regenerated; 3 v11-* rows moved) |
| `maintenance-docs/v11-implementation/IMPL-BD-200-C4.md` | new (this report) |

Line delta on METHODOLOGY.md: **+22 / −25** (1 file). `git diff --stat` confirms the diff is confined to the Procedure 6 region (hunk headers: 1407, 1412, 1415–1417, 1432→1436, 1436→1440, 1456–1464). No edit landed outside Procedure 6; Procedure 5-S (before) and Procedure 7 (after) are byte-unchanged.

C1/C2/C3 files were NOT touched. `scripts/activate-capability.sh` was READ-ONLY (to keep the description accurate to the shipped script) — not edited. No `pack update` / pool-refresh logic added (BD-202 boundary intact).

---

## 2 — Contamination stripped (before → after, per span)

Re-measured against the planning EEB-PROC6-CONTAMINATED (PLAN §8) and the live file. All five contamination loci found and stripped, plus the pack-maintenance tail deleted.

### S1 — Heading (1407)
- **Before:** `### Procedure 6 — Adding a pack-supported capability`
- **After:** `### Procedure 6 — Activating a supported capability`
- Reason: aligns with the shipped verb (`activate-capability.sh`) and the script's own P8 prompt wording ("Activating a supported capability").

### S2 — Trigger block (1411–1416)
- **Before:** "the end-of-run prompt emitted by `scripts/add-capability.sh` stage A8" + "first instructs them to run `add-capability.sh` **from the pack** before resuming."
- **After:** "the end-of-run prompt emitted by `scripts/activate-capability.sh`" + "first instructs them to run `scripts/activate-capability.sh --add <dimension>:<value>` before resuming."
- Stripped: `add-capability.sh`, `stage A8`, `from the pack`.

### S3 — Intro paragraph (1418–1423 → 1419–1427)
- **Before:** "Procedure 6 is the PM-chat-side companion to `add-capability.sh`. The script copies the conditional pack files and runs a read-only install-check discovery; …"
- **After:** describes `scripts/activate-capability.sh` as a **self-contained project script** that re-materializes conditional files **from the tracked `pack-capability-pool/`** into the live tree, "No external clone is needed — the pool travels with the project," then names Procedure 6 as the PM-chat-side companion.
- Stripped: `add-capability.sh`; the inaccurate "read-only install-check discovery" claim (the shipped script has no tool-probe discovery stage). Added the no-pack-clone / tracked-pool framing — the whole point of C4.

### S4 — Step 6.1 (1432 → 1436)
- **Before:** "Read the `add-capability.sh` report … or read from `.pack-add-capability-prompt.md` at the project root (written by stage A8). Verify script stages A0–A8 completed. The prompt includes a **Capability install-check discovery** section …"
- **After:** "Read the `activate-capability.sh` prompt … or read from `.pack-activate-capability-prompt.md` at the project root (written by the script's final stage; the file is gitignored local state). The prompt names the activated `--add <dimension>:<value>` capabilities, lists the files re-materialized from `pack-capability-pool/`, and reports the current vs. target `**Active skills:**` line."
- Stripped: `add-capability.sh`, `.pack-add-capability-prompt.md`, `stage A8`, `stages A0–A8`, the non-existent "Capability install-check discovery" section.
- **Accuracy check against shipped script:** prompt-file name `.pack-activate-capability-prompt.md` verified at `activate-capability.sh:53` (`readonly PROMPT_FILE=...`); gitignored via `ensure_prompt_gitignored` (54, 79–85); the prompt body lists activated `--add` caps (365–367), "Files re-materialized from pack-capability-pool/" (373–377), and current vs. target Active-skills (383–384). Description matches the shipped output.

### S5 — Step 6.5 (1436 → 1440)
- **Before:** "For each missing tool listed in **the prompt's install-hint block**, render a **Form I** …"
- **After:** "Identify any machine-level tools the newly-activated dimension needs (from the dimension's `SKILL.md` content read in 6.2 and `INSTALL-PROCEDURES.md`). For each such tool not already present, render a **Form I** …"
- Reason: the shipped `activate-capability.sh` does NOT emit an install-hint block (no tool-probe stage — that was `add-capability.sh`'s A7). Repointed the Form-I source to PM-chat-side discovery from `SKILL.md` + `INSTALL-PROCEDURES.md`. **Form-I structure + G6-install gate PRESERVED.**

### S6 — "Symmetry with Procedure 7" tail (1456–1464 → 1456–1464)
- **Before:** "The discovery itself runs script-side (`add-capability.sh` **stage A7**) so the PM chat enters Procedure 6 with the discovery already done — no G6-discovery gate is needed (the script's read-only **A7** stage is G7-discovery's capability-addition equivalent)."
- **After:** "Tool discovery is PM-chat-side in step 6.5 (read from the activated dimension's `SKILL.md` and `INSTALL-PROCEDURES.md`), so no G6-discovery gate is needed — the PM chat surveys the needed tools as part of drafting and gates only the install at G6-install."
- Stripped: `add-capability.sh`, `stage A7` (×2). The Procedure-7 Form-I idempotency symmetry + the no-G6-discovery-gate conclusion are PRESERVED (now correctly attributed to PM-chat-side discovery).

### S7 — DELETED: "Adding a new capability row" pack-maintenance tail (was 1462–1467)
- **Deleted verbatim:** "**Adding a new capability row.** A new pack-supported dimension / value extends three parallel surfaces in `scripts/add-capability.sh`: `capability_skills()` … `capability_files()` … `capability_install_checks()` … Keep all three in sync — the script depends on them being parallel for stages A1, A5, and A7 respectively."
- Reason: this is pack-internal MAINTENANCE guidance (extending pack capability tables in `scripts/add-capability.sh`) — a client developer never extends pack capability tables. It leaked `add-capability.sh`, `capability_skills`/`capability_files`/`capability_install_checks`, and `stages A1/A5/A7` onto a client surface. DELETED per the prompt + PLAN T5.

---

## 3 — Preserved structure (confirmed via post-edit re-read)

Re-read lines 1403–1467 after editing. The Procedure 6 section map is intact and complete:

- **Heading** `### Procedure 6 — Activating a supported capability` (1407)
- **Trigger block** (two bullets, 1409–1417)
- **Intro paragraph** — companion-to-script framing (1419–1427)
- **Gates paragraph** — **G6-drafts / G6-install / G6-commit** all present (1429–1432) ✓
- **7-step table** — steps **6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7** all present (1434–1442); each client-correct step survives:
  - 6.2 reading on-disk `.claude/skills/<name>/SKILL.md` ✓
  - 6.3 drafting trinity placeholders + TRIO byte-identical ✓ (G6-drafts gate ✓)
  - 6.5 Form-I per-tool ✓ (G6-install gate ✓)
  - 6.6 Procedure 5.5 detection scan + `x-` / PLATFORM-SKILLS custom-region check ✓
  - 6.7 `git add` list + commit message on feature branch ✓ (G6-commit gate ✓)
- **TRIO trinity-edit contract paragraph** (1444–1445) ✓
- **Artifacts modified** list (1447–1448) ✓
- **Artifacts never touched** list (1450–1454) — `x-` files, `SKILL.md`, `BACKLOG.md`, `STATUS.md`, `ARCHITECTURE.md`, `IMPLEMENTATION-PLAN.md`, `CHANGELOG.md`, PLATFORM-SKILLS custom regions — UNCHANGED ✓
- **Symmetry with Procedure 7** paragraph (1456–1464) ✓

No orphaned references remain. Surrounding sections (Procedure 5-S at 1403–1405; Procedure 7 at 1466) are byte-unchanged (`git diff -U0` hunks all fall inside 1407–1464).

---

## 4 — Zero-pack-self grep evidence

Command (against the redesigned Procedure 6, lines 1407–1464):
```
grep -nE 'add-capability|from the pack|stage A7|stage A8|BD-[0-9]|capability_skills|capability_files|capability_install_checks|maintenance-docs/|pack-ops/|pack-architect|pack-coder|pack-reviewer|pack-planner|\$PACK|\.pack-add-capability'
```
Result: **ZERO hits — clean.**

Verb presence: `grep -cE 'activate-capability\.sh'` → **4** (verb used throughout).
Prompt-file name: `grep -oE '\.pack-[a-z-]+\.md'` → `.pack-activate-capability-prompt.md` (the actual file the shipped script writes — verified against `activate-capability.sh:53`).

Whole-file added-line check: `git diff … | grep '^+' | grep -E 'add-capability|from the pack|\$PACK|stage A[78]'` → no added line reintroduces a forbidden token.

CI enforcement confirmation (these walk the installed `docs/pack/METHODOLOGY.md`):
- **Check 43** (project-side bare cross-reference scanner): `OK — 158 project-side / client-installed file(s) walked; zero pack-internal bare cross-references`.
- **Check 37** (project-side pack-only deny-list): `OK — 170 project-side file(s) walked; zero deny-list contamination`.

---

## 5 — Section-map re-read confirmation

Performed a full Read of lines 1403–1467 after all edits (not a summary — actual bytes). Confirmed: heading renamed; trigger/intro/gates/table(6.1–6.7)/TRIO/Artifacts-modified/Artifacts-never-touched/Symmetry all present and in order; pack-maintenance tail gone; Procedure 5-S and Procedure 7 untouched. No section dropped (the `edit-in-place-not-full-rewrite` failure mode — silent section drop — did not occur; targeted Edits only, no full rewrite).

---

## 6 — Manifest rows moved

`bash test-fixtures/build.sh --all --clean` regenerated `test-fixtures/manifest.txt`. Diff (3 insertions / 3 deletions):

```
-v11-realistic-ot  53ceb9178e547f1d0215b7637f0d7abd4829ae15
-v11-flat-file     ac3186eecf2ea8d673a85f48527eb87d6c3ffe2d
-v11-tracker-on    efa3f58b531d5374b966d855fdd6b45c8eb809ec
+v11-realistic-ot  42f713787517954c502443d2de710fbc4c1b27d7
+v11-flat-file     a2a91e7e3a87e4f61c29af262558c14c5ee60473
+v11-tracker-on    05314a6c269840b3894c6703cfe8f434d6f2b6b8
```

Exactly the three **v11-*** rows moved (METHODOLOGY.md installs to `docs/pack/METHODOLOGY.md` in every v11 fixture). The `v10-minimal`, `v10-realistic-ot`, and `existing-project-mid-dev` rows are **unchanged** — they use the v10 init / pre-install shape and are unaffected by a v11-surface doc edit. This matches PLAN §4 C4 ("MOVES") and R4.

---

## 7 — validate-pack result

`python3 scripts/validate-pack.py` → **`PASSED — all checks clean`** (exit 0).

BD-200-relevant checks (quoted):
- **Check 22** (help-fragment freshness): `OK: project-template: 2 prose-referenced verb(s) all present in fragment` — `activate-capability.sh` verb resolves (unaffected by C4; ships in C3).
- **Check 43**: `OK — zero pack-internal bare cross-references` (walks installed METHODOLOGY.md). ✓
- **Check 37**: `OK — zero deny-list contamination`. ✓
- **Check 41** (`_CLIENT_INSTALLED_FILES` integrity): `OK — 37 entries … 0 drift(s)`. Unaffected.
- **Check 47** (sanctioned freeze): `OK — install-map subset == _SANCTIONED_PACK_SIDE_SHIPPED (2 entries) ['scripts/lib/detect.sh', 'scripts/pack-help.sh']` — frozen 2-tuple untouched. ✓
- **Check 39** (cmd_update symmetry): `OK — no asymmetric coverage`. Unaffected.

Check 48 emitted 14 advisory WARNs citing removed docs in `pack-ops/BACKLOG.md` / `pack-ops/CHANGELOG.md` — **pre-existing, out of C4 scope, advisory-only (exit code unaffected, NOT a gate failure)**. Not introduced by this commit; not hand-corrected (per the JC-5 soft-advisory contract).

---

## 8 — Plan deviations

**Zero plan deviations.** The redesign follows PLAN T5 (§2) + §5 + §6 and the authoritative design ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW §4.3/§4.6 exactly: verb = `activate-capability.sh`; all five EEB-PROC6-CONTAMINATED loci stripped; the pack-maintenance "Adding a new capability row" tail DELETED; Form-I/G6 gates + TRIO + Artifacts-never-touched list PRESERVED; in-place edits only (no full rewrite); manifest regenerated.

One accuracy refinement (within scope, not a deviation): the shipped `activate-capability.sh` has no tool-probe discovery stage (unlike the old `add-capability.sh` A7), so Steps 6.5 and the Symmetry-with-Procedure-7 paragraph were repointed to **PM-chat-side** tool discovery (from the dimension's `SKILL.md` + `INSTALL-PROCEDURES.md`) rather than a script-emitted install-hint block. This keeps the procedure accurate to the actual shipped script (the prompt's explicit goal: accurate to `activate-capability.sh`) while preserving the Form-I structure and the no-G6-discovery-gate conclusion. Verified against `activate-capability.sh` stages P0–P8 (no probe stage exists).

## 9 — New POQs

None.

## 10 — Definition-of-Done checklist

| Item | Status |
|---|---|
| Procedure 6 redesigned self-contained (no pack clone; runs project's own `scripts/activate-capability.sh`) | PASS |
| Zero pack-self tokens in Procedure 6 (grep ZERO) | PASS |
| Verb `activate-capability.sh` throughout | PASS |
| Prompt file = `.pack-activate-capability-prompt.md` (matches shipped script) | PASS |
| `BD-048` / any `BD-NNN` citation removed | PASS (none present after edit; grep ZERO) |
| "Adding a new capability row" pack-maintenance tail DELETED | PASS |
| G6 gates (G6-drafts / G6-install / G6-commit) preserved | PASS |
| TRIO trinity-edit contract preserved | PASS |
| "Artifacts never touched" list preserved | PASS |
| Every client-correct step (read SKILL.md, draft trinity, detection scan, commit-on-feature-branch) preserved | PASS |
| In-place edits only (no full rewrite); section map re-read confirmed | PASS |
| Surrounding sections (Proc 5-S, Proc 7) unchanged | PASS |
| Only METHODOLOGY.md + manifest touched (no C1/C2/C3 file; no activate-capability.sh edit) | PASS |
| No BD-202 logic (pack update / pool refresh) added | PASS |
| Manifest regenerated; only v11-* rows moved | PASS |
| `validate-pack.py` PASSED; Check 43/37/22 green; 41/47 frozen | PASS |
| HEAD unchanged (`2d68077`); no state-changing git verb | PASS |

---

## 11 — Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **READ-IN-FULL** | Read IN FULL (entire file, no crop): `CLAUDE.md` (541 lines, incl. `## Pack memory`); `pack-ops/PACK-AGENTS.md` (226 lines); `pack-ops/PACK-CHAT.md` (310 lines); `project-template/CLAUDE.md` (456 lines — confirms trinity rule 361–364 + project-side deny-list block 390–400). TASK SPEC/DESIGN: `PLAN-BD-200.md` (235 lines, full — §2 T5, §5, §6, §8 EEB-PROC6-CONTAMINATED); `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` §3.1 + §4.1–§4.6 + §5 + §7 (read); BD-200 entry `pack-ops/BACKLOG.md:3273–3306` (full). CURATED memory (each Read in full): `feedback_agents_read_rule_docs_in_full.md` (72 lines), `feedback_agent_output_rules_applied_block.md` (15), `feedback_manifest_regen_on_v11_surface.md` (16), `feedback_bd_pack_only_operational_rule.md` (35), `feedback_edit_in_place_not_full_rewrite.md` (15), `feedback_client_ref_delete_or_forward_look.md` (41). SOURCE: `supporting-docs/METHODOLOGY.md` Procedure 6 re-measured (1407–1467); `project-template/scripts/activate-capability.sh` (PROMPT_FILE line 53, P0 preflight 123–160, P8 write_prompt_file 336–394, stage order 412–416). | **COMPLIANT** |
| **preflight-stop-means-stop** | Emitted the single PREFLIGHT line only AFTER all edits + verification PASS (grep ZERO, validate-pack PASSED, manifest regenerated). No partial IMPL-REPORT. No parent stop directive received. | **COMPLIANT** |
| **agents-never-commit** | Only read-only git verbs used (`git rev-parse`, `git status`, `git diff`); `bash test-fixtures/build.sh` regenerated the manifest (a build step, not a git verb). NO `git add`/`commit`/`push`/`tag`. HEAD unchanged: `2d68077a1198a77921296017b972573f01bb498c`. | **COMPLIANT** |
| **boundary / no-pack-self-in-project** | Procedure 6 ships to clients as `docs/pack/METHODOLOGY.md`. Post-edit grep of the procedure for `add-capability\|from the pack\|stage A7\|stage A8\|BD-[0-9]\|capability_skills\|capability_files\|capability_install_checks\|maintenance-docs/\|pack-ops/\|pack-(architect\|coder\|reviewer\|planner)\|\$PACK\|.pack-add-capability` → **ZERO hits**. Check 43 + Check 37 both `OK` (walk the installed file). The pack-maintenance "Adding a new capability row" tail DELETED. | **COMPLIANT** |
| **edit-in-place-not-full-rewrite** | Used 5 targeted `Edit` calls (heading, trigger/intro, 6.1, 6.5, symmetry+tail) — no full-file or full-procedure rewrite. `git diff --stat` = +22/−25, hunks confined to 1407–1464. Re-read 1403–1467 after editing and confirmed the section map (all 7 steps, all 3 gates, TRIO, both Artifacts lists) intact — no silent section drop. | **COMPLIANT** |
| **client-ref delete-or-forward-look** | Each pack-asset reference classified then handled: `add-capability.sh` / `stages A7/A8` / `.pack-add-capability-prompt.md` / `BD-NNN` / `capability_*()` are genuinely pack-only on this client surface → forward-looked to the client asset `scripts/activate-capability.sh` (a real project-installed script) where a real verb is needed, and the pack-maintenance tail DELETED where no client equivalent exists. The prompt-file forward-look points at `.pack-activate-capability-prompt.md` (the file the shipped client script actually writes). | **COMPLIANT** |
| **regenerate-manifest-v11-surface** | METHODOLOGY.md is under `supporting-docs/` (v11-surface). Ran `bash test-fixtures/build.sh --all --clean`; `git diff test-fixtures/manifest.txt` shows the 3 v11-* rows moved (diff non-empty) → regenerated and left staged in the working tree for Pack Chat to commit alongside the scope edit. v10-* / existing rows unchanged. | **COMPLIANT** |
| **rules-applied-verification-block** | This §11 — per-rule name + quoted/measured evidence + terminal verdict; no empty-evidence rows; READ-IN-FULL row carries per-file proof (line counts + specific symbols/sections read). | **COMPLIANT** |
