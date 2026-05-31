# IMPLEMENTATION-REPORT — BD-196 C5 FIX (Fix-coder pass 1 of max-2)

**Finding applied:** SHOULD-1 from `PACK-REVIEW-BD-196-C5.md` (record 6 of
`pack-ops/.spawn-rule-manifest.txt` named the wrong reference surface).
**Branch:** v11-dev. **HEAD (working-tree only, no commit):**
`bf9290b924c9825a7f65a9e1b0ea6f2072259d16`.
**Scope:** `pack-ops/.spawn-rule-manifest.txt` record 6 `references:` line ONLY.

---

## What record 6 now points at + WHY

**Decision: REPOINT (recommendation (a)), not canonical-only.**

Record 6 (`pack-chat-no-coder-review-bounded-cycle`) `references:` was repointed
FROM the triage-stop block TO the "Real fixes only" block:

```
references: PACK-CHAT.md § "Behavioral rules" ("Real fixes only — no green-the-test band-aids", `feedback-pack-chat-does-no-fixes` distinct-from cross-reference)
```

**The truth I found in `pack-ops/PACK-CHAT.md` (grep `git rev-parse HEAD`
working tree):**

- The triage-stop block (`### Behavioral rules`, "Stop after every reviewer pass
  for triage discussion", L63–70) references ONLY the
  `presents-triage-before-fix-coder` rule (`see the "Pack Chat presents triage
  to user before fix-coder spawns" rule …`). It does NOT mention "does NO fixes",
  "NO coder review", or "bounded reviewer/fix cycle". The old record-6 pointer at
  this block did NOT resolve — the SC7 shape.
- A repo-grep of PACK-CHAT.md for `no coder review|bounded.*cycle|does no fixes|
  pack-chat-does-no-fixes` returns exactly TWO hits, both in the "Real fixes only —
  no green-the-test band-aids" block (L89–90):
  - L90 carries `` `feedback-pack-chat-does-no-fixes` (who applies fixes) `` as a
    distinct-from cross-reference.
- `feedback-pack-chat-does-no-fixes` is the trinity memory-cache slug for the
  "Pack Chat does NO fixes" rule — which IS one of the two corpus subsections
  record 6's `canonical`/`corpus` line names ("Pack Chat does NO fixes" + "Pack
  Chat NO coder review; bounded reviewer/fix cycle"). So the "Real fixes only"
  block is the ONE PACK-CHAT surface that carries a resolving pointer to record
  6's concept.

Therefore the truth is "PACK-CHAT DOES reference the rule" (option (a) in the
prompt), NOT "corpus-only" — a resolving pointer exists at L89–90. Canonical-only
would have been WRONG (it would drop a real, present reference surface).

**No PACK-CHAT edit was needed or made.** The resolving pointer already existed
in the file (it was authored in the C5 collapse). The fix is a manifest-accuracy
repoint only — no verbatim imperative text was added to PACK-CHAT.

## Confirmation it satisfies C6 reference-resolution semantics (§9.6)

§9.6 enforcement clause (a): "every referenced surface carries a resolving
reference to the slug." Design §9.8 / §11.1 confirm PACK-CHAT carries one-line
REFERENCES (not copies) and the manifest maps `slug → {canonical, references}`.

- Record 6's named surface is now the "Real fixes only" block, which DOES carry
  the `feedback-pack-chat-does-no-fixes` pointer → resolves to the "Pack Chat does
  NO fixes" corpus rule that record 6 names. C6's reference-resolution check will
  find a resolving pointer at the named surface → PASS.
- This is exactly symmetric with record 5 (`triage-all-fix-all`), whose second
  `references:` clause already cites the SAME "Real fixes only" block (for
  `feedback-fix-all-review-findings`). The reviewer flagged this asymmetry
  (record 5 cites it, record 6 didn't) as the SHOULD-1 smoking gun; the repoint
  closes it. Both concepts that live in the L89–90 distinct-from block are now
  cited by the records that depend on them.

Not a model-ambiguity case — a simple, true repoint to the surface that carries
the pointer. No need to route to the planner.

## Records 1–5 untouched

Verified by inspection: records 1–4 unchanged; record 5 (`triage-all-fix-all`)
unchanged (still cites the triage-stop block + the "Real fixes only" distinct-from
block). Only record 6's single `references:` line changed. The header/format
comment block is unchanged.

## Anti-restate still clean

`git diff --stat pack-ops/PACK-CHAT.md` shows only the pre-existing C5 collapse
(8 insertions / 9 deletions); THIS fix made zero edits to PACK-CHAT.md. No verbatim
canonical imperative TEXT was reintroduced into any reference surface. C6's
anti-restate scan remains satisfied.

## Verification — validate-pack PASS

`python3 scripts/validate-pack.py` → exit 0, "PASSED — all checks clean".
Check 40 OK, Check 45 OK (18/18 bijection), Check 41/42/43 OK. (Check 46 lands in
C6 per plan — not yet wired; correct for this working tree.) Manifest regen
(`build.sh`) is Pack Chat's at commit time — not run here.

## Files changed inventory

| Path | Change type |
|---|---|
| `pack-ops/.spawn-rule-manifest.txt` | modified (record 6 `references:` line only) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-196-C5-FIX.md` | new (this report) |

## Plan deviations

None. SHOULD-1 applied per recommendation (a); no scope expansion.

## New POQs

None.

## Definition-of-Done checklist

| Item | Status |
|---|---|
| Record 6 `references:` repointed to a resolving surface | PASS |
| Truth determined from PACK-CHAT.md (not guessed) | PASS |
| Resolution model verified against design §9.6 / §9.8 / §11.1 | PASS |
| Records 1–5 + header untouched | PASS |
| No verbatim imperative reintroduced into PACK-CHAT | PASS |
| `validate-pack.py` PASS | PASS |
| PREFLIGHT emitted before report | PASS |
| No git state changes | PASS |

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| Agents never commit / read-only git | Only `git rev-parse`/`git status`/`git diff --stat` (read); one Edit to manifest + one Write (this report). `git status` shows HEAD still `bf9290b`. | COMPLIANT |
| Edit-in-place (targeted) | Single Edit changed only record 6's `references:` line; grep -nA4 confirms records 5 + 6, records 1–4 + header unchanged. | COMPLIANT |
| No destructive op | No `rm`/`git rm`/overwrite of trusted files; manifest edit is in-place targeted replace. | COMPLIANT |
| Prison rule | No read/cite/edit of `maintenance-docs/prison/`. | COMPLIANT |
| Trinity rule | No trinity file (`CLAUDE.md`/`AGENTS.md`/`GEMINI.md`) touched — manifest is a single pack-ops file. | N/A: no trinity surface in scope |
| Verification before PREFLIGHT | `python3 scripts/validate-pack.py` → exit 0, "PASSED — all checks clean" (pack-ops/ touched). | COMPLIANT |
| Manifest regen not run by coder | Did NOT run `build.sh` or stage manifest; left for Pack Chat at commit. | COMPLIANT |
| PREFLIGHT before report | PREFLIGHT line emitted in-chat before this Write. | COMPLIANT |
| Anti-restate stays clean | `git diff --stat pack-ops/PACK-CHAT.md` = pre-existing C5 collapse only; this fix made 0 PACK-CHAT edits; no verbatim imperative added. | COMPLIANT |
| Output ends with Rules-Applied Block | This block. | COMPLIANT |
| Concise | Single-finding fix-report; no padding. | COMPLIANT |

**End of IMPLEMENTATION-REPORT-BD-196-C5-FIX.md.**
