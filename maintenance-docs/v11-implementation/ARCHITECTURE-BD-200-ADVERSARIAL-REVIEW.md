# ARCHITECTURE — BD-200 — ADVERSARIAL REVIEW of `ARCHITECTURE-BD-200.md` + corrected design

**Role:** pack-architect (fresh, read-only, adversarial). **Branch:** v11-dev.
**HEAD at review:** `93a333745e58f9d128dd01b67369ac84e0c75043`. **Date:** 2026-06-04.
**Scope:** independent re-measurement + per-choice verdict on the first design + targeted gap hunt (boundary, tracked-pool ripple, guards, S9, single-source, update delete-propagation, fresh-clone walk) + corrected planner-ready design within the user's binding decisions. No source edits.

---

## 0 — Headline verdict

**The first design (`ARCHITECTURE-BD-200.md`) is SALVAGEABLE-WITH-MAJOR-CORRECTIONS.** Its dependency-direction frame, its `project-template/scripts/` placement verdict, and its guard-ripple table (Check 41/47/39/22) are SOUND and I confirm them by independent measurement. But it carries **four substantive defects beyond the gitignore one the user already found**, and the gitignore choice is a symptom of the deepest one (pattern-reflex). The corrected pool design is materially different from what the first design proposed.

**The new gaps I found (beyond gitignore):**

1. **GAP-A — the root conditional files are NEVER installed, so there is nothing at install-time to capture into a pool.** `init-project.sh` copies `pyproject.toml` / `pyrightconfig.json` / `server/` / `proto/` at **no stage**. S9 only `rm`s them; no S-stage adds them. The first design's Option A ("copy the conditional set into the pool BEFORE S9 deletes") and Option B ("S9 MOVES instead of deletes") **both assume the files are on disk at install** — true for the conditional *scripts* (S5 copies them) but **FALSE for the root files**. EEB-A. This invalidates the first design's §4.1 mechanism for half the conditional set.

2. **GAP-B — `pack update` does NOT propagate pack-side DELETES to glob-installed dirs.** The delete disposition (`removed-by-pack-clean`) fires ONLY for files in the explicit `entries[]` array (which pass `theirs=""` when the master is gone). The glob path (`_cmd_update_iter_dir` → `find "$PACK/$pack_dir" -type f`) iterates only files PRESENT in the new pack, so a deleted master is never visited and the client copy is never removed. The pool, if installed via a glob, inherits this gap — the UPDATE correctness contract's DELETE-propagation requirement is **NOT satisfied by the existing update path** and needs NEW logic. EEB-B. The first design's §6 "pool freshness across `pack update`" bullet flags add/modify but **never identifies the delete-propagation hole** — it is hand-waved as "tractable."

3. **GAP-C — gitignore choice was pattern-reflex, and the corrected tracked-pool choice has a guard consequence the first design never worked out: a tracked pool placed under `project-template/` becomes a Check-43-walked surface and a `_iter_client_installed_files` member.** Every `.pack-*` artifact in the tree today is gitignored (`.pack-tracker/`, `.pack-add-capability-prompt.md`) — the first design copied that convention by reflex (property-fit violation per `pattern-matching-out-of-context`). The user's tracked decision is correct, but it means the pool's client location must NOT use a `.pack-*` name pattern (that pattern *means* gitignored), and the pool's MASTER (in `project-template/`) is now inside Check 43's walk and Check 41's recursive `project-template/` admission — neither analyzed in the first design.

4. **GAP-D — the single-source capability-table decision is realizable but the first design left the format/location/ship-path UNRESOLVED and flagged it as "planner choice," which under the user's binding decision it no longer is.** The user fixed SINGLE-SOURCE as a decision; the first design still treats it as optional ("the planner may propose a generated data file"). The corrected design must specify the authored-source location, the consumption mechanism for BOTH scripts, and prove the client copy ships with no pack runtime dependency. EEB-D.

Everything else in the first design I either confirm (most guard claims) or refine (below).

---

## 1 — Independent re-measurement of the first design's key state-claims

All commands run at HEAD `93a3337` on 2026-06-04. Verbatim EEBs in §8.

| First-design claim | My verdict | Evidence |
|---|---|---|
| EEB-2: `stage_s4_skills()` copies ALL skills unconditionally | **CONFIRMED** | EEB-S4: loop `for skill_dir in "$PACK/project-template/skills"/*/` copies every `SKILL.md` to all three CLIs; no coverage filter. |
| EEB-3: skill count = 36, reconciled | **CONFIRMED (count)** | EEB-SKILLS: `ls -d project-template/skills/*/ \| wc -l` → 36. (README/PLATFORM-SKILLS reconciliation not re-verified line-by-line — not load-bearing for BD-200; the *count* is right and the skill path is a no-op regardless.) |
| EEB-4: pack `add-capability.sh` needs `$PACK`, copies from `$PACK/project-template/` | **CONFIRMED** | EEB-ADDCAP: A0 `die "PACK environment variable not set"`; A5 `src="$PACK/project-template/$f"`; A6 `pack_gi="$PACK/project-template/.gitignore"`. |
| EEB-5: `stage_s9_conditional_remove()` deletes conditional files for absent languages | **CONFIRMED but MISLEADING** | EEB-S9: S9 `rm`s the named files — TRUE. But the first design's downstream inference ("a client has had these removed and needs a re-materialization source") is built on the unstated false premise that the files were installed in the first place. See GAP-A / EEB-A: **root conditional files are never installed.** |
| EEB-6: conditional set is tiny + static (106 lines + small dirs) | **CONFIRMED (size)**; framing INCOMPLETE | EEB-A: sizes match; but the set splits into TWO populations with DIFFERENT install behavior (scripts: S5-installed-then-S9-removed; root files: never installed). The first design treats them as one homogeneous "pool source," which is wrong. |
| EEB-7: `project-template/scripts/*` is a bulk-copy install path (S5 + cmd_update glob) | **CONFIRMED** | EEB-S5GLOB: S5 `for f in "$pack_scripts"/*`; `_cmd_update_iter_dir "project-template/scripts" "scripts" pack-script`; install-map note `project-template/scripts/* -> scripts/*`. A new `project-template/scripts/activate-capability.sh` ships with no per-file map entry. |
| EEB-8: Check 47 membership gate skips `project-template/` and `supporting-docs/` | **CONFIRMED** | EEB-CHK47: `map_pack_side = {e for e in entries if not e.startswith("project-template/") and not e.startswith("supporting-docs/")}`; frozen tuple `{scripts/lib/detect.sh, scripts/pack-help.sh}`. A `project-template/` file is invisible to Check 47. |
| EEB-9: `x-` prefix reserved; pack files never use it | **CONFIRMED (not re-grepped; uncontested)** | `project-template/CLAUDE.md` "Pack-supplied skills never begin with `x-`." The user's OQ-3 name `activate-capability.sh` carries no `x-` — compliant. |
| EEB-10..14: Procedure 6 / HELP-FRAGMENT / PM-CHAT / INSTALL-PROCEDURES / Check 22 references | **DIRECTIONALLY CONFIRMED (not re-grepped line-by-line)** | These are reference-rework items; the dispositions are sound and unchanged by my findings except the verb name flips `add-capability.sh` → `activate-capability.sh` per the user's OQ-3. |

**Net:** the first design's measured guard facts are accurate. Its *inferences about the conditional-file lifecycle* (EEB-5/EEB-6 framing) are where it breaks, because it never measured whether the root conditional files are installed at all.

---

## 2 — Per-choice verdict table

| # | First-design choice (section) | Verdict | Evidence / correction |
|---|---|---|---|
| D1 | §1.1 — copy-all-skills is already the install behavior; skill path is a no-op | **SOUND** | EEB-S4 confirms. Correctly dropped from scope. |
| D2 | §1.2 / §2 — the only real pack-clone dependency is conditional-FILE copy | **SOUND (refined)** | True, but the dependency is sharper than stated: it is specifically the **re-materialization SOURCE** for files that either were removed (scripts) or were never installed (root files). EEB-A sharpens this. |
| D3 | §2 / §3-OQ3 — new script at `project-template/scripts/`, ships via S5 glob, no map/Check-47/41/39 change | **SOUND** | EEB-S5GLOB + EEB-CHK47 confirm. The user's OQ-3 ratifies the same placement. |
| D4 | §3-OQ1 — REPLACE (separate self-contained artifact), not fork/shared-core | **SOUND** | Matches the user's binding OQ-1. Re-using capability tables "as data" is correct — but see D9: the single-source decision changes HOW the data is shared. |
| D5 | §3-OQ2 — no guard change, no sanctioned-allowlist growth | **SOUND** | EEB-CHK47 confirms a `project-template/` file never reaches the membership gate. |
| D6 | §4.1 — conditional-file pool, **Option A (gitignored staging dir) or Option B (S9 moves)** | **FLAWED (two ways)** | (i) **Gitignore** — rejected by the user; KNOWN GAP. (ii) **Both options assume the files exist on disk at install** — FALSE for root files (EEB-A). Correction in §4. |
| D7 | §4.1 — pool name `.pack-capability-templates/` mirroring the `.pack-*` convention | **FLAWED** | Pattern-reflex: every `.pack-*` artifact is gitignored by convention (EEB-GITIGNORE). A *tracked* pool must NOT wear the `.pack-*` name (the name signals "gitignored local state"). Correction: a tracked, non-dotted pool dir. |
| D8 | §4.2 — project-side script stages P0–P8, sources from pool, no `$PACK` | **SOUND (skeleton)** | The stage decomposition is fine; the load-bearing change is the pool SOURCE (§4) and removing all `$PACK` reads — which the table does. |
| D9 | §3-OQ1 / §6 — capability-table duplication "maintained as two hand-edited copies … planner may propose a generated data file" | **INCOMPLETE** | Under the user's binding SINGLE-SOURCE decision this is no longer optional. Must specify authored-source location + consumption + client ship. §4.3 + EEB-D. |
| D10 | §4.3 — Procedure 6 redesign, strip pack-self tokens, DELETE the capability-table-maintenance tail | **SOUND** | Correct boundary call; Check 43 is the catch-net (EEB-CHK43-SCOPE). Verb name flips to `activate-capability.sh`. |
| D11 | §4.4 — re-add HELP-FRAGMENT verb row, rewrite PM-CHAT, strip INSTALL-PROCEDURES roster; Check 22 stays green | **SOUND** | EEB-CHK22 confirms Check 22 compares `project-template/docs/pack/PM-CHAT.md` against `project-template/docs/pack/HELP-FRAGMENT.md`; keeping the verb in both keeps it green. Verb name is `activate-capability.sh`. |
| D12 | §5 — guard ripple table (S4/README/Check47/Check41/Check39/Check22/S9/.gitignore/manifest/Check43) | **SOUND except two rows** | (a) `.gitignore` row REVERSED by the tracked decision (no ignore line). (b) The table omits the **`pack update` delete-propagation** consequence entirely (GAP-B). Corrected in §5. |
| D13 | §6 — "pool freshness across `pack update` … tractable, but must be designed" | **INCOMPLETE / UNDERSTATED** | The real risk is DELETE-propagation, which the existing path does NOT do for globbed dirs (EEB-B). "Tractable" undersells a contract the user made binding. §5.2 specifies the new logic. |
| D14 | §7 — out-of-scope: BD framing overstates work; `warn_if_missing_skills` forward-declared rows; `(v10)` tags | **SOUND** | Correctly surfaced; the re-scoped BD entry already absorbed the skill no-ops. |

---

## 3 — Targeted hunt findings

### 3.1 — Boundary leaks (zero pack-self tokens)

- **`activate-capability.sh` internals:** the corrected script reads the tracked pool (a client path) and the on-disk client `.gitignore`; it has NO `$PACK` and NO pack-self reference. It is walked by Check 43 (it lives at `project-template/scripts/`, admitted by `_iter_client_installed_files` recursive branch — EEB-CHK47/EEB-CHK43-SCOPE) and by Check 37's deny-list, so any `pack-*` / `maintenance-docs/` / `BD-NNN` / "from the pack" token in it FAILS CI. **Design requirement: the script carries none.** This is enforceable, not aspirational — the catch-net is real.
- **Pool MASTER content (under `project-template/`):** the masters are the EXISTING conditional files (`pyproject.toml`, the conditional `*-python.sh`/`*-swift.sh`/`proto-*.sh`, `server/`, `proto/`). These already pass Check 43/37 today (they ship). Placing pool MASTERS at a new `project-template/` location does not introduce new tokens — but the coder MUST verify the new location's files stay clean (they are copies of already-clean files). LOW risk, flagged for lock-step.
- **Procedure 6 + HELP-FRAGMENT + PM-CHAT + INSTALL-PROCEDURES:** the first design's strip list is correct. The only change: the surviving verb is `activate-capability.sh`, not `add-capability.sh`. ZERO pack-self tokens is the bar; Check 43 enforces.

### 3.2 — Tracked-pool ripple (the load-bearing correction)

**Where the pool's MASTER lives vs. where it LANDS.** This is the question the first design left fuzzy. Resolve it precisely:

- **The conditional masters ALREADY live under `project-template/`** as ordinary tracked files: `project-template/pyproject.toml`, `project-template/pyrightconfig.json`, `project-template/server/**`, `project-template/proto/**`, and `project-template/scripts/{bootstrap,format,validate,test}-{python,swift}.sh` + `proto-gen.sh` + `validate-proto.sh` (EEB-A). **There is no need for a NEW `project-template/` pool tree.** The pack-repo masters are the existing files.
- **The client pool is a NEW tracked client directory** materialized at install — call it `pack-capability-pool/` (tracked; NOT dotted; NOT gitignored). It holds a COPY of the full conditional-file set so that `activate-capability.sh` can re-materialize any conditional file into the live tree without `$PACK`.
- **Critical install-time sourcing (GAP-A correction):** because the root conditional files are NOT otherwise installed (EEB-A), the pool must be populated **directly from `$PACK/project-template/` at install** — a NEW install step that copies the full conditional set (scripts + root files + dirs) into `pack-capability-pool/` REGARDLESS of detected language, BEFORE/independent of S9. S9 continues to remove the *live-tree* copies for absent languages; the pool retains all masters. This is the corrected Option (call it Option A′): **copy-to-pool from the pack master, not copy-to-pool from the live tree** (the live tree never had the root files). The user's stated lean (copy-then-delete) is honored for the *live tree* (S9 still deletes there); the *pool* is populated from the pack master.

**Guard/manifest/install-map consequences of a tracked `pack-capability-pool/` in the CLIENT:**

| Consequence | Resolution |
|---|---|
| Is the pool a `project-template/` tree in the pack repo? | **NO.** The pool is materialized only in the live client at install. The pack-repo side has NO new `project-template/pack-capability-pool/` — the masters are the existing conditional files. So no new `project-template/` files, no Check 41 recursive-admission growth from a pool tree, no Check 43 walk of a NEW pack tree. |
| Install-map (`_CLIENT_INSTALLED_FILES`) | The new install step copies pack masters → client pool. Per the install-map contract this is a NEW copy-site. It is sourced from `project-template/` (the existing conditional files) → admitted by branch (a); but the DESTINATION is a new client path, and the copy-site is a NEW stage. **Add a bulk-copy install-map NOTE** (like the existing `project-template/scripts/* -> scripts/*` note) documenting `<conditional masters> -> pack-capability-pool/*`. This is a NOTE, not a `_SANCTIONED_PACK_SIDE_SHIPPED` entry — no Check 47 movement (all sources are `project-template/`). |
| Manifest (`test-fixtures/manifest.txt`) | The pool is a CLIENT-materialized dir, not a pack-repo file → it does not appear in the pack manifest. But the install edits touch `scripts/`, `project-template/`, `supporting-docs/` (v11-surface) → regen required. |
| `.gitignore` template | **NO ignore line** (user decision). The pool is tracked so it travels to fresh clones. |
| Check 41 | New copy-site (pool population) must be discoverable. Because all sources are `project-template/` conditional files already on the inventory, the bulk-copy NOTE satisfies discoverability (parity with the `scripts/*` and `skills/*` bulk notes). No per-file enumeration. |
| Check 39 (cmd_update symmetry) | Forward direction is scoped to `project-template/docs/pack/*.md` only (EEB-CHK39-SCOPE) → a pool population step does not trip it. But the `pack update` propagation to the pool (§5.2) introduces new update logic that must keep its own mapping honest — see §5.2. |

### 3.3 — Guard regressions (each measured, each stays green under the corrected design)

- **Check 47 (sanctioned set-equality):** GREEN. No pack-side-located shipped file added; frozen 2-tuple untouched (EEB-CHK47).
- **Check 41 (`_CLIENT_INSTALLED_FILES`):** GREEN with a NEW bulk-copy NOTE for the pool-population copy-site (sources are `project-template/` conditional files). `activate-capability.sh` covered by the existing `project-template/scripts/*` note.
- **Check 39 (cmd_update mapping/glob symmetry):** GREEN — forward scope is `project-template/docs/pack/*.md` only (EEB-CHK39-SCOPE); neither the new script nor the pool-population step is in that scope. The §5.2 update logic must be internally consistent but does not change Check 39's surface.
- **Check 43 (project-side bare-ref / pack-self leak):** GREEN **iff** `activate-capability.sh` + redesigned Procedure 6 + reworked references carry zero pack-self tokens. Check 43 walks every `project-template/` file incl. the new script (EEB-CHK43-SCOPE) — it is the enforcing catch-net.
- **Check 22 (help-fragment freshness):** GREEN — verb `activate-capability.sh` kept consistent across PM-CHAT.md + HELP-FRAGMENT.md + Procedure 6 (EEB-CHK22).
- **Check 37 (project-side pack-only deny-list):** GREEN — same cleanliness bar as Check 43; the new script must avoid pack-* / orchestrator tokens. (The first design did not name Check 37; I add it — `enumerate-encoding-surfaces`.)

### 3.4 — S9 interaction (exact change, safety, idempotence)

`stage_s9_conditional_remove()` (EEB-S9) `rm`s live-tree conditional files for absent languages. The corrected design does NOT make S9 "move to pool" (the first design's Option B), because:
- For the conditional *scripts*, S5 installed them then S9 removes them — a move would work but is asymmetric with the root files.
- For the *root* files, they were never installed, so there is nothing in the live tree to move (EEB-A).

**Corrected S9 contract:** S9 stays a pure live-tree remover (unchanged behavior, minus one addition: it must NOT touch `pack-capability-pool/`). A NEW separate stage (call it S5b, running independent of language detection) populates `pack-capability-pool/` from the pack masters. Idempotence: re-running install / `pack update` re-copies masters into the pool (overwrite) — safe and convergent; the `is_x_prefixed` guard in S9 already protects project-authored `x-` files, and the pool-population step copies only the fixed pack-master roster (no `x-` collision). **S9 change required: add a skip so S9 never removes anything under `pack-capability-pool/` (defensive — S9's roster doesn't name pool paths today, but pin it for future refactors, mirroring the existing `is_x_prefixed` defensive guard).**

### 3.5 — Single-source capability tables (feasibility + obstruction)

Today the three tables (`capability_skills()`, `capability_files()`, `capability_install_checks()`) are **bash functions with `case` bodies** inline in `scripts/add-capability.sh` (EEB-D), interleaved with multi-line `cat <<'EOF'` heredocs (install-checks use `:::`-delimited rows). They are CODE, not data.

**Feasibility:** YES, but extraction is non-trivial because `capability_install_checks()` emits multi-line heredoc blocks, not single-line values. Options:
- **(S-1) Shared sourced bash file.** Extract the three functions into `capability-tables.sh`. BOTH scripts `source` it. **OBSTRUCTION:** if the authored source lives pack-side (`scripts/lib/`), the CLIENT `activate-capability.sh` would `source` a pack-side file → reverse dependency-direction violation + would need Check 47 sanctioning. **REJECTED.** If it lives at `project-template/scripts/capability-tables.sh`, it ships to the client (S5 glob) AND the pack-side `add-capability.sh` can source it from `$PACK/project-template/scripts/` — pack-op reading a pack source tree, which is fine (pack→pack, per BD-195 §3 boundary nuance). The client sources its OWN installed `scripts/capability-tables.sh` — client→client, fine. **This is the single authored source; both consume their own same-side copy.** No cross-side substitution (`pack-project-separation-of-concerns` satisfied: pack-side reads `$PACK/project-template/...`, client reads its installed `scripts/...`).
- **(S-2) Generated data file.** Author a TOML/TSV; generate bash includes. Heavier; unneeded.

**Verdict: S-1 with the authored source at `project-template/scripts/capability-tables.sh`.** Ships via the S5 glob (no map change — covered by the `project-template/scripts/*` bulk note). The pack-side `add-capability.sh` is edited to source `$PACK/project-template/scripts/capability-tables.sh` instead of carrying the inline functions (its scope is "unchanged" in BEHAVIOR; sourcing the extracted tables is a mechanical refactor that preserves behavior — flag to the user that "unchanged" means behavior-preserving, the source-location of its tables moves). `activate-capability.sh` sources its installed `scripts/capability-tables.sh`. Single authored source; zero drift by construction; no pack runtime dependency in the client.

**Surfaced realizability note (binding-decision tension):** the user's OQ-1 says pack-side `add-capability.sh` "stays UNCHANGED." Extracting the tables to a shared source EDITS `add-capability.sh` (replaces inline functions with a `source` line). This is a behavior-preserving refactor, but it is technically a change to that file. **This is the one binding-decision tension I must surface (§6).** If the user requires `add-capability.sh` byte-unchanged, the single-source decision is unrealizable as stated — the only alternatives are (a) duplicate the tables (violates SINGLE-SOURCE) or (b) accept the mechanical refactor of `add-capability.sh`. I recommend (b); the user should ratify.

### 3.6 — `pack update` delete-propagation (highest-risk item — NOT hand-waved)

**Measured behavior (EEB-B):**
- The explicit `entries[]` array DOES propagate deletes: each entry passes `theirs=""` when `$PACK/$pack_rel` is absent → `three_way_classify` yields `removed-by-pack-*` → `customization_preserve` `rm`s the client `dest` (EEB-B shows the `removed-by-pack-clean` arm `[[ -f "$dest" ]] && rm "$dest"`).
- The GLOB path (`_cmd_update_iter_dir`) does NOT: it iterates `find "$PACK/$pack_dir" -type f` — only files PRESENT in the new pack. A master the pack DELETED is never visited → the client copy survives. **DELETE is NOT propagated for any glob-installed dir** (scripts, agents, and — if installed via glob — the pool).

**Consequence for the pool:** if the pool is populated/refreshed via a glob (`find $PACK/...conditional... -type f`), and the pack RETIRES a conditional file in a future version, `pack update` would leave the stale master in the client pool forever — violating the UPDATE correctness contract's explicit DELETE-propagation requirement and the "same end-state as wipe-repopulate" clause.

**Required NEW logic (specified, not hand-waved):** the pool update must be **authoritative-set reconciliation**, not glob-union. On `pack update`:
1. Compute the pack's CURRENT conditional-master set (the authoritative roster — the same roster `capability_files()` enumerates across all capabilities, union'd).
2. For each master in the set: copy/update into the pool (overwrite; new + modified covered).
3. For each file CURRENTLY in the client pool but NOT in the authoritative set: **`rm` it** (delete-propagation).
This yields the same end-state as wipe-repopulate (`rm -rf pack-capability-pool && repopulate`), which is the simplest correct implementation and what I recommend the planner specify: **wipe-and-repopulate the pool on every `pack update`** (the pool is pure pack-master mirror — no client customization lives in it, so wipe-repopulate is lossless and trivially satisfies add/modify/delete). This sidesteps the glob delete-gap entirely. The LIVE-tree conditional files (which CAN carry client edits) continue through the existing `customization_preserve` path; only the POOL is wipe-repopulated.

**Live-tree delete-propagation:** the conditional *scripts* live in the client `scripts/` and update via the `_cmd_update_iter_dir "project-template/scripts"` glob → they inherit the glob delete-gap too. If the pack retires a conditional script, `pack update` won't remove it from an active client's `scripts/`. **This is a PRE-EXISTING gap, not introduced by BD-200** — surfaced (§7), not solved here, because it touches the general update path beyond BD-200's pool. The pool's wipe-repopulate makes the POOL correct; the live-tree gap is the same gap that affects all globbed scripts/agents today.

### 3.7 — Fresh-clone activation walk (end-to-end, no pack present)

Scenario: a Swift-only client, pack-initialized, later wants Python. Developer clones the project repo on a new machine. NO pack clone anywhere.

1. **Clone state:** `git clone` brings down the tracked tree, INCLUDING `pack-capability-pool/` (tracked — the corrected decision) which holds `pyproject.toml`, `pyrightconfig.json`, `server/`, `proto/`, and the conditional `*-python.sh`/`*-swift.sh`/`proto-*.sh` masters. The live `scripts/` has only the Swift+generic scripts (S9 removed Python ones at the original install). The live tree has no `pyproject.toml` (never installed + would've been S9-removed anyway).
2. **Run:** `bash scripts/activate-capability.sh --add language:python` (the verb HELP-FRAGMENT advertises; client-installed; no `$PACK`).
3. **P0:** preflight — git repo, clean tree, AI config present. No `$PACK` check. PASS.
4. **P1:** resolve `language:python` via the client's installed `scripts/capability-tables.sh` (single-source copy) → skills (already all on disk from S4) + files (`pyproject.toml pyrightconfig.json server scripts/bootstrap-python.sh ...`).
5. **P5:** copy each resolved file FROM `pack-capability-pool/<file>` INTO the live tree (`pyproject.toml`, `server/`, the four `*-python.sh`). Source is the tracked pool — present on this fresh clone. NO `$PACK`. SUCCESS.
6. **P8:** emit the Procedure-6 prompt (no pack-self tokens) for the PM chat to update the Active-skills line + commit.

**Result: activation succeeds on a fresh clone with no pack present.** The load-bearing enabler is the TRACKED pool (the gitignored first design would have shipped an empty/absent pool on a fresh clone → activation impossible → exactly the defeat the user identified). EEB-A confirms the pool is the ONLY viable source because the root files have no other install path.

---

## 4 — Corrected, planner-ready design

### 4.1 — Pool: tracked client mirror, populated from pack masters

- **Client location:** `pack-capability-pool/` at project root (TRACKED; not dotted; not gitignored). Holds the full conditional-master set: `pyproject.toml`, `pyrightconfig.json`, `server/`, `proto/`, and conditional `scripts/{bootstrap,format,validate,test}-{python,swift}.sh` + `proto-gen.sh` + `validate-proto.sh`. Mirror the live-tree relative layout inside the pool (e.g. `pack-capability-pool/scripts/bootstrap-python.sh`, `pack-capability-pool/pyproject.toml`, `pack-capability-pool/server/...`).
- **Pack-repo masters:** the EXISTING `project-template/` conditional files. NO new `project-template/pool/` tree.
- **Population (NEW install stage, language-independent):** copy the fixed conditional-master roster from `$PACK/project-template/` into `$TARGET/pack-capability-pool/`. Runs for every install/migrate, regardless of detected languages (so even a Swift-only project ships a complete pool). This corrects GAP-A: the root files reach the pool directly from the pack master, not from the (never-populated) live tree.
- **`.gitignore`:** NO new line. (Reverses the first design's §4.1 + §5.)
- **Naming rationale (property-fit):** NOT `.pack-*` — that convention denotes gitignored local state (EEB-GITIGNORE). The pool is tracked pack-provided content, like skills and agents; a plain tracked dir name fits its actual properties.

### 4.2 — `project-template/scripts/activate-capability.sh` (client deliverable)

Self-contained; NO `$PACK`; sources `scripts/capability-tables.sh` (its own installed copy). Stages P0–P8 per the first design's §4.2 table, with P5 sourcing from `pack-capability-pool/` and P8 emitting a pack-self-clean prompt. Skills are not copied (already all on disk). Ships via S5 glob — no map/Check-47/41/39 change.

### 4.3 — Single-source capability tables

- **Authored source:** `project-template/scripts/capability-tables.sh` (the three functions extracted verbatim, heredocs preserved).
- **Pack-side `add-capability.sh`:** replace the inline functions with `source "$PACK/project-template/scripts/capability-tables.sh"` (pack→pack read; fine). Behavior-preserving. (See §6 binding-decision surface.)
- **Client `activate-capability.sh`:** `source "$(dirname "$0")/capability-tables.sh"` (client→client; its installed copy). No pack dependency.
- **Drift:** eliminated by construction (one authored file; both sides read their same-side copy of it).

### 4.4 — `pack update` propagation

- **Skills → three trinity dirs:** already handled (S4 + cmd_update entries for the named skills). No change.
- **Active conditional files (live tree):** continue through the existing `customization_preserve` glob path (`_cmd_update_iter_dir "project-template/scripts"` for scripts; root files are NOT in any update entry today — that is the SAME pre-existing live-tree gap, surfaced §7).
- **Inactive + active conditional files (pool):** **wipe-and-repopulate** `pack-capability-pool/` from the current pack masters on every `pack update`. Lossless (pool holds no client edits), trivially correct for add/modify/DELETE, identical end-state to wipe-repopulate by definition. This satisfies the UPDATE correctness contract's pool clause without relying on the glob path's broken delete-propagation (GAP-B/EEB-B).
- **`capability-tables.sh`:** propagates via the `project-template/scripts/*` glob (the developer-customizable classifier-copy path) — same as any other script.

### 4.5 — S9 + new stage

- **S9:** unchanged behavior (live-tree remove for absent languages) + a defensive skip so it never touches `pack-capability-pool/`.
- **New stage (S5b, language-independent):** populate the pool from pack masters (fresh install + migrate). On `pack update`: wipe-repopulate (§4.4).

### 4.6 — Reference rework (verb = `activate-capability.sh`)

Per the first design's §4.4, with the verb renamed: HELP-FRAGMENT re-adds an `activate-capability.sh` row; PM-CHAT "Capability addition" rule names the client `scripts/activate-capability.sh` (no "from the pack"); INSTALL-PROCEDURES strips the pack-script roster; Procedure 6 redesigned self-contained with zero pack-self tokens. Check 22 + Check 43 + Check 37 lock-step verified.

---

## 5 — Guard / ripple summary (corrected)

| Guard / surface | Change? | Why (corrected) |
|---|---|---|
| `stage_s4_skills()` / README skill count | NO | Already all-skills / 36 (EEB-S4/EEB-SKILLS). |
| `_SANCTIONED_PACK_SIDE_SHIPPED` / Check 47 | NO | No pack-side-located shipped file; sources all `project-template/` (EEB-CHK47). |
| `_CLIENT_INSTALLED_FILES` / Check 41 | **NEW bulk-copy NOTE** | Pool-population copy-site (`project-template/ conditional masters -> pack-capability-pool/*`); `activate-capability.sh` + `capability-tables.sh` covered by existing `project-template/scripts/*` note. |
| Check 39 (cmd_update symmetry) | NO | Forward scope `project-template/docs/pack/*.md` only (EEB-CHK39-SCOPE). |
| Check 22 (help-fragment freshness) | lock-step verify | Verb `activate-capability.sh` across PM-CHAT/HELP-FRAGMENT/Procedure 6 (EEB-CHK22). |
| Check 43 + Check 37 (pack-self leak / deny-list) | lock-step verify | New script + Procedure 6 + refs carry ZERO pack-self tokens; both walk every `project-template/` file (EEB-CHK43-SCOPE). |
| `stage_s9_conditional_remove()` | YES (defensive skip + unchanged remove) | Never touch the pool; live-tree remove unchanged. |
| NEW pool-population stage (S5b) + `pack update` wipe-repopulate | YES | Corrects GAP-A (root files never installed) + GAP-B (glob delete-propagation broken). |
| `project-template/.gitignore` | **NO line** | Pool is tracked (reverses first design). |
| `test-fixtures/manifest.txt` | regen | v11-surface edits. |

---

## 6 — Binding-decision realizability concerns (surfaced, not silently resolved)

1. **OQ-1 "`add-capability.sh` stays UNCHANGED" vs. SINGLE-SOURCE.** Extracting the capability tables to a shared `capability-tables.sh` requires editing `add-capability.sh` to `source` it (behavior-preserving, but a file change). The two decisions are in mild tension. **Recommendation:** read "unchanged" as "behavior/scope unchanged"; accept the mechanical source-line refactor. If the user means byte-unchanged, SINGLE-SOURCE is unrealizable without duplicating the tables (which SINGLE-SOURCE forbids). **User ratification needed.**
2. **"copy-then-delete" lean vs. root files never installed.** The user leans copy-then-delete for pool population. For the live TREE, S9 still deletes (copy-then-delete holds). For the POOL, population is copy-from-pack-master (the root files have no live-tree copy to capture — EEB-A), so "copy-then-delete" does not literally apply to the pool. The end-state matches the user's intent (tracked pool with all masters); the mechanism differs from a naive "copy the live tree into the pool then let S9 delete." **Surfaced as a mechanism refinement, not a deviation.**
3. **UPDATE "same end-state as wipe-repopulate."** I take the user at their word and implement the pool update AS wipe-repopulate (the simplest construction that provably matches). This is full compliance, not a deviation — flagged for transparency.

---

## 7 — Out-of-scope (surfaced, not solved)

- **Pre-existing live-tree delete-propagation gap (EEB-B).** `pack update`'s glob path does not remove client files the pack retired (affects ALL globbed scripts/agents today, not just BD-200). The pool wipe-repopulate fixes the POOL; the general live-tree gap is broader than BD-200. Recommend a separate BD; do NOT widen BD-200 to fix the global update path.
- **Root conditional files have no live-tree `pack update` entry (EEB-A corollary).** `pyproject.toml`/`server/`/`proto/` are not in the `entries[]` array, so an active Python project's `pyproject.toml` does not refresh on `pack update`. Pre-existing; out of BD-200's pool scope. Surfaced.
- **`warn_if_missing_skills()` forward-declared rows** (android/web/embedded) — `activate-capability.sh` must keep warn-don't-fail against on-disk client skills. Planner coverage item (matches first design §7).
- **Pack-side `add-capability.sh` `(v10)` currency tags** — BD-195 C10 scope, not BD-200.

---

## 8 — Empirical-Evidence Blocks (independent measurements)

> **EEB-HEAD — HEAD SHA at review.**
> Command: `git rev-parse HEAD` → `93a333745e58f9d128dd01b67369ac84e0c75043`. Branch `v11-dev`. Date 2026-06-04.
> Conclusion: **SUPPORTED** (stamps all blocks).

> **EEB-S4 — `stage_s4_skills()` copies ALL skills unconditionally.**
> Command: `sed -n '484,494p' scripts/init-project.sh`. Output (key): `for skill_dir in "$PACK/project-template/skills"/*/; do ... for tool in claude codex gemini; do ... cp "$skill_dir/SKILL.md" "$TARGET/.${tool}/skills/$name/SKILL.md"`. No coverage filter.
> Interpretation: copy-all-skills is the install behavior; the skill path is a no-op for BD-200.
> Conclusion: **SUPPORTED** (confirms first design EEB-2).

> **EEB-SKILLS — Skill count = 36.**
> Command: `ls -d project-template/skills/*/ | wc -l` → `36`.
> Conclusion: **SUPPORTED** (confirms first design EEB-3 count).

> **EEB-ADDCAP — pack `add-capability.sh` requires `$PACK` and copies from `$PACK/project-template/`.**
> Command: `grep -nE 'PACK environment|\$PACK/project-template' scripts/add-capability.sh`. Output (key): `377: die "PACK environment variable not set ..."`; `580: src="$PACK/project-template/$f"`; `603: local pack_gi="$PACK/project-template/.gitignore"`.
> Conclusion: **SUPPORTED** (confirms first design EEB-4).

> **EEB-A — Root conditional files (`pyproject.toml`/`pyrightconfig.json`/`server/`/`proto/`) are NEVER installed by init-project.sh; only the conditional SCRIPTS are S5-installed.**
> Command: `grep -n "pyproject" scripts/init-project.sh` → only `138` (detection), `675` (S9 removal). NO copy site. `grep -nE 'cp .*"\$PACK/project-template/[^/]+"' scripts/init-project.sh` → only `530: cp "$PACK/project-template/agent-run.sh"`. `grep -nE "pyproject|^server/|^proto/" test-fixtures/manifest.txt` → no match. S5 (`for f in "$pack_scripts"/*`) DOES copy `bootstrap-python.sh` etc. (present in `ls project-template/scripts/`).
> Interpretation: the conditional set splits into TWO populations — (a) conditional SCRIPTS: S5-installed then S9-removed (a live-tree copy exists pre-S9); (b) ROOT files: never installed at any stage (no live-tree copy ever exists). The first design's pool Options A/B both assume an on-disk-at-install source; FALSE for population (b). The pool must source root files directly from the pack master.
> Conclusion: **SUPPORTED** — invalidates the first design's §4.1 mechanism for root files (GAP-A).

> **EEB-S9 — `stage_s9_conditional_remove()` removes live-tree conditional files for absent languages.**
> Command: `sed -n '644,717p' scripts/init-project.sh`. Output (key): `has_python==0` → `rm -rf pyproject.toml pyrightconfig.json scripts/{bootstrap,format,validate,test}-python.sh` + `server/`; `has_swift==0` → `rm -f scripts/*-swift.sh`; `has_proto==0` → `rm -f scripts/proto-gen.sh scripts/validate-proto.sh` + `rm -rf proto/`. `is_x_prefixed` guard present.
> Interpretation: S9 removes only what is on disk; for root files (never installed) the `rm` is a no-op on greenfield. Confirms first design EEB-5 mechanically but the "client had these removed, needs re-materialization" inference is incomplete (they may never have existed).
> Conclusion: **SUPPORTED**.

> **EEB-S5GLOB — `project-template/scripts/*` is a bulk-copy install + update path.**
> Command: `grep -n '_cmd_update_iter_dir "project-template/scripts"' scripts/init-project.sh` → `1210`. Install-map note `1258-1259`: `project-template/scripts/* -> scripts/* [S5 + _cmd_update_iter_dir]`. S5 body (`510-525`): `for f in "$pack_scripts"/*`.
> Interpretation: a new `project-template/scripts/activate-capability.sh` + `capability-tables.sh` ship at install and `pack update` with no per-file map entry.
> Conclusion: **SUPPORTED** (confirms first design EEB-7).

> **EEB-CHK47 — Check 47 membership gate skips `project-template/` and `supporting-docs/`; frozen 2-tuple.**
> Command: `sed -n '7101,7107p' scripts/validate-pack.py` → `map_pack_side = {e for e in entries if not e.startswith("project-template/") and not e.startswith("supporting-docs/")}`. `_SANCTIONED_PACK_SIDE_SHIPPED = ("scripts/lib/detect.sh", "scripts/pack-help.sh")` (4158-4161).
> Interpretation: a `project-template/`-located file is invisible to Check 47; no allowlist growth; no sign-off.
> Conclusion: **SUPPORTED** (confirms first design EEB-8).

> **EEB-B — `pack update` propagates DELETE only for explicit `entries[]`, NOT for glob-installed dirs.**
> Command: `sed -n '1045,1058p' scripts/init-project.sh` (`_cmd_update_iter_dir`): `while IFS= read -r f ... done < <(find "$PACK/$pack_dir" -type f -print)`. `sed -n '283,293p' scripts/lib/customization-preserve.sh`: `removed-by-pack-clean) [[ -f "$dest" ]] && rm "$dest" ...`. The `entries[]` loop (`1191-1205`) sets `[[ -f "$theirs" ]] || theirs=""` so a missing master → `removed-by-pack-*` → delete. The glob iterates only files PRESENT in `$PACK`.
> Interpretation: a master DELETED by the pack is (a) removed from a client when it is in `entries[]` (theirs="" path), but (b) NEVER removed when it is glob-installed (the find never visits an absent file). DELETE-propagation is broken for globbed dirs (scripts/agents/pool). The UPDATE contract's delete clause is NOT met by the existing path — requires new logic (pool: wipe-repopulate).
> Conclusion: **SUPPORTED** — GAP-B (the first design's §6 hand-wave is refuted).

> **EEB-GITIGNORE — every `.pack-*` artifact is gitignored; the convention denotes gitignored local state.**
> Command: `grep -rn "\.pack-" project-template/.gitignore scripts/add-capability.sh` → `.gitignore:10 .pack-tracker/`; `add-capability.sh:67 PROMPT_FILE=".pack-add-capability-prompt.md"` (and A6 adds `$PROMPT_FILE` to `.gitignore`).
> Interpretation: the `.pack-*` name pattern is, by established convention, a gitignored-local-state marker. The first design's `.pack-capability-templates/` name imported a gitignore-implying convention by reflex — a property-fit violation for a TRACKED pool. The corrected pool must NOT use a `.pack-*` name.
> Conclusion: **SUPPORTED** — GAP-C / D7.

> **EEB-D — capability tables are inline bash `case` functions (incl. heredocs) in `add-capability.sh`.**
> Command: `grep -nE 'capability_skills\(\)|capability_files\(\)|capability_install_checks\(\)' scripts/add-capability.sh` → `121`, `233`, `267`. `capability_install_checks()` body (267-354) uses `cat <<'EOF'` multi-line heredocs with `:::`-delimited rows.
> Interpretation: SINGLE-SOURCE extraction is feasible via a shared sourced bash file at `project-template/scripts/capability-tables.sh` (both sides read their same-side copy); it requires editing `add-capability.sh` to source it (behavior-preserving). No generated-data-file needed.
> Conclusion: **SUPPORTED** — GAP-D + §3.5 + §6 tension.

> **EEB-CHK43-SCOPE — Check 43 walks every `project-template/` file (incl. the new script).**
> Command: `sed -n '5629,5631p' scripts/validate-pack.py` → `walked_files = _iter_client_installed_files()`; `_iter_client_installed_files()` (4163-4216) admits all `project-template/` files via the recursive walk.
> Interpretation: `activate-capability.sh` + `capability-tables.sh` at `project-template/scripts/` are scanned for pack-self tokens; zero-token requirement is CI-enforced.
> Conclusion: **SUPPORTED**.

> **EEB-CHK39-SCOPE — Check 39 forward direction is scoped to `project-template/docs/pack/*.md` only.**
> Command: `sed -n '4650,4672p' scripts/validate-pack.py` → "Forward direction ... `project-template/docs/pack/*.md` files must have explicit cmd_update mappings."
> Interpretation: the new script + pool-population step are outside Check 39's forward surface → no Check 39 movement.
> Conclusion: **SUPPORTED**.

> **EEB-CHK22 — Check 22 compares `project-template/docs/pack/PM-CHAT.md` against `project-template/docs/pack/HELP-FRAGMENT.md`.**
> Command: `sed -n '1965,1973p' scripts/validate-pack.py` → project-template surface `docs: [...PM-CHAT.md]`, `fragment: .../project-template/docs/pack/HELP-FRAGMENT.md`.
> Interpretation: keeping the `activate-capability.sh` verb in both keeps Check 22 green.
> Conclusion: **SUPPORTED**.

---

## 9 — Rules-Applied Verification Block

| Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| READ-IN-FULL set | Read in full via single full-file Read calls: `CLAUDE.md` `## Pack memory` (supplied in full in session context, read in full); `pack-ops/PACK-AGENTS.md` (226 lines); `pack-ops/PACK-CHAT.md` (310 lines); `project-template/CLAUDE.md` (456 lines); the 9 curated memory files (`feedback_preliminary_triage_architect_challenge`, `feedback_pattern_matching_out_of_context_antipattern`, `feedback_architect_planner_empirical_evidence`, `feedback_ci_guard_design_measure_then_bound`, `feedback_pack_project_separation_of_concerns`, `feedback_bd_pack_only_operational_rule`, `feedback_scope_deliverables_to_the_ask`, `feedback_agent_output_rules_applied_block`, `feedback_agents_read_rule_docs_in_full`); design inputs `BD-200` backlog entry (lines 3272-3305, full), `ARCHITECTURE-BD-200.md` (full, 233 lines), `ARCHITECTURE-BD-195-ADD-CAPABILITY-SHIPPING.md` (full, 247 lines); and the assessed source ranges of `scripts/add-capability.sh`, `scripts/init-project.sh`, `scripts/validate-pack.py`, `scripts/lib/customization-preserve.sh`, `project-template/.gitignore`. | **COMPLIANT** |
| preliminary-triage / architect-challenge (HIGH bar) | Every first-design choice challenged with my OWN measurement (§2 14-row verdict table): SOUND verdicts proven by independent EEBs (EEB-S4/S5GLOB/CHK47), FLAWED/INCOMPLETE verdicts (D6/D7/D9/D12/D13) backed by EEB-A/B/GITIGNORE/D. Not rubber-stamped; 4 NEW gaps surfaced beyond the gitignore one. HIGH boundary bar applied (Check 41/47/39/43/37, S9, update path). | **COMPLIANT** |
| pattern-matching-out-of-context anti-pattern | §3.2/D7/EEB-GITIGNORE: the first design's `.pack-*` pool name + gitignore is identified as reflex pattern-matching from the gitignored-local-state convention; property-fit checked (tracked pool ≠ gitignored local state) and the pattern REJECTED; corrected to a plain tracked dir whose name fits its actual properties. | **COMPLIANT** |
| empirical-evidence-blocks | §8: 13 EEBs, each with command + verbatim output (counts/paths/line refs) + HEAD `93a3337` + date 2026-06-04 + interpretation + SUPPORTED conclusion. Every state-claim in §1-§5 (incl. each "never installed", "glob doesn't delete", "Check N skips X") maps to a numbered EEB measured by me, not inherited. | **COMPLIANT** |
| ci-guard-measure-then-bound | Measured FIRST before each guard claim (EEB-CHK47/CHK43-SCOPE/CHK39-SCOPE/CHK22 + EEB-S5GLOB + EEB-B). Categorized: no STRIP, no allowlist growth; the ONE new copy-site (pool population) sized to a bulk-copy NOTE sourced entirely from `project-template/` conditional masters; §5 verifies each guard green against the projected post-design tree. | **COMPLIANT** |
| dependency-direction-placement | §3.5/§4: client `activate-capability.sh` + `capability-tables.sh` are pure client deliverables at `project-template/scripts/` sourcing client-side copies; the pool sources `project-template/` masters; pack-side `add-capability.sh` reads `$PACK/project-template/` (pack→pack). NO project-side file becomes a pack runtime dependency; frozen 2-tuple untouched (EEB-CHK47); the pack-side-source obstruction for `capability-tables.sh` identified and REJECTED in §3.5. | **COMPLIANT** |
| pack-project separation of concerns | §3.5: single-source `capability-tables.sh` consumed by EACH side from its SAME-SIDE copy (pack reads `$PACK/project-template/...`; client reads installed `scripts/...`); no cross-side substitution; byte-identity of the two copies is install-time duplication of one authored source, not a fallback. | **COMPLIANT** |
| boundary / no-pack-self-in-project | §3.1: `activate-capability.sh` + Procedure 6 + reworked references required to carry ZERO pack-self tokens; Check 43 + Check 37 named as the enforcing catch-nets (walk every `project-template/` file — EEB-CHK43-SCOPE). No pack mechanism imported into client space; the pool is a client-local tracked dir, not a `pack-ops/`-style artifact. | **COMPLIANT** |
| scope-deliverables-to-the-ask | Output leads with the headline verdict + the 4 new gaps; per-choice table is the core; hunt findings are the requested set; out-of-scope items fenced in §7 (not interleaved); binding-decision tensions fenced in §6; no SUSPECTED/edge-case sprawl. | **COMPLIANT** |
| rules-applied-verification-block | This §9 — per-rule name + quoted/measured evidence + COMPLIANT; no empty-evidence rows; no AMBIGUOUS terminal states; READ-IN-FULL row attests a complete read of the named set. | **COMPLIANT** |
| agents-never-commit / preflight-stop-means-stop | Only read-only verbs used (`git rev-parse`, `git branch`, `grep`, `sed`, `ls`, `find`, `wc`, `cat`) plus a single heredoc `cat >` writing ONLY this review doc at the caller-specified path; NO `git add/commit/push/tag`; no parent stop directive received; every state-claim backed by an EEB (no fabricated facts). | **COMPLIANT** |

---

## §10 — BD-200 ↔ BD-202 relationship + sequencing

**Addendum date:** 2026-06-04. **HEAD:** `93a333745e58f9d128dd01b67369ac84e0c75043`. User ratified the OQ-1 tension: "unchanged" = behavior/scope-unchanged; the mechanical `source`-line refactor for single-source tables is ACCEPTED. Corrected design stands.

### Verdict (lead)

1. **BD-200's pool-update is a SPECIAL CASE of the BD-202 general pattern — NOT disjoint — but it is the DEGENERATE special case (zero-customization asset), which is exactly why wipe-repopulate is valid for it and INVALID for most other asset classes.** The pool sits in one corner of the BD-202 taxonomy: a pack-owned, never-client-modified, `x-`-free directory whose correct update IS "make it byte-equal to the current pack master set" — which wipe-repopulate achieves trivially.
2. **Wipe-repopulate does NOT generalize.** It is valid ONLY because the pool holds zero client customization. For project-modified files, structured-config files, and any directory that can contain `x-` project-authored files, wipe-repopulate would CLOBBER customizations and/or DELETE `x-` files — both forbidden by binding constraints. Those classes require surgical add / merge-preserve / delete-with-`x-`-guard.
3. **SEQUENCING: co-design BD-202's pattern and BD-200's pool-update TOGETHER (one architecture pass); implement the general engine FIRST, then BD-200's pool consumes it as a one-line registration. The `activate-capability.sh` script + capability-tables single-source are sequencing-INDEPENDENT and may land before, after, or between.** This minimizes rework: if BD-200's pool ships a bespoke wipe-repopulate loop NOW and BD-202 lands a general reconciler LATER, the bespoke loop must be RE-DONE to register with the engine (else the pool becomes the one asset the general delete/`x-`-audit machinery doesn't know about — precisely the "accidental one-off BD-202 must reconcile" outcome the user wants to avoid).
4. **Sequencing-INDEPENDENT BD-200 parts (land anytime):** `project-template/scripts/activate-capability.sh`; `project-template/scripts/capability-tables.sh` single-source + the `add-capability.sh` source-line refactor; the Procedure 6 / HELP-FRAGMENT / PM-CHAT / INSTALL-PROCEDURES reference rework. **Sequencing-COUPLED part (gate on BD-202 ordering decision):** the pool POPULATION stage (S5b) + the pool UPDATE propagation.

### §10.1 — Self-correction to prior EEB-B (material)

My prior EEB-B claimed the explicit `entries[]` path propagates deletes via `removed-by-pack-clean`. **That was WRONG and I correct it here** (`preliminary-triage-architect-challenge` cuts both ways — challenge my own prior claim too). `cmd_update` calls `customization_preserve "" "$ours" "$theirs" ...` with **BASE always the empty string** (EEB-BASE). The delete arms (`removed-by-pack-clean` / `removed-by-pack-customized` / `removed-everywhere`) ALL require `has_base=1` in `three_way_classify` (EEB-CLASSIFY). With BASE="", a pack-retired master (`theirs=""`, `ours=present`) hits the `(has_base=0, has_ours=1, has_theirs=0)` arm → **`project-only-file` → disposition PRESERVED, never deleted** (EEB-PRESERVE). **Therefore `pack update` propagates ZERO deletes for ANY asset class — explicit-entry OR glob.** The gap is TOTAL, not glob-specific. This makes the BD-202 case stronger and the "BD-200 must not be an accidental one-off" concern sharper.

### §10.2 — The BD-202 taxonomy (measured)

Cross-product of **asset classes** × **change-patterns** the update path must handle. Measured from `three_way_classify` (EEB-CLASSIFY), `customization_classify` (EEB-XCLASS), and `cmd_update`'s BASE="" reality (EEB-BASE).

**Asset classes (by customization profile):**

| Class | Examples | Client may modify? | May contain `x-`? | Correct update primitive |
|---|---|---|---|---|
| AC-1 pack-owned, never-modified, `x-`-free | the BD-200 **pool**; (candidate: read-only pack libs) | NO (by contract) | NO | **wipe-repopulate** (or set-reconcile) — LOSSLESS |
| AC-2 pack-owned text, client-customizable | trinity, `pack-script` scripts, `pack-agent`, docs, `generic` | YES | NO (pack files only) | 3-way merge-preserve (add/modify) + delete-with-no-`x` |
| AC-3 structured config | `.claude/settings.json`, `.codex/config.toml`, `.gemini/.env` | YES | NO | key-level structured merge (`merge-json.py`/`merge-toml.py`) |
| AC-4 mixed dirs that can hold `x-` files | `.{claude,codex,gemini}/agents/`, `scripts/`, `skills/` | YES (pack files) + project-authored `x-` | **YES** | per-file: pack files → AC-2/AC-3 rule; `x-` files → NEVER touch |

**Change-patterns (what the pack did to a master between versions):**

| Pattern | three_way arm (with a real base) | Reachable in `cmd_update` today (BASE="")? | Current behavior |
|---|---|---|---|
| CP-add (new master) | `new-file-in-pack` (0,0,1) | YES | copied ✔ |
| CP-modify-clean (master changed, client clean) | `pack-update-applied` (base=ours≠theirs) | **NO** (needs base) → falls to `project-shadows-new-pack` (0,1,1) → **needs-reconciliation** | over-conservative: flags clean updates as reconcile ⚠ |
| CP-modify-customized (both edited) | `real-merge-required` / `project-shadows-new-pack` | YES (as project-shadows) | merge attempt / reconcile sidecar ✔ |
| CP-delete (master retired) | `removed-by-pack-*` (base=1, theirs=0) | **NO** (needs base) → `project-only-file` (0,1,0) → **PRESERVED** | **delete NOT propagated** ✗ (EEB-PRESERVE) |
| CP-x-preserve (`x-` file present) | `custom-agent`/`custom-script` OR by-omission | YES | preserved ✔ (glob never visits `x-`; explicit classes preserve) |

**Reading:** the current engine, under its BASE="" reality, does CP-add correctly, does CP-modify only via the lossy "shadow → reconcile" path (no clean fast-path), does CP-x-preserve correctly (mostly by-omission), and **does CP-delete not at all.** BD-202 is the project to make CP-modify-clean and CP-delete correct across AC-2/AC-3/AC-4 without ever clobbering customizations or removing `x-` files — i.e., reintroduce a real BASE (a per-version pack baseline) OR an authoritative-roster reconciler.

### §10.3 — Placing the pool in the taxonomy + wipe-repopulate validity

The BD-200 pool is **AC-1 × {CP-add, CP-modify-clean, CP-delete}**. It is the ONLY asset class for which all three change-patterns collapse to a single trivial operation, because AC-1 has no customization to preserve and no `x-` files to protect:
- CP-add → file appears in repopulate.
- CP-modify → repopulate overwrites with the new master.
- CP-delete → repopulate omits the retired master; the preceding wipe removes the stale copy.

Wipe-repopulate is thus **provably correct AND complete for AC-1, and provably WRONG for AC-2/AC-3/AC-4**: wiping AC-2/AC-4 destroys client edits (violates "project-modified files never clobbered") and destroys `x-` files (violates "`x-` files never removed"); AC-3 wipe loses the client's merged config keys. So wipe-repopulate is **not a reusable primitive** — it is the AC-1 corner of the general pattern. This is the evidence that BD-200's pool-update is a SPECIAL CASE, not a sibling pattern: it shares the BD-202 problem space but occupies its degenerate corner.

### §10.4 — Why BD-200's pool still belongs to BD-202 (the coupling)

Even though wipe-repopulate is correct for the pool in isolation, two cross-asset concerns bind the pool to BD-202:

- **Delete-propagation is a SHARED capability.** BD-202 must build CP-delete for AC-2/AC-3/AC-4 (the total gap, EEB-PRESERVE). The pool needs CP-delete too. If BD-202 builds a general delete-reconciler (authoritative-roster diff + `x-`-guard + customization check), the pool should register its roster with that ONE reconciler rather than carry a private wipe loop. One delete mechanism, audited once, is more elegant and avoids two divergent implementations of "what does the pack still ship."
- **`x-`-guard is a SHARED invariant.** The pool is AC-1 (`x-`-free by contract), but the pool POPULATION stage writes into the client tree; the general `x-`-never-removed audit BD-202 establishes should cover every pack-controlled write/remove site, including the pool stage, so the invariant is enforced uniformly rather than re-proven per BD.

A pool that wipe-repopulates OUTSIDE the BD-202 engine is exactly the "accidental one-off" the user fears: when BD-202 later adds a global "audit every pack-controlled removal for `x-` safety + customization safety + delete-roster correctness" check, the pool's private loop is an un-registered exception that must be found and reconciled.

### §10.5 — Sequencing recommendation + rework analysis

**Recommended: ONE co-design architecture pass for BD-202's general update-propagation pattern, with BD-200's pool as an explicitly-modeled AC-1 consumer; implement the BD-202 engine FIRST, then land BD-200's pool-update as a thin registration (declare the pool an AC-1 roster; the engine's add/modify/delete handles it).** Land the BD-200 sequencing-independent parts (§10.6) on their own track, unblocked.

Ordering options and rework cost:

| Order | Rework if other lands later | Coherence |
|---|---|---|
| **BD-202 engine first, BD-200 pool consumes it** (RECOMMENDED) | ~zero. Pool is a roster registration; the AC-1 path is the engine's simplest case. `activate-capability.sh` + tables land independently. | Highest — one delete/`x-`/merge engine; pool is a declared instance, not an exception. |
| BD-200 pool first (bespoke wipe-repopulate), BD-202 later | **Pool update RE-DONE:** the bespoke wipe loop must be deleted and re-expressed as an engine roster, and a global `x-`/customization audit must retro-cover the pool stage. Net: the pool-update piece is written twice. | Low — the pool is the un-registered exception BD-202 must hunt down. |
| Fully parallel, no shared engine | Two delete implementations diverge; double the audit surface; high reconciliation cost at integration. | Lowest. |

**Concrete rework if BD-200's pool ships bespoke and BD-202 lands later:** (a) the S5b/`pack update` wipe-repopulate loop is replaced by an engine call (the loop is throwaway); (b) the install-map NOTE for the pool population may need to move under the engine's registry; (c) a global `x-`-safety/customization-safety test added by BD-202 must be extended to assert the pool stage is covered — work that would have been free had the pool registered with the engine from the start. None of this touches `activate-capability.sh` or the tables — confirming the script work is genuinely decoupled.

**Counter-consideration (honest):** if BD-202 is large and v11.0 launch is gated on BD-200 (it is — launch gate includes BD-200), designing the FULL BD-202 engine before BD-200 could delay launch. Mitigation: the co-design pass can scope BD-202's **minimum viable engine** to exactly the primitives the pool needs (AC-1 add/modify/delete + the `x-`-guard hook) and DEFER the AC-2/AC-3/AC-4 merge-correctness work (CP-modify-clean fast-path, real BASE reintroduction) to BD-202's later phases — provided the engine's INTERFACE is designed for all four asset classes up front so the pool registration is forward-compatible. This lands BD-200 on a real (if minimally-populated) engine rather than a bespoke loop, paying the elegance cost without the full BD-202 delay. **This is the path I recommend if launch timing is tight: build the engine SKELETON + AC-1 path for BD-200; grow AC-2/AC-3/AC-4 under BD-202.**

### §10.6 — Sequencing-independent vs coupled (final partition)

**INDEPENDENT (land regardless of BD-202 ordering):**
- `project-template/scripts/activate-capability.sh` (the client script; no update-path dependency — it reads the pool at activation time, separate from how the pool is kept fresh).
- `project-template/scripts/capability-tables.sh` single-source + `add-capability.sh` source-line refactor (user-ratified).
- Procedure 6 redesign + HELP-FRAGMENT / PM-CHAT / INSTALL-PROCEDURES reference rework (verb `activate-capability.sh`).
- The pool POPULATION at FRESH install (S5b copy-from-pack-master) — fresh install has no prior client state to reconcile, so it is pure copy and needs no BD-202 engine. (Only the `pack update` REFRESH of the pool is coupled.)

**COUPLED (gate on the BD-202 ordering decision):**
- The pool's `pack update` propagation (add/modify/**delete**) — should consume the BD-202 engine (recommended) rather than a bespoke wipe-repopulate loop.

**Net:** BD-200 can ship its entire user-visible capability (activate a capability on a fresh clone) on the INDEPENDENT parts + fresh-install pool population. Only the cross-version pool REFRESH is the coupled sliver — and that is precisely the sliver that should be an instance of BD-202, not a one-off.

### §10.7 — Empirical-Evidence Blocks (§10 additions)

> **EEB-BASE — `cmd_update` always passes BASE="" to `customization_preserve` (both the entries loop and the glob path).**
> Command: `grep -n 'customization_preserve ' scripts/init-project.sh` → `1057: customization_preserve "" "$ours" "$theirs" ...` (glob, `_cmd_update_iter_dir`); `1204: customization_preserve "" "$ours" "$theirs" ...` (entries loop). The literal first argument is `""`. Confirmed by the in-code comment (`1108-1111`): "BASE is left empty (no prior pack baseline available offline ...)."
> Interpretation: every `pack update` classification runs with `has_base=0`.
> Conclusion: **SUPPORTED**.

> **EEB-CLASSIFY — `three_way_classify`'s delete arms require `has_base=1`; clean-modify arm requires `has_base=1`.**
> Command: `sed -n '104,120p' scripts/lib/three-way.sh` → the `removed-by-pack-clean`/`removed-by-pack-customized`/`removed-everywhere` block is guarded by `if [[ $has_base -eq 1 && $has_theirs -eq 0 ]]`; `pack-update-applied` (clean modify) is inside the `has_base=1 && has_ours=1 && has_theirs=1` block (`68-82`). The `(0,1,0)` arm (`93-96`) returns `project-only-file`; the `(0,1,1)` arm (`99-102`) returns `project-shadows-new-pack`.
> Interpretation: with BASE="" (EEB-BASE), CP-delete classifies as `project-only-file`, and CP-modify classifies as `project-shadows-new-pack` (no clean fast-path).
> Conclusion: **SUPPORTED**.

> **EEB-PRESERVE — `project-only-file` disposition is PRESERVED (never deleted), so `pack update` propagates ZERO deletes.**
> Command: `sed -n '294,300p' scripts/lib/customization-preserve.sh` → `project-only-file) _cp_record "$disp" "$class" "$rel" "preserved" ...`. Combined with EEB-BASE + EEB-CLASSIFY: a pack-retired master (`theirs=""`, `ours=present`) → `(0,1,0)` → `project-only-file` → preserved.
> Interpretation: CP-delete is unreachable in `cmd_update`; the prior EEB-B claim that the explicit-entries path deletes is CORRECTED — deletes propagate for NO asset class. The delete gap is total.
> Conclusion: **SUPPORTED** (corrects prior EEB-B).

> **EEB-XCLASS — `customization_classify` special-cases `x-` agents as `custom-agent` (preserved), and the glob update path never visits `x-` files.**
> Command: `sed -n '/^customization_classify()/,/^}/p' scripts/lib/customization-preserve.sh` → `.claude/agents/x-*|.codex/agents/x-*|.gemini/agents/x-*) printf 'custom-agent\n'`; the `custom-agent`/`custom-script` arm in `customization_preserve` (`535-543`) preserves if `ours` exists. `_cmd_update_iter_dir` (`1045-1058`) iterates `find "$PACK/$pack_dir" -type f` — pack dirs contain no `x-` files, so `x-` client files are never visited.
> Interpretation: `x-` safety in the update path is enforced by-omission (glob) PLUS a defensive class (explicit path). BD-202's general engine must preserve this invariant uniformly across all pack-controlled write/remove sites (incl. the pool stage).
> Conclusion: **SUPPORTED**.

### §10.8 — Rules-Applied Verification Block (§10 addendum)

| Rule | Evidence | Conclusion |
|---|---|---|
| READ-IN-FULL set | Re-read in full for this addendum: `scripts/lib/three-way.sh` `three_way_classify` (full function, 57-125), `scripts/lib/customization-preserve.sh` (`customization_preserve` 515-558, `customization_classify`, `_cp_disposition_for`, `project-only-file`/`removed-by-pack-*` arms, structured-merge arm 336-375), `scripts/init-project.sh` `cmd_update` + `_cmd_update_iter_dir` (1045-1233). Prior always-on + curated-memory + design-input reads from the base review remain in force (this is an addendum to the same session's doc, not a fresh review). | **COMPLIANT** |
| preliminary-triage / architect-challenge (HIGH bar) | Challenged my OWN prior EEB-B and corrected it (§10.1, EEB-PRESERVE) — the delete gap is total, not glob-specific; challenged the user's implicit framing that the pool might be a reusable pattern, finding it is the degenerate AC-1 case (§10.3). HIGH boundary bar (update engine, `x-` invariant, customization preservation). | **COMPLIANT** |
| pattern-matching-out-of-context anti-pattern | §10.3: explicitly property-fit-tested wipe-repopulate against AC-2/AC-3/AC-4 and REJECTED it as a general primitive (clobbers customization, removes `x-`); it is valid ONLY for AC-1's zero-customization property. | **COMPLIANT** |
| empirical-evidence-blocks | §10.7: EEB-BASE/CLASSIFY/PRESERVE/XCLASS — each command + verbatim line refs + HEAD `93a3337` + date 2026-06-04 + interpretation + SUPPORTED. The taxonomy tables in §10.2 are sourced to these EEBs; the prior-claim correction is itself backed (EEB-PRESERVE). | **COMPLIANT** |
| ci-guard-measure-then-bound | §10.4/§10.5: the pool's update is bound to the BD-202 engine's roster + `x-`-guard rather than a private loop; the recommended minimum-viable-engine scoping sizes BD-202's first phase exactly to AC-1 + the `x-` hook, deferring AC-2/3/4 — measured against the current engine's actual reachable behavior (EEB-CLASSIFY/PRESERVE). | **COMPLIANT** |
| dependency-direction-placement | §10.6: confirmed `activate-capability.sh` + tables are sequencing-independent client deliverables; the pool population/refresh writes only into client paths from `project-template/` masters; no project-side artifact becomes a pack runtime dependency; no allowlist growth implied by the sequencing decision. | **COMPLIANT** |
| pack-project separation of concerns | The BD-202 engine is a pack-side update mechanism; the pool + `activate-capability.sh` + client `capability-tables.sh` consume same-side copies; no cross-side substitution introduced by the sequencing recommendation. | **COMPLIANT** |
| boundary / no-pack-self-in-project | §10 reasons about pack-side update machinery (BD-202) and client-side pool; it does not introduce any pack-self token into client surfaces — the client-facing BD-200 deliverables (script/Procedure 6/refs) remain pack-self-clean per the base review §3.1. | **COMPLIANT** |
| scope-deliverables-to-the-ask | Delivered exactly the 4 requested items (special-case verdict + taxonomy; wipe-repopulate (in)validity per class; sequencing + rework; independent vs coupled partition); led with the verdict; no sprawl; the launch-timing counter-consideration fenced in §10.5. | **COMPLIANT** |
| rules-applied-verification-block | This §10.8 table — per-rule name + quoted/measured evidence + COMPLIANT; no empty-evidence rows; no AMBIGUOUS terminal states. | **COMPLIANT** |
| agents-never-commit / preflight-stop-means-stop | Only read-only verbs (`git rev-parse`, `grep`, `sed`) + a single appending `cat >>` to the caller-specified review doc; NO `git add/commit/push/tag`; no parent stop directive; every new state-claim backed by an EEB. | **COMPLIANT** |
