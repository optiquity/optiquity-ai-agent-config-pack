# PACK-REVIEW — BD-175 Commit 10 (TASK-T8 OPTIONAL-FEATURES SPLIT)

**Reviewer:** pack-reviewer
**Date:** 2026-05-19
**Commit reviewed:** `4e240ec` (`feat: v11 — BD-175 TASK-T8 OPTIONAL-FEATURES SPLIT (Override 8 + S3)`)
**HEAD at review:** `4e240eca46e33940e52e3ab5953b406f72e4e832`
**Plan reference:** `PLAN-BD-175-PHASE-5.md` §2.10 + row 10 of §4.2 table
**Architecture references:** `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §6.1 TASK-T8; `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` §13 (§13.1 - §13.6)

---

## §1 Verdict

**GO.**

The commit implements TASK-T8 SPLIT to spec. The 9-row §13.3 content-split table is applied row-by-row in the new project-side file with disciplined audience-tailoring; §13.5 TYPE-2 contamination avoidance shows zero hits on the prescribed deny-grep markers; A4-A8 verify-only outcomes all resolve at client repos post-install; the dual init-project.sh path coverage (S6 fresh-install glob + cmd_update explicit mapping) is correctly diagnosed and addressed; D8.7 ref-update lands cleanly; manifest regen produces the expected 3-v11-row drift with v10-* tag-pinned rows unchanged. Scope discipline holds at exactly 5 files (4 in-scope + IMPL-REPORT), zero trinity edits, zero pack-ops/ edits, zero MERGE-STRATEGY.md edits (the latter being Commit 9b's scope). The 188-vs-180 line-count overshoot is bounded content density (4.4% over the upper "approximate" target), not contamination spillage, and is documented as a judgment call in the IMPL-REPORT.

No BLOCKER, no MUST, no SHOULD findings. Two NIT-class observations are noted in §4 with FIX-or-defer recommendations.

---

## §2 Independent findings

### §2.1 — §13.3 9-row content-split audit (per-row independent assessment)

Each row of the §13.3 table audited against the new project-side file. Reviewer formed independent decisions before reading the IMPL-REPORT §3 table.

| # | Section / row | §13.3 spec | Reviewer-observed outcome | Verdict |
|---|---|---|---|---|
| 1 | Intro paragraphs (lines 1-15 pack-side) | ADAPT (project-PM voice) | Lines 3-15 of new file: "your project can opt into ... without abandoning the cross-CLI parity the Config Pack provides by default" + "Your project stays cross-CLI by default." Pack-side equivalent reads "The Config Pack stays cross-CLI by default." Voice shift confirmed. | PASS |
| 2 | `## Claude Code — Agent Teams` | ADAPT (project-side agent paths + project-side use cases) | Lines 19-92 use "Your project's existing pack agents (at `.claude/agents/<name>.md`)" + explicit `.claude/agents/coder.md`, `.claude/agents/reviewer.md`, `.claude/agents/tester.md` examples in the invocation block. Pack-side equivalent at lines 62-80 references "pack agents at `.claude/agents/<name>.md`" (same path but different framing — pack-side is "the pack's agents", project-side is "your project's existing pack agents"). ADAPT executed. | PASS |
| 3 | `## Codex CLI — Optional features` | KEEP placeholder | Lines 96-99 placeholder. | PASS |
| 4 | `## Gemini CLI — Optional features` | KEEP placeholder | Lines 103-106 placeholder. | PASS |
| 5 | Tracker integration — pack surface | DROP (pack-repo CWD, pack-side example, pack-side signals) | Zero hits on `pack-repo CWD`, `tracker.toml.pack-example`, `pack-side signals`, or `pack-self-specific` patterns; "How to enable" at L129 reads "from your project repo root" (not the pack-side `from the pack repo or a pack-configured project`). DROP executed. | PASS |
| 6 | Tracker integration — project surface | KEEP FULL (client CWD, client tracker.toml.example, project-side signals, client-side failure modes) | L138-142 covers `tracker.toml` at project root + `tracker.toml.example` installed by `init-project.sh`. L120-121 covers project-side signals (open BD count in your project, BACKLOG size, 30-day growth). L150-152 covers client-side failure modes (`gh auth login` against right account, `gh repo view` from project root). KEEP FULL executed. | PASS |
| 7 | `customization-detected-needs-reconciliation` ref | KEEP with "in the pack repo" qualifier | L174 reads `See \`MERGE-STRATEGY.md\` in the pack repo for the per-file class matrix and sidecar conventions.` Qualifier present per §13.5 TYPE-4 prevention. Note: coder used bare `MERGE-STRATEGY.md` + qualifier (rather than `pack-ops/MERGE-STRATEGY.md` + qualifier). This is a SOUND simplification — the qualifier alone resolves the resolution, and bare-with-qualifier carries less TYPE-2 path leakage than path-with-qualifier. Acceptable per §13.3 row (the row offers both forms; the simpler form was chosen). | PASS |
| 8 | Pack-tracker plumbing details | OMIT entirely (validate-pack Check 22, STREAMS, per-entry-tree contract) | Zero hits on `STREAMS`, `Check 22`, `validate-pack`, `per-entry`, `_rules.md`, `cycle_check_k`, `ARCHITECTURE-V3`, `BD-109`, `BD-110`, `auditor-issue-tracking`, `scripts/lib/tracker-provider.sh`. OMIT executed. Note: the `TrackerProvider` abstraction is mentioned at L114 ("Other backends plug in via the TrackerProvider abstraction but are not implemented in v11") but the pack-internal IMPLEMENTATION PATH `scripts/lib/tracker-provider.sh` is correctly OMITTED — the abstraction-name mention is user-facing tracker behavior, the path is pack-internal plumbing. The distinction is exactly the §13.5 line. | PASS |
| 9 | `## Adding new entries` | KEEP-OR-ADAPT (project-side framing) | Lines 181-188 reframed as "If your project adopts a CLI-specific opt-in feature the pack does not yet document..." + "Most projects will not need to add entries — the pack ships the common cross-CLI feature catalog." ADAPT with project-side framing. Pack-side equivalent at L223-235 reads "When a CLI ships an optional or experimental feature that the Config Pack can plug into, add a section here..." — pack-contributor voice. ADAPT executed. | PASS |

All 9 rows: PASS.

### §2.2 — §13.5 TYPE-2 contamination avoidance audit

Independent greps run on the new file:

```
$ grep -n "STREAMS\|Check 22\|validate-pack" project-template/docs/pack/OPTIONAL-FEATURES.md
(no output — zero hits)

$ grep -n "tracker.toml.pack-example" project-template/docs/pack/OPTIONAL-FEATURES.md
(no output — zero hits)

$ grep -n "pack-ops/" project-template/docs/pack/OPTIONAL-FEATURES.md
(no output — zero hits)

$ grep -n "per-entry\|per entry\|_rules.md" project-template/docs/pack/OPTIONAL-FEATURES.md
(no output — zero hits)

$ grep -n "cycle_check\|graph\|ARCHITECTURE-V3" project-template/docs/pack/OPTIONAL-FEATURES.md
(no output — zero hits)
```

All §13.5 markers absent. The only `pack` reference patterns present are:

- L27: "Your project's existing pack agents (at `.claude/agents/<name>.md`)" — project-user-facing reference to the AGENT FILES the pack installs.
- L83-85: "Teams config is per-team, not per-project ... `~/.claude/teams/{team-name}/config.json`; the pack does not ship a team configuration." — describes pack non-shipment, not a pack-internal path.
- L114: "TrackerProvider abstraction but are not implemented in v11" — user-facing abstraction name only; no pack-internal path.
- L171: "project-side and pack-side edits ... real-merge case" — describes the failure-mode contract handled by the migrator (which the project user encounters at `pack tracker init` time).
- L174: "See `MERGE-STRATEGY.md` in the pack repo" — the prescribed qualified reference per §13.3 row 7.
- L183, L187: "the pack does not yet document" / "the pack ships the common cross-CLI feature catalog" — descriptive of what the pack provides to the project.

None of these are TYPE-2 contamination. All six classes of "pack" mention are project-USER-facing descriptions of pack-supplied artifacts or pack-vs-project semantics that a project user encounters at the user-facing surface. The §13.5 contract is satisfied.

### §2.3 — Project-user voice audit

The new file reads as written FOR project users at THEIR client repo. Greps for residual pack-maintainer-only vocabulary:

- "pack root" / "pack-internal" / "pack-self" / "pack-maintainer" / "pack-side framing": zero hits.
- "STREAMS" / "Check 22" / "validate-pack": zero hits.
- "tracker.toml.pack-example": zero hits.
- "pack-ops/": zero hits.

The "your project" / "your client repo" framing dominates (24 occurrences of "your project" / "project root" / "project agents" / etc. confirmed via grep at §2.2). Voice audit: PASS.

### §2.4 — `scripts/init-project.sh` install stage audit

**S6 fresh-install path (lines 537-597):** The S6 stage loop at L544 reads `for f in "$pack_docs"/*.md; do` where `pack_docs="$PACK/project-template/docs/pack"` (L539). This glob iterates every `.md` file under `project-template/docs/pack/` and copies via `cp` (L550) or `existing_classifier_copy` (L548). The new `OPTIONAL-FEATURES.md` file lands in this directory and is auto-picked-up by this glob. Precedent: the existing sibling files (HELP-FRAGMENT.md, HELP-FRAGMENT-TRACKER.md, PACK-FEEDBACK.md, PLATFORM-SKILLS.md, PM-CHAT.md, PROMPT-TEMPLATES.md) all install via this glob with no per-file special-casing in S6. NO S6 EDIT NEEDED. The coder correctly identified this and applied no S6 edit.

**`cmd_update` path (lines 1108-1132):** This is an explicit per-file mapping array. The coder added `OPTIONAL-FEATURES.md` at L1125 between `HELP-FRAGMENT-TRACKER.md:docs/pack/HELP-FRAGMENT-TRACKER.md:generic` (L1124) and `tracker.toml.project-example:tracker.toml.example:generic` (L1126). The `generic` class matches the precedent for sibling docs at L1120-L1124. Without this entry, `init-project.sh --update` on an existing pack-configured project would silently fail to refresh `docs/pack/OPTIONAL-FEATURES.md` — a regression vs the precedent for siblings.

**Smoke tests executed independently by reviewer:**

```
$ mkdir /tmp/optfeat-test-fresh3; cd /tmp/optfeat-test-fresh3; git init -q
$ yes | PACK=/Users/.../v11-dev bash scripts/init-project.sh /tmp/optfeat-test-fresh3
$ ls /tmp/optfeat-test-fresh3/docs/pack/OPTIONAL-FEATURES.md
-rw-r--r-- ... 7872 May 19 15:02 .../OPTIONAL-FEATURES.md   [fresh install: PASS]

$ rm /tmp/optfeat-test-upd/docs/pack/OPTIONAL-FEATURES.md
$ yes | PACK=... bash scripts/init-project.sh --update /tmp/optfeat-test-upd
$ ls -la /tmp/optfeat-test-upd/docs/pack/OPTIONAL-FEATURES.md
-rw-r--r-- ... 7872 May 19 15:03 .../OPTIONAL-FEATURES.md   [--update restore: PASS]
```

Both paths produce the same 7872-byte file (matches `wc -c` on the source). Install plumbing: PASS.

### §2.5 — `supporting-docs/DEPENDENCIES.md:162` D8.7 audit

Diff:
```
-See `OPTIONAL-FEATURES.md` § "Tracker integration (v11)" for the full
+See `docs/pack/OPTIONAL-FEATURES.md` § "Tracker integration (v11)" for the full
```

The change is exactly the §3.5 D8.7 implementation hint: REPLACE bare `OPTIONAL-FEATURES.md` with `docs/pack/OPTIONAL-FEATURES.md`. The surrounding paragraph still reads naturally:

```
- Verify: `gh sub-issue --help` exits 0.
- Reference: https://github.com/yahsan2/gh-sub-issue

See `docs/pack/OPTIONAL-FEATURES.md` § "Tracker integration (v11)" for the full
walkthrough.
```

Only one OPTIONAL-FEATURES reference exists in DEPENDENCIES.md per `grep -n`. D8.7: PASS.

### §2.6 — `test-fixtures/manifest.txt` audit

```
$ git show 4e240ec -- test-fixtures/manifest.txt
-v11-realistic-ot  d409ff7f8fb256db1948da1f35e65c832ba6637b
-v11-flat-file  e522d9b424a2db43aaa01e2148372f2b9c62a62b
-v11-tracker-on  fe4c1d5bdf7167b30636a05ad0c376424a65c684
+v11-realistic-ot  07bebb297174b5c4e4fac523fb0aa0b05249358a
+v11-flat-file  ac200c28852f5fac70f37a7541b2b538d8d18bc2
+v11-tracker-on  2d9811a5415c76ba865ca793a2e4cc5ee53ae6f0
```

3 v11-* rows changed; v10-* tag-pinned rows unchanged; `existing-project-mid-dev` (synthesized pre-install shape) unchanged. Independent verify:

```
$ bash test-fixtures/build.sh --verify
  v10-minimal OK: 19558cbac58ed3e47642a6bbe64418a38c60bc16
  v10-realistic-ot OK: 4c62945f72b037908b38967d5d8f019745263258
  v11-realistic-ot OK: 07bebb297174b5c4e4fac523fb0aa0b05249358a
  v11-flat-file OK: ac200c28852f5fac70f37a7541b2b538d8d18bc2
  v11-tracker-on OK: 2d9811a5415c76ba865ca793a2e4cc5ee53ae6f0
  existing-project-mid-dev OK: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

All 6 rows verify clean at HEAD. RC9 regen: PASS.

### §2.7 — A4-A8 verify-only audit (independent grep)

Reviewer grep across `project-template/`:

```
$ grep -rn "OPTIONAL-FEATURES" project-template/ --include="*.md" --include="*.toml"
project-template/.gemini/commands/pack-help.toml:11:docs/pack/INSTALL-PROCEDURES.md, and docs/pack/OPTIONAL-FEATURES.md.
project-template/.claude/skills/pack-help/SKILL.md:14:`docs/pack/INSTALL-PROCEDURES.md`, and `docs/pack/OPTIONAL-FEATURES.md`.
project-template/.codex/skills/pack-help/SKILL.md:14:`docs/pack/INSTALL-PROCEDURES.md`, and `docs/pack/OPTIONAL-FEATURES.md`.
project-template/docs/pack/HELP-FRAGMENT-TRACKER.md:49:See the tracker example template (`tracker.toml.pack-example` in the pack repo, or `tracker.toml.example` at a client project root) and `OPTIONAL-FEATURES.md` for full setup.
project-template/docs/pack/HELP-FRAGMENT.md:5:`docs/pack/INSTALL-PROCEDURES.md`, `docs/pack/OPTIONAL-FEATURES.md`.
project-template/docs/pack/HELP-FRAGMENT.md:31:`docs/pack/PLATFORM-SKILLS.md`, `docs/pack/OPTIONAL-FEATURES.md`,
```

5 files / 6 hit locations. Each resolves at client repos post-install:

| Ref | File | Line | Form | Post-install resolution |
|---|---|---|---|---|
| A4 | `project-template/.gemini/commands/pack-help.toml` | 11 | `docs/pack/OPTIONAL-FEATURES.md` (relative to client root) | `<client>/docs/pack/OPTIONAL-FEATURES.md` — EXISTS |
| A5 | `project-template/.claude/skills/pack-help/SKILL.md` | 14 | `docs/pack/OPTIONAL-FEATURES.md` (relative to client root) | EXISTS |
| A6 | `project-template/.codex/skills/pack-help/SKILL.md` | 14 | `docs/pack/OPTIONAL-FEATURES.md` (relative to client root) | EXISTS |
| A7 | `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` | 49 | bare `OPTIONAL-FEATURES.md` (relative to file's own directory `docs/pack/`) | sibling in same directory — EXISTS |
| A8a | `project-template/docs/pack/HELP-FRAGMENT.md` | 5 | `docs/pack/OPTIONAL-FEATURES.md` (relative to client root) | EXISTS |
| A8b | `project-template/docs/pack/HELP-FRAGMENT.md` | 31 | `docs/pack/OPTIONAL-FEATURES.md` (relative to client root) | EXISTS |

All 6 hits resolve correctly. A4-A8: PASS.

Line-number drift from plan §2.10.2 (which referenced `:12`, `:15`, `:15`, `:49`, `:6`, `:33`) to current (`:11`, `:14`, `:14`, `:49`, `:5`, `:31`) is explained by Commit 11 (Override 10 QUICKSTART removal) landing BEFORE Commit 10 in the parallel ALPHA-EXPANDED set per §8.2.1. Reference text preserved exactly — only positional shift from upstream deletion. NOT a defect.

### §2.8 — Scope discipline audit

```
$ git show 4e240ec --name-status
A	maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-10.md
A	project-template/docs/pack/OPTIONAL-FEATURES.md
M	scripts/init-project.sh
M	supporting-docs/DEPENDENCIES.md
M	test-fixtures/manifest.txt
```

Exactly 5 files: 4 in-scope + IMPL-REPORT. Verified absent:

- No trinity edits (no `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`).
- No `pack-ops/OPTIONAL-FEATURES.md` edits (Commit 2's resting state preserved).
- No `pack-ops/MERGE-STRATEGY.md` edits (Commit 9b's scope).
- No other out-of-scope edits.

Scope: PASS.

### §2.9 — POQ-3-N regression audit

No new pack-side path references introduced by the new file. The single `pack-ops/`-adjacent reference is `MERGE-STRATEGY.md` with the explicit "in the pack repo" qualifier — by design per §13.3 row 7 + Architect C TYPE-4 prevention. This is a properly-qualified pack-side surface, not a POQ-3-N-creating unqualified reference. POQ-3-N regression: NONE.

---

## §3 Compare-to-IMPL-REPORT

After forming the independent findings above, reviewer read `IMPLEMENTATION-REPORT-BD-175-COMMIT-10.md` to cross-check alignment.

### §3.1 — Alignments

- **§13.3 row decisions:** IMPL-REPORT §3 table assigns ADAPT / KEEP / DROP / OMIT / KEEP-qualified / KEEP-OR-ADAPT — matches reviewer's independent §2.1 audit row-for-row.
- **§13.5 contamination grep results:** IMPL-REPORT §9 Command 4b shows zero hits on STREAMS/Check 22/validate-pack/tracker.toml.pack-example/pack-ops/ — matches reviewer's §2.2 independent grep results.
- **A4-A8 grep results:** IMPL-REPORT §6 table matches reviewer's §2.7 grep output exactly.
- **Manifest regen pattern:** IMPL-REPORT §7 + Command 5 matches reviewer's §2.6 (3 v11-* rows, v10-* unchanged, existing-project-mid-dev unchanged).
- **Scope:** IMPL-REPORT §2 + Command 6 lists exactly 4 in-scope files — matches reviewer's §2.8 `git show --name-status`.
- **Init-project.sh dual-path analysis:** IMPL-REPORT §4 + §8.2 correctly diagnoses the S6 fresh-install glob (auto-cover, no edit) vs the `cmd_update` explicit mapping (needs new entry). Matches reviewer's §2.4 independent code inspection.

### §3.2 — Divergences

- **Line count:** IMPL-REPORT §8.1 documents 188 lines vs target 150-180; treats as judgment call. Reviewer concurs — 4.4% over upper bound is well within "approximate" tolerance and the contamination-avoidance contract (which is the load-bearing constraint) is independently satisfied. NO DIVERGENCE on conclusion; both reviewer and coder land on "accept with documented rationale."
- **A4-A8 plan-line-number drift:** IMPL-REPORT §6 paragraph 2 notes the line shift from plan text and attributes it to Commit 11. Reviewer concurs — reference TEXT is preserved exactly, only positions shifted because Commit 11 deleted lines above them in the same files. NO DIVERGENCE.
- **Reference count:** IMPL-REPORT §6 notes plan says "5 references" but counts 6 hits because HELP-FRAGMENT.md has 2 sites. Reviewer's count matches (5 files, 6 hits). NO DIVERGENCE.

### §3.3 — Concurrence summary

Reviewer's independent findings and the IMPL-REPORT's self-assessment ALIGN on every audit dimension. No divergences. The two judgment calls (line count, `--update` path) are documented in the IMPL-REPORT with citations to §13.3 / §13.4 / §13.5 / §2.10.3 — both calls are sound.

---

## §4 Severity-classified findings table

| Severity | File:Line | Finding | Rationale | Suggested fix |
|---|---|---|---|---|
| NIT | `project-template/docs/pack/OPTIONAL-FEATURES.md:174` | The `MERGE-STRATEGY.md` reference is bare (with "in the pack repo" qualifier) rather than the path form `pack-ops/MERGE-STRATEGY.md` (with qualifier). §13.3 row 7 offers both forms; the coder chose the simpler bare-with-qualifier form. | The bare form carries less TYPE-2 path leakage and is consistent with §13.5's anti-contamination spirit. The "in the pack repo" qualifier is enough for the project-user to locate the doc (they would `git clone` the pack repo to read it — they don't navigate by path from inside their own project). The path-with-qualifier form would couple project-side content to the pack's internal directory choice (a brittle coupling). | NONE — accept as-shipped. The bare-with-qualifier form is the cleaner choice and matches §13.5's spirit. Flagged for awareness only; not a fix request. |
| NIT | `project-template/docs/pack/OPTIONAL-FEATURES.md:27` + `:33` | Two instances of phrase "Your project's existing pack agents" / "When this matters for your project." These are project-user-facing descriptions of pack-supplied agents at project-side paths. Not contamination, but slight redundancy with "your project" pattern. | The phrasing is correct — these agents WERE supplied by the pack and DO live in the project. Saying "your project's pack agents" is accurate. Alternative ("your project's installed agents" or "your agents") would lose the provenance signal that helps a project-PM understand why these specific agent definitions exist at `.claude/agents/`. | NONE — accept as-shipped. The current phrasing is the most accurate available; alternatives lose provenance signal. Flagged for awareness only. |

**No BLOCKER, no MUST, no SHOULD findings.**

The two NITs above are flagged for completeness per pack-memory `feedback_fix_all_review_findings`. Both are explicitly assessed as "NONE — accept as-shipped" rather than fix-or-defer because the current implementation is the better available choice on review, not a defect. Surfacing them lets Pack Chat triage zero-action confirmation rather than skipping the review's full-coverage discipline.

---

## §5 Verification commands run

```
# §1 — Sanity
git rev-parse HEAD                              → 4e240eca46e33940e52e3ab5953b406f72e4e832
git show 4e240ec --stat                         → 5 files / +680/-4 lines
git show 4e240ec --name-status                  → 1 A IMPL-REPORT + 1 A new file + 3 M

# §2.1 — Section structure
grep -nE "^#+ " project-template/docs/pack/OPTIONAL-FEATURES.md
                                                → 6 top-level headings matching §13.1 inventory

# §2.2 / §2.3 — §13.5 contamination + voice
grep -n "STREAMS\|Check 22\|validate-pack" project-template/docs/pack/OPTIONAL-FEATURES.md
                                                → (zero hits)
grep -n "tracker.toml.pack-example" project-template/docs/pack/OPTIONAL-FEATURES.md
                                                → (zero hits)
grep -n "pack-ops/" project-template/docs/pack/OPTIONAL-FEATURES.md
                                                → (zero hits)
grep -n "per-entry\|per entry\|_rules.md" project-template/docs/pack/OPTIONAL-FEATURES.md
                                                → (zero hits)
grep -n "cycle_check\|graph\|ARCHITECTURE-V3" project-template/docs/pack/OPTIONAL-FEATURES.md
                                                → (zero hits)
grep -n "pack repo\|pack root\|pack-internal\|pack-self\|pack-maintainer" project-template/docs/pack/OPTIONAL-FEATURES.md
                                                → 1 hit at L174 (prescribed "in the pack repo" qualifier)

# §2.4 — init-project.sh smoke tests
mkdir /tmp/optfeat-test-fresh3 && git init -q (in there)
yes | PACK=... bash scripts/init-project.sh /tmp/optfeat-test-fresh3
ls /tmp/optfeat-test-fresh3/docs/pack/OPTIONAL-FEATURES.md
                                                → 7872 bytes ✓
rm /tmp/optfeat-test-upd/docs/pack/OPTIONAL-FEATURES.md
yes | PACK=... bash scripts/init-project.sh --update /tmp/optfeat-test-upd
ls -la /tmp/optfeat-test-upd/docs/pack/OPTIONAL-FEATURES.md
                                                → 7872 bytes ✓ (restored by --update path)

# §2.5 — D8.7
git show 4e240ec -- supporting-docs/DEPENDENCIES.md
                                                → 1 line edit (162) bare → docs/pack/ form
grep -n "OPTIONAL-FEATURES" supporting-docs/DEPENDENCIES.md
                                                → 162:See `docs/pack/OPTIONAL-FEATURES.md` ...

# §2.6 — Manifest
git show 4e240ec -- test-fixtures/manifest.txt
                                                → 3 v11-* rows changed; v10-* + existing-project unchanged
bash test-fixtures/build.sh --verify
                                                → all 6 rows OK at HEAD

# §2.7 — A4-A8
grep -rn "OPTIONAL-FEATURES" project-template/ --include="*.md" --include="*.toml"
                                                → 6 hits in 5 files; all resolve post-SPLIT

# §2.8 — Scope
git show 4e240ec --name-status                  → exactly 5 paths, no trinity, no pack-ops/, no MERGE-STRATEGY

# §2.9 — POQ-3-N
(no new pack-side path references introduced; only qualified "MERGE-STRATEGY.md in the pack repo")

# File hygiene
tail -c 1 project-template/docs/pack/OPTIONAL-FEATURES.md | xxd
                                                → 0a (file ends with newline)
grep -n " $" project-template/docs/pack/OPTIONAL-FEATURES.md
                                                → (no trailing whitespace)
```

All verification commands: PASS.

---

## §6 Out-of-scope observations

These observations are NOT actionable for Commit 10 (out of scope) but are surfaced as feeds-into signal for Commit 12 (Architect C prevention mechanisms) or future maintenance.

### §6.1 — Pre-existing `tracker.toml.pack-example` mention in HELP-FRAGMENT-TRACKER.md

`project-template/docs/pack/HELP-FRAGMENT-TRACKER.md:49` reads:

```
See the tracker example template (`tracker.toml.pack-example` in the pack repo, or `tracker.toml.example` at a client project root) and `OPTIONAL-FEATURES.md` for full setup.
```

The `tracker.toml.pack-example` mention is PRE-EXISTING in HELP-FRAGMENT-TRACKER.md (last touched by BD-107 / BD-135, NOT by Commit 10). It uses the "in the pack repo" qualifier per the established convention, so it is properly qualified — but this is a SECOND project-side reference (after the Commit-10 `MERGE-STRATEGY.md in the pack repo` at L174) to a pack-side artifact. Commit 12's M5 deny-list (Check 36/37/38) should consider whether the pattern `<name>.pack-example` warrants explicit deny-list listing AND/OR confirm the "in the pack repo" qualifier exemption applies. This is Architect C's domain (Commit 12 scope), not Commit 10.

**No action requested for Commit 10.** Surfacing for Commit 12 prevention design.

### §6.2 — `--update` path explicit-mapping pattern as a contamination prevention surface

The `cmd_update` explicit-per-file mapping at `scripts/init-project.sh:1108-1132` is now 16 entries long. Adding new files to `project-template/docs/pack/` requires:

1. The fresh-install S6 glob auto-covers (no edit needed).
2. The `--update` mapping needs an explicit entry (must remember to add).

This asymmetry created the §8.2 judgment call. The IMPL-REPORT correctly identified both paths and applied both fixes. But the asymmetry is a maintenance hazard: future contributors adding new docs to `project-template/docs/pack/` may add to S6 only (or rely on the glob) and silently regress the `--update` path. Architect C / Commit 12 may want to consider a CI check that asserts every `project-template/docs/pack/*.md` file (and other auto-glob-covered paths) appears in `cmd_update` mapping list. This is a prevention-mechanism candidate, not a Commit 10 fix.

**No action requested for Commit 10.** Surfacing for Commit 12 prevention design.

### §6.3 — `auditor-issue-tracking` roadmap reference removed from project-side

The pack-side file mentions "BD-109 client-side, BD-110 pack-side" for the `auditor-issue-tracking` agent on the v11.x roadmap. The project-side file correctly OMITS this (per §13.5 pack-tracker plumbing OMIT row). BD-109 IS a client-side BD though — meaning the v11.x project-user audience MIGHT eventually want to know about it. For v11.0 launch, OMIT is correct (the agent doesn't exist yet). When BD-109 lands in v11.x, a future fix-pass may need to add a project-side reference. Out-of-scope for Commit 10 — flagged for v11.x maintenance.

**No action requested for Commit 10.** Tracking for future v11.x BD-109 landing.

### §6.4 — Commit 9b sequential-tail dependency

Commit 10 lands first in the sequential tail (per Path A OQ-1 RESOLVED). Commit 9b's D8.6 ref-update at `pack-ops/MERGE-STRATEGY.md:465` will target `docs/pack/OPTIONAL-FEATURES.md` (resolvable at client repos post-Commit-10). Commit 9b's pre-flight `ls project-template/docs/pack/OPTIONAL-FEATURES.md` will confirm the file exists. As of HEAD `4e240ec`, that file IS present. Commit 9b unblocked.

**No action.** Sequential-tail dependency satisfied.

---

## Verdict reiteration

**GO.**

Commit 10 implements TASK-T8 SPLIT to spec. All §13.3 row decisions correctly applied; §13.5 contamination contract satisfied (zero hits on all deny-grep markers); A4-A8 verify-only outcomes confirmed at client repos post-install; init-project.sh dual-path coverage diagnosed and applied correctly (S6 glob auto-covers + cmd_update explicit mapping +1); D8.7 ref-update lands cleanly; manifest regen produces expected 3-v11-row drift; scope discipline holds (5 files, no trinity, no pack-ops/, no MERGE-STRATEGY.md). Two judgment calls (line count 188 vs 180; cmd_update mapping needed explicit entry) are documented in the IMPL-REPORT with citations to architect spec — both calls sound. No BLOCKER / MUST / SHOULD. The two NIT-class observations are surfaced for awareness; both currently-shipped choices are the better available options.

Recommend: proceed to Commit 9b spawn (sequential tail next).
