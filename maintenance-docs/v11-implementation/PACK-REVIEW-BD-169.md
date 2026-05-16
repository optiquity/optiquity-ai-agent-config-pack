# PACK-REVIEW-BD-169 — Inline per-BD review of commit `cf67a96`

**Review subject:** BD-169 — per-entry split pack-product wording updates (commit `cf67a96`, 11 file edits + 1 IMPL-REPORT)
**Review type:** INLINE per-BD review (post-commit; pre-fix) under the Batch-19-forward inline pattern
**Reviewed against:**
- `PLAN-PER-ENTRY-SPLIT-BATCH-19.md` §5.8 (commit 19g-pack spec)
- `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §4.4.3 / §5.3 / §14.2 / §9.4 / §10.5
- `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md` §1.1 / §1.3 / §1.5 / §5.6 (Layer 0 deferral)
- `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md` §4 (BD-095 bridge) / §5.4 (PM-CHAT verbatim) / §6.6 (Codex SKILL=.md)
- `IMPLEMENTATION-REPORT-BD-169.md`
- `BACKLOG.md` BD-169 entry

**Reviewer:** pack-reviewer (sub-agent)
**Date:** 2026-05-16
**Pre-commit HEAD:** `9c238ab`
**Post-commit HEAD:** `cf67a96`

---

## §1 — Summary

BD-169 lands 11 prose / directive edits across PM-CHAT, MERGE-STRATEGY,
MIGRATION-v10-to-v11, audit-methodology SKILL, pack-startup × 3, and
pm-startup × 4. Architect-binding compliance is strong: PM-CHAT.md
Addition A matches Addendum #2 §5.4 verbatim character-for-character;
Addition B follows PLAN §5.8 spec; the startup directives match
Addendum #1 §1.3 sample shape (with sanctioned "coder refines"
qualifiers); the audit-methodology sub-bullets correctly delegate
through the existing auditor-docs.md skill-citation chain (R-4
assertion verified). Trinity rule is observed by md5sum across
pack-startup × 2 .md files and pm-startup × 3 .md files; the two
.toml files carry byte-identical substantive content inside the
`prompt = """..."""` wrapper. validate-pack.py PASSED clean.

**However**, the MIGRATION-v10-to-v11.md new "Per-entry decomposition"
section contains one MUST-fix forward-reference defect: it documents
`init-project.sh --install-pre-commit-hook` and
`project-template/scripts/git-hooks/pre-commit-check32.sh` as if they
exist, but per Addendum #1 §5.6 + the §0.1 disposition table these
are OUT OF SCOPE for v11.0 (Layer 0 deferral, possibly to v11.x).
Neither the flag nor the hook script exists in the working tree.

Two SHOULD-fix findings concern audit-methodology rule 29 sub-bullet
completeness (missing `_v8-resolved-archive.md` from the IN-SCOPE
list; detection criterion divergence from validate-pack.py Check 32).
Three NITs concern minor cosmetic alignment.

**Totals:** 1 MUST + 2 SHOULD + 3 NIT = 6 findings.

---

## §2 — Findings

### §2.1 — MUST (1)

**Finding M1 — MIGRATION-v10-to-v11.md documents v11.0-out-of-scope features as if they exist.**

- **Severity:** MUST
- **Location:** `supporting-docs/MIGRATION-v10-to-v11.md:337-340` (final paragraph of `### \`--force-overwrite-mirror\` flag (advanced)` subsection)
- **Finding:** The new "Per-entry decomposition" section claims `init-project.sh --install-pre-commit-hook` installs an "optional client-side pre-commit hook" with "block-and-flag semantics" — but the flag is not implemented in `init-project.sh` and the hook script `project-template/scripts/git-hooks/pre-commit-check32.sh` does not exist in the repository. Per `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md` §5.6, Layer 0 (opt-in pre-commit hook) is explicitly OUT OF SCOPE for v11.0; per Addendum #1 §0.1 it is "surfaced for planner" with a hypothetical "BD-172?" for v11.x inclusion.
- **Evidence:**
  ```
  # MIGRATION-v10-to-v11.md:337-340 (committed text):
  The same block-and-flag semantics apply to the optional
  client-side pre-commit hook (installed via
  `init-project.sh --install-pre-commit-hook`): the hook fails the
  commit on divergence and prints the recovery instruction.
  ```
  Verification:
  ```
  $ grep -rn "install-pre-commit-hook" scripts/
  (no output)
  $ ls project-template/scripts/git-hooks/
  ls: project-template/scripts/git-hooks/: No such file or directory
  $ grep -n "install-pre-commit-hook" BACKLOG.md PLAN-PER-ENTRY-SPLIT-BATCH-19.md EXECUTION-PLAN-V11.0.md
  (no v11.0-scope tracking entry)
  ```
  Architect binding from Addendum #1 §5.6:
  ```
  ### §5.6 — Layer 0 (opt-in for planner): sample pre-commit hook
  Out of scope for v11.0; surfaced for planner. If planner picks
  v11.0 inclusion, opens new BD (BD-172?). If planner defers to
  v11.x, accepts Layers 1–3 for v11.0.
  ```
  Addendum #2 §4.4 also references this flag but stays in the architect-design corpus; the architect explicitly defers shipping to planner discretion. Neither PLAN-PER-ENTRY-SPLIT-BATCH-19.md §5.8 nor any other v11.0 BD picks up the hook for v11.0 ship.
- **Suggested remediation:** Either (a) reframe the paragraph as a forward-looking note (e.g., "A future opt-in client-side pre-commit hook will inherit these same block-and-flag semantics; tracked separately for v11.x") and remove the literal flag invocation, OR (b) ship the flag and hook script in this batch (broader scope; would need new BD per project rules). Pack Chat decides — but the doc as committed describes a v11.0 user-runnable command that does not exist.

### §2.2 — SHOULD (2)

**Finding S1 — audit-methodology rule 29 sub-bullet detection criterion diverges from validate-pack.py Check 32 detection.**

- **Severity:** SHOULD
- **Location:** `project-template/skills/audit-methodology/SKILL.md:77` (second sub-bullet under rule 29)
- **Finding:** The new sub-bullet states that a stream's per-entry tree is "present" when its directory contains "one or more entry files (e.g., `BD-NNN.md`) alongside `_rules.md`". The actual validate-pack.py Check 32 + Check 33 + Check 34 detection (per `scripts/validate-pack.py:2891-2895`) is simpler: it tests `stream_dir.is_dir()` and the presence of `_rules.md` — without requiring any entry files. A freshly-init-project.sh-installed stream (containing only `_rules.md` + `_intro.md` + seed `_toc.md`, no BD entries yet) is "present" to the validator but "not present" per the audit-methodology detection rule. This produces inconsistent behavior: auditor-docs would audit the (still-existing) monolithic mirror, while validate-pack.py Checks 32/33 would fire mirror-in-sync against the empty tree.
- **Evidence:**
  ```
  # audit-methodology SKILL.md:77 (committed):
  Detection: a stream's per-entry tree is "present" when its directory
  contains one or more entry files (e.g., `BD-NNN.md`) alongside `_rules.md`.

  # scripts/validate-pack.py:2891-2895 (Check 32):
  for stream_key, stream_rel, mirror_rel, entry_regex in STREAMS:
      stream_dir = REPO_ROOT / stream_rel
      ...
      if not stream_dir.is_dir():
          # "not present (skipping; ...)"
  ```
  The greenfield case is the canonical edge case: a project that has run init-project.sh (BD-166) but not yet authored its first BD entry has populated `_rules.md`/`_intro.md`/`_toc.md` but zero entry files.
- **Suggested remediation:** Align the auditor detection rule to match the validator (presence of `_rules.md` is sufficient), OR pick a different unambiguous shared criterion documented in both places. Architect-doc binding: integration parent §10.5 ("backward-compatibility for pre-v11.0 clients") is silent on the empty-tree edge case; the two systems should agree.

**Finding S2 — audit-methodology rule 29 IN-SCOPE sub-bullet omits `_v8-resolved-archive.md` from the supporting-file list.**

- **Severity:** SHOULD
- **Location:** `project-template/skills/audit-methodology/SKILL.md:76` (first sub-bullet under rule 29)
- **Finding:** The IN-SCOPE supporting-file list reads `\`_rules.md\`, \`_intro.md\`, \`_format.md\`, and \`_toc.md\` supporting files`. The pack-side `/backlog/` per-entry tree also includes `_v8-resolved-archive.md` (per `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §2.6 + §10.5 + multiple references in lines 324/364/453/475/592). This file is pack-side `/backlog/` only and contains the legacy v8 resolved-archive content — it is authored documentation source-of-truth and belongs under auditor-docs scope by the same logic as `_rules.md`. The rule 29 sub-bullet explicitly mentions "pack-side per-entry trees at `/backlog/` and `/changelog/` when present (pack-self dog-food per integration parent §10.5)" but enumerates supporting files only for the project-side common set.
- **Evidence:**
  ```
  # audit-methodology SKILL.md:76:
  including each stream's `_rules.md`, `_intro.md`, `_format.md`,
  and `_toc.md` supporting files

  # ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md:324:
  - Supporting files (`_rules.md`, `_toc.md`, `_intro.md`,
    `_v8-resolved-archive.md`, `_format.md`) per addendum §3.2 —

  # ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md:364:
   - Pack `backlog/` only: `_v8-resolved-archive.md`.
  ```
  Pack-side trees do not yet exist (Batch 23 / BD-102 dependency), so the omission has no immediate operational impact — but the rule is intended to govern auditor behavior after dog-food lands.
- **Suggested remediation:** Add `_v8-resolved-archive.md` to the supporting-file list with a "(pack `/backlog/` only)" qualifier, parallel to how `_format.md` is implicitly changelog-only.

### §2.3 — NIT (3)

**Finding N1 — STATUS.md disclaimer literal in PM-CHAT.md uses PLAN-§5.8 wording rather than integration parent §5.3 wording (two distinct architect texts).**

- **Severity:** NIT
- **Location:** `project-template/docs/pack/PM-CHAT.md:220`
- **Finding:** The PM-CHAT.md disclaimer literal reads `<!-- Working snapshot. Source-of-truth lives in docs/project/backlog/ (per-entry tree). Regenerated mirror at docs/project/BACKLOG.md. Edits to STATUS.md must not contradict the per-entry tree. -->`. This matches PLAN-PER-ENTRY-SPLIT-BATCH-19.md §5.8 spec exactly. The integration parent §5.3 (lines 1140-1146) specifies a different disclaimer literal: `<!-- STATUS.md is a CONVENIENCE VIEW. It is NEVER source of truth. Counts and links may be stale; if they disagree with the per-entry tree at docs/project/backlog/ or the regenerated BACKLOG.md mirror, the per-entry tree wins. Workflows must not depend on STATUS.md being current; depend on the per-entry tree. -->`. The two sources prescribe different exact text; the implementation followed the PLAN. This is a documentation-coordination concern, not a coder defect — the PLAN's wording took precedence per the workflow.
- **Evidence:** See PLAN-PER-ENTRY-SPLIT-BATCH-19.md:851 and integration parent §5.3 lines 1140-1146.
- **Suggested remediation:** Document the wording choice (e.g., in the IMPL-REPORT §3 Group A or as an addendum to PLAN §5.8) so a future audit of the architecture-vs-implementation gap understands which spec wins. Or update one of the two architect texts to match the other for consistency.

**Finding N2 — audit-methodology sub-bullet `_format.md` reference lacks scope qualifier.**

- **Severity:** NIT
- **Location:** `project-template/skills/audit-methodology/SKILL.md:76`
- **Finding:** The supporting-file list mentions `_format.md` generically, but per architect §3.2 + §10.5, `_format.md` is changelog-stream-only (not present for `/backlog/` or `/implementation-plan/`). The "including" phrasing makes this technically defensible (non-exhaustive enumeration), but a reader of the skill might infer `_format.md` should exist for every stream.
- **Evidence:** `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md:365` — "Project `changelog/` only: `_format.md`."
- **Suggested remediation:** Add a "(`_format.md` is changelog-stream-only)" parenthetical qualifier.

**Finding N3 — MIGRATION-v10-to-v11.md "Per-entry decomposition" section size exceeds PLAN estimate.**

- **Severity:** NIT
- **Location:** `supporting-docs/MIGRATION-v10-to-v11.md:246-344`
- **Finding:** PLAN-PER-ENTRY-SPLIT-BATCH-19.md §5.8 specified "~30 lines"; the implementation is ~99 lines (246-344). The IMPL-REPORT §3 Group C acknowledges the size delta ("~85 lines (slightly over PLAN's ~30 estimate)") and asserts no padding. Spot-check confirms: the 5 sub-sections expand the bullet inventory faithfully without redundancy. The architect-doc planner-deferred-item authority covers exact wording but the ~30-line estimate was advisory, so this is informational only.
- **Evidence:** `wc -l` on the section yields ~99 lines including blank lines and the `---` separator; PLAN spec at line 853.
- **Suggested remediation:** None — the size delta is a planning estimate variance, not a defect. Recorded for visibility.

---

## §3 — Trinity rule compliance verification

Byte-faithful comparison results.

### §3.1 — pack-startup × 3

```
$ md5sum .claude/skills/pack-startup/SKILL.md .codex/skills/pack-startup/SKILL.md
df90c41d000a75b26e1a1082c701eb93  .claude/skills/pack-startup/SKILL.md
df90c41d000a75b26e1a1082c701eb93  .codex/skills/pack-startup/SKILL.md

$ diff .claude/skills/pack-startup/SKILL.md .codex/skills/pack-startup/SKILL.md
(no output)
```

**Claude SKILL.md and Codex SKILL.md are byte-identical.** Both are `.md` per Addendum #2 §6.6 (Codex SKILLs are `.md`; only Codex AGENTs are `.toml`).

```
$ grep -A 4 "Pack streams under" .gemini/commands/pack-startup.toml
Pack streams under `/backlog/` and `/changelog/` are per-entry trees
when present; read `/backlog/_rules.md` and `/changelog/_rules.md` for
the per-stream contract before any per-entry edit. The `BACKLOG.md` and
`CHANGELOG.md` files at the pack root are regenerated mirrors of those
per-entry trees, not source of truth.
```

**Gemini TOML carries identical substantive content** inside the existing `prompt = """..."""` wrapper. The TOML structural wrapper is the only format difference.

**pack-startup trinity rule: OBSERVED.**

### §3.2 — pm-startup × 4

```
$ md5sum project-template/skills/pm-startup/SKILL.md \
         project-template/.claude/skills/pm-startup/SKILL.md \
         project-template/.codex/skills/pm-startup/SKILL.md
3e852fa05da248cfc19d85509fdddc6a  project-template/skills/pm-startup/SKILL.md
3e852fa05da248cfc19d85509fdddc6a  project-template/.claude/skills/pm-startup/SKILL.md
3e852fa05da248cfc19d85509fdddc6a  project-template/.codex/skills/pm-startup/SKILL.md
```

**Canonical SKILL.md, Claude per-CLI SKILL.md, and Codex per-CLI SKILL.md are byte-identical.**

```
$ grep -A 5 "Project streams under" project-template/.gemini/commands/pm-startup.toml
Project streams under `docs/project/backlog/`, `docs/project/implementation-plan/`,
and `docs/project/changelog/` are per-entry trees in flat-file mode; read each
`<stream>/_rules.md` for the per-stream contract before any per-entry edit. The
`docs/project/BACKLOG.md`, `docs/project/IMPLEMENTATION-PLAN.md`, and
`docs/project/CHANGELOG.md` files are regenerated mirrors of those per-entry
trees, not source of truth.
```

**Gemini TOML carries identical substantive content** inside the existing `prompt = """..."""` wrapper.

**pm-startup trinity rule: OBSERVED.**

### §3.3 — audit-methodology SKILL.md (N/A this commit)

Single canonical edit at `project-template/skills/audit-methodology/SKILL.md`; per-CLI mirrors regenerate at install time via `init-project.sh stage_s4_skills`. **Trinity rule N/A this commit per PLAN §5.8.**

### §3.4 — PM-CHAT.md, MERGE-STRATEGY.md, MIGRATION-v10-to-v11.md (N/A)

Single-file pack-product docs; not trinity-replicated. **Trinity rule N/A.**

---

## §4 — Verbatim-drift verification (PM-CHAT Addition A vs Addendum #2 §5.4)

The two new rows in PM-CHAT.md file-access strategy table were inserted at lines 124-125.

**Addendum #2 §5.4 reference text (lines 1000-1003):**
```
| `docs/project/backlog/<ID>.md`, `docs/project/implementation-plan/<ID>.md`, `docs/project/changelog/<ID>.md` (per-entry source) | Direct read of single entry when only that entry is needed | Per-entry tree is source of truth in flat-file mode (per project-template trinity Document locations + `<stream>/_rules.md`); smaller token footprint than mirror for one-entry edits |
| `docs/project/backlog/_rules.md`, `docs/project/implementation-plan/_rules.md`, `docs/project/changelog/_rules.md` (per-stream contracts) | Direct read at session start (or on per-entry-tree-aware operation) | Per-stream contract authority |
```

**Committed PM-CHAT.md lines 124-125:**
```
| `docs/project/backlog/<ID>.md`, `docs/project/implementation-plan/<ID>.md`, `docs/project/changelog/<ID>.md` (per-entry source) | Direct read of single entry when only that entry is needed | Per-entry tree is source of truth in flat-file mode (per project-template trinity Document locations + `<stream>/_rules.md`); smaller token footprint than mirror for one-entry edits |
| `docs/project/backlog/_rules.md`, `docs/project/implementation-plan/_rules.md`, `docs/project/changelog/_rules.md` (per-stream contracts) | Direct read at session start (or on per-entry-tree-aware operation) | Per-stream contract authority |
```

**Result: BYTE-EQUIVALENT. Verbatim-drift: ZERO.**

---

## §5 — Sub-coverage verification (MIGRATION-v10-to-v11.md new section)

PLAN §5.8 specified 5 sub-coverage items:

| # | Required sub-coverage | Implementation location | Status |
|---|---|---|---|
| 1 | What changes (per-entry tree under /backlog/ etc.; monolithic becomes regenerated mirrors) | `### What changes` at lines 257-281 | PRESENT — names new directories, entry-file shape, supporting files (`_rules.md`, `_intro.md`, `_format.md`, `_toc.md`), mirror semantics, CI gates (Check 32 + Check 33). |
| 2 | Why mandatory + non-reversible per Addendum #1 §1 | `### Why mandatory and non-reversible` at lines 283-290 | PRESENT — explicit mandatory + non-reversible statement; no rollback verb; retires v10-era pattern. |
| 3 | What the user does (nothing — migrator handles it) | `### What the user does` at lines 292-300 | PRESENT — "Nothing." + names `_v10_to_v11_decompose_streams` sub-operation + sequencing rationale. |
| 4 | Backup + rollback per integration parent §9.4 + Addendum #2 §4 BD-095 bridge | `### Backup and rollback` at lines 302-315 | PRESENT — references unchanged `.pack-migrate-v10-to-v11-backup/` from Stage S1; cross-references existing `## Rollback` section's rsync recipe; covers committed-then-reverted case via `git revert HEAD`. |
| 5 | `--force-overwrite-mirror` flag semantics for advanced users | `### \`--force-overwrite-mirror\` flag (advanced)` at lines 317-343 | PRESENT for flag — names recommended (re-apply hand edit to per-entry file) + advanced override paths; includes sample invocation `bash scripts/migrate-v10-to-v11.sh --apply --force-overwrite-mirror`. **However:** the last paragraph (lines 337-341) describes a non-existent `init-project.sh --install-pre-commit-hook` flag — see Finding M1. |

**Result: 5 of 5 sub-coverage items present.** Item 5 has a sub-defect inside the paragraph documenting the pre-commit hook (Finding M1).

---

## §6 — Auditor agent delegation chain verification (R-4 assertion)

R-4 asserted: NO audit agent file edits are required because the skill delegation chain is sufficient. Verifying this assertion holds.

### §6.1 — `auditor.md` (parent) delegation language

```
# project-template/.claude/agents/auditor.md:11-13
You spawn seven subagents, each covering a semantically coherent audit cluster.
You consolidate their reports into a single structured output following the
rules in the `audit-methodology` skill — that skill is the authoritative source
for cluster definitions, file scopes, pass/fail thresholds, ownership
precedence, and report format.
```

**Delegation: "audit-methodology skill is the authoritative source for ... file scopes ..."** — explicit. Confirmed.

### §6.2 — `auditor-docs.md` (subagent) scope-rule pointer

```
# project-template/.claude/agents/auditor-docs.md:46-50
## File scope

Per `audit-methodology` rule 29: `**/*.md`, `**/*.txt`, `**/README*`,
inline doc comments (`///`, `"""..."""`, `/** ... */`).

The parent passes the exact file scope in your invocation prompt.
```

**Delegation: explicitly cites "rule 29" — the rule that was extended by BD-169.** The two new sub-bullets become operative without any auditor-docs.md edit because the agent file delegates rule-29 authority to the skill.

### §6.3 — Trinity equivalence (Codex + Gemini)

```
$ grep -n "rule 29\|audit-methodology" project-template/.codex/agents/auditor-docs.toml \
                                       project-template/.gemini/agents/auditor-docs.md
project-template/.codex/agents/auditor-docs.toml:32:File scope (per audit-methodology rule 29):
project-template/.gemini/agents/auditor-docs.md:50:Per `audit-methodology` rule 29: `**/*.md`, `**/*.txt`, `**/README*`,
```

All three CLI mirrors of auditor-docs delegate to `audit-methodology` rule 29.

### §6.4 — Conclusion

**R-4 assertion HOLDS.** The new audit-methodology rule 29 sub-bullets will surface at audit time through the existing delegation chain. NO audit agent file edits are required. The IMPL-REPORT §3 Group D + §6 claim is verified.

---

## §7 — Observations (informational; not findings)

1. **CI workflow has no executable surface for BD-169 prose.** Walked `.github/workflows/validate-pack.yml`; no step grep'es the new wording or otherwise gates on it. Only `validate-pack.py` runs, and that passes clean. No risk that any BD-169 prose breaks a CI gate.

2. **All referenced helper paths exist where v11.0 reality permits.**
   - Pack-side `/backlog/` and `/changelog/` do NOT yet exist (deferred to Batch 23 / BD-102 dog-food); the pack-startup directive correctly uses "when present" qualifier.
   - Project-template-side `docs/project/backlog/_rules.md`, etc. DO exist (installed in earlier batch 19 commits); the pm-startup directive's references resolve.
   - `--force-overwrite-mirror` flag IS implemented in `scripts/migrate-v10-to-v11.sh:806` and `scripts/lib/migrator-core.sh:313`.
   - `validate-pack.py` Check 32 + Check 33 exist (at lines 2807 and 2868 respectively). MERGE-STRATEGY.md and MIGRATION-v10-to-v11.md references to these gates resolve correctly.

3. **STATUS.md disclaimer is the ONLY pack-product surface where the disclaimer wording lives in v11.0.** Per R-3 resolution: no STATUS_TEMPLATE.md is created; STATUS.md remains client-authored; PM-CHAT.md is the single surface that instructs the PM chat to prepend the disclaimer at authoring time. The implementation respects this.

4. **No Active-skills line additions.** Verified by `grep -n "Active skills:" .claude/skills/pack-startup/SKILL.md ...`; the only `Active skills:` references are in pm-startup's existing Step 3/Step 6 (unchanged). Addendum #1 §1.5 cascade respected.

5. **BACKLOG.md BD-169 entry remains `Status: Open` as expected.** Per PLAN §5.10, status flip happens in commit 19h. The IMPL-REPORT §1 reaffirms this. No premature status flip.

6. **The MERGE-STRATEGY.md paragraph correctly addresses the catch-all classifier behavior.** Per integration parent §4.4.3, the catch-all routes per-entry files through `generic` 3-way text; the paragraph explains this and adds the mirror-vs-source distinction. Voice matches the surrounding `### 12. generic` section (declarative; cross-references companion docs).

7. **The "Per-entry decomposition" section heading in MIGRATION-v10-to-v11.md correctly cross-resolves.** MERGE-STRATEGY.md line 264-266 references `MIGRATION-v10-to-v11.md § "Per-entry decomposition"` — the heading exists at line 246. Reciprocal reference at MIGRATION-v10-to-v11.md line 341 to `MERGE-STRATEGY.md § "12. \`generic\` — everything else"` — the heading exists at MERGE-STRATEGY.md:238.

8. **The `_format.md` mention applies to project changelog only.** Architect §3.2 + §10.5 confirm this. The audit-methodology sub-bullet lists it generically — see Finding N2.

---

## §8 — Definition-of-Done verification (PLAN §5.8 gates)

| # | Gate | Status | Evidence |
|---|---|---|---|
| 1 | `bash scripts/validate-pack.py` PASSES (Checks 21 + 28 = per-CLI parity) | PASS | Run output: `PASSED — all checks clean`. |
| 2 | Trinity rule check for pack-startup × 3 — identical substantive content | PASS | md5sum: Claude SKILL.md and Codex SKILL.md byte-identical; Gemini TOML carries identical text in wrapper. §3.1 above. |
| 3 | Trinity rule check for pm-startup × 4 — identical substantive content | PASS | md5sum: canonical + Claude + Codex SKILL.md all byte-identical; Gemini TOML carries identical text in wrapper. §3.2 above. |
| 4 | Audit-methodology SKILL.md canonical — single canonical edit; per-CLI mirrors regenerate at install time | PASS | Single canonical edit at `project-template/skills/audit-methodology/SKILL.md`; no per-CLI edits in this commit. |
| 5 | Manual: MIGRATION-v10-to-v11.md new section accurate against integration parent §9.4 + Addendum #2 §4 BD-095 bridge | PARTIAL PASS | 5 sub-coverage items present (§5 above). Sub-coverage item 5 has Finding M1 defect (pre-commit hook reference). |
| 6 | Manual: PM-CHAT.md row text matches Addendum #2 §5.4 verbatim | PASS | Verbatim-equivalent (§4 above). |
| 7 | Manual: PM-CHAT.md STATUS.md disclaimer paragraph accurate against integration parent §5.3 + R-3 | PASS WITH NIT | Disclaimer literal matches PLAN §5.8 spec (which differs from integration parent §5.3 wording — see Finding N1). R-3 resolution honored (no new STATUS_TEMPLATE.md; disclaimer guidance lives in PM-CHAT.md only). |
| 8 | Manual: audit-methodology SKILL.md scope rules accurate against R-4 | PASS WITH SHOULD | Both sub-bullets correctly identify IN-SCOPE and OUT-OF-SCOPE rules. R-4 delegation chain verified intact (§6 above). Findings S1 (detection criterion divergence) and S2 (missing `_v8-resolved-archive.md`). |

**All 8 verification gates PASS** modulo the findings enumerated above. The MUST-fix finding (M1) is the only true blocker; the SHOULD and NIT findings are smaller hygiene items.

---

**End of review.**
