# ARCHITECTURE — Batch 19b-2: Trinity rule for test-fixtures/manifest.txt regeneration

**Author:** pack-architect (mini architect pass)
**Date:** 2026-05-17
**Branch:** v11-dev (HEAD `ef9e5c7`)
**Ship target:** v11.0 (unlaunched)
**Scope:** pack-self only — pack-repo trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`)
**Status:** Planner-ready when D-1 through D-5 (see §6) are accepted.

This is a follow-up to Batch 19b-1 (`667d2dd` trinity `## Pack memory` restructure + `ef9e5c7` manifest fix-commit). The Batch 19b-1 design is unchanged; this doc only specifies the single bullet that codifies "regenerate `test-fixtures/manifest.txt` when committing v11-surface changes."

---

## 1. Problem statement

The Batch 19b-1 commit `667d2dd` shipped trinity edits in `project-template/` that changed v11 install-surface content. CI's `fixture manifest verify` step failed because the committed `test-fixtures/manifest.txt` was stale relative to the v11 surface that `667d2dd` plus two prior drift-source commits (`cf67a96` BD-169 pack-product, `62f9eec` BD-169 review/fix, `479fef5` Batch 19 broad review/fix) had reshaped. Recovery commit `ef9e5c7` regenerated the manifest; all functional CI test steps had already passed.

Per `test-fixtures/README.md` § Determinism and `test-fixtures/build.sh:903-912`, v11-* row SHAs are designed to drift with any v11-surface change. The drift is not a defect; the gap is procedural — there is no standing trinity rule directing actors (Pack Chat directly, pack-coder, or any other agent that reads trinity for behavioral guidance) to regenerate the manifest in the same commit as a v11-surface edit.

User has already decided the solution direction: option (B) — a single trinity `## Pack memory` bullet. Options A (pre-push hook), C (per-agent definition edits), and D (CI auto-regen) were rejected with rationale captured in the user-Pack-Chat discussion. This doc does not re-litigate that.

---

## 2. What counts as "v11-surface"

### 2.1 Trigger form (decided): fuzzy top-level directory

**The rule's TRIGGER condition is: any commit whose diff includes a file under `project-template/` or `scripts/` (top-level).** The empirical table in §2.2 below is descriptive — it documents WHAT is actually consumed by `test-fixtures/build.sh` and WHY the trigger is what it is — but the trigger itself is the two-directory fuzzy form, not an enumerated glob list.

Rationale for the fuzzy directory trigger (chosen over Form A enumerated globs and Form B heuristic phrase — see §8 for the full comparison):

1. **Architecture-stable directory names.** `project-template/` and `scripts/` are pack-architecture-stable top-level names. They will not change for v11 or v12 — only a major top-level restructure (rare; an architect-pass event at that point) would alter either name.
2. **Auto-inclusion of new files.** Adding new files UNDER either directory automatically falls under the trigger — no rule update needed. This solves the "staleness / domino-maintenance" problem that Form A (exact glob list) creates when v11-surface expands.
3. **Intentionally inclusive.** False positives (e.g., a `scripts/test-*.sh` edit that doesn't actually affect fixtures) cost ~30-90s of unnecessary rebuild but produce no incorrect manifest change. The cost is bounded and recoverable.
4. **No false negatives within v11-surface.** Every v11-surface file lives under one of these two directories. The fuzzy form cannot miss a real v11-surface change.
5. **Authority is the manifest diff after rebuild, NOT the trigger globs.** If a rebuild produces an empty `git diff test-fixtures/manifest.txt`, the edit wasn't v11-surface — no staging needed. The trigger is a screen for WHEN to run the rebuild, not a definitive answer to WHETHER an edit is v11-surface. This shifts the load-bearing decision from "did I name the right glob in the rule?" to "did the rebuild produce a diff?", which is the canonical, build-time-verified answer.

`supporting-docs/**` (which is NOT v11-surface per the empirical analysis in §2.2 below) is naturally excluded by the fuzzy trigger because it sits at top level OUTSIDE both `project-template/` and `scripts/`. Similarly, `.github/workflows/**`, `maintenance-docs/**`, `test-fixtures/**` (excluding the manifest itself), and pack-ops files at root (CLAUDE.md, AGENTS.md, GEMINI.md, PACK-CHAT.md, PACK-AGENTS.md, BACKLOG.md, CHANGELOG.md, README.md) are all naturally excluded.

### 2.2 Empirical analysis (descriptive — explains WHY the trigger is what it is)

The v11 fixture rows (`v11-realistic-ot`, `v11-flat-file`, `v11-tracker-on`) are built by `test-fixtures/build.sh` invoking `_run_v11_init` (`build.sh:124-128`), which calls `PACK="$PACK_ROOT" bash "$PACK_ROOT/scripts/init-project.sh" "$target"`. The `v11-realistic-ot` fixture additionally runs the per-entry decompose / regenerate / round-trip block (`build.sh:550-557`) which exercises `scripts/lib/migrate-v10-to-v11/decompose.sh` and friends. The empirical "v11-surface" set is the union of:

| Source path | Why it changes v11 fixture SHAs |
|---|---|
| `project-template/**` | Bulk of files copied by `init-project.sh` (trinity files, skills, agents, docs/, .claude/, .codex/, .gemini/, scripts/, tracker.toml.project-example, .github/ISSUE_TEMPLATE/, .gitignore) |
| `scripts/init-project.sh` | The installer itself; affects what gets copied and in what shape |
| `scripts/migrate-v10-to-v11.sh` and `scripts/lib/migrate-v10-to-v11/**` | Consumed by the `v11-realistic-ot` per-entry decompose block |
| `scripts/lib/migrator-core.sh` and `scripts/lib/migrator-*.sh` | Helpers transitively consumed by migrate scripts |
| `scripts/validate-pack.py` | Run inside the built `v11-realistic-ot` fixture as part of the round-trip block (build.sh comment §C5) |
| `supporting-docs/**` | NOT copied by `init-project.sh`. Empirical drift evidence: commits `cf67a96` (touched both `project-template/` and `supporting-docs/`), `62f9eec` (touched both), `479fef5` (touched only `scripts/` and `.github/workflows/` + pack-ops). Verified by reading `scripts/init-project.sh:418-908`: `$PACK/supporting-docs` is not in any copy path. **Conclusion: `supporting-docs/**` is NOT v11-surface — and is naturally excluded by the fuzzy top-level directory trigger because it sits outside both `project-template/` and `scripts/`.** |
| `.github/workflows/**` | NOT copied by `init-project.sh` (separate from `project-template/.github/`). NOT v11-surface. Naturally excluded by the fuzzy trigger (top-level `.github/`, not under either trigger directory). |

Every entry in the "is v11-surface" rows above lives under either `project-template/` or `scripts/`. Every entry in the "NOT v11-surface" rows lives outside both. The fuzzy directory trigger therefore catches the entire empirical surface AND is forward-compatible with new files added under either directory without requiring a rule update.

---

## 3. Action specificity — `--all --clean` vs `--name <fixture> --clean`

`bash test-fixtures/build.sh --all --clean` rebuilds all six fixtures from scratch. On a fast local machine this is ~30-90 seconds; on slower hardware it is several minutes. It is the safest default — actors do not need to identify which fixture rows are affected — but it has cost.

`bash test-fixtures/build.sh --name <fixture> --clean` rebuilds one fixture. It is fast but requires the actor to know which fixture(s) the change affects. For v11-surface changes, the three affected fixtures are `v11-realistic-ot`, `v11-flat-file`, `v11-tracker-on`. Running `--name` three times is mechanically equivalent to `--all` minus the v10 rebuilds. The v10-* fixtures are tag-pinned and never need rebuild for v11-surface changes (per `test-fixtures/README.md` § Determinism).

**Architect recommendation:** Default action is `bash test-fixtures/build.sh --all --clean`. Rationale:

1. **Safer default.** Identifying "which fixture rows are affected" is itself a per-edit judgment that an actor can get wrong — e.g., touching `scripts/lib/migrate-v10-to-v11/decompose.sh` only affects `v11-realistic-ot` today, but a future plan could route through `v11-tracker-on` and the actor wouldn't know. `--all --clean` is regenerate-by-construction.
2. **Manifest regeneration is the same operation either way.** `_update_manifest` (`build.sh:913-933`) writes SHAs for *every* fixture in `FIXTURE_NAMES` — partial rebuilds still write the manifest with whatever's-on-disk for unrebuilt rows. Running `--name <fixture>` without rebuilding the others would mix freshly-built v11-* SHAs with whatever stale v11-* SHAs happened to be on the working tree, defeating determinism. So the minimum safe form is "rebuild all v11-* rows then write manifest" — which is equivalent to `--all --clean` minus the v10 rebuilds.
3. **v10 rebuilds are cheap.** `v10-minimal` and `v10-realistic-ot` clone the v10 tag once via `_setup_v10_pack_src` (cached for both); they add seconds, not minutes.
4. **Trinity rules favor mechanical over conditional.** A rule that says "run X" is easier to enforce than "run X for changes to Y, run Z for changes to W." This is the same design principle that V11-9 followed in Batch 19b-1 (mechanical workflow-artifact list, no conditionals).

Mention of `--name <fixture> --clean` as a faster alternative IS appropriate in the **How to apply:** line for actors who are confident about scope, but the canonical default is `--all --clean`.

---

## 4. The bullet

### 4.1 Exact text

```
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

### 4.2 Size check against §5 success criterion

The bullet body is ~42 lines of wrapped prose (measured inside the code fence at §4.1; ~32 lines if counted by logical content paragraphs collapsing wrapped lines). Compare to existing `### Repo conventions` bullets in `CLAUDE.md` lines 369-448 (counted the same way — wrapped lines in source):

- RC1 (Per-entry trees vs mirrors): ~16 lines
- RC2 (BACKLOG.md has no Resolved): ~3 lines
- RC3 (Separate pack ops from pack product): ~4 lines
- RC4 (Test infra is self-provisioned): ~4 lines
- RC5 (Skill and agent maintenance): ~18-19 lines
- RC6 (Pack-repo code-comment deferrals): ~11 lines
- RC7 (Filename uniqueness heuristic): ~11 lines
- RC8 (Architect-doc-vs-reality reconciliation): ~11 lines

The proposed bullet at ~42 source lines is the longest in the sub-section by ~23 lines — measurably longer than the prior architect's ~28-line draft and the user's stated ~32-line target. The size growth came from three additions: the trigger-form change (fuzzy directory definition + intentionally-inclusive caveat, ~5 lines), the manifest-diff-as-authority sentence (~3 lines), and the post-rebuild conditional staging instruction in **How to apply:** (~3 lines). All three additions are load-bearing for the chosen trigger form. The §5 reference acceptance criterion is "comparable to existing bullets; clarity over brevity" — RC5 at ~19 lines is the prior longest and is acknowledged as "fine; most are ~5-10 lines." The new bullet is ~2.2x the longest existing; this is the largest single bullet by a meaningful margin and merits explicit acknowledgement here.

The bullet contains the most worked-example anchor information of any `### Repo conventions` entry (4 commit SHAs named, two file:line citations, one CI gate reference, plus the explicit "authority is the manifest diff after rebuild" caveat). If the planner wants to trim, the only safe trim targets are: (a) the trailing `--name <fixture> --clean` fast-path paragraph (could collapse to a single sentence: "Actors confident about scope may substitute `--name <fixture> --clean` per affected v11-* fixture then `--verify` before staging." — saves ~4 lines); (b) the full four-commit drift lineage in **Why:** (could drop `cf67a96` / `62f9eec` / `479fef5` / `a57dd04` and keep only `667d2dd` + `ef9e5c7` — saves ~5 lines, but loses the "drift accumulates across multiple commits" educational point that D-4 explicitly preserved). Architect recommendation: keep the full bullet — the manifest-diff-as-authority sentence is the load-bearing addition that distinguishes the fuzzy trigger from Form A, the fast-path alternative is short enough not to warrant trimming, and D-4 already settled the four-commit-lineage question. If the planner or reviewer disagrees with the size, escalate via Pack Chat triage rather than trimming silently.

---

## 5. Placement

**Decision: append as new bullet at end of `### Repo conventions`, after RC8 (Architect-doc-vs-reality reconciliation).**

### 5.1 Rationale

The bullet governs a repo-mechanical contract (fixture manifests, CI gate behavior, what counts as "v11-surface"). The natural neighbors are:

- **RC4 (Test infra is self-provisioned)** — closest sibling in spirit; both bullets govern test-fixture behavior. RC4 governs *provisioning* (scratch GH repos, `/tmp` clones); the new bullet governs *manifest maintenance*. The bullet body cross-references RC4 explicitly to avoid confusion about scope overlap.
- **RC5 (Skill and agent maintenance is mechanical)** — different topic (skill/agent surface).
- **RC8 (Architect-doc-vs-reality reconciliation)** — different topic (architect-doc carry-forward).

Inserting between RC4 and RC5 would put the new bullet immediately after its closest sibling, which has aesthetic appeal but breaks the chronological-add pattern that `### Repo conventions` has followed in Batch 19b-1 (new bullets appended at end; cross-refs link backward). The chronological pattern preserves git-blame readability: the manifest-regen bullet shows up at "added late" position, which matches its origin story (post-19b-1 incident).

### 5.2 Alternatives rejected

- **`### Workflow` sub-section near W6 "Deferred work needs a tracked anchor".** Rejected. W6 governs work-tracking discipline (where deferred work lives); manifest regeneration is not deferred work. `### Workflow` is for actor-process rules (review/fix cycles, status flips, deferral discipline). The manifest-regen rule is about a build artifact + a CI gate, which is repo-mechanical convention, not actor-process.
- **`### Agent invocation rules` sub-section.** Rejected. Agent-invocation governs HOW agents are spawned and prompted. Manifest regen is not invocation-related.
- **New sub-section (`### Build artifacts` or similar).** Rejected. A single bullet does not justify a new sub-section; `### Repo conventions` is the catch-all by design.

---

## 6. Classification — UNIVERSAL vs TOOL-SPECIFIC

**Classification: UNIVERSAL.** Byte-identical across CLAUDE.md / AGENTS.md / GEMINI.md per the trinity rule.

### 6.1 Rationale

The rule governs a repo-mechanical contract (run `test-fixtures/build.sh`, stage `test-fixtures/manifest.txt`). The operation is CLI-agnostic:

- Pack Chat (Claude Code) editing `project-template/` trinity directly: runs the build script.
- Pack-coder (any CLI: Claude / Codex / Gemini): runs the build script.
- Pack-architect / pack-planner / pack-reviewer / pack-docs-researcher: read the rule for behavioral context (they don't typically edit v11-surface, but if they do via working-tree writes, the same rule applies).

There is no CLI-specific enforcement mechanism, no CLI-specific tool, no CLI-specific behavior. Contrast with the existing trinity bullets that carry "Trinity exemption" notes:

- `### Sub-agent behavior (Claude-only)` sub-section: Claude-Code-specific because Agent tool, `run_in_background`, Agent Teams, and SendMessage are Claude-Code-specific features.
- W14 "Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern" — the preamble is platform-neutral but the ENFORCEMENT mechanism (SendMessage classifier) is Claude-Code-specific, hence the in-bullet platform-conditional note.

The manifest-regen rule has no such platform conditional. It is purely a "run X command, stage Y file" instruction. Trinity rule applies cleanly.

### 6.2 Per-CLI variant work

**None.** Byte-identical text in all three trinity files. The planner-handoff is three identical Write edits.

---

## 7. Cross-references

### 7.1 Bullets the new rule references in its body

- **RC4 (Test infra is self-provisioned)** — explicit cross-reference: "the 'Test infra is self-provisioned' bullet above governs *test provisioning*; this bullet governs *manifest maintenance*." This forestalls the "isn't this already covered by RC4?" reader question.

### 7.2 Bullets that should reference the new rule (none)

No existing bullet needs editing to cross-reference the new rule. The new rule is self-contained: it names its trigger (file globs), its action (build.sh invocation), its rationale (CI gate + 2026-05-17 incident), and its scope-distinction from RC4.

### 7.3 External anchors named in the body

- `test-fixtures/README.md` § Determinism — canonical drift-design statement (file-level reference, no symbol/line).
- `test-fixtures/build.sh:903-912` — `_update_manifest` comment (file + symbol — `_update_manifest` is the stable symbol; the line range is included for navigation but symbol is the load-bearing anchor per RC8 worked-example pattern).
- Commits `667d2dd`, `ef9e5c7`, `cf67a96`, `62f9eec`, `479fef5`, `a57dd04` — historical anchors for the incident lineage.
- CI gate: `fixture manifest verify` step (BD-115, RELEASE-GATE item 5) — names the gate that the rule protects.

The cross-reference set follows RC6's "cross-reference: the project-template section is canonical" model and RC8's "Worked example: BD-119 §9.2 addendum" model — pattern in trinity, worked-example anchor by name (commit SHA / file path / CI step name), not by file:line.

---

## 8. Trigger specificity — three forms considered, fuzzy directory chosen

### 8.1 The three candidate forms

The architect doc considered three ways to express the trigger:

- **Form A (exact glob list):** "Any commit that touches `project-template/**`, `scripts/init-project.sh`, `scripts/migrate-v10-to-v11.sh`, `scripts/lib/**`, or `scripts/validate-pack.py`."
- **Form B (heuristic phrase):** "Any commit that touches files copied or executed by `scripts/init-project.sh` or `test-fixtures/build.sh`."
- **Form C (fuzzy top-level directory — CHOSEN):** "Any commit whose diff includes a file under `project-template/` or `scripts/`."

### 8.2 Form A vs Form B (prior architect comparison — preserved for audit trail)

The prior architect draft recommended **Form A (glob list)** with this rationale:

1. **Unambiguous for pack-coder.** Pack-coder agents have empirically been mechanical and benefit from explicit triggers. Form B requires the agent to know which files are "copied or executed," which is a transitive judgment.
2. **Auditable.** Form A can be verified by `grep` against the diff; Form B requires reading `init-project.sh` and `build.sh` to enumerate.
3. **Drift cost is bounded.** The glob list will need updating when v11-surface expands (e.g., when v12 adds new script paths). That update is itself a trinity edit and follows the same pattern as RC5's enumerated workflow-artifact list (which has been updated multiple times — V11-9 in Batch 19b-1 added two patterns).

The drift cost was acknowledged as a known weakness. User override (D-2) introduced Form C, which addresses the drift weakness directly.

### 8.3 Form C (fuzzy directory) — analysis and chosen form

**Form C catches all current v11-surface AND any future files added under either directory without rule update.** The two trigger directories (`project-template/`, `scripts/`) are pack-architecture-stable top-level names: only a major top-level restructure (e.g., v12 introducing a new top-level pack directory) would require a rule update, which is an appropriate-scope event at that point (an architect pass would already be reviewing trinity at that time).

**Cost/benefit comparison vs Form A:**

| Aspect | Form A (exact list) | Form C (fuzzy directory) |
|---|---|---|
| Trigger precision | Exact file list | Two directory names |
| Staleness risk | High — new v11-surface files require list update | Low — only restructure changes the trigger |
| False positives | ~0 | Some `scripts/test-*.sh` edits trigger unnecessary rebuilds (~30-90s wasted) |
| False negatives within v11-surface | Possible if new file added outside the list | Impossible |
| Maintenance burden | Update list when v11-surface expands | Update only on major restructure (rare) |
| Auditability | grep against exact paths | grep against `^project-template/\|^scripts/` |

**Form B vs Form C:** Form B's "files copied or executed by `scripts/init-project.sh` or `test-fixtures/build.sh`" is shorter than Form A but still requires interpretation (which files are transitively executed?). Form C is similarly short but requires no interpretation — the trigger is mechanical (top-level directory check).

**Form C addresses the "authority shift" insight separately:** even with Form C, the canonical authority for "is this commit v11-surface?" is the manifest diff after rebuild, not the trigger globs. False positives (Form C's only weakness vs Form A) are detected at rebuild time — an empty `git diff test-fixtures/manifest.txt` after `--all --clean` proves the edit wasn't v11-surface. The cost is wasted rebuild time (~30-90s), not incorrect manifest content. See §2.1 rationale point 5 and §4.1 **How to apply:** for the full pattern.

**Conclusion: Form C (fuzzy directory) is the chosen trigger form per user D-2 override.** The bullet in §4.1 reflects Form C; the empirical table in §2.2 explains WHY Form C captures the actual v11-surface (descriptive, not prescriptive).

---

## 9. OPEN QUESTIONS for planner

### D-1 — `--all --clean` vs `--name <fixture> --clean` default

Architect recommendation: `--all --clean` as canonical; `--name` as fast-path-alternative for confident actors. See §3.

**Resolution path:** accept architect recommendation, or override with `--name <fixture>` as the canonical default and document the actor's responsibility to identify affected fixture(s).

### D-2 — Form A (glob list) vs Form B (heuristic phrase) vs Form C (fuzzy directory)

**RESOLVED — fuzzy directory trigger (Form C) per user override.** User reasoning: Form A creates staleness / domino-maintenance problem when v11-surface expands; Form B is interpretive. Form C — "any commit touching files under `project-template/` or `scripts/`" — uses architecture-stable top-level directory names, auto-includes new files added under either directory, and shifts the load-bearing authority to the manifest diff after rebuild (not the trigger globs themselves). See updated §2.1 (rationale), §4.1 (bullet text), and §8.3 (form analysis).

**Resolution status:** ACCEPTED (user override of architect recommendation).

### D-3 — Bullet placement

Architect recommendation: append at end of `### Repo conventions` after RC8. See §5.

**Resolution path:** accept, or override to `### Workflow` near W6, or override to a new sub-section.

### D-4 — Incident lineage in **Why:** line

Architect recommendation: keep full four-commit lineage (`cf67a96` + `62f9eec` + `479fef5` cumulative drift; `667d2dd` proximate failure; `ef9e5c7` recovery; `a57dd04` last-clean baseline).

**Resolution path:** accept, or trim to just `667d2dd` + `ef9e5c7` (proximate cause + recovery only).

### D-5 — Cross-link from `test-fixtures/README.md` § Determinism back to the trinity rule

Architect recommendation: **out of scope for this batch.** The trinity bullet references the README; the README does not currently reference the trinity. Adding the reverse-link would be a `project-template/`-free pack-ops edit, but it triggers a build-process change (README content does not affect v11 fixtures because `test-fixtures/README.md` is not in v11-surface, so the edit would NOT trigger a manifest regen — meta-clean). Architect recommends planner notes this as a potential follow-up (one-line README addendum) but does not include it in the 19b-2 commit, to keep the commit minimal.

**Resolution path:** accept (defer), or include the README addendum in the same commit.

---

## 10. Planner handoff — scope of file edits

### 10.1 File edits required (decided)

1. `CLAUDE.md` — append new bullet at end of `### Repo conventions` (after the "Architect-doc-vs-reality reconciliation" bullet). One Write/Edit, ~42 source lines added (~32 logical lines after collapsing wrapped prose; see §4.2 for size analysis).
2. `AGENTS.md` — same edit, byte-identical text. The current `AGENTS.md` `### Repo conventions` sub-section mirrors CLAUDE.md byte-for-byte after Batch 19b-1 (`667d2dd`); planner must verify this assumption holds at coder-spawn time and produce the same edit.
3. `GEMINI.md` — same edit, byte-identical text where text appears verbatim. GEMINI.md uses a slightly tighter prose form in some places; planner must verify the `### Repo conventions` section in GEMINI.md mirrors CLAUDE.md/AGENTS.md and apply the same edit, OR if GEMINI.md uses tighter wording for `### Repo conventions` (per Batch 19b-1 precedent in V11-9), produce the tighter-wording version that preserves the same rule semantics.

**Verification step pre-edit:** planner runs `diff <(sed -n '/### Repo conventions/,/^### /p' CLAUDE.md) <(sed -n '/### Repo conventions/,/^### /p' AGENTS.md)` and the same against GEMINI.md to confirm current parity state. Per CI Check 24 (byte-identity for trinity), CLAUDE.md and AGENTS.md `## Pack memory` body should be byte-identical; GEMINI.md is allowed prose-form divergence.

### 10.2 File edits OUT of scope

- `test-fixtures/README.md` — D-5 deferred.
- `test-fixtures/build.sh` comment — the `_update_manifest` comment at lines 903-912 already names the design intent; no edit needed.
- `PACK-CHAT.md` — the trinity bullet IS the rule; no PACK-CHAT.md companion rule is needed.
- `PACK-AGENTS.md` — trinity bullets are read by all agents per `## Pack memory` convention; no PACK-AGENTS.md cross-ref needed.
- `project-template/**` — out of scope per OQ-3 (pack-self only).
- pack-coder agent definitions (`.claude/agents/pack-coder.md` / `.codex/agents/pack-coder.toml` / `.gemini/agents/pack-coder.toml`) — option (C) was rejected in user discussion; the trinity bullet replaces option (C).

### 10.3 Memory cache (Claude-only)

Per the Batch 19b-1 trinity-first design (Tier 1.5 pointer-only Claude cache, per `ARCHITECTURE-CLEANUP-BATCH-19B-V2.md` §A.1), a new pointer file should be added to `~/.claude/projects/<slug>/memory/` referencing the new trinity bullet. This is a Claude-side memory addition that mirrors how Batch 19b-1 added pointer entries for newly-promoted bullets (`feedback-deferral-is-scope-creep`, `feedback-pack-coder-preflight-pattern`, etc. — see MEMORY.md). Suggested entry:

- File: `feedback_manifest_regen_on_v11_surface.md`
- Title: `Regenerate test-fixtures/manifest.txt on v11-surface commits`
- Body: one-line summary + trinity anchor link (`CLAUDE.md` `### Repo conventions` last bullet).

The memory edit is Pack-Chat-direct per the Pack-Chat-direct list ("Memory files (`~/.claude/projects/<slug>/memory/*.md`) — Pack Chat's own operating state, not pack work"). It is NOT in the pack-coder's scope. Pack Chat lands the memory edit AFTER the trinity commit lands (or in the same approve-and-stage cycle if Pack Chat prefers).

### 10.4 Commit message

Suggested commit message (planner may refine):

```
feat: v11 — Batch 19b-2 trinity manifest-regen rule (RC9)

Add `### Repo conventions` bullet codifying:
- regenerate `test-fixtures/manifest.txt` on every commit that touches
  v11-surface (files under `project-template/` or `scripts/`)
- canonical default action: `bash test-fixtures/build.sh --all --clean`
- authority is the manifest diff after rebuild, not the trigger globs
- worked-example incident: 2026-05-17 (commit `667d2dd` v11-surface
  edit landed without manifest regen, CI's `fixture manifest verify`
  step failed, recovery commit `ef9e5c7` regenerated manifest as a
  separate `fix:` commit; drift accumulated across `cf67a96` +
  `62f9eec` + `479fef5` since last manifest regen at `a57dd04`)

Trinity rule: CLAUDE.md / AGENTS.md byte-identical; GEMINI.md prose
form may diverge if existing `### Repo conventions` is already tighter.

See: maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B-MANIFEST-REGEN-RULE.md
```

The commit message follows the `feat: vN — Batch Nx description` shape sanctioned by the trinity "Commit message format" section (CLAUDE.md lines 41-53). Note this is NOT a `fix:` commit (which would attach to a single BD); it is a `feat:` commit (adds a new standing rule).

### 10.5 Review/fix cycle

This is a single-BD-equivalent (one bullet, three files). Per the trinity `### Workflow` rule "Per-BD review/fix runs INLINE, before next BD's coder spawns," a pack-reviewer pass after the coder lands the three trinity edits is the standard pattern. Pack-reviewer scope: byte-identity check across the three trinity files, **Why:** line accuracy, **How to apply:** line accuracy, cross-reference to RC4 reads correctly, no inadvertent edits outside `### Repo conventions`.

---

## 11. Architect doc summary

| Element | Decision |
|---|---|
| Bullet text | §4.1 — ~32-line `### Repo conventions` bullet titled "Regenerate test-fixtures/manifest.txt on every v11-surface commit." |
| Placement | End of `### Repo conventions`, after RC8 (Architect-doc-vs-reality reconciliation) |
| Classification | UNIVERSAL — byte-identical across CLAUDE.md / AGENTS.md / GEMINI.md (with GEMINI.md prose-form latitude per existing convention) |
| Cross-references | RC4 (Test infra is self-provisioned) — distinguished as test-provisioning-vs-manifest-maintenance |
| Trigger | Fuzzy directory glob — `project-template/` OR `scripts/` (top-level). Authority for v11-surface determination is the manifest diff after `--all --clean` rebuild; trigger globs are a screen for WHEN to run the rebuild. |
| Action | Canonical default `bash test-fixtures/build.sh --all --clean`; fast-path alternative `--name <fixture> --clean` per affected v11-* fixture |
| **Why:** anchor | 2026-05-17 incident — full four-commit drift lineage |
| **How to apply:** | Run build.sh, `git add test-fixtures/manifest.txt` alongside scope edits in SAME commit |
| Planner scope | 3 trinity-file edits (byte-identical for Claude/AGENTS; GEMINI prose-form latitude), 1 Claude memory cache pointer file (Pack-Chat-direct, post-commit), 0 other files |
| Out of scope | `test-fixtures/README.md` reverse-link (D-5 deferred), `project-template/**` edits (OQ-3 pack-self), pack-coder agent definitions (option C rejected) |

---

## 12. Out of scope (forward-pointing)

- **`test-fixtures/README.md` reverse-link to the trinity rule.** Could be added in a follow-up batch as a one-line addendum to § Determinism naming the trinity bullet as the standing rule. Not blocked by anything. Sized at ~3 lines. Per `feedback-deferral-is-scope-creep`, this should land in v11.0 — recommend Pack Chat discusses with user whether to include in 19b-2 commit (D-5 above) or schedule as a follow-up 19b-3 commit.
- **Project-template trinity propagation.** Per OQ-3 (Batch 19b-V2 §A.8 / §A.9), project-template trinity edits are explicitly out of scope for the entire Batch 19b sequence. If pack-coder agents working inside CLIENT projects (where `test-fixtures/` does not exist) should follow a parallel rule about regenerating client-side build artifacts, that is a separate future architect pass keyed off the user's eventual "transfer to project side" conversation.
- **Pre-push git hook (option A).** Rejected per user discussion. If the trinity rule proves insufficient (recurring incidents), option A can be revisited as a defense-in-depth complement. Not in v11.0 scope.
- **CI auto-regen (option D).** Rejected per user discussion. Same defense-in-depth caveat as option A.
