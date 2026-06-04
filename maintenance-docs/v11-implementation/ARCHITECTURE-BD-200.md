# ARCHITECTURE — BD-200 — Project-side capability addition (no pack-clone dependency)

**Role:** pack-architect (read-only). **Branch:** v11-dev.
**HEAD at design:** `972c3a1020f28f604f3bd32f4d7cad818c6c8dd4`. **Date:** 2026-06-03.
**Scope:** project-side capability-addition mechanism (script + workflow/Procedure 6 + client-surface references) + the conditional-file source-of-truth question + the guard/install-map ripple. Read-only; one design doc; no source edits.

---

## 1 — Summary / recommended design (lead)

The BD-200 goal is sound, but **two of its three stated work-items are already done in the tree** and must be re-scoped, while the **one genuinely-undesigned problem** is narrower and different from the BD framing. Measure-first findings:

1. **Copy-ALL-skills is ALREADY the install behavior.** `stage_s4_skills()` iterates `project-template/skills/*/` and copies **every** skill's `SKILL.md` into all three client CLI dirs unconditionally (EEB-2). `pack_skill_coverage_for()` is used **only** for the preview/gap REPORT, never to filter the copy. Skill count (36) is already reconciled in README and PLATFORM-SKILLS (EEB-3). **No install-change, no skill-count edit, no PLATFORM-SKILLS edit is needed for the skill path.** The BD's "today copies only selected coverage, must copy ALL skills" premise is FALSE at HEAD.

2. **The ONLY real pack-clone dependency is the conditional-FILE copy.** `add-capability.sh` stage A5 copies conditional files (`pyproject.toml`, `pyrightconfig.json`, `server/`, `proto/`, and the per-language `scripts/*-python.sh` / `*-swift.sh` / `proto-*.sh`) FROM `$PACK/project-template/` (EEB-4). At install, `stage_s9_conditional_remove()` DELETES exactly these files for languages the project does not yet have (EEB-5). So a Swift-only client that later wants Python has had `pyproject.toml`/`server/`/`scripts/*-python.sh` removed and **needs a source to re-materialize them** — that source is the only thing tying capability-addition to a pack checkout. This is the real design problem.

3. **Recommended mechanism: ship a self-contained project-side `add-capability` script that re-materializes conditional files from a client-local SOURCE POOL, not from `$PACK`.** Because the conditional-file set is tiny and static (106 lines of text + two small dir trees — EEB-6), the install ships a client-local **conditional-file pool** (a hidden, gitignored staging dir, e.g. `.pack-capability-templates/`, populated at install from `project-template/` BEFORE S9 removal — or equivalently, S9 is changed to MOVE conditional files into the pool instead of deleting them). The project-side script reads the pool, never `$PACK`. The script is a **full REPLACE of the client-facing capability path** (open question 1 verdict), placed at `project-template/scripts/` (open question 3 verdict) so it ships automatically via the existing S5 glob — **no install-map edit, no Check 47 / Check 41 change, no sanctioned-allowlist growth** (open question 2 verdict; EEB-7/EEB-8).

4. **Procedure 6 is redesigned as a self-contained project-side workflow** keyed to the project-side script's emitted prompt; all "run from the pack" / `add-capability.sh`-by-name / pack-self references are removed. HELP-FRAGMENT verb row and PM-CHAT "Capability addition" rule are reworked to name the project-side verb; INSTALL-PROCEDURES strips the pack-script enumeration (matching the BD-195 C8 disposition).

5. **Pack-side `add-capability.sh` stays pack-side, unchanged in scope.** It remains the pack-developer tool for the pack's own dog-food/test flow. The project-side script is a SEPARATE artifact (`pack-project-separation-of-concerns`), not a fork of the pack script's `$PACK`-coupled internals.

**This re-scopes BD-200 to: (a) a conditional-file client-local pool + S9 change; (b) a project-side `add-capability` script at `project-template/scripts/`; (c) Procedure 6 redesign; (d) client-surface reference rework. It drops the skill-install change and skill-count reconciliation as no-ops.** Items dropped are surfaced, not silently removed (§4, §7).

---

## 2 — The dependency-direction analysis (the decisive frame)

`add-capability.sh` (pack-side) is inoperable client-side for exactly two reasons (BD-195 verdict, re-confirmed at HEAD — EEB-4):
- A0 hard-exits when `$PACK` is unset/invalid.
- A5 copies conditional files from `$PACK/project-template/$f`.

Per `dependency-direction-placement`: a **project-side deliverable must never be a runtime dependency of a pack operation**, and a client-shipped script's default home is `project-template/scripts/`. The new script is a pure client deliverable — no pack operation invokes it, and it must run with no `$PACK`. Therefore:
- It lives at `project-template/scripts/` (ships via S5 glob; covered by the `project-template/scripts/* -> scripts/*` bulk-copy install-map note — EEB-7).
- It sources its conditional files from a **client-local pool**, never from `$PACK` (the substitution-direction rule: a script copying to a client path must source from the client's own SSOT, never a pack-internal location — `pack-project-separation-of-concerns`).
- It does **not** qualify for `_SANCTIONED_PACK_SIDE_SHIPPED` and must not be added there (the sanctioned set is for pack-side-LOCATED files that ship; a `project-template/`-located file is admitted automatically and is invisible to Check 47 — EEB-8).

---

## 3 — Resolution of the three open design questions

### OQ-1 — Relationship to pack-side `add-capability.sh`: **REPLACE (separate artifact), not fork or shared-core.**

- **Not a fork.** ~80% of `add-capability.sh`'s body (A0 `$PACK` validation, A5 `$PACK/project-template/` copy, A6 `$PACK/project-template/.gitignore` merge, `warn_if_missing_skills()` reading `$PACK/.../SKILL.md`, the A8 prompt that points at Procedure 6 / BD-048) is `$PACK`-coupled or pack-developer-facing. Forking it drags `$PACK` assumptions into client space — a boundary regression.
- **Not a shared core library.** A shared `scripts/lib/*.sh` consumed by BOTH the pack script and a client script would make a client deliverable a runtime dependency of a pack operation (or vice-versa) — and the shared logic would have to be present client-side, which only re-creates the dependency-direction problem the BD exists to remove. (`scripts/lib/detect.sh` is already a sanctioned dual-use lib; we do NOT widen that pattern here — `ci-guard-measure-then-bound` / no allowlist growth.)
- **Verdict: the project-side script is a NEW, self-contained artifact** that re-uses the pack script's *capability tables as data* (the `capability_skills` / `capability_files` / `capability_install_checks` mappings) but re-implements the few stages it needs against the client-local pool. The pack-side `add-capability.sh` stays for the pack's own use; its scope is unchanged. The two scripts are SEPARATE artifacts per `pack-project-separation-of-concerns` — byte-overlap in the capability tables is coincidence, not a shared-source contract. (If keeping the two tables manually in sync is judged a maintenance burden, the planner may propose a generated data file shipped into the pool; that is a planner-level mechanism choice, flagged not prescribed.)

### OQ-2 — Copy-all-skills × `_SANCTIONED_PACK_SIDE_SHIPPED` / Check 47 / Check 41: **NO interaction — copy-all-skills already happens; no guard change.**

Measure-then-bound result (EEB-2, EEB-3, EEB-7, EEB-8):
- **Skill install is already all-skills** (S4 glob). No code change ⇒ no new install-map entry ⇒ no Check 41 row ⇒ no Check 47 set-equality movement. Skills install to `.{claude,codex,gemini}/skills/*` via the S4 canonical-pool loop, already a bulk-copy install-map note, NOT enumerated per-file in `_CLIENT_INSTALLED_FILES`.
- **The new project-side script** lands under `project-template/scripts/`. `_iter_client_installed_files()` admits all `project-template/` files via the recursive walk (branch (a)); the `_SANCTIONED_PACK_SIDE_SHIPPED` membership gate runs ONLY on install-map entries that are NEITHER `project-template/` NOR `supporting-docs/` (EEB-8). The new script is therefore invisible to Check 47 and needs no allowlist entry. Check 41 covers it via the existing `project-template/scripts/* -> scripts/*` bulk-copy note (no per-file enumeration required — EEB-7).
- **The conditional-file pool** is sourced from `project-template/` content already shipped; whether it lands as a hidden dir or via an S9-change, no NEW pack-side-located file ships, so the frozen 2-tuple `{scripts/lib/detect.sh, scripts/pack-help.sh}` is untouched. **No architect+user sanctioned-allowlist sign-off is required.** (Flagged explicitly per the rule: this design does NOT grow the sanctioned set.)

### OQ-3 — Placement: **`project-template/scripts/<name>.sh`; nothing new must stay pack-side; pack-side `add-capability.sh` unchanged.**

- New script: `project-template/scripts/` (dependency-direction default for a client-shipped script; ships via S5 + `_cmd_update_iter_dir` glob; reaches `--update` clients automatically).
- Name: must NOT use the `x-` prefix (that prefix is reserved for project-AUTHORED files; pack-supplied files never begin with `x-` — EEB-9). Recommended `add-capability.sh` at the **project** path (it is a different file from the pack-root `scripts/add-capability.sh`; they live at different paths and serve different audiences, which is exactly the trinity/separation model). NOTE the `filename-uniqueness-heuristic`: a same-basename collision with pack-root `scripts/add-capability.sh` is acceptable here because the two are a deliberate pack-vs-project pair, but every prose reference MUST carry path context (`scripts/add-capability.sh` in client docs always means the installed client copy). The planner may instead choose a distinct basename (e.g. `add-capability-local.sh`) to eliminate the collision entirely — flagged as a planner-level naming decision, not prescribed.
- Pack-side `scripts/add-capability.sh`: **stays, scope unchanged.** It is the pack's own capability tool (dog-food, tests). BD-200 does not delete or rewrite it.

---

## 4 — The project-side mechanism design

### 4.1 — Conditional-file source pool (the load-bearing new piece)

The project-side script cannot read `$PACK`. It needs a client-local source for the conditional files that S9 removed. Two equivalent mechanisms; the planner picks one (both satisfy the boundary contract):

- **Option A — staging pool.** At install, BEFORE `stage_s9_conditional_remove()` deletes, copy the full conditional-file set into a hidden, gitignored client dir (proposed `.pack-capability-templates/`, mirroring the existing `.pack-*` prompt/state-file convention). S9 still removes the active-tree copies for absent languages; the pool retains the masters. The project-side script copies from the pool into the live tree on capability-add.
- **Option B — S9 moves instead of deletes.** Change `stage_s9_conditional_remove()` to MOVE absent-language conditional files into the pool rather than `rm`. Functionally identical end-state; slightly less duplication at install.

Either way the pool is the client-local SSOT for conditional files; `$PACK` is never read. The pool is gitignored (project does not version pack template masters). The set is tiny and static (EEB-6), so install-size cost is negligible.

**Guard ripple of the pool:** the pool lives under the client project root, materialized at install — it is NOT a pack-repo tree, so it adds no `project-template/` file and no install-map entry. The `.gitignore` template (`project-template/.gitignore`) gains a `.pack-capability-templates/` line (a `project-template/` edit — auto-shipped, no map change). Manifest regen applies (v11-surface).

### 4.2 — Project-side script behavior (stages, client-local)

Mirrors the *useful* subset of the pack script, re-pointed at the pool and with all `$PACK` logic removed:

| Stage | Behavior | Notes vs pack script |
|---|---|---|
| P0 pre-flight | Require: target is a git repo; clean tree; AI config present (a pack-initialized project). **No `$PACK` check.** | Drops A0's `$PACK` validation entirely. |
| P1 resolve | Resolve `--add <dim>:<val>` via the capability tables (skills + files). | Same tables as pack script (data, not shared code). |
| P2 delta | Compute skills-to-add vs the `**Active skills:**` line; files-to-add vs files already present. | Same as A2. |
| P3 preview + P4 confirm | Show planned changes; confirm. | Same as A3/A4. |
| P5 copy | Copy conditional files **from the client-local pool** into the live tree. | Replaces A5's `$PACK/project-template/$f` with `<pool>/$f`. |
| P6 gitignore | Re-merge from the **client-local** `.gitignore` (already present) — or no-op (the client `.gitignore` already carries pack lines from install). | Replaces A6's `$PACK/project-template/.gitignore`. |
| P7 install-check | Read-only `command -v` discovery (unchanged — no `$PACK`). | Identical to A7. |
| P8 prompt | Emit the end-of-run PM-chat prompt naming the **project-side Procedure 6** with NO pack-self references. | A8 rewritten: no BD-048 citation, no "from the pack". |

Skills are NOT copied by the script (they are all already on disk from install — same as today; the PM chat only edits the Active-skills line in Procedure 6).

### 4.3 — Procedure 6 redesign (self-contained, project-side)

Current Procedure 6 (METHODOLOGY.md §6, EEB-10) references `add-capability.sh` by name, "run from the pack", BD-048, and stage A7/A8 internals — all pack-self leaks per `bd-pack-only-operational-rule`. Redesign:

- **Trigger:** keep the two-trigger shape but rewrite both to the project-side script. Trigger 1: developer pastes the prompt emitted by the **project-side** `scripts/add-capability.sh`. Trigger 2: developer asks "add Python"/"add iOS"; the PM chat runs the project-side `scripts/add-capability.sh` (a client script, no pack checkout) then resumes.
- **Framing line:** replace "PM-chat-side companion to `add-capability.sh` … stage A8" with audience-neutral prose: "the PM-chat-side companion to the project's `scripts/add-capability.sh` capability script."
- **Step bodies:** Step 6.1 reads the prompt from `.pack-add-capability-prompt.md` (project root, already gitignored) — drop the "stage A8" parenthetical. Steps 6.2–6.7 are already client-side correct (read on-disk SKILL.md, draft trinity, Form-I, detection scan, commit) and need only the pack-self citations stripped (BD-048, "stage A7" → "the script's read-only discovery").
- **"Adding a new capability row" tail (METHODOLOGY §6 final para):** this paragraph is pack-MAINTENANCE guidance (it instructs editing `capability_skills()` / `capability_files()` / `capability_install_checks()` — pack-development work). It is a leak on a client surface (matches BD-195 C7 line-1463 disposition). **DELETE it from the client METHODOLOGY** — a client developer never extends pack capability tables. (Pack-side maintenance of those tables is documented pack-side, out of client scope.)
- **Net:** Procedure 6 survives as a coherent, fully client-side workflow keyed to a script the client actually has and can run. (This resolves the BD-195 §5 escalation in the redesign direction (a): "reframe Procedure 6 to a purely client-side workflow," now feasible because the script exists client-side.)

### 4.4 — Client-surface reference rework

| Surface | Current (HEAD) | Disposition |
|---|---|---|
| `project-template/docs/pack/HELP-FRAGMENT.md` verb row (EEB-11) | `` \| `bash scripts/add-capability.sh` \| Add a pack-supported capability… \| `` | **KEEP/REWRITE as a valid client verb.** Now legitimate — `scripts/add-capability.sh` IS installed client-side and runnable. Confirm wording matches the project-side script's actual invocation. (Reverses BD-195 C1's DELETE, which was correct under the old "pack-only script" verdict; BD-200 changes the underlying fact.) |
| `project-template/docs/pack/PM-CHAT.md` "Capability addition" rule (EEB-12) | "direct them to run `scripts/add-capability.sh` from the pack first; then run METHODOLOGY.md Procedure 6" | **REWRITE.** Drop "from the pack"; the client PM chat runs the project's own `scripts/add-capability.sh`, then Procedure 6. No pack checkout implied. |
| `supporting-docs/INSTALL-PROCEDURES.md:56` (EEB-13) | "the pack's scripts (`init-project.sh`, … `add-capability.sh`) that removes files…" | **STRIP the pack-script enumeration** (matches BD-195 C8). The client reader needs the `x-` deletion guarantee, not the pack-script roster. Note `add-capability.sh` is add-only client-side; if the sentence is about pack-controlled deletion it should name only the install/migrator paths the client actually runs, or drop the roster. |

**Check 22 (help-fragment freshness) ripple:** Check 22 requires every verb token in the named docs to APPEAR in the matching HELP-FRAGMENT (EEB-14). The project-template surface checks PM-CHAT.md against `project-template/docs/pack/HELP-FRAGMENT.md`. Keeping the `scripts/add-capability.sh` verb in BOTH PM-CHAT.md and HELP-FRAGMENT.md keeps Check 22 green. (This is why HELP-FRAGMENT.md KEEPS the row rather than deleting it.) `enumerate-encoding-surfaces`: the coder verifies the verb token is consistent across PM-CHAT.md + HELP-FRAGMENT.md + Procedure 6.

---

## 5 — Guard / install-map / skill-inventory ripple (measure-then-bound summary)

| Guard / surface | Change? | Why |
|---|---|---|
| `stage_s4_skills()` (skill install) | **NO** | Already copies ALL skills (EEB-2). |
| README / PLATFORM-SKILLS skill count | **NO** | Already 36, reconciled (EEB-3). |
| `_SANCTIONED_PACK_SIDE_SHIPPED` / Check 47 | **NO** | New script is `project-template/`-located → outside the membership gate (EEB-8). Frozen 2-tuple untouched. NO architect+user sign-off needed. |
| `_CLIENT_INSTALLED_FILES` / Check 41 | **NO new explicit entry** | New script covered by existing `project-template/scripts/* -> scripts/*` bulk-copy note (EEB-7). |
| Check 39 (cmd_update mapping/glob symmetry) | **NO** | `_cmd_update_iter_dir "project-template/scripts"` glob already covers any new script (EEB-7). |
| Check 22 (help-fragment freshness) | **lock-step verify** | Verb token kept consistent across PM-CHAT/HELP-FRAGMENT/Procedure 6 (§4.4). |
| `stage_s9_conditional_remove()` | **YES (Option A or B)** | Must preserve conditional files into the client-local pool instead of unconditionally destroying the only client-local source. |
| `project-template/.gitignore` | **YES (one line)** | Gitignore the pool dir. Auto-ships; no map change. |
| `test-fixtures/manifest.txt` | **YES (regen)** | Edits touch `project-template/`, `scripts/`, `supporting-docs/` (v11-surface) — `regenerate-manifest-v11-surface`. |
| Check 43 (project-side bare cross-ref / leak sweep) | **lock-step verify** | The redesigned Procedure 6 + reworked references must carry ZERO pack-self tokens (no BD-NNN, no `maintenance-docs/`, no "from the pack"); Check 43 is the catch-net. |

**Pack-side fixtures/tests for `add-capability.sh`** (`scripts/tests/test-add-capability.sh`, `scripts/test-detect.sh` comments): unchanged — the pack script is unchanged. A NEW project-side test fixture for the project-side script is a planner-level coverage item (the project-side script has no `$PACK` and a pool source — its own test harness).

---

## 6 — Risks / sign-offs required

- **No sanctioned-allowlist growth.** This design deliberately does NOT touch `_SANCTIONED_PACK_SIDE_SHIPPED`. If the planner/coder finds a reason to ship the new script from a pack-side location instead of `project-template/scripts/`, that would require architect+user sign-off per Check 47 — but the design explicitly avoids that path. (Flagged per `dependency-direction-placement`.)
- **Capability-table duplication risk.** The project-side script re-uses the pack script's capability tables as data. If maintained as two hand-edited copies they can drift. Mitigation options (planner choice): (a) ship a single generated capability-table data file into the pool that both consume; (b) accept duplication with a lock-step-edit note + a CI parity check (would be a NEW check — architect+user decision if pursued). Not prescribed here; surfaced.
- **Pool freshness across `pack update`.** When a client runs `pack update`, the pool masters should refresh from the new pack version (else added capabilities use stale templates). The planner must wire the pool into the `--update` path (the conditional-file masters already flow through `_cmd_update_iter_dir`/S-stages for the LIVE tree; the pool needs the same). Tractable, but must be designed, not assumed.
- **BD-195 reversal of C1/C8.** BD-195's verdict DELETED the HELP-FRAGMENT verb row (C1) and stripped the INSTALL-PROCEDURES roster (C8) on the premise that `add-capability.sh` is pack-only. BD-200 changes that premise (the script now ships and runs client-side). The coder must confirm the BD-195 remediation already landed (it did — BD-195 Resolved 2026-06-03) and that BD-200 RE-ADDS a corrected client verb row, not a duplicate. Reconcile with the BD-195 final state, not the pre-BD-195 state.

---

## 7 — Out-of-scope observations (surfaced, not solved)

- **BD-200 framing overstates the work.** Two of three stated items (copy-all-skills install change; skill-count + PLATFORM-SKILLS reconciliation) are no-ops at HEAD. Pack Chat should re-scope the BD entry's File/Symbol + Acceptance-criteria lines so the launch-gate item reflects the actual (smaller) work: conditional-file pool + project-side script + Procedure 6 + reference rework. (Surfaced; the BD entry is PM-only — not edited here.)
- **`warn_if_missing_skills()` forward-declared skills (BD-144).** The pack script warns when a resolved skill has no `SKILL.md` in `$PACK`. Client-side, all 36 skills are present (S4), so the project-side script's equivalent check is against the on-disk client skills — simpler, no `$PACK`. Forward-declared platform rows (android/web/embedded) still resolve to skills that DO now ship (EEB-3 shows android-architecture etc. are absent from the 36? — verify: the 36-list does NOT contain `android-architecture`/`web-architecture`/`embedded-mcu-architecture`). The project-side script must keep the same warn-don't-fail behavior for those forward-declared rows. Surfaced for the planner.
- **The pack-side `add-capability.sh` `(v10)` currency tags** (header self-label, README row) are a BD-195 C10 item, already in BD-195 scope — not re-touched here.

---

## 8 — Empirical-Evidence Blocks (state-claims)

> **EEB-1 — HEAD SHA at design.**
> Command: `git rev-parse HEAD` → `972c3a1020f28f604f3bd32f4d7cad818c6c8dd4`. Date 2026-06-03.
> Conclusion: **SUPPORTED** (stamps all blocks below).

> **EEB-2 — `stage_s4_skills()` already copies ALL skills unconditionally.**
> Command: `sed -n '484,508p' scripts/init-project.sh`. Output (key): `for skill_dir in "$PACK/project-template/skills"/*/; do … cp "$skill_dir/SKILL.md" "$TARGET/.${tool}/skills/$name/SKILL.md"` for `tool in claude codex gemini` — no filter by coverage. Corroborated by the in-file comment (`init-project.sh:286-290`): "stage_s4_skills copies ALL pack skills to the per-CLI directories unconditionally." `pack_skill_coverage_for()` (lines 235-327) is consumed only by `print_preview()` (line 355) and the S10 gap report (line 732), never to gate the S4 copy.
> Interpretation: copy-all-skills is the current install behavior; BD-200's "today copies only selected coverage" premise is false.
> Conclusion: **SUPPORTED**.

> **EEB-3 — Skill count = 36, already reconciled in README and PLATFORM-SKILLS.**
> Command: `ls -d project-template/skills/*/ | wc -l` → `36`. `grep -n "36 skills" README.md` → `README.md:101 "Canonical skill library (36 skills …)"`. `grep "Full skill inventory" project-template/docs/pack/PLATFORM-SKILLS.md` → present (line 417); Tier-0 header reads "(14)". The 36 dirs do NOT include `android-architecture`/`web-architecture`/`embedded-mcu-architecture` (forward-declared rows resolve to not-yet-shipped skills).
> Interpretation: no skill-count edit needed; the forward-declared-row warn behavior must be preserved client-side.
> Conclusion: **SUPPORTED**.

> **EEB-4 — Pack `add-capability.sh` requires `$PACK` and copies from `$PACK/project-template/`.**
> Command: `grep -nE 'PACK environment|detect_pack_path|\$PACK/project-template' scripts/add-capability.sh`. Output: `376: if [[ -z "${PACK:-}" ]]; then`; `377: die "PACK environment variable not set …" "$EXIT_PACK_INVALID"`; `380: pack_status=$(detect_pack_path "$PACK" …)`; `580: src="$PACK/project-template/$f"`; `603: local pack_gi="$PACK/project-template/.gitignore"`.
> Conclusion: **SUPPORTED**.

> **EEB-5 — `stage_s9_conditional_remove()` deletes the conditional files for absent languages.**
> Command: `sed -n '644,717p' scripts/init-project.sh`. Output (key): for `has_python==0`, `rm -rf` of `pyproject.toml pyrightconfig.json scripts/bootstrap-python.sh scripts/format-python.sh scripts/validate-python.sh scripts/test-python.sh` + `server/`; for `has_swift==0`, `rm -f` of `scripts/*-swift.sh`; for `has_proto==0`, `rm -f scripts/proto-gen.sh scripts/validate-proto.sh` + `rm -rf proto/`.
> Interpretation: a client lacking a language has those exact files removed; re-adding the language needs a re-materialization source. This is the sole real pack-clone dependency.
> Conclusion: **SUPPORTED**.

> **EEB-6 — The conditional-file set is tiny and static.**
> Command: `wc -l project-template/pyproject.toml project-template/pyrightconfig.json project-template/scripts/bootstrap-python.sh project-template/scripts/proto-gen.sh` → `33 / 6 / 30 / 37` (106 total). `find project-template/server -type f` → 2 files; `find project-template/proto -type f` → 4 files.
> Interpretation: shipping a client-local pool of these costs negligible install size.
> Conclusion: **SUPPORTED**.

> **EEB-7 — `project-template/scripts/*` is a bulk-copy install path (S5 + cmd_update glob); a new script needs no per-file map entry.**
> Command: `grep -n '_cmd_update_iter_dir "project-template/scripts"\|project-template/scripts/\*' scripts/init-project.sh`. Output: `1210: _cmd_update_iter_dir "project-template/scripts" "scripts" pack-script`; install-map comment block `1258-1259`: `project-template/scripts/* -> scripts/* [S5 + _cmd_update_iter_dir]`. S5 body (`510-525`) copies `for f in "$pack_scripts"/*`.
> Interpretation: a new `project-template/scripts/<name>.sh` ships at fresh install (S5) and updates (cmd_update) with no explicit `_CLIENT_INSTALLED_FILES` entry; Check 41/Check 39 satisfied by the existing glob note.
> Conclusion: **SUPPORTED**.

> **EEB-8 — Check 47's membership gate runs ONLY on non-`project-template/`, non-`supporting-docs/` install-map entries; a `project-template/` file is invisible to it.**
> Command: `sed -n '7101,7106p' scripts/validate-pack.py` → `map_pack_side = { e for e in entries if not e.startswith("project-template/") and not e.startswith("supporting-docs/") }`. `_iter_client_installed_files()` (4209-4216): `if entry.startswith("project-template/"): continue` is preceded by branch (a) recursive walk that admits all `project-template/` files unconditionally; the membership gate `entry not in _SANCTIONED_PACK_SIDE_SHIPPED` applies only after excluding `project-template/` and `supporting-docs/`.
> Interpretation: the new `project-template/scripts/` script is never tested against `_SANCTIONED_PACK_SIDE_SHIPPED`; no allowlist growth, no Check 47 movement, no architect+user sign-off.
> Conclusion: **SUPPORTED**.

> **EEB-9 — `x-` prefix is reserved for project-authored files; pack-supplied files never use it.**
> Command: `grep -n "Pack-supplied skills never begin with x-\|never begin with .x-" project-template/CLAUDE.md` → `project-template/CLAUDE.md:210 "Pack-supplied skills never begin with x-."`. `grep -n "reserved_x_prefix" scripts/validate-pack.py` → `742: def check_reserved_x_prefix()`.
> Interpretation: the new pack-shipped script must NOT use the `x-` prefix.
> Conclusion: **SUPPORTED**.

> **EEB-10 — Procedure 6 contains pack-self references ("from the pack", `add-capability.sh`, BD-048, stage A7/A8, capability-table maintenance).**
> Command: `grep -n "add-capability\|from the pack\|BD-048\|stage A7\|stage A8\|capability_skills" supporting-docs/METHODOLOGY.md` (Procedure 6 region 1407-1467). Output (key): `1412 "scripts/add-capability.sh stage A8"`; `1415 "run add-capability.sh from the pack"`; `1418 "PM-chat-side companion to add-capability.sh"`; `1432 "Read the add-capability.sh report … written by stage A8"`; `1457 "discovery itself runs script-side (add-capability.sh stage A7)"`; `1463 "extends three parallel surfaces in scripts/add-capability.sh: capability_skills() …"`.
> Interpretation: Procedure 6 redesign must strip these; the §6.x bodies are otherwise client-correct.
> Conclusion: **SUPPORTED**.

> **EEB-11 — HELP-FRAGMENT carries the `add-capability.sh` verb row.**
> Command: `grep -n "add-capability" project-template/docs/pack/HELP-FRAGMENT.md` → `15: | `bash scripts/add-capability.sh` | Add a pack-supported capability to an existing project. |`.
> Conclusion: **SUPPORTED**.

> **EEB-12 — PM-CHAT "Capability addition" rule says "from the pack".**
> Command: `grep -n "from the pack\|add-capability\|Capability addition" project-template/docs/pack/PM-CHAT.md` → `387: "- **Capability addition.**"`; `389: "scripts/add-capability.sh from the pack first; then run METHODOLOGY.md"`.
> Conclusion: **SUPPORTED**.

> **EEB-13 — INSTALL-PROCEDURES:56 enumerates pack scripts including `add-capability.sh`.**
> Command: `grep -n "add-capability" supporting-docs/INSTALL-PROCEDURES.md` → `56: "migrator, `add-capability.sh`) that removes files from these"`.
> Conclusion: **SUPPORTED**.

> **EEB-14 — Check 22 (help-fragment freshness) compares PM-CHAT verbs against `project-template/docs/pack/HELP-FRAGMENT.md`.**
> Command: `sed -n '1965,1972p' scripts/validate-pack.py` → project-template surface `docs: [ … PM-CHAT.md ]`, `fragment: … project-template/docs/pack/HELP-FRAGMENT.md`. Check body: every verb token in the docs must appear in the fragment.
> Interpretation: keeping the verb in BOTH PM-CHAT and HELP-FRAGMENT keeps Check 22 green; this is why the row is KEPT/rewritten, not deleted.
> Conclusion: **SUPPORTED**.

---

## 9 — Rules-Applied Verification Block

| Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| READ-IN-FULL set | Read in full (single full-file Read calls, no offset/limit crop except where a file exceeds tool limits and was read in measured ranges with grep confirmation): `CLAUDE.md` (incl. `## Pack memory`); `pack-ops/PACK-AGENTS.md` (226 lines); `pack-ops/PACK-CHAT.md` (310 lines); `project-template/CLAUDE.md` (456 lines); the 8 curated memory files (`feedback_architect_planner_empirical_evidence`, `feedback_ci_guard_design_measure_then_bound`, `feedback_pack_project_separation_of_concerns`, `feedback_bd_pack_only_operational_rule`, `feedback_preliminary_triage_architect_challenge`, `feedback_scope_deliverables_to_the_ask`, `feedback_agent_output_rules_applied_block`, `feedback_agents_read_rule_docs_in_full`); design inputs `BD-200` backlog entry + `ARCHITECTURE-BD-195-ADD-CAPABILITY-SHIPPING.md` (full). CLAUDE.md `## Pack memory` was supplied in full via the session system context and read in full. | **COMPLIANT** |
| empirical-evidence-blocks | §8 EEB-1..EEB-14: each state-claim carries the actual command, captured verbatim output (counts/paths/lines), HEAD `972c3a1` + date 2026-06-03, interpretation, SUPPORTED conclusion. Every "the tree has X / NO X / will contain Y" claim in §1-§5 maps to a numbered EEB. | **COMPLIANT** |
| ci-guard-measure-then-bound | Measured FIRST before any guard claim: S4 copy logic (EEB-2), Check 47 membership-gate slice (EEB-8), `project-template/scripts/*` bulk-copy install-map note (EEB-7), `_SANCTIONED_PACK_SIDE_SHIPPED` frozen tuple (EEB-8). Categorized: no STRIP needed (the design adds NO pack-side-located shipped file); allowlist NOT widened — frozen 2-tuple untouched; §5 table verifies each guard stays green against the projected post-design tree. | **COMPLIANT** |
| dependency-direction-placement | §2 + §3 OQ-3: new script is a pure client deliverable → `project-template/scripts/`; sources conditional files from a client-local pool, never `$PACK`; does NOT qualify for and is NOT added to `_SANCTIONED_PACK_SIDE_SHIPPED` (EEB-8); pack-side `add-capability.sh` stays pack-side. No allowlist growth; sign-off requirement flagged as NOT triggered. | **COMPLIANT** |
| pack-project separation of concerns | §1.5 + §3 OQ-1: project-side script is a SEPARATE artifact, not a fork/fallback of the pack script; capability-table byte-overlap declared coincidence not shared-source contract; conditional-file source is the client-local pool (client SSOT), pack-internal `$PACK` paths declared inadmissible. | **COMPLIANT** |
| boundary / no-pack-self-in-project (P-missed-7) | §4.3 + §4.4: redesigned Procedure 6 and reworked references strip ALL pack-self tokens (no BD-NNN, no `maintenance-docs/`, no "from the pack", no BD-048, no capability-table-maintenance guidance); Check 43 named as the lock-step catch-net (§5). The design imports NO pack-style mechanism into client space. | **COMPLIANT** |
| preliminary-triage / architect-challenge (HIGH bar) | §1 + §3: the BD's own framing was challenged with evidence — "copy-all-skills" premise REJECTED as already-done (EEB-2/EEB-3); the real problem re-identified as the conditional-file pool; OQ-1 "fork/shared-core" hints rejected in favor of REPLACE with measured rationale; HIGH bar applied (boundary-with-existing-pack: Check 47/41/39, S9). Not rubber-stamped. | **COMPLIANT** |
| scope-deliverables-to-the-ask | Output leads with the recommended design; the three OQs are answered directly; no-op items surfaced in a fenced §7, not interleaved; no SUSPECTED/edge-case sprawl; guard ripple is a single table. | **COMPLIANT** |
| rules-applied-verification-block | This §9 table — per-rule name + quoted/measured evidence + COMPLIANT conclusion; no empty-evidence rows; no AMBIGUOUS terminal states. | **COMPLIANT** |
| agents-never-commit / preflight-stop-means-stop | Only read-only verbs used (`git rev-parse`, `find`, `grep`, `sed -n`, `wc`, `ls`) plus heredoc `cat >>` writing ONLY this design doc at the caller-specified path; no `git add/commit/push/tag`; no parent stop directive received; every state-claim backed by an EEB (no fabricated facts). | **COMPLIANT** |
