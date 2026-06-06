# PLAN-BD-211 — Canonicalize the per-entry header grammar (execution plan)

**Author:** pack-planner
**Branch / HEAD:** `v11-dev` / `7bdb33f671b56e9e804bf17e0b85dda94b9d78b8`
**Date:** 2026-06-06
**Executes:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-211.md` (APPROVED;
all 5 DPs fixed as the architect recommended — DO NOT reopen).
**Foundation map:** `maintenance-docs/v11-implementation/RESEARCH-BD-211-GRAMMAR-BLAST-RADIUS.md`.
**This doc PLANS; a coder executes. The planner does not implement, stage, or commit.**

> **Decisions are FIXED (do not reopen):**
> - **DP-1** BD-195 `(Code Red 3)` → END of title inside the bold span; `Alias:` line UNCHANGED.
> - **DP-2** fold BD-167b→BD-167, BD-169b→BD-169 as a trailing `## Sub-entry: <former-ID> — <title>` H2 (fields verbatim), then DELETE the 2 files.
> - **DP-3** propagate the no-letter-suffix rule into the trinity § "BD-NNN numbering" NOW (×3 CLIs) + retire the memory grandfather clause in lockstep.
> - **DP-4** the 3-commit split (C1 / C2 / C3) below.
> - **DP-5** NO historical-ref action — the 40 `maintenance-docs/` files stay accurate-history, outside every guard scan.

---

## 0. Goal + BD items addressed

**Goal.** Canonicalize the per-entry BD/TD line-2 header grammar to
`**<ID>-NNN — Title**` (no letter-suffix sub-entry form; no parenthetical
between the ID and the em-dash); simplify the shared per-entry engine + validator
+ pack `_rules.md` to that canonical form; and make the validator ENFORCE it so
drift is caught going forward. BD-204 PREREQUISITE — must land before BD-204
resumes at C-6 / the C-8 dogfood flip, so the migration carries a canonical,
suffix-free backlog.

**BD in scope:** BD-211 (sole). Every acceptance criterion in `backlog/BD-211.md`
line 11 is mapped to a commit + a verification below:

| BD-211 acceptance criterion | Where addressed |
|---|---|
| all live entries parse via the canonical header (count == live count) | C1 (data canonical) + C2 guard positive test (§5.B) |
| no suffix entry/grammar remains in the active engine/_rules/validator | C2 + grep-zero gate (§6) |
| validator FAILS a non-canonical header (suffix OR pre-em-dash parenthetical) — negative test | C2 guard + negative test (§5.B) |
| no-letter-suffix rule/memory reflect retired grandfathering | C3 trinity bullet + memory edit (Pack-Chat-direct, lockstep with C3) |
| historical refs advisory only (NOT rewritten) | DP-5 — no action; allowlist boundary (§6) |
| validate-pack green + full CI | per-commit verification (§4 full CI set) |
| BD-203's shared grammar adapted with NO project-side regression | C2 + no-project-regression check (§7) |

---

## 1. Empirical state baseline (HEAD `7bdb33f`)

All commands run at HEAD `7bdb33f` on branch `v11-dev`.

### EE-1 — the non-canonical live entry set is EXACTLY 3, all pack-backlog
```
$ for f in backlog/BD-*.md; do hdr=$(sed -n '2p' "$f");
    printf '%s\n' "$hdr" | grep -qE '^\*\*BD-[0-9]+ — .+\*\*$' \
    || printf '%s :: %s\n' "$f" "$hdr"; done
backlog/BD-167b.md :: **BD-167b — Per-entry split PM-only edits (...)**
backlog/BD-169b.md :: **BD-169b — Per-entry split PM-only wording updates (...)**
backlog/BD-195.md  :: **BD-195 (Code Red 3) — v11.0 pristine-state recovery before BD-185 restart (full-repo)**
```
Interpretation: exactly 3 non-canonical headers (2 suffix, 1 pre-em-dash
parenthetical). Conclusion: **SUPPORTED.**

### EE-2 — live BD entry count = 213 today; projected 211 post-fold
```
$ ls backlog/BD-*.md | wc -l
213
```
Interpretation: 213 BD entry files today; the fold DELETEs `BD-167b.md` +
`BD-169b.md` → 211 post-fix. (The design doc §4.3 "211 canonical entries pass"
refers to the POST-fix tree; the live-count-today is 213. Both are consistent:
213 − 2 = 211.) Conclusion: **SUPPORTED.**

### EE-3 — grep-zero baseline: 8 `[a-z]*` BD/TD-id grammar-site occurrences in active code
```
$ grep -rEn 'BD-[0-9]+\[a-z\]\*|BD-\\d\+\[a-z\]\*|TD-[0-9]+\[a-z\]\*|TD-\\d\+\[a-z\]\*|\[A-Z\]\+-\\d\+\[a-z\]\*' \
    scripts/lib/per-entry/ scripts/validate-pack.py \
    scripts/lib/recommendation.sh scripts/lib/detect.sh | wc -l
8
```
Interpretation: 8 literal `[a-z]*`-bearing regex occurrences across the 6 active
files (`_lib.sh` 1, `decompose.sh` 2, `toc-regenerate.sh` 3, `validate-pack.py`
STREAMS 1 + CROSS_REF 2 = 3 [counted as the STREAMS L311 plus 2 CROSS_REF
tokens], `recommendation.sh` 1, `detect.sh` 1). The design enumerates these as
the 14 grammar SITES (regex + comment occurrences); the 8 here are the literal
`[a-z]*` regex tokens (comments are additional). The grep-zero gate (§6) targets
this family → 0 post-fix. Conclusion: **SUPPORTED** (the architect's 14-site set
is the superset; the 8 literal `[a-z]*` tokens are the grep-zero core).

### EE-4 — active `BD-167b`/`BD-169b` token refs in `backlog/` + `scripts/`
```
$ grep -rln 'BD-167b\|BD-169b' backlog/ scripts/
backlog/BD-169b.md          backlog/BD-211.md          backlog/_toc.md
backlog/BD-169.md           backlog/_rules.md          backlog/BD-167b.md
scripts/validate-pack.py    scripts/tests/recommendation-test.sh
scripts/tests/test-validate-pack-checks-32-33-34.sh  scripts/tests/pack-help-test.sh
scripts/lib/per-entry/decompose.sh  scripts/lib/per-entry/toc-regenerate.sh
scripts/lib/per-entry/_lib.sh
```
Interpretation: 13 active files carry a `BD-167b`/`BD-169b` token. Note
`backlog/_rules.md` carries the literal `BD-167b.md`/`BD-169b.md` examples (§3.5
of design); `validate-pack.py`/`decompose.sh`/`toc-regenerate.sh`/`_lib.sh` carry
them in BD-203 comments. Post-fix the ONLY surviving tokens are the documented
allowlist: `backlog/BD-211.md` (self-describing) + the 40 historical
`maintenance-docs/` files (outside this scan). Conclusion: **SUPPORTED.**

### EE-5 — the `19b` trinity token is the UNRELATED commit-batch sub-number
```
$ grep -n '19b' CLAUDE.md AGENTS.md GEMINI.md
AGENTS.md:60:- `fix: vN — BD-NNN ... (Batch Nx)` (fix attached to a sub-batch — e.g., 19b cleanup)
CLAUDE.md:58:- `fix: vN — BD-NNN ... (Batch Nx)` (fix attached to a sub-batch — e.g., 19b cleanup)
```
Interpretation: the only `19b` token in the trinity is the `(Batch Nx)`
commit-message convention — NOT a BD letter suffix. C3 MUST NOT touch it.
Conclusion: **SUPPORTED.**

### EE-6 — `backlog/` is NOT a `test-fixtures/manifest.txt` source surface
```
$ grep -c 'backlog/' test-fixtures/manifest.txt   →  0   (no manifest file / no backlog refs)
```
Interpretation: the manifest is built by `test-fixtures/build.sh` from
init-project output against fixtures, not from the pack `backlog/` tree. So C1
(diff = `backlog/` only) does NOT mechanically require a manifest regen; C2
(diff includes `scripts/`) DOES per RC9. C1's coder still runs `build.sh --all
--clean` and stages the manifest ONLY if its diff is non-empty (belt-and-braces).
Conclusion: **SUPPORTED.**

### EE-7 — trinity § "BD-NNN numbering" shape per CLI (C3 target sites)
```
$ grep -n "BD-NNN numbering\|BD numbering" CLAUDE.md AGENTS.md GEMINI.md
CLAUDE.md:91:**BD-NNN numbering:**
AGENTS.md:93:**BD-NNN numbering:**
GEMINI.md:71:**BD numbering:**   (compressed single-paragraph form)
```
Interpretation: CLAUDE.md (§ at L91) and AGENTS.md (§ at L93) carry a bulleted
"BD-NNN numbering" block; GEMINI.md carries a compressed single-paragraph
"BD numbering:" form at L71. The C3 edit is trinity-PARALLEL (same rule, three
files) but audience-correct per CLI shape — a bullet under the CLAUDE/AGENTS
block; a parallel sentence in GEMINI's compressed paragraph. NOT a byte-identical
copy. Conclusion: **SUPPORTED.**

### EE-8 — project DATA already canonical (no project-side regression risk)
```
$ grep -nE '\^TD-\\d\+|TD-NNN' project-template/docs/project/backlog/_rules.md
14: Per-entry files match `^TD-\d+\.md$` (e.g., `TD-001.md`). ...
22: ... `**TD-NNN — <Title>**`.
$ for f in test-fixtures/v11-realistic-ot/docs/project/backlog/TD-*.md; do sed -n '2p' "$f"; done
**TD-001 — ...**  ...  **TD-005 — ...**   (all canonical)
```
Interpretation: the project template ALREADY declares the canonical suffix-free
TD grammar; the 5 fixture TD entries are canonical. The engine simplification
moves the shared code INTO agreement with the already-canonical template — the
project side gets MORE consistent, not regressed. Conclusion: **SUPPORTED.**

---

## 2. Dependency chain + ordering (the load-bearing sequence)

**Hard ordering: C1 → C2 → C3.**

The single ordering constraint that MUST be honored:

> **C1 (canonicalize the 3 entries) MUST land before C2's new canonical-header
> guard goes live.** C2 adds a guard inside Check 32′ that FAILs any line-2
> header not matching `^\*\*(?:BD|TD)-\d+ — .+\*\*$`. If the 3 non-canonical
> entries (`BD-167b`, `BD-169b`, `BD-195 (Code Red 3)`) still exist when that
> guard runs, the guard FAILs the tree and `validate-pack.py` goes RED at C2's
> own verification — a self-inflicted CI-red. Folding/normalizing the data FIRST
> (C1) makes the tree canonical, so when C2's guard lands the tree already
> passes it. **Fold-then-guard, never guard-then-fold.**

Secondary dependencies:

- **C1 also removes the two suffix FILES** that the engine-simplification (C2)
  would otherwise have to keep admitting. After C1, the only `BD-167b`/`BD-169b`
  tokens left in `backlog/` + `scripts/` are the ones C2 strips (engine comments,
  `_rules.md` prose, test fixtures) plus the documented allowlist. The grep-zero
  gate (§6) is therefore meaningful only AFTER both C1 and C2 land.
- **C2's `_rules.md` simplification** (pack `backlog/_rules.md`) describes the
  canonical grammar the C1 data already conforms to and the C2 guard enforces —
  it belongs with the engine/guard change (cross-surface contract), NOT with the
  pure-data C1.
- **C3 (trinity rule + memory)** has no code dependency on C1/C2 — the rule text
  is a governance statement. It is sequenced LAST so the rule prohibition lands
  only after the engine actually forbids suffixes (the rule and the enforcement
  agree at the moment the rule is published). C3 may be dropped only if DP-3 were
  "leave-pending" — it is NOT (DP-3 = propagate NOW), so C3 is REQUIRED.

**Why not merge C1+C2.** C1 is pack-only data (`backlog/` only → `pack-only`
keyword, Check 36 passes). C2 is cross-surface (shared `scripts/lib/per-entry/*`
+ `validate-pack.py` serve the `TD-` project stream → NO keyword). Merging them
would force the merged commit to drop the `pack-only` keyword (honest), but it
would also couple the data fix to the engine change, defeating the fold-then-guard
safety property (the guard would land in the same commit as the data it guards —
acceptable for correctness but worse for auditability and bisection). Keep them
split per DP-4.

**Each commit leaves the pack in a working state** (`validate-pack.py` green +
full CI green) — the per-commit verification (§4) is the gate at every step.

---

## 3. The three commits — scope, recipe, ordering rationale

Each commit below specifies: (a) exact file scope; (b) the change recipe (design
§ + code BY SYMBOL); (c) dependency/ordering rationale; (d) the bounded
review/fix cycle applies; (e) per-commit verification (the full set is in §4).

### C1 — pack-side data fix (`pack-only`)

**Commit subject (recommended):**
`fix: v11 — BD-211 canonicalize 3 non-canonical backlog entries (fold BD-167b/169b, normalize BD-195) (pack-only)`

**(a) Exact file scope** — `backlog/` ONLY (no `project-template/`, no
`supporting-docs/`, no `scripts/`):
- `backlog/BD-167.md` — append fold H2 (modify)
- `backlog/BD-169.md` — append fold H2 + repoint line-14 cross-ref (modify)
- `backlog/BD-167b.md` — DELETE (`git rm`)
- `backlog/BD-169b.md` — DELETE (`git rm`)
- `backlog/BD-195.md` — normalize line-2 header (modify)
- `backlog/_toc.md` — REGENERATE (modify, generated artifact)
- `backlog/_rules.md` — **NOT in C1** (it is the cross-surface contract change → C2). C1 stays purely data.

**(b) Change recipe (design §2):**

1. **Fold BD-167b → BD-167** (design §2.2 + §2.2.1, DP-2 = user option (a),
   TOKENLESS). APPEND to the END of `backlog/BD-167.md` body a trailing,
   **tokenless** H2 section (NO `BD-167b` token anywhere in the result — SCRUB the
   token; no allowlist exception, no Check-34 special-case):
   ```
   ## Sub-entry b — Per-entry split PM-only edits (trinity Key files + PACK-AGENTS.md PM-only directories list + CLAUDE.md pack-memory bullet + pack-* agent prompts × 15)
   Folded from a former standalone sub-entry per BD-211 (no-letter-suffix
   canonicalization; a sub-part is a section, not a suffixed entry).
   Type: <verbatim from BD-167b.md line 3>
   Status: Resolved
   Blockers: BD-167
   Unblocks: none
   File/Symbol (PM-only — Pack Chat applies; ...): <verbatim from BD-167b.md lines 7–14, with the self-referential token scrubbed — see scrub below>
   Description: <verbatim from BD-167b.md line 15>
   Resolved: <verbatim from BD-167b.md line 16>
   ```
   The H2 label is TOKENLESS: `## Sub-entry b — <former title>` — the trailing `b`
   denotes the former suffix sub-part (per "a sub-part is a section") and carries NO
   `BD-167b` token; human/history continuity is served by the `b` label + the
   provenance line. DROP the former entry's line-1 back-pointer and line-2 suffix
   header (they carry no LIVE field content — the title survives in the H2 label).
   SCRUB the one self-referential suffix token in the verbatim `File/Symbol` block
   (design §2.2 / §2.2.1): the bullet ending `… NOT in BD-167b)` → `… NOT in this
   sub-entry)`. All other fields preserved VERBATIM (safe-before-delete: the parent
   carries every LIVE field before the file is deleted). `Blockers: BD-167` (parent
   ref) STAYS. Parent line-2 header, Type, Status, Resolved UNCHANGED. The `##
   Sub-entry b` H2 is NOT a line-2 bold header, so the C2 guard does not scan it.

2. **Fold BD-169b → BD-169** (design §2.2 + §2.2.1, DP-2 = user option (a),
   TOKENLESS). Same tokenless shape: append
   `## Sub-entry b — Per-entry split PM-only wording updates (PACK-CHAT.md row + README.md Repository Layout entries)`
   to the END of `backlog/BD-169.md`, carrying BD-169b's
   Type/Status/Blockers/Unblocks/File-Symbol/Description/Resolved verbatim EXCEPT
   the one self-referential suffix token, which is SCRUBBED: the `Description`
   ending `… §6.1 BD-169b sample text.` → `… §6.1 sample text.` (design §2.2 /
   §2.2.1). DROP the former entry's line-1 back-pointer + line-2 suffix header (no
   LIVE field content). The H2 label is TOKENLESS (`## Sub-entry b — <former
   title>`, NO `BD-169b` token). `Blockers: BD-169` (parent ref) STAYS. Result
   carries ZERO `BD-169b` token.

3. **Repoint BD-169 cross-ref** (design §2.3, TOKENLESS). `backlog/BD-169.md`
   line 14 Description currently reads `... those land in BD-169b).`. Change the
   `BD-169b` TOKEN to TOKENLESS same-entry prose `the sub-entry b section below`
   (NO `BD-167b`/`BD-169b` token, NO `BD-NNN`-shaped token — so Check 34 sees no
   reference, the grep-zero gate stays clean, and the folded `## Sub-entry b`
   section is the resolved referent). `backlog/BD-167.md` body has NO `BD-167b`
   token (EE-4 / design §2.3) — no repoint needed there. Post-fold both parents
   (`BD-167.md`, `BD-169.md`) carry ZERO `BD-167b`/`BD-169b` tokens (design §2.2.1).

4. **Normalize BD-195** (design §2.1, DP-1). `backlog/BD-195.md` line 2:
   - FROM: `**BD-195 (Code Red 3) — v11.0 pristine-state recovery before BD-185 restart (full-repo)**`
   - TO:   `**BD-195 — v11.0 pristine-state recovery before BD-185 restart (full-repo) (Code Red 3)**`
   The `(Code Red 3)` parenthetical moves to the END of the title, inside the
   bold span, AFTER `(full-repo)`. The `Alias:` line (line 6) stays UNCHANGED.
   No other line in BD-195.md changes. Filename stays `BD-195.md`.

5. **DELETE the 2 files** (design §2.2, fail-loud / delete-old-source). After the
   folds verify the parents carry every field, `git rm backlog/BD-167b.md
   backlog/BD-169b.md` (no stub, no mirror). NOTE: this is a destructive op — per
   the per-action-approval rule, the coder surfaces the deletion and Pack Chat
   carries the user approval; the coder NEVER runs `git rm` on its own authority.
   (Recipe alternative if the coder may not run `git rm`: remove the files via the
   filesystem and let Pack Chat stage the deletion at commit time. Pack Chat owns
   all git state changes; the coder produces the tree state.)

6. **Regenerate `_toc.md`** (design §2.4). After fold + delete + normalize, run
   `per_entry_regenerate_toc pack-backlog backlog` (sourced from
   `scripts/lib/per-entry/_lib.sh` + `toc-regenerate.sh`). The BD-167b/BD-169b
   rows disappear; BD-195's row title updates to the normalized title. NEVER
   hand-edit `_toc.md`.

**(c) Ordering rationale.** C1 is FIRST so the tree is canonical before C2's
guard lands (fold-then-guard, §2). C1 touches no shared engine code, so it cannot
regress the project stream; it is pure pack data.

**(d) Bounded review/fix cycle applies** (max 2 review/fix pairs + 1 final
reviewer pass = 3 reviewer / 2 fix-coder spawns per commit; architect escalation
if dirty after the final pass).

**(e) Per-commit verification (full set in §4):** full CI test battery +
`validate-pack.py`. CRITICAL at C1: `validate-pack.py` runs the EXISTING Check
32′ filename-conformance + Check 33 (`_toc.md` in-sync) + Check 34 (cross-ref).
The deletion + regen must leave Check 33 green (regen done) and Check 34 green
(no dangling `BD-169b` token — the repoint removed it). The NEW header guard does
NOT exist yet at C1 (it lands in C2), so C1's tree is validated against the
current grammar. Manifest: run `bash test-fixtures/build.sh --all --clean`; C1's
diff is `backlog/` only (not a manifest source surface per EE-6) so the manifest
diff is expected empty — stage it ONLY if non-empty.

### C2 — cross-surface engine + validator + _rules + tests (NO scope keyword)

**Commit subject (recommended, NEUTRAL — no exclusive keyword):**
`feat: v11 — BD-211 canonicalize per-entry header grammar (cross-surface engine + validator)`

NO `pack-only` / `project-only` / `pack-chat-only` keyword: the diff includes
shared `scripts/lib/per-entry/*` + `scripts/validate-pack.py` + `scripts/lib/
{recommendation,detect}.sh` which serve the `TD-` project stream. A `pack-only`
keyword would be a Check-36 mis-claim (commit-subject keyword-token trap: even a
keyword token in prose is parsed — keep the subject free of all three keywords).

**(a) Exact file scope:**

Engine + validator (simplify grammar — design §3):
- `scripts/lib/per-entry/_lib.sh` (L88 BD filename regex + L86–87 comment)
- `scripts/lib/per-entry/decompose.sh` (L127 BD anchor, L152 TD anchor, L118–126 + L149–151 comments)
- `scripts/lib/per-entry/toc-regenerate.sh` (L85 filename regex, L128 title regex, L246 sort regex, L84 + L122–126 + L242–245 comments)
- `scripts/validate-pack.py` (L311 STREAMS BD regex, L3438 CROSS_REF BD token, L3439 CROSS_REF TD token, L309 + L3430–3435 comments; NEW header guard in `check_mirror_in_sync`)
- `scripts/lib/recommendation.sh` (L148 BD filename regex)
- `scripts/lib/detect.sh` (L59 BD filename regex)

Contract (simplify prose — design §5.2):
- `backlog/_rules.md` (L30–33 filename convention, L35–43 ID-extraction, L49 entry contract)

Tests (re-pin + add negative test — design §5.1 / §4.4):
- `scripts/tests/test-validate-pack-checks-32-33-34.sh` (re-pin A5/A6/C6/C7; rename the BD-167b fixture to a canonical id; ADD the header-guard negative + positive tests)
- `scripts/tests/test-per-entry.sh` (L223 1.6 assertion → canonical regex)
- `scripts/tests/pack-help-test.sh` (L43–45 rename `BD-167b.md` fixture → canonical id e.g. `BD-900.md`)
- `scripts/tests/recommendation-test.sh` (L52–54 rename `BD-167b.md` fixture → canonical id)
- `scripts/tests/tracker-migrate-reverse-test.sh` (L349 comment regex → canonical)
- `scripts/tests/tracker-migrate-roundtrip-test.sh` (L445 comment regex → canonical)

Generated:
- `test-fixtures/manifest.txt` (RC9 — C2 touches `scripts/`; regen + stage IF non-empty diff)

**VERIFY-only (NO edit — must NOT appear in the diff):**
- `project-template/docs/project/backlog/_rules.md` (already canonical, EE-8)
- `test-fixtures/v11-realistic-ot/.../TD-00{1..5}.md` + 9 fixture `_rules.md` (already canonical)
- `changelog/_rules.md` + pack-changelog regexes (version-shaped — KEEP, design §3.6)

**(b) Change recipe (design §3 + §4), BY SYMBOL:**

ENGINE simplification — each site drops `[a-z]*` and (where present) the
parenthetical group `(?:\s*\([^)]*\))?`; each is property-fit, NOT blind find-replace:

1. `_lib.sh` `pe__stream_attr` pack-backlog `entry-regex` branch:
   `'^BD-[0-9]+[a-z]*\.md$'` → `'^BD-[0-9]+\.md$'`. Update the L86–87 comment to
   state the canonical form + cite BD-211. The `TD-` `entry-regex` (project-backlog,
   already `^TD-[0-9]+\.md$`) is KEPT (already canonical).

2. `decompose.sh` `anchor_re` (pack-backlog branch, the `if key == "pack-backlog"`
   block): `r"^\*\*(BD-\d+[a-z]*)(?:\s*\([^)]*\))?\s+— "` → `r"^\*\*(BD-\d+) — "`.
   `id_extract` returns the captured `BD-\d+` group unchanged. CROSS-SURFACE
   sibling: the `elif key == "project-backlog"` branch `anchor_re`
   `r"^\*\*(TD-\d+[a-z]*)(?:\s*\([^)]*\))?\s+— "` → `r"^\*\*(TD-\d+) — "`. Update
   the L118–126 + L149–151 comments → canonical, cite BD-211. Property-fit note:
   dropping the parenthetical group is SAFE because decompose is the one-time
   monolith→tree CONVERSION verb; the only header that carried a pre-em-dash
   parenthetical (BD-195) is normalized in C1 BEFORE any re-decompose, and no
   project monolith carries one.

3. `toc-regenerate.sh`:
   - `entry_regex_for_stream["pack-backlog"]`: `re.compile(r"^BD-\d+[a-z]*\.md$")`
     → `re.compile(r"^BD-\d+\.md$")` (must mirror `_lib.sh`).
   - the title-extraction regex (`re.match(r"^\*\*[A-Z]+-\d+[a-z]*(?:\s*\([^)]*\))? — (.+?)\*\*", ln)`)
     → `re.match(r"^\*\*[A-Z]+-\d+ — (.+?)\*\*", ln)`. Prefix-agnostic `[A-Z]+`
     serves BD AND TD — CROSS-SURFACE.
   - the within-group sort-key regex (`re.match(r"^[A-Z]+-(\d+)[a-z]*$", entry_id)`)
     → `re.match(r"^[A-Z]+-(\d+)$", entry_id)`. CROSS-SURFACE. Update the L84 +
     L122–126 + L242–245 comments → canonical, cite BD-211.

4. `validate-pack.py`:
   - `STREAMS` pack-backlog tuple entry_regex `r"^BD-\d+[a-z]*\.md$"` →
     `r"^BD-\d+\.md$"`.
   - `CROSS_REF_RE`: `r"BD-\d+[a-z]*"` → `r"BD-\d+"`; `r"TD-\d+[a-z]*"` →
     `r"TD-\d+"` (CROSS-SURFACE). Update the L309 + L3430–3435 comments →
     canonical, cite BD-211.
   - `_collect_defined_ids(stream_key, stream_dir, entry_regex)` takes
     `entry_regex` as a PARAMETER — it consumes the STREAMS regex, NOT a
     hard-coded `[a-z]*`. Simplifying the STREAMS tuple simplifies it
     automatically; NO separate edit. The coder PREFLIGHT (grep-zero gate §6)
     VERIFIES no other hard-coded `BD-\d+[a-z]*\.md$` survives in
     `validate-pack.py`.

5. `recommendation.sh` (the entry-counting loop): `grep -qE '^BD-[0-9]+[a-z]*\.md$'`
   → `grep -qE '^BD-[0-9]+\.md$'`.

6. `detect.sh` (the per-entry-tree-presence detector): `grep -qE
   '^BD-[0-9]+[a-z]*\.md$'` → `grep -qE '^BD-[0-9]+\.md$'`.

NET-NEW canonical-header guard — INSIDE Check 32′ (design §4.2):

7. In `check_mirror_in_sync` (`validate-pack.py`), AFTER the existing
   filename-conformance loop, for each pack stream whose entry regex is
   `[A-Z]+-\d+`-shaped (pack-backlog; pack-changelog is version-shaped → SKIP the
   header assertion), read line 2 of each entry file (the bold header BELOW the
   line-1 `<!-- per-entry source: ... -->` back-pointer) and assert it matches:
   ```
   _CANON_HEADER_RE = re.compile(r"^\*\*(?:BD|TD)-\d+ — .+\*\*$")
   ```
   FAIL with a file-path + verbatim-header callout naming the non-canonical
   feature (suffix or pre-em-dash parenthetical) when line 2 does not match. The
   stream-applicability (ID-shaped vs version-shaped) MUST be DERIVED from the
   same STREAMS data the filename loop uses — do NOT hard-code "pack-backlog" in
   two places (enumerate-encoding-surfaces). Stream-scoped so the version-shaped
   changelog stream is never mis-asserted (property-fit, not blind).

CONTRACT simplification — `backlog/_rules.md` (design §5.2):

8. Filename convention (L30–33): `^BD-\d+[a-z]*\.md$` + the "OPTIONAL lowercase
   suffix-letter run ... `BD-167b.md`/`BD-169b.md`" prose → `^BD-\d+\.md$` +
   "Three-or-more-digit BD-NNN; NO letter suffix (canonical per BD-211 — a
   sub-part is an in-body section, not a suffixed entry)."
9. ID-extraction (L35–43): remove the suffix example (`**BD-167b — ...**`) AND the
   parenthetical-admission sentence (the `**BD-195 (Code Red 3) — ...**` "admitted"
   prose). Keep the "filename IS the ID" core; restate canonical: a parenthetical
   qualifier, if present, is TITLE TEXT after the em-dash, never between the ID and
   the em-dash. The captured ID group becomes `BD-\d+`.
10. Entry contract (L49): `**BD-NNN[suffix] — <Title>**` → `**BD-NNN — <Title>**`.
    The project-template `_rules.md` is ALREADY canonical (EE-8) — NO edit; this
    brings the PACK `_rules.md` into agreement with it (separate artifacts —
    pack/project separation).

TESTS — re-pin + negative test (design §5.1 / §4.4):

11. `test-validate-pack-checks-32-33-34.sh`:
    - A5/A6 (filename conformance): rename the `BD-167b.md` suffix fixture to a
      canonical id (e.g. `BD-700.md`); A6 becomes "canonical entry conforms" (drop
      the suffix-specific framing). The A5 ROGUE-FILE.md non-conform test stays.
    - C6/C7 (cross-ref): re-pin from `BD-167b` / `BD-999z` suffix tokens to
      canonical ids — C6 "a defined-id ref resolves" (use a canonical defined id);
      C7 "a dangling ref FAILs" (use a canonical-but-undefined id, e.g. `BD-555`,
      mirroring the existing C2 dangling-`BD-555` precedent). The C7 dangling test
      is the SEED for the new header-guard NEGATIVE test.
    - ADD the header-guard tests (design §4.4): seed a scratch pack-backlog tree
      with (i) `**BD-500b — Suffix header**` and (ii) `**BD-501 (Qualifier) —
      Parenthetical header**`; assert `check_mirror_in_sync` returns rc=1 and the
      output names BOTH offending files. Add a POSITIVE control:
      `**BD-502 — Clean header**` passes (rc=0, not flagged).
12. `test-per-entry.sh` 1.6: `assert_eq "1.6 pack-backlog entry regex"
    "^BD-[0-9]+[a-z]*\.md$" ...` → `"^BD-[0-9]+\.md$"`.
13. `pack-help-test.sh` (L43–45) + `recommendation-test.sh` (L52–54): rename the
    `BD-167b.md` fixture to a canonical id (e.g. `BD-900.md`) + update the body
    header line to match (`**BD-900 — ...**`). Preserve the fixture's Status:
    field (Resolved for pack-help, Unblocked for recommendation — those drive the
    test's active/resolved counting).
14. `tracker-migrate-reverse-test.sh` (L349) + `tracker-migrate-roundtrip-test.sh`
    (L445): sync the comment regex `^BD-[0-9]+[a-z]*\.md$` → `^BD-[0-9]+\.md$`.

**(c) Ordering rationale.** C2 lands AFTER C1 so the guard (recipe item 7) runs
against an already-canonical tree (fold-then-guard, §2). C2's cross-surface
engine edits move the shared code into agreement with the already-canonical
project template (EE-8) — no project regression.

**(d) Bounded review/fix cycle applies** (max 2 pairs + 1 final pass;
architect escalation if dirty).

**(e) Per-commit verification (full set in §4):** full CI battery +
`validate-pack.py`; the measure-then-bound guard tests (positive: all 211
post-fix canonical entries pass; negative: a suffix header AND a pre-em-dash
parenthetical header both REJECT); grep-zero completeness gate (§6);
no-project-regression (§7); manifest regen + stage IF non-empty.

### C3 — trinity rule propagation (`pack-chat-only`) [DP-3 = NOW]

**Commit subject (recommended):**
`docs: v11 — BD-211 propagate no-letter-suffix rule to trinity § BD-NNN numbering (pack-chat-only)`

pack-root trinity ops files are pack-chat-only, so the `pack-chat-only` keyword is
ACCURATE. Because this is a SUBSTANTIVE rule/contract edit to landed trinity
content (not a bookkeeping token, not a new entry), it routes to a `pack-coder`
that Pack Chat scopes the 3 trinity files into — NOT a Pack-Chat-direct edit —
under the bounded review/fix cycle (pack-chat-minor-edits-only: a rule/contract
change is MAJOR → coder).

**(a) Exact file scope:**
- `CLAUDE.md` (§ "BD-NNN numbering" at L91 — add bullet)
- `AGENTS.md` (§ "BD-NNN numbering" at L93 — add parallel bullet)
- `GEMINI.md` (§ "BD numbering:" at L71 — add parallel sentence in the compressed paragraph)

**(b) Change recipe (design §5.4, DP-3):**

Add the no-letter-suffix rule to § "BD-NNN numbering" in all three, in the SAME
commit (trinity rule REQUIRES the parallel edit; NO tool-specific carve-out — this
is a project-numbering rule identical across the three CLIs). Audience-correct per
CLI shape (EE-7), NOT a byte-identical copy:

- **CLAUDE.md (L91 bullet block) + AGENTS.md (L93 bullet block):** add a bullet:
  > - **No letter suffix.** A SEPARATE BD never carries a letter suffix (no
  >   `BD-210b` as a standalone entry) — assign the next INTEGER. A sub-part of an
  >   existing BD lives as a SECTION inside that BD's body, never a suffixed
  >   entry. (BD-167b/BD-169b were folded into their parents by BD-211.)
- **GEMINI.md (L71 compressed paragraph):** add a parallel sentence in the same
  compressed style as the surrounding "BD numbering:" prose:
  > No letter suffix on a SEPARATE BD (no `BD-210b` standalone) — next INTEGER; a
  > sub-part is a SECTION in the parent BD's body. (BD-167b/BD-169b folded into
  > their parents by BD-211.)

**Do NOT touch the `19b` token** (`CLAUDE.md:58` / `AGENTS.md:60`) — that is the
commit-message `(Batch Nx)` sub-number convention, UNRELATED to BD letter
suffixes (EE-5).

**Memory edit (NOT a commit — Pack-Chat-direct, lockstep with C3):** the
`feedback_no_bd_letter_suffix.md` memory file (Pack Chat's out-of-repo operating
state) is updated in lockstep with C3 (design §5.3): replace the grandfather
clause ("Existing suffix entries (BD-167b, BD-169b) are GRANDFATHERED one-offs")
with a historical note ("BD-167b/BD-169b were folded into BD-167/BD-169 as in-body
sections by BD-211 (2026-06-06); no suffix entry exists. Never create one."), and
change the "Pending: propagate ... into the trinity" bullet → "Landed in BD-211
(see trinity § 'BD-NNN numbering')." This is NOT part of any in-repo commit's diff;
Pack Chat applies it directly.

**(c) Ordering rationale.** C3 LAST so the published rule prohibition and the
engine enforcement (C2's guard) agree at the moment the rule lands. No code
dependency on C1/C2, but governance-after-enforcement is the correct sequence.

**(d) Bounded review/fix cycle applies** (rule/contract edit → coder + bounded
review/fix).

**(e) Per-commit verification (full set in §4):** full CI battery +
`validate-pack.py`. The trinity-parity checks (Check 18 H2 structure parity, Check
16 `## Project addenda`) run as part of the full CI — they assert trinity STRUCTURE
parity. C3 adds a bullet to an existing § in all three, preserving structure. NO
`scripts/` touched → NO manifest regen required for C3.

---

## 4. Per-commit verification — the FULL CI suite (load-bearing)

**Rule: run the ENTIRE CI test set per commit, not a named subset.** The C-5
CI-red was a missed test outside the coder's named subset — do not repeat. The
coder PREFLIGHT and the reviewer BOTH run the complete set below + run it after
EVERY commit (C1, C2, C3).

### 4.1 The complete CI `tests` job set (enumerated from `.github/workflows/validate-pack.yml`)

The `validate` job: `python3 scripts/validate-pack.py`.

The `tests` job (every step is `if: always()`, run independently). Run ALL of:
```
bash scripts/test-detect.sh
bash scripts/tests/tracker-provider-test.sh
bash scripts/tests/tracker-config-test.sh
bash scripts/tests/tracker-init-test.sh
bash scripts/tests/tracker-agent-read-test.sh
bash scripts/tests/tracker-migrate-forward-test.sh
bash scripts/tests/tracker-migrate-reverse-test.sh
bash scripts/tests/tracker-migrate-roundtrip-test.sh
bash scripts/tests/test-tracker-phase-task.sh
bash scripts/tests/test-tracker-links.sh
bash scripts/tests/test-tracker-cycle-check.sh
bash scripts/tests/tracker-errors-test.sh
bash scripts/tests/tracker-config-schema-test.sh
bash scripts/tests/recommendation-state-schema-test.sh
bash scripts/tests/test-per-entry.sh
bash scripts/tests/test-validate-pack-checks-32-33-34.sh
bash scripts/tests/test-validate-pack-checks-36-37-38.sh
bash scripts/tests/test-validate-pack-check-39.sh
bash scripts/tests/test-validate-pack-check-40.sh
bash scripts/tests/test-validate-pack-check-41.sh
bash scripts/tests/test-validate-pack-check-18.sh
bash scripts/tests/test-validate-pack-check-16.sh
bash scripts/tests/test-validate-pack-check-19.sh
bash scripts/tests/test-validate-pack-check-42.sh
bash scripts/tests/test-validate-pack-check-43.sh
bash scripts/tests/test-validate-pack-check-44.sh
bash scripts/tests/test-validate-pack-check-45.sh
bash scripts/tests/test-validate-pack-check-46.sh
bash scripts/tests/test-validate-pack-check-removed-doc-advisory.sh
bash scripts/tests/tracker-bd129-gh-repo-test.sh
bash scripts/tests/tracker-bd130-doctor-wired-test.sh
bash scripts/tests/tracker-bd132-race-test.sh
bash scripts/tests/tracker-bd133-header-preservation-test.sh
bash scripts/tests/tracker-bd134-close-retry-test.sh
bash scripts/tests/recommendation-test.sh
bash scripts/tests/pack-help-test.sh
bash scripts/tests/test-customization-preserve.sh
bash scripts/tests/test-init-project.sh
bash scripts/tests/test-migrate-v10-to-v11.sh
bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh
bash scripts/tests/test-migrate-v10-to-v11-gates.sh
bash scripts/tests/test-migrate-v10-to-v11-decompose.sh
bash scripts/test-migrator-core.sh
bash scripts/test-migrator-manifest.sh
bash scripts/test-migrator-capability-translation.sh
bash test-fixtures/build.sh --all --clean
git checkout HEAD -- test-fixtures/manifest.txt   # restore-before-verify (CI does this)
bash test-fixtures/build.sh --verify
bash scripts/tests/test-v11-realistic-ot.sh
bash scripts/test-migrator-skills.sh
bash scripts/test-persona-contracts.sh
bash scripts/tests/template-translations-test.sh
bash scripts/tests/template-version-test.sh
bash scripts/tests/test-issue-forms.sh
```
(50 `tests`-job steps + the `validate` job = the complete CI surface.)

### 4.2 Why the full set, per commit (not a hand-picked subset)

The C-2/C-5 CI-reds came from a test OUTSIDE the coder's named subset
(`feedback_verify_full_ci_suite`): `test-v11-realistic-ot.sh` hard-asserts
validator OUTPUT (banners, SKIP wording); the `tracker-migrate-*` tests carry the
grammar regex in COMMENTS (C2 recipe items 14); `pack-help-test.sh` /
`recommendation-test.sh` write `BD-167b.md` FIXTURES (C2 recipe item 13). A
"clean" `validate-pack.py` is NOT a green commit. The coder + reviewer each run
the full set; `gh run list` CI-red is the backstop, NOT the first detector.

### 4.3 The specific tests this change WILL move (enumerate-encoding-surfaces)

These tests pin the OLD grammar and MUST be re-pinned in C2 (and stay green):
- `test-per-entry.sh` 1.6 (entry-regex assertion).
- `test-validate-pack-checks-32-33-34.sh` A5/A6 (filename conformance), C6/C7
  (cross-ref), + the NET-NEW header-guard positive/negative tests.
- `pack-help-test.sh` / `recommendation-test.sh` (`BD-167b.md` fixtures).
- `tracker-migrate-reverse-test.sh` / `tracker-migrate-roundtrip-test.sh`
  (grammar-regex comments).
- `test-v11-realistic-ot.sh` — VERIFY it still passes (the simplified engine must
  parse the realistic-ot project fixture; it asserts validator output — confirm no
  banner/SKIP wording the C2 guard introduces breaks a stale assertion). The C2
  guard adds a new assertion inside Check 32′ but does NOT rename the Check 32′
  banner, so the known BD-203-C-1 failure mode (banner-rename breaking a stale
  realistic-ot assertion) does not recur — but the coder/reviewer VERIFY this
  explicitly by running the test, not by assuming.

---

## 5. Guard verification — measure-then-bound (positive + negative)

The new canonical-header guard (C2 recipe item 7) is sized to pass EXACTLY the
canonical set and reject EXACTLY the non-canonical forms. Both tests live in
`scripts/tests/test-validate-pack-checks-32-33-34.sh` (C2 recipe item 11).

### 5.A Positive test (no false positives)
Against the POST-fix tree (after C1: BD-167b/BD-169b deleted, BD-195 normalized),
all 211 canonical entries pass the guard. The design's §4.3 measurement ran the
accept-regex `^\*\*(?:BD|TD)-\d+ — .+\*\*$` against the projected post-fix tree:
211 entries scanned, 0 non-canonical. The C2 reviewer + coder re-run
`validate-pack.py` against the real post-C1 tree and confirm Check 32′ (with the
header guard) is GREEN (0 false positives). The 5 fixture TD headers
(TD-001..005) are already canonical (EE-8) so the guard passes them too.

### 5.B Negative test (no false negatives) — the C7 dangling-suffix test is the seed
The new negative test (design §4.4) seeds a scratch pack-backlog tree with:
- `**BD-500b — Suffix header**` → guard REJECTS (suffix), `check_mirror_in_sync`
  rc=1, output names `BD-500b.md`.
- `**BD-501 (Qualifier) — Parenthetical header**` → guard REJECTS (pre-em-dash
  parenthetical), rc=1, output names `BD-501.md`.
- POSITIVE control `**BD-502 — Clean header**` → guard PASSES (not flagged).

Both non-canonical forms (suffix AND pre-em-dash parenthetical) MUST reject; a
guard that catches only the suffix would be a false-negative on the parenthetical
form. This is the load-bearing acceptance criterion in BD-211 line 11 ("the
validator FAILS a non-canonical header — suffix or pre-em-dash parenthetical —
verified with a negative test").

---

## 6. grep-zero completeness gate (coder PREFLIGHT + reviewer)

**Lead with the gate** (rename/measure-then-bound). After C1+C2, BOTH greps below
MUST be EMPTY except the documented allowlist. The coder asserts this in its
PREFLIGHT line; the reviewer asserts it independently. The gate is
enumeration-independent — it catches ANY missed occurrence regardless of the
anchor list's completeness.

### 6.1 No `[a-z]*` BD/TD-id grammar site remains in active code
```
$ grep -rEn 'BD-[0-9]+\[a-z\]\*|BD-\\d\+\[a-z\]\*|TD-[0-9]+\[a-z\]\*|TD-\\d\+\[a-z\]\*|\[A-Z\]\+-\\d\+\[a-z\]\*' \
    scripts/lib/per-entry/ scripts/validate-pack.py \
    scripts/lib/recommendation.sh scripts/lib/detect.sh
→ (empty)
```
Baseline today = 8 occurrences (EE-3); post-C2 must be 0.

### 6.2 No active `BD-167b`/`BD-169b` token outside the allowlist
```
$ grep -rln 'BD-167b\|BD-169b' backlog/ scripts/
→ (empty)
```
Baseline today = 13 files (EE-4); post-C1+C2 must be 0 in `backlog/` + `scripts/`.

### 6.3 Documented allowlist (the ONLY legitimate survivors)
1. The 40 `maintenance-docs/` accurate-history files (288 v11-impl + 13 archive
   lines) — DP-5, intentionally untouched, OUTSIDE the gate's scan dirs
   (`backlog/`, `scripts/`). They are the accurate-history allowlist boundary.
2. `backlog/BD-211.md` itself (self-describing the fix — names the targets in its
   Problem/Scope text). NOTE: §6.2 scans `backlog/` so `BD-211.md` WILL match —
   the reviewer treats `backlog/BD-211.md` as the single in-scope allowlisted file
   (the gate's expected output is "exactly `backlog/BD-211.md`," not literal empty,
   for the §6.2 grep restricted to `backlog/`). For `scripts/` the §6.2 grep MUST
   be literally empty. (Equivalent precise form: `grep -rln 'BD-167b\|BD-169b'
   backlog/ scripts/ | grep -v '^backlog/BD-211.md$'` → empty.)

Anything else is a miss → the coder reports it INSTEAD of a partial IMPL-REPORT;
the reviewer fails the commit.

---

## 7. No-project-regression verification

The engine simplification (C2 recipe items 2/3/4 cross-surface sites) must keep
the `TD-` project stream working AND agreeing with the project-template
`_rules.md`. The engine moves INTO agreement with the already-canonical template
(EE-8) — the project side gets MORE consistent, not regressed.

Verification (coder + reviewer):
1. `bash scripts/tests/test-v11-realistic-ot.sh` GREEN — the simplified engine
   decomposes + TOC-regenerates + validates the realistic-ot project fixture
   (5 canonical TD entries) with no error.
2. `project-template/docs/project/backlog/_rules.md` is UNCHANGED (must NOT appear
   in any commit diff) — it is already canonical; C2 brings the PACK `_rules.md`
   into agreement with it (separate artifacts — pack/project separation; the
   project version is never edited as a side effect).
3. The 9 fixture `_rules.md` copies + the 5 fixture `TD-00{1..5}.md` are UNCHANGED
   and still parse under the simplified engine.

This satisfies BD-211 acceptance "BD-203's shared grammar adapted with no
project-side regression."

---

## 8. Risks + unknowns

| Risk | Severity | Mitigation |
|---|---|---|
| **CI-red from a test outside a named subset** (the C-5 failure mode) | HIGH | §4 full-CI-per-commit, coder PREFLIGHT + reviewer both run ALL 50 `tests` steps + `validate-pack.py`; specifically `test-v11-realistic-ot.sh`, the `tracker-migrate-*` comment tests, `pack-help`/`recommendation` fixture tests (§4.3). |
| **Fold-then-guard inversion** (guard lands before data is canonical → self-CI-red) | HIGH | Hard ordering C1 → C2 (§2); C1 makes the tree canonical BEFORE C2's guard exists. |
| **Stale `BD-169b` cross-ref dangling** (Check 34 RED after delete) | MED | C1 recipe item 3 repoints the token to prose BEFORE the file is deleted; Check 34 runs in C1's verification. |
| **`_toc.md` not regenerated → Check 33 RED** | MED | C1 recipe item 6 runs `per_entry_regenerate_toc`; Check 33 in C1's verification. |
| **Guard false-negative on the parenthetical form** (catches suffix only) | MED | §5.B negative test asserts BOTH forms reject; the C7 dangling test is only the seed — the new test adds the parenthetical case explicitly. |
| **Hard-coded `pack-backlog` in the guard** (two-place drift) | MED | C2 recipe item 7 derives stream-applicability from STREAMS data, not a literal — enumerate-encoding-surfaces. |
| **Manifest drift** (C2 touches `scripts/` but coder forgets regen) | MED | C2 verification regenerates + stages `manifest.txt` IF non-empty (RC9). C1's `backlog/`-only diff is not a manifest surface (EE-6). |
| **`git rm` on coder authority** (per-action-approval violation) | MED | C1 recipe item 5: the coder surfaces the deletion; Pack Chat carries user approval; the coder never runs a state-changing git verb (agents-never-commit). |
| **Project-template `_rules.md` accidentally edited** (pack/project cross-contamination) | LOW | §7 item 2 + C2 scope "VERIFY-only, must NOT appear in diff." |
| **GEMINI.md compressed-form parity miss** (trinity Check 18) | LOW | EE-7: C3 adds an audience-correct parallel sentence to GEMINI's compressed paragraph; Check 18 trinity-parity runs in C3 verification. |
| **40 historical files flagged** (if a future guard widened to `maintenance-docs/`) | LOW (out of scope) | DP-5: NO net-new advisory; the historical files stay outside every guard scan. |

**Unknowns (none are MAINTAINER CHECK NEEDED — all resolved by state reads):**
- The exact post-fix entry count is 211 (213 today − 2 folded, EE-2) — resolved.
- The `19b` token is the unrelated commit-batch sub-number (EE-5) — resolved, do
  not touch.
- `backlog/` is not a manifest source surface (EE-6) — resolved, C1 manifest diff
  expected empty.

No open questions require maintainer intent or a future decision; the 5 DPs are
fixed by the approved design.

---

## 9. Commit-sequence summary (the deliverable at a glance)

| # | Commit | Keyword | Scope | Depends on | Manifest regen |
|---|---|---|---|---|---|
| C1 | fold BD-167b/169b + normalize BD-195 + regen `_toc.md` | `pack-only` | `backlog/` only (NOT `_rules.md`) | — | run; stage IF non-empty (expected empty, EE-6) |
| C2 | simplify 14 grammar sites + net-new header guard in Check 32′ + pack `_rules.md` + 6 test files | NONE (cross-surface) | shared `scripts/lib/per-entry/*`, `validate-pack.py`, `recommendation.sh`, `detect.sh`, `backlog/_rules.md`, tests | **C1** (fold-then-guard) | run; stage IF non-empty (RC9 — touches `scripts/`) |
| C3 | no-letter-suffix bullet → trinity § BD-NNN numbering (×3 CLIs) | `pack-chat-only` | `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (pack root) | C2 (governance-after-enforcement) | none (no `scripts/`) |

Out-of-repo (lockstep with C3, Pack-Chat-direct, NOT a commit): the
`feedback_no_bd_letter_suffix.md` memory grandfather-retirement edit.

Each commit leaves the pack in a working state — `validate-pack.py` green + full
CI green per §4.

---

## 10. Rules-Applied Verification Block

### 10.1 Per-rule (Rules in force)

| Rule | Verification evidence | Conclusion |
|---|---|---|
| **Empirical-Evidence Blocks (every state-claim)** | §1 EE-1..EE-8 each carry the command + verbatim output + HEAD `7bdb33f` + interpretation + SUPPORTED conclusion (non-canonical set = 3; live count = 213→211; grep-zero baseline = 8; active token files = 13; `19b` = batch token; `backlog/` ∉ manifest; trinity § shapes; project data canonical). | COMPLIANT |
| **Verify the FULL CI suite (entire set per commit)** | §4.1 enumerates ALL 50 `tests`-job steps verbatim from `.github/workflows/validate-pack.yml` + the `validate` job; §4.2 mandates the coder PREFLIGHT + reviewer both run the COMPLETE set per commit; §4.3 names the specific tests this change moves (incl. `test-v11-realistic-ot.sh`, the `tracker-migrate-*` comment tests, fixture tests). | COMPLIANT |
| **CI-guard measure-then-bound** | §5.A positive (211 post-fix canonical entries pass, 0 false-pos) + §5.B negative (suffix AND pre-em-dash parenthetical both REJECT; canonical control passes); C2 recipe item 7 sizes the guard to the canonical set, stream-scoped to ID-shaped streams, derived from STREAMS data (no two-place hard-code). | COMPLIANT |
| **Rename/measure-then-bound (grep-zero gate)** | §6 leads with the grep-zero gate as a coder-PREFLIGHT + reviewer assertion; two greps (grammar sites → 0; token refs → 0 except `backlog/BD-211.md` + 40 historical); enumeration-independent; allowlist sized to KEEP only. | COMPLIANT |
| **Enumerate ENCODING surfaces** | C2 updates code + `backlog/_rules.md` + 6 test files in lockstep (recipe items 1–14); §4.3 lists every test pinning the old grammar; the header guard is added inside Check 32′ and its tests added in the same commit. | COMPLIANT |
| **Manifest regen on v11-surface commits** | C1 (e): run `build.sh --all --clean`, stage IF non-empty (`backlog/` ∉ manifest surface, EE-6 → expected empty). C2 (e): RC9 — touches `scripts/` → regen + stage IF non-empty. C3: no `scripts/` → none. | COMPLIANT |
| **Pack/project separation** | C2 carries NO keyword (cross-surface, honest); pack `backlog/_rules.md` simplified, project-template `_rules.md` VERIFY-only (NOT edited) — separate artifacts (§7 item 2); no-project-regression proven (§7, EE-8). | COMPLIANT |
| **Fail-loud / delete the old source** | C1 recipe item 5 DELETEs `BD-167b.md`/`BD-169b.md` (no stub/mirror) after safe-before-delete fold; BD-195 reconciled IN PLACE (active Resolved doc, one stale element); 40 historical files left as accurate-history (DP-5); BD-169 dangling token repointed (recipe item 3). | COMPLIANT |
| **Bounded review/fix cycle** | Each commit (C1/C2/C3) (d) states the bounded cycle applies (max 2 pairs + 1 final reviewer pass; architect escalation if dirty). | COMPLIANT |
| **Rules-Applied Verification Block + read-docs-in-full** | This §10 (per-rule + per-read-doc, evidence quoted, terminal conclusions). | COMPLIANT |
| **Agents never commit** | This doc is Writes to the plan-doc path only (chunked). No `git add/commit/push/tag/rm`; the plan instructs the coder to surface deletions to Pack Chat and never run state-changing git verbs (C1 recipe item 5). | COMPLIANT |

### 10.2 Per-read-doc (READ IN FULL — directly)

| Document | Read evidence | Conclusion |
|---|---|---|
| `ARCHITECTURE-BD-211.md` | Read tool, 480 lines (full); the 5 DPs + §2–§7 recipes + EE blocks drive every commit recipe here. | COMPLIANT |
| `RESEARCH-BD-211-GRAMMAR-BLAST-RADIUS.md` | Read tool, 574 lines (full); the 14-site / 53-ref / 3-entry / cross-surface map feeds §3 scope + §6 gate. | COMPLIANT |
| `backlog/BD-211.md` | Read tool, 15 lines (full); acceptance-criteria mapping in §0. | COMPLIANT |
| `scripts/lib/per-entry/_lib.sh` | Read tool, L70–119; §3 C2 item 1 cites the pack-backlog `entry-regex` branch (L88) + `PE_STREAM_KEYS` (L72). | COMPLIANT |
| `scripts/lib/per-entry/decompose.sh` | Read tool, L115–159; §3 C2 item 2 cites the pack-backlog `anchor_re` (L127) + project-backlog `anchor_re` (L152). | COMPLIANT |
| `scripts/lib/per-entry/toc-regenerate.sh` | Read tool, L78–137 + L238–257; §3 C2 item 3 cites `entry_regex_for_stream` (L85), title regex (L128), sort regex (L246). | COMPLIANT |
| `scripts/lib/recommendation.sh` | Read tool, L142–153; §3 C2 item 5 cites the entry-count grep (L148). | COMPLIANT |
| `scripts/lib/detect.sh` | Read tool, L53–64; §3 C2 item 6 cites the tree-presence grep (L59). | COMPLIANT |
| `scripts/validate-pack.py` | Read tool, L300–354 (STREAMS + Check 48 constants), L3160–3309 (`_list_unknown_files` + `check_mirror_in_sync` Check 32′ + Check 33), L3425–3551 (`CROSS_REF_RE` + `_collect_defined_ids` + `_extract_references`); §3 C2 items 4/7 cite L311/L3438/L3439/`check_mirror_in_sync`/`_collect_defined_ids`. | COMPLIANT |
| `backlog/_rules.md` (pack) | Read tool, 86 lines (full); §3 C2 items 8/9/10 cite L30–33, L35–43, L49. | COMPLIANT |
| `project-template/docs/project/backlog/_rules.md` | Read tool, 48 lines (full); EE-8 / §7 cite L14/L22 canonical — VERIFY-only. | COMPLIANT |
| `backlog/BD-167.md`, `BD-167b.md`, `BD-169.md`, `BD-169b.md`, `BD-195.md` | Read tool, all 5 full; C1 fold/repoint/normalize recipes quote the verbatim field sources + the BD-195 line-2 header + Alias line. | COMPLIANT |
| `scripts/tests/test-validate-pack-checks-32-33-34.sh` | Read tool, L240–262 (suffix fixture) + L570–614 (C5/C6/C7); grep-verified A5/A6 (L439–464); §3 C2 item 11 cites A5/A6/C6/C7 + the C7 dangling seed. | COMPLIANT |
| `scripts/tests/test-per-entry.sh` | grep-read L218–228; §3 C2 item 12 cites the 1.6 assertion (L223). | COMPLIANT |
| `scripts/tests/pack-help-test.sh`, `recommendation-test.sh` | grep-read L40–58 / L48–58; §3 C2 item 13 cites the `BD-167b.md` fixtures + Status fields. | COMPLIANT |
| `scripts/tests/tracker-migrate-reverse-test.sh`, `tracker-migrate-roundtrip-test.sh` | grep-read L347–351 / L443–447; §3 C2 item 14 cites the comment regexes (L349/L445). | COMPLIANT |
| `.github/workflows/validate-pack.yml` | Read tool, 287 lines (full); §4.1 enumerates ALL 50 `tests`-job steps + the `validate` job verbatim. | COMPLIANT |
| `CLAUDE.md ## Pack memory` + trinity § "BD-NNN numbering" | Provided in full in system context; CLAUDE.md L91–97 + AGENTS.md L93–100 + GEMINI.md L71 read (EE-7); §3 C3 cites the per-CLI § shapes; EE-5 confirms `19b`@L58/L60 is the unrelated batch token. | COMPLIANT |
| `feedback_no_bd_letter_suffix.md` | Read tool, full; §3 C3 quotes the grandfather clause + pending-trinity bullet to retire (memory edit). | COMPLIANT |
| `feedback_verify_full_ci_suite.md` | Read tool, full; §4.2 applies the full-CI-per-commit + integration-test-output rule (the BD-203 C-1 banner-assertion exemplar). | COMPLIANT |
| `feedback_rename_plans_measure_then_bound.md` | Read tool, full; §6 leads with the grep-zero gate (coder PREFLIGHT + reviewer), enumeration-independent. | COMPLIANT |
| `feedback_ci_guard_design_measure_then_bound.md` | Read tool, full (recall + rationale pointer); §5 applies measure-then-bound to the header guard (size to canonical, positive + negative). | COMPLIANT |
| `feedback_pack_project_separation_of_concerns.md` | Read tool, full; §7 + C2 scope treat pack vs project `_rules.md` as separate artifacts (project VERIFY-only, never edited as a side effect). | COMPLIANT |
| `feedback_architect_planner_empirical_evidence.md` | Read tool, full (recall + rationale pointer); every state-claim in §1 carries an EE block. | COMPLIANT |

**No named document was derived rather than read.** Every engine/validator/_rules/
entry/test file + the CI workflow + the 6 named memories were Read directly; every
count/claim in §1 was measured live via Bash at HEAD `7bdb33f`.
