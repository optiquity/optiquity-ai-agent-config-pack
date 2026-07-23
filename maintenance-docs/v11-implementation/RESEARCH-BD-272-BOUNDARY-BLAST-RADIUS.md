# RESEARCH — BD-272 — `pack td` cross-boundary violation: scope, decision history, broader-class census, load-bearing verdict

> **Part of the BD-272 design chain** (as-landed reference record) — see `backlog/BD-272.md`. Chain order: **RESEARCH (this doc)** → `ARCHITECTURE-BD-272.md` → `ADVERSARIAL-ARCH-REVIEW-BD-272.md` → `RECONCILIATION-ARCH-REVIEW-BD-272.md` → `AUDIT-BD-272.md`. Landed by BD-272 (paired report commit); the `pack td` eradication that shipped under BD-272 is the realized consumer of this chain.

**Status:** as-landed reference record (BD-272) · **Design HEAD:** `0d427f9` · **Branch:** v11-dev.
**Author:** `pack-docs-researcher` (fresh, read-only instance).
**Date:** 2026-07-23 (US/Pacific).
**Canonical checkout:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`.
**HEAD at read time:** `0d427f9` (`docs: v11 — session-state: refresh boundary to CI-green frontier (97277d6) ...`).
**Graph:** `graphify-out/graph.json` (25.9 MB, built ≥ 06:32 today).
**Deliverable role:** inventory + characterize for an architect design pass. This report does NOT design the fix.
**Census:** 99 files / 856 match lines (`git grep -iE "pack[ -]td|pack_td|tracker[-_]promote"`) — 19 LIVE files / 192 lines (CLASS-1+2), 80 historical / 664 lines (CLASS-3).
**One-line verdict:** `pack td` is the UNIQUE live-advertised, client-facing, pack-backed, never-shipped verb; the cross-boundary SHAPE was never dispositioned (an oversight compounded under four individually-plausible affirmations); the workflow is DEAD in practice.

> **Reader orientation.** The user calls `pack td` "an enormous boundary
> violation." This report answers four questions an architect needs before
> designing the fix: (1) exactly what breaks if you touch it (blast radius +
> CI interlocks); (2) whether the cross-boundary shape was ever a deliberate,
> reviewed decision or an unreviewed blind spot (decision history + verdict);
> (3) whether `pack td` is unique or the visible symptom of a broader class
> ("are there more?"); (4) whether the workflow is actually used or dead code.

---

## How discovery used the graph (graph-first attestation)

Per `graph-first-context`, discovery ran graph-FIRST, then grep-to-zero to VERIFY:

1. **`graphify affected "tracker-promote.sh" --graph <abs> --budget 1500
   --backend claude-cli`** — reverse traversal surfaced the candidate live
   surfaces (`scripts/pack-td.sh [calls]`, `project-template/docs/pack/HELP-FRAGMENT.md`,
   `pack-ops/HELP-FRAGMENT-PACK.md`, `scripts/tests/tracker-bd129-gh-repo-test.sh`)
   plus ~28 maintenance-docs reference nodes (the historical record).
2. **`graphify query "pack td tracker-promote verb backing and references"`**
   and **`affected`/`explain`** widened the candidate set to the tracker-lib
   family + CI-wiring surfaces.
3. **VERIFICATION (grep-to-zero):** `git grep -iE "pack[ -]td|pack_td|tracker[-_]promote"`
   over the whole tree established the exhaustive literal census
   (**99 files / 856 match lines**), which I then partitioned and read to
   classify. The grep is the completeness gate; the graph is what widened the
   candidate set beyond the a-priori pattern (it surfaced `tracker-bd129-gh-repo-test.sh`
   and the maintenance-docs reference cloud I would not have enumerated up front).

The prior partial pass reported "~99 files / 855 matches." **Verified and
corrected: 99 files / 856 match lines at HEAD `0d427f9`.** The one-line delta
is the untracked render artifact `pack-ops/dashboard-approvals/dashboard.html`
(embeds BD-107/BD-224 text; not a source surface — see §1.4).

---

# §1 — Verified, grep-complete blast radius of `pack td`

**Total:** 99 files, 856 match lines (`git grep -iE "pack[ -]td|pack_td|tracker[-_]promote"`).
**Partition:** LIVE = 19 files / 192 lines; HISTORICAL (CLASS-3) = 80 files / 664 lines.

## §1.1 — CLASS-1: LIVE client-facing (the violation the user sees)

These are shipped-to-client or client-audience surfaces that ADVERTISE / instruct
`pack td` whose backing never reaches the client. **This is the core violation.**

| # | File | Lines | What it does | Rule broken |
|---|---|---|---|---|
| C1-a | `project-template/docs/pack/HELP-FRAGMENT.md` | L20-22, L27, L32-34 (7) | Client `pack help` manifest advertises `pack td promote --to=phase-N`, `--to=phase-N.M`, `pack td resolve` as runnable client verbs. | `dependency-direction-placement` (advertised client verb whose backing is not in the shipped set) |
| C1-b | `project-template/docs/pack/PM-CHAT.md` | L752-754, L796, L800, L823, L846-848, **L856-857** (11) | Client PM-chat orchestration instructs the client PM to RUN `pack td promote/resolve`; L856-857 explicitly name the backing as `scripts/lib/tracker-promote.sh` + `scripts/pack-td.sh` — pack-side paths that do NOT exist in the client tree. | `dependency-direction-placement`; `declare-verify-backing` (names a backing that never ships) |
| C1-c | `project-template/scripts/.docs-gate-allowlist.txt` | L504, L507 (2) | **Client-side docs-gate allowlist** exempts `scripts/pack-td.sh` and `scripts/lib/tracker-promote.sh` from the "referenced-file-must-exist" gate with the reason **"present after install, absent from the bare template."** That reason is FALSE — see §4. This row MASKS the dangling reference. | `declare-verify-backing` (records a load-bearing "present after install" claim that is false) |
| C1-d | `supporting-docs/METHODOLOGY.md` | L1600, L1606, L1611, L1630 (4) | Client-SHIPPED methodology (installed at init-project S6) instructs `pack td resolve`, `pack td promote --to=phase-N`, `--to=phase-N.M`, and "the `pack td promote` verb has no `--fold-into` flag." | `dependency-direction-placement` |

**Why C1 is the violation:** the client HELP-FRAGMENT advertises exactly two
`pack <verb>` families — `pack help` and `pack td` (verified: `grep '`pack '`
project-template/docs/pack/HELP-FRAGMENT.md` returns only these two). `pack help`
is backed by `scripts/pack-help.sh`, which IS in the frozen
`_SANCTIONED_PACK_SIDE_SHIPPED` set and IS copied at init-project S11. `pack td`
is backed by `scripts/pack-td.sh` + `scripts/lib/tracker-promote.sh`, which are
NOT in the sanctioned set and are NEVER copied (proof in §4). So the ONLY
client-advertised verb whose backing does not ship is `pack td`.

## §1.2 — CLASS-2: LIVE pack backing + CI wiring

| # | File | Lines | Role | Removal impact |
|---|---|---|---|---|
| C2-a | `scripts/pack-td.sh` | 18 | The `pack td` verb dispatcher. **L2 carries `# pack-internal: true`** (added by BD-224 dc82c2e). Sources `tracker-promote.sh` (L65); routes `promote`/`resolve`. | Removing it un-backs C1 entirely. |
| C2-b | `scripts/lib/tracker-promote.sh` | 47 | The TD→phase promotion orchestration library (BD-107). Defines `tracker_promote_path1/path2/direct_close/reverse_*/compose_*/next_phase_task_M/phase_task_M_in_use`. **No live caller but `pack-td.sh` + the 3 tests (§4).** | Dead once dispatcher + tests go. |
| C2-c | `scripts/tests/test-tracker-promote-path1.sh` | 21 | Path-1 unit/integration test. | Wired in CI (see interlocks). |
| C2-d | `scripts/tests/test-tracker-promote-path2.sh` | 29 | Path-2 unit/integration test. | Wired in CI. |
| C2-e | `scripts/tests/test-tracker-promote-direct.sh` | 27 | Direct-close unit/integration test. | Wired in CI. |
| C2-f | `scripts/tests/fixtures/tracker-promote/` | (dir) | Test fixtures (`BACKLOG.md`, `id-map.json`, `IMPLEMENTATION-PLAN.md`) referenced by the 3 tests via the `FIXTURES` var. Dir NAME matches the census literal; file CONTENTS do not. | Delete with the tests. |
| C2-g | `scripts/tests/pack-help-test.sh` | L6-7, L142, L155-161, L170, L185-187 (12) | **Asserts 2.1 `pack td` rows ABSENT on the PACK surface AND 2.2 client `pack td` rows PRESENT** (L185-187: `t_pass "2.2 client pack td rows present"`). This test ENCODES the half-fixed state (§2). | Must be rewritten if C1 advertising is removed — 2.2 would break. |
| C2-h | `scripts/tests/test-validate-pack-check-89.sh` | L40, L267 (2) | Locks the `/pack-td` / `/pack-tracker` non-regression (asserts they are NOT advertised as `/pack-*` slash commands on the pack surface). | Update if names change. |
| C2-i | `scripts/ci-shard-weights.tsv` | L89-91 (3) | Shard weights for the 3 `test-tracker-promote-*.sh`. **Consumed by Check 60** (`check_ci_shard_coverage` → `ci-shard-plan.py --assert-coverage`). | Removing the 3 tests WITHOUT deleting these rows FAILS Check 60 (partition must cover exactly the wired set). |
| C2-j | `scripts/ci-test-wiring-allowlist.txt` | L24-25 (2) | Documents that the 3 `test-tracker-promote-*.sh` were re-classified KEEP (WIRED), NOT exempt. | Update on removal. |
| C2-k | `scripts/lib/tracker-edit.sh` | L35, L491 (2) | **COMMENTS only** — cite `tracker-promote.sh:801` as "the `provider_update` call shape this reuses." NOT a source/call (§4). (Also a line-number cite → `architect-doc-reality-reconciliation` drift risk.) | Cosmetic; update comment. |
| C2-l | `scripts/lib/tracker-migrate-forward.sh` | L72 (1) | COMMENT: "cycle-graph store is empty until a `pack td promote --to=phase-N.M`". | Cosmetic. |
| C2-m | `scripts/lib/validate_checks/help_fragments.py` | L333 (1) | Check 89 comment noting the closing-backtick anchor excludes `scripts/pack-td.sh`-shape spans. | Cosmetic; Check 89 logic. |
| C2-n | `README.md` | L221 (1) | Pack `scripts/` directory listing: "pack-td.sh — TD orchestration ... (v11; project-side tool, pack-internal — not advertised in pack help)." | Update on re-home/removal. |
| C2-o | `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | L212 (1) | Idempotency-methodology EXAMPLE row cites `pack td promote`. | Cosmetic example. |

## §1.3 — CI interlocks that break on removal (enumerate-encoding-surfaces)

An architect removing or re-homing `pack td` MUST update these in lock-step:

1. **Check 60 — CI shard coverage** (`scripts/lib/validate_checks/singletons.py:1436`
   `check_ci_shard_coverage`, runs `scripts/lib/ci-shard-plan.py --assert-coverage`):
   the partition in `ci-shard-weights.tsv` L89-91 must cover exactly the wired
   test set. Delete the 3 tests → delete the 3 tsv rows, or Check 60 FAILS.
2. **Check 89 — HELP-FRAGMENT `/pack-*` ↔ backing-skill parity**
   (`help_fragments.py:371`; test `test-validate-pack-check-89.sh` L40/L267):
   asserts `/pack-td` / `/pack-tracker` are NOT advertised as `/pack-*` slash
   commands (non-regression lock). Independent of C1 removal, but the test
   references the names.
3. **Check 23 — scripts/ executables ↔ HELP-FRAGMENT-PACK.md**
   (`help_fragments.py`, the "listed OR `# pack-internal: true`" gate):
   `pack-td.sh` currently passes ONLY because BD-224 added `# pack-internal: true`
   (L2). Any change that un-marks it re-triggers Check 23.
4. **Client docs-gate** (validate-docs family — `.docs-gate-allowlist.txt` is read
   by the `test-validate-docs-*` / template-fullscan gate): the two allowlist rows
   (C1-c) currently EXEMPT `pack-td.sh` + `tracker-promote.sh` from the
   referenced-file-must-exist check. This is the interlock that MASKS the dangling
   reference; removing the client advertising means removing these rows too.
5. **pack-help-test.sh 2.2** (C2-g): asserts client `pack td` rows PRESENT — a
   direct encoding of the current (violating) state; breaks the moment C1 is fixed.
6. **ci-test-wiring-allowlist.txt** (C2-j): the 3 tests are declared WIRED, not
   exempt — removal must reconcile here too.

## §1.4 — CLASS-3: HISTORICAL record (do NOT scrub) — 80 files / 664 lines

Per `fail-loud-delete-old-source`, historical record is SEPARATE from live source
and is NOT scrubbed. All 80 files live under `maintenance-docs/**` (79) and
`backlog/**` (BD-076, BD-107, BD-204, BD-222, BD-224, BD-251 — 6 rows across those).
Highest-density historical files: `IMPLEMENTATION-REPORT-BD-107.md` (82),
`IMPLEMENTATION-REPORT-BD-129-RETRO-FIX.md` (49), `ARCHITECTURE-BD-219-CI-FAILURE-DIAGNOSIS.md` (35),
`IMPLEMENTATION-REPORT-BD-107-FIX.md` (34), `PACK-REVIEW-BD-107.md` (33). These record
what was built/reviewed and MUST stay as the audit trail. `backlog/BD-107.md` is the
origin entry (Resolved) and is a governance SSOT, not scrubbable.

**Untracked artifact (not CLASS-3, not source):**
`pack-ops/dashboard-approvals/dashboard.html` (1 match) — an untracked render
artifact whose embedded `#state` JSON quotes BD-107's description and BD-224's
commit subject. Regenerated by `scripts/dashboard-render.py`; not a surface to edit.

---

# §2 — Decision history: oversight, deliberate-but-flawed, or half-fixed leak?

**Question:** was `pack td`'s cross-boundary shape ever DISPOSITIONED as
acceptable, and was the boundary a deliberate call? This determines whether the
architect's job is to REVERSE a decision or FIX an oversight.

I read the five decision points in chronological order and quote each below.

## §2.1 — Origin: BD-107 (2026-05-15) — the root mis-homing

`backlog/BD-107.md` File/Symbol (quoted):

> "NEW `scripts/pack-td.sh` (verb dispatcher for the `pack td <verb>` namespace
> **per existing `scripts/pack-<noun>.sh` convention**; wires `pack td promote
> --to=phase-N` and `pack td promote --to=phase-N.M` ...)"

And its correction note:

> "Second correction 2026-05-14: `EXTEND scripts/pack-tracker.sh` → `NEW
> scripts/pack-td.sh` since `pack-tracker.sh` dispatches the `pack tracker`
> namespace, not `pack td`; **per existing one-script-per-noun convention**."

**Reading:** BD-107 placed the dispatcher pack-side because it followed the
PACK CLI naming convention (`scripts/pack-<noun>.sh`). A PROJECT-side workflow
(TD → phase promotion) was wired into the pack's `pack <noun>` namespace and
homed pack-side because *it looked like a pack verb*. The client advertising
already existed — BD-107 notes "`HELP-FRAGMENT.md` lines 20-21 already reference
these verbs" — so the client-facing surface predates the backing. **This is the
root cause: convention-driven placement, never a boundary decision.** There is
NO evidence in BD-107 that anyone asked "does this backing ship to the client
that is told to run it?"

## §2.2 — PACK-SIDE-CONCEPTS-AUDIT (V1, 2026-05-26) — explicitly dispositioned LEGITIMATE, on a mistaken "constructor" reading

`PACK-REVIEW-PACK-SIDE-CONCEPTS-AUDIT.md` §3.5.1 (quoted):

> "**`scripts/pack-td.sh`** — The script's entire purpose is to operate on
> PROJECT-side TD entries ... This is a CONSTRUCTOR that emits/manipulates
> project-side artifacts ... **Per rule: 'scripts that emit project-side
> templates' — allowed.**"

§3.5.3 (quoted):

> "**`scripts/lib/tracker-promote.sh`** — Library that promotes a project-side
> TD entry into a project-side phase epic (Path 1) or phase task (Path 2) ...
> Constructs project-side artifacts. **Allowed by rule.**"

**Reading — the load-bearing error.** The audit dispositioned both files
LEGITIMATE by classifying them as "constructors that emit project-side
templates," which the `pack-side-project-concepts-deliverable-only` rule
permits. **But that carve-out covers pack-side EMITTERS that run at
pack/build/install time to PRODUCE artifacts that then ship** (e.g.
`init-project.sh`, `validate-pack.py`). `pack-td.sh` is not that: it is a
CLIENT RUNTIME TOOL the client is instructed to invoke against its OWN repo.
The audit conflated "references a project concept" (true, and permitted) with
"is a build-time emitter of a shipped deliverable" (false). It never asked the
ship question. This is the first place the violation was actively looked at —
and it was cleared on a category error.

## §2.3 — AUDIT-DISPOSITION-BD-TD-PATH (2026-05-26) — client surface dispositioned LEGITIMATE-KEEP

`AUDIT-DISPOSITION-BD-TD-PATH.md` §4.18 (HELP-FRAGMENT.md, quoted):

> "A-3.23.2 (L19) | **LEGITIMATE** | ``pack td promote --to=phase-N`` | KEEP."
> "A-3.23.3 (L20) | **LEGITIMATE** | ``pack td promote --to=phase-N.M`` | KEEP."

§4.16 (PM-CHAT.md, quoted):

> "A-3.21.5–18 (L540-650) | **LEGITIMATE** | Full TD resolution orchestration
> section: Path 1, Path 2, Path 3-forbidden. ... **This entire section is the
> client-side normative pattern. | KEEP entirely.** This is the OPERATIONAL
> TD-promotion contract for client PMs."

And the user-locked frame (§7.2): *"TD entries are CLIENT-ONLY (operational TD
lifecycle stays in client-facing docs)."*

**Reading.** This audit's lens was the TOKEN boundary — is a PROJECT concept
(TD) correctly on the CLIENT surface? Yes → KEEP. That reasoning is *correct on
its own axis*: TD promotion IS a client workflow and DOES belong in client docs.
But the audit had a stated `Rule 2` for exactly cross-side substitution —
*"Is this a cross-side substitution (script copying pack file to client; client
file used for pack ops)?"* — and it returned 0 VIOLATIONs for `pack td` because
it only looked for pack-ops files copied to clients, not for a client-advertised
verb whose backing lives pack-side and never ships. The ship dimension was
outside its search. So the client advertising was affirmed KEEP — again without
the ship check.

## §2.4 — PACK-SIDE-CONCEPTS-AUDIT-V2 — re-affirmed CONFIRMED-LEGITIMATE

`PACK-REVIEW-PACK-SIDE-CONCEPTS-AUDIT-V2.md` re-ran the audit and re-tabled
(L444-446, L531, quoted): `tracker-promote.sh | TD promotion (Path 1 + Path 2)
| CONFIRMED-LEGITIMATE` and the 3 tests `CONFIRMED-LEGITIMATE`. §5.3 searched
for "similar patterns elsewhere" but only for dropdown-keyed dependent-field
cascades, and its HELP-FRAGMENT note (L779) says the fragments "describe pack
verbs ... No propagation needed." **The ship-status was never revisited.**

## §2.5 — BD-224 `/pack-help` boundary-leak fix (dc82c2e, 2026-07-19) — the half-fix, deliberate client-keep

`backlog/BD-224.md` "As landed" record L25 (quoted):

> "The `/pack-help` **boundary-leak fix** removed project-side TD/tracker verbs
> from the pack fragment (pack-self vs client `project-template/` command
> surfaces stay separate), **marking `pack-td.sh` internal so Check 23 stays
> green.**"

The commit subject (dc82c2e, quoted): *"fix: v11 — BD-224 remove project-side
TD/tracker verbs from the pack /pack-help fragment; mark pack-td.sh internal so
Check 23 stays green (pack-only)."*

The test that encodes the resulting state — `scripts/tests/pack-help-test.sh`
(quoted):

> L155-156: "2.1 `pack td` rows ABSENT on the pack surface: `pack td` is
> pack-internal (scripts/pack-td.sh carries `# pack-internal: true`) ..."
> L185-187: `[[ "$output" == *"pack td promote"* && "$output" == *"pack td
> resolve"* ]] && t_pass "2.2 **client pack td rows present**" || t_fail "2.2
> client pack td rows missing"`.

**Reading — the deliberate keep.** BD-224 explicitly split the surfaces: it
REMOVED `pack td` from the PACK help fragment and marked `pack-td.sh`
pack-internal (so Check 23 — every `scripts/` executable must be listed OR
marked internal — stays green), while DELIBERATELY KEEPING `pack td` on the
CLIENT surface and enshrining that in an assertion (`2.2 client pack td rows
present`). The framing "pack-self vs client command surfaces stay separate"
treats `pack td` as a legitimate CLIENT verb. So BD-224 cleaned the PACK side
and *deliberately preserved* the CLIENT side — but, like every prior pass, it
did not check whether the client backing ships. It is a HALF fix: the pack
surface is now clean, the client surface is deliberately unchanged, and the
underlying advertised-but-unshipped defect is untouched (indeed `# pack-internal:
true` further guarantees the backing stays pack-side and out of the client copy).

## §2.6 — VERDICT

**The cross-boundary SHAPE (client-advertised + pack-backed + never-shipped) was
NEVER dispositioned by anyone. It is an unreviewed blind spot — but a
*compounded* one, layered under four passes that each DELIBERATELY affirmed the
adjacent (and individually defensible) sub-decision that "`pack td` belongs on
the client surface."** Concretely, the answer is a hybrid of all three offered
categories:

- **(b) Unreviewed oversight — on the SHIP axis (the core defect).** No pass —
  BD-107, V1 audit, disposition, V2 audit, BD-224 — ever asked "does
  `pack-td.sh` / `tracker-promote.sh` reach the client that PM-CHAT.md tells to
  run `pack td`?" The `.docs-gate-allowlist.txt` row (C1-c) even encodes the
  *false* belief that it does ("present after install"). This is a genuine blind
  spot, not a reviewed-and-accepted trade-off.
- **(a) Deliberate-but-flawed — on the PLACEMENT axis.** The V1 audit made a
  *deliberate* LEGITIMATE ruling on `pack-td.sh`/`tracker-promote.sh` via a
  mistaken "constructor emits a shipped deliverable" reading. That was an
  active, wrong decision, not an omission.
- **(c) Half-fixed leak — on the SURFACE axis.** BD-224 deliberately cleaned the
  PACK surface and kept the CLIENT surface, encoding the keep in `pack-help-test.sh`
  2.2. The pack half is fixed; the client half is deliberately preserved and the
  ship defect is untouched.

**Consequence for the architect.** This is NOT "reverse a considered decision
that `pack td` should span the boundary" — no one ever decided that. It is
"fix an oversight that was masked by four individually-plausible affirmations."
The individually-correct insight (TD promotion IS a client workflow and belongs
on the client surface) is exactly what makes the fix direction non-obvious: if
`pack td` belongs on the client surface, then the BACKING must ship to the
client (re-home to `project-template/scripts/`), OR the advertising must be
removed. The current state is the worst cell of the matrix: advertised where it
cannot run. (Re-home vs delete is surfaced as an open item in §5 — that is the
architect's call, not this report's.)

---

# §3 — Broader class: are there more instances of the same violation shape?

The user asked "are there even more?" I define the violation SHAPE precisely,
then hunt every candidate against the boundary SSOT (`pack-ops/BOUNDARY-DEFINITION.md`
§2 two-axis matrix; the `dependency-direction-placement`,
`pack-side-project-concepts-deliverable-only`, and
`pack-project-separation-of-concerns` rules; the `boundary-investigation`
methodology). Three sub-questions, each with a grep-verified answer.

## §3.1 — The shape, stated precisely

`pack td` combines TWO distinct defects:
- **Defect A (advertised-but-unshipped):** a verb/feature ADVERTISED on the
  client surface whose backing lives pack-side and is NOT in the shipped set
  (`_SANCTIONED_PACK_SIDE_SHIPPED` = exactly `{scripts/lib/detect.sh,
  scripts/pack-help.sh}`, `boundary_refs.py:593-596`).
- **Defect B (mis-homed project-concept machinery):** pack-side scripts/libs
  that operate on PROJECT concepts (TD / phase / tracker) and are homed pack-side.

These are separable — an instance can have B without A (dormant machinery that is
mis-homed but advertised nowhere). Below I answer for each.

## §3.2 — Q1: other client-ADVERTISED verbs whose backing is pack-side + doesn't ship (Defect A)

**Method:** the client help manifest is `project-template/docs/pack/HELP-FRAGMENT.md`.
`grep '`pack '` returns exactly two verb families: `pack help` and `pack td`
(§1.1). And `grep -nE "scripts/(pack-|lib/)"` over the client docs
(`HELP-FRAGMENT.md` + `PM-CHAT.md`) returns only `scripts/lib/tracker-promote.sh`
+ `scripts/pack-td.sh` (PM-CHAT.md L856-857).

**Result:** **`pack td` is the UNIQUE instance of Defect A.** The only other
advertised verb is `pack help`, backed by `scripts/pack-help.sh`, which IS in
`_SANCTIONED_PACK_SIDE_SHIPPED` and IS copied at init-project S11 (verified:
`init-project.sh:989` asserts `scripts/pack-help.sh missing or not executable
after copy`). No other client-advertised feature points at a pack-side unshipped
backing. **Verified by:** the two-verb HELP-FRAGMENT census + the two-hit
client-doc script-reference grep.

## §3.3 — Q2: other pack-side scripts/verbs operating on PROJECT concepts (Defect B)

**Method:** enumerate `scripts/pack-*.sh` dispatchers and the tracker/groupings lib
family; classify each pack-ops vs project-deliverable-mis-homed.

`ls scripts/pack-*.sh` → three dispatchers:

| Dispatcher | Operates on | Advertised where | `# pack-internal`? | Ships? | Classification |
|---|---|---|---|---|---|
| `scripts/pack-help.sh` | pack+client help surface | pack + client | no (it's the help itself) | **YES** (sanctioned) | LEGITIMATE — genuine dual-use LCD verb, correctly shipped. |
| `scripts/pack-td.sh` | PROJECT TD → phase promotion | **CLIENT only** (removed from pack by BD-224) | **yes** (L2) | **NO** | **VIOLATION — Defect A+B (the subject).** |
| `scripts/pack-tracker.sh` | PROJECT tracker mode (init/status/tree-rebuild/edit/...) | **NOWHERE** (dormant) | **yes** (L2) | **NO** | Defect B only — mis-homed but advertised nowhere; see §3.3.1. |

`scripts/lib/groupings*.sh` → **none exist** (`ls` returns no matches). No
groupings-lib instance.

`scripts/lib/tracker-*.sh` → **18 libraries** (`tracker-agent-read/config/
cycle-check/doctor/edit/errors/header-snapshot/init/labels/links/migrate-forward/
migrate-reverse/mirror/phase-task/promote/provider-gh/provider/sidecar.sh`), plus
`scripts/tracker-migrate.sh`. All operate on PROJECT tracker artifacts; all are
pack-side; none ship; all are `# pack-internal` or sourced-only.

### §3.3.1 — Why the tracker family is NOT the same violation as `pack td`

The distinguishing fact: **`pack td` is ADVERTISED to clients (Defect A);
`pack tracker` and the 18 tracker libs are NOT.** `README.md` L220 (quoted):
*"pack-tracker.sh — Tracker ... (v11; **dormant, deferred per BD-214 — verbs
refuse**)"* and L222 *"tracker-migrate.sh ... (v11; dormant, deferred per
BD-214)."* Tracker mode was deferred indefinitely by BD-214 (Resolved); the
flat-file per-entry mode is the sole supported mode (per pack `CLAUDE.md`
Project goals). `pack-tracker.sh`'s own header (L4-8, quoted): *"Tracker mode is
deferred indefinitely (BD-214) ... This dispatcher is retained dormant and
test-covered, but is NOT advertised in `pack help` — hence `pack-internal: true`."*
And `grep "pack tracker" project-template/docs/pack/` returns ZERO — it is on
NO client surface.

So the tracker family is **Defect B only: mis-homed project-concept machinery,
dormant, advertised nowhere.** Whether dormant deferred machinery should live
pack-side at all is a real boundary question (it fits the `pack-side-project-
concepts-deliverable-only` tension — it is not currently CONSTRUCTING a shipped
deliverable, it is dormant), but it is a MUCH weaker instance than `pack td`
because no client is told it exists and nothing advertises an unbacked
capability. **`pack td` is unique in being LIVE-ADVERTISED to clients.**

## §3.4 — Q3: project concepts on PACK-ops surfaces / pack concepts on CLIENT surfaces (beyond the deliverable carve-out)

**Method:** the two prior audits (V1 + V2, §2.2/§2.4) already ran this census
against `pack-side-project-concepts-deliverable-only` across every pack-ops
surface. Their result (V1 §5.4, V2 §6.1): pack-ops operating docs
(`PACK-CHAT.md`, `PACK-AGENTS.md`, `HELP-FRAGMENT-PACK.md`, `CHANGELOG.md`,
`BOUNDARY-DEFINITION.md`, etc.) are CLEAN of project-concept operational leak;
the only operational leak found was the pack-root `.github/ISSUE_TEMPLATE/work-item.yml`
`td`/`phase-skeleton` options (F1/F2, **already fixed** at b4906d1) — a DIFFERENT
shape (a form dropdown, not an advertised verb). The `pack-ops/BACKLOG.md`
narrative mentions were LOW audit-trail (no-fix).

I re-verified the one pack-ops LIVE hit in my census:
`pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md:212` cites `pack td promote` as an
EXAMPLE in an idempotency-methodology row (C2-o). That is an explanatory example
inside a pack-ops methodology doc, not an operational admission — but it will read
as stale once `pack td` is re-homed/removed, so it belongs in the fix's
lock-step surface set.

**Result:** no NEW class of project-concept-on-pack-ops or pack-concept-on-client
leak beyond (i) the already-fixed pack-root form and (ii) the `pack td` /
tracker-family machinery covered above. Verified by the two prior full audits
plus my LIVE-surface re-grep.

## §3.5 — Broader-class conclusion

**`pack td` is UNIQUE as a LIVE, client-ADVERTISED, unshipped-backing violation
(Defect A) — there is exactly one.** It is, however, the most acute member of a
BROADER Defect-B family: a large body of PROJECT-concept tracker machinery (the
`pack-tracker.sh` dispatcher + `tracker-migrate.sh` + 18 `scripts/lib/tracker-*.sh`)
homed pack-side. That family is dormant/deferred (BD-214) and advertised nowhere,
so it does not expose an unbacked client capability the way `pack td` does — but
an architect scoping the `pack td` fix should decide whether the tracker family's
pack-side home is in-scope (it shares the same root cause: project-concept CLI
machinery placed pack-side by `scripts/pack-<noun>.sh` convention). Surfaced as
an open item in §5.

---

# §4 — Load-bearing verdict: is the TD→phase promotion workflow used or dead?

**Question:** is `pack td` / `tracker-promote.sh` actually USED (a real
invocation path, a client that runs it, a live documented procedure), or is it
effectively DEAD machinery whose only "users" are its own tests?

## §4.1 — Does the backing ship to any client? NO (proof)

- `find project-template -name pack-td.sh -o -name tracker-promote.sh` → **empty**
  (the backing does not exist under `project-template/`).
- `init-project.sh stage_s5_scripts` (L553-566) copies ONLY
  `$PACK/project-template/scripts/*` into the client's `scripts/`. `pack-td.sh`
  lives in `scripts/`, `tracker-promote.sh` in `scripts/lib/` — NEITHER under
  `project-template/scripts/`, so neither is copied.
- `_SANCTIONED_PACK_SIDE_SHIPPED` (`boundary_refs.py:593-596`) = exactly
  `{scripts/lib/detect.sh, scripts/pack-help.sh}` — `pack-td.sh` /
  `tracker-promote.sh` are NOT members; Check 47 enforces set-equality with the
  install map, so they cannot be silently shipped either.
- **Therefore a client that follows PM-CHAT.md and runs `pack td promote` has no
  such script.** The `.docs-gate-allowlist.txt` reason "present after install"
  (C1-c) is factually false.

## §4.2 — Is there any RUNTIME invoker (pack-side or client-side)? NO

- `git grep "pack-td.sh"` filtered to exec/source/bash/`./` invocation, excluding
  tests/docs → **zero hits.** There is NO unified `pack` dispatcher that routes
  `pack td` to `pack-td.sh` (`scripts/pack`, `scripts/pack.sh`, `bin/pack` do not
  exist; `pack-help.sh` is ONLY the help printer, it does not dispatch verbs).
  `pack-td.sh` is invoked only by the 3 `test-tracker-promote-*.sh` tests
  (dispatcher-integration groups).
- `git grep "source.*tracker-promote\|tracker_promote_"` excluding
  tests/docs/self → the ONLY non-test caller is `pack-td.sh` (which sources it,
  L65) plus one allowlist row. **No other lib sources it**
  (`git grep -l "source.*tracker-promote" scripts/lib/` → empty).

## §4.3 — Is the `tracker-edit.sh:491 → tracker-promote.sh:801` reference a live dependency? NO — it is a COMMENT

`scripts/lib/tracker-edit.sh` L35 and L491 (quoted L491):

> "# Build the provider_update payload (§2.3; reuses the **tracker-promote.sh:801
> `provider_update "$gh_id" "$payload"` call shape**). ..."

This is a CODE COMMENT documenting a shared *pattern* ("call shape this reuses"),
not a `source` or a function call. `tracker-edit.sh` independently builds its own
`provider_update` payload inline; it does not depend on `tracker-promote.sh` at
runtime. (Note: the `:801` line-number cite is itself an
`architect-doc-reality-reconciliation` drift risk — line numbers drift — but that
is tangential to the boundary fix.)

## §4.4 — Is the workflow a LIVE documented procedure? Documented-live but UNBACKED

The workflow IS documented as a live client procedure —
`project-template/docs/pack/PM-CHAT.md` L752-857 and `supporting-docs/METHODOLOGY.md`
L1600-1630 instruct the client PM to run `pack td promote/resolve`. So it is not
"documented as deferred/dormant" (unlike `pack tracker`). It is documented as an
ACTIVE client verb. But per §4.1 the executable never reaches the client. So the
precise status is **documented-live but structurally unbacked on the client
side** — the worst failure mode: a client following the docs hits a missing
command.

## §4.5 — Load-bearing VERDICT

**The TD→phase promotion workflow (`pack-td.sh` + `tracker-promote.sh`) is
effectively DEAD machinery whose only executing "users" are its own three tests.**
Grounded in: (a) backing ships to NO client (§4.1); (b) NO runtime invoker
pack-side or client-side, no `pack` dispatcher exists (§4.2); (c) the one
apparent cross-lib dependency is a COMMENT, not a live call (§4.3); (d) nothing
but the 3 `test-tracker-promote-*.sh` tests calls `tracker_promote_*`. A wired
test is machinery exercising the code, NOT a user of the workflow. The workflow
is simultaneously (i) documented as a live client procedure and (ii) never
executable by any client — dead in practice, advertised in doc.

**Nuance for the architect:** "dead" describes the CURRENT execution reality, not
intended value. TD→phase promotion is a coherent, tested project workflow; the
defect is placement + ship, not the logic. Whether to revive-by-re-homing (ship
the backing to `project-template/scripts/` so the client docs become true) or to
retire (delete the advertising + machinery as unshipped dead code) is a
value/roadmap decision for the user/architect — surfaced in §5, not decided here.

---

# §5 — Open items (context + options + recommendation)

Per `open-item-surfacing`, every open item carries context, my own options, and an
evidence/logic-based recommendation (or explicit none). Nothing is deferred.

## OI-1 — Re-home vs delete (the central decision)

**Context.** `pack td` is a coherent, tested, DEAD-in-practice, client-advertised
project workflow whose backing never ships. The individually-correct insight from
the audits (TD promotion belongs on the client surface) means the two clean
end-states are: **(A) re-home** the backing to `project-template/scripts/` (+
`scripts/lib/` client-side) so the client advertising becomes true and the docs
executable; or **(B) delete** the advertising + the pack-side machinery as
unshipped dead code.

**Options with evidence:**
- **(A) Re-home.** Pros: honors the audits' TD-is-client-workflow ruling; makes
  PM-CHAT.md/METHODOLOGY.md/HELP-FRAGMENT.md true; `dependency-direction-placement`
  says "the default home for a new client-shipped script is
  `project-template/scripts/`" — this is where a client runtime tool BELONGS.
  Cons: `tracker-promote.sh` sits atop the tracker-lib family (provider/labels/
  links/phase-task) which is dormant/deferred (BD-214) — re-homing the promotion
  path may pull a dependency subtree client-side, OR require severing it from the
  deferred tracker machinery; the workflow is currently DEAD (§4.5), so re-homing
  revives an unused feature.
- **(B) Delete.** Pros: it is dead machinery (§4.5); `fail-loud-delete-old-source`
  favors deleting unshipped dead code over keeping a mirage; smallest surface,
  removes the CI-interlock burden. Cons: reverses the audits' "client workflow"
  ruling and discards a tested capability; TD lifecycle docs (Path 1/2/3) would
  need to drop the `pack td` mechanism and fall back to manual BACKLOG-edit.

**Recommendation (logic-based, non-binding — this is the architect's call):**
lead with **(A) re-home** IF the user still wants an executable TD→phase
promotion client verb, because four review passes and the user-locked rule "TD
entries are CLIENT-ONLY (operational TD lifecycle stays in client-facing docs)"
all affirm the workflow belongs client-side, and re-homing is the ONLY end-state
that makes the existing client documentation honest. Fall to **(B) delete** IF
the user judges TD→phase promotion not worth shipping (it has never executed for
any client — §4.5) — then delete advertising + machinery together as dead code.
The deciding input is a USER value judgment (is this feature wanted?) that this
inventory cannot supply; the DEPENDENCY-untangling cost of (A) vs the
capability-loss of (B) is the architect's trade to size. **No further deferral:
whichever path, it lands as scoped work, not a new deferred BD.**

## OI-2 — The BD-224 deliberate client-keep (`pack-help-test.sh` 2.2)

**Context.** BD-224 (dc82c2e) deliberately KEPT `pack td` on the client surface
and encoded it as `pack-help-test.sh` L185-187 `t_pass "2.2 client pack td rows
present"`. Any fix that removes/re-homes the client advertising CONTRADICTS this
assertion — it is a live encoding of the current (violating) state.

**Options:** (a) if re-home (OI-1 A): keep the client rows but ensure the backing
now ships — 2.2 stays true and gains meaning; (b) if delete (OI-1 B): 2.2 must be
inverted to assert ABSENCE. Either way `pack-help-test.sh` is in the fix's
lock-step surface set.

**Recommendation:** treat 2.2 as an artifact of the half-fix (§2.5), NOT as a
standing decision to protect — it was written to lock in a state nobody validated
for ship-correctness. Re-point it to whichever end-state OI-1 selects. Evidence:
its sibling 2.1 already asserts pack-surface ABSENCE, so the test file is designed
to encode whatever the surface policy is; updating 2.2 is mechanical.

## OI-3 — Scope of the tracker-family (Defect B) in this fix

**Context.** §3.5: `pack-tracker.sh` + `tracker-migrate.sh` + 18
`scripts/lib/tracker-*.sh` share `pack td`'s root cause (project-concept CLI
machinery homed pack-side by `pack-<noun>.sh` convention) but are dormant/deferred
(BD-214) and advertised nowhere — a weaker instance.

**Options:** (a) SCOPE-OUT — fix only `pack td` (the live-advertised acute
instance) and leave the dormant tracker family for the deferred tracker-redesign
group; (b) SCOPE-IN — treat the whole pack-side tracker home as one boundary
cleanup.

**Recommendation:** **scope-out (a)** for THIS fix. Logic: the tracker family
exposes no unbacked client capability (advertised nowhere, verbs refuse per
BD-214), so it fails the acute-violation test that makes `pack td` urgent; and the
tracker mode is a deferred-redesign surface (BD-185 is `Deferred`; no open
tracker-redesign BD exists) whose placement decision is entangled with that
redesign. Bundling it would balloon the fix's blast radius (18 libs + dispatcher)
for no live-safety gain. Recommend the architect NOTE the shared root cause in the
design doc and flag the tracker family for the tracker-redesign group, but not
edit it here. (This is a scoping recommendation, not a deferral of unblocked work:
the tracker family is genuinely BLOCKED on the deferred redesign, satisfying the
`deferral-is-scope-creep` BLOCKED test.)

## OI-4 — `.docs-gate-allowlist.txt` false "present after install" claim

**Context.** C1-c: the client-side allowlist exempts `pack-td.sh` +
`tracker-promote.sh` from the docs-gate with a reason that is factually FALSE
(they are never installed). This is an independent `declare-verify-backing`
defect that MASKS the dangling reference and would keep CI green even for a
client whose docs point at absent files.

**Options:** (a) if re-home: the reason becomes TRUE (they will be present after
install) — keep the rows, they are now correct; (b) if delete: remove the rows
with the advertising.

**Recommendation:** whichever OI-1 path is chosen, correct these two rows in
lock-step — they are not a neutral bystander, they are the interlock that hid the
bug. Evidence: `pack-help.sh`'s sibling allowlist row IS true (it ships at S11),
which is exactly why the false `pack-td.sh` row went unnoticed — it was pattern-
copied from a true row.

## §5.1 — Cross-BD collision scan (`cross-bd-collision-scan`)

I intersected the `pack td` fix's likely surface set (`project-template/docs/pack/
{HELP-FRAGMENT.md,PM-CHAT.md}`, `project-template/scripts/`, `supporting-docs/
METHODOLOGY.md`, `scripts/pack-td.sh`, `scripts/lib/tracker-*.sh`,
`scripts/tests/`, CI wiring) against every OPEN BD:

| Open BD | Title (abbrev) | Collision | Signal |
|---|---|---|---|
| **BD-257** (Open) | Client (project-side) slash-commands + execution foundation (project-side analog of BD-224) | **DIRECT** — BD-257 owns the CLIENT command surface (`project-template/skills/` + `project-template/scripts/` + client `docs/pack/`). A re-home of `pack td` to `project-template/scripts/` OR any edit to client `HELP-FRAGMENT.md`/`PM-CHAT.md` co-edits BD-257's exact surface. | **COORDINATE / SEQUENCE** — BD-257 is the natural home OR sequencing partner for the re-home path; the `pack td` client verb is precisely a "client slash-command + execution foundation" concern. Strongest collision. |
| **BD-205** (Open) | v11.0 final readiness audit (last gate) | Sequencing — a boundary fix this significant should land BEFORE BD-205 audits the tree. | COORDINATE (ordering). |
| **BD-210** (Open) | Pre-launch maintenance-docs cleanup (delete superseded docs) | Light — CLASS-3 historical (§1.4) is NOT scrubbed by this fix; BD-210 may separately prune superseded `PACK-REVIEW-*`/`AUDIT-*` docs. Orthogonal but same doc-tree. | NOTE (no gate). |
| **BD-202** (Open) | Universal `pack update` propagation engine | Light — if `pack td` re-homes to `project-template/scripts/`, it enters the client-installed set BD-202's engine propagates. | NOTE. |
| **BD-136** (Open) | Trinity marker-section preservation | Minimal — touches client `PM-CHAT.md` + trinity for a different concern; watch for same-file edit ordering on PM-CHAT.md. | NOTE (same-file serialize if concurrent). |
| BD-247 (Open) | Pack-side backlog form-family compliance | None on the `pack td` surface (form-family, not verb backing). | none |
| Others (BD-020/036/037/039/093/109/110/171/172/187/192/223/236/254) | — | No structured-surface intersection with the `pack td` set. | none |

**Deferred/related:** BD-185 (`Deferred`) is the flat-file/phase-parts half of the
tracker-redesign group; the tracker family (OI-3) belongs to that group. No OPEN
tracker-redesign BD exists at HEAD `0d427f9`.

**Non-empty intersection = COORDINATE signal, not a gate.** The load-bearing
collision is **BD-257** — an architect should sequence the `pack td` fix with
BD-257 (or fold the client re-home into BD-257's execution-foundation scope), since
both edit the client command surface. This is a coordination signal for the
user/architect, not a blocker.

---

# §6 — Rules-Applied Verification Block

Per rule, each rule in the prompt's "Rules in force" block is recorded with
verification evidence (quoted measurement) and a conclusion.

**agents-never-commit.** Evidence: I ran only read-only verbs (`git rev-parse`,
`git grep`, `git log`, `git ls-files`) and Bash reads; the SOLE file written is
this report at `/Users/david/Developer/_tmp/optiquity-pack-handoff/
boundary-blastradius-research-20260723/BOUNDARY-BLASTRADIUS.md`. No `git add/
commit/push/checkout/...` was invoked. HEAD unchanged at `0d427f9`.
**Conclusion: COMPLIANT.**

**memory-not-an-ssot.** Evidence: every claim cites a live file+line I read at
HEAD `0d427f9` (e.g. `boundary_refs.py:593-596` for the sanctioned set;
`init-project.sh:553-566` for the copy loop; `pack-help-test.sh:185-187` for the
2.2 assertion; `backlog/BD-224.md:25` for the BD-224 keep). The census count
(99/856) is a grep result, not recall. No claim rests on training data.
**Conclusion: COMPLIANT.**

**graph-first-context.** Evidence: discovery ran `graphify affected/query/explain
--graph <abs> --budget 1500 --backend claude-cli` FIRST (attested in "How
discovery used the graph"), which surfaced `tracker-bd129-gh-repo-test.sh` and the
maintenance-docs reference cloud beyond my a-priori pattern; THEN
`git grep -iE "pack[ -]td|pack_td|tracker[-_]promote"` established the exhaustive
literal set (99 files / 856 lines) as the completeness gate. G1 satisfied (graph
existed and was used); G2 not needed (queries returned useful sets).
**Conclusion: COMPLIANT.**

**declare-verify-backing.** Evidence: the not-shipped claim is grounded in
`find project-template -name pack-td.sh` (empty) + `init-project.sh:553-566`
(copies only `project-template/scripts/*`) + `_SANCTIONED_PACK_SIDE_SHIPPED`
membership (`boundary_refs.py:593-596`, not a member). The load-bearing/dead claim
is grounded in the zero-hit invocation greps (§4.2) and the tracker-edit COMMENT
quote (§4.3). The decision-history claims quote the actual audit/BD-224 text
(§2.2–§2.5). The `.docs-gate-allowlist.txt` false-claim is quoted verbatim (C1-c).
**Conclusion: COMPLIANT.**

**dependency-direction-placement / pack-side-project-concepts-deliverable-only /
pack-project-separation-of-concerns.** Evidence: §1 tags each CLASS-1 surface with
the specific rule it breaks; §2.2 identifies the V1 audit's misapplication of the
`deliverable-only` "constructor" carve-out; §3 frames the census on the
`_SANCTIONED_PACK_SIDE_SHIPPED` set and the `pack-<noun>.sh` convention root cause;
§5 OI-1 cites `dependency-direction-placement`'s "default home is
`project-template/scripts/`." Boundary analysis is framed by
`pack-ops/BOUNDARY-DEFINITION.md` §2 (two-axis matrix, read at L19-73).
**Conclusion: COMPLIANT.**

**fail-loud-delete-old-source.** Evidence: §1 partitions LIVE source (CLASS-1/2,
19 files) from HISTORICAL record (CLASS-3, 80 files under `maintenance-docs/**` +
`backlog/**`) and states CLASS-3 is NOT scrubbed; §5 OI-1 cites the rule as
favoring delete-over-mirage for the dead-code path. The untracked render artifact
is separated from both.
**Conclusion: COMPLIANT.**

**open-item-surfacing.** Evidence: §5 surfaces four open items (OI-1 re-home vs
delete; OI-2 the BD-224 client-keep; OI-3 tracker-family scope; OI-4 the false
allowlist claim), each with context + my own options + an evidence/logic-based
recommendation. No item is deferred to a new/other BD; OI-3's scope-out is
defended on the BLOCKED test, not a defer.
**Conclusion: COMPLIANT.**

**cross-bd-collision-scan.** Evidence: §5.1 intersects the fix's structured
surface set against every OPEN BD (enumerated via `Status: Open` grep over
`backlog/BD-*.md`), naming BD-257 (DIRECT), BD-205/210/202/136 (NOTE), and
confirming no tracker-redesign BD is open (BD-185 `Deferred`). Keyed on structured
paths, not free-text.
**Conclusion: COMPLIANT.**

**rules-applied-verification-block.** Evidence: this section. Each in-force rule
has name + quoted/pathed evidence + COMPLIANT conclusion; no AMBIGUOUS terminal
state.
**Conclusion: COMPLIANT.**

---

*End of RESEARCH-BD-272-BOUNDARY-BLAST-RADIUS.md (handoff name: `BOUNDARY-BLASTRADIUS.md`). Inventory + characterization only; the fix design
is the architect's job.*
