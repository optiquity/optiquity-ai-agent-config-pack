# PACK-REVIEW — BD-204 C-RS (entry re-scope; FIRST of the lossless-fix sequence)

- **Reviewer:** pack-reviewer
- **Branch:** v11-dev
- **HEAD (review base):** `454191a9693c284095d21f04662e0f501e99950e`
- **Date:** 2026-06-07
- **Scope under review:** working-tree diff of `backlog/BD-204.md` (+ the untracked
  IMPL-REPORT-BD-204-C-RS.md). `pack-only`. Markdown/entry-only.
- **Source of truth for the change:** `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §5.a
  (+ §3.3 / §3.3c / §3.3d / §3.3e / §4 / §5.f for mechanism faithfulness);
  recipe `PLAN-BD-204.md` §3.LF.2 + `PLAN-BD-204-LOSSLESS-FIX-SEQUENCE.md` C-RS row.

---

## VERDICT: PROCEED (clean; ready to commit)

The C-RS change is exactly the two design-§5.a-sourced edits, byte-faithful to
the authoritative text, additive-only on every other field, validator-green, and
boundary-clean. No BLOCKER, no MUST, no SHOULD, no NIT. Calibration honored: this
is a 2-line additive entry edit applying reviewed design text, and it is correct.

---

## 1. FAITHFULNESS to design §5.a — PASS

**CMD (semantic byte-compare of the inserted block core vs the design fenced
block, §5.a lines 885–911, flattening newlines+indentation to single spaces and
joining the slash-delimited field list across its line-wrap):**

```
python3 -c "<flatten design[884:911]; strip the entry's folded CREDENTIAL+NOTE
clauses; compare>"
→ CORE == DESIGN (slash-join fixed): True
```

**CONCL — the inserted block's CORE is byte-faithful to the §5.a fenced block.**
The ONLY non-whitespace artifact during the compare was at the slash-delimited
field list `…/Acceptance criteria/\n  Encapsulation/…` which wraps mid-list in
the design's fenced rendering; the entry correctly joins it WITHOUT a space
(`Acceptance criteria/Encapsulation`), which is the correct flattening of a
single `A/B/C` slash list — faithful, not drift.

**The two folded-in clauses are both sourced inside §5.a's authorized scope** (the
design says "Add ONE authoritative section … + the one BD-204.md:20 wording fix"):

- **CREDENTIAL clause** — sourced from §5.a / §5.f prose (lines 919–920:
  "the credential can archive but NOT delete — see §5.f); the run additionally
  RECOMMENDS a manual delete to the user (tooling never deletes)"). The entry's
  "the PAT can create/write/archive but has NO repo-delete — scratch disposal is
  ARCHIVE-only (the tool never deletes); a manual delete is a USER-only step the
  run RECOMMENDS" is a faithful condensation and matches
  `reference_gh_pat_no_delete` verbatim in substance (PAT archive-only / no
  delete / manual user-only delete / tool RECOMMENDS).
- **NOTE clause** — sourced from §5.a prose (lines 926–927: "The IMPLEMENTATION
  CARRY-FORWARD line (Deferred forward-encode) is already landed
  (`_tmf_labels_for_entry` `Deferred → status:deferred`) — surface as a NOTE, do
  not re-open"). The entry's "NOTE: the prior IMPLEMENTATION CARRY-FORWARD
  `Deferred` … already landed (`_tmf_labels_for_entry` `Deferred →
  status:deferred`) — not re-opened" is faithful.

**Mechanism / fact spot-checks (all match §3.3 / §3.3c / §3.3d / §3.3e / §4):**
gz64 verbatim-body-blob (gzip mtime=0 + base64, lines 2..EOF, marker
`<!-- pack-entry-body-gz64: ... -->`, reverse decode + FAIL-LOUD on corrupt blob);
9-field whitelist that DROPPED 19 field classes + corrupted prose into `unblocks`;
`pack-extra-fields` = DEAD code; SIZE budget on STORED BYTES vs
`provider_body_limit` (GH 65,536), worst BD-136 = 40,771 bytes (62.2%), fail-loud
above `limit − margin`; PORTABILITY raw_text vs rich_text_normalizing
(GitLab/Redmine/Shortcut FIT, Jira Cloud MISFITS 32,767 + ADF); OPERATIONAL paced
create ≥1s + 80/min + 500/hr cap + H2-projection-only autolink neutralization
(21 `#NNN` + 2 bare-`@`); GO-FORWARD title ≤ 256 (R-TITLE-1, BD-208 worst 231) +
no NUL/CR/control byte (R-BODY-6); CI `check_migrator_field_faithfulness` (next
registry integer) wired into validate-pack.yml (Check 42); v11.0 launch-gate (no
deferral) before C-8. **No editorialization, no field-count drift, no rule-value
drift, no claim the design does not make.**

---

## 2. ADDITIVE-ONLY — PASS

**CMD:** `git diff --stat backlog/BD-204.md`
**OUT:** `1 file changed, 2 insertions(+), 1 deletion(-)`

**CMD (line-2 invariant):** `git diff backlog/BD-204.md | grep '^[-+]' | grep -i 'BD-204 —'`
**OUT:** *(empty)* → the canonical bold-header line-2 `**BD-204 — …**` is NOT in
the diff = **byte-identical.**

**CMD (enumerate changed lines):** `git diff … | grep -E '^[-+]' | grep -v '^[-+][-+]'`
**OUT:** exactly TWO `+` lines (the reworded `Scope:` line + the new field block)
and ONE `-` line (the old `Scope:` line). Every other field —
`Status: Open` / `Target:` / `Type:` / `Blockers:` / `Unblocks:` /
`Resolved: n/a` / `Position:` and all prose fields — is byte-unchanged. **No
silent edit to any other field.** CONCL: additive-only invariant HELD.

---

## 3. OPTION-A CORRECTNESS — PASS

**CMD (verbatim compare of the reworded dogfood clause vs design §5.a lines 923–925):**
```
DESIGN : Dogfood-sequence gated (REPEATABLE scratch-repo proof — as many throwaway
         scratch repos as needed, each ARCHIVED at end + a manual-delete
         recommendation to the user — then, on a green rehearsal + explicit user
         approval, flip the REAL (never-archived, stays-editable) pack repo) per
         user direction.
ENTRY  : <identical>
MATCH  : True
```

The reworded clause states the REAL repo is **never-archived, stays-editable**;
scratch disposal is **ARCHIVE-only** with a **manual-delete recommendation to the
user** (the PAT cannot delete — matches §5.f + `reference_gh_pat_no_delete`); the
proof is **REPEATABLE** (as many throwaway scratch repos as needed). The old
"scratch-repo proof → archive → real flip" ambiguity is fully removed from the
`Scope:` line (confirmed in the `-` diff line). CONCL: Option-A correct; no
residue.

---

## 4. GRAMMAR / VALIDATOR — PASS

**CMD:** `python3 scripts/validate-pack.py ; echo EXIT=$?`
**OUT:** `PASSED — all checks clean` / `EXIT=0`.

- **Canonical line-2 header / per-entry parse:** PASS (validate-pack green; a
  malformed line-2 or entry span would fail the per-entry checks — none did). The
  new field block is a valid free-text field-block line per `backlog/_rules.md`
  Entry contract (one entry per file; HTML-comment backpointer above the
  bold-header; standard BACKLOG field format; free-text field blocks admitted).
- **Check 33 (per-entry `_toc.md` in-sync):** `OK: backlog/_toc.md byte-identical
  (21565 bytes)` / `OK: changelog/_toc.md byte-identical (582 bytes)`. The
  body-only re-scope did NOT change BD-204's ID / status / title, so `_toc.md`
  stayed byte-identical — NO drift, NO regen needed, and none was performed
  (correct; the toc derives from ID/status/title only).
- **Check 34 (cross-reference integrity):** `OK: cross-reference integrity: 2699
  reference(s) across 222 per-entry file(s); all resolved`. The added prose
  introduces no new BD-cross-ref token that would dangle.
- Check 48 emitted pre-existing soft-advisory WARNs (removed-doc citations across
  v8/v9 changelog + several backlog entries) — these are advisory-only (exit code
  unaffected), unrelated to C-RS, and not introduced by this change.

---

## 5. BOUNDARY — PASS

**CMD:** `git status --short`
**OUT:**
```
 M backlog/BD-204.md
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C-RS.md
```

Only `backlog/BD-204.md` is modified; the sole other artifact is the untracked
coder IMPL-REPORT (an expected deliverable). NO other backlog entry, NO
`backlog/_toc.md`, NO `backlog/_rules.md`, NO code, NO project-template/, NO
supporting-docs/ touched. `backlog/` is NOT a v11-surface dir (v11-surface =
`project-template/` / `scripts/` / `pack-ops/` / `supporting-docs/`), so no
manifest regen is owed; `git status --short test-fixtures/manifest.txt` is empty
(manifest unchanged). CONCL: `pack-only` keyword valid; boundary clean.

---

## 6. SCOPE DISCIPLINE — PASS

Exactly the two changes mandated by `PLAN-BD-204.md` §3.LF.2 / the C-RS row
(re-scope: LOSSLESS FIELD-CARRIER FIX section + Option-A archive=scratch-disposal
wording): (1) ADD the §5.a authoritative field block; (2) REPLACE the `Scope:`
dogfood clause with the §5.a Option-A wording, treating §5.a step-3 (the
IMPLEMENTATION CARRY-FORWARD `Deferred` item) as a NOTE (not re-opened). The
diffstat (+2 / −1) bounds the change to exactly these two hunks — no scope creep,
no incidental reflow. No new POQ is introduced (the design + plan fully determined
the text and the insertion point — the new block is inserted before `References:`,
which keeps the trailing `References:` / `Resolved:` / `Position:` fields
contiguous, per the plan's "Insert it as a new field block; do NOT rewrite other
field lines"). The IMPL-REPORT's claims (+2/−1, line-2 unchanged, Check 33
byte-identical, validate-pack green, manifest unchanged, pack-only) were
independently re-verified above and all hold.

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| `agents-never-commit` | No git state-changing verb run. `git rev-parse HEAD` = `454191a9693c284095d21f04662e0f501e99950e` (unchanged); only read-only `git diff`/`git status`/`git log` + `python3 validate-pack.py` invoked. Single file write = this report only. | COMPLIANT |
| `empirical-evidence-blocks` | Every section carries the actual CMD + verbatim OUT (diffstat `+2/−1`; `EXIT=0`; Check 33 `byte-identical (21565 bytes)`; Check 34 `2699 reference(s)…all resolved`; semantic byte-compare `True`) + HEAD `454191a…` + date 2026-06-07 + CONCL. | COMPLIANT |
| `verify-full-ci-suite` | Re-ran `validate-pack.py` (exit 0). A `backlog/`-only edit touches no v11-surface dir + no test-pinned validator output (the Check 33 toc + Check 34 ref-graph are the only entry-tree-sensitive checks, both confirmed green + byte-identical); the unattended integration battery (`test-v11-*.sh`, tracker-*-test.sh) pins code/template/manifest state which this edit does not touch → unaffected. | COMPLIANT |
| `scope-deliverables-to-the-ask` | Delivered exactly the 6 requested checks + verdict + this block + the read-in-full attestation; no edge-case sprawl. | COMPLIANT |
| `boundary-investigation-precedes-pack-defaults` | Verified the pack-only boundary via `git status --short` (only `backlog/BD-204.md` + the untracked IMPL-REPORT); no project-side file touched → P-missed-7 N/A; manifest unchanged. | COMPLIANT |
| `edit-in-place-not-full-rewrite` (faithfulness lens) | The change is a targeted 2-hunk in-place edit (one replace + one insert-before-`References:`), NOT a full rewrite; every pre-existing line byte-unchanged except the intended two (§2). | COMPLIANT |
| `rules-applied-verification-block` | This table: each rule named + quoted command/file evidence + terminal conclusion; no empty-evidence rows. | COMPLIANT |

---

## READ-IN-FULL attestation

| Doc | Read | Use |
|---|---|---|
| `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §5.a (877–928) + §5.b context | Read in full | Source of the inserted block + the Option-A wording; faithfulness compare |
| `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §3.3/§3.3c/§3.3d/§3.3e/§4/§5.f (referenced) | Read (mechanism cross-refs cited in §5.a) | Judged mechanism-description faithfulness (size/portability/operational/credential/guard/CI) |
| `PLAN-BD-204.md` §3.LF.2 (C-RS recipe) + `PLAN-BD-204-LOSSLESS-FIX-SEQUENCE.md` C-RS row | Read in full | Confirmed the recipe = exactly the two changes; scope discipline |
| `backlog/BD-204.md` (1–28) | Read in full | The edited entry under review |
| `backlog/_rules.md` (1–84) | Read in full | Entry-contract grammar (line-2 header, field format, toc-regen rule) |
| `IMPL-REPORT-BD-204-C-RS.md` (1–248) | Read in full | The coder's claims — independently re-verified, not trusted |
| Memory: `reference_gh_pat_no_delete` | Read in full | Verified the CREDENTIAL clause (PAT archive-only/no-delete/manual user-only) |
| Memory pointers: `feedback_edit_in_place_not_full_rewrite`, `feedback_verify_full_ci_suite`, `feedback_scope_deliverables_to_the_ask`, `feedback_agent_output_rules_applied_block` | Read (index entries in MEMORY.md, applied above) | Calibration + per-rule block construction |
| `CLAUDE.md` `## Pack memory` | Read in full | Standing rules in force for this review |
