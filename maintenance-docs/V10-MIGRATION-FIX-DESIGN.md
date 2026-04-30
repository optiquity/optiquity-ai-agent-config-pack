# V10 Migration Fix Design — BD-059

**Status:** Architect design (read-only output).
**Author:** pack-architect session, 2026-04-30.
**Scope:** Defines preservation, reporting, fixture, and validation design for
the v9.3 → v10.0 migration so that project customization survives migration
and any future loss is detected in CI.
**Output of this document feeds:** pack-planner sequencing → pack chat
implementation, all on `main` (no version bump per BD-059 framing).

---

## 0. Reading order and document conventions

This design has eight parts plus appendices:

1. Audit — every customization touchpoint the migration's blast radius reaches.
2. Root cause — why the design and verification together let the defect ship.
3. Preservation design — per file class.
4. Reporting design — what `report.md` (or its successor) must contain.
5. Fixture and verification design — what regression-tests this class.
6. `validate-pack.py` coverage additions.
7. End-to-end verification procedure (reproducible).
8. Open questions for the planner.

Throughout, **OT** = `~/Developer/OptiquityTrader`, **the migration** =
`scripts/migrate-v9-to-v10.sh` and the helpers it calls.

---

## Part 1 — Audit: customization touchpoints

The migration is eight stages S0–S7. Touchpoints are derived from
(a) explicit `cp`/`rm`/`mv` operations in `migrate-v9-to-v10.sh` and
the helpers it invokes, and (b) cross-checking those against the diff
between OT pre-migration backup
(`~/Developer/OptiquityTrader/.pack-migration-backup/v9.3-to-v10.0/`)
and OT post-migration working tree.

**Universe of paths touched directly by the migration script:**

| # | Path (project-relative) | Stage | Operation today | Customization patterns possible |
|---|---|---|---|---|
| C1 | `CLAUDE.md` | S5 | overwrite via `merge-trinity.py`; only `**Active skills:**` line and `### Custom agents` sub-section preserved | Project name, platform defaults prose, Xcode/SDK guidance, domain model, broker integrations, Swift/Python coding rules, security/refactoring/anti-pattern lists, phase-routing tables, agent-behavior overrides, project-specific CONDITIONAL section content |
| C2 | `AGENTS.md` | S5 | as C1 (Codex variant) | Same prose surface as C1 (Codex-flavoured wording) |
| C3 | `GEMINI.md` | S5 | as C1 (Gemini variant) | Same prose surface as C1 (Gemini-flavoured wording) |
| D1 | `docs/pack/PM-CHAT.md` | S5 | wholesale `cp` from pack template | Project name in H1, "You are the PM for X" prose, "Additional project documents" section, project-specific kickoff rules, user-tuned routing table additions |
| D2 | `docs/pack/PLATFORM-SKILLS.md` | S5 | `merge-platform-skills.py` (preserves `## Custom agents` / `## Custom skills` sections only) | Active-skills row tuning above the `## Custom *` boundary; v9.3 projects had no such sections so today's merge writes pack template verbatim |
| D3 | `docs/pack/METHODOLOGY.md` | S5 | wholesale `cp` from `$PACK/supporting-docs/METHODOLOGY.md`; pre-existing root copy removed | Procedure 5 / 5-S / 5-R / 7 customizations; project-specific addenda; this is **pack-owned** content per V10-DESIGN — but the pack ships a 1886-line file and we must verify projects do not edit it |
| D4 | `docs/pack/PROMPT-TEMPLATES.md` | S6 | text-equality compare against `git -C $PACK show v9.3:supporting-docs/PROMPT-TEMPLATES.md`; if equal → delete; else → move to `docs/pack/prompts/_v9-backup.md` | Any user edits to v9.3 templates; this is the **only** file class with intentional customization detection today |
| K1 | `.claude/settings.json` | S3 | wholesale `cp` from pack template | `env.XCODE_SCHEME`, `env.XCODE_DESTINATION`, `env.AGENT_CAPABILITIES`, `permissions.allow` / `permissions.deny` / `permissions.ask` arrays (project-tuned add/remove), `hooks` arrays |
| K2 | `.codex/config.toml` | S3 | wholesale `cp` from pack template | `[model_providers.*]` retained/removed (e.g., OT removed `ollama` and `lmstudio`); `[agents]` overrides; `approval_policy`, `sandbox_mode`, `web_search_mode` if project-tuned; profile sections |
| K3 | `.codex/requirements.toml` | **NOT TOUCHED TODAY (gap)** | (none) | Project-edited `requirements.toml` would survive — but v10's pack template ships a different `requirements.toml`; if the pack content changes, S3 silently leaves stale content in place |
| K4 | `.mcp.json.example` | S3 | wholesale `cp` from pack template | The `_tools` description string (OT had a v9.3-shape string referencing PROMPT-TEMPLATES.md); any project-added MCP server entries in the example |
| K5 | `.gemini/settings.json` (if/when shipped) | not currently shipped | n/a | Reserved — same shape as K1 |
| S1 | `agent-run.sh` | S3 | wholesale `cp` | Project-extended per-agent flags or env exports; today OT had no edits |
| S2 | `scripts/*.sh` | S3 | full-tree replace from `$PACK/project-template/scripts/` | Project-edited bootstrap, validate, format, test wrappers — OT had no edits, but a different project might. Project-added `x-*.sh` scripts (no convention defined today) would be deleted because S3 does a directory replace, not a selective merge |
| A1 | `.claude/agents/*.md` | S1 | selective replace from pack roster | `x-*.md` agents preserved (S1 explicit); pack-roster files overwritten; project-edited pack agents (e.g., a project that hand-tuned `coder.md` for its codebase) silently overwritten |
| A2 | `.codex/agents/*.toml` | S1 | as A1 | as A1 |
| A3 | `.gemini/agents/*.md` | S1 | as A1 | as A1 |
| L1 | `.claude/skills/*/SKILL.md` | S2 | full-directory replace from pack roster | `x-*/` skill dirs preserved (S2 explicit); pack-roster skill dirs overwritten; **project additions to a pack skill's directory** (sibling files, supporting docs in skill dir) are deleted because S2 does `rm -rf` then re-creates with only `SKILL.md` |
| L2 | `.codex/skills/*/SKILL.md` | S2 | as L1 | as L1 |
| L3 | `.gemini/skills/*/SKILL.md` | S2 | as L1 | as L1 |
| P1 | `docs/pack/prompts/*.md` | S4 | created if absent; pack files copied in | Project-added prompt variants would be preserved iff filenames don't collide with pack roster; collision → silent overwrite |
| G1 | `.gitignore` | S0 | append-only `.pack-migration-backup/` line | Low risk |
| ROOT | `METHODOLOGY.md` (project root) | S5 | removed if exists | v9.3 OT shape: no root copy → no-op. Mid-flight v10-dev shape: removed (intended). Risk: a project that intentionally placed a customized `METHODOLOGY.md` at root (non-canonical but technically possible) is silently deleted. |

**Universe of paths the migration does NOT touch but should be considered:**

The audit must be explicit about what the migration leaves alone, because a
"safe" file in v10.0 may become a "touched" file in v10.1 if the pack adds
new shipping content. The following are present in OT and survive the v10.0
migration intact today; the design must not regress them:

- `ARCHITECTURE.md`, `BACKLOG.md`, `STATUS.md` (project-owned project docs)
- `docs/` outside `docs/pack/` (project-owned)
- All source/test/build artifacts (Swift, Python, proto, Xcode project)
- `.git/`, `.github/` (project-owned)
- Project-specific top-level files (e.g. `Package.swift`, `pyproject.toml`)
- `.claude/rag-cache/`, `.claude/rag-index/`, `.claude/settings.local.example.json`
  (project-tuned local files; survive because S3 only touches three named files)

**Confirmed losses on OT (from `git diff HEAD` on `migration-v9-to-v10`):**

| Class | File | Diff lines (current vs HEAD) | Net effect |
|---|---|---|---|
| C1 | `CLAUDE.md` | 588 lines changed (~451 cur vs 477 HEAD) | OT-customized prose replaced with pack template containing `[PROJECT_NAME]`, `[PLATFORM_TARGETS]`, `[TRANSPORT]`, `[PLATFORM_DEFAULTS]`, `[PLATFORM_ARCHITECTURE]`, and the `<!-- HOW TO USE THIS TEMPLATE -->` comment block. Active-skills line preserved. |
| C2 | `AGENTS.md` | 322 lines changed | as C1 |
| C3 | `GEMINI.md` | 286 lines changed | as C1 |
| D1 | `docs/pack/PM-CHAT.md` | 199 diff lines | "OptiquityTrader — PM Chat Instructions" replaced with `[PROJECT_NAME] — PM Chat Instructions` plus pack-template HOW-TO-USE block; v9.3 OT body content overwritten |
| K1 | `.claude/settings.json` | 17 lines | `XCODE_SCHEME` reset `OptiquityTrader` → `""`; `XCODE_DESTINATION` reset `platform=macOS` → `""`; permissions array changed (`git log/show/tee` removed; `git status/add` added); env block re-ordered |
| K2 | `.codex/config.toml` | 11 lines | OT-intentional removal of `[model_providers.ollama]` and `[model_providers.lmstudio]` sections **reverted** (pack template re-introduces them) |
| K4 | `.mcp.json.example` | 2 lines | `_tools` string text changed (low semantic loss but illustrates wholesale-overwrite scope) |
| ROOT-DELETE | `docs/pack/PROMPT-TEMPLATES.md` | -741 lines (file deleted) | Intended: S6 declared `customization: none` and deleted the file. **The detection produced a false negative for trinity/PM-CHAT/configs simultaneously.** |
| BENIGN | All `.claude/skills/*/SKILL.md`, `.codex/skills/*/SKILL.md`, `.gemini/skills/*/SKILL.md`, auditor-architecture trinity, `scripts/bootstrap.sh`, `.gitignore` | various | Pack updates from v9.3 → v10 (capabilities pattern additions, etc.). OT had not customized these — current==pack-template; backup==HEAD. Not destroyed customization. |

The S5 trinity merge collapsed all of OT's project-specific prose because v9.3
OT had no `### Custom agents` heading. Per `merge-trinity.py` line 130–135 and
the assertions in `find_custom_agents_region`, when v9 has no `### Custom
agents` heading the helper falls back to v10's section verbatim, and
**everything else in v9 outside the Active-skills line is discarded**.

---

## Part 1 (cont.) — Customization-pattern characterization

For the planner and implementer to derive preservation rules, the audit
classifies **how** projects customize each touched file. Three patterns
recur across the universe:

**Pattern X — Markered region (designed extension point).**
A file ships pack content with explicit named regions the project owns:
`### Custom agents` in trinity, `## Custom agents` / `## Custom skills` in
PLATFORM-SKILLS.md, the "Additional project documents" section in PM-CHAT.md.
Mechanism: the migration preserves the marked region verbatim; pack region
is replaced wholesale. **Limitation discovered:** v9.3 projects do not have
these markers. Preservation only works for projects created or upgraded into
the v10 marker convention — i.e., not the v9.3 → v10.0 path.

**Pattern P — Intermixed prose (no markers).**
The project's customization is woven into pack-shipped headings — H2
`## Platform and stack defaults`, H2 `## Architecture rules`, H2 `## Security`,
H2 `## Refactoring policy`, etc. The headings are pack-owned but the body
under each is a mix of pack guidance the project kept, pack guidance the
project removed, and project-original prose the project added. Distinguishing
these three requires a three-way comparison: pack-v9.3 baseline, project at
HEAD, pack-v10 template. This is the dominant pattern in OT trinity files
and PM-CHAT.md.

**Pattern S — Structured config (semantic merge required).**
JSON/TOML files with named keys. Customization is per-key value or
add/remove of named blocks. Wholesale `cp` is wrong; line-diff merging is
fragile. The right tool is structured-aware merging at the data-model
level (per-key precedence rules), not text merging. K1 (`.claude/settings.json`),
K2 (`.codex/config.toml`), K3 (`.codex/requirements.toml`), K4 (`.mcp.json.example`)
are all this pattern.

**Pattern T — Template (single-shot fill at install).**
PM-CHAT.md is intended as a copy-and-fill template (PROJECT_NAME placeholder,
"Additional project documents" filled by the kickoff). After kickoff, the
file becomes Pattern P (intermixed prose). The migration must recognize that
once a project has filled in its template, re-applying the template
overwrites the fill. Either the migration treats this file as Pattern P at
upgrade time, or the file design must be re-shaped to expose Pattern X
markers and a project-owned region the migration leaves alone.


---

## Part 2 — Root cause

The defect has three reinforcing causes. Each must be addressed
separately; fixing one without the others leaves the class of failure
intact.

### 2.1 Design assumed Pattern X coverage was sufficient

V10-DESIGN AD-5 / AD-7 / §6.6 introduce `### Custom agents` and
`## Custom agents` / `## Custom skills` markers and design splice rules
that preserve those marker regions. The design treats marker-section
preservation as the customization-preservation mechanism for trinity and
PLATFORM-SKILLS.md. It does not address Pattern P (intermixed prose in
v9.3 projects without those markers) for the migration path.

The trinity merge helper (`merge-trinity.py`) is correct under its stated
assumption (pack template + project file with markers), but the assumption
does not hold for v9.3 → v10.0 — every v9.3 project lacks the marker by
definition, because v9.3 does not ship the marker convention. The
migration silently degrades to "preserve only the Active-skills line."

For files like PM-CHAT.md, the design did not even propose a marker
mechanism — S5 simply `cp`s the pack template over the project file
(line 343–346 of `migrate-v9-to-v10.sh`).

### 2.2 Customization detection scoped to one file

S6 implements the only customization-detection logic in the migration:
text-equality compare of `docs/pack/PROMPT-TEMPLATES.md` against
`git show v9.3:supporting-docs/PROMPT-TEMPLATES.md`. The `report.md`
"Customization status" line is fed exclusively from S6's `status.txt`.
Every other touched file class is silently overwritten without comparison
or report.

The result: the report says "customization: none" while ~1100 lines of
trinity content, ~150 lines of PM-CHAT content, and project-tuned config
keys have been overwritten in the same run. The single-file scope is the
direct mechanism by which the report becomes false.

### 2.3 §4.6 verification compared structure, not content

V10-PHASE-4-VERIFICATION §4.6 ran the migration against an OT clone and
recorded byte-level evidence at line 727:

> "Trinity-section count parity is the strongest §4.8 signal: the
> migration's S5 splice/merge produced byte-identical section counts
> across the two trees (23/19/26 each), even though OT had substantially
> more populated trinity content pre-migration (per §4.6 diff-stat: OT
> trinity diffs 588/322/286 lines vs synthetic 65/70/71)."

The 588/322/286 diff-line counts are the destruction itself. §4.6 saw
them, observed they exceeded the synthetic fixture's 65/70/71, and
characterized this as a positive signal of "splice/merge invariant under
real-project complexity" — the inverse of what those numbers actually
mean. The pass criterion was the *count* of `## ` H2 headings, not the
preservation of content under those headings. §4.6's verdict was "soft
pass — one real-project defect found (F-C: legacy METHODOLOGY
duplication)" with no flag on trinity/PM-CHAT content loss.

The fixture used for §4.6 was an OT clone but the **comparison criteria**
were structural, not content-preservation-based. A correct §4.6 would
have asserted that OT-customized lines present in the pre-migration tree
also appear in the post-migration tree (with at most permitted edits
from S1 / S2 / S3 pack updates). It did not.

### 2.4 `validate-pack.py` has no migration safety check

`validate-pack.py` covers ten static-pack-shape checks
(skill frontmatter, codex TOML, agent count, prompts directory, roster,
x-prefix reservation, init-project structure, prompt triad compliance).
None of them simulate or verify a migration. A regression in
`merge-trinity.py` (e.g., a refactor that breaks the Active-skills splice)
is not caught at CI; only a real downstream migration would surface it,
and §4.6's structural pass criteria let real downstream migrations pass
visually.

---

## Part 3 — Preservation design

The preservation mechanism is selected per file class. Each mechanism is
chosen to cover a customization pattern (X / P / S / T from Part 1) without
forcing v9.3 projects to retroactively adopt v10's marker convention.

The unifying principle: **for every file the migration writes, the script
must produce a per-file disposition record before commit. Disposition is
one of five values: `unchanged-pack`, `pack-update-applied`,
`merged-with-customization`, `customization-detected-needs-reconciliation`,
`removed-by-design`. The disposition determines whether the file is
written, written-with-suffix, or paused for user reconciliation.** The
report is a roll-up of per-file dispositions; truthfulness is structural,
not heuristic.

### 3.1 Three-way diff foundation (applies to all text classes)

The migration already has the materials for a three-way diff at every
touched text file:

- **BASE** = `git -C $PACK show v9.3:<pack-shipped-path>` (the v9.3 pack
  baseline that the project originally received).
- **OURS** = the project file as it exists at the start of the migration
  (already backed up to `$BACKUP_DIR/...` by the existing script).
- **THEIRS** = the v10 pack template the migration would copy in.

For every text-class file (C1–C3, D1–D4, S1, S2, A1–A3, L1–L3, P1), the
migration computes:

- `base_vs_ours` — whether the project edited the v9.3 baseline.
- `base_vs_theirs` — whether the pack changed the file from v9.3 → v10.
- A merge attempt only when both are true; trivial cases short-circuit.

Trivial cases:

- `base == ours` and `base == theirs` → no-op (`unchanged-pack`).
- `base == ours` and `base != theirs` → adopt pack v10 file
  (`pack-update-applied`).
- `base != ours` and `base == theirs` → keep project file unchanged
  (`merged-with-customization`, no merge needed — pack made no change).
- `base != ours` and `base != theirs` → real merge required.

The fourth case is the only one where preservation strategy matters per
class. The previous three cases are deterministic and account for the
overwhelming majority of files in any real migration.

A standardized helper — call it `scripts/lib/three-way.sh` — computes the
classification once per file. Each stage that touches a text-class file
calls the helper before deciding what to write. This collapses the
per-stage, per-file logic to a small dispatch table.

### 3.2 Trinity files (C1–C3) — Pattern P

**Mechanism:** when the four-case classifier returns "real merge required,"
the migration does NOT attempt an automatic merge of intermixed prose.
Instead it:

1. Writes the v10 pack template to `<file>` (so the developer's repo has
   the new pack content available).
2. Writes the project's pre-migration file to `<file>.v9-customized`
   alongside it.
3. Writes a structured diff to
   `$BACKUP_DIR/diffs/<file>.three-way.diff`
   showing BASE/OURS/THEIRS for human inspection.
4. Records disposition `customization-detected-needs-reconciliation` in
   the report's per-file table.
5. Adds a tracked TD-NNN entry to the project's `BACKLOG.md` (or, if
   BACKLOG.md is absent, leaves a `RECONCILE-TRINITY.md` next to the
   files) instructing the developer to invoke a reconciliation procedure.

**Reconciliation procedure (Procedure 5-T, new):** documented in
`MIGRATION-v9-to-v10.md` Step 6. The PM chat (or developer manually)
walks each section heading present in the v9 file: if the v10 template
has a section with the same heading, the developer chooses keep-pack /
keep-project / hand-merge; if the heading is project-original, the
developer decides whether it belongs in the pack template (file as
PACK-FEEDBACK) or stays as a project addendum at the bottom of the file
(under a new `## Project addenda` H2 the v10 template will reserve).

Why not auto-merge: trinity prose is high-stakes (architecture rules,
security policy, anti-patterns). A line-level three-way merge produces
syntactically clean output that is semantically wrong (rules from two
different versions interleaved, contradictions buried in prose). The
migration's job is to surface the conflict and stop, not to resolve it.

**Trinity-rule symmetry:** the same disposition rule, the same
reconciliation procedure, and the same `<file>.v9-customized` sidecar
naming apply to all three trinity files (no asymmetry).

**v10 template change required (deferred to planner):** the v10 pack
trinity templates gain a `## Project addenda` H2 marker section near
the bottom, providing a Pattern X-style designed extension point that
post-migration projects can land their preserved content into during
Procedure 5-T. New projects start with the section empty.

### 3.3 PM-CHAT.md (D1) — Pattern T → Pattern P

PM-CHAT is a template at install (Pattern T) that becomes intermixed prose
once the kickoff fills `[PROJECT_NAME]` and "Additional project documents."

**Mechanism:** identical disposition flow as trinity (3.2), with a
detection-only refinement. The classifier checks two specific markers in
the project file before classifying: presence of `[PROJECT_NAME]` (still
an unfilled placeholder ⇒ template was never customized, safe to overwrite)
and presence of any `<!-- HOW TO USE THIS TEMPLATE -->` comment block
(still pristine ⇒ safe). If both indicate a still-pristine template, the
disposition is `pack-update-applied`. If either indicates a customized
file, the disposition is `customization-detected-needs-reconciliation`
and the same `.v9-customized` sidecar is produced.

Pack template change (deferred to planner): wrap the project-mutable
region of PM-CHAT — the H1 line, the Role paragraph, and the "Additional
project documents" list — in a Pattern X marker block (e.g.,
`<!-- BEGIN project-owned -->` / `<!-- END project-owned -->`). After
this change, future migrations preserve that region verbatim and
classify the rest as Pattern P.

### 3.4 PLATFORM-SKILLS.md (D2) — Pattern X (already designed)

The current `merge-platform-skills.py` is correct **for projects that
have the v10 marker convention**. For v9.3 projects, today it falls
through to "use v10 verbatim" and silently writes pack-template
illustrative-row content into the project file (confirmed in OT diff at
lines 295–325 of the merged output).

**Mechanism:** add a four-case classifier (3.1) wrapping the existing
helper. v9.3 projects with no `## Custom *` heading and `base == ours`
get `pack-update-applied` (clean adoption). v9.3 projects with no
`## Custom *` heading and `base != ours` get
`customization-detected-needs-reconciliation` with the same
`.v9-customized` sidecar pattern. Projects already on the v10 marker
convention go through the existing splice and report
`merged-with-customization`. Trim the illustrative-row content from
the v10 template — illustrative rows are documentation, they belong in
PLATFORM-SKILLS-EXAMPLES.md or in the file's body comments, not as
default-shipped table rows that pollute every project.

### 3.5 METHODOLOGY.md (D3) — Pack-owned, with detection-only check

Per V10-DESIGN, METHODOLOGY.md is pack-owned content. Migrations replace
it wholesale by intent. But "pack-owned" is a convention, not a
guarantee — a developer can still edit it. The migration must detect
that case rather than assume it.

**Mechanism:** the four-case classifier is run. If `base != ours`, the
disposition is `customization-detected-needs-reconciliation` with the
`.v9-customized` sidecar — same as trinity. The pack file is still
written (because METHODOLOGY is canonically pack-owned), but the
sidecar preserves the developer's edits and the report flags the
divergence so it is not silently lost. This treats METHODOLOGY
identically to trinity for the purposes of customization detection
while preserving the wholesale-replace semantics.

### 3.6 PROMPT-TEMPLATES.md (D4) — Pattern P, special-cased

The existing S6 logic is the right shape but is the **only** stage with
this shape. After 3.1–3.5 land, S6 is no longer special: it follows the
same four-case classifier with two specifics: (a) a `removed-by-design`
disposition exists for this file class because v10 retires it, and (b)
the `.v9-customized` sidecar lands at `docs/pack/prompts/_v9-backup.md`
to interoperate with the existing Procedure 5-R. No semantic change to
the user-visible behaviour; the implementation collapses into the
shared helper.

### 3.7 Structured configs (K1, K2, K3, K4) — Pattern S

Wholesale `cp` is replaced with key-level merge. Two implementations:

**JSON (K1, K4):** a Python helper `scripts/merge-json.py`. Strategy:
parse pack baseline (BASE), project file (OURS), pack v10 template
(THEIRS) into Python dicts. Walk the pack-defined keys recursively:

- For scalar leaves (strings, numbers, bools): if `base == ours`, take
  THEIRS; if `base != ours`, take OURS (project edit wins).
- For list leaves (e.g. `permissions.allow`): compute set-add and
  set-remove sets between BASE and OURS, then between BASE and THEIRS.
  Result = THEIRS minus pack-removed-from-BASE plus project-added-in-OURS.
  (i.e. union of independent edits; documented edge case: project removed
  AND pack added the same item ⇒ flag for reconciliation, default is
  to include the item with a comment.)
- For object branches: recurse.
- Project-only keys not in pack template: kept (project addendum).
- Pack-new keys not in BASE: added.

For `.claude/settings.json`, this preserves OT's `XCODE_SCHEME` /
`XCODE_DESTINATION` env values, preserves the project's permission
tuning (the `git log/show/tee` removal, if intentional), and adopts pack
v10 schema additions. The disposition is `merged-with-customization`
when any key was preserved against pack default and
`pack-update-applied` when every value matched the four-case "no project
edit" rule.

**TOML (K2):** a Python helper `scripts/merge-toml.py` using
`tomllib` + `tomli_w`. Same algorithm at the TOML table level. For OT,
this preserves the intentional removal of `[model_providers.ollama]`
and `[model_providers.lmstudio]` because the section is absent in OURS,
present in BASE, and present in THEIRS — set-difference logic (THEIRS
minus base-to-ours-removals) drops it correctly.

**Reconciliation flag for ambiguous merges:** when a list-merge produces
a "project removed AND pack added the same item" case, or when a TOML
section has structural conflicts (key types differ across the three
sources), the disposition is
`customization-detected-needs-reconciliation` and the project file is
left untouched (or written to a `.v9-customized` sidecar) with the
report explaining the specific conflict.

K3 (`.codex/requirements.toml`) is added to S3's touched-file list with
the same merge logic. The current omission is a latent gap.

### 3.8 Pack agents (A1–A3) and pack skills (L1–L3) — Pattern P, narrow

Today S1 and S2 unconditionally overwrite every pack-roster file with
the v10 version. The OT auditor-architecture diff shows that projects
DO sometimes edit pack agent files in place (OT added a "Capabilities
pattern adherence" bullet to the auditor-architecture review checklist).

**Mechanism:** four-case classifier per agent and per skill. Trivial
cases are unchanged. The "real merge required" case writes the pack v10
file, writes the project's pre-migration file to `<file>.v9-customized`,
and reports `customization-detected-needs-reconciliation` per file.
Reconciliation procedure: developer either ports the customization
forward into the v10 pack file (and files PACK-FEEDBACK if it should be
upstreamed) or deletes the sidecar.

For skills (L1–L3), the same approach applies to `SKILL.md`, with one
extension: today S2 does `rm -rf` on the skill directory and re-creates
with only `SKILL.md`. **Any sibling files in the skill dir are silently
deleted.** The fix: S2 backs up the entire skill directory tree (it
already does, to `$BACKUP_DIR/.<tool>/skills/<skill>/`), then on
restore, only `SKILL.md` is replaced; sibling files are preserved
in place and listed in the report under "preserved skill-dir siblings."

### 3.9 Scripts (S1, S2 — `agent-run.sh`, `scripts/*.sh`) — Pattern P

Same four-case classifier per script. Today S3 wholesale-replaces the
entire `scripts/` directory and replaces `agent-run.sh`. The fix:

- `agent-run.sh`: classify; if `base != ours`, write `.v9-customized`
  sidecar.
- `scripts/<script>.sh`: classify per script. Pack-roster scripts
  (those present in `$PACK/project-template/scripts/`) follow the
  classifier. **Project-added scripts not in the pack roster are
  preserved in place** — today S3 does not delete them (it copies pack
  files in via `cp`, not via tree-replace), but the design must make
  this explicit and add a check that prevents future S3 refactors from
  regressing the behaviour.

A reserved naming convention for project-added scripts (`x-*.sh`)
mirrors the agent/skill convention and lets `validate-pack.py`
distinguish project-added from pack-roster. Without it, a project
script with the same name as a future pack script silently gets
overwritten on a future migration.

### 3.10 `docs/pack/prompts/*.md` (P1) — Pattern X-compatible

S4 creates the directory and copies pack files in. Pre-existing
`x-*.md` prompts (project-added) are preserved automatically because
S4's loop only iterates pack-source files. Pre-existing pack-named
prompts (collision case) are silently overwritten. The fix: S4 runs
the four-case classifier per pack file. If a project file at the same
path differs from the pack v10, write `.v9-customized` sidecar.

### 3.11 Disposition table summary

The five possible per-file dispositions, with which file classes they apply
to and what each means for the developer:

| Disposition | Meaning | File written? | Sidecar? | Report flag |
|---|---|---|---|---|
| `unchanged-pack` | base == ours == theirs | no-op | no | (suppressed unless verbose) |
| `pack-update-applied` | base == ours, pack updated v9.3 → v10 | yes (THEIRS) | no | brief one-liner |
| `merged-with-customization` | base != ours, pack changed too, merge succeeded (Pattern S only) | yes (merged) | no | itemized merge result |
| `customization-detected-needs-reconciliation` | base != ours, merge not safe / not attempted | yes (THEIRS) | yes (`.v9-customized`) | prominent; blocks "ready to commit" |
| `removed-by-design` | v10 retires the file (PROMPT-TEMPLATES.md only today) | no (deleted) | yes when ours had edits (`_v9-backup.md`) | prominent if sidecar produced |

Five values is the minimum that covers every observed touchpoint. Adding a
sixth (e.g. `partial-merge-warnings`) is rejected — it splits hairs that the
developer cannot act on differently than `merged-with-customization`. If a
merge had warnings, those go in the per-file detail row, not as a separate
disposition.

---

## Part 4 — Reporting design

`report.md` becomes the developer's only structural-source-of-truth before
the migration commit. The current report (single "customization: none"
line plus x-files / improperly-added counts) cannot bear that weight.

### 4.1 Report structure

```
# v9.3 → v10.0 migration report

**Date:** <UTC>
**Pack version:** v10.0 (commit <sha>)
**Target project:** <pwd>
**Migration script SHA:** <sha of migrate-v9-to-v10.sh as run>
**Branch:** migration-v9-to-v10
**Disposition summary:** N pack-updates · M merges · K reconciliations needed

## Reconciliation required (K files)

For each file with disposition `customization-detected-needs-reconciliation`
or `removed-by-design` (with sidecar):

- **`<path>`** — class <C/D/K/S/A/L/P>; reason <one-line>
  - Pack v10 written to: `<path>`
  - Project v9 preserved at: `<sidecar-path>`
  - Three-way diff: `<diff-path>`
  - Suggested next step: <Procedure 5-T / Procedure 5-R / hand-port / file PACK-FEEDBACK>

## Merged with customization (M files)

For each file with disposition `merged-with-customization`:

- **`<path>`** — kept project edits to: <keys / sections>; adopted pack
  v10 changes to: <keys / sections>

## Pack updates applied (N files)

Itemized list, one line each — file path and one-line summary of pack v10
change.

## Files retired (removed-by-design)

For each `removed-by-design` disposition: file path, sidecar location if
any, the reason ("v10 retired this file class").

## Project files preserved (no migration touch)

- `x-*` agents / skills / prompts: <count> per location
- Project-only scripts (not in pack roster): <list>
- Skill-dir siblings preserved: <list>

## Improperly-added files (Procedure 5.4 candidates)

(unchanged from current implementation)

## Next steps

1. Read this report from top to bottom. The "Reconciliation required" section
   above must be empty before commit.
2. For each reconciliation: invoke Procedure 5-T (trinity / pack docs /
   pack agents / pack skills) or Procedure 5-R (PROMPT-TEMPLATES legacy)
   from METHODOLOGY.md.
3. After every reconciliation, delete the corresponding `.v9-customized`
   sidecar.
4. Run `git diff` and confirm the working tree matches your intent.
5. Commit on branch `migration-v9-to-v10`.
6. Follow `supporting-docs/MIGRATION-v9-to-v10.md` Steps 5–7.

## Rollback

(unchanged from current implementation)
```

### 4.2 Truthfulness invariant

The report's top-line "Disposition summary" is a roll-up over the per-file
dispositions. The "Reconciliation required" section is non-empty if and
only if at least one file has the
`customization-detected-needs-reconciliation` or
`removed-by-design`-with-sidecar disposition. There is no path through
the migration script that produces a `customization: none` summary while
sidecars exist — the report is generated from the same disposition table
that drives the file writes. This is the structural truthfulness property:
the report cannot diverge from the disposition record because both are
the same data.

The current implementation breaks this invariant because S6's `status.txt`
is a separate string written by a single stage, not a roll-up of all
stages' decisions. The fix replaces `status.txt` with a structured
disposition file (e.g. `$BACKUP_DIR/dispositions.tsv` or `.json`) that
every stage appends to. S7 reads the structured file and renders the
report.

### 4.3 "Ready to commit" pre-check

The migration's stdout at the end of S7 currently says:

> "Migration complete. Review `git diff` and `report.md` before committing."

The fix-tier message becomes:

```
Migration complete.

Disposition summary: N pack-updates · M merges · K reconciliations needed.

K files require reconciliation before commit:
  - <path>      → Procedure 5-T
  - <path>      → Procedure 5-T
  - <path>      → Procedure 5-R
  - <path>      → Procedure 5-T

DO NOT COMMIT until reconciliation is complete and `.v9-customized`
sidecars are resolved.

Full report: $BACKUP_DIR/report.md
Three-way diffs: $BACKUP_DIR/diffs/
```

When K is zero the message degrades to the current "review and commit"
form. The signal-to-action mapping is explicit.

---

## Part 5 — Fixture and verification design

### 5.1 Why §4.6 passed

§4.6 used a real OT clone, but its sanitization rules forbade the
verification record from containing "OT documentation body" or
"OT-derived names beyond the single token OptiquityTrader." Combined
with the verification's structural-only pass criteria (§ count, file
count, prompts-dir presence), the only signal §4.6 looked at was
shape, and shape was unbroken — every H2 heading from the v10 template
was present in the post-migration trinity.

The verification design implicitly assumed: "if all v10-required
structural elements are present and counts match, the migration
preserved customization." This is false for any file class with
intermixed prose under pack-named headings.

### 5.2 Required fixture properties

A fixture sufficient to catch BD-059 must have, **per file class in the
audit**:

- **Trinity (C1–C3):** v9.3-baseline content with project additions
  woven into pack-named H2 sections (`## Platform and stack defaults`,
  `## Anti-patterns`, etc.). Specific marker strings the verification
  asserts against post-migration: e.g.,
  `FIXTURE-MARKER-C1-PLATFORM-DEFAULTS`,
  `FIXTURE-MARKER-C1-ANTIPATTERN-1`,
  `FIXTURE-MARKER-C1-DOMAIN-MODEL`. Place ≥3 markers per H2 section that
  v9.3 OT had populated.
- **PM-CHAT (D1):** filled `[PROJECT_NAME]` (use the literal token
  `FIXTURE-PROJECT`), populated "Additional project documents"
  section, customized routing rule.
- **PLATFORM-SKILLS (D2):** v9.3-shape (no `## Custom *` headings).
- **`.claude/settings.json` (K1):** non-empty `XCODE_SCHEME`,
  `XCODE_DESTINATION`, custom `permissions.allow` entries (added),
  pack-default `permissions.allow` entries (removed).
- **`.codex/config.toml` (K2):** removed `[model_providers.ollama]`
  block.
- **`.mcp.json.example` (K4):** project-edited `_tools` string.
- **Pack agent (`.claude/agents/auditor-architecture.md`):** appended
  custom bullet under `## Architecture review checklist`.
- **Pack skill (`.claude/skills/swift-best-practices/SKILL.md`):**
  appended custom item under `## Design choices`. Plus a sibling file
  in the skill dir (`NOTES.md`) to test L1's preservation rule.
- **`docs/pack/prompts/x-custom.md`:** present pre-migration (tests
  x-prefix preservation across S4).
- **Skill `x-domain-model/SKILL.md`:** present pre-migration (tests
  S2 x- preservation).
- **Agent `x-broker.md`:** present pre-migration (tests S1 x-
  preservation).
- **Project script `scripts/x-deploy.sh`:** present pre-migration
  (tests S3 project-script preservation).

The fixture lives at
`maintenance-docs/test-fixtures/migration-v9.3-customized/` (a new
directory) and is constructed by a script
`maintenance-docs/test-fixtures/build-migration-fixture.sh`. The
fixture is a real git tree on the v9.3 baseline with the customizations
above committed; the build script clones the v9.3 pack-template state
into the fixture, applies the customization patch, and commits. The
patch is the source of truth.

### 5.3 Verification assertions

The fixture-based verification — call it
`scripts/test-migration.sh` — runs the migration end-to-end against a
fresh fixture clone in `/tmp/`, then asserts:

- **Content preservation per marker:** every `FIXTURE-MARKER-*` token
  present in the pre-migration tree appears in either the
  post-migration tree or the corresponding `.v9-customized` sidecar.
  Zero markers may be lost.
- **Disposition coverage:** the `dispositions.tsv` produced by the
  migration contains an entry for every file in the touched-file
  universe. Files in the universe with no entry are a defect.
- **Report truthfulness:** for each file with disposition
  `customization-detected-needs-reconciliation`, the report's
  "Reconciliation required" section has a corresponding entry. For each
  file with disposition `pack-update-applied`, the report's "Pack
  updates applied" section has a corresponding entry. Report content
  is a deterministic function of the disposition record.
- **Sidecar/structured-merge correctness:** for `K1` (`.claude/settings.json`),
  the post-migration JSON has both pack-v10 schema additions AND the
  fixture's `XCODE_SCHEME` string. For `K2`, the post-migration TOML
  does NOT contain `[model_providers.ollama]`.
- **x- file preservation:** every `x-*` agent/skill/prompt/script in
  the fixture is present byte-identical post-migration.
- **No silent overwrite of pack agents/skills with project edits:** the
  fixture's `auditor-architecture.md` custom bullet appears in either
  the post-migration file or its sidecar.
- **No false `customization: none`:** the migration must NOT report
  zero reconciliations when fixture customizations exist.

### 5.4 Where the fixture lives in CI

`scripts/test-migration.sh` is invoked from the GitHub Actions workflow
`.github/workflows/validate-pack.yml` after `validate-pack.py`. It
brings up the fixture in `/tmp/`, runs the migration, runs the
assertions, tears down. Failure of any assertion fails the workflow.

The fixture also gives the planner a deterministic regression target
for any future migration script change — `merge-trinity.py` /
`merge-platform-skills.py` / `merge-json.py` / `merge-toml.py` /
`scripts/lib/three-way.sh` refactors must not regress
`scripts/test-migration.sh`.

### 5.5 Multiple fixture shapes

A single fixture cannot exercise every customization pattern. Three
fixtures are recommended:

- `migration-v9.3-empty/` — v9.3 baseline with no customization. Tests
  the trivial case (every disposition should be `pack-update-applied`
  or `unchanged-pack`); zero `.v9-customized` sidecars produced.
- `migration-v9.3-customized/` — the OT-shape fixture described in 5.2.
  The primary regression target for BD-059.
- `migration-v9.3-marker-convention/` — a fixture that has *already*
  adopted v10 marker sections (per the v10-DESIGN happy path: project
  has `### Custom agents`, `## Custom agents`, `## Custom skills`).
  Verifies the existing splice-merge logic still works under the new
  classifier wrapping.

---

## Part 6 — `validate-pack.py` coverage additions

`validate-pack.py` is a static, structural validator of the pack repo.
It cannot directly verify a migration outcome (the migration runs
against a target project, not the pack). It can verify the pack-side
preconditions for migration correctness. Three new checks are proposed.

### 6.1 New check — `check_three_way_helper_present`

Asserts that `scripts/lib/three-way.sh` exists, has a documented entry
point, and is sourced by `migrate-v9-to-v10.sh`. Fails if the helper is
missing, untracked, or not referenced.

### 6.2 New check — `check_merge_helpers_consistent`

Asserts that the migration script invokes the merge helpers
(`merge-trinity.py`, `merge-platform-skills.py`, `merge-json.py`,
`merge-toml.py`) for every file class in the design's audit table. The
check has a hard-coded mapping of file class → expected helper that
mirrors Part 3. A new shipping file class in `project-template/` that
the migration does not invoke a helper on is a CI failure. This is the
"future migration regression" guard: if a developer adds a new file to
`project-template/` without updating the migration, CI catches it.

### 6.3 New check — `check_disposition_table_documented`

Asserts that `MIGRATION-v9-to-v10.md` contains a per-file-class
disposition table that matches the per-file-class table in the
migration script's documented stages. Cross-doc consistency check —
if the script changes which files it touches and the migration guide
isn't updated, CI catches it.

### 6.4 New check — `check_migration_test_runs_clean`

Invokes `scripts/test-migration.sh --quick` (a fast subset that runs
S0–S7 against the empty fixture only) and asserts exit zero. Full
fixture suite runs in a separate workflow step (Part 5.4). The
"--quick" mode keeps `validate-pack.py` runtime within bounds while
still catching catastrophic migration regressions.

### 6.5 Updates to existing checks

- `check_init_project_structure` — extend to assert
  `scripts/test-migration.sh` and `maintenance-docs/test-fixtures/`
  exist.
- `check_pack_agent_roster` — no change required; the roster check
  remains correct and is leveraged by `check_merge_helpers_consistent`.

---

## Part 7 — End-to-end verification procedure

The end-state verification answers two questions:

1. Does the fixed migration preserve OT customization?
2. Does the report truthfully describe what changed?

The procedure is reproducible and uses the pre-migration backup as
ground truth.

### 7.1 Reproduction setup

Pre-conditions:

- Pack repo on `main` at the post-fix commit.
- OT working tree on branch `migration-v9-to-v10` with current dirty
  state preserved (the destroyed-state evidence). The procedure does
  not touch the live OT — it works against a clone.

Steps:

```
# 1. Clone OT state pre-migration (from backup) into a verification dir.
TMPDIR=$(mktemp -d)
cd "$TMPDIR"
mkdir ot-revert
cp -R ~/Developer/OptiquityTrader/.pack-migration-backup/v9.3-to-v10.0/* ot-revert/
# Note: the backup includes .claude/, .codex/, .gemini/, scripts/, and
# the trinity/PM-CHAT/configs files at the top level. Reconstruct the
# project tree shape: trinity files at root, .claude/ etc at root, etc.
# (Helper script `scripts/restore-from-backup.sh` to be authored by
# planner — see open question OQ-2.)

# 2. Make ot-revert a git repo at the v9.3 baseline state.
cd ot-revert
git init -q
git add -A
git commit -q -m "v9.3 baseline (restored from OT backup)"

# 3. Run the FIXED migration script.
PACK=/Users/david/Developer/optiquity-ai-agent-config-pack \
    "$PACK/scripts/migrate-v9-to-v10.sh"

# 4. Read the report.
cat .pack-migration-backup/v9.3-to-v10.0/report.md

# 5. Run verification assertions.
"$PACK/scripts/test-migration.sh" --target . --fixture-shape ot-revert
```

### 7.2 Pass criteria (per success criterion of BD-059)

The verification PASSES if and only if all of the following hold:

1. **No fixture marker is lost.** Every `FIXTURE-MARKER-*` token (and
   for the OT-revert run, every confirmed-loss content fragment listed
   in the audit) appears in either the post-migration tree or a
   `.v9-customized` sidecar.
2. **Report has non-empty "Reconciliation required" section.** OT had
   real customization in C1–C3, D1, K1, K2, K4 (and possibly more
   discovered by audit); the report must list at least these.
3. **Report disposition summary is non-zero K.** No "customization:
   none" line. The disposition summary explicitly counts
   reconciliations needed.
4. **Sidecars exist for each reconciliation entry.** Every report
   entry under "Reconciliation required" has a matching
   `.v9-customized` (or `_v9-backup.md` for the PROMPT-TEMPLATES
   case) file on disk.
5. **Structured-config merges produced correct content.** For K1,
   `XCODE_SCHEME == "OptiquityTrader"` post-migration. For K2,
   `[model_providers.ollama]` is absent post-migration.
6. **All `x-*` files preserved byte-identical.** Empty set in OT
   today, but the assertion still runs and passes trivially.
7. **`scripts/test-migration.sh` exits zero.**

### 7.3 Negative tests

Run the same procedure against the existing (pre-fix) migration script
to confirm it FAILS the verification (i.e., the verification correctly
detects the defect). This is a one-time confidence check.

### 7.4 What the planner sequences

The planner translates this into an ordered task list:

1. Build helper `scripts/lib/three-way.sh`.
2. Build merge helpers (`merge-json.py`, `merge-toml.py`); refactor
   existing `merge-trinity.py` and `merge-platform-skills.py` to use
   the four-case classifier.
3. Refactor `migrate-v9-to-v10.sh` to use the disposition table.
4. Build the three fixture shapes and `scripts/test-migration.sh`.
5. Add `validate-pack.py` checks (Part 6).
6. Update `MIGRATION-v9-to-v10.md` with disposition-table doc and
   Procedure 5-T.
7. Update METHODOLOGY.md with Procedure 5-T.
8. Trinity edit: add `## Project addenda` H2 to the three trinity
   templates.
9. Run end-to-end verification (Part 7.1) and capture evidence.
10. Update `V10-PHASE-4-VERIFICATION.md` (or write a new
    `V10-PHASE-4-VERIFICATION-2.md`) recording the gap closure.

The planner picks dependency order (e.g., 1 must precede 2; 4 can run
parallel to 2; 6 + 7 + 8 are doc work that follows code).

---

## Part 8 — Open questions for the planner

These are decisions the architect identified but does not resolve.
Each blocks at least one task in Part 7.4.

**OQ-1 — Sidecar naming and lifecycle.**
This design proposes `<file>.v9-customized` as the sidecar suffix for
trinity, PM-CHAT, configs, agents, skills, and scripts; `_v9-backup.md`
remains for PROMPT-TEMPLATES (existing convention). Should sidecars
live alongside the file (this design's default — discoverable in `git
status`) or under `$BACKUP_DIR/`? Discoverability vs cleanliness
tradeoff. A second concern: should sidecars be added to `.gitignore`?
If they are committed, they pollute `main` after merge; if they are
gitignored, the developer might miss them. **Recommendation: alongside
the file, NOT gitignored, removed by Procedure 5-T as its final step.**
Planner to confirm.

**OQ-2 — `scripts/restore-from-backup.sh` for verification.**
The end-to-end verification (Part 7.1) needs a way to reconstruct the
v9.3 project tree shape from a `$BACKUP_DIR/` snapshot. The current
backup directory layout flattens some paths (e.g.
`docs-pack-PROMPT-TEMPLATES.md` is at the top level, not at
`docs/pack/`). A helper script must invert this flattening. Planner
decides whether to author this helper inside the fix or to declare the
fixture build (5.5) sufficient and leave the OT-revert path as a
manual procedure documented in `MIGRATION-v9-to-v10.md` §12.

**OQ-3 — Procedure 5-T placement.**
The reconciliation procedure for the new sidecar pattern needs to live
in METHODOLOGY.md alongside Procedures 5 / 5-R / 5-S. Naming options:
**Procedure 5-T** ("trinity reconciliation" but also handles configs,
PM-CHAT, agents, skills — broader than trinity) or **Procedure 5-C**
("customization reconciliation" — more general but conflicts with
existing naming where letters are not always meaningful). The
architect's preference is **Procedure 5-C** for clarity; this design
used "5-T" only because it seemed adjacent to trinity. Planner to
choose final letter.

**OQ-4 — `## Project addenda` template change ordering.**
Adding `## Project addenda` to the three trinity templates is a
design-time change to the pack templates themselves. It should land
*before* the migration fix ships, so projects upgrading immediately
after BD-059 see the new template shape. Planner to confirm whether
this trinity-template edit goes in the same commit as the migration
fix or in a preceding commit, and whether `validate-pack.py` is
updated to require the new H2.

**OQ-5 — `init-project.sh` parity.**
This design focuses on `migrate-v9-to-v10.sh`. `init-project.sh` for
new projects has no "merge with existing project content" path — every
file is fresh. But `init-project.sh` run against an existing project
with pre-existing content (the `--existing` flow) faces a similar
problem. Planner to confirm whether the four-case classifier helper is
reusable there or whether `init-project.sh --existing` already handles
this correctly.

**OQ-6 — Skill-dir sibling-file convention.**
Part 3.8 proposes that S2 preserve sibling files inside a pack skill
directory. This is the right behaviour for projects that have used the
skill directory as a place to put related notes, but it is also a
silent extension point — there is no convention saying projects MAY
put files there. Planner to choose: (a) document the convention
(skill-dir siblings allowed, prefix `x-` for project-added); (b)
prohibit (S2 deletes anything not `SKILL.md`); (c) status quo (S2
already deletes via `rm -rf`, so no change needed and the design
"preservation" item is dropped). Architect leans (a); migration safety
is a strong priority and prohibition would surprise users who already
have such files.

**OQ-7 — `.codex/requirements.toml` (K3) inclusion.**
The audit notes K3 as a gap — it is not currently touched by the
migration. The planner must confirm whether v10 ships an updated
`.codex/requirements.toml` and, if so, add it to S3's touched list with
the same TOML merge logic as K2. If v10 has the same content as v9.3,
the file is not touched and the audit item resolves itself.

**OQ-8 — Existing OT remediation path.**
The OT project is currently in a destroyed state on branch
`migration-v9-to-v10` with the backup intact. After the fix lands, OT
remediation has two options: (1) `git restore` everything and re-run
the fixed migration; (2) manually port content from
`.pack-migration-backup/v9.3-to-v10.0/` files into the current
post-migration tree. Option (1) is cleaner; option (2) preserves the
forensic evidence. Planner / Pack Chat decides; the architect notes
both paths must be documented in `supporting-docs/MIGRATION-v9-to-v10.md`
once the fix ships.

---

## Appendix A — File class summary table

| Class | Path | Pattern | Mechanism (Part 3) |
|---|---|---|---|
| C1–C3 | `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` | P | 3.2 four-case + sidecar; reconciliation via Procedure 5-C |
| D1 | `docs/pack/PM-CHAT.md` | T → P | 3.3 placeholder-detect + sidecar |
| D2 | `docs/pack/PLATFORM-SKILLS.md` | X (with P fallback) | 3.4 four-case + existing splice |
| D3 | `docs/pack/METHODOLOGY.md` | (pack-owned) + detect | 3.5 four-case + sidecar; replace by intent |
| D4 | `docs/pack/PROMPT-TEMPLATES.md` | P | 3.6 existing S6 collapsed into shared helper |
| K1 | `.claude/settings.json` | S | 3.7 JSON key-merge |
| K2 | `.codex/config.toml` | S | 3.7 TOML table-merge |
| K3 | `.codex/requirements.toml` | S | 3.7 TOML; gap to fill |
| K4 | `.mcp.json.example` | S | 3.7 JSON key-merge |
| S1 | `agent-run.sh` | P | 3.9 four-case + sidecar |
| S2 | `scripts/*.sh` (pack roster) | P | 3.9 per-script four-case + sidecar |
| S2-x | `scripts/x-*.sh` | (project-only) | preserved in place; convention codified |
| A1–A3 | `.{tool}/agents/<roster>.{md,toml}` | P | 3.8 four-case + sidecar |
| A1-x–A3-x | `.{tool}/agents/x-*.{md,toml}` | X | preserved (existing) |
| L1–L3 | `.{tool}/skills/<roster>/SKILL.md` + siblings | P + dir | 3.8 four-case for SKILL.md; siblings preserved |
| L1-x–L3-x | `.{tool}/skills/x-*/` | X | preserved (existing) |
| P1 | `docs/pack/prompts/<roster>.md` | P | 3.10 four-case + sidecar |
| P1-x | `docs/pack/prompts/x-*.md` | X | preserved (existing) |
| ROOT | `METHODOLOGY.md` (root) | (legacy removal) | unchanged: backed up + removed |
| G1 | `.gitignore` | append-only | unchanged: append-only line |

---

## Appendix B — Trinity-rule compliance check

This design touches CLAUDE.md, AGENTS.md, GEMINI.md identically:

- All three get the same four-case classifier disposition (Part 3.2).
- All three get the same sidecar naming (`<file>.v9-customized`).
- All three are treated as a single atomic group by `merge-trinity.py`
  (existing behaviour preserved).
- All three get the same `## Project addenda` H2 template change
  (OQ-4).

There is no asymmetry in this design's treatment of the three trinity
files. Tool-specific differences (Codex TOML vs Markdown; Gemini YAML
frontmatter vs Markdown) are confined to the agent-file class
(A1/A2/A3) where they are intrinsic to the tool, and the design's
mechanisms (3.8) apply identically across A1/A2/A3.

---

## Appendix C — Separation-of-concerns check

The migration script and its helpers operate exclusively against
`project-template/`, `supporting-docs/`-shipped content (METHODOLOGY.md
copy), and the `$PACK` v9.3 git tag for baseline retrieval. They never
touch:

- Pack operational files: `PACK-CHAT.md`, `PACK-AGENTS.md`,
  pack-repo `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`, `BACKLOG.md`,
  `CHANGELOG.md`, `README.md`, `QUICKSTART.md`.
- Maintenance records: `maintenance-docs/` (other than as a place to
  store fixtures and design records, which are not read by the
  migration at runtime).

The design's new helpers (`scripts/lib/three-way.sh`, `merge-json.py`,
`merge-toml.py`) and new fixture
(`maintenance-docs/test-fixtures/migration-v9.3-customized/`) live in
the pack-product layer, not the operational layer. The boundary holds.

