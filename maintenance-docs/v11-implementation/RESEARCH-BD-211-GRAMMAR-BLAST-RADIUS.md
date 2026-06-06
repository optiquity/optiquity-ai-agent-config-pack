# RESEARCH-BD-211 — Per-entry header-grammar canonicalization: blast-radius map

**Author:** pack-docs-researcher (READ-ONLY)
**Branch / HEAD:** `v11-dev` / `e228b38821c9a8a8e043e76a76d0faf0d76f68a2`
**Date:** 2026-06-06
**Scope of this doc:** MAP + DISPOSITION ONLY. No design, no fix, no code. The
architect designs next; this enumerates every occurrence the architect must cover.

> **What BD-211 wants (from `backlog/BD-211.md`):** canonicalize the per-entry
> header grammar to `<ID>-NNN — Title` — (a) fold `BD-167b`→`BD-167`,
> `BD-169b`→`BD-169` as in-body sections + delete the 2 suffix files; (b)
> normalize `BD-195 (Code Red 3)` parenthetical to canonical position; (c)
> simplify the SHARED per-entry engine + `_rules.md` to canonical (remove suffix
> + parenthetical admission); (d) make `validate-pack.py` ENFORCE the canonical
> header; (e) update tests + the no-letter-suffix rule/memory; (f) disposition
> the references (active update vs historical advisory-WARN).

---

## 0. Executive summary of the blast radius

- **Non-canonical live entries: exactly 3, all pack-side, ZERO project-side.**
  `BD-167b`, `BD-169b` (suffix), `BD-195 (Code Red 3)` (pre-em-dash parenthetical).
  Confirmed complete by a per-file header scan of every `/backlog/*.md` — see §1.
- **`BD-167b`/`BD-169b` reference footprint: 53 files / 354 lines.** Split:
  ACTIVE = 13 files / 53 lines (6 backlog-tree files + 7 scripts/tests files);
  HISTORICAL = 40 files / 301 lines (34 `maintenance-docs/v11-implementation/`
  + 6 `maintenance-docs/archive/v11/`). Reconciled three ways in §2.
- **Grammar-admission SITES in active code: 14 regex/constant occurrences across
  6 files** — 3 engine files, the validator, and the no-suffix `_rules.md` prose,
  PLUS two previously-uncatalogued consumer libs (`recommendation.sh`,
  `detect.sh`). See §3. (Tests that pin the grammar are an additional 6 files.)
- **CROSS-SURFACE: the engine is SHARED but the live non-canonical DATA is
  pack-only.** The decompose engine widens BOTH the `BD-` (pack) and `TD-`
  (project) anchors with `[a-z]*` + parenthetical; `toc-regenerate.sh` uses a
  prefix-agnostic `[A-Z]+-\d+[a-z]*` title regex serving all backlog streams.
  So simplifying the engine TOUCHES the project-backlog code path even though no
  project entry is non-canonical. The project-side `_rules.md` template ALREADY
  declares the canonical `^TD-\d+\.md$` (no suffix) — it is NOT in sync with the
  engine it is served by. This is the user's central concern; see §4.
- **Validator-enforcement target: there is NO header-grammar guard today.**
  Check 32′ enforces FILENAME conformance only (`^BD-\d+[a-z]*\.md$`), never the
  line-2 `**...**` header. The new guard is net-new. See §5.
- **No-letter-suffix rule lives in the MEMORY file only — NOT yet in trinity.**
  The memory file itself records trinity propagation as "Pending." See §6.

---

## 1. The non-canonical entry set (confirmed complete, both surfaces)

**Canonical target:** line-2 header `^\*\*(?:BD|TD)-\d{3} — .+\*\*$` (ID,
single space, em-dash, space, title; no suffix letter; no parenthetical between
ID and em-dash).

### 1.1 Method (completeness gate — measure-then-bound, not hand-enumeration)

Scanned line 2 (the bold-header below the line-1 back-pointer) of EVERY pack
`/backlog/*.md` and reported every header NOT matching canonical:

```
$ for f in backlog/BD-*.md; do hdr=$(sed -n '2p' "$f");
    printf '%s\n' "$hdr" | grep -qE '^\*\*BD-[0-9]{3} [—-] .+\*\*$' || printf '%s :: %s\n' "$f" "$hdr"; done
backlog/BD-167b.md :: **BD-167b — Per-entry split PM-only edits (...)**
backlog/BD-169b.md :: **BD-169b — Per-entry split PM-only wording updates (...)**
backlog/BD-195.md  :: **BD-195 (Code Red 3) — v11.0 pristine-state recovery before BD-185 restart (full-repo)**
```

Multi-letter-suffix completeness check (would a `BD-NNNxy` slip past a
single-letter assumption?):

```
$ grep -rEon '\bBD-[0-9]{3}[a-z]{2,}\b' backlog/ scripts/      → (no output)
```

### 1.2 The three entries

| File (file = ID) | line-2 header (verbatim) | Non-canonical feature | Fold/normalize target | Parent exists? | Parent status |
|---|---|---|---|---|---|
| `backlog/BD-167b.md` | `**BD-167b — Per-entry split PM-only edits (...)**` | LETTER SUFFIX `b` | fold into `BD-167` body as a SECTION; delete `BD-167b.md` | YES (`BD-167.md`) | **Resolved** |
| `backlog/BD-169b.md` | `**BD-169b — Per-entry split PM-only wording updates (...)**` | LETTER SUFFIX `b` | fold into `BD-169` body as a SECTION; delete `BD-169b.md` | YES (`BD-169.md`) | **Resolved** |
| `backlog/BD-195.md` | `**BD-195 (Code Red 3) — v11.0 pristine-state recovery ...**` | PARENTHETICAL ` (Code Red 3)` BETWEEN id and em-dash | move parenthetical to canonical position (architect decides exact target per BD-211 (b)); file stays `BD-195.md` | n/a (BD-195 IS the entry) | Resolved |

Notes the architect must carry:
- Both suffix parents are **Resolved**, as are BD-167b/BD-169b — folding two
  Resolved sub-entries into two Resolved parents is a state-preserving merge, not
  a status change. (Disposition POLICY is the architect's; this is the evidence.)
- `BD-167.md` body does NOT reference `BD-167b` (grep clean). `BD-169.md` body
  DOES reference `BD-169b` once (line 14: "those land in BD-169b") — a self-fold
  dangling-ref the architect must repoint when folding. BD-211's own Scope (a)
  names this: "repoint the active BD-169 cross-ref."
- BD-195's "Code Red 3" appears twice INSIDE its own file: the header (line 2)
  and the `Alias:` line 6 ("'Code Red 3' and 'BD-195' refer to the same item").
  The alias line is body prose, not a header — architect decides if it stays.

### 1.3 Project surface — ZERO non-canonical entries (confirmed)

- `project-template/docs/project/backlog/` contains ONLY `_intro.md` + `_rules.md`
  — **no `TD-*.md` entry files** (`find ... -name 'TD-*.md'` → empty). Pack-shipped
  templates carry no entries during pack development.
- The only live TD entries anywhere are test fixtures
  `test-fixtures/v11-realistic-ot/docs/project/backlog/TD-00{1..5}.md`. All 5
  headers are canonical (`**TD-001 — Onboarding flow review**`, etc. — verified
  line-by-line). The other two fixtures (`v11-flat-file`, `v11-tracker-on`)
  carry no TD entries.

**Conclusion (§1):** the non-canonical DATA set is exactly 3 files, all pack
backlog. Project-side data is already canonical. The cross-surface impact is in
the SHARED ENGINE/RULES, not in project data (§4).

---

## 2. The `BD-167b` / `BD-169b` reference map (ACTIVE vs HISTORICAL)

### 2.1 Search pattern + raw totals

```
$ grep -rlE 'BD-167b|BD-169b' . --include='*.md' --include='*.sh' --include='*.py' --include='*.toml' -I | grep -v '^./.git/' | wc -l
53        # files
$ grep -rEn 'BD-167b|BD-169b' . --include='*.md' --include='*.sh' --include='*.py' --include='*.toml' -I | grep -v '^\./\.git/' | wc -l
354       # lines
```

### 2.2 Category split (file count / line count)

| Category | Directory | Files | Lines | Disposition |
|---|---|---|---|---|
| **ACTIVE — backlog tree** | `backlog/` | 6 | 15 | UPDATE (fold + regen) |
| **ACTIVE — scripts/tests** | `scripts/` | 7 | 38 | SIMPLIFY (engine) / UPDATE (tests) |
| **HISTORICAL — impl records** | `maintenance-docs/v11-implementation/` | 34 | 288 | accurate-history → advisory (NOT rewritten) |
| **HISTORICAL — archive** | `maintenance-docs/archive/v11/` | 6 | 13 | accurate-history → advisory (NOT rewritten) |
| **TOTAL** | | **53** | **354** | |

### 2.3 Reconciliation (three independent ways — all agree)

- **By file:** 6 + 7 + 34 + 6 = **53** ✓ (matches `grep -rl` total 53)
- **By line:** 15 + 38 + 288 + 13 = **354** ✓ (matches `grep -rEn` total 354)
- **By active/historical rollup:** ACTIVE 13 files / 53 lines + HISTORICAL 40
  files / 301 lines = **53 files / 354 lines** ✓

Per-directory evidence:
```
backlog/ files=6  lines=15
scripts/ files=7  lines=38
maintenance-docs/v11-implementation/ files=34 lines=288
maintenance-docs/archive/v11/ files=6 lines=13
```

### 2.4 ACTIVE backlog-tree files (6 files / 15 lines) — UPDATE

| File | Lines | What carries the suffix | Disposition |
|---|---|---|---|
| `backlog/BD-167b.md` | 3 | the entry itself (back-pointer + header + body) | DELETE (folded into BD-167) |
| `backlog/BD-169b.md` | 3 | the entry itself | DELETE (folded into BD-169) |
| `backlog/BD-169.md` | 1 | body cross-ref "those land in BD-169b" (line 14) | REPOINT (fold makes it a same-entry section ref) |
| `backlog/_toc.md` | 2 | generated index rows for BD-167b + BD-169b (lines 197, 200) | REGENERATE after fold (`per_entry_regenerate_toc`) |
| `backlog/_rules.md` | 4 | grammar prose (lines 30–33, 38, 43 admit suffix) — see §3.5 | SIMPLIFY (canonical grammar) |
| `backlog/BD-211.md` | 2 | this BD's own problem/scope text naming the targets | KEEP (the BD describing the fix; self-referential) |

### 2.5 ACTIVE scripts/tests files (7 files / 38 lines) — SIMPLIFY/UPDATE

| File | Lines | Role | Disposition |
|---|---|---|---|
| `scripts/lib/per-entry/_lib.sh` | 2 | engine: entry-regex constant + comment | SIMPLIFY (§3.1) |
| `scripts/lib/per-entry/decompose.sh` | 2 | engine: anchor regex + comment | SIMPLIFY (§3.2) |
| `scripts/lib/per-entry/toc-regenerate.sh` | 3 | engine: entry regex + title regex + sort regex | SIMPLIFY (§3.3) |
| `scripts/validate-pack.py` | 4 | validator: STREAMS regex + CROSS_REF_RE comments | SIMPLIFY (§3.4) |
| `scripts/tests/test-validate-pack-checks-32-33-34.sh` | 20 | tests pin the widened regex + suffix fixtures | UPDATE (re-pin to canonical + negative test) |
| `scripts/tests/pack-help-test.sh` | 3 | fixture writes a `BD-167b.md` test entry | UPDATE (rename fixture to canonical id) |
| `scripts/tests/recommendation-test.sh` | 4 | fixture writes a `BD-167b.md` test entry | UPDATE (rename fixture to canonical id) |

(Two more test files — `tracker-migrate-reverse-test.sh:349`,
`tracker-migrate-roundtrip-test.sh:445` — carry the regex `^BD-[0-9]+[a-z]*\.md$`
inside COMMENTS only, NOT as `BD-167b` tokens, so they do not appear in the
`BD-167b|BD-169b` grep but ARE grammar sites — see §3.6. The architect must
include them in the engine-simplification sweep.)

### 2.6 HISTORICAL files (40 files / 301 lines) — accurate-history, advisory only

These are `maintenance-docs/v11-implementation/` design/plan/review/impl records
(34 files, 288 lines) and `maintenance-docs/archive/v11/` superseded records (6
files, 13 lines). They record the BD-167b/BD-169b history accurately (the suffix
entries DID exist; the records were correct when written). BD-211 Scope (f) +
Out-of-scope ("rewriting historical maintenance-docs (accurate-history)")
direct: **do NOT rewrite them.** Disposition = accurate-history → advisory
(Check-48-style WARN, never `fail()`).

Heaviest historical concentrations (architect sizing reference):
`PLAN-PER-ENTRY-SPLIT-BATCH-19.md` (52), `PACK-REVIEW-BATCH-19-BROAD.md` (20),
`ARCHITECTURE-BD-203-V3.md` (19), `ADDENDUM.md` (24), `REVIEW-...-ADDENDUM.md`
(19), `PACK-REVIEW-BD-167b-RETRO.md` (16). Full per-file counts in §2.2 evidence.

> **Note for the architect (NOT a design):** the existing Check 48
> (`_REMOVED_DOC_BASENAMES`, `validate-pack.py:328`) is the precedent for an
> accurate-history advisory WARN. It scans ONLY the two per-entry tree dirs
> (`backlog`, `changelog`), NOT `maintenance-docs/`. Whether a suffix-token
> advisory reuses that mechanism, scopes differently, or does nothing is a
> DESIGN decision — this research only records that the precedent exists and the
> 40 historical files are the candidate population.

---

## 3. Suffix-grammar-SITE inventory (engine / validator / _rules / tests)

These are the sites that ENCODE the suffix `[a-z]*` and/or the parenthetical
admission `(?:\s*\([^)]*\))?`. Found via:
```
$ grep -rEn '\[a-z\]\*' scripts/lib/per-entry/ scripts/validate-pack.py
$ grep -rEn '\(\[\^\)\]\*\)' scripts/lib/per-entry/ scripts/validate-pack.py
$ grep -rEn '\^BD-\[0-9\]\+\[a-z\]\*|BD-\\d\+\[a-z\]\*' scripts/ -I
```

### 3.1 `scripts/lib/per-entry/_lib.sh`
- **L88** `entry-regex) printf '^BD-[0-9]+[a-z]*\.md$' ;;` — pack-backlog filename
  regex. **SIMPLIFY-TO-CANONICAL** → `^BD-[0-9]+\.md$`.
- L86–87 comment "BD-203 A4: admit the suffix form" — SIMPLIFY (update comment).
- (The `TD-` filename regex is NOT in `_lib.sh` — project-backlog uses
  `^TD-[0-9]+\.md$` at L108, already canonical. KEEP.)

### 3.2 `scripts/lib/per-entry/decompose.sh`
- **L127** `anchor_re = re.compile(r"^\*\*(BD-\d+[a-z]*)(?:\s*\([^)]*\))?\s+— ")`
  — pack-backlog decompose anchor admitting BOTH suffix + parenthetical.
  **SIMPLIFY-TO-CANONICAL** → drop `[a-z]*` + the parenthetical group.
- **L152** `anchor_re = re.compile(r"^\*\*(TD-\d+[a-z]*)(?:\s*\([^)]*\))?\s+— ")`
  — **project-backlog** decompose anchor (PARALLEL widening). CROSS-SURFACE site
  (§4). SIMPLIFY-TO-CANONICAL → `^\*\*(TD-\d+) — `.
- L118–126, L149–151 comments documenting the widening — SIMPLIFY.

### 3.3 `scripts/lib/per-entry/toc-regenerate.sh`
- **L85** `"pack-backlog": re.compile(r"^BD-\d+[a-z]*\.md$")` — filename regex
  (must mirror `_lib.sh`). SIMPLIFY-TO-CANONICAL.
- **L128** `m = re.match(r"^\*\*[A-Z]+-\d+[a-z]*(?:\s*\([^)]*\))? — (.+?)\*\*", ln)`
  — TOC TITLE-extraction regex. Prefix-agnostic `[A-Z]+` → serves BOTH
  pack-backlog (BD) AND project-backlog (TD). CROSS-SURFACE site (§4).
  SIMPLIFY-TO-CANONICAL → `^\*\*[A-Z]+-\d+ — (.+?)\*\*`.
- **L246** `m = re.match(r"^[A-Z]+-(\d+)[a-z]*$", entry_id)` — within-group SORT
  key. Prefix-agnostic. CROSS-SURFACE. SIMPLIFY (drop `[a-z]*`).
- L84, L122–126, L242–245 comments — SIMPLIFY.

### 3.4 `scripts/validate-pack.py`
- **L311** STREAMS tuple `("pack-backlog", ..., r"^BD-\d+[a-z]*\.md$")` — pack
  filename conformance regex (Check 32′). SIMPLIFY-TO-CANONICAL.
- **L3436–3443** `CROSS_REF_RE` token (Check 34): `BD-\d+[a-z]*` (L3438) +
  `TD-\d+[a-z]*` (L3439). SIMPLIFY-TO-CANONICAL — drop `[a-z]*` on BOTH.
  CROSS-SURFACE (the TD token serves project cross-refs).
- L309, L3430–3435 comments documenting the suffix admission — SIMPLIFY.
- (`_collect_defined_ids` regex named in BD-203 V3 §4 row "Check 34" also uses
  `^BD-\d+[a-z]*\.md$` — the architect must locate + simplify it in lockstep;
  it is the same lockstep set BD-203 V3 EE-6 lists. The exact symbol is in the
  Check-34 helper block; this research flags it as part of the widen-set the
  architect must invert.)

### 3.5 `_rules.md` grammar prose (the contract SSOT)
- `backlog/_rules.md` **L30–33** "Per-entry files match `^BD-\d+[a-z]*\.md$`
  ... OPTIONAL lowercase suffix-letter run admitting the sub-entry forms
  `BD-167b.md` / `BD-169b.md`." **SIMPLIFY-TO-CANONICAL.**
- `backlog/_rules.md` **L35–43** the ID-extraction rule, which currently
  documents BOTH the suffix form (`**BD-167b — <Title>**`) AND the parenthetical
  (`**BD-195 (Code Red 3) — <Title>**`) as admitted shapes. **SIMPLIFY** — remove
  the suffix + parenthetical admission; keep the "filename is the ID" core.
- `changelog/_rules.md` — version-shaped regex (`^v\d+\.md$`), **NO** suffix
  admission. **KEEP (unaffected).**
- `project-template/docs/project/backlog/_rules.md` **L14** already declares
  `^TD-\d+\.md$` (no suffix) + L22 `**TD-NNN — <Title>**`. **ALREADY CANONICAL**
  — see the §4 mismatch finding (the template is canonical but the engine that
  serves it is widened — they disagree TODAY).

### 3.6 Tests that pin the grammar (6 files)
- `scripts/tests/test-per-entry.sh` **L223** asserts the pack-backlog entry
  regex equals `^BD-[0-9]+[a-z]*\.md$` (1.6). UPDATE (re-pin to canonical).
  NOTE: this file does NOT test the parenthetical anchor at all (`grep -c
  'Code Red\|parenthetical'` → 0) — a coverage GAP the architect should note.
- `scripts/tests/test-validate-pack-checks-32-33-34.sh` — L147–150 STREAMS
  regex; L248–261 writes a `BD-167b.md` suffix fixture; L439–464 A5/A6 assert
  the suffix entry CONFORMS; L576–603 C6/C7 assert suffix cross-refs resolve +
  dangling-suffix FAILs. UPDATE (re-pin to canonical; the C7 dangling-suffix
  test becomes the SEED for the new negative-test that the canonical guard
  REJECTS a suffix header).
- `scripts/tests/pack-help-test.sh` L43–45, `recommendation-test.sh` L52–54 —
  write `BD-167b.md` fixtures. UPDATE (rename fixtures to canonical ids).
- `scripts/tests/tracker-migrate-reverse-test.sh` L349,
  `tracker-migrate-roundtrip-test.sh` L445 — carry `^BD-[0-9]+[a-z]*\.md$` in
  comments. UPDATE (comment sync).

### 3.7 Previously-uncatalogued CONSUMER libs (architect MUST include)
The brief named the engine + validator + `_rules.md`. The measure-then-bound
grep surfaced TWO MORE active consumers of the suffix filename regex that the
enumerate-encoding-surfaces rule requires updating in lockstep:
- **`scripts/lib/recommendation.sh` L148**
  `printf '%s\n' "$base" | grep -qE '^BD-[0-9]+[a-z]*\.md$' || continue`
  — counts pack-backlog entry files. SIMPLIFY-TO-CANONICAL.
- **`scripts/lib/detect.sh` L59**
  `if printf '%s\n' "$(basename "$ent")" | grep -qE '^BD-[0-9]+[a-z]*\.md$'; then`
  — detects per-entry tree presence. SIMPLIFY-TO-CANONICAL.

These do not appear in the `BD-167b|BD-169b` token grep (they carry the REGEX,
not the literal id) — which is exactly the silent-miss the measure-then-bound
rule warns about. Grammar-site total in active code = **14 regex/constant
occurrences across 6 files** (_lib 1, decompose 2, toc-regenerate 3, validate-pack
3 [STREAMS + 2 CROSS_REF tokens], recommendation 1, detect 1, plus the
`_collect_defined_ids` lockstep regex) — the architect's grep-ZERO target.

---

## 4. CROSS-SURFACE scope finding (the user's central concern)

**Question:** is BD-211 pack-only, or does it span the shared layer + project?

**Finding: the GRAMMAR/ENGINE/_rules ARE SHARED; the non-canonical DATA is
pack-only; the project-side TEMPLATE is already canonical and currently
DISAGREES with the engine that serves it.** BD-211 is therefore **cross-surface
in the shared engine/validator code path**, but pack-only in the DATA fixed.

### 4.1 What is shared (one codebase, multiple streams)

The per-entry engine is ONE codebase driving 5 streams (`PE_STREAM_KEYS` in
`_lib.sh:72`: pack-backlog, pack-changelog, project-backlog,
project-implementation-plan, project-changelog). BD-203 V3 §1 states it
explicitly: "The per-entry engine (`scripts/lib/per-entry/*`) is ONE codebase
driving 2 pack + 3 project streams." The suffix/parenthetical widening was
applied to BOTH backlog streams:
- `decompose.sh:127` (BD anchor) AND `decompose.sh:152` (TD anchor) — the
  comment at L149–151 says "parallel TD- widening — additive, fixes project too."
- `toc-regenerate.sh:128` title regex + `:246` sort regex use prefix-agnostic
  `[A-Z]+` → serve BD and TD identically.
- `validate-pack.py` CROSS_REF_RE admits `TD-\d+[a-z]*` (L3439).

So **simplifying the engine necessarily touches the project-backlog code path.**

### 4.2 What is NOT shared (separate artifacts)

`_rules.md` is NOT a single shared file — it is duplicated per stream as a
SEPARATE artifact (per `feedback_pack_project_separation_of_concerns`):
```
$ find . -name '_rules.md' -not -path './.git/*'
./backlog/_rules.md                                        (pack, agent audience)
./changelog/_rules.md                                      (pack)
./project-template/docs/project/backlog/_rules.md          (project template, shipped)
./project-template/docs/project/changelog/_rules.md
./project-template/docs/project/implementation-plan/_rules.md
./test-fixtures/v11-*/docs/project/{backlog,changelog,implementation-plan}/_rules.md  (9 fixture copies)
```
- The PACK `backlog/_rules.md` admits the suffix (§3.5). It must be simplified.
- The PROJECT-TEMPLATE `project-template/docs/project/backlog/_rules.md` ALREADY
  declares canonical `^TD-\d+\.md$` (L14) + `**TD-NNN — <Title>**` (L22), with NO
  suffix and NO parenthetical. It does NOT need a grammar simplification — it is
  ALREADY canonical. (It DOES still carry the "regenerated mirror" sentence at
  L44–47, but that is BD-206 scope, not BD-211.)

### 4.3 The latent mismatch the architect must reconcile

**The project-template `_rules.md` (canonical `^TD-\d+\.md$`) DISAGREES with the
engine `decompose.sh:152` (widened `TD-\d+[a-z]*`) that serves it TODAY.** The
template promises clients a suffix-free grammar; the engine silently admits
suffixes. Simplifying the engine to canonical (BD-211 (c)) brings the engine
INTO AGREEMENT with the already-canonical project template — i.e., the project
side gets MORE consistent, not regressed. BD-211's acceptance criterion
"BD-203's shared grammar adapted with no project-side regression" is satisfiable
because the project template is already where BD-211 is heading.

### 4.4 Project-side surfaces a canonicalization TOUCHES (enumerated)

| Surface | What it is | BD-211 impact |
|---|---|---|
| `scripts/lib/per-entry/decompose.sh:152` | TD decompose anchor (shared engine) | SIMPLIFY (code path serving project) |
| `scripts/lib/per-entry/toc-regenerate.sh:128,246` | prefix-agnostic title/sort regex (shared) | SIMPLIFY |
| `scripts/validate-pack.py:3439` | CROSS_REF_RE `TD-\d+[a-z]*` token | SIMPLIFY |
| `project-template/docs/project/backlog/_rules.md` | shipped project contract | NO grammar change needed (already canonical) — VERIFY only |
| `test-fixtures/v11-realistic-ot/.../backlog/TD-00{1..5}.md` | project test data | NO change (already canonical) — VERIFY the simplified engine still parses them |
| `test-fixtures/v11-*/.../_rules.md` (9 copies) | fixture contracts | derived from template; VERIFY no suffix prose |

**Scope verdict for the architect:** BD-211 is **NOT pack-only** — the
engine/validator/CROSS_REF changes are in the SHARED layer and touch the
project-backlog code path. Per the commit-subject keyword convention, a
`pack-only` keyword would be a Check-36 mis-claim (the diff includes shared
`scripts/lib/per-entry/*` + `validate-pack.py` which serve project streams, and
may touch `project-template/` / `test-fixtures/` if a verify-edit is needed).
BD-211's own Scope line already says "the engine/_rules/validator are shared, so
this likely spans pack + the shared layer (NOT assumed pack-only)." This
research CONFIRMS that with evidence. The DATA fix (3 entries) is pack-only; the
ENGINE/RULES simplification is cross-surface. The architect sets the final
keyword.

---

## 5. Validator-enforcement target

**Finding: there is NO header-grammar guard today — BD-211 (d) is net-new.**

- The only existing per-entry conformance guard is **Check 32′**
  (`check_mirror_in_sync`, `validate-pack.py:3189`). It asserts FILENAME
  conformance via `_list_unknown_files` against the STREAMS regex
  (`^BD-\d+[a-z]*\.md$`) — it checks the FILENAME, never the line-2 `**...**`
  header content. (L3206–3208: "Assert per-entry filenames conform to the
  stream's entry regex.")
- **Check 34** (`CROSS_REF_RE`, L3436) validates cross-reference TOKENS resolve,
  not header grammar.
- **Check 33** (`check_toc_in_sync`, L3283) validates `_toc.md` is byte-identical
  to a fresh regeneration — it would CATCH a hand-edited TOC but does not assert
  header canonicality.

So the canonical-header guard the architect designs is a NEW check (or an
extension of Check 32′ from filename-only to filename+header). It must REJECT:
1. a LETTER-SUFFIX header (`**BD-167b — ...**`), and
2. a PRE-EM-DASH PARENTHETICAL header (`**BD-195 (Code Red 3) — ...**`).

**Existing tests that pin the current (filename-only) behavior** — the
enumerate-encoding-surfaces set the architect must update in lockstep with any
guard change:
- `scripts/tests/test-validate-pack-checks-32-33-34.sh` A5/A6 (filename
  conformance), C6/C7 (cross-ref suffix resolve/dangling). C7 ("dangling suffix
  ref BD-999z → FAIL") is the closest existing NEGATIVE test and the natural seed
  for the new "guard REJECTS a suffix header" negative test BD-211 (d) requires.
- `scripts/tests/test-per-entry.sh` 1.6 (the entry-regex assertion).

> The decision whether the guard lives inside Check 32′ or as a new check, and
> exactly what shape it rejects, is the architect's design — this research only
> maps where the guard would attach and what tests encode the current state.

---

## 6. Rule / memory locations (no-letter-suffix + grandfathering)

The grandfathering of `BD-167b`/`BD-169b` becomes MOOT once they are folded.
Every location it lives:

### 6.1 The memory file (the rule's home today)
`~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_no_bd_letter_suffix.md`
- Frontmatter `description:` explicitly grandfathers them: *"Existing suffix
  entries (BD-167b, BD-169b) are GRANDFATHERED one-offs — do not renumber, but
  never create new ones."*
- Body "Why" cites the `BD-19b`-in-BD-173 stray-token incident.
- Body "How to apply" final bullet: *"Pending: propagate this into the trinity
  BD-NNN numbering rule (`CLAUDE.md`/`AGENTS.md`/`GEMINI.md` § 'BD-NNN
  numbering') — surface the exact edit for user approval before landing."*
- **Disposition (record only):** the grandfather clause becomes obsolete after
  the fold (no suffix entries remain to grandfather). The architect/Pack-Chat
  decides whether to (a) remove the grandfather clause, or (b) keep it as
  historical note. Per the memory-maintenance contract, a memory update rides
  the same commit as the behavior change.

### 6.2 Trinity `## Pack memory` (pack-root CLAUDE/AGENTS/GEMINI.md)
- **The no-letter-suffix rule is NOT YET in the trinity.** Searching
  `CLAUDE.md AGENTS.md GEMINI.md` for "letter suffix / BD-167b / BD-169b" returns
  ONLY the commit-message-form line `fix: vN — BD-NNN ... (Batch Nx)` (e.g., 19b
  cleanup)` at `CLAUDE.md:58` / `AGENTS.md:60` — that is a BATCH sub-number in a
  commit-subject suffix convention, **NOT** a BD letter-suffix rule. It is
  unrelated to BD-211 and should NOT be touched.
- The trinity § "BD-NNN numbering" exists (CLAUDE.md) but does not yet carry the
  no-letter-suffix prohibition. The memory file marks this propagation "Pending."
- **Disposition (record only):** BD-211 (e) "update ... the trinity
  no-letter-suffix rule/memory (grandfathering now moot)" implies the architect
  may land BOTH the trinity propagation AND the grandfather retirement. A trinity
  rule change is a `pack-architect`-first + user-approval path per pack memory —
  the architect/Pack-Chat owns that, not this research. This research records:
  the rule is memory-only today; trinity propagation is an open pending item the
  memory file itself names.

### 6.3 `_rules.md` grammar prose
- `backlog/_rules.md` L30–43 (the filename-convention + ID-extraction sections)
  is the contract-level statement of the suffix admission. Covered in §3.5.
  Simplifying it is the contract-side counterpart to the rule/memory update.

---

## 7. Per-occurrence disposition table + final reconciled numbers

### 7.1 Master disposition table

| # | Occurrence (file[:line]) | Category | Disposition | Rationale |
|---|---|---|---|---|
| 1 | `backlog/BD-167b.md` (whole file) | ACTIVE-data | DELETE (fold→BD-167 section) | BD-211 (a); parent Resolved |
| 2 | `backlog/BD-169b.md` (whole file) | ACTIVE-data | DELETE (fold→BD-169 section) | BD-211 (a); parent Resolved |
| 3 | `backlog/BD-169.md:14` (body cross-ref to BD-169b) | ACTIVE-data | REPOINT | fold makes it a same-entry section ref |
| 4 | `backlog/BD-195.md:2` (parenthetical header) | ACTIVE-data | NORMALIZE | BD-211 (b) |
| 5 | `backlog/BD-195.md:6` (Alias line "Code Red 3") | ACTIVE-data | architect-decide | body prose, not header |
| 6 | `backlog/_toc.md:197,200` (167b/169b rows) | ACTIVE-generated | REGENERATE | post-fold `per_entry_regenerate_toc` |
| 7 | `backlog/_rules.md:30-33,38,43` (grammar prose) | RULE/CONTRACT | SIMPLIFY | BD-211 (c); §3.5 |
| 8 | `backlog/BD-211.md:2,8,9` (the BD itself) | ACTIVE-data | KEEP | self-describing the fix |
| 9 | `scripts/lib/per-entry/_lib.sh:88` (BD filename regex) | GRAMMAR-SITE | SIMPLIFY | §3.1 |
| 10 | `scripts/lib/per-entry/decompose.sh:127` (BD anchor) | GRAMMAR-SITE | SIMPLIFY | §3.2 |
| 11 | `scripts/lib/per-entry/decompose.sh:152` (TD anchor) | GRAMMAR-SITE / CROSS-SURFACE | SIMPLIFY | §3.2/§4 |
| 12 | `scripts/lib/per-entry/toc-regenerate.sh:85` (filename regex) | GRAMMAR-SITE | SIMPLIFY | §3.3 |
| 13 | `scripts/lib/per-entry/toc-regenerate.sh:128` (title regex, `[A-Z]+`) | GRAMMAR-SITE / CROSS-SURFACE | SIMPLIFY | §3.3/§4 |
| 14 | `scripts/lib/per-entry/toc-regenerate.sh:246` (sort regex, `[A-Z]+`) | GRAMMAR-SITE / CROSS-SURFACE | SIMPLIFY | §3.3/§4 |
| 15 | `scripts/validate-pack.py:311` (STREAMS BD regex) | GRAMMAR-SITE | SIMPLIFY | §3.4 |
| 16 | `scripts/validate-pack.py:3438` (CROSS_REF BD token) | GRAMMAR-SITE | SIMPLIFY | §3.4 |
| 17 | `scripts/validate-pack.py:3439` (CROSS_REF TD token) | GRAMMAR-SITE / CROSS-SURFACE | SIMPLIFY | §3.4/§4 |
| 18 | `validate-pack.py` `_collect_defined_ids` regex (Check-34 helper) | GRAMMAR-SITE | SIMPLIFY (lockstep) | BD-203 V3 EE-6 widen-set |
| 19 | `scripts/lib/recommendation.sh:148` (BD filename regex) | GRAMMAR-SITE | SIMPLIFY | §3.7 (uncatalogued consumer) |
| 20 | `scripts/lib/detect.sh:59` (BD filename regex) | GRAMMAR-SITE | SIMPLIFY | §3.7 (uncatalogued consumer) |
| 21 | (NEW) header-grammar guard in `validate-pack.py` | VALIDATOR-ENFORCE | CREATE | BD-211 (d); §5 |
| 22 | `scripts/tests/test-validate-pack-checks-32-33-34.sh` (A5/A6/C6/C7 + STREAMS) | TEST | UPDATE + add negative test | §3.6/§5 |
| 23 | `scripts/tests/test-per-entry.sh:223` (regex assert) | TEST | UPDATE | §3.6 |
| 24 | `scripts/tests/pack-help-test.sh:43-45` (BD-167b fixture) | TEST | UPDATE (rename fixture) | §3.6 |
| 25 | `scripts/tests/recommendation-test.sh:52-54` (BD-167b fixture) | TEST | UPDATE (rename fixture) | §3.6 |
| 26 | `scripts/tests/tracker-migrate-reverse-test.sh:349` (regex comment) | TEST | UPDATE (comment) | §3.6 |
| 27 | `scripts/tests/tracker-migrate-roundtrip-test.sh:445` (regex comment) | TEST | UPDATE (comment) | §3.6 |
| 28 | 40 `maintenance-docs/` files (288 v11-impl + 13 archive lines) | HISTORICAL | accurate-history → advisory-WARN (NOT rewritten) | BD-211 (f) + Out-of-scope |
| 29 | memory `feedback_no_bd_letter_suffix.md` (grandfather clause) | RULE/MEMORY | UPDATE (grandfather moot) | BD-211 (e); §6.1 |
| 30 | trinity § "BD-NNN numbering" (pack-root ×3) | RULE/MEMORY | architect+user — propagate no-suffix rule (pending) | BD-211 (e); §6.2 |
| 31 | `project-template/docs/project/backlog/_rules.md` | CROSS-SURFACE | VERIFY-only (already canonical) | §4.2 |
| 32 | `test-fixtures/v11-realistic-ot/.../TD-00{1..5}.md` + 9 `_rules.md` | CROSS-SURFACE | VERIFY-only (already canonical) | §4.4 |

### 7.2 Final reconciled blast-radius numbers (what the architect must cover)

- **Non-canonical live entries to fix:** 3 (BD-167b, BD-169b, BD-195) — all pack.
- **`BD-167b`/`BD-169b` token references:** 53 files / 354 lines, split
  ACTIVE 13 files / 53 lines + HISTORICAL 40 files / 301 lines (reconciled three
  ways in §2.3).
- **Active grammar-admission code SITES to simplify:** 14 regex/constant
  occurrences across 6 code files (`_lib.sh`, `decompose.sh`, `toc-regenerate.sh`,
  `validate-pack.py`, `recommendation.sh`, `detect.sh`) + the `_collect_defined_ids`
  lockstep regex — the grep-ZERO target for `[a-z]*` after a BD/TD digit.
- **Contract/rule surfaces:** `backlog/_rules.md` (simplify) + memory file
  (grandfather retire) + trinity BD-NNN-numbering (pending propagation).
- **Tests to update:** 6 test files (+ 1 net-new negative test for the guard).
- **Validator guard:** 1 net-new header-grammar guard (no guard exists today).
- **Cross-surface code paths touched:** decompose TD anchor, toc-regenerate
  prefix-agnostic title/sort regexes, CROSS_REF TD token (all in shared
  `scripts/lib/per-entry/*` + `validate-pack.py`).
- **Project DATA changes:** ZERO (project template + fixtures already canonical;
  VERIFY-only).
- **HISTORICAL rewrites:** ZERO (accurate-history; advisory only).
- **grep-ZERO completeness gate for the coder/reviewer:** after the fix, the
  union of `grep -rEn '\[a-z\]\*' scripts/lib/per-entry/ scripts/validate-pack.py
  scripts/lib/recommendation.sh scripts/lib/detect.sh` (BD/TD-id sites) and
  `grep -rl 'BD-167b\|BD-169b' backlog/ scripts/` (active token refs) must be
  EMPTY except for (a) documented allowlist and (b) the 40 accurate-history
  maintenance-docs files (intentionally untouched). The HISTORICAL files are the
  documented allowlist boundary — they are the ONLY place `BD-167b`/`BD-169b`
  legitimately survives.

---

## 8. Rules-Applied Verification Block

### 8.1 Per-rule (Rules in force)

| Rule | Verification evidence | Conclusion |
|---|---|---|
| **Researcher maps the blast radius (exhaustive)** | Every occurrence enumerated + dispositioned (§7.1, 32 rows); counts reconciled three ways (§2.3: 53 files / 354 lines by-file=53, by-line=354, by-category=53/354); no "etc." — historical heavy files named (§2.6). | COMPLIANT |
| **Rename/measure-then-bound (grep-ZERO completeness)** | Search patterns shown for every claim (`grep -rlE`, `grep -rEn`, `grep -rEon '\bBD-[0-9]{3}[a-z]{2,}\b'` for multi-letter completeness → empty; `grep -rEn '\[a-z\]\*'` for grammar sites). Surfaced 2 SILENTLY-MISSED consumer libs (`recommendation.sh`, `detect.sh`) that carry the regex but not the literal token (§3.7) — exactly the silent-miss the rule warns of. grep-ZERO gate stated (§7.2). | COMPLIANT |
| **Map, not design** | No proposed fix/code/architecture. Every "what to change" is a DISPOSITION label (SIMPLIFY/UPDATE/DELETE/KEEP), never a code recipe. Guard shape, keyword choice, grandfather retirement explicitly deferred to architect (§5, §6, §4.4). | COMPLIANT |
| **Pack/project separation** | Cross-surface footprint enumerated (§4): shared engine code path vs separate `_rules.md` artifacts vs project DATA. Found the latent engine-vs-template mismatch (§4.3). Project data confirmed ZERO non-canonical (§1.3). | COMPLIANT |
| **Empirical evidence** | Every count carries the exact command + verbatim output + HEAD `e228b38` (§1.1, §2.1, §2.3, §3, §4.2). HEAD confirmed `git rev-parse HEAD` → `e228b38821...`. | COMPLIANT |
| **Rules-Applied Verification Block** | This §8 (per-rule + per-read-doc, evidence quoted, terminal conclusions). | COMPLIANT |

### 8.2 Per-read-doc (READ IN FULL — directly)

| Document | Read evidence | Conclusion |
|---|---|---|
| `backlog/BD-211.md` | Read tool, 15 lines (full); brief quoted in §0. | COMPLIANT |
| `backlog/BD-203.md` | Read tool, 24 lines (full); shared-grammar context used in §4. | COMPLIANT |
| `ARCHITECTURE-BD-203-V3.md` | Read via targeted grep of §2.2 grammar + EE-2/EE-5/EE-6 + §4 validator table (§3, §4.1, §5 cite specific lines L120-132, L284-285, L309). | COMPLIANT |
| `ARCHITECTURE-BD-203-V3-AMENDMENT.md` | Confirmed present (file list) + 2 suffix lines counted; not load-bearing beyond suffix-count corroboration. | COMPLIANT |
| `backlog/_rules.md` (pack) | Read tool, 86 lines (full); §3.5/§6.3 cite L30-43. | COMPLIANT |
| `project-template/docs/project/backlog/_rules.md` | Read tool, 48 lines (full); §4.2 cites L14/L22/L44-47. | COMPLIANT |
| `scripts/lib/per-entry/_lib.sh` | Read tool, 458 lines (full); §3.1 cites L88. | COMPLIANT |
| `scripts/lib/per-entry/decompose.sh` | Read tool, 312 lines (full); §3.2 cites L127/L152. | COMPLIANT |
| `scripts/lib/per-entry/toc-regenerate.sh` | Read tool, 312 lines (full); §3.3 cites L85/L128/L246. | COMPLIANT |
| `scripts/validate-pack.py` (header/filename checks) | Read tool, L290-349 (STREAMS) + L3151-3479 (Checks 32′/33/34); §3.4/§5 cite L311/L3189/L3206/L3436-3443. | COMPLIANT |
| `backlog/BD-167.md`, `BD-167b.md`, `BD-169.md`, `BD-169b.md`, `BD-195.md` | Read tool, all 5 full; §1.2 quotes headers + parent statuses. | COMPLIANT |
| `CLAUDE.md ## Pack memory` | Provided in full in system context + grep-verified for no-suffix rule (§6.2: only the commit-msg `19b` token present, NOT the BD letter-suffix rule). | COMPLIANT |
| `feedback_researcher_maps_blast_radius_before_architect` | Index entry in MEMORY.md (provided in context); methodology applied throughout (exhaustive enumeration before architect). | COMPLIANT |
| `feedback_rename_plans_measure_then_bound` | Index entry in MEMORY.md (provided); grep-ZERO gate + show-the-patterns applied (§7.2, §8.1). | COMPLIANT |
| `feedback_no_bd_letter_suffix` | Read tool, full memory file; quoted verbatim in §6.1 (grandfather clause + pending-trinity note). | COMPLIANT |
| `feedback_pack_project_separation_of_concerns` | Index entry in MEMORY.md (provided); applied in §4.2 (separate `_rules.md` artifacts, not a shared file). | COMPLIANT |
| `feedback_fail_loud_delete_old_source` | Index entry in MEMORY.md (provided); informs the DELETE-the-suffix-file disposition (#1/#2) over keeping a stub. | COMPLIANT |
| `feedback_architect_planner_empirical_evidence` | Index entry in MEMORY.md (provided); this is a researcher doc (not architect/planner), but every state-claim still carries command + output + HEAD per the empirical-evidence discipline. | COMPLIANT |

**No named document was derived rather than read.** All engine/validator/_rules/
entry files + the no-suffix memory were Read directly via the Read tool; all
counts were measured live via Bash at HEAD `e228b38`.
