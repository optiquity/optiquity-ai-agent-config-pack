# PACK-REVIEW — Per-Entry Flat-Files Architecture (Parent + Diff Doc)

**Reviewer:** pack-reviewer (v11-dev)
**Date:** 2026-05-12
**Branch:** v11-dev
**Scope:** Read-only audit of:
- `maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-FLAT-FILES.md` (parent, 1,655 lines)
- `maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-PACK-VS-CLIENT.md` (diff doc, 1,255 lines)

Posture: pre-BD design review against the locked shape (per-entry +
immutable `_rules.md` + mutable `_toc.md`). The shape is not revisited.
Findings target correctness of evidence, internal consistency between
the two docs, coverage gaps the planner will trip on, and one drift
from the locked decision the brief explicitly required me to flag.

---

## Executive verdict

The two documents are substantively coherent and decision-ready *in
their broad architecture*. The locked shape (per-entry + `_rules.md` +
`_toc.md`) is well-defended, the three-consumer (standalone /
tracker / Graphify) union analysis is sound, and the diff doc's
pack-vs-client differentiation closes the deferred parent questions
cleanly. However, the design has **one BLOCKER-class drift from the
brief's locked decisions**: the byte-identity enforcement mechanism is
specified as (b) "explicit `pack rules-sync` verb in repo-ops
profile" — but neither document mentions `pack rules-sync` or any
explicit verb. Instead both lean on (a) detect-only validator +
symlink/build-time copy. This is a substantive change from the locked
decision and must be reconciled before the planner consumes the
docs. Two SHOULD-FIX gaps (dry-run UX absent for the v11.0→v11.1
decomposer; access-pattern coverage missing for Type / File-Symbol /
Date queries) and one factual error (diff doc's pack-agent count
miscounts `pack-reviewer` as not needing per-entry edits when it
does) are the remaining substantive items. The rest are NITs (line-
number drift, stale internal §11/§15 cross-references, a few minor
count mismatches against current v11-dev tip).

**Counts:**
- BLOCKER: 1 (F-1)
- SHOULD-FIX: 6 (F-2 .. F-7)
- NIT: 8 (F-8 .. F-15)

The design is decision-ready for the planner once F-1 is reconciled
and F-2..F-7 are answered. The NITs can be folded into the planner's
own scope or absorbed during implementation.

---

## Findings

### F-1 — Locked-decision drift: `pack rules-sync` verb absent

- **Severity:** BLOCKER
- **Where:** Parent §5.2(a)-(d); diff doc §3.2-§3.4; absent everywhere
- **What:** The reviewer brief states the locked byte-identity
  enforcement mechanism is **(b) explicit `pack rules-sync` verb in
  repo-ops profile**. Grep across both docs for `rules-sync`,
  `rules_sync`, or `pack rules-sync` returns zero matches.

  Instead the design specifies:
  - Parent §5.2(a) sentinel marker
  - Parent §5.2(b) "Validator Check 31 (new)" — detect-only
  - Parent §5.2(c) skill-rule enforcement
  - Parent §5.2(d) PACK-CHAT.md / PM-CHAT.md rule
  - Diff doc §3.2.3: "pack-self's `backlog/_rules.md` is a symlink to
    (or build-time copy from) `project-template/docs/project/backlog/
    _rules.md`" — this is mechanism (d) symlink, which the brief lists
    as separately rejected
  - Diff doc §3.4: "Validator Check 31 ... extends to assert
    byte-identity" — pure mechanism (a)

  No design path exercises mechanism (b). The locked mechanism's UX
  hinge (the diagnostic emitted when byte-identity drifts) is absent:
  no `→ Run: pack rules-sync` sentence appears anywhere, despite the
  pack's own typed-error pattern from BD-070 (`BACKLOG.md:185`)
  mandating "every error message ends with → Run: pack X."

- **Why it matters:** The brief's framing was that the mechanism
  choice changes the planner's BD shape — (b) requires a new verb in
  `scripts/pack-tracker.sh` (or sibling), a new check-31 diagnostic
  message wired to the verb, and a new entry in
  `HELP-FRAGMENT-PACK.md`. The current design has none of these. If
  the planner treats the docs as-is, the resulting BD set will ship
  mechanism (a)/(d), not the chosen (b). That is a structural defect
  the validator will not catch (Check 31 as designed is detect-only,
  by definition).

- **Open question the design must answer:** Which mechanism is
  authoritative — the brief's (b) or the architecture docs' (a)+(d)?
  If (b) is correct, the parent §5.2 enumeration needs a new
  guard (e) for the verb, Check 31's diagnostic shape needs to name
  the verb, and BD-X8 (parent §17.3) needs to add the verb to its
  scope or split a new BD-X8b. If (a)+(d) is correct, the brief is
  wrong and needs reconciliation — but until that's confirmed, the
  planner has no defensible choice.

---

### F-2 — Access-pattern coverage gaps in §8.2

- **Severity:** SHOULD-FIX
- **Where:** Parent §8.2 table (lines 539-546)
- **What:** The brief asked for §8 coverage of less-common access
  patterns: "search by Type, by File-Symbol, by Date." The §8.2 table
  enumerates six patterns (single-BD lookup, status filter, blocker
  trace, full audit, new-BD-ID, phase status check) — none of those
  three patterns appear.

  - **Search by Type** — `Type: TODO(version)` appears on 60+ of 140
    BDs at v11-dev tip (`grep -c '^Type: TODO(' BACKLOG.md`). Filtering
    "every TODO(version) BD" today requires reading the whole BACKLOG;
    the per-entry shape ought to make it grep-cheap or TOC-enumerable,
    but no schema row in §6.1's TOC table includes Type.
  - **Search by File-Symbol** — "every BD referencing
    `scripts/lib/tracker-mirror.sh`" is exactly the cross-cutting query
    Graphify §11.2 promotes to a `(BD) references (file F)` edge — but
    standalone-mode (no Graphify) the design's read path is grep
    `backlog/*.md` for the path. That works but is unstated.
  - **Search by Date** — "BDs resolved in the last 7 days" today
    requires parsing `Resolved:` lines; the per-entry shape inherits
    this. No mention.

- **Why it matters:** The planner sets the scope of `_toc.md`
  columns (parent §6.1 schemas). If Type and date are expected query
  axes, the TOC schema needs more columns; if File-Symbol queries fall
  back to `grep backlog/*.md`, the read-path contract should say so
  explicitly so the planner doesn't accidentally bake them into the
  TOC. The current design under-specifies.

- **Open question the design must answer:** Are Type / File-Symbol /
  Date access patterns in-scope for v11.1, or explicitly deferred?
  If in-scope, do they extend the TOC schema or stay as grep-fallback?

---

### F-3 — Dry-run UX absent for v11.0→v11.1 decomposer

- **Severity:** SHOULD-FIX
- **Where:** Parent §14.1-§14.5; BD-X10 description (line 1537)
- **What:** Parent §14.1 describes the decomposer mechanically
  ("Reads BACKLOG.md ... emits the per-entry directory tree ...
  deletes the monolithic file only after the decomposed tree is
  verified"). BD-X10 names "dry-run + rollback documentation" but no
  output shape, no dispatch table, no sample diff is sketched.

  By comparison, the v10→v11 migrator's dry-run is described in
  detail in `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md`
  and the dry-run lib was BD-095 (`BACKLOG.md:680-684`) with a 216-
  line `scripts/lib/migrate-v10-to-v11/dry-run.sh`. The per-entry
  decomposer is structurally similar (decompose tree under
  `_MIGRATOR_BACKUP_DIR` first, present the diff, await --apply) but
  the architecture is silent on the output shape.

- **Why it matters:** §14 is the migration story for clients running
  `pack init --update` against an existing v11.0 project. The dry-run
  UX is the user-visible artifact of that story. The planner needs to
  know whether "dry-run" means
  - (a) the decomposer writes a manifest of "would-create" files plus
    a `decompose-preview.txt` and exits before deletion (mirror of
    BD-095 pattern), or
  - (b) something else entirely.

  Without this, the planner cannot scope BD-X7 (decomposer migrator
  stage) — the dry-run lib is either part of that BD or a separate
  ride-along.

- **Open question the design must answer:** What does
  `bash scripts/decompose-monolithic.sh --dry-run` print, and which
  artifacts does it leave on disk vs. in stdout? Does it follow the
  BD-095 dispatch pattern (--dry-run / --apply / --resume)?

---

### F-4 — Diff doc undercounts pack-agent edits (pack-reviewer missed)

- **Severity:** SHOULD-FIX
- **Where:** Diff doc §7.4 (line 610); summary §12 row "Agent files
  touched by per-entry shape" (line 1057)
- **What:** Diff doc §7.4 claims pack-side edits are: "3 files
  (`pack-coder.md`, `pack-architect.md`, `pack-planner.md`) × 3 CLIs
  = 9 files." Summary §12 echoes "3 of 5 (`pack-coder.md`,
  `pack-architect.md`, `pack-planner.md`) × 3 CLIs = 9 files."

  Verification: `grep -l BACKLOG .claude/agents/*.md .codex/agents/
  *.toml .gemini/agents/*.md` returns matches on `pack-coder`,
  `pack-architect`, `pack-planner`, AND `pack-reviewer` (all three
  CLI mirrors). `pack-reviewer.md:28-29` carries the text:

  > **BACKLOG accuracy.** If the change resolves or modifies a BD
  > item, verify the BACKLOG entry is updated with the correct status
  > and resolution.

  This survives the per-entry shape only with text rewording (e.g.,
  "verify the `backlog/BD-NNN.md` file is updated"). The reviewer
  brief explicitly asked me to verify this:

  > pack agent count (parent claims "3 of 5 × 3 CLIs = 9 files" —
  > verify against `PACK-AGENTS.md` roster; pack-reviewer may also
  > need updates since it reads BACKLOG during reviews)

  So the actual count is 4 of 5 × 3 CLIs = 12 files. (`pack-docs-
  researcher` does not reference BACKLOG.)

- **Why it matters:** BD-X3 (parent §17.3) scope is based on the
  9-file count. The planner will scope the trinity-edit BD with the
  wrong file roster. Drift will land if not caught now.

- **Open question the design must answer:** Are `pack-reviewer.md`
  edits in BD-X3 scope (recommended), or is the reviewer's BACKLOG
  reference somehow exempt?

---

### F-5 — Diff doc misrepresents project-template Document-locations table shape

- **Severity:** SHOULD-FIX
- **Where:** Diff doc §5.2 (line 416) and parent §15.1b (line 1188-
  1198); cited as `project-template/CLAUDE.md:221-225`
- **What:** Both docs describe the project-template trinity edit as
  "all 4 stream rows update to directory references":

  > `BACKLOG.md` → `docs/project/backlog/`
  > `STATUS.md` → `docs/project/status/`
  > `IMPLEMENTATION_PLAN.md` → `docs/project/implementation-plan/`
  > `CHANGELOG.md` → `docs/project/changelog/`

  This implies a row-per-stream table. The actual table at
  `project-template/CLAUDE.md:208-225` (header at 208, rows at
  223-224) has a different shape:

  > | `docs/pack/` | `METHODOLOGY.md`, ...
  > | `docs/project/` | `ARCHITECTURE.md`, `IMPLEMENTATION-PLAN.md`,
  >                     `BACKLOG.md`, `STATUS.md`, `CHANGELOG.md` ...
  > | `docs/reference/` | ...

  The table is **3 rows, not per-stream**. The `BACKLOG.md` /
  `STATUS.md` etc. are content of a single cell within the
  `docs/project/` row. The edit is therefore: rewrite the cell
  contents from "BACKLOG.md, STATUS.md, CHANGELOG.md, IMPLEMENTATION-
  PLAN.md, ARCHITECTURE.md" to "backlog/, status/, changelog/,
  implementation-plan/, ARCHITECTURE.md" — one cell, not four rows.

  Same drift in AGENTS.md (`:192-208`) and GEMINI.md (`:203-219`).

- **Why it matters:** The planner will draft BD-X3 with "edit 4 rows
  in the Document locations table" wording. The actual edit is "edit
  the contents of one row's second column" — different mechanical
  change. Validator Check 18 (trinity H2 parity) does not enforce
  table-row structure but the planner's commit description will
  misdescribe the change.

  Also note: the Source-column extension (BD-062, `BACKLOG.md:62-72`)
  added a column to this table at v11.0; per-entry shape preserves
  that column structure. The planner needs to understand the table is
  3-row-with-Source-column, not 4-row-without.

- **Open question the design must answer:** Restate the trinity edit
  shape in §15.1b / §5.2 using the actual table layout.

---

### F-6 — Frontmatter §20 defer is silently inconsistent with §11.2

- **Severity:** SHOULD-FIX
- **Where:** Parent §11.2 (lines 797-810) vs §20 (lines 1649-1652)
- **What:** Parent §20 defers frontmatter as out-of-scope: "Per-entry
  frontmatter (YAML) instead of inline `Status:` lines. Out of scope
  per the brief's 'preserve existing BACKLOG.md entry shape'
  implication."

  But §11.2 claims that regex extraction of `Blockers:` /
  `File/Symbol:` / `Status:` fields produces edges tagged `EXTRACTED`
  with confidence 1.0 — "the same `EXTRACTED` confidence Pass-1 tree-
  sitter edges carry per `RESEARCH-GRAPHIFY-SYNTHESIS.md:25-26`."

  Cross-check the synthesis (`RESEARCH-GRAPHIFY-SYNTHESIS.md:24-29`):
  Pass-1 produces `EXTRACTED` edges with confidence 1.0 from
  tree-sitter on code. Pass-3 (markdown / PDF / image) produces
  `INFERRED` edges with discrete confidence buckets (0.95/0.85/...).
  Regex-extraction of structural fields from markdown is not Pass-1
  (no tree-sitter for markdown structural fields).

  Frontmatter (YAML inside `---`) is the standard way to make those
  fields deterministically extractable without Pass-3 LLM — Graphify
  presumably has a YAML extractor or could be extended with one
  cheaply, and the field-name structure is exact enough that even
  bare regex would deserve the 1.0 confidence tier in pack-supplied
  edge-derivation code.

  In effect §20 defers the one mechanism that would let §11.2's
  claim ("EXTRACTED, confidence 1.0") hold true. Without frontmatter
  the §11.2 claim slips from `EXTRACTED` 1.0 to "Pass-3 high-
  confidence INFERRED 0.95," which the brief asked me to flag as a
  real opportunity left on the table:

  > Is the §20 frontmatter defer revisitable? Frontmatter would let
  > Graphify Pass 1 derive edges deterministically instead of via
  > LLM Pass 3 — this is a real opportunity left on the table.

- **Why it matters:** The Graphify v12 quality argument (§11) is the
  forward-compatibility selling point of v11.1. If the EXTRACTED-tier
  claim is shaky without frontmatter, that case weakens. The §20
  deferral is also justified by appeal to "preserve existing
  `BACKLOG.md` entry shape" — but the v11.0→v11.1 migration already
  rewrites every entry into a new file; adding frontmatter is a
  zero-marginal-cost edit during that rewrite. The "preserve shape"
  argument is weak in this context.

- **Open question the design must answer:** Is the §20 defer
  revisitable? Specifically: does pack-architect want to add a §20
  delta that says "frontmatter is deferred to v12" with explicit
  cost-vs-benefit, or revisit the decision for v11.1?

---

### F-7 — Parent §6.4(a) merge-driver claim relies on idempotent timestamp

- **Severity:** SHOULD-FIX
- **Where:** Parent §6.4(a) (lines 432-440); diff doc §4.4
- **What:** §6.4(a) says: "two agents independently editing two
  different BD files and then each running `per_entry_toc_rebuild`
  produce the **same** TOC — order does not matter. The git merge of
  two TOC writes is byte-conflict-free for the table body (both
  writers compute identical content); only the timestamp line
  drifts. Resolution: a custom `.gitattributes` merge driver for
  `_toc.md` files that takes 'either timestamp, pick latest.'"

  This is only true if both agents see the same on-disk entry set
  when each rebuilds. The scenario "agent A edits BD-100; agent B
  edits BD-200; both rebuild TOC; both commit":
  - If A and B run serially (A commits, B pulls, B rebuilds, B
    commits), the TOCs are sequential and idempotent. No conflict.
  - If A and B run in parallel (each starts from the same HEAD, each
    rebuilds locally, each commits without pulling), the merge sees
    two TOCs at the same parent — but A's TOC has BD-100's change but
    not BD-200's; B's TOC has BD-200's change but not BD-100's. The
    table-body content **differs**. The merge driver "pick latest
    timestamp" picks one TOC body and silently drops the other's row
    update.

  The design's claim "both writers compute identical content"
  requires that both writers' local entry-file states are byte-
  identical at rebuild time. Under parallel commits with non-trivial
  edits, they are not.

  Diff doc §11.1 acknowledges client-side has higher concurrent-edit
  risk than pack-self, but does not call out this specific scenario
  — it assumes the merge driver resolves it.

- **Why it matters:** The TOC is derived state, but if the merge
  driver silently picks one TOC over the other under conflict,
  reconciliation has to run on the next operation to recover. §6.5
  describes the reconciler (orphan-detection, missing-in-index
  detection) which would catch this — but it runs at startup, not on
  push. Between push and next startup, the TOC on `main` is stale.
  Worse, if the startup reconciler edits the TOC and commits without
  user approval (per §6.4 "always-on, no user approval"), it could
  blow over a hand-edit that was intentional.

- **Open question the design must answer:** Is the merge driver
  enough, or does the design need a post-merge `per_entry_toc_rebuild
  --verify` step on the merged ref? Should the startup reconciler
  ever auto-commit, or does it only surface a diff and require the
  user to commit?

---

### F-8 — `Status:` distribution citation drifted

- **Severity:** NIT
- **Where:** Parent §5.1 line 280 (claims "Open 32, Resolved 94,
  Deferred 10, Cancelled 1, Deprecated 3")
- **What:** Actual at v11-dev tip: Open 30, Resolved 96, Deferred
  10, Cancelled 1, Deprecated 3 (verified `grep '^Status:'
  BACKLOG.md | sort | uniq -c`). The total still matches (140); the
  Open/Resolved split has shifted by 2 (likely BD-156/157/158
  resolutions from recent commits).
- **Why it matters:** Just text staleness. The 140-total claim and
  the example TOC in §6.1 (also `Open 32 ... Resolved 94`) need a
  pre-implementation refresh, otherwise the seed `_toc.md` template
  ships with wrong numbers.

---

### F-9 — `PACK-AGENTS.md` line count claim off by 1

- **Severity:** NIT
- **Where:** Diff doc §1.1 (line 47): "`PACK-AGENTS.md` — 180 lines"
- **What:** Actual `wc -l PACK-AGENTS.md` = 179.
- **Why it matters:** Trivial drift, but the diff doc's "every claim
  about current state is cited by file:line" preamble (line 26) sets
  the bar at exact citation.

---

### F-10 — Client-agent count claim off by 1

- **Severity:** NIT
- **Where:** Diff doc §7.2 (line 559) and §12 (line 1056): "15 agents"
- **What:** Actual `ls project-template/.claude/agents/ | wc -l` = 16.
  The enumeration in §7.2 ("`architect.md`, `auditor*.md` (8 auditors),
  `coder.md`, `docs-researcher.md`, `grpc-schema.md`, `planner.md`,
  `repo-ops.md`, `reviewer.md`, `tester.md`") actually sums to 16; the
  count "15" is a typo.
- **Why it matters:** Trivial.

---

### F-11 — Skills count "~32" claim is low

- **Severity:** NIT
- **Where:** Diff doc §12 row (line 1060): "~32 skills in
  `project-template/skills/`"
- **What:** Actual `ls project-template/skills/ | wc -l` = 34.
- **Why it matters:** Trivial — but recent additions (BD-156/157/158
  added `protobuf-patterns`, `apple-swiftdata-patterns`,
  `swift-concurrency-patterns`) confirm the count drifted by 2-3
  during authoring.

---

### F-12 — Type: TODO(version) "only on BD-151..BD-155" claim wrong

- **Severity:** NIT
- **Where:** Diff doc §3.2.5 (lines 296-301): "five current pack-self
  BDs (BD-151..BD-155 per `BACKLOG.md` tail)"
- **What:** Actual: `Type: TODO(version)` appears 60+ times in
  BACKLOG.md (most v11-era BDs carry it). Verified `grep -c
  '^Type: TODO(' BACKLOG.md`.
  The argument the section makes (`Type: TODO(version)` is not
  pack-only and could be valid client content) holds, but the
  premise about it appearing on five BDs is wrong.
- **Why it matters:** Premise of the argument is wrong; conclusion
  stands. Easy to fix by reading the BACKLOG histogram.

---

### F-13 — Stale internal §11/§15 cross-references in parent

- **Severity:** NIT
- **Where:** Parent §4.2 (line 190), §5.2(c) (line 313), §8.3 (line 563)
- **What:** Three internal cross-references point at §11 (Graphify)
  where they should point at §15 (Trinity / per-CLI implications):
  - Line 190: "the validator (Check 31, §11)" — Check 31 is defined
    in §15.5.
  - Line 313: "the new `per-entry-flat-files` skill (§11.2)" — §11.2
    is Graphify edge derivations; the skill is not defined there or
    anywhere with a section number.
  - Line 563: "`AGENTS.md`, `GEMINI.md`, both pack-root and
    `project-template/` (§11 enumerates the file set)" — §15.7
    enumerates the file set.

  The §16-shifted-to-§15 renumber appears to have left these
  references behind.
- **Why it matters:** Planner reading the doc top-to-bottom will hit
  three broken pointers. Minor, but eroding the doc's signal.

---

### F-14 — Pack-root CLAUDE.md line-number citations drifted ~2-5 lines

- **Severity:** NIT
- **Where:** Throughout both docs; concentrated in diff doc §5.4 and
  §11
- **What:** Spot-checks against current CLAUDE.md:
  - `CLAUDE.md:68-79` (Trinity rule) — actual `:70-76`
  - `CLAUDE.md:24-32` (key-files list) — actual `:28-33`
  - `CLAUDE.md:55-65` (commit-message rules) — actual `:46-58` (split
    across "Commit message format" `:46-52` and "Versioning" `:54-58`)
  - `CLAUDE.md:96-101` ("Pack agents never commit") — actual `:102-107`
  - `CLAUDE.md:117-120` (Implicit BD status flip) — actual `:115-117`
  - `CLAUDE.md:163-167` (Separate pack ops from pack product) — actual
    `:160-163`
  - `CLAUDE.md:171-184` (Skill and agent maintenance...) — actual
    `:168-183`
  - `CLAUDE.md:139-153` (Sub-agent isolation, Claude-only) — verbatim
    correct
- **Why it matters:** Citations are still findable (the rules they
  reference exist), so the underlying argument doesn't break — but
  the docs are not citation-clean against current HEAD.

---

### F-15 — Mirror-header lines and migrator-core lines drifted

- **Severity:** NIT
- **Where:** Parent §6.2 (line 404), §13.10 (line 1063)
- **What:**
  - §6.2: "same pattern as `tracker_mirror_header_write` at
    `scripts/lib/tracker-mirror.sh:50-80`" — actual: function at
    `:50`, but the function body runs `:50-83` and the next-function
    `tracker_mirror_header_strip` starts at `:85`. Range close.
  - §13.10: "`_MIGRATOR_STATE_DIR` checkpoint convention (lines
    108-115)" — actual at `:111-112` (variable definitions) and
    `:122-123` (defaults). Drift ~4 lines.
- **Why it matters:** Trivial; both still resolve to the right
  artifact.

---

## Citations verified

Spot-check coverage across both docs (28 distinct citations
checked).

| Citation | Source doc | Status |
|---|---|---|
| `BACKLOG.md` 3,556 lines / 140 entries | Parent §0 | PASS |
| `BACKLOG.md:33-46` (BD-060 entry shape) | Parent §1 | PASS |
| `BACKLOG.md` Status distribution `Open 32 / Resolved 94` | Parent §5.1 | DRIFTED (now 30/96) |
| `CHANGELOG.md` 590 lines | Parent §16.1, Diff §1.1 | PASS |
| `PACK-AGENTS.md` 180 lines | Diff §1.1 | DRIFTED (179) |
| `PACK-CHAT.md:110-129` recommendation flow | Diff §11.2 | PASS (covers tracker recommendation routing) |
| `PACK-CHAT.md:42-46` File access strategy table | Diff §12 | PASS |
| `project-template/docs/pack/PM-CHAT.md:117-131` File access | Parent §1 | PASS |
| `project-template/docs/pack/PM-CHAT.md:119` BACKLOG row | Parent §8.3 | PASS |
| `project-template/docs/pack/PM-CHAT.md:159-170` Additional documents | Parent §1 | PASS |
| `project-template/CLAUDE.md:221-225` Document locations table | Parent §15.1b, Diff §5.2 | DRIFTED (`:208-225`; 3-row table, not 4-row) |
| `scripts/lib/tracker-mirror.sh` 105 lines | Parent §1, §9.1 | PASS |
| `scripts/lib/tracker-mirror.sh:50-80` write function | Parent §6.2 | DRIFTED (function `:50-83`) |
| `scripts/lib/tracker-migrate-forward.sh` 1,465 lines | Parent §1, §9.1 | PASS |
| `scripts/lib/tracker-migrate-reverse.sh` 954 lines | Parent §1, §9.1 | PASS |
| `scripts/lib/tracker-provider.sh` 18 ops | Parent §1, §10.1 | PASS |
| `scripts/lib/tracker-config.sh` schema reader | Parent §1 | PASS |
| `scripts/pack-tracker.sh` verb dispatcher | Parent §1, §9.1 | PASS |
| `scripts/validate-pack.py` 30 numbered + 2 informational checks | Parent §1 | PASS (verified file header `:5-110`) |
| `scripts/validate-pack.py:43-45` Check 18 hard-fail | Parent §5.2(b) | PASS |
| `scripts/lib/migrator-core.sh:108-115` `_MIGRATOR_STATE_DIR` | Parent §13.10 | DRIFTED (actual `:111-112`) |
| `scripts/lib/tracker-agent-read.sh` (BD-071) | Parent §8.4 | PASS (file exists, function present) |
| `RESEARCH-GRAPHIFY-SYNTHESIS.md:14-17` v12 deferral | Parent §1 | PASS |
| `RESEARCH-GRAPHIFY-SYNTHESIS.md:25-26` EXTRACTED/INFERRED tiers | Parent §1, §2, §11.2 | PASS (synthesis section §1) |
| `RESEARCH-GRAPHIFY-SYNTHESIS.md:32-38` token reduction range | Parent §1, §16.4 | PASS |
| `RESEARCH-GRAPHIFY-SYNTHESIS.md:57` /pack-startup detect-only | Parent §9.3 | PASS |
| `RESEARCH-GRAPHIFY-SYNTHESIS.md:104` no new agent | Parent §1 | PASS |
| `RESEARCH-GRAPHIFY-SYNTHESIS.md:144` graph.json merge driver | Parent §6.4 | PASS |
| `RESEARCH-GRAPHIFY-PACK-INTEGRATION.md:29-37` RAG manifest | Parent §1 | PASS |
| `RESEARCH-GRAPHIFY-PACK-INTEGRATION.md:140-153` artifact location trinity-symmetric | Parent §1 | PASS |
| `BD-066 / BD-067 / BD-068 / BD-069` at `BACKLOG.md:120-175` | Parent §1, §17.2 | PASS |
| `BD-088` customization-preserve | Parent §5.3 | PASS |
| `BD-119` migrator framework | Parent §4.4, §14.5 | PASS |
| BD-102 dog-food pattern | Diff §10.3 | PASS (BD-102 at `BACKLOG.md:806`) |
| Pack-agent count: 5 (`PACK-AGENTS.md:13-19`) | Diff §7.1 | PASS |
| Client-agent count: 15 | Diff §7.2 | DRIFTED (actual 16) |
| Skills count: ~32 | Diff §12 | DRIFTED (actual 34) |
| Type: TODO(version) only on 5 BDs (BD-151..BD-155) | Diff §3.2.5 | DRIFTED (60+ BDs carry it) |
| Pack-agent file refs to BACKLOG: pack-coder/architect/planner | Diff §7.4 | DRIFTED (pack-reviewer also references) |
| `CLAUDE.md` line citations (Trinity, key-files, etc.) | Both docs | DRIFTED (2-5 line offsets throughout) |

---

## Decision-readiness

The design is **mostly** ready for planner consumption. The locked
shape is sound and well-defended; the parent + diff doc together
close every brief-stated success criterion; the BD enumeration in
§17.3 / §13 maps cleanly to actual code surfaces.

**One BLOCKER (F-1) must close before planner consumption:** the
byte-identity enforcement mechanism documented in the architecture
(detect-only validator + symlink) drifts from the brief's locked
choice (explicit `pack rules-sync` verb). Either the architecture
docs need a §5.2(e) addition naming the verb and the diagnostic
shape, or the locked decision needs reconciliation upstream. Until
this is resolved, BD-X8 (validator extension) and the implicit
"rules sync" implementation BD will be authored against the wrong
mechanism.

**Six SHOULD-FIX items (F-2..F-7) are decision-affecting** but do
not blockade the planner — they identify gaps the planner will hit
and would need to either resolve in-batch or escalate back to the
architect. Each names the specific question the design has to answer.

**Eight NITs (F-8..F-15) are mechanical drift** — citation lines,
counts, internal cross-references. They are unblocking and can be
swept during planner authoring or absorbed into the implementation
batch. The CLAUDE.md line-number drift is especially worth a
mechanical refresh before the docs are archived under
`maintenance-docs/v11-implementation/`.

ARCHITECTURE-PER-ENTRY-REVIEW-COMPLETE: 2026-05-12 — Design is sound and decision-ready modulo F-1 (rules-sync verb mechanism drift) and the six SHOULD-FIX gaps the planner must close before BD authoring.
