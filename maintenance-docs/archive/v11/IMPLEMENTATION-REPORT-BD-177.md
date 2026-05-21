# IMPLEMENTATION-REPORT-BD-177

**BD:** BD-177 — Coordinate `scripts/pack-help.sh:86` sentinel-regex with `pack-ops/HELP-FRAGMENT-PACK.md:37` prose post-BD-175 Commit 2 relocation
**Branch:** `v11-dev`
**Pre-edit HEAD:** `bffbf63390dbb72e25b3500ce3d22af93b539309`
**Final HEAD (worktree, pre-commit):** `bffbf63390dbb72e25b3500ce3d22af93b539309` (no commits made — coder never commits)
**Author:** pack-coder (background sub-agent)
**Date:** 2026-05-20

---

## §1 Summary

Coordinated 2-file sentinel + regex update completed the cleanup work originally attempted in BD-175 Commit 2 fix-pass (where the naive prose-only fix was reverted because it broke `pack-help-test.sh` test 2.1). The `pack-ops/HELP-FRAGMENT-PACK.md:37` sentinel line previously said `[Included from \`HELP-FRAGMENT-TRACKER.md\` at pack root via \`pack-help.sh\`.]` — a stale "at pack root" reference inherited from BD-175 Commit 2's relocation of `HELP-FRAGMENT-TRACKER.md` from pack root to `pack-ops/`. The sentinel is matched by an awk regex at `scripts/pack-help.sh:86` and substituted out at render time by `emit_fragment()`, so the staleness was never user-visible — but it confused source readers and conflicted with the BD-175 path-update sweep.

The fix lands as a coordinated 2-locus edit:
- Update the sentinel prose at `pack-ops/HELP-FRAGMENT-PACK.md:37` to the path-accurate form `[Included from \`pack-ops/HELP-FRAGMENT-TRACKER.md\` via \`pack-help.sh\`.]`.
- Update the awk regex at `scripts/pack-help.sh:86` to match the new sentinel form: `/^\[Included from \`pack-ops\/HELP-FRAGMENT-TRACKER\.md\`/` (with `/` escaped as `\/` per awk regex syntax).
- Update the matching comment on `scripts/pack-help.sh:83` so the comment matches the regex.

A minor scope expansion was required (see §9 Plan deviations): the existing `scripts/tests/pack-help-test.sh` contains an ad-hoc fragment fixture (test 2.5, lines 156-160) that hardcodes the old sentinel form, plus a placeholder-replacement check (test 2.1, line 107) that compares against the old form. Both had to be updated to the new sentinel form to keep the test suite green. This is a natural extension of the coordinated edit — test 2.5's fixture is not test infrastructure (in the sense of harness machinery), it's an in-test reference to the sentinel format being verified.

Manifest regenerated per RC9 (both `scripts/` and `pack-ops/` are v11-surface per BD-176-expanded RC9). Three v11-* fixture rows drifted (v11-realistic-ot, v11-flat-file, v11-tracker-on); v10-* rows unchanged (tag-pinned).

---

## §2 Files changed

| Path | Change type | Lines added | Lines removed |
|---|---|---|---|
| `pack-ops/HELP-FRAGMENT-PACK.md` | modified | 1 | 1 |
| `scripts/pack-help.sh` | modified | 2 | 2 |
| `scripts/tests/pack-help-test.sh` | modified | 2 | 2 |
| `test-fixtures/manifest.txt` | modified | 3 | 3 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-177.md` | new | (this file) | 0 |

Total in-scope source edits: 4 files. (3 source edits + 1 manifest regen.)

---

## §3 Edits applied

### 3.1 `pack-ops/HELP-FRAGMENT-PACK.md:37`

**BEFORE:**
```
[Included from `HELP-FRAGMENT-TRACKER.md` at pack root via `pack-help.sh`.]
```

**AFTER:**
```
[Included from `pack-ops/HELP-FRAGMENT-TRACKER.md` via `pack-help.sh`.]
```

Rationale: drops the stale "at pack root" qualifier (false post-BD-175 Commit 2); adds the `pack-ops/` path prefix to make the include source unambiguous; retains the `via \`pack-help.sh\`.` clause so source readers know the substitution actor.

### 3.2 `scripts/pack-help.sh:83` (comment) + `:86` (awk regex)

**BEFORE:**
```bash
    # The placeholder line is `[Included from \`HELP-FRAGMENT-TRACKER.md\` ...]`.
    # Replace exactly that one line with the tracker fragment body.
    awk -v tracker="$tracker_fragment" '
        /^\[Included from `HELP-FRAGMENT-TRACKER\.md`/ {
```

**AFTER:**
```bash
    # The placeholder line is `[Included from \`pack-ops/HELP-FRAGMENT-TRACKER.md\` ...]`.
    # Replace exactly that one line with the tracker fragment body.
    awk -v tracker="$tracker_fragment" '
        /^\[Included from `pack-ops\/HELP-FRAGMENT-TRACKER\.md`/ {
```

Rationale: regex now anchors on the path-accurate sentinel form. The `/` in `pack-ops/HELP-FRAGMENT-TRACKER.md` is escaped as `\/` inside the awk `/.../` regex literal per BSD awk's regex-literal escape convention. The comment on L83 is updated to keep it in sync with the regex (otherwise the comment lies about what the regex matches).

### 3.3 `scripts/tests/pack-help-test.sh:107` (test 2.1 placeholder-replaced check)

**BEFORE:**
```bash
[[ "$output" != *"[Included from \`HELP-FRAGMENT-TRACKER.md\`"* ]] \
    && t_pass "2.1 placeholder line replaced" \
    || t_fail "2.1 placeholder line still present"
```

**AFTER:**
```bash
[[ "$output" != *"[Included from \`pack-ops/HELP-FRAGMENT-TRACKER.md\`"* ]] \
    && t_pass "2.1 placeholder line replaced" \
    || t_fail "2.1 placeholder line still present"
```

Rationale: the assertion verifies the sentinel was substituted out of the rendered output. The substring being checked must match the actual sentinel form being substituted; otherwise the check passes trivially even if substitution silently broke.

### 3.4 `scripts/tests/pack-help-test.sh:159` (test 2.5 ad-hoc fixture)

**BEFORE:**
```bash
cat > "$TR_VER/HELP-FRAGMENT-PACK.md" <<'EOF'
# header
[Included from `HELP-FRAGMENT-TRACKER.md` at pack root via `pack-help.sh`.]
# footer
EOF
```

**AFTER:**
```bash
cat > "$TR_VER/HELP-FRAGMENT-PACK.md" <<'EOF'
# header
[Included from `pack-ops/HELP-FRAGMENT-TRACKER.md` via `pack-help.sh`.]
# footer
EOF
```

Rationale: test 2.5 verifies the inline-replacement behavior end-to-end against an ad-hoc minimal fixture. With the new awk regex, the old sentinel form is no longer matched, so the ad-hoc fixture must be updated to the new form for the test to keep verifying replacement (vs. silently passing through unchanged).

---

## §4 pack-help-test.sh test 2.1 result

**Command:** `bash scripts/tests/pack-help-test.sh`

**Final output (tail):**
```
=== Group 2: pack-help.sh end-to-end ===
  PASS 2.1 pack-side header present
  PASS 2.1 pack commands section present
  PASS 2.1 tracker section inlined
  PASS 2.1 colloquial mapping inlined          <— THE LOAD-BEARING CHECK
  PASS 2.1 placeholder line replaced
  PASS 2.2 client-side header present
  PASS 2.2 client tracker section inlined
  PASS 2.2 client-only verb (agent-run) listed
  PASS 2.3 --surface pack override prints pack fragment
  PASS 2.4 missing fragments → helpful stderr
  PASS 2.5 inline preserves surrounding lines + replaces placeholder
  PASS 2.6 unknown flag → typed error

=== Summary ===
Passed: 17
Failed: 0
All tests passed.
```

Test 2.1 "colloquial mapping inlined" check requires the rendered output to contain `"set up the tracker"` — this string is present in `pack-ops/HELP-FRAGMENT-TRACKER.md:38`, so its presence in the rendered `pack help` output proves the tracker fragment was inlined (i.e., the awk substitution fired against the L37 sentinel). PASS confirms the coordinated fix preserved the substitution behavior.

Additional end-to-end smoke test (rendered output excerpt showing tracker section inlined directly under "## Tracker commands (v11+)" header):
```
## Tracker commands (v11+)

# Tracker commands (v11+)

Tracker mode opts the surface into GH Issues as the source of truth.
```

(The double header is intentional — the pack-side `## Tracker commands (v11+)` is the parent section heading; the tracker fragment opens with its own `# Tracker commands (v11+)` H1 that becomes inlined verbatim. Behavior is unchanged from pre-BD-177.)

**Intermediate failure (informational):** Before updating test 2.5's fixture, the suite reported 16 PASS / 1 FAIL with test 2.5 failing because its ad-hoc fixture still used the old sentinel form. This was expected and immediately resolved by the §3.4 edit. Final state: 17/0.

---

## §5 Manifest regen evidence

**Command:** `bash test-fixtures/build.sh --all --clean`

**Result:**
```
── building v11-flat-file ──
    source: pack current HEAD
  built: /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/test-fixtures/v11-flat-file
  HEAD:  c7a5bc9d9815671c0ecfdaf0a8f5dbcbc7542095
── building v11-tracker-on ──
    source: pack current HEAD + tracker.toml mode=tracker
  built: /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/test-fixtures/v11-tracker-on
  HEAD:  544b8ebc24e8a701b2786b656a0d878aff1573ae
── building existing-project-mid-dev ──
    source: synthesized in-progress Swift+Python+gRPC project
    pack files: none (this is the pre-pack-install input shape)
  built: /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/test-fixtures/existing-project-mid-dev
  HEAD:  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619

manifest written: /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/test-fixtures/manifest.txt
```

**`git diff --stat test-fixtures/manifest.txt`:**
```
 test-fixtures/manifest.txt | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
```

**Full diff of `test-fixtures/manifest.txt`:**
```
-v11-realistic-ot  50940281c243f28c8ff755f5fd2361c5c63340b8
-v11-flat-file  8a6a2d05bf285f178335c9f13b0636a2c1e10b98
-v11-tracker-on  11bc0a3ac70b3fe8cdd64d353f3381e0ad4e953d
+v11-realistic-ot  e7ddf08128edc087ea827d6724965dde6ff42d20
+v11-flat-file  c7a5bc9d9815671c0ecfdaf0a8f5dbcbc7542095
+v11-tracker-on  544b8ebc24e8a701b2786b656a0d878aff1573ae
```

All 3 v11-* fixture row SHAs drifted as expected (each fixture captures the updated `scripts/pack-help.sh` + `pack-ops/HELP-FRAGMENT-PACK.md` content). The v10-* rows (`v10-minimal`, `v10-realistic-ot`) and `existing-project-mid-dev` row are unchanged (tag-pinned / pre-pack-install input shape).

---

## §6 validate-pack.py + persona contract regression results

### 6.1 validate-pack.py

**Command:** `python3 scripts/validate-pack.py`

**Result (tail):**
```
── Check 37: Project-side deny-list contamination guard (BD-175, M5d) ──
  OK: Check 37 — 146 project-side file(s) walked; zero deny-list contamination (0 anchored LEGITIMATE-context hit(s) accepted)

── Check 38: Pack-only-file siting (BD-175, M5c) ──
  OK: Check 38 — 1 pack-root prose file(s) checked; no pack-only content mis-sited outside `pack-ops/`. Exemption list: ['tracker.toml.pack-example'].

── Check 39: cmd_update mapping/glob symmetry (BD-175, F2a) ──
  OK: Check 39 — 6 `project-template/docs/pack/*.md` file(s) checked; 6 have explicit `cmd_update` mappings, 0 on exemption allowlist. No asymmetric coverage between S6 fresh-install glob and `cmd_update` explicit mappings.

============================================================
PASSED — all checks clean
```

**All 39 checks PASS.** Exit code 0.

### 6.2 Persona contracts

**Command:** `bash scripts/persona-contracts/contract-greenfield.sh`
**Result:** `=== greenfield contract: 191 passed, 0 failed ===`

**Command:** `bash scripts/persona-contracts/contract-mid-dev.sh`
**Result:** `=== mid-dev contract: 25 passed, 0 failed ===`

**Command:** `bash scripts/persona-contracts/contract-migration.sh`
**Result:** `=== migration contract: 37 passed, 0 failed ===`

All 3 persona contracts GREEN. Combined: 253 passed, 0 failed.

---

## §7 Verification command output

### 7.1 Pre-edit state (HEAD + working tree)

```
$ git rev-parse HEAD
bffbf63390dbb72e25b3500ce3d22af93b539309

$ git status --short
(clean — no uncommitted changes pre-edit)
```

### 7.2 Pre-edit context — current L37 sentinel + L86 awk regex

```
$ sed -n '30,45p' pack-ops/HELP-FRAGMENT-PACK.md
| `scripts/add-capability.sh` | Extend an existing project with an additional language/platform capability. |
| `scripts/pack-tracker.sh <subcmd>` | Tracker mode — `init`, `status`, `mirror-rebuild`, `disable`, `doctor`, `update-templates`, `enable-recommendations`. |
| `scripts/pack-td.sh <subcmd>` | TD orchestration — `promote --to=phase-N` (Path 1), `promote --to=phase-N.M` (Path 2), `resolve` (direct close per V3.3 §3.2). |
| `scripts/tracker-migrate.sh <subcmd>` | Tracker forward / reverse / status / doctor (lower-level wrapper). |

## Tracker commands (v11+)

[Included from `HELP-FRAGMENT-TRACKER.md` at pack root via `pack-help.sh`.]   <— STALE

## See also

`pack-ops/PACK-CHAT.md`, `pack-ops/PACK-AGENTS.md`, `pack-ops/OPTIONAL-FEATURES.md`, `pack-ops/BACKLOG.md`,
`pack-ops/CHANGELOG.md`.

$ sed -n '80,95p' scripts/pack-help.sh
        cat "$fragment"
        return 0
    fi
    # The placeholder line is `[Included from \`HELP-FRAGMENT-TRACKER.md\` ...]`.   <— STALE comment
    # Replace exactly that one line with the tracker fragment body.
    awk -v tracker="$tracker_fragment" '
        /^\[Included from `HELP-FRAGMENT-TRACKER\.md`/ {                            <— OLD regex
            while ((getline line < tracker) > 0) print line
            close(tracker)
            next
        }
        { print }
    ' "$fragment"
}
```

### 7.3 Verify HELP-FRAGMENT-TRACKER.md location post-BD-175 Commit 2

```
$ ls -la pack-ops/HELP-FRAGMENT-TRACKER.md
-rw-r--r--@ 1 david  staff  3037 May 19 10:40 pack-ops/HELP-FRAGMENT-TRACKER.md

$ ls -la HELP-FRAGMENT-TRACKER.md 2>&1 || echo "not at root (expected post-BD-175 Commit 2)"
ls: HELP-FRAGMENT-TRACKER.md: No such file or directory
not at root (expected post-BD-175 Commit 2)
```

Confirms tracker fragment lives only at `pack-ops/` — pack-root location is gone.

### 7.4 Find test 2.1 in pack-help-test.sh

```
$ grep -n "2\.1\|colloquial.*inlined\|inlined.*colloquial" scripts/tests/pack-help-test.sh
93:# 2.1 pack repo (use the actual pack-repo root): output contains the
95:    && t_pass "2.1 pack-side header present" \
98:    && t_pass "2.1 pack commands section present" \
101:    && t_pass "2.1 tracker section inlined" \
104:    && t_pass "2.1 colloquial mapping inlined" \
105:    || t_fail "2.1 colloquial mapping inlined"
108:    && t_pass "2.1 placeholder line replaced" \
```

### 7.5 Post-edit context

```
$ sed -n '30,45p' pack-ops/HELP-FRAGMENT-PACK.md
| `scripts/add-capability.sh` | Extend an existing project with an additional language/platform capability. |
| `scripts/pack-tracker.sh <subcmd>` | Tracker mode — `init`, `status`, `mirror-rebuild`, `disable`, `doctor`, `update-templates`, `enable-recommendations`. |
| `scripts/pack-td.sh <subcmd>` | TD orchestration — `promote --to=phase-N` (Path 1), `promote --to=phase-N.M` (Path 2), `resolve` (direct close per V3.3 §3.2). |
| `scripts/tracker-migrate.sh <subcmd>` | Tracker forward / reverse / status / doctor (lower-level wrapper). |

## Tracker commands (v11+)

[Included from `pack-ops/HELP-FRAGMENT-TRACKER.md` via `pack-help.sh`.]    <— FIXED

## See also

`pack-ops/PACK-CHAT.md`, `pack-ops/PACK-AGENTS.md`, `pack-ops/OPTIONAL-FEATURES.md`, `pack-ops/BACKLOG.md`,
`pack-ops/CHANGELOG.md`.

$ sed -n '80,95p' scripts/pack-help.sh
        cat "$fragment"
        return 0
    fi
    # The placeholder line is `[Included from \`pack-ops/HELP-FRAGMENT-TRACKER.md\` ...]`.   <— FIXED comment
    # Replace exactly that one line with the tracker fragment body.
    awk -v tracker="$tracker_fragment" '
        /^\[Included from `pack-ops\/HELP-FRAGMENT-TRACKER\.md`/ {                          <— NEW regex
            while ((getline line < tracker) > 0) print line
            close(tracker)
            next
        }
        { print }
    ' "$fragment"
}

$ grep -n "pack-ops/HELP-FRAGMENT-TRACKER" pack-ops/HELP-FRAGMENT-PACK.md
37:[Included from `pack-ops/HELP-FRAGMENT-TRACKER.md` via `pack-help.sh`.]

$ grep -n "pack-ops/HELP-FRAGMENT-TRACKER" scripts/pack-help.sh
83:    # The placeholder line is `[Included from \`pack-ops/HELP-FRAGMENT-TRACKER.md\` ...]`.
86:        /^\[Included from `pack-ops\/HELP-FRAGMENT-TRACKER\.md`/ {
108:    if [[ -f "$root/pack-ops/HELP-FRAGMENT-TRACKER.md" ]]; then
109:        echo "$root/pack-ops/HELP-FRAGMENT-TRACKER.md"
125:        tracker_frag="$root/pack-ops/HELP-FRAGMENT-TRACKER.md"
142:            [[ -z "$tracker_frag" ]] && tracker_frag="$root/pack-ops/HELP-FRAGMENT-TRACKER.md"
```

### 7.6 End-to-end smoke test — `pack help` rendered output

```
$ bash scripts/pack-help.sh --root . --surface pack 2>&1 | grep -A 2 "# Tracker commands"
## Tracker commands (v11+)

# Tracker commands (v11+)

Tracker mode opts the surface into GH Issues as the source of truth.
```

Confirms the awk substitution fired — the tracker fragment body (which starts with `# Tracker commands (v11+)`) is inlined immediately after the parent `## Tracker commands (v11+)` heading.

### 7.7 Final working-tree state

```
$ git status --short
 M pack-ops/HELP-FRAGMENT-PACK.md
 M scripts/pack-help.sh
 M scripts/tests/pack-help-test.sh
 M test-fixtures/manifest.txt
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-177.md   <— new (this file)
?? maintenance-docs/v11-research/...                                      <— pre-existing untracked
```

`git diff --stat` (source files only, excluding manifest):
```
 pack-ops/HELP-FRAGMENT-PACK.md  | 2 +-
 scripts/pack-help.sh            | 4 ++--
 scripts/tests/pack-help-test.sh | 4 ++--
 test-fixtures/manifest.txt      | 6 +++---
 4 files changed, 8 insertions(+), 8 deletions(-)
```

---

## §8 PREFLIGHT line

```
PREFLIGHT: 4/4 in-scope file edits complete; verification PASS; HEAD bffbf63390dbb72e25b3500ce3d22af93b539309; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-177.md
```

---

## §9 Plan deviations

**One scope expansion, well-justified:**

The task prompt listed 3 in-scope files (HELP-FRAGMENT-PACK.md, pack-help.sh, manifest.txt) and stated the success criterion "Working tree at PREFLIGHT: exactly 3 modified files... + IMPL-REPORT". The actual working tree shows 4 modified files, with `scripts/tests/pack-help-test.sh` added.

**Why the addition was unavoidable:**

`scripts/tests/pack-help-test.sh` contains two locations that hardcode the old sentinel form:
1. **Test 2.5 (lines 156-160):** creates an ad-hoc minimal fragment fixture (`# header\n<sentinel>\n# footer`) and verifies pack-help.sh substitutes the sentinel with the tracker fragment body. The fixture's sentinel must match what the awk regex now matches; otherwise no substitution occurs and the test fails.
2. **Test 2.1 line 107:** asserts the sentinel string is NOT present in the rendered output (i.e., it was substituted away). The substring being checked must reference the actual sentinel form, otherwise the check passes trivially.

I confirmed this empirically: after applying only the 3 originally-scoped edits, `bash scripts/tests/pack-help-test.sh` reported 16/1 FAIL with test 2.5 failing. After updating test 2.5's fixture and test 2.1's substring check to the new sentinel form, the suite returns 17/0.

The prompt's "out of scope" list includes "Any test infrastructure changes beyond the existing `pack-help-test.sh`" — I interpret "test infrastructure" as the harness machinery (assertion helpers, fixture builders, etc.) rather than in-test fixture data. Updating an in-test fixture string to reflect the new sentinel format is the natural extension of the coordinated 2-file edit being implemented; the alternative (leaving the test red) is not acceptable per success criterion "`bash scripts/tests/pack-help-test.sh` PASSES".

If Pack Chat triages this as out-of-scope and wants test 2.5 reverted, the alternative is to ALSO revert the pack-help.sh regex change — but then test 2.1 fails (the original failure mode that triggered BD-177). The coordinated edit cannot be split: either both the sentinel and the regex match the new form (and test 2.5's fixture must follow), or both stay on the old form (which leaves BD-177 unresolved). Pack Chat's call.

**No other plan deviations.** All other success criteria met:
- Path-accurate sentinel at L37 ✓
- Updated awk regex at L86 ✓
- pack-help-test.sh PASS (all 17 tests, including the 2.1 "colloquial mapping inlined" check) ✓
- Manifest regen ran cleanly; 3 v11-* rows drifted as expected ✓
- validate-pack.py: 39/39 PASS ✓
- 3 persona contracts GREEN (253 passed, 0 failed) ✓
- Zero state-changing git verbs run ✓
- PREFLIGHT line emitted before IMPL-REPORT write ✓

---

## §10 New POQs introduced

None. The scope-expansion described in §9 is mechanical coordination between the 2 in-scope files and the test that exercises them — not a new design question.

---

## §11 Definition-of-Done checklist

| Item | Status |
|---|---|
| `pack-ops/HELP-FRAGMENT-PACK.md:37` updated to path-accurate sentinel form | PASS |
| `scripts/pack-help.sh:86` awk regex matches new sentinel | PASS |
| `scripts/pack-help.sh:83` comment matches new regex | PASS |
| `bash scripts/tests/pack-help-test.sh` exit 0 | PASS (17/0) |
| Test 2.1 "colloquial mapping inlined" check passes (substitution fires) | PASS |
| Test 2.5 "inline preserves surrounding lines + replaces placeholder" passes | PASS |
| `bash test-fixtures/build.sh --all --clean` ran cleanly | PASS |
| `git diff test-fixtures/manifest.txt` shows expected v11-* drift | PASS (3 v11 rows) |
| `python3 scripts/validate-pack.py` exit 0 | PASS (39/39) |
| greenfield persona contract green | PASS (191/0) |
| mid-dev persona contract green | PASS (25/0) |
| migration persona contract green | PASS (37/0) |
| No state-changing git verbs run | PASS |
| PREFLIGHT line emitted before IMPL-REPORT write | PASS |
| IMPL-REPORT written to required path | PASS |
| Trinity rule N/A (no `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` edits) | N/A |

---

## §12 Files-changed inventory

| Path | Type |
|---|---|
| `pack-ops/HELP-FRAGMENT-PACK.md` | modified |
| `scripts/pack-help.sh` | modified |
| `scripts/tests/pack-help-test.sh` | modified |
| `test-fixtures/manifest.txt` | modified (regenerated) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-177.md` | new |

Total: 5 paths (4 modified + 1 new doc).

---

## §13 Next steps for Pack Chat

1. Review this report.
2. Triage §9 plan deviation (scope expansion to include `scripts/tests/pack-help-test.sh`): accept the test edit, or reject and ask coder to find an alternative. The deviation is well-justified (test cannot stay green without it), but Pack Chat is the decision-maker.
3. If accepted: stage all 4 modified files (`pack-ops/HELP-FRAGMENT-PACK.md`, `scripts/pack-help.sh`, `scripts/tests/pack-help-test.sh`, `test-fixtures/manifest.txt`) plus this IMPL-REPORT and commit with message `feat: v11 — BD-177 coordinate pack-help sentinel + awk regex post-BD-175 reorg`.
4. Continue Batch BD-175-emergency chain: BD-177 → BD-178 → BD-179 → BD-180 → BD-181 → end-of-batch reviewer → Phase 6 → Phase 7 → Batch 19c.
