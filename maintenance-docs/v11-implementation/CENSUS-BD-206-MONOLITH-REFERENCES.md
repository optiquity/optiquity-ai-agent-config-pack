# CENSUS — BD-206 Project-Side Monolith-Mirror Blast Radius

**Agent:** `docsresearcher-bd206-census` (pack-docs-researcher)
**Censused at:** HEAD = `775e9cc139ef3fdde3d499198894a7bef70145e1`, branch `v11-dev`, 2026-06-26
**Candidate file set provenance:** `git ls-files` (1762 tracked files); grep is tracked-tree-scoped (`git grep`), never a raw filesystem walk.
**Working-tree note:** the tree has 8 uncommitted deletions (BD-206 "Wave A": the 7 project-side sidecars + `RESEARCH-BD-206-PROJECT-CONVERSION.md`). The census was run against **HEAD** for stability; none of those deletions are *referencing* surfaces, so they do not change the inventory below.

---

## 0. Scope frame (from `/backlog/BD-206.md` @ HEAD)

BD-206 applies the BD-203 **no-monolithic-mirror** standard to the **CLIENT / project side**: for every converted client stream, DELETE the project monolith (`docs/project/BACKLOG.md`, `docs/project/IMPLEMENTATION-PLAN.md`, `docs/project/CHANGELOG.md`) and ship **NO** regenerated mirror; the per-entry tree + generated `_toc.md` becomes the sole SSOT + readable form on the project side (mirroring the pack side, already done in BD-203). Tracker mode is deferred indefinitely (BD-214); BD-206 DROPS the tracker mode-conditional folds but its own KEEP list explicitly retains "the `tracker-mirror.sh` CLIENT legs" — so tracker-family references are treated here as **AMBIGUOUS** (flag for triage), never silently swept in or out. BD-206 must also (a) COMPLETE the client-surface half of `detect.sh`/`pack-help.sh` (the dual-use repoint), and (b) correct the `project-template/skills/*/SKILL.md` masters to the no-mirror standard.

**Classification key**
- **KEEP** — legitimate; survives the no-mirror conversion unchanged.
- **STRIP** — pure mirror artifact; must be removed.
- **UPDATE-REPOINT** — must be changed to reference the per-entry tree / no-mirror model.
- **Scope:** PROJECT-SIDE (in BD-206 scope) / PACK-SIDE (already converted / out of scope) / AMBIGUOUS (flag for human triage).

**Distinction that the prior under-count most likely missed:** the v10→v11 migrator's `decompose` reads a v10 **monolith INPUT** (legitimate conversion source — KEEP) but then **regenerates a project mirror** (BD-206 scope — STRIP). The two are in the same files and must be split, not blanket-classified. Likewise `init-project.sh` greenfield *generates* the project mirror (STRIP) while the install-map tuple's stream-dir half is legitimate (UPDATE-REPOINT the mirror half only).

---

## 1. PROJECT-SIDE OPERATIONAL MACHINERY (in BD-206 scope)

### 1.1 `scripts/init-project.sh` — greenfield project-mirror generation + install map + info string
Command: `git grep -nE 'IMPLEMENTATION-PLAN|BACKLOG\.md|CHANGELOG\.md|mirror|per_entry_regenerate_mirror' -- scripts/init-project.sh`

| Line | Exact text (quoted) | Class | Scope | Rationale |
|---|---|---|---|---|
| 1053 | `#    the empty mirror (just \`_intro.md\` content for backlog /` | UPDATE-REPOINT | PROJECT-SIDE | comment describing the empty-mirror generation that BD-206 removes |
| 1084 | `if ! type per_entry_regenerate_mirror >/dev/null 2>&1; then` | STRIP | PROJECT-SIDE | sources the project-mirror generator solely to emit the project monolith |
| 1086 | `. "$_pe_lib_dir/mirror-generate.sh"` | STRIP | PROJECT-SIDE | same generation sourcing |
| 1098-1101 | install-map / stream tuples `"project-backlog\|docs/project/BACKLOG.md\|docs/project/backlog"`, `"project-implementation-plan\|docs/project/IMPLEMENTATION-PLAN.md\|docs/project/implementation-plan"`, `"project-changelog\|docs/project/CHANGELOG.md\|docs/project/changelog"` | UPDATE-REPOINT | PROJECT-SIDE | the mirror-filename middle field drives `per_entry_regenerate_mirror`; the stream-dir field stays (the tree still installs). Drop the mirror field / its consumption |
| 1109-1114 | `per_entry_regenerate_mirror "$pe_key" "$pe_dir" "$pe_mirror"` (greenfield empty-mirror loop) | STRIP | PROJECT-SIDE | actively writes the three empty project monoliths at install; the no-mirror model emits only the tree + `_toc.md` |
| 1121 | `info "per-entry skeleton installed under docs/project/{backlog,implementation-plan,changelog}/; empty mirrors at docs/project/{BACKLOG.md,IMPLEMENTATION-PLAN.md,CHANGELOG.md}"` | UPDATE-REPOINT | PROJECT-SIDE | user-facing string must stop claiming empty mirrors are written |

NOTE: `_CLIENT_INSTALLED_FILES` block (init-project.sh:1342-1426) — checked; it does **not** list the three project monoliths as install sources (they are generated at install, not copied), so no edit there. Confirmed via `git grep -nE '_CLIENT_INSTALLED' -- scripts/init-project.sh` (markers + Check 41 self-doc only).

### 1.2 `scripts/lib/per-entry/_lib.sh` — stream-attribute `mirror` constants (project streams)
Command: `git grep -nE 'mirror) printf' -- scripts/lib/per-entry/_lib.sh`

| Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| 109 | `mirror) printf 'docs/project/BACKLOG.md' ;;` (project-backlog) | UPDATE-REPOINT/STRIP | PROJECT-SIDE | project-stream mirror constant; pack streams (85/99) already noted "retained as constant only" post-BD-203. Architect decides: retain as deletion-target constant (mirror BD-203 pattern) vs remove. Flag the parallel: pack lines 85/99 KEPT the constant — symmetry argues KEEP-as-constant + dead the generator path |
| 121 | `mirror) printf 'docs/project/IMPLEMENTATION-PLAN.md' ;;` (project-implementation-plan) | UPDATE-REPOINT/STRIP | PROJECT-SIDE | same |
| 129 | `mirror) printf 'docs/project/CHANGELOG.md' ;;` (project-changelog) | UPDATE-REPOINT/STRIP | PROJECT-SIDE | same |
| 4-8 | header comment: pack streams have NO regenerated mirror; "`mirror` ... retained as a CONSTANT only ... mirror-generate.sh ... retained for project streams only, pending BD-206" | UPDATE-REPOINT | PROJECT-SIDE | the doc-comment explicitly states the project-stream carve-out BD-206 closes |
| 36, 150-151 | `pe_canonical_mirror_for_stream <key>` accessor | KEEP (mechanism) | PROJECT-SIDE | the accessor stays; only the project-stream return value's *live use* (generation) is removed. Flag to architect: callers of this accessor for project keys are the real surface (see 1.5 mirror-generate, 1.3/1.4 generation call-sites) |

### 1.3 `scripts/lib/per-entry/mirror-generate.sh` — the mirror generator (retained "for project streams pending BD-206")
Command: `git grep -nE 'per_entry_regenerate_mirror|project streams' -- scripts/lib/per-entry/mirror-generate.sh`

| Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| 15, 204-223 | `per_entry_regenerate_mirror <stream_key> <stream_dir> <mirror_path>` function def | STRIP (for project use) / AMBIGUOUS (file fate) | PROJECT-SIDE | This is THE project-mirror generator. After BD-206 the only remaining caller is the migrator decompose's regenerate step (1.4) which BD-206 also removes, and the test (2.x). Whether the whole function/file is deleted or kept as dead-pack-constant infrastructure is an architect call — flag. (Pack decompose.sh:83 already says "mirror-generate is retained for project streams") |
| 83 (decompose.sh sibling note) | `# monolithic mirror. mirror-generate is retained for project streams` | UPDATE-REPOINT | PROJECT-SIDE | doc-comment naming the project carve-out BD-206 closes |

### 1.4 `scripts/lib/migrate-v10-to-v11/decompose.sh` — v10→v11 migration: monolith INPUT (KEEP) + project-mirror regenerate (STRIP)
Command: `git grep -nE 'IMPLEMENTATION-PLAN|BACKLOG\.md|CHANGELOG\.md|mirror|per_entry_regenerate_mirror' -- scripts/lib/migrate-v10-to-v11/decompose.sh`

| Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| 4 | `# IMPLEMENTATION-PLAN.md files into per-entry trees + regenerated mirrors` | UPDATE-REPOINT | PROJECT-SIDE | header describes regenerating mirrors; must drop the "+ regenerated mirrors" clause |
| 47 | `#     \`mirror-generate.sh\` + \`toc-regenerate.sh\` (the BD-164 helpers).` | UPDATE-REPOINT | PROJECT-SIDE | comment; drop mirror-generate reference |
| 93-95 | `if ! type per_entry_regenerate_mirror ... . "...mirror-generate.sh"` | STRIP | PROJECT-SIDE | sources the project-mirror generator for the regenerate step |
| 146-148 | stream tuples `"project-backlog\|docs/project/BACKLOG.md\|docs/project/backlog"` etc. | KEEP (input read) + UPDATE-REPOINT (mirror-out) | PROJECT-SIDE | the monolith path here is the v10 INPUT to decompose (legitimate read) AND the regenerate-out target (STRIP). Split: keep reading the v10 monolith input; stop regenerating it |
| 162 | `info "$stream_key: no monolithic mirror at $mirror_rel — skip"` | KEEP | PROJECT-SIDE | this "monolith" is the v10 INPUT; the skip-when-absent is correct conversion behavior |
| 195-197 | `per_entry_regenerate_mirror "$stream_key" "$stream_dir" "$mirror_path"` + `info "$stream_key: decomposed $mirror_rel → $stream_dir_rel/ + regenerated mirror + TOC"` | STRIP | PROJECT-SIDE | the regenerate-the-mirror step BD-206 removes; the decompose→tree+TOC half is KEEP |

### 1.5 `scripts/lib/migrator-core.sh` — `--force-overwrite-mirror` help text (project mirrors)
Command: `git grep -nE 'mirror|BACKLOG|IMPLEMENTATION-PLAN|CHANGELOG' -- scripts/lib/migrator-core.sh`

| Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| 266-271 | `--force-overwrite-mirror ... overwrite hand-edited regenerated mirrors (BACKLOG.md, CHANGELOG.md, IMPLEMENTATION-PLAN.md) when the per-entry tree's regenerator output diverges` | UPDATE-REPOINT | AMBIGUOUS | the flag exists for project-mirror divergence; if BD-206 removes project-mirror regeneration the flag/help becomes meaningless for project streams. Flag to architect: does the migrator framework still need this flag for any other adapter? |

### 1.6 `scripts/lib/detect.sh` — CLIENT-surface branch still reads the client monolith (the half-repoint BD-206 must complete)
Command: `git grep -nE 'docs/project/BACKLOG\.md|detect_pack_surface|CLIENT' -- scripts/lib/detect.sh`

| Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| 48-54 | comment: "PACK-SURFACE branch (repointed to the no-mirror tree) ... The CLIENT-surface branches below are UNTOUCHED (they still detect a client monolith until BD-206)." | UPDATE-REPOINT | PROJECT-SIDE | the comment self-identifies as the BD-206-pending half |
| 66 | `for backlog in "$target/docs/project/BACKLOG.md" "$target/BACKLOG.md"; do` (inside DENY-LIST-CONTENT markers) | UPDATE-REPOINT | PROJECT-SIDE | the client-surface detection reads the client monolith; BD-206 repoints it to the client `/backlog/` per-entry tree (TD-NNN.md entries). `_SANCTIONED_PACK_SIDE_SHIPPED` + install map UNCHANGED (Check 47) per BD-206 scope |
| 69, 72 | `grep -qE '^\*\*BD-[0-9]+ ' "$backlog"` / `grep -qE '^\*\*TD-[0-9]+ ' "$backlog"` | UPDATE-REPOINT | PROJECT-SIDE | monolith-format detection; repoint to per-entry tree presence/scan |

### 1.7 `scripts/pack-help.sh` — surface dispatch consuming detect.sh client branch
Command: `git grep -nE 'detect_pack_surface|surface' -- scripts/pack-help.sh`

| Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| 57-79 | `surface="$(detect_pack_surface "$root" ...)"` + `# pattern as detect.sh::detect_pack_surface legacy-root fallback.` | KEEP (verify) | PROJECT-SIDE | consumes detect.sh; once 1.6 is repointed, pack-help.sh inherits correct behavior. Verify no independent monolith read here (none found). Flag as encoding-surface to re-test after 1.6 |

### 1.8 `scripts/lib/recommendation.sh` — reads the client monolith to compute recommendation signals
Command: `git grep -nE 'BACKLOG\.md|IMPLEMENTATION-PLAN\.md|client BACKLOG|TD-\[0-9\]' -- scripts/lib/recommendation.sh`

| Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| 166-173 | comment "client BACKLOG / STATUS / IMPLEMENTATION-PLAN live under docs/project/" + `backlog="$repo_root/BACKLOG.md"` / `[[ ! -f "$backlog" ]] && backlog="$repo_root/docs/project/BACKLOG.md"` / same for `plan` IMPLEMENTATION-PLAN.md | UPDATE-REPOINT | PROJECT-SIDE | the client-signal computation reads the client monolith for TD/phase counts + KB; after no-mirror the monolith vanishes → repoint to the per-entry tree (count TD-NNN.md files, sum bytes, count phase-N.md) |
| 178-188 | `td_total=$(grep -cE '^\*\*TD-[0-9]+ ' "$backlog")`, `_rec_count_active_entries "$backlog" "TD"`, `backlog_kb`, `phase_count=$(grep -cE '^## Phase' "$plan")`, `plan_kb` | UPDATE-REPOINT | PROJECT-SIDE | all monolith-format signal extraction; recompute from the per-entry tree |
| 415 | `implementation_plan_kb) echo "IMPLEMENTATION-PLAN.md size (KB)" ;;` | UPDATE-REPOINT | PROJECT-SIDE | signal-label string keyed to the monolith filename; relabel to tree-based metric |

### 1.9 `scripts/persona-contracts/contract-greenfield.sh` + `contract-migration.sh` — persona acceptance contracts asserting project mirrors exist
Command: `git grep -nE 'docs/project/(BACKLOG|IMPLEMENTATION-PLAN|CHANGELOG)\.md|empty mirrors|monolithic mirror' -- scripts/persona-contracts/contract-greenfield.sh scripts/persona-contracts/contract-migration.sh`

| Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| greenfield 214-215 | `#   7. greenfield empty mirrors + → docs/project/{BACKLOG.md, IMPLEMENTATION-PLAN.md, CHANGELOG.md}` | STRIP | PROJECT-SIDE | contract step asserting greenfield writes the 3 mirrors; removed under no-mirror |
| greenfield 240-244 | `# Sub-stage 7: greenfield empty mirrors at PARENT docs/project/` + array `"docs/project/BACKLOG.md"`, `"docs/project/IMPLEMENTATION-PLAN.md"`, `"docs/project/CHANGELOG.md"` | STRIP | PROJECT-SIDE | the asserted expected-file array must drop the 3 monoliths (keep the tree + `_toc.md` assertions) |
| migration 24-25, 387-397 | `Custom TD-NNN BACKLOG.md preserved verbatim — pack does not ship a BACKLOG.md` / sha256 byte-identical preservation of the project's existing `BACKLOG.md` | KEEP | PROJECT-SIDE | this asserts a v10 client's PRE-EXISTING root `BACKLOG.md` (the migration INPUT) is preserved — NOT a generated mirror. Legitimate; survives |
| migration 426-485 | comments re sub-stage 7 mirrors + the decompose skip-when-input-absent | UPDATE-REPOINT | PROJECT-SIDE | comments describing mirror+_toc generation; align to no-mirror (decompose still produces tree + `_toc.md`, no mirror) |

---

## 2. VALIDATOR / TEST / CI ENCODING LAYER (in BD-206 scope; enumerate in lock-step)

### 2.1 `scripts/validate-pack.py` — Check 43 mirror-skip + basename allowlist + prose
Command: `git grep -nE 'IMPLEMENTATION-PLAN\.md|_CHECK_43_MIRROR_SKIP|Project-side mirror|regenerated mirror' -- scripts/validate-pack.py`

| Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| 5504-5507 | basename allowlist: `"BACKLOG.md": "Project-side mirror (regenerated); at client docs/project/"`, `"CHANGELOG.md": ...`, `"IMPLEMENTATION-PLAN.md": "Project-side mirror (regenerated); at client docs/project/"` (preceded by comment "Project-side mirrors (regenerated; never source of truth but resolve at client install)") | UPDATE-REPOINT | PROJECT-SIDE | these allowlist the 3 monolith basenames as "regenerated mirrors resolving at client install"; under no-mirror they no longer install. Architect: remove the mirror rationale; the basenames may still need allowlisting as the per-entry tree's `_toc.md` readable form or as conversion-input — measure-then-bound |
| 5593 | `_CHECK_43_MIRROR_SKIP_BASENAMES = ("BACKLOG.md", "CHANGELOG.md", "IMPLEMENTATION-PLAN.md")` | UPDATE-REPOINT/STRIP | PROJECT-SIDE | the mirror-skip set exists because Check 43 walked source trees not mirrors; with no project mirror the skip-set's project rationale changes. (BD-206 scope line in BD-206.md names "Check-43's project-side mirror-skip basenames" explicitly as in-scope.) Note: pack mirrors already gone — verify whether any remaining mirror exists to skip |
| 5590-5592 | comment "regenerated project-side mirrors may legitimately mirror pack-internal cites ... Check 43 walks the source trees, not the mirrors" | UPDATE-REPOINT | PROJECT-SIDE | prose rationale tied to the now-removed project mirror |
| 5360-5361 | `# conversion-input monoliths. NOT "regenerated mirrors" — there is` | KEEP (verify) | PACK-SIDE | already-corrected post-BD-203 prose distinguishing conversion-input from regenerated; verify still accurate for the project case after BD-206 |
| 5504 (comment), 5697, 5625, 7819, 8836, 11491 | scattered prose: "regenerated mirrors (BACKLOG.md / CHANGELOG.md) and any...", "BACKLOG.md / CHANGELOG.md are regenerated MIRRORS, NOT in...", "deleted — no regenerated mirror under the no-mirror model" | UPDATE-REPOINT (project) / KEEP (pack, already correct) | AMBIGUOUS | mixed pack-already-correct vs project-pending prose; each occurrence must be read in context. Several (e.g. 11491, 318, 239) are BD-203 no-mirror prose already correct for pack — verify they don't wrongly imply a project mirror still exists |
| 5025 | `# defensive exemption retained post-BD-203; there is no regenerated mirror` | KEEP (verify) | PACK-SIDE | BD-203 pack prose; verify project applicability |

NOTE the install-map↔constant machinery (Check 47, `_SANCTIONED_PACK_SIDE_SHIPPED`, `_CLIENT_INSTALLED_FILES`): BD-206 scope says these stay UNCHANGED (Check 47 equality preserved). detect.sh/pack-help.sh repoint does not add/remove install-map entries. Classify: **KEEP** (Check 47, lines ~4333/9337-9397, ~6229-6550 Check 41) — verify the dual-use repoint leaves set-equality intact (the architect's measure-then-bound obligation).

### 2.2 `scripts/tests/test-per-entry.sh` — project-stream mirror-filename asserts (explicitly KEPT pending BD-206)
Command: `git grep -nE 'project-.*mirror filename|pe_canonical_mirror_for_stream|pending BD-206' -- scripts/tests/test-per-entry.sh`

| Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| 213-218 | comment: "pack-stream mirror-filename asserts removed ... project streams DO still use mirror-generate (pending BD-206) — keep 1.3–1.5." | UPDATE-REPOINT | PROJECT-SIDE | self-identifies as the BD-206-pending test block |
| 219 | `assert_eq "1.3 project-backlog mirror filename" "docs/project/BACKLOG.md" "$(pe_canonical_mirror_for_stream project-backlog)"` | UPDATE-REPOINT/STRIP | PROJECT-SIDE | asserts the project-mirror filename; update/remove per the chosen `_lib.sh` disposition (1.2) |
| 220 | `assert_eq "1.4 project-implementation-plan mirror filename" "docs/project/IMPLEMENTATION-PLAN.md" ...` | UPDATE-REPOINT/STRIP | PROJECT-SIDE | same |
| 221 | `assert_eq "1.5 project-changelog mirror filename" "docs/project/CHANGELOG.md" ...` | UPDATE-REPOINT/STRIP | PROJECT-SIDE | same |

### 2.3 `scripts/tests/test-init-project.sh` — greenfield mirror existence + byte-identity asserts
Command: `git grep -nE 'mirror|docs/project/(BACKLOG|IMPLEMENTATION-PLAN|CHANGELOG)\.md' -- scripts/tests/test-init-project.sh`

| Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| 216, 223-229 | comment block describing "3 regenerated mirrors at parent docs/project/", byte-identity claims, changelog mirror shape | UPDATE-REPOINT | PROJECT-SIDE | test-intent comments to rewrite for no-mirror |
| 270-280 | 4.3 asserts `docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md` mirror PRESENT at parent | STRIP | PROJECT-SIDE | invert: assert the 3 monoliths are ABSENT under no-mirror (matches the BD-203 pack-side test inversion pattern) |
| 282-288 | 4.3 negative: mirrors NOT inside stream subdirs | KEEP/UPDATE | PROJECT-SIDE | the negative still holds (no monolith anywhere); may strengthen to "no monolith at parent either" |
| 293-336 | 4.4/4.5 mirror byte-identity asserts (BACKLOG/IMPLEMENTATION-PLAN == `_intro.md`; changelog mirror shape) | STRIP | PROJECT-SIDE | byte-identity-to-mirror asserts have no subject once the mirror is gone |
| 339-406 | 4.6 empty-seed `_toc.md` asserts + 386-394 mtime snapshot of "3 mirrors + 3 TOCs" | UPDATE-REPOINT | PROJECT-SIDE | keep the 3 `_toc.md` asserts; drop the 3 mirror entries from the regen-output set |

### 2.4 `scripts/tests/test-migrate-v10-to-v11-decompose.sh` — migration regenerated-mirror asserts
Command: `git grep -nE 'mirror|docs/project/(BACKLOG|IMPLEMENTATION-PLAN|CHANGELOG)' -- scripts/tests/test-migrate-v10-to-v11-decompose.sh`

| Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| 15-20, 60, 98, 161-166 | fixture seeds `docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md` content (the v10 INPUT) | KEEP | PROJECT-SIDE | the seeded monolith is the conversion INPUT; the migrator must read it. Legitimate |
| 302-304 | `[[ -f "$T/docs/project/IMPLEMENTATION-PLAN.md" ]] ... "2.2b regenerated mirror IMPLEMENTATION-PLAN.md present"` | STRIP | PROJECT-SIDE | asserts the regenerated mirror exists post-migration; invert to assert NO regenerated mirror (tree + `_toc.md` only) |

### 2.5 `scripts/tests/recommendation-test.sh` — client-signal fixtures seed the client monolith
Command: `git grep -nE 'BACKLOG\.md|IMPLEMENTATION-PLAN\.md|docs/project' -- scripts/tests/recommendation-test.sh`

| Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| 93, 103, 119 | `cat > "$TR_CLI/IMPLEMENTATION-PLAN.md"`, `# F-1 closure: client BACKLOG.md + IMPLEMENTATION-PLAN.md at the`, `cat > "$TR_CLI_DOCS/docs/project/IMPLEMENTATION-PLAN.md"` | UPDATE-REPOINT | PROJECT-SIDE | the fixtures feed `_rec_compute_client_signals` (1.8); once recommendation.sh repoints to the per-entry tree, these fixtures must seed a per-entry tree instead of a monolith |

### 2.6 `scripts/tests/test-validate-pack-check-43.sh` — encodes the mirror-skip basenames
Command: `git grep -nE 'BACKLOG\.md|CHANGELOG\.md|IMPLEMENTATION-PLAN\.md' -- scripts/tests/test-validate-pack-check-43.sh`

| Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| 136-138 | `"BACKLOG.md",` / `"CHANGELOG.md",` / `"IMPLEMENTATION-PLAN.md",` (in a basename/skip list under test) | UPDATE-REPOINT | PROJECT-SIDE | test encodes Check 43's mirror-skip / allowlist basenames; must move in lock-step with 2.1 (the validator change). Lock-step pairing for `enumerate-encoding-surfaces` |

### 2.7 Other test files surfaced (verify / mostly KEEP)
Command: `git grep -lE 'docs/project/(BACKLOG|CHANGELOG|IMPLEMENTATION-PLAN)\.md|regenerated mirror|empty mirror' -- 'scripts/tests/*'` (non-tracker subset)

| File | Class | Scope | Rationale |
|---|---|---|---|
| `scripts/tests/fixture-dependent/test-v11-realistic-ot.sh:240` (`"project-implementation-plan\|docs/project/IMPLEMENTATION-PLAN.md\|...\|B.3\|B.4"`) | UPDATE-REPOINT | PROJECT-SIDE | OT-realistic decompose test carrying the project stream tuple incl. mirror path; align to no-mirror decompose output |
| `scripts/tests/pack-help-test.sh` | KEEP (re-test) | PROJECT-SIDE | exercises detect/help surface; re-run after 1.6/1.7 repoint to confirm green |
| `scripts/tests/test-validate-pack-check-40.sh` | KEEP (verify) | PACK-SIDE | Check 40 is pack-ops bare-cross-ref; surfaced via shared anchor-phrase aliasing, not project mirror — verify no project-mirror assumption |
| `test-fixtures/build.sh:528` (`"project-implementation-plan\|docs/project/IMPLEMENTATION-PLAN.md\|docs/project/implementation-plan"`) | UPDATE-REPOINT | PROJECT-SIDE | fixture-build install-map mirror tuple; align to no-mirror |

---

## 3. PROJECT-SIDE GOVERNANCE / DOCS / SKILL MASTERS (in BD-206 scope)

### 3.1 Project-template trinity — `## Document locations` table + mirror prose
Command: `git grep -nE 'regenerated mirror|read-stable but never source of truth|IMPLEMENTATION-PLAN\.md.*BACKLOG' -- project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md`

| File:Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| CLAUDE.md:226 / AGENTS.md:212 / GEMINI.md:223 | `\| \`docs/project/\` \| \`ARCHITECTURE.md\`, \`IMPLEMENTATION-PLAN.md\`, \`BACKLOG.md\`, \`STATUS.md\`, \`CHANGELOG.md\` (regenerated mirrors for BACKLOG/IMPLEMENTATION-PLAN/CHANGELOG — per-entry source in subdirs) \| ... \| flat \|` | UPDATE-REPOINT | PROJECT-SIDE | trinity Document-locations row claims regenerated mirrors; rewrite to no-mirror (per-entry tree + `_toc.md` is SSOT + readable). TRINITY RULE: edit all three in lock-step |
| CLAUDE.md:236-237 / AGENTS.md:222-223 / GEMINI.md:233-234 | `\`IMPLEMENTATION-PLAN.md\`, and \`CHANGELOG.md\` files in \`docs/project/\` ... are regenerated mirrors — read-stable but never source of truth.` | UPDATE-REPOINT | PROJECT-SIDE | the "regenerated mirrors — read-stable but never source of truth" prose; rewrite to no-mirror. Lock-step trinity |

### 3.2 `project-template/skills/*/SKILL.md` MASTERS (BD-206 explicitly: correct masters → restore pack-copy↔master parity)
Command: `git grep -nlE 'regenerated mirror|monolith|never source of truth|read-stable' -- 'project-template/skills/*/SKILL.md'`

| File:Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| `project-template/skills/audit-methodology/SKILL.md:77` | "**Regenerated mirrors are OUT OF SCOPE when the per-entry tree is present.** The monolithic `BACKLOG.md`, `IMPLEMENTATION-PLAN.md`, and `CHANGELOG.md` files are regenerated mirrors of the per-entry tree in flat-file mode ... auditor-docs SKIPs the mirror file ... If only the monolithic file exists (pre-v11.0 client, no decomposition applied), audit the monolithic file as before." | UPDATE-REPOINT | PROJECT-SIDE | skill master describing the mirror-skip audit rule; rewrite to no-mirror (no project mirror to skip; the pre-v11 monolith-as-input branch may survive). Pack-copy↔master parity (G-4) per BD-206 |
| `project-template/skills/pm-startup/SKILL.md:78,82,89-90` | startup reads `IMPLEMENTATION-PLAN.md`; "Resolve every BACKLOG / STATUS / IMPLEMENTATION-PLAN / CHANGELOG read through ... `docs/project/BACKLOG.md`, `docs/project/IMPLEMENTATION-PLAN.md`, and `docs/project/CHANGELOG.md` files are regenerated mirrors of those per-entry [trees]" | UPDATE-REPOINT | PROJECT-SIDE | startup skill master pointing reads at the monolith mirror; repoint to the per-entry tree (+ `_toc.md`). Pack-copy↔master parity |

NOTE — the pack-side COPIES (`.claude/`, `.codex/`, `.gemini/`) of these skills were corrected in BD-203 (C-3); the masters are the pending half. The architect should enumerate, for each affected skill, BOTH the master and its 3 pack copies to confirm parity is restored (the `enumerate-encoding-surfaces` lock-step).

### 3.3 `project-template/docs/pack/PM-CHAT.md` — STATUS.md header instruction + plan-read prose
Command: `git grep -nE 'regenerated mirror|never source of truth|docs/project/BACKLOG\.md|IMPLEMENTATION-PLAN\.md' -- project-template/docs/pack/PM-CHAT.md`

| Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| 328-334 | STATUS.md header instruction: "declaring STATUS.md a working snapshot — never source of truth — ... `docs/project/BACKLOG.md` named as the regenerated mirror" + literal header `<!-- Working snapshot. Source-of-truth lives in docs/project/backlog/ (per-entry tree). Regenerated mirror at docs/project/BACKLOG.md. ... -->` | UPDATE-REPOINT | PROJECT-SIDE | the STATUS.md header template names the regenerated mirror; rewrite to drop the mirror clause (the per-entry tree remains the SSOT pointer) |
| 123, 321-322, 784, 890, 933, 980, 1022, 1068 | numerous reads/links to `IMPLEMENTATION-PLAN.md` (orchestrator reads "current phase section", entry links `[Title](IMPLEMENTATION-PLAN.md#anchor)`, "writes IMPLEMENTATION-PLAN.md") | UPDATE-REPOINT | PROJECT-SIDE | PM-CHAT orchestrator instructions assume a monolith IMPLEMENTATION-PLAN.md to read/write/anchor-link; under no-mirror these must point at per-entry `phase-N.md` files + `_index.md` (BD-206 creates `_index.md` for ordering). HIGH-VOLUME — architect must decide the read/write/anchor model for the plan stream |

### 3.4 `project-template/docs/pack/prompts/*.md` — agent prompt required-reading of the plan monolith
Command: `git grep -nE 'IMPLEMENTATION-PLAN\.md|BACKLOG\.md|per-entry.*tree' -- 'project-template/docs/pack/prompts/*.md'`

| File:Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| `architect.md:25,35,56` | "Required reading: ... `IMPLEMENTATION-PLAN.md` Phase [N] in full"; propose text changes to `IMPLEMENTATION-PLAN.md` | UPDATE-REPOINT | PROJECT-SIDE | prompt directs reading/writing the monolith plan; repoint to `phase-N.md` |
| `coder.md:14,18,52,63,66,155,192` | Phase [N] of `IMPLEMENTATION-PLAN.md`; "The per-entry BACKLOG/STATUS/CHANGELOG/IMPLEMENTATION-PLAN trees are..." | UPDATE-REPOINT | PROJECT-SIDE | mixed monolith + per-entry-tree language; reconcile to per-entry-only |
| `docs-researcher.md:18`, `planner.md:16`, `reviewer.md:21`, `pm-chat.md:52,207,211,334` | required-reading / anchor-link refs to `IMPLEMENTATION-PLAN.md` | UPDATE-REPOINT | PROJECT-SIDE | same pattern across the prompt family; repoint to per-entry plan stream |

### 3.5 `project-template/docs/pack/HELP-FRAGMENT.md` — "See also" cite to the monolith
Command: `git grep -nE 'docs/project/BACKLOG\.md' -- project-template/docs/pack/HELP-FRAGMENT.md`

| Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| 39 | `\`docs/project/BACKLOG.md\`.` (See-also list) | UPDATE-REPOINT | PROJECT-SIDE | repoint the cite to the per-entry tree (`docs/project/backlog/` + `_toc.md`). NOTE: HELP-FRAGMENT.md is itself a `_CLIENT_INSTALLED_FILES` basename allowlisted at validate-pack.py:5106 (Check 43 client-install exception) — that exception stays |

### 3.6 `project-template/scripts/.docs-gate-allowlist.txt` + `validate-docs.sh` — project-side doc gate allowlisting the mirrors
Command: `git grep -nE 'monolith mirror|regenerated mirror|docs/project/(BACKLOG|IMPLEMENTATION-PLAN)\.md' -- project-template/scripts/.docs-gate-allowlist.txt project-template/scripts/validate-docs.sh`

| File:Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| `.docs-gate-allowlist.txt:15` | "# monolith mirrors, docs/reference/, completion reports) are EXCLUDED from" | UPDATE-REPOINT | PROJECT-SIDE | comment naming monolith mirrors as an excluded category |
| `.docs-gate-allowlist.txt:393-397` | `target: docs/project/BACKLOG.md` / `reason: regenerated monolith mirror of the backlog stream; present after the project is used...` + `target: docs/project/IMPLEMENTATION-PLAN.md` / `reason: regenerated monolith mirror of the implementation-plan stream...` | STRIP | PROJECT-SIDE | explicit allowlist entries for the regenerated monoliths; remove once the mirrors no longer exist |
| `validate-docs.sh:24-25` | "# regenerated monolith mirrors (BACKLOG.md / IMPLEMENTATION-PLAN.md / CHANGELOG.md / STATUS.md), docs/reference/, completion reports," | UPDATE-REPOINT | PROJECT-SIDE | exclude-category comment naming the monoliths |
| `validate-docs.sh:319` | "reference doc, a regenerated mirror, a project script) — add a " | UPDATE-REPOINT | PROJECT-SIDE | user-facing remediation hint naming "a regenerated mirror" as a category |
| `validate-docs.sh:232` ("mirror") / `validate-docs.sh:471` ("mirror the trinity location") | — | KEEP | PROJECT-SIDE | "mirror" used in the generic verb sense, not the monolith concept; no edit |

---

## 4. SUPPORTING-DOCS (client-facing migration + methodology) — in BD-206 scope

### 4.1 `supporting-docs/MIGRATION-v10-to-v11.md` — explicitly named in BD-206 scope
Command: `git grep -nE 'regenerated mirror|Monolithic files become|docs/project/(BACKLOG|IMPLEMENTATION-PLAN|CHANGELOG)\.md' -- supporting-docs/MIGRATION-v10-to-v11.md`

| Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| 316 | "high-churn project documents: `BACKLOG.md`, `IMPLEMENTATION-PLAN.md`," | UPDATE-REPOINT | PROJECT-SIDE | migration-narrative referencing the monoliths |
| 320 | "files become regenerated mirrors of the per-entry trees, not the" | UPDATE-REPOINT | PROJECT-SIDE | the exact "monolith becomes a mirror" claim BD-206 launch-coherence calls out |
| 337 | "the top of the regenerated mirror." | STRIP/UPDATE-REPOINT | PROJECT-SIDE | mirror-header narrative |
| 340-341 | "**Monolithic files become regenerated mirrors.** `docs/project/BACKLOG.md`, `docs/project/IMPLEMENTATION-PLAN.md`, and `docs/project/CHANGELOG.md`" | UPDATE-REPOINT | PROJECT-SIDE | the headline mirror claim; rewrite to "monoliths are DELETED, no regenerated mirror" |
| 364 | "and emits the per-entry tree plus the regenerated mirror. The" | UPDATE-REPOINT | PROJECT-SIDE | migrator-output description; drop "plus the regenerated mirror" |
| 386 | "If you hand-edit `docs/project/BACKLOG.md` (or any other mirror)" | STRIP | PROJECT-SIDE | hand-edit-the-mirror guidance has no subject under no-mirror |
| 468 | S4a rename row `IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md` | KEEP | PROJECT-SIDE | the v10→v11 root rename of the INPUT file; legitimate migration step (not a generated mirror) |

### 4.2 `supporting-docs/METHODOLOGY.md` — IMPLEMENTATION-PLAN.md as a source-of-truth doc (legacy monolith methodology)
Command: `git grep -nE 'IMPLEMENTATION-PLAN\.md' -- supporting-docs/METHODOLOGY.md` (29 hits)

| Lines | Exact text (representative) | Class | Scope | Rationale |
|---|---|---|---|---|
| 188, 200, 204, 369, 421, 465, 517, 539, 587, 643, 656, 681, 726, 857, 879, 886, 916, 1131, 1387, 1488, 1573, 1675, 1707, 1811 | repeated: "`IMPLEMENTATION-PLAN.md` ... source of truth", "Every phase in IMPLEMENTATION-PLAN.md should follow...", "PM chat generates ARCHITECTURE.md, IMPLEMENTATION-PLAN.md", "generating prompts from IMPLEMENTATION-PLAN.md task entries", "Modifying ARCHITECTURE.md or IMPLEMENTATION-PLAN.md" | AMBIGUOUS | PROJECT-SIDE | METHODOLOGY.md treats `IMPLEMENTATION-PLAN.md` as the canonical, hand-authored, source-of-truth plan doc — this is a DEEPER model than "regenerated mirror" (it predates per-entry). Under no-mirror + per-entry the canonical plan is the `phase-N.md` tree + `_index.md`. WHETHER BD-206's flat-file-only scope rewrites METHODOLOGY.md's plan model wholesale, or only the mirror-specific references, is a SCOPING question the architect/user must settle — flag, do not silently include. 24 occurrences; high blast |

### 4.3 Other supporting-docs hits
Command: `git grep -nE 'IMPLEMENTATION-PLAN\.md|regenerated mirror' -- supporting-docs/INSTALL-PROCEDURES.md supporting-docs/SETUP-NEW.md supporting-docs/SETUP_TEMPLATE.md supporting-docs/CLI-PM-SETUP.md`

| File:Line | Exact text | Class | Scope | Rationale |
|---|---|---|---|---|
| `INSTALL-PROCEDURES.md:1276` | "`CHANGELOG.md`; `ARCHITECTURE.md`; `IMPLEMENTATION-PLAN.md`; the" (doc-inventory list) | UPDATE-REPOINT | PROJECT-SIDE | install-doc inventory listing the plan monolith; align to per-entry plan |
| `SETUP-NEW.md:396` | "`IMPLEMENTATION-PLAN.md` (the architect writes these files as its" | UPDATE-REPOINT | PROJECT-SIDE | setup narrative; align to per-entry plan authoring |
| `SETUP_TEMPLATE.md:220` | "- Creating IMPLEMENTATION-PLAN.md" | UPDATE-REPOINT | PROJECT-SIDE | setup checklist item; align |
| `CLI-PM-SETUP.md:147,183` | "...IMPLEMENTATION-PLAN.md to verify state is current", "...current phase from IMPLEMENTATION-PLAN.md to refresh context" | UPDATE-REPOINT | PROJECT-SIDE | PM startup narrative reading the monolith; repoint to per-entry plan |

---

## 5. AMBIGUOUS — FLAG FOR HUMAN TRIAGE (never silently included/excluded)

### 5.1 Tracker library family — tracker mode DEFERRED indefinitely (BD-214); BD-206 DROPS tracker folds but KEEPS "tracker-mirror.sh CLIENT legs"
Tracker verbs are gated OFF at runtime: `scripts/pack-tracker.sh:153-161` ("BD-214 deferral gate ... tracker support is deferred indefinitely (no release version)"). So these references point at the project monolith but the code paths do not execute in flat-file (the sole supported) mode. BD-206.md simultaneously (a) DROPS the R1-R8 tracker mode-conditional folds and (b) lists "the `tracker-mirror.sh` CLIENT legs" under KEEP. This contradiction-by-design means the tracker family MUST be human-triaged, not blanket-classified.

Command: `git grep -nE 'docs/project/(BACKLOG|IMPLEMENTATION-PLAN|CHANGELOG)\.md|monolith mirror|read-only mirror' -- 'scripts/lib/tracker-*.sh' scripts/tracker-migrate.sh`

| File:Line(s) | Representative text | Class | Scope | Rationale |
|---|---|---|---|---|
| `tracker-agent-read.sh:159,251-252,263,277-278` | "Fall back to the regenerated mirror for backward..."; "TD-* → project mirror docs/project/BACKLOG.md"; "phase-* → project mirror docs/project/IMPLEMENTATION-PLAN.md"; "(tree repoint): clients still ship those monolith mirrors." | UPDATE-REPOINT? | AMBIGUOUS | reads the client monolith on tracker-agent-read; gated off, but the comment "clients still ship those monolith mirrors" goes stale under no-mirror |
| `tracker-doctor.sh:123-128,173-174,197` | "docs/project/BACKLOG.md monolith mirror"; "BACKLOG.md has read-only mirror header" | AMBIGUOUS | AMBIGUOUS | tracker-mode health checks on the client mirror |
| `tracker-init.sh:191,323,330` | "surface omits the [mirror] table (no monolith mirrors exist..."; "surface deleted its monolith mirrors at BD-203 — the /backlog/..."; "model still has monolith mirrors until BD-206 lands" | UPDATE-REPOINT | AMBIGUOUS | init.sh:330 LITERALLY says "until BD-206 lands" — a self-identified BD-206 pointer; classify when tracker disposition is settled |
| `tracker-migrate-forward.sh:1395,1431-1432,2145-2150` + 14 plan-parse refs | "clients still ship a `BACKLOG.md` monolith mirror"; reads `IMPLEMENTATION-PLAN.md` to build phase epics | AMBIGUOUS | AMBIGUOUS | forward migration parses the monolith; deferred path |
| `tracker-migrate-reverse.sh:31,36,1168,1348,1590-1610,1667,1783-1793` | "Emit IMPLEMENTATION-PLAN.md from phase-epic titles"; "Strip the read-only mirror header"; "must NOT deposit a root STATUS.md / IMPLEMENTATION-PLAN.md" | AMBIGUOUS | AMBIGUOUS | reverse migration emits the monolith; deferred path |
| `tracker-mirror.sh:1,6,39,71` | "read-only mirror header write/strip"; "This file is a read-only mirror generated from the tracker." | AMBIGUOUS | AMBIGUOUS | BD-206.md KEEP names "tracker-mirror.sh CLIENT legs" explicitly — but the tracker-mirror concept is the read-only-mirror-header model; reconcile with no-mirror |
| `tracker-promote.sh:20-34,117-124,147,266-271,312,463-480,510-526,550-624,714,854-923,1054,1306,1323-1360` | dozens: read/append `IMPLEMENTATION-PLAN.md` / `docs/project/BACKLOG.md` for TD→phase promotion | AMBIGUOUS | AMBIGUOUS | tracker promote writes the monolith; deferred path |
| `tracker-phase-task.sh:7,24,140,487` | parse/emit `IMPLEMENTATION-PLAN.md` ↔ JSON | AMBIGUOUS | AMBIGUOUS | tracker plan parser/emitter; deferred path |
| `tracker-agent-read.sh` & siblings under `scripts/lib/tracker-cycle-check.sh:90` | "IMPLEMENTATION-PLAN-ADDENDUM-4.md §6.Q" (doc cite, not a live read) | KEEP | AMBIGUOUS | a maintenance-doc citation, not a monolith read |
| `scripts/tracker-migrate.sh:57,72` | "Migrate flat-file BACKLOG.md / IMPLEMENTATION-PLAN.md content"; "--disable also flips mode to" | AMBIGUOUS | AMBIGUOUS | tracker-migrate verb dispatcher; deferred |
| `scripts/pack-tracker.sh:104` | "flip, tree-only (no STATUS.md / IMPLEMENTATION-PLAN.md..." | KEEP | AMBIGUOUS | already describes tree-only (no-monolith) behavior |

**Triage question for the architect/user:** does BD-206 (flat-file-only, tracker-deferred) touch the tracker library's monolith references at all, or are they left dormant for the (deferred) tracker resumption? The volume is large (~40+ refs across 9 tracker files); silently editing them risks over-scoping; silently ignoring them risks shipping stale "clients still ship monolith mirrors" comments. RECOMMEND: human decision on tracker-family disposition BEFORE the architect designs the edit set.

### 5.2 `scripts/lib/customization-preserve.sh:36` — `# Disposition tokens (per IMPLEMENTATION-PLAN.md §2.5 BD-088 ...)`
Command: `git grep -nE 'IMPLEMENTATION-PLAN\.md' -- scripts/lib/customization-preserve.sh`
Class: **KEEP** (citation to a maintenance/spec doc section, not a live monolith read). Scope: AMBIGUOUS — verify the cited section still resolves; if it points at a deleted monolith spec, repoint.

### 5.3 `scripts/migrate-v10-to-v11.sh` — root rename + completion message
Command: `git grep -nE 'IMPLEMENTATION-PLAN|BACKLOG\.md|CHANGELOG\.md|regenerated mirror' -- scripts/migrate-v10-to-v11.sh`

| Line(s) | Text | Class | Scope | Rationale |
|---|---|---|---|---|
| 160, 177, 200-243 | S4a rename `IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md` (the INPUT file at project root) | KEEP | PROJECT-SIDE | renames the v10 INPUT (underscore→hyphen) before decompose; legitimate |
| 440 | "BACKLOG.md / IMPLEMENTATION-PLAN.md / CHANGELOG.md is BD-165's" | KEEP/verify | PROJECT-SIDE | comment about the decompose inputs |
| 934, 941-947 | completion `say` block: "regenerated mirrors, not source"; "files are regenerated mirrors — read-stable but not source-of-truth."; lists `docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md` | UPDATE-REPOINT | PROJECT-SIDE | user-facing post-migration message claims regenerated mirrors; rewrite to no-mirror (tree + `_toc.md` is the readable form) |

### 5.4 `scripts/pack-td.sh:74,82,85` — `pack td` writes IMPLEMENTATION-PLAN.md (tracker-deferred note)
Command: `git grep -nE 'IMPLEMENTATION-PLAN\.md' -- scripts/pack-td.sh`
Class: **AMBIGUOUS** — pack-td.sh is a PACK-OPS verb (the pack's own TD handling), and its IMPLEMENTATION-PLAN.md refs are about the PACK's plan stream, NOT a client mirror. Scope: PACK-SIDE (likely out of BD-206 scope — verify it is not project-side). The "tracker mode is deferred — BD-214" notes are accurate. Flag: confirm pack-side, then exclude.

### 5.5 `scripts/validate-pack.py` scattered no-mirror prose (lines 136, 239, 318, 2495, 2752, 3145, 5360, 5625, 5697, 7819, 8836, 11491)
Many of these are BD-203 PACK-side prose already correct ("PACK surface deleted its monolith mirrors at BD-203", "no regenerated mirror under the no-mirror model"). Class: **KEEP (pack)** but each MUST be read in context to confirm it does not assert a PROJECT mirror still exists. AMBIGUOUS until per-line verified by the architect — listed here so the lock-step encoding-surface audit does not miss a project-implying line hidden among the pack-correct ones.

---

## 6. CONFIRMED OUT-OF-SCOPE (PACK-SIDE, already converted) — KEEP, do not touch

| Surface | Evidence | Why out of scope |
|---|---|---|
| `scripts/lib/per-entry/_lib.sh:79-99` pack-backlog/pack-changelog `mirror) printf 'pack-ops/BACKLOG.md'` / `'pack-ops/CHANGELOG.md'` | comment "BD-203: `mirror` is RETAINED as a constant only ... no regenerated monolithic mirror ... dead-for-pack" | PACK side, converted in BD-203 |
| `scripts/tests/test-per-entry.sh:213-216` "pack-stream mirror-filename asserts removed" | already removed | PACK side done |
| `scripts/validate-pack.py` Check 32/32′/33/34 pack no-mirror asserts (lines 136, 239, 318) | "no regenerated mirror under the no-mirror model" | PACK side |
| `pack-ops/BACKLOG.md` / `pack-ops/CHANGELOG.md` themselves | do NOT exist (deleted in BD-203; `/backlog/` + `/changelog/` per-entry trees are SSOT) | PACK side done |
| `maintenance-docs/**` (700+ IMPLEMENTATION-PLAN refs, BACKLOG.md refs) | historical/audit/design prose | reference docs, never operating surfaces; not a no-mirror runtime surface |
| `backlog/**`, `changelog/**` per-entry entries citing IMPLEMENTATION-PLAN | governance entries | pack-chat-only governance, not project-mirror machinery |

---

## 7. COVERAGE STATEMENT

**Search angles run (multi-angle so no single method bounds recall):**
1. **GRAPH-FIRST (mandatory DISCOVERY):** 3 `graphify query` traversals against the injected `--graph` (`/Users/.../graphify-out/graph.json`, `--backend claude-cli --budget 1500`) — (a) project-mirror references, (b) cmd_update / install-map / `_CLIENT_INSTALLED_FILES`, (c) surface-detection / recommendation / startup machinery. The graph surfaced the candidate set: `init-project.sh` (cmd_update, install map), `detect.sh`, `pack-help.sh`, `validate-pack.py`, the Check 39/40/43 fixtures, `recommendation.sh`, `MIGRATION-v10-to-v11.md`, the skill masters, the trinity docs, and the cmd-update-symmetry/project-side-refs fixtures. Each candidate was then grep-/Read-grounded.
2. **Filename angle:** `IMPLEMENTATION-PLAN(.md)`, `BACKLOG.md`, `CHANGELOG.md`, `docs/project/...` (all casings) over `git grep` (tracked tree).
3. **Concept angle:** `regenerated mirror`, `monolith(ic) mirror`, `read-stable`, `never source of truth`, `read-only mirror`, `empty mirror`, `empty seed`.
4. **Machinery angle:** `_CLIENT_INSTALLED`, `install.?map`, `detect_pack_surface`, `_SANCTIONED_PACK_SIDE_SHIPPED`, `per_entry_regenerate_mirror`, `mirror-generate`, `_CHECK_43_MIRROR_SKIP`, `pe_canonical_mirror_for_stream`.
5. **Validator/test/CI lock-step angle:** for each in-scope operational surface, the validator (`validate-pack.py` Check 43/41/47), its test (`test-validate-pack-check-43.sh`), and the persona/init/per-entry/decompose/recommendation tests + fixtures were enumerated together. CI: the `Validate Pack` workflow runs `validate-pack.py` + the shell test battery; no separate workflow file encodes the mirror state beyond running these (verified — the encoding lives in the validator + tests, which are covered).

**What each angle surfaced:** the filename angle found the install-map / `_lib.sh` / generation call-sites + the doc/skill/trinity prose; the concept angle found the prose + the validator rationale + the migrator messages; the machinery angle found the dual-use detect/recommendation repoint + the validator constants; the lock-step angle paired each validator change with its test (e.g. Check 43 constant 5593 ↔ test 136-138; init greenfield generation ↔ test-init-project 270-336; project mirror-filename `_lib.sh` 109-129 ↔ test-per-entry 219-221).

**Candidate-set provenance:** `git ls-files` (1762 tracked); all greps tracked-tree-scoped via `git grep` — NO raw filesystem walk. Git is a work tree (verified `git rev-parse HEAD` = 775e9cc).

**Completeness confidence:** HIGH for the operational + validator/test + governance/docs + skill-master surfaces (Sections 1-4) — these were reached by ≥2 independent angles and graph + grep agree. The graph's DISCOVERY set was fully contained within the grep ground-truth (no graph-only candidate went unverified; no grep-only operational surface was absent from the graph's neighborhood).

**Residual uncertainty (explicitly flagged, not silently resolved):**
- **Tracker library family (§5.1, ~40+ refs across 9 files):** classified AMBIGUOUS because tracker mode is deferred/gated-off (`pack-tracker.sh:153-161`) yet BD-206.md both DROPS tracker folds AND KEEPS "tracker-mirror.sh CLIENT legs." Their monolith references do not execute in flat-file mode, but several carry stale "clients still ship monolith mirrors" / "until BD-206 lands" comments. The disposition (touch now vs leave dormant for deferred tracker resumption) is a SCOPING decision for the architect/user — I did not include them in the STRIP/UPDATE set nor exclude them.
- **`supporting-docs/METHODOLOGY.md` (§4.2, 24 IMPLEMENTATION-PLAN refs):** AMBIGUOUS because it models `IMPLEMENTATION-PLAN.md` as the canonical hand-authored plan (a pre-per-entry model deeper than "regenerated mirror"). Whether BD-206 rewrites METHODOLOGY's plan model wholesale or only the mirror-specific clauses is a scoping question.
- **`_lib.sh` project-mirror constants (§1.2) + `mirror-generate.sh` (§1.3) file fate:** UPDATE-REPOINT-vs-STRIP depends on whether the architect mirrors the BD-203 pack pattern (retain the constant as a deletion-target reference, dead the generator) or removes outright. Flagged with both options + the BD-203 symmetry argument.
- **`validate-pack.py` scattered no-mirror prose (§5.5):** mostly pack-correct; each line needs per-line context verification to ensure none wrongly implies a surviving project mirror.

**Counts (occurrence-records, not unique files):**
- KEEP: ~12 records (conversion-input reads, v10 root-rename steps, generic-verb "mirror", pack-side already-correct, Check 47/41 machinery, the `pe_canonical_mirror_for_stream` accessor mechanism).
- STRIP: ~13 records (greenfield generation call-sites, migration regenerate step, persona "empty mirrors" asserts, test mirror-existence/byte-identity asserts, `.docs-gate-allowlist.txt` mirror entries, hand-edit-the-mirror guidance).
- UPDATE-REPOINT: ~45 records (install-map middle field, detect.sh client branch, recommendation signal reads, trinity Document-locations rows, skill masters, PM-CHAT/prompts plan reads, MIGRATION/METHODOLOGY/INSTALL/SETUP prose, validate-pack Check 43 constants + prose, the migrator completion message).
- AMBIGUOUS (flagged for triage): the entire tracker family (§5.1), METHODOLOGY.md plan model (§4.2), `_lib.sh`/`mirror-generate.sh` fate (§1.2/1.3), `customization-preserve.sh` cite (§5.2), `pack-td.sh` (§5.4 — likely PACK-side), and validate-pack scattered prose (§5.5).

**In-scope vs out-of-scope split:** Sections 1-4 (operational machinery, validator/test/CI, governance/docs, supporting-docs) are PROJECT-SIDE in BD-206 scope. Section 6 is PACK-SIDE out of scope (already converted in BD-203). Section 5 is AMBIGUOUS pending human triage.

---

## 8. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence | Conclusion |
|---|---|---|
| **researcher-maps-blast-radius-before-architect** | This document IS the exhaustive blast-radius map: every reference grepped tracked-tree-wide, categorized KEEP/STRIP/UPDATE-REPOINT, scoped PROJECT/PACK/AMBIGUOUS, with file:line + quoted text + reproducing command per record. Favored recall over brevity (Sections 1-5). | COMPLIANT |
| **external-rules-census-before-design / measure-then-bound** | MEASURED the tree first (`git grep` over `git ls-files`, 1762 tracked, HEAD=775e9cc); classified EVERY surfaced occurrence; sized conclusions to evidence; flagged AMBIGUOUS rather than admitting unclassified hits as legitimate-by-default. Candidate set from git-tracked files, never a raw walk (stated §0/§7). Git confirmed a work tree (`git rev-parse HEAD` succeeded). | COMPLIANT |
| **enumerate-encoding-surfaces** | For each in-scope operational surface, enumerated in lock-step the surface + validator + test + fixture: Check 43 constant (validate-pack.py:5593) ↔ its test (test-validate-pack-check-43.sh:136-138); greenfield generation (init-project.sh:1109-1121) ↔ test-init-project.sh:270-336 + persona contract-greenfield 240-244; project mirror constants (_lib.sh:109-129) ↔ test-per-entry.sh:219-221; migration regenerate (decompose.sh:195-197) ↔ test-migrate-decompose 302-304 + test-v11-realistic-ot + build.sh; skill masters ↔ their 3 pack copies (noted §3.2). Asymmetric-coverage risk explicitly surfaced. | COMPLIANT |
| **graph-first-context** | Ran 3 `graphify query` traversals FIRST (DISCOVERY) against the INJECTED `--graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 1500` (never recomputed from own toplevel); used the surfaced candidate set, then grep/Read to ground-truth each (VERIFICATION). G2 not needed (queries returned useful nodes). Evidence: query outputs in the transcript surfaced init-project.sh/detect/validate-pack/recommendation/fixtures/skill-masters. | COMPLIANT |
| **agents-never-commit / per-action-approval-sub-agents** | Ran only read-only git (`git rev-parse`, `git grep`, `git ls-files`, `git status --short`, `git branch`); NO state-changing verb. The sole write is this census doc (via Bash heredoc, the permitted single output). No destructive op performed. | COMPLIANT |
| **spawn-unique-naming** | Operating under the unique name `docsresearcher-bd206-census` (recorded in the document header §top). | COMPLIANT |
| **agent-output-rules-applied-block / agents-read-rule-docs-in-full** | This block exists with per-rule measured evidence. READ-IN-FULL direct-Read proof of each named memory file: feedback_researcher_maps_blast_radius_before_architect.md (wc -l=40; first "---", last "[[adversarial-architect-review-on-major-gap]]."); feedback_external_rules_census_before_design.md (wc -l=42; ends "lossless requirement)."); feedback_ci_guard_design_measure_then_bound.md (wc -l=14; ends "[[triage-workflow-protocol]]."); feedback_rename_plans_measure_then_bound.md (wc -l=43; ends "feeds the gate's in-scope file set + allowlist)."); feedback_agent_output_rules_applied_block.md (wc -l=14; ends "[[architect-planner-empirical-evidence]]."); feedback_agents_read_rule_docs_in_full.md (wc -l=133; ends "...catches the dangerous cases."). Also read CLAUDE.md `## Pack memory` in full (provided in-context) and backlog/BD-206.md (23 lines). The `feedback_enumerate_...` file named conditionally in the prompt was not present as a standalone file; relied on the CLAUDE.md `enumerate-encoding-surfaces` rule text as the prompt permitted. | COMPLIANT |

**HEAD censused at:** `775e9cc139ef3fdde3d499198894a7bef70145e1` — **Date:** 2026-06-26.
