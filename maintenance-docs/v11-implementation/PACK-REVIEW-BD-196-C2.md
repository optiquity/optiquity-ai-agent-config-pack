# PACK-REVIEW — BD-196 C2 (Reviewer pass 1 of max-3)

**Target:** uncommitted working-tree changes — `## Pack memory` corpus strip in
`CLAUDE.md`/`AGENTS.md`/`GEMINI.md`, new `pack-ops/PACK-MEMORY-RATIONALE.md`,
plus a working-tree edit to `maintenance-docs/v11-implementation/ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md`.
**Design:** `ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` §5.1 (`[rationale:]`-OPTIONAL contract), §5.2 (bijection over PRESENT `[rationale:]` set).
**Plan:** `PLAN-DOC-CONCISION-GUARDRAILS.md` commit C2.
**Method:** independent verification against the actual files; coder reports read for account only, every claim re-verified.

**VERDICT: CLEAN** — one SHOULD-level scope observation (S-1) and one informational note; no BLOCKER/MUST. All ten VERIFY items pass.

---

## Findings

### SHOULD

**S-1 — third file (`ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md`) dirty, not in either IMPL-REPORT inventory.**
Surface: `git status --short` shows ` M maintenance-docs/v11-implementation/ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` (11 lines changed).
Evidence: the diff adds the §5.1 `[rationale:]`-OPTIONAL bullet + worked examples
(`per-entry-trees-vs-mirrors`, `separate-ops-from-product`, `test-infra-self-provisioned`)
and rewords §5.1.ii / §5.2 bijection language from "every imperative slug" to
"every PRESENT imperative slug … rules without `[rationale:]` are outside the
bijection set." Neither `IMPLEMENTATION-REPORT-BD-196-C2.md` §"Files changed"
(4 rows: RATIONALE + 3 trinity) nor `-C2-FIX.md` §"Files changed" (4 rows:
3 trinity + RATIONALE) lists this file.
Clause: prompt VERIFY-1 ("only `## Pack memory` (corpus) + the new `RATIONALE.md`
touched"); plan C2 §Files names only RATIONALE.md + the three trinity files.
Assessment: the edit is the design-record amendment that makes the design MATCH
the user-locked POQ-C2-1 option-a decision the `-C2-FIX` report implements —
without it, §5.1 still mandated `[rationale:]` per rule and C2 would contradict
its own design. The architecture doc is the design SSOT, so the amendment is
correct and necessary; it is a Pack-Chat / architect edit, not coder output,
which is why it is absent from the coder inventories. The substance is sound
(verified below under VERIFY-4). The SHOULD is purely the bookkeeping gap: the
C2 commit will carry a file neither IMPL-REPORT enumerates. Recommend Pack Chat
either (a) note the architecture amendment in the commit body, or (b) confirm it
is intended to ride the C2 commit. No content change required.

### Informational

**I-1 — bijection check (Check 45) not wired; bijection currently proven by manual diff only.**
Per design §5.2 + plan C3, Check 45 wires in C3 (a later commit). At this C2 HEAD
the 18==18 bijection holds but is unenforced by CI. This is the planned
sequencing ("never wire a check against a violating tree"), not a defect. The
RATIONALE.md top-matter correctly forward-references it ("Check 45, wired in
commit C3"). No action.

---

## VERIFY checklist results

1. **Scope — corpus + RATIONALE only.** PASS for the two coder surfaces. `git diff --stat`:
   only `## Pack memory` regions of the trinity changed; bullet counts unchanged
   (CLAUDE 45→45, AGENTS 41→41, GEMINI 41→41); zero `^[+-]- \*\*` bullet add/remove.
   No rule reordered or reworded in substance (imperative lines unchanged; only
   trailing post-tag bodies stripped). RATIONALE.md is new under `pack-ops/`.
   The architecture-doc edit is the S-1 exception.
2. **Verbatim move (no content loss).** PASS. Word-normalized diff of the HEAD
   corpus body vs the RATIONALE section is identical for the spot-checked rules
   (`ci-guard-measure-then-bound`, `rules-applied-verification-block`,
   `empirical-evidence-blocks`, `deferral-is-scope-creep`, `preflight-stop-means-stop`).
   The only intra-body deltas are the intended Check-40 path-qualifications (VERIFY-7).
3. **Bijection 18==18.** PASS. `diff` of the 18 corpus `[rationale: slug]` slugs
   vs the 18 `## <slug>` headings in RATIONALE.md is EMPTY — no orphan either
   direction. `grep -c '^## '` RATIONALE.md = 18; `grep -coE '\[rationale: …\]'`
   CLAUDE.md = 18.
4. **`[rationale:]`-OPTIONAL correctness (§5.1).** PASS. The three rules carrying
   `[roles:]` but NO `[rationale:]` are exactly `per-entry-trees-vs-mirrors`
   (CLAUDE L530), `separate-ops-from-product` (L537), `test-infra-self-provisioned`
   (L556) — the §5.1 named examples. Confirmed at pre-C1 HEAD `3bef42b` that none
   of the three EVER had a separable Why/How/rejected-alternatives body (each was
   a single self-contained imperative), so no hidden rationale was dropped. The
   other 18 each carry exactly one `[rationale:]` + one RATIONALE section.
   `[roles:]` total = 21; `[rationale:]` total = 18; the 3-way difference is
   exactly these rules.
5. **Slugs kebab-case + unique.** PASS. All 18 match `[a-z0-9-]+`; `uniq -d` empty.
6. **Trinity parity (§9.5).** PASS. `[rationale:]` slug-set identical across all
   three (18 each, diff empty C-vs-A, C-vs-G). `[roles:]` set identical (21 each,
   diff empty). The remaining `## Pack memory` section diffs across the trinity
   are all PRE-EXISTING, legitimate trinity divergences (the Claude-only
   "Sub-agent behavior" subsection; per-CLI invocation commands `claude`/`codex --agent`/`@pack-`;
   per-CLI memory-cache notes; long-standing body-text wording differences) — NOT
   introduced by C2; the C2 strip is byte-identical on the tagged lines.
7. **Check-40 path-qualifications resolve.** PASS. Every path-qualified reference
   in RATIONALE.md resolves to a real target: `project-template/docs/pack/PLATFORM-SKILLS.md`,
   `project-template/docs/pack/PM-CHAT.md`, `scripts/tests/test-validate-pack-check-43.sh`,
   `scripts/tests/test-validate-pack-checks-36-37-38.sh`, `scripts/validate-pack.py`,
   `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md`,
   `maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md` (L347 — resolves;
   the file lives under `v11-research/`, and that is the path used), `scripts/init-project.sh`,
   `maintenance-docs/v11-implementation/ARCHITECTURE-BD-182.md`. The two
   non-path-qualified backtick paths (`.claude/settings.json` L430,
   `docs/pack/PM-CHAT.md` L100) are inside historical worked-example prose
   describing a (wrong) BD-178 reference value and a client-relative SSOT-as-it-was
   — correctly left un-qualified, matching the original verbatim body.
8. **RATIONALE.md top-matter.** PASS. Declares pack-only ("lives under `pack-ops/`
   … NOT a trinity file … NOT installed to client projects"), read-on-demand
   ("Agents do NOT load this file into every prompt … only when it hits an
   ambiguous Rules-Applied row"), and never-source-of-truth-for-the-imperative
   ("if this file and the corpus imperative ever disagree, the corpus imperative
   wins").
9. **validate-pack PASS.** PASS. `python3 scripts/validate-pack.py` →
   `PASSED — all checks clean`, exit 0. Includes Check 40 over the new
   `pack-ops/PACK-MEMORY-RATIONALE.md` (10 pack-ops/*.md walked, zero unqualified
   bare cross-references) and Check 38 (RATIONALE.md correctly sited under
   `pack-ops/`). No trinity-parity validator check exists in validate-pack;
   trinity parity is review-enforced and verified manually (VERIFY-6).
10. **No semantic regression.** PASS. The body-strip + 3-rule `[rationale:]`
    removal changed no rule's imperative; the moved bodies are verbatim in
    RATIONALE.md (VERIFY-2); the 24 non-tagged rules are untouched (bullet count
    unchanged, spot-checks intact). What each rule REQUIRES is unchanged.

**Additional checks.**
- Manifest: RATIONALE.md is NOT in `scripts/init-project.sh` client inventory
  (`grep -c PACK-MEMORY-RATIONALE` → 0), so it is not fixture-affecting; manifest
  correctly unstaged/unchanged. (Pack Chat still owns the mandatory
  `build.sh --all --clean` + diff-check at commit per the manifest-regen rule —
  expected-empty.)
- 7b stale-reference sweep: whole-repo grep for cites of "the Why in `## Pack memory`"
  / rationale-in-corpus returned only the PLAN doc's description of the 7b step
  itself — no live dangling inbound reference into a moved body.
- IMPL-REPORT accuracy: both reports' claims (bullet counts, bijection, trinity
  parity, Check-40 in-flight fix, 21→18 reduction) match the working tree exactly.
  The C2 report's "21" reflects its pre-FIX state; the `-C2-FIX` report correctly
  documents the reduction to 18==18 under user-locked POQ-C2-1 option a.

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| Trinity rule (governs the `## Pack memory` edits) | `[rationale:]` slug-set (18) + `[roles:]` set (21) byte-identical C==A==G (diffs empty); C2 strip byte-identical on tagged lines; pre-existing Claude-only/per-CLI divergences are legitimate and not C2-introduced | COMPLIANT |
| No prior reviews fed in | Read DESIGN (`ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md`) + PLAN (`PLAN-DOC-CONCISION-GUARDRAILS.md`) + the two C2 IMPL-REPORTs only; read NO `PACK-REVIEW-*.md` (incl. C1 reviews) | COMPLIANT |
| Findings carry severity + surface + quoted evidence + cited clause | S-1, I-1, and all 10 VERIFY rows cite file:line, quoted text, and design/plan/prompt clause | COMPLIANT |
| Prison rule | `maintenance-docs/prison/` not read, cited, or trusted; excluded from all sweeps | COMPLIANT |
| Agents never commit / no state change | Only read-only ops (`Read`, `git diff/show/status/ls-files`, `grep`, `find`, `python3 validate-pack.py`) + this single report Write; no `git add/commit/push/tag`, no source edits | COMPLIANT |
| Read-only on codebase except the report | Sole Write is this report at the prompted path; no other Edit/Write/Bash file modification | COMPLIANT |
| Output ends with Rules-Applied Verification Block (concise) | This block | COMPLIANT |

**End of PACK-REVIEW-BD-196-C2.md.**
