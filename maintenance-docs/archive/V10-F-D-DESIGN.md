# V10-F-D-DESIGN — METHODOLOGY.md canonical location resolution

**Author:** pack-architect (Phase 4 patch design pass)
**Date:** 2026-04-29
**Status:** Draft — design pass only. Implementer (parent pack chat) commits
after project-lead approval. This document does not edit any pack source file.
**Related:** `maintenance-docs/V10-PHASE-4-VERIFICATION.md` § F-D (proposed;
v10.0 ship-blocker candidate); F-C (legacy `docs/pack/METHODOLOGY.md` not
cleaned up); §4.6 OT migration evidence; §4.7 M-OT post-migration kickoff
evidence.

---

## 0. Status and scope

The v10 pack is internally inconsistent about where `METHODOLOGY.md` belongs.
Three sources disagree:

| Source | Says METHODOLOGY.md belongs at... |
|---|---|
| `project-template/CLAUDE.md` line 275 (and AGENTS.md/GEMINI.md parallels) | `docs/pack/METHODOLOGY.md` |
| `project-template/CLAUDE.md` line 279 ("Root-level files: ...") | not in root list — implies docs/pack |
| `scripts/init-project.sh` line 368–373 (S6 stage, with explicit comment "lives at project root per v10 convention") | project root |
| `scripts/migrate-v9-to-v10.sh` lines 347–352 (S5 stage) | project root |
| `supporting-docs/MIGRATION-v9-to-v10.md` line 150 ("METHODOLOGY.md at project root") | project root |
| `project-template/skills/pm-startup/SKILL.md` line 45 (`git log ... -- docs/pack/METHODOLOGY.md`) | docs/pack |
| `maintenance-docs/V10-DESIGN.md` line 2668 (init-banner spec — "Methodology & templates: docs/pack/") | **docs/pack** |
| `maintenance-docs/V10-DESIGN.md` line 2691 (init S6 stage spec — "Copy `docs/pack/` content: `METHODOLOGY.md`, ...") | **docs/pack** |
| `maintenance-docs/V10-DESIGN.md` line 2333 (migration S5 stage spec — "Trinity + docs/pack splice merge ... for ... `PM-CHAT.md`, `METHODOLOGY.md`") | **docs/pack** |

This is not a 50/50 split. The **approved design document (V10-DESIGN.md)
specifies `docs/pack/METHODOLOGY.md`**. The trinity files (CLAUDE.md /
AGENTS.md / GEMINI.md), the developer-facing init banner, and the
pm-startup skill all agree with the approved design. The two
implementation scripts and the MIGRATION user-facing guide are the
outliers — they are implementation drift away from the approved spec.

Scope of this design pass:

- Decide the canonical location.
- Identify every file that needs to change.
- Specify the migration script's behavior in both pre-migration states.
- Confirm F-C scope under the chosen direction.
- Verify trinity-rule compliance.
- Flag open questions for project lead.

Out of scope (deferred to implementation):

- Producing diffs.
- Editing any pack source file.
- Filing the BD-NNN entry (Pack Chat owns).
- Verification fixture rebuild planning (Pack Chat / pack-planner own).

---

## 1. Decision

**Canonical location: `docs/pack/METHODOLOGY.md`.**

V10-DESIGN.md is the authoritative design input for v10.0 (per its own
"How to use this document" section). It explicitly places METHODOLOGY.md
under `docs/pack/` in three independent places (Parts 7 init S6 stage,
migration S5 stage, and the developer-facing transition notice). The
trinity files were updated to reflect this design. The two scripts and
the MIGRATION user-facing doc drifted off-spec during implementation.

The fix is to restore the implementation to match the approved design:
move the install/migration target back to `docs/pack/METHODOLOGY.md` and
correct the user-facing migration doc to match.

---

## 2. Rationale

### 2.1 Authority hierarchy

V10-DESIGN.md is the approved design record (status: APPROVED, 2026-04-21,
project-lead-signed). The trinity files in `project-template/` derive
from V10-DESIGN.md. The scripts implement V10-DESIGN.md. When
implementation diverges from approved design, **the design wins by
default** unless a separate approved decision overrode it. No such
overriding decision exists; the comment in `init-project.sh` line 368
("METHODOLOGY.md lives at project root per v10 convention") asserts a
"v10 convention" but cites no design record and contradicts the actual
v10 design.

### 2.2 Semantic framing — METHODOLOGY is pack-distributed content

The framing question the project lead asked: is METHODOLOGY.md
**pack-distributed content** (lives alongside PM-CHAT.md,
PLATFORM-SKILLS.md, PACK-FEEDBACK.md, prompts/) or **project-level
convention** (lives alongside CLAUDE.md, AGENTS.md, GEMINI.md, README.md)?

METHODOLOGY.md is unambiguously pack-distributed:

- Source path: `supporting-docs/METHODOLOGY.md` (pack-owned)
- Edited by: pack maintainers only; never by the project
- Updated by: pack version updates only (matches the trinity table's
  "Updated by" column for `docs/pack/`)
- Never customized per-project (no project-specific sections, no
  splice/merge, no placeholders)
- Travels in lockstep with PM-CHAT.md, PLATFORM-SKILLS.md, prompts/ —
  all pack docs version-bound to a specific pack release

The trinity context files (CLAUDE.md / AGENTS.md / GEMINI.md) by
contrast are **project-customized**: they carry `[PROJECT_NAME]`,
`[PLATFORM_TARGETS]`, `[PLATFORM_DEFAULTS]` placeholders, an
**Active skills:** line that the PM chat fills in, and `## Custom
agents` / `## Custom skills` sub-sections that the project owns.
README.md is project-owned. `agent-run.sh` is the only pack-shipped
file at root, and it is at root because it must be invokable as
`./agent-run.sh` from cwd by humans — that's a tool-affordance reason,
not a convention reason.

The "pack-distributed vs project-customized" framing therefore wins
cleanly: METHODOLOGY.md belongs with the other pack-distributed docs
under `docs/pack/`.

### 2.3 Downstream agent confusion (M-OT evidence)

Per V10-PHASE-4-VERIFICATION.md §4.7, the M-OT post-migration kickoff
assistant read the trinity, identified `docs/pack/` as canonical,
observed the v10 file was at root, and recommended `git mv root →
docs/pack/`. **The assistant reasoned correctly from the trinity.**
The trinity is the source AI agents read at every session start; it
is the authoritative project map. The fact that an agent given access
to all three sources (trinity, scripts, V10-DESIGN.md if available)
arrived at "docs/pack is canonical" is positive evidence that this
location is the natural reading of the design.

### 2.4 Symmetry with PM-CHAT.md

PM-CHAT.md is also pack-shipped, also pack-version-bound, and also
edited only at pack version updates. It already lives at
`docs/pack/PM-CHAT.md` per V10-DESIGN.md and the scripts implement
that correctly. METHODOLOGY.md is the same kind of file; placing it
at `docs/pack/METHODOLOGY.md` is the symmetric choice. Putting it
at root would create a one-off carve-out with no semantic justification.

### 2.5 Design elegance — fewer special cases

The pack design philosophy (per CLAUDE.md repo rules and V10-DESIGN.md
Part 1) prefers fewer files, fewer conventions, fewer special cases.
The current root location is a special case: every other pack-shipped
doc lives under `docs/pack/`; METHODOLOGY.md alone goes to root.
Moving it to `docs/pack/` removes the special case.

---

## 3. Rejected alternative — METHODOLOGY at root (option (a) in F-D entry)

The F-D entry's option (a) is "make trinity match scripts" — i.e.,
update CLAUDE.md / AGENTS.md / GEMINI.md to remove METHODOLOGY.md from
the `docs/pack/` row and add it to the Root-level files line. Pros it
listed:

**(a) "Smaller change."** True only if measured in trinity-line edits.
But it requires updating V10-DESIGN.md (the approved design record) to
retroactively justify the drift, which is a much larger conceptual
change — overturning an APPROVED design document via implementation
fait accompli. The design-document edit is the heaviest cost, not the
trinity edit. Net change is **larger** under (a) than under (b) once
V10-DESIGN.md is included.

**(a) "METHODOLOGY at root matches user expectations of pack-vs-project
file separation (METHODOLOGY is project-level convention; docs/pack/ is
pack-distributed material)."** This framing is the inverted one and
does not survive scrutiny. METHODOLOGY.md is pack-distributed
material — it ships from `$PACK/supporting-docs/METHODOLOGY.md`, is
pack-version-bound, never project-customized, edited only by pack
maintainers. The "project-level convention" framing conflates "lives
at project root" with "is project-owned content." `agent-run.sh` lives
at project root and is pack-owned; READMEs live at root and are
project-owned. Root location does not imply ownership. METHODOLOGY's
content semantics are pack-owned; placing it at root does not change
that and creates a misleading visual signal.

**Why option (a) is genuinely worse, not just equivalent:**

1. Overturns approved design without a re-design pass.
2. Creates a permanent special case at root (METHODOLOGY alone among
   pack-distributed docs).
3. Diverges from the M-OT-observed agent reasoning (which arrived at
   docs/pack from the trinity).
4. Forces user-facing migration doc to keep saying "at root" — a
   self-perpetuating drift.
5. The "smaller-change" pro evaporates once V10-DESIGN.md edit is
   counted.

The only real cost of option (b) (chosen) over option (a) is a
slightly larger script edit — see §4 below. That cost is paid once.

---

## 4. Cascade — files that change

Every file in the pack repo affected by the decision. Listed by area;
implementer (or pack-planner) sequences the commits.

### 4.1 Scripts — install path correction (the actual defect fix)

| # | File | Change |
|---|---|---|
| 1 | `scripts/init-project.sh` lines 368–375 | Change comment from "METHODOLOGY.md lives at project root per v10 convention" to "METHODOLOGY.md lives at `docs/pack/` per V10-DESIGN.md §7.6 S6." Change `cp` target from `"$TARGET/METHODOLOGY.md"` to `"$TARGET/docs/pack/METHODOLOGY.md"`. Change the existing-project skip-check from `-f "$TARGET/METHODOLOGY.md"` to `-f "$TARGET/docs/pack/METHODOLOGY.md"`. (Note: the surrounding loop already copies all `*.md` from `$pack_docs/` into `docs/pack/` — `METHODOLOGY.md` lives in `supporting-docs/`, not `project-template/docs/pack/`, so a separate copy is still needed; no merge into the loop.) |
| 2 | `scripts/migrate-v9-to-v10.sh` lines 347–352 (S5) | Change backup path and write target. See §5 for full handling-by-pre-state spec. |

### 4.2 User-facing migration doc

| # | File | Change |
|---|---|---|
| 3 | `supporting-docs/MIGRATION-v9-to-v10.md` line 150 (S5 stage description) | Change "PM-CHAT.md at `docs/pack/`; METHODOLOGY.md at project root" to "PM-CHAT.md and METHODOLOGY.md at `docs/pack/`" (now uniform). |

### 4.3 Trinity files — no change required

`project-template/CLAUDE.md`, `AGENTS.md`, `GEMINI.md` already say
`docs/pack/METHODOLOGY.md` (line 275, 198, 229 respectively). The
"Root-level files" line correctly omits METHODOLOGY.md. The trinity
is already aligned with the chosen direction. **No trinity edit
required, therefore no trinity-rule consideration arises.** This is
clean.

### 4.4 pm-startup skill — already correct

`project-template/skills/pm-startup/SKILL.md` line 45 already runs
`git log ... -- docs/pack/METHODOLOGY.md`. **No change required.**
(This was a latent defect under the current root convention — the
git log command would silently return nothing on a project where
METHODOLOGY was at root. Restoring docs/pack as canonical implicitly
fixes this latent defect too.)

### 4.5 Project-template README

| # | File | Change |
|---|---|---|
| 4 | `project-template/README.md` line 12 (`cp ... METHODOLOGY.md /path/to/your/project/`) | Change destination to `/path/to/your/project/docs/pack/METHODOLOGY.md`. Add `mkdir -p docs/pack` before the `cp` if not already implied. |
| 5 | `project-template/README.md` line 37 ("docs copied individually during setup (METHODOLOGY.md)") | Update prose to reflect docs/pack destination. |

(Implementer should verify whether project-template/README.md is
shipped to projects or only used during pack development — if shipped,
this is a user-facing change; if dev-only, it's a doc-hygiene change.
Either way, the edit is safe.)

### 4.6 Verification fixtures

The §4.4 / §4.6 / §4.7 verification evidence in V10-PHASE-4-VERIFICATION.md
was captured against the root-canonical implementation. The evidence
itself is historical and doesn't need rewriting. But:

- F1 fixture (built fresh by `init-project.sh` during Pre-flight per
  §4.1) currently has METHODOLOGY at root. After the script fix, a
  fresh F1 build will have it at `docs/pack/`. **No fixture file edit
  required** — the fixture is built by the script.
- Any verification check that asserts "METHODOLOGY.md at root" needs to
  flip to "METHODOLOGY.md at docs/pack/". Implementer should grep
  `V10-PHASE-4-VERIFICATION-PLAN-v2.md` for explicit path assertions.

| # | File | Change |
|---|---|---|
| 6 | `maintenance-docs/V10-PHASE-4-VERIFICATION-PLAN-v2.md` (if it asserts METHODOLOGY path) | Update assertion paths from root to `docs/pack/`. |

### 4.7 Pack-repo CLAUDE.md / README.md / V10-DESIGN.md

No change required. V10-DESIGN.md already says `docs/pack/`; this
patch is bringing implementation in line with V10-DESIGN.md, not the
other way around. Repo-level CLAUDE.md and README.md don't reference
METHODOLOGY's path.

### 4.8 Total touch surface

**5 files to edit** (rows 1–5), of which 2 are scripts, 1 is a
user-facing migration doc, 2 are project-template README. Optionally
1 verification plan file (row 6). Compare to option (a)'s touch
surface: 3 trinity files + 1 V10-DESIGN.md edit + scripts unchanged
+ user-facing migration doc unchanged = 4 files, but with the
V10-DESIGN.md edit being a design-overruling change rather than a
mechanical alignment.

---

## 5. Migration script — pre-state handling

The migration script must handle both possible pre-migration states
of `METHODOLOGY.md` in a v9.3 user project. Per §4.6 evidence, real
v9.3 projects had it at `docs/pack/`. Per the synthetic §4.4 fixture,
some had it at root. Both states are possible and the script must
be robust.

### 5.1 Pre-migration state matrix

| State | What's there pre-migration | What should be there post-migration |
|---|---|---|
| A | `docs/pack/METHODOLOGY.md` only (v9.3 OT case) | `docs/pack/METHODOLOGY.md` (overwritten with v10 content) |
| B | `METHODOLOGY.md` at root only (synthetic §4.4 case) | `docs/pack/METHODOLOGY.md`; root file removed |
| C | Both present (impossible in clean v9.3, but possible if a project ran a v10-dev migration mid-flight — observed in §4.6 post-migration: the F-C case) | `docs/pack/METHODOLOGY.md` (v10 content); root file removed |
| D | Neither present (v9.3 project that never installed METHODOLOGY) | `docs/pack/METHODOLOGY.md` (newly written) |

### 5.2 Script behavior — proposed S5 logic

```
# Backup any pre-existing copies (both locations)
if [[ -f docs/pack/METHODOLOGY.md ]]; then
    mkdir -p "$BACKUP_DIR/docs/pack"
    cp docs/pack/METHODOLOGY.md "$BACKUP_DIR/docs/pack/METHODOLOGY.md"
fi
if [[ -f METHODOLOGY.md ]]; then
    cp METHODOLOGY.md "$BACKUP_DIR/METHODOLOGY.md"
fi

# Write canonical v10 content to docs/pack/
if [[ -f "$PACK/supporting-docs/METHODOLOGY.md" ]]; then
    mkdir -p docs/pack
    cp "$PACK/supporting-docs/METHODOLOGY.md" docs/pack/METHODOLOGY.md
fi

# Remove stale root copy if present (states B and C)
if [[ -f METHODOLOGY.md ]]; then
    rm METHODOLOGY.md
fi
```

This logic is safe across all four states:
- **State A:** root file does not exist; rm is skipped.
- **State B:** root backed up, then removed.
- **State C:** both backed up; root removed; docs/pack overwritten.
- **State D:** nothing to back up; docs/pack written fresh.

Backup of both locations preserves the rollback contract — the
v10 script can always restore the v9.3 pre-state.

### 5.3 init-project.sh — analogous logic for existing-project class

For `existing-*` classes (per init-project.sh `$CLASS` variable),
init-project.sh's S6 should:

```
mkdir -p "$TARGET/docs/pack"
if [[ "$CLASS" == existing-* && -f "$TARGET/docs/pack/METHODOLOGY.md" ]]; then
    info "SKIP METHODOLOGY.md at docs/pack (exists)"
elif [[ -f "$PACK/supporting-docs/METHODOLOGY.md" ]]; then
    cp "$PACK/supporting-docs/METHODOLOGY.md" "$TARGET/docs/pack/METHODOLOGY.md"
fi

# Cleanup: if existing project has a stale root METHODOLOGY.md from a
# pre-fix v10 install, leave it alone. init-project.sh is not a
# migration script and should not delete files. Surface to operator
# via the end-of-run report instead.
if [[ "$CLASS" == existing-* && -f "$TARGET/METHODOLOGY.md" ]]; then
    info "WARN: stale METHODOLOGY.md at project root (move or delete; canonical is docs/pack/METHODOLOGY.md)"
fi
```

The asymmetry — `init-project.sh` warns; `migrate-v9-to-v10.sh`
removes — is intentional. The migration script has explicit licence
to mutate project state per its design (it backs up everything it
touches). `init-project.sh` should not silently delete a file the
operator may have created intentionally; it warns instead.

---

## 6. F-C scope under the chosen decision

F-C in V10-PHASE-4-VERIFICATION.md is currently scoped as: "v9.3
project's `docs/pack/METHODOLOGY.md` is not removed by migration; new
v10 root file is written; project ends up with two copies."

Under the chosen decision (canonical = `docs/pack/`), F-C **inverts and
auto-resolves**:

- The migration script writes the v10 content **to `docs/pack/`**
  (overwriting the v9.3 file in place, with backup).
- The migration script **removes any pre-existing root copy**
  (handling pre-state B / C; see §5.2).
- The "two copies" defect cannot occur because both possible source
  locations are addressed: `docs/pack/` is the write target, root is
  the cleanup target.

**F-C scope under this decision:** "Migration script removes stale root
`METHODOLOGY.md` if present (pre-states B and C of §5.1)." This is
satisfied by the §5.2 logic above and does not require a separate
fix — F-C and F-D are resolved by one cohesive script edit.

Recommend collapsing F-C into F-D's BD-NNN entry. The two were filed
separately because they were observed separately (F-C in §4.6, F-D in
post-§4.8 inspection), but at fix time they are one change.

---

## 7. Trinity-rule compliance

Per CLAUDE.md trinity rule: when modifying `project-template/CLAUDE.md`,
make the parallel edit in `AGENTS.md` and `GEMINI.md` in the same commit.
Symmetry is the default; asymmetry requires justification.

**Under this decision, trinity files are not modified.** The trinity
already says `docs/pack/METHODOLOGY.md` (line 275 / 198 / 229
respectively, parallel and symmetric). The script and migration-doc
edits restore implementation to match trinity.

**Trinity-rule status: clean. No trinity changes required.**

If implementer encounters any trinity drift during the cascade
(e.g., an `AGENTS.md` or `GEMINI.md` line that lags CLAUDE.md), it
should be addressed as a separate trinity-symmetry fix — not as part
of this F-D patch.

---

## 8. Self-check against V10-DESIGN.md philosophy

V10-DESIGN.md establishes the layered project structure with three
docs subdirectories:

- `docs/pack/` — pack-distributed; updated by pack version updates only
- `docs/project/` — project-customized; updated by PM chat and developer
- `docs/reference/` — project-specific user-facing docs

The trinity table row codifies this. Placing METHODOLOGY.md at
`docs/pack/` is **the only choice that respects this layering.** Root
placement breaks layering by giving one pack-distributed file
special-case treatment.

V10-DESIGN.md Part 13 lists open items deferred to v10.1 — METHODOLOGY
location is not among them. The location was not deferred; it was
decided (Part 7 §7.6). The implementation simply drifted.

**Conclusion: this decision is consistent with v10 design philosophy
and does not introduce a new internal inconsistency.** It removes one.

---

## 9. Open questions for project lead

**OQ-F-D-1.** Is `project-template/README.md` shipped to projects (per
init-project.sh) or used only during pack development?
*Resolution path: grep the install scripts for `project-template/README.md`
to see if it copies. If shipped: row 5 above is user-facing. If
dev-only: row 5 is doc-hygiene only. Doesn't change the decision; only
the urgency of row 5.*

**OQ-F-D-2.** Is METHODOLOGY.md ever loaded by an agent via `@-reference`
syntax (e.g., `@docs/pack/METHODOLOGY.md` in a Gemini prompt or
`@METHODOLOGY.md` in a Claude command)?
*If yes, every such reference must be updated. Grep result above shows
no `@METHODOLOGY` or `@docs/pack/METHODOLOGY` references in pack
content. Recommend implementer re-greps under both forms during the
plan pass to confirm. The pm-startup SKILL.md path (`docs/pack/METHODOLOGY.md`)
is via shell (`git log -- ...`), not @-reference.*

**OQ-F-D-3.** Does the §4.4 / §4.6 / §4.7 verification evidence need
to be re-captured against the corrected scripts before v10.0 ship, or
is "delta evidence" (run the migration once, confirm METHODOLOGY at
docs/pack/, no root copy) sufficient?
*Recommend: delta evidence only. The full §4.6 / §4.7 runs already
exercised every other migration surface; only the METHODOLOGY path
assertion changes. A targeted post-fix smoke run is proportionate.*

**OQ-F-D-4.** Should the BD-NNN entry combine F-C and F-D (since the
fix is unified per §6) or keep them separate for traceability?
*Recommend: combine. The defects share one root cause (the install/migration
target was wrong) and one fix. Separate entries suggest separate fixes
and may confuse downstream review. If traceability to the §4.6
discovery vs. the post-§4.8 discovery matters, capture it in the
"Context" field of the combined entry.*

**OQ-F-D-5.** Does `mcp-local-rag` ingest path need updating?
*The `.mcp.json.example` at `project-template/.mcp.json.example` line 3
mentions METHODOLOGY but does not specify a path. SETUP-NEW.md line 311
("Ingest METHODOLOGY.md into the RAG index") also doesn't specify a
path. Implementer should verify the actual ingest invocation (likely in
SETUP-NEW.md or a script) does not hardcode root.*

---

## 10. Summary

**Decision:** canonical METHODOLOGY.md location is `docs/pack/METHODOLOGY.md`.

**Why:** V10-DESIGN.md (the approved design record) prescribes it;
trinity files already reflect it; the M-OT assistant's reasoning
confirms it; pack-distributed-content semantics support it; symmetry
with PM-CHAT.md / PLATFORM-SKILLS.md / PACK-FEEDBACK.md compels it.

**Cost:** 5 file edits (2 scripts, 1 user-facing migration doc, 2
project-template/README lines), one optional verification-plan-doc
edit. No trinity changes. No V10-DESIGN.md changes.

**Side effect:** F-C is auto-resolved by the same script edit;
recommend combining into one BD-NNN.

**Trinity-rule:** clean (no trinity changes).

**Open questions:** 5, listed in §9; none block project-lead approval.

