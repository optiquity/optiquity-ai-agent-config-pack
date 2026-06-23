# DESIGN — BD-243 SHIPPED CLIENT-SIDE OPERATING-DOC ENFORCEMENT GATE (the dual-surface mirror)

Architect: FRESH architect instance (pack-architect, RO). I did NOT author any prior BD-243 artifact (DESIGN-BD-243.md / -FINAL / -FINAL-V2 / -DURABLE-GATES / -BLOAT-METHOD, the CENSUS, or any PLAN-BD-243-*). Conclusions are my own; I independently re-measured the client surface (reconciliation-instance-independence).
Runtime: repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, branch `v11-dev`, canonical HEAD **`103cca8`** (verified at runtime: `git rev-parse HEAD` = `103cca8e51feef9c80e4e76be17bd0dd274d3a6b`), clean working tree (untracked plan docs only), 2026-06-22. READ-ONLY: no edits, no patch, no state-changing git. My sole write is this design doc to the caller-specified path.
Status: ARCHITECT-READY — goes to the user, then the planner sequences the client-gate implementation (V4) into the V3 plan. I design the client gate + the dependency-correct insertion; I do NOT re-sequence the bloat/gate waves.

This design closes the SECOND enforcement gap the user identified. BD-243 installs the `operating-docs-no-history-no-bloat` RULE on BOTH trinities and adds 4 durable pack gates (Checks 66/67/68/69 + hardened Check 44) in `scripts/validate-pack.py`. But **`validate-pack.py` is pack-only — it never ships.** It keeps the pack tree + the project-template DELIVERABLES clean, but it does NOT gate a CLIENT's ongoing doc work. After install, when **PM Chat** writes the client's backlog / implementation-plan / changelog entries and edits the installed `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` + `docs/pack/*` over months, NOTHING enforces the anti-history / anti-deferred-feature / anti-bloat / anti-dangling rule — it rests on discipline only. The user's ruling: **ship a client-side operating-doc enforcement gate so PM Chat's work carries the same durable enforcement Pack Chat's work does.** This design is the client mirror of `DESIGN-BD-243-DURABLE-GATES.md`.

---

## 0. EXECUTIVE ANSWER (decision-ready)

| Aspect | Decision |
|---|---|
| **What it enforces** | All 4 axes, project-audience: HISTORY (Check-65 mirror, with the CRITICAL history-home carve-out), DEFERRED-FEATURE (Check-67 mirror), BLOAT (Check-66/44 mirror), DANGLING (Check-68 mirror). |
| **Ship location** | `project-template/scripts/validate-docs.sh` — a project-side deliverable, joining `validate.sh` / `validate-{proto,python,swift}.sh` / `agent-post-edit-check.sh`. Ships automatically via `stage_s5_scripts()` glob (no install-map row). |
| **How it runs** | (1) Wired into `validate.sh` as a language-INDEPENDENT always-run check (the client's top-level validator); (2) wired into `agent-post-edit-check.sh` as a NEW `*.md` branch (today `.md` is skipped); (3) NO shipped CI workflow (the client has none today — out of scope; documented invocation + the two hooks suffice). |
| **Pack-vs-client code-sharing** | **Option (i) — RE-IMPLEMENT in the shipped `validate-docs.sh` (separate, self-contained POSIX-ish bash + a small embedded python/awk pass).** REJECT option (ii) shared-lib: it forces a Check-47 `_SANCTIONED_PACK_SIDE_SHIPPED` expansion the file CANNOT satisfy (no pack op depends on `validate-docs.sh` at runtime), AND it would drag pack-internal vocabulary into a client surface. Drift is mitigated by a shared-RULE-TEXT anchor (both gates enforce the ONE trinity rule) + a pack-side parity check (new validate-pack Check that asserts the shipped gate's axis set matches the rule). |
| **Allowlist** | A client-self-contained allowlist file `scripts/.docs-gate-allowlist.txt` (shipped, `x-`-extensible by the client), sized to the project-audience KEEPs (the rule's own self-reference in trinity; TD-deferral "Deferred items"; the project streams as history-homes via an IN-set EXCLUSION not an allowlist; `x-` custom files; framework filename grammar). |
| **Boundary discipline** | The shipped gate + its config reference ZERO pack-internal mechanism (no `pack-ops/`, no `validate-pack.py`, no BD-NNN, no `maintenance-docs`, no "Pack Chat"). Verified §D2. |
| **Insertion** | Its OWN `project-only` commit **CG-15** AFTER the gate wave (CG-14), because its measure-then-bound baseline is the bloat-reduced + history-clean project-template (CB-07/CB-08/CB-09 + CG-14). Depends on the project-template being clean first. |

**Central decision (the load-bearing one): RE-IMPLEMENT (option i), do NOT extract a shared lib (option ii).** The dependency-direction rule and the Check-47 allowlist contract make (ii) infeasible: a shared shippable lib qualifies for `_SANCTIONED_PACK_SIDE_SHIPPED` ONLY if BOTH (1) a pack op depends on it at runtime AND (2) a client surface invokes it. `validate-docs.sh`'s logic satisfies (2) but NOT (1) — `validate-pack.py` is the pack's OWN gate and would not `source` a client-shippable doc-gate lib (it has its own richer Check-65/66/67/68 implementations already). Forcing (1) just to enable sharing would invert the dependency direction (a pack op depending on a client deliverable — the exact thing the rule forbids). So (i) is the only rule-clean path; §C details the drift mitigation.

---

## 1. RUNTIME STATE BASELINE (measured @ `103cca8`)

The client surface today, measured directly (grep/Read authoritative; the graph returned only rule-rationale nodes — STALE for this surface — so I fell back immediately, G2).

- **Shipped client scripts** (`project-template/scripts/`, 18 files): `validate.sh` (top-level wrapper, language-detecting), `validate-{proto,python,swift}.sh` (per-language), `agent-post-edit-check.sh` (per-edit hook), `format*.sh`, `test*.sh`, `bootstrap*.sh`, `proto-gen.sh`, `activate-capability.sh`, `capability-tables.sh`. There is **NO docs validator** today.
- **`validate.sh`** detects languages via marker files (`Package.swift`/`pyproject.toml`/`proto/`) and runs ONLY the matching per-language validators. It runs NOTHING language-independently today; a docs gate must be added as an always-run step.
- **`agent-post-edit-check.sh`** runs per-edit (Claude PostToolUse hook + Codex `post_edit_command`). It branches on file extension; for `*.md|*.txt|*.json|*.yaml|*.yml|*.toml` it prints "non-code file — skipping build/lint" and does nothing. So **markdown edits — exactly the operating-doc edits this gate targets — are UN-checked per-edit today.**
- **No shipped CI workflow.** `project-template/.github/` contains only `ISSUE_TEMPLATE/` (`work-item.yml`, `inbound.yml`, `config.yml`). There is NO `project-template/.github/workflows/`. The client has no CI gate at all.
- **Install mechanism.** `stage_s5_scripts()` (init-project.sh:553) globs `project-template/scripts/*` and copies EVERY file to the client `scripts/`, then `chmod +x scripts/*.sh`. A NEW `validate-docs.sh` ships AUTOMATICALLY — no install-map row, no per-file wiring. (Contrast: `docs/pack/*` files use explicit install-map rows in `stage_s6_docs_pack` — scripts do not.)
- **Manifest.** `test-fixtures/manifest.txt` keys on FIXTURE names (6 rows), not on `project-template/` paths (0 `project-template` references). Shipped-script changes are verified by the fixture rebuild (`build.sh --verify` + validate-pack Check 62), not a per-file manifest row.
- **The shipped rule.** All three project trinity files carry the rule (`project-template/{CLAUDE,AGENTS,GEMINI}.md`, "Operating docs carry NO history, NO deferred-feature mentions; stay terse + structured"). The rule names the THREE axes (history / deferred-feature / bloat) and explicitly names the history-homes: "History and roadmap belong in the project streams (`docs/project/backlog/` and `docs/project/changelog/`) and in IMPL reports — never copied into an operating doc."

**EE-CBASE — client script surface + wiring @ `103cca8`.**
- Cmd: `ls project-template/scripts/`; `sed -n '35,58p' project-template/scripts/validate.sh`; `sed -n '70,99p' project-template/scripts/agent-post-edit-check.sh`; `ls project-template/.github/`; `sed -n '553,568p' scripts/init-project.sh`; `grep -c project-template test-fixtures/manifest.txt`.
- Output (verbatim, key): 18 scripts incl. `validate.sh`+`agent-post-edit-check.sh`, NO `validate-docs.sh`; validate.sh `has_swift`/`has_python`/`has_proto` only (no language-independent step); agent-post-edit `*.md|*.txt|... ) echo "...skipping build/lint"`; `.github/` = `ISSUE_TEMPLATE` only (no `workflows/`); `stage_s5_scripts()` `for f in "$pack_scripts"/*; do ... cp "$f" "$TARGET/scripts/"; done; chmod +x "$TARGET/scripts"/*.sh`; manifest `project-template` count = 0.
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: a new `project-template/scripts/validate-docs.sh` ships by glob with zero install-map change; `.md` edits are currently un-gated per-edit; there is no client CI to wire into. The two wiring points are validate.sh (add an always-run step) + agent-post-edit-check.sh (add a `*.md` branch).
- Conclusion: **SUPPORTED.**

**EE-CRULE — the shipped rule + history-home declaration @ `103cca8`.**
- Cmd: `grep -n "Operating docs carry NO history" project-template/{CLAUDE,AGENTS,GEMINI}.md`; `sed -n '242,255p' project-template/CLAUDE.md`.
- Output (verbatim): CLAUDE.md:242, AGENTS.md:226, GEMINI.md:239 all carry the rule; body names (a) history (dated notes / "X did Y" / provenance / incident-or-SHA), (b) deferred-feature ("even to say it is deferred"), (c) terse+structured (no mega-bullet / prose-that-should-be-a-table / padding); "LIVE forward-pointers to CURRENT in-flight work KEEP"; "History and roadmap belong in the project streams (`docs/project/backlog/` and `docs/project/changelog/`) and in IMPL reports".
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: the client gate enforces THIS exact rule. The rule itself declares the project streams + IMPL reports as the history-homes — so the gate's IN set MUST EXCLUDE those (gating them would contradict the rule the gate enforces).
- Conclusion: **SUPPORTED.**

**EE-CHIST — the project streams legitimately carry dates + TD-narrative (history-homes, NOT gate-able) @ `103cca8`.**
- Cmd: `sed -n '1,30p' project-template/docs/project/changelog/_format.md`; `head -50 project-template/docs/project/changelog/_rules.md`.
- Output (verbatim, key): changelog `_format.md` entry shape `### YYYY-MM-DD — Phase N — <title>` + "**Backlog items addressed**: TD-NNN resolved. TD-NNN ... investigated and deferred with logging (blocked on <reason>)"; changelog `_rules.md` "Append-only-historical — no lifecycle states. Once written, an entry is never edited".
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: the changelog stream's ENTRY FORMAT mandates `YYYY-MM-DD` dates AND "deferred with logging" narrative. If the client gate applied the HISTORY axis (date-regex) or the DEFERRED axis to `docs/project/changelog/`, it would FAIL the client's own correctly-authored changelog every time PM Chat writes an entry. The streams are history-homes — the gate's IN set EXCLUDES them. This is the single most important client-specific divergence from the pack gate (whose IN set already excludes the per-entry stores).
- Conclusion: **SUPPORTED — the project streams are history-homes; gating them is a defect.**

---

## 2. SECTION A — WHAT THE CLIENT GATE ENFORCES (the 4 axes, project-audience)

The pack gates (`DESIGN-BD-243-DURABLE-GATES.md`) are the template. Each axis below states whether it applies client-side and the project-audience adaptation.

### Axis 1 — HISTORY (Check-65 mirror) — APPLIES, with the history-home carve-out

**What it catches client-side:** an INSTALLED operating doc (trinity, `docs/pack/*` reference docs the client may edit, skills, agent-defs, prompts) carrying dated notes / "X did Y" past-action narration / provenance / "carried from" notes / incident-or-commit-SHA refs. SAME forbidden-pattern family as pack Check 65 (`date` `20\d\d-\d\d-\d\d`, `sha` `\b[0-9a-f]{7,40}\b`, `Commit N`, `Override N`, `carried from|carry-over`, `\bincident\b` whole-word per R2).

**Project-audience adaptations (load-bearing):**
- **The bd-past-action pattern is RE-VOCABULARIZED `BD-` → `TD-`.** The pack pattern is `BD-\d+\s+(deleted|added|...)`; the project uses TD-NNN, not BD-NNN. The client gate's pattern is `TD-\d+\s+(deleted|added|renamed|introduced|removed|created|...)` + `per\s+TD-\d+`. A literal `BD-NNN` reference in a client operating doc is itself a boundary leak (BD- is pack-internal) — but the existing pack-side Check 43 already guards client-surface pack-leaks at SHIP time; the client gate does NOT need to re-police `BD-` (it would be enforcing a pack concept on a client surface — boundary discipline forbids it). The client gate's history axis uses the PROJECT vocabulary (TD-, phase-N, the project streams).
- **The IN set EXCLUDES the project streams + IMPL reports (EE-CHIST).** `docs/project/backlog/`, `docs/project/implementation-plan/`, `docs/project/changelog/` (and their monolith mirrors `BACKLOG.md`/`IMPLEMENTATION-PLAN.md`/`CHANGELOG.md`/`STATUS.md`) are history-HOMES; the rule the gate enforces says so explicitly. They are EXCLUDED from the IN set (not allowlisted line-by-line — a whole-tree exclusion, since EVERY entry legitimately carries a date). Same for `docs/reference/` (developer-authored user docs, not operating docs). This is the client mirror of the pack gate's per-entry-store exclusion, but BROADER (the entire stream trees, plus the date-bearing mirrors).

**Verdict: APPLIES — date/SHA/past-action/provenance over the INSTALLED operating docs; streams + reference + IMPL excluded.**

### Axis 2 — DEFERRED-FEATURE (Check-67 mirror) — APPLIES, recall gate, project-audience KEEPs

**What it catches client-side:** an installed operating doc advertising a deferred / unimplemented / off-by-default feature. SAME recall-gate shape as pack Check 67 (compiled-alternation of deferral markers: `\bdeferred\b`, `future (release|version)`, `\bnot yet (created|implemented|built|shipped)\b`, `once .{0,40}\b(land|ship)s?\b`, `\broadmap\b`, `coming soon`, `\bslated\b`).

**Project-audience adaptations:**
- **Drop the pack-version markers `v11.1|v11.x`.** Those are PACK release tokens, meaningless (and boundary-leaky) on a client surface. A client may have its OWN version vocabulary — but a generic forward-look gate should NOT hardcode a client's versioning (the client's own roadmap lives in the streams). The client gate's deferred axis catches the generic prose markers only, not version tokens.
- **The genuine KEEP categories (project-audience), sized measure-then-bound (§D):** (1) the RULE'S OWN self-reference in the trinity ("ZERO description of a DEFERRED ... feature ... even to say it is deferred") — the rule describing what it forbids; (2) the LIVE TD-deferral workflow — the client coder/agent-defs' "Deferred items" report section + the `// TODO(scope): TD-TBD` deferral-comment vocabulary in `project-template/CLAUDE.md` § "Deferral comments and BACKLOG hygiene" + "Deferral IS scope creep" rules — these document a LIVE workflow, not a deferred feature; (3) generic client-PRODUCT advice (e.g. an `api-design` skill's "remove in a future version" about the CLIENT's own API evolution).

**Verdict: APPLIES — recall gate over installed operating docs; KEEP = rule self-ref + the live TD-deferral workflow + generic product advice; no pack-version tokens.**

### Axis 3 — BLOAT / VOLUME (Check-66 + Check-44 mirror) — APPLIES, simplified

**What it catches client-side:** (a) a per-bullet/per-rule char-cap over the bullet-bearing client surface (the trinity `## Project memory` bullets — the client mirror of the pack `## Pack memory` bullets); (b) optionally a per-doc length ceiling on the installed reference docs the client should keep terse.

**Project-audience adaptations:**
- **The pack's Gate-1a (Check 44 frozen 6-doc per-doc ceilings) does NOT port cleanly.** The pack's 6 durable docs (`pack-ops/*`) do not exist client-side. The client's analogous "must stay terse" docs are the trinity + `docs/pack/*` reference docs. RECOMMEND the client gate ships the per-BULLET char-cap (Gate-1b analog) as the PRIMARY bloat axis — it is the mega-bullet pattern (the dominant trinity bloat) and is the same single-constant mechanism. A per-DOC ceiling is OPTIONAL/SECONDARY: if shipped, it covers the client trinity + `docs/pack/*`, with a single generous cap (not 6 individually-calibrated numbers — the client cannot re-derive per-doc ceilings the way the pack coder does at CG-14-prep).
- **Single char-cap constant + an allowlist for irreducible enumerations** (the denied-git-verb list, the deletion-rules enumeration `.nullify/.cascade/.deny/.noAction`) — same false-positive strategy as the pack gate (volume-only, never meaning; the cap is a character count asserting nothing about content; the allowlist admits genuinely-irreducible bullets with a `reason:`).

**Verdict: APPLIES — per-bullet char-cap as primary (the mega-bullet axis); optional single per-doc cap over trinity + docs/pack; NOT the pack's 6 per-doc calibrated ceilings.**

### Axis 4 — DANGLING-REFERENCE (Check-68 mirror) — APPLIES, project IN set

**What it catches client-side:** a backtick / hyperlink / qualified-path file reference in an installed operating doc whose target does not exist in the CLIENT tree. SAME existence-gate shape as pack Check 68 (bare-ref + hyperlink + qualified-path patterns, after stripping code blocks, resolved against the client tree's basename index, with an anchor-phrase carve-out for self-flagged "archived"/"does not exist" refs).

**Project-audience adaptations:**
- **Resolve against the CLIENT tree, not the pack tree.** Existence is checked in the installed project (the client's `docs/`, `scripts/`, etc.), never any pack path.
- **The intentional-placeholder allowlist is project-grammar:** `TD-NNN.md`, `phase-N.md`, `2026-MM-DD-phase-N.md` (the per-entry filename grammar the streams document), `x-<name>` custom patterns, `[PROJECT_NAME]`/`[PLATFORM_TARGETS]` template placeholders, and the anchor-phrase self-flagged set. NO pack grammar (`BD-NNN.md`, `migrate-vN-to-vM.sh` are pack patterns — they should not appear in client docs at all; if they do, that is a leak Check 43 catches at ship time, not a client-gate concern).

**Verdict: APPLIES — existence over installed operating docs, resolved in the client tree; project-grammar placeholders allowlisted.**

### Axis summary

| Axis | Pack check | Client mirror | Key project-audience delta |
|---|---|---|---|
| HISTORY | 65 | YES | `BD-`→`TD-`; EXCLUDE the stream trees + mirrors + reference + IMPL (history-homes) |
| DEFERRED | 67 | YES | drop `v11.x` version tokens; KEEP the live TD-deferral workflow + rule self-ref |
| BLOAT | 66 (+44) | YES | per-bullet char-cap primary; optional single doc-cap; NOT the 6 calibrated ceilings |
| DANGLING | 68 | YES | resolve in CLIENT tree; project-grammar placeholders; no pack grammar |
| meta (new-doc coverage) | 69 | OPTIONAL | the client surface is far smaller + stable; a glob-based IN set suffices; a meta-check is OPTIONAL polish (§A-note) |

**A-note on Gate 4 (Check-69 meta-check) client-side:** the pack's new-doc auto-coverage meta-check guards a 135-file, 11-family, frequently-edited IN set. The client's installed operating-doc set is smaller and far more STABLE (the client adds `x-` skills/agents but rarely new doc FAMILIES). RECOMMEND the client gate use a glob-based IN set (auto-discovers new `x-` skills/agents/docs in the known families) WITHOUT a separate meta-check — the meta-check's value (catching a doc in an UN-globbed location) is low on a stable client surface, and a 5th axis adds maintenance cost against the design-elegance bar (fewer special cases). If the user wants belt-and-suspenders, it can be a one-line "any `.md` under `docs/` not in a known family or the EXCLUDE set is reported as INFO" — but I recommend OMIT for simplicity.

---

## 3. SECTION B — THE CLIENT OPERATING-DOC IN SET (measure-then-bound)

The gate scans the INSTALLED operating docs + the client's `x-` custom files, and EXCLUDES the history-homes. Measured against the project-template deliverables (the post-install client shape; the realistic client adds `x-` files + authored stream entries on top).

### B.1 IN set (gate scans these)

| Family | Glob (relative to project root) | Project-template members @ `103cca8` | Operating? |
|---|---|---|---|
| project trinity | `{CLAUDE,AGENTS,GEMINI}.md` | 3 | YES |
| installed reference/operating docs | `docs/pack/*.md` | 5 (`METHODOLOGY` not present at template; `HELP-FRAGMENT`/`OPTIONAL-FEATURES`/`PACK-FEEDBACK`/`PLATFORM-SKILLS`/`PM-CHAT`) minus HELP-FRAGMENT (help OUTPUT) = 4 IN | YES (PM Chat may edit) |
| installed prompts | `docs/pack/prompts/*.md` | 10 | YES |
| installed skills | `skills/*/SKILL.md` (→ `.claude/.codex/.agents/skills/`) | 37 | YES |
| installed agent-defs | `.claude/agents/*.md` (16) + `.codex/agents/*.toml` (16) + `.agents-plugin/optiquity-agents/agents/*.md` (16) | 48 | YES |
| stream-meta CONTRACTS | `docs/project/*/_rules.md` (3) + `changelog/_format.md` (1) | 4 | YES (contracts are operating; the ENTRIES are not — see EXCLUDE) |
| `x-` custom files | `**/x-*` (skills/agents the client authors) | 0 at template; grows client-side | YES |

Approx template IN baseline: 3 + 4 + 10 + 37 + 48 + 4 = **~106 files** (the client adds `x-` files + does NOT add new families). The exact count is the coder's measure-then-bound baseline at CG-15 (after the project-template is bloat-clean per CB-07/CB-08/CB-09).

### B.2 EXCLUDE set (history-homes + non-operating — gate NEVER scans for history/deferred)

| EXCLUDE | Why | Axes affected |
|---|---|---|
| `docs/project/backlog/**` | history-home (TD entries) — the rule names it | HISTORY + DEFERRED excluded; DANGLING may still apply (a backlog entry citing a missing file is still a dead pointer) — but the entries legitimately reference TD-NNN grammar, so allowlist the grammar |
| `docs/project/implementation-plan/**` | history-home (phase/task plan) | HISTORY + DEFERRED excluded |
| `docs/project/changelog/**` | history-home (append-only dated entries — EE-CHIST) | HISTORY + DEFERRED excluded |
| `docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG,STATUS}.md` | regenerated mirrors of the above (date-bearing) | HISTORY + DEFERRED excluded |
| `docs/reference/**` | developer-authored user docs (how-to / API ref) — not operating | all axes excluded (developer's own docs) |
| `**/*-IMPL-REPORT*.md`, completion reports | IMPL reports are history-homes per the rule | HISTORY + DEFERRED excluded |
| `_intro.md`, `_toc.md`, `HELP-FRAGMENT*.md` | orientation / generated index / help OUTPUT (mirror the pack EXEMPT set) | all axes excluded |
| `scripts/**`, `proto/**`, source code | scripts are EXEMPT per the BD-243 ruling ("historical/audit text MAY remain in script comments"); source is not an operating doc | all axes excluded |

**The stream-meta CONTRACTS (`_rules.md`/`_format.md`) are IN, but the stream ENTRIES are OUT.** The contract files are operating instruction (how to write an entry) and must stay terse + history-free; but `changelog/_format.md` legitimately SHOWS a `### YYYY-MM-DD` EXAMPLE — so the history axis over `_format.md` needs an allowlist record for the format-example date (the pack gate has the identical K9/K10 date-format records). This is the one place a date legitimately appears in an IN file → allowlisted, not excluded.

### B.3 Measure-then-bound discipline (the coder runs at CG-15)

Because the IN set is sized against the bloat-reduced + history-clean project-template, the coder MUST: (1) glob the IN families on the FINAL project-template (post CB-07/08/09 + CG-14); (2) run each axis's matcher over the IN set; (3) categorize every hit KEEP (→ allowlist or EXCLUDE) vs STRIP (→ the bloat/strip wave already removed it — so the residue at CG-15 should be near-zero KEEP-only); (4) size the allowlist EXACTLY to the KEEP set; (5) verify the gate runs CLEAN (exit 0) against the final project-template. Any unclassified hit = a BLOCKER surfaced to the user (never auto-allowlisted). This is the pack gate's measure-then-bound contract applied to the client surface.

**EE-CINSET — client IN/EXCLUDE family counts @ `103cca8`.**
- Cmd: `ls project-template/docs/pack/*.md` (5); `ls project-template/docs/pack/prompts/*.md` (10); `ls -d project-template/skills/*/` (37); `ls project-template/.claude/agents/*.md` (16), `.codex/agents/*.toml` (16), `.agents-plugin/optiquity-agents/agents/*.md` (16); `ls project-template/docs/project/*/_rules.md` (3) + `changelog/_format.md` (1); `ls project-template/docs/project/{backlog,implementation-plan,changelog}/` (each holds only `_intro/_rules` [+`_format`] at template — no authored entries yet).
- Output (verbatim, key): docs/pack 5 (HELP-FRAGMENT, OPTIONAL-FEATURES, PACK-FEEDBACK, PLATFORM-SKILLS, PM-CHAT); prompts 10; skills 37; agent-defs 16×3; stream-meta 3 `_rules` + 1 `_format`; the stream dirs hold ONLY the contract/orientation files at template (authored entries appear only after the client uses the project).
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: the template IN baseline ≈106 operating files; the streams are empty of entries at template (the client fills them — confirming they are history-HOMES the gate must EXCLUDE so client-authored dated entries never fail). The `changelog/_format.md` date-example is the one IN-file date needing an allowlist record.
- Conclusion: **SUPPORTED.**

---

## 4. SECTION C — WHERE IT SHIPS + HOW IT RUNS

### C.1 Ship location: `project-template/scripts/validate-docs.sh`

A project-side deliverable, joining the existing shipped validators. It ships AUTOMATICALLY via `stage_s5_scripts()` (which globs `project-template/scripts/*` — EE-CBASE), gets `chmod +x` at install, and needs NO install-map row (unlike `docs/pack/*` files). Naming follows the `validate-<thing>.sh` convention (`validate-proto.sh`/`validate-python.sh`/`validate-swift.sh`). `validate-docs.sh` is filename-unique in the repo (checked: no other `validate-docs.sh`).

### C.2 How it runs — two hooks, no shipped CI

**(1) Wired into `validate.sh` as an always-run, language-INDEPENDENT step.** Today `validate.sh` runs only language-matched validators. The docs gate is language-independent (it checks markdown operating docs, present in every project). Add it as an unconditional step that always runs:
```
# Always run (language-independent): operating-doc enforcement
echo "[validate] running validate-docs.sh (operating-doc enforcement)"
"$SCRIPT_DIR/validate-docs.sh" || EXIT_CODE=1
```
Placed before/after the language blocks; it sets `RAN_SOMETHING=1` so a docs-only repo (no Package.swift/pyproject/proto) still validates rather than printing "No project type detected." This is the client mirror of the pack's `validate-pack.py` being the top-level gate.

**(2) Wired into `agent-post-edit-check.sh` as a NEW `*.md` branch.** Today `.md` edits print "skipping build/lint" and do nothing — so PM Chat's operating-doc edits are un-checked per-edit. Replace the `*.md` arm so a markdown edit runs the docs gate ON THE EDITED FILE (a single-file fast path):
```
*.md)
  echo "[agent-post-edit-check] markdown edit ($EDITED_FILE) — running validate-docs.sh on it"
  "$ROOT_DIR/scripts/validate-docs.sh" "$EDITED_FILE" || status=$?
  ;;
*.txt|*.json|*.yaml|*.yml|*.toml)
  echo "[agent-post-edit-check] non-code file ($EDITED_FILE) — skipping build/lint"
  ;;
```
`validate-docs.sh` accepts an OPTIONAL single-file argument (per-edit fast path: gate only that file) and, with no argument, scans the full IN set (the validate.sh full-run path). This is the cheap per-edit enforcement that catches a bloated/historical edit AT WRITE TIME — the durable enforcement PM Chat lacks today.

**(3) NO shipped CI workflow.** The client has none today (only ISSUE_TEMPLATE). Shipping a CI workflow is OUT OF SCOPE for this gate: (a) the client's CI platform is unknown (GitHub Actions assumed but not guaranteed); (b) the two hooks (validate.sh pre-commit + agent-post-edit per-edit) give durable enforcement without a CI dependency; (c) adding a `.github/workflows/*.yml` is a larger surface (CI runner config, secrets, branch protection) that belongs to a separate "ship client CI" BD if the user wants it. DOCUMENT the invocation in the trinity Scripts table (a new `validate-docs.sh` row) + a one-line note that PM Chat / repo-ops runs it before commit. RECOMMEND: defer shipped-CI to a future BD; the two hooks satisfy the user's "same durable enforcement" ask.

### C.3 Pack-vs-client code-sharing — RE-IMPLEMENT (option i)

This is the load-bearing dependency-direction decision.

**Option (ii) — shared shippable lib — REJECTED.** A shared lib would live pack-side (e.g. `scripts/lib/doc-gate-core.sh`) and ship to clients. To ship, it MUST be in the frozen `_SANCTIONED_PACK_SIDE_SHIPPED` allowlist (Check 47, set-equality with the install-map pack-side subset, architect+user sign-off). Membership requires BOTH: (1) a pack op depends on it at runtime AND (2) a client surface invokes it. The doc-gate logic satisfies (2) — the shipped `validate-docs.sh` invokes it — but FAILS (1): `validate-pack.py` (the pack's gate) does NOT depend on a client-shippable doc-gate lib; it has its OWN richer Check-65/66/67/68 implementations in python. To force (1), the pack would have to make `validate-pack.py` `source`/`import` the shippable lib — inverting the dependency direction (a pack op depending on a client deliverable), which the dependency-direction rule forbids ("a project-side deliverable must NEVER be a runtime dependency of a pack operation"). The current sanctioned set is exactly `{scripts/lib/detect.sh, scripts/pack-help.sh}`; growing it for a lib that can't satisfy the contract is a misuse of the allowlist. **REJECT (ii).**

**Option (i) — re-implement in `validate-docs.sh` — ADOPTED.** The shipped gate carries its own self-contained axis logic (bash + a small embedded `python3`/`awk` pass for the regex matching — `python3` is already a client dependency via `validate-python.sh`). Simpler, rule-clean, no allowlist expansion, no boundary leak. The cost is DRIFT: the pack `validate-pack.py` and the shipped `validate-docs.sh` could diverge over pack versions.

**Drift mitigation (the (i) requirement):**
1. **Shared RULE-TEXT anchor.** Both gates enforce the SAME ONE rule (`operating-docs-no-history-no-bloat`), which lives in the trinity (SSOT). The gate's axes mirror the rule's clauses (history / deferred / bloat / + dangling as the referential-integrity corollary). When the rule changes, BOTH gates update — and the trinity rule is the single SSOT both read from. This is the conceptual anchor that keeps them aligned.
2. **A NEW pack-side parity check (validate-pack Check, +1 to the BD-243 gate count or a CG-15 addition).** A `check_client_doc_gate_parity` asserts the shipped `validate-docs.sh` exists, is executable in the template, declares each of the 4 axes (a structural grep for the axis-marker comments the gate carries, e.g. `# AXIS: history` / `# AXIS: deferred` / `# AXIS: bloat` / `# AXIS: dangling`), and is wired into the shipped `validate.sh` + `agent-post-edit-check.sh`. This catches the gate vanishing or losing an axis (the same anti-rot posture the durable pack gates have, applied to the client gate's PRESENCE). It does NOT re-implement the logic (no behavioral parity check — that would be a maintenance trap); it asserts STRUCTURAL parity (the gate ships, runs, and covers all axes).
3. **Pack-version maintenance note.** The shipped gate is pack-version-updated (like the other shipped scripts) — when a pack version refines the rule, the same version refines `validate-docs.sh`. The parity check makes a missed refinement a loud pack-CI failure.

### C.4 Runtime cost (ci-check-runtime-compounding)

- **Per-edit path (`validate-docs.sh <file>`):** scans ONE file — 4 regex passes over one markdown doc + an allowlist lookup. Milliseconds. Runs on every `.md` agent edit; trivial.
- **Full path (`validate-docs.sh`, via `validate.sh`):** scans the ~106-file IN set (the client's installed operating docs minus the excluded streams) — 4 regex passes per file + a once-built basename index for the dangling axis. Bounded to the IN set, never the whole tree, never a subprocess-per-file storm (one `python3`/`awk` pass over the file list). Runs at pre-commit / repo-ops validation, not per-CI-invocation × 155 (there is no shipped CI). Cheap by construction.
- The dangling axis builds the client basename index ONCE per run (mirror the pack Check-40 index-reuse). No per-ref `find` subprocess.

---

## 5. SECTION D — THE CLIENT ALLOWLIST + BOUNDARY DISCIPLINE

### D.1 The client allowlist (project-audience KEEPs, measure-then-bound)

A client-self-contained allowlist file **`scripts/.docs-gate-allowlist.txt`** (shipped with `validate-docs.sh`; same `(doc, pattern, snippet, reason)` record shape the pack uses, so PM Chat / repo-ops can add a record when a legitimate KEEP appears). The client may extend it; the shipped baseline is sized to the project-template KEEPs:

| KEEP category | Example | Mechanism |
|---|---|---|
| Rule self-reference | trinity "ZERO description of a DEFERRED ... feature" / "incident or commit-SHA refs" | `(trinity, deferred|incident, <snippet>, rule-self-ref)` — the rule naming what it forbids |
| Live TD-deferral workflow | coder agent-def "Deferred items"; CLAUDE.md "Deferral comments and BACKLOG hygiene" `TD-TBD`; "Deferral IS scope creep" | `(agent-def/CLAUDE, deferred, <snippet>, live-workflow)` |
| Generic client-product advice | `api-design` skill "remove in a future version" (the client's OWN API) | `(skill, future, <snippet>, product-advice)` |
| Format-example date | `changelog/_format.md` `### YYYY-MM-DD — Phase N` | `(_format.md, date, YYYY-MM-DD, format-example)` |
| Dangling project-grammar | `TD-NNN.md`, `phase-N.md`, `x-<name>`, `[PROJECT_NAME]` | grammar-pattern records (no existence check) |
| Irreducible bloat enumeration | denied-git-verb list; deletion-rules `.nullify/.cascade/...` | bullet-cap allowlist with `reason:` |

**The history-homes are handled by IN-set EXCLUSION, not allowlist** (D.2 / §B.2) — a whole-tree exclude, because EVERY stream entry legitimately carries dates; line-by-line allowlisting would be unbounded. This is the elegant measure-then-bound move: exclude the home, allowlist only the rare in-IN-file legitimate date (the `_format.md` example).

The allowlist is sized EXACTLY at CG-15 to the measured KEEP set on the final project-template; the residue should be small (the bloat/strip waves already removed the STRIP-class). Any unclassified hit = BLOCKER to the user (no widen-to-admit).

### D.2 Boundary discipline (P-missed-7 — CRITICAL; this IS a client deliverable)

The shipped gate + its config must reference ZERO pack-internal mechanism. Verified by construction:

- **No `pack-ops/` / `validate-pack.py` / `maintenance-docs/` references.** The gate is self-contained in `scripts/validate-docs.sh` + `scripts/.docs-gate-allowlist.txt`; it reads ONLY the client tree.
- **No `BD-NNN`.** The history axis uses `TD-` (project vocabulary), not `BD-`. The deferred axis drops `v11.x` (pack tokens). The dangling axis allowlists project grammar (`TD-NNN`/`phase-N`), not pack grammar (`BD-NNN`/`migrate-vN-to-vM`).
- **No "Pack Chat" / pack-orchestrator role.** The gate's messages reference "PM Chat" / "repo-ops" / "the developer" (project-side roles), never Pack Chat. Its remediation message says "STRIP the historical/deferred text OR, if this is a rule self-reference / live TD-deferral workflow / generic product advice, add a `scripts/.docs-gate-allowlist.txt` record with a `reason:`" — all project-side vocabulary.
- **Project SSOT-first (the project trinity's own rule).** The gate enforces the rule that already lives in the project trinity (the project SSOT), reading the project streams' `_rules.md` contracts for the history-home declaration — it does not import any pack SSOT.

**Verification (EE-CBOUND):** the design introduces these client-surface artifacts: `project-template/scripts/validate-docs.sh`, `project-template/scripts/.docs-gate-allowlist.txt`, the validate.sh + agent-post-edit-check.sh wiring, and a new trinity Scripts-table row. NONE references a pack-internal path/token. The ONLY pack-side artifact is the OPTIONAL parity check (`check_client_doc_gate_parity` in `validate-pack.py`) — which lives PACK-SIDE (correct: it polices the deliverable from the pack, the legitimate dependency direction: pack op reads client deliverable for verification, never the reverse) and ships NOTHING.

**EE-CBOUND — no pack-internal reference in the shipped surface @ `103cca8` (projected).**
- Cmd (design-time projection — the artifacts do not exist yet, so this is the CONTRACT the coder verifies post-implementation): the coder runs `grep -nE "pack-ops|validate-pack|maintenance-docs|BD-[0-9]|Pack Chat|PACK-AGENTS|PACK-CHAT" project-template/scripts/validate-docs.sh project-template/scripts/.docs-gate-allowlist.txt` and expects grep-ZERO (the boundary-discipline gate on the deliverable). The existing project-side leak guard (pack Check 43) ALSO covers the shipped scripts at ship time as a backstop.
- Output (verbatim, projected): grep-zero is the acceptance criterion; any hit = BLOCKER.
- HEAD/date: `103cca8` / 2026-06-22 (projection; verified at CG-15 implementation).
- Interpretation: the gate is designed self-contained; the grep-zero is the coder's PREFLIGHT proof + the reviewer's check. The pack-side parity check is the only pack artifact and it lives pack-side (no leak).
- Conclusion: **SUPPORTED — the design introduces no pack-internal reference into the shipped surface; the grep-zero contract enforces it at implementation.**

---

## 6. SECTION E — PLAN IMPACT / INSERTION (the planner sequences V4)

The client gate is a `project-only` shipped deliverable. Its measure-then-bound baseline is the bloat-reduced + history-clean project-template — so it depends on the project-template deliverables being clean FIRST.

### E.1 Dependency-correct position: a new `project-only` commit CG-15, AFTER the gate wave

- **Depends on CB-07 + CB-08 + CB-09** (the project-template bloat/strip wave — they make the project-template operating docs bloat-clean + history-clean + deferred-clean, incl. the D-1 PLATFORM-SKILLS strip). The client gate's allowlist is sized to the REDUCED docs; sizing it against the un-reduced docs would over-grow the allowlist.
- **Depends on CG-14** (the pack gate activation) ONLY IF the OPTIONAL pack-side parity check (`check_client_doc_gate_parity`, §C.3) is included — that check is a new validate-pack check and its count bump must coordinate with CG-14's 63→67 bump. TWO clean options: (a) FOLD the parity check into CG-14's count bump (63→**68**, +5 instead of +4) so there is ONE atomic count event; or (b) land it at CG-15 as its own +1 (63→67 at CG-14, then 67→68 at CG-15). RECOMMEND (a) — one atomic count bump is the lower-risk path the V3 plan already argues for (§6.3 registration-deferral); the parity check is authored at CG-14-prep-b alongside the other gate bodies and registered atomically at CG-14. Under (a), CG-15 is purely `project-only` (the shipped gate) with NO pack-count impact.
- **Position:** CG-15 lands AFTER CG-14 (so the parity check, if folded at CG-14, is already live to verify CG-15's deliverable). The full sequence becomes:
```
CB-01 .. CB-09        (bloat wave; CB-07/08/09 clean the project-template)
   │
CG-14-prep-a/-b       (pack gate bodies + allowlists + Gate-1 params; + the OPTIONAL parity-check body)
   │
CG-14                 (pack gate activation; atomic count bump 63→67 [or →68 if parity folded])
   │
CG-15 (project-only)  (ship validate-docs.sh + .docs-gate-allowlist.txt + validate.sh/agent-post-edit wiring
                       + trinity Scripts-table row; allowlist sized to the final clean project-template)
   │
final push            (manifest-sync if a fixture input changed → push → CI watch)
```

### E.2 New shipped-file → check coupling (enumerate-encoding-surfaces)

Shipping `validate-docs.sh` + its allowlist couples these surfaces — the planner/coder move them in lock-step at CG-15:

| Surface | Action at CG-15 | Why |
|---|---|---|
| `project-template/scripts/validate-docs.sh` | NEW (the gate) | the deliverable |
| `project-template/scripts/.docs-gate-allowlist.txt` | NEW (the allowlist) | the gate's KEEP set |
| `project-template/scripts/validate.sh` | EDIT (add always-run docs step + RAN_SOMETHING=1) | wire the full-run path |
| `project-template/scripts/agent-post-edit-check.sh` | EDIT (`*.md` branch runs the gate on the edited file) | wire the per-edit path |
| `project-template/{CLAUDE,AGENTS,GEMINI}.md` Scripts table | EDIT ×3 (add a `validate-docs.sh` row) — trinity-locked | document the new script; trinity parity |
| `scripts/init-project.sh` | NO EDIT — `stage_s5_scripts()` globs `scripts/*` (auto-ships); `chmod +x` already covers `*.sh` | EE-CBASE confirms auto-ship |
| install-map | NO ROW — scripts ship by glob, not by install-map (unlike `docs/pack/*`) | EE-CBASE |
| `test-fixtures/manifest.txt` + fixtures | REBUILD via `build.sh` (the fixtures stage project-template/scripts → the new file appears in v10/v11 fixtures); manifest re-SHAs at push-time per the manifest-sync rule | a new shipped script changes the fixture content hash; Check 62 / build.sh --verify enforce |
| `scripts/validate-pack.py` Check 65 IN set | VERIFY — the pack gate's Check-65 IN set scans project-template deliverables; the NEW shipped `validate-docs.sh` is a SCRIPT (EXEMPT from operating-doc scan per the BD-243 script-exempt ruling) and `.docs-gate-allowlist.txt` is a config (not an operating doc) — neither enters the pack IN set | confirm no pack-gate false-positive on the new files |
| `scripts/validate-pack.py` `check_client_doc_gate_parity` (OPTIONAL) | NEW pack check (authored CG-14-prep-b, registered CG-14 if folded) | drift mitigation (§C.3) |
| pack-side per-check test for the parity check | NEW `test-validate-pack-check-NN.sh` (DYNAMIC count form) IF the parity check is added | test the new pack check |
| a shipped test for `validate-docs.sh`? | OPTIONAL — the client has no shipped test harness for scripts today (no `test-validate-*.sh` in project-template/scripts); a self-test could ship but adds surface. RECOMMEND a `--self-test` flag in `validate-docs.sh` (a tiny synthetic PASS/FAIL the developer can run) over a separate shipped test file (fewer files) | design-elegance (fewer files) |

### E.3 Fixture / manifest impact (the one non-trivial coupling)

A new `project-template/scripts/validate-docs.sh` + `.docs-gate-allowlist.txt` changes what `stage_s5_scripts()` stages → the install fixtures (`v10-minimal`, `v11-flat-file`, `v11-realistic-ot`, etc.) gain the new files → their content SHAs change → `test-fixtures/manifest.txt` must re-SHA. Per the push-time manifest rule (`regenerate-manifest-v11-surface`), this is done by `scripts/manifest-sync.sh` at push (NOT per-commit), and CI `build.sh --verify` + Check 62 enforce it. The planner flags CG-15 as a "fixture-input-changing" commit so the push-time manifest-sync expects the regeneration. This is the only manifest coupling.

### E.4 What I do NOT change (scope-deliverables-to-the-ask)

I design the client gate + its insertion. I do NOT re-design the pack gates (`DESIGN-BD-243-DURABLE-GATES.md`, approved), the bloat method (`DESIGN-BD-243-BLOAT-METHOD.md`, approved), or re-sequence CB-01..CB-09 / CG-14 (the V3 plan stands). The planner owns the V4 worktree-wave schedule for CG-15.

---

## 7. OPEN DECISIONS FOR THE USER

- **DC-1 (the central one) — RE-IMPLEMENT vs shared lib.** RECOMMEND RE-IMPLEMENT (option i) — the dependency-direction rule + Check-47 contract make a shared lib infeasible (it can't satisfy "a pack op depends on it at runtime"). Drift is mitigated by the shared rule-text anchor + the pack-side parity check. The user confirms (i).
- **DC-2 — ship the pack-side parity check?** RECOMMEND YES (it gives the client gate the same anti-rot presence-guarantee the pack gates have) and FOLD its count bump into CG-14 (63→68, one atomic event). If the user wants minimal pack-check growth, OMIT it and rely on the shared rule-text anchor + pack-version maintenance discipline (weaker but fewer checks). The user decides.
- **DC-3 — shipped CI workflow?** RECOMMEND NO (the two hooks suffice; the client's CI platform is unknown; a shipped CI workflow is a larger separate surface). If the user wants client CI, it is a separate future BD. The user decides whether the two hooks satisfy "same durable enforcement."
- **DC-4 — bloat axis scope.** RECOMMEND per-bullet char-cap as PRIMARY (the mega-bullet axis) + an OPTIONAL single per-doc cap over trinity + docs/pack. The user decides whether to include the doc-cap (more coverage) or bullet-cap-only (simpler).
- **DC-5 — Gate-4 (new-doc meta-check) client-side.** RECOMMEND OMIT (the client surface is small + stable; a 5th axis adds maintenance cost against design-elegance). The user decides if the belt-and-suspenders coverage is wanted.
- **DC-6 — shipped self-test.** RECOMMEND a `--self-test` flag in `validate-docs.sh` over a separate shipped test file (fewer files). The user decides.

---

## 8. EMPIRICAL-EVIDENCE BLOCK (consolidated)

All measurements @ HEAD `103cca8` (`103cca8e51feef9c80e4e76be17bd0dd274d3a6b`), branch `v11-dev`, 2026-06-22, repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, clean tree. Graph queried FIRST for discovery (`graphify query "what consumes validate.sh ... operating vs history-store" --graph .../graphify-out/graph.json --backend claude-cli --budget 2000`) → returned only PACK-MEMORY-RATIONALE rule-rationale + tracker-fixture nodes (STALE for the client-validator surface) → G2 fallback to grep/Read IMMEDIATELY. The client IN-set + the sharing decision are grep/Read-authoritative.

- **EE-CBASE** (§1) — client script surface (18, no validate-docs.sh); validate.sh runs only language-matched validators (no language-independent step); agent-post-edit-check SKIPS `*.md`; `.github/` = ISSUE_TEMPLATE only (no workflows); `stage_s5_scripts()` globs `scripts/*` (auto-ship + chmod); manifest `project-template` count 0. SUPPORTED.
- **EE-CRULE** (§1) — the rule lives in all 3 project trinity files (CLAUDE:242 / AGENTS:226 / GEMINI:239); names the 3 axes + declares the streams + IMPL reports as history-homes. SUPPORTED.
- **EE-CHIST** (§1) — changelog `_format.md` mandates `### YYYY-MM-DD` + "deferred with logging" narrative; changelog `_rules.md` "append-only-historical"; the streams legitimately carry dates → gating them is a defect → EXCLUDE them. SUPPORTED.
- **EE-CINSET** (§3) — client IN baseline ≈106 operating files (trinity 3 + docs/pack 4 + prompts 10 + skills 37 + agent-defs 48 + stream-meta 4); the stream dirs hold only contract/orientation files at template (entries are client-authored → history-homes). SUPPORTED.
- **EE-CBOUND** (§5) — the projected shipped artifacts (validate-docs.sh + .docs-gate-allowlist.txt + wiring + trinity row) carry NO pack-internal reference; the grep-zero `grep -nE "pack-ops|validate-pack|maintenance-docs|BD-[0-9]|Pack Chat|..."` over the shipped surface is the coder's PREFLIGHT + reviewer acceptance gate; the only pack artifact (the parity check) lives pack-side. SUPPORTED (projection; verified at CG-15).

---

## 9. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Only read-only verbs ran: `git rev-parse HEAD`/`git branch --show-current`/`git status` (snapshot), `ls`, `grep`, `sed`, `head`, `cat` (reads), `graphify query` (read-only), Read tool. Sole write = this design doc via `cat >` to the caller-specified `/tmp/pack-handoff-bd243-arch/DESIGN-BD-243-CLIENT-GATE.md`. No repo-file edit; no patch; no `git add`/`commit`/`apply`/state-changing verb. | COMPLIANT |
| **reconciliation-instance-independence** | FRESH architect; did NOT author any prior BD-243 artifact. Reached own conclusions: the RE-IMPLEMENT (option i) decision with the dependency-direction + Check-47 reasoning (§C.3, my synthesis); the history-home IN-set EXCLUSION (not allowlist) as the elegant measure-then-bound move (§B.2/§D.1); the two-hook wiring + the OMIT-meta-check + OMIT-shipped-CI recommendations; independently re-measured EE-CBASE/CRULE/CHIST/CINSET. | COMPLIANT |
| **dependency-direction-placement** | THE central decision: `validate-docs.sh` defaults project-side (`project-template/scripts/`, EE-CBASE); option (ii) shared lib REJECTED because it can't satisfy "a pack op depends on it at runtime" without inverting the dependency direction (pack op → client deliverable, forbidden); the pack-side parity check reads the client deliverable for VERIFICATION (legitimate pack→client read direction, never the reverse); the frozen `_SANCTIONED_PACK_SIDE_SHIPPED = {detect.sh, pack-help.sh}` quoted, not grown. | COMPLIANT |
| **boundary-investigation / P-missed-7** | This IS a client deliverable. Investigated the project SSOT FIRST (project trinity rule EE-CRULE; the streams' `_rules.md`/`_format.md` history-home declaration EE-CHIST). The shipped gate references NO pack mechanism: `BD-`→`TD-`, dropped `v11.x`, project grammar not pack grammar, "PM Chat/repo-ops" not "Pack Chat"; EE-CBOUND grep-zero contract over the shipped surface. The only pack artifact (parity check) lives pack-side. | COMPLIANT |
| **ci-guard design — measure-then-bound** | The client IN set measured (EE-CINSET ≈106); EXCLUDE set categorized (history-homes + reference + IMPL + scripts/source); allowlist sized to the project-audience KEEP categories (§D.1, 6 categories) with the history-homes handled by EXCLUSION not unbounded line-allowlisting; the gate is verified CLEAN against the FINAL bloat-reduced project-template at CG-15 (§B.3); any unclassified hit = BLOCKER, no widen-to-admit. | COMPLIANT |
| **ci-check-runtime-compounding** | Cost stated (§C.4): per-edit path = 1 file × 4 regex passes (ms); full path = ~106-file IN set, one python3/awk pass + a once-built basename index, bounded to the IN set never the whole tree, no per-file subprocess storm; runs at pre-commit/per-edit (no shipped CI × 155). | COMPLIANT |
| **enumerate-encoding-surfaces** | §E.2 enumerates every coupled surface at CG-15: the gate + allowlist (new) + validate.sh + agent-post-edit-check + trinity ×3 Scripts row + NO init-map row (auto-ship) + NO install-map + fixture/manifest rebuild + the optional pack parity check + its test + the self-test decision; moved in lock-step. | COMPLIANT |
| **user prescriptive authority** | The user mandated shipping the client gate for dual-surface parity; encoded, not relitigated — the design ASSUMES the gate ships and focuses on HOW (axes/IN-set/wiring/sharing). Open choices surfaced (§7 DC-1..DC-6) rather than self-decided. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Delivered the client gate (axes A / IN set B / ship+run+sharing C / allowlist+boundary D / insertion E) + the insertion recommendation. Did NOT re-design the pack gates or the bloat method (approved) nor re-sequence CB-01..CB-09/CG-14 (V3 stands). | COMPLIANT |
| **graph-first-context** | Discovery: graph queried FIRST via the injected absolute path (`--graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 2000`); returned STALE rule-rationale/fixture nodes for the client-validator surface → G2 fallback to grep/Read IMMEDIATELY. Authoritative measurements via grep/sed/Read over the named client surfaces. Did not recompute the graph path from own toplevel. | COMPLIANT |
| **rules-applied-verification-block** | This table — every rule in the prompt's Rules-in-force block has measured/quoted evidence + a terminal COMPLIANT conclusion (no empty evidence; no AMBIGUOUS). | COMPLIANT |

**END — DESIGN-BD-243-CLIENT-GATE.md**
