# ARCHITECTURE-BD-195-V10-CURRENCY-SWEEP

**Status:** Architect strategy (read-only design; no source edits, no git state
changes). Closes the BD-195 client-surface v10→v11 currency audit-coverage gap
in ONE measure-then-bound pass.
**Branch:** `v11-dev`. **HEAD at measurement:** `2c5989f`
(`2c5989f279921072398d0f602aaaf419857287b0`), working tree clean.
**Governing rule:** `ci-guard-measure-then-bound` (measure → categorize EVERY
occurrence → fix-recipe per STRIP → size to KEEP → verify post-design).
**Scope keyword for the realizing commit:** see §6 (none / no-keyword).

---

## 0 — Problem framing + scope challenge (preliminary-triage-architect-challenge)

BD-195's original audit under-covered ONE dimension on client-installed
surfaces: **stale "current pack version" currency** — a client-shipped doc
that STATES or IMPLIES the current pack version is v10/v10.0 when the shipping
version is **v11.0** (README version-table SSOT, EEB-1). C4 (`2c5989f`) fixed
the *ledgered* currency findings (K5.9–K5.14 identity headers, K3.6, NL-1) on a
per-finding basis; review-1 and review-2 then each surfaced MORE same-class
leaks not in the ledger (gitignore header token; new-project guidance; example
commit-message provenance "(v10.0)"; skill-coverage example). Iterative
fold-in is unreliable because no pass enumerated the FULL occurrence set. This
doc does that enumeration.

**Scope challenge (3 framings interrogated; results surfaced, not silently
expanded):**

1. **Which surfaces are "client-installed" (in scope)?** NOT "all of
   `supporting-docs/` + `project-template/`". The authoritative client-surface
   set is the Check 43 walk: `_iter_client_installed_files()` =
   **(a) all regular files under `project-template/**` (recursive)** PLUS
   **(b) the explicit `_CLIENT_INSTALLED_FILES` non-template entries**
   (`scripts/validate-pack.py:4116-4180`, EEB-2). The explicit (b) set that
   carries v10 tokens is: `QUICKSTART.md`, `supporting-docs/SETUP-NEW.md`,
   `supporting-docs/SETUP-EXISTING.md`, `supporting-docs/METHODOLOGY.md`,
   `supporting-docs/INSTALL-PROCEDURES.md` (EEB-2). **`supporting-docs/MIGRATION-v10-to-v11.md`
   is NOT client-installed** (absent from the inventory; EEB-2) and is OUT OF
   SCOPE — its ~majority share of the raw v10 count is migration-narrative ABOUT
   v10 and correct by construction. The prompt's "project-template/ inclusion to
   be validated" → VALIDATED IN (all of it is walked). The prompt's
   "~193 supporting-docs / ~33 project-template raw grep" → the in-scope subset
   is far smaller once MIGRATION-v10-to-v11.md and pure migration-narrative are
   excluded (EEB-3/EEB-4).

2. **Are there currency dimensions beyond the literal `v10` token that share
   this gap?** YES — TWO, surfaced not silently merged:
   - **Stale example commit-message / generated-output provenance** carrying
     `(v10.0)` (e.g. `git commit -m "... (v10.0)"`). This is a CURRENCY leak
     (the example tells a v11 client to stamp v10) and is exactly the class C4
     review-2 caught elsewhere. IN SCOPE as a STRIP class (S2).
   - **Pack-version FIELD/LABEL tokens** in template tables (e.g.
     `| Pack version in use | v9.[N] |`, `Pack (v9)`) — currency labels that
     should reflect the current major. IN SCOPE as STRIP class (S3).
   - **Branch-name / sidecar-filename / backup-path tokens** (`migration-v9-to-v10`,
     `*.v9-customized`, `v9.3-to-v10.0/`) — these are MIGRATION-MECHANISM
     identifiers, NOT currency claims (KEEP class K2). Surfaced and explicitly
     bounded OUT of the STRIP set so the sweep does not over-strip them.

3. **Does this sweep introduce/modify a CI guard?** NO. The broadened Check 43
   (C2, landed) already enforces pack-only-ref cleanliness; this sweep is a
   content-currency fix, not a new guard. Therefore the `ci-guard-measure-then-bound`
   contract is applied to the FIX-SET design (occurrence census + KEEP/STRIP +
   recipe + post-fix verify), not to a new allowlist. No allowlist is widened.

**The PRIMARY RISK is over-stripping** a legitimate historical / recovery /
migration / backup-path reference. The categorization below is built so a coder
applies it mechanically (decidable rule per class) and a reviewer confirms
completeness (no under-strip) AND safety (no over-strip) by re-running the §A
census command and checking each hit against its class rule.

---

## 1 — KEEP vs STRIP decision rule (one decidable test per class)

A v10/v9 occurrence on an in-scope client surface is **STRIP** iff it makes a
**present-tense currency claim** about THIS pack — i.e. it states or implies
the current/shipping pack version, or instructs the client to stamp/label
output with, a version OTHER than the current major (v11). Everything else is
**KEEP**. The classes (defined from the evidence, not assumed):

### STRIP classes

- **S1 — "current/new in vN" currency prose.** Text asserting a capability is
  "New in v10" or that the doc/pack "is v10", read by a client as the current
  state. Fix → current major (v11 / v11.0), value from README SSOT (EEB-1).
- **S2 — stale example commit-message / generated-output provenance.** A
  copy-paste example that stamps client output with `(v10.0)` /
  `(v10.0 pack install)`. The client following the example in v11 would write a
  wrong provenance string. Fix → `(v11.0)` / `(v11.0 pack install)`.
- **S3 — pack-version FIELD / inventory LABEL.** A template field or table cell
  whose VALUE is the pack version in use (`Pack version in use | v9.[N]`,
  `Pack (v9)` in a doc-inventory "Source" column). Fix → current major token
  (the placeholder form `v11.[N]` for fill-in fields; `Pack (v11)` for the
  inventory label), value from README SSOT.

### KEEP classes (preserve — over-stripping any of these is a regression)

- **K1 — migration-narrative / "see MIGRATION-v10-to-v11.md".** Any text whose
  subject IS the v10→v11 (or historical v9→v10) upgrade path, including the
  routing cites to `MIGRATION-v10-to-v11.md`, "upgrading from v10 to v11", and
  "Currently at v10.x — see …". Correct by construction.
- **K2 — migration-MECHANISM identifiers.** Branch names (`migration-v9-to-v10`),
  sidecar filenames (`*.v9-customized`, `_v9-backup.md`), backup paths
  (`.pack-migration-backup/v9.3-to-v10.0/`), Procedure 5-C/5-S references. These
  name real artifacts a migrating client encounters; renaming them would break
  the procedures.
- **K3 — recovery refs.** `git checkout v10 -- <path>` / `git checkout v10.0` /
  "v10 floating tag" — version-pinned recovery of sunset files. The v10 tag is
  the correct recovery source; KEEP verbatim.
- **K4 — accurate historical narrative.** "the v9->v10 migrator was sunset in
  v11", "manual in v9", "v9.x is no longer supported", "supersedes the v10
  three-outcome shape", "Retired in v10.0", "split in v11.0 (… v10.x …)". These
  describe what HAPPENED at a prior version; the v10/v9 token is the correct
  historical referent. (JC-5-class: leave accurate process history.)
- **K5 — grammar/format descriptors with a version qualifier that names the
  format generation, not the pack currency.** `one v10-grammar TD entry per
  file`, `v10-grammar CHANGELOG entry` (backlog/changelog `_rules.md` /
  `_format.md`). These name the on-disk entry-grammar generation (a stable
  format identifier), NOT a claim about the current pack version. **BORDERLINE
  → see §3 B1** (enumerated for resolution, not silently bucketed).

### BORDERLINE (enumerated for user/coder resolution — never silently bucketed)

- **B1 — `v10-grammar` format descriptors** (3 hits). KEEP-leaning (K5: names a
  format generation) but a reviewer could read "v10-grammar" as a stale
  currency token. Resolve before coding: confirm whether the on-disk entry
  grammar is unchanged since v10 (→ KEEP, correct descriptor) or was revised at
  v11.0 (→ STRIP to `v11-grammar`). §3 B1 carries the resolving question.
- **B2 — pack-only design-doc cite on a client surface** (METHODOLOGY.md:1412
  `V10-DESIGN §5.14.3`; the `V10-DESIGN.md` source is pack-only at
  `maintenance-docs/archive/`, EEB-5). This is a **pack-self-ref LEAK** (P-missed-7
  / bd-pack-only-operational-rule class), surfaced by the v10 scan but NOT a
  currency fix. Out of this sweep's STRIP set; **SURFACED** for separate
  disposition (drop the parenthetical cite or re-point to a client-resolvable
  anchor). Folding it into this currency commit would mix two finding families.

---

## 2 — Occurrence census (measure-first) — summary; full ledger in Appendix A

Raw substring counts at HEAD `2c5989f` (EEB-3/EEB-4):
`grep -rIn "v10" supporting-docs/` = **176**; `grep -rIn "v10" project-template/`
= **32**. The MAJORITY are out-of-scope (MIGRATION-v10-to-v11.md alone) or KEEP
(migration narrative / mechanism / recovery / history). **In-scope STRIP set =
the small buried subset enumerated in Appendix A.**

**In-scope file roster (v10/v9-bearing, client-installed per EEB-2):**

| File | In Check-43 walk via | v10/v9 hits | STRIP | KEEP | BORDERLINE |
|---|---|---|---|---|---|
| `supporting-docs/SETUP-NEW.md` | `_CLIENT_INSTALLED_FILES` (b) | 8 | 2 (S1,S2) | 6 | 0 |
| `supporting-docs/SETUP-EXISTING.md` | `_CLIENT_INSTALLED_FILES` (b) | 12 | 4 (S1,S2,S3-ish) | 8 | 0 |
| `supporting-docs/METHODOLOGY.md` | `_CLIENT_INSTALLED_FILES` (b) | 7 | 1 (S3) | 5 | 1 (B2) |
| `supporting-docs/INSTALL-PROCEDURES.md` | `_CLIENT_INSTALLED_FILES` (b) | ~70 | 0 | ~70 | 0 |
| `QUICKSTART.md` | `_CLIENT_INSTALLED_FILES` (b) | 2 | 0 (see note) | 1 | 1 (dead link → §3 B3) |
| `project-template/docs/pack/PACK-FEEDBACK.md` | `project-template/**` | 14 | 1 (S3) | 13 | 0 |
| `project-template/docs/pack/PM-CHAT.md` | `project-template/**` | 5 | 0 | 5 | 0 |
| `project-template/docs/pack/HELP-FRAGMENT.md` | `project-template/**` | 1 | 0 | 1 | 0 |
| `project-template/{CLAUDE,AGENTS,GEMINI}.md` | `project-template/**` | 1 each | 0 | 1 each | 0 |
| `project-template/.../pm-startup` (4 copies) | `project-template/**` | 6 each | 0 | 6 each | 0 |
| `project-template/docs/project/backlog/_rules.md` | `project-template/**` | 1 | 0 | 0 | 1 (B1) |
| `project-template/docs/project/changelog/_format.md` | `project-template/**` | 1 | 0 | 0 | 1 (B1) |
| `project-template/docs/project/changelog/_rules.md` | `project-template/**` | 1 | 0 | 0 | 1 (B1) |
| `project-template/skills/python-data-architecture/SKILL.md` | `project-template/**` | 1 | 0 | 1 | 0 |
| `project-template/skills/python-server-architecture/SKILL.md` | `project-template/**` | 1 | 0 | 1 | 0 |

**STRIP set total = 9 occurrences across 4 files** (Appendix A enumerates each
with file:line + surrounding context + fix-recipe). **BORDERLINE = 4** (3× B1
format-descriptor + 1× B2 pack-self-ref). The remaining ~200 raw hits are KEEP
(K1–K4) or out-of-scope (MIGRATION-v10-to-v11.md).

> **QUICKSTART.md note:** QUICKSTART:34 is a **dead hyperlink** to the sunset
> `MIGRATION-v9-to-v10.md` — that is **K3.7, already scheduled for C5** in
> PLAN-BD-195-REMEDIATION.md §4 (a dangling-doc fix, not a currency fix). It is
> NOT in this sweep's STRIP set; flagged here only so the reviewer does not
> double-schedule it. §3 B3 records the cross-reference.

---

## 3 — BORDERLINE resolution (surface for user/coder decision BEFORE coding)

Per `ci-guard-measure-then-bound` (no unclassified hit) + decision-presentation
protocol, each borderline is enumerated with the resolving question. The coder
does NOT decide these; Pack Chat surfaces them to the user.

**B1 — `v10-grammar` / `v10.x` format-generation descriptors (3 + 2 hits).**
- `project-template/docs/project/backlog/_rules.md:19` — "One v10-grammar TD
  entry per file, byte-additive on the legacy monolithic."
- `project-template/docs/project/changelog/_format.md:10` — "Each per-entry file
  contains one v10-grammar CHANGELOG entry."
- `project-template/docs/project/changelog/_rules.md:22` — "One v10-grammar
  CHANGELOG entry per file."
- (related) `project-template/skills/python-{data,server}-architecture/SKILL.md`
  — "the … half of the v10.x `python-architecture` skill, split in v11.0" —
  this one reads as **K4 history** (it explicitly says "split in v11.0", so
  "v10.x" is the prior generation being described) → KEEP, no resolution needed.
- **Resolving question (B1 only):** is the per-entry TD/CHANGELOG on-disk grammar
  UNCHANGED since it was introduced at v10 (→ KEEP: "v10-grammar" is the correct
  stable generation label) or was the grammar REVISED at the v11.0 per-entry
  split (→ STRIP to "v11-grammar")? Evidence to consult: BD-167/BD-168 per-entry
  split scope + the `_rules.md` entry-contract history. **Architect lean:** KEEP
  — "v10-grammar" names a format generation, and the same files describe the
  v11.0 split separately, so the grammar label is a stable historical
  descriptor, not a currency claim. Confirm before coding.

**B2 — pack-only design-doc cite on a client surface.**
- `supporting-docs/METHODOLOGY.md:1412` — "`scripts/add-capability.sh` stage A8
  (V10-DESIGN §5.14.3)." `V10-DESIGN.md` lives ONLY at
  `maintenance-docs/archive/V10-DESIGN.md` (pack-only; EEB-5), absent at any
  client. This is a **pack-self-ref leak** (bd-pack-only-operational-rule /
  P-missed-7), surfaced by the v10 scan but a DIFFERENT finding family from
  currency. **Disposition: SURFACE, do not fold into the currency commit** —
  fixing it here would mix a pack-self-leak fix into a currency commit. Options
  for separate handling: (a) drop the parenthetical `(V10-DESIGN §5.14.3)` cite
  (the sentence reads correctly without it), or (b) re-point to a
  client-resolvable anchor. Architect lean: (a) drop — lowest-risk, the cite
  adds no client-resolvable value.

**B3 — QUICKSTART.md:34 dead `MIGRATION-v9-to-v10.md` hyperlink.** Already
scheduled as **K3.7 → C5** (PLAN-BD-195-REMEDIATION.md §4). NOT in this sweep.
Recorded so the reviewer does not double-fix. No action here.

---

## 4 — Fix-recipes (per STRIP occurrence; SSOT-sourced; mechanical)

Every STRIP target's replacement value is sourced from the **README version
table** (current major = **v11**, current minor = **v11.0**; EEB-1) — never an
invented value. The coder applies these as **targeted in-place edits**
(edit-in-place-not-full-rewrite), one per line, re-reading each after edit.

| ID | File:line | STRIP class | Current text (verbatim) | Fix (SSOT-sourced) |
|---|---|---|---|---|
| V1 | `supporting-docs/SETUP-NEW.md:14` | S1 | `**New in v10:** a single …` | `**New in v11:** a single …` |
| V2 | `supporting-docs/SETUP-NEW.md:265` | S2 | `git commit -m "Add AI agent configuration (v10.0)"` | `… (v11.0)"` |
| V3 | `supporting-docs/SETUP-EXISTING.md:76` | S1 | `… TypeScript in v10.0). Installation still works …` | `… TypeScript in v11.0). …` |
| V4 | `supporting-docs/SETUP-EXISTING.md:172` | S2 | `git commit -m "Add AI agent configuration (v10.0 pack install)"` | `… (v11.0 pack install)"` |
| V5 | `supporting-docs/SETUP-EXISTING.md:258` | S2 | `git commit -m "Fill in context file placeholders (v10.0 pack install)"` | `… (v11.0 pack install)"` |
| V6 | `supporting-docs/SETUP-EXISTING.md:295` | S2 | `git merge --no-ff pack-init -m "Merge pack-init: add AI agent configuration (v10.0)"` | `… (v11.0)"` |
| V7 | `supporting-docs/SETUP-EXISTING.md:266` | S1 | `… not covered by v10.0 pack` | `… not covered by v11.0 pack` |
| V8 | `supporting-docs/METHODOLOGY.md:194` | S3 | `\| `METHODOLOGY.md` \| … \| Pack (v9) \| …` | `… \| Pack (v11) \| …` |
| V9 | `project-template/docs/pack/PACK-FEEDBACK.md:40` | S3 | `\| Pack version in use \| v9.[N] \|` | `\| Pack version in use \| v11.[N] \|` |

**Recipe notes (decidable, no re-deciding by coder):**
- V2/V4/V5/V6 (S2): replace ONLY the parenthetical version token; leave the rest
  of the example commit message byte-identical. The example teaches a v11 client
  to stamp v11.0 provenance.
- V8 (S3): the "Source" column value `Pack (v9)` is a doc-inventory currency
  label (the file is pack-shipped at the current version). Use `Pack (v11)`
  (major token, matching the column's other `Pack`-row convention). Do NOT touch
  the line-3 identity header — C4 already set it to v11.0 (EEB-1 context).
- V9 (S3): this is a fill-in TEMPLATE field; the placeholder form keeps the
  `[N]` minor placeholder and only corrects the stale major: `v11.[N]`.
- **NOT in the recipe set (KEEP — do NOT edit), high-risk over-strip guards:**
  SETUP-NEW.md:10/11/78/94/465/468; SETUP-EXISTING.md:12/17/18/19/37; every
  `*.v9-customized` / `migration-v9-to-v10` / `v9.3-to-v10.0` token in the
  pm-startup quartet + trinity; all of INSTALL-PROCEDURES.md's v9/v10 migration
  narrative; METHODOLOGY.md:1283/1291/1313/1314/1395/1397/1399/1401/1405;
  PM-CHAT.md:149-152/929; HELP-FRAGMENT.md:14; both SKILL.md `v10.x` history
  lines. Each is K1–K4 by the §1 rule.

---

## 5 — Sizing + post-design verification (measure-then-bound steps 4–5)

**Step 4 — STRIP set sized EXACTLY = 9 (V1–V9).** No occurrence outside V1–V9 is
STRIP. The KEEP set is NOT an allowlist that grows; it is "every other in-scope
v10/v9 hit", each decidable by the §1 rule. No CI guard/allowlist is added or
widened by this sweep.

**Step 5 — Projected post-fix verification (the coder MUST run all three):**

1. **No new under-strip / no over-strip — re-census.** After applying V1–V9,
   the §A census command re-run must show the 9 STRIP loci changed to v11/v11.0
   and EVERY other v10/v9 occurrence byte-unchanged. Concretely the coder
   diff-checks: `git diff --stat` touches exactly the 4 STRIP files (+ manifest
   if non-empty); `grep -nE "v10|v9"` on each of the 4 files shows the KEEP lines
   identical and only the V-row lines changed.
2. **validate-pack GREEN.** `python3 scripts/validate-pack.py` exits 0 ("PASSED —
   all checks clean"). Baseline is GREEN at `2c5989f` (EEB-6); the 9 edits are
   currency-token swaps on already-walked surfaces and introduce no new Check 43
   pack-only-ref, no dead path, no fixture-shape change → projected GREEN.
   (S2 commit-message examples and S1/S3 tokens are plain prose/table cells; no
   check asserts a specific version string on these lines — EEB-6 baseline + the
   absence of any version-token check over SETUP/PACK-FEEDBACK content.)
3. **Manifest discipline.** This commit touches `supporting-docs/` +
   `project-template/` (v11-surface) → coder RUNs `bash test-fixtures/build.sh
   --all --clean` and stages `test-fixtures/manifest.txt` IFF the diff is
   non-empty (regenerate-manifest-v11-surface). Of the 4 STRIP files, only
   METHODOLOGY.md ships into a fixture (to `docs/pack/`), so a non-empty manifest
   diff is POSSIBLE for V8; SETUP-*/QUICKSTART/PACK-FEEDBACK feed fixtures only
   if walked by build.sh — RUN-then-check is the authority (never predict-skip).

---

## 6 — Tracking + commit shape

- **Tracking anchor:** this is a BD-195 audit-coverage-gap closure (the v10→v11
  currency dimension the original audit under-covered). It lands as a **dedicated
  commit in push-group PG-2**, AFTER C4 (`2c5989f`) and BEFORE C9, consistent
  with PLAN-BD-195-REMEDIATION.md §3 PG-2 grouping (all client-surface fixes land
  in the one atomic PG-2 push that preserves green CI). It does not open a new BD
  (no new scope/feature/architecture; it completes BD-195's client-surface
  currency coverage) — confirm with the user per the OQ-1 / no-deferral rules.
- **Commit-subject scope keyword: NONE (no keyword).** The commit stages content
  under BOTH `supporting-docs/` (V1–V8) AND `project-template/` (V9) — and may
  stage `test-fixtures/manifest.txt` (outside both project-side prefixes). A
  `project-only` keyword would DENY the manifest path (and is moot if manifest
  diff is empty, but the mixed `supporting-docs/`+`project-template/` content is
  already fine under `project-only`); however to avoid the keyword-token trap and
  the manifest-path conflict, **use no keyword** (Check 36 skipped). Describe the
  scope in prose without any `pack-only`/`project-only`/`PM-only` literal token
  (commit-subject-keyword-token-trap).
- **Suggested subject (illustrative; Pack Chat authors the final):**
  `fix: v11 — BD-195 client-surface v10→v11 currency sweep (9 STRIP: SETUP-*/METHODOLOGY/PACK-FEEDBACK)`
- **Executor:** fresh `pack-coder`, bounded review/fix cycle. B1/B2 are NOT in
  the coder's scope until the user resolves them (§3); if B1 resolves to STRIP or
  B2 to fix, they ride a SEPARATE recipe/commit (B2 is a different finding family).
- **B2 separate handling:** if the user elects to fix B2 (pack-self-ref leak),
  it is a `bd-pack-only-operational-rule` surgical removal, distinct from this
  currency commit — do not merge.

---

## Appendix A — Full in-scope occurrence ledger (file:line → class → disposition)

Legend: **STRIP**=Vn recipe in §4; **KEEP(Kx)**=§1 KEEP class; **OOS**=out of
scope (not client-installed); **BORDER(Bx)**=§3.

### supporting-docs/SETUP-NEW.md  (client-installed via _CLIENT_INSTALLED_FILES)
| Line | Context | Class |
|---|---|---|
| 10 | `upgrading from v10 to v11, see MIGRATION-v10-to-v11.md` | KEEP(K1) |
| 11 | `v9->v10 migrator was sunset in v11; v9.x is no longer supported` | KEEP(K4) |
| 14 | `**New in v10:** a single scripts/init-project.sh` | **STRIP V1 (S1)** |
| 78 | `everything that was manual in v9` | KEEP(K4) |
| 94 | `guide; v9.x is no longer supported` | KEEP(K4) |
| 265 | `git commit -m "Add AI agent configuration (v10.0)"` | **STRIP V2 (S2)** |
| 465 | `Currently at v9.3 — v9 is no longer supported (the v9->v10 …` | KEEP(K4) |
| 468 | `Currently at v10.x — see MIGRATION-v10-to-v11.md` | KEEP(K1) |

### supporting-docs/SETUP-EXISTING.md  (client-installed)
| Line | Context | Class |
|---|---|---|
| 12 | `routes you to MIGRATION-v10-to-v11.md` | KEEP(K1) |
| 17 | `already on a prior pack version (v10): see` | KEEP(K1) |
| 18 | `MIGRATION-v10-to-v11.md. (Older MIGRATION-v9-to-v10.md is` | KEEP(K1/K4) |
| 19 | `historical, available via git checkout v10 -- <path>` | KEEP(K3) |
| 37 | `git -C "$PACK" checkout v10.0   # or v10 floating tag` | KEEP(K3) |
| 76 | `TypeScript in v10.0). Installation still works` | **STRIP V3 (S1)** |
| 172 | `git commit -m "Add AI agent configuration (v10.0 pack install)"` | **STRIP V4 (S2)** |
| 258 | `git commit -m "Fill in context file placeholders (v10.0 pack install)"` | **STRIP V5 (S2)** |
| 266 | `not covered by v10.0 pack` | **STRIP V7 (S1)** |
| 295 | `git merge … "Merge pack-init: add AI agent configuration (v10.0)"` | **STRIP V6 (S2)** |

### supporting-docs/METHODOLOGY.md  (client-installed)
| Line | Context | Class |
|---|---|---|
| 3 | `Version: 2.1 (v11.0, May 2026)` | KEEP (C4 already current) |
| 4 | `… AI Agent Config Pack v11` | KEEP (C4 already current) |
| 194 | inventory row `… \| Pack (v9) \| …` | **STRIP V8 (S3)** |
| 1283 | `(supersedes the v10 three-outcome shape)` | KEEP(K4) |
| 1291 | `v10 lifecycle unchanged` | KEEP(K4) |
| 1313-1314 | `supersedes the v10 fold-into-existing-task shape` | KEEP(K4) |
| 1395/1397/1399/1401/1405 | Procedure 5-C/5-R/5-S v9.3→v10 references | KEEP(K1/K2) |
| 1412 | `add-capability.sh stage A8 (V10-DESIGN §5.14.3)` | **BORDER B2** (pack-self-ref leak; §3) |

### supporting-docs/INSTALL-PROCEDURES.md  (client-installed)
~70 v9/v10 hits — ALL KEEP. The entire Procedure 5-C body is the v9.3→v10
reconciliation narrative explicitly marked HISTORICAL (sunset in v11), plus
`git checkout v10 --` recovery (K3), sidecar/branch mechanism (K2), and the
correct `MIGRATION-v10-to-v11.md` routing (K1). NL-1 (dead V10-DESIGN.md ref)
was already fixed in C4. **Zero STRIP.**

### QUICKSTART.md  (client-installed)
| Line | Context | Class |
|---|---|---|
| 33 | `v10 → v11: MIGRATION-v10-to-v11.md` | KEEP(K1) |
| 34 | dead link `v9 → v10: MIGRATION-v9-to-v10.md` | **BORDER B3** — already C5/K3.7 (§3) |

### project-template/docs/pack/PACK-FEEDBACK.md
| Line | Context | Class |
|---|---|---|
| 7 | `init-project.sh --update / migrate-v10-to-v11.sh` | KEEP(K1) |
| 40 | `\| Pack version in use \| v9.[N] \|` | **STRIP V9 (S3)** |
| 163, 297, 313, 331, 337, 352, 358, 359, 372, 378, 389, 395, 414, 420, 436, 439 | `[v9 release date]` seed placeholders + "after the v9 split" / "broken v9 defect" / "while using v9" seeded auditor-fix prose | KEEP(K4) — per NUD-5 (C4 ruling: keep illustrative prose) |

### project-template/docs/pack/PM-CHAT.md
| Line | Context | Class |
|---|---|---|
| 7 | `migrate-v10-to-v11.sh` | KEEP(K1) |
| 149 | `PROMPT-TEMPLATES.md Retired before v10` | KEEP(K4) |
| 150 | `Retired in v10.0 — replaced by per-agent files` | KEEP(K4) |
| 151 | `Moved to docs/pack/METHODOLOGY.md in v10.0` | KEEP(K4) |
| 152 | `Moved to docs/project/ARCHITECTURE.md in v10.0` | KEEP(K4) |
| 929 | `PM-CHAT.md.v10-customized sidecar` | KEEP(K2) |

### project-template/docs/pack/HELP-FRAGMENT.md
| Line | Context | Class |
|---|---|---|
| 14 | `bash scripts/migrate-v10-to-v11.sh … The v9→v10 migrator is sunset.` | KEEP(K1/K4) |

### project-template/{CLAUDE,AGENTS,GEMINI}.md  (trinity)
| Line | Context | Class |
|---|---|---|
| 452 / 428 / 481 | `v9.3 → v10 migration. See docs/pack/INSTALL-PROCEDURES.md Procedure` | KEEP(K1) — trinity-parity preserved (identical across the three) |

### project-template/.../pm-startup (skills/pm-startup/SKILL.md ×, .claude, .codex, .gemini commands)
All hits (`*.v9-customized`, `v9.3-to-v10.0/postrun-pending`, `_v9-backup.md`,
`migration-v9-to-v10` branch, `pre-C7 v10.0 installs`) = KEEP(K2) migration
mechanism. Quartet must stay in lock-step (same content across 4 copies). **Zero
STRIP.**

### project-template/docs/project/{backlog/_rules.md, changelog/_format.md, changelog/_rules.md}
`v10-grammar` descriptor ×3 = **BORDER B1** (§3). **Zero STRIP pending B1.**

### project-template/skills/python-{data,server}-architecture/SKILL.md
`v10.x python-architecture skill, split in v11.0` ×2 = KEEP(K4) (history; the
"split in v11.0" clause makes "v10.x" the prior-generation referent). **Zero STRIP.**

---

## Empirical-Evidence Blocks

### EEB-1: "The current shipping version is v11.0; v10.0 is the prior version."
- **Command:** `grep -n "v11.0\|v10.0" README.md | head -3`
- **Output:**
  ```
  60:| v11.0   | May 2026     | Issue-tracker integration … aggregate CI test runner across 41 suites
  61:| v10.0   | Apr 29, 2026 | Procedure 7 kickoff auto-discovery … validate-pack.py expanded to 10 checks
  ```
- **HEAD:** `2c5989f`; **Date:** 2026-06-03.
- **Interpretation:** README version table (the SSOT per trinity) lists v11.0
  (May 2026) as the top/current row; v10.0 (Apr 29 2026) is prior. Current major
  = v11; current minor = v11.0.
- **Conclusion:** SUPPORTED.

### EEB-2: "The client-installed (in-scope) surface set is project-template/** plus the explicit _CLIENT_INSTALLED_FILES entries; MIGRATION-v10-to-v11.md is NOT in it."
- **Command:** `sed -n '/_CLIENT_INSTALLED_FILES_START/,/_CLIENT_INSTALLED_FILES_END/p' scripts/validate-pack.py | grep -nE "supporting-docs|QUICKSTART"` + read of `_iter_client_installed_files()` (validate-pack.py:4116-4180).
- **Output:**
  ```
  130:    REPO_ROOT / "QUICKSTART.md",
  131:    REPO_ROOT / "supporting-docs" / "SETUP-NEW.md",
  132:    REPO_ROOT / "supporting-docs" / "SETUP-EXISTING.md",
  ```
  plus fence entries (validate-pack.py:4065-4066): `supporting-docs/METHODOLOGY.md`,
  `supporting-docs/INSTALL-PROCEDURES.md`. `_iter_client_installed_files()`:
  "(a) all regular files under project-template/ (recursive), and (b) the explicit
  non-project-template files in _CLIENT_INSTALLED_FILES".
- **HEAD:** `2c5989f`; **Date:** 2026-06-03.
- **Interpretation:** the Check 43 walk = all of project-template/ + the 5 explicit
  supporting-docs/QUICKSTART entries. `MIGRATION-v10-to-v11.md` does not appear in
  the inventory → not client-installed → out of scope.
- **Conclusion:** SUPPORTED.

### EEB-3: "supporting-docs/ raw v10 count = 176; the in-scope STRIP subset is small."
- **Command:** `grep -rIn "v10" supporting-docs/ | wc -l`
- **Output:** `176`
- **HEAD:** `2c5989f`; **Date:** 2026-06-03.
- **Interpretation:** the bulk of the 176 is MIGRATION-v10-to-v11.md (out of scope)
  + INSTALL-PROCEDURES.md migration narrative (KEEP). Per-file in-scope STRIP =
  V1,V2 (SETUP-NEW) + V3–V7 (SETUP-EXISTING) + V8 (METHODOLOGY) = 8 of 176.
- **Conclusion:** SUPPORTED (PARTIAL on the "small subset" qualitative claim,
  resolved by the per-file census in Appendix A).

### EEB-4: "project-template/ raw v10 count = 32; in-scope STRIP = 1 (V9)."
- **Command:** `grep -rIn "v10" project-template/ | wc -l` and `grep -rIl "v10" project-template/`
- **Output:** `32`; files = pm-startup quartet, trinity ×3, HELP-FRAGMENT,
  PACK-FEEDBACK, PM-CHAT, backlog/_rules, changelog/_format, changelog/_rules,
  python-data/server SKILLs.
- **HEAD:** `2c5989f`; **Date:** 2026-06-03.
- **Interpretation:** of the 32, exactly 1 (PACK-FEEDBACK.md:40 `v9.[N]`) is a
  currency FIELD → STRIP V9; 3 are B1 borderline; the rest KEEP (K1/K2/K4).
- **Conclusion:** SUPPORTED.

### EEB-5: "V10-DESIGN.md is pack-only (maintenance-docs/archive/), not client-installed."
- **Command:** `find . -name "V10-DESIGN.md" -not -path "./.git/*"`
- **Output:** `./maintenance-docs/archive/V10-DESIGN.md`
- **HEAD:** `2c5989f`; **Date:** 2026-06-03.
- **Interpretation:** the only V10-DESIGN.md is under maintenance-docs/ (pack-only);
  METHODOLOGY.md:1412 cites it on a client surface → pack-self-ref leak (B2), not a
  currency fix.
- **Conclusion:** SUPPORTED.

### EEB-6: "validate-pack is GREEN at HEAD 2c5989f (baseline)."
- **Command:** `python3 scripts/validate-pack.py; echo EXIT=$?` (run twice)
- **Output:**
  ```
  ============================================================
  PASSED — all checks clean
  EXIT=0
  ```
  (reproduced on a second independent run, exit 0)
- **HEAD:** `2c5989f`; **Date:** 2026-06-03.
- **Interpretation:** the pre-sweep baseline is fully green; the 9 currency-token
  swaps are prose/table-cell edits on already-walked surfaces with no
  version-asserting check over them, so the projected post-fix state stays green.
- **Conclusion:** SUPPORTED (baseline measured; post-fix is a PROJECTION the coder
  verifies per §5 step 2 — stated as projected, not measured).

### EEB-7: "The STRIP set is exactly 9 (V1–V9); no occurrence outside V1–V9 is STRIP."
- **Command:** per-file `grep -nE "v10|v9"` over the 4 in-scope STRIP files
  (SETUP-NEW, SETUP-EXISTING, METHODOLOGY, PACK-FEEDBACK) + classification against §1.
- **Output:** captured verbatim in Appendix A (every line listed with class).
- **HEAD:** `2c5989f`; **Date:** 2026-06-03.
- **Interpretation:** 9 lines match an S1/S2/S3 currency-claim test; all other v10/v9
  lines satisfy a KEEP class (K1–K4) or are BORDERLINE (B1×3, B2×1) or OOS.
- **Conclusion:** SUPPORTED.

---

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | No `git add/commit/push/tag` issued; only Read/Bash(grep,sed,find,python3 validate-pack)/file-write of THIS doc. `git status` was clean at start (`2c5989f`) and no state-changing verb was run. | COMPLIANT |
| agents-read-rule-docs-in-full | Read IN FULL: CLAUDE.md (541 lines); MEMORY.md (60-line index) THEN every linked memory file — feedback_prompts_grounded_in_facts, pack_chat_boundaries, review_fix_cycle, review_cycle_position_checkpoint, review_carry_forward_discipline, bd_pack_only_operational_rule, pack_project_separation_of_concerns, agent_prompt_enumerates_rules, agents_read_rule_docs_in_full, bd195_prompt_goals_section, agent_output_rules_applied_block, architect_planner_empirical_evidence, ci_guard_design_measure_then_bound, edit_in_place_not_full_rewrite, pattern_matching_out_of_context_antipattern, preliminary_triage_architect_challenge, groupings_design_principles, tracker_portability, triage_workflow_protocol, user_prescriptive_authority, scope_deliverables_to_the_ask, progress_marker_for_multi_step_phases, no_prefix_chars, no_prestaging_until_commit_approval, post_mv_restage_pattern, manifest_regen_on_v11_surface, commit_subject_keyword_token_trap, pack_agent_rule_hallucination, github_mcp_availability, pack_entry_type_semantics, sendmessage_uuid_addressing, project_v11_1_approved_scope, project_batch23_test_coverage_gaps — AND the 4 referenced PACK-MEMORY-RATIONALE.md sections (rules-applied, empirical-evidence, ci-guard, manifest-regen); PACK-AGENTS.md (226 lines); PACK-CHAT.md (310 lines); project-template/CLAUDE.md (455 lines); PLAN-BD-195-REMEDIATION.md (read §0–§645 + targeted §C4/C5/C6 + ledger). | COMPLIANT |
| empirical-evidence-blocks | Every state-claim (version SSOT, scope set, counts, pack-only ref, baseline green, STRIP=9) carries an EEB (EEB-1..EEB-7) with command + verbatim output + HEAD/date + interpretation + conclusion. | COMPLIANT |
| ci-guard-measure-then-bound | Applied to the fix-set: §2 measured FIRST (census, EEB-3/4/7); §1+Appendix A categorize EVERY occurrence KEEP/STRIP/BORDER (none unclassified); §4 fix-recipe per STRIP; §5 sizes STRIP=9 exactly (KEEP not widened, NO allowlist added/grown); §5 step-2 projects post-fix verify GREEN. | COMPLIANT |
| boundary-investigation-precedes-pack-defaults (P-missed-7) | In-scope set derived from the client-install SSOT (`_iter_client_installed_files`/`_CLIENT_INSTALLED_FILES`, EEB-2), not assumed; B2 (V10-DESIGN cite) flagged as a pack-self-ref leak kept OFF the currency commit; every fix value sourced from the client-resolvable README SSOT, no pack-only ref introduced. | COMPLIANT |
| preliminary-triage-architect-challenge | §0 challenged 3 framings (scope set; currency dimensions beyond the token; whether a new guard is needed) and surfaced findings (MIGRATION-v10-to-v11.md OOS; S2/S3 dimensions; no guard) rather than accepting the prompt's framing verbatim. | COMPLIANT |
| scope-deliverables-to-the-ask | Delivered exactly the asked artifact: census + KEEP/STRIP categorization + per-STRIP recipe + sizing/verify + commit shape; borderlines enumerated not sprawled; no SUSPECTED/edge-case padding. | COMPLIANT |
| rules-applied-verification-block | This block. | COMPLIANT |
| preflight-stop-means-stop | No fabrication (every claim EEB-backed or Appendix-A-listed); no parent stop/halt received; would halt immediately if one arrived. | COMPLIANT |
