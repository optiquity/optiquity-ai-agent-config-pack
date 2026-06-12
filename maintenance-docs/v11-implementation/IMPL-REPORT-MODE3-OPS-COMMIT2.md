# IMPL-REPORT-MODE3-OPS-COMMIT2 — BD-204 Mode-3 ops contract, Commit 2 (code/verbs/validation)

> **Agent:** pack-coder (fresh instance). **Date:** 2026-06-12 session.
> **Branch:** `v11-dev`. **HEAD (unchanged start to end):**
> `358310e4e3586fd94d838e0097954c804638f530` (`git rev-parse HEAD`); cwd
> `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`.
> **Authorities applied (later wins):** PLAN-BD-204-MODE3-OPS-CONTRACT.md →
> ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md →
> ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT-2.md (NORMATIVE; its §B8
> D2 delta table is the task list). The first `...-AMENDMENT.md` is
> SUPERSEDED — read for recognition only; its content verified ABSENT from
> the diff (§7).
> **Routed findings closed:** PACK-REVIEW-MODE3-OPS-COMMIT1-REVIEW3.md
> NIT-1, NIT-2A, NIT-2B (§6).
> **No live GitHub calls intended; zero `gh` invocations by this agent;
> one unintended indirect exposure found MID-RUN and closed — see POQ-2.**
> All commands FOREGROUND; no background tasks armed; no git
> state-changing verbs.

---

## 1. Pre-flight (verbatim evidence)

```
$ git rev-parse HEAD
358310e4e3586fd94d838e0097954c804638f530
$ git rev-parse --abbrev-ref HEAD
v11-dev
$ git status --short        # at start
?? tracker.toml             # the live Pack-Chat-owned Mode-3 state — NEVER touched
$ pwd
/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev
```

Base verified: the Commit-1 docs state is present (`backlog/_rules.md`
carries "Flat-file mode"/"Tracker mode" headings; `changelog/_rules.md`
carries "Mode invariance" — measure-then-bound precondition B1 satisfied,
verified by grep before wiring the Check 32′ extension). The live
`tracker.toml` (23 lines) and `.pack-tracker/` were never edited; at end
of session the live `tracker.toml` is no longer `??` because the new
root-anchored `/tracker.toml` ignore rule covers it (`git check-ignore`
→ `.gitignore:17:/tracker.toml`) — the FILE BYTES are untouched
(`wc -l tracker.toml` → 23 before and after).

## 2. Per-deliverable summary (D2 table mapping)

| D2 row | Files | What landed |
|---|---|---|
| D2-1 verbs | `scripts/pack-tracker.sh` (+356/−2) | `cmd_tree_rebuild` (flags `--repo-root`/`--force`; fail-loud tracker-mode gate; fail-loud pack-surface-only gate naming BD-207; engine call `tracker_migrate_reverse_run <root> 0 0 0 <force> 1`); thin `cmd_edit` (flag→patch-JSON 1:1 mapping onto `tracker_edit_entry`'s documented keys, incl. repeatable `--add-label`/`--remove-label` and sentinel-guarded `--raw-body-file`/`--body-file` reads; empty-patch refusal); `cmd_new_entry` (gates: pack surface, tracker mode, `^BD-[0-9]+$` id shape per BD-211, duplicate-id refusal against the id-map; parses the verbatim entry span through the REAL `_tmf_parse_backlog_file`; composes via `tmf_compose_issue_body`; labels via `_tmf_labels_for_entry`; `provider_create`; `tmf_mapping_set`+`tmf_mapping_save`; `tracker_edit_stamp_last_write`; finishes with the tree-rebuild path — NO new codec, NO raw `gh`); `usage()` rows + header comment + dispatch entries for all three. |
| D2-1 engine | `scripts/lib/tracker-migrate-reverse.sh` (+156/−12) | `tracker_migrate_reverse_run` gains the 6th positional `tree_only` (default 0): pack branch with `tree_only=1` runs roster → reconstruct (all guards intact) → `_tmr_emit_pack_tree` (whose final action is `per_entry_regenerate_toc` — `_toc.md` regen inherited by construction) → timestamp stamp; SKIPS `_tmr_emit_implementation_plan`, `_tmr_emit_status`, and the header strips; dedicated `tree-rebuild: complete` summary (tree-only, never flips). Engine-seam guard: `tree_only=1` + `surface!=pack` fails loud naming BD-207 (defensive double of the verb gate; client emit code untouched). NEW `_tmr_check_status_coherence` (blocking comparator, §3 layer 1: first blob `Status:` line vs `_tmr_decode_status` projection; fail loud naming pack-id + BOTH values + the recovery instruction `pack tracker edit --status <blob-status> ...`; `--force` = blob-wins with a WARN, matching `_tmr_check_blob_h2_divergence` semantics; skip when no blob or no `Status:` line — field-faithful) invoked in `tracker_migrate_reverse_reconstruct` beside the body comparator. `_tmr_update_tracker_toml` gains arg 3 `stamp_tree_regen`; the orchestrator passes 1 on every PACK tree materialization (tree_only arm AND full reverse/disable) → `migration.last_tree_regen` stamped in the LOCAL tracker.toml. Silent-data-loss guard message surface-neutralized: "Reconstructing the flat-file state now would drop…". |
| D2-1 freshness | `scripts/lib/tracker-edit.sh` (+65) | NEW `tracker_edit_stamp_last_write <cfg>` (the `set_in_section` writer pattern; no-op on absent cfg; docstring names consumers by file+symbol). `tracker_edit_entry` calls it ONLY after the full mutation sequence (provider_update + any DP-3 boundary cross) succeeds — failures return before the stamp. |
| D2-1 ride-along (a) | `scripts/lib/tracker-migrate-forward.sh` (+1/−1) | `mirror_only` pack-surface fail-loud message gains "Run \`pack tracker tree-rebuild\` instead". |
| D2-1 help | `scripts/tracker-migrate.sh` (+4) | `reverse` usage note: pack-surface routine refresh is `pack tracker tree-rebuild`; `reverse` is the full reverse/disable path. |
| D2-1 doctor | `scripts/lib/tracker-doctor.sh` (+115/−19) | Leg (d) pack arm REPOINTED: `_toc.md`-mtime heuristic retired; compares `migration.last_tracker_write` vs `migration.last_tree_regen` (lexicographic ISO-8601-Z); WARN "tree is stale relative to tracker writes → Run: pack tracker tree-rebuild"; `_toc.md`-present OK/INFO lines kept; absent-key tolerance = INFO, not WARN (R4 — live repo stays rc=0 until first stamp). NEW leg (h): status-coherence ADVISORY — tracker mode + pack surface only; ONE paginated `provider_list '{"label":"bd-entry","state":"all"}'` read (no per-issue `provider_get` sweep); per-item blob decode via `_tmr_decode_body_blob` + projection via `_tmr_decode_status`; WARN per mismatch with the same recovery text; INFO-skip in flat-file mode / decoders-unsourced / provider-unavailable (leg-(g) graceful-degradation pattern); client arm untouched (BD-207). |
| D2-1 provider | `scripts/lib/tracker-provider-gh.sh` (+12/−1) | `_gh_list_fields` gains `body,stateReason`; the list normalizer maps `body` + lowercased `state_reason` — the seam that lets leg (h) read labels + state + body in ONE list call (additive; existing consumers unaffected; zero test pins on the field string — verified by grep). **Plan deviation PD-A (file not in the PLAN §3.1 list; required by the architecture §3 layer-2 / §4.1 leg-(h) "one paginated read" contract).** |
| D2-5 validator | `scripts/validate-pack.py` (+78/−6) | Check 32′ extension: NEW module constant `_RULES_MODE_MARKERS` (allowlist sized to exactly `pack-backlog` → ("Flat-file mode","Tracker mode") and `pack-changelog` → ("Mode invariance",)); marker-PRESENCE assertion in `check_mirror_in_sync` after the `_rules.md`-present leg (no prose-pinning). Check 29″ never-tracked leg in `check_tracker_config`: FAIL iff `git -C REPO_ROOT ls-files --error-unmatch tracker.toml` rc==0 (TRACKED), with the untrack recovery `git rm --cached tracker.toml`; soft-pass on absent/untracked/non-git-roots. Header docstring items 29 + 32 and both functions' docstrings updated in lock-step. |
| D2-3 gitignore | `.gitignore` (+5) | ROOT-ANCHORED `/tracker.toml` appended to the BD-061 tracker-state block with the §B5-surface-6 comment ("the repo's committed state is always flat-file; your local mode survives pulls") + the anchoring rationale naming the committed fixtures. Anchoring proof in §4. |
| D2-4 docs | `tracker.toml.pack-example` (+22/−2), `pack-ops/HELP-FRAGMENT-TRACKER.md` (+9/−3), `pack-ops/HELP-FRAGMENT-PACK.md` (+1/−1), `pack-ops/OPTIONAL-FEATURES.md` (+4/−1) | Pack-example header rewritten per §B5 surface 5 (LOCAL + gitignored; never committed; sticky across pulls/version bumps; committed repo always flat-file; published-tree + single-writer pointer to `/backlog/_rules.md`) + `[mode]` comment gains the local clause. TRACKER fragment: init row gains the local-gitignored clause (§B5 surface 7); NIT-2B closed (§6); rows added for `tree-rebuild`/`edit`/`new-entry`; doctor row mentions tree freshness + status coherence; colloquial mappings updated. PACK fragment: verb list row gains `tree-rebuild`, `edit`, `new-entry`. OPTIONAL-FEATURES: one §B5-surface-9 sentence (pack `tracker.toml` is LOCAL and gitignored; committed repo ships flat-file). |
| Routed findings | trinity ×3, `README.md`, pack-startup ×3 | §6 below. |
| Test legs | 6 suites | §5 below. |
| D2-7 manifest | `test-fixtures/manifest.txt` | Rebuilt `--all --clean`; diff EMPTY → does NOT ride this commit (§8). |

## 3. New symbols (file + symbol, per architect-doc-vs-reality)

- `scripts/lib/tracker-migrate-reverse.sh` — `_tmr_check_status_coherence`
  (blocking comparator; advisory counterpart named in docstring:
  `tracker_doctor_run` leg (h)); `tracker_migrate_reverse_run` `tree_only`
  arm (caller named: `cmd_tree_rebuild` in `scripts/pack-tracker.sh`);
  `_tmr_update_tracker_toml` `stamp_tree_regen` (consumer named:
  `tracker_doctor_run` leg (d); local-key home per AMENDMENT-2 §B3).
- `scripts/lib/tracker-edit.sh` — `tracker_edit_stamp_last_write`
  (callers named: `tracker_edit_entry`, `cmd_new_entry`; consumer named:
  `tracker_doctor_run` leg (d)).
- `scripts/pack-tracker.sh` — `cmd_tree_rebuild`, `cmd_edit`,
  `cmd_new_entry` (each docstring cites the architecture §2/§3 + OQ-A and
  AMENDMENT-2 §B8 D2 by name).
- `scripts/validate-pack.py` — `_RULES_MODE_MARKERS`; Check 29″ leg inside
  `check_tracker_config`.

**D2-8 reconciliation:** this report cross-references
`ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT-2.md` as the NORMATIVE
supersession record (ops-contract §2 freshness rationale → §B3 local keys;
§1.1/§1.3 staging text → D1-2/D1-4; prior amendment §A1–§A5 dissolved per
§B2). The in-code docstrings above carry the matching file+symbol chain
(never line numbers).

## 4. Gitignore anchoring proof (commands + verbatim output)

```
BEFORE the edit:
$ git ls-files | grep "tracker.toml"
project-template/tracker.toml.project-example
scripts/tests/fixtures/roundtrip/bd-v11.0/tracker.toml
scripts/tests/fixtures/tracker-bd204-lossless/tracker.toml
scripts/tests/fixtures/tracker-migrate/tracker.toml
tracker.toml.pack-example
$ git check-ignore -v tracker.toml   → rc=1 (NOT ignored; merely untracked)

AFTER the edit:
$ git check-ignore -v tracker.toml
.gitignore:17:/tracker.toml	tracker.toml          ← rc=0 (root file ignored)
$ git check-ignore -v scripts/tests/fixtures/tracker-migrate/tracker.toml \
    scripts/tests/fixtures/roundtrip/bd-v11.0/tracker.toml \
    scripts/tests/fixtures/tracker-bd204-lossless/tracker.toml
(no output) → rc=1                                  ← fixtures NOT ignored
$ git ls-files | grep -c "tracker.toml"
5                                                   ← tracked set unchanged
```

Plus the CI realization: Check 29″ fails any future `git add -f` of the
live file (per-check legs 18a/18b/18c in
`scripts/tests/tracker-config-schema-test.sh`, all PASS).

## 5. Test legs landed (plan §5 inventory → host suites; all PASS)

| Plan leg | Where | Result evidence |
|---|---|---|
| 1 happy path | `tracker-migrate-reverse-test.sh` 8.1 (9 assertions: tree + `_toc.md`; `last_tree_regen` stamped; `mode.state` unchanged; NO root STATUS.md/IMPLEMENTATION-PLAN.md; no monolith) | all PASS |
| 2 flat-file refusal | 8.3 (typed validation; "not in tracker mode"; "the per-entry tree is the SSOT in flat-file mode") | all PASS |
| 3 mirror-rebuild names tree-rebuild | `tracker-migrate-forward-test.sh` 4.5 new assertion | PASS |
| 4 client mirror-rebuild byte-unchanged | `tracker-migrate-forward-test.sh` NEW 4.5b (rc=0; "BACKLOG.md mirror header refreshed"; header written; body preserved) | all PASS |
| 5 coherence comparator | `tracker-migrate-reverse-test.sh` 8.5 unit (fail-loud names pack-id + BOTH values + recovery verb; `--force` rc=0 + WARN; match passes; no-Status skips) + 8.5 e2e (divergent issue BLOCKS tree-rebuild, no tree file written; `--force` → blob's `Status: Resolved` reaches the tree file) | all PASS |
| 6 stamp on success not failure | `tracker-provider-test.sh` 4.9a/4.9b/4.9c (success stamps; failed update no stamp; failed boundary cross no stamp) | all PASS |
| 7 doctor legs | `tracker-bd130-doctor-wired-test.sh` Group 9: 9.1 absent-keys INFO tolerance; 9.2 stale-tree WARN + "→ Run: pack tracker tree-rebuild" + rc=1; 9.3 fresh OK; 9.4 coherence WARN on mocked divergent issue (blob via PRODUCTION `_tmf_gz64_encode`) naming "→ Run: pack tracker edit --status Resolved"; 9.5 flat-file INFO-skip | all PASS |
| 8 hand-edit overwrite (the contract's teeth) | 8.2: sentinel appended to `backlog/BD-001.md` → second tree-rebuild → **sentinel GONE; file byte-equal to pre-edit regenerated content** | all PASS |
| 9 client refusal names BD-207 | 8.4 (verb gate + the engine-seam guard, both refuse naming BD-207) | all PASS |
| 10 OQ-A verbs | `tracker-provider-test.sh` NEW Group 5: 5.1 new-entry e2e (compose carries pack-id marker + gz64 blob + H2; labels = bd-entry/status:open/template:bd-v11.0 via the forward map; id-map BD-002→77; `last_tracker_write` stamped; tree file materialized with lines 2..EOF BYTE-EQUAL to the input span via `cmp`; `_toc.md` regenerated); 5.2 duplicate-id refusal; 5.3 id-shape + id/body-mismatch refusals; 5.4 edit flag→patch mapping drives `issue edit 77` label swap + `issue close 77 --reason completed`; 5.5 content edit recomposes blob+H2; 5.6 empty-patch refusal | all PASS |
| 11 Check 32′ markers | `test-validate-pack-checks-32-33-34.sh`: fixture `_rules.md` builders gain the markers (green path re-proven by A1/A6/F1); NEW A7 (both markers absent → rc=1, banner names "missing required mode marker" + both marker names + BD-204), A7b (one absent → names exactly the missing one), F6 ("Mode invariance" absent → rc=1) | all PASS |
| 29″ per-check | `tracker-config-schema-test.sh` NEW Test 18: 18a non-git soft-pass banner; 18b untracked → rc=0 + OK banner; 18c COMMITTED → rc!=0 + "git-TRACKED" + "git rm --cached tracker.toml" (scratch git repos self-provisioned + cleaned) | all PASS |
| guard-message pins | 8.6 static pins: new "Reconstructing the flat-file state now would drop" present; old "Reconstructing BACKLOG.md now would drop" absent (zero pre-existing test pins on the old text — grep-verified) | all PASS |

Hermeticity fix that rides along: the reverse suite's Group 6 doctor
invocations now run under the suite's fake gh (the new leg (h) calls
`provider_list` on tracker-mode fixtures; without the wrap the real `gh`
binary would be invoked) — see POQ-2.

## 6. Routed-findings closure (REVIEW3 NIT-1 / NIT-2A / NIT-2B)

- **NIT-2A (pack-startup detection):** all three copies now read
  "`tracker.toml` exists at the pack root, its `[mode] state` is
  `\"tracker\"`, AND its `[migration] forward_complete` is `true` (the
  same three-part test `tracker_mode()` in `scripts/lib/tracker-config.sh`
  applies)". Parity proof: `.claude` and `.codex` SKILL.md byte-identical —
  `shasum` `766e9ea9997edd7aac4fdcd79c1e267585102859` ×2; the `.gemini`
  command's prompt body diffed byte-equal to the SKILL body
  (`diff <(sed -n '7,$p' .claude/.../SKILL.md) <(sed -n '4,$p'
  .gemini/commands/pack-startup.toml | sed '$d')` → "gemini prompt body ==
  skill body").
- **NIT-1 (unconditional "sole SSOT" phrasing):** the minimal mode-aware
  qualifier — the clause `(committed state)` / `(committed state; …)` —
  added at every census site: trinity head lines (3 sites per file ×3
  files; clause census `grep -o "(committed state[;)]"` → exactly
  `2× "(committed state)" + 1× "(committed state;"` in EACH of
  CLAUDE/AGENTS/GEMINI); README layout rows 185/187/278/279 (", committed
  state" inside the existing parentheticals); pack-startup Step-2 prose ×3
  ("the SOLE source of truth and readable form of the committed state
  (…the committed repo is always flat-file — a local tracker opt-in
  changes the write channel)").
- **Trinity parity hashes:** CLAUDE.md and AGENTS.md added-diff-hunks
  byte-identical — shasum `8a85dbe695a4ab01645c549d89a4fd3c9aab7d5e` ×2;
  GEMINI.md added-hunk `9442e7f8a87887887283fa7d6c790a7d6fb42151` differs
  ONLY because its head section is the pre-existing condensed-prose form
  (same clause set, same count — census above). validate-pack
  trinity-parity + Check 18 legs green in both runs.
- **NIT-2B (stale `mirror-rebuild` rows in `pack-ops/HELP-FRAGMENT-TRACKER.md`):**
  the verb-table row now reads "Client surface only: … On the pack
  surface this fails loud — use `pack tracker tree-rebuild`"; the
  colloquial mapping row is split ("rebuild the tree" → `tree-rebuild`
  (pack repo); "rebuild the mirror"/"regenerate BACKLOG.md" →
  `mirror-rebuild` (client surface; the pack repo has no mirror)).

## 7. Superseded-content absence + hygiene proofs

```
$ git diff | grep -c "tracker-id-map\|pack-ops/tracker-id-map\|!negation"
0          ← the SUPERSEDED first amendment's content is ABSENT
$ git diff | grep -E "^\+" | grep -in "phase"
4 hits, ALL in scripts/lib/tracker-migrate-reverse.sh: two code-comment
uses of the file's PRE-EXISTING "legacy/phase issues" idiom (the
no-blob skip class) and two MOVED (re-indented) pre-existing engine
lines (`_tmr_emit_implementation_plan "$phase_jsons"` …). ZERO hits on
any prose/doc surface (pack-ops/, trinity, README, examples, skills) —
consistent with pack-side-project-concepts-deliverable-only (the
tracker engine constructs project-side deliverables).
$ git diff added lines, line-number-reference grep → only "lines 2..EOF"
  (the entry-span structural convention, not a drifting line citation).
```

Live state untouched: `tracker.toml` 23 lines before and after;
`.pack-tracker/` never opened for write. No `rm` outside `mktemp`
scratch + test fixtures' own `trap` cleanup.

## 8. Manifest state

`bash test-fixtures/build.sh --all --clean` → rc=0;
`git diff test-fixtures/manifest.txt` → **EMPTY (0 lines)**;
`bash test-fixtures/build.sh --verify` → **6/6 rows OK** (v10-minimal
`19558cb…`, v10-realistic-ot `4c62945…`, v11-realistic-ot `ae3fc6f…`,
v11-flat-file `f9705c2…`, v11-tracker-on `944ddee…`,
existing-project-mid-dev `a54e081…`).

The 4-directory trigger fired (`scripts/` + `pack-ops/` touched), the
rebuild ran, and the diff is empty: none of this commit's files are
client-copied (the sanctioned pack-side-shipped set is exactly
`{scripts/lib/detect.sh, scripts/pack-help.sh}`, untouched; the
client-copied pack-ops file is the PROJECT-TEMPLATE TRACKER fragment, not
the pack-ops one). Per the trinity rule's canonical-authority clause
(empty diff → nothing to stage), **`test-fixtures/manifest.txt` does NOT
ride this commit** — a deviation from the PLAN §3.4 *expectation*
("manifest WILL drift"), resolved by the rule's own authority order
(PD-B, §10).

## 9. Verification battery (FOREGROUND, complete, counts)

- `python3 scripts/validate-pack.py` → **PASSED — all checks clean** (rc=0;
  run TWICE: once post-edits pre-tests, once in the final battery).
- `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → **PASSED — all
  checks clean** (rc=0).
- **All 52 workflow `tests:`-job suites, workflow order, every rc=0**
  (5 chunks; per-suite result line captured in session). Counts on the
  edited suites: `tracker-migrate-reverse-test.sh` **190/0** (was 134);
  `tracker-provider-test.sh` **199/0**; `tracker-migrate-forward-test.sh`
  **204/0**; `tracker-bd130-doctor-wired-test.sh` **36/0** (was 25);
  `tracker-config-schema-test.sh` **40/0** (was 34);
  `test-validate-pack-checks-32-33-34.sh` **96/0** (was 85). Highlights
  elsewhere: `test-detect.sh` 100/0; `test-per-entry.sh` 57/57;
  integration `test-v11-realistic-ot.sh` **33/33**;
  `test-persona-contracts.sh` "All persona contracts PASS";
  `test-migrator-skills.sh` 19/0; every remaining suite "All tests
  passed" / 0 failed.
- Fixture sequence per §8 (build rc=0; manifest diff 0 lines; `--verify`
  6/6 OK). The CI-only `git checkout HEAD -- manifest.txt` restore step
  was NOT run (forbidden verb); the empty diff proves the same property.
- `bash -n` on every edited shell file → OK; `ast.parse` on
  `validate-pack.py` → OK.
- Post-rebuild no-stray-files assertion: `ls STATUS.md
  IMPLEMENTATION-PLAN.md` at pack root → both absent (and the tree-rebuild
  happy-path leg 8.1 asserts the same at the FIXTURE root).
- Live oracle: default-SKIP — not run.

## 10. Plan deviations (explicit; 3)

- **PD-A — `scripts/lib/tracker-provider-gh.sh` edited (not in PLAN §3.1's
  file list).** Required to realize the architecture's leg-(h) contract
  ("labels + state + body in one paginated read — no per-issue
  provider_get sweep"): as-built `provider_list` returned neither `body`
  nor `state_reason`. Additive field-set + normalizer extension; zero test
  pins on the field string (grep-verified); full battery green.
- **PD-B — manifest does not ride the commit.** PLAN §3.4 expected drift;
  the rebuild proved the diff EMPTY (§8). The manifest rule's canonical
  authority (the post-rebuild diff) governs.
- **PD-C — engine-seam BD-207 guard (defensive double).** The PLAN places
  the pack-surface-only gate in `cmd_tree_rebuild`; the engine also
  refuses `tree_only=1` on a non-pack surface (fail loud naming BD-207) so
  a DIRECT engine call cannot silently ignore the flag and over-emit on
  the client surface. The client branch's emit code itself is untouched.
  Both seams are test-pinned (leg 8.4).

Not-a-deviation notes: (a) the §B6 R11 asymmetry sentence for
`tracker.toml.pack-example` was NOT added — §B6's header scopes ALL R-rows
to BD-206/207 ("Commits 1–2 touch NONE of these surfaces"); D2-4 scopes
the pack-example edit to §B5 surface 5 only, which is what landed.
(b) `.codex/skills/pack-startup/SKILL.md` was refreshed by `cp` from the
`.claude` copy — the two were byte-identical before the edit and the cp
reproduces the two targeted edits exactly (parity hash §6); no content
beyond the targeted edits changed.

## 11. POQs introduced

- **POQ-1 (resolved in-session, surfaced for review):** doctor leg (h) on
  the LIVE pack repo will make a real (read-only) `gh issue list` call
  when the operator runs `pack tracker doctor` in local tracker mode —
  that is the designed operator behavior (graceful INFO-skip when
  gh/network unavailable), not a test-path concern.
- **POQ-2 (resolved in-session; disclosed):** adding leg (h) initially
  made the reverse suite's Group 6 doctor fixtures non-hermetic — on this
  machine (real `gh` on PATH, `GH_REPO=fixture-org/fixture-repo` exported
  by `tracker_gh_repo_setup`) the FIRST run of the edited
  `tracker-migrate-reverse-test.sh` likely triggered up to three indirect
  read-only `gh issue list` attempts against the nonexistent
  `fixture-org/fixture-repo` before I wrapped Group 6 with the suite's
  fake gh. No mutation ops were possible (list is read-only; the repo
  does not exist); the wrap eliminates the exposure for every future run
  (re-run verified offline-green). Surfaced per the no-live-GitHub
  constraint rather than silently absorbed.
- **POQ-3 (disposition note):** `pack tracker edit` does not auto-run the
  tree-rebuild (its usage text says to run `tree-rebuild` afterward),
  while `new-entry` DOES finish with the rebuild (per the D2-1 recipe
  text, which specifies the rebuild finish for new-entry only). If Pack
  Chat wants edit to auto-materialize too, that is a one-line follow-up;
  the contract docs' "after any tracker write batch … run tree-rebuild"
  cadence makes the current shape coherent. Recommended default: keep
  as-is.

## 12. Boundary discipline check

Zero project-side files in the diff (`git status` paths under
`project-template/` or `supporting-docs/`: **0**). All edits are pack-side
surfaces; the BD-206/207 client analogs were left untouched per the
amendment (client `mirror-rebuild` arm, client doctor arm, client reverse
branch all byte-preserved — regression leg 4.5b proves the client
mirror-rebuild path). No pack-only reference was added to any
client-shipped file. No boundary stop triggered.

## 13. Files changed inventory (26 modified; 1 new = this report)

| Path | Type | Δ |
|---|---|---|
| `scripts/pack-tracker.sh` | modified | +356/−2 |
| `scripts/lib/tracker-migrate-reverse.sh` | modified | +156/−12 (net) |
| `scripts/lib/tracker-doctor.sh` | modified | +115/−19 |
| `scripts/lib/tracker-edit.sh` | modified | +65/−0 |
| `scripts/lib/tracker-provider-gh.sh` | modified | +12/−1 |
| `scripts/lib/tracker-migrate-forward.sh` | modified | +1/−1 |
| `scripts/tracker-migrate.sh` | modified | +4/−0 |
| `scripts/validate-pack.py` | modified | +78/−6 |
| `scripts/tests/tracker-migrate-reverse-test.sh` | modified | +244/−6 (Group 8 + Group 6 fake-gh wrap + header) |
| `scripts/tests/tracker-provider-test.sh` | modified | +261/−0 (4.9 legs + Group 5) |
| `scripts/tests/tracker-migrate-forward-test.sh` | modified | +38/−0 (4.5 assert + 4.5b) |
| `scripts/tests/tracker-bd130-doctor-wired-test.sh` | modified | +129/−0 (Group 9) |
| `scripts/tests/tracker-config-schema-test.sh` | modified | +59/−0 (Test 18) |
| `scripts/tests/test-validate-pack-checks-32-33-34.sh` | modified | +80/−2 (fixture markers + A7/A7b/F6) |
| `.gitignore` | modified | +5/−0 |
| `tracker.toml.pack-example` | modified | +22/−2 |
| `pack-ops/HELP-FRAGMENT-PACK.md` | modified | +1/−1 |
| `pack-ops/HELP-FRAGMENT-TRACKER.md` | modified | +9/−3 |
| `pack-ops/OPTIONAL-FEATURES.md` | modified | +4/−1 |
| `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (root trinity) | modified | +3/−3 each (NIT-1 clause; CLAUDE==AGENTS hunks byte-identical) |
| `README.md` | modified | +4/−4 |
| `.claude/skills/pack-startup/SKILL.md` / `.codex/skills/pack-startup/SKILL.md` / `.gemini/commands/pack-startup.toml` | modified | +10/−5 each (NIT-1 + NIT-2A; byte-parity proven) |
| `test-fixtures/manifest.txt` | NOT changed | rebuild diff empty (§8) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-MODE3-OPS-COMMIT2.md` | new | this report |

Full unified diffs live in the working tree against base
`358310e4e3586fd94d838e0097954c804638f530` (`git diff` reproduces them;
no other modifications exist — `git status` quoted in §1/§7 is the
complete set). Per the calling prompt's Output spec the report carries
the per-deliverable content summaries + proofs rather than the ~1,660
inserted lines verbatim.

## 14. Definition-of-Done checklist

| Item | Result | Evidence pointer |
|---|---|---|
| `tree-rebuild` verb: reverse-driven, no-flip, tree-only; `_toc.md` by construction; one-way overwrite proven by test | PASS | reverse suite 8.1/8.2 (sentinel clobbered; byte-equal regen) |
| `mirror-rebuild` retired on pack surface (message repoint) | PASS | forward suite 4.5 "names tree-rebuild"; client 4.5b regression green |
| `edit` + `new-entry` thin verbs over existing lib paths (no new codec, no raw gh) | PASS | provider suite Group 5 (composer/parser/label-map/provider_* reuse asserted) |
| Status-coherence: blocking comparator at every materialization; blob truth; `--force` blob-wins; advisory doctor leg | PASS | reverse 8.5 unit+e2e; bd130 9.4/9.5 |
| Doctor freshness repoint to local keys; absent-key INFO tolerance; client arm untouched | PASS | bd130 9.1–9.3; doctor client branch byte-unchanged in diff |
| Check 29″ never-tracked FAIL leg + per-check test | PASS | validate-pack green ×2; schema suite Test 18 (3 legs) |
| Check 32′ mode-marker assertions + per-check red/green legs | PASS | validate-pack green against the real post-Commit-1 tree; checks-32 suite A7/A7b/F6 |
| `.gitignore` root-anchored `/tracker.toml`; 3 fixtures stay tracked (before/after `git ls-files` proof) | PASS | §4 |
| Doc surfaces per §B5 (pack-example header, PACK/TRACKER fragments incl. NIT-2B, OPTIONAL-FEATURES) | PASS | §2 D2-4 row + §6 |
| NIT-2A: `forward_complete` conjunct ×3 copies, parity kept | PASS | §6 hashes + body diff |
| NIT-1: mode-aware qualifier on trinity head lines / README rows / pack-startup prose; trinity byte-parity | PASS | §6 (clause census ×3; CLAUDE==AGENTS hunk hash ×2) |
| Test legs in already-CI-wired host suites (wiring claim re-verified — zero workflow edits; all 6 host suites in `.github/workflows/validate-pack.yml` run lines) | PASS | §5; workflow run-line extraction quoted in session |
| Full battery green (validate ×2 + 52 suites + fixtures) | PASS | §9 |
| Manifest regenerated; staged iff non-empty | PASS (empty → not staged) | §8 |
| Check-36 `pack-only` clean on the final diff | PASS | §7/§12 — 0 paths under the deny set |
| Zero phase refs in added pack-side prose; no line-number refs; superseded content absent | PASS | §7 |
| Live `tracker.toml` / `.pack-tracker/` untouched | PASS | §1/§7 |

## 15. Proposed commit subject

```
feat: v11 — BD-204 Mode-3 ops verbs (tree-rebuild/edit/new-entry) + status-coherence + doctor/validator repoints (pack-only)
```

(The PLAN §3.3 / calling-prompt subject verbatim; final wording is the
user's at the commit gate per OQ-3. Stage list = the 26 modified files +
this report; `test-fixtures/manifest.txt` not staged — empty diff;
`tracker.toml` cannot be staged — now gitignored.)

## 16. READ-IN-FULL attestation (path + line count, read this session)

| # | File | Proof |
|---|---|---|
| 1 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` (post-Commit-1) | Read IN FULL via Read tool, 590 lines incl. the complete `## Pack memory` section (lines 140–590). |
| 2 | `maintenance-docs/v11-implementation/PLAN-BD-204-MODE3-OPS-CONTRACT.md` | Read IN FULL, 451 lines (§0–§9, EE-1..EE-8, OQ-1..OQ-3). |
| 3 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md` | Read IN FULL, 556 lines (§0–§9). |
| 4 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT-2.md` (NORMATIVE) | Read IN FULL, 624 lines (§B0–§B12 incl. the D2 table). |
| 5 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT.md` (SUPERSEDED) | Read IN FULL, 384 lines — recognition only; content verified ABSENT from the diff (§7). |
| 6 | `maintenance-docs/v11-implementation/PACK-REVIEW-MODE3-OPS-COMMIT1-REVIEW3.md` | Read IN FULL, 311 lines (NIT-1 / NIT-2 / ADVISORY-1 sections consumed). |
| 7 | Memory files: `feedback_verify_full_ci_suite.md` (43), `feedback_edit_in_place_not_full_rewrite.md` (14), `feedback_manifest_regen_on_v11_surface.md` (15), `feedback_agent_output_rules_applied_block.md` (14) | Each read IN FULL; both conditional MUST-READs honored — `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block` (lines 195–267 region) and § `regenerate-manifest-v11-surface` (lines 479–533) read directly this session. |
| 8 | Standing docs + skills: `pack-ops/PACK-AGENTS.md` FULL (223); `/backlog/_rules.md` FULL (152); `/changelog/_rules.md` FULL (77); `.claude/skills/{implementation-report,verification-harness,commit-discipline,boundary-investigation}/SKILL.md` FULL (139/218/175/186). |
| 9 | Instructed section-reads, each verified directly: `scripts/lib/tracker-migrate-reverse.sh` FULL in two passes (1646 pre-edit — `tracker_migrate_reverse_run`, `_tmr_emit_pack_tree`, `_tmr_check_blob_h2_divergence`, `_tmr_decode_status`, `_tmr_update_tracker_toml`); `scripts/lib/tracker-edit.sh` FULL (347 — `tracker_edit_entry`); `scripts/lib/tracker-migrate-forward.sh` `mirror_only` arm (1330–1424) + parser/composer/labels/mapping regions (175–315, 380–600, 1040–1175, 1500–1630, 2218–2258); `scripts/pack-tracker.sh` FULL (456 — verb table + dispatch); `scripts/lib/tracker-doctor.sh` FULL (304); `scripts/validate-pack.py` Check 29 region (2592–3030) + Check 32′ region (3229–3510) + header docstring (82–170) + import block; `scripts/tracker-migrate.sh` FULL (196); `.gitignore` FULL (66); `tracker.toml.pack-example` FULL (74); pack-startup ×3 FULL (.claude 117 / .codex byte-identical / .gemini toml 115); `pack-ops/HELP-FRAGMENT-PACK.md` FULL (41); `pack-ops/HELP-FRAGMENT-TRACKER.md` FULL (49); `pack-ops/OPTIONAL-FEATURES.md` tracker section (125–215); trinity head regions (AGENTS 25–40, GEMINI 22–36); README layout rows (182–192, 274–281); host-suite structures: reverse-test FULL head+groups (1–280, 514–1160), provider-test (1–232, 905–1071), forward-test 4.4–4.6 region, bd130 FULL (245), checks-32 suite (1–480, 658–732), schema suite (1–150, 540–end); `scripts/lib/tracker-config.sh` (60–296 — `tracker_mode`, `tracker_config_get`, `tracker_config_resolve_path`, `tracker_config_auto_surface`); `scripts/lib/tracker-provider-gh.sh` list/create/update/close region (211–460) + capabilities (883–920); `.github/workflows/validate-pack.yml` run-line extraction (the complete battery enumeration). |

No named document was derived rather than read; every file above was
opened via the Read/Bash tools this session at HEAD `358310e`.

---

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| **agents-never-commit** | Git verbs run this session: `git rev-parse HEAD`, `git rev-parse --abbrev-ref HEAD`, `git status --short`, `git ls-files`, `git check-ignore -v`, `git diff` (+ `--stat`, grep-piped) — read-only only. Zero `add/commit/push/tag/stash/reset/restore/checkout/rm` invocations by this agent (the per-check Test-18 fixtures run `git init/add/commit` INSIDE self-provisioned `mktemp` scratch repos that are created and `rm -rf`'d by the test itself — the repo-under-work's git state never changed; HEAD identical start to end: `358310e4e3586fd94d838e0097954c804638f530`). Output = working-tree edits + this report. | COMPLIANT |
| **per-action-approval-sub-agents** | Zero destructive ops on trusted files: no `rm`/`git rm` outside mktemp scratch + the suites' own `trap` cleanup; the live `tracker.toml` (23 lines) and `.pack-tracker/` untouched (§1/§7); report path verified non-existent pre-write (absent from the §1 `git status` and the maintenance-docs listing read at session start). The `.codex` pack-startup refresh overwrote a file byte-identical to its `.claude` source pre-edit (parity mechanism, hash-proven §6), not a divergent trusted file. | COMPLIANT |
| **preflight-stop-means-stop** | Emitted before this Write, verbatim: `PREFLIGHT: 26/26 in-scope file edits complete; verification PASS; HEAD 358310e4e3586fd94d838e0097954c804638f530; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-MODE3-OPS-COMMIT2.md`. Every command ran FOREGROUND to completion (zero background tasks armed; no turn ended with verification pending). No parent stop/halt/revert message received at any point. | COMPLIANT |
| **agent-output-rules-applied-block** | This table: 10 rows (one per prompt "Rules in force" item), each with quoted command/output evidence; zero empty cells; no AMBIGUOUS row. Format per `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block`, read this session per the memory file's conditional MUST-READ (§16 row 7). | COMPLIANT |
| **agents-read-rule-docs-in-full** | §16: every prompt-named file attested with line counts — CLAUDE.md 590 (full Pack memory); authorities 451/556/624; superseded amendment 384; REVIEW3 311; four memory files 43/14/15/14; both conditional rationale sections; every instructed section-read enumerated with file + symbol (+ the standing PACK-AGENTS/_rules/skills set). | COMPLIANT |
| **verify-full-ci-suite** | §9: `python3 scripts/validate-pack.py` → "PASSED — all checks clean" rc=0 (×2 runs); `PACK_VALIDATE_DEEP=1` → "PASSED — all checks clean" rc=0; **52/52** workflow `tests:`-job suites FOREGROUND in workflow order across 5 chunks, every rc=0 (per-suite result lines quoted: reverse 190/0, provider 199/0, forward 204/0, bd130 36/0, schema 40/0, checks-32 96/0, detect 100/0, per-entry 57/57, integration v11-realistic-ot 33/33, persona PASS, migrator-skills 19/0, …); fixture `build.sh --all --clean` rc=0 + manifest diff 0 lines + `--verify` 6/6 OK. Live oracle default-SKIP. Check 29″ green on the real tree with the gitignore landing in this diff (tracker.toml ignored AND untracked → OK banner). | COMPLIANT |
| **regenerate-manifest-v11-surface** | Diff touches `scripts/` + `pack-ops/` → trigger fired → `bash test-fixtures/build.sh --all --clean` rc=0 → `git diff test-fixtures/manifest.txt` → **EMPTY** → per the rule's canonical-authority clause ("if empty … no staging needed"), the manifest is NOT staged; `--verify` → 6/6 rows OK (§8). The conditional MUST-READ rationale section was read before acting (§16 row 7). | COMPLIANT |
| **edit-in-place-not-full-rewrite** | Every change landed via targeted Edit calls against re-read regions (Read-before-Edit on all 26 files); zero full-file Writes on existing files (sole Write = this NEW report; the `.codex` mirror cp is hash-proven equivalent to the two targeted edits, §6/§10). Edited regions re-verified by the passing per-check tests + greps; untouched text byte-stable per `git diff --stat` (82 deletions total, each accounted for in the per-file recipes). | COMPLIANT |
| **pack-only** | End-state diff = 26 files (§13); `git status --short | awk … | grep -cE "^(project-template/|supporting-docs/)"` → **0**. Every touched path is outside the Check-36 `pack-only` deny set; the commit subject (§15) carries the keyword verified against this final diff. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Deliverables = exactly the D2 table rows (§2) + the three routed findings (§6) + the plan-§5 test legs (§5). Discoveries surfaced as POQs (§11), deviations declared (§10 — PD-A/PD-B/PD-C, each grounded in an architecture/rule authority); the §B6 R11 pack-example sentence deliberately NOT added (out of D2-4 scope, §10); zero entry files (`BD-*.md`) touched; zero new BD numbers assigned; zero project-side edits (§12). | COMPLIANT |

---

**End of IMPL-REPORT-MODE3-OPS-COMMIT2.md**
