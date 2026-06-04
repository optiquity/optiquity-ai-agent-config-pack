# PLAN-BD-208 — Pack Chat editing-actor rule (Pack Chat MINOR-only; coder does every MAJOR edit + everything outside the small set)

**Status:** Plan (planner). PLANNING ONLY — no source edits, no git verbs.
**HEAD at planning:** `3d7bec4076cc63f7dcb588fcf194b60e984dc04f` (date 2026-06-04).
**Design source (FIXED):** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-208.md` (user-approved 2026-06-04, Option B + ID-history closure).
**BD:** BD-208 (`pack-ops/BACKLOG.md` L3420–3439, Status: Open).
**Pipeline position:** architect (done) → planner (this doc) → user review → (coder → bounded review/fix) → Pack Chat commit.

> **Line-number drift notice.** The architect doc cites PACK-CHAT.md L13/L21 and
> trinity insert anchors at SHA `a630a312`. At planning HEAD `3d7bec4` the same
> anchor TEXT lives at slightly different line numbers (PACK-CHAT "Write files
> directly" = L14; "execute pack changes directly" = L21 within L19–21; trinity
> anchor "those go to pack-coder." = CLAUDE L383 / AGENTS L349 / GEMINI L316).
> This plan anchors every edit on byte-quoted TEXT, never line numbers (per
> `edit-in-place-not-full-rewrite`). Line numbers below are informational only.

---

## 0. Goal and BD items addressed

**Goal.** Land the new trinity `## Pack memory` editing-actor rule
(`pack-chat-minor-edits-only`) and propagate it lock-step across every governance
surface and encoding surface, in ONE atomic `pack-only` commit, leaving
`validate-pack.py` GREEN (Checks 18/45/46) and trinity parity held.

**BD addressed.** BD-208 — fully. The design's §1–§7 are realized by the tasks
below. OOS items: OOS-1 (memory-cache reconciliation) is DONE out-of-repo (not a
plan task — see §6); OOS-2 (PACK-CHAT Role-section staleness) is IN-SCOPE (Task
T6b); OOS-3 (coherence flag) is RESOLVED (user chose ID-history closure — no open
decision).

---

## (A) Task breakdown — atomic propagation edits

All edits are TARGETED in-place inserts/replacements with exact byte-quoted
anchors. The coder re-reads each file's section map after editing and reports
actual re-read evidence (per `edit-in-place-not-full-rewrite`). Actor for T1–T8:
**pack-coder, scoped in** (Pack Chat scopes the PM-only files into the coder
prompt via the existing PACK-AGENTS "off-limits UNLESS explicitly scoped in"
clause). The rule TEXT is architect-defined (design §1–§3.5); the coder applies
it MECHANICALLY and holds trinity parity. Pack Chat does only the commit.

### T1 — CLAUDE.md corpus insert (design §3.1)
- **File:** `CLAUDE.md` (pack root), `### Pack Chat scope` subsection (inside `## Pack memory` H2).
- **Anchor (byte-quoted, ends the "What Pack Chat CAN edit directly" bullet):**
  ```
    - Pack Chat may NOT edit project-template / supporting-docs /
      maintenance-docs / scripts / fixtures / agent definitions —
      those go to pack-coder.
  ```
  (live L381–383)
- **Insert point:** the line AFTER that sub-bullet and BEFORE `- **Commit-approval requests include next-steps plan.** Every` (live L384).
- **What changes:** INSERT the §1 rule bullet VERBATIM from ARCHITECTURE-BD-208.md §1 (the fenced block L98–129, ending `[roles: universal] [rationale: pack-chat-minor-edits-only]`).

### T2 — AGENTS.md corpus insert (design §3.1)
- **File:** `AGENTS.md` (pack root). **Same anchor** (`those go to pack-coder.` = live L349; following bullet L350). **Same byte-identical insert** as T1 (the rule has NO CLI-specific content; the middle sub-bullet of the "CAN edit directly" bullet differs per CLI but the insert ANCHOR + inserted text do not).

### T3 — GEMINI.md corpus insert (design §3.1)
- **File:** `GEMINI.md` (pack root). **Same anchor** (`those go to pack-coder.` = live L316; following bullet L317). **Same byte-identical insert** as T1.

> **Parity invariant (T1/T2/T3):** the inserted bullet is byte-identical across
> all three. No trinity-exemption needed (no CLI-specific content). The coder
> diffs the three inserted blocks against each other and reports byte-equality.

### T4 — PACK-MEMORY-RATIONALE.md rationale append (design §3.2)
- **File:** `pack-ops/PACK-MEMORY-RATIONALE.md`.
- **Anchor:** END of file (live L565; file is an ordered list of `## <slug>` sections — last is `## dependency-direction-placement` at L549).
- **What changes:** APPEND the new `## pack-chat-minor-edits-only` section VERBATIM from ARCHITECTURE-BD-208.md §3.2 (the fenced body L285–319: Why + How-to-apply + Rejected-alternative — the established 3-part shape).
- **Bijection note:** this section's `## pack-chat-minor-edits-only` heading is the bijection partner for the new corpus `[rationale: pack-chat-minor-edits-only]` token landed in T1. Lands in the SAME commit so Check 45 never sees a half-applied (orphan) state.

### T5 — PACK-AGENTS.md reference line (design §3.3)
- **File:** `pack-ops/PACK-AGENTS.md` § "Agent permission rules", PM-only block.
- **Anchor (byte-quoted, the existing scope-in clause, live L157–159):**
  ```
  `pack-coder` MAY scope a per-entry directory in for an explicit BD when
  Pack Chat's prompt scopes it — the same exception clause that applies to
  the PM-only files above.
  ```
- **Insert point:** immediately AFTER that clause.
- **What changes:** INSERT the §3.3 reference line VERBATIM (ARCHITECTURE-BD-208.md L354–357) — a NAME+slug paraphrase pointer, deliberately under the Check 46 60-char body-restate threshold. Do NOT restate the corpus imperative body.

### T6a — PACK-CHAT.md Behavioral-rules reference bullet (design §3.4(a))
- **File:** `pack-ops/PACK-CHAT.md` § "Behavioral rules".
- **Anchor (byte-quoted, end of the "Real fixes only" bullet, live L92–94):**
  ```
    Distinct from `feedback-fix-all-review-findings` (scope of fixes)
    and `feedback-pack-chat-does-no-fixes` (who applies fixes): this
    rule is the depth requirement on whatever fix the coder applies.
  ```
- **Insert point:** immediately AFTER that bullet (live L94).
- **What changes:** INSERT the §3.4(a) reference bullet VERBATIM (ARCHITECTURE-BD-208.md L377–385) — NAME+slug paraphrase pointing to the corpus SSOT; anti-restate-safe.

### T6b — PACK-CHAT.md Role-section in-place reconciliation (design §3.4(b); OOS-2 in-scope)
- **File:** `pack-ops/PACK-CHAT.md` § "Role".
- **Edit b1 — anchor (byte-quoted, live L14):** `- Write files directly to the repo (CLI: native file write and git)`
  REPLACE with the §3.4(b) L13-replacement text (ARCHITECTURE-BD-208.md L398–401): "Apply bookkeeping edits and NEW-entry authoring (BD-opens / version-boundary CHANGELOG) to the small PM-only set directly; route every MAJOR edit … to a pack-coder per trinity `## Pack memory` `[rationale: pack-chat-minor-edits-only]`".
- **Edit b2 — anchor (byte-quoted, live L20–21):** `You plan and execute pack changes` … `directly, with explicit approval before any commit.`
  REPLACE with the §3.4(b) L21-replacement text (ARCHITECTURE-BD-208.md L402–406): "You plan pack changes; you apply bookkeeping edits + new-entry authoring on the small PM-only set directly and route every MAJOR (landed-content / rule / out-of-set) edit to a pack-coder, with explicit approval before any commit."
- **What changes:** two minimal in-place replacements of the stale "directly at any depth" framing. Neither restates the corpus body (anti-restate-safe).

### T7 — .spawn-rule-manifest.txt record append (design §3.5)
- **File:** `pack-ops/.spawn-rule-manifest.txt`.
- **Anchor:** END of file (blank-line-separated records; last record at file tail).
- **What changes:** APPEND the §3.5 record VERBATIM (ARCHITECTURE-BD-208.md L422–425): `slug: pack-chat-minor-edits-only` / `canonical: ## Pack memory` / `corpus: ### Pack Chat scope — …` / `references: PACK-AGENTS.md § "Agent permission rules" (…); PACK-CHAT.md § "Behavioral rules" (…); PACK-CHAT.md § "Role" (…)`. Match the existing record FORMAT (verified against live records, e.g. `agents-never-commit` at L24–27).
- **Resolution invariant:** every `references:` surface named here MUST carry a resolving pointer in the live file (T5 = PACK-AGENTS; T6a = PACK-CHAT Behavioral; T6b = PACK-CHAT Role) so Check 46 reference-resolution passes both directions.

### T8 — test-fixtures/manifest.txt regen (design §3.7)
- **File:** `test-fixtures/manifest.txt`.
- **What changes:** coder runs `bash test-fixtures/build.sh --all --clean`; if `git diff test-fixtures/manifest.txt` is NON-EMPTY, stage it in the SAME commit. Trigger: T4/T5/T6/T7 touch `pack-ops/` (a v11-surface trigger dir). (T1/T2/T3 pack-root trinity are base-case exempt, but the `pack-ops/` edits independently fire the trigger.)

### PARAMETRIC (re-run only — NO edits, design E-5)
- Check 18 / Check 45 / Check 46 (`scripts/validate-pack.py`): parametric — no code edit.
- `scripts/tests/test-validate-pack-check-45.sh`, `...check-46.sh`: parametric (synthetic trees + Group-2 HEAD clean-exit) — re-run to confirm green; NO edit.

---

## (B) File-dependency + ordering (so validate-pack stays GREEN at the commit)

The commit is ATOMIC, so ordering is an AUTHORING sequence for the coder (the
END-STATE is what CI verifies per PACK-CHAT.md propagation note "verified by
END-STATE checks, not a hard-enforced step sequence"). Recommended authoring order
mirrors the PACK-CHAT.md propagation procedure (corpus → rationale → refs +
manifest → regen):

1. **T1 → T2 → T3** (corpus ×3). Lands the new `[rationale: pack-chat-minor-edits-only]` token. *Dependency:* must co-land with T4 or Check 45 sees an orphan corpus slug.
2. **T4** (rationale section). *Pairs with step 1* — together they keep Check 45 bijection at N+1 == N+1 (21→22 both sides).
3. **T5, T6a, T6b** (reference surfaces). *Dependency:* must co-land with T7 — Check 46 reference-resolution is bidirectional (a named manifest reference with no resolving surface fails; a surface pointer with no manifest record is not required but the manifest must name every reference it claims).
4. **T7** (manifest record). *Pairs with step 3.*
5. **T8** (manifest regen) — LAST, after all content edits, so the fixture SHAs reflect final bytes.

**GREEN-at-commit guarantees:**
- **Check 45 (bijection):** corpus slug-set (from CLAUDE.md `## Pack memory` only — verified: Check 45 reads ONLY CLAUDE.md, L6429/L6443) == RATIONALE `## <slug>` set. T1 adds the corpus token; T4 adds the rationale section → both sets 21→22. AGENTS/GEMINI corpus tokens are NOT scanned by Check 45 but ARE required for trinity parity (Check 18 + trinity rule).
- **Check 46 (anti-restate + ref-resolution):** scans `pack-ops/PACK-AGENTS.md` + `pack-ops/PACK-CHAT.md` (verified surface tuple L6539–6546) for ≥60-char verbatim corpus-BODY restatement (name excluded, L6564 `_CHECK_46_ANTI_RESTATE_MIN_LEN = 60`). T5/T6a/T6b are NAME+slug paraphrases → no ≥60-char body slice → safe. Ref-resolution: T7 manifest record names exactly the T5/T6a/T6b surfaces, each of which carries a `## Pack memory` + slug pointer.
- **Check 18 (trinity H2 parity):** gates H2 STRUCTURE (names/order) only (verified L1465–1503). The new rule is a BULLET inside the existing `## Pack memory` H2 / `### Pack Chat scope` H3 — adds NO H2 → Check 18 unaffected. Trinity PARITY of the bullet text is held by T1/T2/T3 byte-identical insert (the trinity rule, not Check 18, enforces this — coder diffs the three).

---

## (C) Commit shape — confirm §7 single atomic commit

**CONFIRMED: ONE atomic commit** (design §7). Rationale: Check 45 bijection and
Check 46 ref-resolution must never observe a half-applied state; an atomic commit
is the only shape where corpus+rationale+refs+manifest land together. No refinement
needed — the single-commit shape is correct and minimal.

**File set (exactly 8 paths, all pack-side governance):**
1. `CLAUDE.md`
2. `AGENTS.md`
3. `GEMINI.md`
4. `pack-ops/PACK-MEMORY-RATIONALE.md`
5. `pack-ops/PACK-AGENTS.md`
6. `pack-ops/PACK-CHAT.md`
7. `pack-ops/.spawn-rule-manifest.txt`
8. `test-fixtures/manifest.txt` (only if regen diff non-empty)

**Scope keyword: `pack-only`.** All 8 paths are pack-ops/ + pack-root trinity +
test-fixtures — none under `project-template/` or `supporting-docs/`. Check 36's
`pack-only` keyword DENIES `project-template/` and `supporting-docs/`; the file
set touches neither → the claim is honest.

> **KEYWORD-TOKEN-TRAP guard (`commit-subject-keyword-token-trap`).** The commit
> subject MUST carry `pack-only` as the ONLY scope-keyword token. BD-208 is
> literally ABOUT the "PM-only" set — so the subject MUST NOT contain the literal
> string `PM-only` (nor `project-only` / `pack-memory-only`) anywhere, including
> descriptive prose: Check 36 substring-scans the whole subject and a denying
> `PM-only` token would win and FAIL the gate (the exact BD-198 failure). Describe
> the small set with non-keyword vocabulary — e.g. "small Pack-Chat-direct set",
> "pack-memory-governed set" — never the literal `PM-only`.
- **Suggested subject (token-trap-safe, verify against live format before commit):**
  `feat: v11 — BD-208 Pack Chat minor-edits-only editing-actor rule + lockstep propagation (pack-only)`
  (contains `pack-only` once; no other scope-keyword literal; "minor-edits-only" is a slug fragment, NOT a scope-keyword token — safe.)

**Actor:**
- **pack-coder (scoped in)** does T1–T8 — Pack Chat's spawn prompt scopes the
  PM-only governance files in (the PACK-AGENTS "off-limits UNLESS explicitly
  scoped in" clause is the supported path; design §1 confirms "Pack Chat scoping
  a PM-only file INTO a coder prompt … is NOT a boundary violation"). The rule
  text is architect-defined; the coder applies it mechanically + holds parity.
  Note: this BD is itself the first application of its own model (a MAJOR edit to
  governance files → coder).
- **Pack Chat** does ONLY the commit (no Edit/Write — `agents-never-commit` +
  Pack-Chat-NO-coder-review).

**Manifest regen:** included as T8, staged in the SAME commit when non-empty
(`manifest-regen-on-v11-surface`; pack-ops/ trigger fires).

**Staging (`no-prestaging-until-commit-approval`):** Pack Chat does NOT pre-stage.
At user commit-approval, commit named paths directly. All 8 paths are already
tracked → `git commit <8 paths> -m "…"` (pathspec commit, no standing staged
window). Follow with `git show --stat HEAD` to confirm only the intended paths.

**Bounded review/fix cadence for this single commit (`review-fix-cycle`):**
coder → reviewer pass 1 → [clean ⇒ commit] | [findings → triage→user→fix-coder
pass 1 → reviewer pass 2 → [clean ⇒ commit] | findings → fix-coder pass 2 →
reviewer pass 3 → [clean ⇒ commit] | dirty ⇒ STOP + architect escalation]].
Fresh coder per spawn. Single-BD / single-commit → one cycle; NO end-of-batch
reviewer needed (only one commit).

---

## (D) Verification plan

**CI / validator (coder PREFLIGHT gate — must all PASS before IMPL-REPORT):**
1. `python3 scripts/validate-pack.py` GREEN overall, with specifically:
   - **Check 45** — bijection holds: corpus slug-set == RATIONALE slug-set, both 22 (was 21). New slug `pack-chat-minor-edits-only` has its `## pack-chat-minor-edits-only` section (no orphan).
   - **Check 46** — 0 anti-restate violations across PACK-AGENTS.md + PACK-CHAT.md; reference-resolution passes (T7 manifest record's named surfaces all resolve).
   - **Check 18** — trinity H2 parity GREEN at pack-root (no H2 added) and project-template (untouched).
   - **Check 43** — leak-sweep GREEN (no pack-self leakage introduced).
2. `bash scripts/tests/test-validate-pack-check-45.sh` PASS (parametric — re-run, no edit).
3. `bash scripts/tests/test-validate-pack-check-46.sh` PASS (parametric; Group 2 runs validate-pack on HEAD for clean-exit — satisfied once T5/T6/T7 land consistently).
4. `Validate Pack` GitHub Actions workflow GREEN on push (post-commit).

**Manual / grep audits (coder reports evidence in IMPL-REPORT):**
- **Trinity parity:** `diff` the three inserted bullets (T1/T2/T3) — byte-identical. Confirm slug appears exactly once per file: `grep -c 'pack-chat-minor-edits-only' CLAUDE.md AGENTS.md GEMINI.md` → 1 each.
- **Bijection count:** `grep -oE '\[rationale: [a-z0-9-]+\]' CLAUDE.md | sort -u | wc -l` → 22; `grep -cE '^##\s+[a-z0-9][a-z0-9-]*\s*$' pack-ops/PACK-MEMORY-RATIONALE.md` slug-set → 22.
- **Spawn-manifest record present:** `grep -A4 'slug:       pack-chat-minor-edits-only' pack-ops/.spawn-rule-manifest.txt` shows the full 4-line record.
- **Anti-restate spot-check:** confirm no ≥60-char contiguous verbatim slice of the corpus imperative BODY appears in PACK-AGENTS.md / PACK-CHAT.md edits (the reference lines name+paraphrase).
- **Manifest regen:** `git diff --stat test-fixtures/manifest.txt` — staged if non-empty; if empty, T8 is a no-op (record it).
- **Re-read evidence:** coder re-reads each edited file's section map and reports the actual post-edit anchor neighbourhood (not intent) per `edit-in-place-not-full-rewrite`.

**Post-commit (Pack Chat):** `git show --stat HEAD` confirms exactly the 8 (or 7) intended paths; Actions workflow GREEN.

---

## (E) Open gaps / ambiguities (SURFACED — not resolved)

- **G-1 (manifest regen indeterminate at plan-time).** Whether T8 produces a
  non-empty diff cannot be known until the content edits land (the manifest
  hashes `pack-ops/` files; T4–T7 change them). EXPECTATION: non-empty (four
  pack-ops/ files change) → T8 will stage `test-fixtures/manifest.txt`. The plan
  handles both branches (stage if non-empty; no-op + record if empty). No action
  needed — flagged so the coder treats a non-empty diff as EXPECTED, not a defect.

- **G-2 (OOS-1 memory-cache reconciliation is out-of-repo, already DONE).** The
  design §4.3/§4.5/§3.6 require reconciling `review-cycle-position-checkpoint` #3
  and `pack-chat-boundaries` #2 in Pack Chat's OUT-OF-REPO memory cache. Per the
  spawn prompt, OOS-1 is ALREADY APPLIED by Pack Chat directly (out-of-repo memory,
  not a coder deliverable). This is NOT a plan task and NOT in the coder commit.
  Recorded for completeness; the trinity rule WINS over the memory cache regardless,
  so no validator gate depends on it.

- **G-3 (line-number drift in the design doc).** The architect doc's L13/L21
  (PACK-CHAT) and trinity anchor line numbers are from SHA `a630a312`; live HEAD
  `3d7bec4` has the same TEXT at different lines (documented in the drift notice up
  top). NO ambiguity in the EDIT — every task anchors on byte-quoted text. Flagged
  only so the coder ignores the design doc's line numbers and uses the quoted
  anchors. NOT a blocker.

- **G-4 (no genuine open decision).** OOS-3 (delete-and-reauthor coherence) is
  RESOLVED by the user's ID-history closure; OOS-2 is folded in-scope (T6b). No
  `MAINTAINER CHECK NEEDED` items — every state question was answered by direct
  read this session.

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| read-in-full + NO-DERIVATION | All named docs Read DIRECTLY this session — see READ-IN-FULL proof row. ARCHITECTURE-BD-208.md read full (775 lines, `wc -l` = 775); BD-208 entry read (BACKLOG L3418–3440); CLAUDE.md `## Pack memory` slug-set read via grep (21) + section anchors read; PACK-AGENTS.md PM-only block read (L128–163); PACK-CHAT.md Role L9–21 + Behavioral L83–94 + propagation L295–309 read; PACK-MEMORY-RATIONALE.md tail+count read; validate-pack Checks 18 (L1461–1505), 45 (L6427–6466), 46 (L6539–6564) read; 8 memory files read full. No claim derived — every state-claim cites a command run this session. | COMPLIANT |
| empirical-evidence-blocks | Every state-claim backed: HEAD `3d7bec4` (`git rev-parse HEAD`); slug count 21 (`grep -oE '\[rationale:…' CLAUDE.md \| sort -u \| wc -l` = 21); slug absent (`grep -rn pack-chat-minor-edits-only … = 0`); Check 45 reads only CLAUDE.md (L6429–6443 quoted); Check 46 surfaces = PACK-AGENTS+PACK-CHAT (L6539–6546 quoted); MIN_LEN=60 (L6564 quoted); Check 18 = H2 structure only (L1465 quoted); trinity anchors located (CLAUDE L383/AGENTS L349/GEMINI L316); PACK-CHAT anchors (L14, L20–21, L94); test files exist (`ls` PASS). Each interpreted + SUPPORTED inline. | COMPLIANT |
| bounded-review-fix-cycle | Plan §C specifies the literal cadence (coder → rev1 → [clean⇒commit \| fix1→rev2→[clean⇒commit \| fix2→rev3→[clean⇒commit \| architect-escalate]]]); fresh coder per spawn; single-commit ⇒ one cycle, no end-of-batch reviewer. | COMPLIANT |
| commit-subject scope-keyword + keyword-token-trap | §C assigns `pack-only` (file set excludes project-template/ + supporting-docs/); explicit guard that the subject must NOT contain literal `PM-only`/`project-only`/`pack-memory-only` (BD-198 trap); suggested subject carries `pack-only` once only. | COMPLIANT |
| manifest-regen-on-v11-surface | T8 regenerates `test-fixtures/manifest.txt` via `bash test-fixtures/build.sh --all --clean`; staged in SAME commit if non-empty; trigger = pack-ops/ edits (T4–T7). G-1 flags the regen as expected-non-empty. | COMPLIANT |
| enumerate-encoding-surfaces | Every encoding surface named with lockstep disposition: Check 45 (parametric, re-run), Check 46 (parametric, re-run), Check 18 (parametric, re-run), test-45 (re-run, no edit), test-46 (re-run, no edit), .spawn-rule-manifest.txt (T7 ADD record), PACK-MEMORY-RATIONALE.md (T4 ADD section), test-fixtures/manifest.txt (T8 regen). | COMPLIANT |
| agents-never-commit | Plan assigns commits to Pack Chat only; coder does T1–T8 edits + verification, NO git verbs. Planner emitted no git verb (planning-only). | COMPLIANT |
| edit-in-place-not-full-rewrite | Every task (T1–T7) specified as TARGETED insert/replace with exact byte-quoted anchor; T4/T7 are APPENDS to ordered-list files; no full-file rewrite. Coder directed to re-read section map post-edit (D, re-read evidence). | COMPLIANT |
| scope-deliverables-to-the-ask | Deliverable leads with (A) task breakdown + (C) commit shape; no edge-case sprawl, no speculative coverage tables; OOS items dispositioned tersely per spawn instruction (DONE/in-scope/resolved). | COMPLIANT |
| rules-applied-verification-block | This block + READ-IN-FULL proof row; no empty-evidence rows; no AMBIGUOUS terminal state. | COMPLIANT |

### READ-IN-FULL proof (direct-read evidence per doc)

| Doc | Direct-read proof |
|---|---|
| `ARCHITECTURE-BD-208.md` | Read L1–775 (full; `wc -l` = 775). First: `# ARCHITECTURE-BD-208 — Pack Chat editing-actor rule…` (L1); last: READ-IN-FULL proof table row `feedback_scope_deliverables_to_the_ask.md` (L775). |
| BD-208 entry (`pack-ops/BACKLOG.md`) | Read L3418–3440. First: `---` (L3418) → `**BD-208 — Pack Chat editing-scope rule…**` (L3420); last: `Position: pack-self governance; parallel with BD-203…` (L3439). |
| `CLAUDE.md` `## Pack memory` | Slug-set grepped (21, `sort -u`); slug absence grepped (0); trinity anchor located (L383 `those go to pack-coder.` + L384 Commit-approval bullet). |
| `pack-ops/PACK-AGENTS.md` | Read L128–163. First quoted: `**PM-only files and directories** are off-limits…` (L130); scope-in clause `pack-coder MAY scope a per-entry directory in…` (L157–159). |
| `pack-ops/PACK-CHAT.md` | Read L9–21 (Role), L83–94 (Behavioral / Real-fixes-only), L295–309 (propagation procedure). Anchors `Write files directly…` (L14), `execute pack changes directly` (L20–21), Real-fixes-only bullet end (L94). |
| `pack-ops/PACK-MEMORY-RATIONALE.md` | `wc -l` = 565; last slug header `## dependency-direction-placement` (L549); 21 slug headers confirmed via grep. |
| `pack-ops/.spawn-rule-manifest.txt` | Read L1–52. Header (L1) + sample record `agents-never-commit` (L24–27) for format match; `wc -l` = 52. |
| `scripts/validate-pack.py` (Checks 18/45/46) | Check 18 L1461–1505 (`H2 structure parity`); Check 45 L6427–6466 (corpus = CLAUDE.md only, bijection); Check 46 L6539–6564 (surfaces tuple + `_CHECK_46_ANTI_RESTATE_MIN_LEN = 60`). |
| `feedback_review_fix_cycle.md` | Read full (32 lines). First `name: review-fix-cycle`; last `Cross-refs: [[pack-chat-boundaries]]…`. |
| `feedback_manifest_regen_on_v11_surface.md` | Read full (15 lines). First `name: manifest-regen-on-v11-surface`; last `Related: test-infra self-provisioning…`. |
| `feedback_commit_subject_keyword_token_trap.md` | Read full (38 lines). First `name: commit-subject-keyword-token-trap`; last `…[[feedback_no_prestaging_until_commit_approval]]`. |
| `feedback_no_prestaging_until_commit_approval.md` | Read full (23 lines). First `name: no-prestaging-until-commit-approval`; last `…(the default assumption).` |
| `feedback_scope_deliverables_to_the_ask.md` | Read full (34 lines). First `name: scope-deliverables-to-the-ask-no-noise`; last `…preference for terse, exactly-scoped work.` |
| `feedback_agent_output_rules_applied_block.md` | Read full (14 lines). First `name: agent-output-rules-applied-block`; last `Related: [[agent-prompt-enumerates-rules]]…`. |
| `feedback_architect_planner_empirical_evidence.md` | Read full (14 lines). First `name: architect-planner-empirical-evidence`; last `Related: [[agent-output-rules-applied-block]]…`. |
| `feedback_edit_in_place_not_full_rewrite.md` | Read full (14 lines). First `name: edit-in-place-not-full-rewrite`; last `…[[feedback_pack_chat_no_coder_review]] (independent verification).` |
