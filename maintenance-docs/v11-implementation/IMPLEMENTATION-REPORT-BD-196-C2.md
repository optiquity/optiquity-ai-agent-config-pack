# IMPLEMENTATION-REPORT — BD-196 C2

**Commit:** C2 of 12 — Author `pack-ops/PACK-MEMORY-RATIONALE.md`; move
Why/How/example bodies out of corpus (M2/C3). NO check wired.

**Branch:** `v11-dev`
**Base HEAD (worktree):** `84206ad3b9bc8de8a08a5374f36289bca28f3332`
(C1 — pack-memory two-clause imperatives + role/rationale tags)
**Agent:** pack-coder. No git state changes performed (Pack Chat commits).

## PREFLIGHT

`PREFLIGHT: 4/4 in-scope file edits complete; verification PASS; HEAD
84206ad3b9bc8de8a08a5374f36289bca28f3332; about to Write IMPL-REPORT to
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-196-C2.md`

## Files changed (inventory)

| Path | Change |
|---|---|
| `pack-ops/PACK-MEMORY-RATIONALE.md` | NEW (rationale companion, 21 `## <slug>` sections + top-matter) |
| `CLAUDE.md` | MODIFIED (`## Pack memory` — 18 tagged-rule bodies stripped) |
| `AGENTS.md` | MODIFIED (`## Pack memory` — 18 tagged-rule bodies stripped) |
| `GEMINI.md` | MODIFIED (`## Pack memory` — 18 tagged-rule bodies stripped) |

Diff stat: `3 files changed, 30 insertions(+), 1127 deletions(-)` across the
three trinity files (insertions = trimmed tag-closing lines; deletions =
moved bodies).

## 1. What C2 did

1. **Authored `pack-ops/PACK-MEMORY-RATIONALE.md`** — one `## <slug>` section
   per tagged rule (21 sections), slug == the corpus `[rationale: slug]`. Each
   section holds that rule's Why / How-to-apply-worked-example /
   rejected-alternatives, moved verbatim from the CLAUDE.md (canonical) corpus
   body. Top-matter declares: what the file is; pack-only (not client-
   installed); read-on-demand; never source-of-truth-for-the-imperative
   (corpus imperative wins); 1:1 bijection with the corpus slug-set.
2. **Stripped the moved bodies from the corpus** (`CLAUDE.md` / `AGENTS.md` /
   `GEMINI.md` `## Pack memory`, trinity-identical strip on the tagged lines):
   each affected tagged rule now keeps ONLY its imperative line + `[roles:]` +
   `[rationale: slug]`; its Why/How/example block is removed.
3. **7b stale-reference sweep** — clean (§4 below).

## 2. Plan deviation — DEVIATION-1 (18 strips, not 21) — surfaced for review

The C2 prompt and `PLAN-DOC-CONCISION-GUARDRAILS.md` C2 say "strip those 21
tagged rules' bodies." Empirically, **only 18 of the 21 tagged rules carry a
post-tag body to strip.** Three rules — `per-entry-trees-vs-mirrors` (#10),
`separate-ops-from-product` (#11), `test-infra-self-provisioned` (#14) — had
their `[roles:]`/`[rationale:]` tag APPENDED by C1 at the END of an already
application-grade imperative, with NO Why/How/example block following the tag.
Evidence from the C1 diff (`git show 84206ad -- CLAUDE.md`): for these three,
the only C1 change was appending the tag after `wins. Read more at
\`<stream>/_rules.md\`.` (rule 10), after `Same applies in reverse.` (rule 11),
and after `or a \`/tmp\` clone.` (rule 14). There is no separable post-tag body.

**Why I did NOT strip those three:** design §5.1.i (ARCHITECTURE-DOC-CONCISION-
GUARDRAILS.md L142) states rationale holds "WHY + worked examples + rejected
alternatives only — never load-bearing application detail." For rules 10/11/14
the full corpus text IS the application-grade imperative (mode-dependent SSOT
semantics; the ops/product file-list; the provision-and-clean-up mechanic).
Stripping it would REMOVE load-bearing application detail (§5.1.i violation) and
leave a sub-application-grade stub. Per the standing rule "never resolve plan
contradictions / fill plan gaps yourself," I did NOT invent a thin-imperative
rewrite for these three (that is planner/architect work). I implemented the
plan's recommended default — bijection requires 21 rationale sections — by
authoring genuine Why/context rationale sections for slugs 10/11/14 that do NOT
duplicate the corpus application text. Their corpus text is unchanged.

**Disposition request to Pack Chat:** confirm the 18-vs-21 reconciliation. If
the design intends rules 10/11/14 to ALSO split (thin imperative + moved body),
that requires a planner pass to author the thin imperatives (not coder work).
As-shipped, the bijection is satisfied and the corpus stays application-grade.

The 18 rules WITH a stripped body: agents-never-commit;
per-action-approval-sub-agents; deferred-work-tracked-anchor;
no-deferral-without-user-direction; deferral-is-scope-creep;
boundary-investigation-precedes-pack-defaults; preflight-stop-means-stop;
rules-applied-verification-block; empirical-evidence-blocks;
ci-guard-measure-then-bound; pack-side-project-concepts-deliverable-only;
enumerate-encoding-surfaces; skill-agent-maintenance-mechanical;
pack-repo-code-comment-deferrals; filename-uniqueness-heuristic;
architect-doc-reality-reconciliation; regenerate-manifest-v11-surface;
cross-cli-reference-normalization.

## 3. Bijection-equality proof (corpus slug-set == rationale heading-set)

```
$ grep -E "^## " pack-ops/PACK-MEMORY-RATIONALE.md | sed 's/^## //' | sort > rat.txt   # 21 headings
$ grep -oE "\[rationale: [a-z0-9-]+\]" CLAUDE.md | sed -E 's/\[rationale: (.*)\]/\1/' | sort > cor.txt  # 21 slugs
$ diff rat.txt cor.txt   # (empty)
BIJECTION-EQUAL (21 slugs)
```

Trinity slug-set parity: `AGENTS.md` and `GEMINI.md` each carry the identical
21 slugs as `CLAUDE.md` (diff empty both directions). Tagged-line TEXT parity:
every `[rationale: slug]` line is byte-identical across all three trinity files
(diff of sorted tag-lines empty C-vs-A and C-vs-G).

## 4. No-24-touched + count-unchanged confirmation (re-read evidence)

**Bullet count (`## Pack memory` → `### Project goals (v11)`), working tree:**

| File | Bullets | HEAD baseline | Delta |
|---|---|---|---|
| `CLAUDE.md` | 45 | 45 | 0 |
| `AGENTS.md` | 41 | 41 | 0 |
| `GEMINI.md` | 41 | 41 | 0 |

**No bullet added/removed in any file:**
`git diff <f> | grep -E "^[+-]- \*\*"` → 0 added, 0 removed bullet-lines in all
three files. Only bodies were stripped; the rule SET is structurally identical.

**Non-tagged (24) rules intact — spot checks:**
- "Pack Chat NO coder review … BOUNDED review/fix cycle" (untagged): present
  ×1 each file; its `Reviewer pass 1` cycle body present (×2 each file). The
  only diff line mentioning "reviewer pass" is the REMOVED preflight-body line
  (a tagged rule's moved body), not this untagged rule.
- "Pack Chat does not architect" (untagged): present ×1 each file.
- "Per-BD review/fix runs INLINE" (untagged): present ×1.
- Moved-body content confirmed GONE from corpus + PRESENT in rationale: the
  manifest 2026-05-17 incident SHA `667d2dd` → 0 hits in CLAUDE/AGENTS/GEMINI,
  1 hit in `PACK-MEMORY-RATIONALE.md`.

## 5. 7b stale-reference blast-radius sweep — clean

Swept the whole repo (excl. `.git/`, `maintenance-docs/prison/`, `/archive/`)
for inbound cites of the moved corpus bodies:
`grep -rniE "the Why in .*Pack memory|see the rationale in (the corpus|CLAUDE.md)|rationale in.*Pack memory|Pack memory.*Why:|Why.*## Pack memory"`
and a tighter sweep over client/skill surfaces
(`.claude/ project-template/ scripts/ supporting-docs/ pack-ops/`) for
`Why in .*Pack memory | How-to-apply in .*Pack memory | rationale in (CLAUDE|AGENTS|GEMINI) | see the (Why|How|worked example|rejected alternative).*Pack memory`.

**Findings:** the only matches are in the design/plan/backlog artifacts that
PRESCRIBE this C2 work (`ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` §7b/§5.2,
`PLAN-DOC-CONCISION-GUARDRAILS.md` C2/§7b, `pack-ops/BACKLOG.md` BD-196 entry)
plus two historical PACK-REVIEW artifacts that describe a rule's `Why:` block in
audit context. NONE is a live cross-reference that now dangles into a deleted
body. The client/skill/script/pack-ops tighter sweep returned ZERO live
cross-refs into moved bodies. **No fix-or-remove action was required.** All
forward references to `PACK-MEMORY-RATIONALE.md` (design/plan/backlog) are now
satisfied by the file existing.

## 6. validate-pack PASS evidence

`python3 scripts/validate-pack.py` → `PASSED — all checks clean` (exit 0).

**In-flight finding FIXED (not a sequencing report):** the first run FAILed
Check 40 (pack-ops/ bare cross-reference scanner, BD-179) with 12 hits in the
NEW `pack-ops/PACK-MEMORY-RATIONALE.md`. Check 40 does NOT assert corpus body
structure (it is a path-qualification content rule that applies to every
`pack-ops/*.md` file), so per the prompt this is a fix-in-commit, not a
report-and-halt. The bare references were inherited verbatim from the corpus
bodies (which lived in pack-ROOT trinity, outside Check 40's pack-ops/ scope);
moving them into `pack-ops/` brought them under the check. Remediation: path-
qualified each bare reference to its directory
(`project-template/docs/pack/PLATFORM-SKILLS.md`,
`project-template/docs/pack/PM-CHAT.md`,
`scripts/tests/test-validate-pack-check-43.sh`,
`scripts/tests/test-validate-pack-checks-36-37-38.sh`,
`scripts/validate-pack.py`,
`maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md`,
`maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md`,
`scripts/init-project.sh`,
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-182.md`), reworded the
monolithic-mirror sentence to avoid a bare `IMPLEMENTATION-PLAN.md`, and
reworded the filename-uniqueness exemption-example list to avoid bare `SKILL.md`
/ `pyproject.toml` basenames (those names appear as illustrative ecosystem-fixed
examples, not pointers; `validate-pack.py` was NOT edited — out of C2 scope).
Re-run after fix: Check 40 clean (10 pack-ops/*.md walked, zero unqualified bare
cross-references); whole suite `PASSED — all checks clean`. Bijection re-checked
post-fix: still 21==21 equal.

No validate-pack check asserted the corpus body structure (no `Why:`/`How to
apply:` section requirement tripped) — the body-strip did not trip any check.

## 7. Manifest regen note (Pack Chat's at commit — NOT done here)

C2 touches `pack-ops/` (new `PACK-MEMORY-RATIONALE.md`), so the manifest-regen
trigger FIRES and **Pack Chat must run `bash test-fixtures/build.sh --all
--clean` and stage `test-fixtures/manifest.txt` at the C2 commit** if the diff
is non-empty. I did NOT run `build.sh` and staged nothing (per prompt).
Expectation: the manifest diff is likely EMPTY because
`PACK-MEMORY-RATIONALE.md` is NOT in the `scripts/init-project.sh` client
inventory (`grep -c PACK-MEMORY-RATIONALE scripts/init-project.sh` → 0), and the
pack-root trinity edits are not fixture-affecting (pack-root `CLAUDE.md` etc.
are not client-copied). The rebuild + diff-check is still mandatory; the
manifest diff after rebuild is the canonical authority.

## 8. Definition-of-Done checklist

| Item | Result |
|---|---|
| NEW `pack-ops/PACK-MEMORY-RATIONALE.md` authored, 21 `## <slug>` sections | PASS |
| Slug-set == corpus `[rationale: slug]` set (bijection, 1:1) | PASS (21==21, diff empty) |
| Top-matter: pack-only / read-on-demand / never-SSOT-for-imperative | PASS |
| Tagged-rule bodies stripped from corpus (trinity-identical on tag lines) | PASS (18 rules; see DEVIATION-1) |
| 24 non-tagged rules untouched (bodies intact) | PASS (0 bullet add/remove; spot checks intact) |
| Bullet count unchanged (45/41/41) | PASS |
| Trinity tagged-line text parity (C==A==G) | PASS |
| 7b stale-reference sweep | PASS (no live dangling refs; no fix needed) |
| `validate-pack.py` PASS | PASS (exit 0, all checks clean) |
| No corpus-body-structure check tripped by the strip | PASS (Check 40 was path-qualification, fixed in-commit) |
| No git state changes; no build.sh run; nothing staged | PASS |
| Prison untouched | PASS (not read/cited) |

## 9. New POQs introduced

- **POQ-C2-1 (DEVIATION-1):** 18-vs-21 strip reconciliation. Plan says "21
  bodies"; only 18 tagged rules carry a strippable post-tag body. Rules
  10/11/14 were left application-grade in the corpus per design §5.1.i, with
  genuine (non-duplicating) rationale sections authored for bijection. Default
  applied: bijection satisfied, corpus stays application-grade. Disposition:
  Pack Chat to confirm; if a thin-imperative split for 10/11/14 is intended,
  route to planner (not coder).

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| Agents never commit | No `git add/commit/push/tag/...` run; only Edit/Write + this report; `git status --short` shows ` M`/`??` working-tree changes, no staged | COMPLIANT |
| EDIT IN PLACE — targeted Edits, NOT full-file rewrite | All corpus changes via targeted `Edit` on `[rationale: slug]`+body spans; `git diff` shows 0 bullet-lines added/removed; 45/41/41 bullets preserved | COMPLIANT |
| TRINITY lock-step | Same 18-rule strip applied to CLAUDE/AGENTS/GEMINI; tagged-line text byte-identical across all three (sorted-tagline diff empty C-vs-A, C-vs-G); slug-sets identical (21 each) | COMPLIANT |
| BIJECTION PRECONDITION (load-bearing for C3) | `diff` of rationale `## <slug>` headings vs corpus `[rationale: slug]` slugs is EMPTY; 21==21; re-verified post-Check-40-fix | COMPLIANT |
| PREFLIGHT before IMPL-REPORT | Emitted `PREFLIGHT: 4/4 ... verification PASS; HEAD 84206ad...` before this Write | COMPLIANT |
| Verification before PREFLIGHT (validate-pack required, pack-ops/ touched) | `python3 scripts/validate-pack.py` → `PASSED — all checks clean` exit 0; Check 40 in-flight FAIL fixed in-commit (path-qualification, not corpus-body-structure) | COMPLIANT |
| No corpus-body-structure check forced green | No check asserted `Why:`/`How:` body presence; the only failing check (40) was a generic path-qualification rule on the new pack-ops/ file, legitimately fixed; `validate-pack.py` NOT edited | COMPLIANT |
| Manifest regen is Pack Chat's at commit (NOT coder's) | Did NOT run `build.sh`; staged nothing; noted in §7; confirmed RATIONALE not in init-project.sh inventory | COMPLIANT |
| Never resolve plan contradictions / fill plan gaps yourself | 18-vs-21 gap surfaced as DEVIATION-1 + POQ-C2-1; did NOT author thin imperatives for rules 10/11/14 (planner work); implemented plan default (bijection) | COMPLIANT |
| Boundary discipline (P-missed-7) | No project-side file edited; all edits are pack-root trinity + `pack-ops/` (pack-only). RATIONALE.md is pack-only, not client-installed. N/A for project-side SSOT investigation | N/A: no project-side file touched |
| Prison rule | `maintenance-docs/prison/` not read, cited, or trusted; excluded from the 7b sweep | COMPLIANT |
| Output ends with Rules-Applied Verification Block (concise) | This block | COMPLIANT |
