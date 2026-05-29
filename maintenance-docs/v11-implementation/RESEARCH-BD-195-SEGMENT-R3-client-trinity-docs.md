# RESEARCH-BD-195-SEGMENT-R3-client-trinity-docs

## Segment / owned paths (manifest)

Segment R3 — Client-shipped product: trinity + docs/pack + docs/project.

- `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md` (trinity)
- `project-template/docs/pack/` — `PM-CHAT.md`, `PLATFORM-SKILLS.md`, `PACK-FEEDBACK.md`, `OPTIONAL-FEATURES.md`, `HELP-FRAGMENT.md`, `HELP-FRAGMENT-TRACKER.md`, `prompts/` (10 files). (`METHODOLOGY.md`/`INSTALL-PROCEDURES.md` referenced from here live in `supporting-docs/`, owned by another segment.)
- `project-template/docs/project/` per-entry trees: `backlog/`, `implementation-plan/`, `changelog/` — `_rules.md` / `_intro.md` / `_format.md`
- `project-template/README.md`

## Coverage attestation
Every owned path read in full. Trinity and per-entry trees read fully; all 10 prompts scanned for boundary/version leaks (coder/reviewer/pm-chat read in targeted sections at every hit; short prompts wholesale). Supporting evidence read out-of-segment to verify client reachability: `scripts/init-project.sh` S6 + `_CLIENT_INSTALLED_FILES` inventory, `scripts/lib/per-entry/` (mirror-generate/toc-regenerate/_lib), `scripts/validate-pack.py` Check 32/33 scope, repo-root README version table. No path skimmed without follow-up.

## Findings count
BLOCKER 0 / MUST 1 / SHOULD 4 / NIT 2

---

## Findings

### R3-F01 — `docs/pack/PM-CHAT.md` cites a client-side `docs/pack/MERGE-STRATEGY.md` that is never installed
- Severity: MUST
- Category: C (cross-reference) + B (boundary/separation-of-concerns) + E (ENCODING)
- Surface(s): `project-template/docs/pack/PM-CHAT.md` § "Recommendation routing (v11+)" — `... see` / `docs/pack/MERGE-STRATEGY.md` / (DENY-wrapped) `(or pack-ops/MERGE-STRATEGY.md in the pack repo).`
- Side: client-shipped
- Evidence: PM-CHAT.md's primary path is `docs/pack/MERGE-STRATEGY.md`, with `pack-ops/MERGE-STRATEGY.md` only as a DENY-LIST-wrapped pack-repo fallback. But `MERGE-STRATEGY.md` exists ONLY at `pack-ops/MERGE-STRATEGY.md`. It is not in `project-template/docs/pack/`, and `scripts/init-project.sh` `_CLIENT_INSTALLED_FILES` (lines 1273–1311) has no MERGE-STRATEGY row — S6 copies all `project-template/docs/pack/*.md` plus METHODOLOGY/INSTALL-PROCEDURES from supporting-docs, none of which is MERGE-STRATEGY. So `docs/pack/MERGE-STRATEGY.md` does not exist at any client install.
- Why it's a problem: A client-shipped file points the PM chat at a `docs/pack/` path that resolves to nothing at the client (cross-reference-integrity violation) and surfaces a pack-only artifact as a client `docs/pack/` path (separation-of-concerns). The same content is referenced *correctly* one file over: `OPTIONAL-FEATURES.md` § "Tracker integration" → "See `MERGE-STRATEGY.md` **in the pack repo**." PM-CHAT.md's `docs/pack/`-prefixed primary form is the defect.
- Recommendation: Drop the `docs/pack/MERGE-STRATEGY.md` primary path; make the pack-side qualification primary (mirror OPTIONAL-FEATURES.md: "see `MERGE-STRATEGY.md` in the pack repo (`pack-ops/MERGE-STRATEGY.md`)"), kept DENY-LIST-wrapped. Do NOT add MERGE-STRATEGY.md to the client inventory — it is pack-internal design material, not client-runtime-needed.
- Cross-segment touch points: `pack-ops/MERGE-STRATEGY.md`; `scripts/init-project.sh` `_CLIENT_INSTALLED_FILES`.
- Confidence: high (verified only location is `pack-ops/`, absence from client inventory + S6 globs, and OPTIONAL-FEATURES.md's correct phrasing).

### R3-F02 — `docs/pack/PACK-FEEDBACK.md` is stamped/operated as v9 throughout (client-shipped, v11)
- Severity: SHOULD
- Category: A (version) + staleness
- Surface(s): `project-template/docs/pack/PACK-FEEDBACK.md` — Status row `| Pack version in use | v9.[N] |`; "broken v9 defect"; "seed questions from the v9 auditor fix pass"; every Q1–Q6 `**Asked by Pack Chat:** [v9 release date]` / `**Last updated:** [v9 release date] (seeded)`; Q6 "while using v9".
- Side: client-shipped
- Evidence: 17 `v9` occurrences in this file. Header (line 28) declares "AI Agent Config Pack v11", yet the operating-version default is `v9.[N]` and the whole Open-Questions framing presents the pack as v9-era. (Contrast the single `v9` in PM-CHAT/HELP-FRAGMENT/trinity, which are migration-history, not operating-version.)
- Why it's a problem: Lens A — pack is v11.0 (repo-root README dates v11.0 May 2026). The default placeholder and seed-stamps are stale; a v11 install ships a feedback log telling the PM chat the pack is v9.
- Recommendation: Bump the `Pack version in use` default to `v11.[N]` (or neutral `[pack version]`); "broken v9 defect" → "broken pack defect"; re-stamp Q1–Q6 `[v9 release date]` → `[pack release date]` / v11 date; make the seed-context block version-neutral. Confirm with user whether the v9-auditor-split seed set is still the intended v11 seed (the split still ships in v11).
- Cross-segment touch points: `supporting-docs/METHODOLOGY.md` Part 10 (stamped v10 — coordinate sweep).
- Confidence: high.

### R3-F03 — `docs/pack/prompts/pm-chat.md` kickoff template hardcodes "Pack version: AI Agent Config Pack v10"
- Severity: SHOULD
- Category: A (version) + staleness
- Surface(s): `project-template/docs/pack/prompts/pm-chat.md` kickoff variant — `**Pack version:** AI Agent Config Pack v10`.
- Side: client-shipped
- Evidence: The kickoff prompt block hardcodes `v10` as the pack version, in a v11 pack, while sibling fields are bracketed placeholders.
- Why it's a problem: Lens A — a v11 client's PM-chat kickoff states the pack is v10.
- Recommendation: Change to `AI Agent Config Pack v11`, preferably `**Pack version:** [pack version, e.g. v11.0]` to match surrounding fill-in placeholders and avoid re-staling.
- Cross-segment touch points: version sweep with R3-F02/R3-F06.
- Confidence: high.

### R3-F04 — `project-template/README.md` titled v10 and overstates/understates shipped counts
- Severity: SHOULD
- Category: A (version) + C (cross-reference) + B (boundary) + count-accuracy
- Surface(s): `project-template/README.md` — title `# Project Template — AI Agent Config Pack v10` (line 1); METHODOLOGY-location paragraph citing `V10-DESIGN.md Part 7 §7.6` (lines 9, 13); "What this template contains" table "Skills | ... | 30 skills per tool" (line 23); also "16 agents", "15 scripts".
- Side: maintenance-doc (README is NOT client-installed — see Why)
- Evidence: (a) title v10, pack is v11.0; (b) `V10-DESIGN.md Part 7 §7.6` resolves only to `maintenance-docs/archive/V10-DESIGN.md` (pack-internal archived design doc) and is bare-version-shorthand with no reader-resolvable path; (c) "30 skills per tool" conflicts with the actual `project-template/skills/` count (36 directories) and with PLATFORM-SKILLS.md "Total skills: 36" — off by 6.
- Why it's a problem: Lens A (stale title), Lens C (V10-DESIGN cite resolves only to archive; section-shorthand has no path), internal-consistency conflict (36 vs 30). Mitigation: `init-project.sh` never copies this README to a client; fixtures carry no template README; audience is a pack maintainer / manual `cp -r` user — hence maintenance-doc severity, not a client leak. Still wrong on the pack's own surface.
- Recommendation: (a) retitle v11; (b) replace the V10-DESIGN authority cite with a client-resolvable statement (METHODOLOGY installs to `docs/pack/METHODOLOGY.md`) or qualify it as pack-internal history; (c) fix skill count to 36 and re-verify the 16-agents/15-scripts numbers while editing. Surface to user whether this README should ship to clients at all or be relabeled pack-maintainer-only.
- Cross-segment touch points: `project-template/skills/` (36 authoritative); `maintenance-docs/archive/V10-DESIGN.md`; repo-root README version table (v11.0).
- Confidence: high (counted 36 skill dirs; V10-DESIGN only in archive; README not in inventory/fixtures).

### R3-F05 — `docs/pack/HELP-FRAGMENT.md` foregrounds the v9→v10 migrator on a v11 pack; v10→v11 migrator demoted to a footnote
- Severity: SHOULD
- Category: A (version) + C (cross-reference) + upgrade-path-correctness
- Surface(s): `project-template/docs/pack/HELP-FRAGMENT.md` § "Project commands" — `| bash scripts/migrate-v9-to-v10.sh | One-time per upgrade. v10→v11 migrator ships separately. |`.
- Side: client-shipped
- Evidence: The v11 help fragment lists `migrate-v9-to-v10.sh` as the prominent migrator and relegates the current-upgrade migrator to "ships separately." `scripts/migrate-v10-to-v11.sh` exists (47KB, executable) in the same `scripts/`.
- Why it's a problem: Lens A/C — a v11 help surface points at the prior-cycle migrator; "ships separately" is inaccurate (both are in `scripts/`). A client looking up the upgrade command is misdirected.
- Recommendation: Make `bash scripts/migrate-v10-to-v11.sh` the listed migrator ("One-time per upgrade from v10 to v11"); if keeping a v9→v10 reference, list it as the older/secondary verb; drop "ships separately."
- Cross-segment touch points: `scripts/migrate-v10-to-v11.sh`; pack-root `CLAUDE.md` already treats it as the current migrator.
- Confidence: high.

### R3-F06 — `PLATFORM-SKILLS.md` cites the pack-repo trinity `## Pack memory` from a client-shipped, RAG-indexed surface
- Severity: NIT
- Category: B (boundary/token-economy) + C (cross-reference)
- Surface(s): `project-template/docs/pack/PLATFORM-SKILLS.md` § "Extending this file" → "Naming convention for new skills" → Maintainability-rule blockquote: "See the pack-repo trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` `## Pack memory`) ..."; also the same section's "See the dimension extension rules in the pack's design documentation ..." (no path).
- Side: client-shipped
- Evidence: `## Pack memory` is a pack-repo-only construct (project trinity carries `## Project memory`). Clients have no pack-repo trinity. PLATFORM-SKILLS.md ships to clients (S6, `_CLIENT_INSTALLED_FILES`) and is re-read at every prompt generation — high token-query exposure.
- Why it's a problem: Lens B — pack-only concept on a client-facing, frequently-queried surface; per the client-facing token-economy rule, pack-only references are removed unless client-NECESSARY. The mechanical-vs-structural threshold is a pack-maintenance concern. "the pack's design documentation" is also unresolvable (no path). NIT (not MUST) because the references are "see the pack repo"-framed and don't assert a broken client path.
- Recommendation: Either drop the `## Pack memory` pointer + "pack's design documentation" sentence (keep the client-relevant naming convention + `x-` preservation rule inline), or restate the maintainability framing client-side without a pack-only pointer.
- Cross-segment touch points: pack-root trinity `## Pack memory`.
- Confidence: medium (boundary call; reasonable to rate SHOULD vs NIT; flagged NIT on the conservative reading).

### R3-F07 — Trinity parity: `AGENTS.md` iOS-26 Xcode bundle line lacks the `$XCODE_APP` relocation mechanism that CLAUDE.md/GEMINI.md document
- Severity: NIT
- Category: D (trinity/parity)
- Surface(s): `project-template/AGENTS.md` § "[CONDITIONAL] iOS 26 / Xcode 26.3 platform features" — hardcoded `/Applications/Xcode.app/Contents/...` with no override; vs `project-template/CLAUDE.md` / `project-template/GEMINI.md` same section using `$XCODE_APP/Contents/...` + "where `$XCODE_APP` defaults to `/Applications/Xcode.app` — override in `.claude/settings.json` env block / `.gemini/.env` if Xcode is installed elsewhere."
- Side: client-shipped
- Evidence: CLAUDE.md and GEMINI.md expose a relocatable-Xcode capability (`$XCODE_APP` var + per-CLI override location). AGENTS.md hardcodes the default with no variable/override note.
- Why it's a problem: Lens D — trinity asymmetry is allowed only when provably tool-specific. The AGENTS.md concise-body convention justifies terser prose, but the `$XCODE_APP` override is a *capability*, not verbosity — omitting it removes a behavior. The per-CLI override LOCATION is legitimately tool-specific (`.claude/settings.json` vs `.gemini/.env` vs Codex env), but the *existence* of the mechanism should be parity-held.
- Recommendation: Add `$XCODE_APP` + a Codex-appropriate override location to AGENTS.md (concise but capability-preserving). If the user judges this provably tool-specific, document that justification at the asymmetry instead.
- Cross-segment touch points: none (all three trinity files in-segment).
- Confidence: medium (parity-substance call).

---

## Coverage map

| Owned path | Result |
|---|---|
| `project-template/CLAUDE.md` | clean (`.claude/settings.json` ref BD-182-correct; carries override capability) |
| `project-template/AGENTS.md` | R3-F07 |
| `project-template/GEMINI.md` | clean (`.gemini/.env` BD-182-correct; GEMINI-only `## Agent roster` is a documented trinity-rule exception) |
| `project-template/README.md` | R3-F04 |
| `project-template/docs/pack/PM-CHAT.md` | R3-F01 |
| `project-template/docs/pack/PLATFORM-SKILLS.md` | R3-F06 |
| `project-template/docs/pack/PACK-FEEDBACK.md` | R3-F02 |
| `project-template/docs/pack/OPTIONAL-FEATURES.md` | clean (MERGE-STRATEGY ref correctly pack-side-qualified; "v11.0+" correct) |
| `project-template/docs/pack/HELP-FRAGMENT.md` | R3-F05 |
| `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` | clean |
| `project-template/docs/pack/prompts/pm-chat.md` | R3-F03 |
| `project-template/docs/pack/prompts/coder.md` | clean (pack-only refs DENY-LIST-wrapped boundary teaching) |
| `project-template/docs/pack/prompts/reviewer.md` | clean (pack-only refs DENY-LIST-wrapped boundary teaching) |
| `project-template/docs/pack/prompts/architect.md` | clean |
| `project-template/docs/pack/prompts/planner.md` | clean |
| `project-template/docs/pack/prompts/auditor.md` | clean |
| `project-template/docs/pack/prompts/tester.md` | clean |
| `project-template/docs/pack/prompts/docs-researcher.md` | clean |
| `project-template/docs/pack/prompts/grpc-schema.md` | clean |
| `project-template/docs/pack/prompts/repo-ops.md` | clean |
| `project-template/docs/project/backlog/_rules.md` | clean (`_toc.md` in support list is runtime-generated, correctly unshipped) |
| `project-template/docs/project/backlog/_intro.md` | clean (mirror-perspective prose is by-design Layer-1 preamble, sourced verbatim into BACKLOG.md) |
| `project-template/docs/project/implementation-plan/_rules.md` | clean |
| `project-template/docs/project/implementation-plan/_intro.md` | clean |
| `project-template/docs/project/changelog/_rules.md` | clean |
| `project-template/docs/project/changelog/_intro.md` | clean |
| `project-template/docs/project/changelog/_format.md` | clean |

### Investigated and cleared (not findings)
- **`_toc.md` absent from template streams** — runtime-regenerated by `scripts/lib/per-entry/toc-regenerate.sh` from entries; template streams ship empty (no entries → no TOC). Correctly excluded from `_CLIENT_INSTALLED_FILES`; `_rules.md` "Supporting files" lists document what helpers emit at runtime.
- **`docs/pack/PROMPT-TEMPLATES.md` references** — only in PM-CHAT.md's "Forbidden in the index / retired path" RAG-orphan table. Intentional.
- **`docs/pack/INSTALL-PROCEDURES.md` / `docs/pack/METHODOLOGY.md` trinity references** — both files live in `supporting-docs/` and are copied to client `docs/pack/` at install (S6, `_CLIENT_INSTALLED_FILES` rows 1307–1308). Client-side refs correct.
- **Single `v9` refs in CLAUDE.md (Project addenda migration note), PM-CHAT.md (`.v9-customized` sidecar), HELP-FRAGMENT.md (`migrate-v9-to-v10.sh`)** — legitimate migration-history, not operating-version claims.
- **GEMINI.md `## Agent roster` H2 present only in GEMINI.md** — carries an inline trinity-rule-exception comment (Gemini filesystem auto-discovery aid); documented asymmetry.

### Cross-segment version note
A v11.0 version sweep spans R3 (R3-F02 PACK-FEEDBACK.md, R3-F03 pm-chat.md, R3-F04 README, R3-F05 HELP-FRAGMENT) and the supporting-docs segment: `supporting-docs/METHODOLOGY.md` is stamped `Version: 2.1 (v10.0, April 2026)` / "Applies to ... AI Agent Config Pack v10" and INSTALL-PROCEDURES.md carries v10 framing. Those two files are owned by another segment but are copied to client `docs/pack/` at install, so the same stale-version class lands client-side from there too — flagging as a cross-segment touch point for whoever owns supporting-docs.
