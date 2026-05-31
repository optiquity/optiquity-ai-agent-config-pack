# IMPLEMENTATION-REPORT — BD-196 commit C8

§11.3 routing pointers + §12 propagation table + trinity stale-entry pointer.

## Worktree / state

- **Branch:** `v11-dev`
- **Base / final HEAD SHA:** `b83c0dc858c1349caaf4f7e71065af863a7f302f` (no commit made — agents never commit; Pack Chat stages/commits with user approval)
- **Pre-flight:** `git rev-parse HEAD` = b83c0dc; `git status` = clean at start; in-scope dirs (`pack-ops/`, `.claude/skills/review/`, pack-root trinity) verified present.
- **Scope class (CI Check 36):** `pack-only` — touches only pack-root trinity + `pack-ops/` + `.claude/skills/` (pack-internal); NO `project-template/` or `supporting-docs/`.

## Files changed (inventory)

| Path | Change type |
|---|---|
| `pack-ops/PACK-CHAT.md` | modified (2 regions: File access strategy routing pointers; §12 propagation table) |
| `.claude/skills/review/SKILL.md` | modified (`[roles: reviewer]` tag + reviewer routing pointer) |
| `CLAUDE.md` (pack-root) | modified (stale-entry rule → §12 pointer) |
| `AGENTS.md` (pack-root) | modified (trinity-parallel) |
| `GEMINI.md` (pack-root) | modified (trinity-parallel) |
| `pack-ops/.boundary-pointer-manifest.txt` | modified (header note + 3 §11.3 routing-pointer records) |

`test-fixtures/manifest.txt` — regenerated, diff EMPTY (not in changeset).

No new files. No deletions.

## Per-task detail

### Task 1 — PACK-CHAT.md (a) File access strategy routing pointers

Authored after the File access strategy table (PACK-CHAT.md L50-51). Exact line:

> **Rule-SSOT routing (one hop to the authority — no index, query the SSOT directly):**
> For spawn-relevant rules, read trinity `## Pack memory`. For file placement, read `pack-ops/BOUNDARY-DEFINITION.md` §2 matrix. For a rule's rationale, read `pack-ops/PACK-MEMORY-RATIONALE.md` (`[rationale: <slug>]`). To add/change/remove a rule, follow the change-procedure in § "Keeping CLAUDE.md, AGENTS.md, GEMINI.md, and PACK-AGENTS.md current" below.

This is the §11.3 "Durable home per actor" Pack-Chat row: 4 one-hop pointers (rules → `## Pack memory`; placement → BOUNDARY §2; rationale → `PACK-MEMORY-RATIONALE.md`; change-procedure → §12). One-line references, no enumeration — index stays DROPPED (Decision B).

### Task 1 — PACK-CHAT.md (b) §12 propagation table

Extended § "Keeping … current" with the §12 ordered surfaces-1-6 table (PACK-CHAT.md L295-309). As authored:

```
### Rule-change propagation procedure (add / change / remove a spawn-relevant rule)

This procedure also owns the ordered surfaces to touch when a spawn-relevant `## Pack memory` rule is added, changed, or removed. It composes the existing enforcement checks — it adds no new check.

| # | Surface to touch | Enforcing check |
|---|---|---|
| 1 | Corpus imperative line ×3 trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` `## Pack memory`), incl. `[roles:]` tag + `[rationale: slug]` | trinity-parity + role-tag controlled-vocab |
| 2 | `pack-ops/PACK-MEMORY-RATIONALE.md` — add/edit/remove the `## <slug>` entry | C3 bijection (slug-set equality) |
| 3 | Thin memory-cache pointer (out-of-repo) | Pack-Chat upkeep; trinity-wins (no validator gate, no pack generator) |
| 4 | Any reference surface (`PACK-AGENTS.md` / `PACK-CHAT.md` one-line refs) | anti-restate scan + reference-resolution |
| 5 | `pack-ops/.spawn-rule-manifest.txt` slug→canonical+references | reference-resolution |
| 6 | `test-fixtures/manifest.txt` regen if a v11-surface path changed | existing manifest CI gate |

- **Order:** corpus (1) → rationale (2) → references (4) + manifest (5) in the SAME commit (so C3 bijection + anti-restate never see a half-applied state) → cache (3) as Pack-Chat upkeep → manifest regen (6) last. Removing a rule reverses: drop references first, then rationale, then corpus.
- **Order is documented, not gate-sequenced:** a commit is atomic; the propagation order is verified by END-STATE checks (bijection / anti-restate / trinity-parity / manifest), not a hard-enforced step sequence.
```

Table content matches architecture §12 surfaces-1-6 + the Order bullet + the "documented, not gate-sequenced" caveat. No new check introduced (composes existing checks per §12 HOW-enforced).

### Task 2 — review SKILL.md

Item 0 gained `[roles: reviewer]` and a universal routing pointer (SKILL.md L9 + L11). Exact pointer line:

> **Rule-SSOT routing (reviewer entry point — one hop, no index).** The spawn rules that apply to a review are the trinity `## Pack memory` rules tagged `[roles: reviewer]` or `[roles: universal]`; read them there. For file placement, read `pack-ops/BOUNDARY-DEFINITION.md` §2 matrix; for a rule's rationale, read `pack-ops/PACK-MEMORY-RATIONALE.md` (`[rationale: <slug>]`). Query the SSOT directly — there is no enumerated rule×audience index.

This extends the existing SSOT cites (P-missed-7 + boundary-investigation) with `[roles: reviewer]` + universal spawn-rule routing, per §11.3 reviewer row.

### Task 3 — trinity stale-entry pointer (lock-step ×3)

Identical one-line pointer appended to the `## Pack memory` intro sentence in all three pack-root trinity files. Quoted from each (verbatim-identical):

- **CLAUDE.md:**
  > To add, change, or remove a spawn-relevant rule, follow the ordered propagation procedure in `pack-ops/PACK-CHAT.md` § "Keeping CLAUDE.md, AGENTS.md, GEMINI.md, and PACK-AGENTS.md current".
- **AGENTS.md:** (identical text — verified by grep below)
- **GEMINI.md:** (identical text — verified by grep below)

Trinity-parity proof (grep, all three return identical normalized text):

```
spawn-relevant rule, follow the ordered propagation procedure in `pack-ops/PACK-CHAT.md` § "Keeping CLAUDE.md, AGENTS.md, GEMINI.md, and PACK-AGENTS.md current".   ← CLAUDE.md
spawn-relevant rule, follow the ordered propagation procedure in `pack-ops/PACK-CHAT.md` § "Keeping CLAUDE.md, AGENTS.md, GEMINI.md, and PACK-AGENTS.md current".   ← AGENTS.md
spawn-relevant rule, follow the ordered propagation procedure in `pack-ops/PACK-CHAT.md` § "Keeping CLAUDE.md, AGENTS.md, GEMINI.md, and PACK-AGENTS.md current".   ← GEMINI.md
```

**Cross-CLI normalization check:** the pointer targets a single pack-ops file (`pack-ops/PACK-CHAT.md`) identical for all three audiences — there is NO per-CLI path/command token in the pointer, so no ARCHITECTURE-BD-182 §4.1 normalization applies; the text is correctly byte-identical across the trinity (confirmed).

### Task 4 — manifest extension (§11.3 routing-pointer surfaces)

Header note rewritten to document the two surface classes (C6 entry-point network + C8 §11.3 routing pointers, both resolved by Check 46's generic substring resolution; index stays dropped).

Three records added (each binds to a pointer that ACTUALLY resolves — verified below):

```
surface:   pack-ops/PACK-CHAT.md
pointer:   Rule-SSOT routing (one hop to the authority
role:      Pack-Chat startup doc, § "File access strategy" — routes Pack Chat to the rule SSOTs (## Pack memory / BOUNDARY §2 / PACK-MEMORY-RATIONALE.md / the §12 change-procedure). §11.3 Decision C.

surface:   .claude/skills/review/SKILL.md
pointer:   Rule-SSOT routing (reviewer entry point
role:      Review skill — routes the reviewer to its [roles: reviewer]+universal spawn rules + the placement/rationale SSOTs. §11.3 Decision C.

surface:   pack-ops/BOUNDARY-DEFINITION.md
pointer:   four-step placement procedure (§3)
role:      BOUNDARY self-homed — the file-mover / project-side-author lands on the placement entry doc itself (§2 matrix + §3 procedure in-doc). §11.3 Decision C.
```

BOUNDARY self-homed required NO edit to BOUNDARY-DEFINITION.md — the `four-step placement procedure (§3)` substring already exists (L15), so the manifest record resolves against the existing self-homed routing text (§11.3 "self-homed — §2 matrix + §3 procedure are in the doc the actor lands on"). Measure-then-bound: every record binds to a pointer present at HEAD; no record added for a surface lacking a pointer.

## Verification

### Manifest pointer-resolution (each substring present in its surface)

```
=== PACK-CHAT pointer ===        grep -c "Rule-SSOT routing (one hop to the authority" pack-ops/PACK-CHAT.md → 1
=== review skill pointer ===     grep -c "Rule-SSOT routing (reviewer entry point" .claude/skills/review/SKILL.md → 1
=== BOUNDARY self-homed ===      grep -c "four-step placement procedure (§3)" pack-ops/BOUNDARY-DEFINITION.md → 1
```

### Check 46 (full validate-pack)

```
Check 46 — boundary manifest: 11 surface(s) resolve their BOUNDARY-DEFINITION pointer; spawn manifest: 6 rule(s) resolve to `## Pack memory`; anti-restate: 0 verbatim imperative-body restatements across 6 spawn-relevant surface(s) (45 candidate bodies scanned, >= 60 chars).
```

8 original entry-point surfaces + 3 new §11.3 routing-pointer surfaces = 11; 0 unresolved; 0 anti-restate hits.

### validate-pack.py

```
PASSED — all checks clean
VALIDATE_EXIT=0
```

Check 45 (bijection) held at 18=18 — the trinity pointer appends to the intro paragraph (not a new rule), so no rationale-slug delta. Trinity-parity checks ran clean (validate-pack exit 0).

### Check-46 per-check test

```
=== Summary ===  PASS: 3  FAIL: 0  All tests passed.  TEST46_EXIT=0
```

### Manifest regen

```
bash test-fixtures/build.sh --all --clean → BUILD_EXIT=0
git diff --name-only test-fixtures/manifest.txt → (empty)
```

Manifest diff EMPTY — the manifest tracks fixture-tree content, not pack-ops docs; my edits do not change the fixture tree. Nothing to stage for the manifest.

## G-E zero-pointer proof (NO project PM-CHAT pointer)

```
grep -c "BOUNDARY-DEFINITION" project-template/docs/pack/PM-CHAT.md → 0
grep -rn "Rule-SSOT routing" project-template/ supporting-docs/ → (no matches)
```

`project-template/docs/pack/PM-CHAT.md` carries ZERO `BOUNDARY-DEFINITION.md` references (unchanged); no `Rule-SSOT routing` pointer leaked into any project-side surface. The V1-class project→pack-only boundary leak is NOT introduced.

## 7b sweep (withdrawn discoverability index)

`grep -rniE "rule.{0,3}audience index|the unified index|the discoverability index|see PACK-CHAT for the index"` (excluding prison + .git):

| Hit | Disposition |
|---|---|
| `.claude/skills/review/SKILL.md:11` | MY new pointer — a NEGATIVE cite ("there is no enumerated rule×audience index"). Correct; affirms the drop. KEEP. |
| `ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md:213,219` | Design-doc-internal 7b-sweep instruction naming the patterns to grep. KEEP. |
| `ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md:333` | §11.2 Decision B text that WITHDRAWS the index (deliberate negative cite). KEEP. |
| `PLAN-DOC-CONCISION-GUARDRAILS.md:113` | C8 7b-sweep instruction naming the patterns. Design-internal. KEEP. |

**Result:** ZERO live-surface stale cites implying a now-existing index (exactly as the plan predicted: "mostly design-doc-internal, possibly zero in live surfaces"). No `see PACK-CHAT for the index` cite exists anywhere. The only live-surface hit is my own negative cite affirming the index is dropped. No fix-or-remove required.

## Plan deviations

ZERO. All C8 work landed per PLAN §3 C8 + architecture §11.3/§12: 4 PACK-CHAT routing pointers, §12 table, review-skill `[roles: reviewer]`+pointer, trinity stale-entry pointer ×3 lock-step, 3 manifest records. Index stayed DROPPED (no new file/view/check). BOUNDARY required no edit (self-homed text pre-existing).

## New POQs

None. No architecture gap encountered; G-E was pre-resolved by the user-lock (NO project PM-CHAT pointer) and honored.

## Definition-of-Done checklist

| Item | Result |
|---|---|
| PACK-CHAT File access strategy gains §11.3 routing pointers | PASS |
| PACK-CHAT "Keeping … current" gains §12 ordered surfaces-1-6 table | PASS |
| review SKILL.md gains `[roles: reviewer]` + universal routing pointer | PASS |
| Trinity stale-entry pointer present + parallel in all 3 pack-root files | PASS |
| Manifest extended with each new routing-pointer surface (3 records) | PASS |
| Index stays DROPPED — no new index/view/check | PASS |
| G-E — zero project PM-CHAT → BOUNDARY pointer | PASS |
| Check 46 green — all records resolve, 0 anti-restate | PASS |
| validate-pack.py exit 0 | PASS |
| Check-46 per-check test PASS | PASS |
| 7b sweep — no live-surface withdrawn-index cite | PASS |
| test-fixtures/manifest.txt regenerated (diff empty) | PASS |
| No state-changing git verbs run | PASS |

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| Trinity rule (pack-root) | Stale-entry pointer byte-identical in CLAUDE.md/AGENTS.md/GEMINI.md (grep all 3 → identical normalized text; each `grep -c` = 1); validate-pack trinity-parity clean (exit 0) | COMPLIANT |
| Cross-CLI reference normalization | Pointer targets single pack-ops file `pack-ops/PACK-CHAT.md` § "Keeping…current"; no per-CLI path/command token present → byte-identical is correct (no §4.1 substitution applies) | COMPLIANT |
| G-E — NO project PM-CHAT pointer | `grep -c BOUNDARY-DEFINITION project-template/docs/pack/PM-CHAT.md` → 0; `grep -rn "Rule-SSOT routing" project-template/ supporting-docs/` → no matches | COMPLIANT |
| B5 anti-restate (Check 46) | Check 46: "anti-restate: 0 verbatim imperative-body restatements across 6 spawn-relevant surface(s) (45 candidate bodies scanned, >= 60 chars)"; pointers authored as one-line references, not rule-body copies | COMPLIANT |
| CI-guard measure-then-bound (manifest sizing) | 3 records added; each substring verified present in its surface (`grep -c` = 1 ×3); no record for a surface lacking a pointer; Check 46 → 11 surfaces resolve, 0 unresolved | COMPLIANT |
| Enumerate ENCODING surfaces | Pointer + its manifest record authored in lock-step (PACK-CHAT pointer↔record; review pointer↔record; BOUNDARY self-homed text↔record); Check-46 per-check test re-run (3/3 PASS) since manifest content changed | COMPLIANT |
| Edit-in-place, not full rewrite | All 6 edits targeted in-place Edits (diff stat: 60 insertions / 8 deletions across 6 files); re-read of PACK-CHAT L48-55 + L285-309 + review L7-12 confirms surrounding structure intact | COMPLIANT |
| Separate pack ops from pack product | Touched only pack-ops + pack-root trinity + `.claude/skills/`; zero `project-template/` or `supporting-docs/` edits (git status --short) | COMPLIANT |
| Regenerate manifest on v11-surface commit | `pack-ops/` touched → `bash test-fixtures/build.sh --all --clean` run (BUILD_EXIT=0); diff EMPTY → nothing to stage (reported) | COMPLIANT |
| Pack-coder PREFLIGHT + STOP-MEANS-STOP | PREFLIGHT line emitted only after all edits + all verification PASS; no parent stop received | COMPLIANT |
| Agent output requires Rules-Applied Verification Block | This table | COMPLIANT |
| Agents never commit / per-action approval / no destructive ops | Only read-only git verbs (rev-parse, status, diff) + Edit/Write/validate/test run; no `git add/commit/push/tag/mv/rm`; no destructive file ops | COMPLIANT |
| No deferral / deferral IS scope creep | All in-scope C8 work completed this pass; nothing deferred | COMPLIANT |
| Index stays DROPPED (Decision B) | No new index file/view/check authored; pointers are one-line references riding existing Check 46 | COMPLIANT |
| Prison rule | `maintenance-docs/prison/` not read; 7b grep excluded it | COMPLIANT |

**End of IMPLEMENTATION-REPORT-BD-196-C8.md.**
