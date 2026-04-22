# V10-DESIGN-2.md — Re-Review Report (v2)

**Reviewer:** pack-reviewer (Claude Code)
**Review date:** 2026-04-22
**Subject:** `maintenance-docs/v10-working/V10-DESIGN-2.md` (addendum, 700 lines — up from 618)
**Prior review:** `maintenance-docs/v10-working/V10-DESIGN-2-review.md` (2 Blockers, 3 Majors, 12 Minors)
**Base design:** `maintenance-docs/V10-DESIGN.md` (APPROVED, 3,425 lines)
**Verdict:** **APPROVED.** All 17 prior findings are resolved. No regressions detected. Two micro-observations noted for awareness only; neither is a blocker.

---

## 1. Executive summary

The architect's revision grew the addendum by 82 lines and applied every requested fix exactly as the review requested, in some cases adding more explanatory material than strictly necessary (welcome). Every cross-reference to V10-DESIGN.md is now correct. AD-12 is the scope annotation target (AD-11 is untouched). Four new verification tests (V-ADDCAP-13..16) cover the edge cases that were gaps in the prior draft. All six design invariants in §6.4 still hold. The blast-radius table is complete; the commit-ID caveat is explicit. The addendum is approvable as-is.

---

## 2. Prior findings — resolution verification

### Blockers

#### B-1 — AD-11 cited as BD-046 scope (two occurrences) — **RESOLVED**

- **§AD-A5 (lines 207–217).** Rewritten. New text: *"BD-046's v10 scope is established across V10-DESIGN.md AD-12 (combined scope for v10.0) and Parts 4, 5, 6 ... the scope extension is carried by the BACKLOG.md edit in §5.3 below and by AD-12's combined-scope framing."* **AD-11 is no longer referenced.** ✓
- **§4.1 row 1 (line 406).** Rewritten. New text: *"Part 2 AD-12 (v10.0 combined scope) | Text note: AD-12's combined-scope list covers capability-addition as a fourth BD-046 sub-area ... | Confirms scope without changing acceptance; **preferred over annotating AD-11 (which is about BD-045)**."* ✓
- **Verified:** V10-DESIGN.md line 445 "AD-11 — BD-045 is v10 scope" and line 465 "AD-12 — v10.0 is the target version" with combined-scope list — cross-references match.

#### B-2 — V-ADDCAP-10 byte-compare incompatible with Procedure 6 interpretive step — **RESOLVED**

- **§6.2 V-ADDCAP-10 (line 598).** Rewritten. New text: *"the targeted placeholder sections ... now contain non-trivial content; no placeholder-literal text (`[LANGUAGE_RULES — fill in from loaded skills]` or equivalent) remains in those sections; at least one full sentence is present per filled placeholder. **(Byte-comparison against `.claude/skills/<name>/SKILL.md` is not the assertion — the PM chat step is interpretive per §3.3 step 6.2.)**"* Test is now checkable; the disclaimer eliminates confusion. ✓

### Majors

#### M-1 — §5.8 cited for migration-script placement rationale — **RESOLVED**

- **§AD-A1 "Why split" (lines 115–119).** Replaced `§5.8` with `§7.1`: *"V10-DESIGN §7.1 uses the same reasoning for placing migration and init as separate pack-repo scripts with a shared detection library."* Verified against V10-DESIGN.md §7.1 (line 1934, OQ-5 two-scripts decision). ✓

#### M-2 — V-ADDCAP matrix-coverage paragraph internally inconsistent — **RESOLVED**

- **§6.2 (line 591).** New test added: *"**V-ADDCAP-03b** | `--add role:python-server` on an Apple-client monorepo ... Dimension 3 coverage — asserts the script resolves the role to its skill + file delta (per PLATFORM-SKILLS.md Dimension 3)."* ✓
- **§6.2 matrix paragraph (lines 606–612).** Rewritten: *"V-ADDCAP-01, 02, 03, 03b cover all four PLATFORM-SKILLS.md dimensions: language (2), platform (1), protocol (4), role (3). ... The earlier draft's 'Dimension 3 is covered by V-ADDCAP-03' claim has been removed — `protocol:grpc` is Dimension 4, not Dimension 3, and the role case needed its own test."* Dimension mapping now correct: 01→2, 02→1, 03→4, 03b→3. ✓

#### M-3 — Claude Desktop parity under-specified for the script-run step — **RESOLVED**

- **§3.1 (lines 240–244).** Added: *"On Claude Desktop, the shell step runs via filesystem MCP or in a separate terminal; the developer then pastes the end-of-run prompt (§3.4) into the Desktop session. This mirrors V10-DESIGN §6.9's treatment for `migrate-v9-to-v10.sh` and preserves the four-surface parity constraint (Part 1 constraint 4)."* Mirror of §6.9 treatment verified against V10-DESIGN.md lines 1839–1903. ✓

### Minors

#### m-1 — §6.6 "CLAUDE.md authoritative" overclaim — **RESOLVED**

- **§3.2 A2 (line 263).** Rewritten: *"Read existing Active skills line from `CLAUDE.md` **(trinity-equivalent to `AGENTS.md` / `GEMINI.md` per V10-DESIGN §6.6)**."* Exactly the recommended wording. ✓

#### m-2 — §3.10 cited as TRIO source; TRIO is Appendix B — **RESOLVED**

- **§3.3 closing (line 323).** Rewritten: *"The trinity edits are always TRIO (**V10-DESIGN Appendix B "Trinity rule", Part 8 §8.5 trinity-rule integrity audit**)."* Verified against V10-DESIGN.md line 3404 (Appendix B TRIO) and line 2702 (§8.5). ✓

#### m-3 — A1 "delta non-empty" excludes legitimate skill-only adds — **RESOLVED**

- **§3.2 A1 post-assertion (line 262).** Rewritten: *"combined (skill-delta ∪ conditional-file-delta) is non-empty — see degenerate-case note below."* ✓
- **§3.2 degenerate-case note (lines 282–288).** Added: *"**A1 degenerate-case exit.** If the combined ... is empty ... A1 exits 0 with the message 'nothing to add — this dimension/value is already covered by existing active skills and files.' This is a success outcome, not an error."* Covers `role:shared-native-library` and similar. ✓

#### m-4 — Dimension-already-active case not specified or tested — **RESOLVED**

- **§3.2 A2 already-active exit (lines 290–295).** Added: *"**A2 already-active exit.** If every `--add` argument resolves to a dimension/value whose skills are already in the Active skills line AND whose conditional files are already present on disk, A2 exits 0 with 'all requested capabilities already active; no changes needed.'"* ✓
- **V-ADDCAP-13 (line 601).** Added test covering this case. ✓

#### m-5 — Multi-word dimension values beyond platform unaddressed — **RESOLVED**

- **AD-A4 (lines 187–203).** Elevated from Open Question to an in-AD decision: *"**Token grammar (decision; was Open Q 4 in an earlier draft).** Valid `value` tokens are atomic, lowercase-hyphenated normalizations of the row labels ... **This rule applies uniformly to all four dimensions — not just `platform:` — because Dimensions 1 and 3 both use multi-word row labels** (e.g., 'iOS + macOS (universal)', 'Python server', 'Shared native library')."* Explicit enumeration of all four dimensions' valid tokens. ✓

#### m-6 — `.gitignore` per-dimension delta source unspecified — **RESOLVED**

- **§3.2 A6 (line 267).** Rewritten to Option (b): *".gitignore merge: re-run the full pack .gitignore merge using the init-project.sh S8 logic (append-missing under the pack header comment; dedupe). **Idempotent — entries already present are skipped.**"* Uses existing single-source-of-truth; no new per-dimension `.gitignore` table needed. ✓

#### m-7 — Procedure 6.1 "known stdout location" implies unwritten file — **RESOLVED**

- **§3.2 A7 (line 268).** Rewritten: *"Write end-of-run PM chat prompt to stdout **AND to `.pack-add-capability-prompt.md` in the project root** (the file is gitignored by A6's merge; it is ephemeral and may be deleted after Procedure 6 completes)."* ✓
- **§3.3 step 6.1 (line 316).** Rewritten: *"Read `add-capability.sh` report — either pasted into the session or **read from `.pack-add-capability-prompt.md` at the project root (written by A7)**."* ✓
- **§3.4 (lines 329–334).** Added file-based resilience explanation. ✓
- **§3.5 artifact table (line 377).** New row for `.pack-add-capability-prompt.md`. ✓

#### m-8 — Pack-version-mismatch check references uncodified banner — **RESOLVED**

- **§3.2 A0 note (lines 270–280).** Added: *"**A0 pack-version compatibility — warning, not hard stop.** ... A0 reads the banner best-effort. If the banner's version string does not match `$PACK`'s current version, the script prints a warning ... but does not abort. Formalizing the banner to a fenced frontmatter block with a `pack-version:` key is deferred to a future minor-version iteration."* Option (b) chosen (weaken to warning). ✓
- **Open Q 4 (lines 673–677).** Added a new OQ item on future formalization. ✓

#### m-9 — Missing V-ADDCAP tests — **RESOLVED**

- **V-ADDCAP-13 (line 601).** Already-active exit. ✓
- **V-ADDCAP-14 (line 602).** Multi-dimension atomic invocation (`--add language:python --add role:python-server --add protocol:grpc`). ✓
- **V-ADDCAP-15 (line 603).** Trigger-rule firing — PM chat redirects developer to run script before starting Procedure 6. ✓
- **V-ADDCAP-16 (line 604).** G6-drafts abort rollback state. ✓
- All four gaps closed. Test count: 12 → 16 (13 + 03b + 13–16 = 17 listed; matches the prior review's "12 → 16" estimate plus 03b). ✓

#### m-10 — Appendix B glossary entry missing — **RESOLVED**

- **§4.1 (line 415).** New row: *"Appendix B Glossary | New entry: 'Procedure 6 — METHODOLOGY.md Part 7 procedure for adding a pack-supported capability ...; paired with `scripts/add-capability.sh`. See V10-DESIGN-2 §3.3.' | Matches existing glossary entries for Procedure 5 and Procedure 5-R."* Verified that V10-DESIGN.md Appendix B lines 3414–3415 already contain Procedure 5 and Procedure 5-R entries — the new entry is parallel-structured. ✓

#### m-11 — Part 7 §7.13 integration-with-other-BDs bullet missing — **RESOLVED**

- **§4.1 (line 411).** New row: *"Part 7 §7.13 Integration with other BDs | Append one bullet: 'BD-046 add-capability.sh — runs post-init against already-initialized projects; sources `scripts/lib/detect.sh`; inverts the §7.6 S9 conditional-file table; never creates `x-` files.' | Keeps the integration inventory complete."* Verified against V10-DESIGN.md §7.13 (lines 2487–2501) existing integration bullets for BD-045, BD-046 prompt reorg, BD-046 custom agents, BD-046 migration — the new bullet extends the same pattern. ✓

#### m-12 — Phase-3 commit IDs provisional — **RESOLVED**

- **§5.1 Commit-ID note (lines 485–495).** Added: *"**Commit-ID note.** The commit identifiers in the table above (`C-046-ADD-01..03`) and in the 'Depends on' column ... are **placeholders referenced from the working Phase 3 implementation plan** ... That plan is a working artifact outside the approved design boundary and its commit IDs may be renumbered when Phase 3 is frozen. The **dependency relationships** expressed here (not the literal IDs) are the authority."* ✓

---

## 3. Cross-reference integrity (full sweep, not sampled)

Every V10-DESIGN §N.N / Part N / Appendix / AD-N reference in the 700-line addendum was grepped and verified against V10-DESIGN.md:

| Addendum cite | Line | V10-DESIGN target | Line | Verdict |
|---|---|---|---|---|
| `§7.2` `scripts/lib/detect.sh` shared library | 23, 150, 255, 409, 434, 622 | §7.2 Shared library | 1966 | ✓ |
| `§7.6` stage S4 (skill distribution) | 36 | §7.6 S4 row | 2181 | ✓ |
| `§7.6` stage S9 (conditional removal) | 48, 256, 266, 410, 641 | §7.6 S9 row + conditional-removal table | 2186, 2216 | ✓ |
| Part 7 §7.8 kickoff pattern | 104 | §7.8 Skill-gap tracking and end-of-run PM chat prompt | 2284 | ✓ |
| Part 6 §6.5 Procedure 5-R | 106, 159, 304, 408 | §6.5 Procedure 5-R | 1684 | ✓ |
| `§7.1` script placement / OQ-5 rationale | 116, 138, 143, 144, 546, 649 | §7.1 OQ-5 Two scripts | 1934 | ✓ |
| `§6.10` migration file locations | 138, 144, 146, 147 | §6.10 File locations | 1905 | ✓ |
| `§5.7` Procedure 5 | 159, 407 | §5.7 Procedure 5 outline | 1313 | ✓ |
| `§6.9` paste-ready prompt `$PACK` | 237, 242 | §6.9 MIGRATION-v9-to-v10.md outline / paste-ready prompt | 1839 | ✓ |
| `§6.6` trinity merge rules | 263 | §6.6 PLATFORM-SKILLS.md and trinity merge rules | 1703 | ✓ |
| `§7.4` stop exit 20 | implicit via §3.2 A0 inversion | §7.4 AI config stop condition | 2069 | ✓ |
| Part 8 §8.2 touch-point inventory | 412, 428, 626 | §8.2 Pack repository — files that change | 2518 | ✓ |
| Part 8 §8.5 trinity audit | 323, 635 | §8.5 Trinity-rule integrity audit | 2702 | ✓ |
| Part 7 §7.13 Integration with other BDs | 411, 421 | §7.13 Integration with other BDs | 2487 | ✓ |
| Part 10 verification plan | 413, 584 | Part 10 | 2877 | ✓ |
| Part 12 §12.1 Implementation Sequence | 414 | §12.1 Order | 3210 | ✓ |
| Appendix B glossary | 323, 415, 627, 635 | Appendix B — Glossary | 3397 | ✓ |
| `§L1` V9 Lessons | 616 | Part 11 L1 — Skills distribution design changed twice | 3102 | ✓ |
| AD-10 BD-044 scope | implicit by symmetry | AD-10 | 402 | ✓ |
| AD-11 BD-045 | 406 (explicit non-annotation) | AD-11 — BD-045 is v10 scope | 445 | ✓ (correctly **not** annotated) |
| AD-12 combined scope | 10, 209, 216, 406 | AD-12 — v10.0 is the target version | 465 | ✓ |
| AD-13 migration baseline | implicit | AD-13 | 482 | ✓ |
| `§7.5` report format | 264 | §7.5 Preview-and-confirm flow | 2096 | ✓ |
| Part 7 §7.1 rationale for zero-dependency shell | 649 | §7.1 alternatives-rejected "Shared Python module" | 1959 | ✓ |

**Twenty-five distinct citations checked; zero errors.** The prior review found 1 hard error (B-1), 2 loose (M-1, m-2), and 1 arguable (m-1) — all four are corrected in this revision.

---

## 4. Consistency with AD-1..AD-13 (no revisions, no contradictions)

| AD | Subject | V10-DESIGN line | Addendum impact | Verdict |
|---|---|---|---|---|
| AD-1 | `x-` prefix uniform | 131 | Addendum explicitly forbids touching `x-` files (§3.4, §6.4, V-ADDCAP-12, V-ADDCAP-16) | ✓ |
| AD-2 | Custom files tool-native | 171 | Not touched | ✓ |
| AD-3 | PM chat primary creation | 197 | Procedure 6 is PM-chat-driven | ✓ |
| AD-4 | Three paths, four gates | 224 | Procedure 6 adds G6-drafts + G6-commit; does not mutate AD-4 | ✓ |
| AD-5 | Migration `x-` in-place skip | 251 | Not touched | ✓ |
| AD-6 | Skills load uniformly | 275 | Preserved — skills already on disk from init | ✓ |
| AD-7 | PLATFORM-SKILLS `## Custom` sections | 296 | Addendum §3.3 step 6.5 verifies these untouched | ✓ |
| AD-8 | Per-agent prompts | 316 | Not touched | ✓ |
| AD-9 | Custom prompts in `prompts/` | 388 | Not touched | ✓ |
| AD-10 | BD-044 is v10 scope | 402 | Cited correctly by symmetry | ✓ |
| AD-11 | **BD-045 is v10 scope** | 445 | **Correctly no longer claimed as BD-046 scope** | ✓ (B-1 fix verified) |
| AD-12 | v10.0 is target | 465 | Cited correctly as scope-annotation target (combined scope includes capability addition as fourth BD-046 sub-area) | ✓ |
| AD-13 | v9.3 migration baseline | 482 | Not touched | ✓ |

All thirteen ADs are either cited correctly or untouched. No AD is revised. No approved decision is reopened. AD-A1..AD-A5 remain additive and parallel (non-colliding numbering). ✓

---

## 5. New verification tests — requested-coverage check

| Test | Prior-review ask | Addendum text (line) | Verdict |
|---|---|---|---|
| V-ADDCAP-13 | m-4 / m-9: already-active case | Line 601: *"A2 exits 0 with 'all requested capabilities already active'; no file changes; no trinity edits"* | ✓ |
| V-ADDCAP-14 | m-9: multi-dimension invocation | Line 602: *"A single invocation with three flags — `--add language:python --add role:python-server --add protocol:grpc` — resolves all three deltas ..."* | ✓ |
| V-ADDCAP-15 | m-9: trigger-rule firing | Line 603: *"The PM chat (observing its PM-CHAT.md behavioral rule) redirects the developer to run `add-capability.sh --add language:python` from the pack before beginning Procedure 6"* | ✓ |
| V-ADDCAP-16 | m-9: G6-drafts abort rollback | Line 604: *"Developer runs the script through Procedure 6 up to G6-drafts, then declines the trinity drafts. Post-abort state: conditional files present on disk (from A5); `.gitignore` updated (from A6); trinity files unchanged"* | ✓ |

All four tests match the §3.6 rollback description and the §3.3 step flow. None contradicts A2's already-active exit (the tests and the script stages are aligned). ✓

**Bonus:** V-ADDCAP-03b (Dimension 3 role coverage, line 591) added in response to M-2. This was not strictly required by the "V-ADDCAP-13..16" ask but was needed to make the matrix-coverage paragraph correct.

---

## 6. Design invariants (§6.4) — post-fix re-verification

Each of the six invariants reverified against the revised text:

1. **Trinity rule (TRIO).** §3.3 step 6.3 commits trinity edits together; V-ADDCAP-11 byte-compares added content across CLAUDE.md, AGENTS.md, GEMINI.md. §6.4 invariant cites Appendix B + §8.5 (m-2 fix). **Holds.** ✓
2. **`x-` preservation.** §3.4 prompt forbids; V-ADDCAP-12 enforces; §3.5 lists `x-` files as never-touched; V-ADDCAP-16 confirms abort path does not touch `x-` either. **Holds.** ✓
3. **Project-owned regions.** §3.3 step 6.5 runs Procedure 5.5 detection; §3.4 prompt explicitly forbids touching `## Custom agents` / `## Custom skills`. **Holds.** ✓
4. **Single source of truth for conditional files.** §3.2 A5 reads V10-DESIGN §7.6 S9 table inverted; no second table introduced; m-6 fix uses init-project.sh S8 logic for `.gitignore` rather than a new per-dimension table. **Holds.** ✓
5. **Skill-loading uniformity.** §3.2 explicitly states "No `.claude/skills/`, `.codex/skills/`, `.gemini/skills/` writes (skills are already on disk from init)." Preserved. **Holds.** ✓
6. **Zero-dependency script policy.** `add-capability.sh` remains shell; §6.4 cites §7.1 rationale. **Holds.** ✓

All six invariants are preserved. The §6.4 list accurately describes the current addendum. ✓

---

## 7. Regression sweep — did the fixes introduce new problems?

Systematic check for each fix area:

| Fix | Area touched | Regression check | Verdict |
|---|---|---|---|
| B-1 | §AD-A5, §4.1 row 1 | Did any other section still assume AD-11 annotation? Grep for "AD-11" in addendum: only at line 406, where it is correctly cited as the non-target | ✓ no regression |
| B-2 | V-ADDCAP-10 | Does §3.3 step 6.2 still claim byte-equality? No — step 6.2 says "extract the content **relevant**" (line 317). Test and procedure now aligned | ✓ no regression |
| M-1 | §AD-A1 | §5.8 no longer cited anywhere in the addendum | ✓ no regression |
| M-2 | §6.2 matrix paragraph + V-ADDCAP-03b | Does any other section still claim V-ADDCAP-03 covers Dimension 3? No — paragraph explicitly retracts the claim | ✓ no regression |
| M-3 | §3.1 Desktop sentence | Does the §3.4 prompt still assume terminal? No — §3.4 is now explicitly file + stdout (m-7 fix compounds usefully with M-3) | ✓ no regression |
| m-1 | §3.2 A2 "trinity-equivalent" wording | Consistent with §8.5 audit — no tension | ✓ no regression |
| m-2 | §3.3 closing citation | Cites existing glossary + §8.5; both verified extant | ✓ no regression |
| m-3 | A1 degenerate-case exit | Does V-ADDCAP-02 (skill-only add) still pass under the new rule? Yes — platform:ios has non-empty skill-delta (union) ∪ empty file-delta = non-empty combined delta. V-ADDCAP-02 is safe | ✓ no regression |
| m-4 | A2 already-active exit | Interacts with V-ADDCAP-13. §3.4 prompt still written — line 295: *"The end-of-run prompt is still written (§3.4) for auditing, but it reports zero deltas."* Correct | ✓ no regression |
| m-5 | AD-A4 token grammar | Does §3.2 A1 still say "value recognized"? Yes, and A1 resolution is now explicit against the normalized tokens. Alignment correct | ✓ no regression |
| m-6 | A6 full-merge semantics | Consistent with init-project.sh §7.6 S8 behavior (verified V10-DESIGN.md line 2210). No contradiction with V10-DESIGN.md | ✓ no regression |
| m-7 | A7 dual output | §3.5 artifact table adds the ephemeral file row (line 377). Step 6.1 references the file. Consistent throughout | ✓ no regression |
| m-8 | A0 warning semantics | Does not break V-ADDCAP-08 (invalid $PACK). The banner warning is orthogonal to the $PACK-valid stop. Both still fire correctly | ✓ no regression |
| m-9 | V-ADDCAP-13..16 | No test contradicts §3.2 stage assertions or §3.3 step flow | ✓ no regression |
| m-10 | §4.1 Appendix B row | No contradiction with actual Appendix B contents in V10-DESIGN.md (the entry is proposed, not yet written) | ✓ no regression |
| m-11 | §4.1 §7.13 row | No contradiction with existing §7.13 bullets | ✓ no regression |
| m-12 | §5.1 commit-ID note | Softens commitment without undermining dependency claims | ✓ no regression |

No fix introduces a new inconsistency. No prior-approved content (e.g., §3.2 A3 preview format, §3.6 abort semantics, §5.3 BACKLOG draft) was disturbed.

---

## 8. Micro-observations (not blocking; noted for awareness)

Two small items noticed during the sweep — neither warrants another review cycle and neither affects approval:

### Obs-1 — AD-A4 enumerates `language:c`, `language:cpp`, `language:objc` but PLATFORM-SKILLS.md Dimension 2 has no conditional-file delta for these

**Location:** addendum line 200; PLATFORM-SKILLS.md line 54–56.

C / C++ / Objective-C are valid `--add` values per AD-A4 but have no conditional-file entry in V10-DESIGN.md §7.6 S9. The addendum already handles this via the A1 degenerate-case exit (m-3 fix, lines 282–288) and the A2 already-active exit (m-4 fix, lines 290–295), so no implementation ambiguity exists. Worth a one-line note in Phase 3 implementation planning that "C-language adds are skill-only — no conditional files copied" to pre-empt confusion.

**Impact:** None on approval.

### Obs-2 — §4.1 "fourth BD-046 sub-area" framing is slightly imprecise

**Location:** addendum line 406.

The §4.1 row describes capability-addition as "a fourth BD-046 sub-area alongside custom agents, prompt reorg, and migration." V10-DESIGN.md AD-12 (line 467) lists BD-044 + BD-045 + BD-046 + migration + init-project + custom-file mechanism as v10 scope — six items, not three sub-areas of BD-046. The "four BD-046 sub-areas" framing is consistent with the BACKLOG.md §5.3 edit (line 517–524, which reframes BD-046 as four bullets) but is not a verbatim AD-12 claim. Not wrong, just slightly telescoped.

**Impact:** None on approval. The §5.3 BACKLOG edit is the canonical place for the four-bullet framing.

---

## 9. Open Questions list — approval check

The addendum's Part 7 Open Questions is now four items (was five; old OQ-4 promoted to AD-A4 decision):

| OQ | Subject | Blocker? | Disposition |
|---|---|---|---|
| 1 | Commit placement (Phase 3 vs Phase 2c) | No | Implementation-time choice; both respect dependencies |
| 2 | Trigger-rule wording | No | Final text lands with Procedure 6 author |
| 3 | README layout row placement | No | Match whatever C-044-06 lands on |
| 4 | Pack-version banner formalization | No | Deferred to future minor; m-8 warning suffices for v10.0 |

None of the four blocks approval. All are implementation-time or deferred decisions. ✓

---

## 10. Blast-radius table completeness

The addendum's §4.1 blast-radius table now includes all items the prior review flagged as missing:

- **Appendix B Glossary** — added (row at line 415, from m-10 fix). ✓
- **Part 7 §7.13 Integration with other BDs** — added (row at line 411, from m-11 fix). ✓
- **Part 2 AD-12 scope annotation** — corrected from AD-11 (row at line 406, from B-1 fix). ✓

Independent sweep found no additional V10-DESIGN.md section that this addendum touches but fails to list. The "unchanged" list in §4.2 (lines 419–422) is accurate — each enumerated section remains unchanged.

---

## 11. Verdict

**APPROVED.**

All 17 prior findings (B-1, B-2, M-1, M-2, M-3, m-1 through m-12) are resolved with text that matches or exceeds the prior review's recommended remediation. Twenty-five cross-references verified; zero errors. No AD-1..AD-13 is revised. AD-A1..AD-A5 remain additive and non-colliding. Four new V-ADDCAP tests (13–16) plus V-ADDCAP-03b cover the edge cases identified in the prior review. All six design invariants from §6.4 still hold. No regressions detected.

The addendum is ready to move into Phase 3 implementation planning. The two micro-observations in §8 are optional polish for Phase 3 kickoff and do not require another design-level pass.

### Recommended next steps

1. Tag or annotate V10-DESIGN-2.md status line as **APPROVED** (per Part 0 currently says DRAFT on line 5).
2. Proceed with Phase 3 planning that incorporates C-046-ADD-01..03 per §5.1.
3. (Optional) When Phase 3 plan is frozen, update the commit-ID placeholders in §5.1 with the real IDs.
4. (Optional) Address Obs-1 with a single-line clarification in the Phase 3 implementation notes — no design change.

---

*End of re-review.*
