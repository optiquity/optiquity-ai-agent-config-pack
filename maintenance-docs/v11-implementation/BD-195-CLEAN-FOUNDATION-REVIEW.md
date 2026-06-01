# BD-195-CLEAN-FOUNDATION — Transcription Fidelity Review

- **Reviewer:** fresh pack-reviewer (transcription check, READ-ONLY)
- **Branch / HEAD:** v11-dev / `3178fa4`
- **Target:** `maintenance-docs/v11-implementation/BD-195-CLEAN-FOUNDATION.md`
- **Scope:** Confirm each required item is PRESENT + ACCURATE and that
  NOTHING beyond the spec was added (no findings, counts, scope, or claims).
  This is a transcription check, not a design review. Only the target doc was
  read; the discarded inventory/map were not opened.

---

## Purpose block

**CONFIRMED.** Lines 3–9 state this is "the ONLY trusted basis for BD-195
going forward"; that the prior `CLEAN-PROBLEM-INVENTORY` and
`CONTAMINATION-MAP` "are discarded"; and that "Concrete contamination/defect
findings are NOT in this doc — they are re-derived fresh from the repo by the
upcoming fan-out discovery." All three required purpose elements (sole trusted
basis; findings re-derived by discovery, not in this doc; inventory + map
discarded) are present and accurately stated. Line 9 scopes the doc to "only
the verified concepts, principles, and decisions" — consistent with the spec,
nothing added.

## A — Contamination kinds (7)

**CONFIRMED.** All seven kinds present, accurately stated, with correct ruling
cross-references and no added kinds:

- **K1 — pack-self-token-in-project-entity-grammar** (lines 13–15): pack
  identifier admitted into a project-side entity grammar (phase-task
  dependency target); "See ruling JC-1." Matches spec (→JC-1).
- **K2 — pack-self-ref-on-client-shipped-surface** (lines 16–18): pack-internal
  docs/paths/agent-names or the `Pack Chat` role on a client-shipped surface.
  Matches spec.
- **K3 — dangling-reference-to-removed-or-superseded-doc** (lines 19–24):
  explicitly reframed; notes "the prison directory has been deleted"; and
  states it "now also covers references to everything deleted during the
  BD-195 cleanup (the former prison set, the contaminated audit docs, the
  deleted strategy/plan chain)." Matches spec (reframed; notes prison deleted;
  covers refs to deleted cleanup docs).
- **K4 — client-shipped-dead-pack-doc-reference** (lines 25–26): client-shipped
  surface references a pack-only doc clients never receive; "See ruling JC-3."
  Matches spec (→JC-3).
- **K5 — version-currency-staleness** (lines 27–28): stale version labels/content
  (e.g. "v10" where v11 is current). Matches spec.
- **K6 — v11.1-mislabel** (line 29): v11.0 concepts mislabeled as v11.1. Matches
  spec.
- **K7 — surface-blind-union-grammar-in-dual-surface-validator** (lines 30–32):
  dual-surface validator/operator whose grammar admits both pack and project
  tokens without surface-gating. Matches spec.

Count is exactly 7; no extra kinds, no editorializing beyond the spec'd
descriptions.

## B — Non-contamination correctness defects

**CONFIRMED.** Lines 34–41. Defines category B as "Real must-fix mistakes that
are NOT boundary leaks: malformed or dangling internal paths, cross-CLI /
cross-surface inconsistencies, factual and version-currency errors." The NOTE
(lines 40–41) explicitly marks the prior pass's "~21" as "a DISTRUSTED count —
neither the number nor the item list is carried; the real set is re-derived
from the repo." Matches spec exactly ("~21" explicitly DISTRUSTED; count +
items re-derived, not carried). No concrete defect list carried in — correct.

## C — Open

**CONFIRMED.** Lines 43–46. Open category for "Any defect fitting no kind in A
or B," with the requirement that "Each discovery agent MUST report such
findings explicitly, so a missed category cannot hide." Matches spec (open
category; agents must report uncategorized defects).

## Principles (8)

**CONFIRMED.** Lines 48–69. All eight present and accurately stated; none
added:

1. **Categorical-principle-first** (50–52) — pack-self token on a client-gated
   surface is contamination by default; burden on proving exception. Matches
   spec (categorical-first).
2. **Empirical-evidence** (53–55) — command + verbatim output + HEAD SHA +
   interpretation; "confidence binds to the WEAKEST load-bearing premise."
   Matches spec (empirical-evidence; confidence binds to weakest premise).
3. **No false dichotomy** (56). Matches spec.
4. **Directory-based, not ship-based** (57–58) — LOCATION determines compliance;
   never audit ship-status. Matches spec.
5. **Deliverable-only (narrow) + cleanliness corollary** (59–62) — project
   concepts on pack surfaces ONLY to construct a project deliverable; the
   emitted/modified deliverable must itself be clean; never in
   pack-self-maintenance. Matches spec (deliverable-only narrow + cleanliness
   corollary).
6. **Never-read-contaminated** (63–64) — contaminated content never a source for
   new work. Matches spec.
7. **Delete-by-default** (65–67) — superseded/incorrect docs deleted not
   quarantined; keep only if essential; banner justified only when doc must
   stay AND error cannot be removed. Matches spec.
8. **Distrust-derived-claims** (68–69) — ground every finding in the repo, never
   in a derived audit doc. Matches spec.

Count is exactly 8; no added principles.

## Rulings (7)

**CONFIRMED.** Lines 71–100. All seven rulings present, accurate, no extras:

- **JC-1** (77–80): strip `BD-` from project phase-task dependency grammar
  (tracker libs + their tests/fixtures); add error-guard failing on `BD-` as a
  project phase-task dependency target; pack's own-backlog `BD-` handling
  untouched. Matches spec (strip BD- from project phase-task dependency grammar
  + error-guard; pack own-backlog untouched).
- **JC-2** (81–84): broaden the client-surface leak guard — bare pack-doc
  basenames, commit-SHA-as-provenance, scan `.example`/`.proto`/`.env.example`,
  bare-prose (non-backtick) — with measure-then-bound governing what lands.
  Matches spec (broaden client-surface leak guard; basenames/SHA/.example +
  .proto + .env.example/bare-prose; measure-then-bound).
- **JC-3** (85–88): `project-template/README.md` → `V10-DESIGN.md` is a K4 leak
  BY LOCATION (project-template/ client-gated regardless of ship-status); strip
  the ref, de-version (v10→v11), redirect the stale `cp -r` to
  init-project.sh/QUICKSTART. Matches spec (README→V10-DESIGN K4 by-location;
  strip + de-version + redirect cp -r).
- **JC-4** (89–91): the `boundary-investigation/SKILL.md` SSOT-table path is a
  malformed-path correctness defect (category B), NOT a K4 leak; fix the path.
  Matches spec (SKILL.md path = category-B malformed-path, not K4).
- **JC-5** (92–95): leave accurate historical narrative; CHANGELOG v8 entries
  (incl. lines 562/564) are accurate v8 history and are NOT hand-corrected;
  only output is a SOFT-advisory guard (cited-path-resolves-to-a-removed-doc),
  never hard-fail. Matches spec (leave accurate v8 history incl. 562/564,
  SOFT-advisory guard only, no hand-correction).
- **JC-6** (96–98): version-neutral the pm-startup RAG-manifest "in v10" label
  across the pm-startup triad; the `.gemini/settings.json` two-path RAG claim
  is a category-B cross-surface defect. Matches spec (version-neutral pm-startup
  label; Gemini 2-path = category-B).
- **JC-7** (99–100): delete superseded docs (delete-by-default; supersedes the
  earlier prison-both disposition). Matches spec (delete superseded docs;
  supersedes prison-both).

The preamble (72–75) correctly states rulings are "Carried as decisions" and
that "the discovery MUST re-confirm each ruling's underlying finding still
exists in the repo — a ruling whose finding does not reproduce is flagged, not
acted on." This satisfies the **Re-confirm note** requirement.

Count is exactly 7; no added rulings.

## Re-confirm note

**CONFIRMED.** Captured in the Rulings preamble (lines 72–75), as noted above:
rulings carried as decisions; discovery must re-confirm each ruling's
underlying finding still exists. Accurate, nothing added.

## Out-of-scope (deferred)

**CONFIRMED.** Lines 102–106. States guard *designs* are NOT in this doc "(they
are step-7 remediation output)" and that "Removing the now-obsolete 'ignore
maintenance-docs/prison/' instructions from the rules is a separate future BD —
not part of BD-195." Matches spec (guard DESIGNS excluded → step-7;
prison-instruction removal is a separate future BD).

---

## Added-beyond-spec scan

Walked the entire doc section-by-section for content not traceable to the spec:

- No concrete contamination/defect findings are listed (correct — purpose block
  defers these to discovery).
- No counts beyond the spec'd "~21 DISTRUSTED" note (no carried item lists, no
  totals of kinds/principles/rulings presented as findings).
- No scope expansions (out-of-scope block matches spec; no new BDs proposed; no
  guard designs).
- No added kinds, principles, or rulings.
- The Rules-Applied Verification Block at the end (lines 110–118) is process
  metadata required by pack-memory `rules-applied-verification-block`, not
  BD-195 content; it makes no substantive findings claim. Not a fidelity defect.

No added-beyond-spec content found.

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| transcription-fidelity (task-specific) | All spec items verified present + accurate: Purpose (lines 3–9), 7 kinds K1–K7 (13–32), B (34–41), C (43–46), 8 principles (48–69), 7 rulings JC-1–JC-7 (77–100), re-confirm note (72–75), out-of-scope (102–106). Added-beyond-spec scan returned nothing: no concrete findings, no carried counts beyond the "~21 DISTRUSTED" note, no scope expansion. | COMPLIANT |
| agents-never-commit [universal] | No state-changing git verb run. Only `git rev-parse HEAD`, `ls`, `Read`, `Write` (this report) used. `git rev-parse HEAD` → `3178fa4...` (read-only). | COMPLIANT |
| per-action-approval-sub-agents [universal] | No destructive file operation performed; sole write is the prompted report path `maintenance-docs/v11-implementation/BD-195-CLEAN-FOUNDATION-REVIEW.md`. | COMPLIANT |
| preflight-stop-means-stop [universal] | No parent stop/halt/revert message issued; review completed; single Write at the prompted report path is the deliverable. | COMPLIANT |
| rules-applied-verification-block [universal] | This per-rule table terminates the report with rule + quoted evidence + conclusion. | COMPLIANT |
| scope-deliverables-to-the-ask [universal] | Report is exactly the transcription check requested; per-item CONFIRMED/DEFECT + added-beyond-spec scan + verdict; no design-review sprawl. | COMPLIANT |

Note: `/backlog/_rules.md` and `/changelog/_rules.md` (prompt pre-reads) do not
exist at HEAD `3178fa4` — those per-entry trees are absent on this branch. They
are not load-bearing for a transcription check that reads only the target doc.

---

## Verdict

**FIDELITY-CLEAN.** All required items are present and accurately transcribed;
nothing beyond the spec was added.
