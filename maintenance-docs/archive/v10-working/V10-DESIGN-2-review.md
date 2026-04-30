# V10-DESIGN-2.md — Review Report

**Reviewer:** pack-reviewer (Claude Code)
**Review date:** 2026-04-22
**Subject:** `maintenance-docs/v10-working/V10-DESIGN-2.md` (addendum, 618 lines)
**Base design:** `maintenance-docs/V10-DESIGN.md` (APPROVED, 3,425 lines)
**Verdict:** **NOT APPROVED** — 2 blocking findings, 3 major advisory findings, 12 minor findings. Blockers are small edits; the addendum's core design is sound and should be re-submitted after fixes.

---

## 1. Summary

V10-DESIGN-2.md proposes `scripts/add-capability.sh` + METHODOLOGY.md Procedure 6 as an in-scope BD-046 addition to let developers add pack-supported PLATFORM-SKILLS.md dimension values to an existing v10 project without re-running `init-project.sh` or destroying customizations. The design is architecturally consistent with V10-DESIGN.md: it reuses the shared-library (`scripts/lib/detect.sh`) and script-plus-PM-chat-procedure patterns, preserves all six invariants it names, and stays within BD-046's scope envelope.

The blockers are citation/factual errors that, uncorrected, would confuse implementers in Phase 3 and Phase 4. They are mechanical to fix.

---

## 2. What the addendum got right

Before the findings, the following claims are verified as accurate:

- **Active skills line locations (lines 40).** `CLAUDE.md:218`, `AGENTS.md:140`, `GEMINI.md:172` — verified by `grep -n "Active skills"` against `project-template/`. ✓
- **Trinity [PLACEHOLDER] section names (lines 41–44).** All seven placeholders (`PLATFORM_DEFAULTS`, `PLATFORM_ARCHITECTURE`, `LANGUAGE_RULES`, `GRPC_RULES`, `PLATFORM_SECURITY`, `PLATFORM_TESTING`, `PLATFORM_ANTIPATTERNS`) are present in `project-template/CLAUDE.md`. ✓
- **PLATFORM-SKILLS.md four dimensions (line 70).** Dimensions 1–4 in PLATFORM-SKILLS.md match the addendum's claim. ✓
- **init-project.sh stop condition §7.4 exit 20 (lines 62–66).** V10-DESIGN.md §7.4 does list exit 20 for existing AI config. ✓
- **Shared-library pattern reuse (§3.2, §4.1).** V10-DESIGN.md §7.2 establishes `scripts/lib/detect.sh`; extending it with `detect_installed_capabilities()` is a natural augmentation. ✓
- **No AD-1..AD-13 is revised.** Verified by reading V10-DESIGN.md Part 2 in full; AD-A1..AD-A5 are additive and do not contradict any existing AD. ✓
- **AD-A1 split rationale.** The shell-plus-PM-chat split mirrors init-project.sh-plus-kickoff (V10-DESIGN §7.8) and migrate-plus-Procedure-5-R (V10-DESIGN §6.5). Structurally consistent. ✓
- **Conditional-file table single-source-of-truth (§6.4 invariant).** V10-DESIGN §7.6 stage S9 is the one table; inversion for add-capability is legitimate. ✓
- **Zero-dependency script policy (§6.4 invariant).** `add-capability.sh` in shell matches V10-DESIGN §7.1 rationale. ✓
- **§3.4 end-of-run prompt.** Follows the init-project.sh §7.8 pattern faithfully (absolute path, active-skills delta, do-not-modify-x- rule, approval gates named). ✓

---

## 3. Findings

### BLOCKERS (must fix before approval)

#### B-1 — AD-11 is BD-045, not BD-046 (two occurrences)

**Severity:** blocking
**Files / lines:**
- `V10-DESIGN-2.md` §AD-A5, lines 192–199.
- `V10-DESIGN-2.md` Part 4 §4.1 row 1, line 347.

**Evidence.** V10-DESIGN.md Part 2:
- AD-10 (line 402) = "BD-044 is v10 scope"
- **AD-11 (line 445) = "BD-045 is v10 scope"**
- AD-12 (line 466) = "v10.0 is the target version" (names the combined BD-044 + BD-045 + BD-046 + migration + init-project + custom-file scope)
- No AD in V10-DESIGN.md is dedicated to "BD-046 is v10 scope" — BD-046's scope is established across AD-12 and Parts 4, 5, 6.

**What the addendum claims:**
- §AD-A5 (line 194): "V10-DESIGN.md Part 2 AD-11 and AD-10 place init-project.sh (BD-044) and migration (BD-046) in v10 scope…" — AD-11 does not place BD-046 in v10 scope; AD-11 is about BD-045.
- §4.1 row 1 (line 347): "Part 2 AD-11 (BD-046 is v10 scope) | Text note: BD-046 now covers capability-addition as a fourth bullet…" — an implementer instructed to annotate AD-11 would land the annotation on BD-045, corrupting that decision's record.

**Required action.** Replace both references. Candidates:
- Point at AD-12 (combined scope) and add the "fourth bullet" annotation there, OR
- Drop the AD-level annotation entirely (the addendum's BACKLOG.md update in §5.3 already captures the scope extension), OR
- Note that BD-046 scope is established through Parts 4–6 collectively rather than a single AD.

The addendum's own §5.3 BACKLOG edit (lines 442–449) and §5.4 CHANGELOG edit (lines 455–460) correctly capture the scope extension without touching AD-11. The blast-radius table row for AD-11 is the anomaly.

---

#### B-2 — V-ADDCAP-10 byte-compare test is incompatible with Procedure 6's interpretive step

**Severity:** blocking (design-level inconsistency, easy to fix)
**Files / lines:**
- `V10-DESIGN-2.md` §6.2 V-ADDCAP-10, lines 522.
- Compare to `V10-DESIGN-2.md` §3.3 step 6.2, line 266: "extract the content **relevant** to each trinity placeholder".

**Evidence.** V-ADDCAP-10 pass condition reads: "PM chat Procedure 6 fills `[LANGUAGE_RULES]` and `[PLATFORM_ARCHITECTURE]` placeholders with content derived from the newly-activated skills — **byte-compared against SKILL.md content** in `.claude/skills/<name>/SKILL.md`."

Procedure 6.2 explicitly frames the step as interpretive: "extract the content relevant to each trinity placeholder." A PM chat selecting "relevant" content cannot produce a byte-exact copy of SKILL.md, and if it did, the placeholder would contain the full skill body (hundreds of lines) rather than placeholder-sized content. The test would fail every real run of Procedure 6 and pass only a broken one.

**Required action.** Replace V-ADDCAP-10 with a checkable assertion, e.g.:
- "Placeholder now contains content; at least one full sentence is present; no placeholder-literal text (`[LANGUAGE_RULES — fill in from loaded skills]`) remains."
- Optionally: "PM chat session transcript records reading `.claude/skills/<name>/SKILL.md` before writing the placeholder."

---

### MAJOR (advisory — strongly recommended before approval)

#### M-1 — §5.8 cross-reference is wrong (used as rationale for migration-script placement)

**Severity:** major
**Files / lines:** `V10-DESIGN-2.md` §AD-A1 "Why split", lines 115–119.

**Evidence.** V10-DESIGN-2.md claims "V10-DESIGN §5.8 uses the same reasoning for migration-script placement." V10-DESIGN.md §5.8 (lines 1400–1453) is **Detection workflow** — it argues for PM-chat-layer scanning rather than tool-emitted hooks, citing Step 2 Contradiction C-3 (Codex has no file-edit hook) and Step 2 Fact 2 (Claude Code live detection is session-local). It does not discuss migration-script placement.

The migration-script placement rationale lives in §7.1 (OQ-5 — Two scripts with a shared detection library), §6.10 (file locations), or §6.11 (BD integration).

**Required action.** Replace `§5.8` with `§7.1` (or `§6.10`). The argument is otherwise sound; only the citation is wrong.

---

#### M-2 — V-ADDCAP matrix-coverage paragraph is logically inconsistent

**Severity:** major
**Files / lines:** `V10-DESIGN-2.md` §6.2 matrix-coverage paragraph, lines 526–531.

**Evidence.** The paragraph states: "V-ADDCAP-01..03 cover Dimensions 2, 1, 4 (language, platform, protocol). Dimension 3 (Component Roles) is covered by V-ADDCAP-03 when the added role implies a new skill set already covered by Dimensions 1–2…"

V-ADDCAP-03 tests `--add protocol:grpc` — that is Dimension 4, not Dimension 3. The claim that V-ADDCAP-03 covers Dimension 3 "when the added role implies…" is a non-sequitur; `protocol:grpc` is not a role.

**Required action.** Either (a) add a V-ADDCAP-03b covering Dimension 3 with a concrete role value (e.g., `role:python-server`), or (b) rewrite the paragraph to say Dimension 3 is deferred to Phase 3 implementation sampling and remove the incorrect coverage claim. Recommendation: (a), using `role:python-server` since the addendum uses it as a worked example in AD-A4 (line 180).

---

#### M-3 — Four-surface parity claim is under-specified for Claude Desktop

**Severity:** major (parity is a stated AD-A1 requirement)
**Files / lines:** `V10-DESIGN-2.md` §3.1, lines 205–227; §AD-A1 "Why not PM chat only", lines 126–132.

**Evidence.** §3.1 says "The developer triggers the workflow from a terminal in the project directory" and provides only bash invocations. Claude Desktop is not a terminal; Claude Desktop without filesystem MCP cannot run scripts. V10-DESIGN.md §6.9 (migrate-v9-to-v10.sh paste prompt, lines 1865–1903) explicitly addresses Desktop: "On Claude Desktop + filesystem MCP, the Desktop app can drive the script via the same prompt with the MCP filesystem server enabled." V10-DESIGN-2.md makes the Desktop case implicit at best.

The §3.4 end-of-run prompt is PM-chat-tool-agnostic — that part is fine. But the *triggering* of add-capability.sh on Desktop needs a note analogous to §6.9.

**Required action.** Add one sentence to §3.1 (after line 220 `$PACK` paragraph) of the form: "On Claude Desktop, the shell step runs via filesystem MCP or in a separate terminal; the developer then pastes the end-of-run prompt into the Desktop session." Mirrors V10-DESIGN.md §6.9's treatment. This also strengthens the four-surface claim in §4.1, §4.3, and Part 1 constraint 4.

---

### MINOR (should fix but not blocking)

#### m-1 — "V10-DESIGN §6.6 CLAUDE.md authoritative" overclaims the source

**File / line:** V10-DESIGN-2.md §3.2 stage A2, line 239.

The addendum says "Read existing Active skills line from `CLAUDE.md` (authoritative per V10-DESIGN §6.6)." V10-DESIGN §6.6 applies the trinity splice rule atomically to all three trinity files; it does not designate CLAUDE.md as the authoritative reader. The three files are equivalent by trinity invariant.

**Recommended wording:** "Read existing Active skills line from `CLAUDE.md` (trinity-equivalent to `AGENTS.md` / `GEMINI.md` per V10-DESIGN §6.6)."

---

#### m-2 — "§3.10" cited as TRIO rule source; the canonical definition is in Appendix B

**File / line:** V10-DESIGN-2.md §3.3 (closing paragraph), line 272.

"The trinity edits are always TRIO (V10-DESIGN §3.10, §6.6)" — §3.10 is specifically the BD-045/BD-046 trinity-integration note, not the TRIO definition. TRIO is defined in Appendix B (glossary, line 3404) and applied throughout Part 8 §8.2.1 and §8.5. Citation is loose but not incorrect.

**Recommended wording:** Cite `Appendix B` or `Part 8 §8.5` (trinity-rule integrity audit) instead of §3.10.

---

#### m-3 — A1 stage assertion "delta is non-empty" excludes legitimate skill-only adds

**File / line:** V10-DESIGN-2.md §3.2 A1 post-assertion, line 238.

Stage A1 asserts "Dimension + value recognized; delta is non-empty." But:
- `--add platform:ios` (V-ADDCAP-02) has zero conditional-file delta — it's skill-only.
- `--add language:c` / `--add language:cpp` / `--add language:objc` — PLATFORM-SKILLS.md adds `c-language`, `cpp-language`, `objc-language` skills, but V10-DESIGN §7.6 S9 table lists NO conditional-file delta for C / C++ / Objective-C.
- `--add role:shared-native-library` — adds no skills and no files (PLATFORM-SKILLS.md Dimension 3 row says "(none additional)").

If "delta" is read strictly as "conditional-file delta," A1 will stop the skill-only cases the addendum's own V-ADDCAP-02 expects to succeed.

**Recommended fix:** Clarify A1 to read "combined (skill-delta ∪ conditional-file-delta) is non-empty." Also add an explicit stop condition for the degenerate case (`role:shared-native-library`, which adds nothing at all): exit 0 with "nothing to add — this role is already covered by existing language skills."

---

#### m-4 — "Dimension already active" case not specified or tested

**File / line:** V10-DESIGN-2.md §3.2 A2 ("report what will be added vs. what is already active"), line 239.

A2 reports the union but does not specify behavior when the union equals the current set (every requested dimension/value is already active). No V-ADDCAP test covers this. Expected behavior could be (a) exit 0 with "already active, nothing to do" or (b) proceed as a no-op and still emit the prompt. The addendum is silent.

**Recommended fix:** Add a sentence to A2: "If skill-delta and file-delta are both empty after union computation, exit 0 with 'all requested capabilities already active'." Add V-ADDCAP-13 covering this case.

---

#### m-5 — Multi-word dimension values beyond platform are unaddressed

**File / line:** V10-DESIGN-2.md §7 Open Question 4, lines 585–591.

Open Q 4 recommends atomic tokens for `--add platform:`. But Dimension 3 (Component Roles) also has multi-word row labels: "Python server", "Embedded Python", "Shared native library". Dimension 1 is not unique in this respect. The addendum's AD-A4 example uses `role:python-server` — that is already the atomic-token form, but the recommendation in Open Q 4 is scoped to platform only.

**Recommended fix:** Extend Open Q 4 (or make it a decision in AD-A4) to say "atomic tokens apply to platform, role, language, and protocol dimensions; multi-word row labels are normalized to lowercase-hyphenated tokens."

---

#### m-6 — Per-dimension `.gitignore` delta source is unspecified

**File / line:** V10-DESIGN-2.md §3.2 A6, line 243; §3.4 example output, line 295.

A6 says ".gitignore merge for the new dimension (e.g., Python adds `__pycache__/`, `.venv/`) using V10-DESIGN §7.6 dedupe logic from init-project.sh S8." V10-DESIGN §7.6 S8 row and "Conditional removal table" do not define per-dimension `.gitignore` entries. Init-project.sh S8 (lines 2185, 2211–2215) merges the pack's entire `project-template/.gitignore` wholesale under a header comment.

For add-capability.sh, merging the wholesale pack `.gitignore` is not wrong but may re-add entries already pruned by init-project.sh S9. The correct behavior — compute per-dimension ignore entries and append only those — requires a data source that V10-DESIGN.md does not define.

**Recommended fix:** Either (a) add a per-dimension `.gitignore` addendum table to V10-DESIGN §7.6 (propose it here, implement in Phase 3), or (b) specify that add-capability.sh re-runs the full pack `.gitignore` merge with dedup, which is safe by idempotence — no new source-of-truth.

---

#### m-7 — Procedure 6.1 "known stdout location" implies a file that stage A7 does not write

**File / line:** V10-DESIGN-2.md §3.3 step 6.1, line 265; §3.2 A7, line 244.

Step 6.1 says "Read `add-capability.sh` report (pasted or at the known stdout location)". A7 says "Write end-of-run PM chat prompt to stdout." Stdout is ephemeral; the only "known location" for stdout is the terminal scrollback. For Desktop users (m-3) there may not even be a terminal.

**Recommended fix:** Either (a) have A7 also write the prompt to `.pack-add-capability-prompt.md` (gitignored, ephemeral), or (b) strike "the known stdout location" from step 6.1. Option (a) matches the resilience intent and makes Desktop/MCP flows work cleanly.

---

#### m-8 — Pack-version-mismatch check in A0 references a banner convention that is not formally defined

**File / line:** V10-DESIGN-2.md §3.2 A0, line 237.

A0 says "pack version matches project's installed pack version (read from context file frontmatter banner)." The current `project-template/CLAUDE.md` has a banner block:
```
*Copied from: project-template/CLAUDE.md — AI Agent Config Pack v9*
```
but this is a human comment, not a versioned frontmatter field, and the string is hardcoded (would need updating to `v10` manually). V10-DESIGN.md does not formalize this banner as a machine-readable version marker.

**Recommended fix:** Either (a) promote the banner to a fenced frontmatter block with a `pack-version:` key (trinity-rule applies; Phase 3 touches rows in Part 8 §8.2.1 would gain the version field), or (b) weaken A0 to a warning rather than a hard stop.

---

#### m-9 — Missing V-ADDCAP tests for multi-dimension invocation and for PM chat trigger rule

**File / line:** V10-DESIGN-2.md §6.2.

Test gaps:
- Multi-dimension atomic add (e.g., `--add language:python --add role:python-server --add protocol:grpc`) — declared supported in §AD-A4 line 182 but not tested.
- PM chat trigger rule (§4.3 row 4) firing: developer says "add Python"; PM chat must redirect to add-capability.sh before running Procedure 6. No test asserts this behavior.
- Procedure 6 aborting at G6-drafts — V-ADDCAP-09/10/11/12 all assume Procedure 6 runs to completion. Rollback behavior (§3.6) is claimed but untested.

**Recommended fix:** Add V-ADDCAP-13 (multi-dimension), V-ADDCAP-14 (trigger-rule firing), V-ADDCAP-15 (abort at G6-drafts, verify pre-G6-drafts state).

---

#### m-10 — Appendix B glossary is not updated

**File / line:** V10-DESIGN.md Appendix B, line 3414 (Procedure 5 and Procedure 5-R are glossary entries).

Glossary entries exist for "Procedure 5" and "Procedure 5-R" but not for "Procedure 6". Addendum's §4.1 blast-radius table (lines 343–354) does not list Appendix B as touched. Either Appendix B should be added to the sections-affected list with a new entry, or the absence should be justified.

**Recommended fix:** Add row to §4.1: "Appendix B Glossary | New entry: 'Procedure 6 — METHODOLOGY.md Part 7 procedure for adding a pack-supported capability to an existing project; paired with scripts/add-capability.sh. V10-DESIGN-2 §3.3.'"

---

#### m-11 — Part 7 §7.13 integration bullet for add-capability should be listed as a blast-radius item

**File / line:** V10-DESIGN.md Part 7 §7.13, lines 2487–2502; V10-DESIGN-2.md §4.1 table.

V10-DESIGN.md §7.13 enumerates BD-044 integration points with BD-045, BD-046 prompt reorg, BD-046 custom agents, and BD-046 migration. The addendum's add-capability mechanism is a post-init operation that shares `scripts/lib/detect.sh` with init-project.sh and uses the same conditional-file table — exactly the kind of relationship §7.13 catalogs. The §4.1 blast-radius table misses this touch point.

**Recommended fix:** Add to §4.1 sections-affected table: "Part 7 §7.13 Integration with other BDs | Append one bullet: 'BD-046 add-capability.sh — runs post-init against already-initialized projects; sources scripts/lib/detect.sh; never creates x- files.' | Keeps the integration inventory complete."

---

#### m-12 — Implementation-plan commit placement references a file outside approved V10-DESIGN.md

**File / line:** V10-DESIGN-2.md §5.1, lines 408–430.

§5.1 cites `maintenance-docs/v10-working/phase-3-implementation-plan.md` and names specific commit IDs (`C-044-08`, `C-046-01`, `C-046-04`, `C-046-08`, `C-046-15`). That file is a Phase-3 working artifact outside the approved design boundary; commit IDs there are not stable and may renumber before Phase 3 is frozen. The addendum's dependency claims (e.g., "Depends on C-046-04 PM-CHAT.md pack roster pass") are therefore provisional.

**Recommended fix:** Note explicitly in §5.1 that commit IDs are placeholders subject to renumbering during Phase 3 planning, and the dependency relationships (not the literal IDs) are the authority.

---

## 4. Consistency with V10-DESIGN.md Approved Decisions

Systematic pass over AD-1..AD-13:

| AD | Subject | Addendum impact | Verdict |
|---|---|---|---|
| AD-1 | `x-` prefix uniform across tools | Addendum forbids touching `x-` files (§3.4, §6.4, V-ADDCAP-12). | ✓ consistent |
| AD-2 | Custom files tool-native structure | Not touched; skills on disk unchanged by Procedure 6. | ✓ consistent |
| AD-3 | PM chat primary creation path | Procedure 6 is PM-chat-driven with approval gates. | ✓ consistent |
| AD-4 | Three creation paths, four gates | Procedure 6 has its own gates (G6-drafts, G6-commit); does not mutate AD-4 workflow. | ✓ consistent |
| AD-5 | Migration `x-` in-place skip | Not touched. | ✓ consistent |
| AD-6 | Skills load uniformly | Addendum preserves (skills already on disk from init). | ✓ consistent |
| AD-7 | PLATFORM-SKILLS `## Custom` sections | Addendum §3.3 step 6.5 verifies these are untouched. | ✓ consistent |
| AD-8 | Per-agent prompts | Not touched. | ✓ consistent |
| AD-9 | Custom prompts in `prompts/` | Not touched. | ✓ consistent |
| AD-10 | BD-044 is v10 scope | AD-A5 cites correctly. | ✓ consistent |
| AD-11 | **BD-045 is v10 scope** | **AD-A5 mis-cites as BD-046.** | ✗ see B-1 |
| AD-12 | v10.0 is target | AD-A5 line 10 cites correctly ("same ship target as V10-DESIGN.md per AD-12"). | ✓ consistent |
| AD-13 | v9.3 migration baseline | Not touched. | ✓ consistent |

All thirteen ADs except AD-11 are cited correctly or untouched. B-1 is the single citation defect.

---

## 5. Design invariants (Part 6 §6.4) — independent verification

Each of the six invariants verified against source:

1. **Trinity rule (TRIO).** §3.3 step 6.3 commits trinity edits in one commit; V-ADDCAP-11 byte-compares. Consistent with V10-DESIGN Appendix B and §8.5. **Verified.** ✓
2. **x- preservation.** §3.4 prompt says "Do NOT modify any file starting with x-"; V-ADDCAP-12 enforces. Script scope (§3.2) writes only to `.gitignore` and conditional-file destinations (no x- targets). PM chat Procedure 6 step 6.5 runs Procedure 5.5 scan. **Verified.** ✓
3. **Project-owned regions.** §3.4 prompt forbids touching `## Custom agents` / `## Custom skills`; V-ADDCAP-09 enforces. PLATFORM-SKILLS.md merge rule (V10-DESIGN §6.6) does not apply because add-capability does not splice that file. **Verified.** ✓
4. **Single source of truth for conditional files.** §3.2 A5 reads V10-DESIGN §7.6 S9 table inverted. No new table. **Verified.** ✓
5. **Skill-loading uniformity.** §3.2 explicitly says "No `.claude/skills/`, `.codex/skills/`, `.gemini/skills/` writes (skills are already on disk from init)." Script scope excludes skill dirs. **Verified.** ✓
6. **Zero-dependency script policy.** `add-capability.sh` is shell. No Python or other interpreter introduced. **Verified.** ✓

All six invariants hold. The invariant list is accurate.

---

## 6. Zero-token dormancy claim (§4.4)

Three components of the claim:

1. **`add-capability.sh` on disk, not read by agents during normal work.** Script is a file in the pack repo's `scripts/` directory; V10-DESIGN.md §5.8 detection scan does not include `scripts/`; no agent prompt references it. **Confirmed zero tokens during normal work.**

2. **Procedure 6 inside METHODOLOGY.md (~one page added).** METHODOLOGY.md is currently read by pm-startup (V10-DESIGN §4.7) for the RAG freshness check. Whether this is "read once in full" depends on surface:
   - Claude Code CLI with mcp-local-rag: RAG-indexed; per-query retrieval cost, not startup cost.
   - Claude Desktop + filesystem MCP: on-demand read; zero startup cost for Procedure 6 unless invoked.
   - Codex CLI / Gemini CLI: direct on-demand read.

   Addendum's claim "PM chat session startup reads METHODOLOGY.md once" is **imprecise** — several surfaces do not read METHODOLOGY.md at startup at all. The correct framing is "adds ~one procedure's worth of content to METHODOLOGY.md; consumed only when Procedure 6 is invoked." The practical conclusion — near-zero dormancy cost — holds but is under-justified.

3. **PM-CHAT.md trigger rule, ~15 tokens.** PM-CHAT.md IS read at pm-startup on most surfaces; one added behavioral-rule line is de minimis. **Confirmed.**

**Net verdict on zero-token dormancy.** Substantively correct; the claim's justification in §4.4 point 2 is loosely worded (see m-1 framing suggestion). Not a blocker — the conclusion is sound.

---

## 7. Mechanism completeness (Part 3)

Four-dimension coverage assessment:

| Dimension | Addendum handling | Status |
|---|---|---|
| 1 — Platform Targets | `--add platform:ios`; V-ADDCAP-02 (skill-only, no files); Open Q 4 (multi-word normalization) | ✓ covered |
| 2 — Languages | `--add language:python`; V-ADDCAP-01 (full file copy) | ✓ covered for Python; ✗ missing for C / C++ / Objective-C (no conditional files — see m-3) |
| 3 — Component Roles | `--add role:python-server` (example); V-ADDCAP test marked deferred | ⚠ see M-2 (coverage claim wrong) and m-5 (multi-word normalization) |
| 4 — Communication Protocols | `--add protocol:grpc`; V-ADDCAP-03 | ✓ covered |

**Edge cases not addressed:**
- Dimension already active (see m-4).
- Multi-dimension invocation (declared supported, not tested — see m-9).
- Skill-only adds with empty file delta (A1 assertion problem — see m-3).
- Degenerate zero-add cases (`role:shared-native-library`).
- Non-initialized project — **addressed** (§3.2 A0 inverts init-project §7.4 stop; exits if no AI config).
- Pack-version mismatch — mentioned but under-specified (see m-8).

**Overall:** Mechanism is complete at the high level; several edge cases deserve explicit treatment before Phase 3 implementation.

---

## 8. Four-surface parity

| Surface | Script-run step | Prompt-paste step | Verdict |
|---|---|---|---|
| Claude Code CLI | Runs bash natively | Pastes prompt | ✓ |
| Claude Desktop | Requires MCP filesystem OR separate terminal | Pastes prompt | ⚠ not explicitly documented — see M-3 |
| Codex CLI | Runs bash via Bash tool | Pastes prompt | ✓ |
| Gemini CLI | Runs bash | Pastes prompt | ✓ |

Procedure 6 itself (markdown editing) is PM-chat-tool-agnostic because skills are on disk after init and SKILL.md files are directly readable. The only parity concern is the script-run step on Desktop without MCP — M-3 above.

---

## 9. Verification tests (§6.2, V-ADDCAP-01..12)

**Test quality assessment:**

| Test | Quality |
|---|---|
| V-ADDCAP-01 | Good; tests positive file-copy path. |
| V-ADDCAP-02 | Good; tests skill-only (no-file) case. Tension with A1 "non-empty delta" assertion — see m-3. |
| V-ADDCAP-03 | Good. |
| V-ADDCAP-04 / 05 / 06 / 07 / 08 | Standard pre-flight negative tests; coverage adequate. |
| V-ADDCAP-09 | Good; essential project-owned-region guard. |
| V-ADDCAP-10 | **Broken** — see B-2. |
| V-ADDCAP-11 | Good; TRIO byte-identity. |
| V-ADDCAP-12 | Good; x- guard. |

**Missing tests (see m-9):** multi-dimension, trigger-rule firing, G6-drafts abort, dimension-already-active, pack-version-mismatch.

**Total after blocker fix and additions:** estimate 12 → 16 tests. Still reasonable scope.

---

## 10. Open Questions (Part 7) — approval impact

| OQ | Subject | Blocker? | Disposition |
|---|---|---|---|
| 1 | V-ADDCAP-01b for Dimension 3 | No (but M-2 forces something here) | Resolve in implementation — recommend adding the test when M-2 is fixed. |
| 2 | Commit placement Phase 3 vs Phase 2c | No | Either ordering respects dependencies; Phase 3 grouping is fine. |
| 3 | Trigger-rule wording | No | Final text can land with Procedure 6 author. |
| 4 | Dimension value grammar | No (extends with m-5) | Accept atomic-tokens recommendation; extend to role/language/protocol dimensions. |
| 5 | README layout row placement | No | Match whatever C-044-06 lands on. |

**None of the five open questions block approval.** All are either implementation-time decisions or stylistic choices with no architectural impact.

---

## 11. Blast-radius accuracy audit

Addendum's §4.1 "Sections affected" table vs. my independent sweep of V10-DESIGN.md:

**Correctly listed.** Part 2 AD-11/AD-12 (up to B-1), Part 5 §5.7, Part 6 §6.5, Part 7 §7.2, Part 7 §7.6, Part 8 §8.2, Part 10, Part 12 §12.1.

**Missing / under-listed.**
1. **Appendix B Glossary** — see m-10. Should be added.
2. **Part 7 §7.13 Integration with other BDs** — see m-11. One bullet should be added for completeness with the existing integration inventory pattern.
3. **Part 11 V9 Lessons Carried Forward** — addendum §6.3 explicitly invokes Lesson 1 ("placement justification") and leverages Lesson 4 (maintenance-docs consistency via Part 10 §10.15 rule). Part 11 itself does not strictly need modification — the lessons are carried forward by applying them here — but the addendum could note this in §4.1 for traceability. Optional.
4. **Part 13 Open Items Deferred** — no new deferred items; addendum's own §7 Open Questions are NOT promoted to Part 13 because they resolve at implementation time. Consistent with Part 13's structure.

**Incorrectly listed.** None. Every section the addendum claims is unchanged is indeed unchanged (spot-checked Parts 1, 3, 4, 5.1–5.6 and 5.8–5.13, 6.1–6.4 and 6.6–6.11, 7.1, 7.3–7.12, 9, 10, 11, 13).

**Net:** The blast-radius claim is broadly accurate but misses two small touch points (m-10, m-11) and contains one citation error inside an accurate row (B-1).

---

## 12. Cross-reference integrity (grep-verified)

Spot-checked every V10-DESIGN §N.N reference in the addendum:

| Addendum cite | V10-DESIGN reality | Verdict |
|---|---|---|
| §7.2 `scripts/lib/detect.sh` shared library | §7.2 exists, defines the library (line 1966) | ✓ |
| §7.6 stage S9 conditional-removal table | §7.6 exists, S9 table present (line 2216) | ✓ |
| §7.1 init-project.sh placement | §7.1 exists (line 1934) | ✓ |
| §6.10 migration file locations | §6.10 exists (line 1905) | ✓ |
| §7.4 stop condition exit 20 | §7.4 exists, exit 20 confirmed (line 2069) | ✓ |
| §7.5 report format | §7.5 exists (line 2096) | ✓ |
| §7.8 end-of-run PM chat prompt | §7.8 exists (line 2284) | ✓ |
| §6.9 paste-ready prompt / `$PACK` | §6.9 exists (line 1839) | ✓ |
| §6.6 Active skills preservation | §6.6 exists but doesn't say "CLAUDE.md authoritative" | ⚠ see m-1 |
| §5.7 Procedure 5 | §5.7 exists (line 1313) | ✓ |
| §6.5 Procedure 5-R | §6.5 exists (line 1684) | ✓ |
| §5.8 migration-script placement rationale | §5.8 is detection workflow, NOT migration placement | ✗ see M-1 |
| §3.10 trinity TRIO rule | §3.10 is BD-045/BD-046 integration; TRIO defined in Appendix B | ⚠ see m-2 |
| §3.10, §6.6 (combined, line 273) | same as above | ⚠ |
| AD-10 BD-044 | correct | ✓ |
| AD-11 BD-046 | **WRONG** — AD-11 is BD-045 | ✗ see B-1 |
| AD-12 (line 10, same ship target) | correct | ✓ |
| §5.7 (line 158) | correct | ✓ |
| §6.5 (line 158) | correct | ✓ |

Nineteen citations checked. **Sixteen correct, one wrong (B-1), two loose (M-1, m-2), one arguable (m-1).** The correctness rate is acceptable for a 618-line addendum but the one hard error (B-1) lands on a high-visibility row.

---

## 13. Other items surfaced

- **§3.5 commit message format (`feat: project — add <dimension>:<value> capability`).** This is a *project* commit message, not a *pack* commit. CLAUDE.md (pack repo rule) prescribes pack commit format; projects may have their own conventions. The addendum correctly does not impose the pack format on projects; but it also does not cite any project-side convention source. Non-issue for approval.

- **§AD-A3 (line 159).** "Procedure 5 handles custom additions (`x-` files); Procedure 5-R handles v9.3-to-v10 reconciliation; Procedure 6 handles pack-supported-capability additions." Crisp, non-overlapping. No collision with Procedures 1–4 (phase-gate, post-session, orphan audit, resolution — all unrelated lifecycle points).

- **AD-A5 "fourth bullet" framing.** The BACKLOG edit (§5.3) frames add-capability as a fourth problem. V10-DESIGN.md Part 1 "v10 addresses three problems together" is the language being extended. No issue with that extension.

- **Roadmap discipline.** Addendum stays within BD-046; does not open new BDs; does not extend v10 to v10.1 work. Consistent with CLAUDE.md pack-repo rules on scope creep.

- **No maintenance-docs invariants violated.** V9 Lesson 1 (single owner), Lesson 2 (per-tool verified facts), Lesson 3 (trinity), Lesson 4 (stale-refs updated) all respected or applied.

---

## 14. Verdict

**NOT APPROVED — return to author for fixes.**

**Blockers (must fix, small edits):**
- **B-1.** Correct AD-11 → AD-12 (or remove) in §AD-A5 line 194 and §4.1 row 1 line 347.
- **B-2.** Rewrite V-ADDCAP-10 to assert presence/non-placeholder content rather than byte-equality with SKILL.md.

**Strongly recommended (advisory):**
- **M-1.** Correct §5.8 → §7.1 citation in §AD-A1 "Why split."
- **M-2.** Fix Dimension 3 coverage in the V-ADDCAP matrix paragraph; add a concrete role test.
- **M-3.** Add one sentence on Claude Desktop parity in §3.1.

**Minor (not blocking, but fix before Phase 3 planning consumes this document):**
- m-1 (§6.6 authoritative wording), m-2 (TRIO citation), m-3 (A1 assertion wording), m-4 (already-active case), m-5 (multi-word normalization scope), m-6 (.gitignore per-dimension source), m-7 (stdout vs. file), m-8 (pack-version banner formalization), m-9 (missing tests), m-10 (Appendix B glossary), m-11 (Part 7 §7.13 integration bullet), m-12 (provisional commit IDs).

**Once B-1, B-2, M-1, M-2, M-3 are addressed, the addendum will be APPROVED with advisory minor findings that can be cleared during Phase 3 implementation planning or in a v2 of the addendum.**

The underlying design — two-part mechanism (script + Procedure 6), AD-A1..AD-A5, four-dimension uniformity, BD-046 scope envelope, six preserved invariants, three new Phase-3 commits — is sound and well-reasoned. The fixes are editorial and small. Estimated rework: one hour for blockers + majors; another hour for minors.

---

*End of review.*
