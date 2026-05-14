---
title: ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2
author: primary-chat (v11-dev) integration architect
status: design — bundles 5 user-Pack-Chat-decided items (1 BLOCKER + 4 SHOULD-FIX) on Addendum #1
parent: maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md (Addendum #1; 2,050 lines)
grandparent: maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md (original integration architect doc; 3,477 lines)
prior-pipeline: sidecar parent + addendum + two primary-chat reviewer passes + Addendum #1 + Addendum #1 reviewer pass
audience: primary-chat reviewer (next), then primary-chat planner
date: 2026-05-14
---

# Per-entry split — integration architecture Addendum #2

This Addendum #2 bundles 5 items decided in user-Pack-Chat
discussion following the reviewer pass on Addendum #1
(`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md`,
2,050 lines). Addendum #1 is NOT edited; this Addendum #2
corrects + supersedes specific sections of Addendum #1
(parallel to the sidecar's addendum-of-addendum supersession
pattern; preserves iteration history).

## §0 — TL;DR + 5-item disposition table + verify-by-`ls` summary

### §0.1 — Headlines

**One BLOCKER (Item 1).** Codex pack-* agent file extension
errors in Addendum #1 §1.4 / §6.2 BD-167b / §6.5 commit 19b-PM
/ §11.1 §18.2 — Codex agent files are `.toml`, not `.md`.
Verified by `ls`. Correction restated explicitly per the
Addendum #1 §3.2 friction-correction pattern. Sweep also
surfaced TWO ADDITIONAL `.codex/.../*.md` errors (auditor
agent path in original integration doc + Addendum #1; generic
`.codex/agents/*.md` claim in original §1.1) — corrected here.
NO error in `.codex/skills/.../SKILL.md` references — Codex
SKILLs ARE `.md` files; only Codex AGENTs are `.toml`.

**Four SHOULD-FIX.** Item 2 drops the body-field back-pointer
introduced in Addendum #1 §1.2 (it violated sidecar parent's
byte-additive invariant); Layer 2 reverts to the original
HTML-comment back-pointer only. Item 3 corrects EXECUTION-PLAN
line 282 totals arithmetic and provides exact replacement text.
Item 4 bridges the regenerator divergence-handling path to
BD-095's `--dry-run`/`--apply`/`--resume` two-phase contract
(replaces "stderr warning + proceed" with "dry-run reports +
apply blocks + `--force-overwrite-mirror` flag for explicit
acknowledgement"). Item 5 provides the exact PACK-CHAT.md row
spec previously deferred to Pack Chat.

### §0.2 — Item disposition table

| Item | Priority | Topic | Disposition | This addendum § |
|---|---|---|---|---|
| 1 | BLOCKER | Codex agent file extension correction (`.toml` not `.md`); sweep surfaces 2 more `.codex/.../*.md` errors | DESIGN — corrects Addendum #1 §1.4 + §6.2 + §6.5 + §11.1 + original §1.1 + original §4.4.3 | §1 |
| 2 | SHOULD-FIX 1 | Drop body-field back-pointer from Layer 2 entirely; Layer 2 = HTML-comment line 1 only | DESIGN — supersedes Addendum #1 §1.2 + §1.5 partial revert | §2 |
| 3 | SHOULD-FIX 2 | EXECUTION-PLAN-V11.0.md line 282 totals arithmetic — exact replacement text "26 main batches (24 + Batch 5b + Batch 21b)" | DESIGN — supersedes Addendum #1 §2.4 row 4 | §3 |
| 4 | SHOULD-FIX 3 | Bridge regenerator divergence path to BD-095 two-phase contract (dry-run reports + apply blocks unless `--force-overwrite-mirror`) | DESIGN — supersedes Addendum #1 §4.5 + §5.3 routing | §4 |
| 5 | SHOULD-FIX 4 | PACK-CHAT.md row exact spec — fills the "How to access / Why" columns | DESIGN — completes Addendum #1 §6.3 BD-169b spec | §5 |

### §0.3 — verify-by-`ls` discipline summary

This iteration is the THIRD where path-fact errors slipped
through prior architect+reviewer passes (Batch 18 collision in
the original integration architect doc; audit-methodology path
error caught in Addendum #1 §7; now Codex extension errors
caught in Addendum #1 §1.4 / §6.2 / §6.5 / §11.1 + original
§4.4.3). Per the PROCESS SAFEGUARD, every file path enumerated
in this Addendum #2 was directly verified via `ls` against the
file system before write.

The verification record is enumerated in §6 below (the
verify-by-`ls` discipline applied section). All 5 items + the
2 additional findings beyond Item 1 are grounded in directly-
observed file system state, not inference.

### §0.4 — Architect-pass discipline preserved

This Addendum #2 holds the same discipline as Addendum #1 and
the original integration architect doc:
- No edits to PM-only files (BACKLOG / CHANGELOG / README /
  PACK-CHAT / PACK-AGENTS / CLAUDE / AGENTS / GEMINI /
  EXECUTION-PLAN-V11.0 / RELEASE-GATE / V3.x corpus). All
  required PM-only edits surfaced as edit specifications for
  Pack Chat to apply.
- No edits to pack-product files (project-template/,
  supporting-docs/, scripts/). All required pack-product edits
  surfaced as planner / coder work.
- No edits to Addendum #1, the original integration architect
  doc, the sidecar design corpus, or any prior reviewer doc.
- No v10 entry-format grammar changes (V3.1-DELTA §3 A2
  invariant preserved — Item 2 explicitly REMOVES Addendum
  #1 §1.2's body-field upgrade because it violated the
  invariant).


---

## §1 — Item 1 (BLOCKER): Codex agent file extension correction + sweep findings

### §1.1 — Verified-by-`ls` reality

Direct `ls` against `.codex/agents/`:

```
$ ls -la /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.codex/agents/
-rw-r--r--  pack-architect.toml
-rw-r--r--  pack-coder.toml
-rw-r--r--  pack-docs-researcher.toml
-rw-r--r--  pack-planner.toml
-rw-r--r--  pack-reviewer.toml
```

Direct `ls` against `.claude/agents/` (correct in Addendum #1):
all five `pack-*.md` files exist. Direct `ls` against
`.gemini/agents/` (correct in Addendum #1): all five `pack-*.md`
files exist.

**Verified format convention by CLI:** Codex agents are `.toml`,
Claude agents are `.md`, Gemini agents are `.md`. (This is
already documented in `PACK-AGENTS.md:174-176` per
"Agent files: `.claude/agents/` (markdown), `.codex/agents/`
(TOML), `.gemini/agents/` (markdown with YAML frontmatter)" —
which Addendum #1 §1.4 missed.)

**Same convention for project-template agents:** verified by
`ls` against `project-template/.codex/agents/`:
all 16 project-template Codex agent files are `.toml` (architect,
auditor, auditor-architecture, auditor-code, auditor-docs,
auditor-ops, auditor-security, auditor-tests, auditor-ui,
coder, docs-researcher, grpc-schema, planner, repo-ops,
reviewer, tester) — all `.toml`.

### §1.2 — Correction (verbatim acknowledgement, parallel to Addendum #1 §3.2 friction-correction pattern)

> **Correction.** Addendum #1 §1.4 / §6.2 BD-167b / §6.5 commit
> 19b-PM / §11.1 §18.2 enumerated `.codex/agents/pack-*.md` for
> the five pack-* agent prompt cascade target files. Actual
> files are `.codex/agents/pack-*.toml`. Cited correctly herein.
> The `.claude/agents/pack-*.md` and `.gemini/agents/pack-*.md`
> references in those same sections are factually correct and
> remain unchanged. Per `PACK-AGENTS.md:174-176`: Codex agent
> files are TOML; Claude and Gemini agent files are Markdown.

### §1.3 — Corrected pack-* agent file list (replaces Addendum #1 §1.4 enumeration)

Pack-side per-CLI agent files (15 files total — 5 agents × 3
CLIs) that gain a `_rules.md` reference under Layer 4 of the
Item 1 discoverability cascade in Addendum #1 §1.4:

```
.claude/agents/pack-architect.md
.claude/agents/pack-coder.md
.claude/agents/pack-docs-researcher.md
.claude/agents/pack-planner.md
.claude/agents/pack-reviewer.md

.codex/agents/pack-architect.toml
.codex/agents/pack-coder.toml
.codex/agents/pack-docs-researcher.toml
.codex/agents/pack-planner.toml
.codex/agents/pack-reviewer.toml

.gemini/agents/pack-architect.md
.gemini/agents/pack-coder.md
.gemini/agents/pack-docs-researcher.md
.gemini/agents/pack-planner.md
.gemini/agents/pack-reviewer.md
```

Each path verified individually by `ls`; all 15 exist as
listed.

### §1.4 — Format note for the planner / coder

The Codex `.toml` format places agent prompt content inside a
TOML-string field (typically `prompt = """..."""` per the
Codex agent file convention). The "Inputs to read" block
addition under Layer 4 of the Item 1 discoverability cascade
must be authored as a TOML-string-safe block in `.codex/agents/pack-*.toml`
files. Concretely: triple-quoted multi-line TOML strings with
no embedded triple-quote sequences. Planner / coder pass
verifies the existing `prompt = """...""" ` shape in each Codex
file and inserts the `_rules.md` reference inside that string.

The `.claude/agents/pack-*.md` and `.gemini/agents/pack-*.md`
files are plain Markdown; the addition lands as a Markdown
bullet in the existing "Inputs to read" / "Before making any
design recommendation, read:" block.

**Trinity rule applies:** the substantive content of the
addition is identical across all three CLI flavors (per the
existing trinity discipline). The format-specific wrapping
(TOML string vs Markdown bullet) is the only per-CLI
difference.

### §1.5 — Sweep findings beyond Item 1

Per the PROCESS SAFEGUARD instruction, the integration
architect grepped Addendum #1 + the original integration
architect doc for `.codex/.../*.md` references that might
share the same extension-error class. The initial sweep
surfaced two findings (2A, 2B); Reviewer Pass #3 follow-up #2
identified three additional sites in the original integration
architect doc (Finding 2C) that share Finding 2A's class. Full
enumeration:

**Finding 2A — Original integration architect doc §4.4.3 + Addendum #1 §6.3 BD-169 File/Symbol auditor agent path error.**

Original line 972 (paraphrased; verbatim text in the original
integration architect doc):

> "auditor.md (and trinity mirrors at .codex/agents/auditor.md,
> .gemini/agents/auditor.md)"

Addendum #1 §6.3 BD-169 File/Symbol carries this forward
(Addendum #1 line 1149 verbatim):

> "`project-template/.codex/agents/auditor.md`,
> `project-template/.gemini/agents/auditor.md`"

Verified by `ls` against `project-template/.codex/agents/auditor.toml`:
EXISTS. The `.codex` reference must be `.toml`.

**Correction text (parallel to §1.2 above):**

> Original §4.4.3 + Addendum #1 §6.3 BD-169 File/Symbol's
> reference to `.codex/agents/auditor.md` is wrong; correct
> path is `.codex/agents/auditor.toml`. Verified by `ls`. The
> `.gemini/agents/auditor.md` reference is correct
> (verified). The project-template auditor agent edit list
> for BD-169 is:
>
> - `project-template/.claude/agents/auditor.md`
> - `project-template/.codex/agents/auditor.toml`
> - `project-template/.gemini/agents/auditor.md`

**Finding 2B — Original integration architect doc §1.1 generic
claim `.codex/agents/*.md`.**

Original line 252 (verbatim):

> "Plus per-CLI trinity mirrors in `.codex/agents/` and
> `.gemini/agents/`"

Following text "and the project-side coder / repo-ops / auditor
/ auditor-docs agent files × 3 CLIs" with `.codex/agents/*.md`
implied.

**Correction text:**

> Original §1.1 generic claim "agent files × 3 CLIs" implied
> `.md` extension for all three. Codex agent files are `.toml`
> per `PACK-AGENTS.md:174-176`. Per-CLI mirror enumeration
> across all per-CLI agent file references in the original
> integration architect doc and Addendum #1 must use:
> Claude → `.md`, Codex → `.toml`, Gemini → `.md`.

**Finding 2C — Three additional auditor.md sites in original integration architect doc with implicit per-CLI mirror expansion.**

The Finding 2A correction surfaced one auditor.md path
(original line 972) but the sweep was incomplete — three
additional sites in the original integration architect doc
mention `auditor.md` in connection with "per-CLI mirrors" or
"trinity mirrors," and all three share Finding 2A's class
(when expanded to Codex, the path becomes `.toml`):

> - **Original §1.1, line 263 (verbatim):**
>   `(project-template/.claude/agents/auditor.md and per-CLI mirrors).`
>   The Claude path is correct (`.md`); the implicit per-CLI
>   mirror expansion must use `.codex/agents/auditor.toml` and
>   `.gemini/agents/auditor.md`.
>
> - **Original §4.4.1, line 882 (verbatim fragment):**
>   `repo-ops.md:66-67`, `auditor.md:42`,
>   followed on line 883 by `and per-CLI mirrors`.
>   The bare `auditor.md:42` line reference is Claude-side and
>   correct as-is. The implicit per-CLI mirror expansion must
>   use `auditor.toml` for Codex and `auditor.md` for Gemini
>   (line numbers are Claude-source; per-CLI mirrors are
>   regenerated and may carry different line numbers — coder
>   pass resolves the equivalent location in each mirror).
>
> - **Original §4.4.3, line 912 (verbatim fragment):**
>   `audit-methodology references in
>   project-template/.claude/agents/auditor.md (and trinity mirrors)`.
>   The Claude path is correct (`.md`); the implicit trinity
>   mirror expansion must use `.codex/agents/auditor.toml` and
>   `.gemini/agents/auditor.md`.

**Correction text (parallel to Finding 2A):**

> All three sites in original §1.1 / §4.4.1 / §4.4.3 share the
> same per-CLI extension convention as Finding 2A. The textual
> phrases "per-CLI mirrors" and "trinity mirrors" must be read
> by planner / coder as expanding to: Claude → `.md`, Codex →
> `.toml`, Gemini → `.md`. No new path-naming cascade beyond
> Finding 2A's extension correction.

**Sweep verification — `.codex/skills/.../SKILL.md` references:**

The sweep also surfaced multiple `.codex/skills/*/SKILL.md`
references in the original integration architect doc (lines
244, 247, 862, 943) and Addendum #1 (lines 190, 201, 1159,
1163, 1346, 1364, 1370, 1384). Direct `ls` verification:

```
$ ls -la /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.codex/skills/pack-startup/
SKILL.md (4228 bytes)
```

```
$ ls -la /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/.codex/skills/pm-startup/
SKILL.md (12408 bytes)
```

**`.codex/skills/.../SKILL.md` is CORRECT.** Codex SKILL files
ARE Markdown (`.md`) — only Codex AGENT files are TOML. This
distinction matches the existing pack convention (per
`README.md:101-104` skill distribution shape: skills are
copied from `project-template/skills/` — which is Markdown
canonical — to `.claude/skills/`, `.codex/skills/`,
`.gemini/skills/` retaining the Markdown shape).

No correction needed for any `.codex/skills/.../SKILL.md`
reference in the original or Addendum #1.

### §1.6 — Cascade impact (this Item)

Affected Addendum #1 sections:
- **Addendum #1 §1.4 Layer 4 file enumeration** — corrected
  per §1.3 above (5 Codex files become `.toml`; the 10 Claude
  + Gemini files unchanged).
- **Addendum #1 §6.2 BD-167b File/Symbol** — pack-* agent
  prompt edits × 15 files: the 5 Codex paths use `.toml`.
- **Addendum #1 §6.5 commit 19b-PM** — same correction
  applies to the commit-message file list.
- **Addendum #1 §11.1 §18.2 row** — coder items list pack-*
  agent prompt edits include the 5 Codex `.toml` paths.

Affected original integration architect doc sections (per
§1.5 sweep findings):
- **Original §1.1, line 252** (Finding 2B) — generic claim
  "agent files × 3 CLIs" must be read with the corrected
  per-CLI extension convention.
- **Original §1.1, line 263** (Finding 2C) — explicit
  `project-template/.claude/agents/auditor.md` + "per-CLI
  mirrors": Codex mirror is `.toml`.
- **Original §4.4.1, line 882** (Finding 2C) — bare
  `auditor.md:42` is Claude-side (correct); "per-CLI mirrors"
  expansion uses `.toml` for Codex.
- **Original §4.4.3, line 912** (Finding 2C) — `audit-
  methodology` references in `project-template/.claude/agents/auditor.md`
  + "trinity mirrors": Codex mirror is `.toml`.
- **Original §4.4.3, line 972** (Finding 2A) — auditor agent
  file edits × 3 CLIs: the Codex path is `.toml`.

Affected Addendum #1 sections (per §1.5 Finding 2A):
- **Addendum #1 §6.3 BD-169 File/Symbol** — auditor agent
  file extensions × 3 CLIs: the Codex path is `.toml`.

No path-naming cascade beyond extension correction; no
contract change; no scope change. The Item 1 correction is
mechanical at every affected site.


---

## §2 — Item 2 (SHOULD-FIX 1): drop body-field back-pointer entirely

**Supersedes Addendum #1 §1.2** (entire section RETIRED) and
partially supersedes Addendum #1 §1.5 cascade impact for Layer 2.

### §2.1 — The byte-additive invariant violation

Sidecar parent `ARCHITECTURE-PER-ENTRY-SPLIT.md:248-256`
(verbatim, per the sidecar parent's stated entry-content
contract):

> "Per-entry contents. A single per-entry file contains exactly
> one v10-grammar entry. The bold-header line is the H1-equivalent
> (it is not an H1 — it is the v10 bold header per V3.1-DELTA §3
> A2), then the field labels (`Type:`, `Status:`, etc.), then the
> `Description:` body, then `Resolved:` if Status=Resolved. No
> `---` separator at the top or bottom of the file — the file
> boundary is the separator. **This is byte-additive on entry
> format: the file content from `**BD-NNN —` through the last
> narrative line of the entry is byte-identical to the
> corresponding span in the legacy monolithic `BACKLOG.md`.**"

(Emphasis added.)

Addendum #1 §1.2 introduced a NEW first body field
(`Stream contract:`) on every per-entry file as a Layer 2
upgrade. This violated the bolded sentence above: a `Stream
contract:` field between the bold-header and `Type:` is content
that does NOT exist in the legacy monolithic — it is byte-
additive on the FILE (sidecar parent §3.1 says the file content
includes the back-pointer comment line at line 1, which lives
ABOVE the bold-header start anchor — so the line-1 HTML comment
is FINE because it does NOT live inside the byte-identical span)
but it is NOT byte-identical on the SPAN starting at
`**BD-NNN —`.

The reviewer correctly flagged this. The user-Pack-Chat call:
**drop the body-field upgrade entirely.**

### §2.2 — Decision: Layer 2 reverts to HTML-comment line 1 only

Layer 2 returns to the original integration architect doc §4.2
Layer 2 shape (HTML-comment back-pointer at line 1 of every
per-entry file, ABOVE the bold-header):

```
<!-- per-entry source: /backlog/BD-NNN.md; contract: /backlog/_rules.md -->
**BD-NNN — Title**
Type: TODO(version)
Status: Open
...
```

The line-1 HTML comment lives ABOVE the byte-identical span
(which starts at `**BD-NNN —`). The comment is byte-additive on
the FILE; the span from `**BD-NNN —` onward is byte-identical
to the legacy monolithic. Sidecar parent's invariant
PRESERVED.

(Path uses post-Item-10 non-dot form per Addendum #1 §10
REDESIGN-CORE #2.)

### §2.3 — Rationale for accepting Layer 2 as line-1-only

Addendum #1 §1.2 motivated the body-field upgrade by claiming
"offset-read fragility": an agent reading per-entry content with
a non-zero `Read` `offset` parameter would miss the line-1 HTML
comment.

**Re-evaluating the offset-read scenario:**

- **First-read recovery (the load-bearing case):** an agent that
  has NEVER seen the per-entry file before reads it via Read
  with no offset; line 1 is hit; the HTML-comment back-pointer
  fires; the agent has the contract resolution path. Layer 2
  works.

- **Subsequent-offset-read (the theoretical case Addendum #1
  worried about):** an agent that reads a previously-known
  per-entry file with `Read` `offset=30` to get the
  Description body. By definition this agent ALREADY has prior
  context on the file — it knows the file's path (because it
  passed the path to Read), it knows where to skip to (offset
  30), it has resolved the contract before (the prior
  full-file read populated context). The "fragility" is
  theoretical because the agent in the offset-read path is the
  same agent that previously had the line-1 comment in
  context.

- **Sub-agent isolation:** an agent invoked as a sub-agent
  (which loses parent-session context) might read a per-entry
  file in isolation. Layer 4 (Addendum #1 §1.4 — pack-* agent
  prompt `_rules.md` references) is the realistic protection
  for this case: the sub-agent's prompt loads the contract
  resolution path before any per-entry read.

- **Chunked-read of long Descriptions:** Description bodies in
  per-entry files are typically 5–20 lines (per the v10 entry
  grammar shape). Chunking is rare for entry bodies; when it
  happens, the first chunk includes line 1 (the chunk starts
  at offset 0 by default unless the agent explicitly skips).

**Conclusion:** the offset-read fragility was a theoretical
concern with no realistic failure path. Dropping the body-field
upgrade simplifies the design, preserves the byte-additive
invariant, and avoids tracker-integration scope creep (per §2.4
below).

### §2.4 — Bonus: avoids tracker-integration scope creep

Addendum #1 §1.2 introduced a NEW first body field on every
per-entry file. The flat ↔ tracker contract (sidecar addendum
§4 + original integration architect doc §2.4) requires byte-
identity round-trip for every body field that survives the
contract. Adding a new body field would have required:

- Forward-emit handling (`tmf_compose_issue_body` per
  `tracker-migrate-forward.sh:459`): emit `Stream contract:` to
  tracker issue body, OR strip it before emitting.
- Reverse-emit handling (`_tmr_emit_backlog` per
  `tracker-migrate-reverse.sh:409` etc.): re-introduce
  `Stream contract:` on reverse with the correct path value.
- Round-trip byte-identity verification: the field must survive
  forward → reverse → forward without drift.

Addendum #1 §1.2 did NOT address any of these. Item 2
explicitly observes the scope-creep was avoided by the drop.

**Document this absence explicitly so future readers don't
rediscover the question:** the Layer 2 HTML-comment back-pointer
is stripped by the mirror generator (per original §4.2 Layer 2
spec) when emitting per-entry content into the regenerated
monolithic mirror; the comment lives ONLY on the per-entry file
on disk; tracker forward / reverse never sees it (the comment is
stripped at the mirror-generation step, and tracker forward
reads the mirror, not the per-entry file directly per sidecar
§8.1). NO new tracker contract surface.

### §2.5 — Cascade impact (this Item)

**Addendum #1 §1.2 (entire section)** — RETIRED. Replace with a
one-paragraph "DROPPED — superseded by Addendum #2 §2; Layer 2
reverts to HTML-comment line 1 only" pointer. (Pack Chat does
NOT edit Addendum #1 — the Addendum #2 supersession is
authoritative; future readers see the Addendum #1 §1.2 content
and the Addendum #2 §2 supersession in the same way they see
all other supersessions.)

**Addendum #1 §1.5 cascade impact entry for Layer 2 (UPGRADED
by §1.2 above)** — reverts. Layer 2 cascade is now: HTML-comment
back-pointer added by decompose step (per original integration
architect doc §4.2); stripped by mirror generator at emit (per
original §4.2). NO body-field changes; NO new entry-format
content.

**Addendum #1 §11.1 cascade audit row for original §4.2** —
update Item 1 effect from "Layer 2 upgraded with body-field
back-pointer" to "Layer 2 unchanged from original §4.2 (HTML-
comment back-pointer at line 1 only)".

**Addendum #1 §11 (Item 1 grand cascade)** — Layer 2 entry
removes the byte-additive note about Field-Name: value shape
(no longer applicable).

**Original integration architect doc §4.2 Layer 2** — UNCHANGED.
The original spec (HTML-comment line 1) is the final design.

**Original integration architect doc §17.2 BD-164 File/Symbol /
§17.2 BD-167 File/Symbol** — UNCHANGED in this Item 2's scope.
The HTML-comment add/strip mechanism (per original §18.2 #3
coder item) is preserved; no body-field add/strip needed.

**Original integration architect doc §18.2 coder items #3** —
"Per-entry HTML-comment back-pointer add/strip (BD-164 +
BD-165)": the body-field add/strip clause from Addendum #1
implicitly added to this item is REMOVED. Coder item #3 reverts
to the original integration architect doc text (HTML-comment
add/strip only).

**Tracker integration impact (sidecar addendum §4 + original
§2.4):** ZERO. Forward-emit, reverse-emit, round-trip byte-
identity verification all unchanged. No new tracker-contract
surface introduced or removed.


---

## §3 — Item 3 (SHOULD-FIX 2): EXECUTION-PLAN line 282 totals arithmetic fix

**Supersedes Addendum #1 §2.4 row 4 (the EXECUTION-PLAN-V11.0.md
line 282 edit specification).**

### §3.1 — The arithmetic error in Addendum #1

Addendum #1 §2.4 row 4 proposed text (verbatim from Addendum
#1):

> "Total: 26 main batches (24 + Batch 5b + Batch 21b + Batch 19
> = 27 total once per-entry split inserts; with conditional fix
> slots up to 30 main + 3 conditional)" — PRECISE wording for
> Pack Chat to refine

Three problems:
1. **Double-counts Batch 19.** "24 + ... + Batch 19" — Batch 19
   is one of the 24 numbered batches under the Item 2 renumber
   cascade (Batch 19 = NEW per-entry split; existing Batches
   19+ shift up). Counting it explicitly after "24" double-
   counts.
2. **Contradictory "26 main = 27 total" sum** — the math doesn't
   work. 26 ≠ 27.
3. **Abdicates final wording to Pack Chat** ("PRECISE wording
   for Pack Chat to refine") — violates the architect-pass
   discipline of providing exact replacement text for PM-only
   edit specifications.

### §3.2 — Correct arithmetic

Per the verified-by-grep batch enumeration (per Addendum #1
§2.1 + §2.2 verification):

**Current EXECUTION-PLAN-V11.0.md line 282 (verbatim,
re-verified by direct read):**

> "Total: 25 main batches (23 + Batch 5b for BD-135 + Batch 20b
> for BD-136 implementation) + up to 3 conditional in-session
> fix commits if audits/dog-food surface defects = max 28
> commits, plus Batch 20b internally ships 4 commits, putting
> practical max at ~31 commits."

**Math (current state, pre-Item-2 renumber):**
- 23 numbered batches (Batch 1 through Batch 23).
- + Batch 5b (one named non-numbered).
- + Batch 20b (one named non-numbered).
- = 25 main batches.
- + 3 conditional in-session fix slots (Batches 14b / 21b /
  22b).
- = 28 main + conditional commits.
- + Batch 20b internally ships 4 commits (3 extras counted
  beyond the single Batch 20b slot).
- = ~31 commits practical max.

**Math (post-Item-2 + post-Item-6 — addendum state):**
- Item 2 inserts NEW Batch 19 = +1 numbered batch slot.
- Item 2 renumber cascade pushes existing Batches 19+ up by
  one: existing 19 → 20, existing 20 → 21, existing 20b →
  21b, existing 21 → 22, existing 21b → 22b, existing 22 →
  23, existing 22b → 23b, existing 23 → 24.
- After renumber: 24 numbered batches (Batch 1 through Batch
  24).
- + Batch 5b (unchanged — pre-Batch-19 in number; not affected
  by renumber cascade).
- + Batch 21b (was Batch 20b; renumbered).
- = **26 main batches.**
- + 3 conditional in-session fix slots (Batches 14b / 22b /
  23b — per the renumbered table).
- = 29 main + conditional commits.
- + Item 6 BD-split adds NEW commit count internally to Batch
  19 (10 commits per Item 6 §6.5 vs 8 in original §17.3 vs
  Batch 20b's 4 internal commits in the current line 282
  arithmetic).
- + Batch 20b's renumber-target Batch 21b ships 4 commits (as
  before).

### §3.3 — Exact replacement text for EXECUTION-PLAN line 282

**Replaces Addendum #1 §2.4 row 4. Pack Chat applies
verbatim.**

```
**Total: 26 main batches (24 + Batch 5b for BD-135 + Batch 21b
for BD-136 implementation) + up to 3 conditional in-session fix
commits if audits/dog-food surface defects = max 29 commits,
plus Batch 21b internally ships 4 commits AND Batch 19 ships
10 commits internally per the per-entry split BD-split per
ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §17.3 + ADDENDUM
§6.5, putting practical max at ~41 commits.** Could be slightly
higher if any audit / dog-food gate needs more than one small
follow-up commit.
```

The text:
- Names "26 main batches" (24 numbered + Batch 5b + Batch 21b
  = 26).
- Names "max 29 commits" (26 main + 3 conditional).
- Names "Batch 21b internally ships 4 commits" (preserved from
  the current line 282 phrasing for Batch 20b → Batch 21b
  renumbering).
- Names "Batch 19 ships 10 commits internally" (per Item 6).
- Names "practical max at ~41 commits" — corrects the off-by-one
  in Addendum #1 §6.6's "max ~40" claim and Addendum #1 §0.2
  headline "max ~38 → max ~40" (Batch 19's 10 internal sub-commits
  add 9 extras to the running total, not 8). All three Addendum #1
  sites (§0.2 line 67, §6.6 line 1230, §11.3 line 2007 cascade
  audit) updated to ~41 in lockstep with this Item via Pack-Chat-
  direct edits.
- Names BOTH the original integration architect doc §17.3 AND
  Addendum #1 §6.5 as the references for the 10-commit
  internal-to-Batch-19 count, so future readers traceable.

### §3.4 — Cascade impact (this Item)

**Addendum #1 §2.4 row 4** — superseded by §3.3 above; Pack
Chat applies the §3.3 text verbatim instead of the Addendum #1
proposed text.

**Addendum #1 §6.6 ("Updated total v11.0 commit count")** —
arithmetic corrected from ~40 to ~41; the math confirmation in
§3.2 above ratifies the ~41 figure (Batch 19's 10 internal
sub-commits add 9 extras, not 8). Pack-Chat-direct edits
applied to Addendum #1 §0.2, §6.6, and §11.3 in lockstep with
this Item.

**Original integration architect doc §17.8 ("Total v11.0 BD
count after integration")** — unchanged in conclusion. The BD
count is unaffected by the commit-count math (BDs and commits
are different surfaces).

**EXECUTION-PLAN-V11.0.md line 282 cascade:** the line 282 edit
specification in Addendum #1 §2.4 (the row 4 entry) is the
ONLY EXECUTION-PLAN edit affected by Item 3. All other Addendum
#1 §2.4 row entries (lines 277, 279, 295, 296, 348, 349, 400,
401, 402) preserve their existing edit specs from Addendum #1.


---

## §4 — Item 4 (SHOULD-FIX 3): bridge migrator path to BD-095 two-phase contract

**Supersedes Addendum #1 §5.3 (regenerator divergence-warning
non-interactive routing) and Addendum #1 §4.5 (mitigation
flagged for the planner — pre-commit hook semantics).**

### §4.1 — Why "stderr warning + proceed" was insufficient

Addendum #1 §5.3 routed non-interactive contexts (CI, migrator)
to "stderr warning + proceed" — the regenerator detects
divergence but writes the new mirror anyway, with a stderr
warning the user may or may not notice.

The reviewer + user-Pack-Chat call: this is the highest-stakes
context. Silent overwrite of manual mirror edits during a
v10→v11 migration could drop user work the user explicitly
created. Stderr can be buffered, captured-but-uninspected in CI
logs, or simply not reviewed — none of which prevent the
overwrite.

### §4.2 — Decision: bridge to BD-095 `--dry-run`/`--apply` contract

The v10→v11 migrator already has BD-095's `--dry-run`/`--apply`/
`--resume` two-phase contract per `EXECUTION-PLAN-V11.0.md:43`:

> "BD-095 — `migrate-v10-to-v11.sh` two-phase
> `--dry-run`/`--apply`/`--resume` workflow"

Verified by `ls` against `scripts/migrate-v10-to-v11.sh` (the
dry-run / apply / resume mode wiring is at lines 47–61 in the
file's usage block; mode detection is at lines 264–272 in
`migrator-core.sh` setting `_MIGRATOR_MODE` to one of `apply`
| `dry-run` | `resume`; the `_migrator_is_dryrun` gate function
is verified in use at `migrate-v10-to-v11.sh:140`).

The integration architect's bridge: route the regenerator's
divergence-handling through the same two-phase semantics. The
regenerator is invoked from inside the migrator's
`migrator_post_dispatch_hook` (per BD-165 in original §17.2 +
Addendum #1 §6.4). Inside that hook, `_migrator_is_dryrun`
returns true for `--dry-run` mode and false for `--apply`. The
regenerator dispatches accordingly:

**Updated §5.3 specification (replaces Addendum #1 §5.3
non-interactive routing):**

- **Dry-run phase (`migrate-v10-to-v11.sh --dry-run`):** the
  regenerator detects per-entry-tree-vs-mirror divergence in
  the target tree (same diff logic as Check 32 per original
  §10.1). If divergence found: report to the user explicitly
  with file:line of divergence and the message "this divergence
  will be overwritten on `--apply` unless `--force-overwrite-mirror`
  is passed." Report goes to stdout (the dry-run report
  channel — already captured in the dry-run state per
  `_MIGRATOR_DRY_RUN` per `migrator-core.sh:109`). Exit 0
  (dry-run is informational; non-zero exit reserved for
  preflight failures).

- **Apply phase (`migrate-v10-to-v11.sh --apply`):** the
  regenerator BLOCKS on divergence with non-zero exit (use
  the framework's existing `fail_stage` per
  `migrate-v10-to-v11.sh:198, 213` shape, OR a new typed
  error code in the migrator-core exit-code table — planner
  picks). Exit code lands in the framework's existing
  `EXIT_GATE_FAILED=31` slot or a sibling slot (per
  `BACKLOG.md:816` BD-101 resolution narrative confirming
  the slot is assigned to gate failures; planner verifies
  exact slot assignment).

  The user must explicitly acknowledge to proceed by passing
  `--force-overwrite-mirror`. Sample usage:
  `bash scripts/migrate-v10-to-v11.sh --apply --force-overwrite-mirror`.
  Without the flag: blocks; user is told what to do.

- **Resume phase (`migrate-v10-to-v11.sh --resume`):** inherits
  the apply-phase semantics. The resume flow continues a
  paused apply; if the user reconciled the divergence between
  pause and resume, the regenerator detects no divergence and
  proceeds. If divergence remains, blocks with the same
  non-zero exit + same `--force-overwrite-mirror` instruction.

- **Documented contract (replaces Addendum #1 §5.3 "stderr
  warning + proceed"):** the migrator NEVER silently overwrites
  the mirror in `--apply` or `--resume` mode. Stderr warning
  is INSUFFICIENT because stderr can be buffered, lost, or
  unreviewed in CI/automation contexts; explicit blocking with
  exit code is the safety mechanism. The
  `--force-overwrite-mirror` flag is the explicit user
  acknowledgement.

### §4.3 — CI context (Check 32 invocation): different from migrator

The validator path (`scripts/validate-pack.py` Check 32) invokes
the regenerator differently from the migrator. Check 32 (per
original §10.1):
1. Re-runs the mirror generator against the per-entry tree to
   a temporary file.
2. Diffs the temporary file against the on-disk mirror.
3. FAILs if any difference.

Check 32 is **already non-destructive** — it never writes the
on-disk mirror; it only diffs against a temp file. No blocking
needed; the FAIL exit code from Check 32 is the existing
mechanism. Item 4's bridge does NOT apply to Check 32 (which
already has the right semantics).

The CI context for the regenerator INVOCATION (vs Check 32's
diff-only invocation) is the migrator path — the regenerator
runs inside the migrator's post-dispatch hook in CI when
testing v10→v11 migration end-to-end (per BD-128's CI repair
work + the migrator behavior-preservation harness). In the CI
migrator path, the migrator's mode is `--apply` or `--dry-run`
per the test setup; the §4.2 contract applies uniformly.

### §4.4 — Updated §4.5 specification (opt-in pre-commit hook)

Addendum #1 §4.5 flagged an optional client-side pre-commit
hook (`project-template/scripts/git-hooks/pre-commit-check32.sh`)
for the planner. The hook runs Check 32+33 locally before
allowing the commit.

**Updated §4.5 specification:** the pre-commit hook inherits
the same "block on divergence; require flag to proceed"
semantics as the apply-phase regenerator (per §4.2 above).
Sample shape: the hook detects divergence; if found, prints
the recovery instruction ("regenerate then re-stage, OR pass
`--no-verify` to bypass" — but `--no-verify` is the user's
explicit override, not a silent proceed); exits non-zero to
block the commit.

The hook is opt-in via `init-project.sh --install-pre-commit-hook`
per Addendum #1 §4.5. Inheriting the apply-phase semantics keeps
the local-time gate consistent with the migrator-time gate;
clients have one mental model for "what happens when the mirror
diverges."

### §4.5 — `--force-overwrite-mirror` flag specification

**Flag name (planner picks final; provisional architect-pass
naming):** `--force-overwrite-mirror`.

**Flag scope:** valid only in `--apply` and `--resume` modes.
In `--dry-run` mode, the flag has no effect (dry-run does not
overwrite anything; divergence is reported informationally).

**Flag behavior:** when passed, the regenerator proceeds with
the overwrite even if divergence is detected. Stderr warning
still emitted ("WARNING: --force-overwrite-mirror specified;
overwriting hand-edited mirror") for the audit trail.

**Migrator integration:** add to the BD-095 mode-flag parser
in `scripts/lib/migrator-core.sh` (lines 264–272 currently
parse `--dry-run` / `--apply` / `--resume`). Sample addition
shape (planner refines; coder authors):

```
--force-overwrite-mirror)
    _MIGRATOR_FORCE_OVERWRITE_MIRROR="1"
    shift
    ;;
```

**Default:** `_MIGRATOR_FORCE_OVERWRITE_MIRROR="0"`; the
regenerator checks the flag value; if "0" and divergence
detected and mode is apply/resume, blocks.

**Composition with BD-101 gate failure exit code:** the
divergence-block uses `EXIT_GATE_FAILED=31` (per
`scripts/lib/migrator-core.sh` exit-code table, confirmed by
BD-101 resolution narrative at `BACKLOG.md:816` adding the
slot). Planner verifies the exact slot at implementation time.

### §4.6 — Cascade impact (this Item)

**Addendum #1 §5.3 (regenerator emits divergence warning):**
Layer 2 mechanism updated. The interactive context path
(prompts the user) UNCHANGED; the non-interactive context
path is REPLACED by the §4.2 two-phase semantics. The
"interactive context" detection (TTY check or environment
variable per Addendum #1 §5.3) STILL applies for the chat /
Pack-Chat context (where the regenerator runs outside the
migrator); for the migrator-internal path, the BD-095 mode
flag (`_MIGRATOR_MODE`) is the dispatch signal.

**Addendum #1 §4.5 (mitigation flagged for planner — pre-commit
hook):** UPDATED per §4.4 above. Hook inherits the same
"block + flag-required" semantics.

**Addendum #1 §5.4 (Layer 3 explicit defense-in-depth doc):**
the dry-run-reports + apply-blocks language replaces the
"stderr warning + proceed" language in the Layer 2 description.

**Original integration architect doc §10.6 (validator behavior
on missing per-entry tree):** unchanged. Check 32's
non-destructive invocation pattern is unaffected.

**Original integration architect doc §17.2 BD-165 File/Symbol:**
GAINS the `--force-overwrite-mirror` flag-parsing addition in
the migrator-core mode-flag parser scope. Planner picks final
flag-parser placement; coder authors.

**BD-095 contract composition:** explicitly named — the
planner reads BD-095's existing `--dry-run`/`--apply`/`--resume`
contract (per `BACKLOG.md:816` BD-101 resolution narrative
+ `migrator-core.sh:264-272` mode-flag parser) and composes
the divergence-handling against it. NO redesign of BD-095;
NO new mode flag beyond `--force-overwrite-mirror`.

### §4.7 — Why bridge, not extend

The integration architect explicitly chooses to BRIDGE
(compose against the existing BD-095 contract) rather than
EXTEND (add a new mode flag or new mode dispatch). Rationale:
- BD-095's contract is ALREADY in v11.0 scope (Batch 13 per
  current EXECUTION-PLAN; renumbered Batch 13 unchanged
  pre-Batch-19 in Item 2's renumber cascade). Per-entry split
  lands in Batch 19 (renumbered). BD-095 is shipped before
  Batch 19 fires; the contract is stable.
- Adding a new mode flag would expand the BD-095 surface and
  trip maintainability signal 8 (migrator behavior change
  per `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.2 line
  301–304). Bridging composes onto the existing surface; signal
  8 conditionally tripped (per original §13.4 + Addendum #1
  §6.4) but the trip is the same conditional trip already
  acknowledged for the v11.0 decompose step.


---

## §5 — Item 5 (SHOULD-FIX 4): PACK-CHAT.md row exact spec

**Completes Addendum #1 §6.3 BD-169b File/Symbol** (the
"PACK-CHAT.md row addition in file-access strategy table
(lines 42–43) per original §4.4.3" was deferred to Pack Chat
without exact text; this Item provides the exact text).

### §5.1 — Verified table column structure

Direct read of `PACK-CHAT.md` lines 38–47 (verified by
`sed -n '38,50p'`):

```
## File access strategy

| File | How to access | Why |
|---|---|---|
| `BACKLOG.md` | Direct read | Open BD-NNN items, current backlog state |
| `CHANGELOG.md` | Direct read (last entry only) | Current version and recent changes |
| `README.md` | Direct read (version table section) | Pack version history at a glance |
| `supporting-docs/METHODOLOGY.md` | Direct read (on demand) | Author of this file — read directly when needed |
| `project-template/docs/pack/prompts/*.md` | Direct read (on demand) | Author of this set of files — read directly when needed |
```

Three columns: `File` | `How to access` | `Why`. Each row is a
file path (column 1) + access strategy (column 2) + intent /
context note (column 3).

**No surprises in the table structure.** The proposed row content
fits the existing 3-column shape.

### §5.2 — Exact row text (replaces Addendum #1 §6.3 BD-169b deferral)

Pack Chat applies VERBATIM. Two new rows extend the existing
file-access strategy table — one for the per-entry tree
read-target capability, one for the entry-source-of-truth
discoverability per Goal 2:

```
| `/backlog/<ID>.md`, `/changelog/<ID>.md` (per-entry source) | Direct read of single entry when only that entry is needed | Per-entry tree is source of truth in flat-file mode (per CLAUDE.md pack-memory + `<stream>/_rules.md`); smaller token footprint than mirror for one-entry edits |
| `/backlog/_rules.md`, `/changelog/_rules.md` (per-stream contracts) | Direct read at session start (or on per-entry-tree-aware operation) | Per-stream contract authority — filename regex, lifecycle states admitted, supporting-file basenames admitted, write-authority pointer |
```

(Paths use the post-Item-10 non-dot form per Addendum #1 §10
REDESIGN-CORE #2.)

### §5.3 — Editorial intent of the rows

**Row 1 (`/backlog/<ID>.md`, `/changelog/<ID>.md`):** names the
per-entry tree as a direct-read target for single-entry
operations. Existing rows in the table read the regenerated
mirror (e.g., `BACKLOG.md` row); the new row offers the
per-entry alternative for token-efficient single-entry edits
(per original integration architect doc §6.3's optional
per-entry-read capability addition; per original §5.2's
workflow source-of-truth resolution rule preferring per-entry
reads).

**Row 2 (`/backlog/_rules.md`, `/changelog/_rules.md`):** names
the per-stream contracts as discoverable read targets. The
existing trinity Key files line addition (Addendum #1 §6.2
BD-167b — Layer 1 of the discoverability cascade) names the
directories; the PACK-CHAT.md row names the contract files
explicitly so Pack Chat operators can read them on-demand
without re-deriving the path from the directory listing.

The two rows together complete the discoverability surface for
Pack Chat: row 1 is the "what to read for entry content," row
2 is the "what to read for the per-stream contract."

### §5.4 — Project-template-side analog (PM-CHAT.md)

Per Addendum #1 §6.3 BD-169 File/Symbol (the pack-product BD,
not the PM-only BD), `project-template/docs/pack/PM-CHAT.md`
also receives a row addition in its file-access strategy table
(at lines 119–123 per original §14.2 reference). The PM-CHAT.md
analog covers project-side per-entry trees:

```
| `docs/project/backlog/<ID>.md`, `docs/project/implementation-plan/<ID>.md`, `docs/project/changelog/<ID>.md` (per-entry source) | Direct read of single entry when only that entry is needed | Per-entry tree is source of truth in flat-file mode (per project-template trinity Document locations + `<stream>/_rules.md`); smaller token footprint than mirror for one-entry edits |
| `docs/project/backlog/_rules.md`, `docs/project/implementation-plan/_rules.md`, `docs/project/changelog/_rules.md` (per-stream contracts) | Direct read at session start (or on per-entry-tree-aware operation) | Per-stream contract authority |
```

The PM-CHAT.md rows ship as part of BD-169 (pack-product
wording) — the planner / coder authors them; Pack Chat does
NOT apply (this is a project-template file, not a pack-root
file). Item 5's exact spec covers BOTH the PACK-CHAT.md
PM-only edit AND the PM-CHAT.md pack-product edit so the
planner has the matched-pair text.

### §5.5 — Cascade impact (this Item)

**Addendum #1 §6.3 BD-169b File/Symbol** — the deferred
"PACK-CHAT.md row addition" entry is COMPLETED by §5.2 above.
Pack Chat applies the §5.2 row text verbatim.

**Addendum #1 §6.3 BD-169 File/Symbol** — the
`project-template/docs/pack/PM-CHAT.md` row addition is
COMPLETED by §5.4 above. Coder authors per the §5.4 spec;
trinity rule does NOT apply (PM-CHAT.md is a single file, not
trinity-replicated; per `README.md` Repository Layout and
sidecar §3.0 stream-shape discussion).

**Original integration architect doc §4.4.3** — the targeted
prose addition surfaces table entry for "PACK-CHAT.md
file-access strategy table (lines 42–43)" GAINS the §5.2
exact text. Same for "project-template/docs/pack/PM-CHAT.md
file-access strategy table" GAINS the §5.4 exact text.

**No further architect-pass abdication.** The exact text is
provided; Pack Chat (PM-only path) and the coder pass
(pack-product path) have what they need to ship.


---

## §6 — verify-by-`ls` discipline applied (with all paths verified)

Per the PROCESS SAFEGUARD: every file path enumerated in this
Addendum #2 was directly verified via `ls` against the file
system before write. This section enumerates the verification
record for traceability.

### §6.1 — Codex pack-* agent files (Item 1 BLOCKER)

```
$ ls -la /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.codex/agents/
pack-architect.toml          (1887 bytes)
pack-coder.toml              (4332 bytes)
pack-docs-researcher.toml    (1720 bytes)
pack-planner.toml            (1778 bytes)
pack-reviewer.toml           (2789 bytes)
```

All 5 verified `.toml`. No `.md` files in `.codex/agents/`.
Item 1's correction (Addendum #1 §1.4 / §6.2 / §6.5 / §11.1
references to `.codex/agents/pack-*.md` are wrong; correct
extension is `.toml`) is grounded in this verification.

### §6.2 — Claude pack-* agent files (Item 1 confirmation — these are correct in Addendum #1)

```
$ for f in pack-architect pack-coder pack-docs-researcher pack-planner pack-reviewer; do
    test -f /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.claude/agents/$f.md && echo OK || echo MISSING
  done
OK / OK / OK / OK / OK
```

All 5 verified `.md`. Addendum #1's `.claude/agents/pack-*.md`
references are correct.

### §6.3 — Gemini pack-* agent files (Item 1 confirmation)

```
$ ls -la /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.gemini/agents/
pack-architect.md            (1769 bytes)
pack-coder.md                (4301 bytes)
pack-docs-researcher.md      (1635 bytes)
pack-planner.md              (1699 bytes)
pack-reviewer.md             (2295 bytes)
```

All 5 verified `.md`. Addendum #1's `.gemini/agents/pack-*.md`
references are correct.

### §6.4 — Project-template auditor agent files (sweep finding 2A)

```
$ for cli in claude codex gemini; do
    for ext in md toml; do
      f=/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/.${cli}/agents/auditor.${ext}
      test -f "$f" && echo "EXISTS: .${cli}/agents/auditor.${ext}"
    done
  done

EXISTS: .claude/agents/auditor.md
EXISTS: .codex/agents/auditor.toml
EXISTS: .gemini/agents/auditor.md
```

`.codex/agents/auditor.toml` confirmed (NOT `.md`). Sweep
finding 2A correction grounded in this verification.

### §6.5 — Project-template Codex agents directory survey (sweep finding 2B)

```
$ ls /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/.codex/agents/
architect.toml
auditor.toml
auditor-architecture.toml
auditor-code.toml
auditor-docs.toml
auditor-ops.toml
auditor-security.toml
auditor-tests.toml
auditor-ui.toml
coder.toml
docs-researcher.toml
grpc-schema.toml
planner.toml
repo-ops.toml
reviewer.toml
tester.toml
```

All 16 project-template Codex agents verified `.toml`. Sweep
finding 2B (generic `.codex/agents/*.md` claim in original §1.1
is wrong) grounded in this directory listing — every Codex
agent file in project-template is `.toml`, no exceptions.

### §6.6 — Codex SKILL files (sweep finding — NO error in original or Addendum #1)

```
$ ls -la /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.codex/skills/pack-startup/
SKILL.md (4228 bytes)

$ ls -la /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/.codex/skills/pm-startup/
SKILL.md (12408 bytes)
```

Both `.codex/skills/.../SKILL.md` references in original and
Addendum #1 are CORRECT. Codex SKILLs are `.md`; only Codex
AGENTs are `.toml`. The convention asymmetry is documented in
`PACK-AGENTS.md:174-176`.

### §6.7 — PACK-CHAT.md table column structure (Item 5)

```
$ sed -n '38,47p' /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/PACK-CHAT.md
## File access strategy

| File | How to access | Why |
|---|---|---|
| `BACKLOG.md` | Direct read | Open BD-NNN items, current backlog state |
| ...
```

Verified 3-column structure: `File | How to access | Why`. Item
5's row text fits the structure.

### §6.8 — EXECUTION-PLAN-V11.0.md line 282 verbatim (Item 3)

```
$ sed -n '281,283p' /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md

**Total: 25 main batches (23 + Batch 5b for BD-135 + Batch 20b for BD-136 implementation) + up to 3 conditional in-session fix commits if audits/dog-food surface defects = max 28 commits, plus Batch 20b internally ships 4 commits, putting practical max at ~31 commits.** Could be slightly higher if any audit / dog-food gate needs more than one small follow-up commit.
```

Verified verbatim. Item 3's exact replacement text grounded in
this current text + the Item 2 + Item 6 renumber/split cascade.

### §6.9 — BD-095 dry-run/apply/resume contract (Item 4)

```
$ grep -nE "BD-095|--dry-run|--apply|--resume" /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md | head -3

43:- **BD-095** — `migrate-v10-to-v11.sh` two-phase `--dry-run`/`--apply`/`--resume` workflow
266: ... `scripts/migrate-v10-to-v11.sh` two-phase workflow → in-script validation gates | Two commits; BD-101 builds on BD-095's `--dry-run`/`--apply`/`--resume` surface |
```

```
$ grep -nE "_migrator_is_dryrun|MIGRATOR_MODE|--dry-run|--apply|--resume" /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/migrator-core.sh | head -10

109:#   _MIGRATOR_DRY_RUN      "1" if --dry-run, else "0"
110:#   _MIGRATOR_MODE         one of: apply | dry-run | resume
121:    _MIGRATOR_MODE="apply"
243:    say "  --dry-run     ..."
244:    say "  --apply       ..."
245:    say "  --resume      ..."
264:            --dry-run)
266:                _MIGRATOR_MODE="dry-run"
268:            --apply)
269:                _MIGRATOR_MODE="apply"
271:            --resume)
```

Verified BD-095 mode-flag parser at `migrator-core.sh:264-272`.
`_MIGRATOR_DRY_RUN` and `_MIGRATOR_MODE` state vars verified at
lines 109–110, 121. Item 4's bridge to the BD-095 contract is
grounded in this wired-and-shipping infrastructure.

### §6.10 — Addendum #1 + original integration doc files (parent docs)

```
$ ls -la /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md
102427 bytes

$ ls -la /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md
169196 bytes

$ ls /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md
(does not exist before this write)
```

Both parent docs verified present and readable; Addendum #2
target verified non-existent before write (no overwrite risk).

### §6.11 — Verification summary

Total file paths verified by direct `ls` or `sed -n` or
`grep -nE` in this Addendum #2: 45+ distinct paths across the
5 items + the 3 sweep findings + the verification record.

**Three additional findings beyond Item 1 surfaced and corrected
in §1.5 above:**
- Finding 2A: original §4.4.3 line 972 + Addendum #1 §6.3 BD-169
  File/Symbol's `.codex/agents/auditor.md` reference is wrong;
  correct is `.codex/agents/auditor.toml`.
- Finding 2B: original §1.1 line 252 generic claim "agent files × 3
  CLIs" implied `.md` for all three; Codex is `.toml`.
- Finding 2C: three additional `auditor.md` sites in the original
  integration architect doc (§1.1 line 263, §4.4.1 lines 882–883,
  §4.4.3 line 912) reference `auditor.md` in connection with
  "per-CLI mirrors" / "trinity mirrors"; the implicit per-CLI
  expansion at each site must use `.toml` for Codex (added in
  Reviewer Pass #3 follow-up #2).

**Zero further path errors found in this iteration.** The
verify-by-`ls` discipline caught the BLOCKER plus Findings 2A
and 2B in the initial sweep; the Reviewer Pass #3 follow-up #2
extended the sweep to surface Finding 2C. Future iterations
should preserve this discipline AND extend the sweep beyond
the first hit when "and per-CLI mirrors" / "and trinity
mirrors" textual idioms appear.


---

## §7 — Cascade audit (affected sections of original integration doc + Addendum #1)

This section provides the cascade view per the PROCESS
SAFEGUARD. Every section of the original integration architect
doc and Addendum #1 modified by this Addendum #2 is enumerated.

### §7.1 — Original integration architect doc (`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md`) sections affected

| Original § | Title | Items affecting it |
|---|---|---|
| §1.1 | Inputs read | Item 1 sweep finding 2B (generic `.codex/agents/*.md` claim corrected to `.toml`) |
| §4.2 Layer 2 | Per-entry HTML-comment back-pointer | Item 2 (Addendum #1 §1.2 body-field upgrade RETIRED; Layer 2 reverts to original §4.2 spec — UNCHANGED from original) |
| §4.4.3 | Surfaces that gain a TARGETED PROSE addition | Item 1 sweep finding 2A (auditor agent `.codex` extension corrected); Item 5 (PACK-CHAT.md row exact text + PM-CHAT.md row exact text) |
| §10.6 | Pack-side vs project-side validator scope | Item 4 (CI-context note clarifies Check 32's non-destructive invocation does not need Item 4's apply-blocking semantics) |
| §17.2 BD-165 File/Symbol | `_v10_to_v11_decompose_streams` 6th sub-op | Item 4 (gains `--force-overwrite-mirror` flag-parsing addition in migrator-core mode-flag parser) |
| §18.2 coder items #3 | Per-entry HTML-comment back-pointer add/strip | Item 2 (body-field add/strip clause from Addendum #1 implicitly added is REMOVED; reverts to HTML-comment add/strip only) |

### §7.2 — Addendum #1 (`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md`) sections affected

| Addendum #1 § | Title | Items affecting it |
|---|---|---|
| §1.2 | Layer 2 upgrade: body-field back-pointer | Item 2 (entire section RETIRED; Layer 2 reverts to HTML-comment line 1 only) |
| §1.4 | Layer 4: pack-* agent prompts close sub-agent context gap | Item 1 (5 Codex paths corrected from `.md` to `.toml`); §1.5 file enumeration corrected per §1.3 above |
| §1.5 | Cascade impact (Layer 2 entry) | Item 2 (Layer 2 cascade reverts; no body-field changes) |
| §2.4 row 4 | EXECUTION-PLAN line 282 totals | Item 3 (exact replacement text per §3.3 above) |
| §4.5 | Mitigation flagged for the planner — pre-commit hook | Item 4 (hook inherits "block on divergence + flag-required" semantics from BD-095 bridge) |
| §5.3 | Layer 2: regenerator emits divergence warning | Item 4 (non-interactive context routing replaced by BD-095 two-phase semantics; interactive context routing UNCHANGED) |
| §5.4 | Layer 3: explicit defense-in-depth doc | Item 4 (Layer 2 description in the defense-in-depth statement updated for the dry-run-reports + apply-blocks language) |
| §6.2 BD-167b File/Symbol | PM-only edits | Item 1 (5 Codex `pack-*.md` paths corrected to `.toml`) |
| §6.3 BD-169 File/Symbol | Pack-product wording | Item 1 sweep finding 2A (auditor `.codex` extension); Item 5 (PM-CHAT.md exact row text per §5.4) |
| §6.3 BD-169b File/Symbol | PM-only wording | Item 1 (5 Codex `pack-*.md` paths if any in BD-169b — verified NONE in BD-169b which is README + PACK-CHAT.md only); Item 5 (PACK-CHAT.md exact row text per §5.2) |
| §6.5 commit 19b-PM | PM-only commit content list | Item 1 (5 Codex `pack-*.md` paths corrected to `.toml`) |
| §6.5 commit 19g-pack | Pack-product wording commit | Item 1 sweep finding 2A (auditor `.codex` extension corrected) |
| §6.5 commit 19g-PM | PM-only wording commit | Item 5 (PACK-CHAT.md exact row text confirmed) |
| §11.1 §18.2 row | Cascade audit row for original §18.2 | Item 1 (5 Codex paths corrected); Item 2 (body-field add/strip clause removed) |
| §11.1 §4.2 row | Cascade audit row for original §4.2 | Item 2 (Layer 2 reverts; cascade entry updated) |

### §7.3 — Coverage verification

Per the PROCESS SAFEGUARD cascade-verification instruction, the
above enumeration is exhaustive. The planner reading Addendum
#2 + Addendum #1 + the original integration architect doc
together has the complete view.

**Items 1, 2, 3, 4, 5 — total 5 items + 3 sweep findings = 8
distinct corrections enumerated in this Addendum #2** (Finding
2C added in Reviewer Pass #3 follow-up #2). Each is grounded
in verified file system state per §6 above.

**Net effect on Batch 19 BD-set + commit count:** UNCHANGED.
Addendum #1 §6.4 BD table (10 BDs) and Addendum #1 §6.5 commit
ordering (10 commits) remain authoritative; Addendum #2 only
corrects path-naming, drops one design upgrade, fixes one
arithmetic error, bridges to an existing contract, and provides
one deferred exact-text spec. No new BDs; no new commits; no
contract changes beyond Item 4's BD-095 bridge (which composes
against existing infrastructure).

**Architect-pass discipline preserved:** zero PM-only file
edits made; zero pack-product file edits made; zero parent-doc
edits made; zero v10 entry-format grammar changes (Item 2
explicitly REMOVES Addendum #1's grammar-violating body-field
upgrade); structural-signal trips named where they occur (Item
4 §4.7 names the Signal 8 conditional trip already
acknowledged in original §13.4 + Addendum #1 §6.4).


---

## §8 — Final-line marker

ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2-COMPLETE: 2026-05-14 —
Bundles 5 user-Pack-Chat-decided items (1 BLOCKER + 4
SHOULD-FIX) on Addendum #1
(`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md`, 2,050
lines). ONE BLOCKER (Item 1 — Codex pack-* agent file extension
errors in Addendum #1 §1.4 / §6.2 BD-167b / §6.5 commit 19b-PM
/ §11.1 §18.2: Codex agent files are `.toml`, not `.md`;
verified by `ls`; correction restated explicitly per the
Addendum #1 §3.2 friction-correction pattern; sweep ALSO
surfaced TWO ADDITIONAL `.codex/.../*.md` errors — original
§4.4.3 + Addendum #1 §6.3 BD-169 auditor agent path is wrong
[`auditor.md` → `auditor.toml`]; original §1.1 generic
"agent files × 3 CLIs" claim implies wrong extension for Codex;
both corrected here). FOUR SHOULD-FIX (Item 2: drop body-field
back-pointer entirely from Addendum #1 §1.2; the Field-Name:
value addition violated sidecar parent's byte-additive
invariant at `ARCHITECTURE-PER-ENTRY-SPLIT.md:248-256`; Layer
2 reverts to original integration architect doc §4.2 spec —
HTML-comment back-pointer at line 1 only, byte-additive on the
file but byte-identical from `**BD-NNN —` onward; offset-read
fragility re-evaluated as theoretical; sub-agent isolation
covered by Addendum #1 §1.4 Layer 4 instead; bonus avoids
tracker-integration scope creep [no flat ↔ tracker forward /
reverse changes needed]. Item 3: EXECUTION-PLAN-V11.0.md line
282 totals arithmetic — Addendum #1 §2.4 row 4 double-counted
Batch 19 and abdicated final wording; corrected to "26 main
batches (24 + Batch 5b + Batch 21b)" with full exact
replacement text provided for Pack Chat to apply verbatim;
practical max corrected to ~41 commits (Pack-Chat-direct edits to Addendum #1 §0.2, §6.6, §11.3 in lockstep with this Item; Batch 19's 10 internal sub-commits add 9 extras, not 8). Item
4: bridge regenerator divergence-handling to BD-095's existing
`--dry-run`/`--apply`/`--resume` two-phase contract; replaces
Addendum #1 §5.3's "stderr warning + proceed" non-interactive
routing with "dry-run reports + apply blocks unless
`--force-overwrite-mirror` flag passed"; verified BD-095
contract at `migrator-core.sh:264-272` mode-flag parser +
`_MIGRATOR_DRY_RUN`/`_MIGRATOR_MODE` state vars at lines
109–110, 121; Check 32 invocation [non-destructive diff-only]
unaffected; pre-commit hook semantics in Addendum #1 §4.5
inherit the same "block + flag-required" contract. Item 5:
PACK-CHAT.md row exact spec — Addendum #1 §6.3 BD-169b deferred
the row text; this Item provides the exact text for the
PACK-CHAT.md row [PM-only edit Pack Chat applies] + the
analogous PM-CHAT.md row [pack-product edit coder authors];
PACK-CHAT.md table column structure verified by `sed -n
'38,47p'` as `File | How to access | Why`; two-row addition
covers the per-entry-tree direct-read capability AND the
per-stream `_rules.md` discoverability surface). verify-by-`ls`
discipline applied to 45+ distinct file paths across the 5
items + 3 sweep findings + verification record; results in §6
above. Cascade audit (§7) provides per-section impact map
across original integration architect doc + Addendum #1; 6
original-doc sub-sections affected + 15 Addendum #1
sub-sections affected. Architect-pass discipline preserved:
zero PM-only file edits made (BACKLOG / CHANGELOG / README /
PACK-CHAT / PACK-AGENTS / CLAUDE / AGENTS / GEMINI /
EXECUTION-PLAN-V11.0 / RELEASE-GATE / V3.x corpus); all
required PM-only edits surfaced as edit specifications (Pack
Chat applies the §1.2 Codex correction in BD-167b commit
19b-PM, the §3.3 EXECUTION-PLAN line 282 replacement, and the
§5.2 PACK-CHAT.md row addition); zero pack-product file edits
made; zero parent-doc edits made (Addendum #1 + original
integration architect doc UNCHANGED — Addendum #2 supersession
authoritative); zero v10 entry-format grammar changes (Item 2
explicitly REMOVES Addendum #1 §1.2's body-field upgrade
because it violated V3.1-DELTA §3 A2 + sidecar parent §3.1's
byte-additive invariant at lines 248–256); structural-signal
trips named where they occur (Item 4 §4.7 names Signal 8
conditional trip already acknowledged in original §13.4 +
Addendum #1 §6.4; no NEW signal trips). Verification by
direct `ls` + `sed -n` + `grep -nE` is the THIRD-iteration
discipline that caught the BLOCKER + 3 sweep findings (2A and
2B in initial sweep; 2C in Reviewer Pass #3 follow-up #2
extended sweep); recommended preserved for future iterations. Net effect on
Batch 19: Addendum #1 §6.4 BD table (10 BDs) and §6.5 commit
ordering (10 commits) UNCHANGED in count; only path-naming /
extension / arithmetic corrections + one design upgrade
withdrawal + one contract bridge + one deferred-text completion.
No further iteration anticipated; ready for primary-chat
reviewer to evaluate before primary-chat planner spawns Batch
19 BD scheduling.
