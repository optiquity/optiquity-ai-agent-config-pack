# V10-PHASE-3B-PLAN-v2 — PM chat kickoff slim + METHODOLOGY.md Procedure 7

## Part 0 — Status + supersession

**STATUS: DRAFT.** Planner-pass output under the v2 architecture.
Consumes:

- `maintenance-docs/V10-PHASE-3B-DESIGN-v2.md` (architecture; Part 3
  relocation table is authoritative for what moves where).
- `maintenance-docs/V10-PHASE-3B-DESIGN.md` (Parts 4, 5, 6, 8, 9 carry
  forward unchanged).
- `maintenance-docs/V10-PHASE-3B-PLAN.md` (the "v1 plan"; 14 resolved
  decisions, Form E anchor-match rules, idempotency rules, brew
  version ranges, fixture strategy, Gate E3 criteria — reused
  wherever v2 architecture does not disturb them).

**Supersedes.** This plan replaces V10-PHASE-3B-PLAN.md **for Phase
3-B execution only**. The v1 plan is retained for historical
reference and as the definitive spec for every decision the v2
architecture does not disturb — especially Part 2 (Form E anchor-
matching spec), Part 3 (idempotency rules), Part 4 (brew version
ranges), Part 5 (fixture sourcing strategy). When this document
points at "v1 plan Part N," the referenced content ships verbatim
into Procedure 7 (Commit 3 below).

**Backlog item:** BD-047 — v10.0 ship-blocker.

**Gate membership:** Gate E3 (unchanged from v1).

**Predecessor:** Phase 3-AC Gate E2 (closed at commit `84cb4ef`).
**Successor:** Phase 4 Gate F (final v10.0 release pass).

**Current working-tree state (2026-04-24, branch `v10-dev`).**
`project-template/docs/pack/prompts/pm-chat.md` carries 518 total
lines; the `## Variant: kickoff` block spans lines 18–388 (~371
lines in-variant, plus the ~44 lines of pre-Phase-3B baseline
content inside that block — see Part 3 below for the authoritative
line-range breakdown). The v2 plan transforms this unstaged state
rather than appending to it.

**Scope principle (restated, updated from v1 Part 0 for v2).** This
phase ships:

1. `pm-chat.md Variant: kickoff` **slim** to ~55 lines (Commit 1 —
   removes content now hosted by Procedure 7 and by SETUP-NEW.md
   Manual fallback).
2. SETUP-guide collapse for non-shell surfaces (Commit 2 — unchanged
   from v1 Part 7 Commit 2).
3. New `METHODOLOGY.md` Procedure 7 (Commit 3 — hosts the K1/K2/K3
   flow, Forms R/I/E/M, nine-row behavior-on-failure table, reply
   grammar, idempotency rules, G7 gate labels).

It does **not** touch the trinity files (`CLAUDE.md`, `AGENTS.md`,
`GEMINI.md`), does **not** touch `init-project.sh`,
`add-capability.sh`, `scripts/lib/detect.sh`, or any other script,
does **not** alter `validate-pack.py`, does **not** touch `README.md`
layout sections, does **not** alter `PACK-CHAT.md`, `PACK-AGENTS.md`,
`QUICKSTART.md`, `PM-CHAT.md`, or any MAINTENANCE doc other than
plan/design updates. The v1 plan's Commits 3 and 4 remain dropped
(v1 Part 7 Commit 3 / Commit 4 rationale carries forward verbatim).

---

## Part 1 — Decisions table — nine open questions from V2 design Part 8

Each row resolves one V2 design Part 8 open question with a concrete
decision, a rationale, and the location where the decision is
expanded. "Implementer flag-back" marks a decision the implementer
must pause on if contact with the text contradicts the decision.

| # | Question (V2 design Part 8) | Decision | Rationale | Surface |
|---|---|---|---|---|
| Q1 | Gate label convention for Procedure 7 — four fine-grained labels vs. coarser pair | **Four labels: `G7-discovery`, `G7-install`, `G7-edit`, `G7-machine`** — one per Form (R / I / E / M). | Each Form is already an approval gate with its own default-`skip` invariant (v1 plan Part 3 idempotency rules). A coarser `G7-preview`/`G7-apply` pair would collapse four semantically distinct approval points into one name and lose the 1:1 trace between Form and Gate label. Procedure 6's two-label shape reflects Procedure 6's two natural gates (drafts + commit); Procedure 7 has four, and the label count should follow the gate count, not the precedent's count. | Part 5 §5.3 |
| Q2 | Manual-mode pointer shape inside pm-chat.md | **4-line pointer** naming SETUP-NEW.md § Manual fallback sub-sections 5.A–5.D. No inline command summary. | V2 design Part 3 row 15 specifies the pointer-only shape. The developer who declared `manual` has shell access on some other surface (mouth-to-keyboard manual execution); the commands they need are in SETUP-NEW Manual fallback, which they reach by opening one file. Inline summary duplicates content that must stay byte-parity with the SETUP-NEW source (v1 plan flag-back #4) — strictly cheaper to emit one pointer. | Part 3 §3.3; Part 7 Commit 1 retention #6 |
| Q3 | Gemini plan-mode line — Procedure 7 or pm-chat.md? | **Stays in pm-chat.md kickoff variant preamble.** | V2 design Part 8 Q3 states the plan-mode line must fire before any shell call — i.e., before Procedure 7 is ever read. Procedure 7 is not reached on plan-mode pastes. The line lives in the `Before pasting` list (current row 2) at ~1 line condensed. Current unstaged line 24 wording is preserved verbatim. | Part 3 §3.1 |
| Q4 | Brew version ranges — hardcode in Procedure 7 or reference DEPENDENCIES.md | **Hardcode ranges inline in Procedure 7 Form I examples (carry v1 plan Part 4 verbatim).** Annotate each entry with the existing reference-comment pointer at `supporting-docs/DEPENDENCIES.md`. | v1 plan Q14-2 decided hardcode-for-simplicity; v2 only moves the location from pm-chat.md to METHODOLOGY.md. Developers reading Procedure 7 see the ranges in context; DEPENDENCIES.md remains the authoritative reference. No new file, no new convention. | Part 5 §5.4.3 |
| Q5 | SETUP-EXISTING.md — additional Procedure 7 pointer? | **No. The kickoff-variant continuation pointer is the single route to Procedure 7** from both SETUP-NEW and SETUP-EXISTING. | Both guides already funnel the developer through the same kickoff paste (SETUP-NEW Step 10, SETUP-EXISTING Step 8). Adding a second pointer from SETUP-EXISTING Step 5 duplicates a route the developer already takes. Commit 2 SETUP-EXISTING edit is unchanged from v1 plan Part 7 Commit 2. | Part 4; Part 6 §6.5 |
| Q6 | Procedure 7 numbering + anchor slug | **`### Procedure 7 — Kickoff auto-discovery and install-check`**, anchor slug `#procedure-7--kickoff-auto-discovery-and-install-check` (GitHub anchor convention — lowercase, spaces→hyphens, em-dash `—` leaves `--`, no other special chars). Insertion point: **immediately after line 1134** (end of Procedure 6 "Artifacts never touched" block), before the `### Cancelling or deprecating a BACKLOG item` heading at line 1136. | Procedure 5 sub-procedures (5.1–5.6) use H4 `####`; Procedure 5-R and Procedure 6 use H3 `###`. Procedure 7 is a top-level procedure, so H3 matches precedent. Anchor slug verified against METHODOLOGY.md Part 7 (`Procedure 6 — Adding a pack-supported capability` anchors as `#procedure-6--adding-a-pack-supported-capability`). | Part 5 §5.1 |
| Q7 | Commit 3 message prefix — `docs:` or `feat:` | **`feat:` — `feat: v10 — BD-047 METHODOLOGY.md Procedure 7 for kickoff auto-discovery`.** Mirror-exact shape of commit `84cb4ef` (`feat: v10 — BD-046 METHODOLOGY.md Procedure 6 for capability addition`). | Procedure 7 is a new feature capability in the pack's methodology surface, parallel to Procedure 6. The file touched is documentation, but the *semantic* content is a feature addition with behavioral rules, gate labels, Forms, and a reply grammar. Commits 1 and 2 under v2 are `docs:` — slim edits and doc restructuring with no new procedure. | Part 8 |
| Q8 | Cross-reference sweep additions — S3B-5, S3B-6; confirm S3B-1..S3B-4 still apply | **Confirm S3B-1..S3B-4 apply post-v2 unchanged.** Add S3B-5 (`Procedure 7` reference sweep across `project-template/`) and S3B-6 (`^### Procedure ` sweep in METHODOLOGY.md to confirm 1, 2, 3, 4, 5, 5-R, 6, 7 exactly). | S3B-1/S3B-2 (SETUP-* step numbering) operate on Commit 2's output — Commit 2 spec is unchanged from v1. S3B-3 (BD-047 script names) is informational and does not move. S3B-4 (`Variant: kickoff` pointer sanity) still applies — the variant still exists, only slimmed. S3B-5 verifies the kickoff variant's Procedure 7 pointer is the only in-tree `Procedure 7` reference outside METHODOLOGY.md itself. S3B-6 verifies Procedure 7 landed at H3 with the expected neighbors. | Part 6 |
| Q9 | Information needed but not in required reading | **None identified at plan time.** If Procedure 7 needs to reference an artifact not in current METHODOLOGY.md — e.g., a directory-structure spec for `xcode-companion-templates/` that METHODOLOGY.md has not previously carried — the implementer **flags back** before inlining the reference. | V2 design Part 8 Q9 already records this: "do not silently add the reference." No invention. | Part 10 flag-back #9 |

---

## Part 2 — Reused decisions from v1 plan (index)

The v2 architecture does not disturb the following v1-plan decisions;
they carry forward verbatim into Commit 3 (Procedure 7) and into the
verification criteria below. The implementer must **not re-litigate**
any of these.

| v1 plan Part | Decision | Used in v2 plan |
|---|---|---|
| v1 Part 1 §1.1 Q14-1 | Single combined Form R read-only discovery batch | Procedure 7 §7.1 body |
| v1 Part 1 §1.1 Q14-2 | Hardcode brew ranges inline + pointer to DEPENDENCIES.md | Procedure 7 Form I Pack-tested lines |
| v1 Part 1 §1.1 Q14-3 | Form M default `skip` even for stale installs | Procedure 7 §7.2.4 body |
| v1 Part 1 §1.1 Q14-4 | Kickoff does not offer to commit in-tree edits | Procedure 7 terminal-state wording |
| v1 Part 1 §1.1 Q14-5 | Defer capability-addition kickoff symmetry to BD-048 (not filed — pack chat decides) | Part 10 flag-back #8 of v1; unchanged |
| v1 Part 1 §1.1 Q14-6 | Surface declaration = opening question (not placeholder) | pm-chat.md retention (Commit 1) |
| v1 Part 1 §1.1 Q14-7 | Gemini plan-mode line verbatim | pm-chat.md retention (Commit 1) |
| v1 Part 1 §1.1 Q14-8 | Form M reads `xcode-companion-templates/` at run time | Procedure 7 §7.2.4 body |
| v1 Part 1 §1.1 Q14-9 | SETUP-EXISTING runs discovery after existing-docs pointer | Commit 2 SETUP-EXISTING intro wording (unchanged) |
| v1 Part 1 §1.2 Q10 | Form E anchor-matching (literal primary, bracketed legacy fallback, already-populated skip) | Procedure 7 §7.2.2 body (full v1 Part 2 text lifts verbatim) |
| v1 Part 1 §1.2 Q11 | Per-Form idempotency rules | Procedure 7 §7.6 "Idempotency rules" sub-section |
| v1 Part 1 §1.2 Q12 | Version ranges 2026-04 baseline | Procedure 7 Form I examples |
| v1 Part 1 §1.2 Q13 | Kickoff-variant insertion kept as one commit — **carries to Procedure 7 as one commit under v2** | Commit 3 atomicity |
| v1 Part 1 §1.2 Q14 | Concurrent/interrupted kickoff — rely on idempotency + existing PM-CHAT.md rules | Procedure 7 §7.6 cross-ref to PM-CHAT.md |
| v1 Part 2 | Form E anchors (4 script targets + settings.json) | Procedure 7 §7.2.2 body |
| v1 Part 3 | Idempotency per Form | Procedure 7 §7.6 |
| v1 Part 4 | Brew version range table | Procedure 7 Form I examples |
| v1 Part 5 | Fixture sourcing — `/tmp/phase-3b-fixtures/` | Gate E3 §8.1 "Fixture evidence" criterion (unchanged) |
| v1 Part 6 §6.4 | Step-number preservation (5–8 collapse, gap kept) | Commit 2 (unchanged) |
| v1 Part 8 | Gate E3 criteria skeleton | Part 7 of this plan — updated for 3-commit shape |
| v1 Part 9 | Deferred-to-Phase-4 items | unchanged |
| v1 Part 10 flag-backs #1–#7 | | Part 10 of this plan — incorporated with two additions |
| v1 Part 11 | BD-047 field-by-field closure | Part 11 of this plan — remapped for v2 commit shape |

**What v2 disturbs.** v1 Part 7 Commit 1 (single fat kickoff-variant
edit), v1 Part 7 summary table (2-commit count), v1 Part 6 §6.2
sweep set (S3B-1..S3B-4 → plus S3B-5 and S3B-6), v1 Part 8 Gate E3
entry criteria (add Procedure 7 verification items). Commit 2 is
untouched. All other v1 decisions carry forward.

---

## Part 3 — Commit 1 — pm-chat.md kickoff variant slim

**Purpose.** Transform the current 438-line Variant: kickoff body
(lines 18–388 of the unstaged file) into a ~55-line session-resident
shell: project context, surface-declaration Q/A, a continuation
pointer to Procedure 7 for `shell` declarations, and a pointer to
SETUP-NEW.md § Manual fallback for `manual` declarations.

**File touched.** `project-template/docs/pack/prompts/pm-chat.md` —
one file, edits inside `## Variant: kickoff` only. The three other
variants (backlog-status-update, generate-setup, generate-agent-kickoff)
and the YAML front matter are **not touched**.

**Line-count target.** 55 lines for the variant body (H2 heading
through the end of the pointer block), **±5 lines tolerance**. Full
file after edit: ~200 lines total (current 518 − ~320 removed by
this commit).

### 3.1 Deletion list — lines to remove from the current unstaged body

Line-range references are against the current unstaged file
(confirmed via `wc -l` and the Read output above). Every block below
maps to a row in V2 design Part 3 table — the "Destination" column
there states where the content lands. Deletions here are **relocated**
to Commit 3 (Procedure 7) or to Commit 2 (SETUP-NEW.md § Manual
fallback); nothing is destroyed.

| V2 Part 3 row | Current lines | Block | New home | Deletion rationale |
|:-:|:-:|---|---|---|
| 6 | 88–94 | `### Shell-mode post-kickoff work` intro paragraph ("With the initial context established…") | Procedure 7 §7.0 (Trigger) | Once-per-project framing; not session-resident |
| 7 | 96–127 | `**Step K1 — Read-only discovery**` + Form R block | Procedure 7 §7.1 | One-time per project |
| 8 | 129–147 | `**Step K2 — Apple sub-flow**` + K2.1 scheme/destination | Procedure 7 §7.2.1 | One-time per project |
| 9 | 148–183 | K2.2 Form E (validate-swift.sh / test-swift.sh / settings.json / format-swift.sh) + anchor-matching rules + settings.json safety rule | Procedure 7 §7.2.2 | One-time per project |
| 10 | 185–204 | K2.3 swift-format Form I + idempotency note | Procedure 7 §7.2.3 | One-time per project |
| 11 | 206–230 | K2.4 Xcode companion files Form M + stale-detection | Procedure 7 §7.2.4 | One-time per project (once per Mac) |
| 12 | 231–243 | K3.1 Apple-side gRPC tooling Form I triplet | Procedure 7 §7.3.1 | One-time per project |
| 13 | 244–252 | K3.2 Python-side gRPC tooling Form I quadruplet | Procedure 7 §7.3.2 | One-time per project |
| 14 | 253–264 | K3.3 proto-gen.sh invocation example | Procedure 7 §7.3.3 | One-time per project |
| 15 | 267–341 | `### Manual-mode branch` — M1–M5 verbatim commands + closing pointer | SETUP-NEW.md § Manual fallback (Commit 2, unchanged from v1) | Developer reads SETUP-NEW once; cannot be externalized further |
| 16 | 345–377 | `### Behavior on failure / ambiguity` — 9-row prose block | Procedure 7 §7.4 | Fires only on failure; not session-resident |
| 17 | 379–388 | Reply grammar summary | Procedure 7 §7.5 | Contract for Form replies; lives with the Forms |

**Also removed:** the HR divider on line 265 (`---`) that separates
K3 from Manual-mode (no longer needed — see retention list).

**Removal scope summary.** Lines 88–388 of the current unstaged body
(≈300 lines in-variant) are removed. What remains is the 44-line
pre-Phase-3B baseline (rows 1/2/3/5 in V2 design Part 3) **plus** the
surface-declaration block (row 4) **plus** the new continuation
pointer.

### 3.2 Retention + condensation list — lines to keep

Line-range references are against the current unstaged file. V2
design Part 3 table rows 1–5 describe the retained content.

| V2 Part 3 row | Current lines | Block | Retention mode | New approximate line count |
|:-:|:-:|---|---|---|
| 1 | 20–22 | Variant preamble (`*Paste this at the start…*` + `*Fill in all [PLACEHOLDERS]*`) | **Keep verbatim** | 3 lines (incl. blank line) |
| 2 | 23–26 | "Before pasting" list — Gemini plan-mode line (row-Q3 confirmed), Claude/ChatGPT Web manual-mode pointer, shell-vs-non-shell one-liner | **Condense to 3 bullet lines** (~15 tokens each); retain the Gemini plan-mode line verbatim per v1 plan Q14-7 | 4 lines (heading + 3 bullets) |
| 3 | 28–38 | Project-context placeholders (`I am starting…` through `[Any other settled decisions]`) | **Keep verbatim** | 11 lines |
| 4 | 40–56 | Surface-declaration Q/A block — `**Before I do anything else:**` intro, shell/manual bullets, "Reply with the single word" sentence, override-rules paragraph | **Condense to ~10 lines.** Keep the four core lines: intro sentence, `shell` bullet, `manual` bullet, `Reply with the single word…` line. Trim: move the override-and-mid-kickoff re-declaration paragraph (current lines 53–56) **into Procedure 7 §7.0** (Trigger). | 10 lines |
| 5 | 58–84 | Project-documents pointer + PM-chat-role block + placeholder-fill instructions (`**Project documents are in the GitHub repo.**` through the `**Active skills:**` populate instructions) | **Keep verbatim** | 27 lines |
| new | — | **Kickoff continuation pointer** (new block — see §3.3 below) | **Add** | 6 lines |

**Total retained body.** 3 + 4 + 11 + 10 + 27 + 6 = **61 lines** of
in-variant content, plus 1 line for the `## Variant: kickoff` H2
heading. Comes in at **62 lines** — within the 55-line ±5 tolerance.
If the implementer's condensation lands tighter (e.g., row 2 at 3
total lines, row 4 at 8 lines), the body will hit the ~55-line
target exactly. If the implementer cannot condense below 60 lines,
**flag back** before committing (see Part 10 flag-back #6).

### 3.3 Continuation pointer — exact wording

Inserted at the end of the variant, replacing the deleted
`### Shell-mode post-kickoff work` section header and everything
below it through line 388. Six lines, plain-text prose (no code
fence, no heading, no list bullet):

```markdown
**Next, based on your surface declaration:**

On `shell`: I will read `supporting-docs/METHODOLOGY.md` Procedure 7
directly (not via RAG — Procedure 7 is order-sensitive) and follow
its gates G7-discovery / G7-install / G7-edit / G7-machine before
any write or install.

On `manual`: I will point you at `supporting-docs/SETUP-NEW.md` §
Manual fallback (sub-sections 5.A–5.D) and wait for you to report
values back, then compose the corresponding edits for you to apply.
```

**RAG-vs-direct-read rationale.** `project-template/docs/pack/PM-CHAT.md`
line 124 states METHODOLOGY.md is reachable via RAG on Claude Code
CLI. Procedure 7 is order-sensitive — K1 must fire before K2/K3; Form
R must render before Form I/E/M — so a RAG query that returns only
part of the procedure is a correctness hazard. The pointer's "not
via RAG" clause names the direct-read contract explicitly. This is
the wording the implementer uses verbatim; other paraphrases must be
flagged back.

### 3.4 Edit procedure (implementer sequence)

1. Read current unstaged `project-template/docs/pack/prompts/pm-chat.md`
   (line ranges verified — see §3.1).
2. Delete lines 88–388 (inclusive of the `### Shell-mode post-kickoff
   work` heading through the end of the reply-grammar block and any
   trailing blank line before `## Variant: backlog-status-update`).
3. Delete the HR divider at line 86 (current `---` separating Step 5
   placeholders from Shell-mode section) only if keeping it would
   leave two HRs adjacent in the slimmed output.
4. Condense the "Before pasting" list per §3.2 row 2.
5. Condense the surface-declaration block per §3.2 row 4 (move the
   override/mid-kickoff paragraph into Procedure 7 §7.0).
6. Insert the six-line continuation pointer per §3.3 at the end of
   the Variant: kickoff section, before `## Variant:
   backlog-status-update`.
7. Verify — see §3.5.

### 3.5 Commit 1 verification checklist

Run before committing Commit 1 (and before any commit; hereafter just
"verification"):

- `python3 scripts/validate-pack.py` → exit 0.
- `grep -n '^## Variant: ' project-template/docs/pack/prompts/pm-chat.md`
  → exactly 4 matches (kickoff, backlog-status-update, generate-setup,
  generate-agent-kickoff). No new variants; none removed.
- `grep -c '^---$' project-template/docs/pack/prompts/pm-chat.md` →
  exactly 2 (YAML front-matter delimiters).
- `wc -l project-template/docs/pack/prompts/pm-chat.md` → ≤220 lines
  total (sanity check; hard ceiling — flag back if exceeded).
- `awk '/^## Variant: kickoff/,/^## Variant: backlog-status-update/'
  project-template/docs/pack/prompts/pm-chat.md | wc -l` → ≤65 lines
  (section-scoped line count; flag back if exceeded).
- `grep -n 'Procedure 7' project-template/docs/pack/prompts/pm-chat.md`
  → exactly 1 match, inside the continuation pointer.
- `grep -n 'SETUP-NEW.md' project-template/docs/pack/prompts/pm-chat.md`
  → exactly 1 match inside the kickoff variant (the continuation
  pointer's `manual` branch); other `SETUP-NEW.md` references in the
  file are inside other variants and unchanged.
- `grep -n 'xcodebuild\|xcrun simctl\|brew install\|uv add\|cmp -s\|proto-gen.sh\|cp "\$PACK"' project-template/docs/pack/prompts/pm-chat.md`
  → exactly 0 matches. These strings all relocated to Procedure 7
  (Commit 3) or SETUP-NEW § Manual fallback (Commit 2). If any match
  survives, the deletion was incomplete — do not commit.
- Visual diff: confirm the six-line continuation pointer is the only
  new text; every other change is a deletion.

**Commit 1 is safe to land before Commits 2 and 3 exist.** The
continuation pointer names files that are either already present
(SETUP-NEW.md Manual fallback does not yet exist, but SETUP-NEW.md
Steps 5–8 do and contain the same commands) or will be present after
Commit 2/3. The kickoff behavior is degraded but coherent in the
interim — the PM chat cannot reach Procedure 7 content until Commit
3 lands, so real kickoff sessions **should not happen between Commit
1 and Commit 3**. See Part 10 flag-back #7 and Part 7 Gate E3
criterion #10 ("commits land in one push").

### 3.6 Commit 1 message

`docs: v10 — BD-047 pm-chat.md kickoff variant slim + Procedure 7 pointer`

See Part 8 for commit-message rationale and the full three-commit
message set.

---

## Part 4 — Commit 2 — SETUP-NEW.md + SETUP-EXISTING.md (unchanged from v1)

**No deltas from v1 plan Part 7 Commit 2.** Reproduced in summary
here for completeness; the implementer reads the full spec from v1
Part 7 Commit 2 and v1 Part 6 §6.4 (step-number preservation
rationale).

**Files touched.**

- `supporting-docs/SETUP-NEW.md` — replace current Steps 5, 6, 7, 8
  with one collapsed Step 5 (intro + `### Manual fallback` subsection
  containing 5.A Apple Xcode scheme variables, 5.B swift-format
  install, 5.C gRPC tooling install, 5.D Xcode companion files). Steps
  1–4 and 9–12 unchanged.
- `supporting-docs/SETUP-EXISTING.md` — replace current Steps 5 and 6
  with one collapsed Step 5 that cross-references
  `SETUP-NEW.md § Manual fallback`. Update the current line 149
  cross-reference (`See SETUP-NEW.md Step 5 for detailed values and
  how to find them.`) to point at the new sub-section heading. Steps
  7–12 unchanged.

**Content source.** Current SETUP-NEW.md Steps 5–8 (lines 149–235 in
the current unstaged tree — confirmed by Read above). Moved verbatim
into sub-sections 5.A–5.D with only heading-level changes. v1 plan
Part 6 §6.4 numbering-invariant post-Commit 2:

- SETUP-NEW: Step 1, 2, 3, 4, **5** (new collapsed), 9, 10, 11, 12.
- SETUP-EXISTING: Step 1, 2, 3, 4, **5** (new collapsed), 7, 8, 9,
  10, 11, 12.

**Deltas from v1 Part 7 Commit 2: none.** Under v2, Procedure 7's
Forms R/I/E/M are the PM-chat-side expression of the same underlying
facts Manual-fallback expresses developer-side — the "audience split"
argument in V2 design §7.4. Commit 2 edits are identical to v1.

**Verification.**

- `python3 scripts/validate-pack.py` → exit 0.
- Sweep S3B-1 and S3B-2 (Part 6 below) clean outside sanctioned
  residuals.
- `grep -n '^## Step' supporting-docs/SETUP-NEW.md` → Steps 1, 2, 3,
  4, 5, 9, 10, 11, 12 (gap intentional).
- `grep -n '^## Step' supporting-docs/SETUP-EXISTING.md` → Steps 1,
  2, 3, 4, 5, 7, 8, 9, 10, 11, 12 (gap intentional).
- Byte-parity spot-check: the new 5.A/5.B/5.C/5.D command blocks
  match the current Steps 5/6/7/8 command blocks character-for-
  character on every shell command line.

**Commit 2 message.**

`docs: v10 — BD-047 SETUP-NEW + SETUP-EXISTING fold Steps 5–8 into PM chat`

(Unchanged from v1 plan Part 7 Commit 2 message.)

**Gate membership:** Gate E3.

---

## Part 5 — Commit 3 — METHODOLOGY.md Procedure 7 (NEW)

**Purpose.** Host the K1/K2/K3 flow, Forms R/I/E/M, the nine-row
behavior-on-failure table, the reply grammar, the idempotency rules,
and the G7 gate labels. Lifted substantially verbatim from the
current unstaged kickoff-variant body (lines 88–388), reformatted to
METHODOLOGY.md's Procedure shape (§5.1 below) and the Gn gate-label
convention.

**File touched.** `supporting-docs/METHODOLOGY.md` — one file, one
insertion. Insertion point: immediately after line 1134 (end of
Procedure 6 "Artifacts never touched" block), before line 1136
(`### Cancelling or deprecating a BACKLOG item`).

**Target size.** ~220 lines total for the Procedure 7 block (H3
heading + ten sub-sections + wrap). Implementer flag-back #5 fires if
the final size is <180 or >260 lines (content substance would have
changed).

### 5.1 Heading, anchor, placement

- **Heading:** `### Procedure 7 — Kickoff auto-discovery and install-check`
- **Anchor slug (automatic, GitHub convention):** `#procedure-7--kickoff-auto-discovery-and-install-check`
- **Placement:** after line 1134 of current METHODOLOGY.md; before
  `### Cancelling or deprecating a BACKLOG item`.
- **Heading level:** H3 (matches Procedure 6, Procedure 5-R, and
  Procedures 1–4). Sub-sections use H4 `####` (matches Procedure 5
  sub-procedures 5.1–5.6 style at METHODOLOGY.md lines 964–1046).

### 5.2 Sub-section outline (exact heading list)

The implementer writes Procedure 7 with this sub-section list, in
this order. Each sub-section's body is sourced from the current
unstaged kickoff-variant lines noted in parentheses (authoritative
source for content; only heading style changes). Bodies are lifted
verbatim except for the explicit transformations in §5.3–§5.10.

1. **Trigger and scope** (H4 `#### 7.0 Trigger and scope`) — lifts
   current lines 88–94 (`### Shell-mode post-kickoff work` intro) +
   the override/mid-kickoff re-declaration paragraph moved from
   current lines 53–56.
2. **Step K1 — Read-only discovery (Form R)** (H4 `#### 7.1 K1 —
   read-only discovery (Form R, G7-discovery)`) — lifts current
   lines 96–127 verbatim (Form R code fence, command enumeration,
   reply line).
3. **Step K2 — Apple sub-flow** (H4 `#### 7.2 K2 — Apple sub-flow`)
   — 4-line intro + conditional-on-PLATFORM_TARGETS guard, sourced
   from current lines 129–131.
   - **7.2.1 Xcode scheme and destination** (H5 `##### 7.2.1 Xcode
     scheme and destination`) — lifts current lines 132–147
     verbatim.
   - **7.2.2 Script and settings edits (Form E, G7-edit)** (H5 `#####
     7.2.2 Script and settings edits (Form E, G7-edit)`) — lifts
     current lines 148–183 verbatim (Form E code fence, anchor-
     matching rules, settings.json safety rule).
   - **7.2.3 swift-format install (Form I, G7-install)** (H5 `#####
     7.2.3 swift-format install (Form I, G7-install)`) — lifts
     current lines 185–204 verbatim.
   - **7.2.4 Xcode companion files (Form M, G7-machine)** (H5
     `##### 7.2.4 Xcode companion files (Form M, G7-machine)`) —
     lifts current lines 206–230 verbatim.
4. **Step K3 — gRPC sub-flow** (H4 `#### 7.3 K3 — gRPC sub-flow`)
   — conditional-on-TRANSPORT-or-proto/-dir intro, sourced from
   current line 231.
   - **7.3.1 Apple-side gRPC tooling** (H5 `##### 7.3.1 Apple-side
     gRPC tooling (Form I, G7-install)`) — lifts current lines
     233–243 verbatim.
   - **7.3.2 Python-side gRPC tooling** (H5 `##### 7.3.2 Python-side
     gRPC tooling (Form I, G7-install)`) — lifts current lines
     244–252 verbatim.
   - **7.3.3 Proto code generation example** (H5 `##### 7.3.3 Proto
     code generation example`) — lifts current lines 253–264
     verbatim.
5. **Behavior on failure / ambiguity** (H4 `#### 7.4 Behavior on
   failure / ambiguity`) — lifts current lines 345–377 verbatim (the
   three common-discipline bullets and the nine-row numbered list).
6. **Reply grammar** (H4 `#### 7.5 Reply grammar`) — lifts current
   lines 379–388 verbatim.
7. **Idempotency rules** (H4 `#### 7.6 Idempotency rules`) — NEW in
   Procedure 7 (not in current kickoff variant as a standalone
   section); assembled from v1 plan Part 3 §3.1–§3.5. Concise form;
   forward-references the existing per-Form idempotency notes inside
   7.2.3, 7.2.4, and the "note:" one-liners inside 7.2.2 Form E.
8. **Artifacts and cross-references** (H4 `#### 7.7 Artifacts and
   cross-references`) — follows the Procedure 6 precedent
   (METHODOLOGY.md lines 1127–1134 `**Artifacts modified:**` /
   `**Artifacts never touched by Procedure 7:**`). See §5.10 below
   for exact content.

### 5.3 Gate-label assignments (G7-*)

Four labels, one per Form, as decided in Part 1 Q1:

| Gate label | Where it appears in Procedure 7 | What it guards |
|---|---|---|
| `G7-discovery` | §7.1 Form R | Read-only discovery batch; default `yes` acceptable because read-only — see §7.1 code-fence reply line |
| `G7-install` | §7.2.3 Form I (swift-format); §7.3.1 Form I triplet (buf / swift-protobuf / grpc-swift); §7.3.2 Form I quadruplet (Python gRPC) | Every `brew install` / `uv add` action; default `skip` |
| `G7-edit` | §7.2.2 Form E (validate-swift.sh, test-swift.sh, .claude/settings.json, format-swift.sh) | Every in-tree file edit; default `skip` |
| `G7-machine` | §7.2.4 Form M (Xcode companion files under `~/Library/...`) | Machine-level writes outside the project tree; default `skip` |

The labels are inline in the sub-section heading (e.g., `##### 7.2.2
Script and settings edits (Form E, G7-edit)`). No free-standing
"Gate" line is needed inside sub-section bodies — the Form code
fences themselves are the gate. This parallels Procedure 6's
`**G6-drafts**` / `**G6-commit**` inline annotations on step
rows (METHODOLOGY.md lines 1111–1122).

### 5.4 Forms R / I / E / M — body specifications

The Forms are the approval-gate surface. They appear as Markdown
code fences inside the relevant sub-sections. Each Form's body is
sourced from the current unstaged kickoff variant — the implementer
lifts the code-fence block verbatim. Line pointers are to current
unstaged pm-chat.md (see §3.1 for the full relocation table).

#### 5.4.1 Form R — read-only discovery

- **Source:** current lines 98–127 (the `PROPOSED ACTION — read-only
  discovery` code fence).
- **Content:** verbatim. Eleven discovery commands: Apple / Swift
  lines 1–3; gRPC lines 4–6; Environment line 7; Python + gRPC
  lines 8–9; Machine-level lines 10–11. Reply line: `yes` to run
  all · `skip` to bypass · `abort`.
- **No transformation.** Reply default behavior per v1 plan Part 3
  §3.1 — Form R always runs on every kickoff invocation; read-only,
  no persistent target state.

#### 5.4.2 Form E — single file edit

- **Source:** current lines 156–170 (the `PROPOSED EDIT —
  scripts/validate-swift.sh` code-fence example) + anchor-matching
  prose lines 172–180 + settings.json safety rule lines 181–183.
- **Content:** verbatim. The example code fence is a concrete
  demonstration for one target; the prose below enumerates the four
  targets (v1 plan Part 2 §2.1 table).
- **Carry-forward rule:** v1 plan Part 2 §2.1 / §2.2 / §2.3 / §2.4 /
  §2.5 is the authoritative Form E spec. The implementer lifts the
  current kickoff variant's prose (lines 148–183) — which already
  implements v1 Part 2 — into Procedure 7 §7.2.2.

#### 5.4.3 Form I — single install

- **Source:** current lines 187–198 (swift-format example code
  fence) + idempotency note lines 200–203.
- **Content:** verbatim. The "Pack-tested:" lines hardcode the brew
  version ranges (Q4 decision — hardcode; v1 plan Part 4 table).
- **Multiple Form I instances.** §7.2.3 (swift-format), §7.3.1 (buf,
  swift-protobuf, grpc-swift — three Form I renderings each with its
  own range), §7.3.2 (grpcio-tools, grpcio, grpcio-status,
  grpcio-reflection — four Form I renderings via `uv add`). All
  ranges as in v1 plan Part 4.

#### 5.4.4 Form M — companion-files batch (machine-level)

- **Source:** current lines 208–221 (`PROPOSED ACTION — install
  Xcode companion files` code fence) + idempotency note lines
  223–229.
- **Content:** verbatim. Runtime `ls "$PACK/xcode-companion-templates/"`
  per v1 plan Q14-8 — already in the current prose.
- **Idempotency:** v1 plan Part 3 §3.4 — byte-identity check via
  `cmp -s`. Already reflected in current lines 223–229.

### 5.5 §7.4 Behavior on failure — nine-row source

Source: current lines 345–377 verbatim. The table is rendered as a
numbered list (rows 1–9), not as a Markdown table, preserving the
current body shape. Under each numbered row, the behavior description
is verbatim from the kickoff variant. Nine rows:

1. Xcode not installed
2. One scheme detected
3. Multiple schemes detected
4. No simulators available
5. `brew` not installed
6. Required brew tool missing
7. Brew tool at out-of-range version
8. Source layout indeterminate
9. Network required but unavailable

The three common-discipline bullets (current lines 347–354) precede
the numbered list. Implementer lifts the entire block.

### 5.6 §7.5 Reply grammar — source

Source: current lines 379–388 verbatim. Six bullets:

- `yes` / `y`
- `no` / `skip`
- `abort`
- `edit`
- Bare integer / scheme name / destination string / directory list
- Empty / unrecognized / "no" / "don't" / "wait" → treated as `no`;
  re-prompt; never defaults to `yes`

Heading: `#### 7.5 Reply grammar`.

### 5.7 §7.6 Idempotency rules — NEW, sourced from v1 plan Part 3

This sub-section is not present as a standalone block in the
current kickoff variant. The implementer assembles it from v1 plan
Part 3 §3.1–§3.5. Recommended shape (~25 lines):

- Intro sentence: "Procedure 7 is idempotent on re-invocation. Each
  Form has a target-state definition; when the target state already
  holds, the Form emits a single-line `note:` diagnostic and moves
  on without re-rendering."
- Four bullet rows (one per Form): Form R — always runs (no target
  state); Form I — `command -v <tool>` + version in known-good range;
  Form E — anchor equals proposed value (empty diff); Form M — every
  pair byte-identical under `cmp -s`.
- Pointer: "For concurrent / interrupted kickoff handling, see
  `project-template/docs/pack/PM-CHAT.md` § Before starting a new
  project ('Never run two PM chats simultaneously for the same
  project')." (v1 plan Q14 — no new text needed in PM-CHAT.md.)
- Terminal state paragraph: "If Form R runs, all Form I targets are
  in-range, all Form E anchors are populated, and all Form M targets
  are byte-identical, Procedure 7 prints: 'Kickoff complete — nothing
  to change.' This is the empty-diff re-invocation terminal state."
  (v1 plan Part 3 §3.5 verbatim.)

### 5.8 §7.7 Artifacts and cross-references — source

Follows Procedure 6 precedent (METHODOLOGY.md lines 1127–1134).
Approximate shape:

- `**Artifacts modified:**` — `scripts/validate-swift.sh`,
  `scripts/test-swift.sh`, `scripts/format-swift.sh` (conditional),
  `.claude/settings.json`, and `~/Library/Developer/Xcode/
  CodingAssistant/{ClaudeAgentConfig,codex}/*` (machine-level; not
  in project tree).
- `**Artifacts never touched by Procedure 7:**` — `BACKLOG.md`;
  `STATUS.md`; `CHANGELOG.md`; `ARCHITECTURE.md`;
  `IMPLEMENTATION_PLAN.md`; the trinity files (`CLAUDE.md`,
  `AGENTS.md`, `GEMINI.md`); `.codex/`, `.gemini/`, `.claude/agents/`
  subtrees; any file under `docs/project/` other than the ones the
  PM chat ordinarily writes via Part 9 permissions; any `x-` custom
  agent / skill / prompt file.
- `**Sub-flow conditions:**` — the Apple sub-flow runs iff
  `[PLATFORM_TARGETS]` includes any of iOS, iPadOS, macOS, tvOS,
  watchOS, visionOS; the gRPC sub-flow runs iff `[TRANSPORT]`
  includes gRPC OR a `proto/` directory exists at the project root;
  the Python Form I quadruplet under §7.3.2 runs iff Python is also
  detected.
- Forward-reference: "The kickoff-variant continuation pointer in
  `project-template/docs/pack/prompts/pm-chat.md` Variant: kickoff
  is the invocation point for Procedure 7." (Symmetry with
  Procedure 6's `add-capability.sh` trigger mention at line 1106.)

### 5.9 §7.0 Trigger and scope — body

Two paragraphs:

1. **Trigger** (lifted from current lines 88–94 + condensed): the PM
   chat enters Procedure 7 when the kickoff-variant continuation
   pointer fires on a `shell` declaration. On `manual`, Procedure 7
   is not entered; the PM chat emits the SETUP-NEW.md § Manual
   fallback pointer instead and waits for developer-reported values.
2. **Override and mid-kickoff re-declaration** (moved from current
   kickoff-variant lines 53–56): the developer may declare `manual`
   even on a shell-capable surface (e.g., to read planned commands
   before granting execution); the PM chat honors it. The developer
   may also switch to `manual` mid-kickoff; the PM chat treats that
   as a re-declaration from that point onward — commands already run
   cannot be unrun.

### 5.10 Commit 3 verification checklist

- `python3 scripts/validate-pack.py` → exit 0.
- `grep -n '^### Procedure ' supporting-docs/METHODOLOGY.md` →
  exactly **8 matches**: Procedure 1, 2, 3, 4, 5, 5-R, 6, **7** (in
  that order). No gaps, no duplicates.
- `grep -n '^### Procedure 7 ' supporting-docs/METHODOLOGY.md` →
  exactly 1 match.
- `grep -cE '^#### 7\.[0-7] |^##### 7\.[23]\.[1-4] ' supporting-docs/METHODOLOGY.md`
  → 8 H4 matches + 7 H5 matches = **15 sub-section headings** under
  Procedure 7 (7.0, 7.1, 7.2, 7.2.1, 7.2.2, 7.2.3, 7.2.4, 7.3,
  7.3.1, 7.3.2, 7.3.3, 7.4, 7.5, 7.6, 7.7).
- `grep -n 'G7-discovery\|G7-install\|G7-edit\|G7-machine' supporting-docs/METHODOLOGY.md`
  → ≥4 matches (one per gate label, plus optional references
  elsewhere in Procedure 7).
- `grep -nE 'xcodebuild|xcrun simctl|brew install swift-format|cmp -s|proto-gen\.sh' supporting-docs/METHODOLOGY.md`
  → matches present inside Procedure 7 body (confirms the Form
  content was lifted).
- `wc -l` over the Procedure 7 block (awk between `^### Procedure 7`
  and `^### Cancelling or deprecating`) → between 180 and 260 lines.
  Flag back if outside this range.
- Visual: the K1/K2/K3 Form code fences in Procedure 7 are byte-
  parity with the kickoff variant's pre-slim code fences. (Obsolete
  as of Commit 1; confirm against the v1 plan Part 2/3 spec
  instead.)

### 5.11 Commit 3 message

`feat: v10 — BD-047 METHODOLOGY.md Procedure 7 for kickoff auto-discovery`

See Part 8.

---

## Part 6 — Cross-reference sweep specification (S3B-1..S3B-6)

v1 plan Part 6 §6.2 defines S3B-1..S3B-4. V2 adds S3B-5 and S3B-6.
All six sweeps run after Commit 3.

### 6.1 S3B-1 — SETUP-NEW step-number residuals (carry from v1)

```bash
grep -rnE 'SETUP-NEW\.md[[:space:]]+(Step|§)[[:space:]]?[5-8]\b' \
    project-template/ supporting-docs/ maintenance-docs/ \
    QUICKSTART.md README.md CLAUDE.md AGENTS.md GEMINI.md \
    PACK-CHAT.md PACK-AGENTS.md BACKLOG.md
```

**Expected:** zero matches in `project-template/`, `QUICKSTART.md`,
`README.md`, `PACK-*.md`, `BACKLOG.md`, root trinity.

**Sanctioned residuals:**
- `supporting-docs/SETUP-NEW.md` (self — "Step 5" and "5.A"–"5.D"
  headers appear inside the file).
- `supporting-docs/MIGRATION-v9-to-v10.md` Step 5 / Step 6 headers
  (different semantic — custom-file registration).
- `maintenance-docs/V10-PHASE-3B-*.md` (this plan + v1 + design docs
  cite historical step numbers).
- `maintenance-docs/V10-IMPLEMENTATION-PLAN.md` historical references.

### 6.2 S3B-2 — SETUP-EXISTING step-number residuals (carry from v1)

```bash
grep -rnE 'SETUP-EXISTING\.md[[:space:]]+(Step|§)[[:space:]]?[56]\b' \
    project-template/ supporting-docs/ maintenance-docs/ \
    QUICKSTART.md README.md CLAUDE.md AGENTS.md GEMINI.md \
    PACK-CHAT.md PACK-AGENTS.md BACKLOG.md
```

**Expected:** zero matches in `project-template/`, `QUICKSTART.md`,
`README.md`, `PACK-*.md`, `BACKLOG.md`, root trinity.

**Sanctioned residuals:** `supporting-docs/SETUP-EXISTING.md` itself;
`maintenance-docs/V10-PHASE-3B-*.md`.

### 6.3 S3B-3 — BD-047 description alignment (carry from v1, informational)

```bash
grep -n 'scripts/validate\.sh\|scripts/test\.sh\|scripts/format\.sh' \
    BACKLOG.md maintenance-docs/V10-PHASE-3B-DESIGN.md \
    maintenance-docs/V10-PHASE-3B-DESIGN-v2.md \
    maintenance-docs/V10-PHASE-3B-PLAN.md \
    maintenance-docs/V10-PHASE-3B-PLAN-v2.md
```

**Expected matches only in:** BACKLOG.md (BD-047 description,
historically correct-as-written); V10-PHASE-3B design/plan docs.
Does not block the gate; see Part 10 flag-back #1.

### 6.4 S3B-4 — pm-chat.md variant pointer sanity (carry from v1)

```bash
grep -n 'Variant: kickoff' project-template/docs/pack/prompts/pm-chat.md \
    supporting-docs/ project-template/PM-CHAT.md \
    project-template/docs/pack/PM-CHAT.md \
    project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md
```

**Expected:** every match is either the kickoff variant heading
itself or a SETUP-guide / PM-CHAT.md pointer citing
`docs/pack/prompts/pm-chat.md` Variant: kickoff.

### 6.5 S3B-5 — Procedure 7 pointer uniqueness (NEW under v2)

```bash
grep -rn 'Procedure 7' project-template/ supporting-docs/ \
    QUICKSTART.md README.md CLAUDE.md AGENTS.md GEMINI.md \
    PACK-CHAT.md PACK-AGENTS.md BACKLOG.md
```

**Forbidden category.** Redundant routing pointers — any new file or
section that purports to "tell the PM chat to read Procedure 7" beyond
the kickoff-variant continuation pointer in `pm-chat.md`. There is one
canonical routing pointer; everything else must be descriptive (naming
Procedure 7 in prose) rather than prescriptive (instructing the PM
chat to read it).

**Sanctioned residuals (descriptive-not-prescriptive mentions).**

| Location | Mention | Why sanctioned |
|---|---|---|
| `project-template/docs/pack/prompts/pm-chat.md` lines 26, 82, 83 | 3 mentions: "Before pasting" bullet; continuation pointer x 2 | Path A acceptance during Commit 1 execution; the §3.3 verbatim pointer text contains 2 mentions of "Procedure 7" by design (identifier + order-sensitive clause), and the bullet 3 mention is a one-line preview of the routing decision. Plan-arithmetic discrepancy with §3.5's "exactly 1" — accepted. |
| `supporting-docs/METHODOLOGY.md` ≥1 match | `### Procedure 7` H3 heading + intra-procedure cross-references | Authoritative procedure home; mentions inside the procedure body are normal cross-references. |
| `supporting-docs/SETUP-NEW.md` line 153 | Step 5 prose: "(METHODOLOGY.md Procedure 7) after you paste the kickoff prompt" | Descriptive — the SETUP guide tells the *developer* what the PM chat will do, not the PM chat itself. Not a routing pointer. |
| `supporting-docs/SETUP-EXISTING.md` line 148 | Step 5 prose: same pattern as SETUP-NEW | Same rationale; descriptive not prescriptive. (Q5 of this plan said "no separate routing pointer from SETUP-EXISTING" — it does not forbid descriptive mentions.) |
| `BACKLOG.md` BD-047 Resolution line | "METHODOLOGY.md Procedure 7 hosts the K1/K2/K3 auto-discovery + Forms R/I/E/M…" | Resolution-record artifact written 2026-04-24 *after* this sweep was originally specified. Historical record; not a routing pointer. |

**Forbidden (would trigger flag-back).** Any *new* file under
`project-template/` (other than `pm-chat.md`'s continuation pointer)
that instructs the PM chat to read Procedure 7. Any new file in
`QUICKSTART.md`, `README.md`, `PACK-*.md`, or the root trinity that
adds a routing pointer.

**Sweep verdict at Gate F.** If the sweep returns only the sanctioned
residuals enumerated above (or a strict subset), pass. If any new
match appears outside the sanctioned set, the implementer flags back.

### 6.6 S3B-6 — METHODOLOGY.md Procedure ordering (NEW under v2)

```bash
grep -n '^### Procedure ' supporting-docs/METHODOLOGY.md
```

**Expected — exactly eight lines, in this order:**

1. `### Procedure 1 — Phase gate check (runs before every phase prompt)`
2. `### Procedure 2 — Post-session processing (after every coder completion report)`
3. `### Procedure 3 — Orphan audit (runs at every phase gate, step 5)`
4. `### Procedure 4 — Resolution procedure (when item is Unblocked and approved)`
5. `### Procedure 5 — Custom agent and skill workflow`
6. `### Procedure 5-R — Prompt reconciliation after v9.3 → v10 migration`
7. `### Procedure 6 — Adding a pack-supported capability`
8. `### Procedure 7 — Kickoff auto-discovery and install-check`

Any divergence (missing, duplicated, or reordered) blocks the gate.
Procedure 5 sub-procedures 5.1–5.6 remain at H4 and are **not**
expected in this grep (the pattern is `^### Procedure`, H3-only).

### 6.7 Sweep execution point

All six sweeps run **after Commit 3**. S3B-1/S3B-2 may also run
after Commit 2 (they operate on Commit 2's output and are unchanged
from v1). S3B-3 informational only. S3B-4/S3B-5/S3B-6 must all pass
before Gate E3 closes.

---

## Part 7 — Gate E3 entry criteria (updated for three-commit shape)

Mirrors Gate E / Gate E2 structure (V10-IMPLEMENTATION-PLAN §6.5).
Carries v1 Part 8 criteria forward with v2 deltas marked [v2-new] and
[v2-updated].

Gate E3 opens when **all** of the following hold:

1. **`validate-pack.py` passes after every commit.** Run after Commit
   1, after Commit 2, and after Commit 3. All three runs exit 0.
   [v2-updated — was 2 runs; now 3.]
2. **Cross-reference sweeps clean.**
   - S3B-1 (Part 6 §6.1) → matches only within sanctioned residual
     set.
   - S3B-2 (Part 6 §6.2) → matches only within sanctioned residual
     set.
   - S3B-3 (Part 6 §6.3) → informational only.
   - S3B-4 (Part 6 §6.4) → every match is a recognized pointer.
   - **[v2-new] S3B-5** (Part 6 §6.5) → exactly 1 match in
     pm-chat.md (continuation pointer); ≥1 in METHODOLOGY.md; zero
     elsewhere in pack-product.
   - **[v2-new] S3B-6** (Part 6 §6.6) → exactly 8 `### Procedure `
     lines in METHODOLOGY.md, in the correct order.
3. **Kickoff variant parses cleanly and sits within line-count
   target.**
   - `grep -n '^## Variant: ' project-template/docs/pack/prompts/pm-chat.md`
     → exactly 4 matches. [unchanged]
   - YAML front matter preserved (no new keys, no removed keys).
     [unchanged]
   - **[v2-new]** Variant: kickoff section body ≤65 lines
     (tolerance); full file ≤220 lines.
4. **SETUP-guide numbering invariant holds.** [unchanged from v1]
5. **[v2-updated] Manual-vs-Procedure-7 Form parity spot-check.**
   Reviewer reads SETUP-NEW.md § Manual fallback 5.A–5.D side-by-
   side with Procedure 7 §7.1–§7.3.3 Form R/I/E/M blocks. The
   command sets match on every shell command line. (v1 criterion #5
   compared Manual fallback vs. kickoff-variant Manual-mode branch;
   under v2 the kickoff variant no longer carries a Manual-mode
   branch, so the comparison axis moves to Procedure 7.)
6. **Fixture evidence.** Six fixtures per v1 plan Part 5 exercised
   with the kickoff → Procedure 7 path on at least one Bash-capable
   surface. [unchanged from v1]
7. **Cross-surface checks** (deferable to Phase 4). [unchanged]
8. **Category-C (Manual mode) check.** Paste the kickoff into Claude
   Web; reply `manual`; verify no tool call fires and the pointer
   emitted matches SETUP-NEW § Manual fallback. [unchanged]
9. **BD-047 coverage verified.** Part 11 of this plan closes every
   BD-047 description clause under the v2 commit shape. [v2-updated]
10. **[v2-updated] No unintended touches.** `git log --stat` for
    Phase 3-B shows exactly three commits touching exactly three
    file paths:
    - Commit 1: `project-template/docs/pack/prompts/pm-chat.md`
    - Commit 2: `supporting-docs/SETUP-NEW.md`,
      `supporting-docs/SETUP-EXISTING.md`
    - Commit 3: `supporting-docs/METHODOLOGY.md`

    No trinity files, no scripts, no `validate-pack.py`, no
    `README.md`, no `BACKLOG.md`, no other MAINTENANCE docs (other
    than plan/design updates written outside this phase's commit
    window), no `QUICKSTART.md`, no `PACK-*.md`, no `PM-CHAT.md`.
11. **[v2-new] Procedure 7 H5 sub-section count.** Procedure 7
    contains 8 H4 sub-sections (7.0 through 7.7) and 7 H5 sub-
    sections (7.2.1–7.2.4, 7.3.1–7.3.3) — see §5.10.
12. **[v2-new] Gate-label consistency with G6 precedent.**
    Procedure 7 uses H4/H5 sub-section heading-level annotation
    (e.g., `##### 7.2.2 Script and settings edits (Form E, G7-edit)`)
    that parallels Procedure 6's `**G6-drafts**` / `**G6-commit**`
    inline cell annotations. Reviewer confirms the pattern is not
    re-invented.

Any failed criterion opens a `fix:` commit and re-runs the gate. The
pack chat owns the Gate E3 approval decision.

---

## Part 8 — Commit message specifications

Three commits, each with a specific message shape. Carry to the
implementer as-is.

| # | Prefix | BD ref | One-line subject | Full message |
|---|---|---|---|---|
| 1 | `docs:` | BD-047 | `pm-chat.md kickoff variant slim + Procedure 7 pointer` | `docs: v10 — BD-047 pm-chat.md kickoff variant slim + Procedure 7 pointer` |
| 2 | `docs:` | BD-047 | `SETUP-NEW + SETUP-EXISTING fold Steps 5–8 into PM chat` | `docs: v10 — BD-047 SETUP-NEW + SETUP-EXISTING fold Steps 5–8 into PM chat` |
| 3 | `feat:` | BD-047 | `METHODOLOGY.md Procedure 7 for kickoff auto-discovery` | `feat: v10 — BD-047 METHODOLOGY.md Procedure 7 for kickoff auto-discovery` |

**Rationale (Q7 resolution).**

- Commit 1 is a pure reduction of an already-shipped variant plus a
  6-line continuation pointer. No new feature behavior; a
  documentation edit pattern. `docs:` is correct.
- Commit 2 restructures SETUP guides — pure documentation shape
  change; no new procedure semantics. `docs:`.
- Commit 3 adds a new Procedure to METHODOLOGY.md. Parallel to
  commit `84cb4ef` (`feat: v10 — BD-046 METHODOLOGY.md Procedure 6
  for capability addition`) — Procedure 6 also lived in a doc file
  but was prefixed `feat:` because it added a new procedure
  capability to the methodology. Procedure 7 follows the exact same
  precedent.

**Pack-repo commit convention.** All three messages follow the
CLAUDE.md format: `<prefix>: vN — BD-NNN short description`, where
N is the current major version (10, from README.md version table)
and BD-NNN is 047. No trailing period. No multi-line body required
for any of the three.

**Landing order.** Commits 1 → 2 → 3 in that sequence. See Part 10
flag-back #7 for the single-push constraint.

---

## Part 9 — Scope boundary (what Phase 3-B still is NOT)

Explicit non-targets, carried from v1 Part 0 and V2 design Part 9,
updated for the three-commit shape.

Phase 3-B does **not** touch:

- `project-template/CLAUDE.md`, `project-template/AGENTS.md`,
  `project-template/GEMINI.md` — the trinity. No content change.
- Pack-repo `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` — the pack trinity.
  No content change.
- `scripts/init-project.sh` — no change. (V2 design §7.6 stage S3
  already copies `METHODOLOGY.md` to the project root; Procedure 7's
  on-project presence is a consequence of existing behavior.)
- `scripts/add-capability.sh` — no change. (BD-048 candidate, v1
  plan flag-back #8 — not filed.)
- `scripts/lib/detect.sh` — no change.
- Any other script under `project-template/scripts/` or top-level
  `scripts/`.
- `scripts/validate-pack.py` — no schema change. Procedure 7's H3
  heading is a regular `^### Procedure ` addition under an existing
  Part 7 tier-equivalent location; no new invariant to enforce.
- `README.md` — no layout-section edit. (Procedure 7 is not a new
  pack-repo file; no Repository Layout entry to add.)
- `BACKLOG.md` — no edit. BD-047 stays Open until the full phase
  lands; pack chat updates BACKLOG.md as a separate PM-chat-only
  operation after Gate E3 closes.
- `CHANGELOG.md` — no edit. Version-boundary-only per CLAUDE.md.
- `PACK-CHAT.md`, `PACK-AGENTS.md`, `QUICKSTART.md`,
  `project-template/docs/pack/PM-CHAT.md` — no edit.
- `supporting-docs/MIGRATION-v9-to-v10.md` — no edit.
- `supporting-docs/DEPENDENCIES.md`, `supporting-docs/SETUP_TEMPLATE.md`,
  `supporting-docs/AGENT_KICKOFF_TEMPLATE.md`, `supporting-docs/
  CLI-PM-SETUP.md`, `supporting-docs/TOOL-COMPARISON.md`,
  `supporting-docs/PLATFORM-SKILLS.md` — no edit.
- `maintenance-docs/V10-DESIGN.md`, `V10-IMPLEMENTATION-PLAN.md`,
  `V10-PHASE-3B-DESIGN.md`, `V10-PHASE-3B-DESIGN-v2.md`,
  `V10-PHASE-3B-PLAN.md` — no edit. (This document is a new
  sibling, not an edit.)
- `xcode-companion-templates/` — no edit.
- Any CI workflow file under `.github/` — no edit.
- Any fixture directory (none committed; v1 Part 5 strategy
  unchanged).

The Phase 3-B three commits touch exactly four file paths:

| Commit | Paths |
|---|---|
| 1 | `project-template/docs/pack/prompts/pm-chat.md` |
| 2 | `supporting-docs/SETUP-NEW.md`, `supporting-docs/SETUP-EXISTING.md` |
| 3 | `supporting-docs/METHODOLOGY.md` |

Any additional path in `git status` at any Phase 3-B commit is a
**flag back** (Part 10 flag-back #10).

---

## Part 10 — Implementer flag-back list

Conditions under which the implementer must pause and ask the user
(pack chat) before proceeding. Carries v1 Part 10 flag-backs #1–#8
forward and adds v2-specific #9–#11.

**Per-commit ordering.** Each flag-back is tagged with the commit it
applies to (C1 = Commit 1 pm-chat.md slim; C2 = Commit 2 SETUP
guides; C3 = Commit 3 Procedure 7; PRE = pre-commit planning; POST
= post-commit verification).

| # | Tag | Condition | Action |
|---|---|---|---|
| 1 | PRE | BD-047 names `scripts/validate.sh`, `scripts/test.sh`, `scripts/format.sh`; post-BD-026 the Xcode-variable anchors live in the language-specific variants. | Target the correct files per v1 Part 2. Do not "fix" BD-047 in-flight. Pack chat decides BACKLOG.md wording. [v1 Part 10 #1, unchanged] |
| 2 | C3 | `.claude/settings.json` edit specification in Procedure 7 §7.2.2 must forbid regex-rewriting JSON. | Lift v1 Part 2 §2.4 text verbatim — JSON parse-mutate-serialize is the rule; regex is forbidden. Flag back if the lifted prose fails to express the rule cleanly. [v1 Part 10 #2, mapped to C3] |
| 3 | C3 | Form M runtime `ls "$PACK/xcode-companion-templates/"` cannot be expressed in Procedure 7's prose without assuming a shell construct. | Fall back to hardcoding the four current file paths with a comment pointing at `xcode-companion-templates/` as the source of truth; flag back. [v1 Part 10 #3, mapped to C3] |
| 4 | C2+C3 | Manual-mode verbatim parity: SETUP-NEW.md § Manual fallback 5.A–5.D (Commit 2) and Procedure 7 Form code-fences (Commit 3) must be byte-identical on every shell command line. | If a phrasing reads better in one location, pick one and make the other match. Do not introduce divergent phrasings silently. [v1 Part 10 #4, mapped] |
| 5 | POST | Step-number gap (5–9) readability in SETUP-NEW. | v1 Part 6 §6.4 keeps the gap. If the gap confuses narrative flow, flag back before renumbering. [v1 Part 10 #5, unchanged] |
| 6 | C1 | pm-chat.md line count after Commit 1 exceeds the 65-line variant body tolerance OR the 220-line full-file ceiling. | Stop. Report the actual line count and the likely cause (probably under-condensed `Before pasting` list or surface-declaration block). Pack chat decides condensation strategy. [v2-new] |
| 7 | POST | Commits must land as a single logical push (3 commits in sequence) to avoid a window in which pm-chat.md points at Procedure 7 that does not yet exist. | Land Commits 1, 2, 3 in one `git push`. Do not push Commit 1 alone. If a CI hiccup forces a solo push, flag back immediately. [v2-new] |
| 8 | PRE | Brew version ranges from v1 Part 4 look wrong against current `brew info` output on the implementer's Mac. | v1 Part 4 is a 2026-04 baseline. If `brew info <tool>` returns a notably different current stable, flag back; do not silently edit the range. [v1 Part 10 #6, unchanged] |
| 9 | C3 | Procedure 7 needs to reference an artifact (e.g., a `xcode-companion-templates/` directory-structure spec) that METHODOLOGY.md does not currently carry. | Do not silently add the reference. Flag back to the pack chat before inlining. V2 design Part 8 Q9. [v2-new] |
| 10 | POST | `git log --stat` for Phase 3-B shows any file path other than the four named in Part 9. | Stop. Report the unexpected path. Pack chat decides whether scope expanded or the edit is a miss. [v2-new] |
| 11 | C3 | Procedure 7 final size is <180 or >260 lines (§5.10). | Flag back. Size outside the ±20% corridor around the ~220-line target suggests content substance changed during the lift. [v2-new] |
| 12 | C3 | `### Procedure ` grep (S3B-6) returns anything other than the 8-line expected sequence. | Stop. Report the grep output. Likely cause: heading typo, wrong H-level, or accidental Procedure 6/7 overlap. [v2-new] |
| 13 | C1 | Continuation pointer wording differs from §3.3 verbatim. | Use §3.3 verbatim. Paraphrases risk the RAG-vs-direct-read contract (Success Criterion 5 in the prompt). If the verbatim wording reads awkwardly, flag back for a pack-chat rewrite. [v2-new] |
| 14 | C3 | Gemini plan-mode line (current pm-chat.md line 24) is not present anywhere in Procedure 7 §7.0 AND not retained in Commit 1's condensed `Before pasting` list. | Per Q3 decision, the line stays in pm-chat.md. If both Commit 1 and Commit 3 drop it, kickoff loses plan-mode safety on Gemini CLI. Flag back. [v1 Part 10 #7, mapped and tightened] |
| 15 | POST | `validate-pack.py` fails between commits. | Diagnose the underlying issue (do not skip with `--no-verify`). If the failure is downstream of v2 plan edits (not introduced by this phase), report to pack chat. If the failure is caused by this phase's edits, fix before proceeding. [v2-new; reflects CLAUDE.md rule "Never skip hooks"] |

**Draft BD entry for capability-addition kickoff symmetry** (flag-
back #8 of v1 plan, carried forward unchanged — not filed):

> `BD-048 — Capability-addition discovery + install-check symmetry with kickoff`
>
> Type: TODO(version) · Status: Open · Blockers: BD-047 resolution
> Unblocks: none
> File/Symbol: `scripts/add-capability.sh`, `supporting-docs/METHODOLOGY.md` Procedure 6
> Description: `add-capability.sh` today only does trinity-placeholder
> file plumbing; it does not propose `brew install grpcio-tools` (etc.)
> when the developer adds a new dimension. Mirror the BD-047 kickoff
> auto-discovery + install-check pattern at capability-addition time.
> Implementation either extends Procedure 6 with a kickoff-style
> variant or adds a new `Variant: capability-added-kickoff` to
> `docs/pack/prompts/pm-chat.md`.
> Context: Identified during BD-047 Phase 3-B planning (2026-04).
> Deferred out of v10.0 scope per V10-PHASE-3B-DESIGN.md Part 14 /
> V10-PHASE-3B-PLAN.md Q14-5.

---

## Part 11 — Parity checks

Two parity checks run at Gate E3 (Part 7 criterion #5 and #12).
Specification here for the implementer's self-check before
requesting Gate E3 review.

### 11.1 Procedure 7 Forms ↔ SETUP-NEW.md § Manual fallback — command-set parity

For each Form (R / I / E / M) sub-section in Procedure 7, identify
the command lines the Form would execute if approved. For each
Manual-fallback sub-section (5.A / 5.B / 5.C / 5.D) in SETUP-NEW.md,
identify the command lines the developer is instructed to run.

The two command sets must agree on every line, per the table:

| Procedure 7 sub-section | SETUP-NEW.md Manual fallback sub-section | Command-set parity expected on |
|---|---|---|
| §7.1 Form R — Apple discovery (lines 1–3) | 5.A intro | `xcodebuild -list`; `xcrun simctl list devices available` |
| §7.1 Form R — environment / brew (line 7) | — | Informational only — manual-fallback developer runs brew ad hoc |
| §7.2.3 Form I — swift-format | 5.B | `brew install swift-format` |
| §7.3.1 Form I — Apple-side gRPC tooling | 5.C Apple | `brew install bufbuild/buf/buf`; `brew install swift-protobuf`; `brew install grpc-swift` |
| §7.3.2 Form I — Python-side gRPC tooling | 5.C Python | `uv add grpcio-tools grpcio grpcio-status grpcio-reflection` |
| §7.2.4 Form M — Xcode companion files | 5.D | Four `cp` invocations under `~/Library/Developer/Xcode/CodingAssistant/` |

Disagreement on any row indicates one side drifted — resolve before
Gate E3 signs off. (v1 plan Part 10 flag-back #4 covers this in
flag-back form; this table is its verification expression.)

### 11.2 Procedure 7 sub-section numbering ↔ existing METHODOLOGY.md style

Procedure 5 uses sub-procedures `#### Procedure 5.1`, `#### Procedure
5.2`, … `#### Procedure 5.6` at H4 level (METHODOLOGY.md lines
964–1046). Procedure 7 sub-sections use `#### 7.0`, `#### 7.1`, …,
`#### 7.7` — NUMBERED, not prefixed with "Procedure." This mirrors
Part-structure convention (Part 1, Part 2, …) rather than nested-
Procedure convention.

**Rationale for divergence from Procedure 5 style.** Procedure 5's
sub-procedures are each a standalone procedure (creating a custom
agent is one procedure; creating a custom skill is another).
Procedure 7's sub-sections (K1 / K2 / K3 / Behavior on failure /
Reply grammar / Idempotency / Artifacts) are **steps within one
procedure**, not independent procedures. Numbered steps match the
semantic better than nested-procedure labels.

If the implementer finds a reviewer pushes back on this style
divergence, flag back (Part 10 flag-back #12 applies — the H-level
and numbering choice can be reconsidered at pack-chat discretion).

### 11.3 G7 gate-label consistency with G6 precedent

Procedure 6 annotates its two gates inline in table cells:
`**G6-drafts**`, `**G6-commit**` (METHODOLOGY.md lines 1111, 1113,
1119, 1122). Procedure 7 annotates its four gates inline in H5
sub-section headings: `(Form E, G7-edit)`, `(Form I, G7-install)`,
`(Form M, G7-machine)`, `(Form R, G7-discovery)`.

The two patterns differ in **location** (cell vs. heading) because
Procedure 6 is table-driven and Procedure 7 is prose-driven. They
match in **intent** — each gate has one unique label; the label is
visible at the gate point; the label follows `G<procedure#>-<verb>`.

If a reviewer flags the location divergence as inconsistency, the
implementer points at the table-vs-prose shape difference as the
driver. Flag back if the reviewer is unpersuaded.

---

## Part 12 — BD-047 field-by-field closure mapping (v2 commit shape)

Remapped from v1 plan Part 11 for the three-commit shape. Every
BD-047 description clause is covered.

| # | BD-047 clause | Closure under v2 |
|---|---|---|
| 1 | "auto-discovers Xcode scheme / simulator values (via `xcodebuild -list` and `xcrun simctl list devices available`)" | Commit 3 Procedure 7 §7.1 Form R + §7.2.1 parsing |
| 2 | "detects missing brew tools (swift-format, buf, swift-protobuf, grpc-swift)" | Commit 3 Procedure 7 §7.1 Form R + §7.2.3 / §7.3.1 Form I per tool |
| 3 | "prompts for `brew install` with developer approval" | Commit 3 Procedure 7 §7.2.3 / §7.3.1 / §7.3.2 Form I, default `skip`, G7-install gate |
| 4 | "edits `scripts/validate.sh`, `scripts/test.sh`, `.claude/settings.json`, and `scripts/format.sh`" | Commit 3 Procedure 7 §7.2.2 Form E. Correction: targets `validate-swift.sh`, `test-swift.sh`, `format-swift.sh` per v1 Part 2 §2.1. Flag-back #1 |
| 5 | "handles Xcode companion files (machine-level `cp` with confirmation)" | Commit 3 Procedure 7 §7.2.4 Form M, G7-machine gate |
| 6 | "Shell-out-capability detection" | Commit 1 surface-declaration Q/A block (retained) + Commit 1 continuation pointer's `manual` branch + Commit 2 SETUP-NEW.md § Manual fallback |
| 7 | "SETUP-NEW.md and SETUP-EXISTING.md Steps 5–6 change to 'PM chat handles this during kickoff' with a manual-alternative fallback section" | Commit 2 — scope expanded to SETUP-NEW Steps 5–8 per v1 Part 6 §6.4 |
| 8 | "Principle: Developer is the decision-maker" | Commit 3 Procedure 7 §7.1–§7.4 — every write is behind Form R/I/E/M with default `skip` |
| 9 | "Phase 3-B scope outline step 1 — planner/architect pass designing auto-discovery flow" | **This document** + V10-PHASE-3B-DESIGN.md + V10-PHASE-3B-DESIGN-v2.md + V10-PHASE-3B-PLAN.md |
| 10 | "Phase 3-B scope outline step 2 — enhance `docs/pack/prompts/pm-chat.md` Variant: kickoff with auto-discovery + install-check segment" | Commit 1 (slim + pointer) + Commit 3 (procedure body). The "enhancement" is now two-part: pointer in variant, body in Procedure 7. |
| 11 | "Phase 3-B scope outline step 3 — update SETUP-NEW and SETUP-EXISTING Steps 5–6" | Commit 2 |
| 12 | "Phase 3-B scope outline step 4 — shell-out-capability detection logic with documented fallback path" | Commit 1 (surface declaration + pointer) + Commit 2 (§ Manual fallback as the documented fallback path) |

All twelve clauses close. No clauses remain open.

---

## Part 13 — Implementation sequence (ordered steps with gates)

1. **Pre-commit planning checkpoint.** Implementer reads this plan +
   V2 design + v1 plan required sections (Part 2 for Form E; Part 3
   for idempotency; Part 4 for brew ranges). Implementer reads
   current unstaged pm-chat.md to confirm the line ranges in §3.1.
2. **Commit 1 draft.** Apply the deletion list (§3.1) + condensation
   (§3.2) + continuation pointer (§3.3) per the edit procedure
   (§3.4).
3. **Commit 1 verification.** Run §3.5 checklist. **APPROVAL GATE:
   user confirms Commit 1 diff before staging.**
4. **Commit 1 landed (local, unpushed).**
5. **Commit 2 draft.** Apply v1 Part 7 Commit 2 spec (Part 4 of this
   plan references). Byte-parity between the Manual fallback command
   lines and the current SETUP-NEW Steps 5–8 command lines.
6. **Commit 2 verification.** Run Part 4 verification bullets.
   **APPROVAL GATE: user confirms Commit 2 diff before staging.**
7. **Commit 2 landed (local, unpushed).**
8. **Commit 3 draft.** Insert Procedure 7 after METHODOLOGY.md line
   1134 per §5.1–§5.9. Lift Forms verbatim; assemble §7.6 from v1
   Part 3. Wire gate labels per §5.3.
9. **Commit 3 verification.** Run §5.10 checklist + run all six
   sweeps (Part 6). **APPROVAL GATE: user confirms Commit 3 diff
   before staging.**
10. **Commit 3 landed (local, unpushed).**
11. **Gate E3 self-review.** Implementer runs Part 7 checklist end-
    to-end. Any failure opens a `fix:` commit or a flag-back per
    Part 10.
12. **Push.** Single `git push` with all three commits (flag-back
    #7 constraint). `Validate Pack` CI runs on push; must pass.
13. **Gate E3 approval.** Pack chat reviews and approves.

---

## Part 14 — Risks (open)

- **RAG-vs-direct-read contract adherence.** The PM chat's actual
  behavior on `shell` declaration depends on the PM chat reading the
  continuation pointer literally. If a PM-chat surface (Claude Web,
  ChatGPT Web) paraphrases the pointer internally, the "not via RAG"
  clause may be lost. Mitigation: the §3.3 wording names the
  contract explicitly; a first-real-project test on Claude Code CLI
  (the RAG-capable surface) is the primary smoke. Deferred risk to
  Phase 4 if no smoke fits in Gate E3.
- **Procedure 7 lift drifting from kickoff-variant intent.** The
  verbatim lifts preserve semantics, but sub-section renumbering
  (K2.2 → §7.2.2 etc.) and gate-label additions could introduce
  phrasing drift. Mitigation: Part 11 §11.1 parity check + §5.10
  verification.
- **Commit 2 Manual-fallback diverging from the current Steps 5–8
  content.** If the implementer "improves" wording during Commit 2
  rather than lifting verbatim, Part 11 §11.1 byte-parity breaks.
  Mitigation: v1 Part 7 Commit 2 spec + flag-back #4.
- **Stale cross-references surviving the sweep.** S3B-1/S3B-2 may
  miss references hidden in unusual locations (e.g., a comment
  block in a script). Mitigation: sanctioned-residuals list is
  explicit; residuals outside the list trigger flag-back #10.
- **CI pass-rate on split commits.** `validate-pack.py` passes after
  each commit per v1 Part 8 criterion. v2 adds a third commit; flag-
  back #15 handles failures between commits.

---

*End of V10-PHASE-3B-PLAN-v2.md.*
