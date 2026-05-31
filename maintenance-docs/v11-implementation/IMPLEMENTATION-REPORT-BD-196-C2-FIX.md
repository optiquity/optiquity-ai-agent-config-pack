# IMPLEMENTATION-REPORT — BD-196 C2-FIX (POQ-C2-1 resolution, option a)

**Scope:** ONE user-locked correction applied to the in-progress C2 working
tree. The three rules `per-entry-trees-vs-mirrors`, `separate-ops-from-product`,
`test-infra-self-provisioned` are fully application-grade with no genuine
rationale body; `[rationale: slug]` is now OPTIONAL (self-contained rules carry
NONE). Their `[rationale:]` pointers are removed from the corpus; their filler
sections are removed from `pack-ops/PACK-MEMORY-RATIONALE.md`. Bijection drops
from 21==21 to 18==18.

**Branch:** `v11-dev`
**Base HEAD (worktree):** `84206ad3b9bc8de8a08a5374f36289bca28f3332`
**Agent:** pack-coder. No git state changes performed (Pack Chat commits).

## PREFLIGHT

`PREFLIGHT: 12/12 in-scope Edits complete (3 rules × 3 trinity corpus files = 9
+ 3 RATIONALE section removals); verification PASS; HEAD
84206ad3b9bc8de8a08a5374f36289bca28f3332; about to Write report to
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-196-C2-FIX.md`

## Files changed (inventory)

| Path | Change type |
|---|---|
| `CLAUDE.md` | MODIFIED — 3 corpus rules' `[rationale:]` pointer removed; `[roles:]` kept |
| `AGENTS.md` | MODIFIED — identical 3 removals (trinity lock-step) |
| `GEMINI.md` | MODIFIED — identical 3 removals (trinity lock-step) |
| `pack-ops/PACK-MEMORY-RATIONALE.md` | MODIFIED — 3 `## <slug>` sections removed (the C2 filler sections) |

## 1. The 3 corpus rules — `[rationale:]` removed, `[roles:]` kept

For each of the three rules, only the `[rationale: <slug>]` token was removed;
the imperative line and the `[roles: universal]` tag are intact. The
`[rationale:]` for all three sat on the SAME backtick-span as `[roles:]`; the
edit shortened that span. The change is byte-identical across the trinity.

Final corpus tag-line text (all three trinity files, byte-identical):

| Rule | Final trailing tag (post-fix) |
|---|---|
| `per-entry-trees-vs-mirrors` | `` ...wins. Read more at `<stream>/_rules.md`. `[roles: universal]` `` |
| `separate-ops-from-product` | `` ...Same applies in reverse. `[roles: universal]` `` |
| `test-infra-self-provisioned` | `` ...or a `/tmp` clone. `[roles: universal]` `` |

Evidence — `[roles: universal]` survived, `[rationale:]` gone (per trinity file,
exact-match count = 1 each):

```
$ grep -c 'Read more at `<stream>/_rules.md`. `[roles: universal]`$'  {CLAUDE,AGENTS,GEMINI}.md  → 1 / 1 / 1
$ grep -c 'Same applies in reverse. `[roles: universal]`$'            {CLAUDE,AGENTS,GEMINI}.md  → 1 / 1 / 1
$ grep -c 'or a `/tmp` clone. `[roles: universal]`$'                  {CLAUDE,AGENTS,GEMINI}.md  → 1 / 1 / 1
$ grep -c 'per-entry-trees-vs-mirrors|separate-ops-from-product|test-infra-self-provisioned'  (corpus [rationale:] slug set) → 0
```

## 2. The 3 RATIONALE sections removed

Removed from `pack-ops/PACK-MEMORY-RATIONALE.md` (the non-duplicating filler
sections the C2 coder authored for these three application-grade rules):

- `## per-entry-trees-vs-mirrors` (+ its `---` separator)
- `## separate-ops-from-product` (+ its `---` separator)
- `## test-infra-self-provisioned` (+ its `---` separator)

The other 18 `## <slug>` sections are intact and untouched. Top-matter is
count-agnostic ("held in 1:1 bijection with the corpus `[rationale: slug]` set
(Check 45, wired in commit C3)") — no hardcoded count, so it remains accurate
at 18==18; no top-matter edit was needed.

## 3. Bijection-now-18==18 proof

```
$ grep -cE "^## " pack-ops/PACK-MEMORY-RATIONALE.md                                    → 18
$ grep -coE "\[rationale: [a-z0-9-]+\]" CLAUDE.md                                       → 18  (AGENTS/GEMINI: 18 / 18)
$ grep -E "^## " pack-ops/PACK-MEMORY-RATIONALE.md | sed 's/^## //' | sort > rat.txt
$ grep -oE "\[rationale: [a-z0-9-]+\]" CLAUDE.md | sed -E 's/\[rationale: (.*)\]/\1/' | sort > cor.txt
$ diff rat.txt cor.txt                                                                  → (empty)
BIJECTION-EQUAL (18 slugs, no orphan in either direction)
```

The 18 surviving slugs (rationale headings == corpus pointers):
agents-never-commit; per-action-approval-sub-agents; deferred-work-tracked-anchor;
no-deferral-without-user-direction; deferral-is-scope-creep;
boundary-investigation-precedes-pack-defaults; preflight-stop-means-stop;
rules-applied-verification-block; empirical-evidence-blocks;
ci-guard-measure-then-bound; pack-side-project-concepts-deliverable-only;
enumerate-encoding-surfaces; skill-agent-maintenance-mechanical;
pack-repo-code-comment-deferrals; filename-uniqueness-heuristic;
architect-doc-reality-reconciliation; regenerate-manifest-v11-surface;
cross-cli-reference-normalization.

## 4. Other-18-untouched + trinity-parity confirmation

- **Other 18 RATIONALE sections untouched.** Only the 3 named `## <slug>`
  sections (+ their `---` separators) were removed; the remaining 18 headings
  and their bodies are byte-unchanged by this fix.
- **Other 18 corpus rules untouched.** Only the `[rationale:]` token on the 3
  named rules changed. All 18 other rules retain their `[roles:]` + `[rationale:]`
  pointers unchanged.
- **Bullet counts unchanged** (`## Pack memory` → `### Project goals (v11)`):
  CLAUDE 45 / AGENTS 41 / GEMINI 41 — identical to the C2 baseline (45/41/41).
  This fix added/removed ZERO bullet lines (it only shortened 3 tag spans).
- **Trinity parity (byte-identity of all tagged lines, C==A==G):**
  ```
  $ diff <(C tag-lines, sorted) <(A tag-lines, sorted)  → (empty)   C==A byte-identical
  $ diff <(C tag-lines, sorted) <(G tag-lines, sorted)  → (empty)   C==G byte-identical
  ```
  Slug-set parity: CLAUDE/AGENTS/GEMINI each carry the identical 18 `[rationale:]`
  slugs (diff empty both directions).

## 5. validate-pack PASS evidence

```
$ python3 scripts/validate-pack.py
...
PASSED — all checks clean
EXIT=0
```

No check tripped. Check 45 (bijection) is wired in C3 (a later commit) — not
present at this base HEAD — so the bijection here is proved by the manual diff
in §3, not by a validator. No corpus-body-structure check exists. (Manifest
regen is Pack Chat's at commit — `build.sh` was NOT run; nothing staged.)

## 6. Plan deviations

None. This fix applies the user-locked POQ-C2-1 resolution (option a) exactly:
remove the 3 `[rationale:]` pointers + the 3 filler sections; land bijection at
18==18. POQ-C2-1 is hereby RESOLVED (option a).

## 7. New POQs introduced

None.

## 8. Definition-of-Done checklist

| Item | Result |
|---|---|
| 3 corpus rules: `[rationale:]` removed | PASS (0 hits in corpus slug-set) |
| 3 corpus rules: `[roles: universal]` kept | PASS (1 exact-match each, all 3 trinity) |
| 3 RATIONALE filler sections removed | PASS (18 headings remain) |
| Other 18 RATIONALE sections untouched | PASS |
| Other 18 corpus rules untouched (pointers intact) | PASS |
| Bijection 18==18, no orphan either direction | PASS (diff empty) |
| Bullet counts unchanged (45/41/41) | PASS (0 bullets add/removed) |
| Trinity tag-line byte-identity (C==A==G) | PASS (diff empty both directions) |
| Edit-in-place (targeted edits, not rewrite) | PASS (12 targeted Edits; only 3 tag spans + 3 sections changed) |
| `validate-pack.py` PASS | PASS (exit 0, all checks clean) |
| No git state changes; no build.sh; nothing staged | PASS |
| Prison untouched | PASS (not read/cited) |

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| Agents never commit | No `git add/commit/push/tag` run; only Edit + this Write; `git status` shows ` M`/`??` working-tree changes, nothing staged | COMPLIANT |
| EDIT IN PLACE — targeted Edits, NOT full rewrite | 12 targeted `Edit` calls touching only the 3 tag spans (×3 trinity) + 3 RATIONALE sections; `git`-level bullet count unchanged (45/41/41); other 18 rules + 18 sections byte-unchanged | COMPLIANT |
| TRINITY lock-step | Same 3 `[rationale:]` removals applied to CLAUDE/AGENTS/GEMINI; tag-line text byte-identical across all three (sorted-tagline diff empty C-vs-A, C-vs-G); slug-sets identical (18 each) | COMPLIANT |
| Bijection now 18==18 | `diff` of rationale `## <slug>` headings (18) vs corpus `[rationale: slug]` slugs (18) is EMPTY; no orphan either direction | COMPLIANT |
| PREFLIGHT before report | Emitted `PREFLIGHT: 12/12 ... verification PASS; HEAD 84206ad...` before this Write | COMPLIANT |
| Verification before PREFLIGHT (validate-pack, pack-ops/ touched) | `python3 scripts/validate-pack.py` → `PASSED — all checks clean`, exit 0 | COMPLIANT |
| Manifest regen is Pack Chat's at commit (NOT coder's) | Did NOT run `build.sh`; staged nothing | COMPLIANT |
| Boundary discipline (P-missed-7) | No project-side file edited; edits are pack-root trinity + `pack-ops/` (pack-only); RATIONALE.md is pack-only, not client-installed | N/A: no project-side file touched |
| Prison rule | `maintenance-docs/prison/` not read, cited, or trusted | COMPLIANT |
| Output ends with Rules-Applied Verification Block (concise) | This block | COMPLIANT |
