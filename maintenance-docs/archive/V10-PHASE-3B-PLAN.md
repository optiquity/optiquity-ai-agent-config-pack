# V10-PHASE-3B-PLAN — PM chat kickoff auto-discovery + install-check

## Part 0 — Status + linkage

**STATUS: DRAFT.** Planner-pass output. Consumes
`maintenance-docs/V10-PHASE-3B-DESIGN.md` (commit `7d2347f`). Awaiting
pack-chat review. Implementation may not begin until this plan is
approved.

**Backlog item:** BD-047 — v10.0 ship-blocker.

**Gate membership:** Gate E3 (new, introduced by Phase 3-B; mirrors
Gate E / Gate E2 pattern in `V10-IMPLEMENTATION-PLAN.md`).

**Predecessor:** Phase 3-AC Gate E2 (closed at commit `84cb4ef`).
**Successor:** Phase 4 Gate F (final v10.0 release pass).

**Scope principle (restated from design Part 0):** this phase ships the
kickoff-variant text change and the SETUP-guide collapse. It does
**not** touch the trinity files, does **not** add a `METHODOLOGY.md`
Procedure, does **not** alter `validate-pack.py`, does **not** touch
`init-project.sh` / `add-capability.sh` / `detect.sh`, and does **not**
change any script under `project-template/scripts/`. The implementer
must flag any drift from this scope to the pack chat before committing.

---

## Part 1 — Decisions table (14 open questions / gaps)

For each row: **decision** is the concrete call the implementer
follows. **Rationale** is 1–3 sentences. **Depends on** names any
other decision that must settle first. **Surface in plan** names the
Part of this document where the decision is expanded.

### 1.1 Architect's Part 14 open questions (Q14-1..Q14-9)

| # | Question | Decision | Rationale | Depends on | Surface |
|---|---|---|---|---|---|
| Q14-1 | Read-only discovery batch granularity | **Single combined Form R batch** covering all read-only commands for both Apple and gRPC sub-flows. | One approval per side-effect class (design Part 5 §5.2). All discovery commands are read-only; splitting per sub-flow doubles the approval load without risk differentiation. Host-level per-command approval (Codex/Claude Code) is orthogonal and still fires. | none | Part 3 (Form R idempotency); Part 7 Commit 1 |
| Q14-2 | Brew tool known-good version range source of truth | **Hardcode ranges inline in the kickoff variant text**, annotated with a reference comment pointing at `supporting-docs/DEPENDENCIES.md`. | v10.0 simplicity — no new file, no new convention. DEPENDENCIES.md already exists as the authoritative tool-versions reference; the kickoff variant restates the ranges near the install prompts so the developer reads them in context. Future refinement can migrate to `TOOL-VERSIONS.md` if/when ranges diverge across tools. | none | Part 4 |
| Q14-3 | Companion-files install: opt-in vs opt-out; stale detection | **Opt-in (Form M default = `skip` per design Part 8 §8.3 fail-safe).** Stale-install detection fires a recommendation line but does **not** change the default. | Fail-safe defaults are the whole point of the approval-gate pattern. Elevating to opt-out for staleness breaks the invariant that every destructive/writing action defaults to `skip`. Language changes; default does not. | none | Part 3 (Form M idempotency) |
| Q14-4 | Should kickoff offer to commit in-tree edits? | **No.** Kickoff leaves the working tree dirty after Form E writes. Developer commits manually (SETUP-NEW Step 9 / SETUP-EXISTING Step 7, both unchanged). | Kickoff is a discovery + edit flow, not a commit authority. Committing inside kickoff couples the decision to approve an edit with the decision to land it in git, and the Form M `cp` to `~/Library/...` is outside the project tree and cannot participate in the commit anyway. Keeping kickoff commit-free preserves the existing SETUP-guide boundary. | none | Part 7 Commit 1 (outline) |
| Q14-5 | Capability-addition kickoff symmetry (discovery at `add-capability.sh` time) | **Defer — do not file a BACKLOG entry in this plan.** Record as a candidate for Pack Chat to file post-v10.0. Draft BD entry text is in Part 10. | Out of Phase 3-B scope (design Part 9 §9.2). Pack Chat owns BACKLOG.md; this planner must not create BD items. | none | Part 10 (implementer flag-back); Part 11 flag for pack chat |
| Q14-6 | Surface declaration: placeholder vs opening question | **Opening question (keep design Part 4.2 choice).** | The pasteable kickoff text must be portable across surfaces. Baking the surface into a placeholder forces the developer to commit to one surface at paste time; the opening-question form lets the same pasted text serve any surface. Matches architect's lean. | none | Part 7 Commit 1 (insertion #1) |
| Q14-7 | Gemini plan-mode protection | **Explicit single-line instruction at the top of the kickoff variant** (architect's lean — confirmed). Text: "If you are running Gemini CLI and currently in plan mode (`/plan`), exit plan mode before continuing — kickoff requires shell execution." | Transparency over post-hoc recovery. The developer reads the instruction once at paste time; no runtime detection needed. Single sentence, zero cost to other surfaces. | none | Part 7 Commit 1 (insertion #1, before surface declaration block) |
| Q14-8 | Form M: read from `xcode-companion-templates/` vs. hardcode | **Read at runtime from `$PACK/xcode-companion-templates/`** via `ls` or `find`, then emit the file list in Form M's preview. | Parity with single-source-of-truth discipline already established by `add-capability.sh` sourcing `scripts/lib/detect.sh` (V10-DESIGN §5.14.7). The companion-templates directory IS the source; hardcoding duplicates a list that will drift. Implementation: `ls "$PACK/xcode-companion-templates/ClaudeAgentConfig"` + `ls "$PACK/xcode-companion-templates/Codex"`. Fallback: if the `ls` fails, Form M prints a diagnostic and skips (no guess). | none | Part 7 Commit 1 (insertion #5) |
| Q14-9 | Existing-project ordering: discovery before / during / after existing-docs pointer (SETUP-EXISTING Step 9) | **During the kickoff workflow, after the existing-docs pointer completes** (architect's lean — confirmed). | Discovery is mechanical and does not consume existing-docs context; running it after the reconciliation step avoids interleaving mechanical prompts with architectural-decision prompts. SETUP-EXISTING text states this explicitly (Part 2 below). | none | Part 7 Commit 2 (SETUP-EXISTING edit) |

### 1.2 Pack-chat review gaps (Q10..Q14 from the prompt)

| # | Gap | Decision | Rationale | Depends on | Surface |
|---|---|---|---|---|---|
| Q10 | Form E anchor-matching strategy (empty-string vs bracketed vs populated) | **Literal-string match against the current empty-string placeholder form as primary; bracketed-legacy-form match as fallback; any third shape treated as "already-populated or unknown" and skipped with a printed diagnostic.** Exact strings in Part 2. | Deterministic, reviewable; matches the actual pack state (scripts currently ship `XCODE_SCHEME=""`, not `[SCHEME_NAME]`). Bracketed fallback covers any project that hand-filled the old v8-style placeholders. "Already-populated" path preserves developer edits (idempotency). | none | Part 2 |
| Q11 | Idempotency on re-invocation (empty-diff no-op) | **Per-Form detection rules specified in Part 3.** Form R always re-runs (read-only). Form I is a no-op when `command -v <tool>` returns a path AND the installed version is within the known-good range. Form E is a no-op when the anchor already equals the discovered value (empty-diff). Form M is a no-op when every target file under `~/Library/Developer/Xcode/CodingAssistant/` matches the pack source byte-for-byte. | Each Form has its own "target state" definition; no-op is emitted only when the target state already holds. The PM chat prints a one-line "already done — skipping" diagnostic in each no-op case so the developer sees the non-action. | Q10, Q14-3, Q14-8 | Part 3 |
| Q12 | Brew tool version ranges — concrete list | **See Part 4.** Starting ranges derived from latest stable as of 2026-04 with an empirical-refinement flag on every entry. | Concreteness required for the implementer; the ranges are text in the kickoff variant so refinement is a future one-line edit. | none | Part 4 |
| Q13 | Commit 1 splitting | **Keep as one commit.** The 7 insertion points form one coherent feature (surface-declaration + Form R batch + Apple sub-flow + gRPC sub-flow + Manual-mode branch + error-branch behaviors + Gemini plan-mode line). Splitting creates intermediate states in which the kickoff variant is half-upgraded — worse than one atomic diff. | The variant file is single-purpose and single-file; a commit-per-insertion sequence would break the variant at every intermediate commit (partial branches, missing error behavior). Pack-chat review and `git revert` both favor the atomic form. | none | Part 7 Commit 1 |
| Q14 | Concurrent / interrupted kickoff handling | **Rely on (a) Form-level idempotency (Q11) on re-invocation, and (b) the existing PM-CHAT.md rule "Never run two PM chats simultaneously for the same project" for the concurrent case.** No new text needed in pm-chat.md or PM-CHAT.md. | Aborting mid-kickoff leaves one or more target states already changed; re-invocation's per-Form no-op logic produces a correct continuation automatically. The concurrent case is already covered by PM-CHAT.md (SETUP-NEW §10 references this rule). Adding explicit partial-state recovery text duplicates idempotency logic already specified in Part 3. | Q11 | Part 3; Part 7 Commit 1 (no insertion required) |

**Net commit count:** 2 commits (see Part 7). Commit 3 (PM-CHAT.md
Behavioral rule) is explicitly dropped — see Part 7 Commit 3 decision.
Commit 4 (fixture cleanup) is dropped because fixtures live outside the
repo — see Part 5.

---

## Part 2 — Form E anchor-matching specification

Form E (design Part 8 §8.2) writes to four target locations. For each,
the primary anchor is the literal empty-string placeholder shipped by
the v10 pack (as of commit `7d2347f`). A bracketed-legacy fallback
covers v8-style hand-filled placeholders. Any third shape is treated
as "already populated or unrecognized" and Form E prints a
diagnostic and skips the target.

**Correction from BD-047 description.** BD-047 names
`scripts/validate.sh`, `scripts/test.sh`, and `scripts/format.sh`. Post
BD-026 these are language-agnostic wrappers; the actual Xcode-variable
anchors live in `validate-swift.sh`, `test-swift.sh`, and
`format-swift.sh`. Kickoff targets the language-specific scripts. See
Part 10 flag-back #1.

### 2.1 Target anchors (primary form)

| Target file | Anchor line (primary, literal match) | Discovered from |
|---|---|---|
| `scripts/validate-swift.sh` (line 15) | `XCODE_SCHEME=""` | `xcodebuild -list` (Apple sub-flow) |
| `scripts/validate-swift.sh` (line 16) | `XCODE_DESTINATION=""` | `xcrun simctl list devices available` (+ fallback to `platform=macOS`) |
| `scripts/test-swift.sh` (line 7) | `XCODE_SCHEME=""` | same as above |
| `scripts/test-swift.sh` (line 8) | `XCODE_DESTINATION=""` | same as above |
| `scripts/format-swift.sh` (line 21) | `SWIFT_SOURCE_DIRS=""` | directory inspection + developer input (Part 6 #8 in design) |
| `.claude/settings.json` `env` block | `"XCODE_SCHEME": ""` and `"XCODE_DESTINATION": ""` (inside the `env` object) | same as the script anchors |

### 2.2 Matching rules

For each anchor:

1. **Primary.** Try literal-string match against the shipped
   empty-string form (the table above). This is the expected state
   for a project where `init-project.sh` has just run.
2. **Legacy fallback.** If primary does not match, try the
   bracketed-placeholder form:
   - `XCODE_SCHEME="[SCHEME_NAME]"` / `XCODE_DESTINATION="[DESTINATION]"`
   - `SWIFT_SOURCE_DIRS="[SOURCE_DIRS]"`
   - `"XCODE_SCHEME": "[SCHEME_NAME]"` / `"XCODE_DESTINATION": "[DESTINATION]"`
3. **Already-populated or unknown.** If neither primary nor legacy
   matches, Form E prints one line — `note: {file} {variable} is
   already set to "{current_value}" — skipping` — and moves on. Do
   **not** propose an overwrite. This preserves any hand-edit the
   developer already made.

### 2.3 Diff rendering

Form E renders the proposed change as a two-line unified-diff excerpt
(pattern already shown in design Part 8 §8.2 example). The diff
header is the file path + a single colon; no `---`/`+++` triple-line
headers needed — the developer reads the before/after pair directly.

### 2.4 Settings.json safety rule

`.claude/settings.json` is JSON. Form E does not regex-rewrite the
whole file. Its edit strategy is:

- Read the file, parse as JSON, mutate `env.XCODE_SCHEME` and
  `env.XCODE_DESTINATION`, re-serialize with 2-space indent.
- If the file does not parse as JSON: surface the parse error,
  print the intended diff as textual instructions, ask the
  developer to apply manually. Do **not** attempt a regex fix.

(This matches the current `validate-pack.py` discipline — JSON
files are never regex-rewritten.)

### 2.5 What "not covered" means

If a target file is missing (e.g., a Python-only project has no
`scripts/validate-swift.sh`), Form E does not emit that target at all
— its enclosing sub-flow is guarded by the Apple-conditional branch
(design Part 7 §7.4). Missing target ≠ error.

---

## Part 3 — Idempotency rules per Form

For each Form, the "target state" is defined. When the target state
already holds, the Form emits a single-line "already done —
skipping" diagnostic and moves on. No approval prompt fires on no-op.

### 3.1 Form R (read-only discovery)

**Target state.** None — Form R has no persistent target state.

**Rule.** Form R **always runs** on every kickoff invocation.
Rationale: the pass is read-only, cheap, and the discovered values
may have changed since the last run (new simulator, new Xcode
scheme). Re-running never harms.

### 3.2 Form I (single install)

**Target state.** `command -v <tool>` returns a path **AND**
`<tool> --version` is within the known-good range (Part 4).

**Rules.**

- Both conditions true → no-op. Diagnostic:
  `note: <tool> already installed at <version> (within known-good range) — skipping`
- Tool present, version outside range → **not a no-op.** Form I
  (upgrade variant) prompts: "observed <version>; pack tested with
  <range>. Reply `yes` to upgrade or `skip` to keep current." Default
  on any unrecognized reply: `skip`.
- Tool absent → Form I (install variant) prompts as in design Part 8
  §8.2.

### 3.3 Form E (single file edit)

**Target state.** The anchor is already set to the value Form E
would propose (empty-diff).

**Rules.**

- Anchor already equals the proposed value → no-op. Diagnostic:
  `note: <file> <variable> already set to "<value>" — skipping`
- Anchor is in its primary or legacy-fallback placeholder form → Form
  E emits normally.
- Anchor is populated with a **different** value (neither placeholder
  nor proposed value) → see Part 2 §2.2 rule 3: print skipping note,
  do not propose overwrite.

### 3.4 Form M (companion-files batch)

**Target state.** Every source file under
`$PACK/xcode-companion-templates/` has a byte-identical counterpart at
the corresponding path under
`~/Library/Developer/Xcode/CodingAssistant/`.

**Rules.**

- All files present and byte-identical → no-op. Diagnostic:
  `note: Xcode companion files already present and up to date — skipping`
- All files present, some differ (stale install) → Form M prompts
  with an elevated recommendation line:
  `recommendation: installed companion files differ from the pack — reinstall recommended`
  Default remains `skip` per Q14-3.
- Any file missing → Form M prompts normally.

Byte-identity check: shell-level `cmp -s <src> <dst>` per file. Missing
or different → not-idempotent.

### 3.5 What the PM chat prints when everything is a no-op

If Form R runs (mandatory), all Form I targets are in-range, all Form
E anchors are populated, and all Form M targets are byte-identical, the
PM chat prints:

```
Kickoff complete — nothing to change.
  - All Form R discovery commands succeeded.
  - All checked tools are installed and in range.
  - All script/settings anchors are already populated.
  - Xcode companion files are byte-identical with the pack.
```

This is the empty-diff re-invocation terminal state. It is the signal
the kickoff is idempotent on this project.

---

## Part 4 — Brew version ranges (pack-tested starting baseline, 2026-04)

Each range is **hardcoded inline** in the kickoff variant text (Q14-2)
with a comment pointing at `supporting-docs/DEPENDENCIES.md`. Every
entry is flagged for empirical refinement after first-real-project
use.

### 4.1 Apple / Swift side

| Tool | Known-good range | Notes |
|---|---|---|
| `swift-format` | `≥510.0.0` | Swift 6 / Xcode 16+ matching. Below 510, formatting output may differ. |
| `buf` | `≥1.35.0` | buf 1.35 is the pack's reference across `validate-proto.sh` usage. |
| `swift-protobuf` | `≥1.28.0` | Apple-side protobuf runtime; current at time of plan. |
| `grpc-swift` | `≥1.24.0` (1.x-line) | 2.x migration is out of scope for v10.0; the pack targets 1.x. |

### 4.2 Python side (optional — only when Python + gRPC detected)

| Tool | Known-good range | Notes |
|---|---|---|
| `grpcio-tools` | `≥1.64.0` | Matches Python 3.12+ wheels; `uv add` path. |
| `grpcio` | `≥1.64.0` | Same line as grpcio-tools; pin them together. |
| `grpcio-status` | `≥1.64.0` | Same line. |
| `grpcio-reflection` | `≥1.64.0` | Optional — only if reflection is used. |

### 4.3 Empirical-refinement protocol

Every entry above carries the in-text annotation:

> *Pack-tested starting range (2026-04). Refine empirically after
> first real-project use — see PACK-FEEDBACK.md.*

When the first downstream project reports a tool-version mismatch that
the range got wrong, the PM chat appends to PACK-FEEDBACK.md per
METHODOLOGY.md Part 10; Pack Chat updates the inline range in a
future minor version.

### 4.4 Where the ranges live in the variant text

Form I's "Side effects:" block includes the range, e.g.:

```
PROPOSED ACTION — install
  Command:        brew install swift-format
  Purpose:        enables scripts/format-swift.sh to format Swift sources
  Pack-tested:    swift-format ≥510.0.0 (see supporting-docs/DEPENDENCIES.md)
  Side effects:   writes to /opt/homebrew/Cellar; ~5MB; network required
  Skip impact:    format-swift.sh emits a warning but does not block validation
```

---

## Part 5 — Test fixture sourcing strategy

### 5.1 Fixtures live outside the repo

The six fixture projects named in design Part 11 (`apple-spm-single-scheme`,
`apple-multi-scheme`, `apple-no-simulator`, `apple-non-spm-layout`,
`python-grpc-server`, `python-only`) are **ephemeral, constructed
per-review, and never committed to the pack repo**. The implementer
creates them under a path outside the pack working tree, e.g.
`~/tmp/phase-3b-fixtures/<name>/` or `/tmp/phase-3b-fixtures/<name>/`.

**Rationale.** `maintenance-docs/v10-working/` is a tracked directory
— entries there are committed to the pack repo, and `.gitignore`
does not exclude `maintenance-docs/v10-working/*`. Placing fixtures
there would commit test artifacts into the pack repo and trigger
`validate-pack.py` pathway noise. Putting fixtures on `/tmp/`
removes the question entirely: they are outside any tracked
directory, never approach a commit, and disappear on reboot.

### 5.2 Construction method — manual-ad-hoc (option (a) from the prompt)

Each fixture is built by:

1. `mkdir -p /tmp/phase-3b-fixtures/<name>`
2. `cd` into it, `git init`
3. `"$PACK/scripts/init-project.sh" .` — once, per SETUP-NEW Step 3
4. Fill trinity placeholders for the fixture's project type (SETUP-NEW
   Step 4)
5. For Apple fixtures: create a stub `Package.swift` or a stub
   `*.xcodeproj` directory as needed to make the conditional branches
   fire.
6. For the multi-scheme fixture: fake `xcodebuild -list` output by
   placing a stub `Package.swift` with multiple products, OR by
   setting an `XCODEBUILD_LIST_FIXTURE` env var the kickoff-variant
   prose ignores but a human reviewer recognizes as "pretend this
   returned two schemes."

### 5.3 Why not a helper script

Option (b) in the prompt (generated by a committed helper) was
considered and rejected. A helper script would itself need to be
reviewed, tested, and documented — and the fixtures are so
lightweight that the scripting cost exceeds the construction cost.
Option (c) (reuse Phase 4 infrastructure) is rejected because Phase 4
fixtures do not exist yet and Phase 3-B cannot block on Phase 4.

### 5.4 What the implementer commits vs. runs

- **Committed:** nothing — no fixtures, no fixture-helper script, no
  fixture README. Test results are captured in the Gate E3 approval
  narrative only.
- **Runs:** the six fixtures per design Part 11 §11.1 before pack
  chat signs off Gate E3.

### 5.5 What is deferred to Phase 4

Fixture-based cross-surface verification for Codex CLI, Gemini CLI,
and Desktop Commander (design Part 11 §11.2): one `apple-spm-single-scheme`
run on each. If any of these three surfaces is not available to the
implementer at Phase 3-B time, defer to Phase 4 (Gate F) — see Part 9.

---

## Part 6 — Cross-reference sweep specification

### 6.1 Sweep goal

After Commit 2, no file in the pack may cite
`SETUP-NEW.md Step 5/6/7/8` or `SETUP-EXISTING.md Step 5/6` as a
detail-reference, except the SETUP guides themselves. Cross-references
that name a later step (e.g., `SETUP-NEW.md Step 10`) remain valid
because the collapse keeps Steps 9 and later at their current numbers
— see the numbering decision in §6.3.

### 6.2 Grep commands (run from repo root)

```bash
# S3B-1 — SETUP-NEW Steps 5..8 detail references (expected zero after Commit 2
# except in SETUP-NEW.md itself, historical migration guides, and this plan).
grep -rnE 'SETUP-NEW\.md[[:space:]]+(Step|§)[[:space:]]?[5-8]\b' \
    project-template/ supporting-docs/ maintenance-docs/ \
    QUICKSTART.md README.md CLAUDE.md AGENTS.md GEMINI.md \
    PACK-CHAT.md PACK-AGENTS.md BACKLOG.md

# S3B-2 — SETUP-EXISTING Steps 5..6 detail references (expected zero except
# in SETUP-EXISTING.md itself).
grep -rnE 'SETUP-EXISTING\.md[[:space:]]+(Step|§)[[:space:]]?[56]\b' \
    project-template/ supporting-docs/ maintenance-docs/ \
    QUICKSTART.md README.md CLAUDE.md AGENTS.md GEMINI.md \
    PACK-CHAT.md PACK-AGENTS.md BACKLOG.md

# S3B-3 — BD-047 description alignment (informational; does not block).
grep -n 'scripts/validate\.sh\|scripts/test\.sh\|scripts/format\.sh' \
    BACKLOG.md maintenance-docs/V10-PHASE-3B-DESIGN.md

# S3B-4 — pm-chat.md variant mention sanity check.
grep -n 'Variant: kickoff' project-template/docs/pack/prompts/pm-chat.md \
    supporting-docs/ project-template/PM-CHAT.md project-template/docs/pack/PM-CHAT.md \
    project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md
```

### 6.3 Expected zero-match / sanctioned-residual set

| Sweep | Expected after Commit 2 | Sanctioned residuals |
|---|---|---|
| S3B-1 | Zero matches in `project-template/`, `QUICKSTART.md`, `README.md`, `PACK-*.md`, `BACKLOG.md`, and root trinity. | `supporting-docs/SETUP-NEW.md` itself (the collapsed Step 5 sub-sections are labeled 5.A–5.D per design Part 10.1 — the strings "Step 5" and "5.A" may appear); `supporting-docs/MIGRATION-v9-to-v10.md` Step 5 / 6 headers (different semantic — custom-file registration, not SETUP-NEW). `maintenance-docs/V10-PHASE-3B-*.md` may cite the historical step numbers. `maintenance-docs/V10-IMPLEMENTATION-PLAN.md` historical references are acceptable. |
| S3B-2 | Zero matches in `project-template/`, `QUICKSTART.md`, `README.md`, `PACK-*.md`, `BACKLOG.md`, root trinity. | `supporting-docs/SETUP-EXISTING.md` itself. `maintenance-docs/V10-PHASE-3B-*.md`. |
| S3B-3 | Informational only — expected matches in `BACKLOG.md` (BD-047 description, which is historically correct-as-written) and in `V10-PHASE-3B-DESIGN.md`. These are **not** edited by Phase 3-B — see Part 10 flag-back #1. | all matches on the two files named. |
| S3B-4 | Every match is either the kickoff variant itself, a SETUP-guide pointer, or a PM-CHAT.md pointer citing `docs/pack/prompts/pm-chat.md` Variant: kickoff (verbatim form). | none — spec is positive. |

### 6.4 Step-number preservation rationale (why we do NOT renumber)

Design Part 10.1 gives the planner a choice between (a) collapse 5–8
into a new Step 5 and keep later step numbers (Step 9 is still Step 9,
Step 10 is still Step 10), vs (b) collapse and shift downstream steps
up.

**Plan chooses (a): collapse 5–8 into a single Step 5, keep Steps 9
onward at current numbers.** Cross-references that currently cite
`SETUP-NEW.md Step 10` remain valid — these live in:

- `project-template/docs/pack/PM-CHAT.md` (kickoff + PM chat sections)
- `supporting-docs/METHODOLOGY.md` lines 54, 328
- `supporting-docs/DEPENDENCIES.md` line 135
- `supporting-docs/SETUP_TEMPLATE.md` line 210
- `supporting-docs/SETUP-EXISTING.md` line 195

Renumbering would force touching all five files. The collapse-only
approach affects only the SETUP-NEW.md Step 5 target and one cross-ref
in `SETUP-EXISTING.md:149` ("See `SETUP-NEW.md` Step 5 for detailed
values") that must be updated to point at the new Manual-fallback
sub-section heading.

Downstream step numbering invariant (post-Commit 2):

- Step 1 — Create the GitHub repo (unchanged)
- Step 2 — Create the Xcode project (unchanged)
- Step 3 — Run init-project.sh (unchanged)
- Step 4 — Fill context file placeholders (unchanged)
- **Step 5 — PM chat completes setup** (new collapsed form; old Steps 6/7/8 become sub-sections 5.A/5.B/5.C/5.D of the Manual-fallback section)
- (Steps 6, 7, 8 — gone; numbering resumes at 9 — the gap is intentional and documented in the Step 5 intro)
- Step 9 — Initial commit (unchanged)
- Step 10 — Set up the PM chat (unchanged)
- Step 11 — Generate SETUP.md and AGENT_KICKOFF.md (unchanged)
- Step 12 — Run the architecture kickoff (unchanged)

(SETUP-EXISTING.md: Steps 5 and 6 collapse to a new Step 5 by the same
rule; Steps 7 onward unchanged.)

---

## Part 7 — Commit-by-commit plan

### Commit 1 — kickoff variant

**Message.** `feat: v10 — BD-047 PM chat kickoff auto-discovery + install-check`

**Files touched.**
- `project-template/docs/pack/prompts/pm-chat.md` — single file; insertions only inside `## Variant: kickoff` (no changes to the three other variants or to the YAML front matter).

**Content scope — seven insertion points inside Variant: kickoff
(order matches Q13 decision to keep as one commit).**

1. **Pre-declaration preamble** — a 3-line block inserted immediately
   after the `## Variant: kickoff` H2 paste instructions (after the
   current "Fill in all [PLACEHOLDERS] before pasting" line). Contains:
   - Gemini plan-mode line (Q14-7 text).
   - A one-line pointer to "run manual mode if you are pasting this
     into Claude Web or ChatGPT Web without shell."
2. **Surface declaration block** — design Part 4.2 text. Inserted
   after the existing `**Key architectural decisions already made:**`
   list and before the existing project-documents pointer block. The
   developer replies `shell` or `manual`.
3. **Read-only discovery batch (Form R)** — design Part 8 §8.2 Form
   R text. Single batch per Q14-1.
4. **Apple sub-flow** — conditional-on-PLATFORM_TARGETS (design Part
   7 §7.4). Contains:
   - Scheme selection (Part 6 #2, #3 — single / multi).
   - Destination selection (Part 6 #4 — no-simulator fallback).
   - Form E for `validate-swift.sh`, `test-swift.sh`, `.claude/settings.json`, `format-swift.sh` anchors (Part 2 of this plan).
   - Form I for `swift-format` (version range from Part 4).
   - Form M for Xcode companion files (Q14-8 — `ls` of
     `$PACK/xcode-companion-templates/` at run time).
5. **gRPC sub-flow** — conditional-on-TRANSPORT-or-proto/-dir. Contains:
   - Form I for each of `buf`, `swift-protobuf`, `grpc-swift` (with
     Part 4 ranges).
   - On Python + gRPC branch: `uv add grpcio-tools ...` prompt using
     the same Form I grammar.
   - Print the example `./scripts/proto-gen.sh` invocation
     (verbatim from current SETUP-NEW Step 7).
6. **Manual-mode branch** — for `manual` declaration (Category C).
   Contains the verbatim SETUP-NEW Manual fallback block (same text
   as Commit 2 adds to SETUP-NEW). Cross-reference: "see
   `supporting-docs/SETUP-NEW.md` § Manual fallback for the complete
   list."
7. **Error-branch behavioral rules** — design Part 6 Table, rendered
   as a short "Behavior on failure / ambiguity" section at the end
   of Variant: kickoff. Nine numbered rules corresponding to design
   conditions #1..#9.

**Dependencies.** None — the edits are self-contained.

**Verification (run before committing).**

- `python3 scripts/validate-pack.py` → pass. (Front matter untouched;
  no new files.)
- `grep -n '^## Variant: ' project-template/docs/pack/prompts/pm-chat.md`
  → returns 4 matches (kickoff, backlog-status-update, generate-setup,
  generate-agent-kickoff). No new variants added.
- `grep -n '^---$' project-template/docs/pack/prompts/pm-chat.md`
  → exactly two `---` lines (YAML front-matter delimiters only).
- Visual: diff is additive-only inside the Variant: kickoff block.
- `git diff --stat project-template/docs/pack/prompts/pm-chat.md` →
  single file changed.

**Gate membership.** Gate E3.

**Revert safety.** `git revert <hash>` restores the pre-commit
kickoff variant. Commit 2 does not depend on Commit 1 being present —
the SETUP-guide collapse is self-contained (it points at the kickoff
variant, which exists before and after). If the implementer must
revert Commit 1 after landing Commit 2, the SETUP guides' Manual-
fallback sub-section remains correct (it is the content the kickoff
variant would have emitted) — projects simply perform Step 5 manually.
Log a flag-back in that case so the pack chat knows.

---

### Commit 2 — SETUP guides

**Message.** `docs: v10 — BD-047 SETUP-NEW + SETUP-EXISTING fold Steps 5–8 into PM chat`

**Files touched.**
- `supporting-docs/SETUP-NEW.md` — replace Steps 5, 6, 7, 8 with one collapsed Step 5 (intro + Manual-fallback sub-sections 5.A–5.D). Steps 1–4 and Steps 9–12 unchanged.
- `supporting-docs/SETUP-EXISTING.md` — replace Steps 5, 6 with one collapsed Step 5 that cross-references SETUP-NEW.md Manual fallback. Update the line-149 cross-reference ("See `SETUP-NEW.md` Step 5 for detailed values and how to find them") to point at "§ Manual fallback of SETUP-NEW.md Step 5." Steps 7–12 unchanged.

**Content scope.**

- **SETUP-NEW.md new Step 5.**

  The collapsed Step 5 contains:

  1. An intro paragraph explaining that the PM chat's kickoff variant
     completes the work on Bash-capable surfaces and the manual
     fallback is for non-Bash surfaces (per design Part 10.1).
  2. A short "Skip to Step 9 if your PM chat surface has shell
     access" note.
  3. A `### Manual fallback` subsection with four numbered
     sub-sections (5.A Apple Xcode scheme variables — current Step 5
     text verbatim; 5.B Apple swift-format install — current Step 6;
     5.C gRPC tooling install — current Step 7; 5.D Xcode companion
     files — current Step 8).
  4. A closing note: "A numbering gap 6–8 is intentional — those
     steps were merged into Step 5 in pack v10.1." (If v10 is the
     first version to carry this, substitute `v10.0`.)
- **SETUP-EXISTING.md new Step 5.**

  The collapsed Step 5 contains:

  1. Intro paragraph identical in purpose to SETUP-NEW's Step 5 but
     tuned to existing-project context (mentions that discovery runs
     **after** the existing-docs pointer step — Q14-9).
  2. A cross-reference: "See `SETUP-NEW.md` § Manual fallback for
     the complete list."
  3. **Removal of the old "See SETUP-NEW.md Step 5 for detailed
     values" line on the current line 149** (that line is absorbed
     into the cross-reference above).
- **Line-149 update.** Current line (SETUP-EXISTING.md:149):
  `See SETUP-NEW.md Step 5 for detailed values and how to find them.`
  New form (in the Manual fallback sub-section of new Step 5):
  `Detailed commands and example values are in SETUP-NEW.md § Manual fallback (sub-sections 5.A and 5.B).`

**Dependencies.** None on Commit 1 (see revert-safety note above).

**Verification.**

- `python3 scripts/validate-pack.py` → pass.
- Sweep S3B-1 (Part 6 §6.2) → zero matches outside the sanctioned
  residual set.
- Sweep S3B-2 (Part 6 §6.2) → zero matches outside the sanctioned
  residual set.
- `grep -n '^## Step' supporting-docs/SETUP-NEW.md` → Steps 1, 2, 3,
  4, 5, 9, 10, 11, 12 (no 6, 7, 8 — the gap is intentional).
- `grep -n '^## Step' supporting-docs/SETUP-EXISTING.md` → Steps 1,
  2, 3, 4, 5, 7, 8, 9, 10, 11, 12 (no 6).
- Read the SETUP-NEW Step 5 Manual-fallback subsections and confirm
  the commands match the current Steps 5–8 byte-for-byte
  (design Part 10.3 parity requirement).
- Read the kickoff variant's Manual-mode branch (from Commit 1) and
  confirm it contains the same commands as SETUP-NEW Manual fallback
  (design Part 11 §11.4 diff-vs-manual parity check).

**Gate membership.** Gate E3.

**Revert safety.** `git revert <hash>` restores the pre-commit SETUP
guides. If Commit 1 is still present after revert, the kickoff variant
continues to work — it emits the Manual-mode content inline, so
pointing to SETUP-NEW's old Steps 5–8 is still accurate.

---

### Commit 3 — PM-CHAT.md Behavioral rule (**DROPPED**)

**Decision: drop.**

Rationale. The architect flagged Commit 3 as conditional on whether
the planner concluded a new Behavioral rule was needed in
`project-template/docs/pack/PM-CHAT.md`. The planner concludes **no**:

1. The kickoff capability declaration (shell-vs-manual) is self-
   contained inside the kickoff variant text (Commit 1 insertion #2)
   and does not require a cross-session behavioral rule.
2. The machine-level `~/Library/...` write path introduced by Form M
   is adequately bounded by Form M's approval gate (design Part 8
   §8.2) and does not require a new row in PM-CHAT.md's existing
   `## File access strategy` table. Kickoff machine-level writes are
   one-time-per-machine under explicit approval, not a routine access
   pattern worth tabulating alongside project-internal paths.
3. PM-CHAT.md's existing rules ("Plan before executing", "Never run
   two PM chats simultaneously") already carry the weight Commit 3
   would have added.

If the implementer, while writing Commit 1, finds a rule belongs in
PM-CHAT.md after all, **flag it back** — do not add it silently.

**Files touched.** None.
**Gate membership.** n/a.

---

### Commit 4 — fixture cleanup (**DROPPED**)

**Decision: drop.**

Rationale. Per Part 5 of this plan, fixtures live outside the pack
repo (`/tmp/phase-3b-fixtures/<name>/`). Nothing is committed,
nothing needs cleaning.

**Files touched.** None.
**Gate membership.** n/a.

---

### Commit sequence summary

| # | Message | Files | Gate |
|---|---|---|---|
| 1 | `feat: v10 — BD-047 PM chat kickoff auto-discovery + install-check` | `project-template/docs/pack/prompts/pm-chat.md` | E3 |
| 2 | `docs: v10 — BD-047 SETUP-NEW + SETUP-EXISTING fold Steps 5–8 into PM chat` | `supporting-docs/SETUP-NEW.md`, `supporting-docs/SETUP-EXISTING.md` | E3 |

Total: **2 commits**, zero trinity files touched, zero scripts
touched, zero `METHODOLOGY.md` edits, zero `validate-pack.py` changes.

---

## Part 8 — Gate E3 entry criteria

Mirrors Gate E (V10-IMPLEMENTATION-PLAN §6.5 Gate E block) and Gate
E2 (V10-IMPLEMENTATION-PLAN §6.5 Gate E2 block) structure.

Gate E3 opens when **all** of the following hold:

1. **`validate-pack.py` passes on every commit.** Run after Commit 1
   and again after Commit 2. Both runs must exit 0.
2. **Cross-reference sweeps clean.**
   - S3B-1 (Part 6 §6.2) → matches only within the sanctioned
     residual set.
   - S3B-2 (Part 6 §6.2) → matches only within the sanctioned
     residual set.
   - S3B-3 (Part 6 §6.2) → only BD-047 description and the Phase 3-B
     design doc match (these are not edited by Phase 3-B — flag-back
     #1 addresses any future edit).
   - S3B-4 (Part 6 §6.2) → every match is a recognized pointer to
     `Variant: kickoff`.
3. **Kickoff variant parses cleanly.**
   - `grep -n '^## Variant: ' project-template/docs/pack/prompts/pm-chat.md`
     → exactly 4 lines (kickoff, backlog-status-update, generate-setup,
     generate-agent-kickoff).
   - YAML front matter preserved (no new keys, no removed keys).
4. **SETUP-guide numbering invariant holds.**
   - `grep -n '^## Step' supporting-docs/SETUP-NEW.md` →
     1, 2, 3, 4, 5, 9, 10, 11, 12 (gap is expected and documented in
     the new Step 5 intro).
   - `grep -n '^## Step' supporting-docs/SETUP-EXISTING.md` →
     1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12.
5. **Manual-vs-variant parity spot-check.** Reviewer reads the
   kickoff variant's Manual-mode branch and SETUP-NEW.md Step 5
   Manual fallback side-by-side; the commands are byte-identical. If
   they diverge, one is wrong — resolve before Gate E3 signs off.
6. **Fixture evidence.** Each of the six fixtures from Part 5
   exercised with the kickoff variant on at least one Bash-capable
   surface (Claude Code CLI is the cheapest; see Part 11 §11.2 of
   design). For each fixture, the reviewer records:
   - Form R commands actually run matched the variant's prose.
   - Form E anchors correctly detected and the proposed diff matched
     the discovered values.
   - `abort` at any gate leaves the project in the pre-gate state.
   Fixture evidence may be a short markdown note in the Gate E3
   approval message; no committed artifact is required (Part 5 §5.4).
7. **Cross-surface checks (deferable to Phase 4).** Codex CLI and
   Gemini CLI one-shot `apple-spm-single-scheme` runs. If either
   surface is not available to the implementer, defer to Phase 4 and
   log the deferral in Part 9 of this plan.
8. **Category-C (Manual mode) check.** Paste the kickoff into
   Claude Web (no Desktop Commander) or ChatGPT Web, reply `manual`,
   verify no tool call fires and the Manual-mode branch's text
   matches SETUP-NEW Manual fallback.
9. **BD-047 coverage verified.** Part 11 of this plan closes out
   every BD-047 description clause; reviewer confirms each row.
10. **No unintended touches.** `git log --stat` for Phase 3-B shows
    exactly the files enumerated in Part 7. No trinity files, no
    scripts, no `METHODOLOGY.md`, no `validate-pack.py`, no
    `README.md`, no `BACKLOG.md`.

Any failed criterion opens a `fix:` commit and re-runs the gate. The
pack chat owns the Gate E3 approval decision.

---

## Part 9 — Deferred-to-Phase-4 items

| # | Item | Reason | Phase 4 owner |
|---|---|---|---|
| D1 | Codex CLI fixture run (apple-spm-single-scheme) | May require a Mac with Codex CLI configured and the brew-install escalation path (design Part 3 §3.2). If unavailable at Phase 3-B time, defer. | Phase 4 Gate F reviewer |
| D2 | Gemini CLI fixture run (apple-spm-single-scheme) | May require Gemini CLI installed locally. If the implementer's Mac does not have Gemini, defer the smoke. | Phase 4 Gate F reviewer |
| D3 | Desktop Commander (Category B) fixture run | Requires Claude Desktop + Desktop Commander MCP installed. If not present, defer. | Phase 4 Gate F reviewer |
| D4 | Empirical refinement of Part 4 brew version ranges | No data at Phase 3-B time. First real project audit provides the feedback. | Pack Chat (via PACK-FEEDBACK.md loop) |
| D5 | Second-real-project audit of idempotency no-op paths | Part 3 defines the rules; confirming they hold across project types needs real projects. | Pack Chat |
| D6 | Stale Xcode companion detection tuning | Byte-identity check is deterministic but the "recommendation" language may need softening or hardening based on developer feedback. | Pack Chat |
| D7 | Capability-addition kickoff symmetry (architect's Q14-5) | Out of v10.0 scope; planner deferred to candidate BD entry (Part 10). | Pack Chat — file after v10.0 ships |

---

## Part 10 — Implementer flag-back list

Every item below is a decision the planner made that might look
different once the implementer is in the text. If any of these turn
out wrong on contact with reality, **flag back to the pack chat**
before deviating.

1. **BD-047 names the wrong scripts.** BD-047 description cites
   `scripts/validate.sh`, `scripts/test.sh`, `scripts/format.sh`.
   Post-BD-026 the Xcode-variable anchors live in the language-
   specific variants (`validate-swift.sh`, `test-swift.sh`,
   `format-swift.sh`). This plan targets the correct files (Part 2);
   the implementer should not "fix" BD-047 in-flight. Pack Chat
   decides whether to clarify BD-047's description wording.
2. **`.claude/settings.json` JSON edit.** Part 2 §2.4 forbids
   regex-rewriting JSON. If the implementer finds the v10 pack's
   settings.json has reproducibly-formatted structure that a
   carefully-crafted regex could safely rewrite, the implementer
   should still not take that path — JSON round-trip through a
   parser is the rule. Flag back if the parser path is harder than
   expected.
3. **Form M `ls` read of `xcode-companion-templates/`.** Q14-8
   specifies reading at run time. If the implementer finds that the
   kickoff variant's prose cannot reliably express "list these files"
   to the PM chat (e.g., the variant's prose was about to rely on a
   shell-tool-only construct), fall back to hardcoding the current
   four paths with a comment pointing at `xcode-companion-templates/`
   as the source of truth, and flag back.
4. **Manual-mode verbatim parity.** Commit 1 insertion #6 (Manual-mode
   branch) and Commit 2 SETUP-NEW.md Step 5 Manual fallback must be
   byte-identical on command lines. If the implementer finds a
   phrasing that reads better in one location but not the other,
   pick one and make the other match — do not introduce divergent
   phrasings silently.
5. **Step-number gap (5..9) readability.** Part 6 §6.4 chooses to
   keep the gap rather than renumber. If the implementer finds that
   the gap confuses the SETUP-guide narrative, flag back — do not
   renumber unilaterally. (Renumbering triggers edits in five files
   outside Phase 3-B scope; the flag-back gives pack chat the chance
   to decide whether to expand scope.)
6. **Brew version ranges look wrong.** Part 4 is a starting baseline.
   If the implementer's local `brew info <tool>` returns a notably
   different current stable than Part 4 cites, flag back; do not
   silently edit the range.
7. **Gemini plan-mode line location.** Commit 1 insertion #1 places
   the plan-mode line at the very top. If the implementer finds the
   kickoff variant's top already has a similar structural note and
   this would read poorly, relocate to directly above the surface
   declaration block — and flag the relocation.
8. **Draft BD entry for Q14-5 (capability-addition kickoff
   symmetry).** Included below as reference; not filed.

> **Draft BD entry (NOT filed — pack chat decides):**
>
> `BD-048 — Capability-addition discovery + install-check symmetry with kickoff`
>
> Type: TODO(version)
> Status: Open
> Blockers: BD-047 resolution (kickoff flow lands first)
> Unblocks: none
> File/Symbol: `scripts/add-capability.sh`, `supporting-docs/METHODOLOGY.md` Procedure 6
> Description: `add-capability.sh` today only does trinity-placeholder file plumbing; it does not propose `brew install grpcio-tools` (etc.) when the developer adds a new dimension. Mirror the BD-047 kickoff auto-discovery + install-check pattern at capability-addition time. Implementation either extends Procedure 6 with a kickoff-style variant or adds a new `Variant: capability-added-kickoff` to `docs/pack/prompts/pm-chat.md`.
> Context: Identified during BD-047 Phase 3-B planning (2026-04). Deferred out of v10.0 scope per V10-PHASE-3B-DESIGN.md Part 14 Open Question 5.

---

## Part 11 — BD-047 field-by-field closure mapping

BD-047's description decomposes into the following clauses. For each
clause, the table below cites the commit(s) and the part of this plan
that covers it.

| # | BD-047 clause | Closure |
|---|---|---|
| 1 | "auto-discovers Xcode scheme / simulator values (via `xcodebuild -list` and `xcrun simctl list devices available`)" | Commit 1 insertion #3 (Form R discovery) + #4 (Apple sub-flow). Design Part 6 #2/#3/#4. |
| 2 | "detects missing brew tools (swift-format, buf, swift-protobuf, grpc-swift)" | Commit 1 insertion #3 (Form R `command -v`) + insertion #4 (Form I per tool). Ranges in Part 4 of this plan. |
| 3 | "prompts for `brew install` with developer approval" | Commit 1 insertion #4 + #5 (Form I, design Part 8 §8.2). |
| 4 | "edits `scripts/validate.sh`, `scripts/test.sh`, `.claude/settings.json`, and `scripts/format.sh`" | Commit 1 insertion #4 (Form E). **Correction:** targets are the language-specific variants `validate-swift.sh`, `test-swift.sh`, `format-swift.sh` per Part 2 §0/§2.1. Flag-back #1 names the discrepancy to pack chat. |
| 5 | "handles Xcode companion files (machine-level `cp` with confirmation)" | Commit 1 insertion #4 Form M. Sourcing rule Q14-8. Idempotency rule Part 3 §3.4. |
| 6 | "Shell-out-capability detection: Adapt behavior to Bash-capable CLI surfaces vs. Claude Web without Desktop Commander" | Commit 1 insertion #2 (surface declaration block) + #6 (Manual-mode branch). Design Part 3 categories A/B/C + Part 4 declarative-via-question. |
| 7 | "Documentation updates: SETUP-NEW.md and SETUP-EXISTING.md Steps 5–6 change to 'PM chat handles this during kickoff' with a manual-alternative fallback section for non-Bash surfaces" | Commit 2 both files. Part 6 §6.4 numbering. |
| 8 | "Principle: Developer is the decision-maker, not a copy/paste executor. Every auto-discovered value and every install/edit action is confirmed before the PM chat writes or runs anything." | Commit 1 insertion #3/#4/#5/#6 — every write is behind Form I / Form E / Form M (design Part 8). Error-branch rules (Commit 1 insertion #7) preserve this on failure paths. |
| 9 | "Phase 3-B scope outline step 1 — planner/architect pass designing auto-discovery flow, confirmation gates, and error handling for each branch" | **This plan** — closes design Open Questions and pack-chat gaps (Part 1); confirmation gates in design Part 8; error branches in design Part 6. |
| 10 | "Phase 3-B scope outline step 2 — enhance `docs/pack/prompts/pm-chat.md` Variant: kickoff with the auto-discovery + install-check segment" | Commit 1. |
| 11 | "Phase 3-B scope outline step 3 — update `SETUP-NEW.md` and `SETUP-EXISTING.md` Steps 5–6" | Commit 2. Scope expanded to Steps 5–8 in SETUP-NEW per design Part 10.1 (implicit in BD-047 — "Step 5–6" read as the SETUP-EXISTING form; SETUP-NEW's equivalent is Steps 5–8). |
| 12 | "Phase 3-B scope outline step 4 — shell-out-capability detection logic with documented fallback path" | Commit 1 insertion #2 (declarative-via-question) + Commit 2 (SETUP-NEW.md Manual fallback is the fallback-path documentation). |

Every BD-047 description clause is closed by Commits 1–2 plus the
planner-pass artifact (this document). No clauses remain open.

