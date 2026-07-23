# AUDIT — BD-272 — Final Independent Audit: `pack td` Eradication Residue Census

> **Part of the BD-272 design chain** (as-landed reference record) — see `backlog/BD-272.md`. Chain order: `RESEARCH-BD-272-BOUNDARY-BLAST-RADIUS.md` → `ARCHITECTURE-BD-272.md` → `ADVERSARIAL-ARCH-REVIEW-BD-272.md` → `RECONCILIATION-ARCH-REVIEW-BD-272.md` → **AUDIT (this doc)**. This is the post-landing residue audit of the `pack td` eradication that shipped under BD-272 (the realized consumer of the chain).

**Status:** as-landed reference record (BD-272) · **Audit HEAD:** `3aba48a` (post-landing) · **Branch:** v11-dev.
**Auditor:** `pack-docs-researcher` (fresh, independent instance — did NOT design or implement this eradication)
**Date:** 2026-07-23
**Repo:** Optiquity AI Agent Config Pack (`optiquity-ai-agent-config-pack-v11-dev`)
**Runtime placement (verified at runtime):**
- `pwd` = `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` (canonical checkout — I was spawned isolated under `isolation_mode=full` and `cd`-ed here)
- `HEAD` = `3aba48abebfae6078f61832b85b82bd4dfd3ccec` (short `3aba48a`) — matches the expected `3aba48a`
- Branch = `v11-dev`, in sync with `origin/v11-dev` (both at `3aba48a`)
- Working tree = clean (`git status --porcelain` empty)
- Audited the COMMITTED live state at `3aba48a`.

---

## Method

1. **Discovery (graph-first, per `graph-first-context`).** Ran `graphify query` against the
   orchestrator-canonical graph `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json`
   (built 2026-07-23 13:22, post-BD-272) to widen recall before grep. The graph returned the trinity
   workflow nodes and the dormant tracker test nodes but **NO live `scripts/pack-td.sh` or
   `scripts/lib/tracker-promote.sh` source node** — corroborating deletion. The graph also surfaced
   the candidate surface families (scripts/tests, help fragments, project-template docs, pack-ops).
2. **Verification (grep-to-zero, per `graph-first-context` P2).** Grepped each candidate surface plus
   an exhaustive whole-tree union sweep, then classified every hit against the contract.

**Union pattern used** (case-insensitive):
`pack-td | pack td | pack-td.sh | tracker-promote | td promote | td resolve | promote --to=phase | promote orchestration | promote-orchestration | BD-107`.

---

## Master census — every hit bucketed by top-level directory

Whole-tree union sweep (excluding `.git/`, `graphify-out/`, `__pycache__/`):

| Top-level dir | Hit count | Classification |
|---|---:|---|
| `maintenance-docs/` | 624 | **CLASS-3 history** — architecture/plan/review/impl/audit/research docs (BD-107, BD-214 tracker-deferral, BD-206, BD-219 CI, etc.) |
| `backlog/` | 16 | **CLASS-3 history** — BD entries (BD-107, BD-204, BD-222, BD-224, BD-251, BD-272, BD-076) |
| `changelog/` | (in history bucket) | **CLASS-3 history** — release records the resolution gate preserves |
| `pack-ops/dashboard-approvals/dashboard.html` | (generated) | **CLASS-3** — generated dashboard artifact embedding a historical BD-224 snippet |
| `pack-ops/session-state.json` | 2 | **Live state snapshot (NOT residue)** — frontier note describing the eradication as DONE |
| `scripts/tests/pack-help-test.sh` | 11 | **Absence-guard (NOT residue)** — asserts the verb is ABSENT on both surfaces |

**No hits at all** in: `project-template/` (entire client-facing template tree), `supporting-docs/`
(incl. `METHODOLOGY.md`), `pack-ops/PACK-CHAT.md`, `pack-ops/PACK-AGENTS.md`, `README.md`, the pack-root
trinity (`CLAUDE.md`/`AGENTS.md`/`GEMINI.md`), `.github/` CI workflows, `scripts/validate-pack.py`,
`scripts/lib/validate_checks/` (incl. `help_fragments.py`), `scripts/ci-shard-weights.tsv`,
`scripts/lib/ci-shard-plan.py`, all `HELP-FRAGMENT*.md` (pack-ops + client + 3 fixtures).

---

## Live-surface hits — full classification (the only non-history occurrences)

### 1. `pack-ops/session-state.json` (2 hits) — NOT residue (live state snapshot)

- **L9** `"wave": "BD-272 (pack td eradication) FULLY LANDED — machinery deleted, client surface stripped, README residue cleared, and the dormant-tracker BD-107 promote-orchestration comment cites stripped; ... grep-zero for live pack td / BD-107 promote-orchestration references; the only surviving BD-107 mentions are CLASS-3 changelog history ..."`
- **L11** `"BD-272 awaiting the user's explicit resolve sign-off ... (grep-zero live pack td / BD-107 promote-orchestration; only changelog CLASS-3 history remains, which the gate keeps)."`

**Why NOT residue:** This is the committed session-state frontier snapshot (the `session-state-snapshot`
SSOT). It *describes the eradication as completed* and names BD-107 as history — it does NOT advertise a
`pack td` verb, does NOT reference the deleted machinery as if live, and carries no dangling live cite.
Naming the eradicated concept to record that it was eradicated is not residue.

### 2. `scripts/tests/pack-help-test.sh` (11 hits) — NOT residue (TEST NON-REGRESSION ABSENCE-GUARDS)

The `pack td` string appears ONLY inside must-NOT-be-present assertions and their explanatory comments:

- **L160** (pack surface): `[[ "$output" != *"pack td promote"* && "$output" != *"pack td resolve"* ]]`
  → **L161** `t_pass "2.1 pack td rows absent (pack surface)"` / **L162** `t_fail "... leaked onto pack surface"`
- **L186** (client surface): `[[ "$output" != *"pack td promote"* && "$output" != *"pack td resolve"* ]]`
  → **L187** `t_pass "2.2 client pack td rows absent"` / **L188** `t_fail "2.2 client pack td rows leaked"`
- **L6–7, L143–144, L156–158, L171** — comments explaining these guards ("the eradicated `pack td` verb
  rows are ABSENT on BOTH the pack and client", "BD-272 pack td eradicated").

**Why NOT residue:** The assertions use `!=` — they PASS when the verb is absent and FAIL if it ever
leaks back. This is exactly the sanctioned absence-guard: an assertion-of-absence, not an
assertion-of-presence. Covers both known sub-verbs (`promote`, `resolve`) on both surfaces.

### 3. `pack-ops/dashboard-approvals/dashboard.html` — NOT residue (CLASS-3 generated artifact)

Header: `<!-- pack-dashboard shell · spec: pack-ops/DASHBOARD-SPEC-PACK.md · spec-sha: 090132bd... -->`.
The `pack-td.sh` occurrence sits inside an embedded BD snippet: `BD-224 ... mark pack-td.sh`. This is a
generated dashboard artifact embedding historical backlog JSON — explicitly de-scoped as CLASS-3 by the
task contract and the resolution gate. NOT residue.

### 4. `scripts/pack-tracker.sh` `td` occurrences — NOT residue (dormant-tracker scope enum, not the verb)

- L137 `[--scope all|bd|td|inbound]`, L606 `all|bd|td|inbound) ;;`, L609 error text, L648 `"td-v11.0"` version string.

**Why NOT residue:** These are the SEPARATE, intentionally-kept dormant tracker subsystem's own
`--scope …|td|…` (tech-debt scope) vocabulary and version strings — NOT the eradicated
`pack td promote` / `pack td resolve` verb namespace. No `promote` verb, no `pack-td`, no
`tracker-promote` wiring. This is "INTENTIONALLY-KEPT LIVE CODE (NOT pack td)" per the contract.

---

## Targeted deletion + dangling-cite confirmations

| Check | Result |
|---|---|
| `scripts/pack-td.sh` exists? | **NO** (`ls`: No such file or directory) — deleted |
| `scripts/lib/tracker-promote.sh` exists? | **NO** (`ls`: No such file or directory) — deleted |
| Any `test-tracker-promote-*.sh` promote test files exist? | **NO** — none found |
| `HELP-FRAGMENT-TRACKER.md` exists (the planned tracker help fragment)? | **NO** — never/no-longer shipped |
| Dangling cite to `tracker-promote.sh` / BD-107 promote-orchestration inside the dormant tracker code (`tracker-labels.sh`, `tracker-phase-task.sh`, all `tracker-*.sh`)? | **NONE** — `grep -rniE "tracker-promote\|pack-td\|pack td\|BD-107\|promote orchestration" scripts/` returns ONLY the `pack-help-test.sh` absence-guards. `tracker-labels.sh` + `tracker-phase-task.sh` (both touched 13:21 by BD-272's cite-strip) are clean. |
| Mis-homed `# pack-internal` backing for a project-side promotion verb? | **NONE** — 45 `# pack-internal: true` files enumerated; none references `promote`/`pack-td`/`tracker-promote`. The deleted backing (`pack-td.sh`, `tracker-promote.sh`) is gone; the surviving pack-internal files are the legitimate tracker dispatcher, migrate wrapper, hooks, merge helpers, and test runners. |
| Client-surface `pack td` advertisement (help fragments, `PM-CHAT.md`, `METHODOLOGY.md`, docs-gate allowlists)? | **NONE** — all clean |
| CI interlocks (`ci-shard-weights.tsv`, `ci-shard-plan.py`, `help_fragments.py`, `validate-pack.py`, `.github/` workflows) referencing the deleted verb/tests? | **NONE** — all clean |
| Graph node-set contains a live `pack-td.sh` / `tracker-promote.sh` source node? | **NO** — corroborates deletion |

---

## Absence-guard confirmation (explicit)

`scripts/tests/pack-help-test.sh` intentionally asserts the `pack td` verb is **ABSENT** on both the pack
surface (test 2.1, L160–162) and the client surface (test 2.2, L186–188), via
`[[ "$output" != *"pack td promote"* && "$output" != *"pack td resolve"* ]]`. These are
assertions-of-absence (PASS on absent, FAIL on present) — the sanctioned non-regression guard, **not**
residue. There is no assertion anywhere that the verb is PRESENT.

---

## Open items

**None blocking.** Every hit classified deterministically against the contract; no genuinely ambiguous
occurrence required a judgment call.

One **non-blocking observation** (not residue, no action implied by this audit): the generated
`pack-ops/dashboard-approvals/dashboard.html` snapshot predates BD-272 (its embedded backlog JSON still
carries the BD-224 `pack-td.sh` snippet and shows no BD-272 record). Because it is a *generated* artifact
and the resolution gate treats it as CLASS-3, this is expected and not a defect. Options if the pack ever
wants it current: (a) leave as-is (a dashboard is regenerated on the next `/pack-dashboard` render — the
staleness self-heals and is de-scoped by the gate) — **recommended**, since regenerating solely to erase
historical embedded text would fight the CLASS-3 preservation intent; (b) regenerate now (cosmetic only).
Recommendation: **(a) leave as-is** — it is a generated view, self-healing, and explicitly de-scoped.

---

## VERDICT

Every remaining occurrence of the eradicated concept is one of: CLASS-3 historical record
(`backlog/`, `changelog/`, `maintenance-docs/`, the generated `dashboard.html`); the live
session-state frontier note recording that the eradication is done; the intentionally-kept dormant
tracker subsystem's own `td` scope vocabulary; or the sanctioned absence-guard in `pack-help-test.sh`.
The deleted machinery (`scripts/pack-td.sh`, `scripts/lib/tracker-promote.sh`) is gone, no dangling cite
to it survives in the dormant tracker code, no client surface advertises the verb, and no CI interlock
references the deleted verb/tests.

**No LIVE residue remains.**

---

## Rules-Applied Verification Block

- **agents-never-commit**
  - Evidence: Ran only read-only verbs — `git rev-parse`, `git status -sb`, `git status --porcelain`,
    `git log -1`, plus `ls`/`grep`/`find`/`graphify query` and one `Read`. No `git add/commit/push/tag/
    checkout/restore/reset/...` was invoked. The only write is this report at the caller-specified path
    (RO agent's single permitted write). Working tree remained clean at `3aba48a` throughout.
  - Conclusion: **COMPLIANT**

- **graph-first-context**
  - Evidence: Discovery ran `graphify query "…" --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --budget 1500 --backend claude-cli` FIRST (multiple queries), using the orchestrator-canonical graph path (not my own toplevel — I was isolated). Graph output: "NO live pack-td.sh / tracker-promote.sh source node in graph — corroborates deletion" and surfaced the candidate surface families. Then grep-to-zero verified each candidate. The completeness census grep ran as the VERIFICATION gate after graph discovery, not as a substitute for it.
  - Conclusion: **COMPLIANT**

- **memory-not-an-ssot**
  - Evidence: Every classification is sourced from live-repo command output quoted above
    (e.g., `ls: scripts/pack-td.sh: No such file or directory`; the L160/L186 `!=` assertions;
    the session-state L9/L11 text; the dashboard header spec-sha). No classification relied on
    training data or memory of a prior audit.
  - Conclusion: **COMPLIANT**

- **fresh-agent-default**
  - Evidence: I did not read, cite, or rely on any prior BD-272 audit/design/impl doc's conclusions.
    Verdict is re-derived independently from the live tree at `3aba48a` (e.g., I re-verified the
    deletions, the dormant-code cleanliness, and the absence-guards directly rather than trusting the
    session-state note's own "materially clean" claim).
  - Conclusion: **COMPLIANT**

- **open-item-surfacing**
  - Evidence: The "Open items" section surfaces the one non-blocking observation (stale generated
    dashboard snapshot) with context, both options, and an evidence-based recommendation
    ("(a) leave as-is"). No hit was silently classified where ambiguity existed; none was deferred to
    a new BD.
  - Conclusion: **COMPLIANT**

- **rules-applied-verification-block**
  - Evidence: This block enumerates each rule in force with quoted evidence and a terminal conclusion.
  - Conclusion: **COMPLIANT**

AUDIT VERDICT: CLEAN
