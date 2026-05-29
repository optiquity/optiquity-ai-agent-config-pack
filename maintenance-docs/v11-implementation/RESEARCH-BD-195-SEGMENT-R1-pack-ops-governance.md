# RESEARCH-BD-195-SEGMENT-R1-pack-ops-governance

## Segment / owned paths (manifest)
Segment R1 — Pack operations & governance (PM-only + pack-self surfaces): all `pack-ops/*.md` + `.boundary-exempt-root.txt`; pack-root trinity (CLAUDE/AGENTS/GEMINI.md); README.md, QUICKSTART.md, LICENSE.md, .gitignore, tracker.toml.pack-example; pack-root `.github/` (validate-pack.yml + 3 issue forms).

## Coverage attestation
Every owned path read in full EXCEPT: `pack-ops/BACKLOG.md` and `pack-ops/CHANGELOG.md` (518 KB / 46 KB regenerated mirrors — grep-scanned for owned-path references only, not source-of-truth); `LICENSE.md` (skimmed — boilerplate, no version/boundary/cross-ref surface); `MERGE-STRATEGY.md` / `DRY-RUN-MIGRATION.md` (scanned for version/frozen/shorthand markers — clean on those lenses). prison/ NOT read (cross-referenced by filename only).

## Findings count
BLOCKER 0 / MUST 4 / SHOULD 3 / NIT 3

---

## Findings

### R1-F01 — README Repository-Layout mis-files MERGE-STRATEGY.md and DRY-RUN-MIGRATION.md under supporting-docs/
- Severity: MUST
- Category: C (cross-reference), repo-layout-accuracy
- Surface(s): `README.md` § "Repository Layout" — `supporting-docs/` block (the `MERGE-STRATEGY.md` and `DRY-RUN-MIGRATION.md` lines) vs the `pack-ops/` block
- Side: pack-self
- Evidence: README supporting-docs block lists `MERGE-STRATEGY.md   Per-file customization-preservation matrix (v11)` and `DRY-RUN-MIGRATION.md   Companion guide for scripts/dry-run-migration.sh (v11; BD-114 / BD-125)`. On disk both live only in `pack-ops/`. `pack-ops/BOUNDARY-DEFINITION.md` §5.1 confirms canonical placement: "`MERGE-STRATEGY.md` → `pack-ops/MERGE-STRATEGY.md`", "`DRY-RUN-MIGRATION.md` → `pack-ops/DRY-RUN-MIGRATION.md`". QUICKSTART.md line 41 already uses the correct `pack-ops/MERGE-STRATEGY.md`.
- Why it's a problem: CLAUDE.md § "Repo structure" designates the README Repository-Layout section as "the authoritative reference"; mis-filing two files contradicts the canonical BOUNDARY-DEFINITION.md §5.1 (BD-175 F-1 resolution) and misleads any agent resolving these paths.
- Recommendation: Move both entries out of the README `supporting-docs/` block into the `pack-ops/` block. PM-only edit.
- Cross-segment touch points: any segment auditing `supporting-docs/` (these two are NOT there); BOUNDARY-DEFINITION.md §5.1 is the SSOT.
- Confidence: high (on-disk `find` + canonical §5.1 both verified).

### R1-F02 — README pack-ops/ block omits three files that physically reside there
- Severity: MUST
- Category: C (cross-reference), repo-layout-accuracy
- Surface(s): `README.md` § "Repository Layout" — `pack-ops/` block
- Side: pack-self
- Evidence: Actual `pack-ops/*.md` includes `CONCEPTUAL-REVIEW-METHODOLOGY.md`, `DRY-RUN-MIGRATION.md`, `MERGE-STRATEGY.md`; the README pack-ops/ block lists none of the three. `grep "CONCEPTUAL-REVIEW" README.md` returns nothing.
- Why it's a problem: README is the designated authoritative layout (CLAUDE.md § "Repo structure"); three resident pack-ops files are invisible. Omission half of the R1-F01 defect.
- Recommendation: Add `CONCEPTUAL-REVIEW-METHODOLOGY.md`, `DRY-RUN-MIGRATION.md`, `MERGE-STRATEGY.md` to the README `pack-ops/` block. PM-only edit.
- Cross-segment touch points: none beyond README.
- Confidence: high (`ls pack-ops/*.md` vs README block).

### R1-F03 — README maintenance-docs/ layout is materially stale (omits v11-implementation/, v11-research/, prison/; lists two prison-moved files as present)
- Severity: MUST
- Category: C (cross-reference), A (Step-2 reality), repo-layout-accuracy
- Surface(s): `README.md` § "Repository Layout" — `maintenance-docs/` block
- Side: pack-self
- Evidence: README maintenance-docs block lists root docs incl. `GEMINI-CLI-ANALYSIS.md` and `ANDROID-ANALYSIS.md` and subdirs `archive/ origins/ guides/`. Reality: both `GEMINI-CLI-ANALYSIS.md` and `ANDROID-ANALYSIS.md` are NOT in maintenance-docs/ root — moved to `maintenance-docs/prison/` in BD-195 Step 2 (commit `4a3f5e2`). The two largest actual subdirs — `v11-implementation/` (193 entries) and `v11-research/` (64 entries) — and `prison/` are entirely absent from the README block.
- Why it's a problem: The segment explicitly requires verifying the layout reflects reality after the Step-2 prison move. Authoritative layout lists relocated files as present and omits the directories holding all active v11 work. Not a v11.1 issue — a stale-layout-after-Step-2 issue.
- Recommendation: Update the README maintenance-docs/ block: drop the `GEMINI-CLI-ANALYSIS.md` / `ANDROID-ANALYSIS.md` root lines, add `v11-implementation/` and `v11-research/` subdir lines, and either add a one-line `prison/` entry or deliberately omit it with rationale. PM-only edit.
- Cross-segment touch points: any segment auditing maintenance-docs/ trees; Step-2 commit `4a3f5e2`.
- Confidence: high (file-presence test + prison ls + commit verified).

### R1-F04 — PACK-CHAT.md says "Four pack agents" but there are five (omits pack-coder)
- Severity: MUST
- Category: C (cross-reference), E (encoding lock-step), internal-consistency
- Surface(s): `pack-ops/PACK-CHAT.md` § "Behavioral rules" → "Delegate to pack agents when appropriate" bullet
- Side: pack-self
- Evidence: PACK-CHAT.md: "**Four** pack agents exist for structured work: `pack-architect`, `pack-planner`, `pack-reviewer`, and `pack-docs-researcher`." But `pack-ops/PACK-AGENTS.md` line 10 states "**Five** dedicated agents exist" and its table includes `pack-coder`; the on-disk roster confirms five in each of `.claude/agents/`, `.codex/agents/`, `.gemini/agents/` (architect, coder, docs-researcher, planner, reviewer).
- Why it's a problem: Direct contradiction between two pack-self governance surfaces. PACK-AGENTS.md's own "Keeping ... current" rule requires these to stay accurate. An agent reading PACK-CHAT.md would conclude pack-coder is not delegable.
- Recommendation: Change "Four" to "Five" and add `pack-coder` to the enumerated list. PM-only edit (PACK-CHAT.md).
- Cross-segment touch points: PACK-AGENTS.md (authoritative roster); pack agent-files segment.
- Confidence: high (both files read; roster counted on disk).

### R1-F05 — HELP-FRAGMENT-PACK.md advertises sunset script scripts/migrate-v9-to-v10.sh as a live verb
- Severity: SHOULD
- Category: C (cross-reference), A (version)
- Surface(s): `pack-ops/HELP-FRAGMENT-PACK.md` § "Pack scripts (install / migrate / tracker)" — the `scripts/migrate-v9-to-v10.sh` row
- Side: pack-self
- Evidence: HELP-FRAGMENT-PACK.md: "`scripts/migrate-v9-to-v10.sh` | One-shot v9.3 → v10 migrator (frozen). Use against a v9.3 client repo." `ls scripts/migrate-v9-to-v10.sh` → "No such file or directory". README lines 156-157/198 confirm the v9→v10 migrator "were sunset in v11 per BD-121; recover from history with `git checkout v10 -- ...`".
- Why it's a problem: The pack-side verb reference (rendered by `pack help` / `/pack-help`) presents a runnable command for a script that does not exist at v11 HEAD → file-not-found for the user. README's mention is in the historical v10.0 version-history row (acceptable); the help fragment presents it as current.
- Recommendation: Remove the row, or replace with a "(sunset in v11 per BD-121 — recover from `git checkout v10`)" note that does not present a live verb.
- Cross-segment touch points: QUICKSTART.md line 34 (see closing note — same sunset-artifact theme).
- Confidence: high (file absence + BD-121 sunset note verified).

### R1-F06 — BOUNDARY-DEFINITION.md §6 declares a cross-reference network whose pack-self entry-point pointers do not exist
- Severity: SHOULD
- Category: E (encoding lock-step), C (cross-reference)
- Surface(s): `pack-ops/BOUNDARY-DEFINITION.md` §6.1 + §6.2 + §6.4 ("discoverability invariant") vs `README.md`, pack-root trinity, `pack-ops/PACK-CHAT.md`, `pack-ops/PACK-AGENTS.md`
- Side: pack-self
- Evidence: §6.4: "Any actor ... can reach this doc by ONE of these paths: reading README, reading PACK-CHAT.md, reading PACK-AGENTS.md, reading the pack trinity ...". §6.1 claims a top-section pointer in PACK-CHAT.md, PACK-AGENTS.md, and the pack-trinity pack-memory section; §6.2 claims a README § Repository-Layout one-line pointer. Actual: `grep "BOUNDARY-DEFINITION"` finds NO pointer in PACK-CHAT.md, PACK-AGENTS.md, or any pack-root trinity file; README's only hit is the layout-listing line for the file itself (not a pointer).
- Why it's a problem: The doc asserts a discoverability invariant ("No actor has to GUESS where the rule lives") that is false on the surfaces it names. Per the pack-memory "Enumerate ENCODING surfaces" rule, a declared cross-reference network must be in lock-step with the surfaces meant to encode it. §6.1 hedges relocation as "post-Commit 2" but asserts the pointers themselves as present-tense; they are absent.
- Recommendation: Either (a) add the declared one-line pointers to README § Repository Layout, the pack-trinity pack-memory section, and the top of PACK-CHAT.md / PACK-AGENTS.md (trinity edits in lock-step), or (b) downgrade §6 to aspirational and drop the "discoverability invariant" claim. Architect pass (touches trinity).
- Cross-segment touch points: pack agent files (§6.2 also claims a pointer in each pack-* agent read-list — verify in the agent-files segment); project-side PM-CHAT.md (§6.1 claims a pointer there — project-side segment).
- Confidence: medium (pointers absent on all R1-owned surfaces; agent-file / PM-CHAT pointers outside R1, unverified here).

### R1-F07 — CONCEPTUAL-REVIEW-METHODOLOGY.md references a non-existent ARCHITECTURE-V1.md and uses bare-version shorthand throughout
- Severity: SHOULD
- Category: C (cross-reference), filename-uniqueness / bare-version-shorthand leak
- Surface(s): `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` § "From the now-archived `ARCHITECTURE-V1.md` and `V3.3-DELTA.md`" list + § "Design best practices (for dimension e)" table Source column
- Side: pack-self
- Evidence: Cites "V1 §6.0", "V1 §5.3", "V1 §9 / §9.6", "V3 §27.1", "V3.3 §1", "V3.3 §9.7", "V3.3 §8.4", "V3.3 §5.6", "V3.3 §5.3" as anchors; header reads "From the now-archived `ARCHITECTURE-V1.md` and `V3.3-DELTA.md`". `find` shows NO `ARCHITECTURE-V1.md` anywhere (the "V1 §…" refs resolve to nothing). `V3.3-DELTA.md` exists only as `maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md` — bare "V3.3 §X" gives no path.
- Why it's a problem: The pack-memory "Filename uniqueness heuristic" explicitly calls bare-version shorthand "a leak under the rule's spirit because the reader has no filename to follow, no path to resolve, and the version shorthand is ambiguous." Compounded: `ARCHITECTURE-V1.md` is a dangling reference (target absent), so the "V1 §…" anchors cannot be followed at all.
- Recommendation: (a) Replace each bare "V3.3 §X" with `maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md §X`. (b) Resolve the "V1 §…" anchors — identify the real successor doc (no `ARCHITECTURE-V1.md` exists) and cite file+path, or remove the dangling anchors. (c) Verify the "now-archived" claim against actual locations.
- Cross-segment touch points: maintenance-doc segments auditing `maintenance-docs/v11-research/ARCHITECTURE.md` / `ARCHITECTURE-V3.3-DELTA.md`; the same bare-shorthand class likely recurs elsewhere.
- Confidence: high (ARCHITECTURE-V1.md absence + V3.3-DELTA path both verified by `find`).

### R1-F08 — "Task tool" vs "Agent tool" terminology disagreement between PACK-AGENTS.md/PACK-CHAT.md and the pack trinity
- Severity: NIT
- Category: C (cross-reference), internal-consistency
- Surface(s): `pack-ops/PACK-AGENTS.md` § "Sub-agent invocation (from pack chat)"; `pack-ops/PACK-CHAT.md` § "Delegate to pack agents" bullet; vs pack-root `CLAUDE.md` § "Pack memory" → "Agent invocation rules" / "Sub-agent behavior"
- Side: pack-self
- Evidence: PACK-AGENTS.md: "The pack chat uses the **Task tool** to spawn pack agents". PACK-CHAT.md: "Use sub-agent invocation (**Task tool**)". CLAUDE.md pack-memory: "via the **Agent tool** with `subagent_type=pack-<name>`" and repeatedly "the **Agent tool**'s `run_in_background` parameter".
- Why it's a problem: Terminology drift across pack-self governance surfaces for the same mechanism. Not load-bearing → NIT. Claude Code's sub-agent tool naming has shifted across versions, so the currently-correct name should be confirmed before normalizing.
- Recommendation: Pick one term (verify the current Claude Code tool name) and normalize across PACK-AGENTS.md, PACK-CHAT.md, and the trinity in one pass; trinity edits in lock-step.
- Cross-segment touch points: none beyond these three.
- Confidence: medium (mismatch verified; which name is currently canonical not independently confirmed against Claude Code docs).

### R1-F09 — Pack-side HELP-FRAGMENT-TRACKER.md (rendered by the pack's own `pack help`) advertises TD/phase-task verbs as pack-self commands
- Severity: NIT
- Category: B (boundary — deliverable-only)
- Surface(s): `pack-ops/HELP-FRAGMENT-TRACKER.md` § "TD promotion (v11+)" + § "Colloquial mappings" (the `pack td promote --to=phase-N.M` rows); rendered for the pack repo via `scripts/pack-help.sh` `get_tracker_fragment`
- Side: pack-self
- Evidence: HELP-FRAGMENT-TRACKER.md: "`pack td promote --to=phase-N.M <td-id>` | Path 2 — promote TD to a new phase task under phase N." `scripts/pack-help.sh` resolves the pack-side fragment when CWD = pack root, so the pack's own `pack help` prints TD→phase-task verbs. Pack-side and project-side copies are byte-identical (`diff` empty). Contrast: pack-root `.github/ISSUE_TEMPLATE/work-item.yml` was cleaned to admit only `bd` (no `td`/`phase-*`) per BD-193 deliverable-only.
- Why it's a problem: The pack-memory "Project-side concepts on pack-side surfaces — deliverable-only" rule forbids TD/phase/phase-task references on pack-self-management surfaces; work-item.yml was cleaned but the pack-self help surface still surfaces them. NIT (not MUST) because the fragment is byte-identical shared CLIENT-deliverable content and `pack-td.sh` is a real shipped script — the deliverable-only test ("constructing a project-side deliverable vs pack-self-management?") needs an architect call.
- Recommendation: Architect adjudication. If `pack td promote --to=phase-N.M` is project-deliverable-only, gate the TD-promotion section out of the pack-side render (mirroring the work-item.yml cleanup); if it's a legitimate cross-surface verb, document the exemption. Do NOT mechanically delete — verify property-fit first.
- Cross-segment touch points: `scripts/pack-help.sh` (renderer); project-side `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (byte-identical copy); `scripts/pack-td.sh`.
- Confidence: medium (boundary leak is real on the pack-self render path; whether it's intended shared-deliverable content is the open question).

### R1-F10 — tracker.toml.pack-example points the pack user to a design doc ("ARCHITECTURE.md §6") to run a migration, with no path
- Severity: NIT
- Category: C (cross-reference), filename-uniqueness, usability
- Surface(s): `tracker.toml.pack-example` — header comment block
- Side: pack-self
- Evidence: tracker.toml.pack-example: "#   3. Run the forward migration script (see ARCHITECTURE.md §6)." and "# Read by scripts/lib/tracker-config.sh; spec: ARCHITECTURE.md §3.1." A bare `ARCHITECTURE.md` exists only at `maintenance-docs/v11-research/ARCHITECTURE.md` (no path given; generic name). The project-side `project-template/tracker.toml.project-example` carries NO such reference (clean — no client leak).
- Why it's a problem: (a) bare path-less `ARCHITECTURE.md` is ambiguous (filename-uniqueness). (b) Usability: directs the user to a maintenance design doc to "run the forward migration" when the actual command is `bash scripts/pack-tracker.sh init` (per OPTIONAL-FEATURES.md).
- Recommendation: Replace "see ARCHITECTURE.md §6" with the concrete command (`bash scripts/pack-tracker.sh init`); for spec pointers give the full path `maintenance-docs/v11-research/ARCHITECTURE.md §3.1`.
- Cross-segment touch points: `maintenance-docs/v11-research/ARCHITECTURE.md` (real target — maintenance-doc segment).
- Confidence: medium (target exists but path-less; usability call).

---

## Coverage map

| Owned path | Result |
|---|---|
| `README.md` (Repository Layout + Version table) | R1-F01, R1-F02, R1-F03 (layout); Version table clean (Lens A) |
| `QUICKSTART.md` | dangling sunset link noted (line 34 `MIGRATION-v9-to-v10.md` absent — see closing note); otherwise clean |
| `LICENSE.md` | clean (skimmed) |
| `.gitignore` | clean (no stale pack-ops/moved-file refs) |
| `tracker.toml.pack-example` | R1-F10 |
| pack-root `CLAUDE.md` | clean directly; implicated by R1-F06, R1-F08 |
| pack-root `AGENTS.md` | clean (H2 parity held); implicated by R1-F06, R1-F08 |
| pack-root `GEMINI.md` | clean (extra "Gemini CLI operating notes" H2 = justified tool-specific); implicated by R1-F06, R1-F08 |
| `pack-ops/BACKLOG.md` | clean on owned-path-ref scan (mirror; not read in full) |
| `pack-ops/CHANGELOG.md` | clean on owned-path-ref scan (mirror; not read in full) |
| `pack-ops/PACK-CHAT.md` | R1-F04, R1-F08; R1-F06 (missing pointer) |
| `pack-ops/PACK-AGENTS.md` | R1-F08; R1-F06; roster authoritative (5 agents) |
| `pack-ops/BOUNDARY-DEFINITION.md` | R1-F06 |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | R1-F07 |
| `pack-ops/MERGE-STRATEGY.md` | clean (location defect is in README — R1-F01) |
| `pack-ops/OPTIONAL-FEATURES.md` | clean (ARCHITECTURE-V3.3-DELTA ref resolves; pack-side only, no client leak) |
| `pack-ops/DRY-RUN-MIGRATION.md` | clean (location defect is in README — R1-F01) |
| `pack-ops/HELP-FRAGMENT-PACK.md` | R1-F05 |
| `pack-ops/HELP-FRAGMENT-TRACKER.md` | R1-F09 |
| `pack-ops/.boundary-exempt-root.txt` | clean (1 entry `tracker.toml.pack-example`, matches §4) |
| `.github/workflows/validate-pack.yml` | clean (Check-count claim in README consistent — 12-15 + 24 retired) |
| `.github/ISSUE_TEMPLATE/work-item.yml` | clean (wi-type admits only `bd` — BD-193 deliverable-only cleanup landed) |
| `.github/ISSUE_TEMPLATE/inbound.yml` | clean |
| `.github/ISSUE_TEMPLATE/config.yml` | clean |

---

## Notes for the parent agent

1. **Output-file caveat:** the Write tool was not enabled in this context, so I could not create `maintenance-docs/v11-implementation/RESEARCH-BD-195-SEGMENT-R1-pack-ops-governance.md`. The full report is delivered above as my final message (per the "parent agent reads your text output, not files you create" directive). If a file is required, the content above is ready to paste verbatim.

2. **QUICKSTART sunset-link (closing note):** `QUICKSTART.md` line 34 links `supporting-docs/MIGRATION-v9-to-v10.md`, which does not exist (sunset per BD-121 — same theme as R1-F05). It is the second of two migration paths offered (the v10→v11 path is valid). Folded into R1-F05's remediation theme: decide whether v9→v10 sunset artifacts should be scrubbed from live user-facing surfaces or left as historical notes. Low confidence on severity (router doc, one path of two valid).

3. **Lens A (version) for this segment is largely clean:** no "frozen" language and no phase-parts-mislabeled-as-v11.1 anywhere in the owned paths. All `v11.1` references in the trinity are the legitimate "No deferral to v11.1+ without explicit user direction" rule. The README v11.0 version row and the tracker-feature "v11.x roadmap" notes (BD-109/BD-110 auditor agent) are correctly future-scoped.

4. **Lens D (trinity parity) held:** pack-root CLAUDE/AGENTS/GEMINI H2 sections align; GEMINI's extra "Gemini CLI operating notes" section is justified tool-specific (Gemini `/chat save`, `save_memory`, Plan Mode). The R1-F06 and R1-F08 fixes that touch the trinity must be applied to all three in lock-step.
