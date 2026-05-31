# PACK-REVIEW — BD-196 C5 (Reviewer pass 1)

**Target:** C5 working-tree changes — `pack-ops/PACK-AGENTS.md`, `pack-ops/PACK-CHAT.md`
(modified), `pack-ops/.spawn-rule-manifest.txt` (new).
**Design:** `ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` §9.6 + EE-6 (v9).
**Plan:** `PLAN-DOC-CONCISION-GUARDRAILS.md` C5 (L84–90).
**HEAD:** `bf9290b924c9825a7f65a9e1b0ea6f2072259d16` (working-tree only; no commit).
**Method:** verified against the actual files + independent greps + ran the full
`validate-pack.py` suite. The C5 IMPL-REPORT was read but every claim was
re-verified against the files.

---

## Verdict: CLEAN (with one SHOULD on manifest accuracy)

The C5 GOAL is met and independently verified: the verbatim canonical imperative
TEXT is GONE from both pack-ops surfaces (so C6's anti-restate scan will pass), the
new one-line references resolve, Check 40 + Check 45 + the full suite are green, and
the 7b sweep finds zero live durable dangles. One SHOULD finding concerns the
ACCURACY of two manifest `references:` lines (a forward risk to C6's
reference-resolution assertion, not to C5's anti-restate goal). The D1 deviation is
a real-and-correct surface; verdict below.

---

## Findings

### SHOULD-1 — `.spawn-rule-manifest.txt`: the `pack-chat-no-coder-review-bounded-cycle` reference surface does not carry a resolving pointer

**Surface:** `pack-ops/.spawn-rule-manifest.txt` (record 6) vs `pack-ops/PACK-CHAT.md`.

**Evidence.** The manifest record:

```
slug:       pack-chat-no-coder-review-bounded-cycle
corpus:     ### Pack Chat scope — "Pack Chat does NO fixes" + "Pack Chat NO coder review; bounded reviewer/fix cycle"
references: PACK-CHAT.md § "Behavioral rules" ("Stop after every reviewer pass for triage discussion", the per-reviewer-pass stop gate)
```

The named reference surface — the triage-stop block, PACK-CHAT.md L63–70 — carries
only a pointer to the `presents-triage-before-fix-coder` rule:

> see the "Pack Chat presents triage to user before fix-coder spawns" rule in
> trinity `## Pack memory` `### Workflow` …

It does NOT mention "does NO fixes", "NO coder review", or "bounded reviewer/fix
cycle". The only PACK-CHAT mention of that concept is in the *separate* "Real fixes
only" block at L89–90 (`` `feedback-pack-chat-does-no-fixes` (who applies fixes) ``)
— which the manifest cites for `triage-all-fix-all` but NOT for this slug.

**Clause.** Design §9.6 / Plan C5 (L85): the manifest maps `slug → {canonical,
references}` and C6's reference-resolution check (Plan C6 L94: "every named surface
carries its expected pointer") reads this file. A `references:` line naming a surface
that carries no resolving pointer is exactly the SC7 failure shape the plan flags at
C6 (L95).

**Why this is SHOULD not NIT.** C5's *anti-restate* goal is fully met regardless
(this concept was never verbatim-restated — see D1). But the manifest is the INPUT to
C6's reference-resolution assertion. If C6 verifies that each `references:` surface
actually carries a resolving pointer to the slug, this record will trip C6 against an
otherwise-clean tree — the failure lands one commit downstream. Fix is cheap: either
(a) repoint record 6's `references:` at the L89–90 "Real fixes only" block (the
surface that actually carries the `feedback-pack-chat-does-no-fixes` pointer, mirroring
how `triage-all-fix-all` already cites it), or (b) surface to the planner so the C6
check's resolution model + this manifest are reconciled in lock-step. This is a
manifest-accuracy fix, not a re-collapse.

**Note (not a separate finding):** `triage-all-fix-all` (record 5) is accurate — its
second `references:` clause correctly cites the L89–90 "Real fixes only" distinct-from
block, which carries `feedback-fix-all-review-findings`. The asymmetry between
records 5 and 6 (both concepts live in the SAME L89–90 block, but only record 5 cites
it) is the smoking gun for SHOULD-1.

---

## D1 verdict — REAL surface, correctly handled; NOT a C5 coverage gap

**The coder's D1 deviation is accurate and correctly NOT self-resolved.** Verified
against `git show HEAD:pack-ops/PACK-CHAT.md`:

- The original PACK-CHAT carried exactly ONE verbatim spawn-rule restatement block
  (the triage-stop block, L63–71). Independent grep of the original for
  `default fix-all` / `nits become tech debt` / `NO coder review` /
  `bounded reviewer/fix cycle` / `max 2 review` / `does NO fixes` → ZERO hits.
- EE-6's framing "3 PACK-CHAT restatements" is therefore a count mis-description: of
  the 3 PACK-CHAT rule-concepts, ONE (`presents-triage`) was a verbatim restatement
  and TWO (`triage-all-fix-all`, `pack-chat-no-coder-review`) existed ONLY as slug
  references in the "Real fixes only" block — there was no verbatim imperative to
  collapse for those two.

**Verdict: D1 is an EE-6 count-description discrepancy, NOT a C5 coverage gap that
requires a different collapse.** The C5 anti-restate OUTCOME is met (no verbatim
imperative survives — see Check 40 + anti-restate measurement below). The coder
correctly declined to invent extra collapses (that would be a fabricated edit) and
surfaced the EE-6/file mismatch to the planner per "never resolve plan contradictions
yourself." The only residual is the manifest-ACCURACY issue (SHOULD-1) — the manifest
DOES record all three concepts, but record 6's `references:` line points at the wrong
surface. So: D1 framing = NIT (count description); its manifest-coverage consequence
= SHOULD-1.

---

## Verification (all independently run/grepped)

**1. Verbatim imperative TEXT GONE (anti-restate).** Independent grep of the canonical
imperative wording across both files:

```
git-ban:        "No agent — including" / "may run `git add`" / "Only Pack Chat may
                stage or commit" / "Every agent produces a report file"   → 0 hits
role-write:     "Source modifications are restricted by agent role"        → 0 hits
PREFLIGHT:      "After all in-scope edits" / "PREFLIGHT: N/N" /
                "STOP-MEANS-STOP on parent" / "do not append to"           → 0 hits
triage-stop:    "surfaces the findings (severity-" /
                "The stop point is BEFORE Pack" / "No auto-commit on clean" → 0 hits
```

ZERO verbatim duplication survives. C6's anti-restate scan WILL pass. CONFIRMED.

**2. References resolvable + Check-40-safe.**
- The 3 PACK-AGENTS references live in `## Agent permission rules` (L110); each is a
  one-line reference carrying a resolving pointer (`[rationale: agents-never-commit]`,
  named-rule "What Pack Chat CAN edit directly", `[rationale: preflight-stop-means-stop]`).
- The `[rationale:]` slugs resolve: both `agents-never-commit` and
  `preflight-stop-means-stop` exist in all three trinity files AND as `## <slug>`
  sections in `PACK-MEMORY-RATIONALE.md` (L29, L109) — Check 45 PASS (18/18 bijection).
- The named-rule references (`What Pack Chat CAN edit directly`, `Pack Chat presents
  triage to user before fix-coder spawns`) resolve to live corpus bullets in
  CLAUDE.md (L396, L194).
- **Check 40 PASS** (RAN): "10 pack-ops/*.md walked; zero unqualified bare
  cross-references". The IMPL-REPORT's noted intermediate FAIL (bare
  `validate-pack.py` at PACK-AGENTS:185, re-qualified to `scripts/validate-pack.py`)
  is fixed — verified clean in the current tree.

**3. Manifest correct + complete.** 6 records present; all 6 corpus targets resolve to
live CLAUDE.md bullets. All EE-6 spawn-rule restatement CONCEPTS are recorded (3
PACK-AGENTS + 3 PACK-CHAT). Caveat: record 6 `references:` accuracy — see SHOULD-1.

**4. D1.** See verdict above.

**5. Non-rule content intact.** Verified by diff scope: PACK-AGENTS diff touches only
the two collapsed blocks + the PREFLIGHT block; roster table, `Mode` column,
"How to invoke", PM-only Files+Directories list, forward-pointing note, skill-maint
reference all unchanged. PACK-CHAT diff is a single hunk (`@@ -60,15 +60,14 @@`) — only
the triage-stop block changed; Role / startup / "File access strategy" / all other
behavioral rules / "Keeping current" untouched.

**6. 7b sweep complete.** Independent repo-wide grep (excl. `prison/`, `archive/`,
this BD's own artifacts) for `as restated in PACK-AGENTS` / `PACK-CHAT restates` /
`severity-grouped` / `Every agent produces a report file` / `Source modifications are
restricted by agent role`. ALL hits are (a) workflow artifacts under
`maintenance-docs/v11-implementation/` + `v11-research/` (EXEMPT historical records
per the Skill/agent-maintenance pack-memory rule — describe state at their own batch
HEAD; sweep to archive at ship), (b) the design/plan docs describing the sweep itself,
or (c) unrelated `severity-grouped` pack-auditor mentions. Two live durable inbound
references to the collapsed blocks point by SECTION NAME (`PACK-MEMORY-RATIONALE.md:42`
→ "Agent permission rules"; pack-coder agent files → "(agent routing + permission
rules)") — both section headers survive the collapse, both resolve. ZERO live durable
dangles. CONFIRMED.

**7. validate-pack PASS.** RAN `python3 scripts/validate-pack.py` → exit 0,
"PASSED — all checks clean". Check 40 OK, Check 45 OK (18/18 bijection), Check 37/38/43
OK. Check 46 is NOT yet wired — correct for C5 (it lands in C6 per plan).

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| No prior reviews fed in | Referenced DESIGN §9.6/EE-6 + PLAN C5/C6 only; read C5 IMPL-REPORT but re-verified every claim against files; read no `PACK-REVIEW-*.md`. | COMPLIANT |
| Prison rule | No read/cite of `maintenance-docs/prison/`; all 7b greps excluded `prison/`. | COMPLIANT |
| Agents never commit / read-only | Only `git diff`/`git show`/`git status`/`git rev-parse` (read), grep, `python3 validate-pack.py`; single Write = this report. `git status` shows HEAD unchanged at `bf9290b`. | COMPLIANT |
| No destructive op | Read-only on source; one Write to the prompted report path. | COMPLIANT |
| Findings: severity + surface + quoted evidence + clause | SHOULD-1 carries surface (manifest record 6 / PACK-CHAT L63–70 vs L89–90), quoted evidence, and clause (§9.6 / Plan C6 L94 SC7 L95). | COMPLIANT |
| Output ends with Rules-Applied Block | This block. | COMPLIANT |
| Concise | One SHOULD + D1 verdict + 7-point verification; no padding. | COMPLIANT |

**End of PACK-REVIEW-BD-196-C5.md.**
