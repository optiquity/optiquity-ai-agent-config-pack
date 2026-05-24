# IMPL-REPORT — BD-173 Batch 19c Commit H.14 (with Option C absorption)

**Branch:** `v11-dev`
**Base HEAD:** `41041a673e4b0f63c310609d27afa257edb0a135` (H.12 commit; Guardrail 3 scope expansion).
**Worktree HEAD at report time:** `a9d593f2680c708fd8cd762c09dc3d123ffefec8` (no agent commits per pack workflow rule; all changes in working tree).
**Architect contract:** `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` §1.1-§1.12 + §1.6 + §1.9 + §1.11.
**Planner spec:** `maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19C.md` §H.14 (lines 639-693).

**Absorption pass (added 2026-05-24):** Pack Chat (with user direction)
triaged the §7.2 audit-vocabulary-gap discovery as **Option C — hybrid**
(allowlist legitimate audit-vocabulary-gap basenames + fix the real
LEAK CLASS C catches). This commit now lands clean at HEAD with 43/43
checks PASSing; the §7 discovery is transitioned from "STOP-AND-REPORT"
to "absorbed per Pack Chat (C) triage". Net deltas appended below in
§2.6, §2.7, §3.6, §6 (refreshed), §7.2 (status transitioned), §7.2.3.

---

## §1 Scope

Per PLAN H.14 and ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md §1, this commit
implements **Guardrail 1 — Check 43 (project-side bare cross-reference
scanner)**. New CI check that walks the client-installed surface
(per `_iter_client_installed_files()` from H.12) and flags bare
backtick-delimited filename refs whose basename resolves into pack-only
territory or to a non-client-installed `supporting-docs/` file.

Implementation surface (H.14 main pass):

1. `scripts/validate-pack.py` — new check function + 4 constants + 1 alias
   helper (~430 lines added between Check 40 and Check 41).
2. `scripts/tests/test-validate-pack-check-43.sh` — 7-group test harness
   following the structural pattern of `test-validate-pack-check-40.sh`
   (~24 KB, executable mode preserved).
3. `scripts/tests/fixtures/project-side-refs/` — 13 fixture files
   (7 FAIL + 5 PASS + 1 README) per §1.10 enumeration verbatim.
4. `.github/workflows/validate-pack.yml` — 3-line YAML block adding the
   per-check test invocation after Check 42's wiring.
5. Manifest regen — no drift in H.14 main pass (scripts/validate-pack.py
   and scripts/tests/ are not client-installed; rebuild produced no SHA
   change).

Additional surface (Option C absorption pass, added 2026-05-24):

6. `scripts/validate-pack.py` — `_CHECK_43_ALLOWLIST` extended with 29
   audit-vocabulary-gap legitimate entries[^count] (basename → one-line
   rationale per Check 40 §6.5 self-documenting convention).

[^count]: The H.14 commit message (`a6bd91d`) records "30/61" for these
    counts. The authoritative counts are **29 absorption entries** and
    **60 total allowlist entries** post-absorption, as verified by the
    §2.6 sub-class table sum (2+3+8+5+1+7+3 = 29) and reflected
    throughout this corrected narrative. The commit message is
    immutable in git history; this footnote records the discrepancy
    for the audit trail. (See N1+N2 H.14 INLINE reviewer fix,
    2026-05-24.)
7. `supporting-docs/METHODOLOGY.md` — 4 LEAK CLASS C rewrites at lines
   L14, L53 (was L54), L386 (was L387), L1624 (was L1625) per §1.14
   remediation pattern (one Cat A drop + three anchor-phrase rewrites).
8. `supporting-docs/INSTALL-PROCEDURES.md` — 1 LEAK CLASS C rewrite at
   L236 (qualified `supporting-docs/MIGRATION-v9-to-v10.md` cite gets
   "in the pack repo" anchor phrase inline).
9. `project-template/scripts/bootstrap.sh` — 1 LEAK CLASS C rewrite at
   L49 (qualified `supporting-docs/SETUP-NEW.md` cite gets "in the pack
   repo" anchor phrase inline). NOTE: this site was tracked in H.14
   §7.2.1 as the 5th SETUP-NEW.md catch (the H.14 reporter recorded
   the location as "INSTALL-PROCEDURES.md line ?" with uncertainty;
   actual location is bootstrap.sh:49).
10. `test-fixtures/manifest.txt` — RC9 regen produces drift this pass
    because supporting-docs/ + project-template/scripts/ are
    client-installed surfaces. Manifest staged alongside the absorption
    edits in the same commit per BD-176.

---

## §2 Edits applied

### 2.1 `scripts/validate-pack.py` — new check function + constants

**Position:** between Check 40 (`check_bare_pack_ops_refs`) end at L5069
and Check 41's section header at L5072 (now ~L5495 after insertion).
Function `_check_43_context_has_anchor` is appended after the main
function definition.

**Constants added (verbatim per §1.4 + §1.5 + §1.7 + §1.9):**

| Name | Purpose |
|---|---|
| `_CHECK_43_ALLOWLIST` | 31-entry dict mapping basename → rationale (§1.4) |
| `_CHECK_43_ANCHOR_PHRASES` | Alias for `_CHECK_40_ANCHOR_PHRASES` (§1.5) |
| `_CHECK_43_ANCHOR_WINDOW` | Alias for `_CHECK_40_ANCHOR_WINDOW` (= 2) |
| `_CHECK_43_MIRROR_SKIP_BASENAMES` | Tuple of 3 mirror filenames (`BACKLOG.md`, `CHANGELOG.md`, `IMPLEMENTATION-PLAN.md`) per §1.9 |
| `_CHECK_43_PACK_INTERNAL_PREFIXES` | Tuple `("maintenance-docs/", "pack-ops/")` per §1.7 |
| `_CHECK_43_PACK_OPS_CLIENT_INSTALLED` | Tuple `("pack-ops/HELP-FRAGMENT-TRACKER.md",)` per §1.7 |

**Allowlist coverage (per §1.4 verbatim):** 31 entries with one-line
rationale per entry (Check 40 §6.5 self-documenting convention):

- Project-side trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`)
- Project-side README + LICENSE (3 entries)
- Cross-boundary product feature (`PACK-FEEDBACK.md`)
- Project-side methodology / install docs at `docs/pack/` (8 entries)
- Per-entry skeleton filename PATTERNS (3 entries: `BD-NNN.md`, `TD-NNN.md`, `phase-N.md`)
- Per-entry tree sibling skeleton files (3 entries: `_rules.md`, `_intro.md`, `_format.md`)
- Project-side mirrors (regenerated; 5 entries: `BACKLOG.md`, `CHANGELOG.md`, `IMPLEMENTATION-PLAN.md`, `STATUS.md`, `ARCHITECTURE.md`)
- Generated / opt-in / external files (4 entries: `tracker.toml`, `tracker.toml.example`, `id-map.json`, `MEMORY.md`)
- Standard project scripts (1 entry: `agent-run.sh`)

**Function body (`check_project_side_bare_internal_refs`):**

- Walks `_iter_client_installed_files()` per §1.2 (reuses H.12 helper).
- Extension filter applied per §1.2 (matches Check 40's
  `_CHECK_40_FILE_EXTS`).
- Mirror-skip exclusions applied per §1.9.
- Honors the Guardrail 2 per-line fence (`_has_per_line_fence` +
  `_build_fence_skip_lineset`) so fenced deny-list teaching content is
  exempt from class-test detection — per §1.12 "Catches only if line
  is OUTSIDE the Guardrail 2 per-line fence."
- For each non-fenced line, runs three detections in order:
  1. **Qualified `supporting-docs/<X>` detection** (§1.6 + LEAK CLASS C):
     pre-install-only FAIL if `<X>` not in client-install set.
  2. **Qualified `maintenance-docs/<X>` / `pack-ops/<X>` detection**
     (LEAK CLASS D + qualified pack-only path-prefix): pack-internal
     target FAIL (excluding client-installed `pack-ops/HELP-FRAGMENT-TRACKER.md`).
  3. **Bare-ref match** (P1+P2+P3+P5 via reused Check 40 regex): runs
     allowlist → anchor-phrase → same-dir → class-test resolution
     verdict (pack-internal target / pre-install-only / ambiguous /
     broken) per §1.7.
- All 4 FAIL classes per §1.7 covered; failure messages match the
  format from §1.8.

**Reuse (NO new regex):**

- `_build_basename_index()` (built once per Check 43 invocation per §1.3)
- `_strip_code_blocks()`
- `_CHECK_40_BARE_REF_PATTERN`
- `_CHECK_40_HYPERLINK_PATTERN`
- `_CHECK_40_FILE_EXTS`
- `_parse_client_installed_files()` (for supporting-docs/ subset rule)
- `_iter_client_installed_files()` (per H.12)
- `_has_per_line_fence()` + `_build_fence_skip_lineset()` (per H.13)

**Main check sequence wired** per §1.6 between
`check_client_installed_files()` (Check 41) and
`check_ci_workflow_wires_per_check_tests()` (Check 42), with comment
documenting the ordering rationale (Check 43 lands AFTER Check 41 so
the inventory-drift gate runs before Check 43's class-test gate).

### 2.2 `scripts/tests/test-validate-pack-check-43.sh` — new file

**7 test groups** per §1.10:

| Group | Tests | Coverage |
|---|---|---|
| Group 0 | 1 | Module import + Check 43 symbol registration (9 required symbols) |
| Group 1 | 4 sub-tests | `_CHECK_43_ALLOWLIST` non-empty + ≥25 entries + every entry has rationale + load-bearing §1.4 entries present (21-entry sub-set) |
| Group 2 | 4 sub-tests | `_iter_client_installed_files()` returns non-empty Path list + project-template/ entries + 5 explicit non-PT entries + deduplication |
| Group 3 | 5 sub-tests | `_check_43_context_has_anchor` smoke + alias identity to Check 40's set + "in the pack repo" + "post-install" anchors + no-anchor case |
| Group 4 | 9 synthetic tree tests | T1-T9 per §1.10 (pre-install MIGRATION FAIL, PACK-FEEDBACK PASS, ARCHITECTURE-V3.md pack-internal FAIL, AUDIT-USER-CURATION BD-175 self-leak FAIL, pack-ops/ qualified FAIL, anchor PASS, code-block PASS, .sh maintenance-docs/ qualified FAIL, _intro.md allowlist PASS) |
| Group 5 | 3 sub-tests | 13 fixture files present + count assertion + FAIL fixtures contain bare-ref or qualified tokens + PASS fixture count = 5 |
| Group 6 | 1 | End-to-end validate-pack.py exit-status — Check 43 ran + reports either clean (zero leaks) or "found leaks" diagnostic |

**Test script is executable** (chmod 0755) — required for CI wiring.

### 2.3 `scripts/tests/fixtures/project-side-refs/` — 13 new fixture files

Per §1.10 enumeration verbatim:

| Filename | Class | Expected verdict |
|---|---|---|
| `README.md` | docs | Test fixture documentation |
| `project-side-fail-per-entry-skeleton.md` | LEAK CLASS A (audit §1.19) | FAIL pack-internal target (`ARCHITECTURE-PER-ENTRY-SPLIT.md`) |
| `project-side-fail-architect-doc-cite.md` | LEAK CLASS A | FAIL pack-internal target (`ARCHITECTURE-V3.3-DELTA.md`) |
| `project-side-fail-detect-sh-comment.sh` | LEAK CLASS D (audit §2.5) | FAIL qualified `maintenance-docs/` path in shell comment |
| `project-side-fail-pmstartup-cite.md` | LEAK CLASS E (audit §1.10) | FAIL pack-internal target (`ARCHITECTURE-V3.md`) |
| `project-side-fail-pmchat-self-prompt.md` | LEAK CLASS C (audit §1.14) | FAIL qualified `supporting-docs/SETUP-NEW.md` pre-install-only |
| `project-side-fail-mcp-example.json` | LEAK CLASS C (audit §1.15) | FAIL qualified `supporting-docs/CLI-PM-SETUP.md` pre-install-only |
| `project-side-fail-audit-cite-in-skill.md` | LEAK CLASS F (audit §1.7.124) | FAIL pack-internal target (`AUDIT-USER-CURATION.md` — BD-175 self-leak) |
| `project-side-pass-pack-feedback.md` | Cross-boundary product feature | PASS allowlist (`PACK-FEEDBACK.md`) |
| `project-side-pass-allowlist-methodology.md` | Client-installed `supporting-docs/` | PASS allowlist (`METHODOLOGY.md`) |
| `project-side-pass-anchor-pack-repo.md` | "in the pack repo" anchor | PASS anchor-phrase exemption |
| `project-side-pass-same-dir-skeleton.md` | Per-entry skeleton sibling | PASS allowlist (`_intro.md` per-entry tree) |
| `project-side-pass-code-block.md` | Bare ref inside fenced code | PASS code-block stripping |

**Total: 13 fixture files (7 FAIL + 5 PASS + 1 README).** Verified by
`ls scripts/tests/fixtures/project-side-refs/ | wc -l = 13`.

### 2.4 `.github/workflows/validate-pack.yml` — 3-line wiring

Inserted AFTER Check 42 wiring (per §1.11 placement):

```yaml
      - name: validate-pack Check 43 tests (BD-173 H.14, V11 leak-sweep prevention, project-side bare cross-reference scanner)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-43.sh
```

Verification: Check 42 (`check_ci_workflow_wires_per_check_tests`) PASSes
with the new wiring — output now reports `10 per-check test file(s) on
disk; 10 workflow invocation(s) found; zero unwired tests` (previously
9/9 before this commit).

### 2.5 `test-fixtures/manifest.txt` — H.14 main pass: no drift; Option C absorption pass: drifts as expected

H.14 main pass: `scripts/validate-pack.py` and the new `scripts/tests/`
content are not in the client-installed fixture-affecting paths. Per
BD-176 manifest regen rule, the scripts/ change triggers the regen but
the manifest content is unchanged (the v11-* fixtures don't include
validate-pack.py or test scripts).

Option C absorption pass (2026-05-24): regen produces drift because
`supporting-docs/METHODOLOGY.md`, `supporting-docs/INSTALL-PROCEDURES.md`,
and `project-template/scripts/bootstrap.sh` are client-installed.
v11-realistic-ot, v11-flat-file, and v11-tracker-on SHAs update. v10-*
and existing-project-mid-dev rows unchanged.

Manifest disposition: regen ran via `bash test-fixtures/build.sh
--all --clean`; `git diff test-fixtures/manifest.txt` shows the
3-row drift (v11-realistic-ot, v11-flat-file, v11-tracker-on).
Manifest is staged for the absorption commit per BD-176.

### 2.6 `_CHECK_43_ALLOWLIST` extension (Option C, Class 1 absorption)

Per H.14 §7.2.2 Option A list, the `_CHECK_43_ALLOWLIST` constant in
`scripts/validate-pack.py` is extended by 29 audit-vocabulary-gap
legitimate entries. Each new entry carries a one-line rationale per
Check 40 §6.5 self-documenting convention. Entries are grouped by
class with section-header comments for readability.

**New entries (29 total)** — appended after the existing 31 H.14
entries — cover **78 catch-sites** in pre-absorption Check 43 output
(many basenames appear multiple times across the walked surface):

| Class | Count | Entries |
|---|---|---|
| Template placeholders (generated by pm-chat self-prompt) | 2 | `SETUP.md`, `AGENT_KICKOFF.md` |
| Generic basenames (ambiguous-by-design at meta-reference level) | 3 | `SKILL.md`, `config.toml`, `settings.json` |
| Agent prompt meta-references (3 candidates per agent) | 8 | `coder.md`, `architect.md`, `reviewer.md`, `planner.md`, `tester.md`, `auditor.md`, `docs-researcher.md`, `auditor-architecture.md` |
| Per-entry skeleton variants (extend phase-N.md / BD-NNN.md / TD-NNN.md) | 5 | `phase-N.M.md`, `phase-0.md`, `phase-NN.md`, `phase-35.md`, `TD-001.md` |
| Custom skill placeholder | 1 | `x-foo.md` |
| Legacy / generated filenames (no real file at HEAD; broken-ref-by-design) | 7 | `report.md`, `PROMPT-TEMPLATES.md`, `FEATURES.md`, `V10-DESIGN.md`, `MIGRATION-v9-to-v10.md`, `migrate-v9-to-v10.sh`, `migrate-vN-to-vM.sh` |
| Audit-methodology teaching examples (illustrative skill-doc content) | 3 | `user_repository.py`, `order_repository.py`, `inventory_repository.py` |

**Insertion point:** End of `_CHECK_43_ALLOWLIST` dict body, after the
existing `"agent-run.sh": "..."` entry. New entries grouped by class
with `# ──` section-header comments. Section-opening comment notes
this is the BD-173 H.14 Option C absorption follow-up.

**Allowlist size post-absorption:** 60 entries (31 H.14 original +
29 Option C additions).

**Verification:** Check 43 at HEAD goes from 78 bare-ref FAILs (caught
generic basenames / template placeholders / agent prompt meta-refs /
etc.) to zero bare-ref FAILs after this extension. Only the 6
qualified-prefix LEAK CLASS C catches remain — handled by §2.7.

### 2.7 LEAK CLASS C rewrites (Option C, Class 2 absorption)

Per H.14 §7.2.1 + §1.14 architect remediation pattern, the 6 real
LEAK CLASS C catches (qualified `supporting-docs/<X>` cites that
resolve to pre-install-only files) are rewritten. Each site preserves
the rule wording / paragraph intent and does NOT introduce new
pack-internal cites.

#### 2.7.1 `supporting-docs/METHODOLOGY.md:14` — Cat A drop

**BEFORE (L11-16):**
```
> **Single source of truth:** One copy of this file lives at
> `supporting-docs/METHODOLOGY.md` in the AI Agent Config Pack. Copy it to your project
> root during setup (copied to project root by `init-project.sh`; see
> `supporting-docs/SETUP-NEW.md` Step 3). Do not modify the pack's copy for
> project-specific needs — edit the project root copy instead and let it evolve with
> the project.
```

**AFTER (L11-15):**
```
> **Single source of truth:** One copy of this file lives at
> `supporting-docs/METHODOLOGY.md` in the pack repo. Copy it to your project
> root during setup (copied to project root by `init-project.sh`). Do not
> modify the pack's copy for project-specific needs — edit the project
> root copy instead and let it evolve with the project.
```

**Choice rationale:** Cat A drop — the `supporting-docs/SETUP-NEW.md`
Step 3 reference is redundant with the immediately-preceding `copied
to project root by init-project.sh` prose. Dropping it preserves
intent and additionally swaps "in the AI Agent Config Pack" → "in
the pack repo" (which is a canonical Check 43 anchor phrase per
§1.5 in case the methodology file or its cite-site evolves to need
the anchor exemption). One bonus: the `supporting-docs/METHODOLOGY.md`
self-reference on L12 is preserved (the file IS client-installed at
`docs/pack/METHODOLOGY.md`; the qualified ref is to its pre-install
source which is fine pre-install).

#### 2.7.2 `supporting-docs/METHODOLOGY.md:53` — anchor-phrase rewrite

**BEFORE (L52-56):**
```
> **Four PM chat options:** The PM chat can run as a Claude Desktop app project
> (setup — see `supporting-docs/SETUP-NEW.md` Step 10, Option A), a resumable
> Claude Code CLI session (Step 10, Option B), a Codex CLI session (Step 10,
> Option C), or a Gemini CLI session (Step 10, Option D). Daily CLI usage
> reference in `supporting-docs/CLI-PM-SETUP.md`.
```

**AFTER (L52-56):**
```
> **Four PM chat options:** The PM chat can run as a Claude Desktop app project
> (setup steps are in the pack repo at `supporting-docs/SETUP-NEW.md` Step 10,
> Option A), a resumable Claude Code CLI session (Step 10, Option B), a Codex
> CLI session (Step 10, Option C), or a Gemini CLI session (Step 10, Option D).
> Daily CLI usage reference in `supporting-docs/CLI-PM-SETUP.md`.
```

**Choice rationale:** Anchor-phrase rewrite per §1.5. The 4-option
listing is genuinely useful for the dual-surface reader (pre-install +
client-installed). The "in the pack repo" anchor phrase makes the
pack-as-product context explicit and exempts the qualified cite under
the Check 43 anchor-phrase tier. (The `supporting-docs/CLI-PM-SETUP.md`
cite on L56 was already anchor-exempt by accident-of-prose — L57 carries
"in the project" which falls within the ±2-line window for L56.)

#### 2.7.3 `supporting-docs/METHODOLOGY.md:386` — anchor-phrase rewrite

**BEFORE (L386-387):**
```
5. Set up the PM chat (`supporting-docs/SETUP-NEW.md` Step 10 — choose
   Claude Desktop, Claude Code CLI, Codex CLI, or Gemini CLI)
```

**AFTER (L386-388):**
```
5. Set up the PM chat — setup steps are in the pack repo at
   `supporting-docs/SETUP-NEW.md` Step 10 (choose Claude Desktop,
   Claude Code CLI, Codex CLI, or Gemini CLI)
```

**Choice rationale:** Anchor-phrase rewrite. Step in a numbered
checklist; the SETUP-NEW.md cite is genuinely useful for the
pre-install reader walking through new-project setup. Anchor phrase
"in the pack repo" injected inline.

#### 2.7.4 `supporting-docs/METHODOLOGY.md:1624` — anchor-phrase rewrite

**BEFORE (L1620-1625):**
```
- [ ] Run `"$PACK/scripts/init-project.sh" .` from the project root.
      The script previews every operation, asks for explicit
      confirmation, and on `y` executes eleven stages (S0..S10) that
      copy template files, distribute skills, set permissions, run
      bootstrap, and emit the PM chat kickoff prompt. See
      `supporting-docs/SETUP-NEW.md` Step 3 for the full procedure.
```

**AFTER (L1620-1626):**
```
- [ ] Run `"$PACK/scripts/init-project.sh" .` from the project root.
      The script previews every operation, asks for explicit
      confirmation, and on `y` executes eleven stages (S0..S10) that
      copy template files, distribute skills, set permissions, run
      bootstrap, and emit the PM chat kickoff prompt. The full
      procedure is documented in the pack repo at
      `supporting-docs/SETUP-NEW.md` Step 3.
```

**Choice rationale:** Anchor-phrase rewrite. New Project Checklist
appendix; cite is informational for the new-project setup reader.
Anchor "in the pack repo" injected inline.

#### 2.7.5 `supporting-docs/INSTALL-PROCEDURES.md:236` — anchor-phrase rewrite

**BEFORE (L231-236):**
```
> `MIGRATION-v10-to-v11.md`. Procedure 5-C is retained here as
> historical documentation only; clients still on v9.x should
> reach out to the pack maintainer for migration guidance, or
> recover the legacy migrator from history with
> `git -C "$PACK" checkout v10 -- scripts/migrate-v9-to-v10.sh
> supporting-docs/MIGRATION-v9-to-v10.md`.
```

**AFTER (L231-236):**
```
> `MIGRATION-v10-to-v11.md`. Procedure 5-C is retained here as
> historical documentation only; clients still on v9.x should
> reach out to the pack maintainer for migration guidance, or
> recover the legacy migrator from history in the pack repo with
> `git -C "$PACK" checkout v10 -- scripts/migrate-v9-to-v10.sh
> supporting-docs/MIGRATION-v9-to-v10.md`.
```

**Choice rationale:** Anchor-phrase rewrite. The `git -C "$PACK"
checkout v10 -- ...` command is a literal command argument list and
the `supporting-docs/MIGRATION-v9-to-v10.md` path is REQUIRED for the
git command to actually recover the legacy migration doc — so Cat A
drop is not viable here. Anchor phrase "in the pack repo" added
inline (4 words) to make pack-as-product cite intent explicit.

#### 2.7.6 `project-template/scripts/bootstrap.sh:49` — anchor-phrase rewrite

**BEFORE (L46-51):**
```
# Skills are distributed at project creation time from the pack's
# project-template/skills/ directory directly into .claude/skills/,
# .codex/skills/, and .gemini/skills/ by `init-project.sh` (see
# supporting-docs/SETUP-NEW.md Step 3).
# Once committed to git they do not need to be redistributed here.
# To update skills after a pack version upgrade, see the migration guide.
```

**AFTER (L46-51):**
```
# Skills are distributed at project creation time from the pack's
# project-template/skills/ directory directly into .claude/skills/,
# .codex/skills/, and .gemini/skills/ by `init-project.sh` (see
# in the pack repo: supporting-docs/SETUP-NEW.md Step 3).
# Once committed to git they do not need to be redistributed here.
# To update skills after a pack version upgrade, see the migration guide.
```

**Choice rationale:** Anchor-phrase rewrite. Comment-only cite in a
script that ships to clients. The SETUP-NEW.md Step 3 documentation
is genuinely useful for the comment's intent (explaining why skills
aren't redistributed at bootstrap). Anchor "in the pack repo" added
inline.

**Site discovery note:** H.14 §7.2.1 listed 5 SETUP-NEW.md catches
with locations "METHODOLOGY.md lines 14, 54, 387, 1625; INSTALL-
PROCEDURES.md line ?" — the H.14 reporter recorded the 5th location
with explicit uncertainty (?). The actual 5th location is
`project-template/scripts/bootstrap.sh:49`, not INSTALL-PROCEDURES.md.
The MIGRATION-v9-to-v10.md catch on INSTALL-PROCEDURES.md:236 was a
separate LEAK CLASS C site the H.14 reporter classified as
"audit-vocabulary-gap: legacy migration doc cite" but it's actually
a qualified-prefix catch (the qualified detection doesn't consult
the allowlist), so it required a rewrite rather than allowlisting.

---

## §3 Verification

### 3.1 validate-pack.py PASS at HEAD — **PASS after Option C absorption**

H.14 main pass (initial state):
```
$ python3 scripts/validate-pack.py
... (43 checks run)
FAILED — 84 issue(s) found
```

The H.14 main pass left validate-pack.py in a failing-at-HEAD state
because Check 43 caught 84 leaks the architect spec did not
anticipate — STOP-AND-REPORT triggered per the prompt's explicit
instruction. See §7.2 for the full disposition (now resolved by the
Option C absorption pass).

Option C absorption pass (final state):
```
$ python3 scripts/validate-pack.py
... (43 checks run)
PASSED — all checks clean
```

After 29 audit-vocabulary-gap allowlist additions (Class 1; 29
basenames covering 78 catch-sites) + 6 LEAK CLASS C rewrites (Class 2),
Check 43 reports:

```
── Check 43: Project-side bare cross-reference scanner (BD-173) ──
  OK: Check 43 — 152 project-side / client-installed file(s) walked;
  zero pack-internal bare cross-references (578 allowlist-exempt +
  18 anchor-phrase-exempt + 12 same-dir-legit + 140 client-installed-
  legit + 585 fenced-line(s) accepted)
```

All 43 checks PASS at HEAD. Check 43's accepted-hit counters
(allowlist 578, anchor-phrase 18, same-dir 12, client-installed-legit
140, fenced 585) verify the absorption: 78 catch-sites (29 distinct
basenames) absorbed via allowlist tier; 6 absorbed via anchor-phrase
tier; 0 catches remain.

### 3.2 Check 43 test script — all 7 groups PASS (post-absorption)

```
$ bash scripts/tests/test-validate-pack-check-43.sh
=== Group 0: Module import + Check 43 symbol registration ===
  PASS validate-pack.py imports + Check 43 symbols registered
=== Group 1: _CHECK_43_ALLOWLIST sanity ===
  PASS _CHECK_43_ALLOWLIST shape + content sanity
=== Group 2: _iter_client_installed_files() base-set verification ===
  PASS _iter_client_installed_files() returns base set per §3.1
=== Group 3: _check_43_context_has_anchor smoke test ===
  PASS _check_43_context_has_anchor smoke + aliasing verified
=== Group 4: End-to-end synthetic-tree tests (T1-T9 per §1.10) ===
  PASS End-to-end synthetic-tree tests T1-T9 (PASS / FAIL / exemption / code-block)
=== Group 5: Static fixture file sanity ===
  PASS Static fixture files present (13 total) + parseable + regex-shaped
=== Group 6: End-to-end validate-pack.py exit-status on HEAD ===
  PASS validate-pack.py exits 0; Check 43 runs and reports clean

=== Summary ===
  PASS: 7
  FAIL: 0
```

**All 7 groups PASS** (post-Option-C-absorption). The function,
allowlist (now 60 entries), helper-alias identity, synthetic-tree
fixtures, static-fixture file sanity, AND end-to-end validate-pack.py
exit-status all verify cleanly.

Group 6's HEAD exit-status PASS confirms that the absorption pass
fully closes the audit-vocabulary-gap discovery; Check 43 no longer
catches anything at HEAD.

### 3.3 Check 42 test script — all 4 groups PASS (post-absorption)

```
$ bash scripts/tests/test-validate-pack-check-42.sh
  PASS validate-pack.py imports + Check 42 symbol registered
  PASS real-state-at-HEAD Check 42 PASSes + self-referential closure
       holds (test-42 file + wiring both present)
  PASS Synthetic PASS/FAIL tests (T1-T9 ...)
  PASS validate-pack.py exits 0; Check 42 runs and reports clean

=== Summary ===
  PASS: 4
  FAIL: 0
```

**All 4 groups PASS** (post-Option-C-absorption). Check 42's own
contract (CI workflow wires all per-check test files) is satisfied —
its output reports `10 per-check test file(s) on disk; 10 workflow
invocation(s) found; zero unwired tests`. The Group 3 e2e exit-status
PASSes after the absorption-pass cleared Check 43's HEAD findings.

### 3.4 Fixture count + manifest disposition

```
$ ls scripts/tests/fixtures/project-side-refs/ | wc -l
13

$ bash test-fixtures/build.sh --all --clean
... (6 fixtures rebuilt successfully)
```

H.14 main pass: `git diff --stat test-fixtures/manifest.txt` was
clean (no drift; scripts/ changes are not in the fixture-row-
affecting set).

Option C absorption pass: manifest drifts because
`supporting-docs/METHODOLOGY.md`, `supporting-docs/INSTALL-PROCEDURES.md`,
and `project-template/scripts/bootstrap.sh` are all client-installed
fixture-affecting paths. v11-realistic-ot / v11-flat-file / v11-tracker-on
SHAs update; v10-* and existing-project-mid-dev unchanged:

```
$ git diff test-fixtures/manifest.txt
- v11-realistic-ot  888bebbca232e4412306ee6ad14a7bd746f08999
- v11-flat-file  a647efa1e98695d22994fd9d95eec493731c855f
- v11-tracker-on  37fcd72a5fcbd9a5347a0988500888d0e4228e5c
+ v11-realistic-ot  b7360537daab9596d1ae3b31bd14203b74d8bb7a
+ v11-flat-file  842cb9621125850425449088947c6630cd2088ef
+ v11-tracker-on  2829366c328d307df5540208817e538ee9979307
```

Manifest is staged for the absorption commit per BD-176.

13 fixture files present (exact count matches §1.10 enumeration).

### 3.5 Module + symbol registration check

```python
>>> mod = ... # load validate-pack.py
>>> mod._CHECK_43_ALLOWLIST  # 60 entries (31 H.14 original + 29 Option C absorption)
>>> mod._CHECK_43_ANCHOR_PHRASES is mod._CHECK_40_ANCHOR_PHRASES  # True (alias)
>>> mod._CHECK_43_ANCHOR_WINDOW  # 2 (alias)
>>> mod.check_project_side_bare_internal_refs  # function exists
>>> mod._check_43_context_has_anchor  # function exists
```

All required symbols registered. Allowlist now has 60 entries (31
H.14 original — §1.4 verbatim — plus 29 Option C absorption entries
covering audit-vocabulary-gap legitimates per §2.6 above; 29
basenames cover 78 catch-sites in the pre-absorption Check 43 output).

### 3.6 End-to-end PASS state (post-absorption)

Final verification at HEAD post-absorption:

```
$ python3 scripts/validate-pack.py
... (43 checks run, all PASS)
PASSED — all checks clean

$ bash scripts/tests/test-validate-pack-check-43.sh
... (7 groups PASS)
All tests passed.

$ bash scripts/tests/test-validate-pack-check-42.sh
... (4 groups PASS)
All tests passed.

$ git status (relevant lines)
modified:   .github/workflows/validate-pack.yml
modified:   project-template/scripts/bootstrap.sh
modified:   scripts/validate-pack.py
modified:   supporting-docs/INSTALL-PROCEDURES.md
modified:   supporting-docs/METHODOLOGY.md
modified:   test-fixtures/manifest.txt
Untracked:
  maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.14.md
  scripts/tests/fixtures/project-side-refs/
  scripts/tests/test-validate-pack-check-43.sh
```

Commit-ready: H.14 commit now lands clean (no failing-CI posture).

---

## §4 Cross-walk verification (§1.12)

The cross-walk table in §1.12 predicts the 7 leak classes (36 total
leaks) Check 43 catches:

| Leak class | Predicted catch | Confirmed at HEAD |
|---|---|---|
| 24 per-entry skeleton bare `ARCHITECTURE-*` cites | basename resolves to `maintenance-docs/...` | N/A at HEAD — these were cleared by H.9/H.10 leak sweeps before H.14 |
| 2 `scripts/lib/detect.sh` `maintenance-docs/` cites | scripts/lib/detect.sh in walked set per §1.2 | N/A at HEAD — cleared by H.10 (Cat D detect.sh fixes) |
| 1 `PM-CHAT.md` `ARCHITECTURE-V3.3-DELTA.md` cite | basename resolves to `maintenance-docs/v11-research/` | N/A at HEAD — cleared by H.9/H.10 |
| 4 pm-startup cluster `ARCHITECTURE-V3.md §28.1.5` cites | basename resolves to `maintenance-docs/v11-research/ARCHITECTURE-V3.md` | N/A at HEAD — cleared |
| 3 pm-chat.md self-prompt `supporting-docs/SETUP*` cites | qualified-path-prefix detection | N/A at HEAD — cleared by H.11 |
| 1 `.mcp.json.example` `supporting-docs/CLI-PM-SETUP.md` cite | qualified-path detection | N/A at HEAD — cleared |
| 1 boundary-investigation `AUDIT-USER-CURATION.md` cite (BD-175 self-leak) | basename resolves to `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` | N/A at HEAD — cleared by H.10 Cat F |

**Status of the 36 architect-anticipated leaks:** All cleared by the
H.9-H.11 sweep + H.13 fence work that landed BEFORE H.14. Check 43
runs against the cleaned state.

**However:** Check 43 at HEAD catches **84 additional leaks** that the
architect-spec did NOT anticipate (audit-vocabulary-gap). See §7
"Out-of-scope confirmations + audit-vocabulary-gap awareness" below
for the full inventory and disposition request.

---

## §5 Cross-references

- **Architect contract:** `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md`
  §1.1 (function signature) + §1.2 (walked file set) + §1.3 (basename
  index reuse) + §1.4 (allowlist verbatim) + §1.5 (anchor-phrase
  aliases) + §1.6 (supporting-docs subset rule) + §1.7 (fail/pass
  conditions) + §1.8 (failure message format) + §1.9 (mirror-skip
  exclusions) + §1.10 (fixture test spec + 13-file enumeration) +
  §1.11 (CI YAML wiring) + §1.12 (cross-walk verification).
- **Planner spec:** `maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19C.md`
  §H.14 (lines 639-693): scope, files modified, edit spec, verification
  commands, RC9 manifest regen, per-commit reviewer, commit subject,
  PREFLIGHT line shape, ordering dependency.
- **Prior commits in batch (context):**
  - H.9 + H.10: Cat A-F leak sweep (`maintenance-docs/...`, `AUDIT-USER-CURATION.md` self-leak cleared)
  - H.11: pm-chat variant rewrites (3 pre-install supporting-docs/ template leaks cleared)
  - H.13: per-line fence (11 files fenced; 4 dual-surface additions)
  - H.12: Guardrail 3 scope expansion (`_iter_client_installed_files()` helper introduced; the helper Check 43 walks)
- **Reordered batch chain:** H.10 → H.11 → H.13 → H.12 → H.14 → H.15+
  (per 2026-05-24 reorder; `IMPLEMENTATION-REPORT-BD-173-Batch-19c-REORDER-H.12-H.13.md`).

---

## §6 Success criteria checklist

Per the original H.14 prompt + the Option C absorption-pass prompt:

| # | Criterion | Status |
|---|---|---|
| 1 | `check_project_side_bare_internal_refs()` function added per §1.1 | **PASS** — function defined; 9 required symbols registered |
| 2 | `_CHECK_43_ALLOWLIST` constant added (~30 entries) per §1.4 | **PASS** — 31 entries (H.14) + 29 absorption entries = 60 total with one-line rationale each |
| 3 | Anchor-phrase aliases added per §1.5 | **PASS** — `_CHECK_43_ANCHOR_PHRASES is _CHECK_40_ANCHOR_PHRASES`; window alias = 2 |
| 4 | Function wired into main check sequence per §1.6 | **PASS** — invoked after `check_client_installed_files()` and before `check_ci_workflow_wires_per_check_tests()` in `main()` |
| 5 | 13 fixture files created per §1.10 enumeration | **PASS** — 13 files (7 FAIL + 5 PASS + 1 README) verified by `ls \| wc -l` |
| 6 | `scripts/tests/test-validate-pack-check-43.sh` created per §1.10 (7 groups) | **PASS** — 7 groups (Group 0-6); executable bit preserved |
| 7 | CI workflow wiring added per §1.11 | **PASS** — 3-line YAML block inserted after Check 42 wiring at L184 |
| 8 | `python3 scripts/validate-pack.py` PASS at HEAD (43 checks; Check 43 returns zero leaks) | **PASS (post-absorption)** — Check 43 reports clean at HEAD; 43/43 checks PASS |
| 9 | `bash scripts/tests/test-validate-pack-check-43.sh` PASS (all 7 groups) | **PASS (post-absorption)** — all 7 groups PASS including Group 6 e2e |
| 10 | `bash scripts/tests/test-validate-pack-check-42.sh` PASS (recognizes new test file) | **PASS (post-absorption)** — all 4 groups PASS |
| 11 | Manifest regen handled per BD-176 (if no drift, no staging needed; if drift, stage) | **PASS** — drift produced in absorption pass (v11-* SHAs updated); manifest staged |
| 12 | IMPL-REPORT at `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.14.md` | **PASS** — this file |
| 13 | Option C Class 1 — `_CHECK_43_ALLOWLIST` extended with ~30 entries per §7.2.2 Option A list | **PASS** — 29 entries added per §2.6 (template placeholders, generic basenames, agent-prompt meta-refs, per-entry skeleton variants, custom skill placeholder, legacy/generated, audit-methodology examples); these 29 basenames cover 78 catch-sites in pre-absorption Check 43 output |
| 14 | Option C Class 2 — 5-6 real LEAK CLASS C catches fixed; SETUP-NEW.md cites removed without introducing new leaks | **PASS** — 6 sites rewritten per §2.7 (1 Cat A drop + 5 anchor-phrase rewrites); no new pack-internal cites introduced |
| 15 | Check 43 PASSes at HEAD with zero leaks | **PASS** — Check 43 reports clean; allowlist + anchor-phrase tiers cover all formerly-caught references |
| 16 | H.14 IMPL-REPORT updated to reflect absorbed mitigations | **PASS** — this update transitions §7.2 from "discovery flagged" to "discovery absorbed" |

**Net status:** 16 of 16 criteria PASS post-absorption. The H.14
implementation faithfully followed the architect spec; the §7.2
audit-vocabulary-gap discovery is now fully absorbed per Pack Chat's
Option C triage decision (allowlist additions + LEAK CLASS C
rewrites). H.14 commit lands clean.

---

## §7 Out-of-scope confirmations + audit-vocabulary-gap awareness

### 7.1 In-scope changes confirmation

All edits remained within the prompt-specified scope:

- `scripts/validate-pack.py` (modified — new function + constants)
- `scripts/tests/test-validate-pack-check-43.sh` (new file)
- `scripts/tests/fixtures/project-side-refs/` (new directory + 13 files)
- `.github/workflows/validate-pack.yml` (modified — 3-line wiring)
- `test-fixtures/manifest.txt` (no edit needed; rebuild produced no drift)
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.14.md` (new IMPL-REPORT)

NO out-of-scope edits applied. Specifically:

- NO `project-template/` or `supporting-docs/` file edits (forbidden
  per prompt — would risk leak-fix scope creep beyond H.14).
- NO fence-allowlisted-file edits (H.13's 12-entry list).
- NO new agent / skill / template additions.
- NO architecture-doc updates.

### 7.2 audit-vocabulary-gap discovery at HEAD — RESOLVED (absorbed per Pack Chat Option C triage)

**Status transition (2026-05-24):** The H.14 STOP-AND-REPORT
discovery is now fully absorbed per Pack Chat's Option C triage
decision (with user direction). See §2.6 + §2.7 for the absorption
edits; §3.1 + §3.2 + §3.3 + §3.6 for the post-absorption PASS
verification.

**Original discovery (H.14 main pass, pre-absorption):**

> "**CRITICAL — Cross-walk verification (§1.12).** ... If Check 43
> FAILs at HEAD, that's an audit-vocabulary-gap discovery — STOP and
> report (do not silently absorb; flag in §7)."

Check 43 at HEAD caught **84 leaks** the architect spec did NOT
anticipate. The architect predicted 36 catches (per §1.12 cross-walk)
— all of which were cleared by the H.9-H.13 sweep work. The 84 leaks
discovered at HEAD were a SEPARATE class.

#### 7.2.1 Failure-class breakdown

| Failure pattern | Count | Class |
|---|---|---|
| Bare `AGENT_KICKOFF.md` — broken ref (template placeholder; file is generated by pm-chat from inlined skeleton; not in pack repo) | 12 | Audit-vocabulary-gap: legitimate template placeholder |
| Bare `SETUP.md` — broken ref (template placeholder; generated by pm-chat self-prompt) | 10 | Audit-vocabulary-gap: legitimate template placeholder |
| Bare `SKILL.md` — ambiguous (collides across ~70 skills at 3 install dirs + pack-source) | 9 | Audit-vocabulary-gap: generic basename used as a meta-reference |
| Bare `coder.md` — ambiguous (3 candidates: claude/agents, gemini/agents, docs/pack/prompts) | 9 | Audit-vocabulary-gap: agent prompt name used as a meta-reference |
| Qualified `supporting-docs/SETUP-NEW.md` — pre-install-only (METHODOLOGY.md lines 14, 54, 387, 1625; INSTALL-PROCEDURES.md line ?) | 5 | Real LEAK CLASS C catch (audit-anticipated; pre-install reference outside fence) |
| Bare `reviewer.md` — ambiguous (3 candidates) | 5 | Audit-vocabulary-gap: agent prompt name meta-reference |
| Bare `architect.md` — ambiguous (3 candidates) | 5 | Audit-vocabulary-gap: agent prompt name meta-reference |
| Bare `MIGRATION-v9-to-v10.md` — broken ref | 3 | Audit-vocabulary-gap: legacy migration doc no longer in repo |
| Bare `tester.md` / `planner.md` — ambiguous (3 candidates each) | 4 | Audit-vocabulary-gap: agent prompt name meta-references |
| Bare `config.toml` — ambiguous (2 candidates) | 2 | Audit-vocabulary-gap: generic config basename |
| Bare `phase-N.M.md` / `phase-0.md` / `phase-35.md` / `TD-001.md` — broken refs | 5 | Audit-vocabulary-gap: per-entry skeleton template placeholders (similar to BD-NNN.md / TD-NNN.md / phase-N.md already on allowlist; `phase-N.M.M` variant + `phase-0` + numeric variants are NEW; `TD-001.md` is the specific instance the docs reference) |
| Bare `x-foo.md` — broken ref | 1 | Audit-vocabulary-gap: x-prefix custom skill placeholder example |
| Bare `V10-DESIGN.md` / `FEATURES.md` / `PROMPT-TEMPLATES.md` / `report.md` — broken refs | 4 | Audit-vocabulary-gap: legacy / generated / placeholder names |
| Bare `auditor.md` / `auditor-architecture.md` / `docs-researcher.md` — ambiguous | 3 | Audit-vocabulary-gap: agent prompt meta-references |
| Bare `migrate-v9-to-v10.sh` / `migrate-vN-to-vM.sh` — broken refs | 2 | Audit-vocabulary-gap: legacy migration / pattern-placeholder scripts |
| Bare `user_repository.py` / `order_repository.py` / `inventory_repository.py` — broken refs (audit-methodology skill teaching content) | 3 | Audit-vocabulary-gap: illustrative example code in teaching content |
| Bare `settings.json` — ambiguous (4 candidates including xcode/vscode companion templates) | 1 | Audit-vocabulary-gap: generic config basename used as meta-reference |
| Qualified `supporting-docs/MIGRATION-v9-to-v10.md` — pre-install-only | 1 | Audit-vocabulary-gap: legacy migration doc cite |

**Total: 84 failures, partitioned as:**
- **~5-6 real LEAK CLASS C catches:** `supporting-docs/SETUP-NEW.md` cites
  in `supporting-docs/METHODOLOGY.md` lines 14, 54, 387, 1625, and
  `supporting-docs/INSTALL-PROCEDURES.md` line X. These are outside
  the H.13 per-line fence (the fence covers lines 110-122 only, not
  these lines). **CORRECTNESS-AFFECTING.** Could be fixed by either
  (a) expanding the fence in METHODOLOGY.md, (b) rewriting these
  lines per the audit §1.14 LEAK CLASS C pattern, or (c) accepting
  them.
- **~78 audit-vocabulary-gap catch-sites (29 distinct basenames):**
  legitimate template placeholders / generic basenames / agent prompt
  meta-references / generated-file names / legacy migration docs.
  The architect did NOT anticipate these in the §1.4 allowlist scope.
  They fall into CLEAN AUDIT-VOCABULARY-GAP CLASS per the prompt's §7
  instruction.

#### 7.2.2 Recommended disposition (Pack Chat triage input)

Per the prompt's instruction to flag (not silently absorb), Pack Chat
must decide between:

**Option A — Audit-vocabulary-gap allowlist additions (NEW POQ):**
Open a new BD (e.g., BD-192) to extend `_CHECK_43_ALLOWLIST` to cover
the legitimate template placeholders and generic basenames:
- `SETUP.md` (template placeholder; generated by pm-chat self-prompt)
- `AGENT_KICKOFF.md` (template placeholder; generated by pm-chat self-prompt)
- `SKILL.md` (per-skill filename; ambiguous-by-design at the meta-reference level)
- Agent prompt names: `coder.md`, `architect.md`, `reviewer.md`,
  `planner.md`, `tester.md`, `auditor.md`, `docs-researcher.md`,
  `auditor-architecture.md` (ambiguous-by-design at the meta-reference level)
- Generic configs: `config.toml`, `settings.json`
- Phase / TD variants: `phase-N.M.md`, `phase-0.md`, `phase-NN.md`,
  `TD-001.md` (per-entry skeleton variants)
- Custom skill placeholder: `x-foo.md`
- Generated / legacy: `report.md`, `PROMPT-TEMPLATES.md`, `FEATURES.md`,
  `V10-DESIGN.md`, `MIGRATION-v9-to-v10.md`, `migrate-v9-to-v10.sh`,
  `migrate-vN-to-vM.sh`
- Audit-methodology teaching examples: `user_repository.py`,
  `order_repository.py`, `inventory_repository.py` (illustrative
  example code in the audit-methodology skill)

**Option B — Project-side leak-fix (qualified ref rewrites):**
Open a leak-fix commit that qualifies each ambiguous bare ref. This
is the architect-anticipated remediation per §1.7 failure message
format (suggests `qualify to one of...`). Higher-effort; touches
project-template/ and supporting-docs/ files; out of H.14 scope.

**Option C — Hybrid:** Adopt Option A allowlist additions for
genuine meta-references (template placeholders, agent prompt names,
ambiguous-by-design generics) AND apply leak-fix rewrites for the
5-6 real LEAK CLASS C catches (the `supporting-docs/SETUP-NEW.md`
references outside fence in METHODOLOGY.md / INSTALL-PROCEDURES.md).

**Recommendation:** Option C is the most defensible — preserves the
class-test semantic for genuine pack-only leaks AND admits the
audit-vocabulary-gap legitimates without project-side churn.

#### 7.2.3 Implementation posture for H.14 commit (RESOLVED — clean landing)

**Original recommendation (H.14 main pass):** land H.14 with
`python3 scripts/validate-pack.py` in FAILing state at HEAD,
surface the audit-vocabulary-gap to Pack Chat for triage, and
follow up with a B-line BD (Option A / B / C per Pack Chat
decision) within the same v11.0 release window.

**Actual resolution (Pack Chat triage, 2026-05-24):** Pack Chat
chose Option C — hybrid (allowlist 29 audit-vocabulary-gap legitimate
basenames covering 78 catch-sites + fix 6 real LEAK CLASS C catches).
Absorption landed in this same H.14 commit. H.14 now lands clean (no
failing-CI posture; no follow-up BD needed).

**Absorption summary:**

| Class | Action | Count | Detail |
|---|---|---|---|
| Class 1 (audit-vocabulary-gap legitimates) | `_CHECK_43_ALLOWLIST` extension | 29 new entries (covering 78 catch-sites) | Per §2.6; 7 sub-classes (template placeholders, generic basenames, agent-prompt meta-refs, per-entry skeleton variants, custom skill placeholder, legacy/generated, audit-methodology examples) |
| Class 2 (real LEAK CLASS C catches) | Cite rewrites | 6 sites | Per §2.7; 1 Cat A drop (METHODOLOGY.md L14) + 5 anchor-phrase rewrites (METHODOLOGY.md L53/L386/L1624, INSTALL-PROCEDURES.md L236, bootstrap.sh L49) |

**Site-discovery reconciliation:** H.14 §7.2.1 listed 5 SETUP-NEW.md
catches with locations "METHODOLOGY.md lines 14, 54, 387, 1625;
INSTALL-PROCEDURES.md line ?". The actual 5th SETUP-NEW.md site is
`project-template/scripts/bootstrap.sh:49`, NOT INSTALL-PROCEDURES.md.
The INSTALL-PROCEDURES.md catch at L236 is for `supporting-docs/MIGRATION-v9-to-v10.md`
(qualified-prefix), which H.14 §7.2.1 classified separately under
"qualified `supporting-docs/MIGRATION-v9-to-v10.md` — pre-install-only
(audit-vocabulary-gap: legacy migration doc cite)". The qualified-
prefix detection doesn't consult the allowlist, so this site needed
a rewrite rather than allowlisting — handled in §2.7.5.

### 7.3 Plan deviations

**Zero plan deviations from the architect contract or planner spec.**
All H.14 main-pass edits applied verbatim per ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md
§1.1-§1.12 and PLAN H.14 specifications. The audit-vocabulary-gap
discovery in §7.2 is NOT a plan deviation — it is a discovery the
plan did not anticipate; the Option C absorption pass implements the
Pack Chat triage decision and is documented in §2.6 + §2.7 + §7.2.3.

### 7.4 New POQs introduced

**Original POQ (H.14 main pass):** the audit-vocabulary-gap
allowlist scope question (Option A/B/C per §7.2.2).
**Disposition (RESOLVED — 2026-05-24):** Pack Chat (with user
direction) chose Option C (hybrid: allowlist 29 basenames covering
78 catch-sites + fix 6 LEAK CLASS C catches). Implemented per §2.6 +
§2.7. No outstanding POQs.

### 7.5 Boundary discipline check

H.14 main pass: all H.14 main-pass edits were to pack-side files
(`scripts/`, `.github/workflows/`, `maintenance-docs/`). The new
`scripts/tests/fixtures/project-side-refs/` directory is pack-side
(test fixture content), NOT project-side (despite the name reflecting
that the fixtures EXERCISE project-side Check 43 logic). No
project-side SSOT investigation was required for this pass.

Option C absorption pass: edits touch **dual-surface and project-side
files** (per the SSOT-investigation pre-flight in the
boundary-investigation skill):

| File | Surface | SSOT investigated | Rationale |
|---|---|---|---|
| `supporting-docs/METHODOLOGY.md` | Dual-surface (pre-install pack-repo + client-installed `docs/pack/METHODOLOGY.md`) | The file IS the project-side SSOT for the methodology concept; pre-install pack-repo cite to `supporting-docs/SETUP-NEW.md` Step 3/10 is the offending reference at client install where SETUP-NEW.md doesn't exist | Rewrites either drop the cite or wrap it in "in the pack repo" anchor to make pack-as-product context explicit |
| `supporting-docs/INSTALL-PROCEDURES.md` | Dual-surface (pre-install pack-repo + client-installed `docs/pack/INSTALL-PROCEDURES.md`) | The file IS the project-side SSOT for install procedures; historical Procedure 5-C documents the v9→v10 migration; the `git checkout v10 --` command arguments preserve the qualified path | Anchor "in the pack repo" injected inline at L236 |
| `project-template/scripts/bootstrap.sh` | Project-side (installs at client `scripts/bootstrap.sh`) | Comment-only cite explaining init-project.sh skill distribution; `supporting-docs/SETUP-NEW.md` Step 3 documents the procedure | Anchor "in the pack repo" injected inline at L49 |
| `scripts/validate-pack.py` | Pack-side (validate-pack tooling; not client-installed) | The allowlist constant is the project-side SSOT for what's exempt from Check 43; Option A absorption list per H.14 §7.2.2 | 29 new entries with one-line rationale per Check 40 §6.5 convention |

No pack-internal cites introduced in any rewrite. All cite-removals
preserve rule wording / paragraph intent. The METHODOLOGY.md /
INSTALL-PROCEDURES.md rewrites add the canonical "in the pack repo"
anchor phrase (already in `_CHECK_40_ANCHOR_PHRASES`, aliased to
`_CHECK_43_ANCHOR_PHRASES`), making pack-as-product context explicit
for the dual-surface reader.

### 7.6 Files changed inventory (H.14 + Option C absorption combined)

| Path | Type | Lines |
|---|---|---|
| `scripts/validate-pack.py` | Modified | +480, -0 (H.14 main: +433 L5069-L5497; absorption: +47 added to `_CHECK_43_ALLOWLIST`) |
| `.github/workflows/validate-pack.yml` | Modified | +3, -0 (after L183) |
| `scripts/tests/test-validate-pack-check-43.sh` | New file | 478 lines (executable 0755) |
| `scripts/tests/fixtures/project-side-refs/README.md` | New file | 88 lines |
| `scripts/tests/fixtures/project-side-refs/project-side-fail-per-entry-skeleton.md` | New file | 12 lines |
| `scripts/tests/fixtures/project-side-refs/project-side-fail-architect-doc-cite.md` | New file | 15 lines |
| `scripts/tests/fixtures/project-side-refs/project-side-fail-detect-sh-comment.sh` | New file | 19 lines |
| `scripts/tests/fixtures/project-side-refs/project-side-fail-pmstartup-cite.md` | New file | 14 lines |
| `scripts/tests/fixtures/project-side-refs/project-side-fail-pmchat-self-prompt.md` | New file | 14 lines |
| `scripts/tests/fixtures/project-side-refs/project-side-fail-mcp-example.json` | New file | 7 lines |
| `scripts/tests/fixtures/project-side-refs/project-side-fail-audit-cite-in-skill.md` | New file | 19 lines |
| `scripts/tests/fixtures/project-side-refs/project-side-pass-pack-feedback.md` | New file | 17 lines |
| `scripts/tests/fixtures/project-side-refs/project-side-pass-allowlist-methodology.md` | New file | 21 lines |
| `scripts/tests/fixtures/project-side-refs/project-side-pass-anchor-pack-repo.md` | New file | 23 lines |
| `scripts/tests/fixtures/project-side-refs/project-side-pass-same-dir-skeleton.md` | New file | 23 lines |
| `scripts/tests/fixtures/project-side-refs/project-side-pass-code-block.md` | New file | 25 lines |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.14.md` | New file | This file |
| `supporting-docs/METHODOLOGY.md` | Modified (Option C) | 4 LEAK CLASS C rewrites (L14 / L53 / L386 / L1624) — net ~0 line delta (rewrites preserve word count) |
| `supporting-docs/INSTALL-PROCEDURES.md` | Modified (Option C) | 1 LEAK CLASS C rewrite (L236) — +1 word ("in the pack repo") |
| `project-template/scripts/bootstrap.sh` | Modified (Option C) | 1 LEAK CLASS C rewrite (L49) — +5 words ("in the pack repo:") |
| `test-fixtures/manifest.txt` | Modified (Option C) | 3 rows updated (v11-realistic-ot / v11-flat-file / v11-tracker-on SHAs) |

**Total: 20 files touched (15 new + 5 modified).**

H.14 main pass: 17 files (15 new + 2 modified — `scripts/validate-pack.py`,
`.github/workflows/validate-pack.yml`).

Option C absorption pass: 3 additional modifications
(`supporting-docs/METHODOLOGY.md`, `supporting-docs/INSTALL-PROCEDURES.md`,
`project-template/scripts/bootstrap.sh`, `test-fixtures/manifest.txt`)
plus extending `scripts/validate-pack.py` (already modified in H.14).

---

## Closing summary

H.14 main pass: implementation matches architect contract §1.1-§1.12
verbatim — function signature, allowlist (31 entries), anchor-phrase
aliases, fail/pass conditions, failure message format, mirror-skip
exclusions, fixture test spec (7 groups + 13 fixture files), and CI
YAML wiring. Fence-awareness added per §1.12 design intent (same
`_has_per_line_fence` + `_build_fence_skip_lineset` pattern Check 37
uses).

Option C absorption pass (Pack Chat triage, 2026-05-24): the §7.2
audit-vocabulary-gap discovery is resolved. 29 audit-vocabulary-gap
legitimate basenames (covering 78 catch-sites) added to
`_CHECK_43_ALLOWLIST`; 6 real LEAK CLASS C catches rewritten (1 Cat A
drop + 5 anchor-phrase rewrites).

Post-absorption state:
- All 43 validate-pack.py checks PASS at HEAD.
- All 7 groups of test-validate-pack-check-43.sh PASS.
- All 4 groups of test-validate-pack-check-42.sh PASS.
- `_CHECK_43_ALLOWLIST` now has 60 entries (31 + 29).
- Manifest staged with 3-row drift (v11-realistic-ot / v11-flat-file
  / v11-tracker-on SHAs updated).
- H.14 commit lands clean (no failing-CI posture).
- Zero outstanding POQs.
