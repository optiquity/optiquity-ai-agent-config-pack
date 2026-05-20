# ARCHITECTURE-BD-176 — Expand RC9 manifest-regen trigger to cover all fixture-affecting surfaces

**Status:** Architect strategy doc (pre-implementation)
**Author:** pack-architect (background spawn)
**Date:** 2026-05-20
**HEAD at design time:** `aca8399`
**Batch:** BD-175 emergency batch chain (BD-175 closed → **BD-176** → BD-177 → BD-178 → BD-179 → BD-180 → end-of-batch reviewer → Phase 6 → Phase 7 → Batch 19c)
**BD-176 entry:** `pack-ops/BACKLOG.md` L1419-L1449
**Prompt context:** pack-root trinity Pack memory § "Repo conventions" RC9 bullet expansion
**Trinity rule:** APPLIES (3 pack-root files lockstep)
**Pack-architect spawn protocol:** SATISFIED (touches trinity Pack-memory section)

---

## §1 Context

### §1.1 Problem statement (per BD-176 entry)

The RC9 ("Regenerate test-fixtures/manifest.txt on every v11-surface commit") rule in pack-root trinity § "Repo conventions" currently defines the trigger glob as:

> `v11-surface = files under project-template/ or scripts/`

Two false-negative classes have been empirically surfaced during BD-175:

**(a) `pack-ops/` (partially false-negative; mostly defensive).** BD-175 commit `59a7dbb` (M1-M5 + M9-M10 directory reorg) created `pack-ops/` as a new top-level pack-side directory hosting LIVE OPS docs. The reorg moved 7 files from pack root:

```
pack-ops/PACK-CHAT.md
pack-ops/PACK-AGENTS.md
pack-ops/HELP-FRAGMENT-PACK.md
pack-ops/HELP-FRAGMENT-TRACKER.md   ← fixture-affecting (see §1.2 below)
pack-ops/OPTIONAL-FEATURES.md
pack-ops/BACKLOG.md
pack-ops/CHANGELOG.md
```

Subsequent BD-175 commits added: `BOUNDARY-DEFINITION.md`, `MERGE-STRATEGY.md`, `CONCEPTUAL-REVIEW-METHODOLOGY.md`, `DRY-RUN-MIGRATION.md`, `.boundary-exempt-root.txt`. Of these 12 files, only `HELP-FRAGMENT-TRACKER.md` is fixture-affecting today (verified via §1.2). The remaining 11 are not currently captured in fixture SHAs.

**(b) `supporting-docs/` files that install to clients (CONFIRMED FALSE-NEGATIVE).** `scripts/init-project.sh:565-570` copies `supporting-docs/METHODOLOGY.md` to client `<repo>/docs/pack/METHODOLOGY.md` during install. `scripts/init-project.sh:576-583` does the same for `supporting-docs/INSTALL-PROCEDURES.md`. So when `test-fixtures/build.sh` invokes `init-project.sh` to build v11-* fixture artifacts, BOTH files' content IS captured in fixture SHAs. BD-175 Phase 5 Commit 8 (`4120d19`) modified METHODOLOGY.md without manifest regen per current RC9 strict rule; CI `fixture manifest verify` step FAILED on the push; recovery commit `6c48f88` had to land as a separate `fix:` commit to restore the manifest. This is the first empirical confirmation of the supporting-docs/ false-negative class.

### §1.2 Empirical verification of fixture-affecting paths

The pack repository's fixture-build dependency chain is:

```
test-fixtures/build.sh
  └─→ invokes scripts/init-project.sh (via _run_v11_init / _run_v10_init)
        └─→ copies these source files into target fixtures:
              * project-template/**                   (stages S1..S11 across many copy sites)
              * scripts/**                            (stage S11 + S5)
              * pack-ops/HELP-FRAGMENT-TRACKER.md     (stage S11 line 823-825 — copy to docs/pack/)
              * supporting-docs/METHODOLOGY.md         (stage S6 line 565-570 — copy to docs/pack/)
              * supporting-docs/INSTALL-PROCEDURES.md  (stage S6 line 576-583 — copy to docs/pack/)
```

Direct `grep` confirmation that no OTHER `pack-ops/` or `supporting-docs/` files are read by `init-project.sh`:

```sh
$ grep -n "pack-ops/" scripts/init-project.sh
820:    # BD-175: HELP-FRAGMENT-TRACKER.md canonical source is pack-ops/ post-reorg.
823:    if [[ -f "$PACK/pack-ops/HELP-FRAGMENT-TRACKER.md" ]]; then
824:        cp -f "$PACK/pack-ops/HELP-FRAGMENT-TRACKER.md" \

$ grep -n "supporting-docs/" scripts/init-project.sh
562:    # ... METHODOLOGY copy site ...
565:    if [[ -f "$PACK/supporting-docs/METHODOLOGY.md" ]]; then
568:            existing_classifier_copy "$PACK/supporting-docs/METHODOLOGY.md" ...
570:            cp "$PACK/supporting-docs/METHODOLOGY.md" "$TARGET/docs/pack/METHODOLOGY.md"
574:    # ... INSTALL-PROCEDURES copy site ...
576:    if [[ -f "$PACK/supporting-docs/INSTALL-PROCEDURES.md" ]]; then
579:            existing_classifier_copy "$PACK/supporting-docs/INSTALL-PROCEDURES.md" ...
581:            cp "$PACK/supporting-docs/INSTALL-PROCEDURES.md" "$TARGET/docs/pack/INSTALL-PROCEDURES.md"
```

The `supporting-docs/` install-to-client subset is therefore: `METHODOLOGY.md`, `INSTALL-PROCEDURES.md` (2 files total at HEAD). The remaining 9 files in `supporting-docs/` (`AGENT_KICKOFF_TEMPLATE.md`, `CLI-PM-SETUP.md`, `DEPENDENCIES.md`, `MIGRATION-v10-to-v11.md`, `MIGRATION-v8-to-v9.md`, `SETUP_TEMPLATE.md`, `SETUP-EXISTING.md`, `SETUP-NEW.md`) are pre-install / reference / template files — NOT copied to clients by `init-project.sh`.

### §1.3 cmd_update overlap

`scripts/init-project.sh::cmd_update` (lines 1108-1133) is a separate code path that operates on already-installed projects via the BD-088 customization-preservation contract. Its explicit-mapping list does NOT currently include `METHODOLOGY.md` or `INSTALL-PROCEDURES.md` — only `project-template/**` paths. This is a SEPARATE BD-NNN-worthy gap (the `--update` flow does not refresh those two files for existing projects), but it is out of scope for BD-176. BD-180 already targets `validate-pack.py` extensions per `pack-ops/BACKLOG.md` L1483-ish; the `cmd_update` gap is a candidate sibling for BD-180's scope. Recorded here as cross-reference; not addressed by BD-176.

### §1.4 BD-176 batch position

BD-176 lands after BD-175 closure and is the SECOND BD in the emergency-batch chain. Its blast radius is narrow: pack-root trinity Pack-memory bullet + one user-memory cache file + (optionally) a self-documenting list in init-project.sh. No downstream BD in the chain (BD-177 through BD-180) consumes RC9 as a contract; the changes here are observational (a more accurate trigger glob) and do not reorder later work.

---

## §2 D1 — Trigger expansion shape

### §2.1 D1a — `pack-ops/` inclusion

**Chosen design: simply add `pack-ops/` to the v11-surface trigger glob.**

The trigger becomes:

> `v11-surface = files under project-template/, scripts/, or pack-ops/`

**Rationale:**

1. **Inclusive design philosophy already governs RC9.** RC9's stated trade-off is "false positives cost ~30-90s of unnecessary rebuild but produce no incorrect manifest change; false negatives within v11-surface are impossible because every v11-surface file lives under one of these two directories." Adding `pack-ops/` extends this trade-off by one directory: `HELP-FRAGMENT-TRACKER.md` makes the directory partially fixture-affecting today (confirmed in §1.2); the 11 other files in pack-ops/ produce false positives whose cost is bounded by the same ~30-90s rebuild and detected as no-op manifest diff (zero staging burden when rebuild produces empty diff).

2. **Defends against future pack-ops/ additions.** The 2026-05-19 supporting-docs/ CI failure illustrates the failure mode: a file lands in a non-triggered directory, the manifest drifts, CI fails, recovery requires a separate `fix:` commit. Adding `pack-ops/` to the trigger glob pre-empts this for any future pack-ops/ file that becomes fixture-affecting (e.g., if `init-project.sh` is later extended to copy `pack-ops/PACK-AGENTS.md` to clients, or if `test-fixtures/build.sh` adds direct `pack-ops/` reads).

3. **Symmetry with the directory-glob trigger model.** RC9's trigger is directory-shaped, not file-list-shaped. Mixing a directory-glob trigger with a file-enumeration trigger (e.g., `project-template/ OR scripts/ OR pack-ops/HELP-FRAGMENT-TRACKER.md`) breaks the model and forces every future maintainer to remember the exception. A directory-uniform glob is mentally cheaper to apply.

**Rejected alternative — enumerate the single file `pack-ops/HELP-FRAGMENT-TRACKER.md` only.** Mechanically tighter but:
- Asymmetric with the `project-template/` and `scripts/` directory-glob form.
- Brittle against future copy-sites added to `init-project.sh`.
- The "false positives are cheap" trade-off is already established for the other 2 directories.

**Rejected alternative — conditional-on-actual-fixture-impact.** "Only trigger if the file is read by init-project.sh." This is the self-documenting list option (see §5) — useful as a code-level safety check but not a viable trigger-rule shape because (a) it requires reading code to apply the rule, (b) the rule must remain text-applicable in commit-discipline contexts where the actor may not have shell access to query init-project.sh, (c) the safety check belongs alongside RC9 not instead of it.

### §2.2 D1b — `supporting-docs/` install-to-client treatment

**Chosen design: option B2 — broaden to all of `supporting-docs/`.**

The trigger becomes:

> `v11-surface = files under project-template/, scripts/, pack-ops/, or supporting-docs/`

**Rationale:**

1. **Consistency with RC9's stated philosophy.** "False positives cost ~30-90s of unnecessary rebuild but produce no incorrect manifest change." For `supporting-docs/` the false-positive set at HEAD is 9 files (`AGENT_KICKOFF_TEMPLATE.md`, `CLI-PM-SETUP.md`, `DEPENDENCIES.md`, `MIGRATION-v10-to-v11.md`, `MIGRATION-v8-to-v9.md`, `SETUP_TEMPLATE.md`, `SETUP-EXISTING.md`, `SETUP-NEW.md`) — small enough that the ~30-90s rebuild on edits to these files is a worthwhile insurance premium against future copy-site additions.

2. **Future-proof against init-project.sh evolution.** If a future BD extends init-project.sh to copy (say) `supporting-docs/DEPENDENCIES.md` to clients (plausible — DEPENDENCIES.md describes pack runtime deps and a client may want a local copy), B2 captures it automatically. B1 (explicit enumeration) would silently leak until the next supporting-docs edit triggered a CI failure.

3. **Forward-compatibility with cmd_update extensions.** `scripts/init-project.sh::cmd_update` does not currently process `METHODOLOGY.md` / `INSTALL-PROCEDURES.md` (§1.3 gap), but if a future BD adds them, B2 already covers the trigger; B1 would need an enumeration update.

4. **Mental model alignment.** Maintainers think in directories ("did my edit touch `supporting-docs/`?"), not in file-by-file install lists. B2 matches the mental model; B1 imposes a synthetic distinction between "the install-to-client list" and "the rest of supporting-docs/."

5. **B3 (self-documenting list) is desirable INDEPENDENTLY of the trigger shape.** Even with B2, a self-documenting list of install-to-client files inside `init-project.sh` (or `validate-pack.py`) is valuable for audit/discovery. §5 D4 addresses the self-documenting list as a separate decision.

**Rejected alternative — B1 (enumerate specific files).** Pros: precise, zero false positives. Cons: requires list maintenance (must update RC9 every time `init-project.sh` adds a supporting-docs/ copy site); creates two-tier mental model ("install-to-client supporting-docs/ files vs other supporting-docs/ files"); the precise enumeration must live in RC9 prose, increasing the bullet's length and adding citation-cost for actors needing to apply the rule.

**Rejected alternative — B3 (RC9 references self-documenting list in init-project.sh).** Pros: single source of truth (the list is in code, not prose). Cons: forces RC9 to be conditional-on-code-query (read `init-project.sh` to apply the rule), which breaks the "apply at commit time without shell access" property of the current RC9 wording. RC9 must remain text-applicable. A self-documenting list inside init-project.sh has audit value — see §5 D4 — but the TRIGGER must remain directory-glob.

### §2.3 Combined trigger result

After D1a + D1b the trigger becomes:

> `v11-surface = files under project-template/, scripts/, pack-ops/, or supporting-docs/`

This is a 4-directory glob with no exceptions. The false-positive cost is bounded (rebuild + empty-diff detection) and the false-negative space is empty for known fixture-affecting paths today.

---

## §3 D2 — Trinity edit shape

### §3.1 Within-trinity parity verification at HEAD

Verified at HEAD `aca8399`: the RC9 bullet is byte-identical across all 3 pack-root trinity files. Confirmed via:

```sh
$ diff <(sed -n '510,552p' CLAUDE.md) <(sed -n '463,505p' AGENTS.md)
# (empty — identical)
$ diff <(sed -n '510,552p' CLAUDE.md) <(sed -n '432,474p' GEMINI.md)
# (empty — identical)
```

Line ranges: CLAUDE.md L510-L552, AGENTS.md L463-L505, GEMINI.md L432-L474. Same content, different line offsets due to surrounding text differences.

### §3.2 Exact BEFORE/AFTER for the trinity-shared text

The change is a SINGLE TARGETED EDIT in the existing RC9 bullet. The bullet's overall shape (header, body, "Why" rationale, "How to apply" recipe, cross-reference footer) is preserved. Only the trigger definition + supporting prose is updated.

**BEFORE (current text — byte-identical across all 3 pack-root trinity files):**

```markdown
- **Regenerate test-fixtures/manifest.txt on every v11-surface commit.**
  v11-surface = files under `project-template/` or `scripts/`. Any
  commit whose diff includes a file under either directory MUST also
  regenerate `test-fixtures/manifest.txt` and stage it alongside the
  scope edits in the SAME commit. The trigger is intentionally
  inclusive — false positives (e.g., a `scripts/test-*.sh` edit that
  doesn't actually affect fixtures) cost ~30-90s of unnecessary
  rebuild but produce no incorrect manifest change; false negatives
  within v11-surface are impossible because every v11-surface file
  lives under one of these two directories. v11-* fixture row SHAs
  drift naturally with any v11-surface change (per
  `test-fixtures/README.md` § Determinism and the `_update_manifest`
  comment at `test-fixtures/build.sh:903-912`); a stale manifest
  fails CI's `fixture manifest verify` step (BD-115, RELEASE-GATE
  item 5) even when every functional test passes. **Why:** prevents
  the 2026-05-17 incident where commit `667d2dd` shipped v11-surface
  trinity edits without regenerating the manifest, CI failed on the
  manifest-comparison step alone (all 40+ functional steps PASSED),
  and recovery commit `ef9e5c7` had to land as a separate `fix:`
  commit; the drift was the cumulative effect of three intentional
  v11-surface commits (`cf67a96` BD-169 pack-product wording,
  `62f9eec` BD-169 review/fix, `479fef5` Batch 19 broad review/fix)
  since the last manifest regen at `a57dd04` (BD-160). **How to
  apply:** before staging a commit whose diff includes any file
  under `project-template/` or `scripts/`, run
  `bash test-fixtures/build.sh --all --clean` from the pack root.
  Then check `git diff test-fixtures/manifest.txt`: if non-empty,
  `git add test-fixtures/manifest.txt` and stage it alongside the
  scope edits in the same commit; if empty, your edit wasn't
  v11-surface (no staging needed). The manifest diff after rebuild
  is the canonical authority — the trigger globs are a screen for
  WHEN to run the rebuild. `--all --clean` is the canonical default
  (rebuilds all six fixtures deterministically; v10-* rows are
  tag-pinned and only drift if the v10 tag moves). Actors confident
  about which v11-* fixture is affected may substitute
  `--name <fixture> --clean` per affected fixture, then
  `bash test-fixtures/build.sh --verify` to confirm the remaining
  rows are unchanged before staging. Cross-reference: the "Test
  infra is self-provisioned" bullet above governs *test
  provisioning*; this bullet governs *manifest maintenance* and is
  load-bearing for the `fixture manifest verify` CI gate
  (BD-115, RELEASE-GATE item 5).
```

**AFTER (revised text — to be applied byte-identical across all 3 pack-root trinity files):**

```markdown
- **Regenerate test-fixtures/manifest.txt on every v11-surface commit.**
  v11-surface = files under `project-template/`, `scripts/`,
  `pack-ops/`, or `supporting-docs/`. Any commit whose diff includes
  a file under any of these four directories MUST also regenerate
  `test-fixtures/manifest.txt` and stage it alongside the scope edits
  in the SAME commit. The trigger is intentionally inclusive — false
  positives (e.g., a `scripts/test-*.sh` edit that doesn't actually
  affect fixtures, or a `supporting-docs/MIGRATION-v10-to-v11.md`
  edit which is a pre-install reference not copied to clients) cost
  ~30-90s of unnecessary rebuild but produce no incorrect manifest
  change; false negatives within v11-surface are impossible because
  every fixture-affecting file lives under one of these four
  directories. Fixture-affecting paths today: all of
  `project-template/**` and `scripts/**` (mass-copied by
  `scripts/init-project.sh` stages S1-S11);
  `pack-ops/HELP-FRAGMENT-TRACKER.md` (`scripts/init-project.sh`
  stage S11 copies to client `docs/pack/`);
  `supporting-docs/METHODOLOGY.md` and
  `supporting-docs/INSTALL-PROCEDURES.md`
  (`scripts/init-project.sh` stage S6 copies to client `docs/pack/`).
  Other files under `pack-ops/` and `supporting-docs/` are not
  fixture-affecting today, but the directory-wide trigger defends
  against future copy-site additions to `init-project.sh` or new
  fixture-build readers. v11-* fixture row SHAs drift naturally with
  any v11-surface change (per `test-fixtures/README.md` § Determinism
  and the `_update_manifest` comment at
  `test-fixtures/build.sh:903-912`); a stale manifest fails CI's
  `fixture manifest verify` step (BD-115, RELEASE-GATE item 5) even
  when every functional test passes. **Why:** two incidents drove
  this rule: (1) the 2026-05-17 incident where commit `667d2dd`
  shipped v11-surface `project-template/` trinity edits without
  regenerating the manifest, CI failed on the manifest-comparison
  step alone (all 40+ functional steps PASSED), and recovery commit
  `ef9e5c7` had to land as a separate `fix:` commit; the drift was
  the cumulative effect of three intentional v11-surface commits
  (`cf67a96` BD-169 pack-product wording, `62f9eec` BD-169 review/
  fix, `479fef5` Batch 19 broad review/fix) since the last manifest
  regen at `a57dd04` (BD-160); (2) the 2026-05-19 incident where
  BD-175 Phase 5 Commit 8 `4120d19` modified
  `supporting-docs/METHODOLOGY.md` (a client-installed file) without
  regenerating the manifest under the prior strict trigger (which
  excluded `supporting-docs/`), CI failed identically, and recovery
  commit `6c48f88` had to land as a separate `fix:` commit. BD-176
  expanded the trigger from 2 directories to 4 to close both classes
  of false negative (pack-ops/ defensively; supporting-docs/
  empirically). **How to apply:** before staging a commit whose diff
  includes any file under `project-template/`, `scripts/`,
  `pack-ops/`, or `supporting-docs/`, run
  `bash test-fixtures/build.sh --all --clean` from the pack root.
  Then check `git diff test-fixtures/manifest.txt`: if non-empty,
  `git add test-fixtures/manifest.txt` and stage it alongside the
  scope edits in the same commit; if empty, your edit wasn't
  v11-surface (no staging needed). The manifest diff after rebuild
  is the canonical authority — the trigger globs are a screen for
  WHEN to run the rebuild. `--all --clean` is the canonical default
  (rebuilds all six fixtures deterministically; v10-* rows are
  tag-pinned and only drift if the v10 tag moves). Actors confident
  about which v11-* fixture is affected may substitute
  `--name <fixture> --clean` per affected fixture, then
  `bash test-fixtures/build.sh --verify` to confirm the remaining
  rows are unchanged before staging. Cross-reference: the "Test
  infra is self-provisioned" bullet above governs *test
  provisioning*; this bullet governs *manifest maintenance* and is
  load-bearing for the `fixture manifest verify` CI gate
  (BD-115, RELEASE-GATE item 5).
```

### §3.3 What changed (delta summary)

Three substantive changes to the bullet body:

1. **Trigger expansion (1 sentence).** `v11-surface = files under project-template/ or scripts/` → `v11-surface = files under project-template/, scripts/, pack-ops/, or supporting-docs/`. The follow-on "Any commit whose diff includes a file under either directory" → "Any commit whose diff includes a file under any of these four directories" mirrors the change.

2. **False-positive example expansion (1 example added).** The parenthetical "e.g., a `scripts/test-*.sh` edit that doesn't actually affect fixtures" gains a sibling example: ", or a `supporting-docs/MIGRATION-v10-to-v11.md` edit which is a pre-install reference not copied to clients". This makes the false-positive accommodation concrete for the new directory.

3. **Fixture-affecting-paths enumeration (new sentence + list).** A new sentence enumerates the fixture-affecting paths today, distinguishing mass-copied directories (`project-template/**`, `scripts/**`) from selectively-copied files (`pack-ops/HELP-FRAGMENT-TRACKER.md`, `supporting-docs/METHODOLOGY.md`, `supporting-docs/INSTALL-PROCEDURES.md`) and stating the defensive forward-looking rationale for the other files in the two new directories.

4. **"Why" rationale expansion (the 2026-05-19 incident added).** The "Why" paragraph now narrates BOTH precedent incidents (2026-05-17 trinity-edit drift + 2026-05-19 METHODOLOGY.md drift) and explicitly names BD-176 as the rule-expansion BD.

5. **"How to apply" trigger glob updated (1 sentence).** "any file under `project-template/` or `scripts/`" → "any file under `project-template/`, `scripts/`, `pack-ops/`, or `supporting-docs/`" — mirror of the trigger sentence.

NO changes to:
- Bullet header.
- Verification recipe (`bash test-fixtures/build.sh --all --clean`).
- Manifest-diff authority statement.
- `--name <fixture> --clean` alternative path.
- Cross-reference to "Test infra is self-provisioned" bullet.
- CI-gate cross-reference (`BD-115, RELEASE-GATE item 5`).

### §3.4 Placement within § "Repo conventions"

The bullet remains at its current position — the last bullet in the § "Repo conventions" subsection of § "## Pack memory". No re-ordering needed; this is a content edit to an existing bullet, not a new bullet insertion.

### §3.5 Within-trinity parity check recipe

Pack Chat (or the coder) runs the following two `diff` invocations after applying the edit and confirms both produce empty output:

```sh
# Pin known line offsets at HEAD aca8399 (will shift slightly after edit;
# coder should re-compute the line ranges before running these diffs).
$ diff <(sed -n '<CLAUDE-start>,<CLAUDE-end>p' CLAUDE.md) \
       <(sed -n '<AGENTS-start>,<AGENTS-end>p' AGENTS.md)
# expected: empty

$ diff <(sed -n '<CLAUDE-start>,<CLAUDE-end>p' CLAUDE.md) \
       <(sed -n '<GEMINI-start>,<GEMINI-end>p' GEMINI.md)
# expected: empty
```

Alternative coder-friendly recipe (more robust to line-offset drift): extract the bullet via awk pattern-match between the bullet's opening sentence and the next bullet's opening, then `diff` across the 3 files. The coder picks the recipe; both produce the same empty-diff signal.

**Note on Check 18 H2 enforcement:** Check 18 enforces H2 *structure* parity only for the `project-template/` trinity (`scripts/validate-pack.py:1295-1300` hardcodes `REPO_ROOT / "project-template" / name`). Pack-root trinity H2 parity is NOT mechanically enforced — only the trinity-rule discipline (lockstep edits in same commit) guards it. This is acceptable for BD-176 because the edit is bullet-content, not H2-structure: byte-identical bullet content across the 3 pack-root trinity files is preserved by lockstep edits + the manual `diff` verification above.

---

## §4 D3 — Memory cache update

### §4.1 File location

`~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_manifest_regen_on_v11_surface.md` is the user-memory cache file for this rule. It is a Claude-Code Tier-1.5 convenience pointer; trinity is the source of truth. The file is byte-identical to its index entry in MEMORY.md (per the `# claudeMd` system reminder § Tier 1.5 contract).

### §4.2 Current content (verified at session start)

```
---
name: manifest-regen-on-v11-surface
description: "When committing changes that touch files under project-template/ or scripts/ (v11-surface), regenerate test-fixtures/manifest.txt in the same commit via bash test-fixtures/build.sh --all --clean and stage the regenerated manifest alongside the scope edits"
metadata:
  node_type: memory
  type: feedback
  trinity_anchor: /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md#repo-conventions
  originSessionId: f6d6104f-9268-42ff-90cf-ac8ae35433e3
---

Trinity-cache pointer. Authoritative source is the trinity
`## Pack memory > ### Repo conventions` bullet RC9 in pack-root
`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (UNIVERSAL classification —
byte-identical across all 3 trinity files).

**Quick reference:**

- **Trigger:** any commit whose diff includes a file under
  `project-template/` or `scripts/` (fuzzy top-level directory form)
- **Action:** run `bash test-fixtures/build.sh --all --clean` from the
  pack root; if `git diff test-fixtures/manifest.txt` shows changes,
  `git add test-fixtures/manifest.txt` and stage alongside scope edits
  in the SAME commit
- **Authority:** the manifest diff after rebuild is canonical — trigger
  globs are a screen for WHEN to rebuild, not WHETHER an edit is
  v11-surface. If rebuild produces empty diff, the edit wasn't
  v11-surface; no staging needed.
- **Recursive base case:** trinity edits at pack-root (CLAUDE.md /
  AGENTS.md / GEMINI.md / PACK-CHAT.md / PACK-AGENTS.md / etc.) are NOT
  v11-surface. Pack-root edits do not require manifest regen.

**Worked example (2026-05-17 incident):** Commit `667d2dd` shipped
v11-surface trinity edits in `project-template/` without regenerating
manifest. CI's `fixture manifest verify` step failed even though all
40+ functional test steps PASSED. Recovery commit `ef9e5c7` regenerated
manifest as a separate `fix:` commit. Drift was cumulative across
`cf67a96` + `62f9eec` + `479fef5` since last manifest regen at
`a57dd04` (BD-160). Rule RC9 landed in commit `a9b7c74` as Batch 19b-2
to prevent future occurrences.

**Pairs with:** [[feedback_test_infra_self_provisioned]] (test
provisioning — distinct from manifest maintenance; cross-referenced
in the trinity bullet itself).
```

### §4.3 Required changes

**Two changes required:**

**Change 1 — `description` field (frontmatter):** Expand the directory list.

BEFORE:
```yaml
description: "When committing changes that touch files under project-template/ or scripts/ (v11-surface), regenerate test-fixtures/manifest.txt in the same commit via bash test-fixtures/build.sh --all --clean and stage the regenerated manifest alongside the scope edits"
```

AFTER:
```yaml
description: "When committing changes that touch files under project-template/, scripts/, pack-ops/, or supporting-docs/ (v11-surface), regenerate test-fixtures/manifest.txt in the same commit via bash test-fixtures/build.sh --all --clean and stage the regenerated manifest alongside the scope edits"
```

**Change 2 — `Trigger` bullet (body):** Mirror the trigger expansion.

BEFORE:
```markdown
- **Trigger:** any commit whose diff includes a file under
  `project-template/` or `scripts/` (fuzzy top-level directory form)
```

AFTER:
```markdown
- **Trigger:** any commit whose diff includes a file under
  `project-template/`, `scripts/`, `pack-ops/`, or `supporting-docs/`
  (fuzzy top-level directory form)
```

**Change 3 — Worked example expansion (1 paragraph added):** Add the 2026-05-19 incident.

After the existing "Worked example (2026-05-17 incident)" paragraph, add a sibling paragraph:

```markdown
**Worked example (2026-05-19 incident — supporting-docs/ false-negative):**
BD-175 Phase 5 Commit 8 (`4120d19`) modified
`supporting-docs/METHODOLOGY.md` without regenerating manifest because
the prior RC9 trigger glob (`project-template/` + `scripts/`) excluded
`supporting-docs/`. METHODOLOGY.md IS copied to client `docs/pack/` by
`scripts/init-project.sh:565-570` during install, so its content is
captured in v11-* fixture SHAs. CI's `fixture manifest verify` step
failed; recovery commit `6c48f88` had to land as a separate `fix:`
commit to restore the manifest. BD-176 expanded the trigger glob from
2 directories to 4 (`project-template/` + `scripts/` + `pack-ops/` +
`supporting-docs/`) to close both this empirical false-negative class
and the pack-ops/ defensive class.
```

**Change 4 — Recursive base case clarification (1 sentence appended):** Pack-root trinity remains NOT-v11-surface, but `pack-ops/` IS v11-surface now — must distinguish.

BEFORE:
```markdown
- **Recursive base case:** trinity edits at pack-root (CLAUDE.md /
  AGENTS.md / GEMINI.md / PACK-CHAT.md / PACK-AGENTS.md / etc.) are NOT
  v11-surface. Pack-root edits do not require manifest regen.
```

AFTER:
```markdown
- **Recursive base case:** trinity edits at pack-root (CLAUDE.md /
  AGENTS.md / GEMINI.md at the repository root) are NOT v11-surface.
  Pack-root trinity edits do not require manifest regen. Note: files
  under `pack-ops/` (PACK-CHAT.md, PACK-AGENTS.md, BACKLOG.md,
  CHANGELOG.md, HELP-FRAGMENT-PACK.md, OPTIONAL-FEATURES.md,
  BOUNDARY-DEFINITION.md, etc.) ARE v11-surface per the BD-176 trigger
  expansion — only the 3 pack-root trinity files themselves (CLAUDE.md
  / AGENTS.md / GEMINI.md at repo root) keep the base-case exemption.
  The expanded glob includes pack-ops/HELP-FRAGMENT-TRACKER.md (today
  fixture-affecting via init-project.sh stage S11) and pack-ops/
  generally (future-proof).
```

### §4.4 Memory-cache edit authority

Per pack memory § "Pack Chat scope" → "What Pack Chat CAN edit directly" → "Memory files (`~/.claude/projects/<slug>/memory/*.md`)", Pack Chat directly edits this file (no pack-coder spawn needed for the memory cache). The trinity edit goes to pack-coder; the memory cache edit is Pack-Chat-direct.

**Trinity exemption note:** This memory cache is Claude-specific (Codex has no pack-shipped per-project memory cache per pack-root AGENTS.md L336-340; Gemini's memory IS the GEMINI.md hierarchy itself per pack-root GEMINI.md L306-310). No parallel Codex/Gemini memory-cache update is needed — the trinity edit to pack-root GEMINI.md / AGENTS.md IS the Codex/Gemini equivalent.

---

## §5 D4 — Code-level safety check (add-now vs defer-to-BD-180)

### §5.1 Decision

**DEFER to BD-180.** Do NOT add a self-documenting "files copied to clients" list to `scripts/init-project.sh` or `scripts/validate-pack.py` in BD-176.

### §5.2 Rationale

1. **Scope boundary (BD-176 = trigger-rule expansion, not code-discoverability instrumentation).** The BD-176 entry's File/Symbol list (`pack-ops/BACKLOG.md` L1426-L1429) is:
   - `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (pack root) "Pack memory" § "Repo conventions" RC9 bullet — trinity rule applies
   - `~/.claude/projects/<slug>/memory/feedback_manifest_regen_on_v11_surface.md` (user memory cache update)
   - *Possibly* `scripts/init-project.sh` (consider adding a self-documenting list of "files copied to clients" for RC9's reference, OR keep RC9 as inclusive directory-trigger model)

   The "possibly" / "consider" wording explicitly marks D4 as an architect's call. The architect declines to bundle a code change into BD-176 because the trigger-rule expansion (§2-4) is the load-bearing decision; the code-level instrumentation is a separate concern.

2. **BD-180 already targets validate-pack.py extensions.** Per `pack-ops/BACKLOG.md` BD-180 entry (the F2a + F2A-S1 stale-mapping scope absorption per commit `4f3dd72`), BD-180's scope includes `validate-pack.py` extensions. A "self-documenting fixture-affecting paths list" with a corresponding `validate-pack.py` check (e.g., Check NN: assert that every directory in the RC9 trigger-glob is either mass-touched by init-project.sh OR has a file individually copied by init-project.sh) is a natural fit for BD-180. Bundling it into BD-176 would create scope creep within BD-176; BD-180 already owns the validation-extension surface.

3. **Per pack memory § "Deferral IS scope creep" 3-prong test:** SIZE (architect-pass material) NO; BLOCKED on BD-176 close NO; LOGICAL FIT — concrete same-contract fit with BD-180's validate-pack.py extension scope. The deferral satisfies the LOGICAL FIT prong: the code-level safety check belongs with sibling validate-pack.py extensions in BD-180, not as an inline addendum to a memory-rule edit in BD-176.

4. **No v11.0 launch blocker.** RC9 with the expanded directory glob (§2) is sufficient on its own to prevent recurrence of both incidents (2026-05-17 and 2026-05-19). The CI gate (`fixture manifest verify`) catches drift independently of any source-code instrumentation. The self-documenting list is a quality-of-life improvement (faster audit, mechanical sync) but not a correctness gate.

### §5.3 Design sketch for BD-180 absorption (forward reference)

When BD-180 lands the code-level check, the recommended shape is:

- **In `scripts/init-project.sh`:** add a comment block above stage S6 + stage S11 listing the explicit copy-sites (file paths from `$PACK/` to `$TARGET/`). Format:
  ```bash
  # FIXTURE-AFFECTING FILES copied by this script (RC9 cross-reference):
  #   * project-template/**                       (mass-copied across S1..S11)
  #   * scripts/**                                (stages S5, S11 partial)
  #   * pack-ops/HELP-FRAGMENT-TRACKER.md         (S11 line 823-825)
  #   * supporting-docs/METHODOLOGY.md            (S6 line 565-570)
  #   * supporting-docs/INSTALL-PROCEDURES.md     (S6 line 576-583)
  # Adding a new explicit copy-site requires either:
  #   (a) the new source directory is already in the RC9 trigger glob, OR
  #   (b) the trigger glob is expanded — see pack-root CLAUDE.md
  #       § Pack memory § Repo conventions § "Regenerate
  #       test-fixtures/manifest.txt on every v11-surface commit".
  ```
- **In `scripts/validate-pack.py`:** add a new Check (e.g., Check 40) that asserts each file listed in the comment block above either (a) exists at the named path, (b) is grep-matched against the corresponding `init-project.sh` line, (c) the surrounding directory is in the RC9 trigger glob. The check is a discoverability assertion: it catches drift between the inline comment list and the actual copy-sites.

This sketch is informational only for BD-176; the design lands in BD-180.

### §5.4 Handoff to BD-180

Adding to the BD-180 entry (Pack-Chat-direct edit when BD-180's scope is finalized — not in BD-176):

> **BD-180 extension (from BD-176 D4 deferral):** add a self-documenting fixture-affecting-paths list to `scripts/init-project.sh` (comment block above stages S6/S11) + a corresponding `validate-pack.py` Check 40 that asserts the comment list matches actual copy-site state. Sketch in `maintenance-docs/v11-implementation/ARCHITECTURE-BD-176.md` §5.3.

Pack Chat owns the BD-180 entry update; BD-176 coder does not touch BD-180.

---

## §6 D5 — Bootstrap order verification

### §6.1 The question

Will the expanded RC9 rule FAIL at HEAD (`aca8399`) once landed? In other words: after the trinity edit is applied, does `bash test-fixtures/build.sh --all --clean` produce a non-empty `git diff test-fixtures/manifest.txt`?

### §6.2 Check at HEAD

Before any BD-176 edit, the working-tree state is:
- `pack-ops/HELP-FRAGMENT-TRACKER.md`: byte-identical to `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (enforced by Check 24 at every pre-push validation).
- `supporting-docs/METHODOLOGY.md`: at HEAD (last modified in BD-175 Commit 8 + reverted-restored loop landing at `6c48f88`'s manifest regen).
- `supporting-docs/INSTALL-PROCEDURES.md`: at HEAD (no recent BD-175 modifications per `git log --oneline | head -20`).

Per `6c48f88`'s commit message, the most recent manifest regen captured METHODOLOGY.md's HEAD content. INSTALL-PROCEDURES.md hasn't been modified since the last `--all --clean` regen (presumably the manifest already reflects its current SHA).

**HOWEVER:** RC9's expanded trigger does NOT itself force a fixture rebuild. The rule is "regenerate manifest when committing v11-surface files." The BD-176 commit itself touches only:
- `CLAUDE.md` (pack root) — pack-root trinity, NOT v11-surface even under the expanded rule (per memory cache § "Recursive base case").
- `AGENTS.md` (pack root) — same, NOT v11-surface.
- `GEMINI.md` (pack root) — same, NOT v11-surface.
- `~/.claude/projects/<slug>/memory/feedback_manifest_regen_on_v11_surface.md` — outside the repo entirely; not v11-surface.

So the BD-176 commit's own diff is ZERO v11-surface files (under either the prior 2-directory glob OR the expanded 4-directory glob). The commit's diff is a pure pack-root trinity Pack-memory edit + a memory-cache file outside the repo.

### §6.3 Conclusion: no bootstrap problem

**The BD-176 commit itself does NOT require a manifest regen.** Pack-root trinity files are explicitly exempt per the "Recursive base case" memory-cache bullet (and the trinity files at `<repo-root>/CLAUDE.md` are outside all 4 directory globs anyway).

The expanded RC9 takes EFFECT for future commits, not for the BD-176 commit itself. There is no order-of-land or bootstrap concern.

### §6.4 Sanity verification recipe

The coder may optionally verify by:

```sh
# After applying the trinity edit + memory cache edit:
bash test-fixtures/build.sh --all --clean
git diff test-fixtures/manifest.txt
# Expected: empty (no v11-surface file in the diff; no manifest drift).
```

If the diff is non-empty (e.g., because some unrelated edit landed since the last manifest regen and the regen now captures it), that signals an UNRELATED drift requiring a separate `fix:` commit BEFORE the BD-176 commit — not a BD-176 bootstrap problem. The coder reports the unexpected diff to Pack Chat for triage; Pack Chat decides whether to absorb the manifest regen into the BD-176 commit (if the unrelated drift is small and same-context) or land it as a separate pre-BD-176 fix commit.

**Architect's expectation:** the verification recipe will produce empty diff at HEAD `aca8399`, because the most recent manifest regen at `6c48f88` captured the supporting-docs/ state, and no v11-surface commits have landed since then. The coder should confirm but plan for the empty-diff happy path.

---

## §7 D6 — Trinity rule confirmation

### §7.1 Trinity scope

BD-176 edits pack-root `CLAUDE.md` § Pack memory § Repo conventions RC9 bullet. Per pack memory Trinity rule (CLAUDE.md L104-119, AGENTS.md L98-113, GEMINI.md L75-87): the parallel edit MUST be applied to pack-root `AGENTS.md` and pack-root `GEMINI.md` in the SAME commit.

The 3-file lockstep applies because:
1. RC9 is in the Pack-memory § Repo conventions subsection.
2. The Pack-memory § Repo conventions subsection IS trinity-rule territory (byte-identical content across all 3 files at HEAD — confirmed §3.1).
3. The proposed edit is not tool-specific (does not concern Claude-Task-tool / Codex-TOML-config / Gemini-/memory-command semantics) — it concerns fixture-build behavior governed by `scripts/init-project.sh` + `test-fixtures/build.sh`, both of which are CLI-neutral.

### §7.2 Within-trinity parity verification recipe

After applying the edit to all 3 files, the coder runs:

```sh
# Extract the RC9 bullet from each trinity file and diff:
extract_rc9() {
    awk '/^- \*\*Regenerate test-fixtures\/manifest\.txt/,/^- \*\*[A-Z]/' "$1" | head -n -1
}
diff <(extract_rc9 CLAUDE.md) <(extract_rc9 AGENTS.md)
# expected: empty
diff <(extract_rc9 CLAUDE.md) <(extract_rc9 GEMINI.md)
# expected: empty
```

Alternative line-range recipe (if the awk approach trips on bullet-format quirks):

```sh
# Compute the bullet's line range in each file:
rc9_lines() {
    local f="$1"
    local start end
    start=$(grep -n "^- \*\*Regenerate test-fixtures/manifest.txt" "$f" | head -1 | cut -d: -f1)
    # Find next bullet that starts with "- **" (i.e., next top-level bullet):
    end=$(awk -v s="$start" 'NR > s && /^- \*\*/ { print NR-1; exit }' "$f")
    [[ -z "$end" ]] && end=$(wc -l < "$f")
    echo "$start,$end"
}
diff <(sed -n "$(rc9_lines CLAUDE.md)p" CLAUDE.md) \
     <(sed -n "$(rc9_lines AGENTS.md)p" AGENTS.md)
diff <(sed -n "$(rc9_lines CLAUDE.md)p" CLAUDE.md) \
     <(sed -n "$(rc9_lines GEMINI.md)p" GEMINI.md)
```

Both diffs MUST be empty. If either is non-empty, the trinity-rule edit was applied non-byte-identically and must be fixed before the commit.

### §7.3 Check 18 H2 relationship

**Check 18 H2 does NOT apply to this edit.** Check 18 (`scripts/validate-pack.py:1281-1352`) operates on `project-template/` trinity only — hardcoded at `REPO_ROOT / "project-template" / name`. The pack-root trinity does NOT have a mechanical H2-parity check; trinity-rule discipline is the only enforcement.

Additionally, this edit does NOT change any H2 in any of the 3 pack-root trinity files. The change is bullet-content within the existing `### Repo conventions` H3 (under the existing `## Pack memory` H2). H2 structure is invariant.

**Conclusion:** the verification recipe in §7.2 is the trinity-parity check for this edit. No CI gate exists for pack-root trinity bullet parity; manual `diff` is the enforcement.

---

## §8 Implementation handoff

### §8.1 File list for coder

The pack-coder spawn for BD-176 implementation will edit exactly these files:

| File | Type | Edit |
|---|---|---|
| `CLAUDE.md` (pack root) | Pack-Chat-only (trinity) | Replace RC9 bullet body per §3.2 AFTER block |
| `AGENTS.md` (pack root) | Pack-Chat-only (trinity) | Replace RC9 bullet body per §3.2 AFTER block (byte-identical to CLAUDE.md) |
| `GEMINI.md` (pack root) | Pack-Chat-only (trinity) | Replace RC9 bullet body per §3.2 AFTER block (byte-identical to CLAUDE.md) |

The user-memory cache file (`~/.claude/projects/.../feedback_manifest_regen_on_v11_surface.md`) is Pack-Chat-direct edit, NOT coder territory. Pack Chat applies the §4.3 changes after the coder commit lands.

### §8.2 Estimated commit shape

```
fix: v11 — BD-176 expand RC9 manifest-regen trigger to pack-ops/ + supporting-docs/ (PM-only)

Adds pack-ops/ and supporting-docs/ to the RC9 v11-surface trigger glob
in pack-root trinity Pack memory § Repo conventions. Empirical driver:
2026-05-19 CI failure where supporting-docs/METHODOLOGY.md edit
required separate fix commit 6c48f88. Defensive driver: pack-ops/
created in BD-175 may host future fixture-affecting files beyond
HELP-FRAGMENT-TRACKER.md.

Trinity rule: 3 pack-root trinity files lockstep (byte-identical
bullet body verified via §7.2 recipe).

No v11-surface files touched (pack-root trinity is base-case exempt
per memory-cache bullet); no manifest regen required for this commit
per RC9 itself.

See: maintenance-docs/v11-implementation/ARCHITECTURE-BD-176.md
```

Suffix: `PM-only` per the commit-subject scope-keyword convention. Per pack-root trinity § Rules for agents → commit-subject scope-keyword convention, `PM-only` permits edits to pack-root trinity (CLAUDE/AGENTS/GEMINI). The diff is 100% trinity files; PM-only is correct.

Estimated commit size: 3 files, ~90 lines per file changed (bullet body replacement), ~270 total line changes.

### §8.3 Verification recipe (full)

```sh
# 1. Trinity parity check (§7.2):
extract_rc9() {
    awk '/^- \*\*Regenerate test-fixtures\/manifest\.txt/,/^- \*\*[A-Z]/' "$1" | head -n -1
}
diff <(extract_rc9 CLAUDE.md) <(extract_rc9 AGENTS.md) && echo "CLAUDE↔AGENTS OK"
diff <(extract_rc9 CLAUDE.md) <(extract_rc9 GEMINI.md) && echo "CLAUDE↔GEMINI OK"

# 2. validate-pack baseline (must continue to PASS — no schema changes):
python3 scripts/validate-pack.py

# 3. Fixture-rebuild sanity (must produce empty manifest diff):
bash test-fixtures/build.sh --all --clean
git diff test-fixtures/manifest.txt
# expected: empty (no v11-surface files in commit diff; no drift)

# 4. Commit-subject scope-keyword check (CI Check 36 will gate this at push):
# Subject must contain "PM-only" (case-insensitive).
# Diff must touch only PM-only files per pack-ops/PACK-AGENTS.md PM-only Files list.
```

### §8.4 Dependencies on other BDs

**Blockers:** BD-175 closure (per BD-176 entry `Blockers:` line). BD-175 status flip to Resolved is the gate; this strategy doc presumes BD-175 closes successfully first.

**Unblocks:** BD-177 (sibling follow-up to BD-175 Commit 2 sentinel coordination — separate scope; no direct dependency on BD-176's content); BD-180 (D4 deferral lands the self-documenting list extension per §5).

**No coupling with:**
- BD-178 (trinity asymmetry alignment — different file set, different scope).
- BD-179 (TBD scope; not visible in current backlog at this design timestamp).
- BD-180 except via the §5 deferral handoff (additive, not blocking).

### §8.5 Post-commit Pack-Chat-direct actions

After the coder commit lands, Pack Chat performs these PM-only actions directly (no coder spawn):

1. Update `~/.claude/projects/.../feedback_manifest_regen_on_v11_surface.md` per §4.3 (4 changes: description, Trigger bullet, worked-example paragraph addition, Recursive base case clarification). Pack-Chat-direct per pack memory § "What Pack Chat CAN edit directly" → Memory files.

2. Flip BD-176 to `Status: Resolved` in `pack-ops/BACKLOG.md` (and per-entry `/backlog/BD-176.md` if present). Pack-Chat-direct per pack memory § implicit-status-flip-on-batch-completion (or per-BD inline flip per the user's batch-completion policy).

3. Update BD-180 entry to absorb the §5.3 self-documenting-list sketch as forward-reference. Pack-Chat-direct.

These 3 Pack-Chat-direct steps land AFTER the coder commit, in the same chat session, as the next-steps plan attached to the BD-176 commit-approval request (per pack memory § "Commit-approval requests include next-steps plan").

---

## §9 Open questions / blockers requiring user input

### §9.1 OQ-1: D1b — is the false-positive cost actually acceptable?

The B2 choice (broaden to all of `supporting-docs/`) adds 9 files whose edits would trigger an unnecessary fixture rebuild. The architect judges the ~30-90s rebuild cost as low and consistent with RC9's stated trade-off, but the user may prefer B1 (explicit enumeration) for one of these reasons:

- The user values minimal-friction rebuild for high-edit-frequency files (e.g., `MIGRATION-v10-to-v11.md` may be edited frequently during v11 closeout). Each edit incurs the rebuild even when no fixture is affected.
- The user prefers explicit enumeration as a discoverability surface (the RC9 bullet itself becomes a list of every install-to-client file).

**Architect recommendation:** ship B2 (chosen design). The "list maintenance burden" of B1 is the larger cost over time; the false-positive cost of B2 is bounded and self-limiting (empty diff → no action).

**Open question for user:** approve B2 vs override to B1?

### §9.2 OQ-2: D4 — does BD-180 currently have headroom for the self-documenting list absorption?

The §5.4 handoff plan adds a sub-task to BD-180 (self-documenting list + Check 40). BD-180's current scope per BACKLOG entry is `F2a + F2A-S1 stale-mapping scope absorption` (added in commit `4f3dd72`). The architect has not read BD-180's full entry — the handoff plan assumes BD-180 has room.

**Open question for user:** is BD-180 sized to absorb the §5.3 sketch, or does the self-documenting list need its own BD (BD-181)?

### §9.3 OQ-3: pre-commit manifest verification — should the coder rebuild fixtures?

§6 / §8.3 verification recipes both include `bash test-fixtures/build.sh --all --clean` as a sanity check. This rebuild takes ~30-90s and stages no files (per §6.3, the expected output is empty diff). The coder will burn the ~30-90s without producing output.

**Architect recommendation:** include the rebuild in the verification recipe but expect empty diff. The rebuild has positive value as a baseline sanity check for the next BD's coder (if the manifest IS unexpectedly drifted, the BD-176 coder catches it and reports to Pack Chat, rather than the BD-177 coder discovering it).

**Open question for user:** is the ~30-90s coder-time cost acceptable as a baseline sanity check, or should the coder skip the rebuild?

### §9.4 OQ-4: memory-cache file scope confusion?

The `feedback_manifest_regen_on_v11_surface.md` description field is a single multi-line string. Some markdown linters or YAML parsers may have line-length opinions; the AFTER value in §4.3 Change 1 is ~330 chars on one line. This is the existing format pattern (BEFORE is similarly long).

**Architect recommendation:** preserve the existing single-line format; the cache file is consumed by Claude Code memory indexing which has no line-length constraints relevant to this edit.

**Open question for user:** none — preservation of existing format is the safe default.

---

## §10 Architect's confidence + iteration accommodation

This strategy doc is structured for user iteration per the planner-to-coder gate pattern. The decisions in §2 (D1a / D1b), §3 (D2 BEFORE/AFTER), §5 (D4 defer), §8.2 (commit shape + suffix) are the load-bearing user-facing choices. The user may:

- Override D1b from B2 to B1 (explicit enumeration). The §3.2 AFTER block then needs a list of 2 files instead of the directory glob.
- Override D4 from "defer" to "add now." The §5.3 sketch then becomes a sub-task within BD-176; the commit grows from 3 files to ~5 (init-project.sh + validate-pack.py added).
- Override §8.2's `PM-only` suffix. If the user wants `pack-only` framing instead, the commit shape stays the same (PM-only is a strict subset of pack-only per Check 36 semantics).
- Adjust §3.2's wording (false-positive examples, fixture-affecting-paths enumeration, Why narrative). The strategy doc's chosen wording is illustrative; the user is the final arbiter of bullet text.

Architect confidence: high on the DIRECTION (4-directory trigger glob, deferred D4) and the trinity-parity recipe; medium on the EXACT WORDING of §3.2 AFTER (Pack Chat / user may tighten or expand the prose).

End of ARCHITECTURE-BD-176.md.
