# PLAN (V4 — FINAL, INTEGRATED) — BD-243 remaining work: BLOAT wave + CLIENT-SIDE doc gate + PACK durable gates + surfaced fixes

Planner: FRESH planner instance (pack-planner, RO). I did NOT author `PLAN-BD-243-FINAL-V3.md`, `DESIGN-BD-243-CLIENT-GATE.md`, `DESIGN-BD-243-DURABLE-GATES.md`, or any prior BD-243 artifact; conclusions are my own (reconciliation-instance-independence). I independently re-measured every load-bearing fact at runtime (§13 Empirical-Evidence Blocks carry my own commands + verbatim output).
Runtime: repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, branch `v11-dev`, canonical HEAD **`103cca8`** (verified at runtime — `git rev-parse HEAD` = `103cca8e51feef9c80e4e76be17bd0dd274d3a6b`, clean working tree, untracked plan docs only), 2026-06-22. READ-ONLY; no edits, no patch, no state-changing git.
Status: **PLANNER-READY** — goes to the user at the planner-to-coder gate (planner-output-user-review); NOT auto-approved into a coder spawn. This is the user's last cheap redirect window before CB-01's coder spawns.

## What V4 is

V4 = V3 (the bloat wave CB-01..CB-09 + the pack gate wave CG-14-prep-a/-b/CG-14 + surfaced fixes) **PLUS** the user's newly-added shipped **CLIENT-side doc-enforcement gate** (`project-template/scripts/validate-docs.sh`, the dual-surface mirror designed in `DESIGN-BD-243-CLIENT-GATE.md`) **PLUS** the user's binding decisions **DC-1..DC-6**. V4 SUPERSEDES V3 as the executable sequence. The single most consequential V4 change vs V3 is the **count bump moves 63 → 68** (not 63 → 67): DC-2 adds the pack-side parity check as the **5th** new check, folded into CG-14's atomic registration event.

The STRIP phase (CG-01..CG-13) is DONE, committed, pushed, CI-green at `103cca8`; V4 does NOT re-plan or re-run it.

---

## 0. EXECUTIVE ANSWER (decision-ready)

- **Total remaining commits: 14** (V3's 13 + 1 client-gate ship commit), with the same two sanctioned reviewability splits available (CB-09 → CB-09a/b) → up to 15.
- **The commit sequence (dependency-correct, the ordering-resolution applied):**
  - **Bloat wave (9):** CB-01 .. CB-09 (CB-07/08/09 clean the project-template; CB-09 splittable).
  - **Client-gate ship commit (1): CG-CLIENT** (`project-only`) — ship `validate-docs.sh` (4 axes, DC-4/DC-5) + `.docs-gate-allowlist.txt` + wire into `validate.sh` + the `agent-post-edit-check.sh` `*.md` branch + `--self-test` (DC-6) + the trinity Scripts-table row ×3. **Positioned AFTER the bloat wave but BEFORE CG-14-prep-a** (the ordering resolution — §1).
  - **Pack gate-infra commit (1): CG-14-prep-a** (`pack-only`) — `_iter_operating_docs()` + EXEMPT + Gate 4 (Check 69) body + Check-65 repoint + R2 + GC-3/GC-4 records. Authored-unregistered (count still 63).
  - **Pack gate-content commit (1): CG-14-prep-b** (`pack-only`) — Checks 66/67/68 bodies + the **parity check** body (`check_client_doc_gate_parity`) + allowlists + Gate-1 parameters from the reduced tree + the dangling-ref fix. Authored-unregistered (count still 63).
  - **Pack activation commit (1): CG-14** (`pack-only`) — register **5** new checks (66/67/68/69 + parity) + bump `CHECK_REGISTRY_EXPECTED_COUNT` **63 → 68** + flip Check 44 advisory→FAIL (Gate 1a) + populate Check 65 over the full IN set. ONE atomic count event.
  - **Final push (1 step, not a commit):** manifest-sync (CG-CLIENT changed a fixture INPUT → expect exit 10 → commit the regenerated `test-fixtures/manifest.txt`) → push → CI watch.
- **THE ORDERING RESOLUTION (the critical dependency the prompt names):** I adopt **option (a) — ship the client gate (CG-CLIENT) BEFORE the CG-14 atomic registration**, placed right after the bloat wave and before CG-14-prep-a. Rationale (§1): the parity check (DC-2, registered atomically in CG-14) verifies that `project-template/scripts/validate-docs.sh` EXISTS + is wired + carries all 4 axes — so the file MUST exist when the parity check activates. Shipping it before CG-14 keeps ALL 5 registrations + the 63→68 bump as ONE atomic event with NO lenient-skip window (the cleaner, leaner option the prompt asks me to recommend). Option (b) — a skip-if-absent lenient parity check + CG-15-after-CG-14 — is REJECTED (§1.3): a lenient window is exactly the silent-rot posture BD-243 exists to eliminate, and it would let the parity check pass against a non-existent gate.
- **THE COUNT-BUMP IS NOW 63 → 68 (5 new checks), NOT 63 → 67.** This is the load-bearing repeat-CI-failure-prevention item, re-enumerated for 5 checks in §2. The surface that MUST move in lock-step: S1 the constant (`= 68`), S2 the **5** new registry entries (66/67/68/69 + parity), S3/S3b the comment ledger + the STALE prose "62", and **S4 = `scripts/tests/test-validate-pack-check-64.sh` which hardcodes the literal `63` at lines 74-75 + the pass-message at line 82 → must become `68`.** All new per-check tests use the DYNAMIC count form, never the hardcoded literal.
- **Per-commit verification = the FULL wired battery** (`ci-shard-plan.py` all shards + `validate-pack.py` no-flag + the per-check tests incl. the count-invariant tests) BEFORE the patch — verify-full-ci-suite (§4).
- **User decisions encoded exactly (V3's D-1..D-4 + R2 carried; the NEW DC-1..DC-6 folded):** DC-1 RE-IMPLEMENT (no shared lib); DC-2 ship the parity check as the 5th check, count 63→68; DC-3 NO shipped client CI; DC-4 client bloat axis = per-bullet char-cap ONLY; DC-5 OMIT Gate-4 meta-check client-side (4 client axes); DC-6 a `--self-test` flag (no separate shipped test file).

---

## 1. THE ORDERING RESOLUTION (the parity-check ↔ validate-docs.sh dependency)

The prompt names this the CRITICAL dependency I MUST resolve. Here is the dependency, the two options, my recommendation, and the justification.

### 1.1 The dependency stated precisely

- DC-2 ships the pack-side **parity check** (`check_client_doc_gate_parity` in `scripts/validate-pack.py`). Per the client-gate design §C.3, it asserts the shipped `validate-docs.sh` (1) EXISTS in the project-template, (2) is executable, (3) declares each of the 4 axes (a structural grep for axis-marker comments, e.g. `# AXIS: history|deferred|bloat|dangling`), and (4) is wired into the shipped `validate.sh` + `agent-post-edit-check.sh`.
- DC-2 ALSO folds that parity check into CG-14's atomic registration (it is the **5th** new check; count 63 → 68).
- THEREFORE: at the instant CG-14 registers the parity check and it begins running in the no-flag battery, `project-template/scripts/validate-docs.sh` MUST already exist + be wired — otherwise the parity check FAILS at its own activation (a RED activation commit), or it must be written lenient (skip-if-absent), which defers the contract.
- The client-gate design (§E.1) provisionally placed the client gate at **CG-15, AFTER CG-14**. That ordering CONFLICTS with the parity check being live at CG-14: CG-14 would register a parity check whose target does not yet exist.

### 1.2 The two options + my decision

**Option (a) — ship the client gate BEFORE the CG-14 registration (ADOPTED).** Place the client-gate ship commit (CG-CLIENT, `project-only`) right after the bloat wave (after CB-09) and BEFORE CG-14-prep-a. Then by the time CG-14 atomically registers the parity check, `validate-docs.sh` already exists + is wired + carries its 4 axis-markers, so the parity check passes against a real, complete gate. ALL 5 registrations + the 63→68 bump stay ONE atomic event with NO lenient-skip window.

**Option (b) — lenient skip-if-absent parity check + CG-15 after CG-14 (REJECTED).** Write `check_client_doc_gate_parity` to soft-pass when `validate-docs.sh` is absent (the V3 design notes Check 65's lenient/inert-until-populated mode as a precedent), register it at CG-14 (63→68), then ship the client gate at CG-15 after. REJECTED for three reasons:
1. **A lenient window is the silent-rot posture BD-243 exists to eliminate.** A parity check that passes when its target is absent provides zero enforcement between CG-14 and CG-15 — and if CG-15 were ever dropped/deferred, the lenient check would pass FOREVER against a non-existent gate. That is exactly the "cleanup silently rots" failure the user is closing.
2. **It splits one logical contract across two commits with a gap.** The parity check and the gate it polices are a lock-step pair (enumerate-encoding-surfaces); landing the policer before the policed creates a window where the invariant is unverifiable.
3. **It adds permanent dead code** (the skip-if-absent branch persists after CG-15 makes it unreachable — a maintenance smell with no benefit once the gate ships).

**Option (a) is the cleaner, leaner path the prompt asks me to recommend.** The only cost of (a) is that CG-CLIENT lands before the pack gate wave rather than after it — which is fine, because (next subsection) CG-CLIENT's own measure-then-bound baseline is satisfied by the bloat wave alone (CB-07/08/09), NOT by the pack gate wave.

### 1.3 Why CG-CLIENT's baseline is satisfied before CG-14 (the dependency that makes (a) safe)

The client gate's measure-then-bound baseline (client-gate design §B.3) is "the bloat-reduced + history-clean **project-template**." That cleanliness is produced by **CB-07 + CB-08 + CB-09** (the project-side bloat commits, incl. the D-1 PLATFORM-SKILLS strip at CB-08). It is NOT produced by the pack gate wave (CG-14-prep-a/-b/CG-14), which touches `scripts/validate-pack.py` + pack-side allowlists ONLY — those commits do not edit `project-template/` content. So CG-CLIENT can be sized + verified against the final project-template the moment CB-09 lands; it does NOT need CG-14 first.

The client-gate design's §E.1 claim "Depends on CG-14" is therefore only HALF true: CG-CLIENT depends on CG-14 ONLY via the parity check's reciprocal need. Resolving that with option (a) (ship CG-CLIENT first, register the parity check after) INVERTS the stated dependency cleanly: CG-CLIENT depends on the bloat wave (real, content dependency); CG-14's parity check depends on CG-CLIENT (real, existence dependency). Both are satisfied by `CB-09 → CG-CLIENT → CG-14-prep-a → CG-14-prep-b → CG-14`.

### 1.4 The resolved order (one line)

```
CB-01 .. CB-09  →  CG-CLIENT (project-only, ships validate-docs.sh)  →  CG-14-prep-a  →  CG-14-prep-b  →  CG-14 (atomic: register 5, count 63→68)  →  final push
```

**EE-ORDER — CG-CLIENT's baseline is the project-template, cleaned by the bloat wave not the pack gate wave @ `103cca8`.**
- Cmd: `grep -n "Operating docs carry NO history" project-template/{CLAUDE,AGENTS,GEMINI}.md` (the rule the client gate enforces, project-side); `git show --stat 103cca8 -- scripts/validate-pack.py | head` (the pack gate wave touches validate-pack.py, a pack-side file).
- Output (verbatim, key): rule at `project-template/CLAUDE.md:242`, `AGENTS.md:226`, `GEMINI.md:239`; the pack gate wave's surface is `scripts/validate-pack.py` + `pack-ops/.*-allowlist.txt` (pack-side), which do NOT edit `project-template/` content.
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: the client gate enforces a PROJECT-side rule over PROJECT-template content; that content is made clean by CB-07/08/09 (project-only). The pack gate wave is pack-side and does not change the project-template. So CG-CLIENT's measure-then-bound baseline is ready after CB-09, before CG-14 — option (a) is safe.
- Conclusion: **SUPPORTED.**

---

## 2. THE COUNT-BUMP SURFACE ENUMERATION — UPDATED TO 63 → 68 (5 new checks)

**This is the single most defect-prone step in the entire plan and the load-bearing repeat-CI-failure-prevention item.** V3 enumerated 63→67 for 4 checks; DC-2 adds the parity check as the 5th, so V4's bump is **63 → 68**. The check NUMBERS are 66/67/68/69 + one parity number (the next free integer at activation time — **70** if assigned sequentially; the coder assigns the next free integer when registering, and number ≠ count, so the count is the entry-count delta = +5, NOT the max number). The CAUTION at validate-pack.py:489-491 states number ≠ count explicitly (Checks 16/18/19 register TWICE; 2 checks carry number=None) — so the count LAGS the max number.

**The 5 new checks (each +1 registry entry, +5 total):**
1. **Check 66** — `check_operating_doc_bullet_concision` (Gate 1b, pack bullet char-cap).
2. **Check 67** — `check_operating_doc_no_deferred_feature` (Gate 2, pack deferred-feature recall).
3. **Check 68** — `check_dangling_file_refs` (Gate 3, pack dangling-ref).
4. **Check 69** — `check_operating_doc_scope_completeness` (Gate 4, pack new-doc meta-check).
5. **Check 70** (next free integer) — `check_client_doc_gate_parity` (DC-2, the pack-side parity check that polices the shipped client gate).

Gate 1a (Check 44 advisory→FAIL) and R2 (Check 65 `incident` tighten) are in-place edits to EXISTING checks = **+0 registry entries** each.

**EVERY surface that encodes the count — measured authoritatively via `grep` (grep is authoritative here, not the graph) — that MUST move in lock-step in the CG-14 count-bump commit:**

| # | Surface | File:line(s) @ `103cca8` | Current value | Required at CG-14 | Mechanism | Miss = CI failure? |
|---|---|---|---|---|---|---|
| S1 | The constant itself | `scripts/validate-pack.py:496` | `CHECK_REGISTRY_EXPECTED_COUNT = 63` | `= 68` | literal | **YES — Check 59 FAILs** |
| S2 | The **5** new `CHECK_REGISTRY` entries | `scripts/validate-pack.py` registry tail (after the Check-65 entry at line 10350) | (absent) | append `(66,…)`,`(67,…)`,`(68,…)`,`(69,…)`,`(70,"check_client_doc_gate_parity",…)` | registry tuples | YES — count won't reach 68 without all 5 |
| S3 | The EXPECTED_COUNT comment LEDGER | `scripts/validate-pack.py:475-495` (the arithmetic `+1 net-new …` block) | sums to 63 | add **5** `+1 net-new BD-243 check (66/67/68/69/70 …)` lines; update the CAUTION's "(65 for BD-243)" → note 66-70 | comment | NO (doc only) but REQUIRED for audit hygiene + the in-file lock-step contract |
| S3b | The STALE prose "62" in that comment | `scripts/validate-pack.py:476` ("so the registry now holds **62** entries") | says 62 (already stale; constant is 63) | reconcile to 68 | comment prose | NO (doc only) — fix it in the same commit; it is already wrong at `103cca8` and the count-bump is the natural reconciliation point |
| S4 | **The hardcoded-literal test** | `scripts/tests/test-validate-pack-check-64.sh:74-75` (`if mod.CHECK_REGISTRY_EXPECTED_COUNT != 63: … FAIL_COUNT_NOT_63`) + line 82 pass-message `(== 63)` | hardcodes `63` | `!= 68` + `FAIL_COUNT_NOT_68` + message `(== 68)` | literal in a `.sh` test | **YES — this test FAILs in CI; THIS is the recent-failure class** |
| S5 | Check 59's runtime assertion | `check_registry_completeness` (`len(_build_check_registry()) == CHECK_REGISTRY_EXPECTED_COUNT`) | dynamic | self-satisfies once S1+S2 land together | code (no edit) | auto (FAILs if S1/S2 out of sync) |
| S6 | Check 60's shard-coverage mirror | `check_ci_shard_coverage` (derives the shard partition from the registry) | dynamic | self-satisfies once S2 lands | code (no edit) | auto |
| S7 | ci-shard-plan.py test-discovery (new per-check tests) | `scripts/ci-shard-plan.py` parse_wired_tests() globs `scripts/tests/*.sh` | dynamic glob | self-satisfies — the 5 new `test-validate-pack-check-NN.sh` files match the glob shape; NO allowlist edit (the allowlist is an EXCLUDE list of manual-only scripts, not an include list) | code (no edit) | auto (a new test must match the glob shape) |

**The DYNAMIC tests that need NO value edit (verified — do NOT touch, but VERIFY they pass):** `test-validate-pack-check-62.sh:70` (`len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT`), `test-validate-pack-check-63.sh:62` (same dynamic form), `test-validate-pack-checks-58-59-60.sh:145-147` (dynamic form, `actual = len(...)` then `!= CHECK_REGISTRY_EXPECTED_COUNT`). These compare the COMPUTED registry length to the constant, so a correct +5 bump satisfies them automatically. **The asymmetry between S4 (hardcoded literal) and these (dynamic) is the trap — only check-64's test hardcodes the literal `63`.**

**The 5 NEW per-check tests (66/67/68/69/70) MUST use the DYNAMIC count-invariant form, never the hardcoded literal** (`if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT` + `if NN not in nums`), matching the check-62/63 pattern — NOT the check-64 hardcoded-`63` pattern. This prevents minting a NEW hardcoded-literal trap for the NEXT count bump. **This is a hard instruction to the CG-14-prep-b / CG-14 coder.**

**Lock-step atomicity rule:** S1 + S2 + S4 MUST land in the SAME commit (CG-14). S3/S3b ride the same commit. If S1 bumps without all 5 S2 entries, or S2 lands without S4's literal edit, CI is RED. The coder PREFLIGHT for CG-14 runs the FULL battery (§4) which exercises check-64's test — catching an S4 miss BEFORE the patch is produced.

**EE-COUNT — the count-encoding surfaces @ `103cca8` (re-measured independently).**
- Cmd: `grep -nE "CHECK_REGISTRY_EXPECTED_COUNT|!= 63|== 63|FAIL_COUNT_NOT|_build_check_registry\(\)" scripts/validate-pack.py scripts/tests/test-validate-pack-check-62.sh scripts/tests/test-validate-pack-check-63.sh scripts/tests/test-validate-pack-check-64.sh scripts/tests/test-validate-pack-checks-58-59-60.sh; grep -n "62 entries" scripts/validate-pack.py; grep -cE '^\s+\([0-9]+, "check_|^\s+\(None, "check_' scripts/validate-pack.py`
- Output (verbatim, key): `validate-pack.py:496:CHECK_REGISTRY_EXPECTED_COUNT = 63`; registry tuple count `63`; `test-validate-pack-check-64.sh:74:if mod.CHECK_REGISTRY_EXPECTED_COUNT != 63:`, `:75: print('FAIL_COUNT_NOT_63 got', …)`, `:82: t_pass "… count invariant holds (== 63)"`; `test-validate-pack-check-62.sh:70:if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:`; `test-validate-pack-check-63.sh:62:` (same dynamic); `test-validate-pack-checks-58-59-60.sh:146:if actual != mod.CHECK_REGISTRY_EXPECTED_COUNT:`; `validate-pack.py:476:# … so the registry now holds 62 entries:` (STALE prose; constant + tuple-count + arithmetic all = 63).
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: exactly ONE test hardcodes the literal `63` (check-64 lines 74-75 + message 82); three tests use the dynamic form (no value edit needed); the comment prose carries a stale "62" while the constant, the registry tuple count, AND the ledger arithmetic all equal 63. The count-bump commit must edit S1 (constant → 68), append S2 (5 entries), edit S4 (check-64 literal `63`→`68` + `FAIL_COUNT_NOT_68` + message), and reconcile S3/S3b (comment → 68). New tests use the dynamic form.
- Conclusion: **SUPPORTED.**

---

## 3. THE FULL COMMIT SEQUENCE (membership, scope keyword, method, deps, verification)

14 commits + 1 push step. The bloat wave + pack gate wave are carried from V3 (summarized here; V3 §3-§7 carries the full bloat method, the OPTIONAL-FEATURES ceiling recipe, the snippet-stability contract, and the per-gate designs — all UNCHANGED except the count delta). The NEW commit is **CG-CLIENT**; the changed commit is **CG-14** (5 registrations, count 63→68). Each commit verifies with the FULL wired battery (§4) BEFORE its patch is produced.

### 3.1 Bloat wave — CB-01 .. CB-09 (carried verbatim from V3 §4)

| Commit | Content | Scope keyword | Deps | Verification (in addition to §4 full battery) |
|---|---|---|---|---|
| **CB-01** | pack-ops operating-doc bloat + FLAG-2a strip + 2 history-NARRATIVE strips + OPTIONAL ceiling re-derive (V3 §5 recipe) | `pack-only` | base `103cca8` | §3.2 OPTIONAL proof: Check-54 trio survives (`--only-check 54` exit 0); fenced blocks byte-identical; K13 snippet verbatim; record all 6 durable-doc `measured_reduced_lines` in IMPL-REPORT for the Gate-1a derivation |
| **CB-02** | pack RATIONALE bloat (surgical, per-`## slug`) | `pack-only` | base `103cca8` | C.3 clause-set-diff; K2-K5/K13 snippet-stable |
| **CB-03** | pack stream-meta bloat (`backlog/_rules.md`, `changelog/_rules.md`) | `pack-only` | base `103cca8` | K7 snippet-stable (`BD-167.md`, `^BD-\d+\.md$`) |
| **CB-04** | pack skills bloat (`.claude/skills/*/SKILL.md` ×11) | `pack-only` | base `103cca8` | A.5 contract: invariant-set diff EQUAL + example-removal log + retention spot-check + Check 1 frontmatter intact |
| **CB-05** | pack agent-defs bloat (`.claude/agents/pack-*.md` ×5) | `pack-only` | base `103cca8` | A.5 contract; Check 11 informational |
| **CB-06** | pack-root trinity bloat (`CLAUDE/AGENTS/GEMINI.md`) | `pack-only` | base `103cca8` | trinity-locked ×3 ONE commit; C.2 clause-preserving (`graph-first-context` 5024c); sanctioned Claude-only asymmetry preserved; K1/K2/K3/K12 snippet-stable |
| **CB-07** | project trinity bloat (`project-template/{CLAUDE,AGENTS,GEMINI}.md`) | `project-only` | base `103cca8`; ∥ CB-06 | trinity-locked ×3; C-SNIP-2(a) verbatim-keep mandatory (project-only); K12 snippet-stable |
| **CB-08** | project docs/pack + prompts + stream-meta bloat **+ D-1 PLATFORM-SKILLS catalog strip (WU-PLATSKILLS-D1)** | `project-only` | base `103cca8` | grep-zero for deferred-skill advertisement patterns; on-demand guardrail survives; K9/K10/K11 snippet-stable (C-SNIP-2(a)) |
| **CB-09** | project agent-defs (tri-family ×16 roles) + project skills (`project-template/skills/*/SKILL.md` ×37) | `project-only` | base `103cca8` | tri-family-locked per role; A.5 contract on skills; SPLITTABLE → CB-09a (agent-defs) / CB-09b (skills) |

All CB-01..CB-09 base on `103cca8` (gate inert). The no-double-BLOAT-touch invariant holds (V3 §4.4 EE-NDT): each bloat-bearing file maps to exactly one CB commit; PLATFORM-SKILLS appears only in CB-08. **ALL CB-01..CB-09 must land before CG-CLIENT** (which sizes against the bloat-reduced project-template) and before the gate wave (Gate-1 parameters measure the reduced tree).

### 3.2 CG-CLIENT (NEW) — ship the client doc gate (`project-only`)

**Membership (the lock-step surfaces — enumerate-encoding-surfaces, client-gate design §E.2):**

| Surface | Action | Why |
|---|---|---|
| `project-template/scripts/validate-docs.sh` | **NEW** (the gate, 4 axes, `--self-test`) | the deliverable |
| `project-template/scripts/.docs-gate-allowlist.txt` | **NEW** (the allowlist) | the gate's KEEP set, sized to the final clean project-template |
| `project-template/scripts/validate.sh` | **EDIT** — add an always-run, language-INDEPENDENT docs step + set `RAN_SOMETHING=1` (so a docs-only repo still validates rather than printing the "No project type detected" line at validate.sh:60-61) | wire the full-run path |
| `project-template/scripts/agent-post-edit-check.sh` | **EDIT** — split a `*.md)` arm out of the current `*.md|*.txt|*.json|*.yaml|*.yml|*.toml)` arm (line 82-83) so a `.md` edit runs `validate-docs.sh "$EDITED_FILE"` (single-file fast path); leave `*.txt|*.json|...` skipping | wire the per-edit path (today `.md` edits are un-gated) |
| `project-template/{CLAUDE,AGENTS,GEMINI}.md` Scripts table | **EDIT ×3** — add a `validate-docs.sh` row (insert near the `validate-*.sh` rows at CLAUDE:272-275 + AGENTS/GEMINI parallels), trinity-locked | document the new script; trinity parity |
| `scripts/init-project.sh` | **NO EDIT** — `stage_s5_scripts()` (init-project.sh:553) globs `project-template/scripts/*` (auto-ships) + `chmod +x scripts/*.sh` | EE-CSTAGE confirms auto-ship |
| install-map | **NO ROW** — scripts ship by glob, not install-map (unlike `docs/pack/*`) | EE-CSTAGE |
| `test-fixtures/manifest.txt` + fixtures | **REBUILD at push** — the v10/v11 install fixtures run `init-project.sh` which stages the new `validate-docs.sh` → fixture content SHAs change → manifest re-SHA via `scripts/manifest-sync.sh` at PUSH (not per-commit); CI `build.sh --verify` + Check 62 enforce | a new shipped script changes the fixture content hash (§3.4) |

- **Scope keyword:** `project-only` — every touched path is under `project-template/` (Check 36 verifies: the deny-set for `project-only` is everything outside `project-template/` + `supporting-docs/`; all 6 edited/new surfaces are project-template). **HAZARD:** do NOT touch any pack-side file in this commit (no `scripts/validate-pack.py`, no `pack-ops/`). The parity check is a SEPARATE pack-side surface that lands at CG-14-prep-b/CG-14 — keeping CG-CLIENT cleanly `project-only`.
- **Method (DC-1 RE-IMPLEMENT):** self-contained `validate-docs.sh` (bash + a small embedded `python3`/`awk` pass — `python3` is already a client dependency via `validate-python.sh`). NO shared lib (DC-1; the Check-47 sanctioned set is frozen at exactly `{scripts/lib/detect.sh, scripts/pack-help.sh}` — EE-SANCTION — and a shared doc-gate lib cannot satisfy "a pack op depends on it at runtime" without inverting the dependency direction). The 4 axes (DC-5: history / deferred / bloat-bullet-cap / dangling — NO Gate-4 meta-check client-side). Bloat axis = per-bullet char-cap ONLY (DC-4: no per-doc cap client-side). The project streams (`docs/project/{backlog,implementation-plan,changelog}/**` + the monolith mirrors + `docs/reference/**` + IMPL reports + `scripts/**`) are EXCLUDED as history-homes (client-gate design §B.2). `--self-test` flag (DC-6: a tiny synthetic PASS/FAIL leg, no separate shipped test file). Project-audience vocabulary: `BD-`→`TD-`, drop `v11.x` version tokens, project grammar (`TD-NNN`/`phase-N`/`x-`) not pack grammar; boundary grep-zero (no `pack-ops`/`validate-pack`/`maintenance-docs`/`BD-[0-9]`/`Pack Chat` in the shipped surface — EE-CBOUND contract, client-gate design §D.2).
- **Deps:** CB-07 + CB-08 + CB-09 (the bloat-reduced + history-clean project-template; the allowlist sizes to the REDUCED docs). NOT dependent on the pack gate wave.
- **Verification:** the `--self-test` leg passes; `validate-docs.sh` run with NO argument over the final project-template exits 0 (measure-then-bound: every axis CLEAN-or-allowlisted, allowlist sized EXACTLY to the measured KEEP set; any unclassified hit = a BLOCKER to the user, never auto-allowlisted); the per-edit fast path (`validate-docs.sh <one .md file>`) exits 0 on a clean file and non-0 on a synthetic dirty file; the boundary grep-zero (`grep -nE "pack-ops|validate-pack|maintenance-docs|BD-[0-9]|Pack Chat|PACK-AGENTS|PACK-CHAT" project-template/scripts/validate-docs.sh project-template/scripts/.docs-gate-allowlist.txt` → ZERO); trinity Scripts-table parity ×3; the FULL pack battery (§4) green — CRITICALLY confirm the new shipped files do NOT trip the PACK gates: `validate-docs.sh` is a SCRIPT (EXEMPT from the operating-doc scan per the BD-243 script-exempt ruling) and `.docs-gate-allowlist.txt` is a config (not an operating doc), so neither enters the pack Check-65/67/68 IN set, and neither is a pack-leak under Check 43 (project-side file, project vocabulary).

### 3.3 Pack gate wave — CG-14-prep-a, CG-14-prep-b, CG-14 (carried from V3 §6, count delta 63→68)

**CG-14-prep-a (`pack-only`) — scope infrastructure + Gate 4 + Check-65 repoint + R2 + GC records.**
- Author `_iter_operating_docs()` + `_CHECK_OPERATING_DOC_FAMILIES` + `_CHECK_OPERATING_DOC_EXEMPT` (the shared single-surface helper).
- Author **Check 69** (Gate 4) body `check_operating_doc_scope_completeness` + `_CHECK_OPERATING_DOC_OUT_OF_FAMILY` + NEW `test-validate-pack-check-69.sh` (DYNAMIC count form). AUTHORED-UNREGISTERED (not yet in `CHECK_REGISTRY`; count stays 63).
- Repoint Check 65 scope: `_CHECK_65_OPERATING_DOCS = tuple(_iter_operating_docs())` at module load (model B — preserves the test's monkeypatch seam at `test-validate-pack-check-65.sh`). Apply R2 (`incident`→`\bincident\b` at `_CHECK_65_FORBIDDEN_PATTERNS`) + edit `test-validate-pack-check-65.sh` (whole-word case: "incidents"/"coincidental" do NOT match, standalone "incident" does).
- Land the GC-3 (boundary-investigation project copy, `incident` whole-word KEEP) + GC-4 (`backlog/_rules.md` `**BD-167 — <Title>**` K7-extension) records in `pack-ops/.operating-doc-history-allowlist.txt`.
- **Deps:** the bloat wave (the Axis-1 history sweep runs over the bloat-reduced tree). **Verify:** `--only-check 65` exit 0 over the auto-discovered scope; Check 69 PASSes on the live tree (exercised via its test's synthetic + `--only-check 69` legs even while unregistered); full battery green (count still 63).

**CG-14-prep-b (`pack-only`) — content gates + the parity-check body + Gate-1 parameters + the dangling-ref fix.**
- Author **Check 66** (Gate 1b) body + `_CHECK_66_BULLET_CHAR_CAP` + its allowlist + `test-validate-pack-check-66.sh` (DYNAMIC).
- Author **Check 67** (Gate 2) body + `_CHECK_67_DEFERRED_PATTERNS` + `pack-ops/.operating-doc-deferred-feature-allowlist.txt` (sized to the 4 KEEP categories; D-1 strip at CB-08 already cleaned PLATFORM-SKILLS so NO catalog allowlist block; any unclassified hit = BLOCKER to user) + `_check_67_load_allowlist()` + `test-validate-pack-check-67.sh` (DYNAMIC).
- Author **Check 68** (Gate 3) body + `_CHECK_68_QUALIFIED_PATH_PATTERN` + `pack-ops/.dangling-ref-allowlist.txt` (sized to the measured KEEP set) + `test-validate-pack-check-68.sh` (DYNAMIC).
- Author **Check 70** (the parity check) body `check_client_doc_gate_parity` + `test-validate-pack-check-70.sh` (DYNAMIC). It asserts `project-template/scripts/validate-docs.sh` exists + is executable + carries the 4 axis-markers + is wired into `validate.sh` + `agent-post-edit-check.sh`. **Because CG-CLIENT already landed, this check passes against a real gate now** (the ordering resolution §1 — no lenient mode needed).
- **Fix the 1 genuine dangling ref** `feedback_review_fix_one_cycle.md` → `feedback_review_fix_cycle.md` at `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md:186` so Gate 3 is clean at activation.
- **Derive Gate-1 parameters from the measured reduced tree (D-4):** the 6 Check-44 FAIL ceilings (`ceil(measured_reduced × 1.15)` per doc, using CB-01's IMPL-REPORT counts + HELP-PACK measured/unchanged); the Check-66 bullet char-cap + over-cap allowlist. Flip Check 44 length branch advisory→FAIL (Gate 1a) + edit `test-validate-pack-check-44.sh` (add a FAIL-path case; the mock is value-agnostic — `advisory_ceiling` parameterized at line 95, so the ceiling values themselves need no test edit).
- AUTHORED-UNREGISTERED (all 5 new checks defined but not in `CHECK_REGISTRY`; count stays 63). **Verify:** each new check CLEAN against the live tree via `--only-check NN` (exercisable while unregistered); the parity check passes (CG-CLIENT's gate exists); the dangling-ref fix grep-zero; the 6 docs each UNDER their new FAIL ceiling; full battery green (count still 63).

**CG-14 (`pack-only`) — ACTIVATION + the atomic count bump 63→68.**
- Register all **5** new checks in `CHECK_REGISTRY`: `(66, "check_operating_doc_bullet_concision", …, W)`, `(67, "check_operating_doc_no_deferred_feature", …, W)`, `(68, "check_dangling_file_refs", …, W)`, `(69, "check_operating_doc_scope_completeness", …, W)`, `(70, "check_client_doc_gate_parity", …, W)` (S2).
- **Bump `CHECK_REGISTRY_EXPECTED_COUNT` 63 → 68** (S1); update the comment ledger with 5 `+1 net-new` lines (S3) + reconcile the stale prose "62"→68 (S3b); **edit `test-validate-pack-check-64.sh` literal `63`→`68` + `FAIL_COUNT_NOT_68` + pass-message `(== 68)` (S4)** — the load-bearing item.
- Confirm Check 65 enforces over the full auto-discovered IN set; Gate 1a FAIL ceilings + Check 66 cap live; Checks 67/68/69/70 enforce.
- **Deps:** CG-14-prep-a, CG-14-prep-b, AND CG-CLIENT (the parity check's target). **Verify:** the FULL wired battery green — Check 59 auto-asserts count==68; Check 60 auto-derives the shard partition incl. 66-70; `test-validate-pack-check-64.sh` passes with `68`; all 5 new per-check tests pass; the C-SNIP-4 Check-65 activation re-verification over the final state.

### 3.4 The final push (after CG-14 lands, CI-green locally)

1. Run `bash scripts/manifest-sync.sh` (push-time, tool-enforced). **Unlike V3, EXPECT exit 10** — CG-CLIENT added `project-template/scripts/validate-docs.sh` + `.docs-gate-allowlist.txt`, which the install fixtures stage via `init-project.sh stage_s5_scripts()`, changing the v10/v11 fixture content SHAs. Exit 10 ⇒ commit the regenerated `test-fixtures/manifest.txt` with user approval (a small `pack-only`/no-keyword bookkeeping commit, or fold into the push per the manifest-regen rule).
2. `git push` (the ~remaining BD-243 commits as the unit).
3. Watch the `Validate Pack` CI run (`gh run list` / `gh run watch`) in the background; surface the verdict when it lands (background-long-waits — never foreground-block).

---

## 4. PER-COMMIT VERIFICATION — the FULL wired battery (verify-full-ci-suite)

**The lesson from the recent CI failure: per-commit verification MUST run the FULL wired battery, not a subset.** The prior failure reached CI precisely because per-commit verification ran a partial check set and missed a count-encoding surface. Every commit (CB-01..CB-09, CG-CLIENT, CG-14-prep-a, CG-14-prep-b, CG-14) verifies with the FULL battery BEFORE its patch is produced:

1. **The full CI battery, in the same partition CI runs:** `python3 scripts/ci-shard-plan.py` (the shard planner CI uses) executed across ALL shards, plus `python3 scripts/validate-pack.py` (no-flag full run = every registered check), plus the relevant per-check tests (`scripts/tests/test-validate-pack-check-*.sh`) — INCLUDING the count-invariant tests (`test-validate-pack-check-62/63/64.sh` + `test-validate-pack-checks-58-59-60.sh`) on the gate commits. The coder PREFLIGHT line asserts the FULL battery PASS, not a validate-pack-only PASS.
2. **The method's substantive proof by surface (carried from V3 §8):** skills/agent-defs (CB-04/05/09 skills) → the A.5 contract; OPTIONAL-FEATURES (CB-01) → the §3.2 protected-content proof + the §5 ceiling recipe; all other docs → the C.3 clause-set-diff; D-1 PLATFORM-SKILLS (CB-08) → grep-zero for the advertisement patterns.
3. **CG-CLIENT-specific proof:** the `--self-test` leg; the no-arg full-run + the single-file fast-path both exit-correctly; the boundary grep-zero; trinity Scripts-table parity ×3; the new shipped files confirmed OUT of the pack gate IN sets (script-exempt + config) and clean under Check 43.
4. **Snippet-stability probe (C-SNIP-3)** for any bloat file carrying allowlisted lines (V3 §7 inventory).
5. **Trinity/tri-family parity (enumerate-encoding-surfaces):** CB-06/CB-07/CG-CLIENT byte-parallel across the 3 trinity files at each location, MODULO the sanctioned Claude-only asymmetries; CB-09 identical substance ×3 per role.

**Gate-wave + client-gate verification specifics:**
- **CG-CLIENT:** `validate-docs.sh --self-test` PASS; no-arg run over the final project-template exit 0; per-edit fast path correct; boundary grep-zero; trinity parity; full PACK battery green (count still 63 — pack gates not yet active; the new client files do not trip Check 65/43/47).
- **CG-14-prep-a:** Axis-1 history sweep clean over the full IN set with auto-discovered scope; Check 69 PASS on the live tree; R2 test green; GC-3/GC-4 records verified; full battery green (count still 63 — checks 66-70 unregistered).
- **CG-14-prep-b:** each new check (incl. the parity check) CLEAN against the live tree via `--only-check NN`; the parity check passes (CG-CLIENT's gate exists, is wired, carries 4 axes); Axis-2 deferred re-grep ZERO outside KEEP; dangling-ref fix grep-zero; Gate-1 parameters derived + Check 44 FAIL flip; each of the 6 docs UNDER its new FAIL ceiling; full battery green (count still 63).
- **CG-14:** the ATOMIC count bump (S1+S2+S3+S3b+S4) — full battery green with count==68; Check 59 asserts count==68; Check 60 shard partition includes 66-70; `test-validate-pack-check-64.sh` passes with `68`; all 5 new per-check tests pass; the Check-65 activation re-verification over the final state.

**ci-check-runtime-compounding (the 5 new pack checks + the client gate, run repeatedly):** confirmed cheap; NO expensive verification added.
- **Pack side (×~155 battery invocations):** Check 66 reads ~5 bullet files once (O(lines)); Check 67 one compiled-alternation scan per IN line (shares Check 65's read); Check 68 reuses Check 40's once-built basename index (near-free); Check 69 reads NO file bodies (path glob + set arithmetic); **Check 70 (parity) reads ONE file's structure (validate-docs.sh) + 2 wiring greps — a handful of file stats + greps, trivial.** R2 narrows an existing pattern (same compile-cost). NO whole-tree-scan-per-entry; NO subprocess storm.
- **Client side (runs at the client's pre-commit + per-`.md`-edit, NO shipped CI × 155 — DC-3):** per-edit path = 1 file × 4 regex passes (ms); full path = the ~106-file IN set, one `python3`/`awk` pass + a once-built basename index for the dangling axis, bounded to the IN set never the whole tree. Cheap by construction (client-gate design §C.4).

**Bounded review/fix cycle per commit:** ≤2 review/fix pairs + 1 final reviewer = 3 reviewer / 2 fix-coder spawns max per commit; if dirty after the final reviewer, STOP and spawn pack-architect (no fix-coder pass 3).

---

## 5. THE CLIENT-GATE COMMIT DETAIL (CG-CLIENT — full specification)

This consolidates the CG-CLIENT specification (the prompt's deliverable item 3). All facts re-measured @ `103cca8` (EE blocks §13).

### 5.1 `validate-docs.sh` — the 4 axes (DC-4/DC-5), project-audience

| Axis | Applies | Project-audience adaptation |
|---|---|---|
| **HISTORY** | YES | date/SHA/past-action/provenance regex over the INSTALLED operating docs; `BD-`→`TD-` re-vocabulary; the project STREAM trees + monolith mirrors + `docs/reference/**` + IMPL reports EXCLUDED as history-homes (a whole-tree exclude, not line-allowlist — EVERY stream entry legitimately carries dates, EE-CHIST in the client-gate design); the one IN-file date (`changelog/_format.md` `### YYYY-MM-DD` example) allowlisted |
| **DEFERRED** | YES | recall gate (compiled-alternation of deferral markers); DROP the pack-version tokens `v11.1\|v11.x` (pack release tokens, boundary-leaky client-side); KEEP = rule self-reference + the live TD-deferral workflow (the coder agent-defs' "Deferred items" + the `// TODO(scope): TD-TBD` vocabulary + "Deferral IS scope creep") + generic client-product advice |
| **BLOAT** | YES — **per-bullet char-cap ONLY (DC-4)** | a single char-cap constant over the bullet-bearing client surface (the trinity `## Project memory` bullets — the client mirror of the pack `## Pack memory`); an allowlist for irreducible enumerations (denied-git-verb list, deletion-rules `.nullify/.cascade/.deny/.noAction`); **NO per-doc cap** (DC-4 — the client cannot re-derive per-doc ceilings the way the pack coder does at CG-14-prep) |
| **DANGLING** | YES | existence over installed operating docs, resolved in the CLIENT tree (never any pack path); project-grammar placeholders allowlisted (`TD-NNN.md`/`phase-N.md`/`x-<name>`/`[PROJECT_NAME]`); a once-built basename index (mirror Check 40); anchor-phrase carve-out for self-flagged "archived"/"does not exist" refs |
| **meta (new-doc)** | **OMITTED (DC-5)** | the client surface is small + stable; a glob-based IN set auto-discovers new `x-` skills/agents WITHOUT a separate meta-check. The pack-only Check 69 covers the pack side |

### 5.2 The IN set + the history-home EXCLUDE (client-gate design §B)

- **IN (the gate scans, ~106 template baseline):** project trinity (3) + `docs/pack/*.md` operating docs (4, minus HELP-FRAGMENT) + prompts (10) + skills (37) + agent-defs (48 = 16×3 families) + stream-meta CONTRACTS (`docs/project/*/_rules.md` ×3 + `changelog/_format.md` ×1) + `x-` custom files (0 at template, grows client-side).
- **EXCLUDE (history-homes + non-operating):** `docs/project/{backlog,implementation-plan,changelog}/**` + the monolith mirrors (`BACKLOG.md`/`IMPLEMENTATION-PLAN.md`/`CHANGELOG.md`/`STATUS.md`) + `docs/reference/**` + IMPL reports + `_intro.md`/`_toc.md`/`HELP-FRAGMENT*.md` + `scripts/**`/`proto/**`/source. The stream-meta CONTRACTS are IN (operating instruction), the stream ENTRIES are OUT (history-homes).
- The exact count is the coder's measure-then-bound baseline at CG-CLIENT, globbed over the FINAL bloat-reduced project-template (post CB-07/08/09).

### 5.3 The allowlist (`.docs-gate-allowlist.txt`) — measure-then-bound

A client-self-contained `(doc, pattern, snippet, reason)` record file (same shape the pack uses; `x-`-extensible by the client). Shipped baseline sized to the project-audience KEEPs: rule self-reference; the live TD-deferral workflow; generic client-product advice; the `changelog/_format.md` format-example date; dangling project-grammar placeholders; irreducible bloat enumerations. The history-homes are handled by IN-set EXCLUSION (whole-tree), NOT line-allowlist. Sized EXACTLY at CG-CLIENT to the measured KEEP set on the final project-template; any unclassified hit = a BLOCKER surfaced to the user (no widen-to-admit).

### 5.4 The wiring + `--self-test`

- **`validate.sh`:** add an always-run, language-INDEPENDENT step (`"$SCRIPT_DIR/validate-docs.sh" || EXIT_CODE=1`) that sets `RAN_SOMETHING=1`, so a docs-only repo validates rather than printing "No project type detected" (validate.sh:60-61).
- **`agent-post-edit-check.sh`:** split a `*.md)` arm out of the current `*.md|*.txt|*.json|*.yaml|*.yml|*.toml)` arm (line 82-83); the `.md` arm runs `validate-docs.sh "$EDITED_FILE"` (single-file fast path) and sets `status`; the `.txt|.json|.yaml|.yml|.toml` arm keeps skipping.
- **`--self-test` (DC-6):** `validate-docs.sh --self-test` runs a tiny embedded synthetic PASS + injected-FAIL leg (a known-clean doc passes; a known-dirty doc fails) and exits accordingly — NO separate shipped test file (the client has no shipped script-test harness; `--self-test` is the in-script verification the developer can run). No naming conflict (EE-SELFTEST: no existing `--self-test` in any shipped script).
- **`validate-docs.sh <file>` arg contract:** with one argument → gate ONLY that file (the per-edit fast path); with no argument → scan the full IN set (the validate.sh full-run path).

### 5.5 Fixture / manifest-rebuild coupling (the one non-trivial coupling)

A new `project-template/scripts/validate-docs.sh` + `.docs-gate-allowlist.txt` changes what `stage_s5_scripts()` stages → the v10/v11 install fixtures gain the new files → their content SHAs change → `test-fixtures/manifest.txt` must re-SHA. Per `regenerate-manifest-v11-surface`, this is done by `scripts/manifest-sync.sh` at PUSH (not per-commit), and CI `build.sh --verify` + Check 62 enforce. **CG-CLIENT is flagged a "fixture-input-changing" commit** → the push-time manifest-sync EXPECTS the regeneration (exit 10 → commit the regenerated manifest with user approval). Install-map: NO row — scripts auto-ship via the `stage_s5_scripts()` glob (EE-CSTAGE), unlike `docs/pack/*` which use explicit install-map rows.

---

## 6. THE LOCK-STEP / SYNC CONTRACTS (the load-bearing repeat-failure-prevention pairs)

Three lock-step pairs MUST each move together in their commit. Asymmetric coverage = an audit gap (enumerate-encoding-surfaces).

### 6.1 The count-bump lock-step (CG-14) — the highest-attention item
S1 (constant → 68) + S2 (5 registry entries) + S4 (`test-validate-pack-check-64.sh` literal `63`→`68`) land in ONE commit; S3/S3b (comment ledger + stale prose) ride it. Full enumeration §2. The registration-deferral mechanism (CG-14-prep-a/-b author the 5 bodies UNREGISTERED; CG-14 registers all 5 + bumps once) concentrates the fragile bump into ONE reviewed commit with ONE chance to get S1+S2+S4 right — verified by the full battery (which exercises check-64's test) BEFORE the patch.

### 6.2 The parity-check ↔ validate-docs.sh sync contract (CG-CLIENT ↔ CG-14)
The pack-side `check_client_doc_gate_parity` (Check 70) and the shipped `project-template/scripts/validate-docs.sh` are a lock-step pair across two surfaces (pack ↔ project). The contract:
- **Existence ordering:** `validate-docs.sh` MUST exist before the parity check activates (§1 — CG-CLIENT lands first, no lenient mode).
- **Axis parity:** the parity check asserts `validate-docs.sh` declares all 4 client axes (structural grep for `# AXIS: history|deferred|bloat|dangling` markers). So CG-CLIENT MUST emit those axis-marker comments, and a future pack version that adds/removes a client axis MUST update BOTH the gate and the parity check's expected-axis set in the same change.
- **Wiring parity:** the parity check asserts `validate-docs.sh` is wired into `validate.sh` + `agent-post-edit-check.sh`. So CG-CLIENT's wiring edits and the parity check's wiring assertions are the same contract.
- **Drift mitigation (DC-1 RE-IMPLEMENT cost):** the two gates re-implement the same logic; drift is mitigated by (a) the shared RULE-TEXT anchor (both enforce the ONE trinity rule, SSOT) + (b) this parity check (STRUCTURAL parity — presence/wiring/axis-coverage — NOT behavioral parity, which would be a maintenance trap).

### 6.3 The OPTIONAL-FEATURES ceiling lock-step (CB-01, carried from V3 §5)
IF CB-01's reduce-then-re-derive changes the OPTIONAL-FEATURES ceiling: the `("pack-ops/OPTIONAL-FEATURES.md", 271)` tuple in `_CHECK_44_DURABLE_DOCS` (~validate-pack.py:7763) + the comment block (~7752-7755) move together; the Check-44 test needs NO value edit (value-agnostic mock — EE-CHECK44TEST). The CB-01 coder records all 6 durable docs' `measured_reduced_lines` in its IMPL-REPORT so the CG-14-prep-b coder derives the 6 Gate-1a FAIL ceilings without re-measuring a drifted tree.

### 6.4 The snippet-stability contract (C-SNIP, carried from V3 §7)
Check 65 clears an allowlisted line ONLY when its `snippet:` is a SUBSTRING of that line. A bloat reword on a doc carrying allowlisted lines MUST keep every snippet matchable (C-SNIP-2(a) verbatim-keep is MANDATORY for the `project-only` commits CB-07/CB-08/CG-CLIENT — a snippet co-update in the `pack-ops/` allowlist would break the `project-only` Check-36 claim). The new gates' allowlists (`.operating-doc-deferred-feature-allowlist.txt`, `.dangling-ref-allowlist.txt`, the Check-66 bullet allowlist, and the CLIENT `.docs-gate-allowlist.txt`) are each sized EXACTLY to the measured KEEP set; no category widened to admit an unclassified hit.

---

## 7. CONSOLIDATED DEPENDENCY-ORDERED SEQUENCE (the scheduler's map)

```
[BLOAT WAVE — all base on 103cca8; gate inert]
  CB-01 (pack-only)    pack-ops bloat + FLAG-2a + 2 hist-narr + OPTIONAL ceiling re-derive  ┐
  CB-02 (pack-only)    RATIONALE                                                            │ parallel
  CB-03 (pack-only)    pack stream-meta                                                     │ across
  CB-04 (pack-only)    pack skills (S-test)                                                 │ distinct
  CB-05 (pack-only)    pack agents (S-test)                                                 ┘ files
  CB-06 (pack-only)    pack trinity (×3)        ┐ ∥ each other (disjoint sets)
  CB-07 (project-only) project trinity (×3)     ┘
  CB-08 (project-only) project docs/pack + prompts + stream-meta + D-1 PLATFORM-SKILLS strip ┐ parallel
  CB-09 (project-only) project agent-defs (tri-family) + project skills (S-test)             ┘ [split a/b opt]
        │  (ALL CB-01..CB-09 land before CG-CLIENT and before the gate wave)
        ▼
[CLIENT GATE — bases on the bloat-reduced project-template; ships BEFORE the pack registration]
  CG-CLIENT (project-only)  ship validate-docs.sh (4 axes; bullet-cap-only bloat; --self-test)
                            + .docs-gate-allowlist.txt + validate.sh wiring
                            + agent-post-edit-check.sh *.md branch + trinity Scripts row ×3
        │  (validate-docs.sh now EXISTS — the parity check has a real target)
        ▼
[PACK GATE WAVE — bases on the bloat-reduced tree; the parity check polices the shipped gate]
  CG-14-prep-a (pack-only)  _iter_operating_docs() + EXEMPT + Check 69 body + Check-65 repoint
                            + R2 incident-tighten + GC-3/GC-4 records   [count 63; checks unregistered]
        │
  CG-14-prep-b (pack-only)  Checks 66/67/68 bodies + the PARITY-CHECK body (check_client_doc_gate_parity)
                            + 3 pack allowlists + Gate-1 params from reduced tree + Check-44 advisory→FAIL
                            + dangling-ref fix   [count 63; checks unregistered; parity passes vs CG-CLIENT]
        │
  CG-14 (pack-only)         ATOMIC: register 5 checks (66/67/68/69/70) + count 63→68 (S1+S2+S3+S3b+S4)
                            + activate Check 65 over full IN set + full battery green
        │
        ▼
[FINAL PUSH]  manifest-sync (EXPECT exit 10 — CG-CLIENT changed fixture inputs → commit regenerated
              manifest w/ user approval) → git push → watch Validate Pack CI (background)
```

**Parallelization map (rule-10):** the bloat wave's parallel waves are unchanged from V3 §4.4. CG-CLIENT is a serial bottleneck (it depends on the full bloat wave + is a single project-side commit; it has no same-file conflict with the pack gate wave but MUST precede CG-14 for the parity-check existence dependency). The pack gate wave is strictly serial (CG-14-prep-a → CG-14-prep-b → CG-14, all touch `scripts/validate-pack.py`). CG-CLIENT ∥ nothing in the gate wave by file (disjoint surfaces: `project-template/scripts/` vs `scripts/validate-pack.py`) but is ORDERED before CG-14 by the existence dependency — Pack Chat schedules `CB-09 → CG-CLIENT → CG-14-prep-a` serially.

**BD-243 scope coverage (deferral-is-scope-creep — all of it LANDS in BD-243):** bloat reduction (CB-01..CB-09) ✓; the shipped CLIENT doc gate (CG-CLIENT, DC-1..DC-6) ✓; the 5 durable PACK gates (Checks 66/67/68/69 + the parity check 70 + Gate-1a hardening + R2) ✓; surfaced fix 1 = D-1 PLATFORM-SKILLS catalog strip (CB-08) ✓; surfaced fix 2 = the `feedback_review_fix_one_cycle.md` dangling ref (CG-14-prep-b) ✓; the carried cleanup (FLAG-2a, 2 history-NARRATIVE strips, GC-1..GC-4) ✓. **Nothing deferred** (no v11.1+ punt — no-deferral-without-user-direction holds).

---

## 8. OPEN RISKS / UNKNOWNS

- **R-1 (count-bump lock-step — the repeat-CI-failure risk, now 5 checks).** S1+S2+S4 must land atomically at CG-14; check-64's HARDCODED `63`→`68` (lines 74-75 + message 82) is the load-bearing miss-risk; S2 is now FIVE entries (one more chance to drop one). MITIGATION: the registration-deferral mechanism concentrates the bump into ONE commit; the full-battery PREFLIGHT exercises check-64's test BEFORE the patch; the 5 new tests use the DYNAMIC form. RESIDUAL: low IF §2 is followed; this is the single highest-attention item for the CG-14 coder + reviewer.
- **R-2 (parity-check ↔ client-gate ordering).** RESOLVED by §1 option (a): CG-CLIENT ships before CG-14, so the parity check has a real target at activation — no lenient mode, no skip-window. RESIDUAL: the parity check's axis-marker grep must match the EXACT `# AXIS:` comment strings the CG-CLIENT coder emits — a lock-step pair across two commits authored by two coders. MITIGATION: the V4 spec fixes the marker vocabulary (`# AXIS: history|deferred|bloat|dangling`) so both coders use the same literals; CG-14-prep-b's parity-check verification (`--only-check 70` against the already-landed CG-CLIENT gate) catches a mismatch before CG-14.
- **R-3 (deferred-allowlist sizing — BLOCKER discipline).** The Gate-2 pack allowlist + the CLIENT `.docs-gate-allowlist.txt` size EXACTLY to the measured KEEP sets. Any unclassified hit = a BLOCKER surfaced to the user, NEVER auto-allowlisted. MITIGATION: the D-1 strip removes the largest unclassified cluster (PLATFORM-SKILLS) at CB-08, shrinking the residue both the pack gate-wave coder and the CG-CLIENT coder must classify.
- **R-4 (Gate 3 + the out-of-repo memory-file family).** The dangling ref `feedback_review_fix_one_cycle.md` points at a curated-memory file OUTSIDE the repo tree. The FIX is to correct the name to `feedback_review_fix_cycle.md` at CG-14-prep-b. Gate 3's existence check must not then FAIL on the corrected name (which also has no in-repo target). MITIGATION: the CG-14-prep-b coder decides Gate 3's resolution rule for the memory-file family (allowlist the family pattern with a reason, OR the corrected ref sits in prose the anchor-phrase mechanism clears). SURFACE to the user if the resolution requires a judgment.
- **R-5 (CG-CLIENT scope-keyword cleanliness).** CG-CLIENT is `project-only`; every touched path MUST be under `project-template/`. The parity check is a SEPARATE pack-side surface (CG-14-prep-b/CG-14) — do NOT let it leak into CG-CLIENT or the `project-only` Check-36 claim fails. RESIDUAL: low — the membership table §3.2 is explicit.
- **R-6 (fixture/manifest churn at push).** CG-CLIENT changes fixture INPUTS → manifest-sync EXPECTS exit 10 at push (unlike V3's expected exit 0). MITIGATION: §3.4 + §5.5 flag CG-CLIENT as fixture-input-changing; the regenerated manifest commits with user approval. RESIDUAL: low — the coupling is known and tool-enforced.
- **R-7 (skill invariant-set-diff judgment, CB-04/05/09b — carried).** The A.5 invariant-set diff requires consistent enumeration; medium risk on the largest technical skills; an over-zealous coder is caught by the invariant-set diff (BLOCKER on any asymmetric loss).
- **R-8 (Gate 1 parameter timing, D-4 — carried).** Gate 1 ceilings/cap derive at CG-14-prep-b from the reduced tree; they CANNOT be finalized before the bloat wave lands. Confirmed dependency; the plan orders it correctly.
- **R-9 (stale graph).** The graph is STALE for BD-243-era surfaces (the client-validator surface returned only rule-rationale + tracker-fixture nodes — EE-GRAPH). Discovery used the graph then fell to grep/`wc -l`/Read (G2). ALL sizing + the count-bump enumeration are grep/`wc -l`-authoritative. No residual — the gate is the file read, not the graph.

---

## 9. WHAT V4 CHANGES vs V3 (the diff, for the user's review)

| Aspect | V3 | V4 | Driver |
|---|---|---|---|
| Total commits | 13 | 14 (+ CG-CLIENT) | the shipped client gate |
| Count bump | 63 → **67** (4 checks) | 63 → **68** (5 checks) | DC-2 parity check = 5th |
| New pack checks | 66/67/68/69 | 66/67/68/69 + **70 (parity)** | DC-2 |
| Client gate | not in V3 | NEW CG-CLIENT (project-only) | user-added scope |
| Client gate position | (architect proposed CG-15 AFTER CG-14) | **CG-CLIENT BEFORE CG-14-prep-a** | §1 ordering resolution (option a) |
| Client bloat axis | n/a | per-bullet char-cap ONLY | DC-4 |
| Client meta-check | n/a | OMITTED (4 client axes) | DC-5 |
| Client test | n/a | `--self-test` flag (no separate file) | DC-6 |
| Client CI | n/a | NO shipped CI workflow | DC-3 |
| Code sharing | n/a | RE-IMPLEMENT (no shared lib) | DC-1 |
| check-64 test literal | `63`→`67` | `63`→**`68`** | DC-2 |
| manifest-sync at push | expect exit 0 | **expect exit 10** (CG-CLIENT changed fixture inputs) | the new shipped script |

Everything else (the bloat method §3.1, the OPTIONAL-FEATURES ceiling recipe, the per-gate pack designs, the snippet-stability contract, D-1..D-4 + R2) is carried UNCHANGED from V3.

---

## 10. EMPIRICAL-EVIDENCE BLOCK (consolidated — my own runtime measurements @ `103cca8`)

All measurements @ HEAD `103cca8` (`103cca8e51feef9c80e4e76be17bd0dd274d3a6b`), branch `v11-dev`, 2026-06-22, repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, clean tree (untracked plan docs only). Graph queried FIRST for discovery (`graphify query "what consumes validate.sh and agent-post-edit-check.sh; client operating-doc enforcement surfaces" --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 2000`) → returned only PACK-MEMORY-RATIONALE rule-rationale + tracker-fixture nodes (STALE for the client-validator surface) → G2 fallback to grep/`wc -l`/Read IMMEDIATELY. Every exact-state claim is grep/Read-authoritative.

- **EE-BASE** — HEAD `103cca8`; clean tree; `CHECK_REGISTRY_EXPECTED_COUNT = 63` (validate-pack.py:496); `_CHECK_65_OPERATING_DOCS = ()` (validate-pack.py:7926); registry tuple count = 63; `python3 scripts/validate-pack.py` = "PASSED — all checks clean" (exit 0). Cmd: `git rev-parse HEAD; git status --short; grep -n "CHECK_REGISTRY_EXPECTED_COUNT = " scripts/validate-pack.py; grep -n "_CHECK_65_OPERATING_DOCS = " scripts/validate-pack.py; grep -cE '^\s+\([0-9]+, "check_|^\s+\(None, "check_' scripts/validate-pack.py; python3 scripts/validate-pack.py | tail -2`. SUPPORTED.
- **EE-COUNT** (§2) — ONLY `test-validate-pack-check-64.sh:74-75` hardcodes the literal `63` (+ message line 82); `test-validate-pack-check-62.sh:70` / `63.sh:62` / `checks-58-59-60.sh:146` use the DYNAMIC `len(_build_check_registry()) != EXPECTED_COUNT` form (no edit); the comment prose (validate-pack.py:476) says a STALE "62 entries" while the constant + tuple-count + ledger arithmetic all = 63. SUPPORTED.
- **EE-LEDGER** — the EXPECTED_COUNT comment ledger (validate-pack.py:475-495) carries per-BD `+1 net-new` lines through Check 65 + the "number ≠ count" CAUTION ("a new check's NUMBER is the next free integer (65 for BD-243) but this constant is the registry ENTRY COUNT — bump it +1 per net-new entry, NOT to the new number"). Cmd: `sed -n '464,496p' scripts/validate-pack.py`. SUPPORTED.
- **EE-REGTAIL** — the registry tail entries 60-65 follow `(NN, "check_name", check_name, W)`; Check 65 = `check_operating_doc_no_history` at line 10350. The 5 new entries append after it. Cmd: `grep -nE '^\s+\(6[0-9], "check_' scripts/validate-pack.py`. SUPPORTED.
- **EE-CSTAGE** — `stage_s5_scripts()` (init-project.sh:553) globs `for f in "$pack_scripts"/*` then `cp "$f" "$TARGET/scripts/"` + `chmod +x "$TARGET/scripts"/*.sh` — a new `validate-docs.sh` auto-ships, no install-map row; `test-fixtures/build.sh` runs `PACK=$PACK_ROOT bash .../init-project.sh` so the new file flows into the v10/v11 install fixtures; `grep -c project-template test-fixtures/manifest.txt` = 0 (manifest keys on fixture SHAs, not template paths). Cmd: `sed -n '550,570p' scripts/init-project.sh; grep -n "init-project" test-fixtures/build.sh; grep -c project-template test-fixtures/manifest.txt`. SUPPORTED.
- **EE-SANCTION** — `_SANCTIONED_PACK_SIDE_SHIPPED = ("scripts/lib/detect.sh", "scripts/pack-help.sh")` (validate-pack.py:4308) — exactly 2 entries; Check 47 enforces install-map↔constant set-equality. A shared doc-gate lib cannot join without architect+user sign-off AND satisfying "a pack op depends on it at runtime" — which validate-docs.sh's logic cannot (validate-pack.py has its own checks; depending on a client lib inverts the dependency direction). Confirms DC-1 RE-IMPLEMENT. Cmd: `sed -n '4308,4312p' scripts/validate-pack.py`. SUPPORTED.
- **EE-CWIRE** — `project-template/scripts/validate.sh` runs ONLY language-matched validators (`has_swift`/`has_python`/`has_proto` at lines 35-37; `RAN_SOMETHING` gate; "No project type detected" at line 60-61) — no language-independent step today; `agent-post-edit-check.sh` SKIPS `.md` in the combined `*.md|*.txt|*.json|*.yaml|*.yml|*.toml)` arm (line 82-83: "non-code file — skipping build/lint"); the trinity Scripts table carries `validate-*.sh` rows (CLAUDE.md:272-275 + AGENTS/GEMINI parallels). Cmd: `grep -n "has_swift\|RAN_SOMETHING\|No project type" project-template/scripts/validate.sh; grep -n "skipping build/lint\|EDITED_FILE" project-template/scripts/agent-post-edit-check.sh; grep -n "validate-proto.sh\|validate.sh" project-template/CLAUDE.md`. SUPPORTED.
- **EE-CABSENT** — `project-template/scripts/validate-docs.sh` and `.docs-gate-allowlist.txt` do NOT exist; `find . -name "validate-docs.sh" -not -path "./.git/*"` returns ZERO (filename-unique; prose refs are unambiguous). Cmd: `ls project-template/scripts/validate-docs.sh; find . -name "validate-docs.sh" -not -path "./.git/*"`. SUPPORTED.
- **EE-CHECK44TEST** — `test-validate-pack-check-44.sh` is value-agnostic (parameterized `advisory_ceiling: int = 10000` at line 95; comment "T4 over-ceiling doc emits ADVISORY but does NOT fail (soft)" at line 23) — the Gate-1a advisory→FAIL flip needs a FAIL-path case ADDED but the ceiling VALUES need no test edit. Cmd: `grep -n "advisory_ceiling\|ADVISORY\|FAIL" scripts/tests/test-validate-pack-check-44.sh`. SUPPORTED.
- **EE-SELFTEST** — no existing `--self-test`/`selftest` in any `project-template/scripts/` file (DC-6 is a new, non-conflicting convention). Cmd: `grep -rn "self-test\|--self-test\|selftest" project-template/scripts/`. SUPPORTED.
- **EE-WIRINGLIST** — `scripts/ci-test-wiring-allowlist.txt` is an EXCLUDE list (the ONE manual-only script: `tracker-bd204-lossless-roundtrip-test.sh`), NOT an include list; new per-check tests are auto-wired by the disk-glob shape (`scripts/tests/*.sh`) in `ci-shard-plan.py parse_wired_tests()` — so the 5 new `test-validate-pack-check-NN.sh` files need NO allowlist edit, only the glob-matching name. Cmd: `tail -20 scripts/ci-test-wiring-allowlist.txt; grep -nE "check-6[6-9]|check-7[0-9]" scripts/ci-test-wiring-allowlist.txt`. SUPPORTED.
- **EE-ORDER** (§1.4) — CG-CLIENT's baseline is the project-template (rule at CLAUDE:242/AGENTS:226/GEMINI:239), cleaned by the bloat wave (project-only CB-07/08/09), NOT the pack gate wave (which touches `scripts/validate-pack.py`, pack-side); so CG-CLIENT can ship after CB-09 and before CG-14 — option (a) is safe. SUPPORTED.
- **EE-GRAPH** — the graph returned only PACK-MEMORY-RATIONALE rule-rationale + `scripts/tests/fixtures/tracker-*/IMPLEMENTATION-PLAN.md` nodes for the client-validator query (STALE for the BD-243 client surface) → G2 fallback to grep/Read. Cmd: the graphify query above. SUPPORTED (graph stale; grep authoritative).

---

## 11. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Only read-only verbs ran: `git rev-parse HEAD` / `git branch --show-current` / `git status --short` (snapshot), `wc -l`, `grep`/`grep -rn`, `sed`, `ls`, `find`, `python3 scripts/validate-pack.py` (read-only validation), `graphify query` (read-only), Read tool. Sole write = this plan doc via `cat >>`/`cat >` to the caller-specified `/tmp/pack-handoff-bd243-plan/PLAN-BD-243-FINAL-V4.md`. No repo-file edit; no patch; no `git add`/`commit`/`apply`/state-changing verb. | COMPLIANT |
| **reconciliation-instance-independence** | FRESH planner; did NOT author V3, the client-gate design, the durable-gates design, or any prior BD-243 artifact. Reached my own conclusions: the ORDERING RESOLUTION (option a, ship CG-CLIENT before CG-14) with my own 3-reason rejection of the lenient option (§1.2-1.3); independently re-derived the 63→68 count enumeration for 5 checks (§2) and re-measured the check-64 hardcoded literal at lines 74-75/82 (EE-COUNT) + the stale "62" prose (EE-COUNT/EE-LEDGER); independently verified the staging glob (EE-CSTAGE), the frozen sanctioned set (EE-SANCTION), the wiring points (EE-CWIRE), the ci-wiring-allowlist semantics (EE-WIRINGLIST). Folded V3 + the architect designs + DC-1..DC-6 without relitigating the approved bloat method / pack gate designs. | COMPLIANT |
| **planner-output-user-review** | Marked PLANNER-READY (header + §0); NOT auto-approved into a coder spawn; §0 one-line decision-ready answers + §9 V3→V4 diff table for the user; the open items (R-3 unclassified BLOCKERs, R-4 memory-file resolution) flagged for the user. The planner-to-coder gate is the user's last cheap redirect window. | COMPLIANT |
| **enumerate-encoding-surfaces** | §2 enumerates EVERY count-encoding surface for the 63→**68** bump (S1 constant, S2 FIVE registry entries, S3 comment ledger, S3b stale prose, S4 hardcoded-literal test at check-64:74-75/82, S5 Check 59, S6 Check 60, S7 ci-shard-plan glob) with file:line + required value + miss=CI-failure flag; identifies the load-bearing trap (check-64 hardcoded `63`→`68`) + the dynamic tests needing no edit. §6 enumerates the THREE lock-step pairs (count-bump; parity-check↔validate-docs.sh; OPTIONAL ceiling; snippet-stability). §3.2/§5 enumerate the CG-CLIENT coupled surfaces (gate + allowlist + validate.sh + agent-post-edit + trinity ×3 + no-install-map-row + fixture/manifest rebuild). | COMPLIANT |
| **dependency-direction-placement** | `validate-docs.sh` is a project-side deliverable (`project-template/scripts/`, RE-IMPLEMENT per DC-1, EE-CSTAGE auto-ship); the parity check is pack-side (validate-pack.py — it READS the client deliverable for verification, the legitimate pack→client read direction, never the reverse); the frozen `_SANCTIONED_PACK_SIDE_SHIPPED = {detect.sh, pack-help.sh}` quoted (EE-SANCTION), not grown; no project-side runtime dependency of a pack op (validate-pack.py does not depend on validate-docs.sh). | COMPLIANT |
| **verify-full-ci-suite** | §4 specifies the FULL wired battery (`ci-shard-plan.py` all shards + `validate-pack.py` no-flag + the per-check tests incl. the count-invariant tests) per commit BEFORE the patch; the coder PREFLIGHT asserts full-battery PASS; the CG-14 verification explicitly exercises `test-validate-pack-check-64.sh` (the S4 surface) so an S4 miss is caught pre-patch; CG-CLIENT verification runs the full PACK battery + the client gate's own `--self-test`. | COMPLIANT |
| **empirical-evidence-blocks** | §10 EE-BASE/COUNT/LEDGER/REGTAIL/CSTAGE/SANCTION/CWIRE/CABSENT/CHECK44TEST/SELFTEST/WIRINGLIST/ORDER/GRAPH + §1.4 EE-ORDER + §2 EE-COUNT: each state-claim has command + verbatim output (counts/paths/line-numbers/quotes) + HEAD `103cca8` + 2026-06-22 + interpretation + SUPPORTED. The count-bump enumeration + the staging/manifest coupling are grep/`wc -l`-authoritative. | COMPLIANT |
| **ci-check-runtime-compounding** | §4 confirms the 5 new pack checks run cheap ×~155 invocations (Check 66 reads ~5 files once; 67 one scan/line sharing Check 65's read; 68 reuses Check 40's once-built index; 69 reads no bodies; 70-parity reads ONE file's structure + 2 wiring greps — trivial); the client gate runs at client pre-commit + per-`.md`-edit (NO shipped CI × 155 per DC-3) — per-edit 1 file ms, full path bounded to the ~106-file IN set, once-built basename index. NO whole-tree scan; NO subprocess storm; NO expensive verification added. | COMPLIANT |
| **deferral-is-scope-creep** | §7 BD-243 scope coverage: bloat (CB-01..CB-09) + the client gate (CG-CLIENT, DC-1..DC-6) + the 5 pack gates (66/67/68/69/70 + Gate-1a + R2) + both surfaced fixes (D-1 at CB-08; dangling ref at CG-14-prep-b) + the carried cleanup ALL planned to LAND in BD-243. Nothing punted to v11.1+ (no-deferral-without-user-direction holds). | COMPLIANT |
| **graph-first-context** | Discovery used graph-first via the INJECTED absolute path (`--graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 2000`, verbatim, not recomputed from my own toplevel); returned STALE rule-rationale + tracker-fixture nodes for the client-validator surface (EE-GRAPH) → G2 fallback to grep/`wc -l`/Read IMMEDIATELY; the count-bump enumeration + all sizing are grep-authoritative; did not block on the graph. | COMPLIANT |
| **rules-applied-verification-block** | This table — every rule in the prompt's Rules-in-force block has measured/quoted evidence + a terminal COMPLIANT conclusion (no empty evidence; no AMBIGUOUS). | COMPLIANT |

**END — PLAN-BD-243-FINAL-V4.md**
