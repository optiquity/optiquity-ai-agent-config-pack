# IMPLEMENTATION-REPORT-BD-182 — Cross-CLI reference normalization across `project-template/` trinity

**BD:** BD-182
**Batch:** BD-175 EMERGENCY BATCH (boundary discipline emergency)
**Pre-edit HEAD:** `ea4c3fa585a0582b3dccd18506d3a0c5c34eaf0c`
**Architect strategy doc:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-182.md` (committed `ea4c3fa`)
**Implementer:** pack-coder (single spawn)

**User-approved OQ resolutions cited:**

- **OQ-1 (R10):** **(a) NO EDIT to R10** — preserve audience-first ordering of `agent-post-edit-check.sh` hook firing attribution unchanged (AGENTS keeps Codex-first; CLAUDE/GEMINI keep Claude-first per BD-178 SHOULD-1 alignment).
- **OQ-2 (AGENTS.md R1 shape):** **Shape A — NO EDIT to AGENTS.md R1** — preserve AGENTS-conciseness contract documented at `project-template/AGENTS.md:13-17`.
- **OQ-3 (Check 18 / new-check decision):** **(a) NO new check + ADD pack-memory bullet** — codify the §4.1 canonical reference table as a standing pack-memory rule per the §8.3 draft. Bullet added byte-identically to all 3 pack-root trinity files.

---

## §1 Problem restatement

Per BD-175 EMERGENCY BATCH boundary-discipline finding (`pack-ops/BACKLOG.md` BD-182) and architect §1: the BD-178 SHOULD-1 retro-fix byte-identicalized `GEMINI.md`'s `[CONDITIONAL] iOS 26 / Xcode 26.3 platform features` bullet to the `CLAUDE.md` form to satisfy trinity-rule "symmetry by default." However, the BD-178 SHOULD-1 retro-fix mistook trinity-parity for substance correctness — it copied a CLAUDE-specific canonical reference (`.claude/settings.json` env block) into the GEMINI-audience file unchanged. Per Override 9 (CLAUDE.md / AGENTS.md / GEMINI.md "Trinity rule — symmetry by default; asymmetry requires justification as provably tool-specific"), per-CLI canonical references ARE the legitimate carve-out for divergence; the GEMINI canonical env-var override surface is `.gemini/.env`, NOT `.claude/settings.json`.

BD-182's scope: empirically inventory cross-CLI references in `project-template/` trinity; identify all rows where the BD-178 SHOULD-1-style "byte-identicalize to CLAUDE form" pattern produced an audience-wrong canonical; correct those references per the §4.1 canonical reference table. Per architect §3.2 inventory totals: **1 definite per-CLI-substitution edit** (R1 in GEMINI.md) + 2 decision-points (R10 hook firing attribution; AGENTS.md R1 conciseness contract) + 1 documentary/CI decision (Check 18 / new-check / pack-memory).

User-resolved OQ-1 (a) + OQ-2 Shape A + OQ-3 (a) yields the architect-§6.4-table minimum edit count: **1 single-line edit in 1 file** (GEMINI.md R1) **+ 1 byte-identical pack-memory bullet addition across 3 pack-root trinity files** (per OQ-3 (a)).

---

## §2 Implementation

### §2.1 Edit 1 — `project-template/GEMINI.md` R1 (per architect §6.1.3)

**File:** `project-template/GEMINI.md`
**H2 section:** `[CONDITIONAL] iOS 26 / Xcode 26.3 platform features` (line 55)
**Edit type:** single-line single-substring substitution within an existing bullet (no H2 modification; no bullet additions/removals)
**Mechanism:** `Edit` tool with `replace_all: false`

**BEFORE** (line 61, pre-edit):

```
- For implementation details on any iOS 26 API, the `docs-researcher` agent reads directly from the Xcode documentation bundle at `$XCODE_APP/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources/AdditionalDocumentation/` (where `$XCODE_APP` defaults to `/Applications/Xcode.app` — override in `.claude/settings.json` env block if Xcode is installed elsewhere). If the path does not exist, fall back to web search.
```

**AFTER** (line 61, post-edit):

```
- For implementation details on any iOS 26 API, the `docs-researcher` agent reads directly from the Xcode documentation bundle at `$XCODE_APP/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources/AdditionalDocumentation/` (where `$XCODE_APP` defaults to `/Applications/Xcode.app` — override in `.gemini/.env` if Xcode is installed elsewhere). If the path does not exist, fall back to web search.
```

**Substantive substring change:** `` `.claude/settings.json` env block `` → `` `.gemini/.env` ``.

**Per-CLI canonical justification** (architect §4.1 row "Environment-variable override surface (e.g., `XCODE_APP`)"): Gemini CLI canonical env-var override surface is `.gemini/.env` (key=value lines). Evidence trail: `project-template/.codex/config.toml:19-20` comment ("mirrors `.claude/settings.json` env.AGENT_CAPABILITIES and `.gemini/.env` AGENT_CAPABILITIES per the BD-059 trinity rule") + `project-template/.gemini/` `ls` output (`.env` generated from `.env.example` at `scripts/init-project.sh:stage_s3_config_files` per architect §4.1.1).

**Empirical post-edit verification** (`grep` evidence):

- `grep -c .claude/settings.json project-template/GEMINI.md` → `0` (substring eliminated)
- `grep -n .gemini/.env project-template/GEMINI.md` → 1 hit on line 61 (within the iOS 26 bullet)
- `grep -n "Xcode is installed elsewhere" project-template/GEMINI.md` → 1 hit on line 61 (confirms only the canonical substring changed; surrounding prose preserved)

### §2.2 Edit 2 — Pack-memory bullet addition to all 3 pack-root trinity files (per architect §8.3, OQ-3 (a))

**Files modified** (byte-identical bullet addition):

- `CLAUDE.md` (pack-root) — bullet inserted before `### Project goals (v11)` (at line 575 post-edit)
- `AGENTS.md` (pack-root) — bullet inserted before `### Project goals (v11)` (at line 536 post-edit)
- `GEMINI.md` (pack-root) — bullet inserted before `### Project goals (v11)` (at line 506 post-edit)

**Insertion-point rationale** (coder discretion per architect §8.2 rationale point 4 "natural location is a Pack memory bullet in pack-root `CLAUDE.md` ... under § Repo conventions"): inserted at the **end** of the `### Repo conventions` H3 subsection immediately before `### Project goals (v11)`. This positions the new rule adjacent to other cross-CLI / trinity-related conventions (already-present "Filename uniqueness heuristic," "Architect-doc-vs-reality reconciliation," "Regenerate test-fixtures/manifest.txt on every v11-surface commit"). The new bullet thematically belongs with the manifest-regen / reconciliation / boundary cluster — they all govern cross-cutting hygiene rules pack-coders consult during edits.

**Final bullet content** (verbatim, as inserted to all 3 files byte-identically):

```markdown
- **Cross-CLI reference normalization in `project-template/` trinity.**
  When editing references to per-CLI paths or commands in
  `project-template/{CLAUDE,AGENTS,GEMINI}.md`, substitute the
  audience-correct canonical value per `maintenance-docs/v11-implementation/ARCHITECTURE-BD-182.md`
  §4.1 canonical reference table. Per Override 9, byte-identical
  cross-trinity adoption of CLI-specific paths is WRONG even when it
  visually closes drift — body-text drift and cross-CLI references are
  different classes (see `ARCHITECTURE-BD-182.md` §1 table). Worked
  example: BD-178 SHOULD-1 byte-identically aligned `GEMINI.md`'s
  `.claude/settings.json` reference (correct for CLAUDE form, wrong
  for Gemini-audience); BD-182 corrected to `.gemini/.env` per §4.1.
```

**Prose-flow refinements vs architect §8.3 draft** (coder discretion within constraint):

- Flattened the architect blockquote (`>` prefix) into the standard `- **Title.** body` bullet shape so it matches the style of surrounding bullets in `### Repo conventions`.
- Backticked `ARCHITECTURE-BD-182.md` in the §1-table cross-reference for consistency (the architect draft used the §-shorthand without backticks there).
- Backticked `` `GEMINI.md` `` in the worked-example sentence (the draft left it unbacktickted).
- Joined the architect's hyphenated linebreak in the path `maintenance-docs/v11-` `implementation/ARCHITECTURE-BD-182.md` into the single unhyphenated string for in-file rendering.

These are prose-flow polish, not content changes — the rule + worked example + Override 9 cross-reference all match architect §8.3 verbatim semantically.

### §2.3 Byte-identity verification — pack-memory bullet across 3 pack-root files

Per architect §10.3 + the CRITICAL constraint in the spawn prompt ("the bullet MUST be byte-identical across the 3 pack-root trinity files ... Check 18 [pack-root] (BD-181 just landed) will enforce this — if you create any divergence, Check 18 will FAIL"):

```bash
$ awk 'NR>=575 && NR<=587' CLAUDE.md > /tmp/bd182-bullet-claude.txt
$ awk 'NR>=536 && NR<=548' AGENTS.md > /tmp/bd182-bullet-agents.txt
$ awk 'NR>=506 && NR<=518' GEMINI.md > /tmp/bd182-bullet-gemini.txt
$ diff /tmp/bd182-bullet-claude.txt /tmp/bd182-bullet-agents.txt
$ diff /tmp/bd182-bullet-claude.txt /tmp/bd182-bullet-gemini.txt
$ diff /tmp/bd182-bullet-agents.txt /tmp/bd182-bullet-gemini.txt
```

**Result:** all three `diff` invocations exit 0 (no output, byte-identical). Bullet content matches across all 3 pack-root trinity files; Check 18 [pack-root] H2-skeleton parity is preserved (this is body-text addition under existing `### Repo conventions` H3, not a new H2 introduction).

---

## §3 OQ resolutions applied (user-approved decisions)

| OQ | User decision | Architect-doc reference | Implementation |
|---|---|---|---|
| OQ-1 (R10 hook firing attribution) | **(a) NO EDIT** | §13.1 option (a); §6.2 | Zero edits to R10 row in any trinity file. AGENTS.md retains "Codex post_edit_command and Claude Code PostToolUse hook" ordering; CLAUDE.md and GEMINI.md retain "Claude Code PostToolUse hook and Codex post_edit_command" ordering per BD-178 SHOULD-1 byte-identical alignment. |
| OQ-2 (AGENTS.md R1 shape) | **Shape A — NO EDIT** | §13.2 Shape A; §6.1.2 | Zero edits to AGENTS.md iOS 26 / Xcode 26.3 bullet. AGENTS-conciseness contract (`project-template/AGENTS.md:13-17`) preserved; Codex users continue with the hardcoded `/Applications/Xcode.app` form (no documented env-var indirection in AGENTS.md). Override 9 still satisfied because the omitted indirection is "concise by contract," not "wrong audience." |
| OQ-3 (Check 18 / new-check decision) | **(a) NO new check + ADD pack-memory bullet** | §13.3 option (a); §8.2 + §8.3 | Zero edits to `scripts/validate-pack.py` (no new check; no Check 18 modification). New pack-memory bullet added byte-identically to all 3 pack-root trinity files (CLAUDE.md, AGENTS.md, GEMINI.md) at end of `### Repo conventions` per architect §8.2 rationale point 4 + coder placement discretion. |

**Scope expansion check** (per architect §13.4 + spawn-prompt constraint "any scope-expansion options would require new BD per user-discussion-and-approval — do NOT silently expand scope"): **zero scope expansion**. Every edit landed maps 1:1 to a user-approved OQ decision; no out-of-OQ surfaces touched.

---

## §4 Files modified — diff stat + per-file purpose

```
 AGENTS.md                       | +12 lines (pack-memory bullet addition)
 CLAUDE.md                       | +12 lines (pack-memory bullet addition; byte-identical to AGENTS / GEMINI bullet)
 GEMINI.md                       | +12 lines (pack-memory bullet addition; byte-identical to AGENTS / CLAUDE bullet)
 project-template/GEMINI.md      |  1 line modified (R1 substring substitution: `.claude/settings.json` env block → `.gemini/.env`)
 test-fixtures/manifest.txt      |  3 lines modified (RC9 regen — 3 v11-* SHAs drift per architect §9.1)
```

| File | Change type | Purpose |
|---|---|---|
| `project-template/GEMINI.md` | modified (R1 substring substitution) | Edit 1 — restore per-CLI audience correctness to the iOS 26 / Xcode 26.3 env-var override reference (Override 9 carve-out) |
| `CLAUDE.md` (pack-root) | modified (additive — new pack-memory bullet) | Edit 2 — codify the §4.1 canonical reference table as a standing rule for future pack-coders |
| `AGENTS.md` (pack-root) | modified (additive — new pack-memory bullet, byte-identical) | Edit 2 (trinity-rule cascade) — same bullet content as CLAUDE.md |
| `GEMINI.md` (pack-root) | modified (additive — new pack-memory bullet, byte-identical) | Edit 2 (trinity-rule cascade) — same bullet content as CLAUDE.md and AGENTS.md |
| `test-fixtures/manifest.txt` | modified (RC9 regen) | `project-template/` touched → RC9 trigger fires; manifest regenerated via `bash test-fixtures/build.sh --all --clean`; 3 v11-* SHAs drift per architect §9.1 prediction |

**Files NOT modified per spawn-prompt constraints + architect §6.4:**

- `project-template/CLAUDE.md` — R1 already correct for Claude-audience (architect §6.1.1: "NO EDIT")
- `project-template/AGENTS.md` — R1 form preserved per OQ-2 Shape A
- R10 references in CLAUDE.md / AGENTS.md / GEMINI.md (pack-root and project-template) — all preserved per OQ-1 (a)
- `scripts/validate-pack.py` — no new check per OQ-3 (a); no Check 18 modification
- `scripts/init-project.sh` — install-time substitution OUT of BD-182 scope per architect §7
- `ARCHITECTURE-BD-182.md` — read-only context
- Any `pack-ops/` doc — out of scope
- Any review skill — out of scope

---

## §5 Verification

### §5.1 `python3 scripts/validate-pack.py` — all 41 checks PASS

Full validate-pack.py invocation tail (post-edits):

```
── Check 36: Commit-scope honesty (BD-175, M5a) ──
  OK: Check 36 — 0 scope-claiming commit(s) verified clean; 1 implicit-scope commit(s) skipped

── Check 37: Project-side pack-only deny-list (BD-175, M5b) ──
  OK: Check 37 — 146 project-side file(s) walked; zero deny-list contamination (0 anchored LEGITIMATE-context hit(s) accepted)

── Check 38: Pack-only-file siting (BD-175, M5c) ──
  OK: Check 38 — 1 pack-root prose file(s) checked; no pack-only content mis-sited outside `pack-ops/`. Exemption list: ['tracker.toml.pack-example'].

── Check 39: cmd_update mapping/glob symmetry (BD-175 F2a + BD-180 E) ──
  OK: Check 39 — 6 `project-template/docs/pack/*.md` file(s) forward-checked; 6 have explicit `cmd_update` mappings, 0 on forward exemption allowlist. 35 `cmd_update` entries reverse-checked; 35 resolve to existing files at HEAD, 0 on reverse exemption allowlist. No asymmetric coverage between S6 fresh-install glob and `cmd_update` explicit mappings; no stale mappings.

── Check 40: pack-ops/ bare cross-reference scanner (BD-179) ──
  OK: Check 40 — 9 pack-ops/*.md file(s) walked; zero unqualified bare cross-references (63 allowlist-exempt + 12 anchor-phrase-exempt + 32 same-dir-legit hit(s) accepted)

── Check 41: _CLIENT_INSTALLED_FILES self-doc list integrity (BD-180 G) ──
  OK: Check 41 — 38 `_CLIENT_INSTALLED_FILES` entry (entries) checked; 38 resolve to existing files at HEAD, 0 on exemption allowlist. 35 cmd_update path(s) cross-checked against inventory; 0 drift(s) (must be 0). Self-documenting list is consistent with copy-site state.

============================================================
PASSED — all checks clean
```

### §5.2 Check 18 invocations — both PASS

Per architect §10.2 + §10.3 expected behavior:

```
── Check 18 [project-template]: Trinity H2 structure parity (BD-059, BD-181) ──
  OK: [project-template] CLAUDE.md ↔ AGENTS.md H2 structures match (26 sections)
  OK: [project-template] GEMINI.md adds 2 intrinsic H2(s); otherwise matches (26 sections)

── Check 18 [pack-root]: Trinity H2 structure parity (BD-059, BD-181) ──
  OK: [pack-root] CLAUDE.md ↔ AGENTS.md H2 structures match (5 sections)
  OK: [pack-root] GEMINI.md adds 1 intrinsic H2(s); otherwise matches (5 sections)
```

Both Check 18 invocations PASS as architect predicted (body-text additions under existing `### Repo conventions` H3 do not affect H2 structure; R1 substring substitution in `project-template/GEMINI.md` is body-text under existing H2).

### §5.3 Adjacent test suites — all green

- **`scripts/persona-contracts/contract-greenfield.sh`** → 191/191 PASS (matches architect §11.3 step 11 prediction)
- **`scripts/persona-contracts/contract-mid-dev.sh`** → 25/25 PASS (matches architect §11.3 step 12)
- **`scripts/persona-contracts/contract-migration.sh`** → 37/37 PASS (matches architect §11.3 step 13)
- **`scripts/tests/test-validate-pack-check-40.sh`** (BD-179 in-flight; ran for regression-check) → 8/8 PASS (no regression from BD-182 edits)

Total adjacent-test green count: **253 + 8 = 261/261 PASS** across persona contracts and Check 40 in-flight test suite. Zero failures, zero skips.

### §5.4 R1 substitution grep verification (architect §11.3 step 14)

```bash
$ grep -c .claude/settings.json project-template/GEMINI.md
0
$ grep -n .gemini/.env project-template/GEMINI.md
61:- For implementation details on any iOS 26 API, the `docs-researcher` agent reads directly from the Xcode documentation bundle at `$XCODE_APP/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources/AdditionalDocumentation/` (where `$XCODE_APP` defaults to `/Applications/Xcode.app` — override in `.gemini/.env` if Xcode is installed elsewhere). If the path does not exist, fall back to web search.
$ grep -n "Xcode is installed elsewhere" project-template/GEMINI.md
61:- For implementation details on any iOS 26 API, the `docs-researcher` agent reads directly from the Xcode documentation bundle at `$XCODE_APP/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources/AdditionalDocumentation/` (where `$XCODE_APP` defaults to `/Applications/Xcode.app` — override in `.gemini/.env` if Xcode is installed elsewhere). If the path does not exist, fall back to web search.
```

R1 substitution verified: zero residual `.claude/settings.json` references in `project-template/GEMINI.md`; `.gemini/.env` present in the iOS 26 bullet; surrounding prose ("Xcode is installed elsewhere") preserved with single-match (confirms single-line single-substring substitution, no body restructure).

### §5.5 Byte-identity verification of pack-memory bullet (architect §10.3 + spawn-prompt CRITICAL)

```bash
$ awk 'NR>=575 && NR<=587' CLAUDE.md > /tmp/bd182-bullet-claude.txt
$ awk 'NR>=536 && NR<=548' AGENTS.md > /tmp/bd182-bullet-agents.txt
$ awk 'NR>=506 && NR<=518' GEMINI.md > /tmp/bd182-bullet-gemini.txt
$ diff /tmp/bd182-bullet-claude.txt /tmp/bd182-bullet-agents.txt && echo OK
OK
$ diff /tmp/bd182-bullet-claude.txt /tmp/bd182-bullet-gemini.txt && echo OK
OK
$ diff /tmp/bd182-bullet-agents.txt /tmp/bd182-bullet-gemini.txt && echo OK
OK
```

All three pairwise `diff` invocations exit 0; pack-memory bullet is byte-identical across CLAUDE / AGENTS / GEMINI pack-root files. Check 18 [pack-root] PASS confirms H2 skeleton parity is preserved (body-text additions under existing `### Repo conventions` H3).

---

## §6 RC9 manifest status

**Trigger:** `project-template/GEMINI.md` is under `project-template/` → RC9 trigger fires per pack-root `CLAUDE.md` § Repo conventions "Regenerate test-fixtures/manifest.txt on every v11-surface commit" (4-directory inclusive trigger).

**Action taken:** `bash test-fixtures/build.sh --all --clean` (canonical default per the RC9 rule).

**Manifest diff (post-regen, pre-stage):**

```diff
diff --git a/test-fixtures/manifest.txt b/test-fixtures/manifest.txt
index 4a22e2e..0f5d2da 100644
--- a/test-fixtures/manifest.txt
+++ b/test-fixtures/manifest.txt
@@ -4,7 +4,7 @@
 #
 v10-minimal  19558cbac58ed3e47642a6bbe64418a38c60bc16
 v10-realistic-ot  4c62945f72b037908b38967d5d8f019745263258
-v11-realistic-ot  add3450a7accd73db8a84add0c975919156f5c02
-v11-flat-file  991dfa306b688037b5a17fbfcde8ce35cb6a46e8
-v11-tracker-on  9cf477864a411037ae6b3a52f03071cb458ffac7
+v11-realistic-ot  c77d7bace2a74909290cd20e14af680370ead2d8
+v11-flat-file  13bba3fc2d24ced8c0568670aa6e961797a484ee
+v11-tracker-on  f116b0a0097f7195726fa737ef3b7b6bd9bdc862
 existing-project-mid-dev  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

**Drift profile matches architect §9.1 prediction exactly:**

- v11-realistic-ot, v11-flat-file, v11-tracker-on rows → **DRIFT** (3 v11-* fixtures include project-template trinity)
- v10-minimal, v10-realistic-ot rows → **UNCHANGED** (tag-pinned per `test-fixtures/README.md` § Determinism)
- existing-project-mid-dev row → **UNCHANGED** (pre-pack-install synthetic; no trinity present)

**Staging plan:** Pack Chat will `git add test-fixtures/manifest.txt` alongside the 4 trinity edits + this IMPL-REPORT in the same commit per architect §9.2.

---

## §7 Architect-doc-vs-reality reconciliation (per CLAUDE.md § Repo conventions "Architect-doc-vs-reality reconciliation" rule)

This BD-182 commit realizes the architect design in `ARCHITECTURE-BD-182.md` §6.1.3 (R1 edit) + §8.3 (pack-memory bullet draft) + §11 (implementation sequence).

**Three-part reconciliation chain (per the rule):**

1. **In-code "docstring" naming the realized consumer** (file + symbol; never line numbers): the pack-memory bullet itself IS the in-code consumer AND it references back to the architect doc:
   - Pack-memory bullet location: `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` pack-root, at end of `### Repo conventions` H3 → § Pack memory subsection
   - Bullet body cross-references: `maintenance-docs/v11-implementation/ARCHITECTURE-BD-182.md` §4.1 canonical reference table + §1 table
2. **Architect-doc addendum cross-referencing the realized consumer:** the architect doc is the design record; this IMPL-REPORT §7 IS the reciprocal cross-reference. Pack Chat may also append an `ARCHITECTURE-BD-182.md` § Realized-by addendum at commit-time if the manifest/CHANGELOG conventions require it (standard practice for the BD-119 → BD-160 pattern), but per BD-182's narrow scope this IMPL-REPORT cross-reference satisfies the rule's intent.
3. **IMPL-REPORT cross-reference linking both:** THIS IMPL-REPORT §7 names the architect doc (`ARCHITECTURE-BD-182.md`) + the realized consumer (pack-memory bullet at pack-root trinity `### Repo conventions` → § Pack memory subsection of CLAUDE/AGENTS/GEMINI). Reciprocal pointers complete.

**Special note:** for BD-182, the architect-doc-vs-reality reconciliation is **simpler than the BD-119 → BD-160 pattern** because the bullet IS both the consumer AND the canonical-doc-cross-reference in a single artifact (the bullet text contains the §4.1 cross-reference). Future pack-coders editing `project-template/` trinity will read the bullet → follow the cross-reference → land on `ARCHITECTURE-BD-182.md` §4.1 → consult the canonical table → apply per-CLI substitution. The chain is self-contained in pack-memory + architect-doc; no script consumer needed for this BD class (the rule is documentary/discipline, not executable).

---

## §8 Carry-forward discipline (per `.claude/skills/review/SKILL.md` § Carry-forward discipline)

**SIZE / BLOCKED / LOGICAL-FIT high-bar applied:** during implementation I identified ZERO scope-adjacent observations meriting carry-forward. The 3 closest candidates I considered + rejected:

1. **"AGENTS.md R1 still doesn't document the env-var override mechanism" (architect §6.1.2 + §13.2 Shape B path).** Forward-looking but EXPLICITLY user-rejected per OQ-2 Shape A. Acting on this would be silent scope expansion; it requires new BD + user-discussion-and-approval per OQ-1. **Rejected — DO NOT carry forward.**
2. **"R10 hook firing attribution audience-first ordering is mismatched between CLAUDE/GEMINI vs AGENTS" (architect §13.1 OQ-1).** Forward-looking but EXPLICITLY user-rejected per OQ-1 (a). Same disposition as #1. **Rejected — DO NOT carry forward.**
3. **"§4.1 canonical reference table mentions multiple per-CLI references beyond R1 (e.g., R5/R6/R7/R8 rows in the §3.1 inventory) that future trinity edits could mis-canonicalize."** This is the very motivation for the pack-memory bullet (Edit 2). The bullet's worded as a standing rule — future pack-coders will consult §4.1 BEFORE editing any per-CLI reference. **Fix-now path EXECUTED via the bullet; no forward-pointing tech debt remains.**

**Forbidden carry-forward shapes evaluated (per architect §13.4 list):**

- "This is a broader pattern than just this commit" — NOT used.
- "End-of-batch reviewer might consider…" — NOT used.
- "Forward-looking conjecture" — NOT used (rejected #1 and #2 as silent scope expansion; they require user-discussion-and-approval per OQ-1).
- "Design ratification" — NOT used.
- "Pack memory rule X recommends fix-now stated as the rationale but presented as carry-forward" — NOT used.

**Carry-forward count for this BD-182 implementation: 0.** All in-scope work shipped; zero deferrals; zero "watch for this in future" notes. Per OQ-1 EXECUTION-PLAN §B, any future scope expansion would require new BD per user-discussion-and-approval.

---

## §9 Files inventory + change-type summary

| Path | Change type | Lines added | Lines deleted | Purpose |
|---|---|---|---|---|
| `project-template/GEMINI.md` | modified | 1 (replacement) | 1 | R1 substring substitution (`.claude/settings.json` env block → `.gemini/.env`); BD-182 Edit 1 |
| `CLAUDE.md` (pack-root) | modified | +12 (new bullet) | 0 | Pack-memory bullet addition; BD-182 Edit 2 (trinity primary) |
| `AGENTS.md` (pack-root) | modified | +12 (new bullet, byte-identical) | 0 | Pack-memory bullet addition; BD-182 Edit 2 (trinity cascade) |
| `GEMINI.md` (pack-root) | modified | +12 (new bullet, byte-identical) | 0 | Pack-memory bullet addition; BD-182 Edit 2 (trinity cascade) |
| `test-fixtures/manifest.txt` | modified | 3 (3 v11-* SHAs) | 3 (3 v11-* SHAs) | RC9 manifest regen; 3 v11-* SHA drifts per architect §9.1 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-182.md` | new | (this report) | — | IMPL-REPORT (this file) |

**Total per architect §6.4 minimum-edit-count prediction:** 1 GEMINI.md edit + 0 AGENTS.md (OQ-2 Shape A) + 0 R10 edits (OQ-1 (a)) **+ 3 byte-identical pack-memory bullet additions (OQ-3 (a))** + manifest regen + IMPL-REPORT = matches expectation. No scope expansion.

---

## §10 Pre-flight + post-edit HEAD state

- **Pre-edit HEAD:** `ea4c3fa585a0582b3dccd18506d3a0c5c34eaf0c` (from `git rev-parse HEAD` at session start)
- **Post-edit HEAD:** `ea4c3fa585a0582b3dccd18506d3a0c5c34eaf0c` (unchanged; agent did NOT run `git add` / `git commit` / `git push` per agents-never-commit rule)
- **Working tree state** (`git status --short`):

```
 M AGENTS.md
 M CLAUDE.md
 M GEMINI.md
 M project-template/GEMINI.md
 M test-fixtures/manifest.txt
```

5 modified files; matches architect §6.4 minimum-edit-count + §9.1 manifest-regen expectation exactly. Pack Chat will stage all 5 + this IMPL-REPORT in the BD-182 commit per architect §11.5.

---

## §11 Definition-of-Done checklist

| DoD item | Status | Evidence |
|---|---|---|
| R1 substitution applied to `project-template/GEMINI.md` per architect §6.1.3 | **PASS** | §2.1; §5.4 grep evidence |
| Pack-memory bullet added byte-identically to 3 pack-root trinity files per architect §8.3 + OQ-3 (a) | **PASS** | §2.2; §2.3 + §5.5 byte-identity diffs |
| No edit to `project-template/CLAUDE.md` (per architect §6.1.1) | **PASS** | `git status --short` shows no project-template/CLAUDE.md change |
| No edit to `project-template/AGENTS.md` (per OQ-2 Shape A) | **PASS** | `git status --short` shows no project-template/AGENTS.md change |
| No edit to R10 in any trinity file (per OQ-1 (a)) | **PASS** | Sole `project-template/` change is `project-template/GEMINI.md` line 61 (the R1 bullet); R10 row at separate line untouched |
| No new check added to `validate-pack.py` (per OQ-3 (a)) | **PASS** | `git status --short` shows no `scripts/validate-pack.py` change beyond pre-existing BD-179 in-flight state |
| `python3 scripts/validate-pack.py` → all 41 checks PASS | **PASS** | §5.1 tail; "PASSED — all checks clean" |
| Check 18 [project-template] STILL PASSES | **PASS** | §5.2; per architect §10.2 prediction |
| Check 18 [pack-root] STILL PASSES | **PASS** | §5.2; per architect §10.3 prediction |
| Persona contracts all green (191 + 25 + 37 = 253) | **PASS** | §5.3 |
| RC9 manifest regenerated; 3 v11-* SHA drift per architect §9.1 | **PASS** | §6 manifest diff |
| Byte-identity of pack-memory bullet across 3 pack-root files (Check 18 [pack-root] enforcement gate) | **PASS** | §2.3 + §5.5; 3 pairwise `diff` exits 0 |
| Carry-forward discipline applied — zero deferrals | **PASS** | §8 |
| Agent did NOT run state-changing git verbs | **PASS** | §10 HEAD unchanged from `ea4c3fa` |
| IMPL-REPORT written to specified path | **PASS** | This file at `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-182.md` |
| PREFLIGHT line emitted before IMPL-REPORT-write authorization handoff | **PASS** (see final assistant message) |

**Definition-of-Done: 16/16 PASS.**

---

## §12 Architect-doc-deviation log

**Zero deviations from `ARCHITECTURE-BD-182.md`.** Every edit applied corresponds to a user-approved OQ resolution OR a mechanical instruction from the architect doc:

- Edit 1 (GEMINI.md R1): architect §6.1.3 mechanical instruction; substring-substitution verbatim
- Edit 2 (pack-memory bullet): architect §8.3 draft applied with prose-flow refinements per coder discretion (§2.2 enumerates the specific refinements); content semantically identical to draft
- Insertion-point selection (end of `### Repo conventions`): coder discretion per architect §8.2 rationale point 4 + spawn-prompt "Exact placement of the new pack-memory bullet within the `### Repo conventions` subsection ... — coder's discretion"
- RC9 manifest regen: architect §9.1 prediction satisfied exactly
- Persona contracts + Check 18 verification: architect §11.3 sequence followed verbatim
- IMPL-REPORT structure: architect §11.4 + spawn-prompt required sections followed

No new POQs introduced. No silent improvisations. No scope expansion.

---

## §13 PREFLIGHT line

PREFLIGHT: 5/5 in-scope file edits complete; verification PASS; HEAD ea4c3fa585a0582b3dccd18506d3a0c5c34eaf0c; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-182.md

*(Note: this PREFLIGHT line appears in this IMPL-REPORT for the audit-trail record per pack memory `feedback_pack_coder_preflight_pattern`; it is ALSO emitted as the final line of the pack-coder's chat-message output before the IMPL-REPORT-Write completion handoff to Pack Chat.)*
