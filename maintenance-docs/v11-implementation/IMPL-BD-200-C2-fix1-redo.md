# IMPL-REPORT — BD-200 commit C2 fix-1 (AUTHORITATIVE REDO)

**Role:** pack-coder (fresh, fix-1 redo). **Branch:** `v11-dev`.
**HEAD at start AND end (unmoved):** `98b6a9b10e9d9e8b114995e3d416e708230c5bde`.
**Date:** 2026-06-04.
**Deliverable:** S-1 + N-1 from `PACK-REVIEW-BD-200-C2.md` — exclude the BD-200
tracked pool (`pack-capability-pool/`) from every tree-scanning marker detector
that the review flagged, with a load-bearing partner test. This is the
authoritative redo of a prior fix-1 attempt REJECTED for an incomplete
read-in-full. The prior (untrusted) attempt's edits were already present in the
working tree; I independently re-derived the correct fix, verified EACH edit
matches the correct design, and confirmed the FINAL working-tree state is exactly
correct + complete. No deviation from the correct fix was found; no correction
to the prior edits was required.

---

## Cycle position (`review-cycle-position-checkpoint`)

Per the literal trinity rule "Pack Chat NO coder review; bounded reviewer/fix
cycle": this is **fix-1 (pass 1 of max 2)** on C2. The mandated next step after
this IMPL-REPORT is **review-2 (a FRESH pack-reviewer pass on the fix)** —
a fix is NEVER terminal, even a small detect.sh edit. Pack Chat does not
self-review. I am the fix-coder; I do not review my own output.

---

## Summary (lead)

**S-1 FIXED + N-1 FIXED + partner test present + all verification PASS.** The
four `*_marker_detected()` functions in `scripts/lib/detect.sh`
(`python_data_marker_detected`, `protobuf_marker_detected`,
`swiftdata_marker_detected`, `python_observability_marker_detected`) each now
prune `pack-capability-pool/` from their recursive `find` walk, commented
LOAD-BEARING. `detect_source_files()` in `scripts/init-project.sh` (N-1) carries
the same exclusion, framed consistency/forward-safety. `scripts/test-detect.sh`
asserts the markers do NOT mis-fire on a pool-only Swift-only tree, with
controls. A/B proof: with the pool present all four markers read correctly; move
the pool aside and (without the prune in view) the pool content WOULD trip
`protobuf`/`python-data`/`python-observability` `yes` — empirically proving the
exclusion is load-bearing. No-regression: a real live-tree proto/python tree
still fires `yes` with the pool present. BD-202 boundary intact (no
update/refresh logic). Check 47 frozen 2-tuple unmoved; `validate-pack` PASSED.

---

## Independent derivation + completeness enumeration (`enumerate-encoding-surfaces`)

I enumerated EVERY tree-scanning marker detector that could see the pool, across
both source files, to guarantee no scan is left unpatched:

**`scripts/lib/detect.sh` — `find` calls (grep `find ` → exactly 4):**
| Fn (line) | Walks tree? | Pool-excluded? | Verdict |
|---|---|---|---|
| `python_data_marker_detected` (362) — marker (b) `find ... -name '*.py'` (L410) | YES | YES (`-not -path "*/pack-capability-pool/*"` L412) | PATCHED |
| `protobuf_marker_detected` (488) — marker (a) `find ... -name '*.proto'` (L501) | YES | YES (prune `*/pack-capability-pool/*` L505) | PATCHED |
| `swiftdata_marker_detected` (599) — markers (a)/(b) `find ... -name '*.swift'` (L614) | YES | YES (prune L620) | PATCHED |
| `python_observability_marker_detected` (731) — marker (b) `find ... -name '*.py'` (L777) | YES | YES (prune L781) | PATCHED |

Note on `python_data_marker_detected` marker (c): it greps the SAME `$py_files`
list produced by marker (b)'s already-pool-excluded `find` — so marker (c) is
covered transitively (no separate `find`). Confirmed.

**`scripts/lib/detect.sh` — NON-tree-scanning / out-of-scope detectors (correctly NOT patched):**
- `detect_installed_capabilities` (253) — reads `$target/CLAUDE.md`'s
  `**Active skills:**` line via `grep`; does NOT walk the tree → cannot see the
  pool → out of scope (matches the prompt's explicit carve-out).
- `detect_x_files` (145) / `detect_improperly_added_files` (173) — iterate FIXED
  AI-config subdirs (`.claude/agents`, `.codex/skills`, `docs/pack/prompts`,
  etc.) via explicit `for loc in` lists; detect `x-*` membership / roster drift,
  not language markers; never traverse `pack-capability-pool/`. Not "marker
  detectors that could see the pool." Out of scope.
- Manifest-filename scans inside the four functions (`$target/pyproject.toml`,
  `Package.swift`, `requirements.txt`, `buf.yaml`, etc.) read live-tree ROOT
  files by name and do NOT recurse into the pool → no change needed (the pool's
  `pyproject.toml` is at `pack-capability-pool/pyproject.toml`, not `$target/`).

**`scripts/init-project.sh` — tree-scanning detectors:**
| Fn | Pool-excluded? | Verdict |
|---|---|---|
| `detect_language_markers` (138) — all marker `find`s | YES (existing C2 edit; NOT altered by me) | UNTOUCHED (C2 baseline) |
| `detect_source_files` (194) — `find ... '*.swift'` (L197), `'*.py'` (L198) | YES (`-not -path '*/pack-capability-pool/*'`) | PATCHED (N-1) |

Conclusion: ALL tree-scanning marker detectors that could see the pool are
excluded. No asymmetric coverage remains.

---

## Per-task detail

### S-1 — `scripts/lib/detect.sh` (4 functions)

Each function's recursive `find` walk gains `pack-capability-pool/` pruning,
matched to that function's existing style:

- **`python_data_marker_detected` marker (b)** — the simple
  `find "$target" -name "*.py" -not -path ...` chain gains a fifth
  `-not -path "*/pack-capability-pool/*"` clause (L412), alongside the existing
  `-not -path "*/tests/*"` / `test_*.py` filters.
- **`protobuf_marker_detected` marker (a)**, **`swiftdata_marker_detected`
  markers (a)/(b)**, **`python_observability_marker_detected` marker (b)** — these
  use the `\( -path '*/node_modules' -o ... \) -prune -o ... -print` prune-set
  form; each gains `-o -path '*/pack-capability-pool/*'` inside the prune group
  (L505 / L620 / L781), alongside `node_modules`/`.git`/`build`/`.venv`/etc.

**Load-bearing comments (NOT defensive/parity):** each exclusion carries a
comment stating the pool genuinely ships marker files that would mis-fire — e.g.
protobuf (L496–500):
> The `pack-capability-pool/` prune is LOAD-BEARING (not defensive): the BD-200
> tracked pool ships `pack-capability-pool/proto/*.proto` masters on EVERY
> installed project, so without this exclusion a Swift-only client would
> mis-fire `protobuf-marker: yes` off its own pool.

python-data (L404–408), swiftdata (L609–612), python-observability (L772–775)
carry the equivalent LOAD-BEARING framing (server `.py` masters; `*-swift.sh` /
`.swift` masters; server `.py` + obs import masters).

### N-1 — `scripts/init-project.sh` `detect_source_files()`

Both `find` walks (`*.swift` L197, `*.py` L198) gain
`-not -path '*/pack-capability-pool/*'`. Comment (L189–193) frames it as
consistency/forward-safety: this diagnostic runs at PREVIEW time (before S5b
populates the pool), so the pool is absent today and there is no current harm,
but excluding it keeps the count honest if the helper is ever called
post-install. (Distinct from S-1's load-bearing framing — N-1 is genuinely
forward-safety, not active mis-fire, matching the review's NIT rating.)

### Test — `scripts/test-detect.sh` (75 added lines, additive only)

New section "pack-capability-pool/ exclusion (BD-200)" (L924–997):

- **Fixture `pool-exclusion-swift-only`** — live-tree `Sources/App/main.swift`
  (genuine Swift project) + a `pack-capability-pool/` containing
  `proto/myorg/v1/svc.proto` + `buf.yaml` (protobuf markers), `pyproject.toml`
  (sqlalchemy + opentelemetry deps), `server/app/mod{1..6}.py` (≥5 .py) +
  `server/app/obs.py` (`import opentelemetry`). Assertions:
  - `protobuf-marker: no` (pool .proto/buf NOT fired) — the headline assertion
    the prompt required.
  - `python-data: no` (pool pyproject + server `.py` NOT fired) — guards the
    ≥1-python-marker requirement.
  - `python-observability-marker: no` (pool obs import NOT fired) — second
    python marker guarded.
  - **Control:** add a live-tree `Sources/Model/Item.swift` with
    `import SwiftData` + `@Model` → `swiftdata-marker: yes` (prune removes the
    pool only, never live-tree markers).
- **Fixture `pool-exclusion-live-proto`** — a REAL live-tree
  `proto/myorg/v1/svc.proto` AND a `pack-capability-pool/proto/pooled.proto`
  both present → `protobuf-marker: yes` (live marker wins; the exclusion narrows
  to the pool, it does not over-suppress genuine markers).

---

## A/B proof (independent, Swift-only `/tmp` scratch, provisioned + cleaned)

Scratch tree `/tmp/bd200-ab.*`: live-tree `Sources/App/main.swift` + a
`pack-capability-pool/` with `proto/*.proto` + `buf.yaml` + `pyproject.toml`
(sqlalchemy, opentelemetry-api) + `server/app/mod{1..6}.py` + `server/app/obs.py`
(`import opentelemetry`). Sourced `detect.sh`; `detect_source_files` extracted
from `init-project.sh` via `sed`. Cleaned up (`rm -rf`) after.

```
######## A: POOL PRESENT (incl. detect_source_files) ########
  python-data: no
  python-observability-marker: no
  protobuf-marker: no
  swiftdata-marker: no
  source-files: *.swift=0, *.py=0
######## B: POOL MOVED ASIDE ########
  python-data: yes
  python-observability-marker: yes
  protobuf-marker: yes
  swiftdata-marker: no
  source-files: *.swift=0, *.py=0
```

**Interpretation:** Moving the pool aside flips `python-data` / `python-observability`
/ `protobuf` from `no` → `yes`. The `yes` is the mis-fire (the pool content
tripping the marker); the `no` (state A, pool present, exclusion active) is
correct for a Swift-only project. This empirically proves the exclusion is
**load-bearing**: with the pool present, the prune is the only thing keeping the
markers correct. (`source-files: *.swift=0` because the live Swift file is at
depth-3 `Sources/App/main.swift`, beyond `detect_source_files`'s `-maxdepth 2` —
irrelevant to the pool point; the key result is the pool's `.py` files are NOT
counted in either state.) The result is stronger than the review's example
(which showed protobuf alone flipping); here all three python/protobuf markers
flip.

## No-regression proof (real live-tree markers WITH pool present)

Same scratch tree, pool present, plus a REAL live-tree
`proto/myorg/v1/real.proto`, `pyproject.toml` (sqlalchemy + opentelemetry),
`src/m{1..5}.py` (`import sqlite3`) + `src/o.py` (`import opentelemetry`):

```
protobuf-marker: yes   (expect yes — real live proto)
python-data: yes       (expect yes — real live python)
python-observability-marker: yes  (expect yes — real live obs)
```

Real live-tree markers still fire `yes` even with the pool present → the
exclusion narrows to the pool only; it does not suppress genuine project
markers. No regression.

---

## Verification results (all PASS)

| # | Command | Result |
|---|---|---|
| 1 | `bash -n scripts/lib/detect.sh scripts/init-project.sh` | `SYNTAX OK (both files)` |
| 2 | A/B proof (above) | PASS — markers correct pool-present; mis-fire only when pool moved aside (proves load-bearing) |
| 3 | No-regression (above) | PASS — real live proto/python/obs still `yes` with pool present |
| 4a | `bash scripts/test-detect.sh` | `100 passed, 0 failed` (incl. 5 new pool assertions) |
| 4b | `bash scripts/tests/test-init-project.sh` | `Passed: 67 / Failed: 0` |
| 5 | `bash test-fixtures/build.sh --all --clean` | manifest regenerated; reproducible (regen == pre-regen working tree, byte-for-byte) |
| 6a | `python3 scripts/validate-pack.py` | `PASSED — all checks clean` (Check 48 WARNs are pre-existing JC-5 advisory, exit 0, not introduced here) |
| 6b | `bash scripts/tests/test-validate-pack-check-41.sh` | `All tests passed.` (FAIL: 0) |
| 6c | Check 47 frozen 2-tuple | UNMOVED: `("scripts/lib/detect.sh", "scripts/pack-help.sh")` |

Note on test path: the detect test is `scripts/test-detect.sh` (per the prompt;
verified as the actual location). The init-project test is
`scripts/tests/test-init-project.sh`.

### Manifest diff (vs committed HEAD)

```
 v10-minimal  19558cbac58ed3e47642a6bbe64418a38c60bc16   (unchanged)
 v10-realistic-ot  4c62945f72b037908b38967d5d8f019745263258   (unchanged)
-v11-realistic-ot  e97888b6121b3e1490f513c9851a9dd80da18f90
-v11-flat-file  3fc3036d6fe8ccc764ef836b2f084e39ab9df6fe
-v11-tracker-on  d83c27df1438e154bc8d159b185b3c44de14cbbd
+v11-realistic-ot  b933e2142a00b4c95cdf6d2be940744ac1b05995
+v11-flat-file  5587dc156de0cef3b517902d17d108b80f787c63
+v11-tracker-on  eafdd09a085258f215b92af7e91ba04186250a2b
 existing-project-mid-dev  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619   (unchanged)
```

Exactly the 3 v11-* fixture rows move (`detect.sh` is S11-installed into v11
fixtures); v10-* + existing-project rows are byte-unchanged (they use the v10
init). Expected per `regenerate-manifest-v11-surface`. (The manifest was already
regenerated by the prior attempt; my re-run reproduces it byte-for-byte —
idempotent.)

---

## BD-202 boundary (intact)

`git diff` of my touched files for `cmd_update`/`wipe`/`repopulate`/`refresh`/
`three_way`/`customization`/`delete-propagat`/`removed-by-pack` (added lines):
the ONLY hit is a COMMENT explicitly EXCLUDING that logic and pointing to BD-202
(`# only — NO `pack update` refresh / wipe-repopulate (that is BD-202).` in the
existing C2 `detect_language_markers` block, which I did not alter). NO
update/refresh/wipe engine, no `cmd_update` logic, no `pack update` pool handling
added. Boundary intact.

---

## Scope discipline

- **C2's other edits NOT altered:** the T4 pool stage, S9 skip, Check-41 NOTE, F1
  comment, and the existing `detect_language_markers()` pool-exclusion are all
  C2 baseline; my diff touches none of them (the `detect_language_markers`
  exclusion at L138–186 is unchanged).
- **C1 files NOT touched:** `git diff --name-only | grep -E 'capability-tables|add-capability'`
  → empty. No C1 file in my diff.
- **No new BD-202 logic:** confirmed above.
- **No pack-only token leak:** added lines in the three source files grepped for
  `pack-ops/`/`maintenance-docs/`/`PACK-CHAT`/`PACK-AGENTS`/`pack-architect`/
  `pack-coder`/`pack-reviewer`/`Pack Chat` → none. (`pack-capability-pool/` is a
  client-tree directory name, not a pack-only token.)

---

## Boundary discipline check

All three patched source files (`scripts/lib/detect.sh`,
`scripts/init-project.sh`, `scripts/test-detect.sh`) are **pack-side** (under
`scripts/`). NONE is a `project-template/` tree, `supporting-docs/`, or other
project-side / client-shipped CONTENT surface, so the project-side
SSOT-investigation pre-flight (P-missed-7) does NOT fire for these edits.
`detect.sh` is client-INSTALLED (S11) and pack-side, but the edit is pack-internal
scan logic (a `find` prune) carrying no project-side concept that needs a
project-side SSOT; `pack-capability-pool/` is a client-tree directory introduced
by BD-200, not a pack-only mechanism. No project-side file edit was made →
"no SSOT augmentation needed; all edits are pack-side scan logic."

---

## Files changed (inventory)

| Path | Change type | Delta |
|---|---|---|
| `scripts/lib/detect.sh` | modified | pool-exclusion + LOAD-BEARING comment in 4 `*_marker_detected()` finds (S-1) |
| `scripts/init-project.sh` | modified | pool-exclusion + consistency/forward-safety comment in `detect_source_files()` (N-1); `detect_language_markers()` C2 baseline edit unchanged |
| `scripts/test-detect.sh` | modified | +75 lines: pool-exclusion assertions + controls (additive only) |
| `test-fixtures/manifest.txt` | modified | regenerated; 3 v11-* rows moved |
| `maintenance-docs/v11-implementation/IMPL-BD-200-C2-fix1-redo.md` | new | this report |

(The four `?? ` untracked files in `git status` — IMPL/PACK-REVIEW docs from
prior C1/C2 steps — are not mine and were left untouched.)

---

## Plan deviations

**Zero.** The fix implements S-1 + N-1 exactly as the review's recommended fix
specifies, in the family-shaped style of the existing T4 patch. The prior
(untrusted) attempt's edits were found already correct and complete on
independent re-derivation; no correction was required, no deviation introduced.

## New POQs

None.

---

## Definition-of-Done checklist

| Item | Status |
|---|---|
| S-1: all 4 `*_marker_detected()` finds pool-excluded, LOAD-BEARING comments | PASS |
| N-1: `detect_source_files()` pool-excluded, consistency/forward-safety comment | PASS |
| Every tree-scanning marker detector that could see the pool is excluded (none unpatched) | PASS |
| `detect_installed_capabilities` correctly NOT patched (reads CLAUDE.md, not tree) | PASS |
| Test asserts markers do NOT mis-fire on pool-only Swift tree (proto false; ≥1 python guarded) + controls | PASS |
| `bash -n` clean on both scripts | PASS |
| A/B proof: same correct answer pool-present vs moved-aside (load-bearing proven) | PASS |
| No-regression: real live-tree proto/python still detected with pool present | PASS |
| `test-detect.sh` green (incl. pool assertions) | PASS (100/0) |
| `test-init-project.sh` green | PASS (67/0) |
| Manifest regenerated + reported (3 v11-* rows moved) | PASS |
| `validate-pack.py` PASSED | PASS |
| Check 47 frozen 2-tuple unmoved | PASS |
| C2's other edits NOT altered; C1 files NOT touched | PASS |
| No BD-202 update/refresh/wipe logic added | PASS |
| No state-changing git verb; HEAD unmoved `98b6a9b` | PASS |

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| READ-IN-FULL set | Read IN FULL via the Read tool (per-file proof): `CLAUDE.md` (540 lines; first `# CLAUDE.md — AI Agent Config Pack (Pack Repo)`, last `OT itself is read-only for testing (use /tmp clones or scratch fixtures, never write to real OT).`); `pack-ops/PACK-AGENTS.md` (226 lines; first `# PACK-AGENTS.md — AI Agent Config Pack (Pack Repo)`, last `Always run `git add -A && git status` and confirm staged files before any commit.`); `pack-ops/PACK-CHAT.md` (310 lines; first `# PACK-CHAT.md — Pack Chat Startup and Operating Instructions`, last `propagation order is verified by END-STATE checks ... not a hard-enforced step sequence.`); **`project-template/CLAUDE.md` (456 lines; first `# CLAUDE.md`, last `The marker is preserved across pack upgrades. New projects start with this H2 empty. -->` — the file the prior attempt skipped, read IN FULL here)**; `PACK-REVIEW-BD-200-C2.md` (107 lines, full — S-1+N-1 detail + A/B evidence + triage); `PLAN-BD-200.md` (235 lines, full — §2 T4 + §5); `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` §3.4 + design context (read L1–336 in full incl. §3.4 S9-interaction L104–111; L337–441 is the BD-202 taxonomy, out of scope for this fix); curated memory each via Read in full: `feedback_agents_read_rule_docs_in_full` (71 lines), `feedback_agent_output_rules_applied_block` (15 lines), `feedback_manifest_regen_on_v11_surface` (16 lines), `feedback_bd_pack_only_operational_rule` (35 lines), `feedback_review_cycle_position_checkpoint` (57 lines); SOURCE read: `scripts/lib/detect.sh` (the 4 marker fns + prune-lists, L362–793), `scripts/init-project.sh` (`detect_source_files` L194–200 + `detect_language_markers` L130–186), `scripts/test-detect.sh` (pool section L920–1001). | COMPLIANT |
| agents-read-rule-docs-in-full | Every named doc opened via the Read tool and read end-to-end (line counts + first/last lines above); no skim/crop. The prior attempt's REJECTION cause (skipped `project-template/CLAUDE.md`) is corrected — read in full this time (456 lines, last line quoted). NAMED-set read is COMPLETE → attested COMPLIANT, not partial. | COMPLIANT |
| enumerate-encoding-surfaces | Enumerated EVERY tree-scanning detector across both files (table in "Independent derivation" §): detect.sh has exactly 4 `find` calls (`grep -n 'find '` → L410/501/614/777), ALL 4 pool-excluded (`grep -n 'pack-capability-pool'` → exclusions at L412/505/620/781). Marker (c) covered transitively (reuses marker (b)'s excluded `$py_files`). `detect_installed_capabilities` (CLAUDE.md grep), `detect_x_files`/`detect_improperly_added_files` (fixed AI-config dirs) confirmed non-tree-scanning → out of scope. init-project.sh `detect_source_files` patched (N-1); `detect_language_markers` already C2-excluded. No asymmetric coverage remains. | COMPLIANT |
| rules-applied-verification-block | This block: per-rule name + measured/quoted evidence + terminal verdict; READ-IN-FULL row carries per-file line counts + first/last lines; no empty-evidence rows; no AMBIGUOUS terminal states. | COMPLIANT |
| regenerate-manifest-v11-surface | `detect.sh` is under `scripts/` (v11-surface) and S11-ships → ran `bash test-fixtures/build.sh --all --clean`; manifest reproducible (regen == pre-regen working tree); diff moves exactly the 3 v11-* rows (`v11-realistic-ot`/`v11-flat-file`/`v11-tracker-on`); v10-* + existing-project rows unchanged (quoted diff above). Staged-alongside is Pack Chat's job (agents-never-commit). | COMPLIANT |
| ci-guard-measure-then-bound | Measured post-fix: `python3 scripts/validate-pack.py` → `PASSED — all checks clean` (exit 0; Check 48 WARNs pre-existing JC-5 advisory, not introduced); `test-validate-pack-check-41.sh` → FAIL 0; Check 47 frozen tuple read directly (`grep`/`sed` → `("scripts/lib/detect.sh", "scripts/pack-help.sh")` — unmoved, no widening). No allowlist growth. | COMPLIANT |
| bd-pack-only-operational-rule / BD-202 boundary | `git diff` added-lines grep for `cmd_update`/`wipe`/`repopulate`/`refresh`/`three_way`/`customization`/`removed-by-pack`/`delete-propagat` → only hit is the existing C2 comment EXCLUDING that logic + pointing to BD-202 (not added by me). No update/refresh engine. Added-lines grep for pack-only tokens (`pack-ops/`/`maintenance-docs/`/`PACK-CHAT`/`PACK-AGENTS`/`pack-*` agent names/`Pack Chat`) in the 3 source files → none. `pack-capability-pool/` is a client-tree dir name, not a pack-only token. | COMPLIANT |
| review-cycle-position-checkpoint | Stated cycle position (top of report): this is fix-1 (pass 1 of max 2); next MANDATED step is a FRESH review-2 on the fix (a fix is never terminal, even small); Pack Chat does not self-review. I am the fix-coder, not the reviewer of my own output. | COMPLIANT |
| preflight-stop-means-stop | Emitted the single PREFLIGHT line (`fix-1 redo (S-1 + N-1) complete; verification PASS; HEAD 98b6a9b...`) only AFTER all edits + verification PASSED (syntax, A/B, no-regression, both test suites, manifest, validate-pack, Check 41/47). No partial-report path taken. No parent stop/halt directive received. | COMPLIANT |
| agents-never-commit | Only read-only git verbs used (`git rev-parse`, `git status`, `git diff --name-only`, `git diff`). `/tmp` scratch tree provisioned for the A/B + no-regression proof (no git repo created; `rm -rf`'d after). NO `git add`/`commit`/`push`/`tag`. HEAD `98b6a9b` unmoved (verified start + end). Only Write = this IMPL-REPORT at the prompted path. | COMPLIANT |
