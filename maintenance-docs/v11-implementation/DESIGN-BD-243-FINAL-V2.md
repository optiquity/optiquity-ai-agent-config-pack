# DESIGN (FINAL-V2) — BD-243: strip historical/audit + deferred-feature MENTIONS + bloat from operating docs; NUCLEAR pack-help tracker strip + client-facing leak census; add anti-bloat governance rule

Architect: FRESH reconciliation instance v2 (pack-architect, RO). Did NOT author DESIGN-BD-243.md / DESIGN-BD-243-FINAL.md; am NOT the adversarial reviewer. Folds the NEW user rulings (OQ-FINAL-1 NUCLEAR / OQ-FINAL-2 sweep / OQ-FINAL-3) + CORRECTION A (`_intro.md` taxonomy fix + full re-verification) + CORRECTION B (the LEAK AXIS) + the scope/success-criterion expansion.
Runtime HEAD `a847f120e4ada06456bec4e2bf6d275fdd8c0742`, branch v11-dev, 2026-06-21, repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`.
**SUPERSEDES** `/tmp/pack-handoff-bd243-arch/DESIGN-BD-243-FINAL.md` (authoritative as of this file). Everything in FINAL stays unless a delta below changes it.

---

## OPEN QUESTIONS FOR USER (genuine NEW ambiguity only — do not guess)

OQ-FINAL-1/2/3 are RULED (folded below, no longer open). OQ-A/OQ-B/OQ-1/OQ-2/OQ-3 from FINAL are RULED. Two genuine new judgments surface:

**OQV2-1 — pack-INTERNAL OPTIONAL-FEATURES / `_intro` deferred-feature passages: strip or tolerable context?**
The §0 directive is unconditional for operating docs (`pack-ops/OPTIONAL-FEATURES.md` IS gate-IN) — so its whole "## Tracker integration (deferred)" section (L309-333) and the tracker mentions in `pack-ops/PACK-CHAT.md` (L53/69-77/430-434) STRIP by the operating-doc rule REGARDLESS of leak axis. NO ambiguity there → STRIP.
The genuine judgment is the pack-INTERNAL, gate-EXEMPT reference surfaces that the leak axis does NOT reach (they never ship): the pack `backlog/_intro.md:19` "Tracker (GH Issues) integration is deferred (BD-214)" and `changelog/_intro.md` (clean). These are human-orientation EXEMPT docs (CORRECTION A) — not operating docs, not client-facing. **Architect resolution: STRIP it anyway.** Rationale: §0 says default to MAXIMAL removal; the `_intro` mention adds zero orientation value (the reader does not need to know a non-existent mode exists), and a pack-internal `_intro` that contradicts the new no-deferred-feature governance rule is self-inconsistent. This is a STRIP recommendation, not a blocker — **surface for user confirmation** since `_intro` is gate-EXEMPT and the leak axis technically does not force it. If the user prefers "leave pack-internal EXEMPT `_intro` context," it degrades cleanly (one line stays).

**OQV2-2 — the dormant tracker SCRIPTS (`pack-tracker.sh`, `tracker-migrate.sh`, `pack-td.sh`) now vanish from `pack help` — confirm the `# pack-internal: true` route.**
The NUCLEAR strip deletes HELP-FRAGMENT-TRACKER + rips the tracker rows from HELP-FRAGMENT-PACK. But Check 23 (help-fragment completeness) REQUIRES every non-`pack-internal` script in `scripts/` be listed in HELP-FRAGMENT-PACK. `pack-tracker.sh` / `tracker-migrate.sh` / `pack-td.sh` are NOT marked `# pack-internal: true` today (measured). To remove their rows from help output WITHOUT a Check-23 failure, they must be marked `# pack-internal: true` (dormant code stays per BD-214; it just stops being advertised). **Architect resolution: mark all three `# pack-internal: true`** — exactly the §0 intent (the dormant CODE stays; the ADVERTISING stops). `pack-td.sh` is borderline: TD-promotion is a LIVE project feature, NOT deferred — see OQV2-2a. **Surface for confirmation:** marking `pack-td.sh` pack-internal would hide a LIVE verb from `pack help`; the alternative is to KEEP `pack td` rows in HELP-FRAGMENT-PACK (it is not a deferred feature) and only strip the `pack tracker` rows + the whole tracker fragment.
  - **OQV2-2a (architect recommendation):** `pack td promote/resolve` is a LIVE, non-deferred feature → its HELP-FRAGMENT-PACK rows STAY (do NOT mark `pack-td.sh` internal). Only `pack-tracker.sh` + `tracker-migrate.sh` (deferred-feature dispatchers) get `# pack-internal: true`, and the HELP-FRAGMENT-PACK "Pack scripts" tracker rows + the whole "## Tracker commands (deferred)" section + the sibling-include marker are deleted. The `pack td` rows that today live INSIDE HELP-FRAGMENT-TRACKER ("## TD promotion (v11+)") must RELOCATE into HELP-FRAGMENT-PACK (else a live feature loses its help text when the fragment is deleted). This is the only content-MOVE in the nuclear strip; everything else is deletion.

If the user rules "hide pack-td too / keep tracker rows / leave EXEMPT `_intro`," each degrades cleanly. Absent a ruling the planner applies OQV2-1 STRIP + OQV2-2a (relocate `pack td`, internal-mark only the two tracker dispatchers).

---

## CHANGES-FROM-FINAL (delta summary)

| # | Area | FINAL said | FINAL-V2 says (delta) |
|---|---|---|---|
| D1 | **OQ-FINAL-1** | "trace-then-decide; if a live `pack help` branch emits the fragment, KEEP + surface separately" | **RULED NUCLEAR.** `pack help` DOES wire it (verified: `pack-help.sh` `emit_fragment` inlines it at BOTH call sites; `migrate:301` copies the client one). DELETE `pack-ops/HELP-FRAGMENT-TRACKER.md` + the client `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` ENTIRELY; RIP the tracker-include path out of `pack-help.sh`; DROP the `HELP-FRAGMENT-TRACKER.md` copy in `migrate-v10-to-v11.sh`. Deliberate client-facing behavior change. |
| D2 | **OQ-FINAL-2** | "standing per-wave grep guard; coder greps each wave for tracker conditional" | **RULED: find ALL now.** DEFINITIVE graph-first+grep sweep done. NO executable tracker-detection step exists. Only prose/reserved mentions: pack-startup Step 8 + its reserved HTML comment; pm-startup Step 7 reserved comment + Step 8. ALL → STRIP. No "per-wave blind guard" remains. |
| D3 | **OQ-FINAL-3** | provisional REWRITE `_rules.md` to operative-only | **RETAINED** (already in FINAL). No change. |
| D4 | **CORRECTION A — `_intro` taxonomy** | all 5 `_intro.md` classified **IN** (gate scope) | **FIXED: `_intro.md` is EXEMPT (D1 human-orientation, ZERO rules, agent-ignorable — verified by their own headers).** Gate scope shrinks by 5 (2 pack + 3 project). Full taxonomy RE-VERIFIED (§A); also reclassified: `HELP-FRAGMENT-*` (help OUTPUT) review, `_format.md`. |
| D5 | **CORRECTION B — LEAK AXIS** | (absent — FINAL had only the operating-doc gate) | **NEW axis.** Complete client-facing deferred-feature leak census (§ Leak Census). Strips client-shipped tracker mentions EVEN on gate-EXEMPT surfaces (client `_intro.md`, client `HELP-FRAGMENT*`, client OPTIONAL-FEATURES, client prompts/skills). |
| D6 | **Scope / success criterion** | "scripts exempt; no functionality change except the new rule" | **EXPANDED (user-authorized).** Now edits SCRIPT mechanism (`pack-help.sh`, `migrate`, tracker-script internal markers) + CHANGES `pack help` output. Success = NO functionality lost EXCEPT (a) the new rule AND (b) deliberate removal of blocked-feature advertising/leaks. |
| D7 | **Encoding surfaces** | F-table: Check 44/45/59/65 + trinity/tri-family | **EXPANDED.** The nuclear strip + leak axis ripple through Checks 22, 23, 39, 40, 41, 43, 47 + install-map + migrate + 3 tracker-script headers. Full lockstep in §F-V2. Checks 29/35/51 (dormant-CODE guards) UNCHANGED — BD-214 retention. |
| D8 | **Wave map** | W0-W6 | **+W-NUCLEAR** (the pack-help strip wave: fragment deletes + `pack-help.sh` + migrate + tracker-script markers + the ~7 validate-pack checks) and **+W-LEAK** (client-facing reference strips). |
| D9 | **EVERYTHING else in FINAL** | (OQ-1=B Check-44 reduction 5-surface; Check 65; full BD/TD census; strip recipes incl. P-DEF + roadmap strips BD-110/109/234/136/218/217/233/215; 3-ban rule; terseness bar; encoding lockstep; wave map) | **CARRIED** verbatim, updated for D1-D8. |

---

## A. TAXONOMY — RE-VERIFIED (CORRECTION A; criterion re-applied to EVERY category; reclassifications flagged)

### Criterion (unchanged from FINAL, restated)
**IN (gate-scanned)** iff an agent/chat EXECUTES it as live instruction at task time. **EXEMPT** iff it DESCRIBES / orients / sets up / records / outputs / self-governs. Tie-breakers: (1) Execution→IN; (2) human-orientation audience→EXEMPT; (3) deliverable/record→EXEMPT; (4) history-home→EXEMPT.

### Per-category re-application (the full ~145 IN set re-judged)

| Category | Count | Criterion application | Verdict | Reclassified? |
|---|---|---|---|---|
| Root trinity CLAUDE/AGENTS/GEMINI.md | 3 | agents EXECUTE these rules | **IN** | no |
| `pack-ops/` operating docs (PACK-CHAT, PACK-AGENTS, MERGE-STRATEGY, PACK-MEMORY-RATIONALE, BOUNDARY-DEFINITION, OPTIONAL-FEATURES, CONCEPTUAL-REVIEW-METHODOLOGY, DRY-RUN-MIGRATION) | 8 | executed as live operating instruction / write-contract / methodology | **IN** | no (was 10 — see HELP-FRAGMENT below) |
| **`HELP-FRAGMENT-PACK.md` / `HELP-FRAGMENT-TRACKER.md`** | 2 | these are **help OUTPUT** — text EMITTED by `pack help` to a human reading the terminal, NOT instruction an agent executes. By tie-breaker (2) human-output + (3) output/record → **EXEMPT** under the strict criterion. **HOWEVER** they ship to clients and are emitted to users → the LEAK AXIS (CORRECTION B) governs them, and HELP-FRAGMENT-TRACKER is DELETED outright (nuclear). HELP-FRAGMENT-PACK is leak-stripped (tracker rows out). | **EXEMPT from Check 65** (output doc), **but leak-axis-governed + nuclear-stripped** | **YES — reclassified IN→EXEMPT** (output, not executed). Net: gate scope −2. Their bloat/leak is handled by the leak axis + nuclear strip, not Check 65. |
| backlog/changelog `_rules.md` (pack) | 2 | write-contract an agent executes | **IN** | no |
| **backlog/changelog `_intro.md` (pack)** | 2 | own header: "Audience: humans. Purpose: orientation. NOT read by agents. carries NO rules." | **EXEMPT** | **YES — reclassified IN→EXEMPT** (CORRECTION A). Gate scope −2. Leak axis still strips the `_intro` tracker mention (OQV2-1). |
| `.claude/skills/*/SKILL.md` (pack) | 11 | agents execute skill bodies | **IN** | no |
| `.claude/agents/pack-*.md` | 5 | agent definitions executed | **IN** | no |
| Project trinity (3) | 3 | client agents execute | **IN** | no |
| Project `docs/pack/*.md` (METHODOLOGY, INSTALL-PROCEDURES, PM-CHAT, PLATFORM-SKILLS, PACK-FEEDBACK, OPTIONAL-FEATURES) | 6 | executed as client operating instruction | **IN** | no |
| **Project `docs/pack/HELP-FRAGMENT.md` / `HELP-FRAGMENT-TRACKER.md`** | 2 | help OUTPUT (client) | **EXEMPT from Check 65** (output), **leak-axis-governed**; client HELP-FRAGMENT-TRACKER DELETED (nuclear D1) | **YES — IN→EXEMPT** (output). Gate scope −2. |
| Project `docs/pack/prompts/*.md` | 10 | spawn prompts executed | **IN** | no |
| Project `skills/*/SKILL.md` | 37 | executed | **IN** | no |
| Project `.claude/agents/*.md` + `.agents-plugin/.../*.md` + `.codex/agents/*.toml` (16×3) + RUNTIME-SUBAGENT-PATTERN.md | 49 | agent defs executed | **IN** | no |
| Project `docs/project/{backlog,changelog,implementation-plan}/_rules.md` | 3 | write-contracts | **IN** | no |
| Project `docs/project/changelog/_format.md` | 1 | filename/heading FORMAT spec the write-contract emits | **IN** | no (its date examples are K9/K10 allowlisted) |
| **Project `docs/project/{backlog,changelog,implementation-plan}/_intro.md`** | 3 | human-orientation (same header class as pack `_intro`) | **EXEMPT** | **YES — IN→EXEMPT** (CORRECTION A). Gate scope −3. Leak axis strips their tracker mentions (client-shipped). |

### Corrected gate scope (Check 65)
- **FINAL IN count:** ~145.
- **Reclassified IN→EXEMPT:** pack `_intro` (2) + project `_intro` (3) + pack HELP-FRAGMENT-{PACK,TRACKER} (2) + project HELP-FRAGMENT{,-TRACKER} (2) = **9 docs removed from gate scope.**
- **Corrected Check-65 IN scope ≈ 136** (~145 − 9). The frozen `_CHECK_65_OPERATING_DOCS` constant is sized to this corrected set; the EXEMPT-9 are NOT scanned (they legitimately hold orientation/output, and the deferred-feature mentions in them are stripped by the leak axis / nuclear strip, not by Check 65).
- **Note:** of the 9 reclassified, 4 (the HELP-FRAGMENT family) are ALSO either deleted (the 2 TRACKER) or leak-stripped (the 2 non-tracker); the 5 `_intro` are leak-stripped where client-shipped (3 project) + OQV2-1 (2 pack).

### EXEMPT set (gate MUST NOT scan) — updated
FINAL's EXEMPT set PLUS the 9 reclassified docs. README/QUICKSTART/LICENSE/project-template README; `supporting-docs/*.md`; `_toc.md` (generated); `BD-*.md`/`v*.md`/`TD-*.md`/`phase-*.md` (history/entry store); `maintenance-docs/**`; all `PACK-REVIEW-*`/IMPL reports; `scripts/**` + non-agent config/`.py` (script exemption); **+ all `_intro.md` (5) + all `HELP-FRAGMENT*` (4).**
DESIGN-BD-243-FINAL-V2.md — page 1 of 3; continues at §LEAK CENSUS.

---

## LEAK CENSUS (CORRECTION B — every CLIENT-FACING deferred-feature mention; measure-then-bound)

**Axis definition.** A client must NEVER see a deferred/unimplemented feature on ANY surface that SHIPS to a client (operating OR reference OR output). Distinct from the operating-doc gate: the leak axis covers gate-EXEMPT client surfaces too. Pack-INTERNAL reference docs (never shipped) are NOT leak-axis (resolved by the operating-doc rule for IN docs, or by OQV2-1 for EXEMPT pack docs).

**Client-facing surface set (what ships).** Project trinity (CLAUDE/AGENTS/GEMINI at `project-template/`), `project-template/docs/pack/*` (METHODOLOGY/INSTALL/PM-CHAT/PLATFORM-SKILLS/PACK-FEEDBACK/OPTIONAL-FEATURES/HELP-FRAGMENT*/SETUP-EXISTING), `project-template/docs/pack/prompts/*`, `project-template/skills/*`, `project-template/.claude|.codex|.agents-plugin/agents/*`, `project-template/docs/project/{backlog,changelog,implementation-plan}/{_intro,_rules,_format}.md`, `project-template/.gitignore`, `project-template/tracker.toml.project-example`, plus `pack help` OUTPUT as rendered on a client. The dormant tracker CODE/example-templates STAY (BD-214) — only client-VISIBLE MENTIONS/advertising go.

### Census table (every distinct client-facing tracker/deferred-feature site; file:line; STRIP unless noted)

| # | Surface (client-shipped) | Site (file:line @ a847f12) | Content | Verdict |
|---|---|---|---|---|
| L-1 | project trinity CLAUDE.md | `project-template/CLAUDE.md` "Document locations" preamble + the table-flat note + "Per-entry source-of-truth trees (v11.0)" para | "tracker mode is deferred indefinitely (no release version — tracker code retained dormant…), so all rows read `flat`"; "tracker integration is deferred indefinitely … dormant" | **STRIP** → state only "Flat-file per-entry is the sole supported mode." (trinity-locked ×3) |
| L-2 | project trinity AGENTS.md | `project-template/AGENTS.md` (parallel sites) | same | **STRIP** (trinity) |
| L-3 | project trinity GEMINI.md | `project-template/GEMINI.md` (parallel sites) | same | **STRIP** (trinity) |
| L-4 | client HELP-FRAGMENT-TRACKER.md | `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (whole file, 54 lines) | entire deferred-tracker verb table + colloquial mappings + dormant-config note | **DELETE FILE** (nuclear D1). The "## TD promotion (v11+)" live block RELOCATES into client HELP-FRAGMENT.md (OQV2-2a). |
| L-5 | client HELP-FRAGMENT.md | `project-template/docs/pack/HELP-FRAGMENT.md` | the sibling-include marker `[Included from \`HELP-FRAGMENT-TRACKER.md\`…]` + any `pack tracker` rows | **STRIP** the include marker + tracker rows; RELOCATE the `pack td` rows in (from L-4). |
| L-6 | client OPTIONAL-FEATURES.md | `project-template/docs/pack/OPTIONAL-FEATURES.md:321-335` "## Tracker integration (deferred)" | DEFERRED-indefinitely tracker section | **STRIP** the whole section. (Check 54 asserts the `worktree`/`baseRef` isolation section across 2 surfaces — NOT the tracker section; deleting the tracker section is Check-54-safe. Verify.) |
| L-7 | client PM-CHAT.md | `project-template/docs/pack/PM-CHAT.md:714,718,793,796` | "D-19 tracker opt-in recommendation is DEFERRED…", "tracker integration is deferred…", "retained dormant for a future tracker resumption" | **STRIP** the deferred-tracker mentions; keep the live flat-file directive. |
| L-8 | client prompt auditor.md | `project-template/docs/pack/prompts/auditor.md:51` | "(…mode; tracker integration is deferred to a future release.)" | **STRIP** the parenthetical; keep the flat-file statement. |
| L-9 | client prompt coder.md | `project-template/docs/pack/prompts/coder.md:68-69` | "(Flat-file per-entry is the sole supported mode; tracker integration is deferred to a future release.)" | **STRIP** the deferred-tracker clause (keep "flat-file is the sole supported mode"). NB coder.md's "Deferral comments / Deferred items section" (L25-26, 94-141, 211-249) is the LIVE TD-TBD project feature — NOT a leak; KEEP. |
| L-10 | client pm-startup skill | `project-template/skills/pm-startup/SKILL.md:85,210-211,217-225` | L85 deferred-tracker clause; L210-211 "Step 7 reserved … tracker-mode triage queue … if tracker integration resumes"; L217-225 "## Step 8 … (deferred) … D-19 tracker opt-in … DEFERRED … dormant" | **STRIP** (OQ-FINAL-2 client leak). Remove the Step-7 reserved comment + the whole deferred Step 8; keep the live step flow. See § STEP-RENUMBERING. |
| L-11 | client `_intro.md` ×3 | `project-template/docs/project/{backlog,changelog,implementation-plan}/_intro.md` (backlog L44-46; changelog L48-50; impl-plan L53-55) | "Tracker mode is deferred indefinitely (no release version); the ability to flip to a tracker (e.g., GH Issues) is blocked and the tracker code is retained dormant…" | **STRIP** the 3-line deferred-tracker block on each (gate-EXEMPT but client-shipped → leak axis). Keep "flat-file is the sole supported mode." |
| L-12 | client `.gitignore` | `project-template/.gitignore` (tracker line) | a `tracker.toml`-ignore line | **KEEP** — gitignoring the dormant config's hand-copy is operative hygiene (the dormant CODE stays; ignoring a stray `tracker.toml` is not an advertisement). VERIFY the line carries no deferred-feature PROSE; if it has a "(deferred — BD-214)" comment, strip the comment only. |
| L-13 | client `tracker.toml.project-example` | `project-template/tracker.toml.project-example` | the dormant example template itself | **KEEP** (dormant config record — BD-214 standing; it is a config file not a doc; not "advertising" in operating/help text). It is gate-EXEMPT (not a doc). NB its REFERENCES from prose (L-6/L-1) are stripped. |
| L-14 | client boundary-investigation skill | `project-template/skills/boundary-investigation/SKILL.md:106-114,128` | references to `HELP-FRAGMENT-TRACKER.md` (bare-filename + pack-ops copy) + `tracker.toml.pack-example` exempt-file note | **REWRITE** — these are boundary-rule examples referencing the now-DELETED `HELP-FRAGMENT-TRACKER.md`. After D1 deletes the fragment, these refs DANGLE → update the skill's example set to drop the deleted fragment (and the deferred-tracker example), keeping the boundary methodology. Coordinate with Check-40/43 allowlists. |
| L-15 | client documentation skill | `project-template/skills/documentation/SKILL.md:20` | "its public issue tracker for known limitations" | **KEEP** — "issue tracker" here is generic 3rd-party-dependency advice, NOT the pack's deferred tracker FEATURE. Not a leak. |
| L-16 | client `.github/ISSUE_TEMPLATE/work-item.yml` | (the "deferred" hits) | a deferral-state field for project work items | **KEEP/VERIFY** — "deferred" as a work-item STATE is the live project workflow, not the tracker feature. Confirm no pack-tracker-FEATURE mention; KEEP. |
| L-17 | client coder agent defs ×3 | `project-template/.claude/agents/coder.md`, `.codex/agents/coder.toml`, `.agents-plugin/.../coder.md` (the "deferred" hits) | "Deferred items" report-section instruction (TD-TBD workflow) | **KEEP** — live TD-deferral feature, not the tracker feature. Tri-family verify identical. |
| L-18 | client PLATFORM-SKILLS / PACK-FEEDBACK / reviewer / pm-chat / audit-methodology / ios-architecture / swift-concurrency / review skills | (the "deferred" hits) | generic "deferred"/"deferral" project-workflow language | **KEEP** (VERIFY each is NOT a tracker-feature mention; the grep for "tracker mode/integration/dormant" returned ZERO on audit-methodology/review/ios/swift — confirmed not leaks). |

**Leak-census bound (measure-then-bound).** STRIP set = L-1..L-11 + L-14 (the genuine deferred-tracker-FEATURE advertisements/leaks, file:line-anchored). KEEP set = L-12/L-13/L-15/L-16/L-17/L-18 (dormant config + generic "issue tracker"/"deferred-item"/"deferral" project-workflow language that is NOT the pack tracker feature). The bound is sized EXACTLY to the deferred-tracker-FEATURE mentions; generic uses of the word "tracker"/"deferred" are NOT widened into the strip. A reviewer re-verifies each KEEP is genuinely non-leak.

**audit-methodology/SKILL.md:76 `_v8-resolved-archive.md` (OQ-B, carried from FINAL):** STRIP/correct (references a non-existent file) — rides W6 as in FINAL; orthogonal to the leak axis.

DESIGN-BD-243-FINAL-V2.md — page 2 of 3; continues at § NUCLEAR PACK-HELP STRIP.

---

## NUCLEAR PACK-HELP TRACKER STRIP (OQ-FINAL-1 — confirmed mechanism; full encoding-surface spec)

### N.0 Confirmed mechanism (Empirical, EE-N1/N2 below)
`pack help` DOES emit the tracker fragment, at BOTH surfaces:
- `scripts/pack-help.sh` `emit_fragment()` (L70-106) replaces the sibling-include placeholder line with the body of the tracker fragment via the `awk` block (L98-105), matched by the regex `^\[Included from \`(pack-ops\/)?HELP-FRAGMENT-TRACKER\.md\``.
- pack call site: L143 `emit_fragment "$pack_frag" "$tracker_frag"` (tracker_frag = `pack-ops/HELP-FRAGMENT-TRACKER.md`).
- client call site: L146-147 `emit_fragment "$root/docs/pack/HELP-FRAGMENT.md" "$root/docs/pack/HELP-FRAGMENT-TRACKER.md"`.
- ambiguous call site: L161 + L170-171 (both surfaces).
- `migrate-v10-to-v11.sh:301` `for help_src in HELP-FRAGMENT.md HELP-FRAGMENT-TRACKER.md` copies the client tracker fragment into the migrated tree.
This is a LEAK (a client running `pack help` sees a full deferred-tracker verb table) + bloat. RULING = NUCLEAR.

### N.1 The nuclear deletions / edits
1. **DELETE** `pack-ops/HELP-FRAGMENT-TRACKER.md` (whole file).
2. **DELETE** `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (whole file, client-shipped).
3. **`scripts/pack-help.sh`** — RIP the tracker-include path: remove `emit_fragment`'s second `tracker_fragment` parameter + the `awk` include logic (L85-105) + the missing-tracker stderr branch (L77-84) + `_pack_tracker_fragment_path()` (L120-126) + the `tracker_frag` resolution at all three call sites (pack/client/ambiguous). `emit_fragment` becomes a single-arg `cat`-with-fragment. Update the file header comment (L4-6) + the `usage()` text (L37-40) to drop the sibling-include description.
4. **`scripts/migrate-v10-to-v11.sh:301`** — drop `HELP-FRAGMENT-TRACKER.md` from the `for help_src in …` loop (keep `HELP-FRAGMENT.md`).
5. **`HELP-FRAGMENT-PACK.md`** (pack, EXEMPT/leak-stripped) — DELETE: the L21 header "(install / migrate / tracker)" → "(install / migrate)"; the L30 `pack-tracker.sh` row; the L32 `tracker-migrate.sh` row; the whole "## Tracker commands (deferred)" section (L34-36, incl. the sibling-include marker L36). KEEP the `pack-td.sh` row L31 (live feature). RELOCATE the "## TD promotion (v11+)" content (from deleted HELP-FRAGMENT-TRACKER L22-37) into HELP-FRAGMENT-PACK as a "## TD promotion" section.
6. **client `HELP-FRAGMENT.md`** — same shape: drop the tracker include marker + any `pack tracker` rows; RELOCATE the client `pack td` rows (from deleted client HELP-FRAGMENT-TRACKER "## TD promotion (v11+)") into HELP-FRAGMENT.md.
7. **Mark `# pack-internal: true`** in `scripts/pack-tracker.sh` + `scripts/tracker-migrate.sh` headers (so Check 23 no longer requires them in HELP-FRAGMENT-PACK; dormant code stays). Do NOT mark `scripts/pack-td.sh` (live feature, OQV2-2a).

### N.2 The ~7 validate-pack checks the nuclear strip ripples through (enumerate-encoding-surfaces — ALL lockstep, same wave)
| Check | Today references HELP-FRAGMENT-TRACKER | Nuclear-strip action |
|---|---|---|
| **22** `check_help_fragment_freshness` (reg L9979) | `tracker_fragment` key in BOTH surfaces; HARD-FAILS `tracker fragment missing` (L2087-2089) | Remove `tracker_fragment` from both surface dicts; drop the missing-fragment fail; `frag_text` = fragment only (no `+ tracker_frag.read_text()`). After tracker verbs leave the prose docs (L-6/L-7/etc.), the `pack tracker` verb-coverage requirement vanishes — verify no surviving `pack tracker` verb token in the Check-22 doc set. |
| **23** `check_help_fragment_completeness` (reg L9980) | reads tracker_fragment; HARD-FAILS `tracker fragment missing` (L2156-2157); concatenates it into `text` | Remove tracker_fragment read + the missing-fail; `text` = HELP-FRAGMENT-PACK only. `pack-tracker.sh`/`tracker-migrate.sh` now `# pack-internal: true` → excluded from the required-listed set (no fail). `pack-td.sh` stays listed. |
| **39** `check_cmd_update_symmetry` (reg L10013) | references HELP-FRAGMENT-TRACKER (L4261, §16a row) | Remove the HELP-FRAGMENT-TRACKER row from its symmetry table/allowlist (file deleted). |
| **40** `check_bare_pack_ops_refs` (reg L10020) | bare-ref allowlist mentions HELP-FRAGMENT-TRACKER (L4297, L4623) | Remove the HELP-FRAGMENT-TRACKER allowlist entries (no longer a bare-ref target — file gone). |
| **41** `check_client_installed_files` (reg L10026) | `_CLIENT_INSTALLED_FILES` "HELP-FRAGMENT.md" note cites HELP-FRAGMENT-TRACKER (L5098-5107) | Update the comment (drop the deleted-file cross-ref). `HELP-FRAGMENT.md` stays client-installed. |
| **43** `check_project_side_bare_internal_refs` (reg L10033) | `_CHECK_43_PACK_OPS_CLIENT_INSTALLED = ("pack-ops/HELP-FRAGMENT-TRACKER.md",)` (L5584); `mirror_skip` includes it (L5683); docstring (L5674) | Remove HELP-FRAGMENT-TRACKER from `_CHECK_43_PACK_OPS_CLIENT_INSTALLED` (→ empty tuple or drop), from `mirror_skip`, and from the docstring. (The constant exists ONLY to exempt the now-deleted file — it becomes vestigial.) |
| **47** `check_sanctioned_pack_side_shipped` (reg L10073) | `_SANCTIONED_PACK_SIDE_SHIPPED = {detect.sh, pack-help.sh}` | UNCHANGED — `pack-help.sh` stays sanctioned-shipped (it still ships; only its tracker-include behavior is removed). Frozen-set membership unchanged (no architect+user sign-off needed; we are not growing the set). |
| **install-map** (`_INSTALL_MAP`/Check 41 source, L5474-5475) | "HELP-FRAGMENT-TRACKER.md" install-map row | Remove the HELP-FRAGMENT-TRACKER.md install-map row (file no longer installs). Keep HELP-FRAGMENT.md. |
| **init-project.sh** (L949-954) | copies client HELP-FRAGMENT-TRACKER.md | Remove the HELP-FRAGMENT-TRACKER.md client-copy block (keep HELP-FRAGMENT.md copy). |
| **pack-help-test.sh** + any check-22/23 test fixtures | asserts tracker-fragment inclusion in `pack help` output | Rewrite: drop the tracker-fragment-inclusion assertions; assert the tracker section is ABSENT from `pack help` output; assert `pack td` rows present (relocated). |
| **Checks 29 / 35 / 51** (dormant-tracker-CODE guards) | guard `tracker-config.sh` clamp, verb gates, recommendation seam, entry grep-zero, `tracker.toml.example`-not-installed | **UNCHANGED** — BD-214 retention. These guard the dormant CODE/state, not the help fragment. Verify each still passes (none reads HELP-FRAGMENT-TRACKER). Check 51 leg 5 already asserts `tracker.toml.example` NOT in install map — consistent with the nuclear direction. |

### N.3 Registry/count impact of the nuclear strip
No registry ADD/REMOVE (Checks 22/23/39/40/41/43 keep their numbers; their bodies shrink). `CHECK_REGISTRY_EXPECTED_COUNT` change is SOLELY from Check 65 (+1, 62→63) as in FINAL — the nuclear strip is body edits, not count changes.

### N.4 Step-renumbering (OQ-FINAL-2; pack-startup + pm-startup)
- **pack-startup/SKILL.md:** steps today = 1,2,3,4,5,8 (6/7 reserved via HTML comment; 8 = deferred no-op). STRIP: the HTML-comment reserved block (L108-119, which says "Step 7 is the … tracker-mode triage queue … when tracker mode lands") + the whole "## Step 8 — Inflection-point recommendation check (deferred)" (L121-129, "so this step surfaces nothing"). Result: last live step = Step 5. No renumber needed (5 is already last after removal); the reserved 6/7/8 vanish. The dormant `recommendation.sh` stays (BD-214). VERIFY no other doc references "pack-startup Step 8".
- **pm-startup/SKILL.md (client):** steps = 0,1,2,3,4,5,6,8 (Step 7 reserved comment; Step 8 deferred no-op). STRIP: the Step-7 reserved HTML comment (L209-216) + the whole "## Step 8 … (deferred)" (L217-225). Result: last live step = Step 6. VERIFY no other client doc references "pm-startup Step 7/8" (the reserved-numbering note claimed external refs — grep to confirm none survive; if a doc says "see Step 8," strip that too).
- Both are pure deferred-feature MENTIONS (the step "surfaces nothing") → clean STRIP, no behavior lost (nothing executed).

---

## OQ-FINAL-2 SWEEP RESULTS (definitive; graph-first + grep)
Charge: find EVERY tracker-mode CONDITIONAL/DETECTION STEP across ALL skills/agents; prose/reserved → STRIP; genuine executable detection → REMOVE-or-SURFACE per §0.
**Result: NO genuine executable tracker-mode detection/conditional step exists anywhere** (pack skills, pack agents, client skills, client agent defs ×3 families). Grep for `if tracker|tracker mode|detect.*tracker|tracker\.toml.*exist|skip.*tracker|tracker.*enabled` over all four trees returned ONLY:
- `.claude/skills/pack-startup/SKILL.md:114` — the reserved HTML-comment "when tracker mode lands in pack-startup" (prose mention → STRIP, N.4).
- (pm-startup Step 7/8 found via the `-i tracker` pass, all prose/reserved → STRIP, N.4).
No "Step 8 … tracker.toml exists … skip in tracker mode" executable step exists (the hypothetical in the charge does NOT occur). Both startup Step 8s are explicit NO-OPs ("surfaces nothing"). **No SURFACE-to-user item; all resolve to STRIP.** No blind per-wave guard remains.

DESIGN-BD-243-FINAL-V2.md — page 3 of 3; continues at § GATE SCOPE / WAVE MAP / carried sections.

---

## GATE SCOPE (Check 65) — UPDATED for the corrected IN set
- Check 65 (`check_operating_doc_no_history`, number 65, allowlist `pack-ops/.operating-doc-history-allowlist.txt`, test `scripts/tests/test-validate-pack-check-65.sh`) — identity/registration/detect/allowlist all per FINAL §E.2-E.5, with ONE change: the frozen `_CHECK_65_OPERATING_DOCS` scope is the **corrected ~136 IN set** (FINAL ~145 minus the 9 reclassified EXEMPT docs: 5 `_intro` + 4 HELP-FRAGMENT). The EXEMPT-9 are NOT scanned.
- The Check-44 REDUCTION (5 surfaces) is UNCHANGED from FINAL §E.1 (pattern tuple → `("will",)`; test MOVE; allowlist header; comment/docstring/fail-message; CONCISION-GUARDRAILS addendum). HELP-FRAGMENT-PACK/TRACKER were NEVER in `_CHECK_44_DURABLE_DOCS`'s history role anyway (they carry the `will`/length role only); note HELP-FRAGMENT-TRACKER (deleted) must be REMOVED from `_CHECK_44_DURABLE_DOCS` (it is listed there at L7802 `("pack-ops/HELP-FRAGMENT-TRACKER.md", 57)`) — **NEW lockstep item: drop the HELP-FRAGMENT-TRACKER row from `_CHECK_44_DURABLE_DOCS` + its advisory-ceiling tuple in the W-NUCLEAR commit.** HELP-FRAGMENT-PACK stays in the Check-44 durable set (`("pack-ops/HELP-FRAGMENT-PACK.md", 49)` L7801) but its ceiling may shrink after the tracker rows leave — planner re-measures the post-strip line count.
- Check-65 measure-then-bound proof: unchanged from FINAL §E.5 except the scanned set is the corrected ~136; the deferred-feature RESIDUE (date/BD tokens left by a P-DEF/leak strip) is still caught by Check 65 on the IN docs; the EXEMPT-9's residue is caught by the reviewer (leak axis), not Check 65.

---

## F-V2. ENCODING-SURFACE LOCKSTEP (FINAL §F + the nuclear/leak additions)
Carry ALL of FINAL §F (Check 44 reduced ×5 surfaces; Check 65 + test + allowlist; Check 59 EXPECTED_COUNT 62→63; Check 45 bijection; Checks 16/18/19/11/1; trinity parity ×2; tri-family lock). ADD:

| Surface | Constraint | Lockstep action (wave) |
|---|---|---|
| Check 22 `check_help_fragment_freshness` | requires + reads tracker_fragment; hard-fails on missing | W-NUCLEAR: remove tracker_fragment from both surface dicts + missing-fail; verify no surviving `pack tracker` verb token in its doc set |
| Check 23 `check_help_fragment_completeness` | requires + reads tracker_fragment; requires non-internal scripts listed | W-NUCLEAR: remove tracker_fragment read + missing-fail; mark `pack-tracker.sh`+`tracker-migrate.sh` `# pack-internal: true` |
| Check 39 `check_cmd_update_symmetry` | HELP-FRAGMENT-TRACKER §16a row | W-NUCLEAR: drop the row |
| Check 40 `check_bare_pack_ops_refs` | bare-ref allowlist HELP-FRAGMENT-TRACKER | W-NUCLEAR: drop the allowlist entries |
| Check 41 `check_client_installed_files` + install-map | "HELP-FRAGMENT.md" note + HELP-FRAGMENT-TRACKER install-map row | W-NUCLEAR: update comment; drop HELP-FRAGMENT-TRACKER install-map row |
| Check 43 `check_project_side_bare_internal_refs` | `_CHECK_43_PACK_OPS_CLIENT_INSTALLED` + `mirror_skip` + docstring | W-NUCLEAR: remove HELP-FRAGMENT-TRACKER from all three |
| Check 44 `_CHECK_44_DURABLE_DOCS` | lists `HELP-FRAGMENT-TRACKER.md` (deleted) + `HELP-FRAGMENT-PACK.md` ceiling | W-NUCLEAR: drop the TRACKER row; re-measure PACK ceiling |
| Check 47 `_SANCTIONED_PACK_SIDE_SHIPPED` | `pack-help.sh` membership | UNCHANGED (verify pack-help.sh still ships; no set growth) |
| `scripts/pack-help.sh` | the emit mechanism | W-NUCLEAR: rip the tracker-include path (N.1.3) |
| `scripts/migrate-v10-to-v11.sh:301` | copies client tracker fragment | W-NUCLEAR: drop from the copy loop |
| `scripts/init-project.sh:949-954` | copies client tracker fragment | W-NUCLEAR: drop the copy block |
| `scripts/pack-tracker.sh`, `scripts/tracker-migrate.sh` headers | Check-23 listing requirement | W-NUCLEAR: add `# pack-internal: true` |
| `scripts/tests/pack-help-test.sh` + check-22/23 test fixtures | assert tracker inclusion | W-NUCLEAR: rewrite to assert tracker ABSENT + `pack td` present |
| Checks 29/35/51 dormant-code guards | guard the dormant CODE | UNCHANGED — VERIFY still green post-strip |
| project trinity (L-1/L-2/L-3) | trinity parity (project loc) | W-LEAK/W4: strip the 3-site tracker passages, trinity-locked ×3 |
| client OPTIONAL-FEATURES / PM-CHAT / prompts / pm-startup / `_intro` ×3 / boundary-investigation | client-facing leak | W-LEAK: strip per the leak census (L-6..L-11, L-14) |
| pack `_intro` ×2 (OQV2-1) | EXEMPT but self-consistency | W2 (pack strip): strip the `_intro` tracker mention pending OQV2-1 confirmation |

**Asymmetric-coverage guard (unchanged):** any check whose body/constant a wave changes updates its per-check TEST in the SAME commit. The nuclear strip's check-body shrinks (22/23/39/40/41/43/44) each pair with their test edits in W-NUCLEAR.

---

## G-V2. WAVE MAP (FINAL §G waves + W-NUCLEAR + W-LEAK)
Carry FINAL W0-W6. Serialization constraints unchanged (trinity sets serialize; tri-family per role; same-file serialize; W0/W1 atomic). ADD two waves; place W-NUCLEAR EARLY (its check-body edits must land before the strip waves that depend on the gates being correct, and it is self-contained in scripts+validate-pack+fragments).

| Wave | Content | Parallel? | Lock |
|---|---|---|---|
| **W0 (gate)** | Check 44 reduction (5 surfaces) + Check 65 (+ test + allowlist sized to corrected ~136 IN) + EXPECTED_COUNT 62→63 | serial, ONE commit | validate-pack green incl. 59 + 43; Check 44/65 tests pass |
| **W-NUCLEAR (pack-help tracker strip — NEW, runs with/just after W0)** | DELETE both HELP-FRAGMENT-TRACKER files; rip tracker-include from `pack-help.sh`; migrate+init-project copy drops; mark 2 tracker scripts `# pack-internal: true`; edit Checks 22/23/39/40/41/43/44-durable-list; relocate `pack td` rows into HELP-FRAGMENT-PACK + client HELP-FRAGMENT; rewrite pack-help-test.sh + check-22/23 fixtures; STRIP pack-startup Step 8 + reserved comment | serial, ONE commit (cross-cutting validate-pack + scripts + fragments must stay green atomically) | full battery green: validate-pack (esp. 22/23/39/40/41/43/47/51/54) + pack-help-test.sh + test-migrate + test-init-project |
| **W1 (new rule)** | new rule ×6 trinity + RATIONALE `## operating-docs-no-history-no-bloat` | serial, ONE commit | Check 45 + 16/18/19 |
| **W2 (pack history-heavy strip)** | RATIONALE; MERGE-STRATEGY; OPTIONAL-FEATURES (incl. its "## Tracker integration (deferred)" section — pack-side IN-doc strip); CONCEPTUAL-REVIEW; backlog/_rules (OQ-2=c v8 clause + OQ-FINAL-3 `_rules` operative-only); PACK-CHAT (incl. tracker L53/69-77/430-434); PACK-AGENTS; DRY-RUN; changelog/_rules; **pack `_intro` ×2 tracker mention (OQV2-1, EXEMPT — strip pending confirmation)**; HELP-FRAGMENT-PACK light P1 (already handled in W-NUCLEAR for the tracker rows) | PARALLEL across distinct files | per-file; Check 65 green (IN docs); reviewer leak-check (EXEMPT `_intro`) |
| **W3 (root-trinity strip + bloat)** | CLAUDE/AGENTS/GEMINI: P2/P3 provenance + §0 deferred-feature mentions (tracker BD-214, BD-217/233 cross-CLI worktree, BD-218/241/225/226 tags) + OQ-3 carve-out rewrites + C.2 structural conversion | serial, ONE trinity commit | trinity parity + 16/18/19 + 45 |
| **W4 / W-LEAK (project trinity + client-facing leak strip)** | project-template CLAUDE/AGENTS/GEMINI tracker passages (L-1/2/3) + structural reduction; AND the client-facing leak strips: client OPTIONAL-FEATURES (L-6), PM-CHAT (L-7), prompts auditor/coder (L-8/L-9), pm-startup Step 7/8 (L-10), client `_intro` ×3 (L-11), boundary-investigation refs to the deleted fragment (L-14) | project trinity = serial ONE commit; the other client leak strips PARALLEL across distinct files | trinity parity (project loc) + 16/18/19; Check 40/43 (boundary refs) green post-fragment-deletion |
| **W5 (project bloat — agent defs)** | 16 roles ×3 families + RUNTIME-SUBAGENT-PATTERN (verify L-17 coder "Deferred items" KEEP across tri-family) | PARALLEL across roles; each role = ONE serial tri-family commit | tri-family lock per role |
| **W6 (project bloat — skills + docs/pack + prompts + stream-meta)** | 37 skills + 6 docs/pack + 10 prompts + 3 stream `_rules`/1 `_format` (NOT `_intro` — EXEMPT) (incl. OQ-B `audit-methodology/SKILL.md:76`) | PARALLEL | Check 1; same-file serialize |

**Sequencing note:** W-NUCLEAR before W2/W3/W4 because (a) it deletes the fragment the boundary-investigation refs (L-14) and Check 40/43 allowlists point at — those must be cleaned in coordination; (b) its check-body edits to 22/23 must be in place before any prose-doc tracker-verb strip, else Check 22 transiently fails on missing verb coverage. If the planner prefers, W-NUCLEAR and W0 MAY combine into one foundational commit (both are validate-pack-scoped) — planner's call; they MUST both precede the strip waves.

**BD-206 coordination (unchanged from FINAL):** BD-206 (PAUSED) handles the per-entry no-mirror FUNCTIONAL conversion; BD-243 handles operating-doc history/bloat/deferred-feature mentions + the nuclear pack-help strip + the leak axis. Check 65 number is taken by BD-243.

---

## CARRIED SECTIONS (from FINAL, unchanged unless a delta above touched them)
The following FINAL sections are AUTHORITATIVE as written in DESIGN-BD-243-FINAL.md and carried verbatim into FINAL-V2:
- **§B strip recipes** (P1-P8 + P-DEF; the K1-K11 KEEP allowlist; the FULL categorized per-IN-doc BD/TD census incl. all Status verdicts; the Open/Deferred roadmap-mention strips BD-110/109/234/136/218/217/233/215; the DROPPED-from-KEEP BD-214/217/215 reversal). **Delta:** the HELP-FRAGMENT-TRACKER row in §B.2 is superseded by the NUCLEAR delete (the file is gone, not P1-stripped); the OPTIONAL-FEATURES "## Tracker integration (deferred)" section strip is now explicit (W2).
- **§C terseness/structure bar** (B1-B4 bloat types; the C.2 clause-preserving trinity mega-rule method; C.3 reviewer before/after clause-set diff; C.4 sizing). Unchanged.
- **§D the new governance rule** (exact 3-ban text `operating-docs-no-history-no-bloat`; 6 trinity + RATIONALE bijection locations; D.3 surface-asymmetry; D.4 Check-45 lockstep 26↔26→27↔27; literal placeholders self-safe vs Check 65). Unchanged.
- **§E gate changes** (Check 44 reduction + Check 65) — carried, with the gate-scope shrink (corrected ~136 IN) + the `_CHECK_44_DURABLE_DOCS` HELP-FRAGMENT-TRACKER row removal noted above.
- **§H success confirmation** — carried, with the success criterion EXPANDED per D6 (below).

### Success criterion (EXPANDED — D6, replaces FINAL §H's bar)
NO meaning or functionality lost EXCEPT (a) the ONE new governance rule (D) AND (b) the DELIBERATE removal of blocked-feature advertising/leaks — a behavior change to features that DO NOT WORK today (the deferred tracker). Specifically the deliberate changes are: the new rule; `pack help` no longer emitting the tracker verb table (both surfaces); the migrator no longer copying the client tracker fragment; two dormant tracker scripts no longer advertised in help. The dormant tracker CODE/libs/example-templates and the dormant-code guards (Checks 29/35/51) are UNTOUCHED (BD-214). Everything else is delete-history / delete-deferred-feature-mention / restructure-bloat with zero behavior change (reviewer clause-set diff proves it).


---

## EMPIRICAL-EVIDENCE BLOCK (FINAL-V2 re-measurements; FINAL EE-1..EE-13 carried, the new deltas below)
Runtime: HEAD `a847f120e4ada06456bec4e2bf6d275fdd8c0742`, branch v11-dev, 2026-06-21, repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`. Graph queried for discovery (`graphify-out/graph.json`, 19.5 MB, built 2026-06-20) — STALE for BD-243 (returned unrelated PACK-REVIEW/validate-pack nodes on the `_intro` query) → G2 fallback to grep/Read/git for every exact-state claim.

**EE-V1 — runtime HEAD = BD-243 commit.** Cmd `git rev-parse HEAD; git branch --show-current`. Output `a847f120e4ada06456bec4e2bf6d275fdd8c0742` ; `v11-dev`. Conclusion: **SUPPORTED.**

**EE-V2 — `_intro.md` are human-orientation EXEMPT (CORRECTION A).** Cmd `grep -n "Audience: humans\|NOT read by agents\|carries NO rules" backlog/_intro.md`. Output (verbatim): `backlog/_intro.md:4 > **Purpose:** orientation. This file is NOT read by agents and carries` / (continuation) `NO rules.` (changelog/_intro.md carries the identical header). Interpretation: by criterion tie-breaker (2) human-orientation + the file's own self-declaration "NOT read by agents … NO rules," all `_intro.md` are EXEMPT, NOT IN. FINAL mis-classified them IN. Conclusion: **SUPPORTED** (gate scope −5 for the 5 `_intro`).

**EE-V3 — `pack help` DOES wire the tracker fragment (OQ-FINAL-1 NUCLEAR confirmed).** Cmd `grep -nE "emit_fragment \"|tracker_frag|HELP-FRAGMENT-TRACKER" scripts/pack-help.sh`. Output (verbatim): L72 `local tracker_fragment="$2"`; L77 `if [[ ! -f "$tracker_fragment" ]]; then`; L98 `awk -v tracker="$tracker_fragment" '`; L99 `/^\[Included from `(pack-ops\/)?HELP-FRAGMENT-TRACKER\.md`/ {`; call sites L143 (pack) + L146-147 (client) + L161/L170-171 (ambiguous). Plus `migrate-v10-to-v11.sh:301` `for help_src in HELP-FRAGMENT.md HELP-FRAGMENT-TRACKER.md; do`. Interpretation: `pack help` inlines the tracker fragment at BOTH surfaces; the migrator copies the client one. The fragment is LIVE help OUTPUT → a client running `pack help` sees the deferred-tracker table. Confirms NUCLEAR. Conclusion: **SUPPORTED.**

**EE-V4 — OQ-FINAL-2 sweep: NO executable tracker-detection step.** Cmd `grep -rnE -i "if tracker|tracker mode|detect.*tracker|tracker\.toml.*exist|skip.*tracker|tracker.*enabled"` over `.claude/skills/`, `.claude/agents/`, `project-template/skills/`, `project-template/.claude|.codex|.agents-plugin/`. Output (verbatim, only hit): `.claude/skills/pack-startup/SKILL.md:114:when tracker mode lands in pack-startup. Step 6 is open for future`. Plus the `-i tracker` pass surfaced pack-startup Step 8 (L121-129, "so this step surfaces nothing") + pm-startup Step 7 reserved comment (L210-211) + Step 8 (L217-225, "so this step surfaces nothing"). Interpretation: ALL are prose/reserved NO-OP mentions; ZERO executable `tracker.toml exists → skip` detection step. All resolve to STRIP; no SURFACE-to-user. Conclusion: **SUPPORTED.**

**EE-V5 — client-facing leak surfaces (CORRECTION B).** Cmd `grep -rln -i "tracker" project-template/ | grep -v test-fixtures` + per-file `grep -nE -i "tracker.*defer|tracker mode|dormant|GH Issues"`. Output (verbatim, leak sites): project trinity CLAUDE/AGENTS/GEMINI "Document locations" + "Per-entry source-of-truth trees" paras; `docs/pack/HELP-FRAGMENT-TRACKER.md` (whole, 54 ln); `docs/pack/HELP-FRAGMENT.md` include marker; `docs/pack/OPTIONAL-FEATURES.md:321-335`; `docs/pack/PM-CHAT.md:714,718,793,796`; `docs/pack/prompts/auditor.md:51`; `docs/pack/prompts/coder.md:68-69`; `skills/pm-startup/SKILL.md:85,210-211,217-225`; `docs/project/{backlog,changelog,implementation-plan}/_intro.md` (3-line deferred block each); `skills/boundary-investigation/SKILL.md:106-114` (refs the deleted fragment). NON-leak (KEEP): `tracker.toml.project-example` (dormant config), `.gitignore` (hygiene), `documentation/SKILL.md:20` ("issue tracker" = generic dep advice), coder agent-def "Deferred items" (TD workflow), `.github/ISSUE_TEMPLATE` "deferred" (work-item state). Interpretation: leak STRIP set L-1..L-11+L-14, sized exactly to deferred-tracker-FEATURE advertisements; generic "tracker"/"deferred" uses excluded. Conclusion: **SUPPORTED.**

**EE-V6 — nuclear strip ripples through ~7 validate-pack checks (encoding surfaces).** Cmd `grep -n "HELP-FRAGMENT-TRACKER" scripts/validate-pack.py` + per-check reads. Output (verbatim, key sites): Check 22 L2066/L2074 `tracker_fragment` + L2087-2089 `fail(... tracker fragment missing ...)`; Check 23 L2152 read + L2156-2157 missing-fail; Check 39 §16a row L4261; Check 40 allowlist L4297/L4623; Check 41 note L5098-5107; Check 43 `_CHECK_43_PACK_OPS_CLIENT_INSTALLED = ("pack-ops/HELP-FRAGMENT-TRACKER.md",)` L5584 + `mirror_skip` L5683 + docstring L5674; install-map L5475; init-project.sh L949-954; `_CHECK_44_DURABLE_DOCS` L7802 `("pack-ops/HELP-FRAGMENT-TRACKER.md", 57)`. Interpretation: deleting the fragment + ripping the include forces lockstep edits to Checks 22/23/39/40/41/43/44 + install-map + init-project + migrate + 2 tracker-script headers + pack-help-test.sh. Conclusion: **SUPPORTED** (the scope is materially larger than FINAL captured).

**EE-V7 — Check 23 requires the tracker scripts listed (OQV2-2).** Cmd `grep -l "pack-internal: true" scripts/pack-tracker.sh scripts/tracker-migrate.sh scripts/pack-td.sh`. Output (verbatim): (empty — none marked). Plus Check 23 docstring L2141 "Every top-level executable script in scripts/ must appear in HELP-FRAGMENT-PACK.md unless the script declares `# pack-internal: true`". Interpretation: to remove the 2 tracker dispatchers from help output without a Check-23 fail they must be marked `# pack-internal: true`; `pack-td.sh` stays listed (live feature). Conclusion: **SUPPORTED.**

**EE-V8 — dormant-code guards (Checks 29/35/51) do NOT read the fragment.** Cmd read `check_tracker_deferral_flip_block` (Check 51) docstring + legs. Output (verbatim): "leg 1 … `tracker-config.sh` … `PACK_TRACKER_DEFERRAL_OVERRIDE` + the dated BD-214 comment … leg 5: `tracker.toml.example` is absent from the init-project.sh install map." No HELP-FRAGMENT reference. Interpretation: Checks 29/35/51 guard the dormant CODE/state (BD-214) and survive the nuclear strip UNCHANGED; leg 5 is consistent with the strip direction. Conclusion: **SUPPORTED.**

**EE-V9 — pack-internal OPTIONAL-FEATURES tracker section + the EXEMPT pack `_intro` mention (OQV2-1).** Cmd `grep -nE -i "tracker|dormant|defer" pack-ops/OPTIONAL-FEATURES.md` + `grep -n tracker backlog/_intro.md`. Output (verbatim): `pack-ops/OPTIONAL-FEATURES.md:309 ## Tracker integration (deferred)` … L311 "DEFERRED indefinitely, with no release version (BD-214)" … L319-321 "DORMANT code (`scripts/lib/tracker-*.sh` …)"; `backlog/_intro.md:19 Tracker (GH Issues) integration is deferred (BD-214)`. Interpretation: pack OPTIONAL-FEATURES is gate-IN (operating doc) → §0 STRIP unconditional (W2). pack `_intro` is gate-EXEMPT (orientation) → leak axis does not reach it; architect recommends STRIP (OQV2-1) but surfaces for confirmation. Conclusion: **SUPPORTED.**

**EE-V10 — graph is STALE; G2 fallback exercised.** Cmd `graphify query "_intro.md human-readable orientation information doc" --graph .../graph.json --backend claude-cli --budget 1500`. Output (verbatim, first nodes): `NODE PACK-REVIEW — BD-196 C2 …`, `NODE check_template_archive_v11() …`, `NODE Informational — template archive directory v11.0 …` — all unrelated to `_intro` taxonomy. Interpretation: graph stale/unhelpful for BD-243-era discovery → fell through to grep/Read IMMEDIATELY for every exact-state claim (per §4 + G2). Conclusion: **SUPPORTED** (graph-first attempted, fallback correct).

(FINAL EE-1..EE-13 — next-free check 65; EXPECTED_COUNT 62→63; Check 44 pattern set + the 5 history patterns to MOVE; Check-44 test break; allowlist 6 `will`; 7 docs history-clean; 6 date examples K9-K11; FULL per-IN-doc BD/TD census with Status; OQ-A trinity tracker sites; OQ-2=c v8 clause + OQ-B dangling ref; OQ-3 carve-outs; project history-provenance≈0 + slug-unique; no `(BD-NNN)` on a CLAUDE.md heading — all carried, re-verified consistent at a847f12; nothing in those measurements changed.)

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **reconciliation-instance-independence** | Fresh v2 instance; did NOT author DESIGN-BD-243.md / DESIGN-BD-243-FINAL.md; am NOT the adversarial reviewer. Folded NEW rulings OQ-FINAL-1 (NUCLEAR, EE-V3) / OQ-FINAL-2 (sweep, EE-V4) / OQ-FINAL-3 + CORRECTION A (taxonomy, EE-V2) + CORRECTION B (leak axis, EE-V5) + scope expansion (D6). One evidence-based challenge/extension recorded: FINAL under-captured the encoding-surface ripple (EE-V6/EE-V7 — ~7 checks) → corrected, not contradicted. All rulings adopted as binding. | COMPLIANT |
| **agents-never-commit** | Only git verbs run: `git rev-parse HEAD`, `git branch --show-current`, `git log --oneline` (read-only). Sole write = this design doc via `cat >>` to `/tmp/pack-handoff-bd243-arch/DESIGN-BD-243-FINAL-V2.md`. No repo-file edit; no patch; no OptiquityTrader write. | COMPLIANT |
| **empirical-evidence-blocks [architect]** | EE-V1..EE-V10 each: command + verbatim output + HEAD `a847f12` + 2026-06-21 + interpretation + SUPPORTED. RE-MEASURED per charge: taxonomy re-verification per-category (§A + EE-V2); leak census every client-facing site file:line (Leak Census + EE-V5); pack-help tracker-inclusion path (EE-V3); OQ-FINAL-2 detection sweep (EE-V4); the encoding-surface ripple (EE-V6/EE-V7); dormant-code-guard survival (EE-V8). | COMPLIANT |
| **ci-guard-measure-then-bound [architect]** | (1) Measured the tree FIRST (EE-V2/V5/V6). (2) Categorized EVERY occurrence: corrected gate scope = ~136 IN (the EXEMPT-9 removed); leak census = STRIP L-1..L-11+L-14 vs KEEP L-12/13/15/16/17/18 by FUNCTION (deferred-tracker-FEATURE vs generic word). (3) Sized exactly: Check-65 `_CHECK_65_OPERATING_DOCS` = ~136 (no EXEMPT doc admitted); leak strip sized to deferred-tracker-FEATURE mentions only (generic "tracker"/"deferred" excluded). (4) Verify-clean post-strip: Check 65 scans the ~136 clean; the ~7 nuclear-touched checks pass with their bodies edited; Checks 29/35/51 unchanged-and-green (EE-V8). | COMPLIANT |
| **rules-applied-verification-block** | This table. | COMPLIANT |
| **enumerate-encoding-surfaces** | §F-V2 enumerates ALL: the nuclear strip touches Checks 22/23/39/40/41/43/44-durable-list + install-map + init-project.sh + migrate + 2 tracker-script headers + pack-help.sh + pack-help-test.sh + check-22/23 fixtures, EACH paired with its test in W-NUCLEAR; the gate-scope change updates Check 65's frozen IN-list + test; Checks 29/35/51 flagged UNCHANGED-verify; trinity parity ×2 + tri-family lock carried. EE-V6/EE-V7 measured the surfaces. | COMPLIANT |
| **graph-first-context** | Discovery query attempted FIRST (EE-V10) for taxonomy/sweep/leak-census; graph STALE → G2 fallback to grep/Read/git IMMEDIATELY (per §4 — no block, no defer-to-later). Injected absolute `--graph` path used verbatim; `--backend claude-cli`; `--budget 1500`; QUERY only, never built. | COMPLIANT |
| **deferral-is-scope-creep + no-deferral-without-user-direction** | Full final design now (taxonomy re-verified + leak census + nuclear spec + OQ-FINAL-2 sweep results + gate scope + encoding + waves). The nuclear pack-help strip + leak axis are USER-AUTHORIZED scope expansions (D6), not deferrals I introduced. The dormant tracker CODE/lib/example retention + Checks 29/35/51 are the STANDING BD-214 decision (not a deferral). Two genuine ambiguities surfaced as OQV2-1/OQV2-2 (architect-resolved with a recommendation + surfaced for confirmation), not self-authorized silently; nothing deferred to v11.1+. | COMPLIANT |
| **dependency-direction-placement [architect]** | `scripts/pack-help.sh` is in the frozen `_SANCTIONED_PACK_SIDE_SHIPPED` set (`{detect.sh, pack-help.sh}`, Check 47). Editing it (ripping the tracker-include) is a sanctioned-shipped-file change with a deliberate CLIENT-BEHAVIOR impact (client `pack help` stops emitting tracker); the frozen-set MEMBERSHIP is UNCHANGED (no growth → no architect+user sign-off needed). The 2 tracker dispatchers marked `# pack-internal: true` stay pack-side (dormant); they were never in the sanctioned-shipped set. | COMPLIANT |
| **architect-doc-reality-reconciliation [architect]** | The CONCISION-GUARDRAILS MOVE addendum (FINAL §E.1.e — history axis MOVED §6/Check 44 → Check 65, naming `check_operating_doc_no_history`) is CARRIED. NEW reconciliation: `_CHECK_44_DURABLE_DOCS` loses its `HELP-FRAGMENT-TRACKER.md` row (file deleted) — noted by file+symbol in §GATE SCOPE + §F-V2 (the addendum also notes the help-fragment family reclassified IN→EXEMPT). | COMPLIANT |
| **filename-uniqueness-heuristic** | Carried repo-unique names (function `check_operating_doc_no_history`; test `test-validate-pack-check-65.sh`; allowlist `pack-ops/.operating-doc-history-allowlist.txt`; slug `operating-docs-no-history-no-bloat`). No NEW file introduced by FINAL-V2 (the nuclear strip DELETES files; relocates content into existing HELP-FRAGMENT-PACK/HELP-FRAGMENT.md). Output doc `DESIGN-BD-243-FINAL-V2.md` is BD-243-unique. | COMPLIANT |

**END — DESIGN-BD-243-FINAL-V2.md (authoritative; supersedes DESIGN-BD-243-FINAL.md)**
