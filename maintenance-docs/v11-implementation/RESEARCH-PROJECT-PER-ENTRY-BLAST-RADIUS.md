# RESEARCH-PROJECT-PER-ENTRY-BLAST-RADIUS — Project-side per-entry no-mirror + reversible-tracker feature

**Agent:** pack-docs-researcher · **Date:** 2026-06-04 · **Branch:** v11-dev · **HEAD:** `1936136`
**Mode:** READ-ONLY foundational blast-radius research. NOT a design. No source edits, no git state change.
**Purpose:** Exhaustive, re-verified enumeration of the PROJECT-SIDE blast radius for adopting the
corrected no-monolithic-mirror + preserve-all + reversible standard in the CLIENT-shipped per-entry +
tracker FEATURE (BD-206 monolith→per-entry; new BD-207 per-entry↔GH-Issues reversible). Companion to
`RESEARCH-BD-203-BLAST-RADIUS.md` (the PACK-side counterpart). The architect reads BOTH + decides
together-vs-separate.

---

## HEADLINE (lead)

| Measurement | Value | Caveat / how |
|---|---|---|
| **Project per-entry streams** | **3** (backlog `TD-NNN`, implementation-plan `phase-N`, changelog `YYYY-MM-DD`) | pack has only 2 — the project side is BIGGER. `_lib.sh:64` `PE_STREAM_KEYS` lists all 5 (2 pack + 3 project). |
| **Project-side wrong-model "regenerated mirror" surfaces** | **16 files** | grep `regenerated mirror` across `project-template/` + `supporting-docs/`. Distinct from the pack-side subset. |
| → of which CLIENT-SHIPPED (`project-template/`) | **15 files** | every file under `project-template/` ships to clients per Check 41 (whole-tree walk). |
| → `supporting-docs/` (client-installed source) | **1 file** (`MIGRATION-v10-to-v11.md`, 24 mirror/monolith hits) | client-facing migration guide. |
| **SHARED tooling (pack + project use the SAME code)** | `scripts/lib/per-entry/{_lib,decompose,mirror-generate,toc-regenerate}.sh` | the SINGLE biggest together-vs-separate driver — ONE codebase drives BOTH pack streams (BD-203) and project streams (BD-206). |
| **Project-only tooling** | `scripts/lib/migrate-v10-to-v11/decompose.sh` (client conversion) + the tracker subsystem's `client` surface | the v10→v11 client conversion + the client tracker forward/reverse. |
| **Does the client conversion regenerate a monolith mirror?** | **YES** — `migrate-v10-to-v11/decompose.sh:195` calls `per_entry_regenerate_mirror` after every decompose; `init-project.sh:1124` does the same for greenfield | the exact wrong-model behavior BD-206 must retire. |
| **Does the client conversion preserve ALL entries?** | project-backlog admits only **2 states** (Open/Resolved) so no status-filter drop; BUT the shared `TD-NNN` anchor (`decompose.sh:128`) has the SAME plain-`-\d+`-only form as the pack BD anchor → any `TD-NNNb`/parenthetical header would be dropped | anchor-form risk identical to the pack's `BD-167b` gap. |
| **Is the client per-entry↔GH-Issues round-trip reversible + per-entry-preserving?** | **NO — major gap.** The tracker forward/reverse read/write a MONOLITH at the client REPO ROOT (`$repo_root/BACKLOG.md`), NEVER the `docs/project/` per-entry tree. Reverse calls NO `per_entry_decompose`/`regenerate`. | BD-207's core problem: the tracker subsystem is disconnected from the per-entry tree on the client side. |
| **Does the tracker subsystem ship to clients?** | **NO** — `scripts/lib/tracker-*.sh` + `scripts/migrate-v10-to-v11.sh` + `scripts/lib/per-entry/` are NOT in `_CLIENT_INSTALLED_FILES` and not under `project-template/`. They run PACK-SIDE against a client `--repo-root` target. | so BD-206/207 change the FEATURE (pack-side tooling + shipped docs/templates), not files installed in the client repo. |
| **Pack-CI validator coverage of client per-entry/mirror contract** | **NONE** — `validate-pack.py` STREAMS tuple (`:297-301`) loads ONLY the 2 pack streams; project streams explicitly NOT loaded (`§10.6`, comment at `:288`). Client-side enforcement lives in the shipped `audit-methodology` skill. | no pack-CI guard asserts the client no-mirror contract — BD-206 must decide whether to add one. |

**Bottom line for the architect.** The project-side picture is LARGER than the pack's (3 streams vs 2) but
SHARES its core tooling. The 16 wrong-model surfaces are a DISJOINT set from the pack's (different files,
client audience). Two distinct project-side defects must be fixed: (1) **BD-206** — the client conversion
(`migrate-v10-to-v11/decompose.sh` + greenfield `init-project.sh`) regenerates a monolith mirror + 16 docs
say "mirror is the model"; (2) **BD-207** — the client tracker forward/reverse is built on a root monolith
with NO per-entry tree connection and NO verified per-entry-preserving round-trip. The **shared
`scripts/lib/per-entry/`** is the decisive together-vs-separate input: changing the mirror-generate behavior
there affects BOTH pack (BD-203) and project (BD-206) simultaneously — they CANNOT be cleanly separated at
the tooling layer.

---

## 1. THE CLIENT-SHIPPED PER-ENTRY + TRACKER FEATURE INVENTORY (ship-status + current mirror behavior)

### 1.1 Ship-status determination (the boundary that drives everything)

A file is "client-shipped" iff it is under `project-template/` (Check 41 whole-tree walk) OR in
`_CLIENT_INSTALLED_FILES` / `_SANCTIONED_PACK_SIDE_SHIPPED`. Measured: the per-entry helpers and the entire
tracker subsystem are NEITHER — they are PACK-SIDE TOOLING that operates ON a client repo via `--repo-root`.

| Surface | Path | Ships to client? | Evidence | Current mirror behavior |
|---|---|---|---|---|
| **Shared per-entry helpers** | `scripts/lib/per-entry/{_lib,decompose,mirror-generate,toc-regenerate}.sh` | **NO** (pack-side tooling; `_SANCTIONED_PACK_SIDE_SHIPPED` = `{detect.sh, pack-help.sh}` only) | `validate-pack.py:4159-4161` | `_lib.sh` hard-codes project mirror filenames (`:87,99,107`); `mirror-generate.sh` REGENERATES the monolith from the tree — used for BOTH pack + project streams. |
| **Client v10→v11 conversion** | `scripts/migrate-v10-to-v11.sh` + `scripts/lib/migrate-v10-to-v11/decompose.sh` | **NO** (run pack-side against client `--repo-root`) | not under `project-template/`; not in `_CLIENT_INSTALLED_FILES` | Decomposes the client `docs/project/*.md` monolith → per-entry tree, then `per_entry_regenerate_mirror` (`:195`) REWRITES the mirror. |
| **Client tracker subsystem** | `scripts/lib/tracker-*.sh`, `scripts/tracker-migrate.sh`, `scripts/pack-tracker.sh` | **NO** (pack-side; `client` surface = `--repo-root` against a client repo) | `tracker-config.sh:82` `client) echo "$root/docs/pack/tracker.toml"` | forward/reverse read/write the client MONOLITH at repo ROOT, NOT the per-entry tree (§4). |
| **Client trinity convention** | `project-template/{CLAUDE,AGENTS,GEMINI}.md` `## Document locations` table + "Per-entry source-of-truth trees" block | **YES** | `project-template/CLAUDE.md:228-244` | states "regenerated mirrors … per-entry source in subdirs" + "tracker … tree and the monolithic mirror are regenerated from tracker state" (WRONG-model). |
| **Client per-entry stream contracts** | `project-template/docs/project/{backlog,implementation-plan,changelog}/_rules.md` | **YES** | install via `init-project.sh:1039-1059` (S11 step 6) | all 3 say "The monolithic `docs/project/<X>.md` is a regenerated mirror — read-stable but never source of truth" (WRONG-model). |
| **Client per-entry stream intros** | `project-template/docs/project/{backlog,implementation-plan,changelog}/_intro.md` | **YES** | install S11 step 6 | all 3 are themselves labeled "the regenerated mirror of the per-entry source-of-truth" + carry the "regenerated from tracker state per the Mode 2 → Mode 3 transition" line (WRONG-model). |
| **Client changelog format** | `project-template/docs/project/changelog/_format.md` | **YES** | install S11 step 6 (project-side asymmetry; no pack analog) | append-only format rules; check for mirror language. |
| **Client migration guide** | `supporting-docs/MIGRATION-v10-to-v11.md` | **YES** (client-installed source) | `_iter_client_installed_files` admits `supporting-docs/` | "monolithic files become regenerated mirrors" + `--force-overwrite-mirror` flag narrative (WRONG-model; 24 mirror/monolith hits). |
| **Client methodology** | `supporting-docs/METHODOLOGY.md` | **YES** | client-installed at `docs/pack/METHODOLOGY.md` | per-entry write-authority pointers (Part 4/7); tracker Phase N.M blocker prose (`:1242`). NO "regenerated mirror" hit — but the `_rules.md` files point clients here for per-entry procedure. |
| **Shipped per-entry tree templates** | `project-template/docs/project/{backlog,implementation-plan,changelog}/` (8 files) | **YES** | S11 step 6 | the skeleton greenfield clients start from; `_rules.md`/`_intro.md` carry the wrong model. |
| **Shipped audit skill** | `project-template/skills/audit-methodology/SKILL.md` | **YES** | S4 skill distribution | `:77` "Regenerated mirrors are OUT OF SCOPE when the per-entry tree is present … The monolithic … are regenerated mirrors of the per-entry tree" (WRONG-model + encodes mirror-skip logic). |
| **Shipped pm-startup skill** | `project-template/{.claude,.codex,skills}/pm-startup/SKILL.md` + `.gemini/commands/pm-startup.toml` | **YES** | S4 / S11 | `:93` "`docs/project/CHANGELOG.md` files are regenerated mirrors of those per-entry trees" (WRONG-model). |
| **Shipped PM-CHAT** | `project-template/docs/pack/PM-CHAT.md` | **YES** | S6 docs-pack | `:330-332` "STATUS.md a working snapshot — never source of truth … `docs/project/BACKLOG.md` named as the regenerated mirror" (WRONG-model). |
| **Client tracker config example** | `project-template/tracker.toml.project-example` | **YES** | S11 step 2 → `tracker.toml.example` | the only `*tracker*` file under `project-template/`; a config example, not tooling. |
| **Client-side per-entry validators** | none in pack CI; `audit-methodology` skill ships the client-side check | n/a | `validate-pack.py:288` "project-side per-entry trees … NOT loaded here" | NO pack-CI guard on the client no-mirror contract. |

### 1.2 The three project streams (vs the pack's two)

`_lib.sh:64`: `PE_STREAM_KEYS="pack-backlog pack-changelog project-backlog project-implementation-plan project-changelog"`.
The project side has an **implementation-plan stream the pack lacks** (the pack has no implementation-plan
monolith per BD-203 entry). Per-stream attrs (`_lib.sh:85-117`):

| Project stream | Mirror filename | Entry regex | Anchor (`decompose.sh`) | States admitted (`_rules.md`) |
|---|---|---|---|---|
| project-backlog | `docs/project/BACKLOG.md` | `^TD-[0-9]+\.md$` | `^\*\*(TD-\d+) — ` (`:128`) | Open, Resolved (2 only) |
| project-implementation-plan | `docs/project/IMPLEMENTATION-PLAN.md` | `^phase-[0-9]+\.md$` | `^## Phase (\d+) — ` (`:133`) | pending/in-progress/done/deferred/merged-into/superseded-by |
| project-changelog | `docs/project/CHANGELOG.md` | `^[0-9]{4}-[0-9]{2}-[0-9]{2}(-.+)?\.md$` | `^### (\d{4}-\d{2}-\d{2})…` (`:139`) | append-only (no states) |

---

## 2. EVERY "monolith = regenerated mirror" WRONG-MODEL STATEMENT IN PROJECT-SIDE / CLIENT-SHIPPED CONTENT

16 files (15 shipped under `project-template/` + 1 client-installed source). Disposition: **CORRECT-model**
(rewrite to no-mirror) for all. This set is DISJOINT from the pack-side §5 set in the companion report
(different files, client audience — per `pack-project-separation-of-concerns`, these are SEPARATE artifacts).

### 2.1 Client trinity (×3 — trinity rule binds parity)
| File:line | Statement |
|---|---|
| `project-template/CLAUDE.md:231` | `## Document locations` table row: "(regenerated mirrors for BACKLOG/IMPLEMENTATION-PLAN/CHANGELOG — per-entry source in subdirs)" |
| `project-template/CLAUDE.md:236-244` | "Per-entry source-of-truth trees" block: "The monolithic … are regenerated mirrors — read-stable but never source of truth. In tracker mode … the monolithic mirror are regenerated from tracker state." |
| `project-template/AGENTS.md:215, 224-228` | parallel trinity statements |
| `project-template/GEMINI.md:227, 236-240` | parallel trinity statements |

### 2.2 Client per-entry stream contracts + intros (the shipped skeleton)
| File:line | Statement |
|---|---|
| `project-template/docs/project/backlog/_rules.md:44-47` | "The monolithic `docs/project/BACKLOG.md` is a regenerated mirror — read-stable but never source of truth; hand-edits are silently overwritten on the next regeneration." |
| `project-template/docs/project/implementation-plan/_rules.md:45-48` | parallel statement for `IMPLEMENTATION-PLAN.md` |
| `project-template/docs/project/changelog/_rules.md:48-51` | parallel statement for `CHANGELOG.md` |
| `project-template/docs/project/backlog/_intro.md:1, 9, 42, 48` | the intro IS labeled "regenerated mirror of the per-entry source-of-truth" + "regenerated from tracker state per the Mode 2 → Mode 3 transition" |
| `project-template/docs/project/implementation-plan/_intro.md:1, 10, 51, 57` | parallel |
| `project-template/docs/project/changelog/_intro.md:1, 11, 45, 51` | parallel |

> **Note (architect):** the `_intro.md` files are the GENERATED mirror's own preamble (they ARE the head of
> the regenerated monolith). Under no-mirror they have no mirror to head. The architect must decide their
> fate — repurpose as the per-entry tree's `_intro` (readable-form header) or retire. This is the project
> analog of the pack's `_intro.md` question.

### 2.3 Client shipped skills + docs
| File:line | Statement |
|---|---|
| `project-template/skills/audit-methodology/SKILL.md:77` | "Regenerated mirrors are OUT OF SCOPE when the per-entry tree is present. The monolithic … are regenerated mirrors of the per-entry tree … auditor-docs SKIPs the mirror file when the corresponding per-entry tree exists." (also encodes mirror-skip detection logic keyed on `validate-pack.py` Checks 32/33/34) |
| `project-template/.claude/skills/pm-startup/SKILL.md:93` | "`docs/project/CHANGELOG.md` files are regenerated mirrors of those per-entry trees" |
| `project-template/.codex/skills/pm-startup/SKILL.md:93` | parallel |
| `project-template/skills/pm-startup/SKILL.md:93` (canonical pool) | parallel |
| `project-template/.gemini/commands/pm-startup.toml:90` | parallel |
| `project-template/docs/pack/PM-CHAT.md:330-332` | "STATUS.md a working snapshot — never source of truth … `docs/project/BACKLOG.md` named as the regenerated mirror" |

> **Trinity-of-skills note:** the `pm-startup` skill exists in FOUR shipped copies (`.claude`, `.codex`,
> `skills/` canonical pool, `.gemini` TOML). Per `skill-agent-maintenance-mechanical` + the `x-` contract,
> all four correct in lockstep. Same for any audit-methodology copies.

### 2.4 Client migration guide (`supporting-docs/`)
| File:line | Statement |
|---|---|
| `supporting-docs/MIGRATION-v10-to-v11.md:246-247` | "The pre-existing monolithic files become regenerated mirrors of the per-entry trees, not the source of truth" |
| `:262-264` | "`_intro.md` — the preamble extracted from the v10 monolithic … the top of the regenerated mirror" |
| `:267-292` | "**Monolithic files become regenerated mirrors.**" + "the per-entry tree plus the regenerated mirror" |
| `:311-337` | the entire `--force-overwrite-mirror` flag section (a flag whose existence presupposes a mirror) |

---

## 3. THE CLIENT monolith→per-entry CONVERSION FLOW (BD-206)

**How a client converts.** A client with a v10 `docs/project/BACKLOG.md` monolith runs (pack-side, against
their repo) `scripts/migrate-v10-to-v11.sh --apply --repo-root <client>`. Its S5d-decompose step
(`scripts/lib/migrate-v10-to-v11/decompose.sh`) loops the 3 project streams (`:145-148`) and for each:
1. `per_entry_decompose` (shared helper) — monolith → per-entry tree under `docs/project/<stream>/`.
2. **`per_entry_regenerate_mirror` (`:195`) — REWRITES the monolith mirror from the tree.** ← wrong-model.
3. `per_entry_regenerate_toc` (`:203`) — writes `_toc.md`.

A GREENFIELD client (`init-project.sh` S11 step 7, `:1080-1133`) does the same for empty seeds:
`per_entry_regenerate_mirror` (`:1124`) writes an empty mirror at `docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md`.

**Does it generate a monolithic mirror?** YES — both the conversion AND greenfield paths actively write the
client monolith. This is the precise behavior BD-206 must retire (stop writing the mirror; the per-entry
tree + `_toc.md` become the sole SSOT + readable form).

**Does it preserve ALL entries?**
- project-backlog admits only Open/Resolved (`_rules.md:24-30`) — no Deferred/Deprecated/Cancelled to drop,
  so NO status-filter risk (unlike the pack which has 5 states).
- BUT the shared `TD-NNN` anchor `^\*\*(TD-\d+) — ` (`decompose.sh:128`) is the SAME plain-`-\d+`-immediate-
  `— ` form that DROPPED the pack's `BD-167b`/`BD-195 (Code Red 3)` entries. Any client `TD-NNNb` suffix or
  parenthetical header form would be silently dropped. The architect must close this anchor-coverage gap on
  the SHARED helper (it fixes both pack and project at once — a together argument).
- project-implementation-plan: `## Phase N — ` anchor; `section_break_re` is ALSO `^## ` — but `is_anchor`
  is evaluated FIRST (`decompose.sh:249-250`), so a phase H2 is correctly treated as an anchor, not a
  break. No drop here, but flag for architect verification.

**Blast radius of no-mirror + preserve-all on the client conversion:** (a) `migrate-v10-to-v11/decompose.sh`
must stop calling `per_entry_regenerate_mirror` (or that function is retired); (b) `init-project.sh` S11
step 7 must stop writing greenfield mirrors; (c) the shared `mirror-generate.sh` becomes vestigial for
project streams too (it's vestigial for pack streams under BD-203 — SAME function, SAME retirement); (d) the
decompose/conversion tests (`test-migrate-v10-to-v11-decompose.sh` Groups 2-5, all built on
`per_entry_regenerate_mirror` + `--force-overwrite-mirror`) must be reworked; (e) the 16 docs corrected.

---

## 4. THE CLIENT per-entry↔GH-Issues TRACKER FLOW + REVERSIBILITY (BD-207)

### 4.1 What the tracker subsystem actually does on the client side (measured)
- **Surface resolution** (`tracker-config.sh:80-87`): `client) echo "$root/docs/pack/tracker.toml"`. So the
  client opt-in config lives at `docs/pack/tracker.toml`.
- **Forward (Mode 2→3)** `tracker-migrate-forward.sh:732-737`: for the `client` surface it reads
  **`$repo_root/BACKLOG.md`** (repo ROOT), parses v10-shape entries, creates GH Issues, then "Regenerate
  flat-file mirror" (step 10, `:23`). It does **NOT** read the `docs/project/backlog/` per-entry tree and
  does NOT read `docs/project/BACKLOG.md`.
- **Reverse (Mode 3→2)** `tracker-migrate-reverse.sh:1063-1068`: for the client surface it emits
  **`$repo_root/BACKLOG.md`**, `$repo_root/IMPLEMENTATION-PLAN.md`, `$repo_root/STATUS.md`,
  `$repo_root/CHANGELOG.md` — all at repo ROOT. It calls NO `per_entry_decompose` / `per_entry_regenerate`
  (grep: zero hits in any `tracker-*.sh`). The comment at `:1051-1054` CLAIMS "Client side has its own
  canonical locations under docs/project/ already handled by the project-side reverse path" — **but no such
  per-entry reverse path exists** (grep for `docs/project/backlog` in tracker libs: zero). The claim is
  aspirational/stale; the only emit is the legacy root monolith.
- **The one tree-aware tracker lib:** `tracker-agent-read.sh:174-200` DOES read the per-entry tree
  (`TD-NNN → docs/project/backlog/TD-NNN.md`) with a MIRROR FALLBACK + carries the wrong-model comment
  ("regenerated mirror of tracker state in tracker mode," `:166-169`). This is a READ shim, not the
  forward/reverse migration.

### 4.2 Is a lossless per-entry round-trip currently supported / verified?
**NO, on two counts:**
1. **Not per-entry.** Forward consumes a ROOT monolith and reverse emits a ROOT monolith. The per-entry tree
   under `docs/project/` is never the forward input nor the reverse output. A client whose SSOT is the
   per-entry tree (post-BD-206) has NO supported path INTO or OUT OF the tracker — the tracker only speaks
   monolith-at-root.
2. **Round-trip test is pack-surface only.** `tracker-migrate-roundtrip-test.sh:343-349` copies the fixture
   `BACKLOG.md` into `pack-ops/` and forces `tracker_config_auto_surface` to return `"pack"`. There is NO
   client-surface round-trip test, and NO per-entry round-trip test.

### 4.3 The reverse-migration path (enumerated)
`tracker_migrate_reverse_run` (`tracker-migrate-reverse.sh:43,848+`): auto-detect surface → reconstruct
entries from GH Issues (`tracker_migrate_reverse_reconstruct:502`) → silent-data-loss guard
(`:1035-1042`, fails if any issue fails to reconstruct) → `_tmr_emit_backlog` writes the ROOT monolith →
header-snapshot preservation (BD-133, `:1100-1109`) → strip mirror header → update
`tracker.toml [migration].last_reverse_run`. Round-trip safety today is asserted at the MONOLITH-BYTE level
(`roundtrip-test.sh:325` "canonical string for byte-equivalent comparison"), not the per-entry level.

### 4.4 What changes for no-mirror + preserve-all + reversible (BD-207 blast radius)
- Forward must consume the per-entry tree (`docs/project/<stream>/`) as input, not a root monolith.
- Reverse must EMIT the per-entry tree (call `per_entry_decompose` or write per-entry files directly), not a
  root/`docs/project/` monolith — and must NOT regenerate a mirror.
- Round-trip must be verified at the PER-ENTRY level (tree → GH Issues → tree, every TD/phase/changelog
  entry + status preserved), with a NEW client-surface + per-entry round-trip test.
- **Cross-reference the pack-side BD-204 collision** (companion §2A): the pack reverse
  (`tracker-migrate-reverse.sh:1059-1060`) WRITES `pack-ops/BACKLOG.md` — the same wrong-model mirror write,
  on the SAME reverse function, pack-surface branch. BD-204 (pack) and BD-207 (project) hit the SAME reverse
  emitter (`_tmr_emit_backlog` + the surface branch at `:1056-1068`). The "tree + mirror regenerated from
  tracker" clause in BOTH the BD-204 entry (`:3358,3361`) and the client `_intro.md`/trinity
  ("regenerated from tracker state per the Mode 2 → Mode 3 transition") is the wrong-model statement under
  the no-mirror standard. **The architect must reconcile the Mode-3 contract for BOTH surfaces at once —
  this is a shared-code collision, a strong together argument for the tracker layer.**

---

## 5. PROJECT-SIDE ENTRY-PRESERVATION REALITY (does any shipped conversion path drop entries?)

| Path | Drops entries? | Evidence |
|---|---|---|
| Client v10→v11 decompose (project-backlog) | Risk: `TD-NNNb`/parenthetical headers (shared anchor `^\*\*(TD-\d+) — `, `decompose.sh:128`) — same class as the pack's dropped `BD-167b`. No status-filter risk (only Open/Resolved admitted). | `decompose.sh:128`; `_rules.md:24-30` |
| Client v10→v11 decompose (implementation-plan) | `## Phase N —` anchor vs `^## ` section-break — anchor wins (`:249-250`); low risk but verify | `decompose.sh:133,249-250` |
| Client v10→v11 decompose (changelog) | date-anchored `### YYYY-MM-DD` (`:139`) — no version-grouping-H2 discard problem the PACK changelog has (the pack drops v1–v7 H2-only + nested subsections; the PROJECT changelog is date-per-H3 so NOT affected) | `decompose.sh:139` |
| Client tracker forward | Reads ROOT monolith; silent-data-loss guard on reverse only. Forward partial-write surface (`:757-761`) tracks per-entry create failures. | `tracker-migrate-forward.sh:732-761` |
| Client tracker reverse | silent-data-loss guard (`:1035-1042`) FAILS rather than drops — good. But emits MONOLITH only; per-entry tree never reconstructed (a state-LOCATION loss, not a count loss). | `tracker-migrate-reverse.sh:1035-1068` |

**Net:** the dominant project-side preservation risk is the SHARED `TD-NNN` anchor-form gap (fixable on the
shared helper — fixes pack + project together) + the tracker's per-entry-tree disconnection (BD-207).

---

## 6. FULL PROJECT-SIDE BLAST RADIUS OF THE MODEL CHANGE (no-mirror + preserve-all + reversible)

| # | Surface | BD | Disposition |
|---|---|---|---|
| 1 | `scripts/lib/per-entry/mirror-generate.sh` (vestigial for project streams) | 206 (shared w/ 203) | retire / repurpose project-stream mirror-generate |
| 2 | `scripts/lib/per-entry/_lib.sh:87,99,107` (project mirror filename consts) | 206 (shared w/ 203) | repoint/retire mirror attr for project streams |
| 3 | `scripts/lib/per-entry/decompose.sh:128` (TD anchor form gap) | 206 (shared w/ 203) | widen anchor to admit suffix/parenthetical TD forms |
| 4 | `scripts/lib/per-entry/toc-regenerate.sh` (project TOC) | 206 (shared w/ 203) | KEEP — TOC is the no-mirror readable index |
| 5 | `scripts/lib/migrate-v10-to-v11/decompose.sh:195` (regen mirror after decompose) | 206 | stop writing client mirror |
| 6 | `scripts/init-project.sh:1095-1132` (greenfield mirror write) | 206 | stop writing greenfield mirror |
| 7 | `scripts/lib/tracker-migrate-forward.sh:732-737` (client reads root monolith) | 207 | consume per-entry tree |
| 8 | `scripts/lib/tracker-migrate-reverse.sh:1063-1068` (client emits root monolith) | 207 | emit per-entry tree, no mirror |
| 9 | `scripts/lib/tracker-agent-read.sh:166-200` (wrong-model comment + mirror fallback) | 207 | correct comment; per-entry-only |
| 10 | `project-template/{CLAUDE,AGENTS,GEMINI}.md` (trinity ×3) | 206 | CORRECT-model |
| 11 | `project-template/docs/project/*/{_rules,_intro}.md` (6 files) | 206 | CORRECT-model + decide `_intro` fate |
| 12 | `project-template/skills/audit-methodology/SKILL.md:77` | 206 | CORRECT-model + rework mirror-skip logic |
| 13 | `project-template/{.claude,.codex,skills,.gemini}/pm-startup/*` (4 copies) | 206 | CORRECT-model lockstep |
| 14 | `project-template/docs/pack/PM-CHAT.md:330-332` | 206 | CORRECT-model |
| 15 | `supporting-docs/MIGRATION-v10-to-v11.md:246-337` (+ `--force-overwrite-mirror` section) | 206 | CORRECT-model; retire flag narrative |
| 16 | `supporting-docs/METHODOLOGY.md` (per-entry write-authority / tracker prose) | 206 | verify + correct any mirror assumption |
| 17 | client-conversion tests (`test-migrate-v10-to-v11-decompose.sh` Groups 2-5; `tracker-migrate-roundtrip-test.sh` client surface) | 206/207 | FIX-test (rework off mirror/round-trip-to-mirror premise; ADD per-entry round-trip) | 
| 18 | pack-CI client-per-entry validator | 206 | DECISION — none today; add a guard or rely on shipped `audit-methodology` skill |
| 19 | README project-side rows (`:123` "shipped to" + client per-entry note) | 206 | verify/correct if it states client mirror model |

---

## 7. PACK-vs-PROJECT OVERLAP / DIVERGENCE (the architect's together-vs-separate input)

| Layer | SHARED (pack+project, SAME code) | PROJECT-ONLY | PACK-ONLY |
|---|---|---|---|
| **Per-entry helpers** | `scripts/lib/per-entry/{_lib,decompose,mirror-generate,toc-regenerate}.sh` — ONE codebase, 5 streams (2 pack + 3 project). Retiring mirror-generate / widening anchors affects BOTH. | — | — |
| **Conversion driver** | — | `scripts/lib/migrate-v10-to-v11/decompose.sh` (client v10→v11) + `init-project.sh` greenfield | (the pack converts via BD-203's own one-time decompose, not the v10→v11 migrator) |
| **Tracker forward/reverse** | `_tmr_emit_backlog` + the surface branch (`tracker-migrate-reverse.sh:1056-1068`) — ONE reverse function, pack + client branches both write a monolith | client surface paths (`docs/pack/tracker.toml`, root emit) | pack surface paths (`pack-ops/`) |
| **The CONVENTION (trinity `## Pack memory` rule)** | The "Per-entry trees vs mirrors" RULE in CLAUDE.md `## Pack memory` SHIPS to clients (it's in the client trinity too). BD-203 corrects the pack-repo copy; the same rule text lives in the client trinity (BD-206). | — | — |
| **Wrong-model docs** | — | 16 project-side files (§2) — DISJOINT from the pack's §5 set | pack §5 set (trinity pack copy, README pack rows, PACK-AGENTS/PACK-CHAT, HELP-FRAGMENT-PACK) |
| **Validators** | — | none (no project-stream validator in pack CI) + shipped `audit-methodology` skill | `validate-pack.py` Checks 32/33/34 (pack streams only) |

**Together-vs-separate signal:** the **tooling layer is heavily SHARED** (per-entry helpers + the reverse
emitter), which argues STRONGLY for designing BD-203/206 (and BD-204/207) TOGETHER at the code layer — you
cannot retire `mirror-generate.sh` for the pack without it being retired for the project, and you cannot fix
the reverse emitter's monolith-write for the pack surface without touching the client surface branch in the
same function. The **DOCS layer is cleanly DISJOINT** (pack vs project files, separate audiences per
`pack-project-separation-of-concerns`), which argues the doc-correction WORK can be split. The architect's
real decision is whether to land the shared-tooling change once (covering both) vs sequence it; the doc
corrections are independently schedulable. Per `pack-project-separation-of-concerns`, byte-identical
pack/project doc statements are still SEPARATE artifacts — do NOT collapse them.

---

## EMPIRICAL-EVIDENCE BLOCKS

All commands run at HEAD `1936136`, branch `v11-dev`, cwd
`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, 2026-06-04.

### EE-1 — project per-entry tree (3 streams; 8 shipped files; no monolith in template)
```
$ find project-template/docs/project -type f | sort
project-template/docs/project/.DS_Store
.../backlog/_intro.md  .../backlog/_rules.md
.../changelog/_format.md  .../changelog/_intro.md  .../changelog/_rules.md
.../implementation-plan/_intro.md  .../implementation-plan/_rules.md
$ ls project-template/docs/project/*.md  → no matches (no shipped monolith mirror)
```
Interpretation: 3 streams, supporting files only (no entry files, no mirror) ship. Conclusion: **SUPPORTED**.

### EE-2 — 16 project-side wrong-model files
```
$ grep -rln "regenerated mirror" project-template/ supporting-docs/ | wc -l   → 16
```
Files: trinity ×3; `docs/project/*/{_rules,_intro}.md` ×6; audit-methodology + pm-startup ×4 + PM-CHAT;
MIGRATION-v10-to-v11.md. Conclusion: **SUPPORTED** (full list §2).

### EE-3 — shared per-entry helpers (5 streams; not client-shipped)
```
$ cat scripts/lib/per-entry/_lib.sh:64
PE_STREAM_KEYS="pack-backlog pack-changelog project-backlog project-implementation-plan project-changelog"
$ grep -A3 '_SANCTIONED_PACK_SIDE_SHIPPED = (' scripts/validate-pack.py
  "scripts/lib/detect.sh", "scripts/pack-help.sh",   (per-entry NOT present)
$ find project-template -name "*tracker*" -o -name "*migrate*"  → tracker.toml.project-example (only)
```
Conclusion: **SUPPORTED** — one shared helper codebase drives all 5 streams; per-entry + tracker tooling
is pack-side (not shipped).

### EE-4 — client conversion regenerates a mirror (BD-206 target)
```
migrate-v10-to-v11/decompose.sh:195   per_entry_regenerate_mirror "$stream_key" "$stream_dir" "$mirror_path"
init-project.sh:1124                  per_entry_regenerate_mirror "$pe_key" "$pe_dir" "$pe_mirror" </dev/null
```
Streams loop (`decompose.sh:146-148` / `init-project.sh:1110-1112`): project-backlog | project-
implementation-plan | project-changelog. Conclusion: **SUPPORTED** — both conversion + greenfield write the
client monolith.

### EE-5 — shared TD anchor form gap
```
decompose.sh:128   anchor_re = re.compile(r"^\*\*(TD-\d+) — ")
```
`TD-\d+` + immediate ` — ` rejects `TD-NNNb — ` / `TD-NNN (…) — ` (same class as the pack's dropped
`BD-167b`). Conclusion: **SUPPORTED** — anchor-form preservation gap on the shared helper.

### EE-6 — tracker forward/reverse operate on a ROOT monolith, not the per-entry tree
```
tracker-migrate-forward.sh:735   backlog_path="$repo_root/BACKLOG.md"        # client surface
tracker-migrate-reverse.sh:1064  backlog_out="$repo_root/BACKLOG.md"         # client surface
$ grep -rn "per_entry_decompose\|per_entry_regenerate" scripts/lib/tracker-*.sh   → (zero hits)
$ grep -rln "docs/project/backlog\|docs/project/changelog" scripts/lib/tracker-*.sh → (zero hits)
```
Conclusion: **SUPPORTED** — tracker forward/reverse never touch the per-entry tree; reverse never
reconstructs per-entry files. The `:1051-1054` "project-side reverse path" comment describes a path that
does not exist in code.

### EE-7 — round-trip test is pack-surface + monolith-byte only
```
tracker-migrate-roundtrip-test.sh:348-349  cp "$fixture_dir/BACKLOG.md" "$test_repo/pack-ops/BACKLOG.md"
tracker-migrate-roundtrip-test.sh:325      "canonical string for byte-equivalent comparison"
```
Conclusion: **SUPPORTED** — no client-surface, no per-entry round-trip coverage.

### EE-8 — pack CI does not validate project per-entry streams
```
validate-pack.py:297-301  STREAMS = ( ("pack-backlog",...), ("pack-changelog",...) )   # 2 pack only
validate-pack.py:288      "project-template/docs/project/<stream>/ are pack-shipped canonical … NOT loaded"
```
Conclusion: **SUPPORTED** — no pack-CI guard on the client no-mirror contract; client-side check lives in
the shipped `audit-methodology` skill.

### EE-9 — tracker subsystem ships nothing to clients (runs against --repo-root)
```
tracker-config.sh:82   client) echo "$root/docs/pack/tracker.toml"
tracker-migrate.sh:53  --repo-root    Path to the repo to migrate (default: CWD)
$ grep -rn "scripts/lib/tracker" scripts/init-project.sh   → (zero hits)
```
Conclusion: **SUPPORTED** — the feature reaches the client as pack-side tooling pointed at the client repo,
not as installed files.

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule (as named in prompt) | Verification evidence (quoted) | Conclusion |
|---|---|---|
| **agents-read-rule-docs-in-full (+ no-derivation)** | READ-IN-FULL row below: every named doc Read DIRECTLY via the Read tool, in full, with per-file proof. No named doc derived from another source. | COMPLIANT |
| **empirical-evidence-blocks** | EE-1..EE-9: each load-bearing claim carries the actual command/file:line + verbatim output + HEAD `1936136` + date 2026-06-04 + interpretation + SUPPORTED conclusion. | COMPLIANT |
| **completeness / exhaustiveness** | Full client-feature inventory (§1, 14 surfaces); all 16 wrong-model files file:line'd (§2); client conversion flow (§3) + tracker reverse path (§4) enumerated; preservation reality (§5); full blast radius table (§6, 19 rows); shared-vs-project-only split (§7). When unsure flagged: `_intro` fate, METHODOLOGY/README verify rows, audit-methodology skill copies, the stale `:1051` comment. | COMPLIANT |
| **pack-project-separation** | §7 separates SHARED tooling (per-entry helpers + reverse emitter) from PROJECT-ONLY (conversion driver, client doc set) and PACK-ONLY (pack §5 set, pack validators); explicit note that byte-identical pack/project docs are SEPARATE artifacts (do not collapse). | COMPLIANT |
| **scope-deliverables-to-the-ask** | Research-only: find + categorize + count; no conversion design proposed (no "do X then Y" recipe). Headline leads. Dispositions name the CLASS of each surface, not the rewrite. | COMPLIANT |
| **rules-applied-verification-block (+ no-derivation)** | This block; every row quoted evidence; READ-IN-FULL row with direct-read proof per named doc. | COMPLIANT |

### READ-IN-FULL row (per-file direct-read proof)
| Document | Direct Read? | Proof |
|---|---|---|
| `CLAUDE.md` (incl. `## Pack memory`) | YES | 541 lines; L1 "# CLAUDE.md — AI Agent Config Pack (Pack Repo)" → L541 "OT itself is read-only … never write to real OT." |
| `pack-ops/PACK-AGENTS.md` | YES | 226 lines; L1 "# PACK-AGENTS.md" → L226 "Always run `git add -A && git status` … before any commit." |
| `pack-ops/PACK-CHAT.md` | YES | 310 lines; L1 "# PACK-CHAT.md" → L310 "verified by END-STATE checks … not a hard-enforced step sequence." |
| `project-template/CLAUDE.md` (client trinity) | YES | 456 lines; L1 "# CLAUDE.md" → L456 "marker is preserved across pack upgrades. New projects start with this H2 empty." |
| BD-203 entry (`pack-ops/BACKLOG.md:3330-3349`) | YES | Read offset 3330 lim 85; header L3330 → Position L3349. |
| BD-204 entry (`:3353-3366`) | YES | same Read; L3353 header → L3366 Position. |
| BD-206 entry (`:3386-3397`) | YES | same Read; L3386 header → L3397 Position. (BD-207 confirmed NOT yet created — grep returned only 203/204/205/206.) |
| `RESEARCH-BD-203-BLAST-RADIUS.md` (pack companion) | YES | 466 lines; L1 title → L466 "every number above is independently measured from primary sources at HEAD 1936136." |
| `project_pack_self_migration_launch_gate.md` | YES | 49 lines; L1 frontmatter → L48 "tracker-mode feature design (BD-060 …)." |
| `feedback_fail_loud_delete_old_source.md` | YES | 55 lines; L1 frontmatter → L55 "do not invent scope." |
| `feedback_researcher_maps_blast_radius_before_architect.md` | YES | 41 lines; L1 → L41 "[[adversarial-architect-review-on-major-gap]]." |
| `feedback_pack_project_separation_of_concerns.md` | YES | 33 lines; L1 → L33 "audience anchors." |
| `feedback_agent_output_rules_applied_block.md` | YES | 15 lines; L1 → L15 Related links. |
| `feedback_agents_read_rule_docs_in_full.md` | YES | 97 lines; L1 → L97 "no-rationale-for-unread-docs rule reinforced in every spawn prompt." |
| `project-template/docs/project/backlog/_rules.md` | YES | 48 lines; L1 → L48 mirror statement. |
| `project-template/docs/project/changelog/_rules.md` | YES | 51 lines; L1 → L51 mirror statement. |
| `project-template/docs/project/implementation-plan/_rules.md` | YES | 49 lines; L1 → L49 mirror statement. |
| `scripts/lib/per-entry/_lib.sh` | YES | 439 lines; L1 header → L439 `pe_id_from_filename`. |
| `scripts/lib/per-entry/decompose.sh` (anchors) | YES | Read anchor block + grepped lines 85-275 directly. |
| `scripts/init-project.sh` S11 (per-entry install + mirror regen) | YES | Read offsets 907-1106 + 1104-1193 directly. |
| `scripts/lib/migrate-v10-to-v11/decompose.sh` | YES | Read streams loop + mirror-regen (`:140-204`) directly. |
| `scripts/lib/tracker-config.sh` | YES | Read `:60-200` directly (surface resolution + reader). |
| `scripts/lib/tracker-migrate-forward.sh` | YES | Read `:728-767` + grepped `:1-720` directly. |
| `scripts/lib/tracker-migrate-reverse.sh` | YES | Read `:1035-1109` + grepped `:1-603` directly. |
| `scripts/lib/tracker-agent-read.sh` | YES | Read `:155-200` + grepped directly. |
| `scripts/validate-pack.py` (STREAMS, _SANCTIONED, _CLIENT_INSTALLED, Check 3) | YES | grepped + Read `:288-301,455-476,4158-4216,288` directly. |
| `supporting-docs/MIGRATION-v10-to-v11.md` | YES | grepped all 24 mirror/monolith refs with line numbers directly. |

**No named document was derived rather than read. The pack-side companion report
(`RESEARCH-BD-203-BLAST-RADIUS.md`) was read for the shared-surface picture, but every project-side claim
above is independently measured from primary sources at HEAD `1936136`.**
