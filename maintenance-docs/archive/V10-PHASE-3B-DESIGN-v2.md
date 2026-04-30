# V10-PHASE-3B-DESIGN-v2 — pm-chat.md kickoff bloat fix

Revisit of `V10-PHASE-3B-DESIGN.md` Part 7 §7.2 ("single variant with
inline conditionals") in light of concrete token-weight evidence from
the Phase 3-B implementation pass. This document replaces only the
Part 7 §7.2 structural decision and the Part 10 relocation strategy;
all other Phase 3-B design decisions (capability detection Part 4,
interaction model Part 5, error branches Part 6, confirmation-gate
pattern Part 8, scope boundary Part 9) carry forward unchanged.

STATUS: DRAFT — architecture-review output, awaiting pack-chat
direction. No file edits.

BD-047, v10.0 ship-blocker.

---

## Part 1 — Problem restatement

The Phase 3-B implementation pass grew `Variant: kickoff` in
`project-template/docs/pack/prompts/pm-chat.md` from 44 lines to 438
lines (+327 lines, currently unstaged on `v10-dev`). `pm-chat.md` is
loaded into the PM chat's context window for the whole session of
every project using the pack, so each of those 327 lines is paid on
every turn, for every user, for the lifetime of v10.x. Roughly 295 of
the added lines describe actions that fire exactly **once per project
lifetime** (shell-mode auto-discovery K1/K2/K3) or **zero times for
most sessions** (manual-mode branch; behavior-on-failure reply grammar
invoked only when a failure fires). The remaining ~30 lines (surface
declaration, sub-flow pointers) are genuinely session-relevant. The
current shape pays perpetual token cost for one-shot procedural
content.

---

## Part 2 — Proposed architecture

The kickoff variant is split along its actual cost axis. Content paid
every turn stays in `pm-chat.md`. Content paid once per project moves
to an on-demand procedure inside `METHODOLOGY.md`. Content paid zero
times on shell-capable surfaces moves into `SETUP-NEW.md` (where it
was already planned to land in Phase 3-B Commit 2).

**Three-home layout:**

1. **`project-template/docs/pack/prompts/pm-chat.md` Variant: kickoff
   — session-resident content only.** Project context placeholders,
   PM-chat-role preamble, the surface-declaration question, and a
   short pointer to the on-demand procedure. Target line count for
   the full variant: **~55 lines** (44-line pre-Phase-3B baseline +
   ~11 lines for the surface-declaration Q/A block and the procedure
   pointer). This is the 20-%-of-original success-criterion target.

2. **`supporting-docs/METHODOLOGY.md` gains Procedure 7 — "Kickoff
   auto-discovery and install-check."** Contains the full K1/K2/K3
   flow, the four confirmation-gate Forms (R / I / E / M), the
   nine-row behavior-on-failure table, the reply grammar, and
   idempotency rules. Target size: **~220 lines** inside METHODOLOGY.md
   (material is lifted substantially verbatim from the current
   kickoff variant and reformatted with the Gn gate-label convention
   Procedure 6 established). Paid on-demand when the PM chat reads
   Procedure 7 during a kickoff turn — zero-cost in every subsequent
   turn of the session (METHODOLOGY.md is consumed on-demand per
   V10-DESIGN §5.14.6 zero-token dormancy argument; the same argument
   applies here).

3. **`supporting-docs/SETUP-NEW.md` § Manual fallback (sub-sections
   5.A–5.D)** is the authoritative home for the manual-mode commands
   and already shipped in Phase 3-B Commit 2 per
   `V10-PHASE-3B-PLAN.md` Part 7. Under the v2 design the kickoff
   variant no longer duplicates those commands inline; it emits a
   one-line pointer ("see `supporting-docs/SETUP-NEW.md § Manual
   fallback`") when the developer declares `manual`. Procedure 7 also
   references the Manual-fallback section as the authoritative source
   that its Forms R/I/E/M implement — they are two views of the same
   spec, and the parity check in `V10-PHASE-3B-PLAN.md` Part 11 §11.4
   continues to apply between the two (no change to the parity check;
   only the location of one side moves from the kickoff variant body
   to Procedure 7 body).

**Structural properties preserved vs. the original design:**

- **Variant format (V10-DESIGN §4.5).** One file per agent, one
  `## Variant: <slug>` per template. Kickoff variant stays single,
  consistent with Part 7 §7.2 decision — we are NOT splitting per
  surface or per project type.
- **Confirmation-gate pattern (Phase 3-B Design Part 8).** Forms R,
  I, E, M unchanged. They live in Procedure 7 instead of in the
  kickoff variant body; the text of each Form is identical.
- **Script/procedure split pattern (V10-DESIGN §5.14).** Procedure 7
  is to Phase 3-B what Procedure 6 is to Phase 3-AC: a PM-chat-side
  procedure paired with an operational trigger (the kickoff variant,
  which plays the role `add-capability.sh` plays for Procedure 6).

**What ships to projects vs. what does not.** `pm-chat.md`,
`METHODOLOGY.md`, and `SETUP-NEW.md` all ship in
`project-template/docs/pack/` or as root-level copies via
`init-project.sh` (§7.6 stage S3). Every file involved is already part
of the pack product. No new ship surface.

---

## Part 3 — Per-section relocation table

Source references are line spans in the current unstaged 438-line
`Variant: kickoff` body. Headers name the current kickoff sub-section.

| # | Current block | Lines | Destination | Rationale |
|---|---|---:|---|---|
| 1 | Variant preamble ("Paste this at…", "Fill in placeholders") | 20-22 | **Stay** in pm-chat.md | Entry-point guidance for every paste |
| 2 | "Before pasting" list (Gemini plan-mode line; manual-mode pointer; one-line description of shell vs. non-shell) | 23-26 | **Stay** — condense to 3 lines | Pre-paste surface awareness; ~15 tokens is cheap and prevents a common failure mode |
| 3 | Project-context placeholders (PROJECT / PLATFORM / Phase / Pack version / Architectural decisions) | 28-38 | **Stay** | Original 44-line kickoff; needed every session |
| 4 | Surface-declaration Q/A block (Confirm `shell` or `manual`; override rules) | 40-56 | **Stay** — condense to ~10 lines | Every kickoff must pick a mode; cannot externalize. Override-rule prose trims well (override-and-mid-kickoff re-declaration moves to Procedure 7) |
| 5 | Project-documents pointer + "Your role as PM chat" + placeholder-fill instructions | 58-84 | **Stay** | Original 44-line kickoff content; session-relevant |
| 6 | Shell-mode intro paragraph ("With the initial context established…") | 88-94 | **Procedure 7 §7.0 Trigger** | Once-per-project framing |
| 7 | Step K1 — Read-only discovery (Form R, command enumeration) | 96-127 | **Procedure 7 §7.1** | Fires once per project (re-invocation is idempotent but rare) |
| 8 | Step K2 Apple sub-flow — K2.1 scheme/destination | 130-147 | **Procedure 7 §7.2.1** | Once per project |
| 9 | Step K2.2 Form E anchor rules + `.claude/settings.json` JSON safety | 148-183 | **Procedure 7 §7.2.2** | Once per project |
| 10 | Step K2.3 swift-format Form I + idempotency | 185-204 | **Procedure 7 §7.2.3** | Once per project |
| 11 | Step K2.4 Xcode companion files Form M + stale-detection | 206-230 | **Procedure 7 §7.2.4** | Once per project (once per Mac across projects) |
| 12 | Step K3 gRPC sub-flow — K3.1 Apple-side Form I triplet | 232-243 | **Procedure 7 §7.3.1** | Once per project |
| 13 | Step K3.2 Python-side Form I quadruplet | 245-252 | **Procedure 7 §7.3.2** | Once per project |
| 14 | Step K3.3 proto-gen.sh invocation example | 254-264 | **Procedure 7 §7.3.3** | Once per project |
| 15 | Manual-mode branch M1–M5 (full verbatim SETUP commands) | 267-341 | **SETUP-NEW.md § Manual fallback** (already planned) + 4-line pointer in pm-chat.md | Already duplicated in SETUP-NEW.md after Commit 2; pm-chat.md emits a pointer, not a copy |
| 16 | Behavior on failure (9-row table prose) | 346-377 | **Procedure 7 §7.4** | Contract fires only on failure; not needed every turn |
| 17 | Reply grammar summary | 379-388 | **Procedure 7 §7.5** | Contract for Form replies; lives next to the Forms themselves |

**Resulting pm-chat.md Variant: kickoff outline (55-line target):**

- H2 heading (1 line)
- Preamble + paste instructions (4 lines — §3 rows 1,2 condensed)
- Project-context placeholders (12 lines — §3 row 3)
- "Before I do anything else" surface-declaration Q/A (11 lines — §3 row 4 condensed)
- Project-documents pointer + PM-chat-role + placeholder-fill block (22 lines — §3 row 5)
- **Kickoff continuation pointer** (5 lines new text):
  > "On `shell` declaration, read `supporting-docs/METHODOLOGY.md`
  > Procedure 7 and follow its gates (K1 / K2 / K3) before any write
  > or install. On `manual` declaration, emit `supporting-docs/
  > SETUP-NEW.md § Manual fallback` (sub-sections 5.A–5.D) and wait
  > for the developer to report values back."

Net for the whole `pm-chat.md` file (four variants + frontmatter):
**~200 lines** (down from 518 currently).

---

## Part 4 — End-to-end traces under the new design

### 4.1 Happy path — Apple SPM project, shell mode

1. Developer fills placeholders and pastes kickoff variant into a
   Claude Code CLI session. ~55 lines of text enter context.
2. PM chat reads the variant. It sees: project context; the question
   "reply `shell` or `manual`"; the continuation pointer "on `shell`,
   read METHODOLOGY.md Procedure 7."
3. Developer replies `shell`.
4. PM chat reads `METHODOLOGY.md` Procedure 7 (the file is already
   on-disk at the project root — `init-project.sh` §7.6 stage S3
   copies it). Procedure 7 loads into turn context for this turn
   only.
5. Procedure 7 §7.1 — PM chat renders Form R enumerating the
   read-only discovery commands. Developer replies `yes`. Commands
   run. Output is in the PM chat's observation stream.
6. Procedure 7 §7.2.1 — `xcodebuild -list` parsed; one scheme
   (matches design Part 6 #2); PM chat auto-fills the scheme value,
   surfaces it inline in the upcoming Form E.
7. Procedure 7 §7.2.2 — Form E renders with the scheme + destination
   diff against `scripts/validate-swift.sh`. Developer replies `yes`.
   Edit applied. Same for `scripts/test-swift.sh`,
   `.claude/settings.json` (JSON parse-mutate-serialize per
   V10-PHASE-3B-PLAN.md Part 2 §2.4), and `scripts/format-swift.sh`
   (if non-SPM layout indicated).
8. Procedure 7 §7.2.3 — Form I for swift-format. Idempotent skip if
   already installed in the known-good range.
9. Procedure 7 §7.2.4 — Form M for Xcode companion files.
   Byte-identity check; skip with note if already installed.
10. Procedure 7 §7.3 — gRPC sub-flow skipped (not in trinity
    TRANSPORT line, no `proto/` directory).
11. Procedure 7 terminal state printed ("Kickoff complete — all
    gates passed").
12. PM chat emits its normal kickoff output ("current state; what we
    should do next") — this is the content the original 44-line
    kickoff produced. Session continues.

Every turn after turn 12, Procedure 7 is no longer referenced — its
content is not re-loaded on subsequent turns. pm-chat.md's remaining
content (backlog-status-update, generate-setup, generate-agent-kickoff
variants) is what sits in context for the rest of the session.

### 4.2 Failure path — brew not installed

1. Steps 1-5 as above.
2. Form R runs; `command -v brew` returns empty.
3. Procedure 7 §7.4 row 5 fires: PM chat does not attempt any
   install; prints the install URL + the exact `brew install` lines
   the developer must run; records the skips.
4. Procedure 7 §7.2.4 — Xcode companion files do not require brew;
   that sub-flow still runs normally.
5. Procedure 7 §7.3 — gRPC sub-flow cannot install buf / swift-protobuf
   / grpc-swift; §7.4 row 5 applies again; each tool recorded as
   skipped-by-no-brew.
6. Terminal state: "Kickoff complete with skips — 4 installs deferred
   (see above); re-run kickoff after installing Homebrew to pick them
   up idempotently."

The failure contract is no different from the current Phase 3-B design
Part 6 — only its storage location changes.

---

## Part 5 — Trinity-rule and v10-principle analysis

**Trinity rule.** The only pack-product files involved are
`pm-chat.md`, `METHODOLOGY.md`, `SETUP-NEW.md` — none is part of the
`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` trinity. The trinity rule is
not engaged by the v2 design. This matches the original Phase 3-B
design's Part 3 §3.5 conclusion and carries forward.

**"Fewer files, fewer conventions" principle (v10 pillar).** The v2
design adds **one** new artifact: `METHODOLOGY.md` Procedure 7. No new
file, no new directory, no new front-matter key, no new naming
convention. Procedure 7 uses the same H3-anchored `### Procedure N —
<title>` heading shape that Procedures 1–6 already use. The Gn gate
label convention (G7-discovery, G7-install, G7-edit, G7-machine) is a
direct reuse of the G6-drafts / G6-commit pattern Procedure 6
established at §5.14.5.

Against this, the cost of *not* adding Procedure 7 is ~295 lines of
once-per-project content priced into every PM-chat turn indefinitely.
"Fewer files" is not "fewer lines everywhere irrespective of where
they live." Procedure 7 adds one procedure heading to a file that
already hosts six procedures; it removes ~295 lines from a file that
is paid per turn. The principle is better served by the v2 design
than by the status quo.

**Cross-tool parity.** `METHODOLOGY.md` is read the same way on every
surface: Claude Code CLI reads it via mcp-local-rag on demand; Claude
Desktop reads via GitHub connector or filesystem MCP; Codex CLI and
Gemini CLI read from disk on demand; Claude Web reads via the GitHub
connector (the developer has already synced it per SETUP-NEW.md Step
10 Option A). Every surface can reach Procedure 7. No per-surface
branching required.

**Separation of concerns (user memory item:
`feedback_ops_product_separation`).** All three destination files are
pack-product (`project-template/` or `supporting-docs/` shipped to
projects). No maintenance-docs involvement. No pack-repo operational
files touched.

---

## Part 6 — Part 9 scope-constraint question

**V10-PHASE-3B-PLAN.md Part 9 currently forbids Phase 3-B adding a new
METHODOLOGY.md Procedure.** The v2 design depends on relaxing that
constraint.

**Recommendation: relax it. Add Procedure 7.**

**Why the constraint existed.** The planner pass wanted to hold Phase
3-B to a two-commit, single-prompt-variant-edit shape and avoid
scope-creeping Phase 3-B into METHODOLOGY.md where reviewers would
have to vet a new procedure against the precedent Procedures 1–6
already set. That caution was reasonable when the kickoff variant was
expected to cost ~100-150 lines, which is within the tolerable range
for an always-loaded file.

**Why relaxing is principled, not scope creep.**

1. **The constraint's motivation was cost avoidance, not
   correctness.** No architecture invariant required that Phase 3-B
   avoid METHODOLOGY.md. The constraint was a budgeting judgment. The
   438-line concrete outcome invalidates that budget.
2. **The alternative shape (status quo) costs more than the
   relaxation.** Adding Procedure 7 is one heading in a file projects
   already carry; keeping the 438-line kickoff body pays ~295 lines
   per turn per session forever.
3. **Procedure 7 is symmetric with Procedure 6.** §5.14 established
   the shell-trigger-plus-PM-chat-procedure split as the pack pattern
   for stateful, multi-step, approval-gated flows. The kickoff flow
   is exactly that shape; not using the pattern makes Phase 3-B the
   outlier, not the norm.
4. **Procedure 7 addition is within Gate E3's existing review
   surface.** Reviewers already have to validate the kickoff
   variant's four-Form confirmation pattern. Moving that validation
   object from pm-chat.md lines to METHODOLOGY.md lines is not a
   review-load increase; it is a review-location change.

**What the relaxation commits to.** Phase 3-B commit count grows from
2 to 3. Commit 1 becomes "pm-chat.md kickoff variant (slim)." Commit
2 (SETUP guides) is unchanged. A new Commit 3 adds Procedure 7 to
METHODOLOGY.md. The planner pass re-estimates Gate E3 entry criteria
to add one METHODOLOGY.md grep-sweep item (Procedure 7 heading
present, G7 gate labels consistent with G6 precedent).

**What relaxation does NOT commit to.** No change to
`scripts/add-capability.sh`, no change to `init-project.sh`, no
change to `scripts/lib/detect.sh`, no change to `validate-pack.py`
(the Procedure 7 heading is a regular H3 under an existing Part 7
tier-equivalent location; no new schema rule). Phase 3-B scope
boundaries in V10-PHASE-3B-DESIGN.md Part 9 §9.1–§9.4 stay intact.

---

## Part 7 — Rejected alternatives

### 7.1 Keep everything inline in pm-chat.md (status quo)

**Rejected.** The evidence is the 438-line file itself — ~295 lines
of one-time content paid on every turn is the problem this design
pass exists to solve. Holding to V10-PHASE-3B-DESIGN.md Part 7 §7.2's
"single variant with inline conditionals" at the cost of the
token-weight argument is letting an earlier decision override later
evidence. The structural-choice framework in Part 7 §7.3 already
names when §7.2 should be revisited: "when the conditional segments
grow beyond ~40% of the file's total length (token-budget concern)."
At 438 lines for kickoff alone against 518 total, kickoff is ~85% of
pm-chat.md. That bar is well crossed.

### 7.2 Split kickoff into per-surface or per-project-type variants

**Rejected.** Identical to the V10-PHASE-3B-DESIGN.md Part 13 Q5
rejection. Proliferating variants is worse than adding one
METHODOLOGY.md procedure — it doubles maintenance surface,
forces the developer to pick a variant at paste time (a mechanical
decision BD-047's principle rejects), and gains nothing the on-demand
procedure does not already provide. The detection logic that decides
Apple vs. gRPC vs. Python was never per-variant; it was already
inside the kickoff variant, and moves with the content into Procedure 7.

### 7.3 New prompt file — `docs/pack/prompts/kickoff-discovery.md`

**Rejected.** Conflates the purpose of `docs/pack/prompts/`.
V10-DESIGN §4.5 invariants for that directory: one file per agent,
one `## Variant: <slug>` per template, YAML front matter with
`agent:` and `variants:` keys, and the `agent:` value must match the
pack agent roster (or an `x-` custom agent). A kickoff procedure file
would either claim `agent: pm-chat` (duplicating pm-chat.md) or
invent a new `agent:` value (breaking the AD-10 roster invariant).
Neither is acceptable. Prompts live in `prompts/`; procedures live in
`METHODOLOGY.md`. The v2 design respects that separation.

### 7.4 Move the content to `supporting-docs/SETUP-NEW.md` Step 5 body (fold it into the Manual fallback verbatim)

**Rejected.** SETUP-NEW.md is a developer-facing setup narrative, not
a PM-chat operating spec. Folding the four Forms and the nine-row
error table into Step 5 of SETUP-NEW.md would mean the developer
reads, every setup session, a block of content addressed to the PM
chat — confusing audience. The Manual-fallback sub-section's purpose
is to state the commands the developer runs when the PM chat cannot.
Procedure 7's purpose is to tell the PM chat how to run those same
commands. They are two different audiences for the same underlying
facts; V10-PHASE-3B-DESIGN.md Part 10 §10.3 argues that precisely.
Collapsing them loses the audience split.

### 7.5 Keep Procedure 7 in `pm-chat.md` as a fifth variant (`Variant: kickoff-auto-discovery`)

**Rejected.** A variant that is loaded by the PM chat "only during
kickoff" still lives in the always-loaded `pm-chat.md` file — the PM
chat reads the whole file at session start to know which variants
exist (for self-prompts like `backlog-status-update`). The five-th
variant's body pays the same per-turn cost the inlined content pays.
Procedure 7 in METHODOLOGY.md, by contrast, is not read until the PM
chat actively invokes it during a single turn, exactly like Procedure
6 (V10-DESIGN §5.14.6 zero-token dormancy).

---

## Part 8 — Open questions for the planner

Decisions the planner pass must make once direction is given to
accept the v2 architecture. None of these threaten the design; each
is a refinement.

1. **Gate label convention for Procedure 7.** Procedure 6 uses
   `G6-drafts` and `G6-commit`. Procedure 7 has four natural gate
   points (K1 read-only batch, K2/K3 installs, K2 edits, K2
   machine-level). Should the labels be `G7-discovery`, `G7-install`,
   `G7-edit`, `G7-machine` (one per Form) or a coarser
   `G7-preview`/`G7-apply` pair? The Forms-level labels trace
   directly to the confirmation-gate pattern; the coarser pair would
   match the Procedure-6 approach more literally.

2. **Manual-mode pointer shape inside pm-chat.md.** Should the
   kickoff variant's `manual`-declaration branch print a 1-line
   pointer ("see SETUP-NEW.md § Manual fallback sub-sections
   5.A–5.D") or a slightly longer inline summary ("run these:
   `xcodebuild -list`, `xcrun simctl list devices available`, …")
   with a pointer at the end? The 1-line pointer is tighter; the
   summary is faster for developers to act on without switching
   files.

3. **Does Procedure 7 own the Gemini plan-mode pre-declaration line
   or does pm-chat.md keep it?** The plan-mode line must fire before
   any shell call — i.e., before Procedure 7 is ever read. It
   therefore has to live in pm-chat.md. Confirm and set the line's
   final location explicitly in the planner pass.

4. **Inline Part 4 brew version ranges vs. Procedure 7 reference
   into DEPENDENCIES.md.** V10-PHASE-3B-PLAN.md Part 4 hardcodes
   ranges inline in the kickoff variant. Under the v2 design the
   ranges live in Procedure 7 Form I examples. Should the ranges be
   hardcoded in Procedure 7 (copy from the plan verbatim) or should
   Procedure 7 point at DEPENDENCIES.md? Q14-2 in the original plan
   leaned hardcode-for-simplicity; the v2 location change does not
   alter that reasoning, but worth confirming.

5. **SETUP-EXISTING.md pointer.** SETUP-EXISTING.md Step 5 cross-refs
   SETUP-NEW.md § Manual fallback per the current plan. Does it also
   need a pointer to Procedure 7, or is the kickoff variant's
   continuation pointer sufficient given that both SETUP guides
   route through the same kickoff?

6. **Procedure 7 numbering interaction with Procedure 5-R.**
   METHODOLOGY.md currently lists Procedure 1, 2, 3, 4, 5,
   Procedure 5 sub-procedures (5.1–5.6), Procedure 5-R, Procedure 6.
   Procedure 7 is the next whole number — confirm the name and
   anchor slug (`#procedure-7--kickoff-auto-discovery-and-install-check`).

7. **Commit 3 message shape.** Suggested: `docs: v10 — BD-047
   METHODOLOGY.md Procedure 7 for kickoff auto-discovery`. Mirrors
   commit `84cb4ef` (`feat: v10 — BD-046 METHODOLOGY.md Procedure 6
   for capability addition`) — but the Procedure-6 commit used
   `feat:` and Procedure 7 is a pure doc addition with no script
   counterpart shipping in the same commit. Is `docs:` the correct
   prefix, or `feat:` for parity?

8. **Cross-reference sweep additions.** V10-PHASE-3B-PLAN.md Part 6
   §6.2 defines four grep sweeps (S3B-1..S3B-4). Under the v2 design
   add:
   - S3B-5: `grep -n 'Procedure 7' project-template/` —
     should find the pointer inside the kickoff variant and nowhere
     else under `project-template/`.
   - S3B-6: `grep -n '^### Procedure ' supporting-docs/METHODOLOGY.md` —
     should return procedures 1, 2, 3, 4, 5, 5-R, 6, 7 (and their
     sub-procedure headers under 5).

9. **Information needed but not in required reading.** None
   identified. If implementation surfaces that Procedure 7 needs to
   reference an artifact not in the current METHODOLOGY.md
   (e.g., `xcode-companion-templates/` directory structure
   specification), flag back to the pack chat before inlining it —
   do not silently add the reference.

