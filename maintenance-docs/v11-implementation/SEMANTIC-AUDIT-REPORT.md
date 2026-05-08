# BD-097 v11.0 Pre-Release Semantic Audit Report

**Date:** 2026-05-07
**Auditor:** pack-architect (semantic audit role; read-only)
**Repo HEAD:** main @ e07c318 (`docs: v10 — rename to Optiquity AI Agent Config Pack`)
**Pre-release tag pin gate:** BD-093 (open).
**Scope:** v11.0 release surface — code, docs, BACKLOG, CHANGELOG, README,
QUICKSTART, supporting-docs, HELP-FRAGMENT files, trinity files, validate-pack
checks, test suites, tracker artifacts.

---

## 1. Audit prompt summary

The audit was invoked under BD-097 to gate BD-093 (release pin). Scope as
specified in the BD-097 prompt:

1. Code-doc agreement — HELP fragments vs. scripts; MIGRATION-v10-to-v11.md vs.
   migrate-v10-to-v11.sh; MERGE-STRATEGY.md vs. customization-preserve.sh;
   PACK-CHAT.md / PM-CHAT.md recommendation routing vs. recommendation.sh;
   OPTIONAL-FEATURES.md tracker section vs. pack-tracker.sh; tracker.toml.example
   vs. tracker-config.sh.
2. Doc-doc consistency — README v11.0 row vs. CHANGELOG v11.0 entry; README
   Repository Layout vs. filesystem; QUICKSTART links vs. targets; BACKLOG
   Resolved entries vs. git log.
3. BD-NNN integrity — Resolved BD work shipped; CHANGELOG ↔ BACKLOG status
   parity; carried-over discipline; spot-checks.
4. Trinity-rule consistency — Quick reference block byte-identity within tier;
   validate-pack Checks 18 + 19 logic.
5. CI / validation — `validate-pack.py` 25 Checks; `scripts/tests/*` v11
   suites; CI vs. local coverage delta.
6. Stale references / typos — `v10` strings in user-facing v11 docs; `pack
   tracker forward|reverse` references; `7 client signals` references; stale
   `project-template/<root>.md` references after BD-042.

Pass criteria: zero BLOCKER findings; every WARNING dispositioned. Audit is
the gate before BD-093 release pin (tag, README hash, CHANGELOG final).

---

## 2. Methodology

Read-only audit, no files in the working tree modified except this report.
Verifications run:

- **`python3 scripts/validate-pack.py`** — full run; all 25 Checks (plus 2
  unnumbered informational checks for issue forms and template archive)
  PASSED clean.
- **`bash scripts/tests/test-customization-preserve.sh`** — 72/72 pass.
- **`bash scripts/tests/recommendation-test.sh`** — 53/53 pass.
- **`bash scripts/tests/pack-help-test.sh`** — 17/17 pass.
- **`bash scripts/tests/test-migrate-v10-to-v11.sh`** — 35/35 pass.
- **`bash scripts/tests/test-init-project.sh`** — 30/30 pass.
- **Filesystem walks** — every path in README Repository Layout was checked
  for existence; every QUICKSTART link target was checked; agent counts
  (Claude/Codex/Gemini) verified at 16/16/16.
- **Cross-tool diffs** — Quick-reference block content compared across the
  six trinity files (3 pack-root + 3 client) with awk extraction.
- **grep sweeps** — `pack tracker forward|reverse`, `7 client signals` /
  `seven client-side signals`, `project-template/<root>.md`, `v10\.0` /
  `Pack v10` in v11 user-facing docs, `auditor-issue-tracking`.
- **BD-NNN integrity sweep** — every Resolved BD in v11 Active block read for
  status + Resolved date; cross-checked CHANGELOG `Carried over` list against
  BACKLOG Status; spot-checked BD-088 / BD-082 / BD-085 commit references in
  `git log`.
- **Behavior verification by reading code paths** — pack-tracker.sh verb
  dispatch table; migrate-v10-to-v11.sh stage/exit-code surface; init-project.sh
  stage S5 / S11 install flow; customization-preserve.sh class dispatcher.

CI vs. local coverage delta noted in §6.

---

## 3. Findings by severity

### 3.1 BLOCKERS

**B-1 — Client-side `/pack-help` SKILL invokes a script the install never
delivers.** All three client-side pack-help surfaces invoke `bash
scripts/pack-help.sh` as a relative path:

- `project-template/.claude/skills/pack-help/SKILL.md:9` — ``!`bash scripts/pack-help.sh` ``
- `project-template/.codex/skills/pack-help/SKILL.md:9` — ``!`bash scripts/pack-help.sh` ``
- `project-template/.gemini/commands/pack-help.toml:8` — `!{bash scripts/pack-help.sh}`

`scripts/init-project.sh` stage S5 (`stage_s5_scripts`, line 410) copies
`project-template/scripts/` into `$TARGET/scripts/`, which contains only
project build/test/format scripts (`bootstrap.sh`, `validate.sh`, etc.).
**It does NOT copy `pack-repo/scripts/pack-help.sh` or `pack-repo/scripts/lib/`
into the project tree.** Stage S11 (line 692) installs HELP-FRAGMENT files,
tracker config, issue forms, and the per-CLI pack-help skill files — but not
the script those skills invoke.

Result: every project initialized or upgraded by v11 will have a `/pack-help`
slash command that fails at runtime with `bash: scripts/pack-help.sh: No such
file or directory`. The shell verb `pack help` (LCD floor) only works from
the pack repo root, not in the project. This contradicts the explicit
v11 promise that the client `/pack-help` skill works in projects.

Cross-evidence:
- `BACKLOG.md:307` (BD-077 Resolved) explicitly says: *"Note: client-side
  install gap (init-project.sh doesn't yet copy `scripts/lib/` + `pack-help.sh`)
  closed by BD-080."* — but BD-080's S11 implementation does not close it.
- `supporting-docs/MIGRATION-v10-to-v11.md:372-378` Troubleshooting section
  states the script "lives at the pack repo root, not in your project … the
  CLI commands … route to your **pack repo's** `scripts/pack-help.sh`." But
  the SKILL files have no `$PACK`-relative path or absolute resolution; they
  use the relative form `scripts/pack-help.sh`.
- `scripts/tests/test-init-project.sh:171-179` only verifies `SKILL.md`
  presence; it does not exercise the underlying invocation.

**Resolution options** (architect/planner decide; do not implement here):
either (a) install `pack-help.sh` + `scripts/lib/` into the client project at
S11 — the pattern BD-077 / BD-080 originally promised; or (b) rewrite the
client SKILL to resolve via `$PACK` env var or `find` against a known
pack-repo path. Option (a) restores the documented contract and matches the
truthful claim in BACKLOG line 307. Option (b) requires changes to MIGRATION
prose and adds a runtime dependency on an env var being set when the slash
command fires — fragile.

This is the only finding the auditor judges hard-blocking for a v11.0
release-pin: shipping a feature that fails on first use is a documentation/
release-evidence defect.


### 3.2 WARNINGS

**W-1 — `HELP-FRAGMENT-PACK.md` lists wrong verbs for `pack-tracker.sh`.**
`HELP-FRAGMENT-PACK.md:30` reads:

> `scripts/pack-tracker.sh <subcmd>` | Tracker mode — `init`, `forward`,
> `reverse`, `status`, `doctor`, `enable-recommendations`.

`scripts/pack-tracker.sh` actual verb dispatcher (line 412-420) accepts:
`init`, `status`, `mirror-rebuild`, `disable`, `doctor`, `update-templates`,
`enable-recommendations`. The verbs `forward` and `reverse` are NOT in
`pack-tracker.sh` — they live in the lower-level `tracker-migrate.sh`. A user
following HELP-FRAGMENT will get `pack-tracker.sh: Unknown verb: 'forward'`.

The correct verb names for the user-facing surface (per
`HELP-FRAGMENT-TRACKER.md` and `OPTIONAL-FEATURES.md`) are `init` (forward
migration on opt-in) and `disable` (reverse migration on opt-out).

**W-2 — `README.md:184` repeats the same wrong-verb pattern.** The
Repository Layout entry for `pack-tracker.sh` reads `Tracker opt-in /
forward / reverse / status / doctor (v11)`. Same code-doc drift as W-1;
should be `init / status / mirror-rebuild / disable / doctor /
update-templates / enable-recommendations`.

**W-3 — `MIGRATION-v10-to-v11.md:253` directs users at a non-existent verb.**

> To opt out later: `bash scripts/pack-tracker.sh reverse` (idempotent).

`pack-tracker.sh` has no `reverse` verb. The opt-out flow is `pack tracker
disable`. This will fail for any user who follows the printed instructions.

**W-4 — Client trinity templates self-identify as v10.** All three client
templates carry a v10 self-label that v11 will ship unchanged into every new
project:

- `project-template/CLAUDE.md:21` — `*Copied from: project-template/CLAUDE.md — AI Agent Config Pack v10*`
- `project-template/AGENTS.md:20` — same pattern
- `project-template/GEMINI.md:17` — same pattern

`scripts/init-project.sh` and `scripts/migrate-v10-to-v11.sh` do not
rewrite this line. Every v11 project init / `--update` plants a trinity
template advertising itself as v10. User-misleading on every fresh
project. Trinity rule applies (all three templates affected together).

**W-5 — `init-project.sh` writes a hardcoded v10.0 banner into client
`.gitignore`.** `scripts/init-project.sh:518`:

```bash
local header="# --- AI Agent Config Pack additions (v10.0) ---"
```

The same string also appears in `scripts/add-capability.sh:371`. v11
`init-project.sh --update` will inject "v10.0" annotations into every
project's `.gitignore`. Cosmetic but visibly stale across the entire fleet
of client projects.

**W-6 — `OPTIONAL-FEATURES.md:161` and `MIGRATION-v10-to-v11.md:59` cite a
ship-quality `auditor-issue-tracking` agent that does not exist in v11.**

- `OPTIONAL-FEATURES.md:160-164` — *"once opted in, every
  `auditor-issue-tracking` agent run (pack-side or client-side) reads issue
  state via the TrackerProvider…"* (declares agent behavior as if shipped).
- `MIGRATION-v10-to-v11.md:59` — *"Issue tracking auditor agent
  (`auditor-issue-tracking`): pack / client surface verbs."* (in "What
  changed in v11" Phase B list, framed as shipped).
- `supporting-docs/MERGE-STRATEGY.md:190` — also references this agent file
  in passing.

`BACKLOG.md:896-908` shows BD-109 (`Project-side auditor-issue-tracking
sub-agent`) is **Open** (`Resolved: n/a`); no agent file exists under
`project-template/.claude/agents/` or `.codex/agents/` or `.gemini/agents/`.
v11 docs over-claim a feature that lands later. User reading
OPTIONAL-FEATURES.md or MIGRATION will look for an agent that does not
exist.

**W-7 — `BACKLOG.md` v11 Active block header undercount.** `BACKLOG.md:25`
states:

> The v11.0 implementation surface. 51 BD entries (BD-060..BD-110)…

Actual count: 53 entries (BD-060..BD-112 in v11 block; BD-111 and BD-112
were added during v11 development). The numeric claim is stale and the
range bound is wrong.

**W-8 — `BACKLOG.md` BD-072 / BD-074 record "7 client signals" but code
ships 6.** Drift introduced before fix-follow.

- `BACKLOG.md:211` (BD-072 description): *"(3 signals pack-side; 7
  client-side)"*
- `BACKLOG.md:217` (BD-072 Resolved line): *"recommendation_compute_signals
  (3 pack / 7 client)"*

`scripts/lib/recommendation.sh:80-97` (`_rec_signal_names`) emits exactly
**6** client-side signals: `td_count_active`, `backlog_kb`, `phase_count`,
`implementation_plan_kb`, `td_tbd_comment_count`, `typed_deferral_count`.
Code matches CHANGELOG.md (line 33) and `PM-CHAT.md:203` ("6 client-side
signals"). BACKLOG entries are the only documents claiming 7 — likely a
pre-fix-follow remnant the Resolved-line text never updated.

**W-9 — CHANGELOG fixture-test arithmetic is off by 17.** `CHANGELOG.md:50-51`:

> 72 BD-088 fixture tests (137 total v11 fixture tests across BD-088 / BD-080
> / BD-085 / pack-help) on bash 3.2.57.

Verified counts (live): BD-088 → 72; BD-080 → 30; BD-085 → 35; pack-help → 17.
Sum across all four = 154. Sum across the first three (BD-088 + BD-080 +
BD-085, dropping pack-help) = 137 — which matches the CHANGELOG number, but
the CHANGELOG text claims pack-help is in the rollup. Either the listed-set
or the rollup number is wrong.

**W-10 — Trinity Quick-reference block byte-identity hidden by missing
trailing `---`.** Pack-root trinity files (`CLAUDE.md`, `AGENTS.md`,
`GEMINI.md`) close the Quick-reference block with a thematic break (`---`);
client-tier files (`project-template/CLAUDE.md` etc.) do not. The
two-bullet body is byte-identical *within* each tier (verified by awk
extraction); the closer differs across tiers. validate-pack Check 21 / 24
do not check the closer; this is below the validate threshold but worth
noting if BD-081 byte-identity audit was meant tier-symmetric.

**W-11 — CHANGELOG "Carried over to future work" list does not match the
set of v11-Open BDs.** CHANGELOG enumerates BD-093, BD-095, BD-097, BD-098,
BD-110, BD-111, BD-112 as carried over. BACKLOG status sweep shows
**fourteen** v11-Active BDs Open at audit time:

- BD-078, BD-079 — validate-pack checks (deferred)
- BD-093, BD-095, BD-096, BD-097, BD-098, BD-099 — release-pin / migration / docs
- BD-100, BD-101, BD-102 — verification gates
- BD-103, BD-104, BD-105 — operational tooling
- BD-106, BD-107, BD-108 — phase-task entity model
- BD-109, BD-110 — auditor agents (BD-110 is in CHANGELOG; BD-109 is not)
- BD-111, BD-112 — operational fixes

CHANGELOG omits BD-078 / BD-079 / BD-096 / BD-099 / BD-100 / BD-101 / BD-102
/ BD-103 / BD-104 / BD-105 / BD-106 / BD-107 / BD-108 / BD-109. This may be
intentional (only the headline carry-overs are enumerated) but is
asymmetric with the rest of the CHANGELOG entry's exhaustive style and
risks readers thinking the unlisted items are out-of-scope rather than
deferred-and-still-tracked.


### 3.3 NOTES (informational; no action required for BD-093 unless the
maintainer disagrees with the read)

**N-1 — `PACK-AGENTS.md:70` cites "v10 design pass" as an example of
pack-architect work.** Example text (non-load-bearing); will read fine
post-v11 as long as v11 design is also recognizable. May be refreshed at
maintainer discretion.

**N-2 — README Repository Layout omits four pack-side scripts.**
`scripts/compare-agent-trinity.py`, `scripts/test-detect.sh`,
`scripts/test-migration.sh`, `scripts/test-restore-from-backup.sh` exist on
disk but are not enumerated under the `scripts/` block in README.md. The
block is illustrative rather than exhaustive (it groups
`merge-{json,toml,trinity,platform-skills}.py` etc.) — but a maintainer
who reads "13 scripts" implied may be surprised.

**N-3 — `supporting-docs/CLI-PM-SETUP.md` has no v11-awareness.** No
mention of `pack-help`, `pack tracker`, or v11 specifically. Reads as a
v10-stable doc; this may be intentional (CLI-PM-SETUP is about CLI tooling,
not pack features) but worth a maintainer call.

**N-4 — `MIGRATION-v10-to-v11.md:115-127` exit-code table has a small gap.**
Codes 21–30 are listed as "Stage `S<n>` failure"; the migrator only has
seven stages (S0–S6), so codes 27–30 are unreachable. Functionally fine —
the table just over-allocates; a tighter row would say `21–27`. NOTE-level.

**N-5 — `pack-tracker.sh:74-77` `usage()` function still describes
`disable | doctor | update-templates | enable-recommendations` as
"Pending" with `not-implemented validation error`.** All four verbs are now
implemented (lines 134-399). The `usage()` block is stale — users running
`pack-tracker.sh --help` see an inaccurate roadmap. NOTE-level (does not
affect runtime behavior).

**N-6 — `init-project.sh` v10.0 references in comments / code.**
`scripts/init-project.sh:454`, `:489` carry comment-level `v10.0` markers
documenting historical decisions. Comment-only; non-load-bearing.

---

## 4. Per-area summary

### 4.1 Code-doc agreement

| Surface | Status | Notes |
|---|---|---|
| HELP-FRAGMENT-PACK.md vs. pack-tracker.sh | **DRIFT** | W-1 (wrong verb list). |
| HELP-FRAGMENT-PACK.md vs. tracker-migrate.sh | OK | Forward/reverse/status/doctor verbs match. |
| project-template/docs/pack/HELP-FRAGMENT.md vs. install state | **BLOCKER** | B-1 (script not delivered). |
| HELP-FRAGMENT-TRACKER.md vs. pack-tracker.sh | OK | All 7 documented verbs present. |
| MIGRATION-v10-to-v11.md vs. migrate-v10-to-v11.sh | **DRIFT** | W-3 (wrong opt-out verb), W-6 (premature auditor citation). Stages and exit codes match. |
| MERGE-STRATEGY.md vs. customization-preserve.sh | OK | 12 classes match (3.1.1-12 in doc; cases in `_cp_apply_class`); 8 disposition tokens match. |
| PACK-CHAT.md / PM-CHAT.md vs. recommendation.sh | OK | 3 pack signals + 6 client signals consistent in both. |
| OPTIONAL-FEATURES.md vs. pack-tracker.sh | **DRIFT** | W-6 (auditor); verbs `init`/`status`/`doctor`/`disable` correct. |
| tracker.toml.example vs. tracker-config.sh | OK | Keys (`backend.name`, `backend.repo`, `id_namespace.prefix`, `migration.mapping_file`, `mode.state`) all read by lib. |

### 4.2 Doc-doc consistency

| Pair | Status | Notes |
|---|---|---|
| README v11.0 row vs. CHANGELOG v11.0 entry | OK (W-9) | Date / scope / BD list aligned; CHANGELOG arithmetic off by 17. |
| README Repository Layout vs. filesystem | OK (N-2) | All listed paths exist; four script files unlisted. |
| QUICKSTART.md cross-links | OK | Every link target exists. |
| BACKLOG.md Resolved v11 entries vs. git log | OK | Spot-checks (BD-088, BD-082, BD-085) align with commit references. |
| BACKLOG.md v11-block header vs. actual count | **DRIFT** | W-7 (stale "51 BD entries (BD-060..BD-110)"). |

### 4.3 BD-NNN integrity

| Check | Result |
|---|---|
| All Resolved v11 BDs have shipped artifacts | OK — every Resolved BD spot-checked has corresponding code and tests. |
| CHANGELOG Resolved claims match BACKLOG status | OK — every BD enumerated in CHANGELOG v11.0 implementation block is Resolved in BACKLOG (BD-060..BD-077, BD-080..BD-092, BD-094). |
| No Open BDs cited as shipped (other than carried-over list) | **DRIFT** — W-6 (auditor-issue-tracking agent referenced as shipped in OPTIONAL-FEATURES and MIGRATION; BD-109 is Open). |
| Carried-over list completeness | **DRIFT** — W-11 (14 v11-block Open BDs; only 7 enumerated in CHANGELOG). |
| Spot-checks (5+ BDs) | OK — BD-088 (72 tests), BD-082 (Checks 21–24 active), BD-085 (S0–S6 stages, 35 tests), BD-080 (30 tests), BD-072/-074 (53 tests) all confirmed. |

### 4.4 Trinity rule

| Check | Result |
|---|---|
| Pack-root trinity Quick-reference body byte-identity | OK — three files identical (`pack help` / `pack-startup` lines plus closing `---`). |
| Client trinity Quick-reference body byte-identity | OK — three files identical (`pack help` / `pm-startup` lines, no closer). |
| Cross-tier closer symmetry | DRIFT (W-10) — pack-root closes with `---`; client tier does not. Below validate-pack threshold. |
| validate-pack Check 18 (H2 structure parity) | PASS (live run). |
| validate-pack Check 19 (no body scaffolding) | PASS (live run). |
| Trinity Copied-from line currency | DRIFT (W-4) — all three client templates self-identify as v10. |

### 4.5 CI / validation

| Check | Result |
|---|---|
| `python3 scripts/validate-pack.py` | **PASSED** — all 25 numbered Checks + 2 informational checks clean. |
| Test suites run locally | BD-088 (72), BD-080 (30), BD-085 (35), recommendation (53), pack-help (17) — all green. |
| CI workflow vs. local | `validate` job + `tests` job per `.github/workflows/validate-pack.yml`; 17 test suites enumerated; `if: always()` failure isolation per BD-083. Aligned with CHANGELOG claim. |
| CI ↔ local delta | None significant. CI runs `scripts/test-detect.sh` (which is a pack-side script, not under `scripts/tests/`) — accounted for in the "17 suites" total. |

### 4.6 Stale-references / typos sweep

| Pattern | Result |
|---|---|
| `pack tracker forward\|reverse` user-facing | 3 hits (W-1, W-2, W-3). |
| `7 client signals` / `seven client-side` | 2 hits in BACKLOG (W-8); none in CHANGELOG / PM-CHAT / code. |
| `project-template/<root>.md` post-BD-042 | 0 hits in user-facing v11 docs. Remaining hits are intentional (BACKLOG context lines, MIGRATION-v8-to-v9.md historical, customization-preserve.sh class membership, test fixtures). |
| `v10` in v11 user-facing docs | Localized: W-4 (trinity Copied-from), W-5 (`.gitignore` banner). N-1 (PACK-AGENTS.md example), N-6 (init-project comments) are non-load-bearing. |
| `auditor-issue-tracking` in user docs | 3 hits — W-6. |


---

## 5. Disposition recommendation for BD-093 (release pin)

**Recommendation: HOLD on BD-093 release pin until B-1 is resolved.**

The audit found one BLOCKER (B-1) — the client `/pack-help` skill is broken
on first use after every v11 init / `--update`. This is a core v11
deliverable per BD-077 / BD-080 / D-20 and is the headline user-facing
verb-system feature of the release. Pinning v11.0 with this defect would:

- Falsify BD-077 BACKLOG `Resolved` claim (line 307 explicitly says
  BD-080 closes the install gap; BD-080 does not).
- Force every v11 adopter to discover the failure at first `/pack-help`
  invocation.
- Require a v11.0.1 patch within days of release.

The ten WARNING items (W-1 through W-11) are individually small but
collectively undermine release-evidence quality. The auditor recommends
clearing the four cheap ones in the same fix-follow as B-1:

- W-1 / W-2 / W-3 — replace `forward` / `reverse` references with
  `init` / `disable` (3 surface edits).
- W-6 — guard the `auditor-issue-tracking` references so they read as
  "v11.x roadmap" rather than "v11.0 ship".

The remaining warnings (W-4 / W-5 / W-7 / W-8 / W-9 / W-10 / W-11) are
either docs-drift (W-4 / W-5 / W-7 / W-8 / W-11), arithmetic drift (W-9), or
trinity-symmetry detail (W-10). All can be cleaned in a single docs commit
without code changes; whether to bundle into the BD-093 release-pin commit
or ship as W-prefixed follow-up BDs is a maintainer judgment call.

NOTES (N-1 through N-6) are deferred without strong recommendation.

**The audit does NOT clear BD-093 for release pin in its current state.**

Re-audit gate: re-run this audit after B-1 is resolved AND the four cheap
warnings (W-1 / W-2 / W-3 / W-6) are dispositioned. The remaining warnings
can be carried as their own BD or batched into a single docs cleanup.

---

## 6. Followup BD list (proposed; for Pack Chat to assign numbers)

The pack BACKLOG resolves in place; no separate Resolved section. Numbers
below assigned by Pack Chat after this audit.

| Proposed BD | Severity | Title | Files touched |
|---|---|---|---|
| BD-NNN-A | BLOCKER | `/pack-help` client install gap — install `pack-help.sh` + `scripts/lib/` into client at S11, OR rewrite client SKILL invocations to a pack-resolving form | `scripts/init-project.sh`, `scripts/migrate-v10-to-v11.sh`, possibly `project-template/.{claude,codex,gemini}/{skills,commands}/pack-help/*` |
| BD-NNN-B | WARNING | `pack-tracker.sh` verb-list drift — fix three doc surfaces | `HELP-FRAGMENT-PACK.md`, `README.md`, `supporting-docs/MIGRATION-v10-to-v11.md` |
| BD-NNN-C | WARNING | Trinity / `.gitignore` v10 self-label drift | `project-template/{CLAUDE,AGENTS,GEMINI}.md`, `scripts/init-project.sh`, `scripts/add-capability.sh` |
| BD-NNN-D | WARNING | `auditor-issue-tracking` premature ship-claim | `OPTIONAL-FEATURES.md`, `supporting-docs/MIGRATION-v10-to-v11.md`, `supporting-docs/MERGE-STRATEGY.md` |
| BD-NNN-E | WARNING | BACKLOG / CHANGELOG arithmetic and stale headers | `BACKLOG.md` (line 25 + BD-072 prose), `CHANGELOG.md` (test rollup line) |
| BD-NNN-F | WARNING | CHANGELOG carried-over list completeness | `CHANGELOG.md` v11.0 entry |
| BD-NNN-G | NOTE | Trinity Quick-reference closer symmetry | All 6 trinity files |
| BD-NNN-H | NOTE | `pack-tracker.sh` usage() text stale ("Pending" verbs already implemented) | `scripts/pack-tracker.sh:74-77` |
| BD-NNN-I | NOTE | README Repository Layout — list four omitted scripts | `README.md` |
| BD-NNN-J | NOTE | MIGRATION-v10-to-v11.md exit-code table — tighten 21–30 to 21–27 | `supporting-docs/MIGRATION-v10-to-v11.md` |

Some of these can be batched (B and D are 1-line edits across 3 files
each; E and F are CHANGELOG-only). The auditor estimates the BLOCKER plus
the four cheap warnings is one focused fix-follow + Pack Chat approval to
move BD-093 forward.

---

## 7. Audit notes — what was NOT checked

- **Live `pack tracker init` end-to-end against a real GH repo.** Out of
  scope for read-only audit; covered by BD-102 (pack-repo dog-food).
- **Migrator dry-run against a fixture.** Live OT-style migration covered
  by `test-migrate-v10-to-v11.sh` (35 tests, green); a real-project run
  is BD-102 territory.
- **Cross-tool runtime parity** — Codex `/pack-help` and Gemini
  `/pack-help` were not invoked live. The SKILL/TOML files are
  byte-checked by validate-pack Check 21–24, but B-1 affects all three CLIs
  identically.
- **`compare-agent-trinity.py` execution** — exists but was not invoked.
- **Pre-BD-042 historical accuracy in archive docs** — out of scope.

---

## 8. References

- `scripts/validate-pack.py` (live run; PASSED).
- `scripts/lib/recommendation.sh:80-97` (signal lists).
- `scripts/lib/customization-preserve.sh:160-175` (disposition mapping),
  `:492-518` (class dispatcher).
- `scripts/migrate-v10-to-v11.sh:34-40` (exit codes), `:63-364` (stages).
- `scripts/init-project.sh:410-435` (S5 scripts copy), `:692-754` (S11
  v11 artifacts).
- `scripts/pack-tracker.sh:412-420` (verb dispatch).
- `scripts/pack-help.sh:93-134` (surface dispatch + fragment paths).
- `project-template/.claude/skills/pack-help/SKILL.md`,
  `.codex/skills/pack-help/SKILL.md`,
  `.gemini/commands/pack-help.toml` (broken invocations).
- `BACKLOG.md` (full file), `CHANGELOG.md:8-104` (v11.0 entry),
  `README.md:60` (v11.0 row), `:85-218` (Repository Layout).
- `HELP-FRAGMENT-PACK.md` (lines 30–31), `HELP-FRAGMENT-TRACKER.md`,
  `OPTIONAL-FEATURES.md:125-181`,
  `supporting-docs/MIGRATION-v10-to-v11.md`,
  `supporting-docs/MERGE-STRATEGY.md`,
  `PACK-CHAT.md:102-128`,
  `project-template/docs/pack/PM-CHAT.md:200-220`.

---

**Audit complete. Disposition: HOLD.**
