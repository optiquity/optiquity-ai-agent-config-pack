# PACK-REVIEW — BD-167 (RETRO)

**Reviewer:** pack-reviewer
**Date:** 2026-05-16
**Branch:** v11-dev
**HEAD SHA at review:** `03d0dd931ebf7895d81226503032b317b775cdae`
**BD-167 commit SHA:** `142d160b57d177efa3d9e72536b1eb8fd7e0b0cf`
**Scope reviewed:** BD-167 (Commit 19b-pack) only. Out of scope: BD-165
additions to `scripts/migrate-v10-to-v11.sh` (the 6th sub-op call +
post-report advisory + dispatcher flag intercept).
**Authority precedence applied:** Addendum #2 > Addendum #1 >
integration parent > sidecar parent. Plan §5.2 is the spec-of-record
for BD-167's file-creation table.

## §1 — Summary

BD-167 lands the 7 canonical project-side templates (3 streams ×
`_rules.md` + `_intro.md`, plus changelog-only `_format.md`), extends
`_v10_to_v11_install_v11_artifacts` with two additive install loops
(7 canonical templates + 18 BD-161 net-new SKILL.md files = 6 skills
× 3 CLIs), and extends `_tar_read_entry_flat` with a per-entry-prefer-
mirror-fallback shim. Trinity files were NOT touched (correct — those
edits land in BD-167b). All baseline test suites continue to pass
(57/57 per-entry, 43/43 migrator, 31/31 tracker-agent-read,
validate-pack clean across all current checks).

**Verdict:** 2 MUST, 1 SHOULD, 3 NIT. The two MUSTs are real correctness
findings — one is a contract-vs-runtime regex divergence introduced by
the later BD-164 retro fix that BD-167's `_rules.md` was not updated
to match; the second is an under-specified mirror-fallback branch in
`_tar_read_entry_flat` that routes project-side TD-*/phase-*
fall-through reads to the wrong mirror file. All findings are
in-v11.0 fix candidates with concrete fix proposals.

## §2 — Findings

### M1 — `project-template/docs/project/changelog/_rules.md` cites pre-BD-164-retro strict regex; diverges from `scripts/lib/per-entry/_lib.sh` and the BD-164 retro Option B

- **File / Symbol:** `project-template/docs/project/changelog/_rules.md`
  line 15 (Filename convention section).
- **Quote:**
  > Per-entry files match `^\d{4}-\d{2}-\d{2}-.+\.md$` (e.g.,
  > `2026-04-20-phase-35.md`).
- **Architect-doc / cross-source binding:**
  - `scripts/lib/per-entry/_lib.sh:113`
    > `entry-regex) printf '^[0-9]{4}-[0-9]{2}-[0-9]{2}(-.+)?\.md$' ;;`
  - `IMPLEMENTATION-REPORT-BD-164-RETRO-FIX.md` §S3 (BD-164 retro fix,
    Option B): "Slug is OPTIONAL per sidecar §3.5 (OT convention
    typically carries a slug, but the design does not lock it). The
    decompose `id_extract` bare-date fall-back returns `YYYY-MM-DD.md`
    for unannotated H3 anchors; this regex admits both shapes."
  - Sidecar §3.5 (`ARCHITECTURE-PER-ENTRY-SPLIT.md:417-425`): "the
    filename mirrors the heading. Where an entry is not phase-tied
    (e.g. 'Architecture Iteration' labels per `RESEARCH-PER-ENTRY-SPLIT.md`
    §3 line 417), the filename is `YYYY-MM-DD-<slug>.md`." Sidecar
    permits slug-bearing names but does not require a slug per §3.5
    end-of-section; bare-date is implicit in the bare-anchor fall-back.
  - `scripts/lib/per-entry/toc-regenerate.sh` line 88 (also loosened
    by BD-164 retro): `r"^\d{4}-\d{2}-\d{2}(-.+)?\.md$"`.
- **What's wrong:** the contract (`_rules.md`) says "slug mandatory"
  while the runtime helpers (`_lib.sh`, `toc-regenerate.sh`) admit
  slug-optional. If a client (or the decompose helper, when the
  source H3 heading has no slug to derive) creates
  `2026-04-20.md` (no slug), the helper accepts and indexes it;
  the contract `_rules.md` declares it non-conforming. The contract
  is the document agents and humans read for "what filenames are
  admitted here"; runtime acceptance of a filename the contract
  rejects is a contract divergence and a discoverability defect.
- **Fix (concrete):** edit `_rules.md` line 15 to:
  ```markdown
  Per-entry files match `^\d{4}-\d{2}-\d{2}(-.+)?\.md$` (e.g.,
  `2026-04-20-phase-35.md` or bare `2026-04-20.md` when the source
  H3 anchor has no slug suffix). Date-first for lexical sorting;
  trailing slug optional for human readability per
  `ARCHITECTURE-PER-ENTRY-SPLIT.md` §3.5 + `scripts/lib/per-entry/_lib.sh:113`
  BD-164 retro Option B.
  ```
- **Why MUST:** the `_rules.md` is the per-stream contract (sidecar
  §4.1). Contract-vs-runtime divergence breaks the discoverability
  promise that an agent reading `_rules.md` cold can resolve the
  directory's admission contract in one Read call.

### M2 — `_tar_read_entry_flat` mirror-fallback branch reads `$repo_root/BACKLOG.md` for every pack-id; wrong file for TD-* and phase-* fall-through cases

- **File / Symbol:** `scripts/lib/tracker-agent-read.sh` lines
  247-280 (the fall-through mirror-read block at the tail of
  `_tar_read_entry_flat`).
- **Quote (lines 250-256):**
  > ```bash
  >     # Fall through: per-entry tree absent (pre-v11.0 client) OR
  >     # per-entry file missing (entry not in tree — could be a stale
  >     # mirror or a typo). Read from the mirror.
  >     local backlog="$repo_root/BACKLOG.md"
  >     if [[ ! -f "$backlog" ]]; then
  >         tracker_error_emit "not-found" \
  >             "agent_read: BACKLOG.md not found at $backlog"
  > ```
- **Architect-doc binding:**
  - Integration parent §18.2 #2: "Backward-compatibility shim for
    v10.1 read sites (BD-167). `scripts/lib/tracker-agent-read.sh`
    `_tar_read_entry_flat` should detect 'per-entry tree present'
    via `[[ -d /.backlog/ ]]` check and route accordingly. The
    shim ensures pre-v11.0 client repos continue to work (they
    have monolithic-as-source; mirror is the same file)."
  - Integration parent §5.2: "v10-grammar fields ... read from
    the per-entry file `<stream>/<ID>.md`, NOT from the regenerated
    mirror, and NOT from `_toc.md`" — for the flat-file mode
    workflow. The shim's prefer-branch implements this correctly;
    the fallback branch is the failure mode that needs handling.
  - The new prefer-branch resolves three streams (lines 189-209):
    `BD-*` → `$repo_root/backlog/`, `TD-*` →
    `$repo_root/docs/project/backlog/`, `phase-*` →
    `$repo_root/docs/project/implementation-plan/`. The fall-through
    branch (line 250) only ever reads pack-root `BACKLOG.md`.
- **What's wrong:** when a `TD-NNN` or `phase-N` lookup hits the
  fall-through path (per-entry tree absent OR per-entry file
  missing), the function reads pack `BACKLOG.md` — wrong mirror
  for project-side entries. The expected fallback for project-side
  IDs is `$repo_root/docs/project/BACKLOG.md` (for TD-*) or
  `$repo_root/docs/project/IMPLEMENTATION-PLAN.md` (for phase-*).
  Real-world failure modes the bug exposes:
  - v11.0 client where the project-side per-entry tree hasn't yet
    been written (e.g., greenfield project before its first
    decompose, or a project mid-migration). Project-side TD-*
    lookup falls through to pack `BACKLOG.md` (which contains BDs,
    not TDs) → returns "not found in BACKLOG.md".
  - v11.0 client mid-promote: per-entry file deleted or temporarily
    absent for one entry but its block still exists in
    `docs/project/BACKLOG.md`. Project-side TD-* lookup falls
    through to pack `BACKLOG.md` instead of the project mirror
    that holds the entry.
  - phase-N / phase-N.M lookups always fall through to pack
    `BACKLOG.md` (which contains no phases at all) unless the
    project-side per-entry tree exists and the per-entry file is
    present.
- **Why the existing test suite missed it:** `tracker-agent-read-test.sh`
  test 2.3 reads `TD-010` from a synthetic `BACKLOG.md` that
  contains both BDs and TDs (pre-v11.0 test fixture shape). The
  fixture's TD-010 sits in pack-root `BACKLOG.md`, which happens
  to match the buggy code's `$backlog="$repo_root/BACKLOG.md"`
  assignment. Real v11.0 layout never puts TDs in pack `BACKLOG.md`.
- **Fix (concrete):** make the mirror-fallback per-stream-aware,
  mirroring the prefer-branch's stream resolution:
  ```bash
  # Fall through: per-stream-aware mirror selection.
  local mirror_path=""
  case "$pack_id" in
      BD-*)    mirror_path="$repo_root/BACKLOG.md" ;;
      TD-*)    mirror_path="$repo_root/docs/project/BACKLOG.md" ;;
      phase-*) mirror_path="$repo_root/docs/project/IMPLEMENTATION-PLAN.md" ;;
      *)       mirror_path="$repo_root/BACKLOG.md" ;;
  esac
  if [[ ! -f "$mirror_path" ]]; then
      tracker_error_emit "not-found" \
          "agent_read: mirror not found at $mirror_path for $pack_id"
      return 1
  fi
  python3 - "$mirror_path" "$pack_id" <<'PYEOF' || return 1
  ...
  PYEOF
  ```
  Also update the IMPL-REPORT §4 6-scenario list (or its successor
  test) to add per-stream-fallback coverage:
  - TD-NNN lookup on a v11.0 client where `docs/project/backlog/`
    is absent → reads `docs/project/BACKLOG.md`.
  - phase-N lookup on a v11.0 client where
    `docs/project/implementation-plan/` is absent → reads
    `docs/project/IMPLEMENTATION-PLAN.md`.
  - phase-N.M lookup on a v11.0 client where the
    `docs/project/implementation-plan/` tree exists but `phase-N.md`
    is missing → falls through; reads `docs/project/IMPLEMENTATION-PLAN.md`.
  Also extend `tracker-agent-read-test.sh` with project-side TD-*
  and phase-* fixtures that exercise the new fallback paths.
- **Why MUST:** integration parent §18.2 #2 names backward-compat
  as a contract for the shim. The shim correctly preserves backward
  compat for BD-* (the pre-v11.0 capability) but BREAKS new
  v11.0 TD-* and phase-* fall-through reads. Per the prompt: "Per
  Addendum §6.4 BD-167 spec: tasks inline; phase-N.M lookups
  resolve to the phase-N.md file" — but if `phase-N.md` doesn't
  exist on disk yet, the fallback should land on the project mirror,
  not pack BACKLOG.md. This is a latent bug; the test suite's
  current 31/31 PASS only confirms that BD-* fallback still works.

### S1 — IMPL-REPORT §3 / §4 line citations have drifted under later BD-164 retro and BD-165 additions

- **File / Symbol:**
  `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-167.md`
  §3 ("was lines 270–337, now lines 270–410", "new logic at lines
  338–409") and §4 ("was lines 153–186, now lines 153–284", "lines
  156–242 are the new prefer block, 243–284 are the unchanged
  mirror-fallback").
- **Current state:**
  - `scripts/migrate-v10-to-v11.sh` is now 922 lines (was 853 at
    BD-167 commit, per `git show 142d160:scripts/migrate-v10-to-v11.sh`).
    `_v10_to_v11_install_v11_artifacts` is now lines 286-427; the
    BD-167 extension starts at the comment block on line 354 and
    ends with the final closing brace at line 426.
  - `scripts/lib/tracker-agent-read.sh` is still 302 lines; the
    function body shape matches the IMPL-REPORT description but
    individual line offsets may have shifted under BD-164's retro
    awk-regex / grep-pattern tweaks in sibling helpers (which don't
    touch `tracker-agent-read.sh` itself).
- **Architect-doc binding:** the IMPL-REPORT is an audit artifact;
  its file:line citations are the only mechanism that allows a
  future reviewer to verify the change site without re-deriving
  it from scratch. Drift weakens the audit.
- **What's wrong:** the cited line ranges in IMPL-REPORT §3 / §4
  no longer index the BD-167 changes accurately. Anchoring to
  function names + comment block markers (`BD-167:`, `BD-161 …
  absorbed`, "Per-entry tree exists AND per-entry file is present")
  would be drift-resilient.
- **Fix (concrete):** add a "Line numbers may drift under later
  commits in this batch" footnote to IMPL-REPORT §3 / §4 (or
  re-anchor to function/comment markers). The prompt acknowledges
  this as expected drift, so this is a documentation-quality
  improvement, not a correctness defect. **Acknowledged in the
  review prompt as out of BD-167's correctness scope** — included
  here for completeness.
- **Why SHOULD:** the IMPL-REPORT is the canonical post-hoc record
  of what landed in BD-167. Future maintenance reading it should
  not have to mentally subtract BD-164/BD-165 commit deltas to
  locate the BD-167 change sites.

### N1 — `changelog/_intro.md` adds "the project's" qualifier vs OT v10 source

- **File / Symbol:**
  `project-template/docs/project/changelog/_intro.md` line 18.
- **Quote:**
  > Historical record of architectural decisions and phase completions.
  > Current architecture is documented in the project's `ARCHITECTURE.md`.
- **OT v10 source (per `RESEARCH-PER-ENTRY-SPLIT.md` §3 line 407):**
  > Historical record of architectural decisions and phase completions.
  > Current architecture is documented in ARCHITECTURE.md.
- **What's a NIT:** the "project's" qualifier is added vs the OT
  source. For a pack template that ships into ANY client project
  (not just OT), the qualifier provides useful clarity. Defensible
  but represents a small departure from byte-faithful preservation
  of the OT source. Not a correctness defect; documentation choice.
- **Fix (concrete, optional):** either accept the "project's"
  qualifier as defensible pack-template adaptation (preferred), or
  match OT verbatim. Either is fine; document the choice if kept.

### N2 — `_rules.md` write-authority sections pointer-then-reroute is awkward for client-side reads

- **File / Symbol:** all three `_rules.md` files (backlog: line 50-55;
  implementation-plan: 50-55; changelog: 50-55), Write authority
  section.
- **Quote (backlog):**
  > Writes are PM-Chat authority. Read more at `docs/pack/PM-CHAT.md`,
  > `docs/pack/METHODOLOGY.md` Part 7, and pack `PACK-AGENTS.md` (the
  > project-side analog ships in PM-CHAT.md).
- **What's a NIT:** these canonical templates ship into client
  projects. Client projects don't have `PACK-AGENTS.md` (that's
  pack-self only). The text names `PACK-AGENTS.md` then immediately
  reroutes to PM-CHAT.md ("the project-side analog ships in
  PM-CHAT.md"). A client reader is told to look at a file they
  don't have. Simplifying to just point at PM-CHAT.md +
  METHODOLOGY.md would be cleaner.
- **Fix (concrete, optional):** in the project-side `_rules.md`
  copies, drop the `pack PACK-AGENTS.md` reference; point only at
  `docs/pack/PM-CHAT.md` + `docs/pack/METHODOLOGY.md` Part 7 (or
  Part 4 for implementation-plan; or `_format.md` for changelog).
  Example revised wording for backlog:
  ```markdown
  ## Write authority

  Writes are PM-Chat authority. Read more at `docs/pack/PM-CHAT.md`
  + `docs/pack/METHODOLOGY.md` Part 7. The monolithic
  `docs/project/BACKLOG.md` is a regenerated mirror — read-stable
  but never source of truth; hand-edits are silently overwritten
  on the next regeneration.
  ```

### N3 — IMPL-REPORT §7 O-1 framing conflates Addendum #1 §6.2 BD-167 File/Symbol with §17.2 + §9.7

- **File / Symbol:**
  `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-167.md`
  §7 O-1 ("Pack-side `/backlog/` and `/changelog/` canonical
  templates not in scope of this commit").
- **What's a NIT:** O-1 surfaces the gap between Addendum #1 §6.2
  BD-167 File/Symbol list (which mentions pack-side `/backlog/`
  + `/changelog/` templates "extracted from `BACKLOG.md:1-20` +
  `BACKLOG.md:2248`-onward at first migration per original §9.7")
  and the plan §5.2 file table (which only includes project-side
  templates). The Addendum #1 §6.2 reference is NOT a "ship these
  in 19b-pack" instruction — it's a planning-doc note about where
  the pack-side templates will eventually come from (extracted at
  first migration via the BD-165 decompose step). Per integration
  parent §9.7 + §17.2 BD-167 File/Symbol, pack-side `/backlog/`
  + `/changelog/` are EXTRACTED at first migration, not pre-shipped
  from `project-template/`. The implementer correctly followed
  plan §5.2; the framing "surfaced for Pack Chat to decide" reads
  as if it's an open question, but §9.7 already settled it.
- **Fix (concrete, optional):** edit IMPL-REPORT §7 O-1 to note
  that integration parent §9.7 settles the question (decompose
  step extracts pack-side at first migration; nothing to pre-ship
  from `project-template/` on the pack-side); the §6.2 list is a
  planning-doc summary, not a pre-shipping mandate.

## §3 — Verification

```
$ pwd
/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev

$ git rev-parse HEAD
03d0dd931ebf7895d81226503032b317b775cdae

$ git rev-parse --abbrev-ref HEAD
v11-dev

$ git log --oneline -5
03d0dd9 fix: v11 — BD-164 retro review/fix (M1 CI wire + S1-S4 contract/regex + 7 nits/observations)
6696182 feat: v11 — BD-168 validate-pack Checks 32 (mirror-in-sync) + 33 (TOC-in-sync) + 34 (cross-reference integrity)
91e497c feat: v11 — BD-166 init-project.sh greenfield per-entry tree install (S11 extension)
a5b4a6e feat: v11 — BD-165 v10→v11 migrator decompose-streams 6th sub-op + --force-overwrite-mirror flag (BD-095 bridge)
8ba0164 docs: v11 — BD-167b per-entry split PM-only edits (trinity Key files + PACK-AGENTS.md + CLAUDE.md pack-memory + pack-* agent prompts)
142d160 feat: v11 — BD-167 per-entry split client artifact installs (absorbs BD-161)

$ git show 142d160 --stat | tail -15
 .../IMPLEMENTATION-REPORT-BD-167.md                | 1201 ++++++++++++++++++++
 project-template/docs/project/backlog/_intro.md    |   54 +
 project-template/docs/project/backlog/_rules.md    |   55 +
 project-template/docs/project/changelog/_format.md |   72 ++
 project-template/docs/project/changelog/_intro.md  |   57 +
 project-template/docs/project/changelog/_rules.md  |   55 +
 .../docs/project/implementation-plan/_intro.md     |   62 +
 .../docs/project/implementation-plan/_rules.md     |   55 +
 scripts/lib/tracker-agent-read.sh                  |   94 ++
 scripts/migrate-v10-to-v11.sh                      |   74 ++
 10 files changed, 1779 insertions(+)

$ bash -n scripts/migrate-v10-to-v11.sh && echo MIGRATOR OK
MIGRATOR OK

$ bash -n scripts/lib/tracker-agent-read.sh && echo TRACKER-AGENT-READ OK
TRACKER-AGENT-READ OK

$ wc -l project-template/docs/project/*/*.md
      54 project-template/docs/project/backlog/_intro.md
      55 project-template/docs/project/backlog/_rules.md
      72 project-template/docs/project/changelog/_format.md
      57 project-template/docs/project/changelog/_intro.md
      55 project-template/docs/project/changelog/_rules.md
      62 project-template/docs/project/implementation-plan/_intro.md
      55 project-template/docs/project/implementation-plan/_rules.md
     410 total

$ grep -nE '^## ' project-template/docs/project/*/_rules.md | wc -l
18    # 3 files × 6 sections each ✓

$ python3 scripts/validate-pack.py 2>&1 | tail -3
============================================================
PASSED — all checks clean

$ bash scripts/tests/test-per-entry.sh 2>&1 | tail -3
PASS: 57
FAIL: 0
All per-entry tests PASSED (57/57).

$ bash scripts/tests/test-migrate-v10-to-v11.sh 2>&1 | tail -3
Passed: 43
Failed: 0
All tests passed.

$ bash scripts/tests/tracker-agent-read-test.sh 2>&1 | tail -3
Passed: 31
Failed: 0
All tests passed.
```

### Architect-doc-binding spot checks

- **Sidecar §4.1 five contracts + Addendum §3.3 sixth (supporting
  files):** confirmed 6 sections in each `_rules.md`
  (`grep -nE '^## '`). The "Supporting files" section sits between
  "Lifecycle states admitted" and "Write authority" in all three.
- **Filename regex per stream:**
  - backlog: `_rules.md:15` → `^TD-\d+\.md$`. ✓ matches sidecar §3.3 + V3.3-DELTA §6.4.
  - implementation-plan: `_rules.md:15` → `^phase-\d+\.md$`. ✓ matches
    plan §5.2 final paragraph (planner-deferred resolution: tasks
    inline, no per-task files). Also matches `_lib.sh:100`.
  - changelog: `_rules.md:15` → `^\d{4}-\d{2}-\d{2}-.+\.md$`. ✗
    **diverges** from `_lib.sh:113`'s post-BD-164-retro loosened form
    `^[0-9]{4}-[0-9]{2}-[0-9]{2}(-.+)?\.md$` (see M1).
- **Layer 1 "DO NOT EDIT" HTML comment at line 1 of each
  `_intro.md`** (per Addendum #1 §5.2 sample): confirmed via
  `head -7` on each `_intro.md`. backlog has 5-line comment;
  implementation-plan 6-line; changelog 7-line (extra line for the
  append-only reminder). All three correctly name the per-stream
  tree, the regenerator step, and the "silently overwritten" final
  sentence.
- **Mode-aware "Source of truth" sections** (per Addendum #1 §3.4):
  confirmed in all three `_intro.md` files. Each describes flat-file
  mode (per-entry tree is SoT) and tracker mode (tracker is SoT;
  both per-entry tree and mirror are regenerated from tracker
  state per integration parent §5.6). Wording does not contain
  the mode-unaware integration-parent §6.5 text.
- **HTML-comment back-pointer regex match in `_tar_read_entry_flat`:**
  Python strip regex at line 234: `r'^<!-- per-entry source: .*;
  contract: .* -->\s*$'`. Compare to `pe_ensure_backpointer`
  emission at `_lib.sh:297`: `<!-- per-entry source: %s; contract:
  %s -->`. Compare to `_lib.sh:319` awk strip pattern: `/^<!-- per-
  entry source: .*; contract: .* -->[ \t]*$/`. The shim regex uses
  `\s*$` which is a Python superset of `[[:space:]]*$` /
  `[ \t]*$` — compatible with the BD-164 retro S4 "trailing
  whitespace tolerance" change.
- **Migrator install loop additive-only semantics:** confirmed both
  loops use `[[ ! -f "$target/file" ]]` guards
  (`migrate-v10-to-v11.sh:385-386` for templates;
  `migrate-v10-to-v11.sh:421` for SKILL.md). Re-running the migrator
  on an already-v11-installed target is no-op. Customization-preserve
  semantics correct.
- **BD-161 skill list per integration parent §17.2 + BACKLOG.md:1480:**
  6 skill names enumerated correctly: `swift-concurrency-patterns,
  apple-swiftdata-patterns, protobuf-patterns, python-server-
  architecture, python-data-architecture, python-observability-
  patterns`. All 6 exist under `project-template/skills/`. 3 CLI
  destinations correct (`.claude/skills/`, `.codex/skills/`,
  `.gemini/skills/`). 6 × 3 = 18 installs as the IMPL-REPORT claims.
- **Function placement (BD-167 install loops folded into existing
  `_v10_to_v11_install_v11_artifacts`):** confirmed per
  `migrate-v10-to-v11.sh:286` function open + `:427` close;
  BD-167 extension is the function tail (per integration parent
  §18.1 #10 + Addendum #1 §6.4 recommendation).
- **Bash 3.2 + macOS BSD-utility compat:** install loops use
  `case` statement with literal space-separated word list
  (`support_basenames="_rules.md _intro.md _format.md"`) split
  via `for base in $support_basenames` — Bash 3.2 compatible
  (no associative arrays, no `mapfile`/`readarray`, no `&>`,
  no GNU `cp -t`). Skill loop uses simple `for` over literal
  list — also Bash 3.2 compatible.
- **Trinity files untouched in BD-167 commit:** `git show 142d160
  --stat` confirms only the 10 expected files changed; no
  CLAUDE.md / AGENTS.md / GEMINI.md edits (trinity edits land in
  BD-167b's commit 8ba0164).
- **`_format.md` faithfulness to RESEARCH §3 source:** verified
  against `RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 405-450. All 7
  rules reproduced (Append-only, One-entry-per-phase, Date, Separator,
  Architecture Iteration, BACKLOG.md ✅, README.md Known Limitations
  sync). Body fields list complete (Summary / Tasks completed /
  Backlog items addressed / Files created / Files modified / Test
  count / Build warnings). Heading shapes for both Phase-N and
  Architecture-Iteration variants present. Filename-mapping section
  is a sensible pack-template addition. ✓ faithful (per O-5 caveat
  in IMPL-REPORT — OT clone unavailable; reconstructed from
  RESEARCH §3).
- **BD-167 commit message format compliance:** `feat: v11 — BD-167
  per-entry split client artifact installs (absorbs BD-161)` —
  conforms to `CLAUDE.md` commit-message format.

### Tests not regressed by BD-167

Per the IMPL-REPORT §6 list, all baseline test suites still pass at
current HEAD (BD-164 retro applied, BD-165/166/168 added, but BD-167
extension still works):

- `validate-pack.py` → PASSED (now 35 checks including BD-168 Checks
  32/33/34).
- `test-per-entry.sh` → 57/57.
- `test-migrate-v10-to-v11.sh` → 43/43.
- `tracker-agent-read-test.sh` → 31/31 (NB: passes per M2 caveat —
  the test fixture happens to put TD-010 in pack `BACKLOG.md`; the
  buggy fall-through path therefore returns success on the test, but
  is incorrect for real v11.0 layout).

## §4 — Out-of-scope observations

The following are noticed beyond BD-167's strict scope and are not
classified as findings. They are surfaced for in-v11.0 awareness.

### Observation 1 — Pack-side per-entry tree skeletons (`/backlog/`,
`/changelog/`) are not ship-from-`project-template/` per integration
parent §9.7

The pack-self per-entry trees are extracted at FIRST MIGRATION via
the BD-165 decompose step. For the pack repo itself, the pack-self
decompose happens at Batch 23 (BD-102 dog-food) per the v11.0 batch
sequence. BD-167 correctly does NOT pre-ship pack-side templates
from `project-template/` (the IMPL-REPORT §7 O-1 framing is overly
hesitant on a question already settled by §9.7 — see N3 above).

### Observation 2 — `tracker-agent-read-test.sh` has no test fixtures
that exercise the prefer-branch (per-entry tree present)

The 31/31 PASS confirms the FALLBACK path works for BD-* lookups
(the only pre-v11.0 capability). The IMPL-REPORT §4 "End-to-end
smoke test" of 6 scenarios was run ad-hoc against `/tmp` and is not
codified as a test fixture in the test suite. Net result: the new
prefer-branch behavior (BD-167's main addition) has zero CI test
coverage. Combined with M2 above (the fall-through branch has a
real bug uncovered because the test fixture happens to put TDs in
pack `BACKLOG.md`), this is a test-coverage gap that should be
closed in the BD-167 fix-pass. Concrete: add Group 5 (per-entry
prefer-branch) and Group 6 (per-stream-aware fallback) to
`tracker-agent-read-test.sh` with project-side TD-*/phase-*
fixtures.

### Observation 3 — `MIGRATION-v10-to-v11.md` does not document the
BD-167 per-entry-tree install or the BD-161 SKILL.md installs

The supporting-docs/MIGRATION-v10-to-v11.md doc was not updated by
BD-167. Per plan §5.8 (BD-169 / commit 19g-pack), the MIGRATION doc
updates are scheduled there. Not a BD-167 defect; surfaced for
awareness.

### Observation 4 — `README.md` Repository Layout entries do not yet
name the new `project-template/docs/project/{backlog,
implementation-plan, changelog}/` directories

Per plan §5.9 (BD-169b / commit 19g-PM), README.md Repository Layout
entries are scheduled there as PM-only edits. Not a BD-167 defect;
surfaced for awareness.

### Observation 5 — `BACKLOG.md:1480` BD-167 File/Symbol line cites
"lines 144–148 to install new templates + BD-161 net-new SKILL.md
installs" — accurate at BD-167 time; the install-step is now at
the function-tail of `_v10_to_v11_install_v11_artifacts` (lines
354-426 post-BD-165). BD-167 itself did not edit BACKLOG.md (out of
scope for the pack-coder); the BD-167 / BD-167b commits delegated
BACKLOG edits to Pack Chat per the PM-only-files rule.

---

End of PACK-REVIEW-BD-167-RETRO.md.
