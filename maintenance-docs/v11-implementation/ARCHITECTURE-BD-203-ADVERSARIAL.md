# ARCHITECTURE-BD-203-ADVERSARIAL — DELETE the monolith; per-entry tree the SOLE SSOT

**SUPERSEDES** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-203.md` (REJECTED by the user 2026-06-04).
**BD:** BD-203 — Pack self-migration Phase 1 (Mode 1 → Mode 2), DELETE-the-monolith variant.
**Branch:** v11-dev · **HEAD at design:** `da304ca` · **Date:** 2026-06-04.
**Scope keyword:** `pack-only`. **Author role:** pack-architect (read-only; design doc only).
**Posture:** adversarial — every first-design choice is re-measured and re-adjudicated below.

---

## 0. Headline (lead with the answer)

The first design's central architecture — **keep the monolith as a regenerated
mirror, drive it by the existing per-entry tooling, let Check 32 be the
lossless guard** — is structurally incompatible with the user's binding
decisions and is **rejected in full**. Three independent measurements prove it:

1. **The existing tooling REQUIRES a mirror.** `validate-pack.py` Check 32
   (`check_mirror_in_sync`) FAILs the build if "per-entry tree present but
   mirror file absent" (EEB-D). The mirror is not optional under the current
   `STREAMS` table — it is mandatory the instant the tree exists. "Reuse as-is"
   and "delete the monolith" cannot both hold.

2. **The decompose helper does NOT archive history out.** It writes ALL 185
   prose BD entries regardless of `Status:` (EEB-E, decompose.sh has no
   status filter), and it explicitly defers v8-archive extraction to "the
   migrator" which does not exist for the pack self path (decompose.sh
   ll.182–189). The "live-only, history-archived-out" target the user requires
   is NOT a behavior the current tooling produces.

3. **Deleting the monolith collides with BD-204.** Seven runtime libs
   (`tracker-migrate-reverse.sh`, `tracker-agent-read.sh`,
   `tracker-header-snapshot.sh`, `tracker-doctor.sh`, `tracker-migrate-forward.sh`,
   `recommendation.sh`, `detect.sh`) hard-code `pack-ops/BACKLOG.md` /
   `pack-ops/CHANGELOG.md` as the pack-side mirror at runtime (EEB-B). BD-204
   (the very next launch-gate item) runs the tracker Mode-2→3 dogfood ON THE
   PACK and `tracker-migrate-reverse.sh` WRITES `pack-ops/BACKLOG.md`. The
   deletion's interaction with that path is the single biggest unsurfaced risk
   and is adjudicated in §6.

The corrected design: **archive Resolved/historical content OUT to an inert,
never-agent-read location; decompose ONLY the live entries into `/backlog/`,
`/changelog/`; REMOVE the two pack streams from the `STREAMS` table so Check
32/33/34 no longer demand a mirror; author no-mirror `_rules.md`; verify live
entries faithful; fix the bounded set of live references; DELETE the monolith
LAST, gated.** This is more work than the first design claimed, and the bulk
of it lands in the validator/test layer (§5) and the live-vs-archive split
(§3), not in the decompose mechanics.

---

## 1. Per-choice verdict on the REJECTED first design

Every numbered decision in `ARCHITECTURE-BD-203.md`, adjudicated with my own evidence.

| First-design choice | Verdict | Evidence |
|---|---|---|
| OQ-1: monolith REPLACED in place by a regenerated mirror, NOT deleted | **FLAWED — overturned by the user; my measurement confirms the user is right** | The user requires deletion so dangling refs break+surface+fix. The first design defended "mirror" from the keep-a-mirror convention — but that convention is exactly what the binding decision OVERRIDES for the pack (BD-203 entry, decision 1). §6.1. |
| OQ-2: reuse the BD-164 helpers as-is, no new tooling | **PARTIALLY FLAWED** | The decompose helper is reusable for the *live* slice (EEB-E shows it extracts entries faithfully) but (a) it does NOT filter by status, so "archive out" needs a pre/post step, and (b) the mirror generator + Check 32 are NOT reusable — they enforce the mirror that must be deleted (EEB-D). "No tooling build" is wrong: the validator/test layer must change. §4, §5. |
| OQ-3: `_rules.md` declares "tree is SSOT + mirror is regenerated" | **FLAWED** | The pack `_rules.md` must declare **NO mirror** (tree is the SOLE SSOT). The first design's Mode-dependent "mirror regenerated" clause re-asserts the deleted file. §4.3. |
| OQ-4: verification = byte-identical round-trip vs the ORIGINAL monolith | **FLAWED — wrong oracle** | There is no mirror to round-trip and history is archived out, so byte-identity against the full original is the WRONG bar (it would force historical bloat back into the tree). Correct bar: every LIVE entry's per-entry file is content-faithful to its monolith span; history is captured in the archive; the union loses nothing. §3.4, §5.4. |
| OQ-5: backlog + changelog convert; implementation-plan OUT | **SOUND (now moot)** | The two-streams-only conclusion is correct and is now settled by the corrected BD-203 entry (the implementation-plan mention was an erroneous insertion, removed 2026-06-04). No `/implementation-plan/` stream. EEB-A. |
| OQ-6 / §4.6.1: changelog v1–v7 carried in `_intro.md` or a new archive basename | **FLAWED framing** | Under archive-out, v1–v7 AND v8–v10 resolved history are ALL bloat that leaves the agent-read surface entirely (not "carried in a supporting file that the generator re-emits into a mirror" — there is no mirror). The carrier is the inert archive (§3.3), not an `_intro.md` re-emit. |
| §4.6 / §6: "no new standing CI check; Check 32 IS the guard" | **FLAWED — inverted** | Check 32 is the thing that must be REMOVED for the pack streams, not the guard that protects the result. A different, smaller standing guard is appropriate (the no-monolith assertion + the live-faithfulness one-shot). §5. |
| §5 safe order: build+verify, retire (replace) last | **DIRECTIONALLY SOUND, materially incomplete** | "Destructive step last, gated" is right and retained. But the gate oracle is wrong (byte-identity vs full original) and the order omits the `STREAMS`-removal + reference-fix + test-rewrite steps. §7. |
| EEBs (EEB-1..EEB-10) | **Re-measured; mostly SUPPORTED but materially under-scoped** | EEB-5 ("decompose extracts all 185 entries") is true but is presented as a virtue; under archive-out it is a DEFECT (it would pull 143 Resolved + Deprecated/Cancelled entries into the live tree). The first design never measured the live-vs-history split, the Check-34 dangling magnitude, or the runtime-script blast radius. §9. |

Net: the first design is a **keep-a-mirror dogfood**; the user asked for a
**delete-the-monolith, archive-history-out** conversion. They are different
designs. This is a fresh design, not a patch.

---

## 2. Current-state measurement (summary; full EEBs in §9)

| Fact | Evidence | Conclusion |
|---|---|---|
| Pack fully monolithic; `/backlog/`,`/changelog/` absent; no `tracker.toml` | EEB-A | SUPPORTED |
| `pack-ops/BACKLOG.md` = 185 prose BD entries (26 Open + 11 Deferred + 1 Unblocked LIVE; 143 Resolved + 3 Deprecated + 1 Cancelled HISTORY) + 19 v8 TABLE rows + 5 H2 sections + preamble | EEB-C | SUPPORTED |
| `pack-ops/CHANGELOG.md` = 7 `### vN.M` entries (decompose anchor) + v1–v7 bare-H2 history; 734 lines | EEB-F | SUPPORTED |
| Check 32/33/34 iterate `STREAMS` (2 pack tuples); Check 32 FAILs if tree present but mirror absent → mirror is MANDATORY, not optional | EEB-D | SUPPORTED |
| decompose.sh writes ALL prose entries with NO status filter; v8-archive extraction explicitly deferred to "the migrator" (absent for pack-self) | EEB-E | SUPPORTED |
| 7 runtime libs hard-code `pack-ops/BACKLOG.md`/`CHANGELOG.md` as the pack mirror; `tracker-migrate-reverse.sh` WRITES it (BD-204 collision) | EEB-B | SUPPORTED |
| Deletion blast radius: 667 textual refs across the repo; categorized in §5.6 (the load-bearing measurement) | EEB-G | SUPPORTED |
| If live tree = non-Resolved entries only, 28 live entries carry 67 cross-refs to 35 now-archived BD targets + a handful of genuine cross-version refs → Check 34 FAILs unless redesigned | EEB-H | SUPPORTED |
| Test files `test-per-entry.sh` + `test-validate-pack-checks-32-33-34.sh` deeply assert the mirror round-trip for both pack streams → must be rewritten when the mirror is deleted | EEB-I | SUPPORTED |

---

## 3. The LIVE-vs-ARCHIVE boundary (precise, measured)

This is the design's center of gravity and the first design never defined it.
Binding decision 2 requires historical/archival content archived OUT of every
agent-read surface; decision 3 requires every LIVE entry preserved
content-faithfully. So "live" must be defined exactly.

### 3.1 Definition of LIVE (agent-read; goes into the per-entry tree)

A backlog entry is **LIVE** iff its `Status:` is one of the
forward-looking/actionable states an agent must source to do current work:
`Open`, `Deferred`, `Unblocked`. Measured live set = **38 BD entries**
(EEB-C): the 26 Open + 11 Deferred + 1 Unblocked. These are the entries an
agent reaching for "current scope / what's next / what's blocked" must read.

A changelog entry is **LIVE** iff it documents a version in the **current
major line the pack is shipping/working** — i.e., `v11.0` (the unlaunched
in-progress release) and the immediately-prior shipped majors an agent may
still need for migration context. The precise live cut is a planner/user
confirmation point (§8 OQ-A); the measured candidate is the 7 `### vN.M`
entries that already match the decompose anchor, with v1–v7 bare-H2 history
unambiguously ARCHIVE.

### 3.2 Definition of ARCHIVE (inert; NEVER agent-read)

Everything else is history/bloat that leaves the agent-read surface:
- Backlog: the **143 Resolved + 3 Deprecated + 1 Cancelled** prose entries
  (147 total) AND the **19 v8 TABLE rows** AND the section preamble/`## How to
  use this file` prose (re-expressed once, tersely, in the live `_rules.md`,
  not carried verbatim).
- Changelog: the **v1–v7 bare-H2 history** (and, pending §8 OQ-A, older
  resolved `### vN.M` versions the user deems non-live).

### 3.3 WHERE the archive lives (so it is provably NOT agent-read)

The archive must satisfy two properties: (a) preserved (decision 2: "preserved
inert"), (b) outside every surface an agent reads to do pack work — i.e.,
outside `/backlog/`, `/changelog/`, `pack-ops/`, the trinity, README's live
sections, and the pack-* agent/skill read-sets.

**Recommended home: `maintenance-docs/archive/v11/` (a maintainer-docs
location that is already the repo's designated inert design-record archive,
README ll.157–172).** Concretely:
- `maintenance-docs/archive/pack-backlog-resolved-archive.md` — the 147
  resolved/deprecated/cancelled prose entries + the 19 v8 table rows, frozen.
- `maintenance-docs/archive/pack-changelog-history-archive.md` — the v1–v7
  (and any non-live `### vN.M`) history, frozen.

Why `maintenance-docs/archive/` and NOT a supporting file under `/backlog/`:
the per-entry helpers re-emit supporting files like `_v8-resolved-archive.md`
into a MIRROR (mirror-generate.sh) — that is the keep-a-mirror mechanism we are
deleting. An archive that lives as a `/backlog/_v8-resolved-archive.md`
supporting file would (a) sit inside an agent-read directory and (b) be wired
to a generator we are removing. `maintenance-docs/archive/` is already
inert-by-construction (no validator walks it as live content; no agent reads it
for current scope) and is the correct dependency-free home. This also honors
`separate-pack-ops-from-pack-product` in spirit: history is a maintenance
record, not operating state.

PLANNER/USER confirmation point (§8 OQ-B): whether the archive is a single
flat file per stream (recommended — simplest, one inert blob) or retains
internal structure. Default: flat, terse, frozen.

### 3.4 The faithfulness contract (the SAFE-before-DELETE oracle)

"Lossless" is redefined per binding decision 3 to apply to LIVE entries only:

> For every LIVE entry E in the original monolith, the per-entry file
> `/backlog/<E>.md` (sans the line-1 back-pointer) is byte-identical to E's
> span in the original monolith; AND every ARCHIVE entry appears once in the
> archive file; AND (live ∪ archive) partitions the original's entry content
> with no entry dropped and none duplicated.

This is a **partition-completeness** proof, not a round-trip-byte-identity
proof. The diff oracle is the frozen ORIGINAL monolith, but the assertion is
"every original entry lands in exactly one of {live tree, archive} and its body
is preserved" — NOT "regenerate the whole monolith and cmp." §5.4 operationalizes it.

---

## 4. The mechanism — what the tooling does and does NOT support

### 4.1 What is reusable

`per_entry_decompose` (decompose.sh) IS reusable to materialize per-entry
files from a monolith slice: EEB-E shows it extracts entry spans
content-faithfully with the correct back-pointer. The strategy:

1. **Pre-split the monolith into a LIVE slice and an ARCHIVE slice** (a new,
   small, one-shot pack-side step — see §4.2). The live slice contains only
   the 38 live prose entries + the minimal preamble; the archive slice
   contains everything else.
2. **Run `per_entry_decompose pack-backlog <live-slice> /backlog`** — the
   existing helper, against the live slice only. It writes 38 faithful
   per-entry files. Same for changelog against the live changelog slice.

The decompose helper needs NO modification — it just receives a pre-filtered
input. This respects `skill-agent-maintenance-mechanical` (no structural change
to the shipped helper) and `pack-project-separation` (the client decompose
behavior is untouched — the pre-split is a pack-self build step, not a helper
edit).

### 4.2 What is NEW (small, pack-side, one-shot)

A pack-side conversion step (a script under `scripts/` OR a documented
one-shot the coder runs and the IMPL-REPORT records) that:
- Parses the monolith, classifies each entry LIVE/ARCHIVE by `Status:` (§3.1),
- Emits the live slice (→ decompose input) and appends the archive entries to
  the `maintenance-docs/archive/` files,
- Emits the partition-completeness proof (§3.4) as its verification output.

Dependency-direction check (`dependency-direction-placement`): this is a
pack-self conversion utility, NOT a client deliverable and NOT a runtime
dependency of any pack operation. It belongs pack-side (`scripts/`), is NOT in
the `_SANCTIONED_PACK_SIDE_SHIPPED` allowlist, and ships to no client. If the
planner prefers, it can be a throwaway run recorded in the IMPL-REPORT rather
than a committed script — either satisfies the contract; a committed script is
preferable for auditability and is the recommendation.

### 4.3 What is REMOVED / CHANGED in the shipped tooling

- **`validate-pack.py` `STREAMS`** (ll.297–301): the two pack tuples
  (`pack-backlog`, `pack-changelog`) are **removed** so Check 32/33/34 no
  longer iterate them and no longer demand a mirror. (The project-side streams
  are NOT in this table today — EEB-D shows only the two pack tuples — so this
  table becomes empty for pack-self; see §5.1 for the exact treatment and the
  client-side non-impact.)
- **`scripts/lib/per-entry/_lib.sh`**: the `pack-backlog`/`pack-changelog`
  `mirror=` attributes (ll.71, 79) and the mirror-generator/toc code paths
  that target them. CAUTION: `_lib.sh` is SHIPPED machinery used by the
  client-side migrator. **The pack-self mirror entries must be neutralized
  WITHOUT changing client-side behavior** — see §5.2 (the safe edit is to keep
  the helper generic but stop the pack-self path from invoking the mirror
  generator at all, rather than deleting the stream tuple the client migrator
  may share). The planner must measure whether the client migrator references
  `pack-backlog`/`pack-changelog` keys; my measurement (EEB-B/EEB-D) shows the
  client streams are `project-*` keys, so the `pack-*` keys are pack-self-only
  and safe to retire — but the planner confirms before deleting.
- **`_rules.md` (new, pack-self)**: declares the tree is the SOLE SSOT, NO
  mirror. It still needs a `## Supporting files` section (the awk parser in
  `pe_supporting_files_admitted` reads it) listing only `_rules.md _toc.md`
  (NO `_intro.md` re-emit-to-mirror semantics; NO `_v8-resolved-archive.md`
  — that archival slot is the deleted-mirror mechanism). `_toc.md` may stay as
  a convenience index IFF Check 33 is retired for pack streams (§5.3);
  otherwise drop it too. Default recommendation: keep `_toc.md` as a derived
  convenience index, regenerated by the existing toc helper, with NO mirror.

The net tooling change is **subtractive** (remove the mirror demand) plus one
**additive** one-shot conversion utility — NOT the "no tooling change" the
first design claimed, but also not a rewrite of the per-entry helpers.

---

## 5. Validator / CI ripple + the deletion blast radius (measure-then-bound)

### 5.1 Check 32 (mirror in-sync) — REMOVE pack-self coverage

Today Check 32 makes the mirror mandatory once the tree exists (EEB-D). With
the pack tuples gone from `STREAMS`, Check 32 iterates an empty pack set and
PASSes trivially for pack-self. **Decision:** remove the two pack tuples from
`STREAMS`; Check 32 keeps its generic loop (future client-side use of the same
validator binary is unaffected — clients monkey-patch `STREAMS` only in the
test harness, EEB-I; production client validation of their own trees is out of
scope for the pack-self validator per the ll.290–291 comment). The planner
verifies no other check reads the pack tuples from `STREAMS`.

### 5.2 Check 33 (`_toc.md` in-sync) — REMOVE or KEEP-no-mirror

Check 33 also iterates `STREAMS`. With pack tuples removed it PASSes trivially.
If `_toc.md` is kept as a convenience index (§4.3), it is regenerated by the
toc helper but no longer gated by Check 33 for pack-self. Acceptable — `_toc.md`
is explicitly "never source of truth." Default: keep `_toc.md`, drop the gate.

### 5.3 Check 34 (cross-reference integrity) — the HIGH risk

Check 34 walks every live entry and FAILs on any `BD-NNN`/`vN.M`/`phase-N`
reference not defined in the loaded streams (EEB-D code path; FAILs, does not
warn). Under archive-out, the loaded streams hold only the 38 live BDs + the
live changelog versions, so EEB-H measures **67 cross-refs from 28 live entries
to 35 now-archived BD targets**, plus genuine cross-version refs (`v10.1`,
`v11.1`, `v11.2`, `v9.3-era`) and Check-34 false-positives from prose
(`v11.0-process`, `v11.0-ready`, `v11.0-section`, `v11.0-to-v11` — these are
hyphenated prose tokens the CROSS_REF_RE wrongly matches as versions).

This is the measure-then-bound surface. Two viable bounds:

- **(Bound A — REMOVE pack-self from Check 34):** drop the pack tuples from
  `STREAMS` (already done for 32/33), so Check 34 also stops walking the pack
  tree. Simplest, consistent with deleting the mirror-coupled validators, and
  honest: cross-reference integrity for a tree whose history is deliberately
  archived OUT cannot be a closed-world check (a live entry legitimately cites
  a resolved BD that no longer has a per-entry file). **Recommended.**
- **(Bound B — KEEP Check 34 with an allowlist):** keep walking the pack tree
  but admit (i) the archived-BD targets and (ii) the cross-version targets via
  an allowlist sized exactly to EEB-H's measured set, AND fix the 4 prose
  false-positives. This re-introduces a standing closed-world assumption that
  the archive-out model breaks; the allowlist would have to grow every time a
  live entry is resolved+archived. Per `ci-guard-measure-then-bound`, an
  allowlist that must continuously widen to admit legitimate-by-design misses
  is the wrong instrument. **Not recommended.**

I recommend **Bound A**: the cross-reference closed-world check is incompatible
with deliberate history-archival, so retire it for pack-self rather than fight
it with a perpetually-growing allowlist. (If the user wants reference hygiene,
the right future instrument is an OPEN-world check that resolves a ref to
EITHER the live tree OR the archive file — a BD-204+ enhancement, surfaced §8
OQ-C, not built here.)

### 5.4 The faithfulness gate (one-shot, replaces the byte-round-trip)

The conversion utility (§4.2) emits a **partition-completeness proof**:
`count(live entries in tree) + count(archive entries) == count(original entries)`,
`live ∩ archive == ∅`, and per-entry body byte-equality to the original span
for every live entry. This runs once in the conversion commit and is recorded
in the IMPL-REPORT. It is NOT a standing CI check (there is no monolith left to
diff against post-deletion). This is the SAFE-before-DELETE oracle.

### 5.5 Check 48 (removed-doc soft advisory) + Check 40 (bare pack-ops refs)

- **Check 48** scans `_REMOVED_DOC_SCAN_FILES = (pack-ops/CHANGELOG.md,
  pack-ops/BACKLOG.md)` (EEB validate-pack ll.317–320). After deletion those
  files do not exist; Check 48's loop must tolerate-absent (it currently WARNs
  per occurrence; with the files gone it should cleanly find nothing). The
  scan-file constant must be updated — the accurate-history citations it
  guarded now live in the `maintenance-docs/archive/` files; the planner
  decides whether Check 48 re-points at the archive files or is retired (it is
  a soft advisory, never a fail). Surfaced as a bounded edit.
- **Check 40** walks `pack-ops/*.md` excluding `BACKLOG.md`/`CHANGELOG.md`
  basenames (ll.5142–5143). After deletion the exclusion is harmless. BUT
  Check 40 FAILs on a bare `` `BACKLOG.md` `` ref with 0 candidates. EEB-G
  shows bare refs in `BOUNDARY-DEFINITION.md`, `DRY-RUN-MIGRATION.md`,
  `OPTIONAL-FEATURES.md`, `PACK-AGENTS.md`, `PACK-CHAT.md`,
  `PACK-MEMORY-RATIONALE.md`. Several are PROSE about the *concept* of a
  backlog file (e.g., "moves issue tracking out of `BACKLOG.md` flat-file") —
  those need re-wording or anchor-phrase exemption, NOT a path repoint. The
  PACK-AGENTS.md / PACK-CHAT.md ones are live pointers that must repoint to
  `/backlog/` (§5.6). The planner runs Check 40 against the projected post-fix
  tree and resolves each per its triage tier.

### 5.6 The deletion blast radius — categorized fix plan (the load-bearing enumeration)

667 textual refs to the two paths exist (EEB-G). They stratify into four
categories; ONLY categories 1–2 are real "breaks" the user wants surfaced+fixed.

**Category 1 — LIVE RUNTIME consumers (MUST fix; these break execution):**
the 7 libs in EEB-B. Disposition is the §6 BD-204 adjudication — these are NOT
simply repointed, because BD-204 depends on the pack mirror path. **This is the
crux.** See §6.

**Category 2 — LIVE GOVERNANCE / read-pointer surfaces (MUST fix; PM-only):**
the references an agent/Pack-Chat follows expecting the file:
- `CLAUDE.md` ll.30–31, 34 (Key-files block names the two mirrors) → repoint to
  `/backlog/`, `/changelog/` as SOLE SSOT; delete the "(regenerated mirror)"
  framing.
- `pack-ops/PACK-AGENTS.md` ll.134–135 (PM-only Files list "(regenerated
  mirror; per-entry source at …)") → repoint; drop "mirror".
- `pack-ops/PACK-CHAT.md` ll.42–43 (File-access table direct-read rows) →
  repoint to per-entry tree reads.
- `README.md` Repository Layout ll.262–263 (`pack-ops/BACKLOG.md` "regenerated
  mirror") + ll.280–281 (`/backlog/` "source of truth for pack-ops/BACKLOG.md
  mirror") → the mirror lines deleted; the tree lines reworded "SOLE SSOT".
- `AGENTS.md` / `GEMINI.md` pack-root copies (trinity parity — EEB-G shows 7
  hits in CLAUDE.md, 7 in AGENTS.md, 6 in GEMINI.md): the same Key-files edits
  applied in lockstep per the **trinity rule** (these are pack-root trinity,
  PM-only).
- `.claude|.codex|.gemini/agents/pack-{architect,planner,coder}.*` (EEB-G):
  prompt boilerplate "read `pack-ops/BACKLOG.md`" → repoint to `/backlog/`.
- `.claude|.codex|.gemini/skills/pack-startup/SKILL.md`,
  `commit-discipline/SKILL.md`, `implementation-report/SKILL.md`,
  `boundary-investigation/SKILL.md` (EEB-G): live "read/modify `pack-ops/
  BACKLOG.md`" instructions → repoint per the per-CLI canonical-reference rule
  (`cross-cli-reference-normalization` — pack-side trinity is exempt from
  client normalization, but the THREE CLI skill copies must stay in lockstep).
- `pack-ops/HELP-FRAGMENT-PACK.md`, `OPTIONAL-FEATURES.md`,
  `BOUNDARY-DEFINITION.md`, `DRY-RUN-MIGRATION.md`,
  `PACK-MEMORY-RATIONALE.md`: per-line triage — repoint live pointers; reword
  conceptual prose (Check 40 §5.5).

**Category 3 — TEST assertions (MUST fix; they encode the mirror contract):**
`scripts/tests/test-per-entry.sh` (round-trip identity tests 3.x, mirror
filename asserts 1.1/1.2) and `test-validate-pack-checks-32-33-34.sh` (F1–F5
pack-changelog/pack-backlog mirror coverage) — EEB-I. These assert behavior we
are deleting. Per `enumerate-encoding-surfaces`, they update in lockstep with
the `STREAMS`/`_lib.sh` change: the pack-self mirror-roundtrip tests are
removed; the client-side `project-*` round-trip coverage (if any in those
files) is retained. The `tracker-*` tests that write/read `pack-ops/BACKLOG.md`
(EEB-G: `tracker-migrate-forward/reverse-test.sh`, `tracker-bd133/132/134`,
`tracker-agent-read-test.sh`, roundtrip) are Category-1-adjacent — they test
the runtime libs and follow §6.

**Category 4 — INERT HISTORICAL PROSE (do NOT fix; BREAK-is-acceptable / leave):**
the ~494 refs in `maintenance-docs/` (archive/, v11-research/,
v11-implementation/ reports) — EEB-G shows 112 files, 494 refs. These are
frozen design records and IMPL-REPORTs that mention the path as historical
fact ("BD-175 made `pack-ops/BACKLOG.md` canonical"). They are NEVER resolved
as live paths, no agent follows them to read current scope, and rewriting 494
historical mentions would be `scope-deliverables-to-the-ask` violation +
falsifying the historical record. **Leave them.** They are not "broken
references" in the operational sense — they are accurate statements about past
state. (The REJECTED `ARCHITECTURE-BD-203.md` itself, 23 refs, is in this
category — it is superseded by THIS doc and becomes an archived record.)

**Bound:** the fix set is Categories 1–3 (a bounded, enumerable list — roughly
the 7 runtime libs, ~10 governance/trinity surfaces ×3 CLIs, ~6 pack-ops docs,
2 test files + the tracker tests). Category 4 (~494 maintenance-docs refs) is
explicitly OUT. The planner produces the exact line-level fix list by running
the §5.6 categorization against HEAD; this design bounds the categories and
names the load-bearing members.

---

## 6. The BD-204 collision (the crux the first design missed entirely)

**The problem.** `tracker-migrate-reverse.sh` ll.1059–1060 WRITES
`$repo_root/pack-ops/BACKLOG.md` and `pack-ops/CHANGELOG.md` as the pack-side
reverse-migration output; `tracker-agent-read.sh` ll.264/267 READS
`pack-ops/BACKLOG.md` as the pack BD mirror; 5 more libs reference it (EEB-B).
BD-204 — the NEXT launch-gate item — runs the tracker Mode-2→3 dogfood ON THE
PACK, which exercises exactly these code paths against the pack's own backlog.
If BD-203 deletes `pack-ops/BACKLOG.md`, BD-204's reverse migration would
recreate it (a monolith the user just deleted), or fail.

**Why this is in-scope for BD-203 to ADJUDICATE (not solve).** Binding
decision 4 requires every reference fixed so CI is green with NO monolith.
The runtime libs ARE references. But binding decision 5 (pack-only) and
`scope-deliverables-to-the-ask` forbid BD-203 from building BD-204's tracker
behavior. The resolution is to define the CONTRACT, not implement it:

1. **For BD-203's green-CI requirement:** the 7 runtime libs reference the path
   inside tracker-mode code paths that are INACTIVE in the pack today (no
   `tracker.toml`, flat-file mode — EEB-A). They are not invoked at pack CI
   time. So deleting the monolith does NOT break CI via these libs (they are
   dormant). The planner verifies via `grep` that no pack-CI-invoked path
   reaches them with the pack repo in flat-file mode. **This means Category-1
   libs need NO edit for BD-203's CI-green requirement** — they are dormant
   references, not active breaks.

2. **For BD-204's correctness:** BD-204 must NOT recreate the deleted monolith.
   The Mode-2→3 contract (CLAUDE.md "Per-entry trees vs mirrors") says in
   tracker mode "BOTH the per-entry tree and the monolithic mirror are
   regenerated from tracker state" — but the user has OVERRIDDEN keep-a-mirror
   FOR THE PACK (BD-203 decision 1). **This is a genuine contract conflict
   between the shipped Mode-2→3 behavior and the pack's no-mirror override.**
   It is a BD-204-scope decision, not a BD-203 build item. **Surfaced as the
   single most important hand-off (§8 OQ-D):** BD-204 must either (a) run the
   pack tracker in a no-mirror configuration, or (b) the pack accepts a
   tracker-regenerated mirror at Mode-3 (contradicting decision 1). The user
   must adjudicate this at BD-204 time; BD-203 must NOT pre-decide it.

**BD-203's obligation re BD-204:** leave the runtime libs UNTOUCHED (they are
dormant; editing them would be BD-204 scope creep and risks the client-shipped
tracker behavior — `pack-project-separation`), and record this conflict in the
IMPL-REPORT + a forward-pointing note so BD-204 inherits it. This is the
`deferred-work-tracked-anchor` discipline: the conflict lands on BD-204 (a live
anchor), not silently dropped.

---

## 7. Safe conversion order (corrected; destructive step LAST + gated)

Commit boundaries are a planner decision; the dependency order is fixed.

1. **(non-destructive) Snapshot ORIG** — freeze copies of `pack-ops/BACKLOG.md`
   + `CHANGELOG.md` to temp paths (the partition oracle, §5.4).
2. **(non-destructive) Classify + split** — run the §4.2 conversion utility:
   classify every entry LIVE/ARCHIVE (§3.1); write the ARCHIVE slices to
   `maintenance-docs/archive/pack-{backlog,changelog}-*-archive.md`; emit the
   LIVE slices.
3. **(non-destructive) Decompose the LIVE slices** — `per_entry_decompose
   pack-backlog <live-backlog-slice> /backlog` and the changelog equivalent
   (existing helper, unmodified). Author `/backlog/_rules.md`,
   `/changelog/_rules.md` (no-mirror, §4.3). Generate `_toc.md` (convenience).
4. **(non-destructive, GATE) Partition-completeness proof** (§5.4): every
   original entry lands in exactly one of {live tree, archive}; every live
   per-entry body byte-equal to its original span. **Do not proceed until
   the proof passes.** This is the SAFE-before-DELETE gate.
5. **(non-destructive) Retire the mirror-coupled validators/tests** — remove
   the two pack tuples from `validate-pack.py STREAMS` (§5.1); neutralize the
   pack-self mirror path in `_lib.sh` without touching client behavior (§5.2,
   planner-confirmed); update Check 48 scan constant (§5.5); rewrite/remove the
   Category-3 pack-self mirror tests (§5.6); update `_v8-resolved-archive.md`
   known-supporting references that no longer apply.
6. **(non-destructive) Fix Category-1(dormant-verify)/2/3 references** — the
   governance/trinity/agent/skill repoints (§5.6 Cat 2), in trinity lockstep;
   the Check-40 prose rewordings; verify Category-1 libs are dormant (§6 step 1)
   and leave them.
7. **(non-destructive) Run `validate-pack.py`** — must be GREEN with the tree
   present and the mirror still on disk (Check 32/33/34 now skip pack-self;
   Check 40/48 clean). This proves CI is green BEFORE the deletion.
8. **(DESTRUCTIVE — gated on steps 4 + 7) DELETE** `pack-ops/BACKLOG.md` +
   `pack-ops/CHANGELOG.md` (`git rm`). Regenerate `test-fixtures/manifest.txt`
   (v11-surface: `pack-ops/`, `scripts/` touched — `regenerate-manifest-v11-surface`).
9. **(verification) Run `validate-pack.py` again** — must be GREEN with NO
   monolith (`find pack-ops -name BACKLOG.md -o -name CHANGELOG.md` → empty).
   END-OF-BD full correctness audit: no live entry lost (partition proof
   re-cited); history archived OUT (grep the archive files exist, agent-read
   surfaces carry no resolved/historical bloat); no surviving live reference
   sources the deleted files (Cat 1–3 fixed; Cat 4 left as historical record);
   reality matches the docs.

The destructive step (8) is last and double-gated: on the partition proof (4,
no live data lost) and on a GREEN validate-pack BEFORE deletion (7, references
already fixed). The user (per `no-destructive-without-approval` /
`per-action-approval-sub-agents`) approves the `git rm` commit explicitly.

---

## 8. Out-of-scope observations (SURFACED, not solved)

- **OQ-A — the exact changelog live-cut.** Whether "live" changelog = only
  `v11.0`, or `v11.0` + the prior shipped majors for migration context. Default
  candidate: the 7 `### vN.M` entries (v1–v7 unambiguously archive). User/planner
  confirms the cut. Affects only WHICH changelog entries archive out, not the
  mechanism.
- **OQ-B — archive file shape.** Flat blob per stream (recommended) vs
  structured. Default flat + frozen.
- **OQ-C — open-world reference hygiene.** If the user wants live entries' refs
  to archived BDs validated, the right future instrument resolves a ref against
  {live tree ∪ archive} — a BD-204+ enhancement, NOT built here (§5.3 Bound A
  retires the closed-world Check 34 for pack-self).
- **OQ-D — BD-204 / Mode-2→3 mirror-contract conflict (the critical hand-off).**
  The shipped Mode-3 contract regenerates a mirror; the pack's decision-1
  override deletes it. BD-204 must adjudicate (no-mirror tracker config vs
  accept a regenerated mirror). BD-203 leaves the dormant runtime libs untouched
  and records the conflict on BD-204 (§6). DO NOT pre-decide.
- **`pack-project-separation`.** The pack `_rules.md`/archive files are SEPARATE
  artifacts from the client `project-template/docs/project/*` ones — pack
  audience (BD entries, no mirror), NOT byte-copied from the client templates
  (which keep their mirror per their own design). The client-shipped per-entry
  behavior MUST NOT change — verify zero `project-template/` diff (decision 5).

---

## 9. Empirical-Evidence Blocks (independent measurements at HEAD `da304ca`, 2026-06-04)

### EEB-A — pack fully monolithic; trees + tracker.toml absent
- **Command:** `git rev-parse HEAD` → `da304caef978d21e...`; `ls backlog
  changelog tracker.toml` (repo root).
- **Output:** `backlog`/`changelog`/`tracker.toml` → No such file or directory.
- **Interpretation:** Mode 1 (flat-file, hand-maintained); no per-entry tree.
- **Conclusion:** SUPPORTED.

### EEB-B — 7 runtime libs hard-code the pack mirror path; reverse-migration WRITES it (BD-204 collision)
- **Command:** `grep -rn -E 'pack-ops/(BACKLOG|CHANGELOG)\.md' scripts/ --include='*.sh' --include='*.py' | grep -v '/tests/' | grep -v 'test-'`.
- **Output (verbatim, abridged to the runtime libs):**
  `scripts/lib/detect.sh:45: ... "$target/pack-ops/BACKLOG.md" ...`;
  `scripts/lib/recommendation.sh:132: local backlog="$repo_root/pack-ops/BACKLOG.md"`;
  `scripts/lib/tracker-agent-read.sh:264: BD-*) mirror_path="$repo_root/pack-ops/BACKLOG.md" ;;`;
  `scripts/lib/tracker-doctor.sh:122: backlog_path="$repo_root/pack-ops/BACKLOG.md"`;
  `scripts/lib/tracker-header-snapshot.sh:217: backlog_path="$repo_root/pack-ops/BACKLOG.md"`;
  `scripts/lib/tracker-migrate-forward.sh:710/733/1340: backlog_path/mirror_path="$repo_root/pack-ops/BACKLOG.md"`;
  `scripts/lib/tracker-migrate-reverse.sh:1059: backlog_out="$repo_root/pack-ops/BACKLOG.md"` / `:1060 changelog_out=... CHANGELOG.md`.
- **Interpretation:** the pack mirror path is a live runtime target for the
  tracker/migration feature — the same feature BD-204 dogfoods on the pack.
  Reverse migration WRITES the file. These are tracker-mode paths, dormant in
  the pack's current flat-file mode.
- **Conclusion:** SUPPORTED.

### EEB-C — backlog live-vs-history split (185 prose entries + 19 table rows + sections)
- **Command:** `grep -cE '^\*\*BD-[0-9]+ — ' pack-ops/BACKLOG.md`;
  `grep -E '^Status:' pack-ops/BACKLOG.md | sort | uniq -c`;
  `grep -cE '^\| BD-[0-9]+ \|'`; `grep -nE '^## '`.
- **Output (verbatim):** prose entries `185`; Status: `26 Open`, `11 Deferred`,
  `1 Unblocked`, `146 Resolved`*, `3 Deprecated`, `1 Cancelled`; v8 table rows
  `19`; H2s at ll.9/23/3385/3658/4867 (`How to use`, `Active — v11 Scope`,
  `Active — v10 Scope`, `Resolved — v8`, `Deferred`). *(Status count `146`
  Resolved includes the v8 TABLE rows' inline status; the per-entry parse in
  EEB-H yields 143 PROSE Resolved + 19 table-only = the same history set.)*
- **Interpretation:** LIVE = 26+11+1 = **38** prose entries; HISTORY = 143
  Resolved + 3 Deprecated + 1 Cancelled prose + 19 table rows.
- **Conclusion:** SUPPORTED.

### EEB-D — Check 32/33/34 iterate STREAMS; Check 32 makes the mirror MANDATORY
- **Command:** read `scripts/validate-pack.py` ll.297–301 (`STREAMS`), 3254–3260
  (Check 32 "mirror file absent" FAIL), 3366/3583/3612 (Check 33/34 STREAMS loops).
- **Output (verbatim):** `STREAMS = [("pack-backlog","backlog","pack-ops/BACKLOG.md",...),
  ("pack-changelog","changelog","pack-ops/CHANGELOG.md",...)]`; Check 32 else-branch
  `fail(f"{mirror_rel}: per-entry tree present at {stream_rel}/ but mirror file
  absent — run ...")`.
- **Interpretation:** once the tree exists, Check 32 FAILs if the mirror is
  absent — the mirror is MANDATORY under the current table. "Delete the mirror"
  requires removing the pack tuples from STREAMS. Check 33/34 also iterate it.
- **Conclusion:** SUPPORTED.

### EEB-E — decompose writes ALL prose entries; no status filter; v8-archive deferred to absent migrator
- **Command:** read `scripts/lib/per-entry/decompose.sh` ll.110–114, 177–286;
  live run on a temp copy: `per_entry_decompose pack-backlog <tmp> <tmpdir>`.
- **Output (verbatim):** anchor `^\*\*(BD-\d+) — `; walk writes an entry on
  every anchor regardless of Status; ll.182–189 comment: "the decompose helper
  does not write the v8 archive ... at production-time the migrator will
  pre-extract the v8 archive before invoking the decompose helper"; prior live
  run (first design EEB-5, reproduced) → "wrote 185 entry file(s)".
- **Interpretation:** the helper extracts EVERY prose entry (live + resolved);
  archive-out requires a PRE-SPLIT (§4.2). The v8 table rows (pipe form) are not
  `**BD-NNN` anchors → dropped by decompose entirely.
- **Conclusion:** SUPPORTED.

### EEB-F — changelog 7 vN.M entries + v1–v7 bare-H2 history
- **Command:** `grep -cE '^### v[0-9]+\.[0-9]+' pack-ops/CHANGELOG.md`;
  `grep -nE '^## v[0-9]+ '`; `wc -l`.
- **Output (verbatim):** `### vN.M` count `7` (v11.0, v10.0-post, v10.0, v9.3,
  v8.10, v8.9, v8.8); `## vN` bare-H2 at v11/v10/v9/v8 (grouping) + v7..v1 history;
  734 lines.
- **Interpretation:** decompose anchors only `### vN.M` (7 entries); v1–v7
  bare-H2 are history → archive. The live changelog cut is §8 OQ-A.
- **Conclusion:** SUPPORTED.

### EEB-G — deletion blast radius: 667 refs; categorized
- **Command:** `grep -rn -E 'pack-ops/(BACKLOG|CHANGELOG)\.md' . --include=...
  | grep -v '^\./pack-ops/(BACKLOG|CHANGELOG)\.md:' | grep -v '/.git/' | wc -l`;
  then grouped by file.
- **Output (verbatim):** total `667`; `maintenance-docs/` = 112 files / 494 refs
  (Category 4, inert history); runtime libs = the 7 of EEB-B (Category 1);
  governance/trinity/agent/skill (CLAUDE.md 7, AGENTS.md 7, GEMINI.md 6,
  PACK-AGENTS.md/PACK-CHAT.md, pack-* agents ×3 CLI, pack-startup/commit-discipline/
  implementation-report/boundary-investigation SKILL ×3 CLI, README 2) (Category 2);
  test files (`test-per-entry.sh`, `test-validate-pack-checks-32-33-34.sh`,
  `tracker-*-test.sh`) (Category 3); bare pack-ops prose refs in
  BOUNDARY-DEFINITION/DRY-RUN-MIGRATION/OPTIONAL-FEATURES/PACK-MEMORY-RATIONALE
  (Check-40 surface).
- **Interpretation:** the real fix set is Categories 1–3 (bounded, enumerable);
  Category 4 (~494 maintenance-docs refs) is accurate historical prose, left as-is.
- **Conclusion:** SUPPORTED.

### EEB-H — Check 34 dangling magnitude under archive-out (live tree = 38 non-Resolved)
- **Command:** python parse of `pack-ops/BACKLOG.md`: build entries, classify by
  Status, for each LIVE entry count BD-refs to non-live targets + version refs
  to non-live changelog versions.
- **Output (verbatim):** parsed entries `185`, live `38`; v8 table-row IDs `19`;
  live entries with dangling BD-refs `28`; distinct dangling BD targets `35`;
  total dangling (entry,target) pairs `67`; dangling version refs `20` (genuine:
  `v10.1`, `v11.1`, `v11.2`, `v9.3-era`; prose false-positives the regex
  mis-matches: `v11.0-process`, `v11.0-ready`, `v11.0-section`, `v11.0-to-v11`).
- **Interpretation:** a closed-world Check 34 on the live-only tree FAILs on 67+
  refs — incompatible with deliberate archive-out. Retire Check 34 for pack-self
  (§5.3 Bound A); an allowlist would have to grow perpetually.
- **Conclusion:** SUPPORTED.

### EEB-I — test files encode the mirror round-trip contract for both pack streams
- **Command:** `grep -nE 'pack-backlog|pack-changelog|pack-ops/(BACKLOG|CHANGELOG)|STREAMS'`
  on `scripts/tests/test-per-entry.sh` + `test-validate-pack-checks-32-33-34.sh`.
- **Output (verbatim):** `test-per-entry.sh`: `1.1 pack-backlog mirror filename
  ... pack-ops/BACKLOG.md`, Group 3 "pack-backlog round-trip identity",
  `per_entry_regenerate_mirror pack-backlog ...` (multiple);
  `test-validate-pack-checks-32-33-34.sh`: monkey-patches `vp.STREAMS`, Group F
  "pack-changelog stream coverage F1–F5", `per_entry_regenerate_mirror
  pack-changelog ...`.
- **Interpretation:** these tests assert the mirror behavior being deleted; they
  must be updated in lockstep (`enumerate-encoding-surfaces`) — pack-self
  mirror-roundtrip cases removed, client `project-*` coverage retained.
- **Conclusion:** SUPPORTED.

---

## 10. Rules-Applied Verification Block

**READ-IN-FULL (per-file proof — each named doc Read DIRECTLY via the Read tool, IN FULL; no derivation):**
- `CLAUDE.md` — Read in full, 541 lines (l.1 `# CLAUDE.md — AI Agent Config
  Pack (Pack Repo)` … l.541 `… use /tmp clones or scratch fixtures, never write to real OT.`). COMPLIANT.
- `pack-ops/PACK-AGENTS.md` — Read in full, 226 lines (l.1 `# PACK-AGENTS.md — AI
  Agent Config Pack (Pack Repo)` … l.226 `… confirm staged files before any commit.`). COMPLIANT.
- `pack-ops/PACK-CHAT.md` — Read in full, 310 lines (l.1 `# PACK-CHAT.md — Pack
  Chat Startup and Operating Instructions` … l.310 `… verified by END-STATE checks … not a hard-enforced step sequence.`). COMPLIANT.
- `project-template/CLAUDE.md` — Read in full, 456 lines (l.1 `# CLAUDE.md` …
  l.456 `… The marker is preserved across pack upgrades. -->`). COMPLIANT.
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-203.md` (REJECTED first
  design) — Read in full, 597 lines (l.1 `# ARCHITECTURE-BD-203 — Pack
  self-migration Phase 1 (Mode 1 → Mode 2)` … l.597 `… no git state change.`). Challenged in §1. COMPLIANT.
- BD-203 entry (`pack-ops/BACKLOG.md` ll.3330–3348) — Read DIRECTLY. COMPLIANT.
- BD-204 entry (`pack-ops/BACKLOG.md` ll.3352–3365) — Read DIRECTLY. COMPLIANT.
- `README.md` Repository Layout (ll.85–294) — Read DIRECTLY. COMPLIANT.
- Curated memory (each Read DIRECTLY, in full): `project_pack_self_migration_launch_gate.md`
  (49 ll.), `feedback_preliminary_triage_architect_challenge.md` (46 ll.),
  `feedback_pattern_matching_out_of_context_antipattern.md` (41 ll.),
  `feedback_architect_planner_empirical_evidence.md` (15 ll.),
  `feedback_ci_guard_design_measure_then_bound.md` (15 ll.),
  `feedback_pack_project_separation_of_concerns.md` (33 ll.),
  `feedback_scope_deliverables_to_the_ask.md` (35 ll.),
  `feedback_agent_output_rules_applied_block.md` (15 ll.),
  `feedback_agents_read_rule_docs_in_full.md` (97 ll.). All COMPLIANT.
- MEASURE (the mechanism), Read DIRECTLY: `scripts/lib/per-entry/_lib.sh`
  (439 ll., full); `scripts/lib/per-entry/decompose.sh` (288 ll., full);
  `scripts/validate-pack.py` STREAMS (ll.290–380) + Check 32 (ll.3141–3260) +
  Check 33 (ll.3364–3483) + Check 34 (ll.3490–3683) + Check 40 (ll.5113–5210) +
  Check 48 region; the current `pack-ops/BACKLOG.md` (header + BD-203/204
  entries + section structure) + `pack-ops/CHANGELOG.md` (anchors). COMPLIANT.

| Rule | Evidence (quoted/measured) | Conclusion |
|---|---|---|
| preliminary-triage / architect-challenge (HIGH bar) | §1 adjudicates EVERY first-design choice with my own evidence; 7 of 9 overturned FLAWED/INCOMPLETE; agreement (OQ-5 two-streams) backed by EEB-A + corrected BD entry, not deference. A design agreeing everywhere = failed pass; this disagrees on the central architecture. | COMPLIANT |
| pattern-matching-out-of-context anti-pattern | §1 + §4.3: the first design reflex-reused the keep-a-mirror + Check-32-as-guard pattern; property-fit fails against the user's archive-out goal (EEB-D mirror is mandatory; EEB-H closed-world Check 34 incompatible with archival). Rejected the pattern, chose subtractive+archive structure fit to the actual goal. | COMPLIANT |
| empirical-evidence-blocks [architect] | §9 EEB-A..EEB-I: each carries command + verbatim output + HEAD `da304ca` + date 2026-06-04 + interpretation + SUPPORTED. The load-bearing deletion blast-radius (EEB-G, 667 refs categorized) + live-vs-history split (EEB-C) + Check-34 magnitude (EEB-H) measured independently, not trusted from the first design. | COMPLIANT |
| ci-guard-measure-then-bound [architect] | §5: measured Check 32/33/34/40/48 against actual repo (EEB-D/G/H); categorized every blast-radius occurrence KEEP/FIX/LEAVE (§5.6 four categories); sized the fix to Cat 1–3 (legitimate breaks), Cat 4 left; REJECTED the perpetually-widening Check-34 allowlist (Bound B) per the no-widen-to-swallow clause, chose retire-for-pack-self (Bound A). Post-design state validates clean (§7 steps 7+9). | COMPLIANT |
| separate-pack-ops-from-pack-product + pack-project-separation | §4.2/§4.3/§6/§8: zero `project-template/` edits (decision 5); the conversion utility + `_rules.md` + archive are pack-self artifacts, NOT byte-copied from client templates; client decompose/mirror behavior untouched (only the pack-self mirror path retired, planner-confirmed §5.2); the BD-204 runtime libs (shipped tracker feature) left untouched to avoid client-behavior regression. | COMPLIANT |
| scope-deliverables-to-the-ask | Designed exactly BD-203 (Mode 1→2, two streams, delete+archive-out). BD-204 / GH Issues / tracker.toml / Mode-2→3 mirror-contract conflict / open-world ref hygiene / implementation-plan all SURFACED in §6/§8, NOT solved. Category-4 494 maintenance-docs refs explicitly OUT (rewriting them would be the over-scoping the rule forbids). | COMPLIANT |
| rules-applied-verification-block (+ no-derivation) | This §10 table + the READ-IN-FULL per-file direct-read proof block (line counts / first+last lines); every named doc attested COMPLIANT with direct-Read evidence; no doc derived; no empty-evidence rows. | COMPLIANT |

**Output:** written to
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-203-ADVERSARIAL.md` (this
file); markdown only; no source edits; no git state change. SUPERSEDES
`ARCHITECTURE-BD-203.md`.
