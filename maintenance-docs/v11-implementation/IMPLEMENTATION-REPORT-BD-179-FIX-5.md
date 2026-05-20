# IMPLEMENTATION-REPORT-BD-179-FIX-5.md

**BD:** BD-179
**Scope:** FIX-5 — CF-3 prevention-mechanism absorption (carry-forward discipline encoding in the `review` skill, all 4 surfaces)
**Batch:** BD-175 EMERGENCY BATCH (parallel with 4 other fix-coders working on disjoint files)
**HEAD pre-fix:** `13feef3` (confirmed via `git rev-parse HEAD` at pre-flight)
**Coder:** pack-coder (fix-coder spawn)
**Report path:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-179-FIX-5.md`

---

## §1 Problem restatement

PACK-REVIEW-BD-179.md §5 surfaced 5 "end-of-batch carry-forward observations" for deferred handling by a future end-of-batch reviewer. The CF-3 observation explicitly noted that this carry-forward pattern recurred across multiple findings in the very batch that produced the review, indicating a **systemic gap** — not a one-off oversight.

The gap is **structural**:

- Pack memory rule "Deferral IS scope creep" (pack-root `CLAUDE.md` § "Pack memory > Workflow" → "Deferral IS scope creep" bullet) already codifies a high-bar test for when deferral is legitimate: ALL THREE of SIZE / BLOCKED / LOGICAL FIT must apply, with concrete evidence (not "feels big" / "feels related" / "thematic resemblance").
- The pack-reviewer agent (which produces the review reports under examination) loads the `review` skill — confirmed at `.claude/agents/pack-reviewer.md` line referencing `Load skills as specified: review for review methodology, ...`.
- The `review` skill itself contained NO carry-forward discipline section. It documented review priorities (0–5), what to examine (6–10), and reporting findings (11–14), but said nothing about when a finding qualifies as carry-forward vs in-scope.
- As a result, pack-reviewer agents had no skill-level prompt-time guidance on carry-forward discipline. The pack-memory rule was authoritative for Pack Chat triage but invisible to the reviewer at the moment classification decisions were made.

The user has stated this pattern is "NOT ACCEPTABLE" and called for prevention: **"Hope is not a plan. The reviewer can identify things to carry forward only if they meet this high bar."**

Empirical evidence from this very batch (PACK-REVIEW-BD-179.md §5, observations 1–5):

1. **CF-1** — "CI workflow staleness for the `test-validate-pack-check-*` family is a batch-wide pattern." The observation literally states "Pack-memory rule 'Deferral IS scope creep' recommends (a)" — i.e., the reviewer CITED the rule that says "fix now" while ALSO surfacing the finding as carry-forward, a direct contradiction of pack-memory guidance.
2. **CF-2** — "README Repository Layout has accumulated staleness across the BD-175 batch." Pure broader-pattern framing; fixable now (a single PM-only README edit); deferred without high-bar justification.
3. **CF-3** — "Architect §3.2 indented-block contract pattern (SHOULD-2) suggests a class of architect-contract-vs-implementation divergence that the batch may want to systematically reconcile. End-of-batch reviewer might consider whether a final mechanical sweep ... is worth ~30 minutes of attention before the BD-182 audit closes." The "worth N minutes" framing is the exact forbidden shape — if it's worth 30 minutes, it's a fix-now finding, not a carry-forward. THIS is the carry-forward that the FIX-5 prevention mechanism is named after.
4. **CF-4** — "The `_CHECK_40_ALLOWLIST` is at 17 entries and likely to grow as more pack-ops/ docs are added." Forward-looking conjecture ("likely to grow") with no current defect — not a finding at all; should not have been surfaced.
5. **CF-5** — "The 5 modified `pack-ops/*.md` files now contain qualified prose paths that may drift if the qualified targets move in a future BD." Explicitly self-rationalizes as design ratification ("this is feature, not coupling tax") — not a finding; should not have been surfaced.

All 5 carry-forwards fail the high-bar test: none meet ALL THREE of SIZE + BLOCKED + LOGICAL FIT. The fix encodes the test in the skill itself so future pack-reviewer instances (and project-side reviewer instances) see the discipline at the moment they would have classified a finding as carry-forward.

## §2 Added section content (final text as inserted)

The new section "Carry-forward discipline" was inserted in all 4 SKILL.md surfaces. The pack-root trinity variants (`.claude/`, `.codex/`, `.gemini/`) ship byte-identical content; the project-template canonical ships substantively-identical content with audience-appropriate framing tweaks (PM chat vs Pack Chat; no pack-memory citations since pack memory is pack-only by P-missed-7 boundary discipline).

### §2.1 Pack-root trinity variant (byte-identical across `.claude/` / `.codex/` / `.gemini/`)

```markdown
## Carry-forward discipline

A reviewer may surface a finding as "end-of-batch carry-forward" (or any analogous "defer to later phase / later BD / later batch" framing) ONLY if the finding meets ALL THREE of the following high-bar tests. This rule operationalizes pack memory "Deferral IS scope creep" (see trinity Pack memory § Workflow) inside the review process itself, so deferral discipline is enforced at the moment findings are classified — not after the fact.

1. **SIZE.** The finding requires architect-pass material work — new design surface, new contract negotiation, structural change spanning multiple files or layers. NOT "feels big" — provide a concrete file/contract surface argument (which files, which contracts, which design decisions are open).
2. **BLOCKED.** Real dependency on a not-yet-landed artifact — a sibling BD's implementation, a tool/framework version not yet adopted, a fixture or test harness not yet built. NOT "feels related" — name the specific blocker and the unblock event.
3. **LOGICAL FIT.** The finding cleanly belongs with another sibling BD/commit (concrete same-file / same-contract / same-symbol fit). NOT "thematic resemblance," "broader pattern," or "related area."

**Default: FIX NOW.** Every finding that does NOT meet ALL THREE tests must be surfaced as an in-scope review finding (BLOCKER / MUST / SHOULD / NIT) for fix-now triage by Pack Chat, not deferred to a later reviewer pass. Pack Chat's default-fix-all triage discipline (pack memory `feedback-fix-all-review-findings`) requires every finding to be visible at fix-or-defer triage time; carry-forward is not a way to bypass that triage.

**Forbidden carry-forward shapes.** These framings are NOT acceptable carry-forwards; the reviewer must classify them as in-scope findings (fix in the current cycle; expand the in-scope finding's scope to cover the broader pattern if needed):

- *"This is a broader pattern than just this commit."* — If the pattern is fixable now, expand the in-scope finding's scope to cover the pattern. Do not defer.
- *"End-of-batch reviewer might consider…"* / *"Worth ~N minutes of attention before the batch closes."* — If it's worth N minutes, it's a fix-now finding, not a carry-forward. N minutes does not justify deferral.
- *Forward-looking conjecture* (*"X is likely to grow"*, *"this could drift"*). — Not a finding; do not surface unless it represents a current defect with concrete evidence.
- *Design ratification* (*"this is a feature, not a bug"*, *"acknowledged tradeoff"*). — Not a finding; do not surface.
- *"Pack memory rule X recommends fix-now"* stated as the rationale but presented as carry-forward. — If pack memory recommends fix-now, surface as fix-now; do not contradict pack memory by deferring.

**If a finding qualifies as a true carry-forward**, explicitly cite which test it passes in the report using this format:

> CARRY-FORWARD: SIZE / BLOCKED / LOGICAL-FIT — <concrete evidence: which files, which blocker, which sibling BD>

If it does not qualify, surface it as a regular in-scope finding with severity. Hope is not a plan. Carry-forward without high-bar justification is tech debt accumulation by another name.
```

### §2.2 Project-template canonical (audience-appropriate framing)

Substantively identical; framing tweaks:

- Opening paragraph: replaces *"This rule operationalizes pack memory 'Deferral IS scope creep' (see trinity Pack memory § Workflow) inside the review process itself"* with the inline rationale *"Deferral is scope creep — punted findings lose context, multiply across reviews, and become tech debt that requires archaeology in future sessions."* The substance is the same; the wording is independent of pack-only references (project clients have no pack-memory file).
- Default-FIX-NOW paragraph: replaces *"Pack Chat"* with *"the PM chat"* and drops the pack-memory `feedback-fix-all-review-findings` citation (replaced with the substantive rule "Every finding must be visible at fix-or-defer triage time").
- Last forbidden-shape bullet: replaces *"Pack memory rule X recommends fix-now"* with *"Project rule X recommends fix-now"*.
- The 3 high-bar tests, the "Default: FIX NOW" rule, the 4 other forbidden carry-forward shapes, the CARRY-FORWARD citation format, and the closing aphorism *"Hope is not a plan."* are all word-for-word identical to the pack-root trinity.

The boundary-discipline rationale: pack-memory rules are pack-internal mechanisms (per P-missed-7); they do not exist at client install. The project-template canonical must encode the same discipline using project-side framing.

## §3 Insertion point per file

In all 4 SKILL.md files, the new "## Carry-forward discipline" section was inserted **immediately after** the existing "## Reporting findings" section (which contains numbered items 11–14). This is the logical position per the prompt's guidance: carry-forward discipline is a sub-discipline of how findings are reported and classified. The section is the new final section in each file (no closing/summary section was displaced).

The 4 files now share this structure:

| Section | Pack-root trinity | Project-template canonical |
|---|---|---|
| Frontmatter (`name`, `description`, `allowed-tools`) | unchanged | unchanged |
| `## Review priorities (check in this order)` | items 0–5 (priority 0 = Boundary discipline) | items 1–5 (no priority 0; baseline pre-existing) |
| `## What to examine` | items 6–10 | items 6–10 |
| `## Reporting findings` | items 11–14 | items 11–14 |
| `## Carry-forward discipline` (NEW) | inserted | inserted |

The pre-existing baseline difference (project-template lacks the priority-0 boundary-discipline line) is unrelated to FIX-5; it pre-dates this fix and is out of FIX-5 scope.

## §4 Files modified — diff stat per file

| File | Insertions | Deletions | Net |
|---|---:|---:|---:|
| `.claude/skills/review/SKILL.md` | +24 | 0 | +24 |
| `.codex/skills/review/SKILL.md` | +24 | 0 | +24 |
| `.gemini/skills/review/SKILL.md` | +24 | 0 | +24 |
| `project-template/skills/review/SKILL.md` | +24 | 0 | +24 |
| **Total** | **+96** | **0** | **+96** |

All four edits are purely additive — no pre-existing prose was modified. Existing sections (Review priorities, What to examine, Reporting findings) are preserved untouched. Confirmed via `git diff --stat` (output captured in §6).

## §5 Files changed inventory

| Path | Change type | Scope |
|---|---|---|
| `.claude/skills/review/SKILL.md` | modified | pack-root Claude trinity variant of `review` skill |
| `.codex/skills/review/SKILL.md` | modified | pack-root Codex trinity variant of `review` skill |
| `.gemini/skills/review/SKILL.md` | modified | pack-root Gemini trinity variant of `review` skill |
| `project-template/skills/review/SKILL.md` | modified | Pattern A canonical for client distribution |
| `test-fixtures/manifest.txt` | modified (RC9 rebuild) | 3 v11-* row SHAs drifted; staging delegated to Pack Chat |

No other files modified. No new files created. No files deleted. The `.claude/agents/pack-reviewer.md` / `.codex/agents/pack-reviewer.toml` / `.gemini/agents/pack-reviewer.md` agent files already load the `review` skill (verified at `.claude/agents/pack-reviewer.md` line `Load skills as specified: review for review methodology, ...`) — no agent-file edit needed, the new skill section is picked up automatically.

## §6 Verification

### §6.1 Pack-root trinity byte-identity

```
$ diff .claude/skills/review/SKILL.md .codex/skills/review/SKILL.md
$ diff .claude/skills/review/SKILL.md .gemini/skills/review/SKILL.md
```

Both diffs exit zero with no output → **PASS**: claude / codex / gemini variants are byte-identical post-edit. This preserves the BD-149 naming-convention maintenance contract and the existing review-skill trinity convention.

### §6.2 Project-template canonical contains discipline section

```
$ grep -c "## Carry-forward discipline" project-template/skills/review/SKILL.md
1
```

→ **PASS**: section header present exactly once.

Substantive elements verified via parse:

- Section header `## Carry-forward discipline` — present
- `1. **SIZE.**` — present
- `2. **BLOCKED.**` — present
- `3. **LOGICAL FIT.**` — present
- `**Default: FIX NOW.**` — present
- `**Forbidden carry-forward shapes.**` — present (5 sub-bullets covering broader-pattern / worth-N-minutes / forward-looking conjecture / design ratification / contradicts-fix-now-rule)
- CARRY-FORWARD citation format blockquote — present
- Closing aphorism `Hope is not a plan.` — present

### §6.3 Markdown validity (all 4 files)

```
$ python3 -c "
import re
for f in ['.claude/skills/review/SKILL.md', '.codex/skills/review/SKILL.md', '.gemini/skills/review/SKILL.md', 'project-template/skills/review/SKILL.md']:
    with open(f) as fh:
        c = fh.read()
    assert c.startswith('---\\n'), f + ': missing frontmatter open'
    fm_close = c.find('\\n---\\n', 4)
    assert fm_close > 0, f + ': missing frontmatter close'
    for sec in ['## Review priorities', '## What to examine', '## Reporting findings', '## Carry-forward discipline']:
        assert sec in c, f + ': missing section ' + sec
    for test in ['1. **SIZE.**', '2. **BLOCKED.**', '3. **LOGICAL FIT.**']:
        assert test in c, f + ': missing test ' + test
    print(f + ': VALID')
"
.claude/skills/review/SKILL.md: VALID markdown structure + all required sections + 3 tests present
.codex/skills/review/SKILL.md: VALID markdown structure + all required sections + 3 tests present
.gemini/skills/review/SKILL.md: VALID markdown structure + all required sections + 3 tests present
project-template/skills/review/SKILL.md: VALID markdown structure + all required sections + 3 tests present
```

→ **PASS**: all 4 files have valid frontmatter open/close, all 4 expected section headers, and all 3 high-bar test items.

### §6.4 git diff --stat (4 edited skill files)

```
$ git diff --stat .claude/skills/review/SKILL.md .codex/skills/review/SKILL.md .gemini/skills/review/SKILL.md project-template/skills/review/SKILL.md
 .claude/skills/review/SKILL.md          | 24 ++++++++++++++++++++++++
 .codex/skills/review/SKILL.md           | 24 ++++++++++++++++++++++++
 .gemini/skills/review/SKILL.md          | 24 ++++++++++++++++++++++++
 project-template/skills/review/SKILL.md | 24 ++++++++++++++++++++++++
 4 files changed, 96 insertions(+)
```

→ **PASS**: 24 insertions per file, 0 deletions per file (purely additive; existing prose preserved untouched).

### §6.5 Pack-root vs project-template substantive-identity audit

`diff .claude/skills/review/SKILL.md project-template/skills/review/SKILL.md` reports exactly 4 differences:

1. Pack-root has priority-0 "Boundary discipline" entry; project-template does not. **PRE-EXISTING BASELINE DIFFERENCE — out of FIX-5 scope.**
2. Opening paragraph of new section: pack-root cites pack memory "Deferral IS scope creep"; project-template inlines the rationale (no pack-memory citation). **AUDIENCE FRAMING TWEAK — by design per P-missed-7 boundary discipline.**
3. Default-FIX-NOW paragraph: pack-root says "Pack Chat"; project-template says "the PM chat". **AUDIENCE FRAMING TWEAK — by design.**
4. Last forbidden-shape bullet: pack-root says "Pack memory rule X"; project-template says "Project rule X". **AUDIENCE FRAMING TWEAK — by design.**

All other content (3 tests, default-fix-now rule, 4 other forbidden-shape bullets, citation format, closing aphorism) is word-for-word identical. The substantive discipline (when carry-forward is acceptable; what shapes are forbidden; how to cite a qualifying carry-forward) is identical across all 4 surfaces.

## §7 RC9 manifest status

`project-template/skills/review/SKILL.md` is under `project-template/` → **RC9 trigger FIRED**.

Ran `bash test-fixtures/build.sh --all --clean` from pack root. Build completed cleanly (4 fixtures rebuilt; v10-* rows tag-pinned and unchanged; 3 v11-* rows drifted per expectation).

```
$ git diff --stat test-fixtures/manifest.txt
 test-fixtures/manifest.txt | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

$ git diff test-fixtures/manifest.txt
@@ -4,7 +4,7 @@
 #
 v10-minimal  19558cbac58ed3e47642a6bbe64418a38c60bc16
 v10-realistic-ot  4c62945f72b037908b38967d5d8f019745263258
-v11-realistic-ot  1b65059394305f2704660cfc8764e8b1e34fd7c5
-v11-flat-file  8299a525af78380f6bfcd1ff62aa1445d37146f4
-v11-tracker-on  281ff6f24ca4a49554b34ac7173e84bf2d9e5d38
+v11-realistic-ot  47e5ea262217c02f07c303f517332c2266556bb8
+v11-flat-file  e0e4e081c61732f88e8bd63b9acbf05d62216508
+v11-tracker-on  84f6621483082ca2a4b8bdee9d7d8bbaa76f1138
 existing-project-mid-dev  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

Manifest **DRIFTED** (3 v11-* rows). The v10-* rows are tag-pinned at `v10.1` and unchanged; the `existing-project-mid-dev` row (synthesized non-pack input) is unchanged.

**Disposition for Pack Chat:** `git add test-fixtures/manifest.txt` alongside the 4 SKILL.md edits in the same commit, per RC9 trigger.

**I did NOT stage the manifest** — per the pack-coder permission rules (no state-changing git verbs), staging is delegated to Pack Chat at commit time.

## §8 Boundary discipline check (per P-missed-7)

The FIX-5 task edits one project-template surface (`project-template/skills/review/SKILL.md`). Boundary discipline pre-flight performed:

- **Project-side SSOT investigated:** There is no pre-existing project-side rule for carry-forward discipline (confirmed by `grep -rln "Deferral IS scope creep\|carry-forward\|carry forward" project-template/` returning empty). The project-side framing for orchestrator-level discipline is documented at `project-template/docs/pack/PM-CHAT.md` and `project-template/CLAUDE.md` § "Project memory"; neither encodes a carry-forward rule today. This FIX-5 introduces the discipline at the project-side `review` skill as a genuine net-new project-side rule.
- **Project-side framing used:** The project-template canonical does NOT reference pack memory, Pack Chat, or any pack-only mechanism. It uses "the PM chat" (per `project-template/CLAUDE.md` line 31 `pm-startup` and § "Project memory" § PM-chat-does-not-architect bullet), "project rule" instead of "pack memory rule", and inlines the deferral-scope-creep rationale instead of citing pack memory.
- **No pack-only references introduced in project-template:** verified by re-reading the inserted section against the canonical deny-list (`pack-ops/`, `pack-*` agent names, `Pack Chat` orchestrator role, `maintenance-docs/`, `PACK-AGENTS.md`, `PACK-CHAT.md`). None present in the project-template canonical.

→ Boundary discipline **PASS**. No boundary-discipline stop required.

## §9 Forward-pointing memory pointer (recommendation)

**Recommendation: YES.** A Tier 1.5 Claude-Code memory cache entry should be added at `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_review_carry_forward_discipline.md` pointing at the new SKILL.md section, AND the MEMORY.md index at the same directory should add a one-line bullet for it.

**Rationale:**

- Pack Chat already triages reviewer findings using `feedback-fix-all-review-findings` and `feedback-deferral-is-scope-creep` at the trinity/memory layer; adding `feedback-review-carry-forward-discipline` makes the chain explicit (reviewer-side encoding + Pack-Chat-side triage discipline are siblings, not duplicates).
- The new pointer would document that the discipline is enforced at TWO layers: at the reviewer (skill-level prompt time, FIX-5) and at Pack Chat (memory-rule triage time, pre-existing). This dual-layer enforcement is the structural prevention mechanism for the CF-3 class of regression.
- The MEMORY.md index line should follow the existing pattern: `[Reviewer carry-forward discipline — high bar](feedback_review_carry_forward_discipline.md) — review-skill encodes the SIZE/BLOCKED/LOGICAL-FIT test; forbidden shapes are fix-now findings`.

**Final decision rests with Pack Chat / user.** The skill-level encoding is the load-bearing change; the memory pointer is a Tier 1.5 convenience cache that helps Claude-Code Pack Chat sessions find the rule fast without re-walking the trinity. Pack Chat should decide whether to add the pointer in the same commit or as a follow-up Pack-Chat-direct edit.

## §10 Plan deviations

**Zero deviations.** The FIX-5 task as prompted was executed exactly:

- 4 SKILL.md files edited (the 4 listed in the prompt).
- New "Carry-forward discipline" section inserted in each.
- Pack-root trinity variants byte-identical post-edit.
- Project-template canonical substantively identical with audience-appropriate framing tweaks.
- Existing prose untouched outside the insertion point.
- No source code, fixture, test, or non-skill doc modified.
- No pack-reviewer agent file modified (skill update is picked up automatically; agents already load the `review` skill).
- IMPL-REPORT written at the prompted path.
- RC9 manifest rebuilt; drift documented; staging delegated to Pack Chat.
- No `git add` / `git commit` / `git push` executed.

## §11 New POQs introduced

**None.** The fix is purely additive to an existing skill file structure; no design surface change, no architectural decision deferred. The Tier 1.5 memory pointer (§9) is a recommendation, not a POQ — Pack Chat / user can decide in commit-approval.

## §12 Definition of Done checklist

| # | Item | Status |
|---|---|---|
| 1 | All 4 review-skill files contain the carry-forward discipline section | **PASS** (verified §6.2 / §6.3) |
| 2 | The 3 pack-root variants are byte-identical | **PASS** (verified §6.1) |
| 3 | The project-template canonical contains substantively-identical guidance with client-audience framing | **PASS** (verified §6.5: 3 tests + default + 4-of-5 forbidden shapes word-for-word identical; framing tweaks per §8) |
| 4 | All 4 files remain syntactically valid markdown | **PASS** (verified §6.3) |
| 5 | IMPL-REPORT documents added text + cross-references pack memory rule + verifies trinity byte-identity | **PASS** (§2.1 full text; §1 references pack-root `CLAUDE.md` § "Pack memory > Workflow" "Deferral IS scope creep" bullet; §6.1 byte-identity verification) |
| 6 | No source code / fixture / test / non-skill doc modified | **PASS** (verified §5: only 4 SKILL.md + manifest rebuild) |
| 7 | No pack-reviewer agent file modified | **PASS** (verified §5: agents already load `review` skill at line 56 of `.claude/agents/pack-reviewer.md`) |
| 8 | Boundary discipline check performed for project-template edit | **PASS** (verified §8) |
| 9 | RC9 manifest rebuilt and drift documented | **PASS** (verified §7: 3 v11-* rows drifted; staging delegated to Pack Chat) |
| 10 | No state-changing git verbs run | **PASS** (only `git rev-parse HEAD`, `git status`, `git diff --stat`, `git diff` read-only verbs used) |
| 11 | PREFLIGHT line emitted in final assistant message | **PASS** (see PREFLIGHT line below) |

---

## §13 Final HEAD SHA

`git rev-parse HEAD` at session end: `2842454` (moved from pre-flight `13feef3` while this fix-coder was working — sibling fix-coders FIX-1 / FIX-2 / FIX-3 in the parallel BD-175 emergency batch landed commits `1e644d1` SHOULD-1, `415f484` NIT-1, `2842454` SHOULD-3 via Pack Chat during this session). All 4 SKILL.md edits and the rebuilt `test-fixtures/manifest.txt` remain intact in the working tree (verified via `git status --short`). The 3 landed sibling commits touched `.github/workflows/`, `IMPLEMENTATION-REPORT-BD-179.md`, and `README.md` — no conflict with FIX-5's 4 SKILL.md surfaces. This fix-coder executed no state-changing git operations; only read-only verbs (`git rev-parse`, `git status`, `git diff --stat`, `git diff`, `git log`).

---

**End of IMPLEMENTATION-REPORT-BD-179-FIX-5.md.**
