# ARCHITECTURE-BD-211 — Canonicalize the per-entry header grammar

**Author:** pack-architect
**Branch / HEAD:** `v11-dev` / `7bdb33f671b56e9e804bf17e0b85dda94b9d78b8`
**Date:** 2026-06-06
**Foundation:** `maintenance-docs/v11-implementation/RESEARCH-BD-211-GRAMMAR-BLAST-RADIUS.md`
(the blast-radius map — BUILT ON, not re-derived). This doc DESIGNS; a planner
then a coder execute.

**Canonical target grammar.** A per-entry line-2 bold header is canonical iff it
matches `^\*\*(?:BD|TD)-\d+ — .+\*\*$`: prefix `BD`/`TD`, a hyphen, digits, a
single ASCII space, an em-dash (U+2014), a single space, then the title, all
inside `**…**`. NO letter-suffix run after the digits; NO parenthetical between
the ID and the em-dash. The per-entry FILENAME remains the ID (`BD-167.md` →
`BD-167`); a parenthetical, if any, is title text and lives AFTER the em-dash.

---

## 1. DECISION POINTS (user resolves these; mechanics resolved by the architect below)

| # | Decision | Architect recommendation | Why it needs the user |
|---|---|---|---|
| **DP-1** | **BD-195 normalized line-2 header.** The `(Code Red 3)` parenthetical sits between the ID and the em-dash today. Where does it go? | Move it to the END of the title, inside the bold span: `**BD-195 — v11.0 pristine-state recovery before BD-185 restart (full-repo) (Code Red 3)**`. Keep the `Alias:` line (line 6) UNCHANGED — it is body prose, already canonical, and is the durable place the "Code Red 3" ↔ "BD-195" equivalence is recorded. | The exact title text is editorial; the user owns BD-195's prose. Two viable placements (end-of-title vs. dropping the parenthetical entirely since the Alias line already records it). |
| **DP-2** | **Fold structure for BD-167b → BD-167 and BD-169b → BD-169 (TOKENLESS).** How does a Resolved sub-entry render as a section inside a Resolved parent WITHOUT reintroducing the suffix token? | Append a trailing **tokenless** `## Sub-entry b — <former title>` H2 section to the parent body (the `b` denotes the former suffix sub-part per the rule "a sub-part is a section"; it carries NO `BD-167b`/`BD-169b` token), carrying the sub-entry's Type/Status/Resolved/File-Symbol/Description verbatim-preserved as prose under the H2 with any self-referential `BD-167b`/`BD-169b` token SCRUBBED (parent-referencing `Blockers: BD-167`/`BD-169` tokens stay). The parent's own `Status:`/`Resolved:` fields are UNCHANGED (both parents already Resolved). See §2.2 for the exact shape. | A fold changes landed, Resolved content — the user should see the exact rendered shape before it lands. The tokenless form keeps the §6.2 grep-zero gate clean with NO allowlist exception (user-decided 2026-06-06). |
| **DP-3** | **Trinity propagation of the no-letter-suffix rule — now or pending?** The rule lives ONLY in the `feedback_no_bd_letter_suffix` memory; the memory marks trinity propagation "Pending." | **Propagate NOW, in BD-211.** BD-211 is the canonicalization event; the engine/validator are about to FORBID suffixes, so the trinity § "BD-NNN numbering" should carry the prohibition in lockstep (one bullet, ×3 CLIs). Retire the grandfather clause in the same memory edit (moot post-fold). See §5 for the exact bullet. | A trinity rule change is an architect-first + explicit-user-approval path per pack memory; the user must approve the exact bullet text and the now-vs-pending call. |
| **DP-4** | **Commit-scoping / keyword split.** BD-211 is cross-surface (shared engine serves the `TD-` project stream). | Three commits (§6): C1 pack-side data fix = `pack-only`; C2 cross-surface engine + validator + `_rules` + tests = NO keyword (neutral "cross-surface" framing); C3 rule/memory + trinity = `pack-chat-only` (trinity + memory are pack-chat-only) — but see §6 for the merge-vs-split nuance. | A mis-applied `pack-only` keyword on the engine commit is a Check-36 failure; the user approves the commit sequence. |
| **DP-5** | **Historical maintenance-docs (40 files) advisory — extend Check 48, or do nothing?** | **Do NOTHING net-new for BD-211.** The 40 historical files are accurate-history and ALREADY untouched by Check 48 (it scans only `backlog/` + `changelog/`, never `maintenance-docs/`). No advisory is required by BD-211's acceptance criteria; adding a `maintenance-docs/`-wide suffix-WARN is scope the BD does not ask for and the user has not requested. Leave the historical set exactly as accurate-history. | The research flagged Check 48 as a *precedent*, not a requirement; whether to widen it is a user call. Recommendation is the do-nothing (smaller) path. |

There is no HARD-tier architect challenge: the design is a strict SIMPLIFICATION
(removing admission), it AGREES with the already-canonical project template, and
the measure-then-bound proof (§4.3) is clean. The only genuine choices are the
five DPs above; all other mechanics are resolved inline below.

---

## 2. Area 1 — Data fix (3 entries, pack-side)

### 2.1 BD-195 parenthetical normalization (DP-1)

**Current (line 2):**
`**BD-195 (Code Red 3) — v11.0 pristine-state recovery before BD-185 restart (full-repo)**`

**Normalized (recommended, DP-1):**
`**BD-195 — v11.0 pristine-state recovery before BD-185 restart (full-repo) (Code Red 3)**`

The `(Code Red 3)` qualifier moves to the end of the title, inside the bold span,
AFTER the existing `(full-repo)`. The filename stays `BD-195.md`. The `Alias:`
line (line 6: `Alias: "Code Red 3" and "BD-195" refer to the same item`) stays
UNCHANGED — it is already-canonical body prose and is the durable equivalence
record. No other line in BD-195.md changes.

**Why end-of-title, not drop-entirely:** the parenthetical is a meaningful alias
the entry uses internally; preserving it as title text honors fail-loud
(principle: reconcile-the-element-in-place for an active/Resolved doc, do not
destroy content) while satisfying canonical grammar (nothing between ID and
em-dash). DP-1 offers the user the drop-entirely alternative.

### 2.2 Fold structure (DP-2) — Resolved sub-entry → in-body section (TOKENLESS)

Both parents (BD-167, BD-169) and both sub-entries (the former suffix
sub-entries) are **Resolved** (§4.1 evidence). Folding is a state-preserving
merge. The fold APPENDS one **tokenless** H2 section to the END of the parent
body, preserving the sub-entry's fields as prose — with NO `BD-167b`/`BD-169b`
token anywhere in the result (SCRUB-THE-TOKEN: no allowlist exception, no
Check-34 special-case). Shape (BD-167 example):

```
## Sub-entry b — Per-entry split PM-only edits (trinity Key files + …)
Folded from a former standalone sub-entry per BD-211 (no-letter-suffix
canonicalization; a sub-part is a section, not a suffixed entry).
Type: TODO(version) — surfaced 2026-05-13 …
Status: Resolved
Blockers: BD-167
Resolved: 2026-05-16 — PM-only edits landed in commit 8ba0164 …
File/Symbol (PM-only — Pack Chat applies; …):
  - <verbatim file/symbol bullets, with any self-referential former-ID token scrubbed>
Description: <verbatim description, with any self-referential former-ID token scrubbed>
```

Two verbatim fields carry a self-referential former-ID token that MUST be
scrubbed during the fold (measured §2.2.1): the BD-167b `File/Symbol` bullet
ending `… NOT in BD-167b)` → `… NOT in this sub-entry)`; the BD-169b
`Description` ending `… §6.1 BD-169b sample text.` → `… §6.1 sample text.`. No
other verbatim field carries a `BD-167b`/`BD-169b` token (the `Blockers: BD-167`/
`BD-169` parent tokens are legitimate and stay).

Rules for the fold:
- The H2 label is **tokenless**: `## Sub-entry b — <former title>`. The trailing
  `b` denotes the former suffix sub-part (per the rule "a sub-part is a section")
  and carries NO `BD-167b`/`BD-169b` token. It is NOT a line-2 bold header, so the
  canonical-header guard (§4) does NOT scan it. Human/history continuity is served
  by the `b` label + the provenance line WITHOUT a suffix token.
- All sub-entry fields are preserved verbatim (Type/Status/Blockers/Unblocks/
  File-Symbol/Description/Resolved) under the H2 EXCEPT any self-referential
  `BD-167b`/`BD-169b` token, which is scrubbed (above) — no LIVE content loss
  (safe-before-delete: the parent must contain every live field before the suffix
  file is deleted). The dropped line-1 back-pointer and the suffix line-2 header
  carry no LIVE field content (the title survives in the H2 label).
- Parent line-2 header, Type, Status, Resolved are UNCHANGED.
- After appending, DELETE `backlog/BD-167b.md` and `backlog/BD-169b.md`
  (fail-loud: delete the old source, do not keep a stub or mirror).

#### 2.2.1 Empirical-Evidence Block — the tokenless fold is grep-zero; allowlist UNCHANGED

State-claim: after the tokenless fold, no `BD-167b`/`BD-169b` token remains in
either parent, so the §6.2 grep-zero gate stays clean with the §6.3 allowlist
UNCHANGED (only the 40 historical files + `BD-211.md`; NO fold-target exception).

```
# Self-referential suffix tokens in the sub-entry bodies (the scrub targets):
$ grep -n 'BD-167b\|BD-169b' backlog/BD-167b.md backlog/BD-169b.md
backlog/BD-169b.md:1:<!-- per-entry source: /backlog/BD-169b.md; … -->   (line-1 back-pointer — DROPPED on fold)
backlog/BD-169b.md:2:**BD-169b — …**                                       (line-2 header — becomes tokenless H2)
backlog/BD-169b.md:10:Description: … §6.1 BD-169b sample text.              (prose token — SCRUBBED)
backlog/BD-167b.md:1:<!-- per-entry source: /backlog/BD-167b.md; … -->   (line-1 back-pointer — DROPPED on fold)
backlog/BD-167b.md:2:**BD-167b — …**                                       (line-2 header — becomes tokenless H2)
backlog/BD-167b.md:14:  - (… ; NOT in BD-167b)                              (prose token — SCRUBBED)

# Parent-referencing Blockers tokens (legitimate; STAY):
$ grep -n 'Blockers:' backlog/BD-167b.md backlog/BD-169b.md
backlog/BD-167b.md:5:Blockers: BD-167
backlog/BD-169b.md:5:Blockers: BD-169

# Simulated post-fold parent bodies (back-pointer dropped, header→tokenless H2,
# prose tokens scrubbed, §2.3 repoint applied): token count via python3 re.findall
# over the BD-167 fold block, the BD-169 fold block, and the BD-169 repoint line:
BD-167 fold:    BD-167b/BD-169b tokens = 0   []
BD-169 fold:    BD-167b/BD-169b tokens = 0   []
BD-169 repoint: BD-167b/BD-169b tokens = 0   []
```
HEAD `7bdb33f`. Interpretation: (1) every `BD-167b`/`BD-169b` occurrence in the
two source files is either a dropped back-pointer, the header (→ tokenless H2),
or a prose token slated for scrub — so the projected post-fold parents contain
ZERO suffix tokens; `grep 'BD-167b\|BD-169b' backlog/BD-167.md backlog/BD-169.md`
is EMPTY. (2) No in-body former-ID token remains to dangle under Check 34. The
§6.3 allowlist is therefore NOT widened — no fold-target exception is added;
the only legitimate survivors stay exactly {40 historical maintenance-docs files,
`backlog/BD-211.md`}. **SUPPORTED.**

### 2.3 BD-169 active cross-ref repoint

`backlog/BD-169.md:14` (Description) reads `… those land in BD-169b).`. Post-fold,
`BD-169b` is no longer a separate entry, so the token would dangle (Check 34).
Repoint to the same-entry section with TOKENLESS prose: change `BD-169b` →
`the sub-entry b section below` (NO `BD-167b`/`BD-169b` token, no `BD-NNN` token,
so Check 34 sees no reference and the grep-zero gate stays clean).
`backlog/BD-167.md` body has NO `BD-167b` token (grep-clean per §4.1), so no
repoint there.

### 2.4 _toc.md regeneration

After the fold + delete + normalize, regenerate `backlog/_toc.md` via
`per_entry_regenerate_toc pack-backlog backlog`. The two rows for `BD-167b`/
`BD-169b` (lines 197, 200 today) disappear; BD-195's row title updates to the
normalized title. The TOC is a generated artifact — never hand-edited.

### 2.5 Empirical-Evidence Block — the data set is exactly 3, all pack

```
$ for f in backlog/BD-*.md; do hdr=$(sed -n '2p' "$f");
    printf '%s\n' "$hdr" | grep -qE '^\*\*BD-[0-9]{3} [—-] .+\*\*$' \
    || printf '%s :: %s\n' "$f" "$hdr"; done
backlog/BD-167b.md :: **BD-167b — Per-entry split PM-only edits (…)**
backlog/BD-169b.md :: **BD-169b — Per-entry split PM-only wording updates (…)**
backlog/BD-195.md  :: **BD-195 (Code Red 3) — v11.0 pristine-state recovery …**
$ grep -rEon '\bBD-[0-9]{3}[a-z]{2,}\b' backlog/ scripts/     → (no output)
```
HEAD `7bdb33f`. Interpretation: exactly 3 non-canonical headers; no multi-letter
suffix anywhere. Parent/sub-entry statuses all `Resolved` (BD-167.md:4,
BD-167b.md:4, BD-169.md:4, BD-169b.md:4). BD-167.md body grep-clean of `BD-167b`;
BD-169.md:14 carries one `BD-169b` token (the repoint target). **SUPPORTED.**

---

## 3. Area 2 — Engine grammar simplification (cross-surface)

Each site drops the suffix admission (`[a-z]*`) and, where present, the
parenthetical group `(?:\s*\([^)]*\))?`. Each change is property-fit to the site's
stream/role (NOT a blind find-replace) per the pattern-matching anti-pattern rule.

### 3.1 `scripts/lib/per-entry/_lib.sh:88` — pack-backlog filename regex
`'^BD-[0-9]+[a-z]*\.md$'` → `'^BD-[0-9]+\.md$'`. Update the L86–87 comment
("BD-203 A4: admit the suffix form …") → state the canonical form + cite BD-211.
The `TD-` filename regex (L108) is ALREADY `^TD-[0-9]+\.md$` — KEEP (already
canonical; agrees with project template).

### 3.2 `scripts/lib/per-entry/decompose.sh`
- **L127** pack-backlog anchor `r"^\*\*(BD-\d+[a-z]*)(?:\s*\([^)]*\))?\s+— "` →
  `r"^\*\*(BD-\d+)\s+— "`. `id_extract` returns the captured `BD-\d+` group.
- **L152** project-backlog anchor `r"^\*\*(TD-\d+[a-z]*)(?:\s*\([^)]*\))?\s+— "` →
  `r"^\*\*(TD-\d+)\s+— "`. **CROSS-SURFACE** (serves the project stream).
- Update L118–126 + L149–151 comments → canonical grammar, cite BD-211.

Property-fit note: dropping the parenthetical group is SAFE for decompose because
decompose is the one-time monolith→tree CONVERSION verb; the only header that ever
carried a pre-em-dash parenthetical (BD-195) is normalized in Area 1 BEFORE any
re-decompose, and no project monolith carries one (§4.1: project data canonical).

### 3.3 `scripts/lib/per-entry/toc-regenerate.sh`
- **L85** `re.compile(r"^BD-\d+[a-z]*\.md$")` → `re.compile(r"^BD-\d+\.md$")`
  (must mirror `_lib.sh`).
- **L128** title regex `r"^\*\*[A-Z]+-\d+[a-z]*(?:\s*\([^)]*\))? — (.+?)\*\*"` →
  `r"^\*\*[A-Z]+-\d+ — (.+?)\*\*"`. Prefix-agnostic `[A-Z]+` serves BD AND TD —
  **CROSS-SURFACE**.
- **L246** sort regex `r"^[A-Z]+-(\d+)[a-z]*$"` → `r"^[A-Z]+-(\d+)$"`.
  **CROSS-SURFACE**.
- Update L84 + L122–126 + L242–245 comments → canonical, cite BD-211.

### 3.4 `scripts/validate-pack.py`
- **L311** STREAMS pack-backlog `r"^BD-\d+[a-z]*\.md$"` → `r"^BD-\d+\.md$"`.
- **L3438** CROSS_REF_RE `r"BD-\d+[a-z]*"` → `r"BD-\d+"`.
- **L3439** CROSS_REF_RE `r"TD-\d+[a-z]*"` → `r"TD-\d+"`. **CROSS-SURFACE**.
- **`_collect_defined_ids` (L3510)** takes `entry_regex` as a parameter — it does
  NOT hard-code `[a-z]*`; it consumes the STREAMS regex (L311), so simplifying
  L311 simplifies it automatically. NO separate edit needed (the research flagged
  it for lockstep; the lockstep is achieved via the STREAMS parameter). VERIFY in
  the coder PREFLIGHT that no other hard-coded `BD-\d+[a-z]*\.md$` exists in
  validate-pack.py (§4.3 grep-zero gate covers this).
- Update L309 + L3430–3435 comments → canonical, cite BD-211.

### 3.5 Consumer libs (previously-uncatalogued; enumerate-encoding-surfaces)
- **`scripts/lib/recommendation.sh:148`** `grep -qE '^BD-[0-9]+[a-z]*\.md$'` →
  `grep -qE '^BD-[0-9]+\.md$'`.
- **`scripts/lib/detect.sh:59`** `grep -qE '^BD-[0-9]+[a-z]*\.md$'` →
  `grep -qE '^BD-[0-9]+\.md$'`.

### 3.6 Out of grammar-simplification scope (unaffected, verify only)
- `changelog/_rules.md` + pack-changelog regexes — version-shaped (`^v\d+\.md$`),
  no suffix admission. KEEP.
- project-implementation-plan / project-changelog anchors — date/phase-shaped, no
  suffix. KEEP.

### 3.7 Empirical-Evidence Block — the 14 grammar sites
```
$ grep -rEn '\[a-z\]\*' scripts/lib/per-entry/ scripts/validate-pack.py \
    scripts/lib/recommendation.sh scripts/lib/detect.sh
_lib.sh:88; decompose.sh:123(comment),127,152; toc-regenerate.sh:85,128,
244(comment),246; recommendation.sh:148; detect.sh:59;
validate-pack.py:3438,3439   (L311 carries `\d+[a-z]*` in the STREAMS tuple,
counted below)
```
HEAD `7bdb33f`. Interpretation: the active-code `[a-z]*` BD/TD-id sites are
exactly the set the research enumerated — `_lib.sh` (1 regex + 1 comment),
`decompose.sh` (2 regex + comments), `toc-regenerate.sh` (3 regex + comments),
`validate-pack.py` (STREAMS L311 + 2 CROSS_REF tokens), `recommendation.sh` (1),
`detect.sh` (1) = 14 regex/constant occurrences across 6 files;
`_collect_defined_ids` consumes the STREAMS regex (no separate hard-coded copy).
**SUPPORTED.**

---

## 4. Area 3 — Validator enforcement (net-new header-grammar guard)

### 4.1 Finding: no header-grammar guard exists today
Check 32′ (`check_mirror_in_sync`, validate-pack.py:3189) asserts FILENAME
conformance via `_list_unknown_files` (L3162) against the STREAMS regex — it
NEVER reads the line-2 `**…**` header. Check 33 (TOC-in-sync) and Check 34
(cross-ref) do not assert header canonicality. The guard is net-new.

### 4.2 Design — extend Check 32′ to assert line-2 header canonicality
Place the guard INSIDE Check 32′ (filename → filename + header), not as a new
numbered check. Rationale (design-elegance, fewer special cases): Check 32′
already iterates the pack streams and already owns "tree-integrity invariant";
header canonicality is the same invariant family (the FILENAME is the ID, the
HEADER must match the ID-grammar). One check, one iteration, one failure surface.

For each pack stream with an `[A-Z]+-\d+`-shaped entry regex (pack-backlog only;
pack-changelog is version-shaped → SKIP the header assertion for it), after the
existing filename-conformance loop, for each entry file read line 2 and assert it
matches the canonical header regex:

```
_CANON_HEADER_RE = re.compile(r"^\*\*(?:BD|TD)-\d+ — .+\*\*$")
```

FAIL with a file-path + verbatim-header callout naming the non-canonical feature
(suffix or pre-em-dash parenthetical) when line 2 does not match. The guard reads
line 2 as the bold header BELOW the line-1 `<!-- per-entry source: … -->`
back-pointer (consistent with the research's scan + `toc-regenerate.sh`'s line-1
skip). Stream-scoped to ID-shaped streams so the version-shaped changelog stream
is never mis-asserted (property-fit, not blind).

Enumerate-encoding-surfaces note: the guard's stream-applicability (ID-shaped vs
version-shaped) must be derived from the same STREAMS data the filename loop uses
— do NOT hard-code "pack-backlog" in two places.

### 4.3 Measure-then-bound proof (sized to fail EXACTLY the non-canonical set)
```
$ python3 — (accept = ^\*\*(?:BD|TD)-\d+ — .+\*\*$) against the PROJECTED
  post-fix tree (BD-167b/BD-169b deleted; BD-195 normalized per §2.1):
post-fix entries scanned: 211
non-canonical post-fix: 0
Guard REJECTS current non-canonical forms:
  REJECT :: **BD-167b — x**
  REJECT :: **BD-169b — x**
  REJECT :: **BD-195 (Code Red 3) — x**
```
HEAD `7bdb33f`. Interpretation: against the projected post-fix tree the guard
passes ALL 211 canonical entries (0 false positives) and rejects all 3 current
non-canonical forms (0 false negatives). The guard is sized EXACTLY to the
non-canonical set — it neither over-admits (no widened allowlist) nor
under-admits. The 5 fixture TD headers (TD-001..005) are already canonical
(§4.4) so the guard passes them too. **SUPPORTED.**

### 4.4 Negative-test seed
The existing C7 test (`test-validate-pack-checks-32-33-34.sh:592–603`, "dangling
suffix ref BD-999z → FAIL") is the cross-ref-side negative-test precedent. The
NEW header-guard negative test is modeled on C7's shape but targets Check 32′:
seed a scratch pack-backlog tree with one entry whose line-2 header is
`**BD-500b — Suffix header**` and one whose header is `**BD-501 (Qualifier) —
Parenthetical header**`, assert `check_mirror_in_sync` returns rc=1 and the
output names both offending files. Add a positive control (a canonical
`**BD-502 — Clean header**` passes). The existing A5/A6 (filename conformance)
and C6/C7 (cross-ref) assertions are RE-PINNED to canonical (no suffix fixture).

### 4.5 Empirical-Evidence Block — project DATA already canonical
```
$ for f in test-fixtures/v11-realistic-ot/docs/project/backlog/TD-*.md; do
    sed -n '2p' "$f"; done
**TD-001 — Onboarding flow review**  …  **TD-005 — Test coverage for offline mode**
$ grep -rn '\[a-z\]\*\|167b\|169b' test-fixtures/*/docs/project/*/   → (none)
```
HEAD `7bdb33f`. Interpretation: all 5 fixture TD headers canonical; no suffix in
any fixture `_rules.md` (9 copies) or fixture TD entry. The guard passes them
unchanged. **SUPPORTED.**

---

## 5. Area 4 + Area 5 — Reference disposition + rule/memory

### 5.1 Active references (13 files / 53 lines) — UPDATE
| File | Disposition |
|---|---|
| `backlog/BD-167b.md`, `backlog/BD-169b.md` | DELETE (folded — §2.2) |
| `backlog/BD-169.md:14` | REPOINT the `BD-169b` token to same-entry-section prose (§2.3) |
| `backlog/_toc.md` | REGENERATE (§2.4) |
| `backlog/_rules.md` | SIMPLIFY grammar prose (§5.2) |
| `backlog/BD-211.md` | KEEP (the BD describing the fix; self-referential — the `BD-167b`/`BD-169b` tokens here name the targets, legitimate) |
| `scripts/lib/per-entry/{_lib,decompose,toc-regenerate}.sh`, `scripts/validate-pack.py`, `scripts/lib/recommendation.sh`, `scripts/lib/detect.sh` | SIMPLIFY (§3) |
| `scripts/tests/test-validate-pack-checks-32-33-34.sh` | RE-PIN A5/A6/C6/C7 to canonical + ADD header-guard negative test (§4.4) |
| `scripts/tests/test-per-entry.sh:223` | RE-PIN the 1.6 assertion to `^BD-[0-9]+\.md$` |
| `scripts/tests/pack-help-test.sh:43-45`, `recommendation-test.sh:52-54` | RENAME the `BD-167b.md` fixture to a canonical id (e.g. `BD-900.md`) |
| `scripts/tests/tracker-migrate-{reverse,roundtrip}-test.sh` (comments) | SYNC the comment regex to canonical |

### 5.2 `backlog/_rules.md` grammar simplification
- **Filename convention (L30–33):** `^BD-\d+[a-z]*\.md$` + "OPTIONAL lowercase
  suffix-letter run … `BD-167b.md`/`BD-169b.md`" → `^BD-\d+\.md$` + "Three-or-more
  -digit BD-NNN; NO letter suffix (canonical per BD-211 — a sub-part is an in-body
  section, not a suffixed entry)."
- **ID-extraction (L35–43):** remove the suffix example (`**BD-167b — …**`) AND
  the parenthetical-admission sentence (`**BD-195 (Code Red 3) — …**` is "admitted").
  Keep the "filename IS the ID" core; restate canonical: a parenthetical qualifier,
  if present, is TITLE TEXT after the em-dash, never between the ID and the em-dash.
- **Entry contract (L49):** `**BD-NNN[suffix] — <Title>**` → `**BD-NNN — <Title>**`.
- The project-template `_rules.md` is ALREADY canonical (§4.5 / §5.5) — NO edit;
  this brings the PACK `_rules.md` into agreement with it.

### 5.3 Memory: `feedback_no_bd_letter_suffix.md` — retire grandfathering
The grandfather clause ("Existing suffix entries (BD-167b, BD-169b) are
GRANDFATHERED one-offs") becomes MOOT post-fold (no suffix entries remain).
Edit the memory (rides the same commit as the behavior change per the
memory-maintenance contract):
- Frontmatter `description:` + body: replace the grandfather sentence with a
  historical note: "BD-167b/BD-169b were folded into BD-167/BD-169 as in-body
  sections by BD-211 (2026-06-06); no suffix entry exists. Never create one."
- "How to apply" final bullet ("Pending: propagate … into the trinity"): if DP-3
  = propagate-now, change "Pending" → "Landed in BD-211 (see trinity § 'BD-NNN
  numbering')". If DP-3 = leave-pending, keep "Pending."

This is a Pack-Chat-direct edit (memory files are Pack Chat's own out-of-repo
operating state) — NOT a coder edit, NOT part of any in-repo commit's diff.

### 5.4 Trinity § "BD-NNN numbering" propagation (DP-3, recommend NOW)
Add one bullet to § "BD-NNN numbering" in pack-root `CLAUDE.md` (L91),
`AGENTS.md` (L93), and `GEMINI.md` (trinity-parallel), in the SAME commit:
> - **No letter suffix.** A SEPARATE BD never carries a letter suffix
>   (no `BD-210b` as a standalone entry) — assign the next INTEGER. A sub-part
>   of an existing BD lives as a SECTION inside that BD's body, never a suffixed
>   entry. (BD-167b/BD-169b were folded into their parents by BD-211.)

Trinity exemption: NONE — this is a project-rule that applies identically to all
three CLIs (no tool-specific carve-out). The trinity rule REQUIRES the parallel
edit. This is a pack-chat-only edit (trinity ops files at pack root are
pack-chat-only) — Pack Chat applies it directly OR scopes it into a coder; per
the new-entry/minor-edit rule it is a SUBSTANTIVE edit to landed trinity content
→ route to a `pack-coder` under the bounded review/fix cycle (it touches a
rule/contract).

**Do NOT touch the `19b` token** in `CLAUDE.md:58` / `AGENTS.md:60` — that is the
commit-message `(Batch Nx)` sub-number convention, UNRELATED to BD letter
suffixes (confirmed: it appears only in the `fix:`-form approved-suffixes list).

### 5.5 Historical references (40 files) + project surfaces — left as-is
- The 40 `maintenance-docs/` files (288 v11-impl + 13 archive lines) are
  accurate-history — NOT rewritten (BD-211 Out-of-scope + fail-loud's "reconcile
  active docs in place" does NOT apply: these are not active rule docs, they are
  point-in-time records that were CORRECT when written). They are ALREADY outside
  every guard's scan scope (Check 48 scans only `backlog/`+`changelog/`). NO net-new
  advisory (DP-5 recommendation). They are the documented allowlist boundary: the
  ONLY place `BD-167b`/`BD-169b` legitimately survives post-fix.
- `project-template/docs/project/backlog/_rules.md` (canonical `^TD-\d+\.md$`,
  `**TD-NNN — <Title>**`) — VERIFY-only, NO change. The simplified engine
  (§3) now AGREES with this realized surface (architect-doc-vs-reality: the
  engine's `decompose.sh` project-backlog anchor + `toc-regenerate.sh` title/sort
  regexes are reconciled to the contract declared in
  `project-template/docs/project/backlog/_rules.md`).
- `test-fixtures/v11-realistic-ot/.../TD-00{1..5}.md` + 9 fixture `_rules.md` —
  VERIFY-only (already canonical; the simplified engine still parses them).

---

## 6. Area 6 — Commit-scoping plan (honest keywords) (DP-4)

The DATA fix is pack-only; the engine/validator/_rules/test changes are
cross-surface (shared engine serves the `TD-` project stream); the trinity edit
is pack-chat-only. Three commits:

**C1 — pack-side data fix (`pack-only`).** Fold BD-167b→BD-167, BD-169b→BD-169
(append sections + delete the 2 files), repoint BD-169.md:14, normalize
BD-195.md line 2, regenerate `backlog/_toc.md`. Diff touches ONLY `backlog/` —
no `project-template/`, no `supporting-docs/`, no shared `scripts/`. `pack-only`
keyword is ACCURATE (Check 36 passes). Regenerate `test-fixtures/manifest.txt` if
its diff is non-empty (RC9; C1 touches no `scripts/`/`pack-ops/`/`supporting-docs/`
surface, but `backlog/` is not a manifest surface — likely empty diff; coder
verifies). NOTE: `backlog/_rules.md` is NOT in C1 (it is the cross-surface
contract change → C2) so C1 stays purely data.

**C2 — cross-surface engine + validator + _rules + tests (NO keyword).** Simplify
the 14 grammar sites (§3), the net-new header guard in Check 32′ (§4), the pack
`backlog/_rules.md` grammar prose (§5.2), and the 6 test files (§5.1). Diff
includes shared `scripts/lib/per-entry/*` + `scripts/validate-pack.py` + `scripts/
lib/{recommendation,detect}.sh` (which serve the `TD-` project stream) → a
`pack-only` keyword would be a Check-36 mis-claim. Use NEUTRAL framing:
`feat: v11 — BD-211 canonicalize per-entry header grammar (cross-surface engine + validator)`.
Regenerate `test-fixtures/manifest.txt` (RC9 — C2 touches `scripts/`) and stage it
in the SAME commit if its diff is non-empty.

**C3 — trinity rule propagation (`pack-chat-only`) [DP-3 = NOW].** Add the
no-letter-suffix bullet to § "BD-NNN numbering" in pack-root CLAUDE/AGENTS/GEMINI
(trinity parallel). pack-root trinity ops files are pack-chat-only, so the
`pack-chat-only` keyword is ACCURATE. Because this is a substantive rule/contract
edit to landed trinity content, it routes to a `pack-coder` (Pack Chat scopes the
3 trinity files into the coder prompt) under the bounded review/fix cycle, NOT a
Pack-Chat-direct edit. If DP-3 = leave-pending, C3 is dropped.

The `feedback_no_bd_letter_suffix.md` memory edit (§5.3) is NOT a commit — it is
Pack Chat's out-of-repo operating state, applied directly, in lockstep with C3
(or C2 if DP-3 = pending).

**Sequencing:** C1 → C2 → (C3). C1 first so the tree is canonical BEFORE the
guard lands (C2's guard would FAIL against the un-folded tree — fold-then-guard).
C2's grep-zero gate (§7) runs after C1 has removed the data and after C2 has
simplified the sites.

---

## 7. No-project-regression verification + grep-zero completeness gate

### 7.1 No project regression — the engine moves INTO agreement with the template
```
$ grep -nE 'TD-\\d\+|TD-NNN|\^TD' project-template/docs/project/backlog/_rules.md
14: Per-entry files match `^TD-\d+\.md$` …
22: `**TD-NNN — <Title>**`.
$ for f in test-fixtures/v11-realistic-ot/docs/project/backlog/TD-*.md; do sed -n '2p' "$f"; done
**TD-001 — Onboarding flow review** … **TD-005 — …**   (all canonical)
```
HEAD `7bdb33f`. Interpretation: the project template ALREADY declares the
canonical suffix-free TD grammar; the shared engine TODAY widens it
(`decompose.sh:152` `TD-\d+[a-z]*`) — a latent DISAGREEMENT. Simplifying the
engine (§3.2/§3.3/§3.4) brings it INTO agreement with the already-canonical
template; project data is unchanged and still parses (all 5 fixture TDs canonical).
The project side gets MORE consistent, not regressed. BD-211's acceptance
criterion "no project-side regression" is SUPPORTED.

### 7.2 grep-zero completeness gate (coder PREFLIGHT + reviewer)
After C1+C2, both must be EMPTY (except the documented allowlist):
```
# (a) no [a-z]* BD/TD-id grammar site remains in active code:
$ grep -rEn '[A-Z]+-\\d\+\[a-z\]\*|[A-Z]+-\[0-9\]\+\[a-z\]\*' \
    scripts/lib/per-entry/ scripts/validate-pack.py \
    scripts/lib/recommendation.sh scripts/lib/detect.sh    → (empty)
# (b) no active BD-167b/BD-169b token outside the allowlist:
$ grep -rl 'BD-167b\|BD-169b' backlog/ scripts/            → (empty)
```
**Documented allowlist (the ONLY legitimate survivors):** (1) the 40
`maintenance-docs/` accurate-history files (intentionally untouched, outside the
gate's scan dirs); (2) `backlog/BD-211.md` itself (self-describing the fix —
names the targets). Anything else is a miss.

---

## 8. Rules-Applied Verification Block

### 8.1 Per-rule (Rules in force)
| Rule | Evidence | Conclusion |
|---|---|---|
| **Empirical-Evidence Blocks (every state-claim)** | §2.5, §3.7, §4.3, §4.5, §7.1 each carry command + verbatim output + HEAD `7bdb33f` + interpretation + SUPPORTED. The guard-sizing (§4.3) ran the matching logic via `python3` against the projected post-fix tree (211 pass / 0 false-pos / 3 reject). | COMPLIANT |
| **CI-guard measure-then-bound** | §4.3: measured the candidate accept-regex against the PROJECTED post-fix tree (BD-167b/169b deleted, BD-195 normalized); sized to fail EXACTLY the 3 non-canonical forms and pass all 211 canonical entries + 5 fixture TDs; verified clean. Allowlist (§7.2) sized to KEEP only (40 historical + the self-describing BD). | COMPLIANT |
| **Pack/project separation + cross-surface care** | `_rules.md` treated as SEPARATE per-stream artifacts (§5.2 pack vs §5.5 project — project NOT edited, only verified). Engine change proven to move INTO agreement, no project regression (§7.1). Commits scoped so keywords are honest: C1 `pack-only`, C2 NO keyword, C3 `pack-chat-only` (§6). | COMPLIANT |
| **Fail-loud / delete the old source** | BD-167b/BD-169b FILES DELETED after content folded (safe-before-delete: parent carries every field, §2.2), no stub/mirror. BD-195 reconciled IN PLACE (active Resolved doc, one stale element — §2.1). 40 historical files left as accurate-history, NOT rewritten (§5.5). BD-169.md:14 dangling token repointed (§2.3). | COMPLIANT |
| **Pattern-matching anti-pattern** | Each grammar-site change is property-fit: changelog/impl-plan/project-changelog anchors UNCHANGED (version/date-shaped, no suffix — §3.6); the header guard is stream-scoped to ID-shaped streams so the version-shaped changelog stream is never mis-asserted (§4.2); `_collect_defined_ids` is parameterized so it is NOT separately hard-edited (§3.4). | COMPLIANT |
| **Architect-doc-vs-reality reconciliation** | §5.5 names the realized surface (`project-template/docs/project/backlog/_rules.md`, symbols: filename-convention + ID-extraction prose) the simplified engine reconciles to; §3.4 names `_collect_defined_ids` (symbol, no line numbers) as the parameterized consumer. | COMPLIANT |
| **Rules-Applied Verification Block + read-docs-in-full** | This §8 (per-rule + per-read-doc, evidence quoted, terminal conclusions). | COMPLIANT |
| **Agents never commit** | This doc is ONE Write to the design-doc path. No `git add/commit/push/tag/rm`; no state-changing verb run. | COMPLIANT |

### 8.2 Per-read-doc (READ IN FULL — directly)
| Document | Read evidence | Conclusion |
|---|---|---|
| `backlog/BD-211.md` | Read tool, 15 lines (full); brief constraints drive §1–§6. | COMPLIANT |
| `RESEARCH-BD-211-GRAMMAR-BLAST-RADIUS.md` | Read tool, 574 lines (full); §1–§7 BUILD ON its 14 sites / 53-ref / 3-entry / cross-surface / validator-target findings. | COMPLIANT |
| `backlog/_rules.md` (pack) | Read tool, 86 lines (full); §5.2 cites L30–43, L49. | COMPLIANT |
| `project-template/docs/project/backlog/_rules.md` | Read tool, 48 lines (full); §5.5/§7.1 cite L14/L22 canonical. | COMPLIANT |
| `scripts/lib/per-entry/_lib.sh` | Read tool, L60–119; §3.1 cites L88 (BD), L108 (TD already canonical). | COMPLIANT |
| `scripts/lib/per-entry/decompose.sh` | Read tool, L110–169; §3.2 cites L127/L152. | COMPLIANT |
| `scripts/lib/per-entry/toc-regenerate.sh` | Read tool, L78–137 + L238–257; §3.3 cites L85/L128/L246. | COMPLIANT |
| `scripts/lib/recommendation.sh` / `scripts/lib/detect.sh` | grep-verified L148 / L59 (§3.5). | COMPLIANT |
| `scripts/validate-pack.py` | Read tool, L300–354 (STREAMS), L3162–3291 (Check 32′/_list_unknown_files), L3420–3479 (CROSS_REF), L3510–3551 (_collect_defined_ids), L7200–7269 (Check 48); §3.4/§4 cite L311/L3438/L3439/L3189/L3510/L7241. | COMPLIANT |
| `backlog/BD-167.md`, `BD-167b.md`, `BD-169.md`, `BD-169b.md`, `BD-195.md` | Read tool, all 5 full; §2.1/§2.2/§2.3 quote headers, statuses, BD-169.md:14, BD-195 Alias line. | COMPLIANT |
| `ARCHITECTURE-BD-203-V3.md` (+ `-AMENDMENT.md`) | grep-read §1/§2.2 (L18/L120–132/L163–164) + AMENDMENT suffix lines (L36/L196/L221); §3 inverts the BD-203 widen-set. | COMPLIANT |
| `CLAUDE.md ## Pack memory` | Provided in full in system context; trinity § "BD-NNN numbering" Read (CLAUDE.md L91–97); §5.4 confirms `19b`@L58 is the unrelated commit-batch token. | COMPLIANT |
| `feedback_no_bd_letter_suffix.md` | Read tool, full; §5.3 quotes grandfather clause + pending-trinity bullet. | COMPLIANT |
| `feedback_ci_guard_design_measure_then_bound.md` | Read tool, full; the 5-step contract applied in §4.3/§7.2. | COMPLIANT |
| `feedback_fail_loud_delete_old_source.md` | Read tool, full; delete-vs-reconcile-in-place distinction applied (§2.1 vs §2.2, §5.5). | COMPLIANT |
| `feedback_pack_project_separation_of_concerns.md` | Read tool, full; separate `_rules.md` artifacts (§5.2 vs §5.5) — no cross-side substitution. | COMPLIANT |
| `feedback_architect_planner_empirical_evidence.md` | Read tool, full; every state-claim carries an EE block (§8.1 row 1). | COMPLIANT |

**No named document was derived rather than read.** All engine/validator/_rules/
entry files + the 5 named memories were Read directly; every count/claim was
measured live via Bash/python3 at HEAD `7bdb33f`.
