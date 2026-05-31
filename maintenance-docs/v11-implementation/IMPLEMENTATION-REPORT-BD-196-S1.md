# IMPLEMENTATION-REPORT — BD-196 S1: split 2 rules + tag-only 1 (corpus reconciliation)

**Agent:** `pack-coder`. **Branch:** `v11-dev`. **Base HEAD (pre-flight):**
`1da5376cc32f20eeb2f90421ddd95238e2d07693`. **Final HEAD:**
`1da5376cc32f20eeb2f90421ddd95238e2d07693` (UNCHANGED — agents never commit;
all changes are working-tree only, staged by nobody). **Date:** 2026-05-31.

**Spec:** `ARCHITECTURE-BD-196-S1-CORPUS-CLASSIFICATION.md` §6 (2 SPLIT + 1
TAG-ONLY, bijection 18→20) + `ARCHITECTURE-BD-196-S1-RULE-BODY-TREATMENT.md` §4
(the 2 SPLIT rules' mechanical strategy). User-approved scope: rows 20, 33
SPLIT; row 35 TAG-ONLY; F1/F2 (rows 14/17) STAY-INLINE (no change).

**Result:** ONE-commit-ready, trinity-lock-step. `validate-pack.py` exit 0;
Check 45 bijection **20==20**; trinity parity byte-identical across all three
files; manifest regen empty. No deviations from the approved plan.

---

## 1. Files changed (inventory)

| Path | Change type | Net line delta |
|---|---|---|
| `CLAUDE.md` | modified | −94 (101 removed / 7 added across the 2 split rules + 1 line on tag-only) |
| `AGENTS.md` | modified | −94 (trinity lock-step, identical) |
| `GEMINI.md` | modified | −94 (trinity lock-step, identical) |
| `pack-ops/PACK-MEMORY-RATIONALE.md` | modified | +86 (2 new `## <slug>` sections) |
| `pack-ops/.spawn-rule-manifest.txt` | modified | +1/−1 (slug-field reconciliation; blast-radius Step 4/5) |

`git diff --stat`: `5 files changed, 129 insertions(+), 295 deletions(-)`.
(The two untracked `ARCHITECTURE-BD-196-S1-*.md` are the architect's input
docs — NOT touched by this coder.)

No new files created. No project-side / client-installed / migrator / agent-
definition / scripts surface touched — pure pack-ops + pack-root-trinity.

---

## 2. Per-rule before/after

### 2.1 Rule 1 — SPLIT → `enumerate-rules-inline` (corpus row 20)

**Subsection:** `### Agent invocation rules`. **Before:** 35 inline lines
(9-line imperative + 10-line `**Why:**` + 14-line `**How to apply:**`),
untagged. **After (trinity imperative, byte-identical ×3):**

```
- **Agent prompt enumerates ALL applicable rules inline.** Every
  sub-agent prompt Pack Chat constructs MUST enumerate ALL applicable
  pack-memory rules + trinity sections INLINE as literal rule text
  (name + Why + How-to-apply), never by reference or hyperlink — before
  spawning ANY sub-agent, assemble a "Rules in force" block selecting
  the rules tagged for the spawn's role plus the universal rules. Pack
  Chat NEVER spawns an agent without the rules-in-force block.
  `[roles: universal] [rationale: enumerate-rules-inline]`
```

Two-clause form: DIRECTIVE = "MUST enumerate ALL applicable rules + trinity
sections INLINE as literal text, never by reference/hyperlink"; TRIGGER =
"before spawning ANY sub-agent — assemble a Rules-in-force block selecting
role-tagged + universal rules." The load-bearing "NEVER spawns without the
block" clause is preserved inline.

**RATIONALE section landed** (`## enumerate-rules-inline`, inserted in corpus
order between `## preflight-stop-means-stop` and `## rules-applied-
verification-block`): carries the full `**Why:**` (BD-195 C6/C7 history +
token-cost note) + a paragraph capturing the "LITERAL rule text … pasted …
not by reference … agent does not have to discover them" detail that left the
imperative, + the full 6-section `**How to apply:**` prompt-assembly recipe
(sections 1–6), with the cross-pointer to `rules-applied-verification-block`
de-linked to a plain slug reference (RATIONALE style). NO content loss — Why +
6-section recipe both survive verbatim in substance.

### 2.2 Rule 2 — SPLIT → `bounded-review-fix-cycle` (corpus row 33)

**Subsection:** `### Pack Chat scope`. **Before:** 66 inline lines (8-line
imperative + 20-line 7-step Cycle + 13-line `**Why:**` + 8-line `**How to
apply:**` + 6-line Architect-escalation contract + 4-line Final-reviewer-pass
note + 1-line "Sharpens…" pointer), untagged — the largest rule in the corpus.
**After (trinity imperative, byte-identical ×3):**

```
- **Pack Chat NO coder review; bounded reviewer/fix cycle.** Pack
  Chat NEVER reviews coder output directly and does NO fixes itself;
  every coder run is followed by a BOUNDED review/fix cycle — maximum
  2 review/fix pairs + 1 final reviewer pass = 3 reviewer / 2 fix-coder
  spawns per commit. If dirty after the final reviewer pass, STOP the
  cycle and spawn `pack-architect` to diagnose root cause + propose a
  path forward — no fix-coder pass 3 is allowed.
  `[roles: universal] [rationale: bounded-review-fix-cycle]`
```

Two-clause form: DIRECTIVE = "Pack Chat NEVER reviews coder output directly +
does NO fixes itself; every coder run gets a BOUNDED review/fix cycle"; TRIGGER
= "max 2 review/fix pairs + 1 final reviewer = 3 reviewer / 2 fix-coder per
commit; if dirty after final reviewer, STOP + spawn architect — no fix-coder
pass 3." The "Sharpens 'Pack Chat does NO fixes'" pointer was FOLDED into the
RATIONALE Why-block (coder's-call per §4; recorded as a deviation-free choice).

**RATIONALE section landed** (`## bounded-review-fix-cycle`, inserted in corpus
order between `## ci-guard-measure-then-bound` and `## pack-side-project-
concepts-deliverable-only`): carries the COMPLETE procedure — full `**Why:**`
(judgment-compromise history + the folded "Sharpens 'Pack Chat does NO fixes'"
clause), the full 7-step Cycle (steps 1–7 verbatim in substance), the full
`**How to apply:**` (progress-marker string examples + "does NOT use
Read/Edit/Bash to verify coder edits"), the full Architect-escalation contract,
and the full Final-reviewer-pass note. The governing procedure that controls
THIS very review process is preserved completely — substance unchanged.

### 2.3 Rule 3 — TAG-ONLY → `[roles: universal]` (corpus row 35)

**Subsection:** `### Repo conventions`. **Before:** 3 lines, untagged. **After
(byte-identical ×3):**

```
- **`pack-ops/BACKLOG.md` has no Resolved section.** Entries resolve in place by
  flipping `Status: Open` to `Status: Resolved` and filling the
  `Resolved:` line. Do not propose moving entries to a separate section.
  `[roles: universal]`
```

Imperative text UNCHANGED; only `[roles: universal]` appended. NO `[rationale:]`
(self-contained, Test B=NO) → NO RATIONALE section → NO bijection impact.

---

## 3. Trinity-parity proof (the load-bearing verification)

Each of the 3 edited rule blocks was extracted from each trinity file and
md5-hashed; all three files match per rule (true parity, not just count):

```
--- block: Agent prompt enumerates ALL applicable rules inline ---
4247b03d5e2d3906d36ad2dc87f5f5c5   (CLAUDE.md)
4247b03d5e2d3906d36ad2dc87f5f5c5   (AGENTS.md)
4247b03d5e2d3906d36ad2dc87f5f5c5   (GEMINI.md)
--- block: Pack Chat NO coder review ---
9e1e02d6457b49ca22c52c92405d0d1c   (CLAUDE.md)
9e1e02d6457b49ca22c52c92405d0d1c   (AGENTS.md)
9e1e02d6457b49ca22c52c92405d0d1c   (GEMINI.md)
--- backlog rule block (ends at [roles: universal]) ---
61746b139f0341496f923366dbd383a0   (CLAUDE.md)
61746b139f0341496f923366dbd383a0   (AGENTS.md)
61746b139f0341496f923366dbd383a0   (GEMINI.md)
```

Per-file slug presence (each 1/1/1):
```
CLAUDE.md: enumerate=1 bounded=1 backlog-rule=1
AGENTS.md: enumerate=1 bounded=1 backlog-rule=1
GEMINI.md: enumerate=1 bounded=1 backlog-rule=1
```

`validate-pack.py` trinity checks (Check 16 / 18 / 19, pack-root + project-
template) all reported OK (no structure/scaffolding/addenda regression — these
edits change tag content, not H2 structure).

---

## 4. Cross-CLI-token finding

The 2 SPLIT rules are universal-process rules. I inspected each moved/edited
imperative for per-CLI tokens (tool names, commands, paths that differ by CLI
per `ARCHITECTURE-BD-182.md` §4.1). **Finding: NONE.** Both imperatives name
only platform-neutral concepts (`Pack Chat`, `pack-architect`, `pack-reviewer`,
`pack-fix-coder` — pack agent names, not CLI-specific tool tokens; "Rules in
force block", "review/fix pairs"). Therefore the three trinity imperatives are
CORRECTLY byte-identical (§3 md5 proof) — no audience-correct normalization was
required. (The Claude-only SendMessage/Agent-Teams notes that DO carry per-CLI
tokens live in the separate `### Sub-agent behavior (Claude-only)` subsection,
which was NOT touched.)

---

## 5. Bijection 20==20 proof + validate-pack + per-check tests

**Check 45 (the bijection gate), from `python3 scripts/validate-pack.py`:**
```
── Check 45: pack-memory rule↔rationale bijection (BD-196) ──
  OK: Check 45 — 20 corpus `[rationale: slug]` pointer(s); 20 rationale
  `## <slug>` section(s); sets are equal (bijection holds, no orphans in
  either direction).
```
Was 18==18 before; +2 corpus pointers (`enumerate-rules-inline`,
`bounded-review-fix-cycle`) + 2 RATIONALE `## <slug>` sections = balanced 20==20.
The TAG-ONLY rule added NO `[rationale:]`, so it did not touch the bijection
(as designed).

**RATIONALE slug-section order (20, corpus order preserved):**
```
agents-never-commit, per-action-approval-sub-agents, deferred-work-tracked-anchor,
no-deferral-without-user-direction, deferral-is-scope-creep,
boundary-investigation-precedes-pack-defaults, preflight-stop-means-stop,
enumerate-rules-inline [NEW], rules-applied-verification-block,
empirical-evidence-blocks, ci-guard-measure-then-bound,
bounded-review-fix-cycle [NEW], pack-side-project-concepts-deliverable-only,
enumerate-encoding-surfaces, skill-agent-maintenance-mechanical,
pack-repo-code-comment-deferrals, filename-uniqueness-heuristic,
architect-doc-reality-reconciliation, regenerate-manifest-v11-surface,
cross-cli-reference-normalization
```

**`validate-pack.py`:** `EXIT=0` → final line `PASSED — all checks clean`.

**Per-check tests:**
- `scripts/tests/test-validate-pack-check-45.sh`: `EXIT=0`, `PASS: 3 / FAIL: 0`,
  "All tests passed."
- `scripts/tests/test-validate-pack-check-46.sh`: `EXIT=0`, `FAIL: 0`,
  "All tests passed." (run because the spawn-rule manifest was touched.)

---

## 6. Blast-radius sweep (Step 4/5)

**Inbound prose cites of the moved inline bodies:** grep across `*.md` (excl.
`prison/`, `archive/`, the trinity, RATIONALE, the BD-196 architect/impl docs)
for "bounded review/fix cycle", "enumerate-inline rule", "Cycle (per commit)",
"Architect-escalation contract" → **0 dangling cites**. Nothing repointed.

**`pack-ops/.spawn-rule-manifest.txt`:** a record existed for Rule 2 with
`slug: pack-chat-no-coder-review-bounded-cycle` (a rule-name token, used
because Rule 2 had no `[rationale:]` slug pre-split). Now that Rule 2 carries
`[rationale: bounded-review-fix-cycle]`, the manifest's own format contract
(lines 14–15: "rationale slug, OR the rule-name token for rules WITHOUT a
`[rationale:]` slug") makes the rationale slug the correct value. I updated the
`slug:` field to `bounded-review-fix-cycle` (one-line edit; `canonical:` /
`corpus:` / `references:` unchanged and still accurate). Rule 1 has NO manifest
record (no reference surfaces were collapsed for it) → no row to add. Check 46
(reference-resolution + anti-restate) re-ran clean after this edit (6 rules
resolve; 0 verbatim restatements; 45 candidate bodies scanned).

---

## 7. Manifest regen (Step 6)

`bash test-fixtures/build.sh --all --clean` → `BUILD EXIT=0`. `git diff
test-fixtures/manifest.txt` → **EMPTY**. As predicted: `PACK-MEMORY-RATIONALE.md`
and `.spawn-rule-manifest.txt` live under `pack-ops/` (v11-surface, so the
rebuild was mandatory) but are NOT client-installed by `init-project.sh`, so the
client-install manifest is unaffected. Pack-root trinity files are not
v11-surface. **No manifest staging required.**

---

## 8. Plan deviations

**ZERO functional deviations.** Two coder's-call choices the architect §4
explicitly delegated, recorded for the record:
1. Rule 2 "Sharpens 'Pack Chat does NO fixes'" one-line pointer → FOLDED into
   the RATIONALE `## bounded-review-fix-cycle` Why-block (architect §4 permitted
   "keep inline OR fold to rationale; coder's call"). Chosen: fold, so the
   inline imperative stays application-grade.
2. `.spawn-rule-manifest.txt` slug-field reconciliation (§6) — performed under
   the architect's Step 4/5 "update rows if present (§9.6)" instruction;
   conforms the manifest to its own documented slug-preference contract. Not a
   new design; a faithful reconciliation.

`[roles: universal]` chosen for both SPLIT rules per architect §4
recommendation (controlled-vocab safe value; both bind Pack Chat universally).

---

## 9. New POQs introduced

NONE.

---

## 10. Definition-of-Done checklist

| Item | Status |
|---|---|
| Rule 1 split: two-clause imperative + `[roles: universal] [rationale: enumerate-rules-inline]` ×3 trinity | PASS |
| Rule 1 Why/How moved to `## enumerate-rules-inline` (no content loss) | PASS |
| Rule 2 split: two-clause imperative + `[roles: universal] [rationale: bounded-review-fix-cycle]` ×3 trinity | PASS |
| Rule 2 Why/7-step-Cycle/escalation/final-reviewer-note moved to `## bounded-review-fix-cycle` (complete) | PASS |
| Rule 3 tag-only: `[roles: universal]` appended ×3 trinity; no rationale; no bijection change | PASS |
| Slug names exact (`enumerate-rules-inline`, `bounded-review-fix-cycle`) | PASS |
| Trinity parity byte-identical ×3 (md5 §3) | PASS |
| Check 45 bijection 20==20 | PASS |
| `validate-pack.py` exit 0 | PASS |
| `test-validate-pack-check-45.sh` pass (3/0) | PASS |
| `test-validate-pack-check-46.sh` pass (manifest touched) | PASS |
| Manifest regen run; diff reported (empty, not staged) | PASS |
| No other `## Pack memory` rule/section changed (diff scope verified) | PASS |
| No state-changing git; HEAD unchanged (`1da5376`) | PASS |
| Edit-in-place (no full-file rewrite) | PASS |

---

## 11. Rules-Applied Verification Block

| Rule (Rules-in-force) | Verification evidence | Conclusion |
|---|---|---|
| Trinity rule (lock-step ×3) | md5 of all 3 edited blocks identical across CLAUDE/AGENTS/GEMINI (§3): enumerate=`4247b03d…`, bounded=`9e1e02d6…`, backlog=`61746b13…` (each printed 3× identical). Slug presence 1/1/1 per file. validate-pack Check 16/18/19 OK. | COMPLIANT |
| Cross-CLI reference normalization | §4: inspected both SPLIT imperatives — NO per-CLI token present (only platform-neutral + pack-agent names). Byte-identical trinity is therefore correct; no normalization needed (recorded the finding). | COMPLIANT |
| Edit-in-place, not full rewrite | All 11 edits were targeted `Edit` old→new string replacements (9 trinity rule blocks + 2 RATIONALE inserts anchored on adjacent `---`+`## <slug>` headers) + 1 manifest slug line; no `Write` over any in-scope file. RATIONALE section map re-read post-edit (20 slug headers, corpus order). Trinity diff scope: only the 2 new `[rationale:]` slugs added, no other slug touched. | COMPLIANT |
| Enumerate ENCODING surfaces | The split's expected state is encoded by Check 45 (bijection) + Check 46 (spawn-rule manifest, since touched) + the per-check tests; all enumerated and run: Check 45 = 20==20, Check 46 OK, both test scripts PASS. | COMPLIANT |
| Regenerate manifest on v11-surface commits | §7: `pack-ops/` files touched → `bash test-fixtures/build.sh --all --clean` run (EXIT 0); `git diff test-fixtures/manifest.txt` EMPTY; reported, not staged (per prompt). | COMPLIANT |
| Pack-coder PREFLIGHT + STOP-MEANS-STOP | PREFLIGHT line emitted in chat AFTER all edits + verification PASS (validate-pack exit 0, Check 45 20==20, both per-check tests, trinity md5). No parent stop received. | COMPLIANT |
| Agent output requires Rules-Applied Verification Block | This table. | COMPLIANT |
| Agents never commit / per-action approval / no destructive ops / no deferral | Only read-only verbs + `python3 validate-pack.py` + `bash test-*/build.sh` run; no `git add/commit/push/tag/etc.`; final HEAD `1da5376` == base HEAD (unchanged); no `rm`/overwrite of trusted files; `maintenance-docs/prison/` not read; full S1 scope implemented in this commit, nothing deferred. | COMPLIANT |

**End of IMPLEMENTATION-REPORT-BD-196-S1.md.**
