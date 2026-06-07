# ARCHITECTURE-BD-204 — Post-BD-211 reconciliation report

**Agent:** pack-architect. **Task:** reconcile ARCHITECTURE-BD-204.md (written pre-BD-211, suffix-bearing world)
to the as-built canonical, suffix-free reality BD-211 landed. **Scope:** PACK-ONLY; exactly the 5 items below; no code/plan/governance/project edits.
**Branch / HEAD (verified):** `v11-dev` / `9fb29a589cf9a121058638e8d7c98223e768eb24` (`git rev-parse HEAD`). **Date:** 2026-06-06.
**Deliverable doc edited:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md` (in place, targeted).
**Rounds:** Round 1 = the original 5-item reconciliation; Round 2 (user-approved scope extension) = the entry-level
count correction + a full count-reference sweep + the §2.4.1 date-ref. Cumulative `git diff --stat`:
`1 file changed, 94 insertions(+), 43 deletions(-)` (13 hunks). The ledger below carries Round-1 rows (L1-L16)
and Round-2 rows (R1-R6).
**Report filename uniqueness:** `find . -name "ARCHITECTURE-BD-204-POST-BD211-RECON.md" -not -path "./.git/*"` → empty (UNIQUE; no collision).

> **Evidence convention.** Each Empirical-Evidence Block carries: `CMD` (command) · `OUT` (verbatim) · `AT` (HEAD/date) · `INTERP` · `CONCL`.

---

## 0. The headline finding (item (a) — challenged, and it is a NON-issue as stated)

The task brief (drift item 4) asserts the committed C-4 migrator "carries `BD-\d+[a-z]*`" and that
"migrator and validator now disagree." **Measured against the actual committed code, that is
NOT-SUPPORTED.** There is NO `[a-z]*` suffix-permissive grammar anywhere in the tracker libs. The
migrator already agrees with BD-211's validator on the suffix-free grammar. Item (a) therefore
requires NO code change — only a doc reconciliation (done) and this surfaced correction. See
DECISIONS §A below for the full measure-then-bound evidence and the coder spec (which is: NO edit).

---

## 1. CHANGE LEDGER (every edit to ARCHITECTURE-BD-204.md — the user's overstep check)

All edits are targeted in-place; the C-1..C-6 design is byte-unchanged outside these rows (attested §4).
Quoting is trimmed to the load-bearing token where the surrounding line is long; the full verbatim diff is in §5.

| # | Section / anchor | Before (quoted) | After (quoted) | Serves item | Why |
|---|---|---|---|---|---|
| L1 | §2.4.2 EE block CMD (line ~509) | `for f in backlog/BD-195.md backlog/BD-204.md backlog/BD-167b.md backlog/BD-185.md; do …` | `… backlog/BD-167.md …` + parenthetical note "(BD-167b deleted by BD-211 … BD-167 is read in its place)" | (d) | `backlog/BD-167b.md` no longer exists; running the old CMD silently drops that leg. BD-167 carries the folded former-167b fields, so the census is preserved. |
| L2 | §2.4.2 EE block OUT (line ~514) | `… (BD-167b, suffix); … (BD-185, parenthetical). AT: HEAD e83aed7, 2026-06-06.` | `… (BD-167, incl. the folded former-167b sub-entry section — same field set, no suffix); … (BD-185). AT: HEAD 9fb29a5, 2026-06-06.` | (d) | Re-measured at current HEAD; the "suffix"/"parenthetical" fixture descriptors are stale; field set unchanged (zero-orphaned conclusion preserved). |
| L3 | §2.4.1 Rules-Applied mini-block row (line ~554) | `… across BD-195 (large) / BD-204 / BD-167b (suffix) / BD-185 (parenthetical) …` | `… across BD-195 (large + parenthetical title) / BD-204 / BD-167 (incl. the folded former-167b section; post-BD-211 suffix-free) / BD-185 …` | (d) | Drift item 3 explicitly listed :554; the row echoes the §2.4.2 stress-fixture state-claim corrected in L1/L2. |
| L4 | §2.6 status-distribution EE block (line ~592) | count regex `^BD-[0-9]+[a-z]*\.md$`; `168 Resolved`; count `212`; `28+1+11+168+3+1 = 212`; `AT: HEAD e83aed7, 2026-06-05` | (Round 1, SUPERSEDED by R2) canonical regex `^BD-[0-9]+\.md$`; count `211`; AT `9fb29a5`, 2026-06-06 | (c)(d) | **CORRECTED in Round 2 (row R4):** Round 1 set `169 Resolved` / `28+1+11+169+3+1` — internally inconsistent (sums to 213, and 169 was a `grep -h` LINE-count artifact double-counting the folded BD-167/BD-169 sub-entry `Status:` lines). The correct entry-level set is `167 Resolved` / `28+1+11+167+3+1 = 211`. |
| L5 | §2.7 lead line (line ~641) | `they are the same \`BD-\d+[a-z]*\` token.` | `they are the same \`BD-\d+\` token (canonical per BD-211 — no \`[a-z]*\` … the reverse marker reader … uses \`[A-Za-z]+-\d+(?:\.\d+)?\` … consistent with \`_CANON_HEADER_RE\`).` | (a)(b) | The shared ID token is suffix-free; names the realized consumer by symbol (architect-doc-reality-reconciliation). |
| L6 | §2.7 suffix+parenthetical sub-block (lines ~642-659) | heading "The suffix + parenthetical round-trip"; a **Suffix (`BD-167b`)** bullet describing marker carrying the full suffix ID + reverse reading `BD-\d+[a-z]*` → `BD-167b.md` | heading "The parenthetical round-trip"; the suffix bullet REPLACED by "**Suffix sub-entries: ELIMINATED (BD-211).**" describing the fold + the suffix-free engine/validator + the `[A-Za-z]+-\d+(?:\.\d+)?` reader; parenthetical bullet UNCHANGED in substance | (b) | The suffix round-trip leg is dead (no suffix entry can exist). Parenthetical leg preserved byte-for-byte in substance. |
| L7 | §2.7 stress-set EE block (lines ~654-659) | `CMD: ls … grep '^BD-[0-9]+[a-z]\.md$' ; grep -l "Code Red"`; `OUT: BD-167b.md, BD-169b.md (2). … BD-185/193/195 (3). … 2 suffix + 3 parenthetical`; `AT: e83aed7, 2026-06-05` | `CMD: ls … grep '^BD-[0-9]+[a-z]+\.md$' || echo ZERO ; for f … grep -qE '^\*\*BD-[0-9]+ — .*\(Code Red'`; `OUT: ZERO suffix; sole (Code Red ...) header is BD-195`; `AT: 9fb29a5, 2026-06-06` | (c)(d) | Re-measured suffix-free; the old "Code Red" grep matched body prose (BD-185/193 have no header parenthetical). Corrected to the genuine header-parenthetical case (BD-195). |
| L8 | §2.8 lane-filter regex (line ~680) | `\`pack-id\` marker matches \`BD-\d+[a-z]*\`` | `… matches \`BD-\d+\`` | (a-related) | The lane filter's ID grammar is suffix-free per BD-211. |
| L9 | §3.1 lossless-contract items 1-2 (lines ~763-766) | item 1 "incl. the 2 suffix entries (`BD-167b`,`BD-169b`) and the 3 parenthetical entries (`BD-185/193/195`)"; item 2 bold-header `**BD-NNN[suffix] — <Title>**` | item 1 "incl. the parenthetical-title entry (`BD-195`; post-BD-211 the tree is suffix-free)"; item 2 `**BD-NNN — <Title>**` | (c)(d) | Suffix entries gone; the 3-parenthetical census was the same body-prose mismatch as L7. |
| L10 | §3.2 count oracle (line ~784) | `count(/backlog/*.md matching ^BD-\d+[a-z]*\.md$)` … "dynamic — 212 today" | `count(… ^BD-\d+\.md$)` … "dynamic — 211 today, post-BD-211" + "count regex is the canonical suffix-free `^BD-\d+\.md$` (BD-211)" | (c) | Canonical count regex + corrected live count. |
| L11 | §3.2 identity oracle (line ~787) | "Stress set: the 2 suffix + 3 parenthetical entries appear in all three sets." | "Stress set (post-BD-211, suffix-free): the parenthetical-title entry (`BD-195`), a `Deferred` entry, and the large multi-block entry (`BD-195`) … no longer any suffix entry to stress." | (c) | Corrected oracle stress set. |
| L12 | §3.4 fixture stress-set (lines ~833-835) | "incl. a suffix entry, a parenthetical entry, a Deferred entry, and a large multi-block entry — the four stress cases" | "incl. a parenthetical-title entry, a Deferred entry, and a large multi-block entry — the three stress cases; post-BD-211 there is no suffix case" | (c)(e) | The C-7 fixture can no longer contain a suffix entry (PLAN §C-7 still says `BD-NNNb` — the planner must drop it). |
| L13 | §3.4 step-3 count (line ~859) | "the pack's OWN 212 entries" | "the pack's OWN 211 entries (post-BD-211; measured live at flip time, never hard-coded)" | (d) | Corrected count. |
| L14 | §3.4 NEW subsection (after the cleanup-contract paragraph) | (absent) | "**C-7 CI-execution model — MANUAL-ONLY, gated, with a default-SKIP guard …**" (full subsection: not in CI battery; env-var + `gh auth` SKIP guard; planner consequence) | (e) | Pins the under-specified CI-execution model (the brief's drift item 5). |
| L15 | §4.2 stream-key regex example (line ~898) | `entry regex \`^BD-\d+[a-z]*\.md$\` vs the client's \`^TD-\d+\.md$\`` | `… \`^BD-\d+\.md$\` vs the client's \`^TD-\d+\.md$\` (both canonical, suffix-free per BD-211)` | (c) | Canonical example regex. |
| L16 | §5 Rules-Applied block row "Empirical-Evidence Blocks (architect)" (line ~983) | "§2.6 (… distribution sums to 212); §2.7 (2 suffix + 3 parenthetical);" | "§2.6 (… distribution sums to 211 post-BD-211); §2.7 (suffix-free post-BD-211; parenthetical-title `BD-195`);" | (d) | Internal-consistency: this summary row directly echoes the §2.6/§2.7 state-claims corrected in L4/L6/L7 (enumerate-encoding-surfaces — the summary must not contradict its source sections). Only the two echoing phrases changed; the rest of §5 is byte-unchanged. |

**Hunk count (cumulative, both rounds):** 13 `@@` hunks. `git diff --stat`: `1 file changed, 94 insertions(+), 43 deletions(-)`.

### 1.1 Round-2 ledger rows (count-reference sweep + date-ref — user-approved scope extension)

| # | Section / anchor | Before (quoted) | After (quoted) | Why |
|---|---|---|---|---|
| R1 | §2.6 status matrix `Resolved` row (line ~146) | `| \`Resolved\` | 168 | closed | …` | `| \`Resolved\` | 167 | closed | …` | Entry-level Resolved is 167 (168 double-counted the 2 folded sub-entry `Status:` lines). |
| R2 | DP-3 RESOLVED block (line ~180) | "distribution sums to 212 (`28+1+11+168+3+1`)" | "distribution sums to 211 (`28+1+11+167+3+1`)" | Self-consistent set; was out-of-fence in Round 1, now in approved scope. |
| R3 | DP-4 (lines ~197, ~203) | "At 212 entries this is sub-second" / "sub-second at 212 entries" | "At 211 entries …" / "sub-second at 211 entries" | Live count is 211; was out-of-fence in Round 1, now in scope. |
| R4 | §2.6 status-distribution EE block (lines ~592-600) | (Round-1 L4 text) `169 Resolved`; `28+1+11+169+3+1 = 211`; CMD `grep -cE '^BD-[0-9]+\\.md$'` | `167 Resolved`; `28+1+11+167+3+1 = 211`; CMD `for f in backlog/BD-[0-9]*.md; do awk '/^Status:/{print; exit}' "$f"; done \| sort \| uniq -c` (ENTRY-LEVEL, with the double-Status-artifact note) | Corrects the inconsistent Round-1 L4 to the entry-level measurement; the CMD now reads the first `^Status:` per file so it cannot double-count the folds. |
| R5 | §3.2 Status oracle (line ~813) | "the status distribution BEFORE (`168 Resolved, 28 Open, …`)" | "… BEFORE (`167 Resolved, 28 Open, …`)" | Consistent Resolved count. |
| R6 | §2.4.1 Rules-Applied mini-block row (line ~555) | "All at HEAD `e83aed7`, 2026-06-06, verbatim, SUPPORTED." | "All at HEAD `9fb29a5`, 2026-06-06, verbatim, SUPPORTED." | This row cites the §2.4.2 EE block re-measured to `9fb29a5` (ledger L1/L2); date now matches its source. NO other `e83aed7` ref changed (the rest are accurate history for un-re-measured blocks). |

**§5 row (line ~985) already said "distribution sums to 211 post-BD-211" (Round-1 L16) — verified consistent with 167 Resolved; no Resolved-count integer appears in that phrase, so no R-row edit was needed there.**

### 1.2 Empirical-Evidence Block — the entry-level distribution (the R4 measurement)

> **Empirical-Evidence Block (entry-level status distribution = 167 Resolved, total 211; line-count double-counts the 2 folds).**
> `CMD`: `for f in backlog/BD-[0-9]*.md; do awk '/^Status:/{print; exit}' "$f"; done | sort | uniq -c` ; AND the double-Status proof `for f in backlog/BD-[0-9]*.md; do n=$(grep -c '^Status:' "$f"); [ "$n" -gt 1 ] && echo "$f: $n"; done`
> `OUT` (entry-level, first `^Status:` per file): `1 Cancelled · 11 Deferred · 3 Deprecated · 28 Open · 167 Resolved · 1 Unblocked`. Double-Status files: `backlog/BD-167.md: 2`, `backlog/BD-169.md: 2`.
> `AT`: HEAD `9fb29a5`, 2026-06-06. `INTERP`: the entry-level Resolved total is 167; a bare `grep -h '^Status:' | uniq -c` returns 169 because BD-167.md and BD-169.md each carry a SECOND `Status: Resolved` line inside their folded former-167b/169b sub-entry sections (BD-211). The self-consistent set is `28+1+11+167+3+1 = 211`. The Round-1 L4 figure (169 Resolved, sum 213) was the line-count artifact. `CONCL`: SUPPORTED.

---

## 2. DECISIONS

### §A — Migrator-regex disposition (item (a)): NO code change — migrator is ALREADY canonical

**Decision: KEEP the committed C-4/C-5 migrator code as-is. NO regex tightening is required, because no
suffix-permissive (`[a-z]*`) grammar exists in the tracker libs.** The migrator and the BD-211 validator
already agree on the suffix-free grammar. The coder spec is therefore: **make no edit to `scripts/lib/tracker-*.sh`.**

**Measure-then-bound (rule 5) — the complete occurrence census across the tracker libs:**

> **Empirical-Evidence Block (no `[a-z]*` suffix grammar anywhere in the tracker libs).**
> `CMD`: `grep -rn '\[a-z\]\*' scripts/lib/tracker-*.sh`
> `OUT`: (empty — no match).
> `AT`: HEAD `9fb29a5`, 2026-06-06. `INTERP`: the suffix-permissive token the brief expected (`BD-\d+[a-z]*`) is
> NOT present in any tracker lib. `CONCL`: NOT-SUPPORTED (the brief's claim 4 premise does not hold).

> **Empirical-Evidence Block (every BD/TD-id grammar site in the migrator, categorized KEEP/STRIP).**
> `CMD`: `grep -rn 'a-z' scripts/lib/tracker-migrate-forward.sh scripts/lib/tracker-migrate-reverse.sh`
> `OUT` (the only id-relevant hits):
> `tracker-migrate-forward.sh:388  FIELD_LINE = re.compile(r'^([A-Z][A-Za-z/ -]+):\s*(.*)$')`  — a FIELD-LABEL regex (`Type:`/`Status:`/…), NOT a BD-id grammar; KEEP.
> `tracker-migrate-reverse.sh:1101  m = re.search(r"<!--\s*pack-id:\s*([A-Za-z]+-\d+(?:\.\d+)?)\s*-->", b)`  — the pack-id MARKER reader: prefix `[A-Za-z]+`, digits `\d+`, optional dotted `(?:\.\d+)?` (the `phase-N.M` form). NO `[a-z]*` letter-suffix run. KEEP.
> `AT`: HEAD `9fb29a5`, 2026-06-06. `INTERP`: the marker reader admits `BD-NNN`, `TD-NNN`, `phase-N`, `phase-N.M` — and NO letter-suffix. It is already suffix-free; it neither over-admits a suffix nor disagrees with `_CANON_HEADER_RE`. `CONCL`: SUPPORTED (KEEP both; zero STRIP sites).

> **Empirical-Evidence Block (the forward header parser is suffix-free AND parenthetical-free).**
> `CMD`: `grep -n 'ENTRY_HEADER' scripts/lib/tracker-migrate-forward.sh`
> `OUT`: `387:ENTRY_HEADER = re.compile(r'^\*\*((?:BD|TD)-\d{3})\s*[—-]\s*(.+?)\*\*\s*$')`.
> `AT`: HEAD `9fb29a5`, 2026-06-06. `INTERP`: the forward parser captures `(?:BD|TD)-\d{3}` (no `[a-z]*` run) and
> `\s*[—-]\s*` (a hyphen-or-em-dash separator, NO pre-em-dash parenthetical capture group). It is actually
> NARROWER than `_CANON_HEADER_RE` (`\d{3}` vs `\d+`), but it never ADMITS a suffix or a pre-em-dash parenthetical.
> `CONCL`: SUPPORTED (KEEP; the forward grammar cannot emit a non-canonical id).

> **Empirical-Evidence Block (the C-4 pack-tree emitter derives its filter from the shared canonical regex).**
> `CMD`: `grep -n 'pe_entry_regex_for_stream' scripts/lib/tracker-migrate-reverse.sh` ; `grep -n "entry-regex) printf '\^BD" scripts/lib/per-entry/_lib.sh`
> `OUT`: reverse `~:799 pack_entry_regex=$(pe_entry_regex_for_stream "pack-backlog")` (used to filter the emit set at `~:811 grep -E -q "$pack_entry_regex"`); `_lib.sh:90  entry-regex) printf '^BD-[0-9]+\.md$'`.
> `AT`: HEAD `9fb29a5`, 2026-06-06. `INTERP`: `_tmr_emit_pack_tree` does NOT hard-code any id regex — it consumes the
> single shared `pe_entry_regex_for_stream "pack-backlog"`, which BD-211 already simplified to canonical
> `^BD-[0-9]+\.md$`. So the migrator's emit/backup/`_toc` sets are canonical BY CONSTRUCTION (the same regex BD-211 enforces). `CONCL`: SUPPORTED.

**Property-fit reasoning (rules 9, 10).** The brief asked me to weigh "migrator-vs-validator grammar mismatch
against defensive breadth." There is no mismatch to weigh: (a) the migrator's id-bearing surfaces are either the
shared canonical regex (emit filter) or already-suffix-free hand regexes (the marker reader `[A-Za-z]+-\d+(?:\.\d+)?`,
the forward `ENTRY_HEADER` `(?:BD|TD)-\d{3}`); (b) `fail-loud-delete-old-source` (rule 10) prefers the option that
makes grammar disagreement impossible — which is the CURRENT state (no permissive `[a-z]*` exists, so nothing can
quietly admit a suffix the validator would reject). Tightening a regex that is already suffix-free would be a no-op
edit justified by "that's what the brief said," which is the pattern-matching-out-of-context anti-pattern (rule 9).
**The honest disposition is: KEEP, no edit, and surface the corrected premise.**

**Coder spec for item (a) (file + symbol; NOT line numbers):**
- `scripts/lib/tracker-migrate-reverse.sh` — the `pack-id` marker reader (the inline `python3` in the roster loop that
  does `re.search(r"<!--\s*pack-id:\s*([A-Za-z]+-\d+(?:\.\d+)?)\s*-->", …)`): **NO CHANGE.** Already suffix-free;
  the `[A-Za-z]+ … (?:\.\d+)?` form is REQUIRED to keep admitting `phase-N.M` (do not narrow it to `BD-\d+`, which
  would regress phase-epic round-trip).
- `scripts/lib/tracker-migrate-reverse.sh` — `_tmr_emit_pack_tree` (the emit-filter via `pe_entry_regex_for_stream "pack-backlog"`): **NO CHANGE.** It already consumes the BD-211-canonical shared regex.
- `scripts/lib/tracker-migrate-forward.sh` — `ENTRY_HEADER` and `tmf_compose_issue_body` (`pack-id` mint): **NO CHANGE.** Suffix-free / verbatim-mint.
- **Net coder action for item (a): none.** The reconciliation is doc-only.

### §E — C-7 live-test CI-execution model (item (e)): MANUAL-ONLY, gated, with a default-SKIP fail-safe

**Decision: the C-7 lossless oracle is NOT wired into the unattended CI `tests` job. It is a MANUAL, user-gated
test (the C-8 dress rehearsal), and it carries a default-SKIP guard so it can never run `gh repo create`
unattended.** Rationale and the exact design requirement are written into ARCHITECTURE §3.4 (ledger row L14).

**Property-fit evidence (rules 5, 9) — the existing battery is entirely mock-based; a live-repo test is categorically different:**

> **Empirical-Evidence Block (every existing tracker test mocks `gh`; none runs `gh repo create`).**
> `CMD`: `grep -rn 'gh repo create' scripts/tests/` ; `sed -n '22,24p' scripts/tests/tracker-bd129-gh-repo-test.sh`
> `OUT`: `grep 'gh repo create'` → (empty). `tracker-bd129-gh-repo-test.sh:22-24`: "All scenarios are mock-based
> (fake `gh` on PATH that records its environment). No live GitHub state is touched."
> `AT`: HEAD `9fb29a5`, 2026-06-06. `INTERP`: the unattended CI tracker battery NEVER touches live GitHub; the
> C-7 oracle (which §3.4's EE block shows REQUIRES real `gh issue create/list`) is the first and only live-repo test.
> Wiring it into the unattended battery would be the first unattended `gh repo create` — disallowed by
> `test-infra-self-provisioned` (per-step approval). `CONCL`: SUPPORTED.

> **Empirical-Evidence Block (the existing live-precondition idiom is `gh auth status` / `command -v gh`).**
> `CMD`: `grep -rn 'gh auth status\|command -v gh' scripts/tests/tracker-*.sh | head`
> `OUT`: `tracker-init-test.sh:223 … "gh auth status OK"`; `tracker-migrate-forward-test.sh:334 if [[ "$(command -v gh)" != "$FAKE_BIN/gh" ]]`; `tracker-provider-test.sh:160 which_gh="$(command -v gh)"`.
> `AT`: HEAD `9fb29a5`, 2026-06-06. `INTERP`: the suite already uses `gh auth status` + `command -v gh` as preflight
> idioms; the C-7 SKIP guard reuses the SAME idioms (env-var opt-in + `gh auth status`) — property-fit, not invented. `CONCL`: SUPPORTED.

**The guard mechanism (what the design requires; the planner writes the recipe, the coder implements):**
- The test's FIRST action: if `PACK_TRACKER_LIVE_GH` is unset/empty OR `gh auth status` is not OK → print
  `SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)` and `exit 0`.
- The test is NOT enumerated in any CI workflow or unattended `run-all` test list (the PRIMARY control;
  the SKIP guard is the fail-safe).
- C-7's per-commit "FULL CI battery" verification = the EXISTING mock-based battery + `validate-pack.py`
  (unattended, green) AND, SEPARATELY, the live oracle run MANUALLY with the env-var + per-step `gh` approval.

---

## 3. CORRECTED C-7 DESIGN FOR THE PLANNER (unambiguous inputs for the C-7 recipe rewrite)

The planner rewrites PLAN-BD-204.md §C-7 against these three corrected inputs (I did NOT edit PLAN — per the scope fence).

### 3.1 Canonical count regex
`^BD-\d+\.md$` (BD-211; no `[a-z]*` suffix admission). This is the SAME regex the shared engine
(`pe_entry_regex_for_stream "pack-backlog"` = `_lib.sh` → `^BD-[0-9]+\.md$`) and the validator's filename loop use.
The count is DYNAMIC (measured live at audit time; never hard-coded). Today's live count is **211**.

> **Empirical-Evidence Block (canonical count today).**
> `CMD`: `ls backlog/ | grep -cE '^BD-[0-9]+\.md$'` ; `ls backlog/ | grep -E '^BD-[0-9]+[a-z]+\.md$' || echo ZERO`
> `OUT`: `211` ; `ZERO`.
> `AT`: HEAD `9fb29a5`, 2026-06-06. `INTERP`: 211 canonical entries; zero suffix files. The suffix-permissive regex
> `^BD-[0-9]+[a-z]*\.md$` returns the SAME 211 (it admits a superset that is currently empty), so the canonical regex
> is the correct, tighter form. `CONCL`: SUPPORTED.

### 3.2 Canonical C-7 fixture stress set (THREE cases, suffix-free)
PLAN §C-7 currently prescribes a fixture with FOUR cases including "a suffix entry `BD-NNNb`". That case is
**impossible post-BD-211** (the validator's `_CANON_HEADER_RE` FAILS a suffix header; the engine regex rejects a
suffix filename). The corrected fixture is THREE cases:

1. **Parenthetical-title entry** — a `**BD-NNN — <title> (Qualifier)**` header (the parenthetical is admissible TITLE
   TEXT AFTER the em-dash; the live exemplar is BD-195's `(Code Red 3)`). NOT a pre-em-dash parenthetical (that FAILS the guard).
2. **`Deferred` entry** — exercises the DP-3 `Deferred` row (open + `status:deferred`); the `Deferred` count is the
   round-trip canary (the C-5 forward + C-1 reverse `Deferred` fix HARD-GATES C-7).
3. **Large multi-block entry** — `Segments:`/`Steps:`/`State:`/`Goal:`/`Scope:` blocks ride the Issue body verbatim
   (the live exemplar is BD-195, which is also the parenthetical case).

> **Empirical-Evidence Block (the three live exemplars exist; the suffix case does not).**
> `CMD`: `for f in backlog/BD-*.md; do sed -n '2p' "$f" | grep -qE '^\*\*BD-[0-9]+ — .*\(Code Red' && echo "PAREN: $f"; done` ; `grep -lE '^Status: Deferred' backlog/*.md | head -1` ; `grep -l '^Segments:' backlog/*.md`
> `OUT`: `PAREN: backlog/BD-195.md` ; `backlog/BD-031.md` (one of 11 Deferred) ; `backlog/BD-195.md` (Segments:).
> `AT`: HEAD `9fb29a5`, 2026-06-06. `INTERP`: the parenthetical-title + large-multi-block cases are realized by BD-195;
> 11 `Deferred` entries exist (BD-031 is one). No suffix entry exists to seed a suffix fixture. The C-7 fixture is THREE
> stress cases. `CONCL`: SUPPORTED.

> **Empirical-Evidence Block (the validator would REJECT a suffix or pre-em-dash-parenthetical fixture header).**
> `CMD`: `grep -n '_CANON_HEADER_RE' scripts/validate-pack.py`
> `OUT`: `3194:_CANON_HEADER_RE = re.compile(r"^\*\*(?:BD|TD)-\d+ — .+\*\*$")` (applied in Check 32′ via `_stream_is_id_shaped`,
> failing any non-canonical line-2 header). `AT`: HEAD `9fb29a5`, 2026-06-06. `INTERP`: a fixture entry with a `BD-500b`
> suffix header or a `**BD-501 (Qualifier) — …**` pre-em-dash parenthetical would FAIL the validator — so the C-7 fixture
> MUST be suffix-free and may only carry a POST-em-dash parenthetical. `CONCL`: SUPPORTED.

### 3.3 CI-execution requirement (the §E decision, restated for the recipe)
The C-7 recipe MUST:
- (a) NOT add `tracker-bd204-lossless-roundtrip-test.sh` to any CI workflow or unattended `run-all` test list;
- (b) make the test's FIRST action a default-SKIP guard: require `PACK_TRACKER_LIVE_GH=1` AND `gh auth status` OK, else
  print `SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)` and `exit 0`;
- (c) state C-7's per-commit "FULL CI battery" verification as TWO distinct runs — the unattended mock battery +
  `validate-pack.py` (green in CI), and the MANUAL live oracle (env-var + per-step `gh` approval). The PLAN §C-7 phrase
  `"FULL CI battery + the new oracle test"` resolves to: battery = unattended-CI; oracle = manual gated run.

---

## 4. C-1..C-6 UNTOUCHED ATTESTATION

**Claim:** no ARCHITECTURE-BD-204.md content outside the 5 items changed; the C-1..C-6 design (round-trip mechanics,
the GH form family, the in-body `pack-extra-fields` carrier, the no-sidecar decision DP-2, the SSOT/mirror model,
the Pack Feedback two-lane, the DP-1..DP-5 resolutions, the Deferred-status handling) is byte-unchanged except where a
state-claim it cites was invalidated by BD-211 (the 5-item stress-fixture/count echoes).

> **Empirical-Evidence Block (the cumulative diff is confined to 13 hunks — the 5 items + the Round-2-approved count-sweep targets).**
> `CMD`: `git diff --stat` ; `git diff maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md | grep -E '^@@'` ; `git status --short`
> `OUT`: `1 file changed, 94 insertions(+), 43 deletions(-)`. Hunk anchors (13): `@@ -143` (§2.6 matrix Resolved row, R1), `@@ -177` (DP-3, R2), `@@ -194` (DP-4, R3), `@@ -506` (§2.4.2 EE), `@@ -551` (§2.4.1 mini-block row, incl. R6 date), `@@ -590` (§2.6 status EE, incl. R4), `@@ -637` (§2.7 lead + suffix-leg + stress EE), `@@ -677` (§2.8 lane filter), `@@ -760` (§3.1 contract), `@@ -781` (§3.2 oracle, incl. R5 status oracle), `@@ -831` (§3.4 fixture + count + NEW C-7 model), `@@ -895` (§4.2 stream-key regex), `@@ -931` (§5 row echo).
> `git status --short`: ` M maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md` + `?? …RECON.md` (ONLY the two deliverable files).
> `AT`: HEAD `9fb29a5`, 2026-06-06. `INTERP`: every hunk maps to a Round-1 ledger row (L1-L16, the 5 items) or a Round-2 row (R1-R6, the user-approved count-sweep + date-ref); the 3 Round-2-new hunks (`@@ -143/177/194`) are the §2.6-matrix/DP-3/DP-4 count corrections the user explicitly authorized. No code/plan/governance/project file touched. `CONCL`: SUPPORTED.

**Sections verified NOT touched in SUBSTANCE (byte-unchanged except the user-approved COUNT corrections noted):**
§0 (how to read); §1 DP-0/DP-1/DP-2/DP-5 resolutions (byte-unchanged); §2.1 (SSOT/mirror); §2.2 + §2.2.C1 (monolith
retire/repoint, Check 29′); §2.3 (CRUD, delete=close-with-reason); §2.4 + §2.4.1 (carrier/sidecar-drop DESIGN
substance — only the §2.4.2 stress-fixture EE + the one mini-block row's fixture descriptors + that row's HEAD-ref
date changed, NOT the carrier decision/zero-orphaned conclusion); §2.4.3 (GH-only artifacts dropped); §2.5 (write
model); §2.6.1 (two-switch determination); §2.7 parenthetical bullet (substance unchanged); §2.9/§2.10 (capability
matrix); §2.11/§2.12 (reversibility/on-off); §3.3 (silent-data-loss guard); §3.4 steps 1-3 prose + the live-repo EE
block (only fixture-list/count + the NEW C-7 model subsection added); §4.1 (tracker-agnostic); §4.3
(dependency-direction, sidecar-drop flag); §6 (consistency-fix pass).
**Touched ONLY for the user-approved count/date sweep (no DESIGN-substance change):** §2.6 matrix `Resolved` row
(168→167, R1); DP-3 RESOLVED block (the sums-to count, R2); DP-4 (the illustrative entry-count, R3); §2.6
status-distribution EE block (R4); §3.2 status oracle (R5); §2.4.1 mini-block row HEAD-ref (R6). The DP-1/DP-2/DP-5
RESOLVED blocks, the form family, the `pack-extra-fields` carrier, the no-sidecar decision, the SSOT/mirror model,
the two-lane feedback, and the dogfood sequence are byte-unchanged; the ONLY changes to DP-3/DP-4 are the entry-count
figures (advisory/illustrative — the design uses DYNAMIC counts at runtime), not any decision.

> **Empirical-Evidence Block (the DP resolutions + carrier decision are byte-unchanged).**
> `CMD`: `git diff maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md | grep -nE '^[-+].*(RESOLVED \(user|read-only regenerated mirror|the sidecar|the form family|two-lane)'`
> `OUT`: (empty — no added/removed line touches a DP-resolution, the carrier/sidecar decision, the form-family, or the two-lane sentence).
> `AT`: HEAD `9fb29a5`, 2026-06-06. `INTERP`: none of the protected C-1..C-6 design sentences appears in the diff.
> Note: a broader grep that also matches the bare token `pack-extra-fields` returns ONE pair of lines — the ledger-L3
> §2.4.1 mini-block row, which lists the `Target/Position`→`pack-extra-fields` carrier MAPPING. That row's carrier
> mapping text is byte-identical before/after; the ONLY change in it is the stress-fixture descriptor (`BD-167b (suffix)`
> → `BD-167 (incl. the folded former-167b section; post-BD-211 suffix-free)`), which is the 5-item (d) reconciliation,
> not a carrier-decision change. `CONCL`: SUPPORTED.

---

## 5. Full verbatim diff (the user's exact-text overstep check)

The complete `git diff maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md` is reproduced in the agent
transcript that produced this report (13 hunks cumulative, +94/-43). It is intentionally not re-pasted here to keep the report
lean (`scope-deliverables-to-the-ask`); the CHANGE LEDGER (§1) quotes the load-bearing before/after of every edit, and
§4's Empirical-Evidence Blocks pin the hunk anchors and the byte-unchanged protected sentences. To re-verify, run:
`git diff maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md`.

---

## 6. STATUS OF PREVIOUSLY-SURFACED ISSUES

Round 1 surfaced three out-of-scope issues. Round 2 (user-approved scope extension) ACTIONED two of them
(the count drift + the §2.4.1 date-ref); the PLAN drift remains the planner's to fix and stays surfaced-only.

### 6.1 ACTIONED in Round 2

**(A) Count drift across the doc — FIXED (Round-2 rows R1-R5).** Round 1 left stale `212`/`168` counts in the §2.6
matrix, DP-3, DP-4, the §2.6 EE block, and the §3.2 status oracle (and the Round-1 L4 fix was itself wrong — `169`,
sum 213). All are now the self-consistent entry-level set: count `211`, Resolved `167`, `28+1+11+167+3+1 = 211`. The
DP-3/DP-4 lines were out-of-fence in Round 1 but in the Round-2 approved scope.
   > **Empirical-Evidence Block (zero stale entry/Resolved counts remain).** `CMD`: `grep -nE '\b212\b|\b168\b' maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md`
   > `OUT`: only lines `599`/`600` — both inside the §2.6 EE block's own corrective narration ("211 not 212"; "167 not 168 — 168 was a line-count artifact"). No stale count remains. (`grep '\b169\b'` → only `BD-167/BD-169` file names in the R4 CMD + the `ARCHITECTURE-V3.md:169` doc line-ref; no Resolved-count 169.)
   > `AT`: HEAD `9fb29a5`, 2026-06-06. `INTERP`: every entry/Resolved count in the doc is now 211/167; the only `212`/`168` survivors are the explanatory "not 212 / not 168" narration. `CONCL`: SUPPORTED.

**(B) §2.4.1 date-ref — FIXED (Round-2 row R6).** The §2.4.1 Rules-Applied mini-block row ("zero-orphaned-fields
claim") cited HEAD `e83aed7` while its source §2.4.2 EE block had been re-measured to `9fb29a5`; the row now reads
`9fb29a5`. ONLY that one row's date changed for R6 — the 19 OTHER `e83aed7` references that remain in the doc are
accurate history for EE blocks NOT re-measured in this work, so they are intentionally left.
   > **Empirical-Evidence Block (only the §2.4.1 zero-orphaned row's date moved to 9fb29a5; 19 e83aed7 history refs remain).**
   > `CMD`: `git diff …ARCHITECTURE-BD-204.md | grep -cE '^-.*zero-orphaned-fields claim.*e83aed7'` ; `… | grep -cE '^\+.*zero-orphaned-fields claim.*9fb29a5'` ; `grep -c 'e83aed7' …ARCHITECTURE-BD-204.md`
   > `OUT`: `1` (the §2.4.1 row's removed `e83aed7` line) ; `1` (its added `9fb29a5` line) ; `19` (untouched `e83aed7` history refs surviving in the doc).
   > `AT`: HEAD `9fb29a5`, 2026-06-06. `INTERP`: the R6 date-ref fix is surgically scoped to the single §2.4.1 row whose source block was re-measured; the cumulative diff also shows other `e83aed7` removals, but those are the Round-1 EE-block edits (§2.4.2/§2.6/§2.7) — NOT a blanket date sweep. The 19 surviving `e83aed7` refs are intentional accurate-history. `CONCL`: SUPPORTED.

### 6.2 Still surfaced-only (NOT actioned — out of scope / another owner)

**PLAN-BD-204.md §C-7 still encodes the suffix-bearing fixture + the suffix count regex (the planner's to fix).**
   PLAN §C-7 prescribes a fixture with "a suffix entry `BD-NNNb`" and uses `^BD-\d+[a-z]*\.md$` in the count oracle;
   PLAN §3.x (`:98`,`:121`) also carries the suffix regex. The scope fence forbids editing PLAN — the planner rewrites
   C-7 against this report's §3. **Disposition:** the planner consumes §3 (canonical regex, 3-case fixture, CI model)
   to rewrite C-7; I flag it so it is not missed.
   > **Empirical-Evidence Block.** `CMD`: `grep -n '\[a-z\]\*\|167b\|169b\|BD-NNNb' maintenance-docs/v11-implementation/PLAN-BD-204.md`
   > `OUT`: `98:` (`^BD-[0-9]+[a-z]*\.md$`), `121:` (`grep -cE '^BD-[0-9]+[a-z]*\.md$'`), `420:` (fixture prose "a suffix entry `BD-NNNb`"), `429:` (count oracle `^BD-\d+[a-z]*\.md$`).
   > `AT`: HEAD `9fb29a5`, 2026-06-06. `INTERP`: PLAN-BD-204.md carries the same pre-BD-211 suffix drift; it is the
   > planner's to fix (out of my scope per the fence). `CONCL`: SUPPORTED.

---

## 7. RULES-APPLIED VERIFICATION BLOCK

| # | Rule (as named in prompt) | Verification evidence (actual command / grep / path / quote) | Conclusion |
|---|---|---|---|
| 1 | **agents-never-commit** | No state-changing git verb run. `git status --short` shows only ` M ARCHITECTURE-BD-204.md` + the new report (untracked); no `git add/commit/push/tag` issued in this session. | COMPLIANT |
| 2 | **per-action-approval-sub-agents** | No `rm`/`git rm`/overwrite of a trusted file on my own authority. The only writes are targeted Edits to ARCHITECTURE-BD-204.md (in scope) + the new report file. No deletion performed. | COMPLIANT |
| 3 | **edit-in-place-not-full-rewrite** | All edits (Round-1 L1-L16 + Round-2 R1-R6) applied via `str.replace(old,new,1)` with a `count==1` guard (FAIL-if-not-1); never a full-file rewrite. Post-edit re-read of the section map (`grep -nE '^#{1,4} '`) shows §0/§1/DP-0..DP-5/§2.1..§2.12/§2.4.1/§2.6.1/§3.1..§3.4/§4.1..§4.3/§5/§6 all present (1043 lines after Round 2; was 993). | COMPLIANT |
| 4 | **empirical-evidence-blocks** | Every state-claim carries an EE block: §0 (no `[a-z]*` in tracker libs); §A (4 blocks: occurrence census, marker reader, forward parser, emit filter); §E (2 blocks: mock-based battery, gh-auth idiom); §3.1/§3.2 (count, exemplars, validator-reject); §4 (2 blocks: 13-hunk confinement, protected-sentence grep); §1.2 (entry-level distribution = 167 Resolved / 211 + the double-Status proof); §6.1 (2 blocks: zero-stale-count, scoped-date-ref) + §6.2 (1 block: PLAN drift). Each: CMD + verbatim OUT + HEAD `9fb29a5` + 2026-06-06 + INTERP + CONCL. | COMPLIANT |
| 5 | **ci-guard-measure-then-bound** | Item (a): measured the migrator FIRST (`grep '[a-z]*' tracker-*.sh` → empty; `grep 'a-z'` → 2 id-relevant hits), categorized each KEEP (zero STRIP), sized the decision to the measured set (no edit), verified the emit filter consumes the BD-211-canonical shared regex. Item (c): measured the tree (211 canonical / 0 suffix), the validator's `_CANON_HEADER_RE`, and the 3 live fixture exemplars; sized the stress set to the measured reality. Round 2: measured the ENTRY-LEVEL distribution (awk-first-`Status`-per-file → 167 Resolved / 211) and the double-Status artifact (BD-167/BD-169) BEFORE sweeping the counts; sized every count reference to the self-consistent measured set rather than the line-count artifact. | COMPLIANT |
| 6 | **architect-doc-reality-reconciliation** | Every reconciled section names the realized consumer by file + symbol, never line number: §2.7 → `tracker-migrate-reverse.sh` `pack-id` marker reader + `_CANON_HEADER_RE`; §A → `_tmr_emit_pack_tree` / `pe_entry_regex_for_stream` / `ENTRY_HEADER` / `tmf_compose_issue_body`; §E → `tracker-bd204-lossless-roundtrip-test.sh`; §3 → `validate-pack.py` `_CANON_HEADER_RE` + `_stream_is_id_shaped`. | COMPLIANT |
| 7 | **rules-applied-verification-block** | This table (per-rule, evidence quoted, terminal conclusion; no empty evidence, no AMBIGUOUS). | COMPLIANT |
| 8 | **preliminary-triage-architect-challenge** | Challenged each of the 5 items rather than rubber-stamping: item (a) CHALLENGED and found a NON-issue as stated (no `[a-z]*` in code) — surfaced with evidence rather than inventing a tightening edit; item (c) CHALLENGED the "3 parenthetical entries (BD-185/193/195)" census and found it matched body prose, not header parentheticals — corrected to the single genuine header-parenthetical case (BD-195). Round 2: the user's challenge of my OWN Round-1 L4 count (169/sum-213) was verified and accepted — I re-measured at the ENTRY level (167/211) and traced the 169 to the line-count double-count of the two folds, rather than defending the wrong figure. | COMPLIANT |
| 9 | **pattern-matching-out-of-context** | Item (a) decision justified on property-fit (the marker reader's `[A-Za-z]+-\d+(?:\.\d+)?` is REQUIRED for `phase-N.M`; narrowing it to `BD-\d+` would regress phase round-trip) — not "tighten because the brief said so." Item (e) SKIP-guard reuses the suite's existing `gh auth status`/`command -v gh` preflight idiom (property-fit), not an invented gate. | COMPLIANT |
| 10 | **fail-loud-delete-old-source** | Weighed in item (a): the option that makes grammar disagreement IMPOSSIBLE is the current state (no permissive `[a-z]*` exists for the validator to silently disagree with). A no-op "defensive breadth" permissive regex would be a fail-quiet trap; KEEP-as-suffix-free is the fail-loud-consistent choice. No old source needed deletion (BD-211 already deleted the suffix files). | COMPLIANT |
| 11 | **scope-deliverables-to-the-ask** | Round 1: delivered exactly the 5-item reconciliation + required sections; no new design surface. Round 2: delivered exactly the USER-APPROVED scope extension (entry-level count correction + count-reference sweep + §2.4.1 date-ref) — no scope creep beyond it; the PLAN drift stays surfaced-only (another owner). Out-of-scope items fenced in §6.2. | COMPLIANT |
| 12 | **boundary-investigation-precedes-pack-defaults (P-missed-7)** | PACK-ONLY honored (both rounds): `git status --short` shows zero `project-template/` or `supporting-docs/` edits; the only files written are the two `maintenance-docs/` files (pack-side). No project surface touched; no project concept imported. `validate-pack.py` PASSED after Round 2. | COMPLIANT |

### 7.1 READ-IN-FULL attestation (per-file direct-read proof, this session)

| Document | Direct-read proof |
|---|---|
| `CLAUDE.md` `## Pack memory` | Provided in full in session context; trinity rules + pack-memory bullets applied (boundary, dependency-direction, enumerate-encoding-surfaces). |
| `ARCHITECTURE-BD-204.md` | Read full (1-594 then 595-993, two pages) before editing. |
| `PLAN-BD-204.md` §C-7 + §3.x | Read directly (380-509) — C-5/C-6/C-7/C-8 + §4 verification; NOT edited (planner's). |
| `backlog/BD-204.md` | Read full (1-26). |
| `backlog/BD-211.md` | Read full (1-15). |
| `ARCHITECTURE-BD-211.md` | Read full (1-529) — the suffix-elimination design reconciled against. |
| `scripts/lib/tracker-migrate-reverse.sh` | Read directly — `_tmr_emit_pack_tree` (712-826) full + the `pack-id` marker reader (1085-1135) + grep census of the id/marker logic. |
| `scripts/lib/tracker-migrate-forward.sh` | Read directly — `ENTRY_HEADER` (387), `FIELD_LINE` (388), `tmf_compose_issue_body` pack-id mint (600-620), grep census. |
| `scripts/validate-pack.py` | Read directly — `_CANON_HEADER_RE` (3194), `_stream_is_id_shaped` (3197), the Check 32′ header-guard loop (3300-3330). |
| `backlog/_rules.md` | Read full (1-84) — canonical `^BD-\d+\.md$`, ID-extraction, lifecycle states. |
| `scripts/lib/per-entry/_lib.sh` | Read directly — `pe_entry_regex_for_stream` table (80-115); pack-backlog `entry-regex` → `^BD-[0-9]+\.md$`. |
| 10 curated memory files | All read in full this session (`feedback_architect_planner_empirical_evidence`, `feedback_ci_guard_design_measure_then_bound`, `feedback_edit_in_place_not_full_rewrite`, `feedback_scope_deliverables_to_the_ask`, `feedback_agent_output_rules_applied_block`, `feedback_preliminary_triage_architect_challenge`, `feedback_pattern_matching_out_of_context_antipattern`, `feedback_fail_loud_delete_old_source`, `feedback_no_bd_letter_suffix`, `feedback_verify_full_ci_suite`). |

**No named document was derived rather than read.** Every doc, code file, contract, and memory was opened directly via
Read/Bash this session at HEAD `9fb29a5`; every count/claim was measured live.

**End of ARCHITECTURE-BD-204-POST-BD211-RECON.md**
