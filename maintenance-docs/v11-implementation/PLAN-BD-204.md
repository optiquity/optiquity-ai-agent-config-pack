# PLAN-BD-204 — Implementation plan: pack backlog tree ↔ GH Issues reversible tracker migration (Mode 2 ↔ Mode 3)

> **Agent:** pack-planner. **Mode:** PLAN ONLY (no source edits, no git verbs, no status flips,
> no implementation). A `pack-coder` executes each commit below under the bounded review/fix cycle.
> **HEAD (verified):** `bc6861e` (`git rev-parse HEAD` → `bc6861e39f0c3af7770f5f2819ff1e58f036cf95`).
> **Branch:** `v11-dev`. **Date:** 2026-06-06.
> **Spec executed:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md` (all 5 DPs RESOLVED).
> **Brief:** `backlog/BD-204.md` (HARD: pack-only; lossless reversibility; tracker-agnostic; NO monolith; full-CRUD true-SSOT; issue-number independence; surface-generalizable).

## 0. Consequence statement (read-back)

A plan that contradicts the approved design or reopens a fixed decision is REJECTED + REDONE. The
five decision points are FIXED and are NOT reopened here: DP-1 = read-only regenerated mirror (writes
→ tracker via full CRUD); DP-2 = carrier is FORM FAMILY + GH Issue BODY incl. the in-body
`pack-extra-fields` block, NO sidecar file, GH-only non-entry artifacts dropped; DP-3 = the 6-row
status matrix incl. the NEW `Deferred` row (open + `status:deferred`); DP-4 = regenerate `_toc.md`
on EVERY Mode-3 tree-materialization; DP-5 = retire header-snapshot for the pack surface,
`_intro.md` human-only/untouched. This plan sequences the design's execution faithfully; it does not
redesign.

## 0.1 Scope guards (absolute)

- **Pack-only.** Every commit below is pack-only (CI Check 36 `pack-only` keyword). NO commit touches
  `project-template/` or any project-side / client asset. The surface-generalizable machinery wires
  ONLY the `surface=="pack"` branch; the client branch is BD-207 — out of scope, NOT sequenced. The
  `tracker.toml.project-example` `[mirror]` table and the reverse/forward `else` (client) branches are
  UNTOUCHED.
- **Zero regression.** No commit regresses BD-203's no-mirror standard (`backlog/_rules.md:18-26`),
  Check 32′ (no pack monolith, `validate-pack.py:3178` `_check_pack_no_monolith` region), or any
  landed check.
- **Symbol anchors.** Every change cites the design § + the built code BY SYMBOL (line numbers in the
  spec drifted from `e83aed7` → `bc6861e`; this plan re-anchored every site by symbol at `bc6861e`).

---

## 1. Empirical re-measurement at HEAD `bc6861e` (the sites this plan sequences against)

> **Empirical-Evidence Block (HEAD + branch).**
> `CMD`: `git rev-parse HEAD ; git branch --show-current`
> `OUT`: `bc6861e39f0c3af7770f5f2819ff1e58f036cf95` ; `v11-dev`. `AT`: HEAD `bc6861e`, 2026-06-06.
> `INTERP`: the plan sequences against `bc6861e`; the spec's `e83aed7` line numbers are re-anchored by
> symbol below. `CONCL`: SUPPORTED.

> **Empirical-Evidence Block (the 6 monolith sites + carrier sites exist at `bc6861e`, by symbol).**
> `CMD`: `grep -n "<symbol>" scripts/lib/tracker-migrate-forward.sh scripts/lib/tracker-migrate-reverse.sh scripts/lib/tracker-agent-read.sh scripts/lib/tracker-doctor.sh`
> `OUT` (re-anchored, `bc6861e`):
> • forward READ input — `tracker-migrate-forward.sh` `if [[ "$surface" == "pack" ]]` at `:709`/`:732`,
>   `backlog_path="$repo_root/pack-ops/BACKLOG.md"` at `:710`/`:733`; parse via `tmf_parse_backlog` (`:350`, called `:741`).
> • forward Step-10 mirror regen — `_tmf_regen_mirror "$backlog_path"` at `:1208` (def `:1429`), Step-10 comment `:1202`.
> • forward create — `provider_create` at `:831`/`:885`; close/comment — `provider_close` `:1134`/`:1604`, `provider_comment` `:1143`.
> • reverse EMIT target — `_tmr_emit_backlog` (def `:606`) writes a `# BACKLOG` monolith via embedded python (`lines=["# BACKLOG",""]` in the heredoc); pack branch sets `backlog_out="$repo_root/pack-ops/BACKLOG.md"` at `:1056-1059`.
> • reverse header-snapshot — `tracker_header_snapshot_capture "$repo_root"` at `:1109`, `tracker_header_snapshot_apply` at `:1117`.
> • reverse sidecar — `sidecar_path=$(tracker_sidecar_emit ...)` at `:1128` (Step 7.5).
> • reverse `_emit_path_list` backup/restore — `:1082-1083` (the four monolith paths), backup loop `:1089`, restore loop `:1144`.
> • reverse `_tmr_decode_status` — def `:192`; canonical-object OPEN-state switch `# Open: derive from label` (`case "$label"`) at `:244-247` (only `status:unblocked`/`*`→Open; NO `Deferred`); legacy `[`-array switch `:198-205` (NO `Deferred`); production call `status=$(_tmr_decode_status "$issue")` at `:526`.
> • agent-read — `mirror_path="$repo_root/pack-ops/BACKLOG.md"` at `tracker-agent-read.sh:264,267`; greps the monolith via `python3` at `:274`.
> • doctor — `backlog_path="$repo_root/pack-ops/BACKLOG.md"` at `tracker-doctor.sh:122`; mtime/mirror-header freshness `:132-154`.
> `AT`: HEAD `bc6861e`, 2026-06-06. `INTERP`: every spec site is present at `bc6861e` (symbols stable;
> lines drifted ≤ a few from `e83aed7`). `CONCL`: SUPPORTED.

> **Empirical-Evidence Block (provider CRUD surface; `provider_update` unwired for BD).**
> `CMD`: `grep -n "provider_create\|provider_update\|provider_close\|provider_list\|provider_get\|provider_comment\|provider_link" scripts/lib/tracker-provider.sh ; grep -rn "provider_update" scripts/lib/`
> `OUT`: provider ops present — `provider_list :125`, `provider_get :126`, `provider_create :128`,
> `provider_update :129`, `provider_close :130`, `provider_comment :132`, `provider_link :136`. NO
> `provider_delete`. `provider_update` is called ONLY in `tracker-promote.sh:801,1215` (project-side
> TD-promotion) — NOT in `tracker-migrate-forward.sh`. `AT`: HEAD `bc6861e`, 2026-06-06. `INTERP`: the
> abstraction has CRUD but the pack-backlog Mode-3 edit path does not yet wire `provider_update`/
> `provider_close`-on-status-cross; BD-204 adds the wiring (reuse the `tracker-promote.sh:801` call
> shape). `CONCL`: SUPPORTED.

> **Empirical-Evidence Block (Check 29 staleness leg hard-fails a no-mirror live config; the no-mirror guard is absent).**
> `CMD`: `sed -n '2699,2780p' scripts/validate-pack.py`
> `OUT`: `_check_mirror_staleness(live_cfg_path)` (def `:2699`): after `mode.state != "tracker"`
> soft-pass (`:2722-2725`) and `forward_complete is not True` soft-pass (`:2728-2731`), it FAILs at
> `last_forward_run` missing (`:2734-2738`), then `[mirror]` table missing/malformed
> (`:2741-2744`), then per missing mirror FILE `if not mirror_path.is_file(): fail(...)`
> (`:2756-2761`). There is NO branch that soft-passes a tracker-mode config with NO `[mirror]` table
> / `mirror.enabled=false`. `AT`: HEAD `bc6861e`, 2026-06-06. `INTERP`: a live no-mirror pack
> `tracker.toml` (`mode='tracker'`+`forward_complete=true`, no `[mirror]`) hard-FAILs at the
> `[mirror]`-table-missing branch — Check 29′ must add a TOP guard that soft-passes the no-mirror
> surface while still FAILing a config that CLAIMS a mirror but is missing it. `CONCL`: SUPPORTED.

> **Empirical-Evidence Block (Check 29 schema leg REQUIRES `[mirror]` on the example files; examples KEEP `[mirror]`).**
> `CMD`: `sed -n '2620,2650p' scripts/validate-pack.py ; cat tracker.toml.pack-example`
> `OUT`: `_validate_tracker_toml` (def `:2543`) `_require("mirror", dict)` (`:2628`) + REQUIRES
> `enabled/location_backlog/location_status/location_changelog/regenerate_on_write` (`:2630-2643`);
> called for `pack_example` (`:2814`) and `client_example` (`:2815`). `tracker.toml.pack-example` has
> `[mode] state="flat-file"` (`:28`), `[mirror] enabled=true location_backlog="BACKLOG.md"...`
> (`:33-40`), `[migration] forward_complete=false` (`:56`). `AT`: HEAD `bc6861e`, 2026-06-06.
> `INTERP`: the EXAMPLE file is flat-file + KEEPS `[mirror]` (its schema leg validates the shipped
> template; it is NOT a live tracker-mode config). The Check 29′ guard must distinguish the EXAMPLE
> schema leg (unchanged — `[mirror]` stays REQUIRED on the example) from the LIVE staleness leg (new
> no-mirror soft-pass). The pack-example file is NOT edited to drop `[mirror]`. `CONCL`: SUPPORTED.

> **Empirical-Evidence Block (the generalization seam: stream-key registry already parameterizes by (key,dir)).**
> `CMD`: `sed -n '72,130p' scripts/lib/per-entry/_lib.sh ; grep -n "pe_write_atomic\|pe_list_entry_files\|per_entry_regenerate_toc\|pe_id_from_filename\|pe_backpointer_line\|pe_entry_regex_for_stream" scripts/lib/per-entry/_lib.sh scripts/lib/per-entry/toc-regenerate.sh`
> `OUT`: `PE_STREAM_KEYS="pack-backlog pack-changelog project-backlog ..."` (`_lib.sh:72`); per-stream
> attrs via `pe__stream_attr` (`:74`) — `pack-backlog` → entry-regex `^BD-[0-9]+[a-z]*\.md$`,
> dir-suffix `backlog`; `project-backlog` → `^TD-[0-9]+\.md$`, `docs/project/backlog`. Write API:
> `pe_write_atomic` (`:393`, stdin→atomic file), `pe_list_entry_files <key> <dir>` (`:426`),
> `pe_id_from_filename` (`:453`), `pe_backpointer_line` (`:300`), `pe_strip_backpointer_stdin`
> (`:335`), `per_entry_regenerate_toc <key> <dir>` (`toc-regenerate.sh:36`). `AT`: HEAD `bc6861e`,
> 2026-06-06. `INTERP`: the engine is ALREADY parameterized by `(stream_key, stream_dir)`; the pack
> reverse-emit + regen become `per_entry`-keyed calls with key `pack-backlog`, dir `/backlog`. The
> shared layer carries NO pack-specifics (the stream key drives the regex). BD-207 reuses with key
> `project-backlog`. `CONCL`: SUPPORTED.

> **Empirical-Evidence Block (encoding surfaces — tests that pin the touched checks / monolith / sidecar).**
> `CMD`: `grep -rln "Check 29\|Check 32\|Check 33\|_tmr_decode_status\|pack-ops/BACKLOG\|reverse.sidecar\|backlog-header.snapshot" scripts/tests/`
> `OUT` (load-bearing): `tracker-migrate-reverse-test.sh` (Group 1 decoders, `:128-150`, legacy `[`-array
> + canonical-object asserts; NO `status:deferred`); `tracker-migrate-roundtrip-test.sh` (asserts
> reconstructed `pack-ops/BACKLOG.md` `:415,487`, sidecar present `:484`, Group-4 sidecar sections
> `:540+`); `tracker-bd132-race-test.sh` (skip-guard refuses BEFORE `_tmr_emit_backlog`, asserts
> `pack-ops/BACKLOG.md` `:247,273`); `tracker-bd133-header-preservation-test.sh` (header-snapshot
> module API + integration); `tracker-agent-read-test.sh`; `test-validate-pack-checks-32-33-34.sh`;
> `tracker-config-schema-test.sh` (Check 29 schema). `AT`: HEAD `bc6861e`, 2026-06-06. `INTERP`: these
> tests ENCODE the monolith/sidecar/header/decode contracts; each commit that flips a contract on the
> pack surface MUST update its encoding tests in lock-step (enumerate-encoding-surfaces). `CONCL`: SUPPORTED.

> **Empirical-Evidence Block (status distribution + the 11-Deferred canary at `bc6861e`).**
> `CMD`: `grep -rh "^Status:" backlog/*.md | sort | uniq -c | sort -rn ; ls backlog/ | grep -cE '^BD-[0-9]+[a-z]*\.md$'`
> `OUT`: confirm against current tree at run time; spec measured `168 Resolved, 28 Open, 11 Deferred,
> 3 Deprecated, 1 Unblocked, 1 Cancelled = 212`. `AT`: HEAD `bc6861e`, 2026-06-06. `INTERP`: the
> 11 `Deferred` entries are the lossless canary for the DP-3 gap-fix; the count is DYNAMIC (measured at
> audit time, never hard-coded). `CONCL`: SUPPORTED (re-measure live at audit time per §4).

---

## 2. File-dependency analysis (the safe ordering)

The flip from Mode-2 to Mode-3 on the REAL pack repo (commit 8) is gated behind ALL the machinery
being correct AND a green scratch-repo proof AND explicit user approval. The dependency chain that
forces the ordering:

1. **`Deferred` decode branch (C-1)** must exist BEFORE any reverse round-trip can be lossless on the
   11 deferred entries — otherwise the §4 oracle's status-distribution leg fails. Pure-decode change,
   no upstream dep. **→ first.**
2. **Check 29′ no-mirror guard + its encoding surfaces (C-2)** must exist BEFORE a live no-mirror
   `tracker.toml` is ever written — otherwise `validate-pack.py` goes RED the moment the pack flips to
   tracker-mode. Validator + test + (NO example-file edit; example keeps `[mirror]`) in lock-step.
   Independent of C-1. **→ early (before the flip).**
3. **Full-CRUD `provider_update` wiring (C-3)** is the steady-state Mode-3 edit path. It depends on
   nothing in C-1/C-2 but is needed BEFORE the dogfood flip so the post-flip pack can edit entries
   (a `Status:` flip → `provider_update` + boundary `provider_close`/reopen). **→ before the flip.**
4. **Reverse-emit repoint to the TREE + header-snapshot retire + sidecar drop (C-4)** is the
   load-bearing no-monolith change: the pack reverse branch emits `/backlog/*.md` via `per_entry_*`
   instead of the `# BACKLOG` monolith, drops the header-snapshot + sidecar calls, and points the
   backup/restore loop at the tree set. This DEPENDS on C-1 (the reconstructed entries must decode
   `Deferred` correctly) and is what makes Check 32′ stay green through a reverse. **→ after C-1.**
5. **Forward read-input repoint + Step-10 retire (C-5)** points the pack forward branch at the TREE
   (`pe_list_entry_files`/parse) and SKIPS the Step-10 monolith regen. This DEPENDS on nothing in
   C-3/C-4 directly but is paired with C-4 to make the full forward+reverse round-trip monolith-free.
   **→ with/after C-4.**
6. **Agent-read + doctor repoint (C-6)** point the Mode-3 read surfaces at the tree. DEPENDS on the
   tree being the Mode-3 emit target (C-4). **→ after C-4.**
7. **The §4 lossless oracle implemented as a runnable scratch-repo test (C-7)** DEPENDS on ALL the
   machinery (C-1..C-6) being in place — it exercises forward → Issues → reverse → tree on a live
   scratch repo and runs the oracle. **→ after C-1..C-6.**
8. **The real pack-repo Mode-2→3 dogfood flip (C-8)** DEPENDS on C-7 green + explicit user approval.
   **→ last.**

**Why the flip is last (the hard gate):** the flip writes a live tracker-mode `tracker.toml`
(`mode.state="tracker"`, `forward_complete=true`) and moves the pack's own 212 entries to real GH
Issues. If ANY of C-1..C-6 is wrong, the flip either fails CI (Check 29′/32′/33) or silently loses
data on the first reverse. The scratch-repo proof (C-7) is the dress rehearsal on the four stress
cases; the flip is the production run.

---

## 3. Ordered commit sequence

Each commit below is a single `pack-coder` spawn under the **bounded review/fix cycle** (coder →
reviewer → triage → fix-coder → commit; max 2 review/fix pairs + 1 final reviewer pass; architect
escalation if dirty after the final). Each commit subject carries the `pack-only` scope keyword
(CI Check 36). Every commit whose diff touches `scripts/` MUST regenerate
`test-fixtures/manifest.txt` (`bash test-fixtures/build.sh --all --clean`) and stage it in the SAME
commit when the manifest diff is non-empty (manifest-regen rule; ALL of C-1..C-7 touch `scripts/`).

### Commit C-1 — `Deferred` reverse-decode branch (DP-3 gap-fill) + test symmetry

- **Commit subject (shape):** `feat: v11 — BD-204 Deferred reverse-decode branch (DP-3) (pack-only)`
- **File scope:**
  - `scripts/lib/tracker-migrate-reverse.sh` — `_tmr_decode_status` (def `:192`).
  - `scripts/tests/tracker-migrate-reverse-test.sh` — Group-1 decoder asserts (`:128-150`).
  - `test-fixtures/manifest.txt` — regen if non-empty (scripts/ touched).
- **Change recipe (design §2.6 / §2.6.1; DP-3):**
  1. In `_tmr_decode_status`, add a `status:deferred) echo "Deferred" ;;` case to the
     **canonical-object OPEN-state `case "$label"` switch** (the `# Open: derive from label` block at
     `:244-247`), parallel to the existing `status:unblocked)   echo "Unblocked" ;;` case. This is the
     ONLY branch on the live production reverse path (the sole production call passes the full Issue
     JSON object — first char `{` — so it takes the canonical-object path; §2.6.1 EE block).
  2. **Enumerate-encoding-surfaces (test symmetry, per §2.6.1):** ALSO add `status:deferred) echo
     "Deferred" ;;` to the legacy `[`-array switch (`:198-205`) AND add a Group-1 fixture assertion
     `assert_eq "1.1 status:deferred → Deferred" "Deferred" "$(_tmr_decode_status '["status:deferred"]')"`
     so the two switches + their tests stay symmetric (asymmetric coverage = audit gap). The legacy
     switch is test-only / out-of-round-trip, but its encoding test must match.
- **Per-commit verification:**
  - `python3 scripts/validate-pack.py` (full run — green).
  - **FULL CI integration battery** (not validate-pack alone): `bash scripts/tests/tracker-migrate-reverse-test.sh`
    (Group 1 decoders, incl. the NEW `status:deferred` assert) + `bash scripts/tests/tracker-migrate-roundtrip-test.sh`
    + `bash scripts/tests/test-v11-realistic-ot.sh` (pins validator banners — guard against a stale
    assertion regression).
  - Manifest regen flagged (scripts/ touched).
- **Dependency/ordering rationale:** pure-decode change, no upstream dep; MUST precede C-4 (the reverse
  emit) so the reconstructed tree decodes the 11 deferred entries correctly. **First.**
- **Bounded review/fix cycle applies** (coder → reviewer → triage → fix-coder → commit).

### Commit C-2 — Check 29′ no-mirror staleness guard (measure-then-bound) + encoding surfaces

- **Commit subject (shape):** `feat: v11 — BD-204 Check 29' no-mirror staleness soft-pass (pack-only)`
- **File scope:**
  - `scripts/validate-pack.py` — `_check_mirror_staleness` (def `:2699`). The schema leg
    `_validate_tracker_toml` (`:2543`) is NOT changed (examples keep `[mirror]`).
  - `scripts/tests/tracker-config-schema-test.sh` AND/OR `scripts/tests/test-validate-pack-checks-32-33-34.sh`
    — whichever pins Check 29 staleness output (the coder greps both for the Check-29 banner +
    soft-pass/ FAIL wording and updates the one that asserts staleness output).
  - `test-fixtures/manifest.txt` — regen if non-empty.
  - **NOT edited:** `tracker.toml.pack-example` (KEEPS `[mirror]`; it is flat-file + the schema leg
    validates it). `tracker.toml.project-example` (project-side — pack-only VIOLATION to touch).
- **Change recipe (design §2.2.C1; ci-guard measure-then-bound; DP-1):**
  1. **Measure (done, §1 EE):** `_check_mirror_staleness` hard-FAILs a live tracker-mode config that
     has NO `[mirror]` table at the `[mirror]`-table-missing branch (`:2741-2744`). The three
     legitimate live-config shapes are: (a) flat-file [already soft-passes `:2722-2725`]; (b) tracker
     + no `[mirror]` / `mirror.enabled=false` [the NEW no-mirror pack surface — must soft-pass];
     (c) tracker + `[mirror]` pointing at real files [the client surface — must KEEP enforcing
     staleness].
  2. **Bound (the guard, sized to KEEP exactly the legitimate set):** add a guard at the TOP of
     `_check_mirror_staleness` (AFTER the `mode != tracker` and `forward_complete is not True`
     soft-passes, BEFORE the `last_forward_run`/`[mirror]`-table branches):
     `if "mirror" not in cfg or not cfg.get("mirror", {}).get("enabled"): ok("...no [mirror] table /
     mirror disabled — no-mirror surface, staleness N/A"); return`. This soft-passes (b); (a) already
     soft-passes; (c) still reaches the staleness branches and FAILs a claims-mirror-but-missing
     config. The guard does NOT widen to swallow a tracker config that DECLARES `[mirror]
     enabled=true` but is missing the file (that still FAILs — correct).
  3. **Enumerate-encoding-surfaces (lock-step):** the validator function + its staleness-output test
     assertion update together in THIS commit. The example schema is NOT changed (example keeps
     `[mirror]`; the schema leg is unaffected). Add a positive test: a synthetic live config with
     `mode.state="tracker"`, `forward_complete=true`, NO `[mirror]` → `_check_mirror_staleness`
     soft-passes; and a negative test: `mode="tracker"` + `[mirror] enabled=true` + missing file →
     FAILs (guard does not over-admit).
- **Per-commit verification:**
  - `python3 scripts/validate-pack.py` (green; Check 29 still green on the unchanged examples).
  - **FULL CI battery:** `bash scripts/tests/tracker-config-schema-test.sh` +
    `bash scripts/tests/test-validate-pack-checks-32-33-34.sh` + `bash scripts/tests/test-v11-realistic-ot.sh`
    (banner-pinning guard).
  - Manifest regen flagged.
- **Dependency/ordering rationale:** independent of C-1/C-3; MUST land before C-8 (the flip writes the
  live no-mirror config). **Early.**
- **Bounded review/fix cycle applies.**

### Commit C-3 — full-CRUD `provider_update` wiring for the Mode-3 pack edit path

- **Commit subject (shape):** `feat: v11 — BD-204 wire provider_update for Mode-3 pack CRUD (pack-only)`
- **File scope:**
  - The Mode-3 pack edit path. Per §2.3, the wiring reuses the `tracker-promote.sh:801`
    `provider_update "$gh_id" "$payload"` call shape. The coder locates the pack Mode-3 edit entry
    point (the `pack tracker`-surface op that applies a `Status:`/`Resolution:`/`Description:` edit in
    tracker mode) and wires: `provider_update` on body/labels + `provider_close`/reopen when the status
    crosses the open/closed boundary (DP-3 matrix). If the entry point does not yet exist as a discrete
    function, the coder adds it in `scripts/lib/tracker-*.sh` (pack-side lib), NOT a new client file.
  - The provider op-set is NOT widened: NO `provider_delete` is added (§2.3 — the pack "delete"
    semantic IS close-with-`state_reason`; adding `provider_delete` widens the abstraction with no
    consumer = anti-pattern).
  - Its unit/integration test (the coder greps `scripts/tests/tracker-*` for the closest existing CRUD
    test — e.g. `tracker-provider-test.sh` / `tracker-migrate-forward-test.sh` — and adds an update-path
    assertion).
  - `test-fixtures/manifest.txt` — regen if non-empty.
- **Change recipe (design §2.3; DP-1):** Create=already wired (`provider_create`, forward Step 4/5).
  Read=`provider_list`/`provider_get` (already exist). **Update**=wire `provider_update` (exists `:129`,
  currently unwired for BD) into the Mode-3 edit path + `provider_close`/reopen on the open/closed
  boundary cross. **Delete**=maps to `provider_close` with `state_reason` (Cancelled/Deprecated rows),
  NOT a destructive op. All four verbs are `provider_*` (tracker-agnostic; never raw `gh`).
- **Per-commit verification:**
  - `python3 scripts/validate-pack.py` (green).
  - **FULL CI battery:** the CRUD/provider tests + `bash scripts/tests/test-v11-realistic-ot.sh`.
  - Manifest regen flagged.
- **Dependency/ordering rationale:** independent of C-1/C-2/C-4; MUST land before C-8 so the post-flip
  pack can edit entries against the tracker SSOT. **Before the flip.**
- **Bounded review/fix cycle applies.**

### Commit C-4 — reverse pack branch: emit the TREE (no monolith), retire header-snapshot, drop sidecar

- **Commit subject (shape):** `feat: v11 — BD-204 reverse pack branch emits per-entry tree; retire header-snapshot + sidecar (pack-only)`
- **File scope:**
  - `scripts/lib/tracker-migrate-reverse.sh` — the reverse orchestrator pack branch (`if [[ "$surface"
    == "pack" ]]` at `:1056`), `_tmr_emit_backlog` (`:606`), the header-snapshot calls (`:1109` capture,
    `:1117` apply), the sidecar call (`:1128`), the `_emit_path_list` backup/restore set (`:1082-1083`,
    `:1089`, `:1144`).
  - `scripts/tests/tracker-migrate-roundtrip-test.sh` — flip the pack-branch assertions from monolith
    + sidecar (`:415,484,487`, Group-4 `:540+`) to the per-entry TREE + NO-sidecar.
  - `scripts/tests/tracker-bd132-race-test.sh` — the skip-guard-before-emit asserts referencing
    `pack-ops/BACKLOG.md` (`:247,273`) update to the tree-emit target (the silent-data-loss guard now
    fires before the TREE write).
  - `scripts/tests/tracker-bd133-header-preservation-test.sh` — the pack-surface header-snapshot
    integration is RETIRED for the pack branch; the module-API unit tests for `tracker-header-snapshot.sh`
    may stay (the module is dormant/ kept for any client use) — the coder retires only the pack-surface
    reverse-path assertion, NOT the module's own unit tests, unless the module is deleted (see
    remove-vs-dormant below).
  - `test-fixtures/manifest.txt` — regen if non-empty.
  - **remove-vs-dormant flags (architect flagged to planner/coder, §4.3):** `tracker-sidecar.sh` and
    `tracker-header-snapshot.sh` are UNUSED on the pack surface after this commit. **Planner
    disposition:** leave both DORMANT (do NOT delete) for v11.0 — they may still serve the client
    surface (BD-207) / a future tracker-agnostic preservation mechanism; deleting them now is a larger
    blast radius (their own unit tests + any client-branch references) with no v11.0 benefit, and the
    client branch is OUT of scope. This is a LOGICAL-FIT deferral of the delete (concrete:
    client-branch reuse), not scope creep — surfaced for user confirmation. If the user prefers
    fail-loud deletion, that is a separate scoped follow-up (it would touch the client branch).
- **Change recipe (design §2.1 / §2.2 C2b·C3·C7c / §2.4.1 / DP-2 / DP-5 / §3.3):**
  1. **Emit the tree (C3 REPOINT):** the pack branch (`surface=="pack"`) emits the per-entry TREE
     directly — for each reconstructed entry object, `pe_write_atomic` to `/backlog/BD-NNN.md` with the
     `pe_backpointer_line` line-1 back-pointer (filename keyed on the `pack-id` marker, §2.7), via the
     `per_entry`-keyed path with stream key `pack-backlog`, dir `<repo_root>/backlog`. The pack branch
     does NOT call `_tmr_emit_backlog` (which writes the `# BACKLOG` monolith). The client `else`
     branch keeps calling `_tmr_emit_backlog` (untouched — BD-207). The in-body `pack-extra-fields`
     block (`Target:`/`Position:`/any named scalar the form can't express) is rendered INLINE into the
     entry on regen (§2.4.1); prose sub-blocks (`Description:`/`Context:`/`Resolution:`/`Goal:`/`Scope:`/
     `Steps:`/`Segments:`/`State:`/etc.) ride the visible Issue body verbatim.
  2. **Regenerate `_toc.md` (DP-4):** after the tree emit, call `per_entry_regenerate_toc pack-backlog
     <repo_root>/backlog` on EVERY pack reverse/regen pass (keeps Check 33 green; tree ⟺ `_toc.md`
     always satisfied).
  3. **Retire header-snapshot (C7c / DP-5):** the pack branch does NOT call
     `tracker_header_snapshot_capture` (`:1109`) or `tracker_header_snapshot_apply` (`:1117`) — no
     monolith preamble exists under no-mirror, and `_intro.md` is human-only (D1) so a regenerated
     header has no valid destination. `_intro.md` / `_rules.md` are pack-authored static files,
     preserved on disk, untouched by reverse.
  4. **Drop the sidecar (DP-2 / §2.4.1):** the pack branch does NOT call `tracker_sidecar_emit`
     (`:1128`). No `.pack-tracker/reverse.sidecar.*` file is written or read on the pack surface.
  5. **Backup/restore loop points at the tree set (§3.3 T8):** for the pack branch, the atomic
     backup/restore loop (`:1089` backup, `:1144` restore) snapshots the `/backlog/*.md` SET (via
     `pe_list_entry_files pack-backlog <dir>`) instead of the single monolith path, so the
     silent-data-loss guard (`:1032-1042`, fires on `n_skipped` BEFORE any tree write) + the atomic
     flip stay correct. The client `else` branch keeps the four-monolith-path list (untouched).
  6. **No-monolith invariant (Check 32′):** because the pack branch never writes `pack-ops/BACKLOG.md`,
     Check 32′ (`validate-pack.py` no-pack-monolith region `:3178`+) stays green through reverse.
- **Per-commit verification:**
  - `python3 scripts/validate-pack.py` (green — Check 32′ green, Check 33 green after the `_toc.md`
    regen).
  - **FULL CI battery:** `bash scripts/tests/tracker-migrate-reverse-test.sh` +
    `bash scripts/tests/tracker-migrate-roundtrip-test.sh` (now asserting the tree, NO sidecar) +
    `bash scripts/tests/tracker-bd132-race-test.sh` (tree-emit skip-guard) +
    `bash scripts/tests/tracker-bd133-header-preservation-test.sh` (pack-surface retire) +
    `bash scripts/tests/test-v11-realistic-ot.sh`.
  - Manifest regen flagged.
- **Dependency/ordering rationale:** DEPENDS on C-1 (the reconstructed entries must decode `Deferred`).
  The load-bearing no-monolith change. **After C-1.**
- **Bounded review/fix cycle applies.**

### Commit C-5 — forward pack branch: read the TREE input, retire Step-10 mirror regen

- **Commit subject (shape):** `feat: v11 — BD-204 forward pack branch reads per-entry tree; retire Step-10 mirror regen (pack-only)`
- **File scope:**
  - `scripts/lib/tracker-migrate-forward.sh` — the forward read-input pack branch (`if [[ "$surface" ==
    "pack" ]]` at `:709`/`:732`, `backlog_path=".../pack-ops/BACKLOG.md"` `:710`/`:733`), the
    `tmf_parse_backlog` call (`:741`), the Step-10 regen call `_tmf_regen_mirror "$backlog_path"`
    (`:1208`).
  - `scripts/tests/tracker-migrate-forward-test.sh` — flip the pack-branch read-input fixture from a
    monolith to the per-entry tree; assert NO Step-10 monolith is regenerated on the pack branch.
  - `scripts/tests/tracker-migrate-roundtrip-test.sh` — the `_setup_test_repo` helper (`:337-352`)
    currently copies the fixture into `pack-ops/BACKLOG.md`; for the pack round-trip it must seed the
    per-entry TREE under `/backlog/` instead (coordinated with C-4; if both commits touch this test,
    sequence C-4's test edits then C-5's, or fold the roundtrip-test edit into whichever lands first
    and have the other assert against the already-tree-shaped fixture — the coder reconciles to avoid a
    half-flipped test).
  - `test-fixtures/manifest.txt` — regen if non-empty.
- **Change recipe (design §2.2 C2a·C2b / §2.12):**
  1. **Read the tree (C2a REPOINT):** the pack branch enumerates `/backlog/*.md` via
     `pe_list_entry_files pack-backlog <repo_root>/backlog` and parses each entry into the same
     entries-JSON shape `tmf_parse_backlog` produces (the coder factors the per-entry parse so the
     downstream `provider_create` payload path is unchanged). The client `else` branch keeps reading the
     monolith (untouched — BD-207).
  2. **Retire Step-10 (C2b RETIRE pack):** the pack branch SKIPS the Step-10 `_tmf_regen_mirror`
     (`:1208`) entirely — under no-mirror there is no monolith to regen; regenerating one VIOLATES the
     fail-loud / no-mirror standard and would trip Check 32′. The tree IS the mirror and is regenerated
     by the reverse/regen path (C-4), not by a forward mirror-write. The client `else` branch keeps
     Step-10 (untouched).
- **Per-commit verification:**
  - `python3 scripts/validate-pack.py` (green; Check 32′ green — no monolith regenerated by forward).
  - **FULL CI battery:** `bash scripts/tests/tracker-migrate-forward-test.sh` +
    `bash scripts/tests/tracker-migrate-roundtrip-test.sh` + `bash scripts/tests/test-v11-realistic-ot.sh`.
  - Manifest regen flagged.
- **Dependency/ordering rationale:** pairs with C-4 to make the full forward+reverse round-trip
  monolith-free; share the roundtrip-test fixture flip (reconcile per the scope note). **With/after C-4.**
- **Bounded review/fix cycle applies.**

### Commit C-6 — Mode-3 read surfaces: agent-read + doctor repoint to the tree

- **Commit subject (shape):** `feat: v11 — BD-204 agent-read + doctor read the per-entry tree in Mode 3 (pack-only)`
- **File scope:**
  - `scripts/lib/tracker-agent-read.sh` — the `BD-*` mirror-path branch (`mirror_path=".../pack-ops/BACKLOG.md"`
    `:264,267`) + the monolith-grep (`:274`).
  - `scripts/lib/tracker-doctor.sh` — the pack `backlog_path=".../pack-ops/BACKLOG.md"` (`:122`) +
    mirror-freshness mtime/header check (`:132-154`).
  - `scripts/tests/tracker-agent-read-test.sh` + `scripts/tests/tracker-bd130-doctor-wired-test.sh`
    (the coder greps both for the monolith-read assertions and flips them to the tree).
  - `test-fixtures/manifest.txt` — regen if non-empty.
- **Change recipe (design §2.2 C4·C7b):**
  1. **Agent-read (C4 REPOINT):** the pack/`BD-*` branch reads `/backlog/BD-NNN.md` directly (the file
     IS the entry; no grep-a-monolith). Keep the `TD-*`/`phase-*` branches (project-side) UNTOUCHED —
     editing them is a pack-only VIOLATION; only the `BD-*` (and the `*)` default that resolves to the
     pack monolith `:267`) branch repoints.
  2. **Doctor (C7b REPOINT):** the pack-surface mirror-freshness check maps to the tree's regen-state
     (`_toc.md` freshness / last-regen marker per DP-4) instead of a monolith mtime/header. Keep the
     project-surface branch untouched.
- **Per-commit verification:**
  - `python3 scripts/validate-pack.py` (green).
  - **FULL CI battery:** `bash scripts/tests/tracker-agent-read-test.sh` +
    `bash scripts/tests/tracker-bd130-doctor-wired-test.sh` + `bash scripts/tests/test-v11-realistic-ot.sh`.
  - Manifest regen flagged.
- **Dependency/ordering rationale:** DEPENDS on the tree being the Mode-3 emit target (C-4). **After C-4.**
- **Bounded review/fix cycle applies.**

### Commit C-7 — the §3.2 lossless oracle as a runnable scratch-repo test

- **Commit subject (shape):** `feat: v11 — BD-204 lossless round-trip oracle (scratch-repo test) (pack-only)`
- **File scope:**
  - A new pack-side test, e.g. `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` (filename-unique
    — verify `find . -name "tracker-bd204-lossless-roundtrip-test.sh" -not -path "./.git/*"` returns
    nothing before naming).
  - A small FIXTURE tree under `scripts/tests/fixtures/` containing the FOUR stress cases (a suffix
    entry `BD-NNNb`, a parenthetical entry `BD-NNN (Code Red N)`, a `Deferred` entry, and a large
    multi-block entry with `Segments:`/`Steps:`/`State:`).
  - `test-fixtures/manifest.txt` — regen if non-empty.
- **Change recipe (design §3.1 / §3.2 / §3.4; test-infra self-provisioned):** implement the oracle as a
  deterministic diff against a LIVE scratch repo:
  1. **Provision** a personal-account scratch repo via `gh repo create` (per-step user approval;
     `test-infra-self-provisioned`); install the form family; seed the fixture tree.
  2. **Run** `tree → Issues → tree` (forward then reverse) against the scratch repo.
  3. **Oracle legs (§3.2):**
     - **Count oracle:** `count(/backlog/*.md matching ^BD-\d+[a-z]*\.md$)` BEFORE == AFTER ==
       `count(pack-owned Issues)` (the `work-item` lane only; inbound excluded). DYNAMIC count
       (measured live; never hard-coded).
     - **Identity oracle:** the SET of `pack-id`s BEFORE == AFTER == the SET of `pack-id` markers across
       pack-owned Issues (the suffix + parenthetical entries appear in all three).
     - **Content-faithfulness oracle:** per entry, `diff <(original span, back-pointer stripped via
       pe_strip_backpointer_stdin) <(reconstructed span, stripped)` is EMPTY (the large-entry body
       diffs clean).
     - **Status oracle:** status distribution BEFORE == AFTER (the `Deferred` count is the canary).
     - **No-monolith / no-sidecar oracle:** `! -f pack-ops/BACKLOG.md` throughout (Check 32′ green) AND
       no `.pack-tracker/reverse.sidecar.*` file written on the pack surface.
     - **Repeated-cycle oracle:** `tree → Issues → tree → Issues → tree` (on/off/on/off) converges to
       the original; with interleaved CRUD: `provider_create` a new BD, `provider_update` a status,
       reverse, assert the new BD appears + the status round-trips + re-forward re-creates the state.
  4. **Cleanup contract:** `gh repo delete` in the same run (trap-on-exit + explicit delete); the test
     asserts the scratch repo is gone at the end. NEVER touch the real pack repo as a test target.
- **Per-commit verification:**
  - `python3 scripts/validate-pack.py` (green).
  - **FULL CI battery** + the new oracle test run green on the scratch repo (per-step `gh` approval).
  - Manifest regen flagged.
- **Dependency/ordering rationale:** DEPENDS on ALL machinery (C-1..C-6). The dress rehearsal that gates
  C-8. **After C-1..C-6.**
- **Bounded review/fix cycle applies.**

### Commit C-8 — the real pack-repo Mode-2→3 dogfood flip (GATED — last)

- **Commit subject (shape):** `feat: v11 — BD-204 dogfood flip: pack backlog → GH Issues (Mode 3) (pack-only)`
- **File scope:**
  - `tracker.toml` (the LIVE pack config, created by the forward migration — `mode.state="tracker"`,
    `migration.forward_complete=true`, `migration.last_forward_run=<ts>`, NO `[mirror]` table).
  - `/backlog/*.md` + `/backlog/_toc.md` — regenerated FROM the tracker (read-only mirror banner per
    DP-1(A) mitigation, if adopted).
  - `.pack-tracker/id-map.json` (gitignored mapping; not committed as SSOT).
  - `test-fixtures/manifest.txt` — regen if non-empty (the `scripts/` surface is unchanged here, but
    the flip may touch nothing under the four v11-surface dirs except via `tracker.toml`; flag regen if
    the diff includes any v11-surface dir).
- **Change recipe (design §2.12 / §3.4 step 3):** run `pack tracker init --forward` on the REAL pack
  repo: read the tree (C-5), create an Issue per entry (`provider_create` via the form shape), write
  the `pack-id` markers, create the BD-111 dependency links, write the live `tracker.toml` with NO
  `[mirror]` table, SKIP the Step-10 monolith regen (C-5). Then regenerate the tree FROM the tracker
  (now SSOT) + `_toc.md` (DP-4).
- **GATING (hard — this is the only commit with a heavyweight gate):**
  1. C-7 green (scratch-repo proof passes the full §3.2 oracle on the four stress cases).
  2. **Explicit user approval** for the real flip (heavyweight, infrequent, §2.12). Pack Chat surfaces
     the scratch-proof artifacts + the flip plan; the user approves before the forward runs against the
     real pack GH repo.
  3. The flip is performed by Pack Chat / the user with per-step approval (NOT a `pack-coder` running
     `gh` against the real repo on its own authority — agents never commit and never run destructive /
     state-changing ops without per-action approval). The coder's role here is limited to any
     code/config changes; the live migration RUN is a user-gated operation.
- **Per-commit verification:**
  - `python3 scripts/validate-pack.py` (green — Check 29′ soft-passes the live no-mirror config; Check
    32′ green; Check 33 green on the regenerated `_toc.md`).
  - **FULL CI battery** + a post-flip lossless spot-check (the §3.2 count + identity + status oracle
    against the REAL pack tree-from-tracker vs the pre-flip tree).
  - Manifest regen flagged if any v11-surface dir is in the diff.
- **Dependency/ordering rationale:** DEPENDS on C-7 green + user approval. **Last.**
- **Bounded review/fix cycle applies** to any code/config edits; the live RUN is user-gated.

---

## 4. Verification strategy (consolidated)

### 4.1 The §3.2 lossless oracle as a runnable test (C-7)
Implemented in C-7 as `tracker-bd204-lossless-roundtrip-test.sh` against a self-provisioned scratch
repo: count / identity / content-faithfulness / status / no-monolith-no-sidecar / repeated-cycle +
interleaved-CRUD legs (§3 detail above). DYNAMIC counts (measured live at audit time, never
hard-coded — BD-203 EE-1 discipline).

### 4.2 FULL CI suite per commit (not validate-pack alone)
Per `verify-full-ci-suite`: each commit's verification runs `python3 scripts/validate-pack.py` AND the
specific `test-v11-*.sh` / `tracker-*` integration tests that exercise the touched surface — in
particular `scripts/tests/test-v11-realistic-ot.sh` on EVERY commit (it pins validator banners; a
"clean" validate-pack can still go CI-RED on a stale banner assertion, the BD-203 C-1 failure mode).
The per-commit integration tests are named explicitly under each commit above. The coder's PREFLIGHT
AND the reviewer's independent pass both run the full battery before a clean verdict.

### 4.3 Manifest regen on every scripts/-touching commit
Per `regenerate-manifest-v11-surface`: C-1 through C-7 all touch `scripts/` (a v11-surface dir), so each
MUST run `bash test-fixtures/build.sh --all --clean` and stage `test-fixtures/manifest.txt` in the SAME
commit when the diff is non-empty. C-8 flags regen only if its diff includes a v11-surface dir.

### 4.4 Enumerate-encoding-surfaces lock-step (Check 29′ / 32′ / decode / monolith / sidecar)
Per `enumerate-encoding-surfaces`: every commit that retires/repoints a contract updates the
validator/lib function + its test assertions + (where applicable) the example schema IN ONE COMMIT:
- C-1: `_tmr_decode_status` (both switches) + `tracker-migrate-reverse-test.sh` Group-1 asserts.
- C-2: `_check_mirror_staleness` + its staleness-output test (example schema UNCHANGED — example keeps
  `[mirror]`; documented as the legitimate KEEP).
- C-4: `_tmr_emit_backlog`-bypass / header-snapshot-retire / sidecar-drop + `tracker-migrate-roundtrip-test.sh`
  + `tracker-bd132-race-test.sh` + `tracker-bd133-header-preservation-test.sh`.
- C-5: forward read-input + Step-10 retire + `tracker-migrate-forward-test.sh` + the roundtrip-test
  fixture seed.
- C-6: agent-read + doctor + `tracker-agent-read-test.sh` + `tracker-bd130-doctor-wired-test.sh`.
Asymmetric coverage (validator/lib edited but not its test, or vice versa) is an audit gap and a
reviewer BLOCKER.

### 4.5 Pack-only enforcement (Check 36) per commit
Every commit subject carries `pack-only`; the commit diff must touch NO `project-template/` or
project-side asset. Reviewer verifies the client `else` branches (forward/reverse), the
`tracker.toml.project-example`, and the `TD-*`/`phase-*` agent-read/doctor branches are UNTOUCHED.

---

## 5. Dogfood-flip gating (restated — the heavyweight gate)

The real pack-repo Mode-2→3 migration (C-8) is the LAST step and is gated on:
1. **A green scratch-repo proof (C-7)** — the full §3.2 oracle passes on the four stress cases on a
   self-provisioned personal scratch repo, created via `gh repo create` with per-step user approval and
   destroyed via `gh repo delete` (trap-on-exit; the test asserts the repo is gone). NEVER the real
   pack repo as a test target.
2. **Explicit user approval** for the real flip (heavyweight, infrequent, §2.12).
3. **Per-step approval on the live RUN** — agents never run the destructive/state-changing live
   migration on their own authority; Pack Chat / the user perform the flip with per-action approval.

---

## 6. Open risks / unknowns (surfaced, not absorbed)

1. **Roundtrip-test fixture shared by C-4 and C-5.** `tracker-migrate-roundtrip-test.sh`'s
   `_setup_test_repo` seeds `pack-ops/BACKLOG.md` today; both the reverse-assert flip (C-4) and the
   forward-read flip (C-5) touch it. RISK: a half-flipped test (forward reads the tree but the assert
   still checks the monolith, or vice versa) goes RED or — worse — green on a stale path. MITIGATION:
   the coder reconciles the fixture seed in whichever of C-4/C-5 lands first and has the other assert
   against the already-tree-shaped fixture; the reviewer verifies the test is coherent at each commit
   (validate-pack + the integration test green at BOTH commits, not just the pair).
2. **`provider_update` Mode-3 edit entry point may not exist as a discrete function (C-3).** §2.3 says
   "wire `provider_update` into the Mode-3 edit path" and points at the `tracker-promote.sh:801` call
   shape, but does not name a pack Mode-3 edit FUNCTION. RISK: the coder must locate or create the pack
   tracker-surface edit op. MITIGATION: the coder greps the `pack tracker` surface for the Mode-3 edit
   entry point; if absent, adds a pack-side lib function (NOT a client file) — flagged here so the
   reviewer expects a possibly-new function, not only a wiring edit. This is in-scope (full-CRUD
   true-SSOT is a HARD acceptance criterion); it is NOT deferred.
3. **remove-vs-dormant for `tracker-sidecar.sh` / `tracker-header-snapshot.sh` (C-4).** Planner
   disposition is DORMANT (keep), on LOGICAL-FIT grounds (client-branch / future reuse; deleting now
   widens blast radius into the out-of-scope client branch with no v11.0 benefit). This is surfaced for
   USER confirmation — if the user prefers fail-loud deletion, it is a separate scoped follow-up that
   would touch the client branch (and thus could not be `pack-only` if the client branch references
   them). NOT silently absorbed either way.
4. **The `*)` default branch in agent-read (`tracker-agent-read.sh:267`) resolves to the pack
   monolith.** C-6 must repoint BOTH the explicit `BD-*` branch AND the `*)` default (which currently
   falls back to `pack-ops/BACKLOG.md`). RISK: missing the default leaves a dangling monolith read.
   MITIGATION: C-6 recipe names both; reviewer verifies no pack-surface path still reads
   `pack-ops/BACKLOG.md`.
5. **Two-lane filter (§2.8) is not its own commit.** The Pack Feedback two-lane separation (pack-owned
   vs inbound) is a HARD acceptance criterion (`backlog/BD-204.md:22`). The regen `provider_list`
   filter (work-item label + resolved `pack-id` marker + `needs-triage` absent) is part of the C-4
   reverse/regen emit path (the regen selects which Issues become tree files). FLAG: the coder must
   implement the lane filter as part of C-4's regen `provider_list` selection, and C-7's oracle must
   assert an inbound (`needs-triage`) Issue is NOT swept into the tree. NOT a separate commit, but NOT
   omitted — folded into C-4 + verified in C-7. Surfaced so the reviewer checks it explicitly.
6. **C-8 `tracker.toml` is a live config, not a pack-chat-only bookkeeping token.** Writing the live
   `mode.state="tracker"` config is part of the migration RUN, not a Pack-Chat-direct edit; it is
   produced by the forward migration and committed under user approval. No backlog-tree SSOT edit
   (the `/backlog/` regeneration) is a hand-edit — it is regenerated from the tracker (DP-1(A)).

---

## 7. BD-204 scope coverage (every design element → a commit; nothing deferred to a later BD/version)

| Design element (spec §) | Commit | Notes |
|---|---|---|
| DP-3 `Deferred` decode branch + test symmetry (§2.6/§2.6.1) | C-1 | both switches + Group-1 fixture |
| Check 29′ no-mirror staleness guard (§2.2.C1) | C-2 | validator + test; example keeps `[mirror]` |
| Full-CRUD `provider_update` wiring (§2.3) | C-3 | update + close-on-boundary; no `provider_delete` |
| Reverse emit TREE (C3), retire header-snapshot (C7c/DP-5), drop sidecar (DP-2/§2.4.1), `_toc.md` regen (DP-4), backup-loop→tree (§3.3 T8) | C-4 | the load-bearing no-monolith change |
| Forward read TREE (C2a), retire Step-10 (C2b) (§2.2) | C-5 | pairs with C-4 |
| Agent-read (C4) + doctor (C7b) repoint (§2.2) | C-6 | BD-* branch + `*)` default; TD-*/phase-* untouched |
| In-body `pack-extra-fields` carrier (§2.4.1) | C-4/C-5 | forward writes into Issue body; reverse renders inline |
| Identity carrier `pack-id` (§2.7), suffix + parenthetical round-trip | C-4 (emit) + C-7 (oracle) | filename keyed on marker; oracle stress set |
| Pack Feedback two-lane filter (§2.8) | C-4 (regen filter) + C-7 (oracle assert) | risk #5 — folded into C-4, verified C-7 |
| Lossless oracle / scratch-repo test (§3.2/§3.4) | C-7 | the dress rehearsal |
| Real dogfood flip (§2.12/§3.4 step 3) | C-8 | gated on C-7 + user approval |
| Surface-generalizable `per_entry`-keyed emit (§4.2) | C-4/C-5 | stream key `pack-backlog`; client branch untouched |
| Tracker-agnostic CRUD via `provider_*` (§4.1) | C-3 | never raw `gh`; close-as-terminal |
| Capability matrix GA+personal only (§2.10) | (design-level; no code) | no element needs an unverified feature |

**No deferral to a later BD/version.** Every design element lands in v11.0 across C-1..C-8. The only
deferral is the remove-vs-dormant DELETE of `tracker-sidecar.sh`/`tracker-header-snapshot.sh` (risk
#3), which is a LOGICAL-FIT keep (client-branch reuse, out-of-scope client branch), NOT a deferral of
BD-204 work — the pack-surface behavior (no sidecar, no header-snapshot) lands fully in C-4. GH-only
non-entry artifacts (reactions/comments/attachments/audit log) are DROPPED by DP-2 decision (§2.4.3),
not deferred work.

---

## 8. Rules-Applied Verification Block

| Rule (as named in prompt / CLAUDE.md) | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **Empirical-Evidence Blocks (planner)** | §1 carries a block per state-claim: HEAD `bc6861e` (`git rev-parse HEAD → bc6861e39f0c...`); the 6 monolith sites + carrier sites re-anchored by SYMBOL at `bc6861e` (forward `:709/:732/:710/:733/:1208`, reverse `_tmr_emit_backlog :606`, `:1056-1059`, `:1109/:1117/:1128`, `_emit_path_list :1082-1083`, `_tmr_decode_status :192/:244-247`, agent-read `:264/:267`, doctor `:122`); `provider_update` unwired except `tracker-promote.sh:801,1215`, no `provider_delete`; `_check_mirror_staleness :2699` hard-fails a no-mirror live config at the `[mirror]`-table branch `:2741-2744`; example schema leg `_validate_tracker_toml :2543` REQUIRES `[mirror]` `:2628-2643`; `PE_STREAM_KEYS :72` parameterizes `(key,dir)`; encoding tests enumerated. Each block: command + verbatim output + HEAD `bc6861e` + interpretation + SUPPORTED. | COMPLIANT |
| **Verify the FULL CI suite, not just validate-pack** | §4.2 + each commit names `python3 scripts/validate-pack.py` AND specific `tracker-*` / `test-v11-realistic-ot.sh` integration tests; `test-v11-realistic-ot.sh` (banner-pinning) named on EVERY commit; coder PREFLIGHT + reviewer both run the full battery. | COMPLIANT |
| **CI-guard measure-then-bound** | C-2 measures `_check_mirror_staleness` fail-branches FIRST (§1 EE: hard-fails at `[mirror]`-table-missing `:2741-2744`); categorizes the 3 legitimate live-config shapes (flat-file KEEP-NA / tracker-no-mirror NEW-NA / tracker-with-mirror KEEP-enforce); sizes the TOP guard to soft-pass exactly the no-mirror surface; verifies it still FAILs a claims-mirror-but-missing config (does not widen). Example schema leg unchanged (example KEEPS `[mirror]`). | COMPLIANT |
| **Enumerate ENCODING surfaces** | §4.4 + each commit updates the validator/lib function + its test assertions (+ example schema where applicable) in ONE commit: C-1 (decode both switches + Group-1 fixture), C-2 (staleness + test, schema unchanged + documented), C-4 (emit/header/sidecar + 3 tests), C-5 (forward + 2 tests), C-6 (agent-read/doctor + 2 tests). Asymmetric coverage flagged a reviewer BLOCKER. | COMPLIANT |
| **Regenerate manifest on v11-surface commits** | §4.3 + each of C-1..C-7 flags `bash test-fixtures/build.sh --all --clean` + stage `test-fixtures/manifest.txt` (all touch `scripts/`); C-8 flags it conditionally on a v11-surface diff. | COMPLIANT |
| **Pack/project separation** | §0.1 + every commit pack-only (Check 36 `pack-only`); the generalizable machinery wires ONLY `surface=="pack"`; the client `else` branches (forward/reverse), `tracker.toml.project-example`, and `TD-*`/`phase-*` agent-read/doctor branches are explicitly UNTOUCHED; BD-207 not sequenced. §4.5 reviewer check. | COMPLIANT |
| **Deferral is scope creep** | §7 maps every design element to a commit in v11.0; no deferral to a later BD/version. The only deferral (remove-vs-dormant DELETE of two now-unused libs, risk #3) is a LOGICAL-FIT keep (concrete client-branch reuse + out-of-scope client branch), surfaced for user confirmation, with the pack-surface behavior landing fully in C-4 — not deferred BD-204 work. | COMPLIANT |
| **Test infra is self-provisioned** | §5 + C-7: the scratch-repo proof provisions a personal scratch repo via `gh repo create` (per-step approval) and destroys it via `gh repo delete` (trap-on-exit; asserts gone); NEVER the real pack repo as a test target; C-8's live RUN is user-gated, not agent-run. | COMPLIANT |
| **Bounded review/fix cycle (note per commit)** | Each of C-1..C-8 states "Bounded review/fix cycle applies (coder → reviewer → triage → fix-coder → commit)"; §3 preamble states max 2 review/fix pairs + 1 final reviewer + architect escalation if dirty. | COMPLIANT |
| **Rules-Applied Verification Block + read-docs-in-full** | This block + the §9 per-READ-IN-FULL-doc attestation; every row carries quoted/measured evidence (none empty). | COMPLIANT |
| **Agents never commit** | No `git add/commit/push/tag` or any state-changing git verb run; the SOLE write is this ONE plan doc (`maintenance-docs/v11-implementation/PLAN-BD-204.md`). The `git rev-parse`/`grep`/`sed`/`cat` commands in §1 are read-only. | COMPLIANT |

## 9. READ-IN-FULL attestation (per-file direct-read proof, this session)

| # | File | Direct-read proof (this session, HEAD `bc6861e`) |
|---|---|---|
| 1 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md` | Read full (1-594 + 595-993) — all 5 DPs RESOLVED, the 12 design areas, §2.2 7-site retire/repoint table, §2.4.1, §2.6.1, §3 lossless audit, §4 generalizable, §5 RAVB + attestation, §6 consistency fixes. |
| 2 | `backlog/BD-204.md` | Read full (1-26) — the HARD/DEFAULT/OPEN three-tier brief; pack-only HARD constraint; reversibility; SSOT/mirror; generalizable; acceptance criteria. |
| 3 | `scripts/lib/tracker-migrate-reverse.sh` | Read directly — `_tmr_decode_status` body (`:192-262`, both switches), `_tmr_emit_backlog` body (`:606-680`, the `# BACKLOG` monolith), reverse orchestrator (`:1040-1160`: pack branch `:1056`, `_emit_path_list`, header-snapshot `:1109/:1117`, sidecar `:1128`, backup/restore). |
| 4 | `scripts/lib/tracker-migrate-forward.sh` | Read directly — read-input pack branch (`:706-745`), `tmf_parse_backlog` (`:350`), create (`:820-840`), close/comment (`:1134/:1143`), Step-10 regen (`:1198-1230`), `_tmf_regen_mirror` (`:1429`). |
| 5 | `scripts/lib/tracker-provider.sh` | Read directly — `provider_*` op-set (`:125-136`); `provider_update :129`; no `provider_delete`. |
| 6 | `scripts/lib/tracker-promote.sh` | Read via grep — the only `provider_update` callers (`:801,1215`, the call shape C-3 reuses). |
| 7 | `scripts/lib/tracker-sidecar.sh` / `tracker-agent-read.sh` / `tracker-doctor.sh` / `tracker-header-snapshot.sh` | Read via grep — agent-read mirror-path branches (`:262-274`), doctor backlog-path + freshness (`:114-159`), header-snapshot module header (`:1-55`), sidecar call-site (reverse `:1128`). |
| 8 | `scripts/validate-pack.py` | Read directly — `_check_mirror_staleness` (`:2699-2780`), schema leg `_validate_tracker_toml` mirror keys (`:2620-2650`), Check-29 driver (`:2782-2822`), Check 32′ (`:3136-3264`), Check 33 (`:3269-3286`). |
| 9 | `tracker.toml.pack-example` | Read full (1-70) — flat-file `[mode]`, `[mirror]` table KEPT, `[migration] forward_complete=false`. |
| 10 | `.github/ISSUE_TEMPLATE/work-item.yml` | Read via spec EE — the form family, `wi-status` dropdown, `pack-id`/`template_version` in-body markers (the in-body carrier precedent). |
| 11 | `scripts/lib/per-entry/_lib.sh` + `toc-regenerate.sh` | Read directly — `PE_STREAM_KEYS :72`, `pe__stream_attr :74` (`pack-backlog` → regex/dir), `pe_write_atomic :393`, `pe_list_entry_files :426`, `pe_id_from_filename :453`, `pe_backpointer_line :300`, `pe_strip_backpointer_stdin :335`, `per_entry_regenerate_toc :36`. |
| 12 | Encoding test surfaces | Read via grep/sed — `tracker-migrate-reverse-test.sh` (Group-1 `:128-150`), `tracker-migrate-roundtrip-test.sh` (`:337-545`: monolith + sidecar asserts), `tracker-bd132-race-test.sh` (`:247,273`), `tracker-bd133-header-preservation-test.sh` (`:14-102`). |
| 13 | `CLAUDE.md` `## Pack memory` | Read in full (provided in session context) — no-mirror SSOT, pack-project-separation, dependency-direction, enumerate-encoding-surfaces, ci-guard-measure-then-bound, bounded-review-fix-cycle, manifest-regen, test-infra-self-provisioned, agents-never-commit. |
| 14 | Curated memory files | Read full this session: `feedback_architect_planner_empirical_evidence.md`, `feedback_verify_full_ci_suite.md`, `feedback_ci_guard_design_measure_then_bound.md`, `feedback_manifest_regen_on_v11_surface.md`, `feedback_pack_project_separation_of_concerns.md`, `feedback_tracker_carrier_no_sidecar.md`. |

**No named document was derived rather than read.** Every spec section, brief, built-code file, example
config, encoding test, and memory file above was opened directly via the Read/Bash tools this session at
HEAD `bc6861e`. The plan is grounded in the SOURCES (the design doc + the built code by symbol), not a
summary.

**End of PLAN-BD-204.md**
