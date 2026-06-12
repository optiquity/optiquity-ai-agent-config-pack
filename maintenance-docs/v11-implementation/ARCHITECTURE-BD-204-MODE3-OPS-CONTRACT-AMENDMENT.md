# ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT — committed id-map relocation (name + location + client analog)

> **Agent:** pack-architect (fresh instance). **Mode:** DESIGN ONLY — repo read-only;
> the sole write is this amendment doc. **HEAD (verified):** `1c18b28`
> (`git rev-parse HEAD` → `1c18b28c4d149d3e80565beafccc84f8d25b32f2`), branch `v11-dev`,
> with the BD-204 C-8 working-tree edits pending (`git status --short`: tracker libs +
> tests modified; `tracker.toml` and `.pack-tracker/` untracked/ignored live Mode-3 state).
> **Date:** 2026-06-11 session.
>
> **What this amends.** `ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md` (the approved Mode-3
> ops-contract design). That design makes the tracker id-map a COMMITTED artifact (§1.1
> Write-authority staging list; §1.3 item 5). It currently lives at
> `.pack-tracker/id-map.json`, inside a directory gitignored as per-user runtime scratch
> (`.gitignore:12` ignores `.pack-tracker/` wholesale).
>
> **FIXED user decision (2026-06-12):** the committed id-map RELOCATES out of
> `.pack-tracker/` so the directory's ignored-runtime semantics stay uniform with zero
> carve-outs; the `!negation` idiom was explicitly REJECTED (and would not work without
> restating the ignore as `.pack-tracker/*` — git cannot re-include a file under an
> ignored DIRECTORY pattern). This amendment decides ONLY: the file's name + pack-surface
> location, the client-surface analog (as a BD-207 requirement), the live-file migration
> mechanics, and the complete blast radius. The relocation itself is not relitigated.
>
> **Consumers:** the user (approval), pack-planner (Commit-2 recipe delta), pack-coder
> (mechanical application), Pack Chat (live-ops sequence + BD-207 R-row), BD-207 refresh.

---

## A1. Decision 1 — Pack-surface location: `pack-ops/tracker-id-map.json`

**Verdict procedure (`pack-ops/BOUNDARY-DEFINITION.md` §3, run on the artifact):**

1. **Audience (step 1):** the committed pack id-map is read/written by the tracker libs
   when their CWD/`--repo-root` is the PACK repo (forward migration, `tracker_edit_entry`,
   the §2 tree-rebuild engine, doctor, promote), and staged by Pack Chat at commit points.
   Per §3's resolving criterion ("the audience is the actor that consumes the file IN THE
   CONTEXT WHERE THE FILE LIVES … WHEN THE CWD IS X"): audience = **PACK**, unambiguously.
   (The tracker libs also ship to clients via `scripts/**`, but the CLIENT'S id-map
   instance is the client's own generated state in the client repo — each instance
   classifies on its own surface; this doc places the PACK repo's instance. The client
   analog is §A3.)
2. **Function (step 2):** not a deliverable, not platform-mandated at a fixed path — it is
   machine state "used to do the work but not itself a deliverable" (§2 Axis-2 OPERATIONS
   definition). Function = **OPERATIONS**.
3. **Verdict: C2 (PACK × OPERATIONS)** → §3 step 3: "C2 PACK × OPERATIONS → its
   purpose-directory (`pack-ops/` for prose ops docs; `scripts/` for scripts;
   `maintenance-docs/` for design records). Per §2.3, purpose classifies and location is
   convention."

**Explicit no-row statement + minimal matrix extension (required by the calling prompt).**
The C2 purpose-directory enumeration (§3 step 3 and the §2 C2 examples row) names three
artifact classes — prose ops docs, scripts, design records. It has **NO row for committed
machine-state operational artifacts**. Placing by analogy alone is therefore insufficient;
the amendment proposes the MINIMAL extension:

> **C2 row extension (one clause, no new category, no new directory, no new convention):**
> in §3 step 3, the C2 arm becomes "… (`pack-ops/` for prose ops docs AND committed
> pack-operational machine-state artifacts; `scripts/` for scripts; `maintenance-docs/`
> for design records)", and the §2 C2 examples row gains `pack-ops/tracker-id-map.json`
> + the existing dotted manifests as named examples.

This extension codifies what `pack-ops/` ALREADY does rather than inventing anything:

> **Empirical-Evidence Block (pack-ops machine-readable precedent).**
> `CMD`: `ls -a pack-ops/`
> `OUT`: `.boundary-exempt-root.txt`, `.boundary-pointer-manifest.txt`,
> `.concision-allowlist.txt`, `.spawn-rule-manifest.txt` + 11 prose `.md` docs.
> `AT`: HEAD `1c18b28`, 2026-06-11. `INTERP`: four machine-readable, CI/validator-consumed
> C2 artifacts already live in `pack-ops/` — the directory is the de-facto home for
> committed pack-operational non-prose state. `CONCL`: SUPPORTED.

**Why NOT pack root (the user-forbidden default, confirmed by rule):** §3 step 4: "If the
verdict places a NEW loose file at pack root, the file MUST be either C1 or C3. Any
PACK × OPERATIONS file appearing loose at root is a regression and is rejected by a CI
gate." §4: the closed-set root exemption list has exactly ONE entry
(`tracker.toml.pack-example`) and "Adding to this list requires explicit user approval.
Adding an entry is a rule change." Root placement would force exemption-list growth for a
file that has a perfectly valid purpose-directory — rejected. (Note Check 38's
IMPLEMENTATION only scans `.md`/`.txt` prose at root — `scripts/validate-pack.py`
`check_pack_only_file_siting` skips non-prose suffixes — so a root `.json` would evade the
CI gate while still violating the §3-step-4 NORM. Evading a gate is not a placement
argument.)

**The `tracker.toml` lifecycle-pairing consideration (addressed, does not transfer).**
How the matrix treats `tracker.toml` itself: the example (`tracker.toml.pack-example`) is
C2 root-exempted by §4 row 1 (user-curation authority). The LIVE `tracker.toml` sits at
pack root because the pack's own tooling MANDATES that path —
`scripts/lib/tracker-config.sh` (`tracker_config_path`): `pack) echo "$root/tracker.toml"`
— i.e., it is admitted at root under the §2 TOOL-CONFIG shape ("mandated at a specific
location by a CLI, build tool, or platform"). The id-map's location is NOT tool-mandated:
this amendment is choosing where the resolver points, so the C3 root admission does not
transfer. Lifecycle pairing (both committed at the same commit points, both
tracker-mode-only) is a STAGING fact, not a placement criterion — §2.3: "PURPOSE
classifies; LOCATION is convention."

**Tracker-mode-only presence:** fine at `pack-ops/`. No CI gate asserts a closed set of
`pack-ops/` contents (Check 38 walks pack ROOT only, non-recursive); a conditionally
present file there breaks nothing. `pack-ops/` is in the 4-directory fixture-manifest
trigger, but the id-map is not client-installed (the only `pack-ops/` copy-site in
`init-project.sh` is `HELP-FRAGMENT-TRACKER.md`), so no install-map / Check 47 impact.

---

## A2. Decision 2 — Filename: `tracker-id-map.json`

Per the trinity `## Pack memory` § Repo conventions filename-uniqueness heuristic
("prefer names that don't collide with any other file anywhere in the repo … check
`find . -name "<proposed-name>" -not -path "./.git/*"` before naming"):

> **Empirical-Evidence Block (proposed-name collision check).**
> `CMD`: `find . -name "tracker-id-map.json" -not -path "./.git/*"`
> `OUT`: (empty — zero hits; `| wc -l` → `0`)
> `AT`: HEAD `1c18b28`, 2026-06-11. `INTERP`: the proposed name is repo-unique.
> `CONCL`: SUPPORTED.
>
> **Empirical-Evidence Block (keeping `id-map.json` would collide).**
> `CMD`: `find . -name "id-map.json" -not -path "./.git/*"`
> `OUT`: `./.pack-tracker/id-map.json`, `./scripts/tests/fixtures/tracker-links/id-map.json`,
> `./scripts/tests/fixtures/tracker-promote/id-map.json`,
> `./test-fixtures/v11-tracker-on/.pack-tracker/id-map.json` (4 hits).
> `AT`: HEAD `1c18b28`, 2026-06-11. `INTERP`: carrying the bare name to the new location
> would create a 5th collision and make prose references ambiguous (committed pack map vs
> client runtime map vs three fixtures). `CONCL`: SUPPORTED — rename required.

**Name rationale:** `tracker-id-map.json` is self-describing (the tracker's pack-id →
issue-id map), joins the existing `tracker-*` family (`tracker.toml`,
`scripts/tracker-migrate.sh`, `scripts/lib/tracker-edit.sh`, …), and is
**surface-generalizable**: BD-207 reuses the identical basename at the client location
(§A3), exactly as the ops-contract did with the `tree-rebuild` verb name.

---

## A3. Decision 3 — Client-surface analog (BD-207 REQUIREMENT, not implementation)

**New requirement row, appended to the ops-contract §5 R1–R8 handoff set (consume
verbatim at BD-207; stated in PROJECT form per P-missed-7 / `boundary-investigation` —
client SSOTs investigated FIRST, quoted below):**

> **R9 — Committed client id-map at `docs/pack/tracker-id-map.json`.** In client tracker
> mode the pack-id → issue map is a COMMITTED artifact (same rationale as the pack
> surface: offline reads + tree↔map consistency at commit points). It lives at
> `<project-root>/docs/pack/tracker-id-map.json` — pairing with the client tracker config
> SSOT location (`tracker_config_path` client arm: `client) echo "$root/docs/pack/tracker.toml"`;
> `project-template/tracker.toml.project-example` header: "Lives at
> `<project-root>/docs/pack/tracker.toml`"), NOT at the client root and NOT inside the
> client `.pack-tracker/`. The client `.gitignore`'s `.pack-tracker/` entry
> (`project-template/.gitignore:10`) stays uniform-ignored with ZERO carve-outs — the
> same user decision (no `!negation`) applied in client form; `.pack-tracker/` retains
> only runtime scratch (checkpoints, sidecars, `links-graph.json` cache,
> `recommendation-state.json`). BD-207 repoints: the surface-aware mapping resolver's
> CLIENT arm (§A4), `project-template/tracker.toml.project-example`
> `migration.mapping_file` value + its "(gitignored)" comment, the
> `project-template/.gitignore` comment ("Mapping file, …" no longer lives there), the
> v10→v11 migrator's client mapping checks
> (`scripts/lib/migrate-v10-to-v11/checkpoint.sh` `checkpoint_check_mapping_integrity` +
> `gate-3-phase-b-verify.sh` PASS-criteria comment), `test-fixtures/build.sh`'s
> tracker-on fixture, and the client-surface tests/fixtures enumerated in §A5. Client
> vocabulary throughout (PM chat / `docs/pack/PM-CHAT.md` / TD namespace) — the pack
> realization is the reference implementation, not the import source.

**Why `docs/pack/` and not the client root (client-SSOT grounding):** the client-side
SSOT for tracker machine config is ALREADY `docs/pack/` — that is where the client's
`tracker.toml` lives by tooling mandate (quoted above). The committed id-map's lifecycle
is bound to that file (created by forward migration, consumed at every tracker read,
staged at the same commit points). The client root is the home of the STREAM state files
(mirrors/STATUS.md until BD-206, per-entry trees' monoliths), not of tracker plumbing;
`docs/pack/` is the pack-authored operational surface at install (BOUNDARY-DEFINITION §2
C5 commentary: "pack-AUTHORED operations content shipped for PROJECT use") and, on the
client surface, already the tracker-config home. Pairing the map with its config keeps
ONE client location for tracker machine state — fewer conventions.

---

## A4. Decision 4 — Migration of the live file

The real `.pack-tracker/id-map.json` exists NOW on the Mode-3 working tree (verified:
`ls -la .pack-tracker/` → `id-map.json` 25347 bytes, plus `links-graph.json` +
`recommendation-state.json`; `git check-ignore -v` → `.gitignore:12: .pack-tracker/`).
It is the ONLY Mode-3 instance in existence.

**Who does what (decided):**

- **Commit-2 coder (code only, no live-state ops):** relocates the PATH RESOLUTION in
  code. Design shape: ONE shared surface-aware resolver — promote the
  `_tmf_mapping_file` pattern (`scripts/lib/tracker-migrate-forward.sh`, currently
  `$repo_root/$TMF_PACK_TRACKER_DIR/id-map.json`) into a surface-conditional
  `tracker_mapping_path <surface> <repo_root>` beside `tracker_config_path` in
  `scripts/lib/tracker-config.sh` (the existing surface-resolution precedent): pack arm →
  `$root/pack-ops/tracker-id-map.json`; client arm → `$root/.pack-tracker/id-map.json`
  UNCHANGED until BD-207 R9 flips it to `$root/docs/pack/tracker-id-map.json`. Every
  hardcoded literal in §A5 group (a) routes through the resolver (surface already
  derivable at each site — `tracker_edit_entry` already calls
  `tracker_config_auto_surface`). The coder also updates tests/fixtures (§A5 groups
  (c)/(d), pack-surface rows) and regenerates `test-fixtures/manifest.txt`
  (`scripts/` + `pack-ops/` touched → the 4-directory trigger fires).
- **Pack Chat (live-ops sequence, with explicit per-action user approval):** moves the
  LIVE file — `cp .pack-tracker/id-map.json pack-ops/tracker-id-map.json`, repoint the
  live `tracker.toml` `migration.mapping_file` value, stage + commit through the normal
  gates, THEN delete the old copy. Justification: a move is copy+delete, and the delete
  leg is a destructive operation on the only live Mode-3 artifact —
  `per-action-approval-sub-agents` forbids agents from running it on their own authority,
  and `agents-never-commit` means only Pack Chat can land the staged new copy anyway. The
  coder never touches `.pack-tracker/` live state; its tests run against scratch fixtures
  (`test infra is self-provisioned`).
- **Ordering (zero-window):** C-8 pending commit lands first (per the ops-contract §6
  sequencing) → Commit 2 (resolver + code) and the live-file move land TOGETHER in the
  same live-ops step — the resolver flip and the file move are one user-approved
  sequence, so no session ever reads the old path after the new code lands.

**Read-path fallback question (decided): FAIL LOUD — no old-path fallback.** The libs
read ONLY the new path on the pack surface; absence is the existing typed error
(`tracker_edit: tracker mode but mapping file absent at <path>`, now naming the new path,
with the recovery hint "re-run the forward migration / copy from
`.pack-tracker/id-map.json` if migrating"). Rationale: (1) the file is REGENERABLE — the
issue-body `pack-id` markers are the source of truth and the forward migration
skip-recovers the map (`tracker-migrate-forward.sh` header: "Mapping file: … is the fast
path; markers are the source of truth"); (2) this repo is the only Mode-3 instance in
existence and the zero-window ordering above means the transition never executes against
a half-moved state; (3) a silent old-path fallback is a SECOND read path — the exact
shape the BD-204 design rejected at DP-1 (loud-not-silent) and the design-elegance focus
forbids (one path, no special case to retire later).

---

## A5. Decision 5 — Blast radius (exhaustive consumer census) + Commit-2 recipe delta

> **Empirical-Evidence Block (consumer census).**
> `CMD`: `grep -rln "\.pack-tracker/id-map\.json" . -I` (excluding `./.git/`), plus
> per-file `grep -c`, plus `grep -rn "tracker_mapping_file\|_tmf_mapping_file" scripts/`.
> `OUT`: 67 files total; non-test code = 11 files / 26 literal+resolver occurrences;
> tests = 15 files; fixture/example TOMLs = 11; live `tracker.toml` = 1; docs = 28
> (mostly archived reports); `.gitignore` comment = 1. Resolver census:
> `_tmf_mapping_file` defined once (`tracker-migrate-forward.sh`), called at
> `tracker-migrate-forward.sh` (×2) + `tracker-migrate-reverse.sh` (×1);
> `tracker_mapping_file()` (`tracker-config.sh:219`, reads `migration.mapping_file`) has
> ZERO callers outside tests.
> `AT`: HEAD `1c18b28` + pending C-8 working-tree edits, 2026-06-11.
> `INTERP`: the path is constant-driven, not config-driven — the `tracker.toml`
> `mapping_file` key is decorative at runtime (test-asserted only). `CONCL`: SUPPORTED.

**(a) Code — pack-surface-affected, Commit-2 coder scope (route through the new resolver):**

| File | Occurrences | Shape |
|---|---|---|
| `scripts/lib/tracker-migrate-forward.sh` | resolver `_tmf_mapping_file` + header comments (lines-class: 2 comments) | canonical resolver — becomes/delegates to the surface-aware resolver |
| `scripts/lib/tracker-migrate-reverse.sh` | 1 resolver call | no literal; inherits resolver |
| `scripts/lib/tracker-edit.sh` | 1 hardcoded literal | `mapping_file="$repo_root/.pack-tracker/id-map.json"` |
| `scripts/lib/tracker-doctor.sh` | 1 hardcoded literal | same shape |
| `scripts/lib/tracker-agent-read.sh` | 2 (literal + help text) | same shape + user-facing text |
| `scripts/lib/tracker-promote.sh` | 10 (8 literal + 2 comments) | flat-vs-tracker presence probe + load/save sites |
| `scripts/lib/tracker-init.sh` | 3 (prior-state rail, error text, `tracker.toml` heredoc writer line 403-class) | the WRITER of the `mapping_file` default — must emit the new pack-surface value (surface-aware: init on client surface keeps client value until BD-207) |
| `scripts/pack-tracker.sh` | 1 hardcoded literal (`update-templates` entry index) | route through resolver |
| `scripts/pack-td.sh` | 2 hardcoded literals | CLIENT-surface noun (TD) — takes the resolver's client arm; behavior unchanged until BD-207 |
| `scripts/validate-pack.py` | `migration.mapping_file` schema assert (value-agnostic — no change) + TWO basename-allowlist dicts carrying `"id-map.json": "Generated tracker-mode metadata (not in pack repo)"` | the pack-side dict entry's "(not in pack repo)" rationale becomes FALSE post-commit; add `tracker-id-map.json` entry + correct the comment |

**(b) Code — client-surface consumers, BD-207 scope (FLAG only; no Commit-2 edit):**
`scripts/lib/migrate-v10-to-v11/checkpoint.sh` (`checkpoint_check_mapping_integrity`, 2
occurrences) and `scripts/lib/migrate-v10-to-v11/gate-3-phase-b-verify.sh` (1, PASS-criteria
comment) — the v10→v11 migrator runs against CLIENT targets; `test-fixtures/build.sh` (2 —
the `v11-tracker-on` CLIENT fixture, TD prefix). These bind to R9.

**(c) Tests (15 files; pack-surface rows update with Commit 2, client-surface rows with BD-207):**
`tracker-config-test.sh` (3 — asserts the getter returns the TOML value),
`tracker-init-test.sh` (4), `tracker-config-schema-test.sh` (6),
`tracker-migrate-forward-test.sh` (11), `tracker-migrate-reverse-test.sh` (6),
`tracker-migrate-roundtrip-test.sh` (4), `tracker-bd204-lossless-roundtrip-test.sh` (1),
`tracker-bd132-race-test.sh` (6), `tracker-bd134-close-retry-test.sh` (1),
`tracker-agent-read-test.sh` (3), `tracker-provider-test.sh` (1),
`test-tracker-promote-path1.sh` (2) / `-path2.sh` (8), `test-tracker-cycle-check.sh` (1),
`template-translations-test.sh` (2); plus `test-migrate-v10-to-v11-gates.sh` (7 —
group (b), BD-207).

**(d) Config values (`migration.mapping_file`) + the live file:**
live `tracker.toml` (untracked; Pack Chat repoints in the live-ops sequence, §A4),
`tracker.toml.pack-example` (value + the "(gitignored)" comment — now WRONG twice over),
`project-template/tracker.toml.project-example` (BD-207 R9),
`scripts/tests/fixtures/tracker-config/*.toml` (5), `fixtures/tracker-migrate/tracker.toml`,
`fixtures/roundtrip/bd-v11.0/tracker.toml`, `fixtures/tracker-bd204-lossless/tracker.toml`
(pack-vs-client fixture surface decides Commit-2 vs BD-207 treatment).

**(e) Doc surfaces stating the old path (live, forward-pointing — archived reports exempt):**

1. `ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md` §1.1 Write-authority staging list ("… +
   `.pack-tracker/id-map.json` through the normal commit gates") and §1.3 item 5 — THIS
   AMENDMENT supersedes both occurrences; the Commit-1 coder writes the `_rules.md` /
   PACK-CHAT.md text with `pack-ops/tracker-id-map.json`.
2. `PLAN-BD-204-MODE3-OPS-CONTRACT.md` (8 occurrences) — the planner consumes the
   Commit-2 recipe delta below.
3. `.gitignore` comment block at `.pack-tracker/` ("Mapping file, migration checkpoints,
   and reverse-migration sidecars. Never committed …") — drop "Mapping file" from the
   enumeration; the ignore RULE itself is untouched (zero carve-outs, per the user
   decision).
4. `backlog/BD-065.md` + `backlog/BD-106.md` — historical entry content (resolved-era
   records); LEAVE AS-IS (history, not live instruction; and in Mode 3 tree files are
   regenerated mirrors — any edit would go through the tracker tooling for no
   operational gain).
5. `backlog/BD-207.md` — gains the R9 requirement row (Pack Chat, via the tracker
   tooling per the Mode-3 write contract, user-approved).
6. `tracker.toml.pack-example` comment + `project-template/tracker.toml.project-example`
   comment (counted in (d); named here because the "(gitignored)" prose is a doc claim).

**Commit-2 recipe delta (hand to the planner):**

1. Add surface-aware `tracker_mapping_path` resolver (pack → `pack-ops/tracker-id-map.json`;
   client → `.pack-tracker/id-map.json` until BD-207) in `tracker-config.sh`;
   `_tmf_mapping_file` delegates or retires into it.
2. Route ALL group-(a) literals through the resolver; update help/error/comment text at
   each site (typed errors name the resolved path).
3. `tracker-init.sh`: heredoc writer emits the surface-correct `mapping_file` value;
   prior-state rail probes the surface-correct path.
4. Disposition the dead `tracker_mapping_file()` config getter (OQ-B below).
5. `tracker.toml.pack-example`: value + comment ("committed; offline reads +
   tree↔map consistency").
6. `scripts/validate-pack.py`: basename-allowlist additions/corrections (group (a) last row).
7. Group-(c) pack-surface test updates + a new test leg: resolver returns the
   pack-ops path on the pack surface and the legacy path on the client surface; plus
   fail-loud absent-map leg names the NEW path.
8. `.gitignore` comment edit (group (e) item 3).
9. Regenerate `test-fixtures/manifest.txt` (`scripts/` + `pack-ops/` trigger), stage in
   the SAME commit.
10. `pack-ops/BOUNDARY-DEFINITION.md` §2/§3 C2-row minimal extension (§A1) — a RULE edit:
    this amendment is the architect pass; the coder applies mechanically after user
    approval; per the doc's footer, update `pack-ops/.boundary-pointer-manifest.txt` in
    the same commit IF the pointer set changes (expected N/A — no pointer change, planner
    verifies).
11. Live-ops sequence (Pack Chat, per-action approval): `cp` live map → repoint live
    `tracker.toml` → stage/commit → delete old copy (§A4).

**Flagged, not silently scoped (OQ-B — user decision):** the `migration.mapping_file`
TOML key is decorative at runtime (zero non-test callers of `tracker_mapping_file()`).
Options: (i) keep the key as documentation, repoint values, have the resolver stay
constant-driven (smallest diff; key remains decorative — comment must say so); (ii) wire
the resolver to honor the key with the constant as default (config becomes real; larger
test surface). Either is compatible with this design; (i) is the minimal-change
recommendation. User gates.

---

## A6. CONTRADICTION-FOUND

**NONE against the ratified rule sets or the fixed user decision.** Two reconciliations
recorded for completeness, neither a live contradiction:

1. The approved ops-contract's §1.1/§1.3 staging text ("commit `.pack-tracker/id-map.json`")
   contradicted `.gitignore:12` (`.pack-tracker/` wholesale-ignored) — that is the defect
   the user's relocation decision RESOLVES; this amendment supersedes the two staging-list
   occurrences (§A5 (e) 1).
2. `scripts/validate-pack.py`'s basename-allowlist rationale `"id-map.json": "Generated
   tracker-mode metadata (not in pack repo)"` becomes false for the pack surface
   post-relocation — handled as blast radius (§A5 group (a)), not a rule conflict.

---

## A7. READ-IN-FULL attestation (per-file direct-read proof, this session)

| # | File | Proof (path + line count, read this session) |
|---|---|---|
| 1 | `pack-ops/BOUNDARY-DEFINITION.md` | Read IN FULL via Read tool, 135 lines (§1–§6 + footer). |
| 2 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md` | Read IN FULL via Read tool, 556 lines (§0–§9). |
| 3 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` | Read IN FULL via Read tool, 579 lines, incl. the complete `## Pack memory` section (filename-uniqueness heuristic, P-missed-7, dependency-direction-placement, manifest-regen rule). |
| 4 | `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_agent_output_rules_applied_block.md` | Read IN FULL via Read tool, 15 lines. |
| 5 | Section-reads (verified directly, as instructed): `scripts/lib/tracker-config.sh` (header + `tracker_config_path` + getters region incl. line-219 getter); `scripts/lib/tracker-migrate-forward.sh` (path-resolvers region 170–210 + header comments + grep census); `scripts/lib/tracker-migrate-reverse.sh` (mapping_file grep census — resolver call at orchestrator); `scripts/lib/tracker-edit.sh` (205–235, id-map resolution + surface detection); `scripts/lib/tracker-doctor.sh` (65–102 region via grep); `scripts/lib/tracker-init.sh` (60–90 prior-state rail + 395–410 heredoc writer); `scripts/lib/tracker-promote.sh` (grep census, 10 occurrences); `scripts/pack-tracker.sh` (275–300); `scripts/pack-td.sh` (grep census); `scripts/lib/migrate-v10-to-v11/checkpoint.sh` (385–400) + `gate-3-phase-b-verify.sh` (20–96); `scripts/validate-pack.py` (Check 38 in full 4745–4840 + scope-keyword constants region + mapping_file/id-map grep census + allowlist contexts 5080–5100, 5485–5505); `.gitignore` (FULL via cat); `tracker.toml` (FULL — live); `tracker.toml.pack-example` (FULL); `project-template/tracker.toml.project-example` (header 1–25 + mapping_file context); `project-template/.gitignore` (`.pack-tracker/` section); `pack-ops/.boundary-exempt-root.txt` (FULL); `test-fixtures/build.sh` (585–615). |

No named document was derived rather than read; every file above was opened via
Read/Bash this session at HEAD `1c18b28` (+ pending C-8 working-tree edits).

---

## A8. Rules-Applied Verification Block

| Rule (as named in the prompt) | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Git verbs run this session: `git rev-parse HEAD`, `git status --short`, `git check-ignore -v .pack-tracker/id-map.json` — all read-only. The sole filesystem writes are the chunked `cat >` / `cat >>` writes of THIS file; no `add/commit/push/tag/stash/reset/restore` run; no other repo file edited. | COMPLIANT |
| **per-action-approval-sub-agents** | Zero destructive ops: no `rm`/`rm -rf`/`git rm`/file overwrite of any trusted file — the output path was non-existent pre-session (`find . -name "ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT.md" -not -path "./.git/*"` → empty). Zero live GitHub calls: no `gh` invocations, no GitHub MCP tool calls; all evidence is local reads. The live-file move is explicitly DESIGNED as a Pack-Chat-with-user-approval step (§A4), not performed. | COMPLIANT |
| **preflight-stop-means-stop** | Emitted before the first write chunk, verbatim: `PREFLIGHT: amendment complete; 5 elements decided; about to Write to maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT.md`. No parent stop/halt/revert message received at any point; all commands ran foreground to completion (no background tasks armed). | COMPLIANT |
| **agent-output-rules-applied-block** | This table: 8 rows (one per prompt "Rules in force" item), each with quoted measurement evidence; zero empty cells. The memory file supplying the format contract was read in full (15 lines, §A7 row 4). | COMPLIANT |
| **agents-read-rule-docs-in-full** | §A7 attestation: 4 named files read IN FULL with line counts (BOUNDARY-DEFINITION.md 135; ops-contract architecture doc 556; CLAUDE.md 579; memory file 15) + every instructed section-read verified directly (§A7 row 5). | COMPLIANT |
| **boundary-investigation-precedes-defaults** | The placement decision opens from BOUNDARY-DEFINITION.md §3's four-step verdict (§A1 quotes the C2 row, §3 step 4, §4 closed-set rule, §2.3 principle) — root-by-convenience explicitly rejected WITH the rule citation the user demanded. The client analog (§A3) starts from CLIENT SSOTs: `tracker_config_path` client arm `"$root/docs/pack/tracker.toml"` (quoted), `tracker.toml.project-example` header (quoted), `project-template/.gitignore:10` — no pack mechanism imported into the R9 row. | COMPLIANT |
| **user-prescriptive-authority** | The relocation itself is treated as FIXED throughout ("FIXED user decision (2026-06-12)… not relitigated", header; `!negation` rejection restated with the technical confirmation it could not work). Only name / place / client-analog / migration mechanics are decided, per the prompt's delegation. No ratified BD-204 rule re-argued; the two §A5(e)-1 superseded staging-list occurrences implement the user decision rather than challenge the design. | COMPLIANT |
| **scope-deliverables-to-the-ask** | The doc contains exactly the five prompt elements as §A1–§A5 (location, filename, client analog as an R-row, migration, blast radius + Commit-2 recipe delta), plus the prompt-required CONTRADICTION-FOUND (§A6), attestation (§A7), and this block (§A8). The single addition is OQ-B (dead config getter) — flagged as a user-gated disposition surfaced BY the blast-radius census, with a minimal-change recommendation, not silent scope growth. No project-side implementation; BD-207 items stated as requirements only. | COMPLIANT |

---

**End of ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT.md**
