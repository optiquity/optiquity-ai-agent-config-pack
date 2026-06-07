# IMPL-REPORT — BD-204 C-RS (entry re-scope, FIRST of the lossless-fix sequence)

- **Agent:** pack-coder
- **Branch:** v11-dev
- **Base HEAD (pre-flight + final):** `454191a9693c284095d21f04662e0f501e99950e`
  (no commits made — `agents-never-commit`; the edit is left in the working tree)
- **Scope keyword:** `pack-only`
- **Commit subject (for Pack Chat, per PLAN-BD-204 §3.LF.2):**
  `docs: v11 — BD-204 re-scope: lossless field-carrier fix + Option-A archive wording (pack-only)`

---

## 1. Task summary

C-RS is the FIRST commit of the BD-204 lossless-fix sequence. It re-scopes
`backlog/BD-204.md` so no downstream coder reads a stale "the carrier is solved"
directive. Two changes only, both authoritative-text-verbatim from
ARCHITECTURE-BD-204-LOSSLESS-FIX.md §5.a:

1. **ADD** one authoritative field block — the `LOSSLESS FIELD-CARRIER +
   GH-RULES FIX (...)` section — to the entry body.
2. **FIX** the `Scope:` line's dogfood-sequence wording to the SETTLED Option-A
   text.

No other field line touched. No `Status:` / `Target:` / `Type:` / line-2
canonical bold-header change.

### Files changed (inventory)

| Path | Change type |
|---|---|
| `backlog/BD-204.md` | modified (1 insertion of a new field-block line; 1 line replaced) |

`git status --short` after the edit: `M backlog/BD-204.md` (the ONLY entry).
`git diff --stat`: `1 file changed, 2 insertions(+), 1 deletion(-)`.

No new files. No deletions. `test-fixtures/manifest.txt` NOT touched (see §4).

---

## 2. The two changes — before / after

### Change 1 — ADD the authoritative section (new field block, inserted before `References:`)

The block was inserted as a NEW field-block line between the existing
`IMPLEMENTATION CARRY-FORWARD` line (line 23) and the `References:` line, so all
pre-existing lines move down by exactly one but are byte-unchanged. Text is
verbatim from design §5.a's fenced block, with the explicit CREDENTIAL clause
(PAT archive-only, no delete) and the IMPLEMENTATION CARRY-FORWARD NOTE folded
in per §5.a's surrounding prose ("the credential can archive but NOT delete";
"surface as a NOTE, do not re-open").

**Before:** (no such section existed; line 24 was `References: ...`)

**After (new line 24, verbatim):**

```
LOSSLESS FIELD-CARRIER + GH-RULES FIX (user 2026-06-06/07 — CRITICAL, supersedes the prior carrier language; grounded in the 28-rule GH-Issues census + the tracker-landscape census): The C-1..C-6 forward migrator carried a 9-field whitelist and SILENTLY DROPPED 19 other top-level field classes (Target/Position/Scope/Problem/Goal/Out of scope/References/Acceptance criteria/Encapsulation/Surfaced/Steps/Risk note/Quality bar/Pipeline/Paused/Note/Disposition/Alias) — and CORRUPTED prose blocks into the `unblocks` list — while full CI passed green. The `pack-extra-fields` carrier the prior design named is DEAD code. THE FIX (ARCHITECTURE-BD-204-LOSSLESS-FIX.md): make the migrator FIELD-FAITHFUL via a VERBATIM-BODY BLOB — forward gzip(mtime=0)+base64-encodes each entry's complete body verbatim (lines 2..EOF) into one Issue-body marker `<!-- pack-entry-body-gz64: ... -->`; reverse base64-decodes+gunzips it back byte-for-byte (NO field re-parse). Decode is FAIL-LOUD on a corrupt blob (never silent-empty). ZERO per-field carve-outs; NO entry is rewritten. SIZE: budgeted on STORED BYTES against the provider's declared `provider_body_limit` (GH 65,536); worst entry BD-136 = 40,771 bytes (62.2%) under gz64; the forward composer FAILs loud (never truncates) above `limit − margin`. PORTABILITY: the blob is the RAW-TEXT-BODY-CLASS carrier; the provider declares `provider_body_storage_format` (raw_text vs rich_text_normalizing) — GitLab/Redmine/Shortcut FIT, Jira Cloud MISFITS (32,767 cap + ADF rewriting). Same provider contract, class-appropriate carriers. OPERATIONAL (real-repo C-8): the create loop PACES writes (≥1s between creates, honor retry-after) to stay under GH's 80/min + 500/hr secondary cap and avoid abuse-flagging; the composer NEUTRALIZES `#NNN`/`@` autolink/mention triggers in the VISIBLE H2 PROJECTION ONLY (blob untouched) so the 211-issue create scatters no spurious backlinks / mention notifications (21 `#NNN` + 2 bare-`@` entries). CREDENTIAL: the PAT can create/write/archive but has NO repo-delete — scratch disposal is ARCHIVE-only (the tool never deletes); a manual delete is a USER-only step the run RECOMMENDS. GO-FORWARD GUARDS: the CI guard also enforces title ≤ 256 (R-TITLE-1; BD-208 worst at 231) and no NUL/CR/control byte in a body (R-BODY-6), so a future entry cannot silently introduce a violation. CI: validate-pack `check_migrator_field_faithfulness` (next registry integer) asserts byte-faithful round-trip + size + title + control-char on the REAL tree every push (un-mergeable on regression); wired into validate-pack.yml (Check 42). v11.0 launch-gate (no deferral); lands BEFORE the C-8 flip. NOTE: the prior IMPLEMENTATION CARRY-FORWARD `Deferred` forward-encode item is already landed (`_tmf_labels_for_entry` `Deferred → status:deferred`) — not re-opened.
```

This faithfully encodes design §5.a §3.3 (verbatim-body-blob carrier), §3.3c
(stored-byte size budget + fail-loud overflow), §3.3d (paced create +
autolink/mention neutralization of the H2 projection only), §3.3e (go-forward
title/control-char guards), §4 (`check_migrator_field_faithfulness` CI guard),
and the §5.f / `reference_gh_pat_no_delete` credential contract.

### Change 2 — FIX the `Scope:` line dogfood wording to Option-A (line 20, in place)

**Before (the dogfood clause on line 20):**

```
Dogfood-sequence gated (scratch-repo proof → archive → real flip) per user direction.
```

**After (the dogfood clause on line 20, verbatim design §5.a):**

```
Dogfood-sequence gated (REPEATABLE scratch-repo proof — as many throwaway scratch repos as needed, each ARCHIVED at end + a manual-delete recommendation to the user — then, on a green rehearsal + explicit user approval, flip the REAL (never-archived, stays-editable) pack repo) per user direction.
```

Only the trailing sentence of line 20 changed; the rest of the `Scope:` line
(design / implement / `tracker.toml` / CRUD / monolith machinery / Pack Feedback
/ capability matrix clauses) is byte-unchanged.

---

## 3. Byte-unchanged attestation for all other fields

After editing I re-read the full file (`backlog/BD-204.md`, lines 1–28). Mapping
of pre-edit lines (1–27) to post-edit lines:

| Pre-edit line | Field | Post-edit line | State |
|---|---|---|---|
| 1 | `<!-- per-entry source ... -->` backpointer | 1 | byte-unchanged |
| 2 | `**BD-204 — ...**` canonical bold-header | 2 | **byte-unchanged** (line-2 invariant held) |
| 3 | `Type:` | 3 | byte-unchanged |
| 4 | `Status: Open` | 4 | byte-unchanged |
| 5 | `Target:` | 5 | byte-unchanged |
| 6 | `Blockers:` | 6 | byte-unchanged |
| 7 | `Unblocks:` | 7 | byte-unchanged |
| 8 | `HARD CONSTRAINT` | 8 | byte-unchanged |
| 9 | `DESIGN BASELINE` | 9 | byte-unchanged |
| 10 | `REVERSIBILITY` | 10 | byte-unchanged |
| 11 | `SSOT / MIRROR MODEL` | 11 | byte-unchanged |
| 12 | `GENERALIZABLE` | 12 | byte-unchanged |
| 13–16 | `DECISION TIERS` block | 13–16 | byte-unchanged |
| 17 | `PACK FEEDBACK` | 17 | byte-unchanged |
| 18 | `CAPABILITY-INFORMED` | 18 | byte-unchanged |
| 19 | `Problem:` | 19 | byte-unchanged |
| 20 | `Scope:` | 20 | **CHANGE 2** (dogfood clause only) |
| 21 | `Out of scope:` | 21 | byte-unchanged |
| 22 | `Acceptance criteria` | 22 | byte-unchanged |
| 23 | `IMPLEMENTATION CARRY-FORWARD` | 23 | byte-unchanged |
| — | (none) | 24 | **CHANGE 1** (new section, inserted) |
| 24 | `References:` | 25 | byte-unchanged |
| 25 | `Resolved: n/a` | 26 | byte-unchanged |
| 26 | `Position:` | 27 | byte-unchanged |

`git diff --stat` confirms the minimal blast radius: `1 file changed,
2 insertions(+), 1 deletion(-)` — exactly the one new line + the one replaced
line, no incidental reflow. `Status:` / `Target:` / `Type:` / the line-2
canonical bold-header are untouched.

---

## 4. Verification evidence (FULL unattended battery)

### 4.1 `validate-pack.py`

```
python3 scripts/validate-pack.py  →  "PASSED — all checks clean" (exit 0)
```

- **Canonical-header guard / per-entry parse:** the entry still parses
  (validate-pack PASSED; if line-2 or the entry span were malformed, the
  per-entry checks would FAIL — they did not).
- **Check 33 (per-entry `_toc.md` in-sync):**
  `OK: backlog/_toc.md byte-identical (21565 bytes)` /
  `OK: changelog/_toc.md byte-identical (582 bytes)`.
  The body-only re-scope did NOT change BD-204's ID/status/title, so `_toc.md`
  stayed byte-identical — NO drift, NO regeneration needed (and none performed).
- **Check 34 (cross-reference integrity):**
  `OK: cross-reference integrity: 2699 reference(s) across 222 per-entry file(s);
  all resolved`.

### 4.2 Full workflow battery (every `run:` step in `.github/workflows/validate-pack.yml`)

All 54 enumerated steps run locally; every one PASS. Result groups:

| Battery group | Result |
|---|---|
| `validate-pack.py` | PASS (PASSED — all checks clean) |
| `test-detect.sh` | PASS |
| `tracker-*-test.sh` (provider/config/init/agent-read/migrate-forward/migrate-reverse/migrate-roundtrip/errors/config-schema) | PASS |
| `test-tracker-phase-task.sh` / `test-tracker-links.sh` / `test-tracker-cycle-check.sh` | PASS |
| `recommendation-state-schema-test.sh` / `recommendation-test.sh` | PASS |
| `test-per-entry.sh` | PASS |
| `test-validate-pack-checks-32-33-34.sh` / `-36-37-38.sh` | PASS |
| `test-validate-pack-check-{39,40,41,18,16,19,42,43,44,45,46}.sh` | PASS |
| `test-validate-pack-check-removed-doc-advisory.sh` | PASS |
| `tracker-bd{129,130,132,133,134}-*.sh` | PASS |
| `pack-help-test.sh` / `test-customization-preserve.sh` / `test-init-project.sh` | PASS |
| `test-migrate-v10-to-v11{,-dry-run,-gates,-decompose}.sh` | PASS |
| `test-migrator-core.sh` / `test-migrator-manifest.sh` / `test-migrator-capability-translation.sh` | PASS |
| `test-fixtures/build.sh --all --clean` / `build.sh --verify` | PASS |
| `test-v11-realistic-ot.sh` (banner-pinning integration) | PASS |
| `test-migrator-skills.sh` / `test-persona-contracts.sh` | PASS |
| `template-translations-test.sh` / `template-version-test.sh` / `test-issue-forms.sh` | PASS |

(Captured in three batched runs — all reported `BATCH{1,2,3}_FAIL=0`.)

### 4.3 Manifest (NOT regenerated, NOT staged)

`backlog/` is NOT a v11-surface dir (v11-surface = `project-template/`,
`scripts/`, `pack-ops/`, `supporting-docs/`), so no manifest regen is expected.
Evidence:

- Snapshot before: `f4ce9edeb92931adab0a98ac4fe52d0c4e8238f9  test-fixtures/manifest.txt`
- After running `build.sh --all --clean` (which rewrites the manifest):
  `shasum -c /tmp/manifest-before.sha → test-fixtures/manifest.txt: OK` (byte-identical).
- `git status --short test-fixtures/manifest.txt` → empty (no change; not staged).

---

## 5. Plan deviations

**Zero.** The two changes match PLAN-BD-204 §3.LF.2 step 1 (ADD the §5.a section
block) and step 2 (REPLACE the `Scope:` dogfood clause with the §5.a Option-A
wording) exactly, with the §5.a step-3 IMPLEMENTATION CARRY-FORWARD treated as a
NOTE (not re-opened). Insertion point (before `References:`) is "a new field
block" per the plan's "Insert it as a new field block; do NOT rewrite other field
lines" — chosen because it keeps the trailing `References:`/`Resolved:`/`Position:`
fields contiguous and leaves every other line byte-unchanged.

---

## 6. New POQs introduced

**None.** The architecture (ARCHITECTURE-BD-204-LOSSLESS-FIX.md §5.a) and plan
(§3.LF.2) fully determined the text and the insertion approach; no design gap
encountered.

---

## 7. Boundary discipline check

This edit touches `backlog/BD-204.md` — a **pack-ops / pack-chat-only** file,
NOT a project-side surface (`project-template/` / `supporting-docs/`). The
P-missed-7 project-side-SSOT pre-flight is therefore **N/A** (no project-side
file edited). The file was SCOPED INTO this coder prompt by Pack Chat (the
supported path for a MAJOR edit to landed pack-chat-only content per
`pack-chat-minor-edits-only`). No project-template/ or supporting-docs/ path
touched → `pack-only` keyword is valid.

---

## 8. Definition-of-Done checklist

| Item | Status |
|---|---|
| Change 1: §5.a authoritative section added verbatim | PASS |
| Change 2: `Scope:` dogfood clause → Option-A wording verbatim | PASS |
| Line-2 canonical bold-header byte-identical | PASS |
| `Status:`/`Target:`/`Type:` and all other fields byte-unchanged | PASS |
| `validate-pack.py` GREEN (incl. canonical-header parse, Check 33 toc-sync, Check 34) | PASS |
| `_toc.md` NOT regenerated (no drift; body-only change) | PASS |
| FULL workflow battery GREEN (all 54 steps) | PASS |
| Manifest unchanged + NOT staged (backlog/ is not v11-surface) | PASS |
| `pack-only` scope clean (only `backlog/BD-204.md` modified) | PASS |
| No git state change (no add/commit/push) | PASS |
| Edit-in-place (targeted, not full rewrite); re-read confirmed | PASS |

---

## 9. Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| `agents-never-commit` | No `git add`/`commit`/`push`/`tag` run. Final `git rev-parse HEAD` = `454191a9693c284095d21f04662e0f501e99950e` (== base HEAD; unchanged). `git status --short` shows only ` M backlog/BD-204.md` in the working tree. | COMPLIANT |
| `per-action-approval-sub-agents` | No destructive op performed (no `rm`, no overwrite of a trusted file beyond the single in-scope `Edit` calls on BD-204.md; `build.sh` is a read-only-to-repo fixture regen whose output was verified byte-identical and not staged). | COMPLIANT |
| `preflight-stop-means-stop` | Emitted the single PREFLIGHT line `PREFLIGHT: 1/1 in-scope edit complete; verification PASS; HEAD 454191a...; about to Write IMPL-REPORT to ...` only AFTER validate-pack + the full battery all returned PASS. No parent stop/halt received. | COMPLIANT |
| `edit-in-place-not-full-rewrite` | Two targeted `Edit` calls (one replace, one insert-before-`References:`); NOT a Write/full-rewrite. Re-read full file (1–28) post-edit; §3 maps every pre-existing line to its post-edit line, all byte-unchanged except the two intended changes; `git diff --stat` = `2 insertions(+), 1 deletion(-)`. | COMPLIANT |
| `verify-full-ci-suite` | Ran the ENTIRE unattended battery enumerated from `.github/workflows/validate-pack.yml` (54 steps incl. integration `test-v11-realistic-ot.sh` + `build.sh --verify`), not a subset; all PASS (`BATCH{1,2,3}_FAIL=0`). | COMPLIANT |
| `scope-deliverables-to-the-ask` | Exactly the add + the wording fix; nothing else changed. Only `backlog/BD-204.md` modified; no other file, no manifest, no toc. | COMPLIANT |
| `boundary-investigation-precedes-pack-defaults` | Only `backlog/BD-204.md` (pack-ops, pack-chat-only scoped in) edited; no project-side file touched → P-missed-7 pre-flight N/A (documented §7). `pack-only` keyword valid. | COMPLIANT |
| `rules-applied-verification-block` | This block: each rule named with quoted command/file evidence + terminal conclusion; no empty-evidence rows. | COMPLIANT |
| `regenerate-manifest-v11-surface` | `backlog/` is not a v11-surface dir; manifest shasum byte-identical before/after `build.sh --all --clean`; `git status` shows manifest unstaged/unchanged. No regen owed. | N/A: no v11-surface file touched (verified byte-identical) |
