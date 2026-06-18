# PLAN-BD-225-GRAPHIFY-PACK-INTEGRATION

**Implementation plan — the HOW for BD-225, derived purely from the APPROVED design.**
This plan OVERWRITES (supersedes, no mirror) the prior `PLAN-BD-225-*`. The single source of truth is
`maintenance-docs/v11-implementation/DESIGN-BD-225-GRAPHIFY-PACK-INTEGRATION.md` (committed `5f56a35`).
This plan does NOT re-open any design decision; it sequences the design's locked artifacts into commits,
names each commit's files + change + rationale + per-commit verification, and surfaces
implementation-level risks only.

- **Author role:** pack-planner (fresh; read-only except this plan doc, written via Bash heredoc).
- **Date:** 2026-06-18 · **HEAD SHA:** `5f56a35dea0d7bde3777ce8ff27f864e5819b01a` · **branch:** `v11-dev`.
- **Target binary:** `graphify 0.8.39` (commands per design §3 table — do NOT re-derive or alter flags).
- **Boundary (absolute, governs every commit):** PACK-OPS ONLY. The graph MAY index the whole repo
  (incl. `project-template/`) for agent context, but EVERY committed setup artifact is PACK-SIDE; the
  graph-first rule lives in the PACK-ROOT trinity, NEVER `project-template/`; nothing ships to clients.
  Verified clean at HEAD: `git grep -in graphify -- 'project-template/'` → 0 rows (EB-1).

> **Re-measurement note.** The design recorded its evidence at HEAD `0a90f56`; this plan re-measured
> every state-claim at the CURRENT HEAD `5f56a35` (the design's own commit). All design facts re-verify
> identically (registry 60/count 60/55 distinct/max 62; bijection 22↔22; README "48 invoked checks" ×2;
> 3 LIVE + 4 archive + `??`-snapshot dangling-ref census; `.gitignore` clean; boundary clean). No
> design-vs-reality conflict found. The §12 Empirical-Evidence Blocks carry the re-measured commands.

> **Read order.** §A scope + invariants the plan obeys · §B the commit sequence (the spine) · §C the
> per-commit file-by-file detail + verification · §D the one-time INITIAL BUILD runbook (post-merge,
> not a commit) · §E governance (S-2 propagation MINUS the dropped MEMORY.md step) · §F verification
> strategy (full CI battery per commit) · §G implementation risks/notes · §12 Empirical-Evidence
> Blocks · §13 Rules-Applied Verification Block.

---

## Revision log (this is a TARGETED revision of the prior PLAN — only these fixes applied)

This plan revision applies EXACTLY the fix-list from `PLAN-BD-225-ADVERSARIAL-REVIEW.md` (VERDICT:
SOUND-WITH-FIXES, 0 BLOCKERs). The 5-commit structure, the B-1 same-commit bijection (C3 +
`--only-check 45`), M-3 (`GRAPHIFY_FORCE` on `update` only), G1–G3, the Check 63 lockstep, the
`.graphifyignore` content, `--backend claude-cli` / no-`--no-viz`-on-`extract`, and NO-MEMORY.md are
ALL UNCHANGED. The changes, each tagged so the diff is auditable:

- **M-1 = (b) LEAVE ARCHIVE FROZEN (user-locked) — UNCHANGED disposition.** C5 fixes ONLY the 3 LIVE
  forward-pointing refs; the archive-file refs + the `??`-snapshot mentions are DELIBERATELY LEFT
  UNTOUCHED as frozen archive. No archive-ref fixes were added.
- **SHOULD-1 — archive-ref CHARACTERIZATION corrected (NOT the disposition).** Re-measured the census:
  of the 4 archive files, TWO (`ARCHITECTURE-PER-ENTRY-FLAT-FILES.md`,
  `PACK-REVIEW-ARCHITECTURE-PER-ENTRY.md`) carry LIVE PROSE refs (0 `??`-snapshot lines), and TWO
  (`IMPLEMENTATION-REPORT-BD-146.md`, `IMPLEMENTATION-REPORT-BD-149.md`) carry `??`-snapshot lines. The
  prior plan wrongly lumped all 4 as "the same `??`-snapshot pattern." Corrected the "Left UNTOUCHED"
  wording, EB-13, and the §9.3/C5 completeness-gate allow-set so it precisely enumerates the
  deliberately-frozen set (2 live-prose archive files + 2 `??`-snapshot archive files + 3 `??`-snapshot
  live-tree files + the BD-225 self-refs) and won't false-flag. The "leave frozen" disposition rests on
  the FROZEN-ARCHIVE ground (which covers all 4) — UNCHANGED.
- **MUST-1 — README "invoked checks" fix made COMPLETE.** The prior plan bumped the headline (48→56) and
  said "extend the enumeration to …63," but left the STALE PARENTHETICAL ranges/sub-counts → a
  self-contradictory README. Re-measured the registry; both README instances now get the FULL
  parenthetical rewritten to the measured set — headline **56**, sub-count consistent, ranges
  **Check 1–11, 16–20, 22–23, 25–27, 29–63** (actual gaps: 12–15, 21, 24, 28). Offered the
  collapse-to-SoT alternative. Both instances internally consistent post-Check-63.
- **SHOULD-2 — C2 manifest clarity.** Made explicit that the manifest-INPUT change is introduced in
  **C2** (the `scripts/validate-pack.py` edit), so the C2 push triggers `manifest-sync.sh` (push-time,
  BD-228); `graphify-out/` is never a fixture input.
- **SHOULD-3 — C3 governance NOT over-gated.** The "does PACK-AGENTS.md need a parallel touch" question
  is STATE-VERIFIABLE (Check 46 requires no record for a rule with no collapsed restatement — confirmed
  EB-9), not a user decision. The plan now ADOPTS the design's PACK-AGENTS.md-no-touch assertion and
  does NOT gate C3 on a user reply (surfaced for awareness, via the standard planner→coder gate).
- **NIT-2 — `REVIEW-BD-096.md` is NOT a dangling ref.** Its "graphify" hit (line 38) is a verbatim
  commit-log subject, not a forward-pointing reference; it is NOT counted in the census or the fix set.
- **NIT-1 ("41 suites" README staleness) — OUT OF SCOPE; left untouched** (not graphify-related; Check
  63 did not worsen it).

> **Design §9 flag (assess, do NOT edit — separate orchestrator/user decision).** The committed DESIGN
> §9.2(b) line 603 carries the SAME mischaracterization the plan had — it calls `IMPLEMENTATION-REPORT-
> BD-149.md` "the same `??`-snapshot pattern" and groups all FOUR archive files under category (b) as
> "frozen historical snapshots," when 2 of the 4 carry LIVE PROSE refs. **Assessment: MATERIAL-BUT-MINOR
> (evidence-accuracy), leaning COSMETIC** — the design's DISPOSITION (leave all 4 frozen) is correct and
> survives on the frozen-archive ground it also states; only the §9.2/EE-17 *characterization* is
> inaccurate for 2 of 4 files. It is SUPERSEDED in practice by this plan's now-accurate completeness gate
> (the artifact a coder/reviewer follows). A small design correction would tighten §9.2/EE-17 to the
> 2-prose + 2-snapshot split, but it changes no locked decision and blocks nothing. Flagged for the
> orchestrator/user; this plan does NOT edit the committed design.

---

## §A. Scope, invariants, and what this plan does NOT touch

### A.1 The two locked invariants every commit obeys (design §1)
1. **Backend = `--backend claude-cli` ONLY** (design §1.1 / S-3, HARD). Every `extract` invocation the
   plan prescribes pins `--backend claude-cli` literally. The top-level `--help` enum OMITS `claude-cli`
   (it lists `gemini|kimi|claude|openai|deepseek|ollama`) but `claude-cli` IS valid (surfaced by the
   invalid-backend error) and is the NO-KEY subscription path. `--backend claude` (the listed value)
   demands `ANTHROPIC_API_KEY`. **A coder who "fixes" `claude-cli` → `claude` to match the help breaks
   the no-key guarantee — the single highest-consequence substitution error.** Every runbook line that
   shows `extract` carries this one-line caveat.
2. **The graph is a per-clone, gitignored, manual OPT-IN** (design §1.2 / D6). The graph
   (`graphify-out/`), the `.git/hooks/post-commit` hook, and the initial build are NEVER committed,
   NEVER synced; they are per-clone manual installs. The COMMITTED artifacts are ONLY: `.graphifyignore`,
   the `.gitignore` entry, the trinity rule + its rationale section, the CI guard (Check 63 + test), and
   the runbook prose in `OPTIONAL-FEATURES.md`. The integration is BOTH opt-in AND graceful-on-failure
   (G1 existence guard + G2 query-failure fallback + G3 guarded/non-blocking hook — design §2).

### A.2 Flag discipline (design §3 table — use VERBATIM; never invent/alter)
- `--no-viz` is ONLY on the initial interactive `/graphify .` build (a build/skill flag). It is **NOT a
  flag of `extract`** (M-2) — passing it to `extract` is an unknown-option error. NEVER add `--no-viz`
  to any `extract` line.
- `--backend claude-cli` is pinned literally on every `extract`; NEVER `claude`.
- `--graph` is ALWAYS an absolute path: `$(git rev-parse --show-toplevel)/graphify-out/graph.json`.
- `GRAPHIFY_FORCE=1` binds to the **`update`** branch only (M-3, source-verified: `update` reads it,
  `extract` does not and prunes removals natively via `prune_sources`).
- `--budget`: 2000 human/interactive · 1500 spawned agent · 1000 Pack-Chat prompt-construction.
- Build knobs at the locked Core values: `--no-viz` ON + clustering ON on the initial build;
  `GRAPHIFY_CLAUDE_CLI_PARALLEL=0` (serial) for `extract`; `GRAPHIFY_NO_BACKUP` left at default 0.

### A.3 Surfaces this plan does NOT touch (design §10.2 — with reasons)
- `supporting-docs/DEPENDENCIES.md` — CLIENT-facing deliverable; graphify is pack-dev-only; recording it
  there is a boundary leak. The pack-dev home is `pack-ops/OPTIONAL-FEATURES.md`. **NOT edited.**
- `pack-ops/.spawn-rule-manifest.txt` (Check 46) + `pack-ops/PACK-AGENTS.md` — the new `### Repo
  conventions` graph-first rule has NO collapsed restatement in PACK-AGENTS.md/PACK-CHAT.md, so it needs
  NO manifest record and NO reference-surface touch (Check 46 iterates the records PRESENT, not every
  corpus slug — EB-9). This is STATE-VERIFIABLE (SHOULD-3): the plan ADOPTS the no-touch conclusion;
  it is NOT a C3 user-gate. **NOT edited.**
- `pack-ops/PACK-CHAT.md` propagation procedure — its Step 3 (out-of-repo memory-cache pointer) is the
  MEMORY.md step; it contradicts the HARD NO-MEMORY.md directive. This plan does NOT patch PACK-CHAT.md
  and FLAGS the contradiction for **BD-232** (design §11). **NOT edited.**
- The out-of-repo **MEMORY.md** cache — **ZERO addition anywhere** (HARD directive, design §11). The
  rule lives ONLY in the in-repo corpus (trinity `## Pack memory` + `## graph-first-context` in
  `PACK-MEMORY-RATIONALE.md`).
- `test-fixtures/manifest.txt` — reconciled at PUSH by `scripts/manifest-sync.sh` (BD-228), NOT a
  per-commit step. `scripts/validate-pack.py` IS a fixture input (matches `scripts/*`, not in the deny
  set — EB-10) and is edited in **C2** (SHOULD-2), so the eventual push (after C2 has landed) triggers
  `manifest-sync.sh` (expect exit 10 → the orchestrator commits the regenerated manifest with user
  approval). The new test `scripts/tests/test-validate-pack-check-63.sh` is denied (under
  `scripts/tests/*`) → NOT a fixture input. `graphify-out/` is never a fixture input (gitignored build
  artifact).
- `README.md` "aggregate CI test runner across 41 suites" (line 60) — a SEPARATE pre-existing staleness
  (NIT-1: disk has 64 suites). It is NOT graphify-related, Check 63 did not worsen it, and it is OUT OF
  BD-225 SCOPE. C2 edits the SAME line for the "invoked checks" count, so the coder WILL see it — do NOT
  fold it in (no silent "while I'm here" fix). **NOT edited under BD-225.**
- `project-template/` (any file) — boundary (P-missed-7); the rule is pack-root trinity only.

---

## §B. The commit sequence (the spine)

**Five commits**, each leaving the pack in a working state (validate-pack green + full battery green at
every step). All five are `pack-only` scope (CI Check 36): every touched path is outside
`project-template/` and `supporting-docs/`. Order is chosen so (a) the B-1 bijection NEVER sees a
half-applied state (trinity tag + rationale section land together), (b) the Check-63 lockstep (validator
+ registry + count + test + README) lands as one self-contained unit, and (c) the destructive deletion
(C5) lands LAST so the dangling-ref fixes and deletion are one reviewable change.

| # | Commit subject (proposed) | Files | Why this slice / why this order | Destructive? |
|---|---|---|---|---|
| C1 | `feat: v11 — BD-225 .graphifyignore + .gitignore graphify-out (pack-only)` | `.graphifyignore` (NEW), `.gitignore` (append) | The git-hygiene foundation. Self-contained; no dependency on later commits. Lands first so the ignore-list + gitignore entry exist before the CI guard that pairs with them. | no |
| C2 | `feat: v11 — BD-225 Check 63 graphify-out never-tracked guard (pack-only)` | `scripts/validate-pack.py` (Check 63 fn + registry entry + count 60→61 + comment), `scripts/tests/test-validate-pack-check-63.sh` (NEW), `README.md` (×2 "invoked checks") | The four-surface (+README) lockstep, one atomic unit (enumerate-encoding-surfaces). Pairs with C1's `.gitignore` entry (the guard enforces what C1 declares). Independent of the trinity work. **`validate-pack.py` is a fixture input → this is the manifest-input-changing commit (SHOULD-2); push triggers manifest-sync (orchestrator, push-time).** | no |
| C3 | `feat: v11 — BD-225 graph-first trinity rule + rationale section (pack-only)` | `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (trinity bullet + tag), `pack-ops/PACK-MEMORY-RATIONALE.md` (NEW `## graph-first-context` section) | The B-1 BIJECTION commit: the `[rationale: graph-first-context]` tag and the matching `## graph-first-context` rationale section MUST land in the SAME commit or Check 45 fails CI-RED (orphan corpus slug). Trinity-parity (Checks 16/18/19) + bijection (Check 45) both satisfied in one commit. **Verification MUST include `--only-check 45`** (bijection 22↔22 → 23↔23). PACK-AGENTS.md needs NO parallel touch (SHOULD-3, EB-9). | no |
| C4 | `feat: v11 — BD-225 OPTIONAL-FEATURES graphify runbook + hook (pack-only)` | `pack-ops/OPTIONAL-FEATURES.md` (NEW `## Graphify` section) | The runbook prose: D3 privacy/secrets, the D4/D5 guarded post-commit hook template (per-clone manual install, NOT a committed file), the §7.4 initial-build runbook, the §1.1 `claude-cli` caveat. Depends conceptually on C1–C3 being in place (the runbook references the `.graphifyignore`, the gitignored `graphify-out/`, and the graph-first rule) but has no file-level dependency. | no |
| C5 | `feat: v11 — BD-225 delete stale graphify research docs + fix dangling refs (pack-only)` | DELETE 3 docs (orchestrator-executed), `RESEARCH-CLAUDE-REPOS-SURVEY.md`, `TOUCH-POINT-INVENTORY-GROUPINGS-V2.md`, `V11.1-DISCUSSION-GITHUB-PROJECTS.md` (3 LIVE ref fixes) | The fail-loud cleanup, LAST so the deletion + all dangling-ref fixes are one reviewable change with a zero-dangling completeness gate. The deletion is a DESTRUCTIVE op: the coder surfaces the 3 paths in its IMPL-REPORT; the ORCHESTRATOR runs the deletion with explicit user approval at commit time. | **yes** (3 deletions) |

**Dependency graph:** C1 → C2 (guard enforces gitignore entry); C3 self-contained (bijection atomic);
C4 references C1–C3 conceptually; C5 self-contained (delete + ref fixes). C1/C3/C5 have no hard
inter-dependency and could in principle reorder, but the listed order keeps each commit's verification
clean and groups the destructive op last. **Batch status flip** (`backlog/BD-225.md` Open→Resolved +
regenerate `backlog/_toc.md`) is Pack-Chat-direct bookkeeping at batch completion — NOT a coder commit;
it rides on the implicit-status-flip-on-batch-completion rule after the full battery is green.

**Per-BD review/fix cycle:** BD-225 is a single-BD batch realized across 5 commits. Per the
per-commit-fresh-coder + per-BD-review-inline rules, EACH commit gets a fresh pack-coder; each coder run
is followed by the bounded reviewer/fix cycle before the next commit's coder spawns. The end-of-batch
reviewer runs once on the full 5-commit set after all per-commit cycles complete.

---

## §C. Per-commit file-by-file detail + verification

### C1 — `.graphifyignore` + `.gitignore graphify-out/`

**Files + changes:**
- `.graphifyignore` (repo root, **NEW file**) — EXACTLY the design §4.3 content (the header comment
  block stating the fnmatch matcher + one-file-or-the-other + built-in-pruned-set + index-scope note,
  then the D1 archive glob, D2 secrets globs, tracker-state, derived/generated, external ref dir, OS/
  editor noise, and the BD-119 snapshot line). The content is copied VERBATIM from design §4.3 — the
  coder does not re-derive or re-validate the globs (the design already fnmatch-validated them, EB-8/
  design EE-8). Load-bearing facts the coder preserves in the header: graphify uses Python `fnmatch`
  (NOT git pathspec) so `*` crosses `/`, `**` is not special, `[Aa]` bracket classes work; when
  `.graphifyignore` is present graphify uses ONLY it and ignores `.gitignore` for indexing.
- `.gitignore` (**append, in-place — do NOT rewrite**) — append the design §5.1 block (3 comment lines
  + `graphify-out/`) at the file TAIL, after the current last entry
  (`scripts/.bd119-pre-refactor-monolith.sh.snapshot`, EB-3).

**Rationale:** `graphify-out/` is a per-clone regenerated build artifact that must never be committed;
the `.graphifyignore` is mandatory because the archive dirs are TRACKED (a `.gitignore`-based skip
would not exclude them) AND because the moment `.graphifyignore` exists graphify stops reading
`.gitignore` for indexing, so every category to keep out of the graph is re-listed.

**Per-commit verification:**
- `python3 scripts/validate-pack.py` exits 0 (no check reads `.graphifyignore`/the new `.gitignore`
  block; this confirms no collateral break).
- `git check-ignore graphify-out/graph.json` resolves (sanity that the new `.gitignore` entry matches).
- Spot-confirm the `.graphifyignore` byte-matches design §4.3 (coder PREFLIGHT diff).
- FULL CI battery (see §F).

### C2 — Check 63 (graphify-out never tracked): validator + registry + count + test + README

**Files + changes (FIVE surfaces, one atomic commit — enumerate-encoding-surfaces):**

1. **`scripts/validate-pack.py` — the validator `check_graphify_out_never_tracked`** (model: Check 62
   `check_manifest_structural`). Contract (design §5.2):
   - Banner: `── Check 63: graphify-out/ is never tracked (BD-225) ──`.
   - Resolve git root via `subprocess.run([...], cwd=mod.REPO_ROOT, ...)` and read the root from the
     module-level `REPO_ROOT` (the module already defines `REPO_ROOT = Path(__file__).resolve().parent.parent`
     at line ~300, EB-5) so the per-check test can monkeypatch `mod.REPO_ROOT` to a `/tmp` repo (N-4 —
     the exact technique the Check 62 test uses: `mod.REPO_ROOT = root`).
   - Run `git ls-files graphify-out/`. Empty stdout → `ok("Check 63 — graphify-out/ is not tracked
     (gitignored build artifact; 0 tracked paths).")`. Any path → `fail(...)` naming the tracked
     path(s) + remediation: `git rm -r --cached graphify-out/` and confirm `.gitignore` carries
     `graphify-out/`.
   - Lenient ONLY if `git` itself is unavailable (mirror Check 62's lenient skip); never swallow a real
     "tracked path found" failure.
   - O(1): a SINGLE `git ls-files graphify-out/` subprocess — NO tree scan, NO per-entry storm
     (ci-check-runtime-compounding; cost ~0 across the ~155-invocation battery).
   - Route through `run_check`.
2. **`scripts/validate-pack.py` — registry registration.** Append, as the LAST entry of
   `_build_check_registry()` (after the Check 62 entry — at HEAD the registry list closes just below the
   `(62, "check_manifest_structural", check_manifest_structural, W)` tuple, EB-5 — before the closing
   `]`): `(63, "check_graphify_out_never_tracked", check_graphify_out_never_tracked, W)`, with a short
   comment mirroring the adjacent CI-infra guards (58/59/60/61/62). Cite the insertion point by CONTENT
   (the last entry of `_build_check_registry()`, after the Check 62 entry), NOT a line number (N-1 —
   line numbers drift).
3. **`scripts/validate-pack.py` — count-constant bump.** `CHECK_REGISTRY_EXPECTED_COUNT` 60 → 61 (at
   HEAD the constant is `CHECK_REGISTRY_EXPECTED_COUNT = 60`, EB-5), AND extend the running-tally
   comment block immediately ABOVE the constant with one line:
   `# + 1 net-new BD-225 check (63 graphify-out-never-tracked guard).`. Cite the block by content (the
   `CHECK_REGISTRY_EXPECTED_COUNT` comment block just above the constant) — NOT a line number (N-1). The
   comment is documentation only (Check 59 computes the real count from `len(_build_check_registry())`
   and asserts equality), but the lock-step comment keeps the tally honest.
4. **`scripts/tests/test-validate-pack-check-63.sh` (**NEW**, model: the Check 62 test).** Auto-wires
   into CI via the disk glob — the `plan` job derives the `tests` matrix from `scripts/tests/*.sh`
   (Check 42, post-BD-219), so committing the file is the only wiring; no matrix/allowlist edit.
   Required groups:
   - **Group 0 — import + registration:** assert `mod.check_graphify_out_never_tracked` exists;
     `63 in [t[0] for t in mod._build_check_registry()]`;
     `len(mod._build_check_registry()) == mod.CHECK_REGISTRY_EXPECTED_COUNT` (Check 59's invariant —
     proves the count bump is consistent).
   - **Group 1 — real-state-at-HEAD PASS:** call the check against the real tree; expect 0 failures +
     the "not tracked" PASS message (the real tree has no tracked `graphify-out/`, EB-3).
   - **Group 2 — synthetic PASS/FAIL against a `/tmp` repo (test-infra-self-provisioned):** `git init`
     a throwaway repo in `mktemp -d`; (T1 PASS) no `graphify-out/` → 0 failures; (T2 FAIL)
     `mkdir graphify-out && echo x > graphify-out/graph.json && git add -A` then monkeypatch
     `mod.REPO_ROOT` to the tmp repo (N-4) → expect ≥1 failure naming the tracked path. `rm -rf` the
     tmp repo; NEVER mutate the real tree.
   - **Group 3 — end-to-end:** `python3 scripts/validate-pack.py --only-check 63` exits 0 and prints
     the banner + clean message on HEAD.
   - Header states the test is NOT fixture-dependent (writes only a `/tmp` REPO_ROOT) so it stays under
     `scripts/tests/` (not `fixture-dependent/`).
5. **`README.md` — fix BOTH "invoked checks" instances COMPLETELY (S-1 / MUST-1).** At HEAD BOTH the
   version-table row (line 60) and the layout line (line 190) carry the SAME detailed parenthetical
   (NOT a bare "48 invoked checks"). Verbatim at HEAD (EB-4):
   `48 invoked checks (46 numbered Check 1–11, 16–23, and 25–51 — including DEEP-only Check 49; 2
   unnumbered informational — issue-template-forms and template-archive-v11; Checks 12–15 retired per
   v9 sunset; Check 24 retired per BD-194)`.
   This string is NOT CI-gated (Check 4 validates only the version TABLE), so it cannot break CI — but it
   is already badly stale AND internally contradictory (it says "16–23" while also saying "Check 24
   retired"; the range "25–51" stops 11 short of the real max 62). **The prior plan's "bump 48→56 and
   extend the tail to …63" was INCOMPLETE (MUST-1): it would leave the parenthetical's ranges/sub-count
   stale → a NEW contradiction (headline 56, body enumerating to 51). The coder MUST rewrite the FULL
   parenthetical in BOTH instances to the measured registry set so each is internally consistent.**
   Re-measured registry (EB-6, importlib): distinct numbered checks today = **55**, max = **62**, gaps
   at **12, 13, 14, 15, 21, 24, 28**; after Check 63 → **56** distinct numbered, max **63**. The exact
   measured ranges (post-Check-63) are: **Check 1–11, 16–20, 22–23, 25–27, 29–63** (these contiguous
   runs reflect the real gaps: 12–15, 21, 24, 28 are absent).
   - **Headline:** `56 invoked checks` in BOTH instances (NOT 48; NOT "increment 48 by one").
   - **Sub-count:** there are **56 numbered** checks (no separate "+2 unnumbered informational"
     double-count — the registry's 2 `None`-numbered entries are NOT in the distinct-numbered set; if
     the coder keeps the "unnumbered informational" framing the headline arithmetic MUST be internally
     consistent, but the recommended phrasing drops the stale "46 numbered + 2 unnumbered = 48" math
     entirely and states "56 numbered checks").
   - **Ranges:** replace `Check 1–11, 16–23, and 25–51` with `Check 1–11, 16–20, 22–23, 25–27, 29–63`.
   - **Retired clauses:** keep "Checks 12–15 retired per v9 sunset; Check 24 retired per BD-194" but
     reconcile them with the gap list (12–15, 21, 24, 28 absent; 21 and 28 were never assigned in this
     window — the coder may note 21/28 as never-assigned or simply let the contiguous ranges express the
     gaps). The headline, sub-count, and ranges MUST agree.
   - **DEEP-only Check 49** note stays (49 is in the set).
   - **Alternative the coder is OFFERED (cleaner, anti-drift):** collapse the brittle hand-enumeration to
     `56 numbered checks (the registry is the source of truth — see _build_check_registry())` so the
     surface stops drifting at every check add. Either the full measured rewrite OR the collapse is
     acceptable; "extend to …63" alone is NOT.
   Both instances are named (lines 60 + 190) so neither is silently left stale (enumerate-encoding-
   surfaces). Do NOT touch the adjacent "aggregate CI test runner across 41 suites" string on line 60
   (NIT-1; out of BD-225 scope — see §A.3).

**Rationale:** Check 63 makes the "graphify-out never committed" invariant CI-enforced (measure-then-
bound: `git ls-files graphify-out/` → 0 at HEAD, so the legitimate tracked set is EMPTY → NO allowlist
constant; the guard runs clean against current + projected-post-C1 state). The five surfaces are one
unit because a registered check with a stale count or no test is a half-applied state. The README is in
the same commit because Check 63 is the change that worsens the count drift (enumerate-encoding-surfaces).

**Per-commit verification:**
- `python3 scripts/validate-pack.py --only-check 63` exits 0, prints the banner + clean message.
- `python3 scripts/validate-pack.py --only-check 59` exits 0 (count invariant holds: registry now 61
  entries == `CHECK_REGISTRY_EXPECTED_COUNT` 61).
- `bash scripts/tests/test-validate-pack-check-63.sh` → all groups PASS.
- `python3 scripts/validate-pack.py` (full, no flag) exits 0.
- **README internal-consistency grep (MUST-1):** both instances read `56 invoked checks` AND the
  parenthetical ranges read `Check 1–11, 16–20, 22–23, 25–27, 29–63` (no residual `25–51` / `16–23` /
  `48` / `46 numbered`); headline, sub-count, and ranges agree. (Or, if the collapse alternative was
  taken, both read the SoT-pointer phrasing.) Confirm "41 suites" on line 60 is UNCHANGED (NIT-1).
- FULL CI battery (see §F). Note: `validate-pack.py` is a fixture input → THIS is the manifest-input-
  changing commit (SHOULD-2); at PUSH (after C2 has landed) the orchestrator runs
  `scripts/manifest-sync.sh` (expect exit 10 → commit regenerated `test-fixtures/manifest.txt` with
  user approval) — push-time, NOT a per-commit step. `graphify-out/` is never a fixture input; the new
  test file is denied → also not an input.

### C3 — graph-first trinity rule + the B-1 rationale bijection

**Files + changes (trinity bullet ×3 + rationale section — ONE atomic commit, B-1 BIJECTION):**

1. **`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (pack-root trinity) — append the graph-first bullet** as
   the LAST bullet of `### Repo conventions`, between the `dependency-direction-placement` bullet and
   the `### Project goals (v11)` header. At HEAD the anchors are: CLAUDE.md (bullet ends 595, header
   597), AGENTS.md (554 / 556), GEMINI.md (531 / 533) (EB-7). Targeted APPEND (edit-in-place), NOT a
   rewrite. NEVER in `project-template/` (boundary). The bullet carries the tag
   `[roles: universal] [rationale: graph-first-context]` on its imperative line in all three files.
   The CORE substance is IDENTICAL across the trinity (D9 parity); only the CLI-specific invocation
   phrasing is normalized per audience (cross-cli-reference-normalization — NOT byte-copied):
   - **CLAUDE.md** — Claude session/skill auto-route; Claude subagents inherit pack-root `CLAUDE.md`;
     pack agents via `claude --agent pack-<name>` / the Agent tool.
   - **AGENTS.md** — Codex audience; pack agents via `codex --agent pack-<name>`; states the rule
     applies the same way and that cross-CLI EFFECTIVENESS is verified separately under **BD-233**
     (the rule ships here for parity; inert text where unconsumed).
   - **GEMINI.md** — Antigravity audience; pack agents via `agy` + the bundled `pack-<name>` plugin/
     subagent; same BD-233 cross-CLI-effectiveness caveat.
   The CORE meaning every file carries (design §6.3):
   - **G1 guard FIRST:** "If `$(git rev-parse --show-toplevel)/graphify-out/graph.json` exists, prefer
     the graph for orientation / relationship / blast-radius / 'what relates to X' / 'where does Y live'
     questions (query ~0 tokens) before broad tree reads; otherwise use normal grep/Read."
   - **G2 fallback:** "If a graph query errors or returns nothing useful, fall back to file reads —
     never block on the graph."
   - **Exceptions (fall through to grep/Read):** exact-string/token search → grep; authoritative SSOT
     fields (a BD `Status`, the README version table, a `_rules.md` contract) → Read the source;
     freshly-changed/uncommitted files → `git diff`/Read; whole-file exact content → Read; archive-dir/
     excluded-category content → Read/grep (not in the graph). (Design §6.4 table.)
   - **Absolute `--graph` always**; **budgets** 2000/1500/1000 (human/agent/Pack-Chat); **role phrasing**
     (one optional line: reviewer→`affected`; architect→`path`/`explain`; coder/docs-researcher→`query`
     then open only cited files).
   - **Never preload the graphify skill** via `skills:` frontmatter (~32KB, build-oriented); querying
     needs `Bash` only — all 5 pack agents already carry it, so NO `tools:` change.
   - Querying is read-only/deterministic/~0 tokens; only BUILDING/refreshing the doc layer costs
     subscription — agents QUERY, never BUILD. **Boundary note:** the graph indexes the whole repo incl.
     `project-template/`; consuming it to answer a deliverable question is fine — the RULE + SETUP stay
     pack-side.
   - Hand-authored, NOT via `graphify claude install` (D7: that writes only CLAUDE.md — breaking trinity
     symmetry — AND a PreToolUse hook the pack does not want). NO PreToolUse hook.
2. **`pack-ops/PACK-MEMORY-RATIONALE.md` — add the `## graph-first-context` section** in the SAME
   commit (the B-1 fix). Mirror the existing sections' shape (Why + How-to-apply-worked-example +
   Rejected-alternatives, e.g. `## dependency-direction-placement`, `## cross-cli-reference-normalization`).
   Content the coder authors (design §6.2):
   - **Why:** the pack is doc/reference/agent-heavy; agents re-read the file tree for context, which is
     token-expensive. A compact subgraph answers orientation/relationship/blast-radius questions at ~0
     tokens (deterministic local CLI, no LLM). Graph-first is the token-efficiency win BD-225 buys.
   - **How to apply:** when `graphify-out/graph.json` exists, query the graph FIRST for "what relates to
     X / where does Y live / blast radius of Z" before broad tree reads; fall through to grep/Read for
     the exceptions; if the graph is absent or a query fails, use normal tools (G1 + G2). Worked
     example: to scope which files a coder needs, Pack Chat runs `graphify query`/`affected` and names
     those exact files in the prompt instead of "read the tree."
   - **Rejected alternatives:** (a) an untagged convention bullet — rejected (the rule is spawn-relevant
     `[roles: universal]`; the tagged form gives a discoverable rationale pointer); (b) `graphify claude
     install`'s auto-written CLAUDE.md section — rejected (trinity-asymmetric + surprise PreToolUse
     hook); (c) per-agent-frontmatter enablement — unnecessary (all 5 agents already carry `Bash`).
   The slug `graph-first-context` is unique vs the current 22-slug set (EB-2) and matches the Check 45
   kebab-case slug regex `^##\s+([a-z0-9][a-z0-9-]*)\s*$`.

**Governance — PACK-AGENTS.md needs NO parallel touch (SHOULD-3 — STATE-VERIFIED, NOT a C3 gate):**
The new `### Repo conventions` rule has NO collapsed restatement in PACK-AGENTS.md/PACK-CHAT.md, so it
needs NO `.spawn-rule-manifest.txt` record and NO reference-surface touch. This is STATE-VERIFIABLE, not
a maintainer judgment call: `grep -c graph-first pack-ops/.spawn-rule-manifest.txt` → 0, and Check 46
(`check_boundary_and_spawn_pointer_manifests`) iterates the records PRESENT — it does NOT require a
record for every corpus slug (EB-9). **The plan ADOPTS the no-touch conclusion; C3 is NOT gated on a
user reply.** (If the user wants a veto window, it is the standard planner→coder gate, not a C3-specific
block.)

**Rationale (why same-commit is MANDATORY):** Check 45 enforces a 1:1 bijection between the
`[rationale: <slug>]` slugs in CLAUDE.md `## Pack memory` and the `## <slug>` headings in
`PACK-MEMORY-RATIONALE.md` (set-equality both directions; an orphan corpus slug is a hard FAIL). Adding
the tag WITHOUT the section makes it the 23rd orphan corpus slug → Check 45 FAILS → the whole
`validate-pack.py` run exits non-zero → CI-RED. Baseline is 22↔22 green (EB-2); the fix takes it to
23↔23. Splitting the tag and the section across two commits leaves an intermediate CI-RED commit —
forbidden (every commit must be working-state).

**Per-commit verification (MUST include `--only-check 45`):**
- `python3 scripts/validate-pack.py --only-check 45` exits 0 and reports **23 ↔ 23** (bijection holds).
- `python3 scripts/validate-pack.py --only-check 16` / `--only-check 18` / `--only-check 19` exit 0
  (trinity-parity holds across the three files — the new bullet is present + parallel in all three).
- `git grep -n "graph-first-context" CLAUDE.md AGENTS.md GEMINI.md pack-ops/PACK-MEMORY-RATIONALE.md`
  shows the tag in all three trinity files + the section heading in the rationale file (4 surfaces).
- `git grep -in graphify -- 'project-template/'` → still 0 rows (boundary held).
- `python3 scripts/validate-pack.py` (full) exits 0.
- FULL CI battery (see §F).

### C4 — `OPTIONAL-FEATURES.md` Graphify runbook (privacy + hook + initial-build)

**Files + changes:**
- `pack-ops/OPTIONAL-FEATURES.md` (**append, in-place**) — a NEW
  `## Graphify — knowledge-graph context (pack-dev)` section following the file's documented entry shape
  (Status / What it is / When it matters / How to enable / How to use the pack's pieces with it /
  Caveats / When to skip — the "Adding new entries" template at file tail, EB-11). At HEAD the file is
  324 lines and ends with the "Adding new entries" guidance; the new section appends after it. The
  section carries:
  - **D3 privacy/secrets:** the semantic pass sends NON-CODE text (docs/PDFs/comments) to the model; the
    AST/code pass is 100% local and never leaves the machine. The auto-mode classifier may REFUSE on a
    secrets-adjacent repo — a CORRECT SAFETY STOP, not a bug; investigate, do NOT blindly override. This
    repo is less secrets-adjacent than dotfiles (only synthetic fixtures + `.example` files); the
    `.graphifyignore` excludes all `.env` + `.mcp.json` + `.claude/settings.local.json`, removing the
    secrets-shaped semantic-pass inputs. **Backend = Claude subscription ONLY (`--backend claude-cli`)**
    with the §1.1 stale-enum caveat verbatim. The auto-route foot-gun: if `GEMINI_API_KEY`/
    `GOOGLE_API_KEY`/`OPENAI_API_KEY` is set, graphify routes the semantic pass to that PAID API — so
    the hook unsets them in its own subshell AND `--backend claude-cli` is always explicit (defense-in-
    depth). No API key anywhere in pack config; NO Ollama (a no-key alternative exists); NO neo4j/
    falkordb/video extras (absent — would `ModuleNotFoundError`; out of scope).
  - **D4/D5 hook runbook — the G3 guarded + non-blocking post-commit hook (design §7.2 template,
    verbatim).** Documented as a per-clone hand-install at `.git/hooks/post-commit` (`chmod +x`), NOT a
    committed file (git does not version `.git/hooks`). The template's LOAD-BEARING shape: guard
    (`[ -x "$GFX" ] && [ -f "$GRAPH" ] || exit 0`) → key-clean subshell (`unset GEMINI_API_KEY
    GOOGLE_API_KEY OPENAI_API_KEY`) → doc-gate split (`.md`/`.pdf` change → `GRAPHIFY_CLAUDE_CLI_PARALLEL=0
    graphify extract . --backend claude-cli` — NO `--no-viz`, M-2; else free `graphify update .`, with
    `GRAPHIFY_FORCE=1 graphify update .` ONLY on a removal commit — M-3) → background → unconditional
    `exit 0`. The runbook states the hook is "install + VERIFY before relying" pending the two D4
    coder-VERIFY items (below); the manual doc-gated refresh is the safe fallback.
  - **The two D4(a)/D4(b) coder-VERIFY items, called out explicitly:**
    - **D4(a)** — verify the post-commit hook FIRES under worktree-isolation (BD-226/197). The
      orchestrator applies the agent patch + commits in the MAIN (parent) tree; a worktree shares the
      parent's `.git` common dir so `.git/hooks/post-commit` SHOULD fire on the main-tree commit — the
      coder VERIFIES empirically and confirms the doc-gate's `git diff --name-only HEAD~1 HEAD` resolves
      against the committed ref. Cross-reference the existing OPTIONAL-FEATURES.md § "Claude Code —
      Isolated parallel agents (worktree isolation)" (at line 111, EB-11).
    - **D4(b)** — verify a backgrounded refresh overlapping an in-flight agent QUERY is safe. Graphify
      keeps an auto-backup (`GRAPHIFY_NO_BACKUP` at default 0) and writes via tmp-then-replace
      (`watch.py` writes `graph_tmp` then swaps); a concurrent reader sees old-or-new, not torn.
      Confirm the atomic-swap on the installed 0.8.39 write path before declaring the hook safe.
  - **§7.4 initial-build runbook + irreducible manual points** (the one-time `/graphify .`): interactive
    main-session build; corpus trips BOTH narrow-gates (1,373 files > 500; ~2.65M `.md` words >
    2,000,000) so it CANNOT be fully automated. Manual/permission points: (1) narrow-gate decision →
    answer "proceed whole-repo" (D6 start-big), `--no-viz` ON, clustering ON; (2) first headless
    `claude -p` permission prompt — confirm once per machine; (3) classifier refusal = correct safety
    stop (investigate, do NOT auto-override); (4) per-clone/per-machine install (`graphify-out/`, the
    hook, the global graph do not sync); (5) env-key hygiene — one-time confirm the three keys unset.
    The initial build produces `graphify-out/cost.json` (the measured token-cost tracker) — the input
    **BD-234** consumes to re-tune cadence/knobs/scope after burn-in. The runbook states: cadence
    direction is LOCKED for now (D5); BD-234 re-tunes with measured numbers — do NOT change cadence here.
  - **§1.1 `claude-cli` caveat** (verbatim): the top-level `--help` enum omits `claude-cli`; it is valid
    (verified via the invalid-backend error) and is the no-key subscription path — do NOT substitute
    `claude`, which demands `ANTHROPIC_API_KEY`.

**Rationale:** OPTIONAL-FEATURES.md is the documented pack-dev home for opt-in/experimental features +
privacy-delta notes; the runbook captures every irreducible manual point so a maintainer can opt into
the graph correctly and safely. The hook + initial build are documented but never committed (opt-in,
per-clone).

**Per-commit verification:**
- `python3 scripts/validate-pack.py --only-check 40` exits 0 (the pack-ops/ bare-cross-reference scanner
  stays green — the new section uses no bare cross-references that would trip Check 40).
- `python3 scripts/validate-pack.py` (full) exits 0.
- Manual read-back: the `extract` lines in the documented hook carry `--backend claude-cli` and NO
  `--no-viz`; `GRAPHIFY_FORCE=1` appears ONLY on the `update` removal sub-branch; the hook ends with
  unconditional `exit 0`; the D4(a)/D4(b) VERIFY items are present.
- FULL CI battery (see §F).

### C5 — delete the 3 stale graphify research docs + fix ALL LIVE dangling refs (fail-loud)

**Files + changes:**
- **DELETE entirely (no banner, no archive — fail-loud) — ORCHESTRATOR-executed destructive op:**
  - `maintenance-docs/v11-research/RESEARCH-GRAPHIFY-EXTERNAL.md`
  - `maintenance-docs/v11-research/RESEARCH-GRAPHIFY-PACK-INTEGRATION.md`
  - `maintenance-docs/v11-research/RESEARCH-GRAPHIFY-SYNTHESIS.md`
  All 3 exist at HEAD (EB-12). Their posture (Graphify as a CLIENT feature deferred to v12, against an
  older version) is reversed by BD-225 (pack-side, v11.0); the new `RESEARCH-BD-225-*` census + the
  design supersede them; their external-research evidence is recoverable from git history. **The coder
  does NOT run `git rm` and does NOT `rm` on its own authority** (agents-never-commit + per-action-
  approval): it surfaces the 3 paths in its IMPL-REPORT; the ORCHESTRATOR performs the deletion with
  explicit user approval at commit time.
- **Fix the 3 LIVE dangling refs (targeted in-place; re-read each line's context first):**
  - `maintenance-docs/v11-research/RESEARCH-CLAUDE-REPOS-SURVEY.md:271` — "Graphify (deferred to v12 per
    RESEARCH-GRAPHIFY-SYNTHESIS.md) indexes structural code relationships" → repoint to BD-225:
    "Graphify (wired pack-side in v11.0 per BD-225 / `DESIGN-BD-225-GRAPHIFY-PACK-INTEGRATION.md`)
    indexes structural code relationships". Preserve the surrounding coexistence prose (the mcp-local-
    rag / claude-context layering point).
  - `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-GROUPINGS-V2.md:128` — "Graphify is explicitly
    deferred to v12 per `RESEARCH-GRAPHIFY-SYNTHESIS.md`" → replace the deferral claim + dead path with
    the BD-225 fact (Graphify landed pack-side v11.0; still orthogonal to groupings' timeline).
  - `maintenance-docs/v11-research/V11.1-DISCUSSION-GITHUB-PROJECTS.md:338` —
    "`RESEARCH-GRAPHIFY-SYNTHESIS.md` — explicitly defers Graphify to v12" → replace with the BD-225
    pack-side-v11.0 reference; keep the "different timeline/scope from groupings" point.

**Left UNTOUCHED — the DELIBERATELY-FROZEN allow-set (M-1=(b), user-locked; SHOULD-1 census corrected).**
fail-loud targets LIVE forward-pointing surfaces, NOT frozen snapshots. The disposition (leave frozen)
rests on the FROZEN-ARCHIVE / historical-verbatim ground; the prior plan's "all 4 archive = same
`??`-snapshot pattern" was WRONG and is corrected here (re-measured, EB-13). The frozen allow-set is:

- **2 archive files with LIVE PROSE refs (0 `??`-snapshot lines)** — under `maintenance-docs/archive/v11/`,
  frozen historical snapshots AND D1-excluded from the graph → UNTOUCHED:
  - `ARCHITECTURE-PER-ENTRY-FLAT-FILES.md` (16 prose ref lines, e.g. line 1408
    "Per `RESEARCH-GRAPHIFY-SYNTHESIS.md:32-38`:").
  - `PACK-REVIEW-ARCHITECTURE-PER-ENTRY.md` (10 prose ref lines, e.g. line 532
    "| `RESEARCH-GRAPHIFY-SYNTHESIS.md:14-17` v12 deferral | ... | PASS |").
- **2 archive files with `??`-snapshot lines (verbatim `git status --short`)** — under
  `maintenance-docs/archive/v11/`, frozen + verbatim → UNTOUCHED:
  - `IMPLEMENTATION-REPORT-BD-146.md` (3 `??`-snapshot lines, 21–23).
  - `IMPLEMENTATION-REPORT-BD-149.md` (3 `??`-snapshot lines, 204–206) — the 4th archive file (M-1
    named BD-149); it carries `??`-snapshot lines (NOT prose), confirmed EB-13.
- **3 non-archive `??`-snapshot files (live tree, verbatim `git status --short`)** — editing would
  falsify a historical record → UNTOUCHED:
  - `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-120.md` (3 `??`-snapshot lines, 25–27).
  - `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-150.md` (3 `??`-snapshot lines, 26–28).
  - `maintenance-docs/v11-implementation/PACK-REVIEW-BD-120.md` (3 `??`-snapshot lines, 158–160).
- **The BD-225 self-references** in `DESIGN-BD-225-GRAPHIFY-PACK-INTEGRATION.md` and
  `RESEARCH-BD-225-GRAPHIFY-INCLUSION.md` (these DESCRIBE the deletion + the doomed paths) → UNTOUCHED.

**NIT-2 — `REVIEW-BD-096.md` is NOT a dangling ref (NOT in the census or fix set).** Its only "graphify"
hit is `REVIEW-BD-096.md:38`, a verbatim commit-log subject (`91e7563 docs: v11 — Graphify +
Claude-ecosystem-repos research artifacts`) — a historical record, NOT a forward-pointing reference; it
contains ZERO `RESEARCH-GRAPHIFY-(EXTERNAL|PACK-INTEGRATION|SYNTHESIS)` refs (re-measured, EB-13). It is
correctly outside the deletion/ref-fix scope.

**Rationale:** fail-loud-delete-old-source — delete the superseded docs entirely (no banner, no
archive); fix every LIVE forward-pointing ref so nothing dangles; leave frozen snapshots + historical-
verbatim lines intact (M-1=(b), user-locked).

**Per-commit verification — the zero-dangling completeness gate (§9.3, allow-set CORRECTED per SHOULD-1):**
- After deletion + the 3 live fixes:
  `git grep -nE "RESEARCH-GRAPHIFY-(EXTERNAL|PACK-INTEGRATION|SYNTHESIS)"` returns ONLY the
  deliberately-frozen allow-set — and ZERO remaining LIVE dangling refs:
  1. the BD-225 self-references (`DESIGN-BD-225-*` / `RESEARCH-BD-225-*`, which describe the deletion);
  2. **2 archive files with LIVE PROSE refs** (`ARCHITECTURE-PER-ENTRY-FLAT-FILES.md`,
     `PACK-REVIEW-ARCHITECTURE-PER-ENTRY.md`) — these return PROSE refs, NOT `??`-lines; the reviewer
     MUST expect prose here and NOT flag it as a violation;
  3. **2 archive files with `??`-snapshot lines** (`IMPLEMENTATION-REPORT-BD-146.md`,
     `IMPLEMENTATION-REPORT-BD-149.md`);
  4. **3 non-archive `??`-snapshot files** (`IMPLEMENTATION-REPORT-BD-120.md`,
     `IMPLEMENTATION-REPORT-BD-150.md`, `PACK-REVIEW-BD-120.md`).
  Any LIVE forward-pointing ref OUTSIDE this allow-set = gate FAIL. (No CI gate covers maintenance-docs
  cross-refs — Check 34 walks only the per-entry stream trees — so this is a fail-loud correctness gate,
  not a CI assertion; the coder PREFLIGHT + reviewer enforce it. The allow-set is enumerated precisely
  so the reviewer does NOT false-flag the 2 archive PROSE-ref files.)
- `python3 scripts/validate-pack.py` (full) exits 0 (no check references the deleted docs).
- FULL CI battery (see §F).

---

## §D. The one-time INITIAL BUILD runbook (post-merge; NOT a commit)

This is a one-time interactive main-session action a maintainer takes AFTER C1–C5 land — it produces no
committed artifact (the graph is gitignored + per-clone) and is NOT part of the commit sequence. It is
documented in C4's OPTIONAL-FEATURES.md section. The orchestrator (or the maintainer) runs it manually;
no agent builds the graph.

**Steps (design §7.4 / §10):**
1. Confirm `GEMINI_API_KEY` / `GOOGLE_API_KEY` / `OPENAI_API_KEY` are UNSET (env-key hygiene).
2. In a Claude session at the repo root, run the interactive `/graphify .` build. The corpus trips BOTH
   narrow-gates (1,373 files > 500; ~2.65M `.md` words > 2,000,000) so graphify warns + asks which
   subfolder to narrow to → answer **"proceed whole-repo"** (D6 start-big), `--no-viz` ON, clustering ON.
3. On the first headless `claude -p` permission prompt (when the post-commit semantic hook first runs
   headless) — confirm once per machine. If the classifier REFUSES — that is a CORRECT safety stop;
   investigate, do NOT auto-override.
4. (Optional opt-in) hand-install the §7.2 guarded post-commit hook at `.git/hooks/post-commit` +
   `chmod +x`, AFTER verifying D4(a)/D4(b) on the installed 0.8.39.
5. The build produces `graphify-out/cost.json` — the measured token-cost tracker **BD-234** consumes
   after burn-in to confirm/adjust cadence + knobs + scope.

**Irreducible manual points (cannot be a committed file):** the narrow-gate decision, the first
`claude -p` permission, the per-clone/per-machine install (graph + hook + global graph do not sync), the
classifier-refusal investigation, and the env-key confirmation. These are documented, not automated.

---

## §E. Governance — the S-2 propagation procedure (MINUS the dropped MEMORY.md step)

The graph-first rule is a spawn-relevant `[roles: universal]` rule, so it follows the PACK-CHAT.md
"Rule-change propagation procedure" — EXCEPT the MEMORY.md step, which is DROPPED per the HARD directive.
At HEAD the procedure table (EB-14) has 6 rows; this plan's disposition:

| Step | Procedure surface | This plan's disposition |
|---|---|---|
| 1 | Corpus imperative line ×3 trinity + `[roles:]` + `[rationale: slug]` | **EXECUTED** in C3 (the trinity bullet in all three files). CI-gated (trinity-parity Checks 16/18/19 + role-tag vocab). |
| 2 | `PACK-MEMORY-RATIONALE.md` `## <slug>` entry | **EXECUTED** in C3 (the `## graph-first-context` section). CI-gated (Check 45 bijection). |
| 3 | Thin memory-cache pointer (out-of-repo MEMORY.md) | **DROPPED — NOT executed.** HARD NO-MEMORY.md directive (design §11). The rule lives ONLY in the in-repo corpus. The procedure's Step 3 contradicts the directive → **FLAG for BD-232** to reconcile. This plan does NOT patch PACK-CHAT.md and adds NO MEMORY.md pointer. |
| 4 | Reference surfaces (PACK-AGENTS.md / PACK-CHAT.md one-line refs) | **N/A** — the new rule has NO collapsed restatement, so no reference surface (EB-9). |
| 5 | `.spawn-rule-manifest.txt` slug→canonical+references | **N/A** — no collapsed restatement → no manifest record needed (Check 46 iterates records present, not every corpus slug — EB-9). |
| 6 | `test-fixtures/manifest.txt` | **Push-time, NOT a propagation step.** `validate-pack.py` (edited in **C2** — SHOULD-2) is a fixture input → orchestrator runs `manifest-sync.sh` at push (BD-228). |

**The MEMORY.md flag for BD-232 (the only deviation):** the propagation procedure's Step 3 (out-of-repo
memory-cache pointer) is at odds with the current NO-MEMORY.md posture and should be revisited under
BD-232. This plan executes Steps 1+2 (the CI-gated half), skips Step 3 (the directive), and notes 4/5
as N/A and 6 as push-time.

**PACK-AGENTS.md no-touch is ADOPTED, not gated (SHOULD-3 — fixed).** The prior plan framed
"PACK-AGENTS.md needs no parallel touch" as a confirmation NEEDED BEFORE C3 lands. That question is
STATE-VERIFIABLE, not a maintainer judgment call: `grep -c graph-first pack-ops/.spawn-rule-manifest.txt`
→ 0, and Check 46 needs no record for a rule with no collapsed restatement (EB-9). **The plan ADOPTS the
design's §10.2/§11.2 PACK-AGENTS.md-no-touch assertion and does NOT gate C3 on a user reply.** It is
surfaced for awareness only; any veto rides on the standard planner→coder gate, not a C3-specific block.

---

## §F. Verification strategy (FULL CI battery per commit — not just validate-pack)

Per `verify-full-ci-suite`, EACH of the 5 commits is judged against the FULL CI battery, not just
`validate-pack.py`. The per-commit verification is:

1. **`python3 scripts/validate-pack.py`** (no flag = ALL checks) exits 0. Plus the commit-specific
   `--only-check N` legs named in §C (Check 63 + 59 for C2; Check 45 + 16/18/19 for C3; Check 40 for C4).
2. **The full test battery** — the aggregate CI test runner across all `scripts/tests/*.sh` suites
   (the `tests` matrix the `plan` job derives from the disk glob, Check 42). For C2 specifically this
   includes the NEW `test-validate-pack-check-63.sh` (auto-wired by the glob) AND the existing
   `test-validate-pack-check-59/61/62.sh` (the count-invariant + adjacent guards must stay green after
   the 60→61 bump).
3. **Integration tests** that exercise validate-pack and fixture state, per the standard per-commit
   verification (not only the unit-level validate-pack run).
4. **Boundary grep audit (every commit):** `git grep -in graphify -- 'project-template/'` → 0 rows.
5. **Pre-flight (coder, before IMPL-REPORT):** the coder emits the PREFLIGHT line only after all
   in-scope edits + verification (in-scope tests + validate-pack + relevant per-check tests) PASS.
6. **Push-time (orchestrator, ONCE for the batch):** the manifest-INPUT change is introduced in **C2**
   (the `validate-pack.py` edit — SHOULD-2); `bash scripts/manifest-sync.sh` before `git push` reconciles
   it regardless of how many commits are pushed together (expect exit 10 because `validate-pack.py`
   changed → commit the regenerated `test-fixtures/manifest.txt` with user approval), then watch the
   `Validate Pack` CI run. (The documented norm is to push the unit as ONE — CARRY-OVER.)

**Grep audits the reviewer/coder run (no CI gate covers these — fail-loud):**
- **C2 (MUST-1):** BOTH README "invoked checks" instances read the post-Check-63 figure — headline
  `56 invoked checks` AND the parenthetical ranges `Check 1–11, 16–20, 22–23, 25–27, 29–63` (no residual
  `48`, `46 numbered`, `16–23`, or `25–51`); headline + sub-count + ranges agree. (Or both read the
  collapse-to-SoT phrasing.) The adjacent "41 suites" string is UNCHANGED (NIT-1, out of scope).
- C3: `git grep -n "graph-first-context"` shows the tag in CLAUDE.md/AGENTS.md/GEMINI.md + the section
  heading in PACK-MEMORY-RATIONALE.md (4 hits, one per surface); the trinity bullets are parallel.
- **C5 (SHOULD-1):** the zero-dangling gate (§C/C5) — `git grep -nE
  "RESEARCH-GRAPHIFY-(EXTERNAL|PACK-INTEGRATION|SYNTHESIS)"` returns ONLY the corrected frozen allow-set
  (BD-225 self-refs + 2 archive PROSE-ref files + 2 archive `??`-snapshot files + 3 non-archive
  `??`-snapshot files). The reviewer must NOT flag the 2 archive PROSE-ref files as violations.
- C4: the documented hook's `extract` lines carry `--backend claude-cli` + NO `--no-viz`; `GRAPHIFY_FORCE=1`
  only on the `update` removal sub-branch; unconditional `exit 0`.

---

## §G. Implementation-level risks / notes (NOT design re-opens)

These are HOW-level risks the coder/reviewer must watch — none re-opens a locked design decision.

- **R1 — Registry insertion by CONTENT, not line number (N-1).** `_build_check_registry()` and
  `CHECK_REGISTRY_EXPECTED_COUNT` shift as the file changes; the coder MUST locate the insertion points
  by content ("the last entry of `_build_check_registry()`, after the Check 62 entry"; "the
  `CHECK_REGISTRY_EXPECTED_COUNT` constant + its comment block just above"), never a hardcoded line.
- **R2 — Entry count ≠ check number (N-2).** The new ENTRY makes the registry 60 → 61 entries; the new
  check NUMBER is 63. These are independent (60 entries today = 55 distinct numbered + 2 None-numbered +
  16/18/19 each registered twice — EB-1). Do NOT infer "63 entries." The count bump is 60→61, the
  number is 63.
- **R3 — The `claude-cli` substitution trap (S-3).** The single highest-consequence error: a coder who
  "fixes" `--backend claude-cli` → `claude` to match the help enum breaks the no-key guarantee. Every
  `extract` line in C4 keeps `claude-cli` + the inline caveat. Reviewer MUST grep for any `--backend
  claude` (without `-cli`) in the new content.
- **R4 — `--no-viz` on `extract` (M-2).** `--no-viz` is a build/`cluster-only` flag, NOT an `extract`
  flag; passing it to `extract` is an unknown-option error. The hook's `extract` line must NOT carry it.
- **R5 — The B-1 same-commit bijection (Check 45).** If the trinity tag and the rationale section are
  ever split across commits, the intermediate commit is CI-RED. C3 is atomic; `--only-check 45` is a
  mandatory C3 verification leg.
- **R6 — Test REPO_ROOT monkeypatch (N-4).** The Check 63 test's synthetic-FAIL leg MUST set
  `mod.REPO_ROOT` to the `/tmp` repo (the Check 62 test's exact technique) and restore it in a `finally`;
  the validator MUST read its root from `mod.REPO_ROOT` (not an implicit cwd) or the synthetic FAIL
  cannot point at the tmp repo.
- **R7 — D4(a)/D4(b) are coder-VERIFY, not design-blocking.** The hook's worktree-fire behavior and the
  backgrounded-refresh-vs-query atomic-swap are empirically resolvable at implementation; until verified
  the runbook frames the automated hook as "install + VERIFY before relying," with the manual doc-gated
  refresh as the safe fallback. This is documented in C4, not a blocker for C1–C3/C5.
- **R8 — Manifest at push (BD-228), the input changes in C2 (SHOULD-2).** Do NOT regenerate
  `test-fixtures/manifest.txt` per-commit. The fixture-INPUT change is the C2 edit to `validate-pack.py`;
  `manifest-sync.sh` at push reconciles it (orchestrator, expect exit 10 → commit with approval) however
  the commits are batched. The new test file (`scripts/tests/*`) is NOT a fixture input; `graphify-out/`
  is never a fixture input.
- **R9 — README "invoked checks" fix must be COMPLETE, not a tail-token patch (S-1 / MUST-1).** Both
  instances are NOT CI-gated (no check reads the string) so the fix cannot break CI — but "extend to
  …63" alone leaves the parenthetical's ranges (`25–51`) and sub-count (`46 numbered`) stale → a
  self-contradictory README. The coder rewrites the FULL parenthetical to the measured set (headline
  56, ranges `Check 1–11, 16–20, 22–23, 25–27, 29–63`) OR collapses to the registry-SoT pointer. This
  is a fail-loud reviewer grep, not a CI assertion. The adjacent "41 suites" staleness is a SEPARATE
  pre-existing item, OUT of BD-225 scope (NIT-1) — do NOT fold it in.
- **R10 — PACK-AGENTS.md no-touch is STATE-VERIFIED, not a C3 gate (SHOULD-3 — fixed).** The plan ADOPTS
  the design's §10.2/§11.2 assertion (EB-9: `grep -c graph-first .spawn-rule-manifest.txt` → 0; Check 46
  needs no record for a rule with no collapsed restatement). C3 is NOT blocked on a user reply; the item
  is surfaced for awareness only, with any veto on the standard planner→coder gate.
- **R11 — Archive-ref characterization corrected (SHOULD-1).** The C5 completeness-gate allow-set splits
  the 4 archive files into 2 PROSE-ref files + 2 `??`-snapshot files (re-measured EB-13). The reviewer
  must expect PROSE refs in `ARCHITECTURE-PER-ENTRY-FLAT-FILES.md` + `PACK-REVIEW-ARCHITECTURE-PER-ENTRY.md`
  and NOT read them as gate violations. The disposition (leave all frozen) is UNCHANGED (M-1=(b)).

**Design-vs-reality conflict found: NONE.** Every state-claim re-measured at HEAD `5f56a35` re-verifies
the design's evidence identically. The one EVIDENCE inaccuracy in the committed design (§9.2(b) line 603
calls BD-149 "the same `??`-snapshot pattern" and lumps all 4 archive files as snapshots — when 2 carry
PROSE refs) is flagged in the Revision-log "Design §9 flag" as MATERIAL-BUT-MINOR (evidence-accuracy,
leaning cosmetic): the design's DISPOSITION (leave all 4 frozen) is correct on the frozen-archive ground
and is superseded in practice by this plan's now-accurate gate. No LOCKED decision contradicts current
repo reality; the plan does NOT edit the committed design.

---

## §12. Empirical-Evidence Blocks (re-measured by this planner for the CHANGED claims)

> All measurements read-only at HEAD `5f56a35dea0d7bde3777ce8ff27f864e5819b01a`, branch `v11-dev`,
> 2026-06-18. Re-measured by this planner (NOT cited from the design or the prior plan). No graph
> built/indexed in the pack repo; no `.graphify*` written; no pack file mutated except this plan. The
> blocks below cover the claims this revision CHANGED (the README numbers + the archive-ref census) plus
> the unchanged anchors the changed sections depend on.

**EB-1 — boundary clean + registry composition (unchanged anchor).**
- Command: `git grep -in graphify -- 'project-template/' | wc -l` → `0`.
- Command (importlib load of `scripts/validate-pack.py`):
  `len(_build_check_registry())` → `60`; `CHECK_REGISTRY_EXPECTED_COUNT` → `60`; distinct numbered → `55`;
  max → `62`; `None`-numbered entries → `2`; duplicate-registered numbers → `{16: 2, 18: 2, 19: 2}`.
- Interpretation: boundary held; registry 60 entries / 55 distinct numbered / max 62. Confirms N-2 (entry
  count ≠ check number: new entry 60→61, new number 63). **SUPPORTED.**

**EB-2 — Check 45 bijection baseline + slug absence (unchanged anchor; C3 depends on it).**
- Command: `python3 scripts/validate-pack.py --only-check 45` → "Check 45 — 22 corpus `[rationale: slug]`
  pointer(s); 22 rationale `## <slug>` section(s); sets are equal (bijection holds, no orphans ...)".
- Command: `grep -c "graph-first-context" pack-ops/PACK-MEMORY-RATIONALE.md CLAUDE.md AGENTS.md GEMINI.md`
  → all `0`.
- Interpretation: baseline 22↔22 green; the slug `graph-first-context` is absent everywhere → adding the
  tag without the section orphans it (CI-RED) → C3 must add both in one commit (23↔23). **SUPPORTED.**

**EB-3 — `.gitignore` clean + graphify-out never tracked (unchanged anchor; C1/C2 depend on it).**
- Command: `grep -c graphify-out .gitignore` → `0`; `git ls-files graphify-out/ | wc -l` → `0`; tail of
  `.gitignore` ends with `scripts/.bd119-pre-refactor-monolith.sh.snapshot`.
- Interpretation: append point clean; Check 63's measure-then-bound legitimate tracked-set = empty → no
  allowlist constant; the guard runs clean now + after C1. **SUPPORTED.**

**EB-4 — README "invoked checks": BOTH instances carry the SAME detailed parenthetical (CHANGED — MUST-1).**
- Command: `grep -nE "invoked check" README.md` → line `60:` (version-table row) + line `190:` (layout
  line), BOTH containing the full parenthetical (not a bare "48").
- Command: `grep -oE "validate-pack.py expanded to [0-9]+ invoked checks \([^)]*\)" README.md` (verbatim):
  `validate-pack.py expanded to 48 invoked checks (46 numbered Check 1–11, 16–23, and 25–51 — including
  DEEP-only Check 49; 2 unnumbered informational — issue-template-forms and template-archive-v11; Checks
  12–15 retired per v9 sunset; Check 24 retired per BD-194)`.
- Command (line 190 verbatim, read): `... (48 invoked checks — 46 numbered Check 1–11, 16–23, and 25–51 —
  including DEEP-only Check 49; 2 unnumbered informational — ...; Checks 12–15 retired per v9 sunset;
  Check 24 retired per BD-194; pack-internal)`.
- Command (CI-gating): `grep -n "invoked check" scripts/validate-pack.py` → (empty) — NOT CI-gated.
- Interpretation: the prior plan's "bump 48→56 + extend the tail to …63" is INCOMPLETE — it leaves the
  parenthetical's ranges (`25–51`) and sub-count (`46 numbered`) stale and internally contradictory
  ("16–23" includes the retired 24). The fix must rewrite the FULL parenthetical in BOTH instances.
  Not CI-gated → cannot break CI; fail-loud reviewer grep. **SUPPORTED (MUST-1 confirmed).**

**EB-5 — validate-pack.py registry anchors (insert-by-content; unchanged anchor for C2).**
- Command: `grep -n "CHECK_REGISTRY_EXPECTED_COUNT\|REPO_ROOT =\|check_manifest_structural"
  scripts/validate-pack.py` → `REPO_ROOT = Path(__file__).resolve().parent.parent` ~line 300;
  `CHECK_REGISTRY_EXPECTED_COUNT = 60` ~line 492; the `(62, "check_manifest_structural", ..., W)` tuple
  is the LAST registry entry (list closes with `]` just below it).
- Interpretation: module-level `REPO_ROOT` exists (monkeypatchable — N-4); the Check 63 entry appends
  after the Check 62 entry; the count bumps 60→61. Cite by content, not line (N-1). **SUPPORTED.**

**EB-6 — measured post-Check-63 README figure + exact ranges (CHANGED — MUST-1).**
- Command (importlib): distinct numbered checks (sorted) =
  `[1,2,3,4,5,6,7,8,9,10,11, 16,17,18,19,20, 22,23, 25,26,27, 29,30,...,62]` → **55** distinct, max **62**.
- Command (importlib): gaps in `1..max` = `[12, 13, 14, 15, 21, 24, 28]`.
- Interpretation: today 55 distinct numbered → after Check 63, **56** distinct numbered, max **63**. The
  empirically-correct README headline = `56 invoked checks`; the exact contiguous ranges (post-Check-63)
  = `Check 1–11, 16–20, 22–23, 25–27, 29–63` (gaps 12–15, 21, 24, 28 absent). "Increment 48 by one" and
  "extend the tail to …63" are BOTH wrong; the full parenthetical must be rewritten (or collapsed to the
  registry-SoT pointer). **SUPPORTED (MUST-1 numbers confirmed).**

**EB-7 — trinity insertion anchors (unchanged anchor for C3).**
- Command: `grep -nE "^### Repo conventions|^### Project goals|rationale: dependency-direction-placement"
  CLAUDE.md AGENTS.md GEMINI.md` → CLAUDE.md: conventions 488, dep-direction bullet 595, Project goals 597;
  AGENTS.md: 447 / 554 / 556; GEMINI.md: 424 / 531 / 533.
- Interpretation: clean append point at the end of `### Repo conventions` in all three. **SUPPORTED.**

**EB-8 — `.graphifyignore` content source (unchanged; fnmatch-validated by design EE-8).**
- Command: read design §4.3 (the verbatim block) — the coder copies it byte-for-byte; the design's EE-8
  already fnmatch-validated the D1/D2 globs. This planner did NOT re-run the matcher probe (the design is
  authoritative; re-probing would build no value and risks writing a `.graphify*` file into the repo).
- Interpretation: the C1 `.graphifyignore` is the design §4.3 content verbatim. **SUPPORTED (by design
  authority; not re-probed — boundary-safe).**

**EB-9 — Check 46 + reference surfaces: no record needed for the new rule (CHANGED framing — SHOULD-3).**
- Command: `grep -c "graph-first" pack-ops/.spawn-rule-manifest.txt` → `0` (absent); the manifest header
  records ONLY rules whose former PACK-AGENTS.md/PACK-CHAT.md restatements were collapsed to one-line
  references; Check 46 (`check_boundary_and_spawn_pointer_manifests`) iterates the records PRESENT, not
  every corpus slug.
- Interpretation: the new `### Repo conventions` rule has no collapsed restatement → no manifest record,
  no reference-surface touch, Check 46 unaffected. This is STATE-VERIFIABLE → the plan ADOPTS the
  no-touch conclusion and does NOT gate C3 on a user reply (SHOULD-3). Steps 4/5 of the propagation
  procedure are N/A. **SUPPORTED.**

**EB-10 — `validate-pack.py` IS a fixture input; the test is NOT (CHANGED framing — SHOULD-2).**
- Command: `scripts/lib/manifest-inputs.sh` input globs include `scripts/*`; deny set =
  `scripts/test*.sh`, `scripts/tests/*`, `scripts/manifest-sync.sh`, `scripts/lib/manifest-inputs.sh`.
  `scripts/validate-pack.py` matches `scripts/*` and is NOT denied → fixture input;
  `scripts/tests/test-validate-pack-check-63.sh` matches the deny glob `scripts/tests/*` → NOT an input.
- Interpretation: the manifest-INPUT change is introduced in **C2** (the `validate-pack.py` edit); the
  push (after C2 lands) triggers `manifest-sync.sh` (expect exit 10). The new test file does not;
  `graphify-out/` is never a fixture input. **SUPPORTED.**

**EB-11 — OPTIONAL-FEATURES.md structure + worktree section (unchanged anchor for C4).**
- Command: `wc -l pack-ops/OPTIONAL-FEATURES.md` → `324`; the tail is the "Adding new entries" template;
  the existing `## Claude Code — Isolated parallel agents (worktree isolation)` section is at line `111`.
- Interpretation: the C4 `## Graphify` section appends following the documented entry shape; the D4(a)
  cross-reference target (the worktree-isolation section) exists at line 111. **SUPPORTED.**

**EB-12 — the 3 doomed docs exist (unchanged anchor for C5).**
- Command: `ls maintenance-docs/v11-research/RESEARCH-GRAPHIFY-{EXTERNAL,PACK-INTEGRATION,SYNTHESIS}.md`
  → all 3 present.
- Interpretation: C5's deletion targets exist. **SUPPORTED.**

**EB-13 — dangling-ref census with the CORRECTED archive split (CHANGED — SHOULD-1 + NIT-2).**
- Command: `git grep -nE "RESEARCH-GRAPHIFY-(EXTERNAL|PACK-INTEGRATION|SYNTHESIS)"` (full repo). Results,
  categorized:
  - **3 LIVE refs** (fix in C5): `RESEARCH-CLAUDE-REPOS-SURVEY.md:271`,
    `TOUCH-POINT-INVENTORY-GROUPINGS-V2.md:128`, `V11.1-DISCUSSION-GITHUB-PROJECTS.md:338`.
  - **2 archive files with LIVE PROSE refs (0 `??`-snapshot lines):**
    `maintenance-docs/archive/v11/ARCHITECTURE-PER-ENTRY-FLAT-FILES.md` (16 prose ref lines, e.g. 40, 44,
    110–111, 439, 699, 773, 815, 837, 1215, 1408, 1478) — measured `??`-snapshot count = `0`;
    `maintenance-docs/archive/v11/PACK-REVIEW-ARCHITECTURE-PER-ENTRY.md` (10 prose ref lines, 276, 278,
    532–539) — measured `??`-snapshot count = `0`.
  - **2 archive files with `??`-snapshot lines (0 prose refs):**
    `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-146.md` (3 `??`-snapshot lines, 21–23);
    `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-149.md` (3 `??`-snapshot lines, 204–206).
  - **3 non-archive `??`-snapshot files (live tree):**
    `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-120.md` (25–27);
    `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-150.md` (26–28);
    `maintenance-docs/v11-implementation/PACK-REVIEW-BD-120.md` (158–160).
  - **BD-225 self-refs:** `DESIGN-BD-225-GRAPHIFY-PACK-INTEGRATION.md` (586–588 + the §9.2(d) repoint
    descriptions); `RESEARCH-BD-225-GRAPHIFY-INCLUSION.md:224`.
- Command (per-archive-file `??`-count, verbatim): ARCHITECTURE → `0`, PACK-REVIEW → `0`, BD-146 → `3`,
  BD-149 → `3`.
- Command (NIT-2): `grep -in graphify maintenance-docs/v11-implementation/REVIEW-BD-096.md` →
  `38:91e7563 docs: v11 — Graphify + Claude-ecosystem-repos research artifacts`;
  `grep -nE "RESEARCH-GRAPHIFY-(EXTERNAL|PACK-INTEGRATION|SYNTHESIS)" .../REVIEW-BD-096.md` → (empty).
- Interpretation: the prior plan's/design's "all 4 archive = same `??`-snapshot pattern" is FALSE for 2
  of 4 (ARCHITECTURE + PACK-REVIEW carry PROSE refs, 0 `??`-lines). The DISPOSITION (leave all 4 frozen)
  is correct on the FROZEN-ARCHIVE ground (all 4 live under `archive/v11/`). The completeness-gate
  allow-set is corrected to name the 2 PROSE-ref archive files explicitly so the reviewer does not
  false-flag. NIT-2: `REVIEW-BD-096.md:38` is a commit-log line, NOT a dangling ref → out of scope.
  **SUPPORTED (SHOULD-1 + NIT-2 confirmed).**

**EB-14 — propagation procedure Step 3 is the MEMORY.md step (unchanged anchor for §E).**
- Command: `grep -nE "Rule-change propagation|memory-cache pointer" pack-ops/PACK-CHAT.md` → the
  "Rule-change propagation procedure" table, row 3: `Thin memory-cache pointer (out-of-repo) | Pack-Chat
  upkeep; trinity-wins (no validator gate, no pack generator)`.
- Interpretation: Step 3 IS the out-of-repo MEMORY.md pointer step; it contradicts the HARD NO-MEMORY.md
  directive → DROPPED here + FLAGGED for BD-232; PACK-CHAT.md NOT patched. **SUPPORTED.**

---

## §13. Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | Read-only git only: `git rev-parse HEAD` → `5f56a35dea0d7bde3777ce8ff27f864e5819b01a`; `git branch --show-current` → `v11-dev`; `git grep`, `git ls-files`. NO add/commit/push/rm/checkout/worktree. Sole write = this plan via `cat >`/`>>` heredoc to the caller-specified path. | COMPLIANT |
| 2 | per-action-approval-sub-agents | No destructive op; read-only except the plan doc. NO graph built/indexed in the pack repo; NO `.graphify*` written; the archive `??`-vs-prose split was measured with `git grep`/`grep -c` only (no graphify invoked). | COMPLIANT |
| 3 | agents-read-rule-docs-in-full | Read IN FULL: the approved DESIGN (939 lines, both pages), the prior PLAN (690 lines, both pages), `PLAN-BD-225-ADVERSARIAL-REVIEW.md` (the fix-list source, full); CLAUDE.md `## Pack memory` (incl. the in-force rules); re-inspected `scripts/validate-pack.py` registry (importlib), README lines 60/190, `.gitignore`, the trinity anchors, the archive-ref census. | COMPLIANT |
| 4 | architect-planner-empirical-evidence | §12 re-measures the CHANGED claims with command + verbatim output + HEAD `5f56a35` + date 2026-06-18 + conclusion: EB-4/EB-6 (README headline 48 + ranges `16–23`, `25–51`; registry 55 distinct, gaps `[12,13,14,15,21,24,28]`, post-63 = 56 / ranges `1–11,16–20,22–23,25–27,29–63`); EB-13 (archive split: ARCHITECTURE `??`=0 / PACK-REVIEW `??`=0 / BD-146 `??`=3 / BD-149 `??`=3; NIT-2 REVIEW-BD-096:38 commit-log, 0 doomed-doc refs). NOT cited from the design's `0a90f56` evidence. | COMPLIANT |
| 5 | user-prescriptive-authority | M-1=(b) (leave archive frozen) + the fix-list are user-locked; applied EXACTLY — disposition UNCHANGED, only characterization/gate-wording/README-completeness/clarity corrected. NIT-1 left out of scope as directed. No locked decision re-opened. | COMPLIANT |
| 6 | NO MEMORY.md (HARD) | This revision adds ZERO MEMORY.md pointer; §A.3 + §E row 3 + this block confirm the rule lives ONLY in the in-repo corpus; Step 3 dropped + flagged BD-232. `grep` of this plan for "MEMORY.md" shows only the NO-MEMORY.md prohibition prose, no pointer add. | COMPLIANT |
| 7 | bd-pack-only / pack-project-separation | Every commit is `pack-only`; the rule is pack-root trinity only (C3), NEVER `project-template/`; client-facing `DEPENDENCIES.md` untouched (§A.3); EB-1 boundary grep → 0. | COMPLIANT |
| 8 | enumerate-encoding-surfaces | C2 ships Check 63 as validator + registry entry + count bump + comment + per-check test + BOTH README instances (MUST-1: full parenthetical, both internally consistent); C3 ships the trinity tag + the rationale section together (Check 45); the C5 completeness-gate allow-set enumerates every frozen surface precisely (SHOULD-1: 2 prose-ref + 2 `??`-archive + 3 `??`-non-archive). | COMPLIANT |
| 9 | fail-loud-delete-old-source | C5 deletes the 3 stale docs ENTIRELY (no banner/archive); fixes all 3 LIVE dangling refs; leaves the frozen allow-set untouched (M-1=(b)); the corrected zero-dangling gate enforces it. This plan OVERWRITES the prior PLAN entirely (no mirror) via `cat >`. | COMPLIANT |
| 10 | verify-full-ci-suite | §F judges EACH of the 5 commits against the FULL battery (validate-pack ALL + `scripts/tests/*.sh` incl. the new Check-63 test + integration + boundary grep + push-time manifest-sync), not just validate-pack; SHOULD-2 names C2 as the manifest-input-changing commit. | COMPLIANT |
| 11 | scope-deliverables-to-the-ask | Applied ONLY the fix-list (M-1(b)/SHOULD-1/MUST-1/SHOULD-2/SHOULD-3/NIT-2); the 5-commit structure, B-1 bijection, M-3, G1–G3, Check 63 lockstep, `.graphifyignore` content, flag discipline, NO-MEMORY.md all UNCHANGED; NIT-1 left out of scope; design §9 FLAGGED not edited. No re-plan, no new scope. | COMPLIANT |
| 12 | agent-output-rules-applied-block | This block: one row per in-force rule (1-12), quoted evidence, terminal conclusion; no AMBIGUOUS, no empty evidence. | COMPLIANT |
