<!-- PACK-REVIEW-BD-211-C1.md — read-only review of BD-211 Commit C1 (pack-side data fix) -->
# PACK-REVIEW-BD-211-C1 — Tokenless suffix fold + BD-195 normalization

**Verdict: PASS.** Branch `v11-dev`, HEAD `7bdb33f` (uncommitted working tree).
All 7 checks clean. No content lost (verbatim except the two documented scrubs).
Zero suffix tokens in the data entries. validate-pack GREEN; full CI suite
(51 test scripts + validate-pack) GREEN. Scope is backlog-only / pack-only.
No fixes required.

## Check results

### 1. No content lost (CRITICAL) — PASS
Field-by-field diff of each folded `## Sub-entry b` section (stripped of its H2
label + provenance line) against `git show HEAD:backlog/BD-16Xb.md` (stripped of
the line-1 back-pointer + line-2 suffix header) yields exactly ONE delta each —
the documented scrub:

- **BD-167b** (`File/Symbol` bullet): `… NOT in BD-167b)` → `… NOT in this
  sub-entry)`. All other fields (Type / Status / `Blockers: BD-167` / Unblocks /
  every File-Symbol bullet / Description / Resolved) preserved VERBATIM.
- **BD-169b** (`Description`): `… §6.1 BD-169b sample text.` → `… §6.1 sample
  text.`. All other fields (Type / Status / `Blockers: BD-169` / Unblocks / both
  File-Symbol bullets / Resolved) preserved VERBATIM.

The only other dropped lines are the source line-1 back-pointer and the line-2
suffix header — neither carries live field content (the title survives in the H2
label). Parent `Blockers: BD-167`/`BD-169` refs preserved. Matches the
ARCHITECTURE §2.2 / §2.2.1 recipe exactly. No live content loss before the
worktree `rm`.

### 2. Tokenless data entries — PASS
`grep -n 'BD-167b\|BD-169b' backlog/BD-167.md backlog/BD-169.md backlog/BD-195.md
backlog/BD-211.md` → **zero matches** (exit 1). The only remaining `backlog/`
tokens are `backlog/_rules.md:31,32,33,38` — grammar documentation (the per-entry
filename-grammar spec, e.g. "admitting the sub-entry forms `BD-167b.md` /
`BD-169b.md`"), NOT cross-refs. Per the prompt these are **C2's scope**, not a C1
finding. Confirmed they are the ONLY remaining occurrences and all are grammar
prose.

### 3. No Check-34 dangling + full validate — PASS
`python3 scripts/validate-pack.py` → `PASSED — all checks clean` (exit 0).
Check 33 (TOC-in-sync) green after regen; Check 34 (cross-reference integrity)
green — no dangling `BD-167b`/`BD-169b` (the BD-169 cross-ref was repointed to
the tokenless `the sub-entry b section below`, §2.3). Check 48 emits 14
pre-existing advisory WARNs (removed-doc citations in unrelated entries —
`GEMINI-CLI-ANALYSIS.md`, `V10-PREDESIGN.md`, etc.); advisory only, exit code
unaffected, NOT introduced by C1.

### 4. BD-195 normalized correctly — PASS
Line 2 is now exactly:
`**BD-195 — v11.0 pristine-state recovery before BD-185 restart (full-repo) (Code Red 3)**`
— nothing between ID and em-dash; `(Code Red 3)` at end inside the bold span,
after `(full-repo)`. `git diff backlog/BD-195.md` shows ONLY line 2 changed.
`Alias:` line (line 6) unchanged; no other line in BD-195.md changed.

### 5. Deletion + TOC — PASS
`backlog/BD-167b.md` and `backlog/BD-169b.md` gone from the worktree (`git
status`: `D` both). `backlog/_toc.md` has **211** entry rows (== 211 entry files;
was 213 with the two suffix entries → 211 post-fold). No BD-167b/BD-169b rows
(removed). BD-195's row retitled to `… (full-repo) (Code Red 3)`. TOC is the
regenerated artifact (matches `per_entry_regenerate_toc` output).

### 6. Full CI suite — PASS
Enumerated all CI commands from `.github/workflows/validate-pack.yml`: the
`validate` job (`validate-pack.py`) + the `tests` job (51 `*-test.sh` /
`test-*.sh` scripts + `test-fixtures/build.sh`). Ran ALL (not a subset — the C-5
lesson):

```
validate-pack.py : PASSED — all checks clean
test scripts     : PASS=51  FAIL=0
```

(51 scripts covered: detect, migrator core/manifest/skills/capability-translation,
persona-contracts, pack-help, recommendation(+schema), template-translations/
-version, customization-preserve, init-project, issue-forms, migrate-v10-to-v11
×4, per-entry, tracker ×17, validate-pack per-check ×14 incl. 32-33-34 and
removed-doc-advisory, and **test-v11-realistic-ot.sh** — the integration test that
caught the BD-203 C-1 banner regression.)

**Manifest:** `bash test-fixtures/build.sh --all --clean` (exit 0) leaves
`test-fixtures/manifest.txt` UNCHANGED (`git diff --stat` empty). Confirmed: a
`backlog/`-only diff is not a manifest source surface (manifest tracks
`project-template/` + `scripts/` + `pack-ops/` + `supporting-docs/`).

### 7. Scope = pack-only / backlog-only — PASS
Tracked changes: `M backlog/{BD-167,BD-169,BD-195,BD-211,_toc}.md`,
`D backlog/{BD-167b,BD-169b}.md` — exactly the expected 7, ALL under `backlog/`.
Nothing outside `backlog/` is tracked-modified. Untracked: only the 4 BD-211
maintenance-docs (ARCHITECTURE / PLAN / IMPL-REPORT / RESEARCH) — out of band,
not part of C1's tracked diff. No `project-template/` or `supporting-docs/` touch
→ pack-only keyword would hold under Check 36.

## Severity-ranked findings

**None.** (No BLOCKER / MUST / SHOULD / NIT.) C2's `_rules.md` grammar tokens are
noted per the prompt as out-of-C1-scope, not a finding.

## Rules-Applied Verification Block

| Rule | Evidence | Conclusion |
|---|---|---|
| Fail-loud / safe-before-delete (every sub-entry field in parent before file delete; no content lost) | `diff` of folded section vs `git show HEAD:` source = exactly 1 delta each = the documented scrub; all Type/Status/Blockers/Unblocks/File-Symbol/Description/Resolved preserved verbatim; old source files DELETED (`D` in `git status`) | COMPLIANT |
| Tokenless (no-letter-suffix) | `grep 'BD-167b\|BD-169b'` over the 4 data entries → zero (exit 1); only `_rules.md` grammar tokens remain (C2 scope) | COMPLIANT |
| Verify the FULL CI suite | validate-pack `PASSED — all checks clean` + 51/51 test scripts PASS (incl. test-v11-realistic-ot.sh integration test); manifest unchanged after rebuild | COMPLIANT |
| Pack/project separation | `git status` tracked changes all under `backlog/`; nothing in `project-template/` or `supporting-docs/`; untracked = maintenance-docs only | COMPLIANT |
| Empirical evidence + Rules-Applied block | Every check above quotes the actual command/output (diffs, grep exits, validate-pack tail, 51/51 aggregate, manifest `git diff --stat` empty) | COMPLIANT |

## Read-doc verification

| Doc | Read? | Evidence |
|---|---|---|
| PLAN-BD-211.md § Commit C1 | YES | tokenless recipe cross-checked against impl |
| ARCHITECTURE-BD-211.md §2.1/2.2/2.2.1/2.3 | YES | §2.1 normalization, §2.2 fold shape, §2.2.1 grep-zero EE-block, §2.3 cross-ref repoint — all matched in the worktree |
| `git show HEAD:backlog/BD-167b.md` + `BD-169b.md` | YES | pre-deletion sources diffed field-by-field against folded sections |
| changed files (BD-167/169/195/211, _toc) | YES | full `git diff` + `Read` of folded BD-167/169/195 |
| `.github/workflows/*.yml` | YES | `validate-pack.yml` — enumerated all 51 test cmds + validate + manifest gate |
| CLAUDE.md ## Pack memory | YES | applied fail-loud-delete, no-letter-suffix, verify-full-CI, pack/project-separation rules |
| coder IMPL-REPORT | NO (per prompt — verified independently) | not read; all findings derived from primary state |
