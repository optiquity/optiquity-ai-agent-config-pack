# MERGE-STRATEGY.md — per-file customization preservation contract

> **Audience: pack-internal.** This document is pack-internal reference
> for pack maintainers running the migrator. Project users encounter
> the per-class disposition tokens via the `report.md` produced by the
> migrator; they do not read this file directly. References here to
> other pack-internal docs (e.g., `HELP-FRAGMENT-PACK.md`) and
> pack-shipped agent files are appropriate at this pack-only path.

When `init-project.sh --update` or `scripts/migrate-v10-to-v11.sh`
refresh a project to a newer pack version, every file the migrator touches
is dispatched to a per-class preservation strategy implemented in
`scripts/lib/customization-preserve.sh`. This document is the
**user-readable matrix** of those rules — what each class does, what kind
of customization it preserves, and what to do when the migrator reports a
file as needing manual reconciliation. The same matrix applies symmetrically
to both upgrade paths.

---

## How to read this document

Every file the migrator touches belongs to one of 11 classes. For each
class:

- **Strategy** — the preservation algorithm
- **What's preserved** — the project-side content that survives a refresh
- **What gets updated** — the pack-side content that gets adopted
- **Disposition tokens** — the labels that appear in `report.md`
- **What to do on `customization-detected-needs-reconciliation`** — the
  action you take when the migrator flags a file for review

Disposition tokens are the truthful-report contract — every file
the migrator processes produces exactly one row in `dispositions.tsv`,
listed in `report.md` under one of:

- `unchanged-pack` — file is byte-equal across baseline / project / new pack
- `pack-update-applied` — pack updated; project hadn't customized
- `merged-with-customization` — project edits preserved; pack changes adopted
- `customization-detected-needs-reconciliation` — both sides edited; sidecar written; YOU resolve
- `removed-by-design` — pack retired the file
- `project-only-file` — project-owned file the pack does not ship
- `project-deleted-pack-kept` — project deleted a file pack still ships
- `removed-everywhere` — already absent on both sides

---

## The four merge behaviors (auto-merge summary)

The 11 classes reduce to **four merge behaviors** for a both-edited file; each
ships only a provably-lossless result. The `resolve-merge-conflicts` skill runs
AFTER dispatch behind a zero-loss gate, never auto-invoked by the migrator.

| Behavior | Classes | Handler | Both-edited outcome | Zero-marker path |
|---|---|---|---|---|
| **Prose auto-merge** | `generic`, `pm-chat` | `tw_merge_file` (git `merge-file -p --diff3`), real line-level 3-way | different-line → clean union, drop sidecar, `merged-with-customization`; same-line → `--diff3` markers, keep sidecar, `needs-reconciliation` (action `merged`) | dispatch (different-line) OR the skill (same-line markers) |
| **Trinity graft-or-fold** | `CLAUDE/AGENTS/GEMINI.md` | marker-aware graft (`marker_preserve_trinity`) | WRAPPED → clean graft, `merged-with-customization`; UNWRAPPED hand-edit → sidecar (+ stashed `.v10-base`), `needs-reconciliation` (class `trinity`) | the graft (wrapped) OR the skill's section-aware fold (unwrapped) — automating `supporting-docs/PRE-RECONCILE-v10-to-v11.md`'s recipe |
| **Hand sidecar (no line-merge — safety)** | `pack-script`, `pack-agent` | loud sidecar; NEVER line-merged | OURS → sidecar, THEIRS → live file, `needs-reconciliation` | client HAND-reapplies over the pack file (skill out of scope) |
| **Structured key-merge** | JSON / TOML configs | key-union (`scripts/merge-json.py` / `scripts/merge-toml.py`) over the BASE resolved below | pack-authored OURS → adopt THEIRS whole-file, `pack-update-applied`, no sidecar; else clean key-merge, warnings on overlap; rc-error → sidecar | dispatch (key merge); skill N/A |

### Structured BASE on a refresh

The base cascade is text-class only, so a refresh reaches a structured file
with NO recorded BASE — and a BASE-less three-way cannot tell a stale PACK
value from a client edit. It keeps the project value, which freezes every
diverged pack key in the file, including keys the client never touched. Two
arms supply the missing ancestor from the pack's own object history. Both
reach the merge as a signal only: `three_way_classify` still runs on the empty
BASE, so the dispatch it selects is unchanged.

| Arm | Condition | Result |
|---|---|---|
| Whole-file | OURS is byte-identical to a blob the pack has held at that SOURCE path | adopt THEIRS whole-file; `pack-update-applied`; no sidecar |
| Per-key | OURS is not such a blob — the client edited something | `scripts/lib/pack_provenance_keys.py` derives a per-key ancestor; the normal key-merge then runs against it, so an edited key keeps the project value while an untouched key takes THEIRS |

The per-key derivation selects the best-matching historical blob, then adopts
OURS's own value at every key the pack has held that value at — including keys
the selected blob itself does not carry. A key whose value NO historical blob
has held is a genuine client addition and gets no BASE entry at all. List
elements are never promoted into the derived BASE: `merge_list` reads a
BASE-only element as a project removal, so promoting one would delete a value
the client still holds.

Both arms require the baseline objects to be reachable. When they are not,
`_CU_BASELINE_OK` withholds both and the run says so on stderr. A derivation
that runs and simply finds no usable candidate is a different case and is
silent: the file keeps base-absent key-union behavior, which is the same
outcome as before either arm existed.

### What the derived BASE changes about removals

Supplying an ancestor changes what a removal MEANS, in both directions. This
is a behavior change for every existing client, so it is stated rather than
left to be discovered:

| Shape | Base-absent (before) | With a derived BASE |
|---|---|---|
| Client deleted a pack key, pack still ships it unchanged | key comes BACK on every refresh | client's deletion is HONOURED |
| Client deleted a pack-shipped list element | element comes BACK | deletion is HONOURED |
| Pack RETIRED a value the client still holds | value is KEPT | value is REMOVED, at rc 0 |

The first two are the point: re-granting something the client deliberately
removed is the wrong default, most sharply for `permissions.allow`, where it
silently restores a capability.

The third is the cost of the same inference, and it lands on the clean arm —
rc 0, no warning, no sidecar, no `.pre-update` copy. It is therefore reported
rather than warned: both merge helpers run a post-merge census of every value
OURS held that the result does not, emit one `notice:` line per value, and the
`merged-with-customization` disposition row carries the count. `notice:` and
not `warning:` is deliberate — a warning is what returns rc 2, rc 2 is what
writes a sidecar, and a sidecar is what blocks the next `--update`, so routing
an intended outcome through that channel would rebuild the reconciliation loop
the derivation exists to end.

### Sidecars that cannot be reconciled

`--update` refuses to start while a `.pre-update` sidecar exists, because a
second run would overwrite it and destroy the client's pre-update content.
A sidecar whose bytes are IDENTICAL to the live file it shadows is exempt from
that gate.

The exemption exists because one shape otherwise has no exit. A client who
deleted a WHOLE key the pack is still editing gets `project removed; pack
edited` — a genuine conflict, correctly rc 2 — on every run. The merge honours
the removal, so the live file never changes, so each run writes a sidecar
identical to it. Deleting the sidecar by hand resolves nothing and the next run
re-creates it, and until then the WHOLE tree's refresh is blocked. Exempting an
identical sidecar costs the gate nothing: the content it protects is the
client's pre-update bytes, and those bytes are still in the live file. A
sidecar that DIFFERS still blocks, and that block terminates, because
reconciling the file is something the client can finish. Deleting a whole key
is the only shape that reaches this; deleting a sub-key merges cleanly.

---

## Install (base-absent) merge

The matrix above governs a **refresh** (`--update` / migrate) with a previous-pack
baseline. A **fresh** `scripts/init-project.sh` run has NO baseline — every merge
is base-absent (Regime B). It fires when a fresh install collides with a
**handwritten trinity** (`CLAUDE.md`/`AGENTS.md`/`GEMINI.md`, no pack agent/skill
tree — routed to the guided `--trinity=keep|replace|merge` branch) or with an
**existing-source** project's own structured config.

| Collision class | Install behavior | Recovery / follow-up |
|---|---|---|
| **trinity — `merge`** | pack template live; original stashed to `<file>.user-orig`; one `merge-2way` row in `<TARGET>/.pack-install-reconcile/dispositions.tsv` | fold `<file>.user-orig` into the pack markers via the `resolve-merge-conflicts` skill (**Case 3**), which KEEPS `<file>.user-orig` on success |
| **trinity — `replace`** | pack template live; original stashed to `<file>.user-orig` (pure recovery); NO row | keep/discard `<file>.user-orig`, or hand-reapply |
| **trinity — `keep`** | your files stay live; pack version → `<file>.pack-template` | reconcile from `<file>.pack-template` by hand |
| **structured config** (JSON/TOML) | 2-way **key-union** in place (project keys win a scalar conflict; pack-only keys added; project-only kept), driven off `customization_classify` | none — union applied live |
| **every other collision** | your file stays live; pack version → `<file>.pack-template` | hand-reapply over the pack file |

**Never-lose floor (`merge`/`replace`).** The guarded order is non-reorderable:
(1) copy the live file to `<file>.user-orig`; (2) verify it byte-equals the live
file BEFORE any overwrite (a pre-existing `<file>.user-orig` aborts loud); (3)
ONLY THEN overwrite with the pack template (it touches the live file LAST) — so
the recovery copy is always the project's original bytes. An absent sibling (a
lone-`CLAUDE.md` starter's missing `AGENTS.md`/`GEMINI.md`) is a plain install
with NO `.user-orig` and NO row.

**Honest 2-way completeness.** The fold has no baseline, so Case 3's completeness
leg is a **lower bound**: it confirms every OURS line differing from the pack
sits inside a marker region — which a dropped MULTI-LINE unit whose lines each
coincide with pack lines can still pass. A green leg is NOT proof nothing dropped;
`<file>.user-orig` is the floor, kept on success.

**Parse-error fallback (F6).** The structured merge runs against a throwaway
probe; only clean merged bytes are promoted. On a PARSE ERROR init does NOT adopt
the pack file silently — it keeps the user file live plus a `<file>.pack-template`
sidecar, so a malformed config never loses the project's version.

**State-dir lifecycle.** `<TARGET>/.pack-install-reconcile/` is created ONLY by a
`--trinity=merge` install (recording the `merge-2way` rows Case 3 reads).
Structured key-unions merge in place with no bookkeeping-dir residue — a
no-trinity install produces no `.pack-install-reconcile/` at all.

**Realized empty-BASE (Regime B) consumer.** The empty-BASE path of
`marker_preserve_trinity` (`scripts/lib/marker-preserve.sh`) is realized by the
`resolve-merge-conflicts` skill's Case 3
(`project-template/skills/resolve-merge-conflicts/SKILL.md`): the guided `merge`
branch records the `merge-2way` `trinity` row and Case 3 reads it. `tw_merge_file`
(`scripts/lib/three-way-merge.sh`) refuses a no-BASE merge, so the trinity 2-way
fold is an AI-skill job, not a `tw_merge_file` call.

---

## The 11 file classes

### 1. `trinity` — `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`

**Strategy:** marker-aware graft via `scripts/lib/marker-preserve.sh`
(`marker_preserve_trinity`), with a markerless-trinity fallback to the
legacy 3-way text dispatch.

A project wraps its trinity customizations in HTML-comment marker pairs
(`<!-- BEGIN project-owned -->` … `<!-- END project-owned -->`) so they
survive byte-identical across a pack refresh. Two shapes:

- **Shape A** — the pack owns the H2 heading + canonical body; the
  project's additions are wrapped INSIDE the section body (the H2 sits
  OUTSIDE the markers). The pack body outside the markers is refreshed;
  the marked region is preserved verbatim.
- **Shape B** — the project owns a whole section: the marker pair wraps
  the heading line + entire body. Used for new project sections, renamed
  optional sections, and overrides — a Shape B pair whose H2 name matches
  a pack section suppresses the pack version; a `renamed-from` annotation
  extends the override match key (multi-name supported).

**BASE-preferred, degrade-safe.** The engine reconciles each pack
section's out-of-marker body under one of two regimes and emits a clean
`merged-with-customization` graft ONLY when that reconciliation is
provably safe — otherwise it routes to the SAME sidecar /
`needs-reconciliation` path the legacy classes use. The worst
case for a marked trinity is exactly today's behavior (a safe, loud
sidecar), never a silent overwrite or silent keep.

- **Regime A — BASE present (migrator).** The previous-pack baseline
  (extracted from the pack repo's `v10` git tag) attributes each
  divergence: an out-of-marker body equal to BASE → the project did not
  edit it → adopt the new pack body (clean graft); an out-of-marker body
  ≠ BASE → the project edited pack body outside its markers → sidecar
  (never silent). This is the real 3-way with teeth.
- **Regime B — BASE absent (`init-project.sh --update`, or a not-found
  baseline).** No baseline can attribute the divergence, so the engine
  degrades conservatively: an out-of-marker body equal to the new pack
  body → clean graft; anything else → sidecar / `needs-reconciliation`
  (never a silent pack-body adoption).

The graft is whole-file: if ANY pack section's out-of-marker body (or the
preamble) conflicts under the active regime, the WHOLE file routes to the
sidecar. On a fully-clean file the engine emits the new pack's canonical
section sequence with the project's Shape B overrides spliced in at their
canonical position, project-original Shape B sections appended, and each
Shape A block re-grafted at the tail of its adopted host section.

**`[CONDITIONAL]` retirement (BASE-aware).** A trinity arriving with a
`## `/`### ` heading carrying the literal `[CONDITIONAL]` prefix is
adjudicated before the marker branch. BASE present and the section body
is unedited (base == ours) → the section auto-adopts the pack's
already-retired canonical (bare heading + `<!-- OPTIONAL: … -->` hint),
no sidecar. BASE present with a customized `[CONDITIONAL]` body, or BASE
absent → fail loud to a sidecar with a keep-vs-delete message (the
literal prefix must not remain).

**`renamed-from` with no canonical match (BASE-aware soft-classify).**
BASE proves the named section existed and the new pack dropped it
(retirement) → benign soft no-op; BASE never had it (typo) → hard
conflict; BASE absent → conservative conflict whose message names the
retirement possibility.

**What's preserved:** every project marker region, byte-identical —
Shape A additions inside a pack section and whole Shape B project
sections alike.

**What gets updated:** the pack-owned skeleton (headings + out-of-marker
canonical body) when it evolved between the baseline and the new pack.

**On `customization-detected-needs-reconciliation`:** an UNWRAPPED hand-edit
routes to a sidecar (`.v10-customized` migrator / `.pre-update` `--update`),
and — on the migrator path — the v10 baseline is stashed as `<file>.md.v10-base`
(the third merge input). Resolve by running the `resolve-merge-conflicts` skill
(folds the sidecar into the marker sections section-aware, behind a zero-loss
gate) or by hand per `supporting-docs/PRE-RECONCILE-v10-to-v11.md` (which the
skill automates); then delete the sidecar and `git add`. Never auto-invoked.

---

### 2. `claude-settings` — `.claude/settings.json`, `.claude/settings.json.example`

**Strategy:** allowlist-based JSON key-merge via `scripts/merge-json.py`.

The classifier auto-emits `claude-settings` for paths matching
`.claude/settings.json`. (The departing v10 `.gemini/settings.json` is
NOT routed through this class on a v10→v11 migration — Gemini is retired
to `gemini-retired-docs/`; Antigravity reads MCP config from
`.agents/mcp_config.json`, not a per-CLI settings file.)

Recursive key-union over BASE / OURS / THEIRS, with set-difference logic
for arrays. Pack-managed top-level keys adopt new pack values; project-
tuned keys (e.g., `XCODE_SCHEME`, `XCODE_DESTINATION`, project-specific
permission entries) survive intact.

**What's preserved:** every project-set key not in the pack baseline,
plus project edits to any pack-shipped key.

**What gets updated:** pack-shipped keys whose project value matched
the baseline (no project edit). On a refresh the baseline is resolved per
"Structured BASE on a refresh" above.

**On `customization-detected-needs-reconciliation`:** rare — only when
both sides edited the same scalar key with conflicting values.
`scripts/merge-json.py` writes warnings to `<state-dir>/diffs/...merge-warnings.log`.
Inspect, choose the correct value manually, edit any CLI's settings.json
file (e.g., `project-template/.claude/settings.json`), remove the sidecar.

---

### 3. `claude-mcp-example` — `.mcp.json.example`, `.mcp.json`

**Strategy:** same as `claude-settings` (JSON allowlist via `scripts/merge-json.py`).

The MCP example file is a template; project edits to add custom MCP
servers (e.g., a dev/stage GraphQL endpoint) are preserved.

---

### 3a. `mcp-config-json` — `.agents/mcp_config.json`, `.agents/mcp_config.json.example`

**Strategy:** same as `claude-mcp-example` (JSON allowlist via
`scripts/merge-json.py`).

The Antigravity workspace MCP config is `mcpServers`-shaped JSON, portable
across MCP clients; the class name is CLI-neutral by design. Project edits
to add custom MCP servers, or to tune `BASE_DIR` / `DB_PATH`, are preserved
via key-level union rather than clobbering the live file on a both-edited
update.

---

### 4. `codex-config` — `.codex/config.toml`, `.codex/requirements.toml`

**Strategy:** allowlist-based TOML key-merge via `scripts/merge-toml.py`.

Mirrors `scripts/merge-json.py`'s contract but at the TOML table level. The
canonical OT case is `[model_providers.ollama]` / `[model_providers.lmstudio]`:
project intentionally removes a section; pack still ships it; the
migrator honors the project-side removal (set-difference logic).

**What's preserved:** project-intentional section removals, project-set
provider keys, project-tuned table values.

**What gets updated:** new sections / new keys the pack added since
the baseline that the project hasn't touched.

**On `customization-detected-needs-reconciliation`:** same recipe as
JSON — read the warnings log, reconcile manually.

---

### 5. `codex-config-example` — `.codex/config.toml.example`

Same strategy as `codex-config`.

---

### 6. `pm-chat` — `docs/pack/PM-CHAT.md`

**Strategy:** prose auto-merge — the `_cp_strategy_text` real-merge arm
(`tw_merge_file`), identical behavior to `generic` (class 11).

PM-CHAT.md mixes pack-managed operating rules with project customizations
(project-name substitution, role definitions); both layers survive the real
3-way merge exactly as `generic` — a clean union, or `--diff3` markers +
sidecar on overlap, resolved by hand or via the `resolve-merge-conflicts` skill.

---

### 7. `custom-agent` — `.claude/agents/x-*.md`, `.codex/agents/x-*.md`, `.agents-plugin/*/agents/x-*.md` (and legacy-READ `.gemini/agents/x-*.md`)

**Strategy:** unconditional preservation. Project-owned by reserved-prefix
contract (V3 §I.4); the pack never ships an `x-`-prefixed agent and the
migrator never overwrites one.

**Surfaces.** The class covers BOTH the loose per-CLI agent dirs
(`.claude/agents/`, `.codex/agents/`) AND the Antigravity plugin bundle
(`.agents-plugin/*/agents/`, e.g. `.agents-plugin/optiquity-agents/agents/`).
The classifier tests the `x-` filename prefix FIRST so a client custom in
the SHARED bundle namespace is told apart from a pack bundle agent and is
protected from replace-if-different. The departing v10 `.gemini/agents/x-*.md` leg is a legacy-READ
carve-out: the migrator classifies the departing Gemini custom so it can
LIFT it into the Antigravity bundle (next paragraph).

**Gemini→Antigravity lift (v10→v11 migration).** On a v10→v11 migration
the client's custom (`x-`) agents are KEPT — the migrator copies each
departing `.gemini/agents/x-*.md` (falling back to `.claude/agents/x-*.md`)
INTO the Antigravity bundle at `.agents-plugin/optiquity-agents/agents/`
so it becomes a live Antigravity agent (it does NOT require manual
re-creation). The whole departing `.gemini/` tree is then moved to
`gemini-retired-docs/` as a BACKUP. The loose `.claude`/`.codex` `x-`
copies stay preserved in place (Claude/Codex still read their loose dirs).

**Disposition:** always `project-only-file` (preservation on bump; the
one-time Gemini→bundle lift is a direct copy, never a clobber of a
same-named bundle custom).

---

### 8. `pack-agent` — `.claude/agents/<non-x>.md`, `.codex/agents/<non-x>.md`, `.agents-plugin/*/agents/<non-x>.md` (and legacy-READ `.gemini/agents/<non-x>.md`)

**Strategy:** 3-way text dispatch — replace-if-different on a pack
version bump.

Pack-shipped agent files (e.g., the pack-architect / pack-reviewer set of
agents at `.claude/agents/` and the Antigravity bundle at
`.agents-plugin/optiquity-agents/agents/`). Pack agents are not
client-modifiable, but a config-pack version bump CAN update them: on a
bump/migrate the new pack agent REPLACES the client's copy when it
DIFFERS (`cmp -s` byte-comparison), ADDs it when the client lacks it, and
preserves a client-edited copy via sidecar when the pack ALSO changed —
identical treatment across the loose surfaces AND the Antigravity bundle.
Trinity rule applies — refreshes are delivered in lockstep across the CLI
variants.

**No line-merge (safety).** A both-edited agent is NEVER line-unioned (a blind
merge can be clean yet behaviourally wrong): it gets a loud sidecar — re-apply
by hand over the pack v11 file; the skill is out of scope.

---

### 9. `custom-script` — `scripts/x-*.sh`, `scripts/<project-added>.{sh,py}`

**Strategy:** unconditional preservation when reached.

**Reachability:** the auto-classifier (`customization_classify`) routes
all `scripts/*` paths to `pack-script` (3-way text). The `custom-script`
class is reachable only when a caller passes it explicitly via the
6th argument to `customization_preserve`. The migrator and
`init-project.sh --update` currently iterate `scripts/` with
`cls=pack-script` for the entire directory, so a project-added script
will route through `pack-script` 3-way text dispatch:

- A `scripts/x-tool.sh` not present in the pack repo will hit
  `project-only-file` via three-way classification (BASE absent,
  THEIRS absent, OURS present) — same effective outcome as
  `custom-script`. The migrator does NOT touch it.
- A `scripts/<name>.sh` whose name collides with a pack-shipped script
  WILL route through 3-way text — the migrator treats it as the
  pack-shipped file (with potential customization-detected-needs-
  reconciliation if both sides differ from baseline).

The reserved `x-` prefix contract guarantees collisions cannot occur:
the pack never ships `x-`-prefixed scripts (validate-pack Check 8
enforces). Per-CLI agents under `.claude/agents/x-*.md` /
`.codex/agents/x-*.md` and bundle agents under
`.agents-plugin/*/agents/x-*.md` (plus the legacy-READ `.gemini/agents/x-*.md`)
ARE classified directly to `custom-agent` by name; scripts rely on
three-way's project-only-file classification rather than a dedicated
classifier branch.

---

### 10. `pack-script` — `scripts/<pack-shipped>.{sh,py}`

**Strategy:** 3-way text dispatch — but NO line-merge on a both-edited
file (safety).

Pack-shipped scripts get the canonical 4-case classification; a customization
(e.g., a project `--quick-mode` flag added to a pack script) surfaces as
`customization-detected-needs-reconciliation` with sidecar. Unlike prose, a
both-edited script is NEVER passed through `tw_merge_file` (a bash/Python
line-union can be lossless yet behaviourally wrong — a duplicated function
shadows): the live file becomes the pack v11 script, your copy stays in the
sidecar, re-apply by hand. The skill does not apply to executables.

---

### 11. `generic` — everything else

**Strategy:** prose auto-merge — the `_cp_strategy_text` real-merge arm
(`tw_merge_file`), the default for text files.

Catch-all for files the classifier doesn't recognize (HELP-FRAGMENT files,
issue-template forms). A both-edited file runs the real 3-way merge (needs a
real baseline; BASE-absent `--update` keeps the legacy sidecar): non-overlapping
edits union cleanly (`merged-with-customization`); overlapping lines produce
`--diff3` markers + sidecar (`needs-reconciliation`, action `merged`), resolved
by hand or via the skill.

**v11.0 per-entry trees — flat-file source of truth (no mirror).**
Per-entry tree files under `docs/project/backlog/`,
`docs/project/implementation-plan/`, and `docs/project/changelog/`
(entry files plus the `_rules.md` / `_intro.md` / `_toc.md` supporting
files, and the impl-plan `_index.md`) route through `generic` 3-way text
dispatch — they are flat-file source-of-truth in v11.0 and any
project-side hand edit is preserved via sidecar like any other generic
file. There is no monolithic mirror: the per-entry tree + generated
`_toc.md` is the sole source of truth and readable form (no
`docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md`). See
`supporting-docs/MIGRATION-v10-to-v11.md` § "Per-entry decomposition"
for the v10 → v11 decomposition contract.

---

## Per-file notes

### `docs/pack/PLATFORM-SKILLS.md` (v11 reframe)

**Class:** routes through `generic` (3-way text dispatch with
sidecar) for the body. Two `## Custom *` H2 sections at the bottom
are project-owned and preserved verbatim by the sidecar mechanism.

**v11 reframe note.** v11 reshapes the file from
the four-dimension model (Platform Targets, Languages, Component
Roles, Communication Protocols) to a five-dimension model (D1
runtime / OS substrate, D2 cross-platform languages, D3 component
role, D4 communication protocols, D5 deployment surface — new) plus
three orthogonal load mechanisms (Tier 0 base, intersection-cell,
trigger-loaded). The reshape is **`transform`-class for the
pack-managed body** (sections from §"How skill selection works"
through §"Full skill inventory" / §"Extending this file") — i.e.,
the pack ships a wholesale-replaced template; project edits to
those sections are not preserved automatically. Per the architecture
§7.6 advisory, projects with locally edited PLATFORM-SKILLS.md
bodies must re-apply edits manually after the migrator writes the
v11 template (the migrator saves the pre-migration copy as
`docs/pack/PLATFORM-SKILLS.md.v10-customized` for the manual
reconciliation pass).

**`## Custom agents` and `## Custom skills` are user-owned.** These
two H2 sections at the bottom of the file are preserved
**byte-identical** by the customization-preserve sidecar
mechanism — the migrator does NOT rewrite them, even when the
column headers inside them are stale. The v11 illustrative-row
column headers are `Base skills | Dimensional skills` (replacing
the v10 `Tier 1 skills | Tier 2 skills`); projects with real custom
rows under the deprecated v10 headers keep those headers
post-migration and rename them manually. See
`supporting-docs/MIGRATION-v10-to-v11.md` § "Skill model changes" for the
manual-rename note and `supporting-docs/INSTALL-PROCEDURES.md` § "Procedure 5.1"
for the v11 column convention used when a new custom agent is
registered.

**D5 monorepo gotcha (architecture §7.4).** The new D5 dimension
loads deployment skills globally for every prompt the PM chat
generates. A monorepo with D5 = {`apple-distribution`,
`linux-container`} loads BOTH `deployment-apple` AND
`deployment-python` for every prompt; the agent prompt (constructed
by the PM chat) scopes per-component citation. This is documented
behavior — multi-component projects migrating from v10 should
verify their PM-chat prompt construction continues to scope
deployment-skill rule citations to the relevant component. No
preservation-strategy change is needed for the gotcha; it is a
documentation / behavioral note carried in PLATFORM-SKILLS.md
§ "Monorepo D5 scoping note" and in `supporting-docs/MIGRATION-v10-to-v11.md`
§ "Skill model changes — D5 monorepo gotcha".

**D2 reshape advisory (architecture §7.6).** The Apple-family
languages (Swift, Objective-C, C, C++) move from a v10 D2
selection to v11 D1-implied loading (Swift implied by D1=ios/macos,
C/C++ implied by D1=embedded-mcu, etc.). Projects that read
PLATFORM-SKILLS.md programmatically by the v10 D2 row labels will
need to update their reading logic to consult the v11 D1 tables.
Manual readers see the same set of skills loaded for the same
project shape — only the labeling of which dimension causes the
load changes.

---

## Sidecar conventions

When the migrator writes a sidecar (`customization-detected-needs-reconciliation`
or `removed-by-pack-customized` paths), the suffix is:

- `scripts/migrate-v10-to-v11.sh`: `<file>.v10-customized`
- `init-project.sh --update`: `<file>.pre-update`

Sidecars are **single-slot**. If `--update` finds prior `.pre-update`
sidecars in the working tree it refuses to run — the user must
reconcile (edit the destination, remove the sidecar) before re-running.
This prevents a second run from silently overwriting unreconciled
content. The migrator's `S1` stage similarly refuses if its backup
directory already exists.

---

## Diff artifacts

For every `customization-detected-needs-reconciliation` and
`real-merge-required` case, the migrator writes a structured
three-way diff under `<state-dir>/diffs/`:

- BASE → OURS (project edits since the previous pack baseline)
- BASE → THEIRS (pack edits across the same baseline)

Read the diff to understand what each side changed before merging.

---

## A1 fallback (`--dry-run` / `--apply` / `--resume`)

The current migrator runs in single-shot mode: pre-flight → backup →
dispatch → install → report. A re-run requires removing the prior
backup directory.

**`scripts/migrate-v10-to-v11.sh` has three modes:**

- `--dry-run` — emit the dispositions TSV and report without writing
  any project files. Useful for previewing changes before commit.
- `--apply` — the default behavior today (write changes, write
  sidecars, exit). Refuses to run unless a fresh dry-run report exists
  for the current working-tree fingerprint (24h freshness window per
  ARCHITECTURE §6.G). Bare invocation auto-runs `--dry-run` first if
  no fresh dry-run output exists, preserving single-shot UX.
- `--resume` — after the user reconciles sidecar files (written with
  the per-migrator suffix `*.${MIGRATOR_OWN_SIDECAR_SUFFIX}` —
  currently `*.v10-customized` for the v10→v11 migrator), resume the
  migration from the next pending dispatch. Sentinel-based
  (`stage-S<N>.done` files in the migrator's state directory).
  Forward-only; accepts BOTH a `.resolved` flag-file alongside the
  sidecar AND extension removal as conflict-resolution signals
  (ARCHITECTURE §6.H).

**Three verification gates** fire inside the `--dry-run` and `--apply`
modes above. Gates do not mutate the working tree — they observe and
either pass or fail.

- **Gate 1 — pre-migration dry-run summary** fires inside `--dry-run`
  after `_stage_report` writes the dispositions TSV + report.md. It
  validates that no `unknown-classification` rows leaked through and
  that report.md was rendered. Read-only; no recovery needed beyond
  re-running `--dry-run` with a fix.
- **Gate 2 — post-Phase-A verification** fires inside `--apply` after
  S6 (post_report_hook). It checks: trinity addenda landed
  (CLAUDE / AGENTS / GEMINI carry the v11 H2 markers), HELP-FRAGMENT
  files match pack mirrors byte-for-byte, dispositions.tsv has no
  unknown rows, relocated docs are in their new
  positions, and `scripts/validate-pack.py` passes against the pack source.
- **Gate 3 — post-Phase-B verification** fires inside `--apply` after
  Gate 2 passes and runs only in tracker mode; in flat-file mode it
  prints `[INFO] tracker: skipped` and returns 0.

**Gate-failure exit code.** A failing gate returns
`EXIT_GATE_FAILED = 31` from the migrator. This slot is intentionally
above the stage-failure range (20..30) so callers / `--resume`
reconciliation logic can distinguish a gate failure from a stage-
internal failure. The exit code is also documented in
`supporting-docs/MIGRATION-v10-to-v11.md` Step 1's exit-codes table.

**Gate-failure recovery.** Recovery depends on which gate fired:

- **Gate 1 FAIL** — re-run `--dry-run` after fixing the defect (no
  working-tree mutation has occurred).
- **Gate 2 FAIL** — first read WHICH checks failed. If the only `[FAIL]`
  line is `sidecars: N unresolved *.v10-customized file(s)`, the
  migration is complete: every stage ran and `report.md` is written;
  each listed file holds the pack v11 version with the pre-migration
  copy in its sidecar. Reconcile each sidecar (re-apply the edit over
  the live file), `rm` it or `touch <sidecar>.resolved`, and continue
  with the guide's Step 2 → Step 3 → Step 4 — do not re-run the migrator
  (`--resume` exits `99`, `--apply` exits `12`). The banner prints these
  same steps for this case. For any OTHER failing check, fix-and-continue
  is NOT supported. The S4/S5/S6
  sentinels are already marked `.done` by the time Gate 2 fires, so
  `--resume`'s forward-only guard would skip past the failed stages
  without re-firing the gate. The only supported recovery is to
  restore the working tree from the migrator's `.pack-migrate-v10-to-v11-backup/`
  mirror via `rsync -a --delete --exclude=.git/ --exclude=.pack-migrate-v10-to-v11-backup/ .pack-migrate-v10-to-v11-backup/ ./`
  followed by a fresh `--dry-run` + `--apply`. The Gate 2 FAIL banner
  spells out the exact commands; the canonical recipe also lives in
  `supporting-docs/MIGRATION-v10-to-v11.md` §Rollback. (Note: the legacy
  `scripts/restore-from-backup.sh` is for v9.3→v10 backups and does
  NOT apply to v10→v11; the v10→v11 backup is a faithful working-tree
  mirror with no path flattening.)
- **Gate 3 FAIL** — does not occur in flat-file mode: Gate 3 runs
  only in tracker mode and is skipped otherwise.

Single-shot recipe (the bare invocation default behavior):

1. Confirm clean working tree.
2. Run `scripts/migrate-v10-to-v11.sh`.
3. Read `.pack-migrate-v10-to-v11/report.md`.
4. For each `customization-detected-needs-reconciliation` row, open
   the named sidecar, merge project content into the destination,
   remove the sidecar, `git add`.
5. Commit.
6. Remove `.pack-migrate-v10-to-v11-backup/` after sufficient
   confidence in the migration result.

---

## Cross-references

These are the pack-internal touch points for the customization-preservation contract.

- `scripts/lib/customization-preserve.sh` — the implementation
- `scripts/lib/customization-report.sh` — the report renderer
- `scripts/tests/test-customization-preserve.sh` — class-coverage tests
- `supporting-docs/MIGRATION-v10-to-v11.md` — the user-facing migration narrative
- `QUICKSTART.md` — where to start
- `scripts/validate-pack.py` Check 25 — CI regression guard for the truthful-report contract

> **Note on `scripts/lib/`.** Files under `scripts/lib/` are pack
> implementation details (sourced by other scripts; never invoked
> directly by users). They are intentionally absent from
> `pack-ops/HELP-FRAGMENT-PACK.md` and `scripts/validate-pack.py` Check 22 skips
> `scripts/lib/` and `scripts/tests/` references when scanning user
> docs for verb freshness. To surface a new lib file as a user-facing
> verb, move it to `scripts/<name>.sh` and add it to the help fragment.
