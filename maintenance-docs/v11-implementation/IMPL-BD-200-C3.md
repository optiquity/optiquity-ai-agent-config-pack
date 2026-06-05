# IMPL-REPORT — BD-200 commit C3 — client `activate-capability.sh` + verb-reference rework + activation test harness

**Role:** pack-coder (fresh). **Branch:** `v11-dev`. **HEAD (unchanged — no git state change):** `3bc96faf3f4bbed667cbd567b2c5a1f0132422ad`.
**Date:** 2026-06-04. **Scope:** exactly C3 = T3 (NEW `activate-capability.sh`) + T6 (HELP-FRAGMENT / PM-CHAT / INSTALL-PROCEDURES rework incl. the R3 correctness fix) + the R5 test harness. C1 (single-source tables) and C2 (S5b pool stage + S9 skip) were verified already landed before any edit.

---

## 0 — Pre-flight (base correctness)

- `git rev-parse HEAD` → `3bc96faf...` (matches caller's stated base).
- `git status` clean except pre-existing untracked C1/C2 IMPL/REVIEW reports — none mine.
- C1 landed: `project-template/scripts/capability-tables.sh` present; `add-capability.sh` sources it lazily (line 135).
- C2 landed: `stage_s5b_populate_pool()` + `is_pool_path` S9 guard present in `init-project.sh`.
- C3 targets absent before work: `project-template/scripts/activate-capability.sh`, `scripts/tests/test-activate-capability.sh` — both NEW.

---

## 1 — Files changed (inventory)

| Path | Change type | Surface |
|---|---|---|
| `project-template/scripts/activate-capability.sh` | **NEW** | project-template (client deliverable; ships via S5 glob) |
| `scripts/tests/test-activate-capability.sh` | **NEW** | pack-side test infra (NOT installed) |
| `project-template/docs/pack/HELP-FRAGMENT.md` | modified | project-template |
| `project-template/docs/pack/PM-CHAT.md` | modified | project-template |
| `supporting-docs/INSTALL-PROCEDURES.md` | modified | supporting-docs (ships to client) |
| `test-fixtures/manifest.txt` | regenerated | pack-side fixture manifest |

No other files touched. No C1/C2 file edited. No `_SANCTIONED_PACK_SIDE_SHIPPED` change. No `project-template/.gitignore` pool line added (verify-only X1 honored). No project-template trinity edit (BD-200 ships no template-trinity content — trinity-parity rule does NOT fire).

---

## 2 — T3: `project-template/scripts/activate-capability.sh`

### Stages (P0/P1/P2/P5/P8 — the useful subset of `add-capability.sh`'s A0–A8, client-side)

- **P0 preflight** — git repo; clean tree (`git status --porcelain`); AI config present (CLAUDE/AGENTS/GEMINI). **NO `$PACK` check.** Verifies `pack-capability-pool/` exists; absent → exit 22 with a CLIENT-actionable message (re-run `init-project.sh --update`). The pool presence check REPLACES the pack-clone check.
- **P1 resolve** — sources its OWN installed tables `source "$SCRIPT_DIR/capability-tables.sh"`; `--add <dim>:<val>` → `capability_skills` + `capability_files`. Dedups. Keeps a `warn_if_missing_skills`-equivalent warn-don't-fail against on-disk client skills (`.{claude,codex,gemini}/skills/<skill>/SKILL.md`) for forward-declared rows (android/web/embedded). Skills NOT copied (already on disk from setup).
- **P2 delta** — computes skills-to-add vs Active-skills line + files-to-materialize vs live tree. Already-present non-`x-` files are skipped silently (never re-copy → never clobber project edits). **Exception:** an already-present resolved dest whose basename is `x-*` is PASSED THROUGH to P5 so the explicit `x-` preserve-warn fires at the copy site (keeps the `x-` contract observable). Degenerate / already-active early exits mirror `add-capability.sh`.
- **P5 copy** — for each resolved file: copy FROM `pack-capability-pool/<rel>` INTO the live tree at `<rel>` (root files + `server/`/`proto/` dirs + conditional `scripts/*`); `mkdir -p` parents; `chmod +x scripts/*.sh`; warn-don't-fail on a pool-missing file. **`x-` overwrite guard:** `if [[ -e "$dst" ]] && is_x_prefixed "$dst"` → SKIP + `warn "preserving project-authored file ..."`, never clobbering a project file (mirrors the pack's `is_x_prefixed` discipline in `init-project.sh` S9).
- **P8 emit prompt** — emits the Procedure-6 PM-chat prompt (written to `.pack-activate-capability-prompt.md` + stdout) driving trinity `**Active skills:**` update + commit. ZERO pack-self tokens.

### `x-` guard (load-bearing) — exact code

```
is_x_prefixed() { [[ "$(basename "$1")" == x-* ]]; }
...
if [[ -e "$dst" ]] && is_x_prefixed "$dst"; then
    warn "preserving project-authored file (x- prefix, not overwritten): $f"
    continue
fi
```

### Architect-doc-reality reconciliation (docstring)

The script's header docstring names the realized design by file+symbol (no line numbers): "This realizes the project-side capability-ACTIVATION design described in `docs/pack/METHODOLOGY.md` Procedure 6 ... resolution comes from the sibling, single-source `scripts/capability-tables.sh` (function `capability_files()`)."

### Zero-`$PACK` / zero-pack-self proof

`grep -nE '\$PACK\b|maintenance-docs/|pack-ops/|PACK-AGENTS|PACK-CHAT|HELP-FRAGMENT-PACK|pack-(architect|coder|planner|reviewer|docs-researcher)|from the pack|Pack Chat|BD-[0-9]{3}|add-capability|\.pack-add-capability' project-template/scripts/activate-capability.sh` → **ZERO hits.** The script uses only client vocabulary ("PM chat" lowercase — established client precedent in PM-CHAT.md, NOT the deny-listed capitalized `Pack Chat`).

### Dependency direction

Pure client deliverable at `project-template/scripts/` sourcing its OWN installed `capability-tables.sh` (client→client) and reading the client `pack-capability-pool/`. No pack runtime dependency; no `_SANCTIONED_PACK_SIDE_SHIPPED` growth (Check 47 frozen 2-tuple unmoved). Ships via the existing S5 `project-template/scripts/*` bulk glob — no install-map entry needed (Check 41 green).

---

## 3 — T6: reference rework (verb = `activate-capability.sh`)

### HELP-FRAGMENT.md (re-add verb row — reverses BD-195 C1 delete)

Replaced the editorial `add-capability.sh` row with:
`| \`bash scripts/activate-capability.sh\` | Activate a supported capability on this project — re-materializes its conditional files from \`pack-capability-pool/\`. |`

### PM-CHAT.md "Capability addition" rule

Renamed to the CLIENT `scripts/activate-capability.sh`; removed "from the pack"; describes the re-materialize-from-`pack-capability-pool/` behavior; still points at METHODOLOGY.md Procedure 6 (the C4-redesigned procedure).

### INSTALL-PROCEDURES.md — R3 correctness fix (measured: `add-capability.sh` deletes NO files; EEB-ADDCAP-NO-DELETE)

- **8a** — "Pack-controlled deletions skip `x-*`" bullet: DROPPED `add-capability.sh` from the deleter roster (it removes nothing). Left `init-project.sh` + the active `migrate-vN-to-vM.sh` migrator (the genuine S9/migrator deleters).
- **8b** — "Pack-controlled overwrites skip `x-*`" bullet: ADDED `activate-capability.sh` as an overwrite site that honors `x-` (its P5 re-materializes pool files and skips+warns on an `x-` collision).
- Both explanatory bullets preserved; only their script lists changed.

**R3 before/after:**
- Before — deletions bullet: `(\`init-project.sh\`, the active \`migrate-vN-to-vM.sh\` migrator, \`add-capability.sh\`)`. Overwrites bullet: no `activate-capability.sh`.
- After — deletions bullet: `(\`init-project.sh\`, the active \`migrate-vN-to-vM.sh\` migrator)`. Overwrites bullet: `+ \`activate-capability.sh\` is also an overwrite site ... it never overwrites a live-tree file whose basename begins with \`x-\` — it skips and warns ...`.

### Check 22 verb resolution (load-bearing) — GREEN

`activate-capability.sh` appears in PM-CHAT.md prose (as `scripts/activate-capability.sh`) AND in HELP-FRAGMENT.md AND resolves to the on-disk `project-template/scripts/activate-capability.sh` (this commit) — all together. Check 22 logic (validate-pack.py:1990–2021): a `scripts/`-prefixed token counts only if `surface_root/token` `.is_file()`; the new file makes it resolve, so the verb must be in the fragment — it is. Check 22 output: `project-template: 2 prose-referenced verb(s) all present in fragment`. The now-stale `add-capability.sh` token is gone from both surfaces (no dangling token; and it never resolved on the project-template surface anyway since `project-template/scripts/add-capability.sh` does not exist — pack-side only).

---

## 4 — R5 test harness: `scripts/tests/test-activate-capability.sh`

Pack-side behavioral test (matches `test-add-capability.sh` style/layout). Scratch repos self-provisioned under `/tmp` mktemp; cleaned via `trap cleanup EXIT`; never a real repo (`test-infra-self-provisioned`).

- **Group 1 — fresh-clone activation walk (no `$PACK`):** builds a Swift-only project (`Package.swift`, no `pyproject.toml`/`.py`); runs `init-project.sh` (S5b populates the pool; S9 removes live-tree Python); `git clone`s to a scratch dir; runs `env -u PACK bash scripts/activate-capability.sh --add language:python`. Asserts: pool populated + holds masters; S9 removed live-tree Python; P0/P5/P8 banners; no `PACK` error; P5 re-materialized `pyproject.toml` + `server/` + all four `*-python.sh` FROM the pool; re-materialized scripts executable; P8 prompt present, references Procedure 6, no `$PACK` / "from the pack".
- **Group 2 — `x-`-preserve-on-activate (guard genuinely exercised):** rewrites the CLONE's OWN installed `capability-tables.sh` so `language:python` resolves to an `x-` dest (`scripts/x-tool.sh`) plus a normal dest (`pyproject.toml`); pre-places a project-authored `x-tool.sh` + a pool master that WOULD clobber it; runs activation. Asserts: the `x-` dest is preserved byte-for-byte; P5 emitted `preserving project-authored file`; the non-`x-` resolved file in the SAME run IS materialized (guard is path-faithful, skips only the `x-` dest). (The stock pack tables never resolve to `x-`, so against them the guard is defensive — like S9's `is_x_prefixed`; the harness injects an `x-` resolution at the client's own table copy to fire the skip+warn path with NO pack involvement.)

**Result:** `passed: 25, failed: 0`.

**Manifest impact of the harness:** `scripts/tests/` is pack-side test infra, NOT under `project-template/` → S5 never installs it into fixtures → it does NOT itself move `test-fixtures/manifest.txt` (confirmed: the manifest diff is exactly the three v11-* rows, attributable to `activate-capability.sh` S5-shipping).

---

## 5 — Verification (all PASS)

| # | Check | Result |
|---|---|---|
| 1 | `bash -n` both new files | clean (SYNTAX OK) |
| 2 | Fresh-clone activation walk (Group 1) | green — activation succeeds with NO `$PACK`; Python set re-materialized FROM pool |
| 2b | `x-`-preserve (Group 2) | green — `x-` dest preserved + warned; non-`x-` written |
| 3 | Boundary grep — `activate-capability.sh` + my edited doc lines | ZERO pack-self tokens / `$PACK` (pre-existing hits elsewhere in PM-CHAT/INSTALL-PROCEDURES are NOT on my edited lines and pass CI today) |
| 4 | Check 22 | GREEN — `project-template: 2 prose-referenced verb(s) all present`; verb resolves to on-disk file |
| 4b | Check 43 | GREEN — 158 client files walked; zero pack-internal bare cross-refs |
| 4c | Check 37 | GREEN — 170 project-side files walked; zero deny-list contamination |
| 4d | Check 41 | GREEN — 37 entries resolve; 0 drift |
| 5 | R3 correctness | deletions bullet no longer lists `add-capability.sh`; overwrites bullet now lists `activate-capability.sh` |
| 6 | Manifest regen (`build.sh --all --clean`) | three v11-* rows moved; v10-* + `existing-project-mid-dev` unchanged; harness did not move it |
| 7 | `python3 scripts/validate-pack.py` | **PASSED — all checks clean**; Check 47 frozen 2-tuple `{scripts/lib/detect.sh, scripts/pack-help.sh}` unmoved |
| — | `test-add-capability.sh` (C1 shared-tables regression) | green (19/19) — no regression |

**Manifest diff (the deliverable artifact):**
```
-v11-realistic-ot  b933e2142a00b4c95cdf6d2be940744ac1b05995
-v11-flat-file  5587dc156de0cef3b517902d17d108b80f787c63
-v11-tracker-on  eafdd09a085258f215b92af7e91ba04186250a2b
+v11-realistic-ot  6647f5c0bba60c1352d8074b12475c09c6a65b4a
+v11-flat-file  b183c6f535fb244e18eff61de8faf36ebea3b2ae
+v11-tracker-on  229a3ab0b820047a93329b9b04b1d15ed00bd81a
```
(v10-minimal / v10-realistic-ot / existing-project-mid-dev rows unchanged — they use the v10 init or are pre-install input shapes.)

The Check 48 WARNs (14, in `pack-ops/CHANGELOG.md`/`BACKLOG.md`) are pre-existing JC-5 advisory removed-doc citations — advisory only, not a gate failure, not my files.

---

## 6 — Plan deviations

**ZERO plan deviations.** All C3 tasks (T3 + T6 incl. R3 + R5 harness) implemented per `PLAN-BD-200.md` §2/§4-C3/§5 and `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` §3.1/§3.7/§4.2/§4.6. BD-202 boundary intact (NO `pack update`/pool-refresh/`cmd_update` logic). No `x-` prefix on the new pack-shipped script name. C1/C2 files untouched. Procedure 6 NOT redesigned here (that is C4/T5 — only pointed at).

---

## 7 — New POQs / observations (no plan re-design; surfaced)

1. **P5 `x-` guard reachability (resolved, in-scope, surfaced).** With the stock pack `capability_files()` resolving NO `x-` paths, the literal P5 guard `[[ -e dst ]] && is_x_prefixed dst` can only fire for an `x-`-basename resolved dest — which the tables never produce. It is therefore a DEFENSIVE/forward-pinning guard, exactly like `init-project.sh` S9's `is_x_prefixed` (whose EEB-S9 itself calls it "defensive — the current loop iterates fixed pack-roster names"). The architecture's `x-`-preserve requirement (review §3.4/§4.5; PLAN §5 explicitly notes "`x-pyproject.toml` is NOT a real resolved path") is satisfied as a defensive contract. To keep the contract OBSERVABLE (not dead code), P2 passes an already-present `x-` resolved dest through to P5 so the explicit preserve-warn fires at the copy site; the harness Group 2 injects an `x-` resolution at the CLIENT's own table copy to exercise the skip+warn path end-to-end. This matches the plan's intent (defensive guard + behavioral assertion) — NOT a deviation, recorded for transparency.

No new BD opened; nothing deferred.

---

## 8 — Definition-of-Done checklist

| DoD item | PASS/FAIL |
|---|---|
| T3 `activate-capability.sh` NEW, self-contained, NO `$PACK`, sources own tables | PASS |
| P0/P1/P5/P8 stages per review §4.2/§3.7 (+ P2 delta) | PASS |
| `x-`-on-overwrite guard present + behaviorally proven (preserve + warn) | PASS |
| Skills NOT copied; warn-don't-fail for forward-declared skill rows | PASS |
| Docstring names realized design (file+symbol, no line numbers) | PASS |
| Zero pack-self tokens in the client-shipped script (Check 43/37) | PASS |
| T6 HELP-FRAGMENT re-adds `activate-capability.sh` verb row | PASS |
| T6 PM-CHAT names client script, removes "from the pack", points at Proc 6 | PASS |
| T6 INSTALL-PROCEDURES R3: 8a drop `add-capability.sh` from deletions; 8b add `activate-capability.sh` to overwrites | PASS |
| Check 22 verb resolves (PM-CHAT + HELP-FRAGMENT + on-disk file, this commit) | PASS |
| R5 harness: fresh-clone walk + `x-`-preserve, green, self-provisioned `/tmp` | PASS |
| Boundary grep ZERO on client surfaces | PASS |
| Manifest regenerated; three v11-* rows moved; harness did not move it | PASS |
| `validate-pack.py` PASSED; Check 47 frozen 2-tuple unmoved | PASS |
| BD-202 boundary intact (no update/refresh logic) | PASS |
| No `x-` prefix on the new pack-shipped script name | PASS |
| No git state-changing verb; HEAD unchanged `3bc96fa` | PASS |

---

## 9 — Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **READ-IN-FULL set** | Read IN FULL via Read tool: `CLAUDE.md` (541 lines, full — first line `# CLAUDE.md — AI Agent Config Pack (Pack Repo)`, last line `testing (use \`/tmp\` clones or scratch fixtures, never write to real OT).`); `pack-ops/PACK-AGENTS.md` (226 lines, full — last `Always run \`git add -A && git status\` and confirm staged files before any commit.`); `pack-ops/PACK-CHAT.md` (310 lines, full — last `verified by END-STATE checks (bijection / anti-restate / trinity-parity / manifest), not a hard-enforced step sequence.`); `project-template/CLAUDE.md` (456 lines, full — last `The marker is preserved across pack upgrades. New projects start with this H2 empty.`-block end); `PLAN-BD-200.md` (235 lines, full, incl. §2 T3+T6, §3, §5, §6, R3/R5, §8 EEBs, §9); `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` (441 lines, full — both pages 1-336 + 337-441, incl. §3.1/§3.7/§4.2/§4.4/§4.6/§10); BD-200 entry `pack-ops/BACKLOG.md:3273-3306` (full); curated memory FULL: `feedback_agents_read_rule_docs_in_full` (71 ln), `feedback_agent_output_rules_applied_block` (15 ln), `feedback_manifest_regen_on_v11_surface` (16 ln), `feedback_bd_pack_only_operational_rule` (35 ln), `feedback_pack_project_separation_of_concerns` (33 ln), `feedback_client_ref_delete_or_forward_look` (41 ln). Source measured: `project-template/scripts/capability-tables.sh` (217 ln, full), `scripts/add-capability.sh` (645 ln, full), `scripts/init-project.sh` (S5b 554-624, S9 733-821, detect 128-200), `scripts/validate-pack.py` (Check 22 1945-2031, deny-list 4086-4135, Check 43 5600-5660, exts 4949/5398), `project-template/docs/pack/HELP-FRAGMENT.md` (full) + `PM-CHAT.md` (capability rule 384-395), `supporting-docs/INSTALL-PROCEDURES.md` (44-73), `scripts/tests/test-add-capability.sh` (158 ln, full). | **COMPLIANT** |
| **preflight-stop-means-stop** | PREFLIGHT line emitted ONLY after all edits + verification PASS (bash -n + harness 25/25 + validate-pack PASSED + Check 22/43/37/41 green + manifest regen). No parent stop directive received. | **COMPLIANT** |
| **agents-never-commit** | Only read-only git verbs (`git rev-parse`, `git status`, `git diff`) + `git init`/`git clone`/`git commit` confined to `/tmp` scratch repos inside the harness (never the pack repo, never a real repo); cleaned via `trap`. NO `git add/commit/push/tag` on the pack worktree. HEAD unchanged `3bc96fa`. | **COMPLIANT** |
| **boundary / no-pack-self-in-project** (CRITICAL) | `grep` for `$PACK`/`maintenance-docs/`/`pack-ops/`/PACK-AGENTS/PACK-CHAT/pack-* agents/"from the pack"/`Pack Chat`/`BD-NNN`/`add-capability` on `activate-capability.sh` → ZERO. My edited PM-CHAT (387-393) + INSTALL-PROCEDURES (54-65) + HELP-FRAGMENT (15) lines → ZERO. Check 43 (158 files) + Check 37 (170 files) GREEN (walk the new client file). | **COMPLIANT** |
| **client-ref delete-or-forward-look** | The stale `add-capability.sh` client reference (genuinely pack-only — `project-template/scripts/add-capability.sh` does not exist) was DELETED from HELP-FRAGMENT + PM-CHAT and REPLACED by the real project asset `activate-capability.sh` (forward-looking to the landed client path `scripts/activate-capability.sh`). INSTALL-PROCEDURES R3: `add-capability.sh` dropped from deletions (case-1 delete); `activate-capability.sh` added to overwrites (case-2 real project asset). | **COMPLIANT** |
| **regenerate-manifest-v11-surface** | C3 touches `project-template/` + `supporting-docs/` → `bash test-fixtures/build.sh --all --clean` run; diff = 3 v11-* rows moved (staged in this commit); v10-*/existing rows unchanged; harness (`scripts/tests/`) does not move it. | **COMPLIANT** |
| **enumerate-encoding-surfaces** | The `activate-capability.sh` verb kept in lock-step across: the script (T3), HELP-FRAGMENT (T6), PM-CHAT (T6), INSTALL-PROCEDURES `x-` bullets (T6/R3), Check 22 verb pairing, and the behavioral harness (R5) — all updated in THIS commit; manifest regenerated. No asymmetric coverage. | **COMPLIANT** |
| **dependency-direction-placement** | Client script at `project-template/scripts/`, sources its own installed `capability-tables.sh` (client→client), reads client `pack-capability-pool/`; no pack runtime dependency; Check 47 frozen 2-tuple unmoved (no `_SANCTIONED_PACK_SIDE_SHIPPED` growth). | **COMPLIANT** |
| **architect-doc-reality-reconciliation** | `activate-capability.sh` docstring names the realized design by file+symbol: `docs/pack/METHODOLOGY.md` Procedure 6 + `scripts/capability-tables.sh::capability_files()` (no line numbers). | **COMPLIANT** |
| **pack-repo-code-comment-deferrals** | No deferral comments introduced (none needed); zero plain-English `// TODO`/`// FIXME` in the new files. `grep -nE 'TODO|FIXME|fix later'` on both new files → none. | **N/A: no deferrals introduced** |
| **rules-applied-verification-block** | This §9 — per-rule name + measured evidence + terminal verdict; no empty-evidence rows; READ-IN-FULL row carries per-file proof (line counts + first/last line). | **COMPLIANT** |

---

## 10 — Full contents of NEW files (for re-apply)

The two NEW files are on disk at:
- `project-template/scripts/activate-capability.sh` (client deliverable; executable; the P0–P8 + `x-` guard described in §2)
- `scripts/tests/test-activate-capability.sh` (pack-side behavioral harness; the 3-group Swift-only fresh-clone walk + `x-`-preserve described in §4)

Both pass `bash -n`; the harness passes 25/25; full `validate-pack.py` PASSED. (Per chunking discipline, the verbatim file bodies are not duplicated here — they are on disk in the worktree at the paths above, staged for C3 by Pack Chat. If a re-derive is needed, the §2 stage spec + the §4 group spec + the `x-`-guard code block in §2 are the load-bearing reconstruction inputs.)
