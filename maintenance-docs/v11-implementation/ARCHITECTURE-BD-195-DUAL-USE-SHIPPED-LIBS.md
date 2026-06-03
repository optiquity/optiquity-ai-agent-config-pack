# ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS

**Status:** Strategy + recommendation (read-only pack-architect pass). No
source edits, no git state change. Pack Chat brings this to the user; the user
decides.
**Branch:** `v11-dev`. **HEAD at design:** `bb9e807`
(`bb9e80722d282ea4272c90f012d8ba63552d4e04`). **Date:** 2026-06-02.
**Trigger:** BD-195 remediation surfaced a conflict between the
directory-based-not-ship-based boundary rule and the C2/Check-43 walk-set,
which treats `scripts/lib/detect.sh` (a pack-side file) as a client surface.
The remaining fix-commits (C3c, PG-2) wait on this decision.

**Scope of decision.** A,B,C,D,E below. The governing question: where does a
file that is USED pack-side AND DELIVERED to clients belong, and how is its
pack-self content (BD-NNN comments, `pack-ops/` refs) handled.

---

## 0 — Bottom line up front

- **(A) Location/ship:** The DELIVERABLE belongs in a project-side directory.
  The cleanest end-state is to **promote the client deliverable into
  `project-template/scripts/` (the project-side scripts tree that already ships
  ~15 sibling helpers) and let `init-project.sh` SOURCE it from there for its
  own pack-side use.** This eliminates the dual-location contradiction at the
  root: one file, in a project-side directory, used both ways. Two viable
  shapes (single-file-in-project-template vs. two-copies) are analyzed; the
  single-file shape wins on the divergence evidence (B).
- **(B) Divergence:** The pack-side use and the client-side use are **NOT
  divergent and are very unlikely to diverge** — the client invokes exactly ONE
  function (`detect_pack_surface`); the pack invokes that PLUS the rest. The
  client's used-set is a strict SUBSET of the pack's used-set. A two-copy
  design would be a pure drift-risk with no divergence benefit. Evidence in §B.
- **(C) Pack-self content:** The BD-NNN comments + `pack-ops/`/`AUDIT-*`/
  `ARCHITECTURE-*` prose are pack-self references on a client-shipped surface →
  they violate `bd-pack-only-operational-rule` regardless of where the file
  ultimately lives, because the file IS delivered. They must be **stripped /
  reworded to client-appropriate rationale**; any genuinely pack-only
  explanatory content (the design history) belongs in a pack-side doc
  (the architecture/audit records), not in the shipped script.
- **(D) Reconcile artifacts:** The C2/Check-43 walk-set is **CORRECT to treat
  these files as client surfaces** — it keys off ship-status because its JOB is
  to protect the client install, and these files ARE installed. NL-2/NL-3
  **STAND** as genuine leaks. But this exposes a deeper inconsistency: the
  boundary RULE is directory-based while the GUARD is ship-based, and today
  they disagree only because a shipped file sits in a pack-side directory.
  Fixing (A) makes rule and guard agree. C3c's reword is still needed in the
  interim; its long-term form changes if (A) lands.
- **(E) Systemic:** **Exactly two** files have this property —
  `scripts/pack-help.sh` and `scripts/lib/detect.sh`. The authoritative
  `_CLIENT_INSTALLED_FILES` map confirms no other non-`project-template/`,
  non-`supporting-docs/` file is client-installed. The problem is bounded.

---

## A — Correct location and ship mechanism

### A.1 — The governing principle

State the principle for a file that must be USED pack-side AND DELIVERED to
clients:

> **A client deliverable lives in a project-side directory; the pack consumes
> it FROM that project-side location for its own use. Ship-status follows
> location, not the reverse — a file is never parked in a pack-side directory
> and then declared "also shipped." The delivery direction is one-way
> (project-template → client); the pack reading its own deliverable is the
> pack acting as its own first client.**

This is the direct corollary of the two standing rules read in full:

- `bd-pack-only-operational-rule`: "Directory-based, NOT ship-based — the
  rule's trigger is the file's location, not whether `init-project.sh` copies
  it today." The rule treats LOCATION as the source of truth for what content
  is allowed.
- `pack-project-separation-of-concerns`: "Script copying to a CLIENT install
  path MUST source from `project-template/` (NEVER `pack-ops/`, pack-root
  `scripts/`, `maintenance-docs/`)." The worked example (BD-185 Code Red 2,
  `init-project.sh:823-825`) is the EXACT precedent: a client-install copy was
  sourced from a pack-side path (`pack-ops/HELP-FRAGMENT-TRACKER.md`) and that
  was ruled a violation; corrected to source from
  `project-template/docs/pack/HELP-FRAGMENT.md`.

`detect.sh`/`pack-help.sh` are the same anti-pattern as BD-185 Code Red 2,
one layer down: a file is COPIED to a client install path
(`$TARGET/scripts/...`) but SOURCED from the pack-side `scripts/` tree
(`$PACK/scripts/...`) instead of from `project-template/`. The boundary rule
and the separation rule both say the deliverable's home is project-side.

### A.2 — Preliminary conclusion

Promote both files to `project-template/scripts/`:

- `project-template/scripts/pack-help.sh`
- `project-template/scripts/lib/detect.sh`

`init-project.sh`'s client-install stage S11 then copies them via the SAME
bulk `project-template/` mechanism that already ships the ~15 sibling scripts
(`format.sh`, `validate.sh`, `proto-gen.sh`, …), instead of the special-case
`cp -f "$PACK/scripts/..."` block at `init-project.sh:887-898`. The pack's OWN
use (`init-project.sh:79`, `add-capability.sh:89`, `migrate-v10-to-v11.sh`)
sources `detect.sh` from `project-template/scripts/lib/detect.sh`.

### A.3 — CHALLENGE (HIGH bar — boundary-with-existing-pack)

This decision changes where the pack sources its own runtime library. Three
strong counter-arguments:

1. **"The pack repo's own scripts shouldn't depend on `project-template/` for
   their runtime — that inverts the dependency direction."** Counter-counter:
   the inversion is exactly what `pack-project-separation-of-concerns`
   PRESCRIBES — "Script copying to a CLIENT install path MUST source from
   `project-template/`." The pack already does this for HELP-FRAGMENT after
   BD-185 Code Red 2. `init-project.sh` sourcing `detect.sh` from
   `project-template/scripts/lib/` is the pack reading its own deliverable; the
   pack is the deliverable's first consumer. This is not a novel inversion —
   it is the established post-BD-185 pattern.

2. **"Moving runtime libs into `project-template/` risks the test harness,
   manifest, and ~10 callers."** Counter-counter: this is a SIZE/blast-radius
   concern, not a correctness objection — it argues for careful planning
   (planner pass), not for keeping the leak. Per `deferral-is-scope-creep` +
   `no-deferral-without-user-direction`, blast-radius is a SCOPING signal, not
   an authority to leave the contradiction. The blast radius is fully
   enumerated in §D.3 so the user can scope it.

3. **"C3c already reworded the comments; isn't the leak gone without the
   move?"** Counter-counter: C3c removes the CONTENT leak (NL-2/NL-3) but
   leaves the STRUCTURAL contradiction — a shipped file in a pack-side
   directory, where the boundary RULE (directory-based) and the GUARD
   (ship-based) permanently disagree about what content is allowed. Every
   future edit to `detect.sh` re-litigates "is this a pack surface or a client
   surface?" The move resolves the contradiction once; the reword only treats
   the current symptom. See §D.2.

**Settled position after challenge:** Promote to `project-template/scripts/`
(single-file shape, §B). The structural fix is the correct end-state; C3c's
content reword remains necessary in the interim because the move is larger and
must be planned. **Recommended sequencing: do C3c's reword now (unblocks PG-2),
and open a tracked BD for the structural promotion** (anchored per
`deferred-work-tracked-anchor`; not a silent v11.1 punt per
`no-deferral-without-user-direction` — the user decides whether the promotion
lands in v11.0 or is explicitly deferred).

> **Note on whether C3c is even needed if the move lands in v11.0.** If the
> user chooses to do the structural promotion WITHIN v11.0 and BEFORE PG-2
> pushes, then C3c's reword and the move can be combined: the move commit
> carries the comment reword. If the move is deferred, C3c is the standalone
> interim fix. Both paths end with zero pack-self content in the shipped file;
> they differ only in whether the file's directory is corrected now or later.
> This is the open user decision §A.4.

### A.4 — The decision the user owns

| Option | What lands in v11.0 | Residual |
|---|---|---|
| **Opt-1: Reword-only (C3c as planned)** | NL-2/NL-3 content reworded; file STAYS in pack-side `scripts/`; guard keeps walking it via `_CLIENT_INSTALLED_FILES`. | STRUCTURAL contradiction remains (shipped file in pack-side dir); tracked-BD for the promotion. |
| **Opt-2: Structural promotion in v11.0** | Files move to `project-template/scripts/`; init/migrator source from there; comment reword folded in; `_CLIENT_INSTALLED_FILES` special-case removed. | None — rule and guard agree. Larger blast radius (§D.3). |
| **Opt-3: Reword now + promotion as tracked v11.0 BD later in the plan** | C3c reword now (unblocks PG-2); promotion as a separate scheduled BD before Batch 24. | Interim contradiction until the promotion BD fires. |

**Architect recommendation: Opt-3.** It unblocks PG-2 immediately (C3c is
already specified and review-ready), preserves the bounded review/fix cycle per
commit, and schedules the real structural fix to a tracked anchor inside v11.0
(honoring `no-deferral-without-user-direction`). Opt-1 leaves a permanent
contradiction; Opt-2 is correct but enlarges the in-flight PG-2 push group
beyond what is already specified. The user retains final authority.

#### Empirical-Evidence Block — EEB-A1 (the special-case ship block exists)

- **Command:** `Read scripts/init-project.sh:882-898`
- **Output (verbatim, key lines):**
  ```
  882	    # 5. The pack-help shell script + its single dep (lib/detect.sh).
  888	    if [[ -f "$PACK/scripts/pack-help.sh" ]]; then
  889	        cp -f "$PACK/scripts/pack-help.sh" "$TARGET/scripts/pack-help.sh"
  892	    if [[ -f "$PACK/scripts/lib/detect.sh" ]]; then
  893	        cp -f "$PACK/scripts/lib/detect.sh" "$TARGET/scripts/lib/detect.sh"
  ```
- **HEAD/date:** `bb9e807` / 2026-06-02.
- **Interpretation:** the two files ship via a special-case block sourcing
  `$PACK/scripts/...` (pack-side), not via the bulk `project-template/` copy.
- **Conclusion:** SUPPORTED — the ship is from a pack-side directory; this is
  the BD-185-Code-Red-2 anti-pattern one layer down.

#### Empirical-Evidence Block — EEB-A2 (siblings ship cleanly from project-template/scripts/)

- **Command:** `find project-template/scripts -type f`
- **Output (verbatim):** 16 files — `validate.sh test-swift.sh
  agent-post-edit-check.sh format-swift.sh proto-gen.sh test-python.sh
  validate-swift.sh bootstrap.sh bootstrap-swift.sh format-python.sh
  validate-proto.sh bootstrap-python.sh test.sh validate-python.sh format.sh`
  (15 listed in the recursive walk; `agent-post-edit-check.sh` + the bootstraps
  included).
- **HEAD/date:** `bb9e807` / 2026-06-02.
- **Interpretation:** a project-side `scripts/` tree already exists and ships
  ~15 client helper scripts via the normal bulk mechanism. The prompt's claim
  that these carry ZERO BD-NNN refs is verified in EEB-E.
- **Conclusion:** SUPPORTED — `project-template/scripts/` is the natural,
  precedented home for a client-shipped script; no new directory or convention
  is introduced by the move (design-elegance: fewer special cases).

---

## B — Dual-use divergence analysis (load-bearing)

The question: could the pack-side use and the client-side use of `detect.sh`
(and `pack-help.sh`) REASONABLY DIVERGE in the future (justifying two copies),
or are they identical (so two copies = drift risk)?

### B.1 — The used-set evidence

`pack-help.sh` (the only client entrypoint that sources `detect.sh`) invokes
exactly ONE detect.sh function: `detect_pack_surface` (`pack-help.sh:63`).

The pack-side callers invoke the rest:
- `init-project.sh` calls `swiftdata_marker_detected`,
  `python_data_marker_detected`, `python_observability_marker_detected`,
  `protobuf_marker_detected` (lines 261/300/301/318).
- `add-capability.sh` sources detect.sh (`:89`) for the capability/marker set.
- `migrate-v10-to-v11.sh` / `migrator-core.sh` source it for
  `detect_target_pack_version` + capability translation.

The CLIENT's used-set (`{detect_pack_surface}`) is a strict SUBSET of the
PACK's used-set (`detect_pack_surface` + all marker/capability/version
functions). The functions a client never calls are dead-but-harmless in the
shipped copy.

### B.2 — Preliminary conclusion

The two uses are NOT divergent and are unlikely to diverge:
- The client uses a strict subset; nothing about the client install pulls the
  function set in a different direction from the pack.
- `detect_pack_surface` itself is intentionally dual-surface BY DESIGN — it
  detects pack-vs-client from a single tree and is meant to behave identically
  whether invoked from the pack repo or a client checkout (it is the LCD floor,
  `pack-help.sh:14-18`).
- A two-copy design (pack-side `scripts/lib/detect.sh` for init/migrator,
  project-side `project-template/scripts/lib/detect.sh` for the client) would
  require keeping two byte-identical copies in lock-step forever. Per
  `pack-project-separation-of-concerns`, byte-identity is "coincidence, NEVER a
  design rationale" — but the converse also holds: when there is no divergence
  PRESSURE, forcing two copies manufactures a drift surface with zero benefit.
  The separation rule forbids cross-side SUBSTITUTION (using the pack copy AS
  the client source); it does NOT mandate gratuitous duplication when one
  project-side file can legitimately serve both as the deliverable and as the
  pack's own first-client read.

**Therefore: ONE file in `project-template/scripts/`, consumed both ways.** Not
two copies.

### B.3 — CHALLENGE (HIGH bar)

1. **"`pack-project-separation-of-concerns` says pack and project versions are
   SEPARATE artifacts — doesn't one-file violate that?"** Counter-counter: the
   rule's concern is AUDIENCE divergence (pack-developer vocabulary vs.
   client-developer vocabulary) and SUBSTITUTION (sourcing the client copy from
   the pack path or vice versa). `detect.sh` has NO audience-divergent content
   once the pack-self comments are stripped (C) — it is pure detection logic
   with one dual-surface contract. After the strip, there is no pack-developer
   vocabulary left to diverge. The file becomes a genuine single-audience
   artifact (a detection library), so the single-file shape does not collide
   with the rule. The rule's worked example (HELP-FRAGMENT) involved a DOC with
   real audience content; `detect.sh` post-strip is CODE with one behavior.

2. **"What if a future pack-only detection function must NOT ship to
   clients?"** Counter-counter: this is the only real divergence scenario, and
   it is handled WITHOUT a second copy — a pack-only helper goes in a
   pack-side lib (e.g., `scripts/lib/` retains pack-only detection that is NOT
   sourced by `pack-help.sh`), while the SHARED detection stays in the shipped
   `project-template/scripts/lib/detect.sh`. The split is by FUNCTION
   PLACEMENT, not by duplicating the whole file. Today no such pack-only
   detection function exists that the client must be denied — the marker
   functions are simply unused at the client, not forbidden there. So no split
   is needed now; if one arises, the answer is a new pack-side lib file, not a
   detect.sh fork.

3. **"The marker functions are dead code at the client — shouldn't we strip
   them from the shipped copy (which WOULD force two copies)?"**
   Counter-counter: dead-but-harmless code is not a leak (it contains no
   pack-self references after C; it is generic detection logic). Stripping it
   would (a) force the two-copy drift surface this section argues against, and
   (b) require a build/transform step (generating a client subset from the pack
   superset) — a new mechanism and a new special case, violating
   design-elegance (fewer files, fewer conventions). The token cost of the
   unused functions is real but small and is a SEPARATE, lower-priority
   question (a tracked NIT at most), not a justification for forking the file.

**Settled position after challenge:** ONE shared file in
`project-template/scripts/`. Divergence pressure is absent; a future pack-only
detection need is met by a new pack-side lib, never by forking `detect.sh`.

#### Empirical-Evidence Block — EEB-B1 (client used-set is a strict subset)

- **Command:** `grep -oE "detect_[a-z_]+|_marker_detected" scripts/pack-help.sh | sort -u`
- **Output (verbatim):** `detect_pack_surface`
- **Command:** `grep -rn "python_data_marker_detected\|protobuf_marker_detected\|swiftdata_marker_detected\|python_observability_marker_detected\|detect_installed_capabilities" scripts/ | grep -v lib/detect.sh | grep -v test`
- **Output (verbatim, key):** `init-project.sh:261/300/301/318`
  (`swiftdata_marker_detected`, `python_data_marker_detected`,
  `python_observability_marker_detected`, `protobuf_marker_detected`);
  `migrate-v10-to-v11.sh:536/619` (comment refs).
- **HEAD/date:** `bb9e807` / 2026-06-02.
- **Interpretation:** the client (`pack-help.sh`) calls only
  `detect_pack_surface`; the marker/capability functions are called only by
  pack-side scripts (`init-project.sh`, `add-capability.sh`, the migrator) that
  are NOT in `_CLIENT_INSTALLED_FILES` (EEB-D).
- **Conclusion:** SUPPORTED — client used-set ⊂ pack used-set; no divergence
  vector; two copies would be a pure drift risk.

---

## C — Handling the pack-self content

### C.1 — What must change

The shipped files carry pack-self references that violate
`bd-pack-only-operational-rule` (no pack-self refs on client-shipped content),
INDEPENDENT of the location decision — because the files ARE delivered, the
content rule applies. Inventory (EEB-C):

`detect.sh`: 34 `BD-NNN` occurrences across 10 distinct BDs (BD-035 ×5, BD-075,
BD-114, BD-119, BD-141 ×9, BD-144, BD-156 ×8, BD-157 ×4, BD-162 ×2, BD-175 ×2),
plus `AUDIT-BD-035.md`, `ARCHITECTURE-SKILL-DIMENSIONS.md`, `V10-DESIGN.md`,
`PLATFORM-SKILLS.md`, and `pack-ops/` path references — all in `#` comments
(zero in executable code). **NOTE:** the prompt stated "31 BD-NNN references";
the measured count at HEAD `bb9e807` is **34 occurrences / 10 distinct BDs**
(EEB-C). I record my measurement, not the prompt's figure.

`pack-help.sh`: 6 `BD-NNN` occurrences (BD-075, BD-077, BD-175 ×2, BD-177 ×2),
plus `pack-ops/` path refs and `V3 §`/`DELTA` prose.

### C.2 — Fence coverage gap (load-bearing)

Both files already carry `<!-- DENY-LIST-CONTENT-START/END -->` fences, and
both are on `_CHECK_37_PER_LINE_FENCE_FILES` (validate-pack.py:4236-4239). BUT
the fences cover ONLY the surface-routing blocks — `detect.sh:22-37` and
`:45-47` (the `pack-ops/BACKLOG.md` candidate-scan paths). The BD-NNN comment
prose (including NL-2/NL-3 at `:351`/`:360`) and the
`PLATFORM-SKILLS.md`/`AUDIT-*`/`V10-DESIGN.md` comment refs are OUTSIDE any
fence (EEB-C). So the fence does not legitimize them; they are unfenced
pack-self content on a shipped surface.

Two distinct content classes, two treatments:

1. **Functional dual-surface refs (KEEP via fence):** the `pack-ops/BACKLOG.md`
   candidate-scan paths in `detect_pack_surface` are LOAD-BEARING — the function
   must look for `pack-ops/BACKLOG.md` to detect a pack surface. These are
   correctly fenced and stay. They pass the op-vs-explanatory test
   (`bd-pack-only-operational-rule`): functional treatment that the code needs
   to run = legitimate, fence-covered.

2. **Explanatory pack-self prose (STRIP/reword):** the BD-NNN provenance
   comments (`BD-141 (v11.0 ...)`, `BD-035 audit finding F5 fix — see
   AUDIT-BD-035.md §3`), the `PLATFORM-SKILLS.md cites the helper`
   cross-references, the `V10-DESIGN §5.14.2` / `ARCHITECTURE-SKILL-DIMENSIONS.md`
   citations. These fail the necessity test: a client reader does NOT need the
   pack's BD history to understand the detection heuristic, and the same
   what-it-does intent is conveyable without naming a pack artifact. STRIP the
   pack-self token; preserve the heuristic rationale in client-appropriate
   terms. This is exactly what C3c's recipe does for NL-2/NL-3 — but C3c only
   covers `:351`/`:360`. The OTHER ~30 BD-NNN comment refs in `detect.sh` and
   the 6 in `pack-help.sh` are the SAME class of leak and are NOT in the C3c
   recipe (C3c scopes only the two AUDIT-BD-035 lines the broadened guard
   happened to fire on).

### C.3 — The scope gap C3c does not close (SURFACED, per bd195-prompt-goals Q1/Q2)

Per `bd195-prompt-goals-section` Q1/Q2: a rule violation the agent spots that
is NOT in its assigned finding-set is SURFACED, never silently fixed nor
ignored. **Surfacing:** C3c removes only the two `AUDIT-BD-035.md`/`BD-035`
comment refs that C2's broadened guard fires on (bare-prose doc-basename +
SHA-style provenance). The remaining ~30 `BD-NNN` provenance comments in
`detect.sh` (BD-075/114/119/141/144/156/157/162/175) and the 6 in `pack-help.sh`
(BD-075/077/175/177) are the SAME `bd-pack-only-operational-rule` violation
class on the SAME shipped surface, but the C2 guard does NOT fire on a bare
`BD-NNN` token in a code comment (the broadened guard targets doc-BASENAMES,
SHAs, `supporting-docs/` prefixes, and `.example`/`.proto` extensions — not
bare `BD-NNN` tokens). So they pass CI but are still leaks under the categorical
rule ("BDs are one example ... may [not] appear anywhere in project-related ...
scripts").

This is a real boundary gap, not a C3c defect. The user should decide:
- **(a)** broaden the strip to ALL `BD-NNN` + pack-doc comment refs in both
  shipped files (clean end-state; folds naturally into the structural-promotion
  BD in §A.4 Opt-3), and/or
- **(b)** extend the C2 guard to flag bare `BD-NNN` tokens on client surfaces
  (so the rule is CI-enforced, not honor-system). Per
  `enumerate-encoding-surfaces`, (b) would also require updating Check-43 tests.

**Architect recommendation:** fold (a) into the structural-promotion BD (§A.4
Opt-3) — strip ALL pack-self comment refs from both files in the same commit
that moves them to `project-template/scripts/`. Pair with (b) so the rule is
guarded going forward (measure-then-bound: the move makes the post-fix
`BD-NNN`-on-client count zero, so the guard's allowlist is empty). This is the
single clean end-state; doing only C3c's two lines leaves ~36 same-class leaks
behind.

### C.4 — Where genuinely-needed explanatory content lives

The BD provenance IS valuable — to PACK DEVELOPERS. Its correct home is the
pack-side design record, NOT the shipped script:
- The detection-heuristic design history already lives in
  `maintenance-docs/v11-implementation/` (`ARCHITECTURE-SKILL-DIMENSIONS.md`,
  `AUDIT-BD-035.md`) and `pack-ops/` BACKLOG entries.
- The shipped script keeps only the WHAT (the heuristic's behavior and
  rationale in client-neutral terms); the WHY-this-BD-changed-it stays in the
  pack design docs. This satisfies `pack-project-separation-of-concerns` (pack
  audience content lives pack-side) and the token-economy reason (client RAG
  indexes the shipped script; pack-history tokens cost query-time budget).
- No new doc is invented (NUD-2-style discipline): the design record already
  exists; the strip simply stops duplicating its citations into a client
  surface.

#### Empirical-Evidence Block — EEB-C (pack-self content inventory + fence gap)

- **Command:** `grep -oE "BD-[0-9]+" scripts/lib/detect.sh | sort | uniq -c`
- **Output (verbatim):** `5 BD-035 · 1 BD-075 · 1 BD-114 · 1 BD-119 ·
  9 BD-141 · 1 BD-144 · 8 BD-156 · 4 BD-157 · 2 BD-162 · 2 BD-175` →
  34 total, 10 distinct.
- **Command:** `grep -nE "DENY-LIST-CONTENT" scripts/lib/detect.sh`
- **Output (verbatim):** `22 / 37 / 45 / 47` (two fence blocks only —
  surface-routing).
- **Command:** `grep -nE "AUDIT-|PLATFORM-SKILLS|V10-DESIGN|ARCHITECTURE-" scripts/lib/detect.sh`
- **Output (verbatim, key):** `:253 V10-DESIGN §5.14.2`, `:307
  ARCHITECTURE-SKILL-DIMENSIONS.md §3.5`, `:351/:360 AUDIT-BD-035.md §3`,
  `:252/:328/:365/:487/:594/:723 PLATFORM-SKILLS.md` — ALL outside the
  `22-37`/`45-47` fences.
- **HEAD/date:** `bb9e807` / 2026-06-02.
- **Interpretation:** the fence covers only the functional surface-routing
  paths; the BD/doc provenance prose is unfenced and is the STRIP-class leak.
  C3c covers 2 of ~36 same-class refs.
- **Conclusion:** SUPPORTED — pack-self content is real, unfenced, and broader
  than the C3c scope; the surface-routing `pack-ops/` paths are the legitimate
  fenced KEEP.

---

## D — Reconcile the existing artifacts (C2 guard / Check-43 / NL-2 / NL-3 / C3c)

### D.1 — Is the C2/Check-43 walk-set CORRECT to treat these as client surfaces?

**Yes — the guard is correct as designed.** Check 43's `_iter_client_installed_files`
walks (a) all of `project-template/` plus (b) the explicit non-template entries
in `_CLIENT_INSTALLED_FILES`, which by SSOT includes `scripts/lib/detect.sh`
and `scripts/pack-help.sh` (EEB-D). The guard's JOB is to protect the CLIENT
INSTALL from pack-self contamination. A file that is installed to the client IS
a client surface for the purpose of "what reaches the client," regardless of
its repo-side directory. So the guard MUST key off ship-status — that is the
only way it can catch contamination in a shipped file that happens to live in a
pack-side directory.

The apparent collision with "directory-based, not ship-based" dissolves once
you separate the two rules' JOBS:
- The **boundary rule** (directory-based) governs **what content an AUTHOR may
  place in a file**, keyed to the file's location so authors have a stable,
  location-based contract.
- The **leak guard** (ship-based) governs **what content may REACH a client**,
  keyed to ship-status so nothing contaminating slips through.

They only disagree in ONE situation: a SHIPPED file in a PACK-SIDE directory.
That situation is precisely the BD-185-Code-Red-2 anti-pattern (A), and the
correct resolution is to eliminate the situation (move the file project-side),
not to weaken either rule. After the §A move, the file is in a project-side
directory AND shipped — rule and guard agree, and the
`_CLIENT_INSTALLED_FILES` special-case entry for it can be dropped because the
`project-template/` recursive walk (branch (a)) covers it.

### D.2 — Do NL-2 / NL-3 stand?

**They STAND.** NL-2 (`detect.sh:351`) and NL-3 (`detect.sh:360`) are genuine
`bd-pack-only-operational-rule` violations: `AUDIT-BD-035.md` (a pack-only
maintenance doc) + the `BD-035` token in a comment on a file that IS installed
to clients. The directory-based rule does NOT excuse them — the rule says "Not
shipped today ≠ license to leave a leak," and here the file IS shipped, which
is even stronger. The content is dead-and-meaningless at a client (no
`AUDIT-BD-035.md` exists there) and costs RAG tokens. C3c's reword is correct.

What this analysis ADDS: NL-2/NL-3 are 2 of ~36 same-class refs (C.3). They are
not WRONG to fix; they are INCOMPLETELY scoped. The full fix is C.3(a).

### D.3 — What does C3c become?

Under the recommended Opt-3 (§A.4):

- **Now (PG-2):** C3c proceeds AS SPECIFIED — reword NL-2/NL-3, `pack-only`
  keyword, manifest run-then-check. It unblocks the PG-2 push (the broadened C2
  guard fires on the two AUDIT-BD-035 lines; C3c clears them). No change to the
  current plan is required to ship PG-2.
- **Later (structural-promotion BD):** the file moves to
  `project-template/scripts/lib/detect.sh`; ALL remaining `BD-NNN`/pack-doc
  comment refs are stripped (C.3(a)); the `_CLIENT_INSTALLED_FILES`
  special-case lines (init-project.sh:1309-1310) and the special-case ship
  block (init-project.sh:882-898) are removed; the pack-side sourcing in
  `init-project.sh:79` / `add-capability.sh:89` / migrator is re-pointed to
  `project-template/scripts/lib/detect.sh`; the
  `_CHECK_37_PER_LINE_FENCE_FILES` entries are updated to the new paths; the
  C2 guard's bare-`BD-NNN` extension (C.3(b)) lands with an empty allowlist
  (post-move count zero, per measure-then-bound). `enumerate-encoding-surfaces`:
  the surfaces touched in lock-step are the two moved files, init-project.sh
  (ship block + map), add-capability.sh, the migrator, validate-pack.py (fence
  list + optional guard ext), the Check-43/Check-37 tests, the persona-contract
  scripts that assert the install paths (`contract-greenfield.sh`,
  `contract-migration.sh`), and `test-fixtures/manifest.txt` regen.

If instead the user picks Opt-2 (promotion in v11.0 within PG-2), C3c's reword
is folded into the move commit and C3c-as-a-standalone disappears.

### D.4 — Blast radius of the structural promotion (so the user can scope §A.4)

Enumerated from the consumer map (EEB-D):

1. `scripts/init-project.sh` — `source` at :79 → re-point to
   `project-template/scripts/lib/detect.sh`; remove special-case ship block
   :882-898; remove map lines :1309-1310.
2. `scripts/add-capability.sh:89` — re-point `source`.
3. `scripts/migrate-v10-to-v11.sh:340-347` + `scripts/lib/migrator-core.sh:402-408`
   — re-point the migrator's pack-help/detect copy + on-demand source.
4. `scripts/lib/migrator-stages.sh:408` — comment ref (cosmetic).
5. `scripts/test-detect.sh:22`, `scripts/tests/pack-help-test.sh:23` — re-point
   test `source`.
6. `scripts/validate-pack.py` — `_CHECK_37_PER_LINE_FENCE_FILES` entries
   :4238-4239; `_CLIENT_INSTALLED_FILES` parse (auto-follows the map edit);
   the Check-43 walk auto-covers via branch (a) after the move.
7. `scripts/persona-contracts/contract-greenfield.sh` + `contract-migration.sh`
   — install-path assertions reference `scripts/pack-help.sh`,
   `scripts/lib/detect.sh` as TARGET paths (those are unchanged — the client
   still receives them at `scripts/...`; only the SOURCE moves). Verify the
   contracts assert TARGET not SOURCE.
8. `test-fixtures/manifest.txt` — regen (v11-surface commit;
   `regenerate-manifest-v11-surface`).
9. `project-template/.{claude,codex,gemini}` pack-help skill/command surfaces
   invoke `bash scripts/pack-help.sh` at the CLIENT (target path unchanged).

Critical invariant: the CLIENT-side install TARGET paths
(`$TARGET/scripts/pack-help.sh`, `$TARGET/scripts/lib/detect.sh`) do NOT change
— only the pack-side SOURCE location moves. So no client-facing contract or
slash-command path changes; zero client regressions if the install logic is
re-pointed correctly (Goal 2).

#### Empirical-Evidence Block — EEB-D (authoritative client-installed map + walk-set)

- **Command:** `awk '/_CLIENT_INSTALLED_FILES_START/{p=1;next}
  /_CLIENT_INSTALLED_FILES_END/{p=0} p{print}' scripts/init-project.sh |
  grep -vE "project-template/|supporting-docs/"`
- **Output (verbatim):**
  ```
  #   scripts/pack-help.sh  ->  scripts/pack-help.sh  [stage:S11]
  #   scripts/lib/detect.sh  ->  scripts/lib/detect.sh  [stage:S11]
  ```
- **Command:** `Read scripts/validate-pack.py:4116-4148` (`_iter_client_installed_files`).
- **Output (verbatim, key):** "(a) all regular files under project-template/
  (recursive) … (b) the explicit non-project-template files in
  _CLIENT_INSTALLED_FILES" and `if entry.startswith("project-template/"):
  continue # already covered by (a)`.
- **HEAD/date:** `bb9e807` / 2026-06-02.
- **Interpretation:** Check 43 walks the two `scripts/` files BECAUSE they are
  in `_CLIENT_INSTALLED_FILES` branch (b); after a `project-template/` move they
  are covered by branch (a) and the branch-(b) entries become removable.
- **Conclusion:** SUPPORTED — the guard correctly treats them as client
  surfaces; the move makes the special-case entry redundant (rule⇔guard agree).

---

## E — Is this systemic?

**Bounded to exactly two files.** The authoritative `_CLIENT_INSTALLED_FILES`
map is the SSOT for "what reaches a client from outside `project-template/` +
`supporting-docs/`." Filtering the map to non-`project-template/`,
non-`supporting-docs/` entries yields EXACTLY:
`scripts/pack-help.sh` and `scripts/lib/detect.sh` (EEB-D).

No other pack-side file is copied to a client by `init-project.sh`. The
`supporting-docs/METHODOLOGY.md` and `supporting-docs/INSTALL-PROCEDURES.md`
entries ARE shipped from outside `project-template/`, but they live under
`supporting-docs/` — a recognized project-side product directory per the
separation rule — and they are handled by the C4/C3a content fixes (currency +
`docs/pack/` re-pointing), not by this dual-use-shipped-LIB question. They are
DOCS with a SOURCE→TARGET re-path, not pack-side runtime libraries sourced by
the pack itself, so they are a different case.

### E.1 — CHALLENGE

1. **"Does the migrator (`migrate-v10-to-v11.sh`) ship any OTHER pack-side
   file?"** The migrator copies `pack-help.sh` + `detect.sh` (migrate:340-347)
   — the SAME two files, via the SAME pattern. No additional file. (The migrator
   also stages `HELP-FRAGMENT-TRACKER.md`, `tracker.toml.example` — but those
   resolve to `project-template/` / pack-product sources, already in the map's
   project-side set.) So the migrator does not widen the set.
2. **"Could a future pack feature ship another pack-side lib?"** Possible —
   which is exactly why the §A.1 PRINCIPLE matters: any future client
   deliverable must be authored in `project-template/` from the start, never in
   pack-side `scripts/` and then declared shipped. Encoding this principle (and
   optionally a CI check that the `_CLIENT_INSTALLED_FILES` non-`project-template/`
   set is empty except for an explicit allowlist) prevents recurrence. That is
   a candidate scope item for the structural-promotion BD, not a separate
   problem today.

**Settled:** systemic scope = these two files. The principle + the move close
the class; an optional CI invariant ("no non-`project-template/`,
non-`supporting-docs/` entry in `_CLIENT_INSTALLED_FILES`") would make the
closure durable (measure-then-bound: post-move the set is empty, so the guard's
allowlist is empty).

#### Empirical-Evidence Block — EEB-E (project-template/scripts cleanliness + Check-36 deny-set)

- **Command:** `grep -rlE "BD-[0-9]+" project-template/scripts/`
- **Output (verbatim):** (empty)
- **Command:** `Read scripts/validate-pack.py:3939-3950` (`_is_project_side_path`).
- **Output (verbatim):** `_is_project_side_path` returns True for paths under
  `_PROJECT_SIDE_PATH_PREFIXES`; Check-36 `pack-only` deny-set =
  `("project-template/", "supporting-docs/")`.
- **HEAD/date:** `bb9e807` / 2026-06-02.
- **Interpretation:** the ~15 sibling scripts already in
  `project-template/scripts/` carry zero `BD-NNN` (clean), confirming the
  project-side scripts tree is a clean home. Moving detect.sh/pack-help.sh there
  flips them under the `project-template/` deny-prefix — so a future commit
  touching them can NO LONGER claim `pack-only` (it becomes a project-side or
  mixed commit). This is a Check-36 consequence the planner must account for
  (it is correct: a client-shipped file edit IS a project-side change).
- **Conclusion:** SUPPORTED — project-side scripts tree is clean; the move
  reclassifies the files' Check-36 scope to project-side, which is the truthful
  classification.

---

## 6 — Consolidated recommendations (for Pack Chat → user)

1. **(A)** Adopt the principle: a client deliverable lives in a project-side
   directory; the pack consumes it from there. Promote `pack-help.sh` +
   `detect.sh` to `project-template/scripts/`. **User decision §A.4
   (recommend Opt-3).**
2. **(B)** Single shared file, NOT two copies — divergence pressure is absent
   (client used-set ⊂ pack used-set; post-strip the file is single-audience
   code).
3. **(C)** Strip ALL pack-self comment refs (BD-NNN + pack-doc citations) from
   both shipped files; keep the functional fenced `pack-ops/BACKLOG.md`
   surface-routing paths; pack design history stays in the pack design docs.
   C3c covers 2 of ~36 — **surface the scope gap (C.3) for a user decision**;
   recommend folding the full strip into the structural-promotion commit.
4. **(D)** The C2/Check-43 guard is CORRECT (ship-based by design — its job is
   to protect the install); NL-2/NL-3 STAND; C3c proceeds as specified now and
   is subsumed by the move later. Rule⇔guard disagreement dissolves once the
   file is project-side.
5. **(E)** Systemic scope = exactly these two files (SSOT-confirmed). Encode the
   §A.1 principle + optional CI invariant to prevent recurrence.

**Pipeline note:** the structural-promotion BD touches the install mechanism,
~10 callers, validators, tests, persona-contracts, and the manifest — it
warrants a `pack-planner` pass before any `pack-coder` spawn
(`skill-agent-maintenance-mechanical` + the bounded review/fix cycle). This
strategy doc is the architect input; the user decides whether to open the BD
and when it fires relative to PG-2.

---

## 7 — Rules-Applied Verification Block

| Rule | Evidence | Conclusion |
|---|---|---|
| agents-never-commit | No `git` verb run; no source edit; the only Write is this strategy doc at the prompt-specified path. Tool log shows Read/Bash(read-only greps)/one Write. | COMPLIANT |
| agents-read-rule-docs-in-full | Read in full: `CLAUDE.md` (incl. `## Pack memory`); `MEMORY.md` + the pointed feedback files (`bd_pack_only_operational_rule`, `pack_project_separation_of_concerns`, `ci_guard_design_measure_then_bound`, `preliminary_triage_architect_challenge`, `architect_planner_empirical_evidence`, `bd195_prompt_goals_section`, `agents_read_rule_docs_in_full`); `PACK-AGENTS.md`; `PACK-CHAT.md`; primary sources `detect.sh`, `pack-help.sh`, `init-project.sh` install stages + `_CLIENT_INSTALLED_FILES`, `validate-pack.py` Check 36 + 43 + fence list, `PLAN-BD-195-REMEDIATION.md` §1-2 + C2 §2.2 + C3c + ledger. | COMPLIANT |
| empirical-evidence-blocks | EEB-A1, A2, B1, C, D, E each carry command + verbatim output + HEAD `bb9e807` + date 2026-06-02 + interpretation + SUPPORTED conclusion, for every state-claim (consumer map, used-set subset, content inventory, walk-set, systemic count). | COMPLIANT |
| preliminary-triage-architect-challenge | HIGH bar applied (boundary-with-existing-pack): A, B, E each state a preliminary conclusion then a CHALLENGE block with the strongest counter-arguments before settling; user retains final authority (§A.4 decision table). | COMPLIANT |
| bd-pack-only-operational-rule + pack-project-separation | Applied as the boundary lens throughout: directory-based-vs-ship-based reconciled in §D; BD-185-Code-Red-2 substitution precedent cited verbatim in §A.1; op-vs-explanatory + necessity tests applied in §C. | COMPLIANT |
| ci-guard-measure-then-bound | §C.3(b), §D.3, §E.1: any guard extension recommended is measured (post-move bare-`BD-NNN`-on-client count = zero → empty allowlist); C2 walk-set change reconciled against branch-(a)/(b) coverage; no allowlist widened to admit unclassified hits. | COMPLIANT |
| filename-uniqueness-heuristic | `find . -name "ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS.md" -not -path "./.git/*"` → empty (unique). | COMPLIANT |
| rules-applied-verification-block | This block. | COMPLIANT |
| preflight-stop-means-stop | No fabrication; the prompt's "31 BD-NNN" figure is corrected to the measured 34/10-distinct (EEB-C) rather than echoed; no parent stop received. | COMPLIANT |
| bd195-prompt-goals-section (boundary-absolute / zero-regressions / terse-no-bloat) | Goal-1: end-state satisfies content-per-directory rules with no contradiction (§D). Goal-2: §D.4 invariant — client TARGET paths unchanged → zero client regression. Goal-3: terse; the C.3 scope gap is SURFACED (not silently fixed, not ignored) per Q1/Q2. | COMPLIANT |

**Empty-evidence audit:** no row has empty evidence; no AMBIGUOUS terminal
state. END.

---

## 8 — ADDENDUM: user decision (keep pack-side) + bounded exception design

**Status:** Addendum (read-only pack-architect pass, follow-up). HEAD at design
`bb9e807`; date 2026-06-02. No source edits, no git.

**USER DECISION (binding, supersedes §A recommendation):**
`scripts/lib/detect.sh` + `scripts/pack-help.sh` STAY pack-side in `scripts/`,
get FULLY stripped of pack-self provenance (§C full scope — ~34 `BD-NNN` +
~6 `pack-help.sh` refs + the `AUDIT-*`/`PLATFORM-SKILLS.md`/`V10-DESIGN`/
`ARCHITECTURE-*` doc cites; KEEP the fenced FUNCTIONAL `pack-ops/BACKLOG.md`
surface-routing paths), and remain client-shipped — a deliberate, bounded,
exceptional case.

### 8.0 — Reconciliation against the dependency-direction principle

**The principle (binding):** *Project-side deliverables must NEVER be a
dependency of pack operations. The reverse (pack-side operations being a
dependency of project-side deliverables) is always fine.*

**My §A/§A.1 was WRONG under this principle, and I retract it.** §A.1 framed
"the pack reading its own deliverable" as benign ("pack as its own first
client"). But `init-project.sh` is a PACK OPERATION, and it `source`s
`detect.sh` at runtime (`init-project.sh:79`) — `detect.sh` is a RUNTIME
DEPENDENCY of a pack operation. Had I moved `detect.sh` to
`project-template/scripts/lib/`, a pack operation would depend on a project-side
deliverable — the exact inversion the principle forbids. The BD-185-Code-Red-2
precedent I cited is NOT analogous: there, the dependency was a CLIENT-INSTALL
COPY step reading a SOURCE (a data flow, project→client), not a pack operation
taking a project-side file as its own runtime dependency. My §A conflated
"client deliverable" (ship direction) with "pack runtime dependency"
(dependency direction); they are orthogonal, and the dependency direction is
the controlling axis here.

**Corrected principle (the reconciled rule):** location is governed by
DEPENDENCY DIRECTION, not by ship-status. A file that a pack operation depends
on at runtime MUST live pack-side, FULL STOP — even if it also ships. Ship-status
does not pull it project-side; the dependency does. `detect.sh` is sourced by
`init-project.sh` / `add-capability.sh` / the migrator (all pack operations,
EEB-D), so it MUST stay pack-side. `pack-help.sh` sources `detect.sh` and is
copied by the same pack operations, so it stays with its dependency.

This SUPERSEDES §A.1's principle. §C (strip the content), §D (guard is correct,
NL-2/NL-3 stand), and §E (exactly two files) all stand UNCHANGED — they never
depended on the location move. Only §A's "promote" recommendation is retracted.

> **State-claim — `detect.sh` is a pack-operation runtime dependency.**
> Evidence (EEB-D, re-confirmed): `init-project.sh:79 source
> "$SCRIPT_DIR/lib/detect.sh"`; `add-capability.sh:89`; `migrator-core.sh:402-408`.
> None of these three is in `_CLIENT_INSTALLED_FILES` (EEB-D) → all pack
> operations. Conclusion: SUPPORTED — `detect.sh` is a runtime dependency of
> pack operations; the principle forces it pack-side.

### 8.1 — (a) The bounded, sanctioned exception

**Problem restated.** Post-strip, the two files are CLEAN but pack-side-LOCATED
and client-SHIPPED. Check 43 correctly walks them (EEB-D, branch (b)) and holds
them to client-surface cleanliness. We need: (i) the guard does NOT flag the
clean files; (ii) it STILL catches future re-contamination; (iii) the sanction
is sized to EXACTLY `{scripts/pack-help.sh, scripts/lib/detect.sh}` — never a
general "pack-side files may ship" loophole.

**Key empirical finding (the real gap).** There is TODAY no frozen sanction at
all. `_iter_client_installed_files` (validate-pack.py:4116-4148) walks WHATEVER
non-`project-template/` entries appear in `_CLIENT_INSTALLED_FILES` — branch (b)
iterates the parsed map with zero membership check (EEB-F). So the "exception"
is currently IMPLICIT and UNBOUNDED: any author who adds a `scripts/foo.sh ->
...` line to the map silently sanctions a new pack-side shipped file. That is
both the missing-sanction problem (a) and the laziness hole (b).

**Preliminary conclusion (a).** Introduce ONE frozen constant — the sanctioned
exception set — in `validate-pack.py`, holding EXACTLY the two paths, with a
documented rationale, and make it the membership gate for branch (b):

- **`_SANCTIONED_PACK_SIDE_SHIPPED` (new frozen constant, validate-pack.py):**
  ```
  # Pack-side-LOCATED, client-SHIPPED files. FROZEN. Each entry is a
  # pack-operation runtime dependency (dependency-direction principle:
  # init-project.sh/add-capability.sh/migrator source detect.sh; pack-help.sh
  # sources detect.sh) AND must ship to clients (pack-help LCD floor). They
  # are held to client-surface cleanliness by Check 43 and MUST stay clean.
  # ADDING AN ENTRY requires architect+user authorization — see Check 44
  # (§8.2) and ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS.md §8.
  _SANCTIONED_PACK_SIDE_SHIPPED = (
      "scripts/lib/detect.sh",
      "scripts/pack-help.sh",
  )
  ```

How it satisfies (i)/(ii)/(iii):
- **(i) no false flag:** the files stay on `_CHECK_37_PER_LINE_FENCE_FILES`
  (already there, validate-pack.py:4238-4239) so their FUNCTIONAL fenced
  `pack-ops/` routing is allowed; OUTSIDE the fence, post-strip there is no
  pack-self content, so Check 43 passes clean. The frozen constant does not
  RELAX cleanliness — the files are walked and must be clean. So (i) is
  satisfied by the strip, not by an exemption. The constant's job is (iii)+(b),
  not silencing the guard.
- **(ii) future re-contamination caught:** because the files REMAIN in the
  Check-43 walk (membership in `_SANCTIONED_*` does NOT remove them from the
  walk — it AUTHORIZES their PRESENCE in the walk-set, while the walk still
  enforces cleanliness), any new pack-self ref added later FAILS Check 43
  exactly as a `project-template/` file would. This is the critical distinction
  from an allowlist-that-silences: the sanction allowlists the file's
  pack-side-LOCATION-with-ship-status, NOT any content within it.
- **(iii) sized to exactly two:** the constant is a 2-tuple; §8.2 freezes it.

**CHALLENGE (a) (HIGH bar).**
1. *"Why a new constant — isn't `_CHECK_37_PER_LINE_FENCE_FILES` already the
   allowlist?"* No. The fence list authorizes pack-self content INSIDE fences
   (functional dual-surface routing). It does NOT speak to "may a pack-side file
   be client-shipped at all." Those are different sanctions: one is intra-file
   (fenced functional refs), the other is a file-level location-vs-ship
   sanction. Conflating them would mean any fence-listed file could ship from
   pack-side — over-broad. Keep them separate: fence = content carve-out;
   `_SANCTIONED_PACK_SIDE_SHIPPED` = location-vs-ship carve-out.
2. *"Does the constant risk silencing the guard?"* Only if implemented as a
   skip. It must be implemented as a MEMBERSHIP GATE on branch (b) (see §8.2),
   not a per-file content skip. The files stay fully walked and fully enforced.
   Verified-by-design: re-add a `BD-` token post-strip → Check 43 must FAIL.
   The C2/Check-43 tests (`test-validate-pack-check-43.sh`) MUST include a
   regression case proving a sanctioned file with injected pack-self content
   still FAILS.
3. *"Two encoding surfaces now name these paths (the constant + the
   `_CLIENT_INSTALLED_FILES` map + the fence list) — drift risk?"*
   `enumerate-encoding-surfaces`: yes, and §8.2's Check 44 closes it by
   asserting the constant and the map's non-template set are IDENTICAL — drift
   becomes a CI failure, not a latent gap.

**Settled (a):** one frozen `_SANCTIONED_PACK_SIDE_SHIPPED` 2-tuple in
`validate-pack.py`, used as the membership gate for branch (b) of
`_iter_client_installed_files`; files stay fully walked + cleanliness-enforced;
files stay on the fence list for their functional routing only.

### 8.2 — (b) Anti-pattern prevention (freeze the set; block the lazy path)

**Problem.** A future author must NOT reason "detect.sh ships from `scripts/`,
so I'll keep my new shipped file in `scripts/` too." The default for any NEW
client-shipped file MUST remain `project-template/scripts/`. The lazy path must
FAIL by default, not be merely discouraged.

**Preliminary conclusion (b).** A NEW CI check — **Check 44 (frozen sanctioned
set + map agreement)** — with the dependency-direction principle as the encoded
membership test:

- **Assertion 1 (freeze):** the set of non-`project-template/`,
  non-`supporting-docs/` entries parsed from `_CLIENT_INSTALLED_FILES`
  (init-project.sh map) MUST EQUAL `_SANCTIONED_PACK_SIDE_SHIPPED` exactly
  (set equality — neither superset nor subset). So adding ANY new pack-side
  shipped file to the install map WITHOUT adding it to the frozen constant
  FAILS CI immediately. The lazy path (`scripts/foo.sh -> ...` in the map only)
  is mechanically blocked.
- **Assertion 2 (authorization gate on growth):** the frozen constant carries
  an inline contract comment (shown in §8.1) stating that ADDING an entry
  requires architect+user authorization referencing this doc §8. Because
  Assertion 1 makes the map and the constant move in lock-step, the ONLY way to
  grow the shipped pack-side set is to edit the FROZEN constant — a file +
  symbol that is human-reviewed and whose comment names the authorization
  requirement. Growing it is a deliberate, reviewed act, never an incidental
  map edit.
- **The membership TEST (encoded criterion, the doc-level gate):** a file
  qualifies for `_SANCTIONED_PACK_SIDE_SHIPPED` ONLY IF **(1) a pack operation
  depends on it at runtime** (it is `source`d / invoked by `init-project.sh`,
  `add-capability.sh`, the migrator, or another pack-side operation) **AND
  (2) it must ship to clients** (a client-side surface invokes it). BOTH
  conjuncts required. A file that only ships but no pack operation depends on
  → belongs in `project-template/scripts/` (default). A file that only a pack
  operation depends on but does not ship → stays pack-side, NOT in this set
  (it is not walked by Check 43). The two current members satisfy both
  conjuncts (EEB-D). This criterion is documented in §8.3 and referenced by the
  constant's comment + Check 44's failure message.

**Where it is encoded (exact surfaces):**
| # | Surface | What it encodes |
|---|---|---|
| 1 | `scripts/validate-pack.py` — new `_SANCTIONED_PACK_SIDE_SHIPPED` 2-tuple + inline contract comment | the frozen set + the authorization-required rationale |
| 2 | `scripts/validate-pack.py` — `_iter_client_installed_files` branch (b) membership gate | (a)(iii): only sanctioned non-template paths are admitted to the walk; an UNsanctioned non-template entry is a hard error, not a silent add |
| 3 | `scripts/validate-pack.py` — new `check_sanctioned_pack_side_shipped()` (Check 44) | (b) Assertion 1 (map↔constant set-equality) + Assertion 2 (membership-test failure message naming the dependency-direction criterion) |
| 4 | `scripts/tests/test-validate-pack-check-43.sh` (+ a Check-44 test, new or folded) | regression: (i) clean sanctioned file PASSES; (ii) sanctioned file with injected `BD-` FAILS; (iii) a non-template map entry NOT in the constant FAILS Check 44; a constant entry NOT in the map FAILS Check 44 |
| 5 | The pack rules doc — trinity `## Pack memory` (CLAUDE/AGENTS/GEMINI `### Repo conventions`) | the standing rule: "client deliverables default to `project-template/scripts/`; a pack-side file ships ONLY if it is a pack-operation runtime dependency AND must ship, and ONLY via `_SANCTIONED_PACK_SIDE_SHIPPED` with architect+user sign-off" — a PM-only trinity edit (NOT this architect's to write; surfaced for the PM propagation procedure) |
| 6 | `test-fixtures/manifest.txt` | regen on the validate-pack.py + scripts edits (`regenerate-manifest-v11-surface`) |

**CHALLENGE (b) (HIGH bar).**
1. *"Does set-EQUALITY (not subset) over-constrain — what if a sanctioned file
   is temporarily not in the map?"* No: a sanctioned-but-unshipped file is a
   contradiction (the sanction's conjunct (2) is "must ship"). If a file leaves
   the install map it must also leave the constant (and likely return to a pure
   pack-side lib). Equality is correct: the two surfaces describe the SAME
   set from two angles (the map = "what ships from pack-side"; the constant =
   "what is authorized to ship from pack-side"). They must coincide.
2. *"Is Check 44 redundant with Check 41 (install-inventory)?"* No. Check 41
   asserts the map is well-formed and its targets exist. Check 44 asserts the
   map's pack-side subset is FROZEN to the authorized set. Different invariants;
   `enumerate-encoding-surfaces` wants both.
3. *"Could an author bypass by editing the constant directly without
   authorization?"* The constant is in `validate-pack.py` (a pack-maintenance
   script, pack-coder territory, reviewed). The authorization gate is SOCIAL +
   reviewed, encoded in the comment + the rules-doc criterion — it cannot be a
   pure CI check (CI cannot verify "the user approved"). But the lazy
   INCIDENTAL path (add to map, forget the constant) is mechanically blocked by
   Check 44; the only remaining path is a DELIBERATE constant edit that a
   reviewer sees and the trinity rule (surface 5) governs. That is the correct
   division: mechanical block on laziness, human sign-off on deliberate growth.
   This matches the pack's existing model (e.g., Signal-9 architect gates).
4. *"Is a brand-new Check the right weight, or fold into Check 41?"* A distinct
   Check 44 is clearer for audit (its failure message can name the
   dependency-direction criterion and this doc) and avoids overloading Check
   41's inventory semantics. Folding is acceptable if the planner prefers fewer
   checks (design-elegance), but the set-equality assertion + the membership
   criterion message must survive intact. Recommend distinct Check 44;
   defer the fold-vs-distinct micro-decision to the planner.

**Settled (b):** Check 44 enforces map↔constant set-equality (blocks the lazy
incidental add); the frozen constant + its comment + the trinity rule encode
the dependency-direction membership test and the architect+user sign-off gate
for deliberate growth. Default for new shipped files stays
`project-template/scripts/`.

### 8.3 — The documented membership criterion (for surfaces 1, 3, 5)

> **A file may join `_SANCTIONED_PACK_SIDE_SHIPPED` ONLY IF BOTH hold:**
> **(1) a pack operation depends on it at runtime** (sourced/invoked by
> `init-project.sh`, `add-capability.sh`, the migrator, or another pack-side
> operation — dependency-direction principle: a pack operation may depend on a
> pack-side file, never on a project-side deliverable), **AND (2) a client-side
> surface requires it shipped** (it must reach the client to function).
> If only (2): the file is a pure deliverable → it belongs in
> `project-template/scripts/` (default; no sanction). If only (1): the file is
> a pure pack dependency → it stays pack-side and is NOT client-shipped (not in
> this set, not walked by Check 43). Adding an entry requires architect design +
> explicit user authorization citing this section.

Current members vs. the criterion (EEB-D): `detect.sh` — (1) sourced by
init/add-capability/migrator ✓, (2) sourced by shipped `pack-help.sh` ✓ →
qualifies. `pack-help.sh` — (1) copied + invoked by init/migrator pack ops ✓,
(2) invoked by the shipped per-CLI pack-help skills ✓ → qualifies. Both
SUPPORTED.

### 8.4 — Empirical-Evidence Block — EEB-F (the sanction is currently absent/unbounded)

- **Command:** `Read scripts/validate-pack.py:4116-4148` (`_iter_client_installed_files`)
  + grep for any frozen non-template expected set.
- **Output (verbatim, key):** branch (b) loops `for entry in entries:` where
  `entries, _, _, _, _ = _parse_client_installed_files()`; the only filter is
  `if entry.startswith("project-template/"): continue`. `grep -n
  "_SANCTIONED\|EXPECTED_NON_TEMPLATE\|non-project-template" scripts/validate-pack.py`
  → only the `_iter_client_installed_files` docstring/comment (4119/4143/4163);
  NO frozen membership constant exists.
- **HEAD/date:** `bb9e807` / 2026-06-02.
- **Interpretation:** today ANY non-`project-template/` map entry is silently
  admitted to the Check-43 walk with no membership gate — the exception is
  implicit and unbounded. This is precisely the (a) missing-sanction and (b)
  laziness hole. The design adds the gate that does not exist yet.
- **Conclusion:** SUPPORTED — no frozen sanction exists; the two-part design
  (frozen constant + Check 44 set-equality) is net-new and necessary.

### 8.5 — Rules-Applied Verification Block (addendum)

| Rule | Evidence | Conclusion |
|---|---|---|
| agents-never-commit | No git verb; no source edit; only this append-Write to the strategy doc; read-only Bash greps. | COMPLIANT |
| empirical-evidence-blocks | EEB-F (sanction absent/unbounded) + the §8.0 dependency-direction state-claim + §8.3 per-member criterion check, each with command + verbatim output + HEAD `bb9e807` + interpretation + SUPPORTED. | COMPLIANT |
| preliminary-triage-architect-challenge | HIGH bar: (a) and (b) each state a preliminary conclusion then a multi-point CHALLENGE before settling; §A.1 retracted under the binding principle. | COMPLIANT |
| bd-pack-only-operational-rule + pack-project-separation | content stays stripped + guard-enforced (8.1); sanction is location-vs-ship, never a content relax; default-to-`project-template/` preserved (8.2). | COMPLIANT |
| ci-guard-measure-then-bound | measured the current walk (EEB-F: no gate); the sanction is sized to EXACTLY the 2-member set; the membership gate admits no unclassified entry; Check 44 fails on any superset/subset. | COMPLIANT |
| filename-uniqueness-heuristic | no new file introduced (addendum to existing doc); proposed symbol `_SANCTIONED_PACK_SIDE_SHIPPED` / `check_sanctioned_pack_side_shipped` are repo-unique (grep showed no prior use). | COMPLIANT |
| enumerate-encoding-surfaces | §8.2 table enumerates all 6 lock-step surfaces (constant, walk gate, Check 44, tests, trinity rule, manifest). | COMPLIANT |
| skill-agent-maintenance-mechanical | the trinity-rule edit (surface 5) is flagged PM-only / architect-escalation, not done here. | COMPLIANT |
| bd195-prompt-goals-section | boundary-absolute (sanction never relaxes cleanliness); zero-regression (files stay walked; client target paths unchanged); terse; no out-of-scope edits. | COMPLIANT |
| rules-applied-verification-block | this block. | COMPLIANT |
| preflight-stop-means-stop | no fabrication; §A.1 explicitly retracted rather than defended; no parent stop received. | COMPLIANT |

END ADDENDUM.
