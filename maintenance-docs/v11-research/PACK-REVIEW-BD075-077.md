# PACK-REVIEW-BD075-077.md

Independent review of Batch 2 (BD-076 + BD-075 + BD-077) at HEAD `1d478d1`.

## Verdict: **GO-WITH-FIXES**

## Test totals confirmed

- `bash scripts/tests/pack-help-test.sh` — **17/17 pass** (5 detect_pack_surface cases + 12 pack-help.sh end-to-end), matching the BD-075 commit message.
- `python3 scripts/validate-pack.py` — **PASSED — all checks clean** (no regression on the v11.0 baseline; Checks 21–24 from BD-082 are not yet wired and are not expected at this point).

## Net assessment

The three commits land the D-20 / V3 §28.2 help surface as designed: a single LCD shell verb (`scripts/pack-help.sh`) backed by canonical + per-surface fragments and a Trinity-replicated × 2-surfaces per-CLI namespaced command. Surface routing, sibling-include resolution, and the pack-side fragment all behave as the architecture sections require, and the tests cover the five detection cases plus the placeholder-replacement contract end-to-end. The pack-root canonical → client-tree mirror byte-identity for `HELP-FRAGMENT-TRACKER.md` holds (verified with `diff`). The six per-CLI files are consistent in pairs (Claude/Codex Markdown skill, Gemini TOML command); pack-side and client-side per-CLI bodies are byte-equal at each variant. The work is correct against the V3 baseline. The fixes needed are scope-clarifying, not behavioural: the BD-077 commit message asserts an install-time wiring that the current `init-project.sh` does not do, the BD-075 BACKLOG entry names a script file that was not created, and the IMPLEMENTATION-PLAN-ADDENDUM-4 §2.8 / §5.3 row-additions to the BD-076 fragments are absent (whether by-design deferral or oversight). None of these block CI; all three should be reconciled before the v11 cumulative review.

---

## Per-BD verification matrix

| BD | Status | Findings |
|---|---|---|
| BD-076 | GREEN | F1 (NIT, missing Addendum-4 §2.8/§5.3 rows; deferable). F2 (NIT, fragment-internal placeholder text vs detected name). |
| BD-075 | GREEN | F3 (WARNING, BACKLOG File/Symbol names a script that does not exist: `scripts/lib/detect-surface.sh`). |
| BD-077 | GREEN | F4 (WARNING, commit-message claim about `init-project.sh` install behaviour is not yet true at HEAD). F5 (NIT, allowed-tools frontmatter narrower than the spec illustrates). |

GREEN = ships; correctness verified against the cited V3 §28.2 contracts.

---

## Trinity-propagation check

### BD-077 per-CLI pack-help files (file-wise trinity × 2 surfaces)

Pack-side (PACK-ROOT):
- `.claude/skills/pack-help/SKILL.md` — present (15 lines, Markdown skill, `name: pack-help`, `allowed-tools: Bash`, body invokes `!\`bash scripts/pack-help.sh\``).
- `.codex/skills/pack-help/SKILL.md` — present, **byte-equal to Claude variant**. Codex skill format is Markdown per V3 §7.1.1 textual fix; this is correct, contrary to V3 §28.2.3 row 2 of the per-CLI table which still says `.codex/skills/pack-help/` without specifying SKILL.md vs TOML — the Addendum-supplemented decision lands on Markdown, which is what shipped.
- `.gemini/commands/pack-help.toml` — present (12 lines, TOML, `description = "Show all pack commands and colloquial mappings."`, `prompt = """..!{bash scripts/pack-help.sh}.."""`), matches V3 §D.7 worked example.

Client-side (`project-template/`):
- `project-template/.claude/skills/pack-help/SKILL.md` — present, **byte-equal to PACK-ROOT pack-side variant**.
- `project-template/.codex/skills/pack-help/SKILL.md` — present, **byte-equal to PACK-ROOT pack-side variant**.
- `project-template/.gemini/commands/pack-help.toml` — present, **byte-equal to PACK-ROOT pack-side variant**.

All six files exist; all six invoke the same shell verb (`scripts/pack-help.sh`). validate-pack Check 21 is not yet wired (BD-082 is downstream); when it lands it will pass.

### Pack-root canonical → client-tree mirror byte-identity

`HELP-FRAGMENT-TRACKER.md` (pack root) vs `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`:
- `diff` returns clean — **byte-identical**.

This satisfies the V3 §28.2.4 / I.4 contract that the shared tracker fragment is the canonical-mirror pair. validate-pack Check 24 (pending in BD-082) will enforce this in CI.

### Trinity-rule symmetry on the pack-side `.toml` filename

Per V3 I.4 trinity-propagation matrix line 2860: pack side per-CLI command files are listed as `.gemini/commands/pack-help.toml`. Reality matches.

---

## Findings

### F1 — BD-076 — Addendum-4 §2.8 / §5.3 row additions absent

- **Severity:** NIT (deferable; depends on whether Addendum 4's V3.3 scope is being deferred).
- **Files:** `HELP-FRAGMENT-PACK.md`, `project-template/docs/pack/HELP-FRAGMENT.md`.
- **Contract:** `maintenance-docs/v11-research/IMPLEMENTATION-PLAN-ADDENDUM-4.md` §2.8 and §5.3 require, at the BD-076 ship commit, two rows in the client fragment (`pack td promote --to=phase-N` and `pack td promote --to=phase-N.M`), one client-fragment row for `agent-run.sh claude --agent auditor-issue-tracking`, and one pack-fragment row for `claude --agent pack-auditor`.
- **Observation:** Neither fragment contains those rows at HEAD `1d478d1`. The verbs / agents named in those rows belong to BD-107 (TD promotion verbs) and BD-109 (`auditor-issue-tracking` sub-agent) / BD-110 (`pack-auditor` agent), none of which have shipped. Addendum 4 §6.1 sequences BD-107 at step 9d (before BD-076 at step 16) and BD-109 at step 23a (after BD-076). Adding the BD-109 / BD-110 rows at BD-076 ship commit produces a forward reference to verbs/agents that do not yet exist; that is what was avoided here. The two `pack td promote` rows could have been added (BD-107 sequencing aside, the verb names are stable per Addendum 4 §3.1) but were not.
- **Action:** Either (a) add the two `pack td promote` rows now and defer the auditor-agent rows to the BD-109 / BD-110 ship commits with an Addendum-4 amendment that relaxes the "all four rows at BD-076 ship" wording, or (b) document explicitly in the next Pack Chat that Addendum 4 §2.8 row additions are deferred to the respective downstream BDs. Either is acceptable; silently deferring without a written amendment is the gap.

### F2 — BD-076 — fragment placeholder text vs detected name

- **Severity:** NIT.
- **File:** `project-template/docs/pack/HELP-FRAGMENT.md` line 45.
- **Contract:** V3 §28.2.4 says `project-template/docs/pack/HELP-FRAGMENT.md` includes `HELP-FRAGMENT-TRACKER.md` from `project-template/docs/pack/` (sibling-file include in the client tree).
- **Observation:** The placeholder line in the client fragment reads "[Included from `HELP-FRAGMENT-TRACKER.md` in this directory via `pack-help.sh`.]" while the pack-side fragment uses "[Included from `HELP-FRAGMENT-TRACKER.md` at pack root via `pack-help.sh`.]". The awk regex in `scripts/pack-help.sh` matches `^\[Included from `HELP-FRAGMENT-TRACKER\.md`` — both wordings match the prefix-anchored pattern, so behaviour is correct. This is documentation-quality only.
- **Action:** Optional — leave as is; the wording disambiguates the two surfaces helpfully. Flag only because a future maintainer changing the pattern in `pack-help.sh` should know the trailing text differs by surface.

### F3 — BD-075 — BACKLOG File/Symbol names a script that was not created

- **Severity:** WARNING.
- **File:** `BACKLOG.md` line 261 (BD-075 entry).
- **Contract:** Pack rule "BACKLOG entries must accurately reflect shipped artefacts."
- **Observation:** BD-075 BACKLOG entry says `File/Symbol: scripts/pack-help.sh, scripts/lib/detect-surface.sh`. The actual shipped artefact is the addition of `detect_pack_surface()` to the existing `scripts/lib/detect.sh`; no `scripts/lib/detect-surface.sh` exists. The commit body describes this correctly ("`scripts/lib/detect.sh` — extended with `detect_pack_surface()`"); only the BACKLOG entry has the stale name.
- **Action:** Pack Chat should update BD-075's `File/Symbol:` line at status-flip time to `scripts/pack-help.sh, scripts/lib/detect.sh (extended with detect_pack_surface)`. No code change needed.

### F4 — BD-077 — commit-message asserts install behaviour that is not present at HEAD

- **Severity:** WARNING.
- **Commit:** `1d478d16f0d10` BD-077.
- **Contract:** Commit-message accuracy; downstream BD-080 unblocks this wiring.
- **Observation:** The BD-077 commit message states: "Body content is byte-equal between pack-root and client-tree at each per-CLI variant — the script invocation `bash scripts/pack-help.sh` resolves to the same target script in either tree because `init-project.sh` installs `scripts/lib/` + `scripts/pack-help.sh` into the client project at install time." This claim is not true at HEAD `1d478d1`:
  - `scripts/init-project.sh` stage_s5_scripts (lines 397–422) copies only from `$PACK/project-template/scripts/`. There is no `pack-help.sh` and no `lib/` subdirectory in `project-template/scripts/` (verified with `ls /Users/david/Developer/optiquity-ai-agent-config-pack/project-template/scripts/` — 15 build/test/format scripts, no `pack-help.sh`, no `lib/`).
  - As a consequence, on a project initialized today via `bash scripts/init-project.sh`, the per-CLI `pack-help` skill/command would be installed but its body's `!\`bash scripts/pack-help.sh\`` would fail at runtime because the target script is absent in the client tree. The pack-repo `pack-help.sh` works because it lives at the pack root.
  - Per BACKLOG, BD-080 ("`init-project.sh` extensions for v11 artifacts", Blockers: BD-076, BD-077, BD-063) is the BD that lands the install-time wiring. BD-080 has not yet shipped.
- **Action:** The runtime gap is correct sequencing — BD-080 closes it. The commit message is the only defect: it asserts the wiring as already-installed when it is in fact a downstream prerequisite. Note this in CHANGELOG when the v11.0 entry is written, or amend the commit-message ledger via the next BD's body. No code change needed at HEAD.

### F5 — BD-077 — `allowed-tools` frontmatter narrower than spec illustration

- **Severity:** NIT.
- **Files:** `.claude/skills/pack-help/SKILL.md`, `.codex/skills/pack-help/SKILL.md`, `project-template/.claude/skills/pack-help/SKILL.md`, `project-template/.codex/skills/pack-help/SKILL.md`.
- **Contract:** V3 §D.6 worked example body shape:
  ```
  ---
  name: pack-help
  description: Show all pack commands and colloquial mappings.
  ---
  ```
  no `allowed-tools` field is shown.
- **Observation:** All four Markdown skill files declare `allowed-tools: Bash`. This is *more* restrictive than the V3 example and is a reasonable hardening (the skill only invokes a Bash shell injection; no other tools needed). It is consistent with v10-baseline skill frontmatter conventions in this pack. Deviation from §D.6 is harmless and probably correct.
- **Action:** None unless an amendment-record is being kept of every textual deviation from V3 worked-example bodies; in that case, mention in the Addendum row.

---

## Contract verification summary

| V3 §28.2 contract | Status | Evidence |
|---|---|---|
| §28.2.1 verb manifest | ✓ | Pack-side fragment lists pack-startup, pack-help, pack-architect/-planner/-reviewer/-docs-researcher, validate-pack, pack tracker × 7, pack help. Client-side fragment lists pm-startup, init-project, migrate-v9-to-v10, add-capability, merge helpers, agent-run, pack tracker × 7, pack help. |
| §28.2.3 LCD shell verb | ✓ | `scripts/pack-help.sh` (134 lines) auto-detects surface via `detect_pack_surface`, accepts `--surface` and `--root` flags, prints verb manifest. |
| §28.2.3 surface detection | ✓ | `detect_pack_surface()` in `scripts/lib/detect.sh` honours BACKLOG.md at root or under `docs/project/`; flips on `^\*\*BD-` vs `^\*\*TD-`; mixed → ambiguous; missing → ambiguous. All five cases tested. |
| §28.2.3 per-CLI implementation table | ✓ | Claude Markdown skill, Codex Markdown skill (per V3 §7.1.1 fix; spec-text says `.codex/skills/pack-help/SKILL.md`), Gemini TOML command. |
| §28.2.4 per-surface content split | ✓ | Pack repo reads `HELP-FRAGMENT-PACK.md`; client reads `docs/pack/HELP-FRAGMENT.md`; both inline `HELP-FRAGMENT-TRACKER.md` from their own tree. |
| §28.2.4 sibling-include via awk resolver | ✓ | `pack-help.sh` `emit_fragment` awk script replaces the placeholder line with the tracker fragment body in place. Test 2.5 verifies surrounding lines are preserved. |
| §28.2.4 byte-identity (canonical → mirror) | ✓ | `diff HELP-FRAGMENT-TRACKER.md project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` clean. |
| §28.2.7 fragment shape | ✓ | Both fragments follow the documented structure (H1 header, `## <surface> commands`, `## Tracker commands (v11+)` placeholder, `## See also`). |
| §D.6 Claude `/pack-help` worked example | ✓ | Body `!\`bash scripts/pack-help.sh\`` matches §D.6. `allowed-tools: Bash` is an additive narrowing; see F5. |
| §D.7 Gemini `/pack-help` worked example | ✓ | TOML uses `prompt = """..!{bash scripts/pack-help.sh}.."""`, `description = "..."`. Matches §D.7 except the example body included slightly different wrapper prose; the shipped wording is consistent. |
| §I.1 new-file inventory | ✓ | All four BD-076 files + six BD-077 files + the BD-075 script + extension to `scripts/lib/detect.sh` are present at the §I.1-listed paths. |
| §I.4 trinity-propagation matrix | ✓ | Pack-side per-CLI trio + client-side per-CLI trio, file-wise; shared fragment via canonical-mirror. |

---

## Extension-point soundness for the next batch

### BD-088 (customization-preservation algorithm)

- BD-088 supplies the library `scripts/lib/customization-preserve.sh` consumed by both `init-project.sh --update` (BD-080) and `migrate-v10-to-v11.sh` (BD-085).
- The BD-076/077 file set adds new artefact paths the customization-preservation algorithm must classify: `HELP-FRAGMENT-PACK.md`, `HELP-FRAGMENT-TRACKER.md`, `project-template/docs/pack/HELP-FRAGMENT.md`, `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`, `.claude/skills/pack-help/SKILL.md`, `.codex/skills/pack-help/SKILL.md`, `.gemini/commands/pack-help.toml` (× both surfaces).
- **Soundness:** the per-CLI pack-help files are pack-shipped-only (no project customization expected) — they fit the "always overwrite from canonical" disposition cleanly, parallel to the existing pack-startup / pm-startup skills. The client-side `HELP-FRAGMENT.md` is intended to be project-edited (per §28.2.4 "client-surface verb list — PM Chat reads"); BD-088 will need to recognise it as MERGE-class. The client-side `HELP-FRAGMENT-TRACKER.md` is byte-identity-required from canonical, so it is OVERWRITE-class. No new disposition primitive is required; existing customization-preserve disposition vocabulary handles all three.

### BD-091 (BD-042 doc relocation)

- BD-091 relocates `METHODOLOGY.md`, `PROMPT-TEMPLATES.md`, `PM-CHAT.md`, `PLATFORM-SKILLS.md`, `PACK-FEEDBACK.md` to `project-template/docs/pack/`.
- **Soundness:** BD-076 already places `HELP-FRAGMENT.md` and `HELP-FRAGMENT-TRACKER.md` under `project-template/docs/pack/`. The relocated docs and the help fragments will coexist in the same directory; no path collision (the help fragments are uniquely named).
- One follow-on note: BD-091's relocated `PM-CHAT.md` will be the file that BD-077 / BD-081 / Addendum-4 §5.4 add the "Routing the issue-tracking auditor" section to. Sequencing currently: BD-091 → adds the docs to docs/pack/ → BD-076 has already created sibling files in the same directory → no conflict.

### BD-080 (init-project.sh v11 extensions)

- BD-080 must do five things on the new artefact set:
  1. Copy `pack-help.sh` and `lib/detect.sh` (with `detect_pack_surface`) into `<target>/scripts/` and `<target>/scripts/lib/` respectively. Currently `project-template/scripts/` ships neither file; BD-080 either (a) seeds them under `project-template/scripts/` so stage_s5 picks them up automatically, or (b) adds explicit copy lines in stage_s5 to read from pack-root `scripts/` for these two files.
  2. Copy `HELP-FRAGMENT.md` to `<target>/docs/pack/` (already covered by stage_s6_docs_pack `*.md` glob).
  3. Copy `HELP-FRAGMENT-TRACKER.md` from pack-root canonical to `<target>/docs/pack/` (this is *not* the same as the project-template mirror — per V3 §28.2.4 the pack-root is canonical, the project-template/docs/pack/HELP-FRAGMENT-TRACKER.md is the byte-identical mirror).
  4. Install per-CLI `pack-help` skills and command. Mechanism: extend stage_s4 (skills) and stage_s3 (configs / commands) to include the new pack-help directories.
  5. Update fixture `scripts/tests/fixtures/init-project-output/` if one is asserted on (none in the current test list, so no fixture-regen burden today).
- **Soundness:** No interface changes required from BD-076/077; BD-080 is purely additive. The BD-077 commit-message claim (F4) gets satisfied at this BD.

### BD-082 (validate-pack Checks 21–24)

- BD-082's four checks (per §28.2.5) map cleanly to current artefacts:
  - Check 21 — per-CLI parity: 6-file presence + same-target invocation. All six files exist; all six invoke `scripts/pack-help.sh`. **Will pass at land.**
  - Check 22 — help-fragment freshness against external doc verb references: the new fragments name verbs that PACK-CHAT.md / PM-CHAT.md / QUICKSTART.md / OPTIONAL-FEATURES.md / INSTALL-PROCEDURES.md may also name. The freshness check is well-defined with the current fragment set; adding the Addendum-4 §2.8 rows later requires re-running Check 22 after each BD-107/109/110 ship.
  - Check 23 — help-fragment completeness: every top-level executable in `scripts/` should appear in `HELP-FRAGMENT*.md` unless flagged. BD-082 will need to enumerate `scripts/` at land and check; current `HELP-FRAGMENT-PACK.md` lists `validate-pack.py` (line 35) and the test runner shape (line 36) and `pack help` (line 37); it does NOT name `init-project.sh`, `migrate-v9-to-v10.sh`, `add-capability.sh`, `merge-platform-skills.py`, `merge-trinity.py` — those are client-surface verbs and live in the client fragment. Per the per-surface split contract (§28.2.4), Check 23 must scope by surface (a verb only appears in the surface that ships it). The current fragment content is consistent with that scoping; Check 23 just needs to honour it.
  - Check 24 — shared-fragment byte-identity: trivially passes today.
- **Soundness:** all four BD-082 checks have unambiguous fail/pass semantics against the current fragment + per-CLI file set.

### BD-085 (migrate-v10-to-v11.sh)

- BD-085 must apply the same install steps as BD-080, plus apply Trinity addenda from BD-081. Current artefact set is migrator-friendly: all per-CLI files are net-additions (no existing v10 file is touched), and the two top-level fragments are net-new files. The shared tracker fragment lives at pack root + client mirror — straightforward to install.

### BD-081 (Trinity addenda)

- BD-081 adds one-line "Pack commands" reference + one-line "Recommended first action" to the 6 trinity files (3 pack + 3 project-template). At HEAD, none of the 6 trinity files mentions `pack help` or `/pack-help` (verified with `grep -rn "HELP-FRAGMENT\|pack-help" /...{CLAUDE,AGENTS,GEMINI}.md` returning empty). Net-additive change; no existing rule conflicts.

### BD-078 / BD-079 (validate-pack additions for tracker.toml + recommendation-state)

- Independent of BD-076/077 surface; no extension-point issue.

### BD-089 (customization-detection regression guard)

- Independent of help-surface; no extension-point issue.

---

## Closing line

**Verdict: GO-WITH-FIXES.** All three commits implement V3 §28.2 / D-20 / §D.6 / §D.7 / §I.1 / §I.4 correctly, the test suite passes 17/17, validate-pack stays green, byte-identity of the shared fragment holds, and trinity parity holds across the six per-CLI files. The fixes (F3 BACKLOG file-name correction, F4 commit-message accuracy note about BD-080 wiring, F1 deferred-row reconciliation against Addendum 4 §2.8) are documentation-level and do not block downstream BDs (BD-080, BD-081, BD-082, BD-085, BD-088, BD-091) from proceeding on the current code. The next batch can be scheduled.
