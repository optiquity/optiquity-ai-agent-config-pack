# PACK-REVIEW — BD-197 commit C8a (project OPTIONAL-FEATURES isolation section + documented-optional `permissions.deny` recipe; DATA half; project-only)

## VERDICT: APPROVE

C8a faithfully lands the client-native OPTIONAL-FEATURES isolation section + the documented-optional `permissions.deny` recipe per design §9/§18.2/§3/§7 and plan §B C8a — client-native (not a byte-copy), ZERO pack-self refs (the no-BD-NNN boundary call is correct), all three PREFLIGHT tokens present, manifest regenerated/kept, full CI green, scope clean (no Guard-A′/C8b leak).

**Reviewer:** fresh pack-reviewer (read-only on codebase; sole write = this report).
**Regime:** IN-PLACE (cwd = main v11-dev tree; branch `v11-dev`; no `/tmp` handoff named).
**HEAD:** `13bb32eee5b36529dd36b7c3eaaf2e4a81f2d10d` (pre-flight + all measurements).
**Date:** 2026-06-14.
**Independence:** every command below re-run by me; the IMPL-REPORT was read but NOT trusted as evidence.

---

## Read attestation (up front)

Read in full before reviewing:
- Design `ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` — §3 (corrected two-mechanisms model), §7 (launcher feasibility / NEW-FORK-1 gate-then-probe-then-degrade), §8 (degradation matrix incl. `fresh`=origin/main + silent-fall-to-MAIN), §9 (OPTIONAL-FEATURES both surfaces separately authored), §10 (D6/D-NEW), §18.1/§18.2/§18.3 (in-session backstop F1–F5; the `permissions.deny` recipe; J4=NO new shipped file).
- Plan `PLAN-BD-197-WORKTREE-ISOLATION.md` — §B C8a (lines 152–155), C8b (157–161, confirmed NOT in C8a scope), C5 (116, pack reference), §C dependency graph.
- Pack `pack-ops/OPTIONAL-FEATURES.md` — the C5 pack isolation section (byte-copy comparison baseline).
- `git diff` of `project-template/docs/pack/OPTIONAL-FEATURES.md` + the file itself (full text).
- `maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-C8a.md` (coder claims, incl. the no-BD-NNN boundary call).
- Cross-ref targets: `project-template/agent-run.sh` (`--worktree` / `run_in_worktree`, C7a) + `project-template/docs/pack/PM-CHAT.md` ("In-session agent spawning", C7a).
- `CLAUDE.md` § "## Pack memory" (full).
- Skills: `review`, `architecture-review`, `commit-discipline`.

---

## Explicit verdicts on the three required dimensions

### (a) Client-native, NOT a byte-copy — VERDICT: PASS

The pack and client isolation sections are materially distinct, not a token-swapped copy.

```
$ awk '/^## Claude Code — Isolated parallel agents/{f=1} f{print} f&&/^## Codex CLI/{exit}' pack-ops/OPTIONAL-FEATURES.md > /tmp/pack-iso.txt
$ awk '...' project-template/docs/pack/OPTIONAL-FEATURES.md > /tmp/client-iso.txt
$ wc -l   pack: 159   client: 179
$ diff /tmp/pack-iso.txt /tmp/client-iso.txt → DIFFERENT (214 differing lines)
```

The diff shows substantive client-native authoring, not mechanical replacement:
- Orchestrator: pack "Pack Chat" → client "PM chat" (`grep -c "Pack Chat"` client = **0**; `grep -ci "PM chat"` client = **14**).
- Contract name: pack `agents-never-commit` contract → client "no-state-changing-git contract" (no pack rule-slug).
- Audience framing: client adds "your project / your branch / your repo / your machine" (`grep -coiE "your (project|branch|repo|machine)"` = **15**).
- Agent roster: pack "(a coder)" → client "your `coder`, or `repo-ops` for scripted writes" + "your `architect`, `reviewer`, `planner`, the `auditor` family".
- Cross-refs: client adds `docs/pack/PM-CHAT.md` ("In-session agent spawning") and `agent-run.sh --worktree` (client paths), absent/different in the pack version.
- Launcher: client documents the project `agent-run.sh --worktree` launcher (the pack has no `agent-run.sh`); pack omits a launcher path.

Design §9 mandates exactly this ("NEITHER is a byte-copy; each is authored for its audience"). Confirmed.

### (b) No-BD-NNN / ZERO pack-self boundary discipline — VERDICT: PASS (the coder's call is correct)

ZERO pack-self references in the edited file, independently re-grepped at HEAD `13bb32e`:

```
$ F=project-template/docs/pack/OPTIONAL-FEATURES.md
$ grep -n "maintenance-docs"  $F → NONE
$ grep -n "pack-ops"          $F → NONE
$ grep -n "Pack Chat"         $F → NONE
$ grep -nE "pack-(coder|architect|planner|reviewer|docs-researcher|fix-coder)" $F → NONE
$ grep -nE "BD-[0-9]"         $F → NONE
$ grep -nE "validate-pack|PACK-AGENTS|PACK-CHAT" $F → NONE
```

The coder's specific boundary call — use neutral "a future pack version" instead of a `BD-218`/`BD-217` pointer — is the CORRECT call, independently confirmed:

```
$ grep -rnE "BD-[0-9]" project-template/   →  ZERO matches anywhere under project-template/
$ grep -nE "BD-21[78]" pack-ops/OPTIONAL-FEATURES.md
  182:...tracked under BD-218 (v11.1)...
  259:...tracked under BD-217 (v11.1)...
```

The client convention carries NO `BD-NNN` token anywhere (the entire `project-template/` tree is BD-free), while the pack version legitimately carries BD-218/BD-217 for the pack audience. Introducing a BD token into the client surface would violate `bd-pack-only-operational-rule` (BDs are categorically pack-self) and P-missed-7 (project-side investigation precedes pack defaults). The neutral phrasings actually used ("a future pack version", "tracked separately and is out of scope here", "a separate concern slated for a future pack version") match the measured client convention (`HELP-FRAGMENT-TRACKER.md`, `PM-CHAT.md`, `PLATFORM-SKILLS.md` all use neutral "a future …" phrasing). This is the boundary-correct disposition.

### (c) The 3-token PREFLIGHT (project half of Guard-A′) — VERDICT: PASS

The file mentions all three tokens the EXTENDED Guard-A′ will assert in C8b. Re-measured:

```
$ grep -c 'baseRef'           project-template/docs/pack/OPTIONAL-FEATURES.md → 10
$ grep -c 'bgIsolation'       ...                                            →  6
$ grep -c 'permissions\.deny' ...                                            →  4
```

All three > 0. Matches the IMPL-REPORT (10/6/4) exactly.

---

## Spec alignment (design §9/§18.2/§3/§7 + plan §B C8a) — independently checked

| Spec element | Required | Implemented? |
|---|---|---|
| TRIGGER = per-spawn Agent-tool `isolation:"worktree"` PARAM; `"worktree"` only valid param value; `head`/`none` are SETTINGS | §3 / plan C8a | YES — "the ONLY valid value for this parameter — `head` and `none` are SETTINGS values … NOT parameter values" (line 130) |
| BASE = `worktree.baseRef:"head"` REQUIRED; unset/`fresh`=origin/main wrong-base consequence | §3 / §8 / plan C8a | YES — REQUIRED + "defaults to `\"fresh\"`, which branches … from `origin/<default>` (i.e. `origin/main`) … wrong base" (lines 143–148); reinforced in Caveats (line 253) |
| `bgIsolation` = background-SESSION gate, NOT a subagent control, not a boolean; future-work pointer client-appropriate | §3 / plan C8a | YES — "governs TOP-LEVEL background `claude` sessions … `bgIsolation` does NOT control Agent-tool subagents … not a boolean (`bgIsolation: true` is invalid)"; pointer = "a separate concern slated for a future pack version" (no BD token) |
| `permissions.deny` recipe: not shipped, user-configured, session-scoped+inherited, deny-first (not bypassed by `bypassPermissions`); ONLY in-session mechanical layer (F1); hook SECONDARY/fails-open | §18.2 (F1–F5) | YES — all present; verb list = the §5.1 set (12 verbs); deny `Bash(git apply:*)` NEVER `Bash(git diff:*)`; "the pack ships neither the settings file nor the hook" |
| `agent-run.sh --worktree` launcher (SECONDARY) + cwd-scoping caveat + manual fallback (NEW-FORK-1 gate-then-probe-then-degrade) | §7 / plan C8a | YES — HEAD-basing (settings-independent, `git worktree add --detach <path> HEAD`), the probe ("run `./agent-run.sh claude --agent coder --worktree`, then … `git status`"), the manual fallback; cross-ref to `run_in_worktree` |
| "pack ships NO settings file" explicit | §9 / plan C8a | YES — dedicated paragraph (line 256) + the Status line |
| NO 9-cell matrix; NO bgIsolation-as-trigger | §3 / plan C8a | YES — `grep -niE "9-cell\|9 cell"` → NONE; `grep -niE "bgIsolation.*(is the trigger\|triggers isolation)"` → NONE |
| C8a does NOT add Guard-A′ (Check 54) | plan C8b | YES — `scripts/validate-pack.py` untouched (scope check below) |

Launcher cross-refs are LIVE, not dangling (both landed in C7a):
```
$ grep -n "\-\-worktree\|run_in_worktree" project-template/agent-run.sh → present (lines 160, 264, 285–286, 460, 582–584)
$ grep -n "In-session agent spawning"     project-template/docs/pack/PM-CHAT.md → 449
```

The launcher is documented as SHIPPED with the probe caveat (not degraded-to-manual-only) — consistent with C7a having landed the `--worktree` flag in `agent-run.sh`; the gate-then-probe-then-degrade contract is documented for the developer to exercise per their environment. This matches §7 / NEW-FORK-1.

---

## Independent re-verification — scope, manifest, carve-out, CI

### Scope (plan §B C8a; project-only)
```
$ git status --short
 M project-template/docs/pack/OPTIONAL-FEATURES.md
 M test-fixtures/manifest.txt
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-C8a.md
```
Exactly the two in-scope files + the report. NO pack-side surface (`scripts/`, `pack-ops/`), NO Guard-A′. Correct.

### Manifest regenerated, non-empty, reproducible, KEPT
```
$ git diff --stat test-fixtures/manifest.txt → 3 insertions, 3 deletions (the 3 v11 fixture SHAs)   [NON-EMPTY ✓]
$ cp manifest.txt /tmp/c8a-wt-manifest.txt; bash test-fixtures/build.sh --all --clean → exit 0
$ diff -q test-fixtures/manifest.txt /tmp/c8a-wt-manifest.txt → IDENTICAL   [reproducible; no checkout residue]
$ bash test-fixtures/build.sh --verify → exit 0 (all 6 fixtures OK)
```
The coder's manifest is reproducible from a clean rebuild (proves it is the correct regenerated artifact, not a stale checkout). KEPT/unstaged as required.

### Check-36 carve-out (project-only set has NO offenders)
Reproduced against `scripts/validate-pack.py`:
```
OPTIONAL-FEATURES _is_project_side_path:        True   (project-side; not an offender)
manifest _is_scope_neutral_generated:           True   (exempt)
manifest in _SCOPE_NEUTRAL_GENERATED_PATHS:     True
```
A `project-only` commit of `{OPTIONAL-FEATURES.md, manifest.txt}` is Check-36 clean.

### Full CI (independently re-run)
```
$ python3 scripts/validate-pack.py                       → exit 0  (PASSED — all checks clean)
$ PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py  → exit 0  (PASSED — all checks clean)
$ bash test-fixtures/build.sh --all --clean              → exit 0
$ bash test-fixtures/build.sh --verify                   → exit 0  (6 fixtures OK)
```
Representative test sample (all exit 0):
```
test-validate-pack-checks-36-37-38.sh   0
test-validate-pack-check-57.sh          0   (Guard-C project parity, the most recent BD-197 check)
test-init-project.sh                    0
test-customization-preserve.sh          0
test-v11-realistic-ot.sh                0   (the integration test that pins validator output)
test-persona-contracts.sh               0
```
Guard-A′ / Check 54 is correctly ABSENT (it ships in C8b). Green throughout.

### Markdown/JSON integrity
```
$ grep -c -F '```' OPTIONAL-FEATURES.md → 8   (4 balanced fence pairs)
```
The `permissions.deny` JSON block (file lines 188–207) is well-formed and lists all 12 §5.1 verbs (commit, push, add, stash, reset, restore, checkout, apply, worktree, clean, merge, rebase) and correctly omits `git diff`. The IMPL-REPORT's note that its OWN code-fence nested the JSON at 4-space indent is a REPORT artifact only — the actual file renders the block at normal indentation. No defect.

---

## Findings by severity

**BLOCKER:** none.
**MAJOR:** none.
**MINOR:** none.
**NIT:** none.

No real defects surfaced. The one plan deviation (the conditional `BD-218` forward pointer was NOT exercised) is rule compliance, not a divergence — verdict (b) above confirms it is the correct boundary call, fully documented in the IMPL-REPORT under "Plan deviations" and "Client-doc future-reference convention finding."

### What the implementation got right (acknowledgements)
- Independent client-native authoring (not a copy) with the correct orchestrator ("PM chat"), client paths, and project launcher.
- The boundary call on BD tokens is exactly right and well-evidenced (measured the whole `project-template/` tree, not just the file).
- The corrected mode model is faithfully reproduced: trigger=param, base=`baseRef`, `bgIsolation`=background gate, no 9-cell matrix, no bgIsolation-as-trigger.
- `permissions.deny` recipe matches §18.2 F1–F5 precisely (session-scoped+inherited+deny-first, verb-precise deny-apply-never-diff, hook secondary/fails-open, pack ships nothing).
- Cross-refs are live (C7a's `agent-run.sh --worktree` + PM-CHAT.md "In-session agent spawning"), not dangling.
- Scope is clean; manifest is reproducible and kept; no Guard-A′ leak into C8a.

---

## Carry-forward discipline

No carry-forward findings. Nothing deferred.

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured at HEAD `13bb32e`, 2026-06-14) | Conclusion |
|---|---|---|
| **bd-pack-only-operational-rule** | `grep -nE "BD-[0-9]" project-template/docs/pack/OPTIONAL-FEATURES.md` → NONE; `grep -rnE "BD-[0-9]" project-template/` → ZERO matches tree-wide; pack version carries `BD-218`/`BD-217` (lines 182/259) but client uses neutral "a future pack version". The no-BD-NNN call is the boundary-correct disposition. | COMPLIANT |
| **pack-project-separation-of-concerns** | `diff` pack-iso vs client-iso = DIFFERENT (159 vs 179 lines, 214 differing lines); client "PM chat" 14 / "Pack Chat" 0; "your project/branch/repo/machine" 15; documents project `agent-run.sh --worktree` (pack has none). Separate artifact, not a fallback. | COMPLIANT |
| **client-ref-delete-or-forward-look** | All references resolve to client-resident paths after install: `docs/pack/PM-CHAT.md` (line 449 anchor LIVE), `agent-run.sh` (`--worktree`/`run_in_worktree` LIVE in C7a), `.claude/settings.json`, `~/.claude/settings.json`. No client-shipped pack-repo path; the future-work pointer is neutral prose. | COMPLIANT |
| **regenerate-manifest-v11-surface** | `git diff --stat manifest.txt` = 3+/3- (NON-EMPTY); `build.sh --all --clean` exit 0 → `diff -q` vs working tree IDENTICAL (reproducible, no checkout residue); `build.sh --verify` exit 0; manifest left ` M` (unstaged, KEPT). | COMPLIANT |
| **verify-full-ci-suite** | `validate-pack.py` exit 0; `PACK_VALIDATE_DEEP=1` exit 0; `build.sh --all --clean`/`--verify` exit 0; representative tests incl. the integration test `test-v11-realistic-ot.sh` + Check-57 all exit 0. | COMPLIANT |
| **empirical-evidence-blocks** | Every claim above carries the actual command + verbatim output + HEAD `13bb32e` + date 2026-06-14. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Reviewed exactly C8a (project OPTIONAL-FEATURES DATA half). Confirmed NO Guard-A′ (`scripts/validate-pack.py` untouched per `git status`), no pack-side surface. No invented nits; no softened blocker (there is none). | COMPLIANT |
| **agents-never-commit** | Read-only git only: `git rev-parse`, `git status`, `git diff`, `git log`, `git rev-parse --abbrev-ref`. `build.sh --all --clean` rewrote the manifest to an IDENTICAL value (no net change / no residue); no `git add`/`commit`/`checkout`/`restore`/`stash` run. Sole file write = this report. | COMPLIANT |
| **rules-applied-verification-block** | This block. | COMPLIANT |

**Surfaced (not silently dropped):** The launcher is documented as a shipped SECONDARY path with the cwd-scoping probe caveat (not degraded-to-manual-only). This is correct given C7a landed `--worktree` in `agent-run.sh`; the gate-then-probe-then-degrade contract (NEW-FORK-1) is documented for the developer to exercise per environment, matching design §7 — no action needed, surfaced for completeness.
