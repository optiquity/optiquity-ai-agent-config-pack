# RESEARCH — §4.2 "Separated-not-combined" MIX-enforcement feasibility spike

**Type:** READ-ONLY measurement spike (no BD; serves the
`ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` §4.2 design pass).
**Measured at:** HEAD `3bef42b` (`3bef42b6117ffa16a42b0ad5094acdaa1ff6aa42`), 2026-05-30.
**Role:** measure, do NOT design. The architect designs the check predicate after this report.

---

## VERDICT (lead)

- **SC1 — candidate set:** **12** client-installed docs co-reference both a pack-side deny-list token AND a project-side token. (Full list below.)
- **SC2 — flag load + legitimacy:** **0** of the 12 use labeled `PACK-SIDE`/`PROJECT-SIDE` blocks (markers exist in ZERO production files). Under a no-labeled-blocks heuristic, **all 12 flag**. But every sampled co-reference is **LEGITIMATELY SEPARATED** — these are boundary-TEACHING docs that name pack-side tokens precisely to forbid them and point at the project-side SSOT. **Zero conflations found.** A flag-for-review emitter would therefore be a **12/12 false-positive storm**, not a signal.
- **SC3 — fence composition:** Marker matcher `_line_is_fence_marker(line, marker)` IS parameterized, but `_build_fence_skip_lineset(text)` **hardcodes** the single `DENY-LIST-CONTENT-START/END` pair. A second `PACK-SIDE`/`PROJECT-SIDE` pair needs a **refactor** of `_build_fence_skip_lineset` to accept the marker pair (small, but not a no-op). Composes — **with refactor**, not drop-in.
- **SC4 — feasibility:** **FEASIBLE-WITH-CAVEAT.** The structural-convention half composes (after a small refactor) and is sound. The flag-for-review half, as proposed (flag any dual-reference doc lacking labeled blocks), produces a 12/12 false-positive storm on today's repo because the existing dual-reference docs are legitimately separated boundary-teaching content. The MIX is not buildable *without a false-positive storm* unless the flag predicate is narrowed below "references both + no labeled block." Architect must redesign the flag predicate.

---

## SC1 — Authoritative candidate set

**File set:** the exact set the validator walks — `_iter_client_installed_files()`
(`scripts/validate-pack.py:4116`), loaded and called directly. **161** client-installed
files total (project-template/ recursive + the explicit `_CLIENT_INSTALLED_FILES`
inventory parsed from `scripts/init-project.sh`).

**Token sets (stated explicitly — this resolves the 5-vs-8 discrepancy):**
The proposal's predicate is "no pack-side identifier (deny-list token) appears OUTSIDE
a PACK-SIDE block" — so I used the SAME Check-37 deny-list token constants the proposed
check would use, NOT the architect's prose-word grep (`pack-side|project-side` literal
words). The two measure different things:

- **PACK-SIDE tokens** = the Check-37 deny-list constants verbatim:
  `_DENY_LIST_FILENAMES` (`PACK-AGENTS.md`, `PACK-CHAT.md`, `HELP-FRAGMENT-PACK.md`),
  `_DENY_LIST_PATH_PREFIXES` (`maintenance-docs/`, `pack-ops/`),
  `_DENY_LIST_AGENT_NAMES` (the 5 `pack-*` agents), `_DENY_LIST_ROLE_NAME` (`Pack Chat`).
- **PROJECT-SIDE tokens** = literal client-install SSOT paths/phrases:
  `docs/pack/`, `docs/project/`, `project-template/`, `PM-CHAT.md`, `project-side`,
  `project repo`, `client install`, `client repo`, `client-installed`, `this project`,
  `your project`.

**Command** (Python, loading the validator's own function so the file set is byte-identical to CI):

```
python3 -c "<import validate-pack as vp>; pack_hit() over _DENY_LIST_* ;
proj_hit() over project-token list ; print docs where BOTH match"
```

**Verbatim output — 12 candidate docs:**

```
CANDIDATE DOCS (co-ref BOTH sides): 12
  project-template/AGENTS.md                              | pack:file='PACK-AGENTS.md'        proj='docs/pack/'
  project-template/CLAUDE.md                              | pack:file='PACK-AGENTS.md'        proj='docs/pack/'
  project-template/GEMINI.md                              | pack:file='PACK-AGENTS.md'        proj='docs/pack/'
  project-template/docs/pack/PACK-FEEDBACK.md             | pack:role='Pack Chat'             proj='docs/pack/'
  project-template/docs/pack/PM-CHAT.md                   | pack:prefix='pack-ops/'           proj='docs/pack/'
  project-template/docs/pack/prompts/coder.md             | pack:file='PACK-AGENTS.md'        proj='docs/pack/'
  project-template/docs/pack/prompts/reviewer.md          | pack:file='PACK-AGENTS.md'        proj='docs/pack/'
  project-template/skills/boundary-investigation/SKILL.md | pack:file='PACK-AGENTS.md'        proj='docs/pack/'
  supporting-docs/METHODOLOGY.md                          | pack:role='Pack Chat'             proj='docs/pack/'
  supporting-docs/INSTALL-PROCEDURES.md                   | pack:role='Pack Chat'             proj='docs/pack/'
  scripts/pack-help.sh                                    | pack:file='HELP-FRAGMENT-PACK.md' proj='docs/pack/'
  scripts/lib/detect.sh                                   | pack:prefix='pack-ops/'           proj='docs/pack/'
```

**5-vs-8 discrepancy resolved.** The architect's EE-4 grep was
`grep -rlE 'pack-side|project-side|<!-- *PACK|<!-- *PROJECT' supporting-docs/ project-template/docs/pack/`
— scoped to TWO directories and matching the prose WORDS, not the deny-list tokens.
Reproducing that grep verbatim returns 8 files. Reproducing the prose-word heuristic
over the FULL client-installed set returns **17** files. My deny-list-token measurement
over the full set returns **12**. The three numbers differ because they measure three
things: (a) architect's = prose-word, 2-dir scope = 8; (b) prose-word, full client set
= 17; (c) deny-list-token (what the proposed predicate uses), full client set = **12**.

**Critical scope correction for the architect:** `supporting-docs/MIGRATION-v10-to-v11.md`
appears in the architect's EE-4 grep but is **NOT in `_iter_client_installed_files()`**
(verified: `in client-installed set? False`). It is a pre-install reference, never copied
to clients, so the §4.2 check (which walks the client-installed set) would NOT see it.
The architect's "8 docs" list includes one doc the check cannot reach. Likewise
`PLATFORM-SKILLS.md` and `OPTIONAL-FEATURES.md` are prose-word matches but carry no
deny-list TOKEN co-reference, so they are not in the 12.

---

## SC2 — False-positive load + legitimacy

**Labeled-block usage today (full client set):**

```
LABELED-BLOCK docs (PACK-SIDE / PROJECT-SIDE markers): 0
```

Confirmed: ZERO production files use `<!-- PACK-SIDE -->` / `<!-- PROJECT-SIDE -->`
markers. So under the proposed "references both + no labeled blocks ⇒ FLAG" heuristic,
**all 12 candidates flag** on day one.

**Legitimacy read — are these conflations or legitimate separation?**
Sampled the co-reference contexts. Every one is **boundary-TEACHING content** — the doc
names pack-side tokens *in order to forbid them* and direct the reader to the project-side
SSOT. This is the textbook definition of "separated, clearly distinguished," not conflation.

Representative excerpts (verbatim):

- **`project-template/skills/boundary-investigation/SKILL.md`** — the entire skill
  EXISTS to teach the pack/project boundary:
  ```
  36:  mechanisms (e.g., "see `PACK-AGENTS.md` for the roster") inside a
  69:  | Agent roster + PM chat orchestration rules | `project-template/docs/pack/PM-CHAT.md` |
  180: - **Step 2:** Project-side SSOT = `docs/pack/PM-CHAT.md` §
  ```
  It names `PACK-AGENTS.md` (pack-side) explicitly to say "do not reference this; the
  project-side SSOT is `docs/pack/PM-CHAT.md`." Maximally separated.

- **`project-template/docs/pack/prompts/reviewer.md`**:
  ```
  90:  a project SSOT for the concept exists (project trinity at root, `docs/pack/PM-CHAT.md`
  104: file like `PACK-AGENTS.md`, `PACK-CHAT.md`, anything under `pack-ops/`, anything
  ```
  Same shape — lists pack-side tokens as the *deny-list* against the project-side SSOT.

- **`project-template/CLAUDE.md`** (and AGENTS/GEMINI trinity) — already wraps its
  pack-side token list in the EXISTING `DENY-LIST-CONTENT-START/END` fence, with prose
  that explicitly separates "part of the project SSOT" from "NOT part of the project
  SSOT ... the pack repo is not present at this client install." This is the separation
  the §4.2 rule wants — achieved already, via different prose + the existing fence.

- **`supporting-docs/METHODOLOGY.md`** — `Pack Chat` co-occurs with `docs/pack/` in the
  feedback-flow vocabulary (`PACK-FEEDBACK.md | Upstream feedback log to Pack Chat`); the
  pack-vs-project channel is the doc's explicit subject, not a conflation.

**Corroborating evidence — Check 37 already passes on all 12:**

```
OK: Check 37 — 158 project-side file(s) walked; zero deny-list contamination
(6 anchored LEGITIMATE-context hit(s) accepted; 584 fenced LEGITIMATE-content
line(s) exempt per Guardrail 2)
```

All 12 candidates are already accounted for by Check 37 as either fence-exempt or
anchor-phrase-legitimate. They are KNOWN-GOOD boundary content, not latent contamination.

**SC2 conclusion:** the flag-for-review half, as proposed, has a **12/12 false-positive
rate** on today's repo — every flagged doc is legitimately separated. This is a STORM, not
a signal. Zero conflations exist to catch.

---

## SC3 — Fence-machinery composition

**Code facts (verbatim, `scripts/validate-pack.py`):**

- Marker constants are module-level and single-pair (L4239-4240):
  ```
  _FENCE_MARKER_START = "<!-- DENY-LIST-CONTENT-START -->"
  _FENCE_MARKER_END = "<!-- DENY-LIST-CONTENT-END -->"
  ```
- `_line_is_fence_marker(line, marker)` (L4243) **IS parameterized** — accepts any
  `marker` string; reusable for a new vocabulary as-is.
- `_build_fence_skip_lineset(text)` (L4262) **HARDCODES** the pair — it calls
  `_line_is_fence_marker(line, _FENCE_MARKER_START)` (L4282) and
  `_line_is_fence_marker(line, _FENCE_MARKER_END)` (L4288) against the module constants.
  It takes only `text`; no marker parameter. It returns a single skip-set and treats a
  second START before an END as "nested ⇒ imbalance ⇒ return None."
- `check_project_side_deny_list` (Check 37, L4303) calls `_build_fence_skip_lineset(text)`
  for fence-allowlisted files only (`_has_per_line_fence(rel_path)`, gated by the
  hardcoded `_CHECK_37_PER_LINE_FENCE_FILES` tuple).

**Vocabulary:** the matcher is parameterized; the skip-set builder and the constants are
hardcoded to ONE pair. The proposed `PACK-SIDE`/`PROJECT-SIDE` markers are a DIFFERENT
vocabulary than `DENY-LIST-CONTENT-START/END`.

**Composition verdict — COMPOSES WITH REFACTOR (not drop-in):**
- A second marker pair cannot be added by constants alone. `_build_fence_skip_lineset`
  must be generalized to accept a `(start, end)` marker pair (or a second sibling function)
  so it can build a skip-set for the new vocabulary independently of the deny-list fence.
- The two vocabularies must remain INDEPENDENT: the existing deny-list fence semantics
  (interior lines exempt from deny-list scanning) must NOT change. Reusing the SAME
  function untouched against a different marker is impossible because the markers are
  baked into the function body — hence "refactor," not "reuse." The refactor is small
  (parameterize 2 constants into args) and low-risk, but it is a real code change with
  its own test obligations (existing `test-validate-pack-check-*.sh` for Check 37 fences).
- No CONFLICT: the marker strings differ, so the two fences cannot collide in a file; the
  nesting/imbalance logic generalizes cleanly per-vocabulary.

---

## SC4 — Feasibility verdict

**FEASIBLE-WITH-CAVEAT.**

Measured basis:
1. **Structural-convention half (preventive):** sound and composable. The fence machinery
   hosts a second marker pair after a small parameterization refactor of
   `_build_fence_skip_lineset` (SC3). "Separated by construction within labeled regions"
   is mechanically enforceable.
2. **Flag-for-review half (detection), AS PROPOSED:** NOT buildable without a
   false-positive storm. The proposed predicate ("references both a pack-side and a
   project-side token but uses no labeled blocks ⇒ flag") flags **12/12** today, and all
   12 are legitimately-separated boundary-teaching docs (SC2). Check 37 already passes on
   all of them. A flag emitter would surface 12 known-good docs and 0 conflations — pure
   noise.

**The caveat is the flag predicate.** The MIX is feasible only if the architect narrows
the detection half below "references both + no labeled block." (I do NOT design the
narrower predicate — that is architect work. The measured fact the architect needs:
"references both deny-list-token + project-token" is satisfied by legitimate
boundary-teaching content at a 12/12 rate, so co-reference presence alone is not a
conflation signal; the existing Check-37 anchor/fence machinery already distinguishes
legitimate boundary content from contamination on this exact corpus.)

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/actual) | Conclusion |
|---|---|---|
| 1. Agents never commit / no state-changing git | Only read-only git verb run: `git rev-parse HEAD` → `3bef42b6...`; `git status --short` showed only the untracked architecture doc. No add/commit/push/mv/rm/tag. | COMPLIANT |
| 2. No destructive op without approval | No file deletions, overwrites, or resets. Sole write = this report at the prompt-specified path. | COMPLIANT |
| 3. MEASURE, DO NOT DESIGN | SC1-SC3 are pure measurement; SC4 states feasibility + names "the flag predicate must narrow" WITHOUT specifying the predicate/regex/algorithm. Explicitly deferred predicate design to architect. | COMPLIANT |
| 4. Empirical-Evidence is the deliverable | Every SC carries the exact command + verbatim output + HEAD `3bef42b` + date 2026-05-30 (candidate-set listing, labeled-block count=0, Check-37 OK line, fence constants L4239-4240, function signatures). | COMPLIANT |
| 5. Rules-Applied Verification Block | This block. | COMPLIANT |
| 6. Concise / dogfood | Leads with VERDICT block (numbers first); no design restatement, no coverage-sprawl. | COMPLIANT |
| 7. Boundary awareness (P-missed-7) | Measured project-side/client-installed docs read-only via the validator's own `_iter_client_installed_files()`; imported no pack mechanism into any project-side file; changed nothing. | COMPLIANT |
| 8. Chunk long writes | Report < 300 lines; single Write. | COMPLIANT |
| Prison disposition | No file under `maintenance-docs/prison/` was read, cited, or trusted. | COMPLIANT |
