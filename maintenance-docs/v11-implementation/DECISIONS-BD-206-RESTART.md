# BD-206 — Decisions, Answers & Rules Capture (RESTART)

> **What this is:** a faithful record of the rules, answers, and decisions the
> user gave for the BD-206 restart, captured so none are lost. The user will
> read and may edit this.
>
> **What this is NOT:** a design, a plan, or a binding spec. It is a decisions
> ledger. The fresh architect/researcher must reach their own conclusions; this
> doc only records the user's stated constraints + measured current-state facts.
>
> **Why a restart:** the prior BD-206 architecture + planning chain was REJECTED
> OUTRIGHT by the user (it introduced a forbidden `_scaffolding.md` sidecar,
> revealing the architect misunderstood `_rules.md` / `_intro.md`). The entire
> design + planning was discarded.
>
> Captured by Pack Chat. Pack HEAD at capture: `79d8aa3`.

---

## 0. Status of the restart (as of capture)

- The rejected design + planning chain (10 docs) is QUARANTINED at
  `/tmp/bd206-REJECTED-DO-NOT-READ/`. **No agent may read it.** "This should
  all be fresh."
- Kept inputs (NOT yet re-confirmed): `/tmp/pack-handoff-bd206-brief/`
  (BRIEF.md, GOALS-REQUIREMENTS-SUCCESS.md) and
  `/tmp/pack-handoff-bd206-research/` (RESEARCH-BD-206.md,
  CENSUS-BD-206-TECHDEBT.md).
- One stale BD-206 research doc is still committed in the repo:
  `maintenance-docs/v11-implementation/RESEARCH-BD-206-PROJECT-CONVERSION.md`
  (commit `3e3159e`). Disposition PENDING (see §9).
- The user DELETED by hand all 7 project-template sidecars under
  `project-template/docs/project/` (backlog/implementation-plan/changelog
  `_rules.md` + `_intro.md`, plus changelog `_format.md`). They are
  recoverable from git history. **Update (2026-06-25): the user now RESISTS
  restoring any of them — all are contaminated and must be COMPLETELY REWRITTEN
  (§1, §12). This supersedes the earlier "user replaces them by hand" plan and
  unblocks the design (the architect does not need them restored).**
- No agents spawned, no commits, no pushes since `79d8aa3`.

---

## 1. The corrected sidecar model (THE critical new guardrails)

These supersede whatever the rejected design assumed. User-stated this session.

- **`_rules.md` = operational contract.** It contains EVERYTHING the PM chat and
  agents need to do their work. It is pack-shipped and is **coupled to all
  operational files**. The pack-shipped `_rules.md` **MUST NOT be modified**
  (not per-project, not otherwise).
- **`_intro.md` = human-readable ONLY.** It is NOT intended for the PM chat or
  agents and contains NO information agents need. The pack-shipped `_intro.md`
  **CAN be modified** per-project.
- **Classifying a monolith's non-entry content:** human-readable, non-rule
  content → `_intro.md`. If the content is a **RULE**, that is a red flag (rules
  must not be project-specific or changing) → **escalate to the user**; do not
  silently place it anywhere.
- **`_scaffolding.md` is FORBIDDEN.** No new sidecars of any kind.
- **`_format.md` is FORBIDDEN in EVERY tree (user, 2026-06-25).** Any formatting
  rules become a SECTION of `_rules.md`. The changelog `_format.md` is rewritten
  into a formatting section of the changelog `_rules.md`; backlog and
  implementation-plan never gain one. Sanctioned vocabulary stays exactly
  `{_rules, _intro, _toc, _index(optional)}`.
- **All current sidecars are CONTAMINATED → complete rewrite (user, 2026-06-25).**
  Whatever BD created the started sidecars enshrined tech debt BD-206 MUST remove.
  It is unclear what is salvageable vs wrong, so all are rebuilt from scratch off
  the corrected requirements + the reference monoliths (§12) — never from the old
  files; do not restore them.

## 2. The architect's sidecar constraint (restart rule)

- The architect must **not invent any new sidecar files**, and must **not even
  know of the existence of any sidecar other than** `_rules.md`, `_intro.md`,
  `_toc.md`, and the **optional** `_index.md`.
- The sanctioned sidecar vocabulary is exactly: `{_rules.md, _intro.md, _toc.md,
  _index.md (optional)}`.

## 3. `_index.md` — use + the design tripwire

- **User decision:** `_index.md` on the project side has the **same use as the
  pack side**, with **multiple indexes potentially in it**. Right now there
  should probably be **only one index**, and **only the implementation-plan
  stream has the file**. The **backlog is unordered → it should not need or have
  one**.
- **Tripwire (user-stated):** "If the architect designs this wrong then we know
  there are more problems." The expected outcome is: implementation-plan gets
  `_index.md`; backlog gets none.
- **Grounded facts (measured / from committed BD-214 IMPL-REPORT, supporting the
  above — NOT to be fed as the answer):**
  - `_index.md` is a sidecar alongside `_intro.md`/`_rules.md`/`_toc.md` that may
    carry ONE OR MORE indexes or graphs (order, groupings, optionally a
    dependency graph — dependency graph not a default).
  - BD-206 must CREATE it for the project implementation-plan stream because
    phase order is NOT numerically recoverable from filenames the way
    `/backlog/` BD-NNN ordering is.
  - Zero `_index.md` / `_order.md` files exist anywhere in the tree today
    (measured at HEAD `79d8aa3`).

---

## 4. BD-206 scope (user-stated)

- Move the **project side** fully onto a **form-family per-entry model**: all
  three streams (`backlog`, `implementation-plan`, `changelog`) → per-entry
  flat-file trees with **NO monolith mirror**.
- **Form families apply to backlog + implementation-plan.** The **changelog is
  in scope for the per-entry move but does NOT need to conform to form
  families** (it is the flexible stream).
- BD-206 must **create the guardrails to enforce the use of phase parts and form
  families**. Conforming to the new format is **mandatory**.
- **Issue trackers are OUT OF SCOPE** for BD-206. The form families are designed
  to work with issue trackers *eventually*, but that migration is a future,
  out-of-scope effort. The guardrails are forward-prep for it.
- BD-206 must **update ALL of the mechanisms** that will not work with the new
  per-entry/no-mirror shape (e.g. METHODOLOGY.md and other docs, scripts,
  validators, installers/migrators) — a full project-side mechanism overhaul.
- **All three streams are in scope.**

## 5. Schema decisions (user-stated)

- The schema **MUST work with form families and eventually issue trackers**, and
  the exact schema **must be decided by an authoritative source** (docs
  researcher or architect) — not assumed.
- Adding phase parts should become **much easier** under the new model.
- **Form families are REQUIRED for BOTH backlog AND implementation-plan (user,
  2026-06-25), with enforcement — rules + tests + CI — going forward.**
- **v10 anchoring is STRICTLY FORBIDDEN.** The new architect MUST challenge every
  v10 rule and use the v11 standards. The form-family schema lives in `_rules.md`.
- **The ot-convert V2 converted monoliths comply with v11 and are the reference;
  the existing v10 production monoliths for backlog + impl-plan are NOT to be
  used at all** (see §12).

## 6. OT reference + read-only rules (user-stated)

- The user performed a transformation on OT's backlog + implementation-plan
  monoliths into the form-family shape. The final results live in OT's
  `completed-conversions/` folder. **The semantic meaning of the entries did not
  change.**
- **OT stays read-only.** Never write to OptiquityTrader or the ot-convert
  folder.
- **If, during BD-206 implementation, the new OT flat files need to be
  modified:** the user will have that done **by the OT chat session itself —
  NEVER here.** The reason must be **defensible, evidence/logic-based, and
  forward-looking — never arbitrary — and must be escalated to the user.**

## 7. Migrator-feed decision (Q3 = A, user-stated)

- The migration script that splits the monolith into per-entry files must use
  the **NEW converted monoliths** (the form-family version), **NOT** OT's
  production version, when it splits the entries.
- **Q3 = A:** build it as a **reusable migrator sub-operation**, BUT note it is
  **not only splitting the entries — it must also produce the content for the
  sidecars.** (User open question: is the sidecar-content production already
  designed, or is it a gap? → for the fresh architect to answer.)
- **OT V2 gold is the authoritative migrator-feed reference.** Its enums are
  already clean — the 4 reclassifications below are applied and user-approved.
  **No further OT reclassification.**

## 8. Standing decisions — RECONSIDERED (user, 2026-06-25)

**RECONSIDERATION (user, 2026-06-25).** Decisions premised on the FIRST-PASS
(contaminated) architect recommendations are **no longer locked** — the FRESH
architect re-derives them from primary sources and the user re-reviews at the
design gate. Disposition:
- **STANDS (fresh / empirically verified):** all §13 walkthrough decisions
  (Items 1–8); the 4 ESC-1 reclassifications + the OT V2 gold (independently
  verified). Q4 → re-grounded by §13 Item 7; GC-2-1 → re-affirmed by §13 Item 3.
- **RE-VALIDATE (clean call, rejected-era basis):** Q5 (`wi-kind` removal), Q6 /
  Q10 (`_order`→`_index` sweep), D9 (allowlist removal) — fresh architect
  re-validates against primary sources before they're relied on.
- **RECONSIDER / RE-DERIVE (content was contaminated/quarantined):** GC-1..GC-8,
  CE-1..CE-6, GC-2-2 — content-less; fresh architect re-derives from primary
  sources, user re-confirms at the design gate. Do NOT carry the old labels'
  content forward.

- **Q4:** land the Check-32′ project no-mirror enforcement in BD-206.
- **Q5:** remove `wi-kind` (the `work-item.yml` field).
- **Q6:** `_order` → `_index` sweep in BD-206.
- **GC-2-1:** phase-parts adopt-as-body + defer enforcement to BD-185.
- **GC-2-2:** BD-185 stale-sibling-string cleanup = a separate pack-chat-only
  pass.
- **D9 allowlist removed** (OT reclassified → clean enums on the V2 gold).
- **The 4 OT reclassifications (ESC-1), applied + approved:**
  - TD-057 `Scope: architecture` → `feature`
  - TD-058 `Scope: architecture` → `feature`
  - TD-070 `Severity: dependency` → `functional`
  - TD-071 `Severity: dependency` → `functional`
- **GC-1..GC-8 and CE-1..CE-6** were accepted "as architect-recommended" — BUT
  their CONTENT lived in the now-quarantined rejected design. **FLAG:** these
  labels are meaningless without that content; the fresh architect must
  re-derive these from primary sources, and the user must re-confirm. Do NOT
  reconstruct them from the quarantine.

## 9. Process / governance rulings that emerged (user-stated)

- **Options + recommendations come from AGENTS, not Pack Chat.** "You are not an
  agent." Pack Chat relays agent options/evidence/recommendations and never
  authors them; if an agent has no evidence-based recommendation, say so.
- **BD entries = current state only.** Never a "Note," never incorrect
  historical info. A stale/confusing entry gets a complete rewrite, not a patch.
- **Reconciliation-instance independence.** A reconciliation pass uses a FRESH
  instance (not the original author, not the adversary). `docs-researcher` is the
  one role that may be re-engaged.
- **The fresh architect must not read** the quarantined chain or (pending §10)
  the old research. "This should all be fresh."

## 10. OPEN / PENDING (not yet decided)

- **Research approach (your choice #1):** re-run a fresh `pack-docs-researcher`
  from primary sources + the corrected requirements (Pack Chat's recommendation,
  given the clean slate) vs keep the existing `/tmp` research as-is. Coupled to
  the disposition of the committed stale `RESEARCH-BD-206-PROJECT-CONVERSION.md`.
- **OT-spec contamination ruling (your choice #2):** Pack Chat's assessment was
  that the quarantined OT-ESCALATION-SPEC contained **no reference to
  `_scaffolding.md` (named or unnamed)** and no sidecar/per-entry content — it
  was solely the 4 ESC-1 reclassifications + tracker-label rationale +
  content-preservation/pushback contract + grep verification. Therefore **NOT
  contaminated → OT-side ESC-1 work does not need re-running.** Your formal
  ruling is pending.
- **`_format.md`:** DECIDED (2026-06-25) — forbidden in every tree; folded into
  `_rules.md` (no longer open). See §1.
- **The 7 deleted project-template sidecars:** DECIDED (2026-06-25) — contaminated,
  to be completely rewritten (NOT hand-restored). The architect designs the new
  sidecars from the corrected requirements + reference monoliths (§12); the design
  is NOT blocked on restoring the old files.

## 11. Measured current-state facts (HEAD `79d8aa3`, before your hand-deletion)

- Pack side (already per-entry, the reference model): `backlog/` and
  `changelog/` each have `_intro.md`, `_rules.md`, `_toc.md`. Neither has an
  `_index.md` (both pack streams are unordered).
- Project side (`project-template/docs/project/`) had only 7 sidecar files
  (backlog/impl-plan/changelog `_rules.md` + `_intro.md`, changelog `_format.md`)
  — NO `_toc.md`, NO `_index.md`, NO per-entry entries. (These 7 are the files
  you have now deleted.)
- No `_index.md` or `_order.md` exists anywhere in the repo.
- `_format.md` existed only at the project changelog stream.

---

## 12. Reference sources for the rewritten sidecars (user, 2026-06-25)

- **backlog + implementation-plan sidecars** derive the form-family schema from
  the **ot-convert V2 converted monoliths** (form-family, v11-compliant — "should
  comply with v11 now").
- **changelog sidecar** derives its format from the **production OT changelog
  monolith** (changelog is the flexible stream; no converted version exists).
- **The existing v10 production monoliths for backlog + implementation-plan are
  NOT to be used at all** (clarified by user 2026-06-25: use the ot-convert V2
  versions instead). The production OT changelog monolith IS the allowed changelog
  reference.
- OT stays READ-ONLY. If a V2/production reference needs modification, that is done
  by the OT chat session only, with defensible/forward-looking evidence, escalated
  to the user (§6).
- **iCloud V2-path caveat (2026-06-25):** the V2 gold path contains spaces + `~`
  chars; `architect-bd206-restart` mis-read it as absent (its DG-1 — a FALSE ALARM;
  Pack Chat re-verified the files present + readable, `Entry-Type: td` 113/113). The
  coder/migrator MUST use the fully-quoted absolute path AND confirm the file is
  materialized (not an iCloud placeholder) before relying on it.

---

## 13. Open-item walkthrough decisions (user, 2026-06-25)

Decisions resolving the docs-research Part-6 open questions, one at a time.

- **Item 1 — Backlog `Scope` enum (Part 6 Q1).** DECIDED: the v11 project-template
  backlog form-family `Scope` enum = `{phase-N, dependency, feature, perf, version}`
  (the fuller, live cross-surface vocabulary — already in METHODOLOGY Part 7 +
  `project-template/CLAUDE.md` deferral-comment rules + `work-item.yml`). `phase-N`
  is a **templated pattern** (`phase-\d+`), NOT a fixed token. (`perf` = performance.)
  This is the enum the backlog form-family enforcement validates.
- **Item 2 — Backlog `Verify-Source` value-space (Part 6 Q2).** DECIDED:
  `Verify-Source` is an **open-string** field (NOT an enum), matching the live
  project-template convention ("name the external source"). Enforcement validates
  PRESENCE, not enum membership. (Any optional format constraint — e.g. a lowercase
  token — is an architect detail unless the user later specifies one.)
- **Item 3 — Phase-part model (Part 6 Q4/Q5).** DECIDED:
  - **Q5 (location): (a) INLINE** for BD-206 — parts stay inline in `phase-N.md`.
    Rationale (user): separate per-part files entail (1) splitting phases-with-parts
    into per-part files, (2) operational enforcement (docs/rules/scripts/tests) to
    prevent drift, (3) form-family prep for eventual tracker migration — ALL of
    which is **BD-185's scope ("and more")**. Doing only part of it now is not
    useful/maintainable. BD-206 = adopt-as-body (inline); **BD-185 = the full
    per-part-file migration + operational enforcement.** (Reaffirms GC-2-1.)
  - **Q4 (richness): (a) LIGHTWEIGHT** (Entry-Type only) for BD-206 — conditioned on
    phase-part richness/consistency enforcement being part of **BD-185**. No
    BD-206-specific phase-part drift-enforcement; that is BD-185.
  - **Resolves the phase-part enforcement-timing tension:** the FULL phase-part
    enforcement + per-file migration → BD-185 by explicit user direction (size +
    logical-fit; BD-185 is the pre-existing, user-authorized deferred scope — not new
    scope creep). BD-185 verified to cover it (`validate-pack.py` "new check(s)
    enforcing part-membership + flat-file ordering invariants"; SC-SER serializability);
    tracker form-family Part-field legs → BD-216. BD-185 is `Deferred, Target: none`
    (tracker-resumption cluster) — i.e. indefinitely deferred.
  - **Minimal v11.0 guard + naming standardization (user, 2026-06-25):** BD-206 ALSO
    adds, *gracefully*, (i) a MINIMAL phase-part guard and (ii) standardized
    phase/part/task naming. **"Graceful" = the BD-185 litmus:** codify the EXISTING
    lowercase-letter convention (`## Phase N`, `### Phase-N.Part-x`, `#### N.M` /
    `#### Phase-N.Part-x.Task-k`) — the OT gold already conforms, so NO forced
    refactor of any existing part; tracker-forward-compatible; NO stored
    execution-order marker; a naming/FORMAT conformance check, NOT a structural
    per-file migration (that stays BD-185). It rides on BD-206's impl-plan
    form-family enforcement. Exact mechanism + the BD-206-minimal vs BD-185-full
    boundary = architect's design (design-gate reviewed). Bounded, deliberate BD-206
    scope addition.
  - **BD-206 must also TOLERATE inline parts gracefully** — the new impl-plan
    form-family enforcement must not choke on the inline `### Phase-N.Part-x` /
    `#### …Part-x.Task-k` content in `phase-N.md`.
- **Item 4 — Non-entry `## ` content classification (Part 6 Q3) — refines §1.**
  DECIDED (user, 2026-06-25), generalized guideline:
  - Text **necessary for proper creation/maintenance/use/operations of an entry** →
    `_rules.md`. Otherwise → `_intro.md`.
  - **`_rules.md` is pack-set (config pack), NOT the project** → project-specific text
    can never live in `_rules.md`. **Corollary:** project text that looks
    operationally-necessary-for-entries but isn't already a pack rule is the
    ESCALATE-to-user case (either the pack `_rules.md` needs a generic addition, or
    the text is project human-content → `_intro.md`).
  - **Arbitrary monolith-reading section headers** (useful only for reading a flat
    monolith, useless once entries are a tree) → **remove**, OR a **small notes section
    in `_intro.md`** (chat/agents don't read `_intro.md` anyway).
  - OT worked example: `## Codebase Snapshot` + `## Cross-Phase Notes` → `_intro.md`/
    remove; the two `## … Completion Checklist` sections → architect applies the test
    (generic process → pack `_rules.md`/METHODOLOGY, never duplicated into project
    content; OT-specific → `_intro.md`/remove; operational-but-not-yet-a-pack-rule →
    escalate).
- **Item 5 — `_index.md` content + generation, impl-plan (Part 6 Q6).** DECIDED
  (user, 2026-06-25):
  - `_index.md` (impl-plan) stores the **canonical serial sort order** of phase
    entries, derived from **dependencies / groupings / a chosen heuristic**. It
    recovers the ordering filenames can't.
  - **Dependencies are SSOT in each per-entry phase file**; `_index.md`'s order
    reflects them — `_index.md` is NOT a competing source of truth for the deps.
  - The serial order is a **baseline, NOT an execution/parallelization schedule.**
    Actual parallelization is the architect/planner's **runtime** decision
    (parallelize entries that are unblocked AND parallelizable), never stored.
  - **BD-185 is the same idea one level down:** execution order + parallelization of
    tasks/parts INSIDE a phase = architect/planner runtime, not driven by presentation
    order, never a stored value (the rejected per-task `<!-- execution-order: N -->`
    marker).
  - Net: STORED = the dependency-derived serial sort (phases, in `_index.md`);
    RUNTIME / never stored = parallelization at BOTH levels + within-phase task order.
  - Generation method (derived vs maintained; deps stay SSOT in the entry files) =
    architect's call (design-gate reviewed).
- **Item 6 — Changelog `_rules.md` formatting-section depth (Part 6 Q7).** DECIDED
  (user, 2026-06-25): **(b) FULLER / structured** — the changelog `_rules.md`
  formatting section codifies a structured body field set (not just Summary +
  structural rules). Rationale (user): changelog entries should be structured even
  though they aren't tracker issues.
  - **"Structured" ≠ "form family":** changelog still does NOT get the
    Entry-Type/Marker/Scope/Severity schema (§4 stands) — it gets a consistent FIELD
    SET (a core required set + optional extras allowed; production body has ~30 one-off
    labels).
  - **Enforcement (Pack-Chat interpretation — user confirming):** the structured set
    gets a conformance check (rules + tests + CI) to prevent drift, parallel to but
    lighter than form-family enforcement (validate core required fields present; allow
    extras). Exact required-vs-optional field set = architect's design (informed by
    production frequencies: Summary 54, Test count 38, Files modified 27, Files created
    25, …), design-gate reviewed.
  - Forward-looking: a structured changelog is easier to eventually represent in a
    tracker (tracker itself out of scope).
- **Item 7 — Project-side no-mirror enforcement home (Part 6 Q8).** DECIDED
  (user, 2026-06-25): **(c) BOTH sides, in different repos.**
  - **Pack repo CI** — `validate-pack.py` (Python): NEW leg validating the shipped,
    empty `project-template/docs/project/` template (no mirror; correct sidecar
    vocabulary). Today validate-pack is pack-stream-scope-only (`:300-313` — project
    trees not loaded).
  - **Each client repo** — the client-side validator (today `validate-docs.sh`, bash,
    ships to clients): validates that client's POPULATED project (real entries + no
    reintroduced mirror).
  - Precisions: (i) different repos AND languages (Python vs bash) → the architect
    must keep the two consistent; (ii) different trees (empty template vs populated
    project); (iii) exact client-side file (extend `validate-docs.sh` vs a new
    validator) = architect's call; `validate-docs.sh:88` `_format.md` ref drops per
    Item Q4.
- **Item 8 — Form-family enforcement: schema-read approach (Part 6 Q9).** DECIDED
  (user, 2026-06-25): **runtime-PARSE `_rules.md` as the single schema SSOT — NO
  hardcoded duplicate.** Consistent with §1 (`_rules.md` = SSOT), Item 5 (single-SSOT),
  BD-185 SC-SER (determinism). Schema is declared in `_rules.md` in a **deterministic,
  machine-parseable form** (structured block, not prose); validators parse it at
  runtime (precedent: supporting-file admission parser `_lib.sh:198-260`).
  - **Mitigates the Item-7 drift risk:** both pack (Python) + client (bash) validators
    parse the SAME `_rules.md` SSOT → cannot diverge on the schema (only the parser is
    written twice, not the schema).
  - Remaining Q9 specifics (pack-side fixtures for the empty template; test/CI wiring +
    Check 42 symmetry) = architect-design (follows Item 7).

---

## 14. Design-gate decisions — architect gates G-1..G-10 (user, 2026-06-25)

The architect (reconciled design) surfaced 10 evidence-backed gates; the user decides each.

- **G-1 — non-entry "Phase Completion Checklist" content (Item-4 escalation).** DECIDED:
  **DROP.** The two `## Phase Completion Checklist` H2s in the OT gold are manual,
  mutating, per-phase completion dashboards whose functionality already exists in v11
  (per-entry `Status` field [SSOT] + `STATUS.md` dashboard [METHODOLOGY §191/1678] +
  `_index.md` execution order). User rationale: not useful + risks drifting out of sync
  with the official SSOT processes. The generalized form already ships, so nothing is
  generalized into the pack. **PRESERVED:** the second checklist's `### Execution order`
  ordering is captured into `_index.md` (Item 5 / G-3) — the manual diagram is dropped,
  but the order survives in the SSOT-derived index.
- **G-2 — changelog CORE REQUIRED field set (Item-6 "fuller").** DECIDED: **ACCEPTED**
  the architect's proposal — core required set `{Summary + Test count + ≥1 Files field}`
  for code-bearing entries + a machine-checkable DOC-ONLY exemption (Summary-only) keyed
  on heading-class OR zero-test-zero-files. Conformance-enforced per Items 6/7/8.
  - **NEW sub-requirement (user, 2026-06-25): a reasonable SIZE LIMIT on changelog
    entries** — they grow unbounded with too much detail and stop being summaries. The
    STANDARD (fixed max vs heuristic) is PENDING — the architect is being consulted to
    propose it (options + evidence from the gold's entry-size distribution + an
    evidence-based recommendation); the user decides; enforced by the same changelog
    conformance check.
  - **G-2b DECIDED (user, 2026-06-25): (a) the gold-safe pair.** Whole-entry cap
    **≤ 180 lines** + Summary cap **≤ 250 words** — both bounded above the gold max
    (130 lines / 243 words → 0 gold violations; no OT-fix / grandfather needed).
    Declared in the `changelog/_rules.md` SSOT (`entry-max-lines: 180`,
    `summary-max-words: 250`); enforced by the changelog conformance check (both repos,
    parse the SSOT, cheap, deterministic word/line counts; independent of the doc-only
    exemption). User chose gold-safe (a) over the tighter (b); noted (a) caps only
    future runaways and does NOT trim the gold's existing 200–243-word summaries.
- **G-3 — `_index.md` generation method (impl-plan).** DECIDED: **(A) derive-seed-then-
  hand-maintain, PLUS a MANDATORY validation script** (user, 2026-06-25). (A) handles the
  judgment-call ordering; the validation script enforces TWO hard properties:
  1. **Hard-dependency-order consistency** — where rule-based dependencies exist (from the
     per-entry `Blockers`/`Unblocks`/`Dependencies` SSOT), the `_index.md` serial order
     MUST respect them (a valid topological order; judgment is free ONLY where no hard dep
     constrains it).
  2. **Per-entry ↔ `_index.md` synchronization** — `_index.md` membership matches the tree's
     entry files exactly (no missing/extra; no drift — analogous to the `_toc.md`-in-sync
     check, Check 33).
  The `_index.md` validation joins the conformance enforcement (both repos, per Items 7/8).
  Architect/planner designs the script's implementation.
- **G-4 — splitter handling of the gold's backlog anchor.** DECIDED: **(A) superset regex** —
  the splitter accepts both `#### TD-NNN —` (H4, the gold) and `**TD-NNN —**` (bold-pair).
  User note: since OT is the only v10.x→v11 migration target in practice, the superset is
  overkill (H4-only would suffice for OT), but it costs nothing, works, and is future-safe.
  Accepted.
- **G-5 — per-entry backlog FILE internal anchor shape.** FRAMEWORK DECIDED (user,
  2026-06-25); the A-vs-B anchor choice is PENDING an architect tracker-relevance read.
  - **Deciding criterion = what's best for eventual issue-tracker support.** If the anchor
    shape (H4 vs bold-pair) is tracker-NEUTRAL (both fine), the user goes **(A) H4**.
  - **Pack/project symmetry is MOOT** as a criterion: real symmetry requires the PACK
    backlog tree to ALSO be form-family + per-entry + drift-enforced, which it is NOT
    today — so "(B) for symmetry" is a false symmetry. The project side is closer +
    enforced (per the user's requirements); there is no symmetry to preserve until the
    pack side is brought into compliance.
  - **Pack-side backlog compliance** (form-family structure + the workflows that maintain
    compliance / prevent drift) is **OUT OF SCOPE for BD-206 → v11.1** (a NEW BD or added
    to an existing v11.1 BD). NEEDS A TRACKED ANCHOR — open/assign a BD (user-approved).
  - **Blocker-check (user):** the project-side no-drift enforcement MUST be real, else
    BLOCKER. Pack-Chat confirms it IS in the design (see chat) → not a blocker.
  - Anchor A-vs-B: **DECIDED (B) bold-pair** `**TD-NNN — Title**` (user, 2026-06-25). The
    anchor is NOT tracker-neutral — the dormant tracker carrier (`tracker-migrate-forward.sh:408`
    `ENTRY_HEADER` regex) is bold-pair; H4 does not match it (empirically verified). Bold-pair
    is tracker-safe (zero carrier change), avoids the orphaned-H4-heading in a standalone file,
    and matches the pack-side. Coheres with G-4: the superset splitter ACCEPTS H4 input + EMITS
    bold-pair per-entry files (normalize-at-emit). Architect's original lean (A) flipped to (B)
    once the live tracker carrier was checked against the user's tracker-best criterion.
- **G-6 — schema-block grammar in `_rules.md`.** DECIDED: **(A) minimal `key: tokens` line
  grammar** (mirrors the existing `## Supporting files` parser, EE-1). Safest for the
  two-language (Python + bash) parser parity Item 8 mandates; a richer grammar is where two
  independent parsers drift.
- **G-7 — the 15 historical `_order.md` references.** DECIDED: **(A) leave them** as immutable
  audit history (NOT a BD-206 target). 0 operational refs (BD-214 already renamed them); the 15
  are in historical maintenance-docs (IMPL/review reports) — rewriting them would falsify the
  audit record, which the operating-docs-no-history rule (history docs keep their content)
  prohibits. The `_order`→`_index` sweep (Q6/Q10) is operationally a no-op.
- **G-8 — the now-dead `_MIGRATOR_FORCE_OVERWRITE_MIRROR` flag.** DECIDED: **(C) clean/scope it
  WITHIN BD-206** (not leave-inert, not defer). Rationale (user + rules): no-mirror makes the
  flag dead code for the converted streams; anti-deferral + "prefer deleting dead code" + it is
  small + logical-fit with the no-mirror migrator overhaul BD-206 already does. It is a
  `_MIGRATOR_*` core-internal var (NOT the frozen `MIGRATOR_*` surface), so cleaning it does not
  touch the frozen contract. Architect/coder MUST verify all call sites first (removal-ripple)
  before removing/scoping.
- **G-9 — confirm the §8 re-derived decision set.** DECIDED: **CONFIRMED** (user, 2026-06-25).
  The architect re-derived the content-less GC-N/CE-N labels into evidence-grounded decisions
  mapped to deliverables: §8.1 re-validations (Q5 remove `wi-kind`; Q6/Q10 sweep = no-op; D9 no
  allowlist [enum IS the bound]; Q4 = Check 72 + client conformance leg); §8.2 the GC/CE-cluster
  decisions (all consistent with Items 1-8 + the gates); §8.3 GC-2-2 = a separate BD-185
  pack-chat-only pass, NOT BD-206. These REPLACE the quarantined labels.
- **G-10 — immutable `_rules.md` behavior on an existing-project re-run.** DECIDED: **(A)
  force-overwrite** to the canonical pack version (user, 2026-06-25). Rationale (user): future
  pack upgrades won't always be next-version-only — the migrator must handle ANY-past-version →
  current; (A)'s always-install-the-current-canonical is robust to skipped-version upgrades
  (a version-naive assert-fail would break them).
  - **NEW launch-blocking BD candidate (user idea — OUT OF BD-206 SCOPE): a non-mutation
    integrity check.** A v11.0-shipped script that verifies all non-mutable (pack-shipped
    immutable) files against an embedded per-version CHECKSUM. Runnable anytime / before a
    version bump / as a CI test that goes RED on mutation — recovers (B)'s loud tampering signal
    while keeping (A). Optional stricter form: BAN committing the non-mutable files (pre-commit
    hook; force-overridable, but the checksum keeps failing). LAUNCH-BLOCKING (v11.0). NEEDS a
    tracked anchor (a new BD). Architect consulted (acceptable? recommended changes?) before the
    BD is opened.

---

## 15. Binding implementation requirements (user, 2026-06-26)

- **Sidecars done correctly.** The rebuilt project-side sidecars (`_rules.md` reauthored to the
  corrected model + the form-family schema; `_intro.md`; generated `_toc.md`; impl-plan
  `_index.md`; NO `_format.md`) must be correct per the design — not rushed for speed.
- **CI green ASAP — minimize the red window.** The foundational commit (Wave A / "Commit 0";
  Deliverable O8 / O8b / O8c) MUST be ATOMIC: rebuild the sidecars + update `init-project.sh`'s
  `_CLIENT_INSTALLED_FILES` (Check 41) + `cmd_update` (Check 39) + the S11 install/mirror-regen +
  eliminate `_format.md` — ALL in ONE commit — so the tree goes (and stays) GREEN at the first
  wave; the current 14 Check 39/41 failures clear at Wave A, never lingering red on a push. Do
  NOT push a bare sidecar-deletion (it would be red); the deletions land WITH their rebuild + fix
  in Wave A. Binding on the planner + the coder waves. (The remote is currently GREEN — nothing
  red is pushed; the local working-tree red is the uncommitted deletions only.)

---

## 16. Foundational requirements — standing evaluation lens (user, 2026-06-26)

The user reviewed the FINAL design ("seems ok"; NOT certain it is COMPLETE — completeness is
ITERATIVE: additional architect designs are added as needed as gaps surface, pass by pass).
These foundational requirements are the BINDING lens; EVERY agent pass (planner, coder,
reviewer, …) is checked against them, and a gap is grounds for an additional architect design:

1. **Guardrail-maintenance mechanisms** — the enforcement that keeps the form-family /
   no-mirror / sidecar-vocabulary guardrails in place AND prevents drift (rules + tests + CI,
   both repos).
2. **Freshness + accuracy mechanisms** — the trees + files stay fresh + accurate as they are
   updated/expanded (e.g. `_toc.md` regeneration; the `_index.md` validation; generated/derived
   views regenerate correctly and SSOT-derived artifacts stay in sync).
3. **File structure** — the per-entry tree shape + the 4-sidecar model, correct + consistent.
4. **Operational mechanics** — how PM Chat + agents create / maintain / use the entries works.
5. **Testing + integrity** — the test coverage + the integrity checks (incl. the BD-246
   non-mutation check) are present + sound.
6. **Ease of future tracker integration** — every choice keeps the eventual tracker migration
   easy (form-family mappability; the bold-pair carrier; the structured changelog; etc.).

ALL of (1)–(6) must be present. Handoff files now live at `~/Developer/_tmp/` (iCloud-synced,
not `/tmp`, not in the repo); the FINAL design is
`~/Developer/_tmp/pack-handoff-bd206-restart/ARCHITECTURE-BD-206-RESTART-FINAL.md`.
