# BD-195 — Clean Foundation (sole trusted basis)

This is the ONLY trusted basis for BD-195 going forward. The prior
`CLEAN-PROBLEM-INVENTORY` and `CONTAMINATION-MAP` are discarded
(untrustworthy provenance + a demonstrated factual error + a rejected
salvage premise). Concrete contamination/defect findings are NOT in this
doc — they are re-derived fresh from the repo by the upcoming fan-out
discovery, each finding grounded in repo evidence. This doc holds only the
verified concepts, principles, and decisions.

## A — Contamination kinds (the discovery search template)

- **K1 — pack-self-token-in-project-entity-grammar:** a pack identifier
  (e.g. `BD-NNN`) admitted into a project-side entity grammar (e.g. a
  phase-task dependency target). See ruling JC-1.
- **K2 — pack-self-ref-on-client-shipped-surface:** pack-internal
  docs/paths/agent-names or the `Pack Chat` role referenced on a
  client-shipped surface (Ban A).
- **K3 — dangling-reference-to-removed-or-superseded-doc** (reframed; the
  prison directory has been deleted): a live doc cites a deleted/superseded
  doc as present/authoritative, or at a path that no longer resolves. This
  now also covers references to everything deleted during the BD-195
  cleanup (the former prison set, the contaminated audit docs, the deleted
  strategy/plan chain).
- **K4 — client-shipped-dead-pack-doc-reference:** a client-shipped surface
  references a pack-only doc that clients never receive. See ruling JC-3.
- **K5 — version-currency-staleness:** stale version labels or content
  (e.g. "v10" where v11 is current) that misleads a reader.
- **K6 — v11.1-mislabel:** v11.0 concepts mislabeled as v11.1.
- **K7 — surface-blind-union-grammar-in-dual-surface-validator:** a
  dual-surface validator/operator whose grammar admits both pack and
  project tokens without surface-gating.

## B — Non-contamination correctness defects

Real must-fix mistakes that are NOT boundary leaks: malformed or dangling
internal paths, cross-CLI / cross-surface inconsistencies, factual and
version-currency errors.

NOTE: the prior pass's "~21" is a DISTRUSTED count — neither the number nor
the item list is carried; the real set is re-derived from the repo.

## C — Open

Any defect fitting no kind in A or B. Each discovery agent MUST report such
findings explicitly, so a missed category cannot hide.

## Principles (governing)

- **Categorical-principle-first:** a pack-self token on a client-gated
  surface is contamination by default; the burden is on proving the
  exception.
- **Empirical-evidence:** every claim is backed by command + verbatim
  output + HEAD SHA + interpretation; confidence binds to the WEAKEST
  load-bearing premise.
- **No false dichotomy.**
- **Directory-based, not ship-based:** a file's LOCATION determines
  compliance; never audit ship-status.
- **Deliverable-only (narrow) + cleanliness corollary:** project concepts
  may appear on pack surfaces ONLY to construct a project deliverable; the
  emitted/modified deliverable must itself be clean; never in
  pack-self-maintenance.
- **Never-read-contaminated:** contaminated content is never a source for
  new work.
- **Delete-by-default:** superseded/incorrect docs are deleted, not
  quarantined; keep only if essential; a banner is justified only when the
  doc must stay AND the error cannot be removed.
- **Distrust-derived-claims:** ground every finding in the repo (the only
  ground truth), never in a derived audit doc.

## Rulings

Carried as decisions; the discovery MUST re-confirm each ruling's
underlying finding still exists in the repo — a ruling whose finding does
not reproduce is flagged, not acted on.

- **JC-1:** strip `BD-` from the project phase-task dependency grammar
  (tracker libs + their tests/fixtures) and add an error-guard that fails
  on `BD-` as a project phase-task dependency target; the pack's
  own-backlog `BD-` handling is untouched.
- **JC-2:** broaden the client-surface leak guard — bare pack-doc
  basenames, commit-SHA-as-provenance, scan `.example`/`.proto`/`.env.example`,
  bare-prose (non-backtick) — with measure-then-bound governing what
  actually lands.
- **JC-3:** `project-template/README.md` → `V10-DESIGN.md` is a K4 leak BY
  LOCATION (project-template/ is client-gated regardless of ship-status);
  strip the ref, de-version (v10→v11), redirect the stale `cp -r` to
  init-project.sh/QUICKSTART.
- **JC-4:** the `boundary-investigation/SKILL.md` SSOT-table path is a
  malformed-path correctness defect (category B), NOT a K4 leak; fix the
  path.
- **JC-5:** leave accurate historical narrative; the CHANGELOG v8 entries
  (incl. lines 562/564) are accurate v8 history and are NOT hand-corrected;
  the only output is a SOFT-advisory guard
  (cited-path-resolves-to-a-removed-doc), never hard-fail.
- **JC-6:** version-neutral the pm-startup RAG-manifest "in v10" label
  across the pm-startup triad; the `.gemini/settings.json` two-path RAG
  claim is a category-B cross-surface defect.
- **JC-7:** delete superseded docs (delete-by-default; supersedes the
  earlier prison-both disposition).

## Out of scope (deferred)

Guard *designs* are NOT in this doc (they are step-7 remediation output).
Removing the now-obsolete "ignore maintenance-docs/prison/" instructions
from the rules is a separate future BD — not part of BD-195.

---

## Rules-Applied Verification Block

| Rule | Evidence (quoted) | Conclusion |
|---|---|---|
| transcription-fidelity (task-specific) | Doc authored from §2 verbatim in substance: kinds K1–K7, sections B/C, 8 governing principles, rulings JC-1–JC-7, out-of-scope; no findings, claims, counts, or scope added beyond §2; "~21" carried only as DISTRUSTED note per §2-B | COMPLIANT |
| rules-applied-verification-block [universal] | This per-rule table ends the doc with rule + quoted evidence + conclusion | COMPLIANT |
| agents-never-commit [universal] | No `git add/commit/push/tag` run; only Read/Bash(read-only)/Write used; `git status --short` shows new file as `??` only | COMPLIANT |
| preflight-stop-means-stop [universal] | No parent stop/halt issued; PREFLIGHT line emitted after file written + re-read for fidelity, before IMPL-REPORT | COMPLIANT |
