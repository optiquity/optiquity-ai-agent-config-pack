# CENSUS — History-Narrative Residue in PROJECT-side Operating Docs (BD-243)

**Repo:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`
**Branch:** `v11-dev` · **HEAD:** `522956f2e76d7ca0e867f655a66b3d8d778c12ac`
**Census date:** 2026-06-22 · **Scope:** PROJECT-side operating docs only (read-only)
**Governing rule:** project-audience `operating-docs-no-history-no-bloat` (shipped in `project-template/CLAUDE.md` § "Document locations")

> An OPERATING doc carries (a) ZERO historical/audit-trail text (dates, "X did Y" narration,
> provenance / "carried from" / "moved/retired/relocated/split in vN", version-provenance of past
> changes, incident or SHA refs); (b) ZERO deferred-feature description; (c) terse + structured.
> LIVE forward-pointers to CURRENT in-flight work are KEPT.

---

## 1. EXECUTIVE SUMMARY

**IN-set surface:** 108 operating-doc files enumerated and scanned (trinity 3; `docs/pack/*.md` 5 — HELP-FRAGMENT, OPTIONAL-FEATURES, PACK-FEEDBACK, PLATFORM-SKILLS, PM-CHAT; `docs/pack/prompts/*.md` 10; agent defs 49 = `.claude/agents` 16 + `.codex/agents` 16 + `.agents-plugin` 16 + RUNTIME-SUBAGENT-PATTERN 1; `skills/*/SKILL.md` 37; stream-meta contracts 4). NOTE: prompt-brief named METHODOLOGY.md + INSTALL-PROCEDURES.md under `docs/pack/` but neither exists in the tree at HEAD — actual `docs/pack/*.md` set is the 5 above.

**Search angles run (7):** (1a) version refs `v\d+\.\d` / `v1[01]`; (1b) relocation verbs split/relocated/moved/renamed/retired/formerly/previously/used-to/half-of/as-part-of/carved/extracted/superseded; (2) dates `\d{4}-\d{2}-\d{2}`; (3) past-action narration was-added/changed/now-lives/introduced-in/deprecated/NEW-in; (4) provenance per-BD/incident/SHA/pack-self IDs; (5) SHA refs `[0-9a-f]{7,40}`; (6) temporal words before-vN/since/no-longer/legacy/pre-vN/prior-version/sunset/absorb; (7) origin descriptions this-skill-is-the-half-of/originally/predecessor.

### Counts (history-narrative axis only)

| Classification | Count |
|---|---|
| **STRIP** (real history-narrative) | **11** |
| **BORDERLINE** (needs user ruling) | **6** |
| **KEEP** (legitimate — live pointer / rule self-def / current-feature label / format example / functional literal) | **17** (the load-bearing ones enumerated; the wide technical-vocabulary "split/legacy/previously/moved-a-field" coding-rule hits are NOT history and are excluded from the table) |
| SHA refs (angle 5) | 0 found in IN set |

### Files with STRIP/BORDERLINE hits (7)

| File | STRIP | BORDERLINE | Landed in |
|---|---|---|---|
| `docs/pack/PM-CHAT.md` | 4 | 0 | landed (not a CB-07/08 target; pre-existing) |
| `skills/python-server-architecture/SKILL.md` | 2 | 0 | pre-existing (CB-09b skills = floor, not yet stripped) |
| `skills/python-data-architecture/SKILL.md` | 2 | 0 | pre-existing |
| `skills/swift-best-practices/SKILL.md` | 1 | 0 | pre-existing |
| `docs/pack/PLATFORM-SKILLS.md` | 2 | 2 | pre-existing (CB-08 touched docs but did not strip history axis) |
| `project-template/{CLAUDE,AGENTS,GEMINI}.md` (trinity) | 0 | 3 | CB-07 LANDED (bloat only; history axis uncaught) |
| `skills/pm-startup/SKILL.md` | 0 | 1 | pre-existing |

**Headline:** The history-narrative axis is **uncaught** by the CB-07/CB-08 bloat commits and the CG-* strip commits. 11 hard STRIP occurrences across 5 files (PM-CHAT.md orphan-paths table is the densest — 4 "Retired/Moved in v10.0" rows; the three python/swift skill "split in v11.0 / relocated in v11.0" provenance blocks; two PLATFORM-SKILLS "not renamed in v11.0" / "pre-v11 model reclassification" notes). 6 BORDERLINE — all current-feature version LABELS (`(v11.0)`, `NEW in v11`, `(v11+)`, `v11.0 additions`) that could read as provenance — flagged for user ruling. No pack-self-ID leaks found in shipped project content beyond the deliberate boundary-rule deny-lists (those are legitimate — see §5 note).

---

## 2. PER-HIT TABLE

Classification key: **STRIP** = real history-narrative (recipe given); **KEEP** = legitimate (reason given); **BORDERLINE** = ambiguous (both readings + recommendation, user ruling needed).

| File:line | Verbatim text | Angle | Class | Recipe / Reason |
|---|---|---|---|---|
| `docs/pack/PM-CHAT.md:149` | `\| `PROMPT-TEMPLATES.md` (root) \| Retired before v10; per-agent prompt files in `docs/pack/prompts/` replaced it \|` | 1b retired | **STRIP** | History-narrative: "Retired before v10 … replaced it" is past-action provenance. KEEP the live operative fact (these paths are orphans that must be removed from the RAG index); STRIP the version-provenance. Recipe: collapse the "Why orphaned" cell to a present-tense reason — e.g. "Orphan path — no per-agent prompt file backs it; delete from index." Drop "Retired before v10". |
| `docs/pack/PM-CHAT.md:150` | `\| `docs/pack/PROMPT-TEMPLATES.md` \| Retired in v10.0 — replaced by per-agent files in `docs/pack/prompts/` \|` | 1a/1b retired in v10.0 | **STRIP** | Same pattern. Recipe: "Orphan — per-agent files in `docs/pack/prompts/` are the live form; delete from index." Drop "Retired in v10.0". |
| `docs/pack/PM-CHAT.md:151` | `\| `METHODOLOGY.md` (root) \| Moved to `docs/pack/METHODOLOGY.md` in v10.0 \|` | 1a/1b moved in v10.0 | **STRIP** | "Moved … in v10.0" = relocation provenance. KEEP the live pointer (canonical path is `docs/pack/METHODOLOGY.md`); STRIP the "in v10.0". Recipe: "Orphan root path — the live file is `docs/pack/METHODOLOGY.md`; delete the root entry from the index." |
| `docs/pack/PM-CHAT.md:152` | `\| `ARCHITECTURE.md` (root) \| Moved to `docs/project/ARCHITECTURE.md` in v10.0 \|` | 1a/1b moved in v10.0 | **STRIP** | Same. Recipe: "Orphan root path — the live file is `docs/project/ARCHITECTURE.md`; delete the root entry." Drop "in v10.0". (Whole §141-152 "Forbidden in the index" table is the strip site — its OPERATIVE content is "these paths are orphans, delete them via `local-rag.delete`"; the version-when-retired column is pure history.) |
| `skills/python-server-architecture/SKILL.md:15-18` | "This skill is the *server-specific* half of the v10.x `python-architecture` skill, split in v11.0 (the `python_data_marker_detected()` load predicate and the trinity SKILL.md split into `python-server-architecture` + `python-data-architecture`)." | 1a/1b/7 split in v11.0 | **STRIP** | Origin/version-provenance narration ("half of the v10.x … split in v11.0"). KEEP the live operative fact (this skill is server-specific; pairs with `python-data-architecture`; both load for a Python server, data-only loads alone). STRIP the v10.x ancestry + "split in v11.0". Recipe: rewrite to present-tense — "This skill covers server-specific Python architecture. Data and I/O rules live in `python-data-architecture`; both load for a Python server project, and `python-data-architecture` loads alone for non-server multi-file Python." |
| `skills/python-server-architecture/SKILL.md:20` | "moved to `python-data-architecture` and load independently …" | 1b moved to | **STRIP** | "moved to" is relocation provenance. KEEP the live fact (data rules LIVE in `python-data-architecture`). Recipe: "Data and I/O rules (repository pattern, N+1, Pydantic placement, ML isolation) live in `python-data-architecture` and load independently for server and non-server multi-file Python." Folded into the 15-18 rewrite. |
| `skills/python-data-architecture/SKILL.md:26-29` | "This skill is the *data and I/O* half of the v10.x `python-architecture` skill, split in v11.0 (the `python_data_marker_detected()` load predicate and the trinity SKILL.md split into `python-server-architecture` + `python-data-architecture`)." | 1a/1b/7 split in v11.0 | **STRIP** | Same provenance pattern, mirror file. KEEP the operative pairing fact; STRIP the v10.x ancestry + "split in v11.0". Recipe: "This skill covers data and I/O Python architecture (repository pattern, N+1 prevention, Pydantic placement, ML isolation); it pairs with `python-server-architecture` for server projects and loads alone for non-server multi-file Python." |
| `skills/swift-best-practices/SKILL.md:92` | "*(AsyncStream payload design — relocated to `swift-concurrency-patterns` as part of the v11.0 split into a separate skill.)*" | 1a/1b relocated/split | **STRIP** | Relocation provenance. KEEP the live cross-pointer (AsyncStream payload design is covered in `swift-concurrency-patterns`); STRIP "relocated … as part of the v11.0 split into a separate skill". Recipe: "*(AsyncStream payload design — see `swift-concurrency-patterns`.)*" |
| `docs/pack/PLATFORM-SKILLS.md:538` | "Existing skills are not renamed in v11.0 — the cost of breaking external references outweighs the consistency benefit." | 1a/1b renamed/v11.0 | **STRIP** | Version-anchored past-decision narration. KEEP the live rule (new skills follow the four-suffix convention; existing skills keep their names because renaming breaks external references). STRIP "in v11.0". Recipe: "Existing skills keep their current names — the cost of breaking external references outweighs the consistency benefit. New skills must follow this convention." |
| `docs/pack/PLATFORM-SKILLS.md:191-195` | "**14 Tier 0 base skills.** Several of these were classified as \"Tier 1 role skills\" in the pre-v11 model (notably `security-patterns`, `api-design`, `debugging`, and `ui-test-strategy`); they are universal-methodology skills and belong in Tier 0. The reclassification is documentation-only — no SKILL.md content changed." | 6 pre-v11/1a; 3 was classified | **STRIP** | Past-action narration ("were classified … in the pre-v11 model … The reclassification is documentation-only — no SKILL.md content changed"). KEEP the live fact (there are 14 Tier 0 base skills; these are universal-methodology skills). STRIP the pre-v11-model history + reclassification note. Recipe: "**14 Tier 0 base skills.** `security-patterns`, `api-design`, `debugging`, and `ui-test-strategy` are universal-methodology skills and load as Tier 0." |
| `docs/pack/PLATFORM-SKILLS.md:146-148` | "D5 absorbs the deployment skills that previously had no clean home in the four-dimension model (`deployment-apple` was implicitly carried by D1=Apple, `deployment-python` was implicitly carried by D3=Python server)." | 6 previously / 3 was carried | **STRIP** | Past-model narration ("previously had no clean home in the four-dimension model … was implicitly carried by …"). KEEP the live fact (D5 = deployment surface; it carries `deployment-apple` / `deployment-python`; it separates distribution/ops from D1 runtime and D3 app-layer). STRIP the four-dimension-model history. Recipe: "D5 is the deployment-surface axis. It carries `deployment-apple` and `deployment-python`, making the distribution / operations concern explicit and separate from D1 (runtime substrate) and D3 (app-layer role)." |
| `project-template/CLAUDE.md:231` (+ `AGENTS.md:217`, `GEMINI.md:228`) | "**Per-entry source-of-truth trees (v11.0).** Project streams under …" | 1a/section-label | **BORDERLINE** | Two readings: (a) CURRENT-FEATURE LABEL — "(v11.0)" names the version in which per-entry trees are the current mode (the trinity self-identifies as v11 at its copied-from line); harmless. (b) PROVENANCE — "(v11.0)" reads as "introduced in v11.0", which is when-it-was-added history. Recommendation: STRIP the "(v11.0)" parenthetical — the section operates identically without it ("**Per-entry source-of-truth trees.**"), and the rule forbids version-provenance labels. Trinity parity: strip all three in lock-step. **USER RULING.** |
| `docs/pack/PLATFORM-SKILLS.md:135` | "### Dimension 5 — Deployment surface (NEW in v11)" | 3 NEW in v11 | **BORDERLINE** | (a) CURRENT-FEATURE LABEL — flags D5 as the newest axis for a reader upgrading. (b) PROVENANCE — "NEW in v11" is explicitly when-it-was-added history (the angle-3 pattern). Recommendation: STRIP "(NEW in v11)" — heading reads "### Dimension 5 — Deployment surface"; the no-history rule treats "NEW in vN" as past-change narration. **USER RULING.** |
| `docs/pack/PLATFORM-SKILLS.md:556` | "plus the three v11.0 additions: `protobuf-patterns` …, `apple-swiftdata-patterns` …, and `swift-concurrency-patterns` …" | 3 additions / 1a v11.0 | **BORDERLINE** | (a) CURRENT-FEATURE LABEL — names the current `*-patterns` skills. (b) PROVENANCE — "v11.0 additions" = when-added history. Recommendation: STRIP "the three v11.0 additions:" → "plus `protobuf-patterns` (…), `apple-swiftdata-patterns` (…), and `swift-concurrency-patterns` (…)." The list is the live operative content; the "v11.0 additions" framing is history. **USER RULING.** |
| `docs/pack/PM-CHAT.md:703` | "## TD resolution orchestration (v11+)" | section-label/v11+ | **BORDERLINE** | (a) CURRENT-FEATURE LABEL — "(v11+)" signals this orchestration is available from v11 onward (a capability-version marker, like OPTIONAL-FEATURES' "v2.1.32+"). (b) PROVENANCE — could read as "added in v11". Recommendation: weak STRIP — heading works as "## TD resolution orchestration"; but "(v11+)" is a forward-availability marker more than past-narration, so this is the most defensible KEEP of the six. **USER RULING.** |
| `skills/pm-startup/SKILL.md:48` | "Sub-procedure 5-C.1 handles the legacy `_v9-backup.md` filename for pre-C7 v10.0 installs." | 6 legacy/pre-C7/v10.0 | **BORDERLINE** | (a) LIVE CONDITIONAL — describes a still-supported migration edge (a pre-C7 v10.0 install carries the old `_v9-backup.md` name; 5-C.1 still handles it) — operative as long as such installs can appear. (b) PROVENANCE — "pre-C7 v10.0 installs" + "legacy filename" is version-history framing, and "C7" is a pack-internal commit-batch token leaking into shipped project content. Recommendation: STRIP the pack-internal "pre-C7" token at minimum (it is a pack-self provenance leak); reword to a present-tense capability — "Sub-procedure 5-C.1 handles the older `_v9-backup.md` filename when present." Whether the whole migration-edge note KEEPs depends on whether the v9→v10 path is still live; the surrounding `pm-startup` migration-detection block (lines 22-39) IS live functional logic, so the edge likely stays — just de-historicized. **USER RULING** (esp. the "pre-C7" pack-token leak). |
| `docs/pack/PLATFORM-SKILLS.md:9-10` + `:162` | "Skill selection in v11 uses **five dimensions …**" / "Per-component fine-grained loading is not in scope for v11." | 1a v11 | **BORDERLINE** | (a) CURRENT-VERSION LABEL — "in v11" identifies the current model; the doc is the v11 pack's skill matrix. (b) Marginal provenance. Recommendation: KEEP-leaning — these read as "the current (v11) model is N dimensions", a present-state description, not past-change narration. line 162 "not in scope for v11" borders the deferred-feature axis (out of this census's history scope; flagged to the bloat/deferred census). Listed here for completeness; lowest strip-priority. **USER RULING (optional).** |
| `project-template/{CLAUDE,AGENTS,GEMINI}.md` ~244/231/242 | "…dated notes, \"X did Y\" past-action narration, provenance/\"carried from\" notes, incident or commit-SHA refs…" | 4 provenance / 6 carried-from | **KEEP** | The no-history rule's OWN self-defining text — it QUOTES the forbidden shapes to define them. Self-reference is exempt (mirrors pack-side Check-65 self-ref allowlist). Trinity-parallel across all three. |
| `project-template/{CLAUDE,AGENTS,GEMINI}.md` 456-462/460-461/518-519 | "…reconcile your customizations during a v10 → v11 migration. See MIGRATION-v10-to-v11.md § \"Step 2…\"" | 1a v10→v11 | **KEEP** | LIVE forward-pointer to the CURRENT upgrade path (v11 is current; v10→v11 migration is the live capability a client runs). Points to a live procedure doc, not past-action narration. |
| `docs/pack/HELP-FRAGMENT.md:1` | "# Pack v11 — verb reference (this project)" | 1a v11 | **KEEP** | Current-version self-identification of the shipped pack (the doc IS the v11 verb reference). Present-state label, not history. |
| `docs/pack/HELP-FRAGMENT.md:14` | "`bash scripts/migrate-v10-to-v11.sh` \| One-time per upgrade. The v9→v10 migrator is sunset." | 1a/6 sunset | **KEEP (with a borderline tail)** | The `migrate-v10-to-v11.sh` row is the LIVE current upgrade command (KEEP). The trailing "The v9→v10 migrator is sunset." is a deferred/retired-feature mention — arguably STRIP, but it is the deferred/retired axis not the history-narrative axis (flagged to that census; included here for completeness). Recommendation: KEEP the live command; consider dropping the "v9→v10 … sunset" tail at the bloat/deferred census. |
| `docs/pack/OPTIONAL-FEATURES.md:21,54` | "Experimental in Claude Code v2.1.32+ …" / "`claude --version` should report v2.1.32 or later" | 1a v2.1.32 | **KEEP** | Current minimum-version REQUIREMENT for an existing feature (tool capability gate), not pack-version provenance. Standard "requires version X+" doc text. |
| `docs/pack/PACK-FEEDBACK.md:28,40` / `:7` | "AI Agent Config Pack v11" / "Pack version in use \| v11.[N]" / "migrate-v10-to-v11.sh" | 1a v11 | **KEEP** | Current-version copied-from banner + a fill-in template field + a live upgrade-command reference. Present-state. |
| `docs/pack/PACK-FEEDBACK.md:357-358` | "**Asked by Pack Chat:** [v9 release date]" / "After the v9 split, `auditor-ui` covers only…" | 1b/2 v9 split / date | **KEEP (special-case — see note)** | PACK-FEEDBACK is by design an APPEND-ONLY feedback log of past questions raised to the pack; dated/versioned Q entries are its OPERATIVE content, not stray history-narrative in an instruction body. `[v9 release date]` is a placeholder, not a real date. This file is a borderline "operating doc vs history-home" — see §5 note; not on the STRIP work-list. |
| `skills/audit-methodology/SKILL.md:77` | "…If only the monolithic file exists (pre-v11.0 client, no decomposition applied), audit the monolithic file as before." | 6 pre-v11.0 | **KEEP** | LIVE CONDITIONAL — a present-tense branch in the audit rule ("if a pre-v11.0 client without decomposition is encountered, audit the monolith"). "pre-v11.0 client" names a current input state the auditor may meet, not a past change. "as before" is mild but operative (audit it the standard way). Low strip-priority; KEEP-leaning. |
| `docs/pack/PLATFORM-SKILLS.md:192` | "…classified as \"Tier 1 role skills\" in the pre-v11 model…" | 6 pre-v11 | (rolled into STRIP @191-195) | Counted in the STRIP row at 191-195, not double-listed. |
| `skills/pm-startup/SKILL.md:22,27,34,36` | `.pack-migration-backup/v9.3-to-v10.0/postrun-pending` / `_v9-backup.md` / `migration-v9-to-v10` branch / WARN string | 1a v9/v10 | **KEEP** | LIVE FUNCTIONAL LITERALS — these version strings are operative path/branch/filename tokens the migration-detection shell logic MATCHES at runtime (a glob path, a `git branch --show-current` comparison, a sentinel filename). Not prose history-narrative. They stay as long as the v9→v10 / v10→v11 migration code path is live. (The line-48 PROSE gloss is the borderline; the code literals are KEEP.) |
| `docs/project/{backlog,changelog,implementation-plan}/_rules.md:9` | "Pack version that minted this contract: v11.0" | 1a v11.0 | **BORDERLINE→KEEP-leaning** | A contract-metadata field naming the minting pack version — arguably provenance, but it is a deliberate machine-consumable contract-version field (like a schema `version:` key), not narrative. The stream-meta `_rules.md` are CONTRACTS; a version stamp on a contract is conventional. Low priority; KEEP-leaning. (Listed for completeness; flag if user wants contract-version stamps stripped too.) |
| `docs/project/changelog/_format.md:62-65` + `_rules.md:15` + `backlog/_rules.md:19` + `changelog/_rules.md:22` | example dates `2026-04-20` etc. / "v10-grammar" entry shape | 2 dates / 1a v10-grammar | **KEEP** | Format EXAMPLES the write-contract emits (the changelog example heading→filename mapping) + "v10-grammar" naming the CURRENT entry grammar these contracts produce. Example dates are illustrative template content, not audit-trail dates; "v10-grammar" is the live grammar name. |
| `docs/pack/PACK-FEEDBACK.md:155` | "Always include a date when changing Status: `Status: Ready (2026-06-15)`." | 2 date | **KEEP** | A format EXAMPLE the write-contract emits (illustrative dated-status sample), not an audit-trail date. |

### Excluded technical-vocabulary hits (NOT history-narrative — recorded so the census is auditable)

The angle-1b / angle-6 / angle-7 sweeps surfaced many uses of "split", "previously", "moved", "renamed", "legacy", "as part of", "superseded" that are CODING-RULE or SCHEMA vocabulary, NOT history about the pack. These are correctly **NOT** on the STRIP list:
- `coder.md:69` / `grpc-schema.md:11` / `audit-methodology` rule 22 / `planning:19` / `testing:16` / `apple-architecture-core:57` / `python-best-practices:50` / `cpp-language:28` — "split [behavior/services/the test]" as a design instruction.
- `protobuf-patterns:105,112` / `swift-concurrency-patterns:25,409` / `apple-swiftdata-patterns:181` / `macos-architecture:56` — "previously-set field", "moving a field INTO a oneof", "previously top-level", "Task.detached in a previously structured", "formerly Automator actions", "previously-uninstrumented" — schema/concurrency semantics + Apple API naming.
- "legacy" coding-rule hits: `objc-language:3,34`, `swift-concurrency-patterns:25,119,255,257,262,384`, `swift-best-practices:63,70`, `protobuf-patterns:142`, `python-observability-patterns:35,234`, trinity refactoring rule "When touching legacy code…", `PLATFORM-SKILLS:435` objc-language description — all describe handling pre-existing CODE in the client's project, not pack history.
- `documentation:38-39` / `auditor-docs` "removed functions, renamed parameters" — a drift-detection rule about the CLIENT's code/docs.
- `dependency-python:11` "archived, deprecated, or superseded" — a dependency-evaluation rule.
- `implementation-plan/_rules.md:30-31` "superseded-by / ➡ (merged / superseded)" — a live phase-state vocabulary in the contract.
- `PACK-FEEDBACK:313,320,358,364` / `audit-methodology:51` "splits observability", "iPad split-view", "the v9 split" (auditor scope) — auditor-scope description (the "v9 split" at 358 is inside the PACK-FEEDBACK log special-case, §5).
- `PM-CHAT:719,736` / `OPTIONAL-FEATURES:386` "absorbing phase / absorbs them all / Split long-running shards" — live orchestration + sharding instruction.

---

## 3. PER-FILE STRIP WORK-LIST (the strip set, sized to real history-narrative only)

**5 files, 11 STRIP occurrences. Recipes preserve all operative content; only version/relocation/past-action history is removed.**

### A. `project-template/docs/pack/PM-CHAT.md` — 4 strips (lines 147-152, the "Forbidden in the index" orphan-paths table)
- The table's OPERATIVE purpose KEEPS: these paths are RAG-index orphans; each must be removed via `local-rag.delete <path>`.
- STRIP the version-provenance in every "Why orphaned" cell:
  - :149 drop "Retired before v10" → present-tense orphan reason.
  - :150 drop "Retired in v10.0 — replaced by" → "per-agent files in `docs/pack/prompts/` are the live form".
  - :151 drop "Moved to … in v10.0" → keep the live path "`docs/pack/METHODOLOGY.md`".
  - :152 drop "Moved to … in v10.0" → keep the live path "`docs/project/ARCHITECTURE.md`".
- Also de-historicize the header line 141 "retired paths from prior pack versions" → "orphan paths (no live file backs them)".

### B. `project-template/skills/python-server-architecture/SKILL.md` — 2 strips (lines 15-18, 20)
- STRIP "the *server-specific* half of the v10.x `python-architecture` skill, split in v11.0 (…)" and "moved to `python-data-architecture`".
- KEEP: server-specific scope; pairs with `python-data-architecture`; both load for a server, data-only loads alone; data rules LIVE in `python-data-architecture`. Present-tense rewrite per §2 recipe.

### C. `project-template/skills/python-data-architecture/SKILL.md` — 2 strips (lines 26-29)
- STRIP "the *data and I/O* half of the v10.x `python-architecture` skill, split in v11.0 (…)".
- KEEP: data/I/O scope (repository pattern, N+1, Pydantic placement, ML isolation); pairs with `python-server-architecture`; loads alone for non-server multi-file Python. (Mirror-symmetric with B.)

### D. `project-template/skills/swift-best-practices/SKILL.md` — 1 strip (line 92)
- STRIP "relocated to `swift-concurrency-patterns` as part of the v11.0 split into a separate skill".
- KEEP the live cross-pointer: "*(AsyncStream payload design — see `swift-concurrency-patterns`.)*"

### E. `project-template/docs/pack/PLATFORM-SKILLS.md` — 2 strips (lines 146-148, 191-195) [538 is BORDERLINE, see §4]
- :146-148 STRIP "absorbs the deployment skills that previously had no clean home in the four-dimension model (… was implicitly carried by …)". KEEP: D5 = deployment surface; carries `deployment-apple`/`deployment-python`; separates ops from D1/D3.
- :191-195 STRIP "Several of these were classified as \"Tier 1 role skills\" in the pre-v11 model … The reclassification is documentation-only — no SKILL.md content changed." KEEP: "14 Tier 0 base skills; `security-patterns`, `api-design`, `debugging`, `ui-test-strategy` are universal-methodology skills and load as Tier 0."

**Cross-cutting note:** B/C/D are SKILL.md files. CB-09b (skills §A bloat) is the floor and the skills history axis is NOT yet stripped — these 5 strips land with whatever commit handles project-skill history. A/E are `docs/pack/` files CB-08 touched for bloat but did NOT strip on the history axis.

---

## 4. BORDERLINE LIST — needs USER RULINGS (6)

All six are current-feature/version LABELS that could read either as a helpful "this is the current model" tag or as "added-in-vN" provenance the rule forbids. Recommendation column gives the census's lean; the user decides.

| # | Site(s) | Text | Census recommendation |
|---|---|---|---|
| BL-1 | trinity `CLAUDE.md:231` / `AGENTS.md:217` / `GEMINI.md:228` | "**Per-entry source-of-truth trees (v11.0).**" | **STRIP** the "(v11.0)" parenthetical (lock-step across trinity). Section operates identically; "(vN.0)" is when-added framing. |
| BL-2 | `PLATFORM-SKILLS.md:135` | "### Dimension 5 — Deployment surface (NEW in v11)" | **STRIP** "(NEW in v11)" — "NEW in vN" is the angle-3 past-change form. |
| BL-3 | `PLATFORM-SKILLS.md:556` | "the three v11.0 additions: `protobuf-patterns` …" | **STRIP** the "v11.0 additions:" framing; keep the skill list. |
| BL-4 | `PM-CHAT.md:703` | "## TD resolution orchestration (v11+)" | WEAK — most defensible KEEP (forward-availability marker like "v2.1.32+"); strip "(v11+)" if rulings favor zero version labels in headings. |
| BL-5 | `pm-startup/SKILL.md:48` | "the legacy `_v9-backup.md` filename for pre-C7 v10.0 installs" | **STRIP at least the "pre-C7" pack-internal token** (a pack-self provenance leak in shipped project content); reword to present-tense capability. Whole-edge KEEP iff the v9 migration path is still live. |
| BL-6 | `PLATFORM-SKILLS.md:9-10,162` | "Skill selection in v11 uses…" / "not in scope for v11" | KEEP-leaning (present-state model label). The :162 "not in scope for v11" is deferred-axis, not history — defer to the bloat/deferred census. |

**Two adjacent-axis tails flagged (NOT history-narrative; for the deferred/retired census, recorded here so nothing is lost):**
- `HELP-FRAGMENT.md:14` "The v9→v10 migrator is sunset." (retired-feature mention).
- `PLATFORM-SKILLS.md:162` "Per-component fine-grained loading is not in scope for v11." (deferred-feature mention).
- (Contract-version stamps `_rules.md:9` "Pack version that minted this contract: v11.0" — flagged KEEP-leaning in §2; raise only if the user wants contract metadata stripped.)

---

## 5. PACK-PROJECT SEPARATION — leak notes (separate from the history axis)

- **No illegitimate pack-self-ID leak in shipped project prose.** Every `PACK-AGENTS.md` / `pack-ops/` / `maintenance-docs/` / `BD-`/`pack-*` occurrence in the IN set is INSIDE a deliberate boundary-rule deny-list or anti-pattern enumeration: `boundary-investigation/SKILL.md` (the SSOT-investigation skill names pack-self artifacts as the forbidden-token set it teaches agents to catch), trinity `## Project memory` DENY-LIST-CONTENT block, `coder.md`/`reviewer.md` prompts (forbidden-token lists), `boundary-investigation:33` "audit incident (P-missed-7)". These are the SKILL/rule's operative subject matter (what to detect), NOT contamination — **KEEP**. `boundary-investigation:33` "The audit incident (P-missed-7) documented…" is mild past-tense narration but is the rule's rationale anchor; borderline-KEEP (raise separately if the strip wants rationale-narration removed too — out of this census's primary STRIP scope).
- **One genuine pack-internal token leak:** `pm-startup/SKILL.md:48` "pre-C7" (a pack commit-batch token) in shipped client content — captured as BORDERLINE BL-5; this is the only true pack→project leak the census found, and it rides on the history-strip.
- **PACK-FEEDBACK.md special case:** This file is an append-only Q&A feedback LOG (dated/versioned past questions to the pack are its operative content). It sits ambiguously between "operating doc" and "history-home". The census treats its dated/versioned entries as the file's legitimate content (KEEP, §2) and puts NOTHING from it on the STRIP work-list — but flags to the architect that whether PACK-FEEDBACK is an operating doc subject to the no-history rule, or a history-home excluded from it, is a scoping decision for the user/architect.

---

## 6. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted command / output) | Conclusion |
|---|---|---|
| **agents-never-commit** | Only writes were `cat > /tmp/pack-handoff-bd243-arch/CENSUS-...md` heredocs (to /tmp, outside the repo). Zero `git add`/`commit`/`mv`/`rm`/edit of any repo file; all repo access was `git rev-parse`, `git log`, `grep`, `sed -n`, `ls`, `Read` (read-only). | COMPLIANT |
| **external-rules-census-before-design** | Enumerated the COMPLETE IN set first: `wc -l /tmp/bd243-inset.txt` → `108`; ran 7 distinct search angles (1a/1b/2/3/4/5/6/7) over that set, not just the 5 spot-check examples (all 5 spot-checks — PM-CHAT:150-152, swift-best-practices:92, python-*:15-28, CLAUDE.md:231, PLATFORM-SKILLS:538,556 — were independently re-found by the angles AND classified). Recall widened beyond spot-checks (found PM-CHAT:149/141, PLATFORM-SKILLS:146-148/191-195, pm-startup:48). | COMPLIANT |
| **measure-then-bound** | Every occurrence classified individually STRIP/KEEP/BORDERLINE with quoted evidence; STRIP work-list sized to exactly 11 real history-narrative hits (excluded technical-vocab "split/legacy/moved-a-field" coding-rule hits explicitly enumerated in §2 sub-list to prove they were measured-then-rejected, not missed). | COMPLIANT |
| **pack-project separation of concerns** | Greps scoped to `/tmp/bd243-inset.txt` (project-template files only); zero pack-side file censused. Pack-self leaks flagged separately in §5 (pm-startup:48 "pre-C7" the one genuine token leak; deny-list/skill occurrences classified KEEP as deliberate subject matter). | COMPLIANT |
| **scope-deliverables-to-the-ask** | Delivered the history-narrative census only; deferred/retired-feature tails (HELP-FRAGMENT:14, PLATFORM-SKILLS:162) and bloat axis NOTED as incidental finds + routed to their own census, not audited here. | COMPLIANT |
| **graph-first-context** | Ran G1 against the injected graph path `graphify-out/graph.json`: `stat` showed mtime `Jun 22 13:02` vs HEAD commit date `Jun 22 19:49:45` → graph built BEFORE HEAD 522956f = STALE; invoked G2 fallback to grep/Read immediately for the exhaustive census (verification gate). The injected absolute path was used verbatim for the existence check; never recomputed from own toplevel. | COMPLIANT (G2 fallback fired on documented staleness) |
| **rules-applied-verification-block** | This table. | COMPLIANT |
