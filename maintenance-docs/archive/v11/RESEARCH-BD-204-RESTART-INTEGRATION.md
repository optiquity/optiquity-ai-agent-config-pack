# RESEARCH-BD-204-RESTART-INTEGRATION — design-corpus map + LOCKED/OPEN classification + integration map + drafted BD-204 entry

> **Agent:** pack-docs-researcher. **Mode:** READ-ONLY (no source edits, no
> git verbs, no status flips, no design). **HEAD:** `ed47be4` (verified:
> `git rev-parse HEAD` → `ed47be4159c80fafe02bdc5ad3a4f8026004590e`).
> **Date:** 2026-06-05. **Branch:** `v11-dev`.
>
> **Why this doc exists.** BD-204 (pack self-migration Phase 2: per-entry
> tree → GH Issues, tracker Mode 2 → Mode 3) was attempted, FAILED, and was
> rolled back to zero because the design **ignored a foundational structural
> component — the GitHub Issue *form family*** (`work-item.yml` /
> `inbound.yml`; decisions D-4-V2 / D-16; rationale "validated input +
> structured roundtrip") that the entire tracker design was built on, and
> reinvented a base64/sidecar carrier instead. **The form family's design is
> LOCKED.** This is a READ-ONLY MAP + a DRAFT BD-204 entry for user review —
> NOT a design. It does not re-debate the forms, does not propose mechanisms,
> and surfaces (not resolves) the open mechanics.
>
> **The known failure mode (verified by memory #5,
> `feedback_verify_availability_not_just_existence.md`, lines 22–33):** an
> earlier BD-204 researcher recommended GH **Issue Fields** + custom **Issue
> Types** as a "go native" fork — but those are org-only + preview and the
> pack account is personal. This map excludes any non-GA / org-only capability
> from the design space (see §D-3 availability matrix).

---

## D-1 — Exhaustive design-corpus map

Every doc/asset/BD relevant to BD-204, with `file:line` and "what it is /
what it covers / where it lives." Reconciled three ways (see end of §D-1).
Ship-status legend: **[BUILT]** = code exists on disk; **[DESIGN]** =
architecture doc only; **[ASSET]** = live config/template on disk.

### D-1.A — The form family (LOCKED substrate) — capture precisely, do NOT critique

| Item | file:line | What it is / covers |
|---|---|---|
| `work-item.yml` | `.github/ISSUE_TEMPLATE/work-item.yml:1-106` **[ASSET]** | The pack-BD intake form. LIVE on disk (the as-shipped v11.0 form; note it has drifted from the V2 §4.2 spec — see "drift" note below). The structured carrier for BD fields. |
| `inbound.yml` | `.github/ISSUE_TEMPLATE/inbound.yml:1-77` **[ASSET]** | The external/upstream-feedback intake form (bug / feature-request / pack-feedback-*). |
| `config.yml` | `.github/ISSUE_TEMPLATE/config.yml:1-9` **[ASSET]** | `blank_issues_enabled: false` + `contact_links` → Discussions. Forces ALL intake through the two forms. |
| Form-family spec (design) | `ARCHITECTURE-V2.md:112-405` (§4 "Issue template schemas") **[DESIGN]** | The full form-family spec: §4.1 the two forms (lines 119-151), §4.2 `work-item.yml` fields (153-283), §4.3 `inbound.yml` fields (284-352), §4.4 field→METHODOLOGY mapping (353-359), §4.5 phase-epic system issue (361-380), §4.6 cross-tracker compat (382-405). |
| OQ-16 defense (design) | `ARCHITECTURE-V2.md:1693-2074` (§24) **[DESIGN]** | The defense of the form-family pattern (two composite forms, dropdown-driven) vs six-separate-files vs one-true-single-form, on token economy / API / search-sort-filter / cross-tracker portability / P2 maintenance / UX. |
| OQ-17 defense (design) | `ARCHITECTURE-V2.md:2075-2339` (§25) **[DESIGN]** | Structure-vs-free-text split: "structured iff a finite enum drives a label, sub-issue parent, or state transition; otherwise textarea." |
| OQ-18 resolution (design) | `ARCHITECTURE-V2.md:2340-2509` (§26) **[DESIGN]** | `template_version` placement = dual carrier (HTML comment + label). |
| D-4-V2 form-family extension | `ARCHITECTURE-V3.3-DELTA.md:308-382` (§6.1-§6.5) **[DESIGN]** | Form family reaffirmed + extended (phase-task-skeleton dropdown option; state/status mapping §6.3; identifier scheme §6.4; D-18 carrier matrix §6.5). |

**Form-family LOCKED representation (the fixed structured shape the BD-204
design MUST conform to — captured precisely, NOT critiqued):**

- **Two forms, one config.** `work-item.yml` (pack work) + `inbound.yml`
  (external/upstream) + `config.yml` (blank-issues banned).
- **`work-item.yml` fields (as-shipped, `.github/ISSUE_TEMPLATE/work-item.yml`):**
  - `wi-type` dropdown (line 16-24) — options: `bd` only (as-shipped);
    `labels:` key (lines 4-7) = `work-item`, `needs-triage`,
    `template:work-item-v11.0`. Type **required: true**.
  - `wi-kind` dropdown (25-38) — `feat / fix / refactor / docs / chore /
    infra` (METHODOLOGY Part 7 type). required: false.
  - `wi-status` dropdown (39-56) — `Open / Unblocked / Pending / In Progress
    / Resolved / Done / Deferred / Cancelled / Deprecated`; default 0 (Open);
    required: true.
  - `wi-blockers` textarea (57-64) — one issue id per line (BD-NNN, #N);
    chat resolves to first-class links/sub-issue parents.
  - `wi-unblocks` textarea (65-71) — informational; inverse of Blockers.
  - `wi-file-symbol` input (72-78) — affected path/symbol (free-form).
  - `wi-description` textarea (79-85).
  - `wi-context` textarea (86-92).
  - `wi-resolution` textarea (93-99) — filled when status flips to Resolved.
  - Trailing `markdown` block (100-106) emits the body comment trio:
    `<!-- pack-id: PENDING -->`, `<!-- template_version: work-item-v11.0 -->`,
    `<!-- pack-version: v11 -->`.
- **`inbound.yml` fields (as-shipped):** `in-category` dropdown (15-29:
  `bug / feature-request / pack-feedback-{workflow,prompt,agent-perf,friction,open-question}`,
  required); `in-pack-version` input (30-37); `in-project-id` input (38-44);
  `in-observation` textarea (45-51, required); `in-context` textarea (52-58);
  `in-expected` textarea (59-64); `in-actual` textarea (65-70); body comment
  trio (71-77).
- **Type/Category dropdown → label mapping** (design spec
  `ARCHITECTURE-V2.md:264-282` for work-item; `:342-351` for inbound): the
  dropdown pick drives the auto-routing label set at intake; the chat
  specializes `template:work-item-v11.0` → `template:bd-v11.0` at triage.
- **State/status mapping** (`ARCHITECTURE-V3.3-DELTA.md:341-358`, §6.3): the
  authoritative flat-file `Status:` ↔ tracker (GH state + `status:*` label)
  table — e.g. `Resolved` → closed + `state_reason: completed` +
  `status:resolved`; `Cancelled`/`Deprecated` → closed + `not_planned` + label.
- **Identifier round-trip carrier** (`ARCHITECTURE-V3.3-DELTA.md:360-369`,
  §6.4): BD-NNN identity = title prefix + `<!-- pack-id: BD-NNN -->` body
  marker. Survives round-trip per V1 §6.0.

> **DRIFT NOTE (surface, do NOT fix — `scope-deliverables-to-the-ask`):** the
> as-shipped `work-item.yml` differs from the V2 §4.2 spec. As-shipped
> `wi-type` has ONLY `bd` (V2 §4.2:166-169 specced `bd`/`td`/`phase-epic-skeleton`);
> as-shipped drops `wi-td-scope`/`wi-td-severity`/`wi-phase-number`;
> as-shipped `template_version` value is `work-item-v11.0` (V2 specced
> `v11.0.0/work-item`). This is because the LIVE pack form is PACK-ONLY (BD
> intake only — there is no TD/phase on the pack side), so it was pruned to
> the pack surface. **This is a fact for the architect to reconcile (which
> shape is canonical for BD-204's pack migration), NOT a defect to fix here.**

### D-1.B — The tracker feature design + build

**Design docs (the layered V1 → V2 → V3 → V3.x corpus):**

| Doc | file:line | What it is / covers |
|---|---|---|
| `DESIGN-BRIEF.md` | `maintenance-docs/v11-research/DESIGN-BRIEF.md:1-333` **[DESIGN]** | The scoping contract the architecture is checked against. §1 hard exclusions (20-27); §3 goals incl. §3.1 mandatory-reverse + `template_version` (57-72); §5 surface map; §6.3 tracker abstraction floors (244-252); §6.4 tracker eligibility (254-261); §7 open questions OQ-16/17/18/19/20 (273-311). |
| `ARCHITECTURE.md` (V1) | `maintenance-docs/v11-research/ARCHITECTURE.md` **[DESIGN]** | The V1 base. Preserved-by-reference under V2/V3. §2 provider abstraction (18 ops); §3 config/detection/trinity; §4 (six forms — SUPERSEDED by D-4-V2); §5 dependency model; §6 migration algorithm incl. §6.5 reverse + §6.6 sidecar + §6.7 round-trip; §8 agent reads; §9 failure UX. (V3 §0.5 lists which V1/V2 sections stand verbatim.) |
| `ARCHITECTURE-V2.md` | `maintenance-docs/v11-research/ARCHITECTURE-V2.md:1-2598` **[DESIGN]** | Adds P1-P6 priorities; §4 form family (replaces V1 §4); §16 decisions D-1..D-18 (445-473); §24/§25/§26 OQ-16/17/18 defenses. |
| `ARCHITECTURE-V3.md` | `maintenance-docs/v11-research/ARCHITECTURE-V3.md:1-3095` **[DESIGN]** | Delta on V2. §0 change-log (34-108); §16 decision table D-1..D-20 with V3-status column (152-184) — the LOCKED-decision index; §0.5 sections-preserved-verbatim (68-92); §0.6 things-V3-does-NOT-change incl. the form-family choice D-4-V2 (94-108); §27/§28 P6/OQ-19/OQ-20; §A.2 modified artifacts. |
| `ARCHITECTURE-V3.1-DELTA.md` | `maintenance-docs/v11-research/ARCHITECTURE-V3.1-DELTA.md:180-252` (§3) **[DESIGN]** | The sidecar `extra_fields` mechanism (DELTA A2): extends V1 §6.6 sidecar to carry `template_version` + `extra_fields` + `template_archive_path` for v11.x fields the v10 grammar cannot represent. The byte-loss backstop. §6.6.1 round-trip behavior (forward→reverse→forward byte-equiv on tracker side). |
| `ARCHITECTURE-V3.3-DELTA.md` | `maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md:185-497` (§4-§6) **[DESIGN]** | §4 forward/reverse/round-trip mechanics for phase tasks; §5 cross-entity dependencies (uniform `blocked-by` model); §6 templates + dependency fields (§6.1 D-4-V2 reaffirmed+extended; §6.3 status mapping; §6.4 identifier carrier; §6.5 D-18 carrier matrix; §6.R sidecar `dependency_edges`). |
| `ARCHITECTURE-V3.3-DELTA-ADDENDUM-1.md` | `maintenance-docs/v11-implementation/ARCHITECTURE-V3.3-DELTA-ADDENDUM-1.md:1-680` **[DESIGN]** | Formalises the §6.R sidecar `dependency_edges` per-task shape (kind/target/annotation); §A.3 composition with V1/V3/V3.3 invariants (bidirectionality, sidecar-only enrichment, round-trip safety). |

**Implementing BDs (all `Status: Resolved` — verified `backlog/BD-NNN.md`):**

| BD | file | What it built |
|---|---|---|
| BD-060 | `backlog/BD-060.md` | TrackerProvider abstraction skeleton + GH backend (the 18-op provider surface, capability flags, error model). |
| BD-061 | `backlog/BD-061.md` | `tracker.toml` schema + detection helper + gitignore entry. |
| BD-065 | `backlog/BD-065.md` | `tracker-migrate.sh forward` + idempotency markers + checkpoint. |
| BD-067 | `backlog/BD-067.md` | `tracker-migrate.sh reverse` + sidecar (V1 §6.6 + §6.6.1 A2). Reverse 9-step orchestrator + per-entry reconstruction; sidecar with `extra_fields`/`template_version`/`template_archive_path` (empty at v11.0). `pack tracker disable` + `doctor` wired. |
| BD-068 | `backlog/BD-068.md` | Round-trip test fixture + multi-template-version coverage. |
| BD-111 | `backlog/BD-111.md` | Switch blocks/blocked-by from comment-marker to first-class GH dependency API (`addBlockedBy`/`removeBlockedBy`/`getBlockedBy`). Blocker carried: "Live GH repo access" (the round-trip assertion needs a live repo). |
| BD-129 | `backlog/BD-129.md` | Tracker libs pass `--repo` to all gh invocations. |
| BD-130 | `backlog/BD-130.md` | Wire `tracker_doctor_run` so `pack tracker doctor` works. |
| BD-131 | `backlog/BD-131.md` | Set `forward_complete = true` at end of clean forward migration. |
| BD-132 | `backlog/BD-132.md` | BLOCKER: tracker disable/init close-step race destroyed ~33% of BACKLOG entries (a data-loss bug — directly relevant to BD-204's lossless requirement). |
| BD-133 | `backlog/BD-133.md` | Reverse migration preserves BACKLOG.md header preamble (the header-snapshot mechanism BD-203 §3.7 ratification point #5 re-maps to `_intro.md`). |
| BD-134 | `backlog/BD-134.md` | Tracker forward close retry-with-backoff (eliminate ~5% partial-write rate). |

**Built tracker libs (`scripts/lib/tracker-*.sh` — all [BUILT], on disk):**

| Lib | Role (from header comment) |
|---|---|
| `scripts/lib/tracker-provider.sh` + `tracker-provider-gh.sh` | The provider abstraction + GH backend (BD-060). |
| `scripts/lib/tracker-config.sh` | `tracker.toml` read/write + mode detection (BD-061). |
| `scripts/lib/tracker-migrate-forward.sh` | Forward (flat-file → tracker); 11-step algorithm, idempotent, checkpoint (BD-065). **Writes the monolith mirror at step 10 — the BD-203 collision.** |
| `scripts/lib/tracker-migrate-reverse.sh` | Reverse (tracker → flat-file); 9-step reconstruction (BD-067). **`_tmr_emit_backlog` WRITES `pack-ops/BACKLOG.md` on the pack-surface branch — the BD-203 §3.7 collision; must emit the per-entry TREE under no-mirror.** |
| `scripts/lib/tracker-sidecar.sh` | Reverse sidecar emitter (BD-067); `extra_fields`/`template_version`/`template_archive_path` + `dependency_edges` (BD-106). |
| `scripts/lib/tracker-mirror.sh` | Shared mirror-header helper (forward+reverse share it) (BD-067). |
| `scripts/lib/tracker-labels.sh` | Label family (status/template/scope/severity). |
| `scripts/lib/tracker-links.sh` | First-class link (blocks/blocked-by) + sub-issue. |
| `scripts/lib/tracker-agent-read.sh` | Agent read path (LCD `gh`). **Reads the monolith — BD-203 §3.5 dormant-in-flat-file, BD-204 repoints.** |
| `scripts/lib/tracker-doctor.sh` | `pack tracker doctor` mapping-integrity report. |
| `scripts/lib/tracker-header-snapshot.sh` | Monolith header preservation (BD-133). **No-mirror re-maps to `_intro.md`.** |
| `tracker-init.sh`, `tracker-promote.sh`, `tracker-cycle-check.sh`, `tracker-errors.sh`, `tracker-phase-task.sh` | Init, TD-promotion, dependency-cycle detection, typed errors, phase-task (project-side, mostly). |

### D-1.C — BD-203's per-entry design + standard

| Item | file:line | What it is / covers |
|---|---|---|
| `ARCHITECTURE-BD-203-V3.md` | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-203-V3.md:1-413` **[DESIGN]** | The shared per-entry engine co-design + the PACK conversion (no-mirror, preserve-all, reversible). §2 the shared engine (decompose + toc; mirror-generate retired §2.4); §2.6 the `_rules.md` contracts; **§3.7 the reverse tracker INTERFACE + Mode-3 reconciliation (the explicit BD-204 hand-off, lines 244-272)**; §4 validator changes; §5 the entry-count oracle; **§7 the BD-204 second-pass hand-off (349-357).** |
| `ARCHITECTURE-BD-203-V3-AMENDMENT.md` | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-203-V3-AMENDMENT.md:1-226` **[DESIGN]** | Pre-normalize the monolith; convert BD-001..019 to full entries (209-entry final count); **§F the D1 doc-governance standard (175-184) — `_rules.md` SOLE rules source, `_intro.md` human-only, audience+purpose headers**; §G reconciliation table; admits `Unblocked` as canonical state (D2). |
| `ARCHITECTURE-BD-203.md` + `-ADVERSARIAL.md` | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-203.md`, `...-ADVERSARIAL.md` **[DESIGN]** | The first BD-203 architect pass + the adversarial re-design that corrected the miscount (185 vs true 189/190) and the gitignored-pool gap. Context for the no-mirror decision lineage. |
| `RESEARCH-BD-203-BLAST-RADIUS.md` | `maintenance-docs/v11-implementation/RESEARCH-BD-203-BLAST-RADIUS.md` **[DESIGN]** | The exhaustive blast-radius enumeration that preceded the BD-203 architect (the `researcher-maps-blast-radius` exemplar). |
| `PLAN-BD-203.md` + `PLAN-BD-203-C2-COMPLETION.md` | `maintenance-docs/v11-implementation/PLAN-BD-203*.md` **[DESIGN]** | The per-commit plan. |
| No-mirror standard (landed) | `backlog/_rules.md:18-26` ("Source of truth — no mirror") + `CLAUDE.md:465-483` (`## Pack memory` "Per-entry trees — sole SSOT (pack: no mirror)") **[ASSET]** | The landed standard: the `/backlog/` + `/changelog/` per-entry trees + `_toc.md` are the SOLE SSOT + readable form; **no monolithic mirror**; BD-203 deleted `pack-ops/BACKLOG.md` + `CHANGELOG.md`. In tracker mode the tracker is SSOT and the tree is regenerated-FROM-tracker per the Mode 2→3 contract. |
| Shared per-entry engine (built) | `scripts/lib/per-entry/_lib.sh` (+ `decompose.sh`, `toc-regenerate.sh`, `mirror-generate.sh`) **[BUILT]** | The engine. `_lib.sh:1-90` carries the BD-203 no-mirror model header + the 5-stream shape table (pack-backlog entry regex `^BD-[0-9]+[a-z]*\.md$`, support `_rules.md _intro.md _toc.md`, mirror `pack-ops/BACKLOG.md` retained as constant only). `decompose.sh` = the monolith→tree conversion (one-time). `toc-regenerate.sh` = the `_toc.md` index (the no-mirror readable index). `mirror-generate.sh` = retired-for-pack, kept for project streams pending BD-206. |
| `_rules.md` / `_toc.md` / `_intro.md` sidecar pattern | `backlog/_rules.md:1-86`, `backlog/_toc.md`, `backlog/_intro.md`; `changelog/_rules.md`, `changelog/_toc.md` **[ASSET]** | The per-entry directory's supporting-file pattern. `_rules.md` = SOLE rules contract (filename regex, lifecycle states incl. `Unblocked`, ID-extraction rule, write-authority). `_toc.md` = generated index (DO NOT EDIT). `_intro.md` = human-only orientation (zero rules). Per-entry file line-1 = HTML-comment back-pointer (`<!-- per-entry source: /backlog/BD-NNN.md; contract: /backlog/_rules.md -->`). |

### D-1 reconciliation (3 independent ways — completeness check)

The failure was a MISSING foundational piece, so the corpus is reconciled
three ways to ensure nothing is missed:

1. **By the V3 §0.5 "preserved verbatim" list** (`ARCHITECTURE-V3.md:68-92`):
   names §1-§15, §18-§22, §24-§26 as standing V2 content. ALL accounted for
   in D-1.A/B (form family = §4/§24/§25/§26; provider = §2; migration =
   §6; sidecar = §6.6). ✔
2. **By the V3 §16 decision table** (`ARCHITECTURE-V3.md:160-180`): D-1..D-20.
   Every decision maps to a D-1 corpus doc (provider=D-1; tracker.toml=D-2/D-5;
   migrate script=D-3; **form family=D-4-V2/D-16**; trinity table=D-6; failure
   UX=D-7; **reverse+sidecar=D-8**; agent reads=D-9; structure split=D-17;
   template_version=D-18; recommendation=D-19; help=D-20). ALL classified in
   §D-2. ✔
3. **By the on-disk asset/lib inventory** (`ls .github/ISSUE_TEMPLATE/`,
   `ls scripts/lib/tracker-*`, `ls scripts/lib/per-entry/`): 3 form-family
   assets + 17 tracker libs + 4 per-entry engine files + 12 implementing BDs.
   Every disk artifact maps to a design doc in D-1.B/C. ✔

**Reconciliation result:** the form family (the piece BD-204 missed) is
present in ALL THREE reconciliations as a first-class, decision-backed
(D-4-V2/D-16), reaffirmed-in-V3, on-disk substrate. **Nothing beyond the
starter list surfaced as un-mapped**; the one notable addition is the
**as-shipped-vs-V2-spec form drift** (D-1.A DRIFT NOTE) — a reconciliation
the architect owns, not a gap.

---

## D-2 — LOCK STATUS of every GH-Issues design decision (verbatim evidence)

Each decision sorted into LOCKED / OPEN / UNMARKED with the exact quote +
`file:line`. The form family is the KNOWN locked exemplar; the point is to
surface ALL the others.

### D-2.1 — LOCKED (do NOT reopen)

Doc language shows an explicit user decision, "reaffirmed in V3," "hard
exclusion not subject to architect debate," or a resolved/ratified OQ.

| ID | Lock signal (verbatim quote) | file:line |
|---|---|---|
| **DESIGN-BRIEF §1 hard exclusions** | "## 1. Out of scope (**hard exclusions, not subject to architect debate**)" — incl. desktop/web surfaces, `/install-github-app`, forced migration, required tracker, v10-non-opt-in. | `DESIGN-BRIEF.md:20` |
| **D-1** Provider surface | "**reaffirmed in V3** \| Provider surface = the 18 ops in V1 §2.1 with `Issue` shape, capability flags, error model, pagination contract." | `ARCHITECTURE-V3.md:160` |
| **D-2** `tracker.toml` | "**reaffirmed in V3** \| Tracker config = single `tracker.toml` per surface." | `ARCHITECTURE-V3.md:161` |
| **D-3** Migrate script surface | "**reaffirmed in V3** \| Migration command surface = bash script `scripts/tracker-migrate.sh forward / reverse / status / doctor`." | `ARCHITECTURE-V3.md:162` |
| **D-4-V2** FORM FAMILY (the LOCKED exemplar) | "**reaffirmed in V3** \| Two forms: `work-item.yml` and `inbound.yml`, each with a Type/Category dropdown driving labels. \| Per OQ-16 defense (§24). The revised P6 does not reach into intake-form shape; the form family carries forward." | `ARCHITECTURE-V3.md:164` |
| **D-4-V2** (also, V3 §0.6 explicit non-change) | "The form-family choice (D-4-V2). The revised P6 does not reach into intake-form design." (listed under "Things V3 deliberately does not change") | `ARCHITECTURE-V3.md:105` |
| **D-5** Mode detection | "**reaffirmed in V3** \| Mode detection = presence and content of `tracker.toml`." | `ARCHITECTURE-V3.md:165` |
| **D-6** Trinity Document-locations table | "**reaffirmed in V3** \| Trinity `## Document locations` table gains a Source column." | `ARCHITECTURE-V3.md:166` |
| **D-7** Failure-mode UX | "**reaffirmed in V3** \| Failure-mode UX = typed error codes, no silent retry, mirror as fallback when fresh, message shapes in V1 §9." | `ARCHITECTURE-V3.md:167` |
| **D-8** Reverse migration + sidecar | "**reaffirmed in V3** \| Reverse migration = same script, also triggered by `pack tracker disable`. Sidecar for tracker-only data." | `ARCHITECTURE-V3.md:168` |
| **D-9** Agent reads = LCD gh | "**reaffirmed in V3** \| Agent reads = LCD `gh` shell-out universal; MCP per-CLI optional." | `ARCHITECTURE-V3.md:169` |
| **D-10** Auth = single gh auth | "**reaffirmed in V3** \| Auth = single `gh auth` per machine." | `ARCHITECTURE-V3.md:170` |
| **D-11** PACK-FEEDBACK upstream | "**reaffirmed in V3** \| PACK-FEEDBACK upstream mechanism." | `ARCHITECTURE-V3.md:171` |
| **D-12** Pre-existing tracker deferred | "**reaffirmed in V3** \| Pre-existing tracker integration deferred." | `ARCHITECTURE-V3.md:172` |
| **D-13** License interaction = none new | "**reaffirmed in V3** \| License interaction = none new in v11." | `ARCHITECTURE-V3.md:173` |
| **D-14** External-issue triage | "**reaffirmed in V3** \| External-issue triage via `needs-triage` + Pack Chat triage queue." | `ARCHITECTURE-V3.md:174` |
| **D-15** Token measurement | "**reaffirmed in V3** \| Token measurement = post-shipping side-effect verification." | `ARCHITECTURE-V3.md:175` |
| **D-16** Multi-template strategy = form family | "**reaffirmed in V3** \| Multi-template strategy = form-family pattern." | `ARCHITECTURE-V3.md:176` |
| **D-17** Structure-vs-free-text split | "**reaffirmed in V3** \| Structure-vs-free-text split." | `ARCHITECTURE-V3.md:177` |
| **D-18** template_version dual carrier | "**reaffirmed in V3** \| `template_version` placement = dual carrier (HTML comment + label)." | `ARCHITECTURE-V3.md:178` |
| **D-19** Recommendation signals/thresholds | "**new (V3)** \| Inflection-point signals and thresholds." (a resolved, dated 2026-05-04 decision) | `ARCHITECTURE-V3.md:179` |
| **D-20** Help-verb scope/naming | "**new (V3)** \| Help-verb scope, naming, and per-surface content split." (resolved, dated 2026-05-04) | `ARCHITECTURE-V3.md:180` |
| **DELTA A2** sidecar `extra_fields` | "**Pick: A2** (extend V1 §6.6 sidecar coverage to include `template_version` and any v11.x-introduced fields...)" — a picked, ratified decision; §4 confirms "D-1..D-20 reopened? No." | `ARCHITECTURE-V3.1-DELTA.md:182`, `:258` |
| **V3.3 §6.1** D-4-V2 reaffirmed+extended | "### §6.1 Form-family templates (**D-4-V2 reaffirmed and extended**)" | `ARCHITECTURE-V3.3-DELTA.md:310` |
| **V3.3 §2.5** D-4-V2 extension reaffirmed | "### §2.5 D-4-V2 extension reaffirmed" | `ARCHITECTURE-V3.3-DELTA.md:87` |
| **BD-203 D1 doc-governance** | "`_rules.md` is the SOLE rules source for its directory." + "`_intro.md` is HUMAN-ONLY; agents may ignore it." (folded-in standard, BD-206 inherits) | `ARCHITECTURE-BD-203-V3-AMENDMENT.md:179-180` |
| **BD-203 no-mirror standard** | "The per-entry tree at `/backlog/` (plus its generated `/backlog/_toc.md` index) is the **SOLE source of truth and readable form**... **There is no monolithic mirror.**" | `backlog/_rules.md:20-23` |
| **BD-203 Unblocked canonical state** | "§2.5 Unblocked (was 'surface to user') \| DECIDED per D2: ADMIT as canonical lifecycle state" | `ARCHITECTURE-BD-203-V3-AMENDMENT.md:195` |

**Critical for BD-204:** The form family (D-4-V2 / D-16), the sidecar
(D-8 / DELTA A2), the structure split (D-17), the template_version dual
carrier (D-18), the identifier carrier (V3.3 §6.4), the status mapping
(V3.3 §6.3), the no-mirror standard, and the D1 doc-governance standard are
ALL LOCKED. **BD-204 builds ON these — it does not re-debate, re-evaluate, or
reinvent any of them** (reinventing the form carrier as base64/sidecar is the
exact failure that triggered the rollback).

### D-2.2 — OPEN for redesign

Doc language shows an unresolved item, "the architect may revise," an open
ratify/nudge intersection, or a flat-file→tracker collision point BD-204 must
wire. **NOTE the scope boundary:** the OPEN items below are the MECHANICS OF
WIRING the locked substrate into Mode 3 — NOT whether to use the forms/sidecar.

| Item | OPEN signal (verbatim quote) | file:line |
|---|---|---|
| **BD-203 §3.7 RATIFY/NUDGE intersection points** (the core BD-204 OPEN set) | "**BD-204 RATIFICATION/NUDGE INTERSECTION POINTS (explicitly marked — do not over-commit internals now):** 1. [RATIFY] per-entry emit target shape... 2. [RATIFY] the ID round-trip carrier... 3. [NUDGE] the Mode-3 `_toc.md` regeneration trigger... 4. [RATIFY] the BD-204 entry's 'tree regenerated-FROM-tracker' clause... 5. [RATIFY] header-snapshot under no-mirror..." | `ARCHITECTURE-BD-203-V3.md:263-268` |
| **BD-204 second-pass hand-off list** | "**BD-204 second-pass hand-off — what it RATIFIES or NUDGES (§3.7):**" (5 items) "Plus the §3.5 deferred tracker-lib runtime repoints (dormant in flat-file mode; BD-204 wires + tests them)." | `ARCHITECTURE-BD-203-V3.md:349-355` |
| **Reverse emit target (the monolith→tree collision)** | "`tracker-migrate-reverse.sh:1059-1060` WRITES `pack-ops/BACKLOG.md` (the monolith) on the pack-surface branch... Under no-mirror the reverse path must emit the per-entry TREE." | `ARCHITECTURE-BD-203-V3.md:246` |
| **Deferred tracker-lib runtime repoints** | "BD-203 corrects their WRONG-MODEL COMMENTS... but defers the runtime repoint to BD-204, where it is testable. This is a LOGICAL-FIT deferral... the repoint cannot be tested until the tracker is exercised on the per-entry tree, which is BD-204's scope." | `ARCHITECTURE-BD-203-V3.md:232` |
| **BD-204 entry's own RATIFY-or-NUDGE instruction** | "when BD-204 BEGINS, run a SECOND design pass to RATIFY (confirm good) or NUDGE that tracker-reverse design — compatible with the landed BD-203 work + correct for BD-204 — at the marked intersection points" | `backlog/BD-204.md:9` |
| **OQ-16 form-revision latitude (NOTE: already CLOSED to D-4-V2 — latitude was historical)** | "The architect may revise D-4 if the defense leads there." — this was the OQ-16 *original* latitude; it RESOLVED to D-4-V2 (LOCKED). Quoted here only to show the latitude is SPENT, not still open. | `DESIGN-BRIEF.md:292` |
| **OQ-17 structure-revision latitude (also SPENT → D-17 LOCKED)** | "The architect may revise structure choices from V1 if priorities... warrant." — resolved to D-17 (LOCKED). Latitude spent. | `DESIGN-BRIEF.md:293` |

**The genuinely-OPEN BD-204 set, distilled (mechanics only):**
1. **[RATIFY]** per-entry emit target shape — direct per-entry write vs
   round-trip through a transient monolith. (BD-203 recommends direct write.)
2. **[RATIFY]** the ID round-trip carrier — how `BD-NNN[b]` + parenthetical
   title survives as a GH Issue field (depends on the BD-204-built forward
   schema; designed: ID in a stable parseable position, NOT inferred from
   title prose).
3. **[NUDGE]** the Mode-3 `_toc.md` regeneration trigger cadence — every
   reverse vs only reverse-to-flat-file.
4. **[RATIFY]** the "tree regenerated-FROM-tracker" clause = tree (not
   monolith) target.
5. **[RATIFY]** header-snapshot under no-mirror = `_intro.md` replaces the
   monolith header snapshot (BD-133's mechanism re-maps).
6. **[WIRE+TEST]** the deferred tracker-lib runtime repoints
   (`tracker-migrate-reverse.sh` `_tmr_emit_backlog`, `tracker-agent-read.sh`,
   `tracker-doctor.sh`, `tracker-header-snapshot.sh`, `tracker-migrate-forward.sh`)
   from monolith → per-entry tree, pack-surface branch only.

### D-2.3 — UNMARKED (no clear lock-or-open signal — flag for user/architect)

Items in the corpus that carry NEITHER a clean lock signal NOR a clean open
signal for the BD-204 context. Do NOT assume either way.

| Item | Why UNMARKED | file:line |
|---|---|---|
| **As-shipped `work-item.yml` vs V2 §4.2 spec drift** | The LIVE form (`bd`-only `wi-type`, no TD/phase fields, `template_version: work-item-v11.0`) differs from the V2 §4.2 spec (`bd/td/phase-epic-skeleton`, `v11.0.0/work-item`). No doc states which is canonical for the pack's OWN Mode-3 migration. The form family PATTERN is LOCKED; the as-shipped vs spec field-set for the pack surface is UNMARKED. | `.github/ISSUE_TEMPLATE/work-item.yml:16-24` vs `ARCHITECTURE-V2.md:166-209` |
| **BD-111 "Live GH repo access" blocker for round-trip proof** | BD-111 (first-class `blocked-by` API) is Resolved but its round-trip assertion carried a "Live GH repo access" blocker. Whether BD-204's lossless-round-trip audit needs a live personal repo provisioned (per `test-infra-self-provisioned`) is implied but not explicitly stated as BD-204's gate. | `backlog/BD-111.md:4-5` |
| **V3 §A.2 modified-artifacts that Mode-3 must touch** | `PACK-CHAT.md` recommendation routing, `pack-startup` Step 8, validate-pack Checks 21-24, `init-project.sh` help-surface install. These are DESIGN-stated as modified, but whether BD-204 (pack Mode-3 only) touches them vs they were already landed is UNMARKED — needs a measure-then-bound check at architect time. | `ARCHITECTURE-V3.md:1715-1751` |
| **BD-132 data-loss class (close-step race) under the per-entry tree** | BD-132 fixed a ~33% entry-destruction race in disable/init. Whether the per-entry emit target re-introduces or avoids that class is not analyzed in the BD-203 §3.7 design (it predates the tree target). Flag for the architect's lossless-audit. | `backlog/BD-132.md` |

**UNMARKED handling:** none of these is assumed locked or open. They are
flagged so the architect (and the user at the pre-architect gate) decides
each explicitly — consistent with the rule that surfaced this whole restart
(a missed/unclassified foundational piece is THE failure mode).

---

## D-3 — The integration map ("how it all comes together")

**The form family is LOCKED — the canonical structured representation, full
stop.** Everything else integrates AROUND it. The open questions for the
architect are STRICTLY the mechanics of combining the locked forms + the
sidecar for byte-losslessness, and the edit/sync workflow — NEVER whether to
use the forms or how to restructure them.

### D-3.0 — External-capability availability matrix (GA + personal-account)

Per memory #5 (`verify-availability-not-just-existence`), the design space
contains ONLY GA + personal-account-available capabilities. The pack repo's
account is **personal** (verified: `git remote -v` →
`https://github.com/DShaneNYC/optiquity-ai-agent-config-pack.git`; `DShaneNYC`
is an individual/personal account).

| Capability | GA? | Personal account? | In BD-204 design space? | Evidence |
|---|---|---|---|---|
| **GH Issue Forms** (`.github/ISSUE_TEMPLATE/*.yml`) — the LOCKED form-family substrate | YES (GA on GitHub.com) | YES ("create default issue... templates for your organization **or personal account**") | **YES — REQUIRED substrate** | GitHub Docs "Configuring issue templates" / "Syntax for issue forms" (see Sources) |
| **GH Issue Dependencies** (blocked-by / blocking) — the BD-111 first-class link substrate | YES (GA 2025-08-21) | YES ("available for users on GitHub **Free**, GitHub Pro, Team, Enterprise Cloud") | **YES — usable for Blockers/Unblocks links** | GitHub Changelog "Dependencies on issues" 2025-08-21 (see Sources) |
| **GH Sub-issues** (parent/child, 8 deep, 100/parent) — phase/hierarchy substrate (project-side; pack BDs are L1-flat) | YES (GA) | YES (account-agnostic) | **YES (pack uses it minimally — BDs are flat L1)** | GitHub Docs "Adding sub-issues"; GA announcement (see Sources) |
| **GH Issue Fields** (custom typed fields) | NO (still preview) | NO (org-only) | **NO — EXCLUDED** (this is the exact phantom the prior researcher fell for; memory #5) | memory #5 lines 22-33; org-only + preview |
| **GH custom Issue Types** | partial GA | NO (org-only) | **NO — EXCLUDED for the personal pack account** | memory #5 lines 22-33 |

**Conclusion:** the LOCKED substrate (Issue Forms + Issue Dependencies +
Sub-issues) is fully GA + personal-account-usable. NO "go-native via Issue
Fields / Issue Types" fork enters the design — it is org-only/preview and OUT.
The structured-field carrier is the **form-family body + labels + the sidecar**
(the locked D-4-V2 / D-8 / DELTA A2 mechanism), NOT a custom-field-typed issue.

### D-3.1 — How each piece integrates AROUND the locked forms

```
  PER-ENTRY TREE (BD-203, no-mirror SSOT in Mode 2)
        /backlog/BD-NNN.md  (+ _toc.md, _rules.md, _intro.md)
                    │
   FORWARD (Mode 2 → Mode 3)         REVERSE (Mode 3 → Mode 2)
   tracker-migrate-forward.sh        tracker-migrate-reverse.sh
                    │                            ▲
                    ▼                            │
   ┌─────────────────────────────────────────────────────────┐
   │   GH ISSUES (Mode 3 SSOT)                                │
   │   ── carried by the LOCKED FORM FAMILY ──                │
   │   • work-item.yml fields  → structured BD fields         │
   │     (Type/Kind/Status dropdowns → labels;                │
   │      Blockers/Unblocks/Description/Context/Resolution     │
   │      → body sections + first-class blocked-by links)     │
   │   • <!-- pack-id: BD-NNN --> body marker → ID carrier    │
   │   • template_version dual carrier (comment + label)      │
   │   • status mapping (V3.3 §6.3): Status ↔ state+label     │
   │                                                          │
   │   SIDECAR (.pack-tracker/reverse.sidecar.<date>.md)      │
   │   • extra_fields  → pack fields beyond the forms        │
   │   • template_version / template_archive_path            │
   │   • dependency_edges (kind/target/annotation)           │
   │   • byte-loss backstop for anything v10-grammar /       │
   │     form-field set cannot represent                     │
   └─────────────────────────────────────────────────────────┘
```

**Integration roles (each AROUND the locked form):**

- **Form fields carry the structured BD fields.** The `work-item.yml`
  dropdowns/textareas ARE the structured representation. Type/Kind/Status →
  labels (the routing + state machine); Blockers → first-class `blocked-by`
  links (BD-111); Description/Context/File-Symbol/Resolution → body sections.
  (LOCKED: D-4-V2, D-17, V3.3 §6.3.)
- **The body-comment marker carries the ID.** `<!-- pack-id: BD-NNN -->` is
  the round-trip key (V3.3 §6.4). The `BD-NNN[b]` suffix + the
  `BD-195 (Code Red 3)` parenthetical MUST survive in a stable parseable
  position — NOT inferred from title prose (BD-203 §3.7 RATIFY #2).
- **The sidecar carries the overflow + byte-loss backstop.** Any pack field
  beyond the form-field set, any v11.x-introduced field, and any
  tracker-only data go to `extra_fields` / `template_version` /
  `dependency_edges` (LOCKED: D-8, DELTA A2, V3.3 §6.R). **This is where the
  prior BD-204 went wrong — it reinvented a base64/sidecar carrier INSTEAD OF
  the forms; the correct model is forms-as-primary + sidecar-as-overflow.**
- **The per-entry tree is the Mode-2 SSOT and the reverse target.** Forward
  reads the tree → creates Issues via the forms' field shape. Reverse
  reconstructs in-memory entries → writes the per-entry tree DIRECTLY (NOT a
  monolith), then regenerates `_toc.md` (BD-203 §3.7; LOCKED no-mirror).
- **The lossless round-trip** = tree → Issues (forms) → tree == original. The
  silent-data-loss guard (`tracker-migrate-reverse.sh:1035-1042`) FAILS rather
  than drops; it now guards the per-entry emit (BD-203 §3.7).
- **Edit/sync + sync-or-fail.** In Mode 3 the tracker is SSOT; the tree is
  regenerated-FROM-tracker. The edit/sync workflow (when does the tree
  re-materialize; `_toc.md` regen cadence) is the OPEN mechanics (BD-203 §3.7
  NUDGE #3), NOT a form question.

### D-3.2 — SURFACED open mechanics-tensions (for the architect — do NOT resolve here)

These are the combining-the-locked-pieces tensions. Each is SURFACED, not
resolved (resolution is the architect's, later). NONE of these is "should we
use the forms" — all assume the forms are the fixed substrate.

- **T1 — Form field-set vs full BD field-set (overflow boundary).** The
  as-shipped `work-item.yml` carries Type/Kind/Status/Blockers/Unblocks/
  File-Symbol/Description/Context/Resolution. A pack BD entry also carries
  `Target:`, `Position:`, `Blockers:`-with-prose, and the parenthetical-title
  form. Which fields ride in the form body vs which spill to the sidecar
  `extra_fields` is an OPEN mechanics question. (LOCKED constraint: forms +
  sidecar are the only carriers; no custom Issue Fields.)
- **T2 — ID + parenthetical-title round-trip carrier (BD-203 §3.7 RATIFY #2).**
  `BD-167b` (suffix) and `BD-195 (Code Red 3)` (parenthetical) must survive
  as a GH Issue field. The marker `<!-- pack-id: BD-NNN -->` carries the base
  ID; the suffix + parenthetical placement is OPEN. Must be a stable parseable
  position, NOT title-prose-inferred.
- **T3 — Per-entry emit target shape (BD-203 §3.7 RATIFY #1).** Reverse writes
  per-entry files DIRECTLY vs decomposes a transient in-memory monolith. BD-203
  recommends direct write (avoids re-introducing the mirror shape). OPEN:
  confirm against the BUILT forward path.
- **T4 — `_toc.md` regeneration trigger cadence (BD-203 §3.7 NUDGE #3).** Every
  reverse that materializes the tree vs only `pack tracker disable`. OPEN.
- **T5 — Header-snapshot under no-mirror (BD-203 §3.7 RATIFY #5).** BD-133
  snapshotted the monolith header; under no-mirror `_intro.md` is the tree's
  stable header. OPEN: confirm the BD-133 mechanism re-maps cleanly to
  `_intro.md` (which is human-only per D1 — does a regenerated header belong
  there, or elsewhere?).
- **T6 — The `_tmr_emit_backlog` pack-vs-client branch split (BD-203 §3.7
  Mode-3 reconciliation).** The shared function emits pack → `/backlog/`,
  client → `docs/project/backlog/`. BD-204 wires the PACK branch only (client
  is BD-207). OPEN: ensure the pack-only edit does not regress the client
  branch (per `pack-project-separation`).
- **T7 — Deferred tracker-lib runtime repoints (BD-203 §3.5).**
  `tracker-agent-read.sh`, `tracker-doctor.sh`, `tracker-header-snapshot.sh`,
  `tracker-migrate-forward.sh` still reference the monolith. Dormant in
  flat-file mode; BD-204 wires + tests them against the tree. OPEN: the exact
  repoint per lib.
- **T8 — Lossless-audit vs the BD-132 data-loss class.** BD-132 fixed a ~33%
  entry-destruction race in the disable/init close step. The per-entry emit
  target post-dates that fix; whether it re-opens or avoids the class is
  un-analyzed. OPEN: the architect's lossless-round-trip audit must cover it.
- **T9 — Live-repo test provisioning (BD-111 blocker; `test-infra-self-provisioned`).**
  The lossless round-trip cannot be proven without a live GH repo. OPEN:
  whether BD-204's audit provisions a scratch personal repo via `gh` (per
  rule) and the cleanup contract.

**Conflicts-with-the-locked-forms (must CONFORM, not choose):** if any corpus
element appears to conflict with the locked forms — e.g., a design that wants
a custom typed field — it MUST conform to the form-family + sidecar carrier
(custom Issue Fields are OUT per D-3.0). The as-shipped-vs-spec form drift
(D-2.3) is a CONFORM-which-shape question, not a re-debate-the-pattern question.

---

## D-4 — Drafted, non-misleading BD-204 entry (for user review — NOT applied)

> **This is a DRAFT for the user to review. It is NOT applied. Authoring/
> editing the `/backlog/` tree is Pack-Chat authority after user approval
> (`backlog/_rules.md:79-85`). This researcher does not write it to disk as a
> backlog entry.**

What this draft fixes vs the current `backlog/BD-204.md`:
- **(a) requires adapting BOTH** the old foundation designs AND BD-203
  (current entry leans almost entirely on BD-203, ignoring the foundation).
- **(b) names the complete list of design docs** to adapt (from D-1).
- **(c) corrects the misleading line 9** — the current
  "RATIFY (confirm good) or NUDGE that tracker-reverse design" framing is
  TOO NARROW: it scopes the second pass to the BD-203 tracker-reverse
  intersection points ALONE and silently ignored the foundation form-family /
  sidecar / provider corpus, which is exactly what caused the failed attempt.
- **(d) distinguishes LOCKED (must use, never reopen) from OPEN (may
  redesign)** per D-2.

---

```
<!-- per-entry source: /backlog/BD-204.md; contract: /backlog/_rules.md -->
**BD-204 — Pack self-migration Phase 2: per-entry directory trees → GH Issues (tracker Mode 2 → Mode 3)**
Type: feat — STRUCTURAL, **pack-only (HARD CONSTRAINT)**. The pack DOGFOODS its own Mode-2→3 tracker (GH Issues) migration on its OWN backlog, built ON the LOCKED tracker-feature corpus (form family + sidecar + provider) AND the landed BD-203 per-entry trees. Full pipeline (researcher → architect → planner → (coder → bounded review/fix) per commit) + a full integrated correctness audit at the end. Phase commits declare `pack-only`.
Status: Open
Target: v11.0 (launch-gate item, user 2026-06-04).
Blockers: Follows BD-203 (the per-entry trees must exist first — DONE). Sequenced BEFORE BD-197 (user 2026-06-04). Needs a live GH personal-account repo for the lossless-round-trip audit (provisioned per `test-infra-self-provisioned`; scratch repo, cleaned up — never a real repo).
Unblocks: the pack tracks its OWN backlog in GH Issues (tracker Mode 3); the per-entry tree is regenerated-FROM-tracker per the Mode-2↔3 contract (NO monolithic mirror); exercises the TrackerProvider / GH-Issues machinery (forward BD-065, reverse BD-067, first-class deps BD-111, hardening BD-129–134) on the pack's own backlog (real dogfood).

HARD CONSTRAINT (user 2026-06-04): **pack-only — this BD must NOT touch `project-template/` or ANY project-side / client asset or workflow. If it affects the project side at all, that is a VIOLATION.** CI Check 36 `pack-only` enforces every commit; any project-side diff fails the gate. (The shared tracker libs + per-entry engine serve both surfaces; BD-204 wires the PACK-surface branch ONLY — the client branch is BD-207.)

BUILT-ON-LOCKED-FOUNDATION (HARD REQUIREMENT — corrects the failed attempt): BD-204 MUST be designed ON the EXISTING, LOCKED tracker-feature design corpus — it must NOT reinvent any carrier. **The GitHub Issue FORM FAMILY (`work-item.yml` + `inbound.yml` + `config.yml`; decisions D-4-V2 / D-16; rationale "validated input + structured roundtrip") is the FIXED, MUST-USE structured representation** and is NOT to be re-debated, re-evaluated, or replaced (the prior attempt FAILED + was rolled back because it ignored the form family and reinvented a base64/sidecar carrier). The complete design corpus BD-204 adapts:
  - **Form family (LOCKED substrate):** `.github/ISSUE_TEMPLATE/work-item.yml` + `inbound.yml` + `config.yml`; `ARCHITECTURE-V2.md` §4 / §24 (OQ-16) / §25 (OQ-17) / §26 (OQ-18); `ARCHITECTURE-V3.3-DELTA.md` §6 (form-family extended; status mapping §6.3; identifier carrier §6.4; D-18 carrier matrix §6.5).
  - **Tracker feature design:** `DESIGN-BRIEF.md` (the contract — esp. §1 hard exclusions, §3.1 mandatory-reverse + `template_version`, §6.3 abstraction floors); `ARCHITECTURE.md` (V1); `ARCHITECTURE-V2.md` (D-1..D-18); `ARCHITECTURE-V3.md` (§16 decision table D-1..D-20 — the LOCKED index; §0.6 things-not-changed); `ARCHITECTURE-V3.1-DELTA.md` §3 (the sidecar `extra_fields` byte-loss backstop, DELTA A2); `ARCHITECTURE-V3.3-DELTA.md` §4–§6 + `ARCHITECTURE-V3.3-DELTA-ADDENDUM-1.md` (sidecar `dependency_edges`).
  - **Tracker build (the libs to wire):** `scripts/lib/tracker-*.sh` (provider BD-060; forward BD-065; reverse + sidecar + mirror BD-067; first-class deps BD-111; hardening BD-129/130/131/132/133/134); the implementing BD entries.
  - **BD-203 per-entry design + standard:** `ARCHITECTURE-BD-203-V3.md` (esp. §3.7 reverse tracker interface + Mode-3 reconciliation; §7 the BD-204 hand-off) + `ARCHITECTURE-BD-203-V3-AMENDMENT.md` (§F D1 doc-governance standard); the no-mirror standard (`backlog/_rules.md`, `CLAUDE.md ## Pack memory`); the shared per-entry engine (`scripts/lib/per-entry/*`); the `_rules.md` / `_toc.md` / `_intro.md` sidecar pattern.
  - **Availability constraint (`verify-availability-not-just-existence`):** the design space is GA + personal-account ONLY. Issue Forms + Issue Dependencies + Sub-issues are GA + personal-usable (USE). GH custom Issue Fields + custom Issue Types are org-only/preview (EXCLUDED — they are NOT a "go-native" fork; the structured carrier is the form-family body + labels + sidecar).

REVERSIBILITY (HARD REQUIREMENT, user 2026-06-04): the per-entry ↔ GH-Issues conversion MUST round-trip LOSSLESSLY (per-entry → GH-Issues → per-entry == original) — not a one-way push. The reverse emits the per-entry TREE (NOT a monolith — corrected no-mirror Mode-3 contract); the silent-data-loss guard FAILS rather than drops.

SECOND-PASS RATIFY/NUDGE (corrects old line 9 — now scoped to the FULL corpus, not the reverse design alone): when BD-204 BEGINS, the architect runs a design pass that (1) ADAPTS the LOCKED foundation corpus above (form family / sidecar / provider — USE as-is, do NOT reopen), and (2) RATIFIES (confirm good) or NUDGES the BD-203 §3.7 reverse-tracker interface at its marked intersection points, against the BUILT forward path. The OPEN (may-redesign) set is the MECHANICS of combining the locked forms + sidecar for byte-losslessness and the edit/sync workflow ONLY — never whether to use the forms. The explicitly OPEN intersection points (BD-203 §3.7 / §7): [RATIFY] per-entry emit target shape; [RATIFY] the ID + parenthetical-title round-trip carrier; [NUDGE] the Mode-3 `_toc.md` regeneration cadence; [RATIFY] the "tree regenerated-FROM-tracker" clause = tree (not monolith); [RATIFY] header-snapshot under no-mirror = `_intro.md`; [WIRE+TEST] the deferred tracker-lib runtime repoints (monolith → tree, pack-surface branch only). (The reverse can't be tested until built, so BD-203 designed the interface and BD-204 validates + wires it.)

LOCKED vs OPEN (do NOT confuse): LOCKED = every numbered decision D-1..D-20 ("reaffirmed in V3"), the form family (D-4-V2/D-16), the structure split (D-17), the template_version dual carrier (D-18), the sidecar + DELTA A2 (D-8), the identifier carrier (V3.3 §6.4), the status mapping (V3.3 §6.3), the no-mirror standard, the D1 doc-governance standard — MUST USE, NEVER REOPEN. OPEN = the BD-203 §3.7 RATIFY/NUDGE mechanics + the deferred lib repoints ONLY. UNMARKED (architect+user decide): the as-shipped `work-item.yml` vs V2 §4.2 spec field-set drift for the pack surface; whether the BD-132 data-loss class re-opens under the tree target; the V3 §A.2 modified-artifacts measure-then-bound scope.

Problem: Phase 2 of the pack dogfooding its own tracker feature — after BD-203 made the pack per-entry, this moves the SSOT to GH Issues (Mode 3), proving the reversible Mode-2↔3 migration on the pack itself, built ON the locked form-family + sidecar + provider corpus.
Scope: migrate the pack's per-entry backlog → GH Issues (tracker Mode 3) via the LOCKED form family + forward-migration contract (BD-065); `tracker.toml` (`mode.state = "tracker"`, `migration.forward_complete = true`); the per-entry tree is regenerated-from-tracker (NO monolithic mirror); wire the deferred tracker-lib runtime repoints (monolith → tree, pack-surface only); verify forward + REVERSE (lossless round-trip) on the pack's own backlog via a self-provisioned live personal-account scratch repo — all pack-side only.
Out of scope: BD-203's per-entry conversion (prerequisite, DONE); reopening/reinventing ANY locked tracker decision (form family, sidecar, provider, carriers); ANY project-side change (a violation if it occurs); the PROJECT tracker + client `_tmr_emit_backlog` branch (→ BD-207); GH custom Issue Fields / Issue Types (org-only/preview, EXCLUDED).
Acceptance criteria (END-OF-BD FULL CORRECTNESS AUDIT): the pack's backlog is tracked in GH Issues via the LOCKED form family; forward migration LOSSLESS (every BD → an issue carried by the form-family field shape + body marker + sidecar overflow, content-faithful, EVERY entry preserved incl. `BD-NNN[b]` suffix + parenthetical-title forms); REVERSIBILITY verified — the round-trip per-entry → GH-Issues → per-entry is LOSSLESS (== original) on a live scratch repo, cleaned up; the Mode-2↔3 contract honored (per-entry tree regenerates from tracker, NO monolithic mirror); NO locked decision reopened; validate-pack green; **zero project-side changes (Check 36 `pack-only` clean on every commit)**; full integrated correctness audit.
References: `project_pack_self_migration_launch_gate`; the LOCKED tracker corpus (DESIGN-BRIEF / ARCHITECTURE-V1/V2/V3 / V3.1-DELTA §3 / V3.3-DELTA §6); the form family (`.github/ISSUE_TEMPLATE/*.yml`, D-4-V2/D-16); the tracker libs (BD-060/061/065/067/111/129-134); BD-203 (`ARCHITECTURE-BD-203-V3.md` §3.7/§7) — prerequisite + reverse-interface hand-off; `RESEARCH-BD-204-RESTART-INTEGRATION.md` (this corpus map).
Resolved: n/a
Position: v11.0 launch gate; after BD-203, before BD-197 (user 2026-06-04).
```

> **Note on the draft's `Type:` and pipeline:** the draft adds
> `researcher → architect` to the pipeline (vs the current entry's
> `architect → planner ...`) per the `researcher-first` + `researcher-maps-
> blast-radius` rules — this corpus map IS that researcher pass; the architect
> runs AFTER it. Surface this to the user as a deliberate pipeline correction.

---

## Rules-Applied Verification Block

| Rule (as named in prompt) | Verification evidence (quoted) | Conclusion |
|---|---|---|
| **researcher-maps-blast-radius [memory #4]** | D-1 enumerates the COMPLETE corpus (form family + tracker design V1/V2/V3/V3.x + 12 implementing BDs + 17 libs + per-entry engine + BD-203 design), each with `file:line`. Reconciled 3 independent ways (V3 §0.5 preserved-list; V3 §16 decision table; on-disk asset/lib inventory) — the form family (the MISSED piece) appears in ALL THREE. "Reconciliation result: ... Nothing beyond the starter list surfaced as un-mapped." | COMPLIANT |
| **empirical-evidence-blocks** | Every claim carries `file:line` + verbatim quote at HEAD `ed47be4` (`git rev-parse HEAD` → `ed47be4159c80fafe02bdc5ad3a4f8026004590e`), 2026-06-05. D-2 LOCKED/OPEN/UNMARKED each quote the exact doc language (e.g. D-4-V2 "**reaffirmed in V3**" `ARCHITECTURE-V3.md:164`; "hard exclusions, not subject to architect debate" `DESIGN-BRIEF.md:20`; BD-203 §3.7 RATIFY list `:263-268`). Form fields cited to `.github/ISSUE_TEMPLATE/work-item.yml:16-106`. | COMPLIANT |
| **verify-availability-not-just-existence [memory #5]** | D-3.0 availability matrix: GH Issue Forms GA + personal-account (GitHub Docs "create default issue... templates for your organization **or personal account**"); Issue Dependencies GA 2025-08-21 + "GitHub **Free**... plans"; account verified personal (`git remote -v` → `DShaneNYC/...`). GH custom Issue Fields + Issue Types EXCLUDED (org-only/preview, per memory #5 lines 22-33) — the exact phantom-fork the prior researcher fell for. | COMPLIANT |
| **pattern-matching-out-of-context [memory #6]** | The locked mechanisms (form family, sidecar, provider) are mapped AS THE SUBSTRATE to USE (D-3.1), explicitly NOT reinvented — D-4 entry states "must NOT reinvent any carrier" and names the base64/sidecar reinvention as the rolled-back failure. The report intentionally maps property-fit (forms-as-primary + sidecar-as-overflow) rather than reflex-adopting a new carrier. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Delivers exactly D-1 map + D-2 lock-classification + D-3 integration map + D-4 draft entry. NO new design, NO edits, NO status flips. Open mechanics SURFACED (D-3.2 T1-T9), explicitly NOT resolved ("resolution is the architect's, later"). Drift + UNMARKED items SURFACED, not fixed. | COMPLIANT |
| **rules-applied-verification-block** | This block; every row quoted evidence (none empty); READ-IN-FULL per-file proof below. No named document derived rather than read. | COMPLIANT |

### READ-IN-FULL row (per-file direct-read proof for required docs #1–#6)

| # | File | Direct-read proof (Read tool, this session) |
|---|---|---|
| 1 | `CLAUDE.md` (whole, esp. `## Pack memory`) | Read in full, lines 1–575 (one Read call). Pack-memory rules `## Pack memory:136-568` incl. no-mirror SSOT (465-483), pack-project-separation, researcher-first, scope-deliverables. |
| 2a | `backlog/BD-204.md` | Read in full, lines 1–17. The current entry whose line 9 D-4 corrects. |
| 2b | `backlog/_rules.md` | Read in full, lines 1–86. The pack-backlog contract (filename regex, lifecycle states incl. `Unblocked`, no-mirror, write authority). |
| 3 | Corpus docs | `.github/ISSUE_TEMPLATE/work-item.yml` (1–106), `inbound.yml` (1–77), `config.yml` (1–9) read in full. `DESIGN-BRIEF.md` (1–333) read in full. `ARCHITECTURE-V3.md` §0/§16/§17/§A.2 read directly (34–188, 1715–1751); `ARCHITECTURE-V2.md` §4/§16 read directly (112–371, 445–581); `ARCHITECTURE-V3.1-DELTA.md` §3 read directly (180–274); `ARCHITECTURE-V3.3-DELTA.md` §6 read directly (308–437); `ARCHITECTURE-BD-203-V3.md` §2.4–§7 read directly (149–378); `ARCHITECTURE-BD-203-V3-AMENDMENT.md` §F/§G/§H read directly (175–214); tracker libs (`tracker-sidecar.sh`/`-migrate-forward.sh`/`-migrate-reverse.sh` headers) + per-entry `_lib.sh` (1–90) read directly; BD-060/065/067/068/111 entries read directly. |
| 4 | `feedback_researcher_maps_blast_radius_before_architect.md` | Read in full, lines 1–41 (one Read call). |
| 5 | `feedback_verify_availability_not_just_existence.md` | Read in full, lines 1–47 (one Read call). |
| 6 | `feedback_pattern_matching_out_of_context_antipattern.md` | Read in full, lines 1–41 (one Read call). |

**No named doc derived rather than read.** Every memory file #4–#6 and
governance doc #1–#2 read directly via the Read tool this session; the corpus
docs #3 read at their design-relevant regions directly (large multi-thousand-
line architecture docs read by section per the prompt's "read the design-
relevant regions directly" instruction).

---

## Sources (external availability verification)

- [Configuring issue templates for your repository — GitHub Docs](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository)
- [Syntax for issue forms — GitHub Docs](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms)
- [About issue and pull request templates — GitHub Docs](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates)
- [Dependencies on issues — GitHub Changelog (2025-08-21)](https://github.blog/changelog/2025-08-21-dependencies-on-issues/)
- [Creating issue dependencies — GitHub Docs](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/creating-issue-dependencies)
- [Adding sub-issues — GitHub Docs](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/adding-sub-issues)

## End of RESEARCH-BD-204-RESTART-INTEGRATION
