# ADVERSARIAL REVIEW — BD-243: strip historical/audit + bloat from operating docs; add governance rule

Reviewer: pack-architect (FRESH adversarial, RO). NOT the first architect, NOT the researcher.
Runtime HEAD `a847f120e4ada06456bec4e2bf6d275fdd8c0742`, branch v11-dev, 2026-06-21.
Review target: `/tmp/pack-handoff-bd243-arch/DESIGN-BD-243.md` (305 lines) + the user's 3 rulings (OQ-1=B, OQ-2=c, OQ-3=rewrite).
Default posture: skepticism. Re-measured every load-bearing claim at runtime HEAD.

---

## OPEN QUESTIONS FOR USER

**OQ-A — `deferred — BD-214` / `(BD-214)` references: KEEP (design) or STRIP (provenance to a Resolved decision)?**
The design's B.1 allowlist KEEPs all `BD-214` references as L2 "live anchors" (4 sites: CLAUDE.md:610, AGENTS.md:503, GEMINI.md:479, PACK-CHAT.md:53, + backlog/_rules.md:28). MEASURED: **BD-214 is `Status: Resolved`** (Resolved 2026-06-13 — tracker-deferral cleanup train landed; GH deletion executed). The references are PROVENANCE CITATIONS to a now-resolved decision ("tracker mode is deferred — BD-214"), NOT live forward-pointers to pending work: the operational fact ("tracker is deferred indefinitely; flat-file is the sole mode") is permanent and stands on its own; `(BD-214)` only records WHICH BD decided it. Per BD-243's own goal ("a copy of provenance in an operating doc is redundant; the real history lives in changelog/backlog") and the charge's own test ("a pointer to landed work is now history → strip"), these are STRIP-class. This is the SAME under-classification the user already caught in OQ-2. Contrast: `until BD-206 retires the mirror` (BD-206 **Open**) IS a genuine live transitional pointer (KEEP). **Recommend STRIP the BD-214 provenance tags** (keep the rule, drop the citation). Surfacing because it reverses a design KEEP across 5 sites.

**OQ-B — `audit-methodology/SKILL.md:76` asserts `_v8-resolved-archive.md` EXISTS pack-side; OQ-2=c removes the one doc that says it does NOT. In BD-243 scope?**
OQ-2=c strips the `backlog/_rules.md` clause "There is no `_v8-resolved-archive.md`…". MEASURED: `_v8-resolved-archive.md` does NOT exist anywhere (not tracked); but `project-template/skills/audit-methodology/SKILL.md:76` (a project-side IN doc) independently names it as an existing pack `/backlog/` supporting file ("`_v8-resolved-archive.md` (pack `/backlog/` only per integration parent §2.6)"). After the strip, SKILL.md:76 becomes the surviving, uncontradicted (FALSE) assertion that the file exists. The design never enumerates this surface. **Recommend the reconciliation also strip/correct the SKILL.md:76 reference** (it is itself a stale reference to a non-existent file). Surfacing because it is out of the design's stated recipes and may need its own user ruling on scope (project-side IN doc edit).

---

## VERDICT: NEEDS-REWORK

The OQ-1=B consolidation is **lossless on the pattern axis** (the 5 history patterns Check 44 owns are a clean subset of what Check 65 must own under B; the 7 Check-44 docs are already date/SHA-clean so no regression there) and **the allowlist has 0 history entries to migrate** (all 6 entries are `will`) — these two A-charge sub-items are CONFIRMED. BUT the design as written is **scoped to provisional Option A** in Sections E, F, and the recipe annotations, and under B it has THREE concrete gaps that a reconciliation architect must close:

1. **BLOCKER — the Check 44 per-check test + 4 other surfaces break under B and are not in the design's lockstep plan** (charge A.iii / G).
2. **MAJOR — the date-axis false-positive surface (legitimate date EXAMPLES in project-side `_format.md`/`_rules.md`/`PACK-FEEDBACK.md`) is unaddressed by the B.1 allowlist** (charge A.iv).
3. **MAJOR — the measure-then-bound categorization is incomplete: BD-214 (Resolved, OQ-A), BD-218, BD-241 are unclassified/mis-classified** (charge D), repeating the OQ-2 under-classification error the user already flagged.

OQ-2=c and OQ-3 are otherwise sound (modulo OQ-B). Findings below are written so a SEPARATE fresh reconciliation architect can act.

---

## FINDINGS BY SEVERITY

### BLOCKER-1 — Check 44 per-check test (+ 4 doc surfaces) break under OQ-1=B; not in Section F lockstep
**Challenged claim:** Design F-row for Check 44: "History strip on the 7 … keeps Check 44 green" + Section E "designed provisionally to (A)." Under B, Check 44 LOSES its date/sha/Commit-N/Override-N/post-Commit patterns (keeps only `will`). That is a contract change to a shipped check, and 5 surfaces ENCODE the moved patterns against Check 44:

Independent measurement (HEAD a847f12):
- `scripts/tests/test-validate-pack-check-44.sh` — **breaks**:
  - L57 imports `_CHECK_44_FORBIDDEN_PATTERNS` (will still exist but reduced).
  - L155-167 **T2** injects a date (`This rule was locked on 2026-05-30`) and asserts Check 44 FAILS — under B Check 44 no longer fails on a date → **assertion breaks**.
  - L194-205 **SHA case** injects `commit deadbeef1234` and asserts Check 44 FAILS — under B Check 44 no longer owns `sha` → **assertion breaks**.
- `scripts/validate-pack.py` — `_CHECK_44_FORBIDDEN_PATTERNS` tuple (L7780-7787, remove 5 of 6); Check 44 comment block (L7754, L7776); docstring (L7833-34); fail-message (L7892-93) — all name the moved patterns.
- `pack-ops/.concision-allowlist.txt` — header L9-13 + L26-32 document dates/SHAs/Commit-N/Override-N/post-Commit as Check-44 forbidden.
- `maintenance-docs/v11-implementation/ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` — §6 M4 (L173 "SHAs/dates … forbidden in durable docs", L195 "NO dates, NO Commit N/Override N/post-Commit … the M4 forbidden set") binds those patterns to M4/Check 44.

**Required fix (reconciliation):** Section F's Check-44 row must become a FULL reduction plan that adds to W0: (a) reduce `_CHECK_44_FORBIDDEN_PATTERNS` to `(("will", …),)`; (b) rewrite `scripts/tests/test-validate-pack-check-44.sh` to keep only the `will`/advisory assertions and MOVE the date + SHA FAIL-case assertions into the new `test-validate-pack-check-65.sh`; (c) rewrite the `.concision-allowlist.txt` header to drop the moved-pattern documentation (the file now allowlists only `will`); (d) rewrite the Check-44 comment/docstring/fail-message; (e) the CONCISION-GUARDRAILS addendum (charge architect-doc-reality-reconciliation) must state the date/sha/Commit-N/Override-N/post-Commit axis MOVED from §6/Check 44 to Check 65 — NOT merely "Check 65 extends §6." This is 5 lockstep surfaces, not the design's "keeps Check 44 green."

### BLOCKER-2 — Section E pattern set is still written to Option A; under B it must own dates on the 7 too
**Challenged claim:** Design E.3 P4/P5/P8 row: "OQ-1 option A: on docs NOT in Check 44's 7, Check 65 owns dates; on the 7, Check 44 already owns dates — Check 65's date pattern is suppressed for those 7 to avoid double-fail." This is the A topology and is WRONG under B.

Independent measurement: under B, Check 65 owns the COMPLETE history axis across ALL ~145 IN docs INCLUDING the 7. I measured the 7 Check-44 docs for date/sha/Commit-N/Override-N/post-Commit: **all 7 return 0 hits on every pattern** (Check 44 keeps them clean). So Check 65 taking those patterns on the 7 produces ZERO new failures — the consolidation is lossless there, and there is NO double-fail to "suppress." The E.3 suppression clause is dead under B and must be deleted; Check 65's pattern set is uniform across all ~145 docs (no per-doc pattern suppression).

**Required fix:** delete the E.3 "suppress for the 7" logic; Check 65 scans the same pattern set on all IN docs. Confirm (measured here) the 7 stay green.

### MAJOR-1 — date-axis false positives: legitimate date EXAMPLES not in the B.1 allowlist (charge A.iv)
**Challenged claim:** Design B.1 + E.4: "the only surviving BD/TD/date tokens in IN docs are the B.1 allowlist set ⇒ Check 65 scans clean." The B.1 allowlist contains BD/TD tokens and ARCHITECTURE refs but ZERO date examples — because under provisional A, Check 65 did not own dates broadly. Under B (Check 65 owns dates on all ~145 IN docs), legitimate date EXAMPLES become Check-65 hits with no allowlist coverage.

Independent measurement (date pattern `20[0-9]{2}-[0-9]{2}-[0-9]{2}` across the full IN set):
- `project-template/docs/project/changelog/_format.md` — **4** hits, all format-spec examples (e.g. L62 `### 2026-04-20 — Phase 35 …` → `2026-04-20-phase-35.md`). KEEP (changelog filename/heading format spec).
- `project-template/docs/project/changelog/_rules.md` — **1** hit (L15 `2026-04-20-phase-35.md or bare 2026-04-20.md`). KEEP (filename grammar).
- `project-template/docs/pack/PACK-FEEDBACK.md` — **1** hit (L156 `Status: Ready (2026-06-15)`). KEEP (status-line format example).
- Pack-side dates: CLAUDE/AGENTS/GEMINI 2 each = the OQ-3 carve-outs (STRIP via rewrite); PACK-CHAT.md:151 (STRIP — `verbatim 2026-05-16: "…"`); RATIONALE 12 (STRIP — incident dates). All STRIP — correctly handled.

**Required fix:** the B.1 allowlist under B MUST add the 6 legitimate date-example sites (`_format.md` ×4, `_rules.md` ×1, `PACK-FEEDBACK.md` ×1) as content-anchored KEEP snippets — sized EXACTLY to these legitimate examples, NOT widened. Without this, Check 65 fails on day one against the clean post-strip tree (violates measure-then-bound: "verify the gate runs clean on the projected post-strip state"). NOTE the SHA pattern is NOT a concern: measured 0 SHA-pattern hits project-side and only RATIONALE (12, all STRIP) pack-side — no SHA false-positive surface.

### MAJOR-2 — measure-then-bound categorization incomplete: BD-218 + BD-241 unclassified; BD-214 mis-classified (charge D / A.iv)
**Challenged claim:** Design B.1/B.2 claim the L1-L3 KEEP set is "exhaustive" and sized to LIVE pointers. The first architect under-classified OQ-2; it repeats the pattern.

Independent measurement — every distinct BD token in CLAUDE.md (pack root trinity) + Status:
`BD-119` (Resolved, L3 doc-ref KEEP-ok), `BD-182` (Resolved, L3 doc-ref KEEP-ok), `BD-203` (Resolved, P2 STRIP — recipe covers), `BD-206` (**Open**, L1 `until BD-206` KEEP-correct), `BD-214` (**Resolved** — see OQ-A; design KEEPs as L2 but it is provenance), `BD-217` (Deferred, `= BD-217`/`coordinate BD-217` KEEP-defensible), `BD-218` (**Deferred** — `worktree.bgIsolation governs background SESSIONS only — BD-218`; **NOT in any allowlist row OR strip recipe**), `BD-225` (Resolved, section anchor — strip recipe covers), `BD-226` (Resolved, section anchor — strip recipe covers), `BD-241` (**Resolved** — `the BD-241 discoverability mechanism then re-finds it`; **NOT in any allowlist row OR strip recipe**).

So **BD-218 and BD-241 are entirely unclassified** by the design (neither KEEP nor STRIP), and **BD-214 is mis-classified KEEP** (OQ-A). BD-218 reads as a cross-ref/provenance tag (the rule stands without "— BD-218"); BD-241 is a P3-style provenance ("the BD-241 mechanism"). This is a measure-then-bound gap on the pack root trinity alone — and the design only spot-checked specific tokens rather than enumerating EVERY BD token per IN doc and categorizing each.

**Required fix:** the reconciliation must run the FULL per-IN-doc BD/TD-token census (every distinct token, with Status), categorize each KEEP/STRIP by the live-anchor-vs-provenance test, and size the allowlist to the LIVE set exactly. BD-218/BD-241 need explicit KEEP-or-STRIP rulings; BD-214 per OQ-A. The pattern (enumerate every occurrence, don't spot-check) must extend to MERGE-STRATEGY (23 tokens), OPTIONAL (13), CONCEPTUAL (12), backlog/_rules (12), RATIONALE (58) — the design's per-doc recipes say "sweep all N" but provide a categorized list for none.

### MINOR-1 — design does not state the new rule's Check-65 self-exemption (charge F)
The new rule's text (D.1) and the RATIONALE `## slug` section (D.3) are themselves in IN docs scanned by Check 65. MEASURED: the D.1 text uses literal placeholders (`BD-NNN`, `User-locked YYYY-MM-DD`, `until BD-NNN`) with NO real digits — so it is self-safe (the date regex needs `20\d{2}-\d{2}-\d{2}`; `BD-\d+` needs digits). GOOD, but the design never states this constraint. The RATIONALE section is the risk: if it cites a REAL BD number or date as a worked example, it trips Check 65 (RATIONALE is an IN doc). **Required fix:** add an explicit authoring constraint — the new rule + its rationale section use literal placeholders only (`BD-NNN`/`YYYY-MM-DD`), never real digits, so they self-satisfy Check 65; the coder PREFLIGHT verifies.

### MINOR-2 — Check 65 EXPECTED_COUNT delta interacts with Check 44 reduction (no net change, but state it)
Under B, Check 44 is REDUCED but NOT removed (it keeps `will`+advisory), so it stays ONE registry entry. Check 65 ADDS one entry. Net: `CHECK_REGISTRY_EXPECTED_COUNT` 62 → 63 (+1). MEASURED: registry count = 62 (Check 59 green), highest number = 64, next-free = 65. The design's EE-1 (62→63, next-free 65) is CONFIRMED and unchanged by B. State explicitly in the reconciliation that the Check-44 reduction does NOT change the entry count (only the pattern tuple), so the +1 is solely Check 65.

---

## THE OQ-1=B CONSOLIDATION VERIFICATION (the 4 sub-items)

### A.i — PATTERN SUPERSET (lossless proof): CONFIRMED
Measured `_CHECK_44_FORBIDDEN_PATTERNS` (validate-pack.py L7780-7787):
```
("date", 20[0-9]{2}-[0-9]{2}-[0-9]{2}), ("sha", \b[0-9a-f]{7,40}\b),
("commit-N", Commit [0-9]), ("override-N", Override [0-9]),
("post-Commit", post-Commit), ("will", \bwill )
```
Under B: 5 history patterns (date, sha, commit-N, override-N, post-Commit) MOVE to Check 65; `will` STAYS on Check 44. Check 65's required history-axis set (rulings: dates + SHA + Commit-N + Override-N + post-Commit + BD/TD-provenance + User-locked + incident + carried-from + pre-DATE) is a strict SUPERSET of the 5 moved patterns — **NONE is dropped**. The one way B could regress vs A (a dropped pattern) does NOT occur. **SUPPORTED — lossless on the pattern axis.** CAVEAT: losslessness requires BLOCKER-2's fix (Check 65 must actually own dates on the 7, no suppression) and BLOCKER-1's fix (the encoding surfaces moved in lockstep).

### A.ii — ALLOWLIST MIGRATION: CONFIRMED (0 history entries to migrate)
Measured `pack-ops/.concision-allowlist.txt`: **6 records, ALL `pattern: will`** (DRY-RUN ×2, MERGE ×2, OPTIONAL ×2). ZERO date/sha/Commit-N/Override-N/post-Commit (history-class) entries. So under B: all 6 `will` entries STAY with Check 44; ZERO entries migrate to the new Check-65 history allowlist. Design claim "0 history entries to migrate" is **SUPPORTED**. (Check 44's run reports "4 allowlisted occurrences admitted" because only 4 of the 6 snippets match a live line at HEAD — a content-drift artifact, not a count discrepancy; the FILE has 6 records.) The new Check-65 history allowlist starts from the B.1 set + MAJOR-1's date examples + MAJOR-2's resolved BD/TD census.

### A.iii — CHECK 44 REDUCTION SAFETY: REFUTED (breaks 5 surfaces) → see BLOCKER-1
Reducing Check 44 to `will`/length is NOT safe as the design implies. It breaks `scripts/tests/test-validate-pack-check-44.sh` (T2 date + SHA injection FAIL-assertions), and requires lockstep edits to the Check-44 comment/docstring/fail-message, the `.concision-allowlist.txt` header, and the CONCISION-GUARDRAILS §6 addendum. Check 59 (registry count) is SAFE (entry count unchanged by a pattern-tuple reduction; +1 only from Check 65). The CONCISION-GUARDRAILS doc DOES need an addendum (REFUTES the design's option-A "extends, no edit" framing — under B the date/sha axis MOVED, not extended).

### A.iv — FALSE-POSITIVE SURFACE: REFUTED (date examples uncovered) → see MAJOR-1
Broad date scanning across 145 docs hits 6 legitimate date-example sites (`_format.md` ×4, `_rules.md` ×1, `PACK-FEEDBACK.md` ×1) NOT in the design's B.1 allowlist. The allowlist is NOT yet sized to cover legitimate examples under B. SHA false-positives: none (measured 0 project-side, 12 RATIONALE all STRIP). The allowlist must ADD the 6 date examples (measure-then-bound), without widening to admit provenance.

---

## EMPIRICAL-EVIDENCE BLOCK

Runtime: HEAD `a847f120e4ada06456bec4e2bf6d275fdd8c0742`, branch v11-dev, 2026-06-21, repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`. Graph queried for discovery (`graphify query … --graph …/graphify-out/graph.json --backend claude-cli --budget 1500`); graph EXISTS but is STALE for Check-44 dependents (no BD-243; surfaced BD-240/BD-241 corroborating findings) → grep/Read/git for every exact-state claim (G2 fallback).

**EE-1 — Check 44 pattern set + reduction targets under B.**
Cmd: `sed -n '7780,7805p' scripts/validate-pack.py`.
Output (verbatim): `_CHECK_44_FORBIDDEN_PATTERNS = (("date", 20[0-9]{2}-[0-9]{2}-[0-9]{2}), ("sha", \b[0-9a-f]{7,40}\b), ("commit-N", Commit [0-9]), ("override-N", Override [0-9]), ("post-Commit", post-Commit), ("will", \bwill ))`; `_CHECK_44_DURABLE_DOCS` = 7 (BOUNDARY 156, CONCEPTUAL 343, DRY-RUN 229, HELP-PACK 49, HELP-TRACKER 57, MERGE 557, OPTIONAL 271). RATIONALE NOT in the 7 (grep count 0).
Interpretation: 5 of 6 patterns are history-class (move to 65 under B); `will` stays. RATIONALE is a Check-65-only doc.
Conclusion: **SUPPORTED.**

**EE-2 — Allowlist has 0 history entries.**
Cmd: `cat pack-ops/.concision-allowlist.txt`; `python3 scripts/validate-pack.py --only-check 44`.
Output (verbatim): 6 records all `pattern: will`; run "0 forbidden pattern(s) outside the allowlist … 4 allowlisted operational occurrence(s)"; OPTIONAL advisory 576 > 271.
Interpretation: 0 history-class allowlist entries → 0 to migrate; all 6 `will` stay with reduced Check 44.
Conclusion: **SUPPORTED** (A.ii confirmed).

**EE-3 — The 7 Check-44 docs are date/sha/Commit-N/Override-N/post-Commit clean (B-consolidation lossless on the 7).**
Cmd: per-doc `grep -cE` of each history pattern over the 7.
Output (verbatim): all 7 docs return date=0 sha=0 commitN=0 overrideN=0 postCommit=0.
Interpretation: Check 65 owning these patterns on the 7 under B yields ZERO new failures → the E.3 "suppress for the 7" logic is dead.
Conclusion: **SUPPORTED** (BLOCKER-2 basis).

**EE-4 — date-pattern false-positive surface across the full IN set.**
Cmd: per-file `grep -cE '20[0-9]{2}-[0-9]{2}-[0-9]{2}'` over pack + project IN families.
Output (verbatim): CLAUDE/AGENTS/GEMINI 2 each (OQ-3 carve-outs); PACK-CHAT 1 (L151 verbatim quote); RATIONALE 12 (incidents); project `_format.md` 4, `_rules.md` 1 (changelog), PACK-FEEDBACK 1.
Interpretation: 6 project-side date hits are legitimate format EXAMPLES (KEEP) NOT in B.1 → false-positive surface uncovered under B.
Conclusion: **SUPPORTED** (MAJOR-1 basis).

**EE-5 — SHA-pattern surface (no false positives).**
Cmd: `grep -rlE '\b[0-9a-f]{7,40}\b'` over pack IN + project IN.
Output (verbatim): pack — only RATIONALE (12); project — 0 files.
Interpretation: SHA broad scan has NO legitimate-example false positives; the 12 RATIONALE hits are STRIP incidents.
Conclusion: **SUPPORTED** (A.iv SHA half clean).

**EE-6 — Check 44 per-check test breaks under B.**
Cmd: `grep -nE` over `scripts/tests/test-validate-pack-check-44.sh`.
Output (verbatim): L57 asserts `_CHECK_44_FORBIDDEN_PATTERNS`/`_CHECK_44_DURABLE_DOCS`; L155-167 T2 injects `2026-05-30` date, asserts FAIL; L194-205 injects `deadbeef1234` SHA, asserts FAIL.
Interpretation: T2 + SHA assertions break when Check 44 loses date/sha under B.
Conclusion: **SUPPORTED** (BLOCKER-1).

**EE-7 — surfaces documenting Check 44 date/sha patterns (lockstep set).**
Cmd: `grep -n` over `.concision-allowlist.txt`, `validate-pack.py`, CONCISION-GUARDRAILS.md.
Output (verbatim): allowlist header L9-13 + L26-32 lists dates/SHAs/Commit-N/Override-N/post-Commit; validate-pack L7754/7776/7833/7892 name them; CONCISION-GUARDRAILS §6 L173/L195 binds them to M4/Check 44.
Interpretation: ≥5 surfaces encode the moved patterns; design Section F omits all under option A.
Conclusion: **SUPPORTED** (BLOCKER-1 + addendum).

**EE-8 — registry count, next-free number, EXPECTED_COUNT delta.**
Cmd: `grep CHECK_REGISTRY_EXPECTED_COUNT`; sorted registry numbers; `--only-check 59`.
Output (verbatim): `CHECK_REGISTRY_EXPECTED_COUNT = 62`; highest number = 64 (`check_dangling_example_deliverable_refs`); 16/18/19 register twice; 2 carry `None`; Check 59 "62 entries == constant." Slug `## operating-docs` absent (unique).
Interpretation: next-free = 65; +1 → 63; Check-44 reduction does not change entry count.
Conclusion: **SUPPORTED** (design EE-1 confirmed; MINOR-2).

**EE-9 — Check 45 bijection state + new-rule self-safety.**
Cmd: `--only-check 45`; `grep -oE '\[rationale: …\]' CLAUDE.md | sort -u | wc -l`; `grep -cE '^## [a-z0-9-]+$' RATIONALE`; test new-rule placeholders against patterns.
Output (verbatim): "26 corpus pointers; 26 rationale sections; sets equal"; CLAUDE.md tags=26, RATIONALE headings=26; D.1 text contains NO real BD digits / dates (literal `BD-NNN`/`YYYY-MM-DD` do not match `BD-\d+`/`20\d{2}-…`).
Interpretation: new rule moves bijection to 27↔27; self-safe vs Check 65 (placeholders only).
Conclusion: **SUPPORTED** (charge F; MINOR-1).

**EE-10 — OQ-2=c clause-strip safety + the audit-methodology dangle.**
Cmd: `ls backlog/BD-0[01][0-9].md | wc -l`; `git ls-files | grep v8-resolved`; `grep -rn _v8-resolved-archive` (filtered); `grep validate-pack.py:326`.
Output (verbatim): 19 BD-001..019 files exist; NO tracked `_v8-resolved-archive.md`; entry regex `^BD-\d+\.md$` at validate-pack.py:326 (machine SKIP, independent of prose clause); `project-template/skills/audit-methodology/SKILL.md:76` asserts `_v8-resolved-archive.md` exists.
Interpretation: clause-strip is functionally safe (regex handles BD-001..019); but SKILL.md:76 becomes an uncontradicted FALSE existence claim.
Conclusion: **SUPPORTED** (charge B confirmed; OQ-B surfaced).

**EE-11 — OQ-3 carve-outs are dead + trinity ×3; rewrites meaning-preserving.**
Cmd: `grep -n` carve-out tokens over CLAUDE/AGENTS/GEMINI; read CLAUDE.md L205-229.
Output (verbatim): carve-out 1 at CLAUDE 213-214 / AGENTS 215-216 / GEMINI 182-183; carve-out 2 at CLAUDE 220-221 / AGENTS 222-223 / GEMINI 189-190; operative rules "Never delay per-BD reviews to end-of-batch retroactive recovery" + "User approves the resulting fix commit, not per-finding approval" survive the rewrite.
Interpretation: dated exceptions/justifications are vestigial; rewrites keep the operative directive; trinity-parity ×3 holds.
Conclusion: **SUPPORTED** (charge C confirmed).

**EE-12 — project-side history ≈ 0.**
Cmd: `grep -rnE 'BD-\d+ (deleted|added|…)|per BD-\d+|User-locked|pre-20…|carried from|carry-over'` over all project IN families.
Output (verbatim): 0 hits.
Interpretation: project-side BD-243 is the bloat axis exclusively; history strip ≈ empty.
Conclusion: **SUPPORTED** (charge H; design EE-8 confirmed).

**EE-13 — L1-L3 allowlist BD statuses (live-vs-resolved).**
Cmd: per-BD `grep -m1 '^Status:' backlog/BD-NNN.md`.
Output (verbatim): BD-206 Open; BD-214 Resolved; BD-217 Deferred; BD-215 Deferred; BD-218 Deferred; BD-119/182/208/225/226/241 Resolved.
Interpretation: `until BD-206` live (KEEP); `BD-214` refs are provenance to a Resolved decision (OQ-A STRIP-candidate); BD-218/BD-241 unclassified.
Conclusion: **SUPPORTED** (MAJOR-2 + OQ-A).

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **reconciliation-instance-independence** | Fresh adversarial instance; did NOT author DESIGN-BD-243.md, am NOT the researcher; challenged independently (refuted A.iii/A.iv; surfaced BD-218/241/214 + audit-methodology dangle the design missed); findings written for a SEPARATE reconciliation instance to act on. | COMPLIANT |
| **agents-never-commit** | Only git verbs run: `git rev-parse HEAD/--abbrev-ref`, `git ls-files`, `git status` (all read-only). Sole write = this review doc via `cat >` to `/tmp/pack-handoff-bd243-arch/ADVERSARIAL-REVIEW-BD-243.md`. No repo edit; no patch; no OptiquityTrader write. | COMPLIANT |
| **empirical-evidence-blocks** | EE-1…EE-13: each command + verbatim output + HEAD `a847f12` + 2026-06-21 + interpretation + SUPPORTED. Re-measured Check 44's pattern set (EE-1), allowlist (EE-2), next-free number/EXPECTED_COUNT (EE-8), the L1-L3 set + statuses (EE-13). | COMPLIANT |
| **ci-guard-measure-then-bound** | Measured the tree FIRST for Check 65's projected scope: the 7 docs clean (EE-3), date false-positives (EE-4), SHA surface (EE-5), full BD census on trinity (EE-13). Categorized KEEP (date examples, live BD-206) vs STRIP (provenance BD-214/218/241, incidents). REFUTED the design's "scans clean" claim — allowlist NOT yet sized to legitimate date examples; verified the superset is lossless on the pattern axis (A.i). | COMPLIANT |
| **rules-applied-verification-block** | This table. | COMPLIANT |
| **enumerate-encoding-surfaces** | Charge G re-checked: design Section F omits, under B, the Check-44 per-check test (EE-6), the validate-pack comment/docstring/fail-message, the `.concision-allowlist.txt` header, and the CONCISION-GUARDRAILS §6 addendum (EE-7) — asymmetric coverage = BLOCKER-1. Verified Check 45/59 interplay (EE-8/EE-9) + trinity parity ×3 on OQ-3 (EE-11). | COMPLIANT |
| **graph-first-context** | Graph EXISTS (`graphify-out/graph.json`); discovery query run FIRST (injected absolute path, `--backend claude-cli`, `--budget 1500`); STALE for Check-44 dependents (surfaced BD-240/241 corroboration) → G2 fallback to grep/Read for every exact-state claim. QUERY only, never built. | COMPLIANT |
| **architect-doc-reality-reconciliation** | Reconciled with CONCISION-GUARDRAILS.md BY FILE (read L1-412): under B the date/sha/Commit-N/Override-N/post-Commit axis MOVES from §6/Check 44 to Check 65 — REFUTES the design's option-A "extends, no edit to §6" framing; the addendum must state the MOVE (BLOCKER-1.e), not merely an extension. | COMPLIANT |

**END — ADVERSARIAL-REVIEW-BD-243.md**
