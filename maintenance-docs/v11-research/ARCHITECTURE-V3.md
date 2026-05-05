# v11 Architecture V3 — Optional Issue-Tracker Integration

**Status.** Architecture proposal, third pass. Refines `ARCHITECTURE-V2.md`
(2026-04-30) which itself refined `ARCHITECTURE.md` (V1, 2026-04-30). Designed
against `DESIGN-BRIEF.md` (the contract; freshly updated with revised §3.4 P6,
new OQ-19, new OQ-20, and three new §4.1 success criteria) plus the original
research inputs `EXTERNAL-RESEARCH.md`, `INTERNAL-INVENTORY.md`, and
`RESEARCH-AUDIT.md`.

**Owner.** Pack-architect agent. Awaiting pack-maintainer review.

**Date.** 2026-05-04 (V3 pass).

**Reading path.** Read V2 first (and V1 if needed for the preserved sections);
this V3 document is a delta on top of V2. The §0 change log is the index.
V3 preserves V2's section numbering for §§1–22 and §§24–26 (OQ-16, OQ-17,
OQ-18 defenses), reshapes §23 (V2 Discoverability) into a thin pointer, and
adds two new sections — §27 (P6 revised: discoverability and proactive
guidance) and §28 (OQ-19 + OQ-20 resolutions). Appendices A–C extend V2's
appendices.

**Out of scope, do-not-revisit.** All `DESIGN-BRIEF.md` §1 hard exclusions
hold. V2's deletions stand (no v10 non-opt-in case). V3 introduces no new
out-of-scope claims.

**Format-compatibility note.** V3 is intentionally additive in structure —
§§1–22 and §§24–26 are not rewritten. Where a V2 design needs revision, V3
marks the V2 row in §16 "superseded by D-N-V3" and adds a V3 decision row.
The reader who has V2 in mind navigates V3 by reading §0, then §16 (decision
deltas), then §27 / §28 (the new P6 / OQ-19 / OQ-20 design).

---

## 0. Change log — V2 → V3

### 0.1 What changed materially

| Area | V2 state | V3 state | Why |
|---|---|---|---|
| §3.4 P6 (priority "Discoverability") | Scoped to "find tracker commands in 5 minutes" | Renamed to "Discoverability and proactive guidance"; expanded to (a) full pack verb surface, (b) chat proactively recommends tracker mode at scale signals, (c) refusal-respecting (per-session vs persistent), (d) help functionality coexists with external docs | `DESIGN-BRIEF.md` §3.4 P6 revision; three new success criteria in §4.1 |
| OQ-19 | Did not exist in V2 | Resolved in §28.1: per-surface signal sets, threshold values, on-disk state file, refusal-respecting state machine, exact prompt shape | New OQ in `DESIGN-BRIEF.md` §7 OQ-19 |
| OQ-20 | V2 §23.2 / §23.3 designed `/help` augmentation + `pack help` shell verb, scoped to tracker only, naming undefended | Resolved in §28.2: scope expanded to entire pack; namespace defense via per-CLI doc citations; `pack help` shell verb is the LCD surface; per-CLI namespaced slash command (`/pack-help`) layered above; per-surface content split designed; trinity propagation specified | New OQ in `DESIGN-BRIEF.md` §7 OQ-20 |
| §23 (V2 Discoverability) | The full P6 design | Replaced in place by a thin pointer section that delegates to §27 + §28 | P6 expansion in V3 forces a structural rewrite; preserving V2 §23 verbatim alongside §27 would create two competing P6 designs |
| §22 (verb surface) | 9 verbs, all tracker-related | §22 unchanged at the verb spelling level; §28.2 expands the *help-surface scope* to also enumerate non-tracker pack verbs (init-project, migrate-v9-to-v10, validate-pack, agent-run, add-capability, merge-platform-skills, merge-trinity, pack-startup, pm-startup) | Per OQ-20 scope expansion. The verbs themselves are not new in V3; the help command's *coverage* is. |
| §16 decisions table | 18 rows D-1..D-18; D-4 superseded by D-4-V2 | 20 rows: D-1..D-15 reaffirmed in V3 (per V2); D-4-V2 reaffirmed in V3; D-16, D-17, D-18 reaffirmed in V3; D-19 (new, resolves OQ-19); D-20 (new, resolves OQ-20). No V2 decision is superseded; revisions are confined to V2 §23 (which was provisional, not a numbered decision). | New OQs need explicit decisions; existing decisions hold |
| §17 risks | R1..R10 from V1, plus V2 R11..R14 | Same risks plus V3 R15 (recommendation-fatigue regression), V3 R16 (state-file corruption / migration loss), V3 R17 (per-CLI help drift across the trinity if a future CLI adds native `/help` augmentation) | New surface area introduced by the proactive-recommendation system |
| Appendix A (artifacts list) | Lists V2 new files | V3 adds `.pack-tracker/recommendation-state.json`, `scripts/pack-help.sh` (V2 already named; V3 promotes scope), `project-template/docs/pack/HELP-FRAGMENT.md` (V2 named tracker-only; V3 expands), `.claude/skills/pack-help/SKILL.md`, `.gemini/commands/pack-help.toml` | New files for OQ-20 self-discoverability + OQ-19 state |
| Appendix B (citation index) | V2 mappings | V3 adds citations: per-CLI `/help` augmentation research (Claude Code commands ref; Codex slash_command.rs source; Gemini custom-commands.md); EXTERNAL-RESEARCH §6.1 token-cost inflection (~50–100 issues; verified plausible by audit §A.5); OT scale baseline (113 entries actual; 339 at 3×) | OQ-20 citations and OQ-19 threshold rationale |
| Appendix C (traceability index) | Listed V2 sections by OQ/priority | V3 adds rows for §27, §28, D-19, D-20 | Mechanical |

### 0.2 Decisions changed (summary; details in §16)

- **Reaffirmed unchanged from V2:** D-1, D-2, D-3, D-4-V2, D-5, D-6, D-7, D-8, D-9, D-10, D-11, D-12, D-13, D-14, D-15, D-16, D-17, D-18 (every numbered V1/V2 decision; the V2 design holds against the revised P6).
- **Superseded:** none. V3 adds; it does not retract.
- **New:** D-19 (OQ-19, inflection-point signals and thresholds), D-20 (OQ-20, help-verb scope, naming, and per-surface content split).

### 0.3 Sections changed materially

- §23 (V2 Discoverability) — replaced in place by a one-paragraph pointer to §27 + §28. The V2 design is preserved by reference (read V2 §23 if you want the prior shape) but is no longer the V3 design.
- §16 (decisions) — two new rows; every existing row gets a V3-status column.
- §17 (risks) — three new risks (R15, R16, R17).

### 0.4 Sections added

- §27 — P6 (revised) — discoverability and proactive guidance.
- §28 — OQ-19 + OQ-20 resolutions.

### 0.5 Sections preserved verbatim from V2 (read V2 directly)

- §1 (architectural overview).
- §2 (provider abstraction).
- §3 (config / detection / trinity).
- §4 (issue template schemas — V2 form family).
- §5 (dependency model).
- §6 (migration algorithm).
- §7 (chat orchestration).
- §8 (agent reads).
- §9 (failure UX).
- §10 (external triage).
- §11 (license).
- §12 (token economy).
- §13 (per-CLI matrix).
- §14 (tracker compatibility).
- §15 (pre-existing tracker).
- §18 (P1 lifecycle state machines).
- §19 (P2 maintenance ergonomics).
- §20 (P3 backend extensibility).
- §21 (P4 auditability).
- §22 (P5 verb surface — verb spellings unchanged; *help-surface scope* extended in §28.2).
- §24 (OQ-16 defense).
- §25 (OQ-17 defense).
- §26 (OQ-18 resolution).

### 0.6 Things V3 deliberately does not change

- The TrackerProvider operation set, capability schema, error model.
- Mode detection signal (`tracker.toml`).
- Trinity `## Document locations` table shape.
- Migration script structure.
- Mirror file behavior.
- LCD = `gh`; per-CLI MCP optional.
- Pack Chat / PM Chat exclusive write authority.
- Reverse migration mandatory.
- The verb spellings in V2 §22.1 (existing verbs unchanged). Note: D-19 adds the `pack tracker enable-recommendations` subcommand; D-20 adds `pack help` (LCD shell) and per-CLI `/pack-help`. These are net-new verbs, not respellings of V2 verbs.
- The form-family choice (D-4-V2). The revised P6 does not reach into intake-form design.
- The structure-vs-free-text split (D-17).
- The `template_version` dual-carrier (D-18).

---

## 1–22, 24–26. Sections preserved from V2

V2 §§1–22 and §§24–26 stand. Read V2 directly. Decisions D-1..D-18 (including
D-4-V2) reaffirmed in §16 below. The only V2 deletion in V3 is §23, replaced
by the pointer in §23 below.

---

## 23. (V2 Discoverability — replaced in V3)

**This section is intentionally short.** V2 §23 designed P6 against the
narrow brief "find tracker commands in 5 minutes." The revised
`DESIGN-BRIEF.md` §3.4 P6 expands the priority to:

1. Discoverability of the *entire pack verb set*, not just tracker.
2. Proactive recommendation when scale signals indicate tracker mode would
   help, with refusal-respecting behavior (per-session "not now" and
   persistent "never").
3. Coexistence with external documentation (QUICKSTART.md,
   OPTIONAL-FEATURES.md, INSTALL-PROCEDURES.md, etc.).

Each of these forces a structural change V2 §23 did not anticipate.
Rather than rewrite §23 in place — which would break the V2 → V3 reading
path because the V2 §23 design IS the V3 starting point — V3 puts the
new design in two new sections:

- **§27** — P6 (revised) design: proactive recommendation behavior,
  static-vs-dynamic balance, help-vs-external-docs coexistence model.
- **§28** — OQ-19 (signals and thresholds) and OQ-20 (help-verb scope and
  naming) resolved with concrete decisions.

V2 §23.1 (the static greeting), §23.2 (`/help` integration), §23.3
(`pack help` verb), §23.4 (colloquial-form router), §23.5 (README
discoverability), §23.6 (in-error-message discoverability), and §23.7
(5-minute SLA validation) are each treated by §27 / §28 explicitly:
some carry forward, some are revised. The carry-forward / revision
status of each V2 §23 sub-element is in §27.5 (the traceability table
from V2 §23 to V3).

---

## 16. Decisions (V3)

V2 had 18 rows (D-1..D-18, with D-4 superseded by D-4-V2 inline). V3 keeps
every V2 row and marks each "**reaffirmed in V3**." V3 adds D-19 (OQ-19) and
D-20 (OQ-20). No V2 decision is superseded in V3.

| ID | Date | V3 status | Decision | Rationale | Resolves | Sections |
|---|---|---|---|---|---|---|
| D-1 | 2026-04-30 | **reaffirmed in V3** | Provider surface = the 18 ops in V1 §2.1 with `Issue` shape, capability flags, error model, pagination contract. (Plus the optional additive `list_events` from V2 §17 R14 / §21.5.) | The revised P6 (proactive recommendation; help-surface) acts at chat orchestration layer, not at provider layer. The provider operation set is unchanged. | OQ-1 | V1 §2 |
| D-2 | 2026-04-30 | **reaffirmed in V3** | Tracker config = single `tracker.toml` per surface. | V3 adds a sibling state file (`.pack-tracker/recommendation-state.json`) under `.pack-tracker/` for OQ-19 state, but it is **not** part of `tracker.toml` (which remains opt-in mode declaration); see §28.1.4 for the file boundary rationale. The principle "one config decision = one config file" holds: `tracker.toml` is the user's mode declaration; `recommendation-state.json` is chat-managed runtime state. | OQ-2 | V1 §3.1 |
| D-3 | 2026-04-30 | **reaffirmed in V3** | Migration command surface = bash script `scripts/tracker-migrate.sh forward / reverse / status / doctor`. P5/P6 verb wrappers remain unchanged. | Verb spellings stable; help-content scope (D-20) doesn't change verb spellings. | OQ-3 | V1 §6.1, V2 §22 |
| D-4 | 2026-04-30 | **superseded by D-4-V2** (carried forward) | (V1) Six separate forms. | (V1) Issue forms give validated input + structured roundtrip. | OQ-4 | V1 §4 |
| D-4-V2 | 2026-04-30 | **reaffirmed in V3** | Two forms: `work-item.yml` and `inbound.yml`, each with a Type/Category dropdown driving labels. | Per OQ-16 defense (§24). The revised P6 does not reach into intake-form shape; the form family carries forward. | OQ-4, OQ-16 | §4, §24, §16 |
| D-5 | 2026-04-30 | **reaffirmed in V3** | Mode detection = presence and content of `tracker.toml`. | One signal, one place. The recommendation system in §28.1 reads the same signal to decide *whether to recommend* — reading is allowed; the file remains the single mode declaration. | OQ-5 | V1 §3.2 |
| D-6 | 2026-04-30 | **reaffirmed in V3**<br>(Source column applies to project-template trinity only; pack-repo trinity has no `## Document locations` section.) | Trinity `## Document locations` table gains a Source column. | Unchanged in V3. | OQ-6 | V1 §3.3 |
| D-7 | 2026-04-30 | **reaffirmed in V3** | Failure-mode UX = typed error codes, no silent retry, mirror as fallback when fresh, message shapes in V1 §9. | The recommendation system honors no-silent-retry: if writing the recommendation-state file fails, the chat surfaces it (§28.1.4). | OQ-7 | V1 §9 |
| D-8 | 2026-04-30 | **reaffirmed in V3** | Reverse migration = same script, also triggered by `pack tracker disable`. Sidecar for tracker-only data. | The recommendation-state file is *not* part of the migration round-trip — it lives at `.pack-tracker/recommendation-state.json` regardless of mode and is preserved across migrations as audit-side state (parallel to V2 §21.9 chat-audit handling). | OQ-8 | V1 §6.5–6.7 |
| D-9 | 2026-04-30 | **reaffirmed in V3** | Agent reads = LCD `gh` shell-out universal; MCP per-CLI optional. | Unchanged. | OQ-9 | V1 §8 |
| D-10 | 2026-04-30 | **reaffirmed in V3** | Auth = single `gh auth` per machine. | Unchanged. | OQ-10 | V1 §7.3 |
| D-11 | 2026-04-30 | **reaffirmed in V3** | PACK-FEEDBACK upstream mechanism. | Unchanged. | OQ-11 | V1 §7.5 |
| D-12 | 2026-04-30 | **reaffirmed in V3** | Pre-existing tracker integration deferred. | Unchanged. | OQ-12 | V1 §15 |
| D-13 | 2026-04-30 | **reaffirmed in V3** | License interaction = none new in v11. | The recommendation-state file is local to the user's machine; it does not cross the SaaS boundary. | OQ-13 | V1 §11 |
| D-14 | 2026-04-30 | **reaffirmed in V3** | External-issue triage via `needs-triage` + Pack Chat triage queue. | Unchanged. | OQ-14 | V1 §10, V2 §18.2 |
| D-15 | 2026-04-30 | **reaffirmed in V3** | Token measurement = post-shipping side-effect verification. | Unchanged. The recommendation system uses *flat-file* token-cost estimates (audit §A.5) as one of its signals; it does not verify backend-mode token cost (D-15 still concerns post-opt-in verification, not pre-opt-in recommendation). | OQ-15, OQ-19 | V1 §12, V3 §28.1 |
| D-16 | 2026-04-30 | **reaffirmed in V3** | Multi-template strategy = form-family pattern. | Unchanged. | OQ-16 | §24 |
| D-17 | 2026-04-30 | **reaffirmed in V3** | Structure-vs-free-text split. | Unchanged. | OQ-17 | §25 |
| D-18 | 2026-04-30 | **reaffirmed in V3** | `template_version` placement = dual carrier (HTML comment + label). | Unchanged. | OQ-18 | §26 |
| **D-19** | **2026-05-04** | **new (V3)** | Inflection-point signals and thresholds. **Per surface, the chat watches three signals: (a) entry count, (b) BACKLOG token cost, (c) IMPLEMENTATION_PLAN/STATUS bloat (client-side only).** Thresholds for the pack repo: ≥80 active entries OR ≥18 KB BACKLOG.md OR (open-entry-count growth >10/30 days). For client repos: ≥120 TD-NNN entries OR ≥45 KB BACKLOG.md OR ≥40 phases in IMPLEMENTATION_PLAN.md OR ≥150 typed-deferral comments. **State file:** `.pack-tracker/recommendation-state.json` per surface, schema in §28.1.4. **Dismissal:** `not_now_until_session_id` (per-session) and `persistent_refusal: true` (until user re-enables). **Recommendation surface:** static one-line hint at every flat-file session start; *active* recommendation (full prompt) only on threshold-cross AND not-already-refused-this-session AND not-persistently-refused. The user accepts (`yes`), defers (`not now`), or refuses (`don't ask again`). **Refusal-respecting state machine** in §28.1.6. | Per OQ-19. Thresholds tied to research data: EXTERNAL-RESEARCH §6.1 token-cost inflection at ~50–100 issues (verified plausible by audit §A.5) = the floor of "tracker becomes cheaper for filtered queries"; OT scale baseline (113 entries actual; 339 at 3×) = the empirical "real workload" data point; pack-repo BD volume historically lower (the BD-NNN counter is in the 50s as of v10), so pack thresholds are tuned lower. The static hint at every session is preserved from V2 §23.1 because it costs ~30 tokens and informs without nagging; the *active* recommendation is the new dynamic surface. The dismissal mechanism distinguishes "not now" (per-session in-memory; lost on session end) from "never" (persistent file flag) because the brief's §3.4 P6 explicitly distinguishes them — same UX as `dismiss-once` vs `dismiss-forever` patterns in any modern toolchain. The state-machine guarantees at most one active recommendation per session. | OQ-19, P6 | §28.1 |
| **D-20** | **2026-05-04** | **new (V3)** | Help-verb scope, naming, and per-surface content split. **Scope:** `pack help` lists the *entire* pack verb set per surface (not just tracker), enumerated in §28.2.1. **Naming:** the LCD verb is `pack help` (shell, available on all three CLIs). The per-CLI namespaced slash command is `/pack-help`. There is **no augmentation of any CLI's native `/help`** because no documented best-practice path exists across all three CLIs (research in §28.2.2: Gemini documents `/help` augmentation via custom-commands TOML; Claude Code's `/help` is a built-in that incidentally surfaces installed skills but augmentation is not a documented feature; Codex CLI has *no* `/help` slash command at all and the slash-command surface is a closed compiled-in enum). Path (b) — namespaced `/pack-help` — is therefore chosen, per the OQ-20 directive "if (a) is not a documented best practice across all three, prefer (b)." **Per-CLI implementation:** Claude Code: `.claude/skills/pack-help/SKILL.md` (creates `/pack-help`). Gemini: `.gemini/commands/pack-help.toml` (creates `/pack-help`; description appears in Gemini's native `/help` menu — that augmentation is incidental, not load-bearing). Codex CLI: no slash extension; the user types `pack help` in shell or as part of a chat-recognized colloquial phrase ("show me the pack commands"). **Per-surface content split:** pack-repo `pack help` lists pack-development verbs; client-repo `pack help` lists project-development verbs. The two sets partially overlap (tracker verbs); the rest differ (pack-startup vs pm-startup; pack-architect/pack-planner/pack-reviewer agents only on pack side). **Self-discoverability:** static greeting at every session start surfaces `pack help` (and `/pack-help` per-CLI as appropriate); errors recommend `pack help` when the chat detects a mistyped verb. **Trinity propagation:** `PACK-CHAT.md` and `project-template/docs/pack/PM-CHAT.md` document the help-verb routing; the trinity files (CLAUDE.md / AGENTS.md / GEMINI.md) get a one-line note pointing at `pack help`. The migration script (`init-project.sh`, `migrate-v9-to-v10.sh`) installs the per-CLI surfaces and the help fragment. **Test:** §28.2.6 5-step UX walk verifies a user who has never seen v11 finds help in one chat session. | Per OQ-20. The "documented best practice across all three CLIs" check is the deciding criterion in the brief; that check fails (only Gemini documents the augmentation; Claude Code and Codex CLI do not). Therefore namespaced `/pack-help` (per-CLI) plus shell `pack help` (LCD) is the path. The choice is forced by the per-CLI documentation state, not preference. The per-surface content split honors `DESIGN-BRIEF.md` §5.4 independence axes (pack-side and client-side adoption don't couple — and their help content shouldn't couple either). The trinity propagation is required by the trinity rule (`CLAUDE.md` rules) since the trinity files document available commands. | OQ-20, P6 | §28.2 |

The V3 decisions table is the reading index for someone with V2 in mind:
two new rows (D-19, D-20) and "**reaffirmed in V3**" status on every prior
row.

---

## 17. Risks and open trade-offs (V3 update)

V1 §17 stands except R9 (deleted in V2). V2 added R11–R14. V3 preserves
R1–R8, R10, R11–R14 unchanged and adds:

**R15. Recommendation fatigue regression.** Even with the per-session and
persistent-refusal mechanism (D-19), a user who runs many short sessions
(common in CLI workflows: open shell, ask one question, close) sees the
recommendation prompt repeatedly across sessions until they explicitly
persistent-refuse. The "once per session" guarantee is correct *per
session* but the *cross-session* exposure is high if sessions are short.

Mitigation: the recommendation prompt is offered **only at threshold
crossings** (the chat compares current signals against the recorded
last-shown-at signals; if no signals have crossed any threshold since
last-shown-at, no recommendation is offered, even if the user is at a
brand-new session). This means subsequent sessions don't re-fire the
recommendation unless the project has actually grown across the
relevant threshold. See §28.1.5 for the exact "should we recommend now?"
test. Documentation must be clear that "not now" is per-session and
"don't ask again" is the path for users who are tired of hearing about
it. Test fixture: a user starts 10 fresh sessions on a project at scale
just above threshold, dismisses with "not now" each time — by design,
the threshold-not-recrossed guard means at most one recommendation
appears across the 10 sessions (the first one).

**R16. Recommendation-state file corruption / migration loss.**
`.pack-tracker/recommendation-state.json` is a small per-surface JSON
file. If it's corrupted (manual edit; merge conflict; partial write
from a crashed session), the chat must not crash; it must default to
"not yet recommended" and offer to rebuild on next session. If the
project moves between machines (clone, fresh worktree), the file is in
git? — **No.** The file is in `.pack-tracker/`, which is in
`.gitignore` per V1 §3.4 (state files). Each machine starts with no
recommendation history. A user who declined "don't ask again" on
machine A and switches to machine B will be re-prompted unless they
decline again on machine B. Committing
`.pack-tracker/recommendation-state.json` to share the refusal across
machines would be wrong (machine-private state). The trade-off:
persistent refusal does not survive machine-switch; the user has to
decline once per machine. This is consistent with how local dot-files
handle "don't show this again" prompts on every other dev tool
(VSCode, IntelliJ, etc.).

Mitigation: explicit documentation in §28.1.4 that the file is
machine-local; "don't ask again" applies to this machine only. A
future minor could lift the persistence to a user-level
`~/.pack/recommendation-state.json` if cross-machine persistence
matters; not designed for v11.

**R17. Per-CLI help drift across the trinity.** D-20 ships per-CLI
`/pack-help` surfaces (Claude Code: `.claude/skills/pack-help/`;
Gemini: `.gemini/commands/pack-help.toml`) and the shell `pack help`
LCD. All three reference the same `HELP-FRAGMENT.md` source of truth,
so the *content* stays in sync via shared file. The risk: if a future
CLI (or a future Codex CLI release) adds documented `/help`
augmentation, the pack maintainer might be tempted to switch to that
CLI's native `/help` — but the namespaced `/pack-help` stays in the
other two. The result would be three CLIs with three different
discoverability surfaces, violating the LCD parity floor.

Mitigation: `validate-pack.py` adds a Check 21 (V3) — verify all three
per-CLI help surfaces exist (or all three are absent if the pack ships
without help). The trinity rule applies to the help surface: if one
CLI's help is added or moved, the parallel files in the other two CLIs
must be updated in the same commit. Documented in `PACK-CHAT.md`
"Trinity rule" section. See §28.2.5 for the test.

V1 §17.2 trade-offs T1–T6 stand. V1 §17.3 reviewer/planner challenge
list stands. V2 §17 risks R11–R14 stand.

---

## 27. P6 (revised) — discoverability and proactive guidance

This section designs the revised P6 priority from `DESIGN-BRIEF.md` §3.4.
The priority has three structural elements:

1. **Discoverability surface** — the user finds tracker commands AND every
   other pack verb without external documentation.
2. **Proactive guidance** — the chat recommends tracker mode when scale
   signals warrant it, refusal-respecting (per-session + persistent).
3. **Help-vs-external-docs coexistence** — in-chat help and external docs
   each carry the right content; both are maintained as the pack evolves;
   neither replaces the other.

§27 designs each in turn. The concrete decisions resolving OQ-19 (signals,
thresholds, dismissal mechanics, recommendation surface) live in §28.1;
the concrete decisions resolving OQ-20 (help-verb scope, naming,
self-discoverability, per-surface content) live in §28.2. §27 is the
P6-level architecture that those resolutions instantiate.

### 27.1 The three-layer discoverability surface

V2 §23 designed two layers (a static greeting at every flat-file session
and `/help` augmentation + `pack help` shell verb). V3 expands to three
layers, each serving a distinct discoverability use case. The three
layers must coexist; none is sufficient on its own.

**Layer 1 — Static greeting (V2 §23.1, retained).** At every session
start, `pack-startup` / `pm-startup` prints a short hint surfacing the
two most-load-bearing affordances: "(a) you can run `pack help` for the
verb list; (b) tracker mode is available — run `pack tracker init` to
opt in." The greeting is ~3 lines; cost ~30 tokens. It runs at *every*
flat-file session, not just the first. **Always-on** content; the
user's eyes glaze past it after a few sessions, but it's the safety net
for "I forgot how to find help."

V3 retains the V2 §23.1 static greeting verbatim with two additions:

```
Optiquity AI Agent Config Pack v11.0.
Tracker mode: flat-file (default) — run `pack help` for the full verb list.
[OPTIONAL: dynamic recommendation line — see Layer 3 below]
```

**Layer 2 — In-error-message verb naming (V2 §23.6, retained).** Every
error message ends with one unambiguous "run X to fix" line. The user
discovers verbs as they need them, by encountering errors that
recommend them. V2 §23.6 specified this; V3 reaffirms.

Examples (from V2):
- `Templates out of date. → Run: pack tracker update-templates --dry-run`
- `Tracker schema unexpected. → Run: pack tracker doctor`

V3 extends the convention: any chat-side error that mentions a verb
gives that verb's exact spelling and (where applicable) a colloquial
phrasing. Example:
```
Unknown command: 'set up tracker'.
Did you mean: pack tracker init  (or "set up the tracker" / "enable issue tracking")?
→ Run: pack help  to see all verbs.
```

**Layer 3 — Proactive threshold-driven recommendation (NEW in V3).**
When scale signals cross thresholds (per OQ-19 / D-19; see §28.1), the
chat surfaces a *full* recommendation prompt — not the static one-line
hint, but a multi-line dialogue that:

1. Names the signal that crossed (e.g., "your BACKLOG.md has 142 entries
   — beyond the ~80-100 entry inflection where tracker queries become
   cheaper than flat-file scans").
2. Names what tracker mode would give (e.g., "GH Issues lets you filter
   by label / status / phase without paging the full file; the
   migration is reversible").
3. Asks the user what they want to do, with three explicit options:
   `yes` (run init), `not now` (per-session dismiss), or `don't ask
   again` (persistent refusal).

The recommendation prompt fires **at most once per session** and **at
most once per signal-crossing event**. See §28.1.5 for the exact
firing condition.

The relationship across the three layers:

| Layer | Frequency | Token cost | Content shape | Refusal sensitive? |
|---|---|---|---|---|
| 1: Static greeting | every session | ~30 tokens | one-line hint | no — always shown (the user can't refuse a 30-token line) |
| 2: Error-message verb-naming | per error | ~10 tokens added per error | next-step verb plus colloquial | no — the user wants the recovery hint |
| 3: Proactive recommendation | at threshold cross, ≤1×/session | ~150 tokens (full prompt) | multi-line dialogue with accept / defer / refuse | **yes** — refusal-respecting state machine |

The three layers are designed against the priority's "user finds tracker
commands AND all other pack functionality without reading external
documentation" sentence. Layer 1 surfaces `pack help`; Layer 2 surfaces
specific verbs in context; Layer 3 surfaces the tracker opt-in path
when the project state warrants. Together: a new user discovers any
verb they need within at most three error-recovery cycles or one
session.

### 27.2 Static-vs-dynamic balance — the trade-off resolved

V2's design ran the static "Tracker mode: flat-file... say 'set up the
tracker'..." greeting at *every* flat-file session. The revised P6
introduces dynamic threshold-driven recommendations. The architect
must choose:

- **(a) Keep the static greeting AND add dynamic.** Both run.
- **(b) Replace static with dynamic-only.** No static greeting at all;
  recommendations only at threshold crosses.
- **(c) Hybrid.** Static greeting always; dynamic recommendation
  layered on top conditionally.

V3 chooses **(c) hybrid** with the following shape:

- **Layer 1 (static greeting)** runs at every session. Token cost
  trivial. Provides the safety-net "I forgot what to do" surface; works
  for *all* users regardless of project state.
- **Layer 3 (dynamic recommendation)** runs only when (i) signals have
  crossed a threshold since last-shown, (ii) the user has not
  per-session-dismissed in this session, and (iii) the user has not
  persistently refused.

Why hybrid wins over (a) "both equally always-on":

The static greeting, repeated at every session, conditions the user to
ignore it. Adding the dynamic recommendation always-on makes the same
kind of warning prominence redundant — every session would ask "do you
want the tracker?" regardless of project state. That is the
nagging-anti-pattern the brief explicitly forbids ("**refusal-respecting**:
after the user declines, the chat does NOT re-recommend in the same
chat session").

Why hybrid wins over (b) "dynamic-only":

Dynamic-only requires the chat to *know* the project state at every
session start. That works for tracker-mode candidacy (read BACKLOG.md
size, count entries) but means a brand-new project with no scale yet
sees no help at all from the chat. The static greeting closes that
gap: "I'm new; what is this thing?" surface is always visible. Cost of
keeping it: ~30 tokens per session, far below noise.

Hybrid: static greeting always; dynamic recommendation only when state
warrants it; refusal-respecting in both directions.

### 27.3 Refusal-respecting behavior — the design contract

The brief mandates two distinct refusal levels:

- **"Not now" (per-session)** — silences future recommendations in this
  chat session only. The next session is fresh.
- **"Never" (persistent)** — silences indefinitely until the user
  re-enables.

V3's design contract (concrete:

| Refusal level | Stored where | Cleared when | User re-enables how |
|---|---|---|---|
| Per-session | In-chat session memory only (no file write) | Session end (process exit; new chat = new state) | Automatic — start a new session, the per-session refusal is gone |
| Persistent | `.pack-tracker/recommendation-state.json` field `persistent_refusal: true` (machine-local; not in git) | When the user explicitly re-enables: `pack tracker enable-recommendations` (or "remind me about the tracker again") | One verb / one phrase |

The state machine in §28.1.6 is the formal design. The principle: the
chat respects refusal at the granularity the user expressed; it never
escalates a per-session "not now" into a persistent silence, and never
re-fires after a persistent "never" without an explicit user
re-enable.

The brief uses the word "**indefinitely**" for persistent refusal.
V3's design is conservative: indefinite means until the user re-enables.
There is no time-based decay (e.g., "ask again after 6 months"). The
trade-off: a user who refused two years ago and now does want the
tracker has to re-enable manually. The cost of the alternative
(time-decay nagging) is that every "indefinitely" promise is broken.
V3 chooses to keep the promise.

### 27.4 Help functionality coexists with external documentation

The brief: "Help functionality coexists with external documentation
(QUICKSTART.md, OPTIONAL-FEATURES.md, INSTALL-PROCEDURES.md, etc.) — it
does not replace them. External docs cover broader context, examples,
rationale, and walk-throughs; help functionality covers verb discovery
and quick reference. Both must be maintained as v11 ships and as the
pack evolves."

V3 designs the maintenance model — the *coexistence contract* — as
follows.

#### 27.4.1 Content split — what lives where

| Content | In-chat help (`pack help`, `/pack-help`) | External documentation |
|---|---|---|
| Verb spelling | yes (the canonical list) | yes (QUICKSTART.md links to verb references) |
| Verb one-line summary | yes | yes (mirrored from the same source-of-truth) |
| Verb arguments / flags | yes | yes |
| Colloquial phrasings | yes (mapping table) | partially (in PACK-CHAT.md / PM-CHAT.md) |
| Worked examples | no (one-line shape only) | yes (full-narrative walkthroughs) |
| Rationale / "why" | no | yes |
| Migration walkthrough (v9→v10, v10→v11) | no (in-chat references the migration verb only) | yes (MIGRATION-vN-to-vM.md is the authoritative narrative) |
| OS / dependency setup | no | yes (DEPENDENCIES.md) |
| Troubleshooting decision trees | no | yes (INSTALL-PROCEDURES.md) |
| Per-CLI feature matrix | no | yes (OPTIONAL-FEATURES.md) |
| Out-of-the-box config explanation | no | yes (CLI-PM-SETUP.md) |
| First-time-user onboarding narrative | no | yes (QUICKSTART.md) |

The principle: in-chat help is for **verb discovery and quick
reference** (what is the spelling? what does it do in one line?).
External documentation is for **understanding** (when do I use this?
what's the migration path? what are the pitfalls?).

#### 27.4.2 Source of truth — single canonical list

To prevent in-chat help and external docs from drifting:

- **`project-template/docs/pack/HELP-FRAGMENT.md` is the single
  source-of-truth** for the canonical verb list (per surface). It
  carries the verb spelling, one-line description, and colloquial
  mappings.
- The in-chat help surfaces (Claude `.claude/skills/pack-help/`, Gemini
  `.gemini/commands/pack-help.toml`, shell `scripts/pack-help.sh`)
  read from this file at runtime.
- External documentation references the same fragment by include /
  transclusion, or copies it with a "this list is authoritative;
  edit `HELP-FRAGMENT.md` to add a verb" header.

Where exactly external docs reference the fragment:

| External doc | How it references HELP-FRAGMENT.md |
|---|---|
| `QUICKSTART.md` | Links to the fragment's section ("for the full verb list, see HELP-FRAGMENT.md or run `pack help`") |
| `OPTIONAL-FEATURES.md` | Tracker section links to HELP-FRAGMENT.md tracker subsection |
| `INSTALL-PROCEDURES.md` | Procedure-step references verb names; full list in HELP-FRAGMENT.md |
| `PACK-CHAT.md` / `PM-CHAT.md` | Colloquial-form router section copies the colloquial mapping table from HELP-FRAGMENT.md (trinity rule applies to PM-CHAT.md → CLAUDE.md / AGENTS.md / GEMINI.md propagation if those files cite the table) |
| `METHODOLOGY.md` | Part 7 verb references named in METHODOLOGY are not duplicated; "for full verb list, see HELP-FRAGMENT.md" |
| `README.md` | Repository Layout section names HELP-FRAGMENT.md as the verb-discovery file |

#### 27.4.3 Drift-prevention test

`validate-pack.py` Check 22 (V3): for every verb named in
`PACK-CHAT.md`, `PM-CHAT.md`, `QUICKSTART.md`, `OPTIONAL-FEATURES.md`,
and `INSTALL-PROCEDURES.md`, verify the verb is also in
`HELP-FRAGMENT.md`. Verbs in HELP-FRAGMENT.md that are not referenced
elsewhere are allowed (the help fragment is canonical and external
docs need not name every verb).

This catches drift in one direction: external docs that reference an
absent or stale verb. The reverse direction (HELP-FRAGMENT.md missing
a verb that exists in `scripts/`) is caught by Check 23 (V3): every
top-level executable in `scripts/` either appears in HELP-FRAGMENT.md
or has a `# pack-internal: true` comment marking it as not
user-facing.

#### 27.4.4 Maintenance cadence

The coexistence contract has a cadence:

- **Adding a verb (or renaming).** Update `HELP-FRAGMENT.md` first.
  External docs that mention the old/new verb get updated in the same
  PR. CI checks (22, 23) verify completeness before merge.
- **Adding a colloquial phrasing.** Update HELP-FRAGMENT.md. Also
  update `PACK-CHAT.md` / `PM-CHAT.md` "Colloquial routing" section
  (trinity rule applies if the table is in trinity files, which V2
  §23.4 placed it in PACK-CHAT.md / PM-CHAT.md, *not* in the trinity
  triple — so trinity rule does not apply to colloquial routing).
- **Removing a verb.** Update HELP-FRAGMENT.md. External docs that
  referenced the verb get a deprecation notice or are removed. CI
  checks pass when the verb is gone everywhere.
- **Pack version bump (v11.x → v12).** External docs may reshape
  significantly; HELP-FRAGMENT.md still ships per-pack-version.

The cadence is enforced by CI (the Validate Pack workflow runs Checks
22 and 23). Drift is detected at PR time, not at user-encounter time.

### 27.5 V2 §23 → V3 §27 / §28 traceability

| V2 §23 element | V3 status | Where in V3 |
|---|---|---|
| §23.1 5-minute path / static greeting | Reaffirmed (with added optional Layer 3 line) | §27.1 Layer 1; §27.2 hybrid |
| §23.2 `/help` integration (per-CLI) | **Revised** — V2 said "augment each CLI's `/help`"; V3 says "no `/help` augmentation; namespaced `/pack-help` per-CLI plus shell `pack help`" | §28.2 (D-20) |
| §23.3 `pack help` verb | Reaffirmed; *scope expanded* from tracker-only to entire pack | §28.2.1 |
| §23.4 Colloquial-form router | Reaffirmed | §28.2.4 |
| §23.5 README discoverability | Reaffirmed; V3 adds explicit reference to HELP-FRAGMENT.md as the canonical verb list | §27.4.2 |
| §23.6 In-error-message discoverability | Reaffirmed (Layer 2) | §27.1 |
| §23.7 5-minute SLA validated | Reaffirmed; V3 §28.2.6 5-step UX walk supersedes the V2 §23.7 SLA wording | §28.2.6 |

### 27.6 Out-of-scope for §27 (intentionally)

V3 §27 does *not* design:

- Web / Desktop chat surfaces (out of scope per `DESIGN-BRIEF.md` §1).
- A "tutorial mode" that walks the user through every verb interactively
  — that is external documentation territory (QUICKSTART.md is the
  walkthrough surface).
- Telemetry on which verbs the user runs / dismisses — privacy /
  license boundary unclear; deferred. The pack does not collect
  recommendation-acceptance statistics.
- A shareable / synced cross-machine refusal state. R16 documents the
  trade-off.
- Time-based decay of persistent refusal. §27.3 documents the choice.

These are called out so the planner does not assume they are in scope
for v11 implementation.

---

## 28. OQ-19 + OQ-20 resolutions

This section resolves the two new OQs from `DESIGN-BRIEF.md` §7. §28.1
is OQ-19; §28.2 is OQ-20.

### 28.1 OQ-19 — inflection-point signals and thresholds

The brief: "Per P6, the chat must observe signals and proactively
recommend opt-in when thresholds cross. The architect designs:
the signal set per surface; where signals are tracked; threshold
values with rationale tied to research data; per-session-dismissal
vs persistent-refusal mechanism; recommendation surface — what the
chat says, how the user accepts / declines / dismisses persistently."

#### 28.1.1 Signal set per surface

The pack-repo surface and client-repo surface track different
artifacts; their signal sets differ. The signals below are observable
at session start (no continuous monitoring; one read at startup
suffices for the recommendation system).

**Pack-repo signal set:**

| Signal | Source | Why this signal |
|---|---|---|
| `bd_count_active` | grep `^\*\*BD-` in `BACKLOG.md`, count entries with `Status: Open` or `Status: Unblocked` | Direct measure of active workload; the load-bearing signal for "tracker query becomes useful" |
| `bd_count_total` | grep `^\*\*BD-` in `BACKLOG.md`, count all | Includes resolved; informs the "BACKLOG.md size" picture |
| `backlog_kb` | `wc -c BACKLOG.md` ÷ 1024 | Token-cost proxy; per EXTERNAL-RESEARCH §6.1 (verified plausible by audit §A.5), ~50–100 issues is the inflection where filtered tracker queries cost less than full-file reads |
| `backlog_growth_30d` | `git log --since="30 days ago" --pretty=format:"%h" -- BACKLOG.md` count, multiplied by ~average per-commit growth | Captures the *trajectory*; a project growing fast crosses the threshold sooner than a stable one |

**Client-repo signal set:**

| Signal | Source | Why this signal |
|---|---|---|
| `td_count_active` | grep `^\*\*TD-` in `BACKLOG.md` (project), count `Status: Open` / `Status: Unblocked` | Direct workload measure |
| `td_count_total` | grep `^\*\*TD-` in `BACKLOG.md` (project), count all | Same purpose as pack `bd_count_total` |
| `backlog_kb` | `wc -c BACKLOG.md` (project) ÷ 1024 | Token-cost proxy |
| `phase_count` | grep `^## Phase` in `IMPLEMENTATION_PLAN.md`, count | Per `RESEARCH-AUDIT.md` OT scale baseline (60 phases at OT today; 180 at 3×); IMPLEMENTATION_PLAN.md scales with phase count |
| `implementation_plan_kb` | `wc -c IMPLEMENTATION_PLAN.md` ÷ 1024 | Captures the file-bloat dimension that BACKLOG count alone misses |
| `td_tbd_comment_count` | grep `TD-TBD` in source files (excluding pack-controlled dirs) | Indicator of pending tracker assignments; high count = high deferred-work backlog the tracker would help organize |
| `typed_deferral_count` | grep `KNOWN GAP\|TODO\|FIXME` in source files | Audit §A.10 dependency comments; signals project complexity even if BACKLOG is small |

The pack repo has no `IMPLEMENTATION_PLAN.md` (per `INTERNAL-INVENTORY.md`
Pass A) so the phase-related signals don't apply. The client repo has
both BACKLOG and IMPLEMENTATION_PLAN; both signals contribute.

The signal computation runs once at session start (in `pack-startup` /
`pm-startup`). Cost: ~10 file reads, each <100 KB; one git log call;
total well under 1 second on any machine the pack supports.

#### 28.1.2 Threshold values per signal

Threshold values fire the *active recommendation* when crossed. Tied
to research data:

**Pack-repo thresholds:**

| Signal | Threshold | Rationale |
|---|---|---|
| `bd_count_active` | ≥ 80 | EXTERNAL-RESEARCH §6.1 inflection at ~50–100 active items where filtered tracker queries beat full-file reads (verified plausible by audit §A.5). 80 is the conservative end of that range — a pack repo at 80 active BDs is firmly past the inflection. The current pack is at ~50 BDs (pre-v11), well under the threshold; it would not trigger today, which is correct. |
| `backlog_kb` | ≥ 18 (KB) | Pack BACKLOG.md is currently ~12 KB at v10. 18 KB ≈ 6,000 tokens at 3 chars/token; near the upper bound of "comfortable single-file read" before tracker queries pay off. |
| `backlog_growth_30d` | > 10 entries / 30 days | Catches projects ramping up fast; 10/month is roughly v10's BD-add rate during active development phases (BD-001 → BD-049 across ~5 months). |

If *any* of these crosses, the recommendation fires (subject to the
state-machine guards in §28.1.5).

**Client-repo thresholds:**

| Signal | Threshold | Rationale |
|---|---|---|
| `td_count_active` | ≥ 120 | Higher than pack-repo `bd_count_active` because client projects have richer in-source typed-deferral structure (TD-TBD comments + actual TD-NNN entries); the BACKLOG count alone underestimates effective workload. OT actual = 113 active equivalents (~58 open + 55 resolved); 120 is just above the OT current state, intentionally — OT is exactly the scale where a tracker becomes valuable, and the threshold should fire for projects in OT's range. |
| `backlog_kb` | ≥ 45 (KB) | OT BACKLOG.md is 1,471 lines ≈ 60 KB. 45 KB is near OT's current size; chosen to fire for projects approaching OT scale but not for greenfield projects. |
| `phase_count` | ≥ 40 | OT has 60 phases. The IMPLEMENTATION_PLAN.md hits 5,235 lines at 60 phases. 40 phases is where the file becomes painful to read fully; tracker-tracked phases (sub-issues per phase epic) start to pay off. |
| `implementation_plan_kb` | ≥ 100 (KB) | OT IMPLEMENTATION_PLAN.md ≈ 200 KB. 100 KB threshold catches projects entering OT-class territory. |
| `td_tbd_comment_count` | ≥ 60 | OT has 0 TD-TBD literals (clean discipline) but 88 typed-deferral comments and 147 TD-NNN references. `td_tbd_comment_count` ≥ 60 catches the rare project where the discipline is breaking down — those projects benefit most from tracker-managed assignment. |
| `typed_deferral_count` | ≥ 150 | OT-actual is 88 typed deferrals (KNOWN GAP / TODO / FIXME); 150 catches projects past 1.5× OT scale where the comment-tracking surface itself overwhelms a flat file. |

If *any* of these crosses, the recommendation fires (with the same
state-machine guards).

The thresholds are deliberately conservative — they fire only when
the project genuinely benefits, and they don't fire for greenfield
or small projects where the tracker would be overkill. The trade-off:
a project that's growing fast may not see the recommendation until
it crosses a threshold; the static greeting (Layer 1) plus
`pack help` cover the gap for proactive users.

#### 28.1.3 OR-logic vs AND-logic

The thresholds use **OR** logic: any one signal crossing fires the
recommendation. AND-logic was considered and rejected because:

- Different projects scale on different axes. A pack with many BDs
  and a small BACKLOG (efficient writers) is different from a pack
  with few BDs but a giant BACKLOG (verbose writers); both benefit
  from tracker mode. AND-logic would force both axes to cross,
  miscatching projects scaling on one axis only.
- The signals are correlated but not identical: a high BACKLOG
  size with low BD count might mean the user is using BACKLOG.md as
  a notes / scratchpad; a high BD count with a small BACKLOG might
  mean tight-summary discipline. Both are valid signals of "this
  project benefits from a tracker."
- The OR threshold means at most one threshold crosses at a time
  (typical case); the recommendation message can name the specific
  signal that crossed (§28.1.7), which is more informative than a
  generic AND-style "your project is large."

#### 28.1.4 State file — `.pack-tracker/recommendation-state.json`

The recommendation system has persistent state (for "don't ask again")
plus per-session state (for "not now"). The persistent state lives
at:

```
<surface-root>/.pack-tracker/recommendation-state.json
```

Schema (v1):

```json
{
  "schema_version": "v1",
  "surface": "pack" | "client",
  "persistent_refusal": false,
  "persistent_refusal_at": null,
  "last_recommendation_shown_at": null,
  "last_recommendation_signals": {
    "bd_count_active": 0,
    "backlog_kb": 0
  },
  "user_re_enable_count": 0
}
```

Field rationale:

- `schema_version` — V3 ships v1; future schema changes carry a
  migration step.
- `surface` — `pack` for pack-repo; `client` for project. Lets the
  same file format work on both surfaces (the schema is the same;
  only signal names differ).
- `persistent_refusal` — boolean; flipped to `true` when the user
  selects "don't ask again." Cleared by `pack tracker
  enable-recommendations` or the colloquial "remind me about the
  tracker again."
- `persistent_refusal_at` — ISO-8601 timestamp of when persistent
  refusal was set; informational; never used to time-decay.
- `last_recommendation_shown_at` — ISO-8601 timestamp; the chat
  records this when the recommendation prompt was last surfaced.
  Used by the §28.1.5 "should we recommend now?" test — we don't
  fire again unless signals have crossed *since* this timestamp's
  recorded values.
- `last_recommendation_signals` — the snapshot of the signal values
  at the time of last recommendation. Used by §28.1.5 to detect
  whether signals have re-crossed: a project that was at
  bd_count_active=82 when last recommended is at 82 again — same
  state — no re-recommendation. A project at 82 last time, now at
  120, has materially grown — fire recommendation.
- `user_re_enable_count` — informational; counts how many times
  the user has re-enabled persistent refusal. Useful for diagnosing
  feedback ("the user tried tracker mode and went back; let's not
  recommend immediately") in a future minor; not used in v11
  decisions.

**Where the file lives.** Per surface root:

- Pack repo: `<pack-root>/.pack-tracker/recommendation-state.json`
- Client repo: `<project-root>/.pack-tracker/recommendation-state.json`

`.pack-tracker/` is in `.gitignore` per V1 §3.4. The file is
machine-local. R16 (V3 §17 update) documents the cross-machine
trade-off.

**Schema migrations.** A future minor ships v2; the chat reads
`schema_version` and migrates. Old v1 files are translated; users
with the file at v1 see no behavior change. This mirrors the
template-version pattern from V2 §19.

**Failure modes.**

- File missing → treat as "no recommendation history; default
  state." Continue. Write the file at next surface.
- File corrupted (JSON parse fails) → log a typed warning; write a
  fresh file with default state; the user starts over. **No silent
  retry per D-7.** After rebuild, treat the current session as if the
  recommendation has already been shown; defer evaluation to the next
  session (avoids firing the recommendation on the same session as
  the rebuild, which would feel disorienting after a corruption
  warning).
- File write fails (disk full, permissions) → surface a typed
  error; the chat does not crash; it skips the recommendation
  surface for this session.

**Why a separate file from `tracker.toml`?**

`tracker.toml` is the user's mode declaration (flat-file vs
tracker). The recommendation-state file is chat-managed runtime
state (was the user offered a recommendation? did they refuse?).
Conflating the two would mean every recommendation interaction
modifies `tracker.toml` — confusing, and potentially noisy in
diff-review tools. Keeping them separate matches the principle
"one file, one purpose."

#### 28.1.5 The "should we recommend now?" test

At session start, the chat runs `pack-startup` / `pm-startup`. As
part of that, it computes the signals (§28.1.1) and decides whether
to fire the active recommendation. The test:

```
def should_recommend(signals, state):
    # Guard 1: tracker already enabled? Then no recommendation needed.
    if tracker_toml_exists() and tracker_toml.mode.state == "tracker":
        return False
    # Guard 2: persistent refusal? Then never recommend until re-enabled.
    if state.persistent_refusal:
        return False
    # Guard 3: any signal threshold crossed?
    crossed_signals = [
        name for name, value in signals.items()
        if value >= THRESHOLDS[surface][name]
    ]
    if not crossed_signals:
        return False
    # Guard 4: have signals materially changed since last recommendation?
    if state.last_recommendation_shown_at:
        # If signals are unchanged or only marginally different from
        # the snapshot at last recommendation, don't re-fire.
        for name in crossed_signals:
            last = state.last_recommendation_signals.get(name, 0)
            now = signals[name]
            # "Materially" = re-cross, or growth of >= 25% over last snapshot
            if now < THRESHOLDS[surface][name]:
                continue  # signal dropped below threshold
            if last >= THRESHOLDS[surface][name] and now < last * 1.25:
                # Signal was already over threshold last time; not
                # materially higher now. Don't re-fire.
                continue
            return True
        return False
    # Guard 5: First time over threshold; fire.
    return True
```

The 25% growth threshold prevents a project sitting at exactly the
threshold from firing every session forever. A project at 82
bd_count_active that crosses to 105 (28% growth) re-fires; a project
oscillating between 80 and 84 doesn't.

The check runs each session start, but the guards make it fire
rarely:

- For tracker-enabled projects: never (Guard 1).
- For persistent-refused projects: never (Guard 2).
- For sub-threshold projects: never (Guard 3).
- For projects that crossed once and refused: until they grow 25%
  more (Guard 4).
- For freshly-crossed-threshold projects in their first session at
  scale: yes — once.

Combined with the per-session "not now" (held in chat session memory
only), the user sees at most one prompt per session and at most one
prompt per material project growth.

#### 28.1.6 Refusal-respecting state machine

```
                                    (start of any session)
                                            │
                                            ▼
                                    [check tracker.toml]
                                            │
                                ┌───────────┴───────────┐
                                │                       │
                            tracker mode           flat-file mode
                                │                       │
                                ▼                       ▼
                            (no recommendation;        [load .pack-tracker/
                             chat operates             recommendation-state.json]
                             on tracker)                       │
                                                                ▼
                                                    [persistent_refusal == true?]
                                                                │
                                                ┌───────────────┴───────────────┐
                                                │ yes                          no │
                                                ▼                                ▼
                                    (no recommendation,                 [compute signals]
                                     no static line either                       │
                                     about "set up tracker";                     ▼
                                     static greeting still shows         [should_recommend(
                                     `pack help` hint)                    signals, state)]
                                                                                 │
                                                                ┌────────────────┴────────────────┐
                                                                │ true                          false │
                                                                ▼                                    ▼
                                                    [show recommendation prompt]      [no active recommendation;
                                                                │                       static greeting only]
                                                ┌───────────────┼─────────────────┐
                                                │               │                 │
                                                ▼               ▼                 ▼
                                    [user: yes]     [user: not now]      [user: don't ask again]
                                                │               │                 │
                                                ▼               ▼                 ▼
                                    [run pack tracker  [in-session memory:   [.pack-tracker/state.json:
                                     init]              dismissed_this_       persistent_refusal=true,
                                                        session=true]         persistent_refusal_at=now]
                                                                │                 │
                                                                ▼                 ▼
                                                        [chat continues         [chat continues
                                                         normally; no            normally; no
                                                         further recom.          recommendations
                                                         this session]           ever, until re-enabled]
                                                                                  │
                                                                                  │ (later, possibly
                                                                                  │  in a different session)
                                                                                  ▼
                                                                    [user: pack tracker enable-recommendations
                                                                     OR colloquial "remind me about the tracker again"]
                                                                                  │
                                                                                  ▼
                                                                    [.pack-tracker/state.json:
                                                                     persistent_refusal=false,
                                                                     user_re_enable_count++]
                                                                                  │
                                                                                  ▼
                                                                    (next session: state evaluated
                                                                     fresh; recommendation may fire
                                                                     if signals cross thresholds)
```

State table (more compact):

| Current state | Event | New state | Side effects |
|---|---|---|---|
| flat-file, no refusal, signals below threshold | session start | unchanged | static greeting shown (Layer 1); `pack help` hint shown |
| flat-file, no refusal, signals above threshold, fresh | session start | `last_recommendation_shown_at` updated; `last_recommendation_signals` snapshot taken | static greeting + active recommendation prompt |
| flat-file, no refusal, signals above threshold, recently shown | session start (signals not 25% higher than last snapshot) | unchanged | static greeting only; no active prompt |
| flat-file, no refusal, signals above threshold | user: "not now" | per-session in-memory `dismissed_this_session=true` | acknowledgment line; no further prompts this session |
| flat-file, no refusal, signals above threshold | user: "yes" | (transitions to tracker mode after migration) | `pack tracker init` runs |
| flat-file, no refusal, signals above threshold | user: "don't ask again" | `persistent_refusal=true` | acknowledgment line; persistent state file written |
| flat-file, persistent refusal | session start | unchanged | static greeting shown but the recommendation hint line is suppressed; `pack help` hint shown |
| flat-file, persistent refusal | user: `pack tracker enable-recommendations` | `persistent_refusal=false`; `user_re_enable_count++` | acknowledgment line; next session evaluates fresh |
| flat-file (any state) | user: `pack tracker init` directly | (transitions to tracker mode) | normal init flow |

The state machine is deliberately small: 3 states (no-refusal /
per-session-refused / persistent-refused) × 1 mode (flat-file; tracker
mode collapses everything to "no recommendation"). This keeps the
implementation a few dozen lines of straight code.

#### 28.1.7 Recommendation prompt — exact shape

When `should_recommend()` returns true (and per-session not yet
dismissed), the chat surfaces the prompt. Exact wording:

```
─────────────────────────────────────────────────────────────────
You're at <signal-name>: <value> (threshold ≥ <threshold-value>).

At this scale, GH Issues lets you filter and search faster than
reading BACKLOG.md in full. The migration is one command, and it's
fully reversible — you can switch back to flat files any time
with `pack tracker disable`.

Want to enable the tracker now?

  yes              → run `pack tracker init` (3-5 minutes; reversible)
  not now          → don't ask me again *this* session
  don't ask again  → don't recommend the tracker until I re-enable

Or run `pack help` to see all pack commands.
─────────────────────────────────────────────────────────────────
```

Cost: ~150 tokens. Shown once per session at most; once per material
project growth at most.

The signal-name field is filled by the chat: e.g., "BACKLOG entries
(active): 124". When multiple signals cross, the prompt names the
most-quantitatively-extreme one (`max(value / threshold)`) so the
user sees the most compelling reason. The other crossed signals are
mentioned in one line: "(BACKLOG.md size: 52 KB also past 45 KB
threshold.)"

The user's response is parsed loosely. The exact accept patterns:

| User says | Parsed as |
|---|---|
| `yes`, `Yes`, `y`, `Y`, `enable`, `OK`, `sure`, `let's do it`, "go ahead" | yes — run init |
| `not now`, `later`, `no`, `No`, `n`, `N`, `skip`, "not yet" | per-session dismiss |
| `don't ask again`, `never`, `disable recommendations`, `stop`, "don't recommend", "leave me alone" | persistent refuse |
| (anything else) | ambiguous; chat re-asks with the three options |

The colloquial mappings are documented in `PACK-CHAT.md` /
`PM-CHAT.md` "Recommendation routing" section, parallel to the
existing "Tracker verb routing" section from V2 §23.4 (which was
already the file for colloquial mappings). The trinity rule does
*not* apply because this content lives in PACK-CHAT.md / PM-CHAT.md,
not in the trinity triple.

#### 28.1.8 What if the user re-enables and signals are below threshold?

After persistent refusal → user re-enables → next session: signals
are still computed; `should_recommend()` runs Guard 3. If the
project has grown past threshold, the recommendation fires. If it
has shrunk below threshold (rare; possible if many BDs are resolved
between refusal and re-enable), no recommendation; the user is
treated as a flat-file-mode user with "no scale signal yet."

This is the intended behavior — the user re-enabled because they're
considering the tracker, but the chat doesn't pressure them if
the project doesn't currently warrant it.

#### 28.1.9 Implementation surfaces

The recommendation logic lives in:

- `project-template/skills/pm-startup/SKILL.md` (extended) — adds
  Step 8 (after V1's Step 7 triage queue): compute signals; check
  state; potentially fire recommendation.
- `pack-startup` skill (pack-side parallel) — same Step 8 added.
- `scripts/lib/recommendation.sh` (new) — shared bash library that
  the skills source. Contains: signal computation, state-file read /
  write, the `should_recommend()` test, the prompt-rendering helper.
- `scripts/pack-tracker.sh` — wrapper for `pack tracker
  enable-recommendations`. Sets `persistent_refusal: false` in the
  state file. V3 adds the `enable-recommendations` subcommand to the
  existing `pack tracker` verb (per D-19); the parent verb `pack
  tracker` already exists in V2 §22.1.

Trinity-replicated content: **none.** The recommendation logic is
chat-side / skill-side; it does not live in the trinity files. The
trinity files (CLAUDE.md / AGENTS.md / GEMINI.md) get a one-line
reference to `pack help` (for OQ-20), not to the recommendation
system.

#### 28.1.10 Tests

The planner / reviewer verifies:

1. **Threshold-cross fires once.** Project at 82 active BDs (just
   over threshold), no prior state. Run `pack-startup`. Recommendation
   fires. Run again same session — does not fire (per-session
   guard). Restart session, no scale change — does not fire (Guard 4
   25% guard). Project grows to 105 BDs (28% growth), restart
   session — fires.
2. **"Not now" silences for the session.** Project crosses
   threshold; user says "not now"; subsequent operations in same
   session — no re-fire.
3. **"Don't ask again" persists.** Project crosses; user refuses
   persistently. Restart session, signals still over threshold —
   does not fire. State file shows `persistent_refusal: true`.
4. **`pack tracker enable-recommendations` clears.** From the
   persistent-refused state, run the verb. Restart session — if
   signals still cross, fires.
5. **Tracker mode disables recommendations.** After running
   `pack tracker init`, restart session — no recommendation prompt
   ever; static greeting now shows tracker-mode line.
6. **Corrupted state file recovers.** Manually corrupt the JSON;
   restart session — chat warns, writes fresh default state, does
   not crash. Verify no recommendation fires in the same session as
   the rebuild (deferred to next session per §28.1.4 failure-mode
   contract); restart again at unchanged-over-threshold scale —
   recommendation fires.
7. **Cross-machine refusal does not survive.** Clone the project on
   a new machine, run session — recommendation can fire (per R16).

These are integration tests; they go in
`scripts/tests/recommendation-test.sh` and run in CI's Validate Pack
workflow.

---

### 28.2 OQ-20 — help-verb scope, naming, and discoverability across surfaces

The brief: "V2's §23.2–§23.3 designed `/help` augmentation (per-CLI) plus
a `pack help` shell verb, both scoped to tracker only. The architect
resolves: scope (extend to entire pack); naming and pattern (augment
each CLI's native `/help` if a documented best practice; otherwise
namespaced `/pack-help`); per-surface content; self-discoverability."

#### 28.2.1 Scope expansion — the entire pack verb set

V2 scoped `pack help` to tracker verbs only. V3 expands to every pack
verb. The exhaustive verb manifest, audited against
`INTERNAL-INVENTORY.md` and `README.md` Repository Layout:

**Pack-repo verbs (verbs the pack maintainer uses on the pack repo
itself):**

| Verb | Purpose | Source |
|---|---|---|
| `pack-startup` (skill, slash) | Pack Chat session bootstrap | `.claude/skills/pack-startup/`, etc. |
| `claude --agent pack-architect` | Spawn pack-architect agent (separate session) | `PACK-AGENTS.md` |
| `claude --agent pack-planner` | Spawn pack-planner agent | `PACK-AGENTS.md` |
| `claude --agent pack-reviewer` | Spawn pack-reviewer agent | `PACK-AGENTS.md` |
| `claude --agent pack-docs-researcher` | Spawn pack-docs-researcher agent | `PACK-AGENTS.md` |
| `validate-pack.py` | Run pack structural validation | `scripts/validate-pack.py` |
| `pack tracker init` | Enable tracker mode (v11+) | V2 §22 |
| `pack tracker disable` | Disable tracker mode | V2 §22 |
| `pack tracker doctor` | Validate tracker state | V2 §22 |
| `pack tracker status` | One-line tracker status | V2 §22 |
| `pack tracker update-templates` | Upgrade entries to current template version | V2 §22 |
| `pack tracker mirror-rebuild` | Regenerate mirror files | V2 §22 |
| `pack triage <id>` | Triage a tracker entry | V2 §22 |
| `pack audit query [...]` | Audit-trail query | V2 §22 |
| `pack feedback upstream` | Send PACK-FEEDBACK upstream | V2 §22 |
| `pack tracker enable-recommendations` | Re-enable proactive recommendations | V3 §28.1 |
| `pack help` | Show this help | V3 §28.2 (this section) |

**Client-repo verbs (verbs the project user / PM Chat uses):**

| Verb | Purpose | Source |
|---|---|---|
| `pm-startup` (skill, slash) | PM Chat session bootstrap | `project-template/skills/pm-startup/` |
| `init-project.sh` | Initialize the pack in a new or existing project (one-time) | `scripts/init-project.sh` |
| `migrate-v9-to-v10.sh` | Upgrade from v9.3 → v10.0 (one-time per upgrade) | `scripts/migrate-v9-to-v10.sh` |
| `add-capability.sh` | Add a pack-supported capability to existing project | `scripts/add-capability.sh` |
| `merge-platform-skills.py` | PLATFORM-SKILLS.md splice helper | `scripts/merge-platform-skills.py` |
| `merge-trinity.py` | Trinity file splice helper | `scripts/merge-trinity.py` |
| `agent-run.sh <agent> <prompt-file>` | Spawn a project agent with read-only/write flags | `project-template/agent-run.sh` |
| `pack tracker init` | Enable tracker mode | V2 §22 |
| `pack tracker disable` | Disable tracker mode | V2 §22 |
| `pack tracker doctor` | Validate tracker state | V2 §22 |
| `pack tracker status` | One-line tracker status | V2 §22 |
| `pack tracker update-templates` | Upgrade entries to current template version | V2 §22 |
| `pack tracker mirror-rebuild` | Regenerate mirror files | V2 §22 |
| `pack triage <id>` | Triage TD entry | V2 §22 |
| `pack audit query [...]` | Audit-trail query | V2 §22 |
| `pack feedback upstream` | Send PACK-FEEDBACK upstream to pack repo | V2 §22 |
| `pack tracker enable-recommendations` | Re-enable proactive recommendations | V3 §28.1 |
| `pack help` | Show this help | V3 §28.2 |

The two sets share the tracker verbs (intentional — tracker functions
work the same on both surfaces) and the help verb. They differ on
pack-development verbs (only on pack side) and project-development
verbs (only on client side).

The scope expansion is justified by the brief's explicit instruction:
"the asymmetry of 'only tracker has discoverability' is unjustified."
A user discovering tracker verbs but not `init-project.sh` or
`agent-run.sh` is exactly the asymmetry. V3 fixes it.

#### 28.2.2 Naming and pattern — the rigorous defense

The brief: "**(a) Augment each CLI's native `/help`** with pack
content. Must be defended as a documented best practice with citations
to each CLI's official docs. If best-practice citations exist across
all three, this is the simpler choice. **(b) Namespaced `/pack-help`**
that is itself discoverable via the chat's first-session greeting.
Cleaner separation; one more verb to learn. **The choice depends on
whether (a) is a documented best practice across all three CLIs.**"

The choice is determined by per-CLI documentation. V3 verified each
CLI with web fetches against the current official docs (verifications
performed 2026-05-04, the V3 design date; recency aligned with
`EXTERNAL-RESEARCH.md` §12 verification 2026-05-03).

**Claude Code (Claude Code v2.1.126, the May 2026 stable):**

- `/help` is documented as a built-in slash command at
  `https://code.claude.com/docs/en/commands`, described as "Show
  help and available commands."
- The skills / commands documentation at
  `https://code.claude.com/docs/en/skills` documents the user-facing
  extension mechanism: `.claude/skills/<name>/SKILL.md` files create
  *new* slash commands (`/<name>`). The doc explicitly states:
  "Custom commands have been merged into skills. A file at
  `.claude/commands/deploy.md` and a skill at
  `.claude/skills/deploy/SKILL.md` both create `/deploy`..."
- The doc does **not** describe a mechanism for *augmenting* `/help`
  with custom content. Skills appear as their own slash commands; the
  skill's `description` field is "for Claude" (used for auto-invocation
  decisions and as autocomplete hint), not for `/help` enumeration.
- Conclusion: **`/help` augmentation is not a documented best practice
  in Claude Code.** The documented practice is to ship a *new* slash
  command (in our case, `/pack-help`).

Citation: [Claude Code Commands](https://code.claude.com/docs/en/commands)
("Show help and available commands"); [Claude Code Skills](https://code.claude.com/docs/en/skills)
("Custom commands have been merged into skills... `.claude/skills/deploy/SKILL.md`
[creates] `/deploy`"). Verified 2026-05-04.

**Codex CLI (post-2026-03-14 GA, current daily-cadence release):**

- The slash-command surface is implemented as a compiled-in Rust enum
  (`SlashCommand` in `codex-rs/tui/src/slash_command.rs`). Built-in
  commands include `/skills`, `/mcp`, `/feedback`, `/status`,
  `/model`, `/init`, `/compact`, `/review`, `/diff`, `/copy`,
  `/permissions`, `/keymap`, `/vim`, `/sandbox-add-read-dir`,
  `/experimental`, `/memories`, `/hooks`, `/apps`, `/plugins`, etc.
- Crucially: **`/help` does not exist as a slash command in Codex
  CLI.** It is not in the SlashCommand enum.
- The user-facing extension surface is via `~/.codex/agents/*.toml`
  (subagents), `~/.codex/skills/*` (skills, surfaced via `/skills`),
  MCP servers, and plugins (`/plugins`). None of these is "augment
  the built-in `/help`."
- Conclusion: **`/help` augmentation is not possible in Codex CLI**
  because there is no `/help` to augment. The native discoverability
  surface is the `/skills` listing and the `/plugins` listing.

Citation: openai/codex source at
[`codex-rs/tui/src/slash_command.rs`](https://github.com/openai/codex/blob/main/codex-rs/tui/src/slash_command.rs)
(the SlashCommand enum is the complete documented set; the file is
compiled-in and user-extension is not via this mechanism). Cross-reference:
EXTERNAL-RESEARCH §12.2 (current Codex CLI release stream); audit §A.1
Codex section. Verified 2026-05-04.

**Gemini CLI (v0.40.0 stable, v0.41.0-preview.0):**

- `/help` is a documented built-in slash command.
- Custom commands at `~/.gemini/commands/<name>.toml` (or project-local
  `<project>/.gemini/commands/<name>.toml`) create new slash commands
  (`/<name>`). The Gemini CLI custom-commands documentation explicitly
  states: "**`description` (String): A brief, one-line description of
  what the command does. This text will be displayed next to your
  command in the `/help` menu.**"
- This means: in Gemini CLI, adding a custom command at
  `.gemini/commands/<name>.toml` does cause that command's
  description to appear in the `/help` menu. *This is documented `/help`
  augmentation.*
- However: the augmentation is automatic; you can't put arbitrary text
  in `/help`, only the descriptions of commands you add. The
  augmentation is bounded.

Citation: [Gemini CLI custom-commands documentation](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/custom-commands.md)
verbatim quote "This text will be displayed next to your command in
the `/help` menu." Verified 2026-05-04.

**Three-CLI summary:**

| CLI | Has native `/help`? | Documented `/help` augmentation? |
|---|---|---|
| Claude Code | yes (built-in) | **no** — custom skills appear as their own slash commands; not documented as augmenting `/help` |
| Codex CLI | **no** (`/help` doesn't exist) | **no** — no `/help` to augment |
| Gemini CLI | yes (built-in) | **yes** — custom command `description` appears in the `/help` menu |

**Verdict.** The brief's directive: "If best-practice citations exist
across all three, this is the simpler choice. If not, prefer (b)."
Best-practice citation exists for **one of three** CLIs (Gemini).
Therefore the directive forces option (b) — namespaced `/pack-help`.

The consequence is not the augmentation per se (Gemini will still
auto-augment its `/help` because `pack-help` is a custom command in
`.gemini/commands/`), but the *commitment* — V3 does not rely on
augmentation for the baseline behavior. The baseline:

- Each CLI ships a `/pack-help` slash command (per-CLI implementation
  detail) and the shell verb `pack help`.
- Gemini's `/help` will incidentally list `/pack-help` (Gemini
  built-in behavior). This is gravy, not load-bearing.
- Claude Code's `/help` lists built-in commands plus all installed
  skills/commands as their own slash entries. `/pack-help` will
  appear there too. Also gravy.
- Codex CLI has no `/help`; the user's discoverability path is via
  `/skills` (which lists `pack-help` as a skill on Codex) and the
  shell `pack help`.

**Why this matters for parity.** If V3 had chosen (a) — augment each
CLI's `/help` — Claude Code and Codex would need workarounds (Claude
Code: no doc'd augmentation; Codex: no `/help` at all). The pack
would be three different help surfaces with three different
mechanisms. The LCD parity floor (`DESIGN-BRIEF.md` §3.1: "All three
CLIs work identically at the lowest common denominator") would
be violated.

By choosing (b), the LCD floor is the shell verb `pack help` (works
on all three CLIs; identical content; identical command spelling). On
top of that floor, each CLI has a `/pack-help` slash command (same
verb at the slash level on all three). This satisfies parity.

#### 28.2.3 Per-CLI implementation

**Shell verb `pack help` (LCD; all three CLIs):**

Implemented as `scripts/pack-help.sh`. The script reads
`project-template/docs/pack/HELP-FRAGMENT.md` (for client-side
projects) or the pack-repo equivalent at root (for pack repo) and
prints the contents. The pack-repo equivalent is
`HELP-FRAGMENT-PACK.md` at the pack root, parallel to the
client-side fragment but with the pack-repo verb set.

Per-surface routing inside `pack-help.sh`: detect surface (presence
of `BACKLOG.md` at root with BD-NNN entries → pack repo; presence of
`docs/project/BACKLOG.md` with TD-NNN entries → client; ambiguous →
print both). The detection mirrors the existing `init-project.sh`
detection in `scripts/lib/detect.sh`.

Output cost: ~400 tokens for one surface's help fragment. Fast (<200ms
shell startup on macOS / Linux).

**Per-CLI namespaced slash:**

| CLI | File | Mechanism |
|---|---|---|
| Claude Code | `.claude/skills/pack-help/SKILL.md` | Skill with `name: pack-help`, `description: Show all pack commands and colloquial mappings`, body invokes `pack-help.sh` via `!\`bash scripts/pack-help.sh\`` shell injection. Creates `/pack-help` (and incidentally appears in Claude Code's `/help` autocomplete). |
| Codex CLI | `.codex/skills/pack-help/SKILL.md` (project-level only) | Codex skill that runs `pack-help.sh`. Surfaced via `/skills` (Codex's listing surface). No native `/help` to surface in. |
| Gemini CLI | `.gemini/commands/pack-help.toml` (project-level only) | TOML custom command with `description: Show all pack commands and colloquial mappings` and `prompt = "!{bash scripts/pack-help.sh}"`. Creates `/pack-help` and (per Gemini docs verbatim) "displayed next to your command in the `/help` menu." |

The per-CLI files are trinity-replicated: editing one requires editing
all three in the same commit. The trinity rule applies because these
are the user-facing CLI command surfaces, and the trinity rule's
"these three files must express the same project rules" extends to
"the three CLI surfaces must expose the same commands."

The pack-repo trinity check (`validate-pack.py` Check 21, V3) verifies
all three files exist with the same target verb name (`pack-help`).

**Why three different files?** Each CLI's command-extension format
is mandated by the CLI itself (Markdown skill for Claude, TOML for
Codex skills, TOML for Gemini commands). The pack does not invent
a format; it ships per-CLI in each CLI's documented schema.

#### 28.2.4 Per-surface content split

Pack repo and client repo have different verb sets (§28.2.1). The
content split:

- **Pack repo `pack help`** reads `HELP-FRAGMENT-PACK.md`. Lists
  pack-development verbs (pack-startup, pack-architect /
  -planner / -reviewer / -docs-researcher invocations, validate-pack,
  pack tracker verbs, pack help).
- **Client repo `pack help`** reads
  `project-template/docs/pack/HELP-FRAGMENT.md`. Lists
  project-development verbs (pm-startup, init-project, migrate scripts,
  add-capability, merge helpers, agent-run, pack tracker verbs, pack
  help).

The two fragments are separately maintained. They share the tracker
section (since tracker verbs work identically on both surfaces); the
shared tracker section lives in `project-template/docs/pack/
HELP-FRAGMENT-TRACKER.md` and is included by both top-level fragments.
This avoids duplication; trinity-rule-style propagation applies to
the shared fragment automatically.

File layout:

```
(pack root)
HELP-FRAGMENT-PACK.md                (pack-repo verb list — Pack Chat reads)
HELP-FRAGMENT-TRACKER.md             (canonical shared tracker section — Pack Chat reads;
                                      init-project.sh copies to client at install time)

project-template/docs/pack/
├── HELP-FRAGMENT.md                 (client-surface verb list — PM Chat reads)
├── HELP-FRAGMENT-TRACKER.md         (mirror of pack-root canonical, installed by init-project.sh;
                                      PM Chat reads via bare-name lookup)
└── ...
```

`HELP-FRAGMENT-PACK.md` includes `HELP-FRAGMENT-TRACKER.md` from
pack root (sibling-file include via `pack-help.sh`'s text-include
resolver). `project-template/docs/pack/HELP-FRAGMENT.md` includes
`HELP-FRAGMENT-TRACKER.md` from `project-template/docs/pack/`
(sibling-file include in the client tree). Each surface includes
the copy that lives in its own tree; neither surface reads across
the pack-ops/pack-product boundary at runtime. The two
`HELP-FRAGMENT-TRACKER.md` copies are kept byte-identical by
`validate-pack.py` (Check 24, see §28.2.5) and by `init-project.sh`
(which overwrites the client-side copy from the pack-root canonical
on every install or `--update` run). The two top-level fragments diverge in the
non-tracker sections.

Trinity rule: PACK-CHAT.md (pack-side) and `project-template/docs/
pack/PM-CHAT.md` (client-side) document the colloquial-mapping table.
Updates to colloquial routing get propagated. The trinity files
(CLAUDE.md / AGENTS.md / GEMINI.md) get a one-line note ("for the
full verb list, run `pack help`") — that note IS trinity-replicated.
Per the trinity rule, editing one means editing all three in the
same commit.

#### 28.2.5 Trinity propagation and validate-pack tests

The trinity rule applies as follows for the help surface:

- **`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (pack-repo trinity):**
  Each gets a "Pack commands" or "Discovering commands" section
  (one-line) that references `pack help`. Editing the section
  requires editing all three.
- **`project-template/{CLAUDE,AGENTS,GEMINI}.md` (client trinity):**
  Same one-line reference. Editing requires editing all three.
- **`.claude/skills/pack-help/SKILL.md`,
  `.codex/skills/pack-help/SKILL.md`,
  `.gemini/commands/pack-help.toml`** (per-CLI, both surfaces):
  Trinity-rule applies because these are the per-CLI command
  surfaces. validate-pack Check 21 (V3) verifies all three exist
  with consistent target.

`validate-pack.py` adds:

- **Check 21 (V3) — Trinity per-CLI help-surface parity.** Verify
  `.claude/skills/pack-help/SKILL.md`, `.codex/skills/pack-help/SKILL.md`,
  `.gemini/commands/pack-help.toml` all exist (or all are absent).
  Verify they invoke the same target (`scripts/pack-help.sh` or its
  equivalent).
- **Check 22 (V3) — Help-fragment freshness.** Verify every verb
  named in `PACK-CHAT.md`, `project-template/docs/pack/PM-CHAT.md`,
  `QUICKSTART.md`, `OPTIONAL-FEATURES.md`,
  `INSTALL-PROCEDURES.md` appears in the corresponding
  `HELP-FRAGMENT*.md`.
- **Check 23 (V3) — Help-fragment completeness.** Verify every
  top-level executable in `scripts/` appears in `HELP-FRAGMENT*.md`
  unless marked `# pack-internal: true`.
- **Check 24 (V3) — Shared-fragment byte-identity.** Verify
  pack-root `HELP-FRAGMENT-TRACKER.md` is byte-identical to
  `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`. Enforces the
  L1 canonical → mirror copy contract from §28.2.4.

The four checks together prevent drift. Bug or stale doc gets
flagged at PR time.

#### 28.2.6 Self-discoverability test — 5-step UX walk

A user who has never seen v11 must find `pack help` in a single chat
session. The walk (client-repo example):

```
[Step 1] User runs `pm-startup` (or "/pm-startup" in their CLI).
         Output:
         > Optiquity AI Agent Config Pack v11.0.
         > Tracker mode: flat-file (default) — run `pack help` for
         > the full verb list.
         > [phase status]
         > [triage queue]

[Step 2] User reads "run `pack help`" line and runs `pack help`.
         (LCD shell verb, available in any terminal pane the user has;
          OR /pack-help via their CLI's slash command.)
         Output: prints HELP-FRAGMENT.md content; shows verb list
         organized by category; shows colloquial-mapping table.

[Step 3] User scans the help and finds the verb they need
         (e.g., `pack tracker init`, `agent-run.sh`, etc.).

[Step 4] User runs the verb. If it errors, the error message names
         the next-step verb (Layer 2 from §27.1). User self-recovers.

[Step 5] User has discovered the full verb surface.
```

Total time: under 60 seconds for a user familiar with shell. The
user has read no external docs.

For the pack-repo surface, the walk is identical with `pack-startup`
in place of `pm-startup`.

**Codex CLI discoverability (accepted asymmetry below the slash surface).**

Codex CLI's slash-command surface is a compiled-in Rust enum
(EXTERNAL-RESEARCH §12.2; `codex-rs/tui/src/slash_command.rs`); it
exposes neither a built-in `/help` nor a documented mechanism for
startup-banner injection. The pack therefore ships three documented
Codex-native paths to the same help content, in priority order:

1. **Shell verb `pack help`** (LCD floor; available in the same terminal
   Codex runs in). This is the first-class path for Codex users.
2. **`/skills` listing → `pack-help` skill** (Codex's documented surface
   for user-installed extensions). The `pack-help` skill is installed
   project-level at `.codex/skills/pack-help/SKILL.md` (ships with
   `init-project.sh`). A user who runs `/skills` sees `pack-help` in
   the listing; selecting it runs `pack-help.sh`.
3. **`pack-startup` / `pm-startup` static greeting** (Layer 1 from §27.1):
   when the user invokes the startup skill (which v11 will document
   as the recommended first action in any pack-managed repo via the
   QUICKSTART.md and trinity-file additions specified in §A.2), the
   greeting prints "run `pack help` for the full verb list."

**What this means for the "no external docs" success criterion.** The
brief §3.4 P6 first bullet asks for in-chat discovery without external
docs. On Claude Code and Gemini CLI, native `/help` autocomplete shows
`/pack-help` (Claude: `/help` is built-in and lists installed skills as
slash commands; Gemini: custom commands' `description` field appears
in `/help`, per `gemini-cli/docs/cli/custom-commands.md`). On Codex,
the equivalent native discovery is `/skills` — Codex's documented
listing surface for user extensions — which is one extra step (3 keys:
`/`, `s`, Tab) but is **not** "external documentation" in the brief's
sense; it is a Codex-native chat surface.

**Accepted gap.** A Codex user who:

- has not run `pack-startup` / `pm-startup` (no static greeting), AND
- does not know to type `/skills` (Codex's listing surface), AND
- does not type `pack help` in shell, AND
- has not yet hit an error that names the next-step verb (Layer 2)

will need to read QUICKSTART.md or OPTIONAL-FEATURES.md to discover
the verb. This is acceptable scope for v11 because:

- The brief explicitly authorizes `pack help` as a valid mechanism
  (§3.4 first bullet, parenthetical: "the exact mechanism is OQ-20").
- The brief explicitly authorizes coexistence with external docs (§3.4
  last sub-bullet: "Help functionality coexists with external
  documentation … it does not replace them").
- The cross-CLI parity floor is at the LCD shell, not at the
  slash-command surface; per-CLI mechanism above the floor is by
  design (`DESIGN-BRIEF.md` §3.1: "All three CLIs work identically at
  the **lowest common denominator**. Per-CLI tuning is allowed where
  one CLI offers more capability").
- Inventing a forced session-start banner on Codex would require a
  mechanism Codex does not document; the pack does not invent
  below-the-surface hooks (§0.6 stability floor).

A future Codex CLI release that introduces documented `/help`
augmentation or a session-startup hook would let v11.x lift this
asymmetry; until then, the three documented paths above plus
external docs satisfy the brief.

(There is no separate "negative case" subsection: the Codex path is
the negative case, and it is now positively designed with three
layers and one acknowledged residual gap covered by external docs.
For a user on any CLI who somehow lands in a chat without ever
running `pack-startup` / `pm-startup`, the shell `pack help` verb
plus colloquial routing in PACK-CHAT.md / PM-CHAT.md still catches
them; the system has multiple paths to discoverability.)

#### 28.2.7 Help fragment shape — the actual content

The HELP-FRAGMENT*.md files share a structure:

```markdown
# Pack v11 — verb reference

For full documentation see <QUICKSTART.md / OPTIONAL-FEATURES.md / etc>.
For interactive help: run `pack help` or `/pack-help` in your CLI.

## Pack commands (this surface)

| Verb | What it does |
|---|---|
| pack-startup | Bootstraps Pack Chat session. Run first. |
| pack tracker init | Enable issue tracking on this surface. Reversible. |
| ...

## Tracker commands (v11+)

[Included from HELP-FRAGMENT-TRACKER.md]

## Colloquial mappings

| Phrase | Verb |
|---|---|
| set up the tracker | pack tracker init |
| switch back to flat files | pack tracker disable |
| ...

## See also
- QUICKSTART.md — full setup and walkthrough
- OPTIONAL-FEATURES.md — per-CLI optional features
- PACK-CHAT.md / PM-CHAT.md — chat operating instructions
```

The structure is identical on both surfaces; the content (verb list)
differs by surface. Both reference external docs by name (the
help-vs-external-docs coexistence model from §27.4 in action).

#### 28.2.8 Trade-offs documented

**Trade-off A: namespaced `/pack-help` is "one more verb to learn"
vs augmenting `/help`.**

Cost: yes, the user has to learn `/pack-help` instead of just running
`/help`. Mitigation: the static greeting names it explicitly at every
session start. After two or three sessions, the user knows the verb.

Counter-benefit: the namespace is unambiguous. `/help` augmentation
in Gemini works but doesn't explicitly say "this content comes from
the Optiquity pack." `/pack-help` does.

**Trade-off B: Gemini's "free" `/help` augmentation is not relied
upon.**

The baseline is `/pack-help`. Gemini's incidental `/help`
augmentation (the `description` field appears in `/help`) is gravy —
it works, and we ship it, but the v11 design does not depend on it.
A future Gemini release that changes `/help` behavior does not break
the pack.

**Trade-off C: Codex CLI users have no slash-command help.**

Codex has no `/help`; its `/skills` is the closest equivalent.
`pack-help` ships as a Codex skill so it appears in `/skills`.
Cost: a Codex user has to know to type `/skills` (built-in Codex
verb) to discover `pack-help`, OR run `pack help` in shell. The
static greeting names `pack help` (the LCD shell version), so the
Codex user discovers via the shell path; the `/skills` path is
secondary.

**Trade-off D: trinity replication burden.**

Three per-CLI files (`.claude/skills/pack-help/SKILL.md`,
`.codex/skills/pack-help/SKILL.md`, `.gemini/commands/pack-help.toml`)
to maintain in lockstep. Mitigated by:
1. validate-pack Check 21 (V3) catches missing files.
2. The files are short (each ~10 lines); the maintenance burden is
   low relative to the user value.
3. The bodies invoke the same `pack-help.sh`; content drift is
   contained because content lives in HELP-FRAGMENT.md, not in the
   per-CLI files.

#### 28.2.9 Help and proactive recommendation interplay

`pack help` is one of the verbs the recommendation prompt offers
("Or run `pack help` to see all pack commands"). The recommendation
system (§28.1.7 prompt) explicitly mentions `pack help` so the user
who declines tracker mode still discovers the broader verb surface.

The two systems are independent: refusing the tracker recommendation
does not silence `pack help`. `pack help` always works, always shows
the full fragment.

#### 28.2.10 Does Codex's `/skills` listing duplicate `pack help`?

`/skills` lists every installed Codex skill, including `pack-help`.
The user could run `/skills` → see `pack-help` → invoke it →
output is the help fragment. That's a 3-step path.

Vs `pack help` directly: 1 step.

The static greeting names `pack help` (1-step path) as the primary
surface. `/skills` works as a fallback and as a generic Codex
discoverability path. There's no conflict; the user who knows
Codex's conventions uses `/skills`; the user who reads the static
greeting uses `pack help`. Both paths converge on the same content.

#### 28.2.11 What V3 explicitly does NOT design

- **A unified single command interpreter.** v11 ships per-CLI native
  surfaces; no abstraction layer.
- **A shared autocomplete service.** Each CLI's autocomplete is its
  own; the pack does not unify.
- **A "help search" feature** (e.g., `pack help <keyword>` returning
  matching verbs). The fragment is small enough to scan; full-text
  search would add complexity for marginal gain. Future minor if
  scaling up.
- **HTML / web-rendered help.** Out of scope per `DESIGN-BRIEF.md` §1.
- **A `pack tour` interactive walkthrough.** External docs (QUICKSTART)
  is the walkthrough surface.
- **Versioned help (e.g., `pack help --version=v10`).** The shipped
  fragment matches the shipped pack version. Cross-version help is
  an external-docs concern (`MIGRATION-vN-to-vM.md`).

#### 28.2.12 Outcome — meeting the brief's success criteria

The brief's three new success criteria from §4.1:

1. *"The chat proactively recommends tracker opt-in at most once per
   session, surfacing the recommendation when scale signals (per
   OQ-19) cross. The recommendation is dismissable per-session AND
   persistently. After persistent dismissal, no further
   recommendations until the user explicitly re-enables them.
   Verifiable by integration test."* — met by §28.1.6 state machine
   + §28.1.10 tests.
2. *"The help-command surface (per OQ-20) lists every pack-shipped
   verb (tracker verbs from V2 §22 PLUS init / migrate / validate /
   agent-run / any other top-level verbs). Per-surface (pack repo /
   client repo) help content matches each surface's verb set. Tested
   by reading help output and matching against the verb manifest."*
   — met by §28.2.1 (verb manifest), §28.2.4 (per-surface split),
   §28.2.5 Check 22 / 23 (CI verification), §28.2.6 (5-step UX
   walk).
3. *"External documentation (QUICKSTART.md, OPTIONAL-FEATURES.md,
   INSTALL-PROCEDURES.md) covers tracker mode, opt-in workflow, and
   verb reference at a depth appropriate to first-time users.
   In-chat help functionality covers the verb-list and quick-reference
   use case. Both are maintained as the pack evolves; both are tested
   for completeness independently."* — met by §27.4 coexistence
   model + §27.4.3 drift-prevention tests + §27.4.4 cadence.

All three pass.

---

## Appendix A — V3 deltas to artifact list

V2 Appendix A inventoried V2's new and modified artifacts. V3 adds:

### A.1 V3 deltas to V2 §A.1 (new artifacts)

V2 listed `HELP-FRAGMENT.md`, `pack-help.sh`, `chat-audit.jsonl`,
`upgrade-log.json`. V3 adds:

- `HELP-FRAGMENT-PACK.md` (pack repo root) — pack-repo verb list,
  parallel to `project-template/docs/pack/HELP-FRAGMENT.md`. New file.
- `HELP-FRAGMENT-TRACKER.md` (pack repo root) — canonical shared
  tracker verb list. Pack Chat reads from pack root; PM Chat reads
  from the client-tree mirror (next bullet). New file.
- `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` —
  client-tree mirror of the pack-root canonical, installed by
  `init-project.sh` from the canonical at every install /
  `--update`; byte-identity enforced by `validate-pack.py`. New file.
- `.pack-tracker/recommendation-state.json` (per surface, machine-local,
  gitignored) — recommendation state file (§28.1.4). New file.
- `.claude/skills/pack-help/SKILL.md` (per surface) — Claude Code
  `/pack-help` skill. New file.
- `.codex/skills/pack-help/SKILL.md` (per surface) — Codex CLI `pack-help`
  skill. New file.
- `.gemini/commands/pack-help.toml` (per surface) — Gemini CLI
  `/pack-help` command. New file.
- `scripts/lib/recommendation.sh` — shared bash library for signal
  computation, state read/write, recommendation prompt rendering. New
  file.
- `scripts/tests/recommendation-test.sh` — integration tests for the
  recommendation system (§28.1.10). New file.

V2's `HELP-FRAGMENT.md` (in `project-template/docs/pack/`) is preserved
but V3 changes its scope from tracker-only to entire-client-pack-verb-set.
The file is renamed semantically (still HELP-FRAGMENT.md) but its
content shape is broader.

V2's `pack-help.sh` (V2 §23.3) is preserved but V3 broadens it to
detect surface and read the right fragment.

### A.2 V3 deltas to V2 §A.2 (modified artifacts)

V2 added modifications to `PACK-CHAT.md`, `PM-CHAT.md`, METHODOLOGY.md,
validate-pack.py. V3 adds:

- **`PACK-CHAT.md` and `project-template/docs/pack/PM-CHAT.md`**:
  add "Recommendation routing" section (parallel to V2's "Tracker
  verb routing"). The colloquial mappings for `yes` / `not now` /
  `don't ask again` plus `pack tracker enable-recommendations` /
  "remind me about the tracker again" live here.
- **`pack-startup` and `pm-startup` skills (each CLI's copy)**: add
  Step 8 (after V1's Step 7 triage queue) — compute signals; check
  recommendation state; potentially fire active recommendation
  prompt.
- **Trinity files (CLAUDE.md / AGENTS.md / GEMINI.md, both pack and
  client)**: add a one-line "Pack commands" reference to `pack help` /
  `/pack-help`, AND a one-line "Recommended first action: run
  `pack-startup` (pack repo) or `pm-startup` (client repo)" line. The
  second line is what makes §28.2.6 Layer 1's static greeting a
  documented contract rather than an implicit assumption.
- **`QUICKSTART.md`**: gains a top-of-doc "Recommended first action:
  run `pack-startup` / `pm-startup` in your CLI" callout, paired with
  the existing setup walkthrough. This is the doc-side counterpart to
  the trinity addendum above; both ship in v11.
- **`scripts/validate-pack.py`**: adds Check 21 (V3 trinity per-CLI
  help-surface parity), Check 22 (V3 help-fragment freshness), Check
  23 (V3 help-fragment completeness), Check 24 (V3 shared-fragment
  byte-identity between pack-root `HELP-FRAGMENT-TRACKER.md` and the
  `project-template/docs/pack/` mirror).
- **`scripts/init-project.sh`**: extends to install `.claude/skills/
  pack-help/SKILL.md`, `.codex/skills/pack-help/SKILL.md`,
  `.gemini/commands/pack-help.toml`, and `HELP-FRAGMENT.md` /
  `HELP-FRAGMENT-TRACKER.md` into the new project. The migration
  script (`migrate-v9-to-v10.sh`) adds parallel propagation for
  v10→v11 upgrades (note: V3 design; the actual v10→v11 migration
  script naming would be `migrate-v10-to-v11.sh`, matching the
  pack's existing migration-naming convention `MIGRATION-vN-to-vM.md`).

### A.3 V3 deltas to V2 §A.3 (out-of-scope artifacts)

Unchanged. The brief's §1 hard exclusions still hold.

### A.4 New artifacts for P6 (revised)

The artifacts listed above (recommendation state file, `pack-help.sh`,
per-CLI `pack-help` files, HELP-FRAGMENT files, recommendation tests)
are the P6-revised additions. They are kept under `scripts/`,
`.pack-tracker/`, and the per-CLI skill / command directories — no
new top-level directory is introduced.

### A.5 Migration impact

For projects upgrading v10 → v11 (forward direction):

- `init-project.sh` (or its v10→v11 migrator) installs the new
  per-CLI help surfaces and fragments.
- The recommendation state file is created lazily on first session
  start with default values (no migration needed; the file simply
  doesn't exist yet on a v10 project).
- Existing trinity files get the one-line "Pack commands" addendum
  (handled by `merge-trinity.py` as an additive splice).

For projects on v11 reverting to v10 (reverse direction; via
`pack tracker disable` + a hypothetical v11→v10 reverse migration):

- The recommendation state file is preserved as a sidecar (mirror of
  V2 §21.9 audit-log handling).
- The per-CLI help surfaces are removed by the reverse (they're
  v11-specific).
- Trinity files get the addendum removed by `merge-trinity.py`.

After reverse, the recommendation-state file remains as inert data;
the recommendation system is no longer active without v11 skills.
Reinstalling v11 reads the file fresh (and the lazy-create path
covers the case where the user manually deleted it between reverse
and re-forward).

The reverse migration is mandatory per `DESIGN-BRIEF.md` §3.1; V3
preserves that contract.

---

## Appendix B — V3 deltas to citation index

V2 Appendix B mapped citations per V2 section. V3 adds:

### B.1 P6 (revised) and OQ-19

- §27 / §28.1: `DESIGN-BRIEF.md` §3.4 P6 (revised); §4.1 last three
  bullets (success criteria); §7 OQ-19; `EXTERNAL-RESEARCH.md` §6
  (token cost characteristics; §6.1 inflection ~50–100 issues);
  `RESEARCH-AUDIT.md` "OT scale baseline" (113 entries actual; 339
  at 3×; 60 phases; 88 typed deferrals; 147 TD-NNN references);
  `RESEARCH-AUDIT.md` §A.5 (token cost estimates verified).

### B.2 OQ-20 — per-CLI documentation citations (verified 2026-05-04)

- **Claude Code:**
  - [Slash commands and bundled skills](https://code.claude.com/docs/en/slash-commands)
    — verifies `/help` is a built-in command described as "Show help
    and available commands."
  - [Skills](https://code.claude.com/docs/en/skills) — verifies that
    custom `.claude/skills/<name>/SKILL.md` creates a new slash command
    `/<name>`; "Custom commands have been merged into skills."
  - [Commands reference](https://code.claude.com/docs/en/commands) —
    verifies `/help` description; verifies no documented mechanism
    for augmenting `/help`.
- **Codex CLI:**
  - [`codex-rs/tui/src/slash_command.rs`](https://github.com/openai/codex/blob/main/codex-rs/tui/src/slash_command.rs)
    — verifies the SlashCommand enum is the complete set of compiled-in
    slash commands; verifies `/help` is not present in the enum;
    verifies user-extension is not via the enum (extension is via
    `/skills`, `/plugins`, MCP, subagents).
  - [Codex CLI overview](https://developers.openai.com/codex/cli) —
    parent doc for the Codex slash-commands surface.
  - `EXTERNAL-RESEARCH.md` §12.2 — Codex CLI release stream and
    subagent GA date.
- **Gemini CLI:**
  - [Custom commands](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/custom-commands.md)
    — verifies the `description` field's behavior: "This text will
    be displayed next to your command in the `/help` menu."
  - `EXTERNAL-RESEARCH.md` §12.3 — Gemini CLI v0.40.0 stable;
    v0.41.0-preview.0.

### B.3 Decision rationale citations

- **D-19 thresholds (pack repo):** EXTERNAL-RESEARCH §6.1 (token-cost
  inflection ~50–100 issues; verified plausible by audit §A.5);
  pack-side BD count history (BD-001 → BD-049 over
  ~5 months as named in `README.md` Version History).
- **D-19 thresholds (client repo):** `RESEARCH-AUDIT.md` "OT scale
  baseline"; `INTERNAL-INVENTORY.md` Pass B (OT actual numbers).
- **D-20 path choice:** the per-CLI documentation citations above
  resolve the "documented best practice across all three CLIs" check
  in the brief; one of three documents augmentation; brief's
  directive falls through to namespaced (b).

---

## Appendix C — V3 traceability index

This appendix supersedes V2's Appendix C, adding the V3 elements.

| Element | Drives | Resolves | V3 status |
|---|---|---|---|
| §4 form family | OQ-16 | D-4-V2 / D-16 | preserved from V2 |
| §6.2 addendum (template_version write) | OQ-18 | D-18 | preserved from V2 |
| §16 decisions table | OQ-1..OQ-20 + P1..P6 | all decisions | extended in V3 (D-19, D-20) |
| §17 R1..R10 | V1 risks | covered in V1 | preserved |
| §17 R11..R14 | V2 risks | covered in V2 | preserved |
| §17 R15..R17 | V3 risks (recommendation fatigue, state-file loss, per-CLI help drift) | covered in V3 §17 | new in V3 |
| §18 lifecycle state machines | P1 | per-entry-type design | preserved from V2 |
| §19 update-templates verb + cadence | P2 | propagation mechanism | preserved from V2 |
| §20 backend contract + conformance | P3 | extensibility ergonomics | preserved from V2 |
| §21 audit-query surface | P4 | auditability | preserved from V2 |
| §22 verb table | P5 | cognitive load floor | preserved verb spellings; help-surface scope expanded in §28.2 |
| §23 (V2 Discoverability) | (V2 P6 narrow) | V2 D-NN | replaced by §27 + §28 in V3 |
| §24 multi-template defense | OQ-16 | D-4-V2, D-16 | preserved from V2 |
| §25 structure-vs-free-text defense | OQ-17 | D-17 | preserved from V2 |
| §26 template_version dual-carrier | OQ-18 | D-18 | preserved from V2 |
| §27 P6 (revised) — three-layer surface, hybrid static-dynamic, help+docs coexistence | P6 (revised) | (architectural; D-19/D-20 instantiate) | new in V3 |
| §28.1 OQ-19 — signals, thresholds, state, dismissal, state machine | OQ-19, P6 | D-19 | new in V3 |
| §28.2 OQ-20 — scope expansion, naming defense, per-surface content, self-discoverability | OQ-20, P6 | D-20 | new in V3 |
| Appendix A V3 deltas | (artifact propagation) | (mechanical) | new in V3 |
| Appendix B V3 deltas | (citation index) | (mechanical) | new in V3 |
| Appendix C V3 (this index) | (reading aid) | (mechanical) | new in V3 |

---

## End of architecture proposal V3

V3 is a refinement of V2 that:

1. Resolves OQ-19 with a concrete signal set per surface (3 signals
   pack-side, 7 signals client-side), threshold values tied to
   research data (EXTERNAL-RESEARCH §6.1 token-cost inflection, verified plausible by audit §A.5; OT scale baseline
   numbers), an on-disk state file at
   `.pack-tracker/recommendation-state.json`, a refusal-respecting
   state machine with three explicit states and one re-enable verb,
   and an exact prompt shape with three accept patterns.
2. Resolves OQ-20 by verifying per-CLI `/help` augmentation
   documentation: only Gemini documents augmentation; Claude Code and
   Codex CLI do not. Per the brief's directive, this forces the
   namespaced `/pack-help` (path b). The shell verb `pack help` is
   the LCD; per-CLI namespaced slash commands are layered above. The
   help surface is expanded from V2's tracker-only scope to the
   entire pack verb set, per-surface (pack-repo and client-repo
   verb manifests differ but share the tracker subsection via the
   shared HELP-FRAGMENT-TRACKER.md fragment).
3. Reaffirms every V2 decision (D-1 through D-18) as still holding
   under the revised P6. No V2 decision is superseded; V3 is purely
   additive at the decisions level.
4. Adds three new risks (R15 recommendation-fatigue regression, R16
   state-file corruption / migration loss, R17 per-CLI help drift)
   with mitigations.
5. Treats V2 §23 as replaced (the V3 P6 design lives in §27 + §28);
   the V2 §23 design is preserved by reference for historical
   continuity but is not the V3 design.

The pack-reviewer audits next; the pack-planner breaks the architecture
(V1 + V2 deltas + V3 deltas) into BD-NNN entries for v11 implementation.

---

## Appendix D — V3 design walkthroughs and worked examples

The body sections (§27, §28) define the architecture. This appendix walks
through worked examples that the planner may use as test fixtures during
implementation. The examples are concrete instances of the architecture's
behavior under specific project states; they are not new design.

### D.1 Worked example — pack repo at v11.0 ship date

Project state at the moment v11.0 is released:

- BACKLOG.md has 49 BD entries (~30 active, ~19 resolved); ~12 KB.
- 30-day growth: 4 entries (BD-046 through BD-049 plus 0-3 in the
  current sprint).
- `.pack-tracker/recommendation-state.json` does not exist (this is
  the first session after the v11.0 install).

Pack maintainer runs `pack-startup` for the first time on v11.0.

Step 1. `pack-startup` Step 8 (V3 addition) computes signals:
  - `bd_count_active` = 30
  - `bd_count_total` = 49
  - `backlog_kb` = 12
  - `backlog_growth_30d` = 4

Step 2. `should_recommend(signals, state)`:
  - Guard 1: tracker.toml does not exist; mode is flat-file → continue.
  - Guard 2: state file doesn't exist; default state has
    persistent_refusal=false → continue.
  - Guard 3: thresholds for pack repo:
    `bd_count_active ≥ 80` → 30 < 80, no.
    `backlog_kb ≥ 18` → 12 < 18, no.
    `backlog_growth_30d > 10` → 4 ≤ 10, no.
  - No threshold crosses; `should_recommend` returns False.

Step 3. Static greeting prints (Layer 1):
```
Optiquity AI Agent Config Pack v11.0.
Tracker mode: flat-file (default) — run `pack help` for the full verb list.
[BD-NNN triage queue: 0]
```

No active recommendation. The maintainer does not see any nag about
the tracker; the project is below scale. Static greeting hints at
`pack help` and the option to enable tracker mode if desired.

Maintainer ignores the greeting; works normally.

### D.2 Worked example — client repo at OT current state

Project state matching OT today:

- BACKLOG.md has 113 TD entries (~58 active, ~55 resolved); ~60 KB.
- IMPLEMENTATION_PLAN.md has 60 phases; ~210 KB.
- 88 typed-deferral comments in source; 147 TD-NNN references.
- `.pack-tracker/recommendation-state.json` does not exist.

PM Chat runs `pm-startup` for the first time.

Step 1. Step 8 computes signals:
  - `td_count_active` = 58
  - `td_count_total` = 113
  - `backlog_kb` = 60
  - `phase_count` = 60
  - `implementation_plan_kb` = 210
  - `td_tbd_comment_count` = 0 (OT is clean)
  - `typed_deferral_count` = 88

Step 2. `should_recommend`:
  - Guard 3 thresholds for client:
    `td_count_active ≥ 120` → 58 < 120, no.
    `backlog_kb ≥ 45` → 60 ≥ 45, **YES**.
    `phase_count ≥ 40` → 60 ≥ 40, **YES**.
    `implementation_plan_kb ≥ 100` → 210 ≥ 100, **YES**.
    `td_tbd_comment_count ≥ 60` → 0 < 60, no.
    `typed_deferral_count ≥ 150` → 88 < 150, no.
  - Three signals cross. `should_recommend` returns True.

Step 3. Recommendation prompt fires. The chat picks the most
quantitatively-extreme signal: `implementation_plan_kb` is at 210 KB
vs threshold 100 KB (210% of threshold; ratio 2.1). Other crossed
signals are mentioned in the trailing line:

```
─────────────────────────────────────────────────────────────────
You're at IMPLEMENTATION_PLAN.md size: 210 KB (threshold ≥ 100 KB).

At this scale, GH Issues lets you filter and search faster than
reading the file in full. The migration is one command, and it's
fully reversible — you can switch back to flat files any time
with `pack tracker disable`.

(Also past threshold: BACKLOG.md size: 60 KB; phase count: 60.)

Want to enable the tracker now?

  yes              → run `pack tracker init` (3-5 minutes; reversible)
  not now          → don't ask me again *this* session
  don't ask again  → don't recommend the tracker until I re-enable

Or run `pack help` to see all pack commands.
─────────────────────────────────────────────────────────────────
```

The user says "not now." The chat acknowledges and continues:
```
Acknowledged. I won't bring up the tracker again this session. You
can run `pack tracker init` any time, or run `pack help` for all
verbs.
```

In-chat session memory: `dismissed_this_session = true`.

The user works normally. The static greeting at session start
showed; the active recommendation showed once; that's it for this
session.

Next session (perhaps the next day):

- The state file now exists with `last_recommendation_shown_at: <yesterday>`,
  `last_recommendation_signals: {td_count_active: 58, backlog_kb: 60, phase_count: 60, implementation_plan_kb: 210, ...}`,
  `persistent_refusal: false`.
- New session computes fresh signals. Suppose nothing has materially
  changed: `td_count_active = 58, backlog_kb = 60, phase_count = 61,
  implementation_plan_kb = 212`.
- `should_recommend`: Guard 4 — for each crossed signal, was it
  already over threshold last time and now within 25% of last? Yes:
  60 / 60 = 1.0, well under 1.25. 61 / 60 = 1.017. 212 / 210 = 1.01.
  All within the 25% growth window; no re-fire.
- Static greeting prints; no active recommendation.

The user works normally. The cross-session experience: not nagged.

Some weeks later, the project has grown:
- `td_count_active = 75, backlog_kb = 78, phase_count = 65,
  implementation_plan_kb = 240, typed_deferral_count = 102`.
- 78 / 60 = 1.30 (BACKLOG kb grew 30% — past 25% threshold). Refire.
- 240 / 210 = 1.14 — within 25%; this signal alone wouldn't refire.
- The first-found 25%-grown signal (`backlog_kb`) triggers refire.
  Recommendation prompt fires again, naming `backlog_kb` (the
  newly-grown signal):
```
You're at BACKLOG.md size: 78 KB (was 60 KB last time we asked,
threshold ≥ 45 KB; 30% growth crosses our material-change window).
...
```

The user can refuse persistently this time:
```
> don't ask again
Acknowledged. I'll stop recommending the tracker on this surface
until you run `pack tracker enable-recommendations` (or say "remind
me about the tracker again"). You can still run `pack tracker init`
directly any time.
```

State file updates: `persistent_refusal = true`,
`persistent_refusal_at = <now>`.

Future sessions: Guard 2 short-circuits; no recommendation prompt.
Static greeting still prints (with the standard `pack help` hint;
no tracker line because the user opted out persistently).

### D.3 Worked example — user re-enables months later

Months pass. The project has grown more (`td_count_active = 200`,
`backlog_kb = 130`, etc.) and the user is reconsidering.

User: "remind me about the tracker again"

The chat (per `PACK-CHAT.md` / `PM-CHAT.md` recommendation routing)
recognizes the colloquial form and runs:
```
pack tracker enable-recommendations
```

State file updates: `persistent_refusal = false`,
`user_re_enable_count = 1`. The chat prints:
```
Recommendations re-enabled. I'll surface the tracker recommendation
when project state warrants it. (You can run `pack tracker init`
right now if you're ready, or wait — the next session will check
your project state.)
```

Next session: signals computed; thresholds crossed (the project has
grown a lot since the persistent refusal); Guard 4 — the
`last_recommendation_signals` from the persistent-refusal moment is
the snapshot. Compare current vs that:
- If current signals are within 25% of that snapshot → no recommendation
  (the user re-enabled but the project hasn't materially changed since
  refusal; respect the implicit "remind me when something is
  different").
- If current signals are >25% of that snapshot → recommendation fires.

For the OT case: current `td_count_active=200` vs last-refusal=58 →
~3.4×, well past 25%. Recommendation fires. Static greeting shows;
recommendation prompt shows.

The user accepts. `pack tracker init` runs. State file is preserved
through the migration (D-2 contract: state file is gitignored,
machine-local, persistent). `persistent_refusal` stays false (no
reason to re-set it). Future sessions: Guard 1 (tracker mode
enabled) → no recommendations.

### D.4 Worked example — corrupted state file

Suppose the JSON state file is corrupted (manual edit gone wrong,
merge conflict markers, etc.). On session start:

```
[pm-startup] Reading .pack-tracker/recommendation-state.json...
[error] JSON parse failed at line 7 column 23.
[recovery] Writing fresh default state. Your previous "don't ask
again" preference (if any) is reset; the chat may surface the
tracker recommendation again at next threshold cross. If this is
unintended, run `pack tracker enable-recommendations` immediately
and the system will not recommend until your project state changes
materially.
```

The chat continues. The session proceeds. No crash, no silent
fallback.

This honors D-7 (no silent retry, surface clear actionable messages).

### D.5 Worked example — user runs `pack help` on Codex CLI

Codex CLI user. Static greeting just printed; user types in shell:

```bash
$ pack help
```

`scripts/pack-help.sh` runs:
- Detects surface: presence of `BACKLOG.md` with `^\*\*BD-` →
  pack repo.
- Reads `HELP-FRAGMENT-PACK.md` from pack repo root.
- Includes `HELP-FRAGMENT-TRACKER.md` content inline.
- Prints to stdout.

Output (~400 tokens) shows:
- Pack development commands.
- Tracker commands (the shared section).
- Colloquial mappings table.
- "See also" pointer to QUICKSTART.md, OPTIONAL-FEATURES.md, etc.

The Codex user discovers every verb. No `/help` slash command;
that's fine — the LCD shell verb did the job.

Alternative Codex paths:
- User types `/skills` (Codex built-in). Output lists installed
  skills, including `pack-help` with its description.
- User invokes `pack-help` skill directly via Codex's skill-invocation
  syntax (TBD per Codex, but typically the skill name in chat).
  Output: same as `pack help`.

All paths converge on the same content (HELP-FRAGMENT.md).

### D.6 Worked example — user runs `/pack-help` on Claude Code

Claude Code user. They start typing `/p` in the composer; Claude
Code's autocomplete shows `/pack-help` (and the description from
`.claude/skills/pack-help/SKILL.md` frontmatter: "Show all pack
commands and colloquial mappings"). User selects.

Claude Code reads the skill's SKILL.md body. The body includes:
```markdown
---
name: pack-help
description: Show all pack commands and colloquial mappings.
---

## Help fragment

!`bash scripts/pack-help.sh`

## Notes

For full documentation, see QUICKSTART.md or OPTIONAL-FEATURES.md.
```

The shell injection (`!\`bash scripts/pack-help.sh\``) runs
`pack-help.sh`; output is inserted into the chat context. Claude
Code returns the help fragment as the response to the user.

User sees the same content as the Codex user (same fragment,
because both routes invoke `pack-help.sh`).

### D.7 Worked example — user runs `/pack-help` on Gemini CLI

Gemini CLI user. They type `/p`; Gemini's autocomplete shows
`/pack-help` (description from `.gemini/commands/pack-help.toml`:
"Show all pack commands and colloquial mappings"). User selects.

The TOML file:
```toml
description = "Show all pack commands and colloquial mappings."
prompt = """
The user wants to see the full pack verb list and colloquial
phrasings. Run the help script and present its output.

!{bash scripts/pack-help.sh}
"""
```

Gemini executes the shell injection (with security confirmation per
Gemini's documented behavior); the script runs; output is injected
into the prompt; Gemini returns the help fragment as the response.

Same content as Codex and Claude Code. LCD parity holds.

Bonus: Gemini's native `/help` will also list `/pack-help` because
the `description` field's documented behavior puts custom commands
in `/help`. The user might discover via `/help` → see `/pack-help`
listed → run it. That path works but is gravy; the static greeting
named `pack help` (LCD), so the primary path is the shell.

### D.8 Edge case — multiple surfaces in one machine

A pack maintainer may have both the pack-repo and one or more client
projects on the same machine. Each surface has its own
`.pack-tracker/recommendation-state.json`. They are independent:

- Pack-repo state: separate file at `<pack-root>/.pack-tracker/
  recommendation-state.json`.
- Client-A state: separate at `<client-A-root>/.pack-tracker/
  recommendation-state.json`.
- Client-B state: separate at `<client-B-root>/.pack-tracker/
  recommendation-state.json`.

A user who refuses recommendations on client-A does not affect
client-B or the pack repo. The independence axis (`DESIGN-BRIEF.md`
§5.4) holds at the recommendation system too: pack-side and
client-side adoptions don't couple, and one client doesn't couple
to another.

### D.9 Edge case — fresh clone, machine-private state

User clones an existing project (already on v11). The
`.pack-tracker/` directory is gitignored; the clone has no state
file. On first session start, the system treats the project as
"fresh recommendation history" and computes signals.

If the project is at scale, the first session triggers the
recommendation. The user's prior persistent refusal (on a different
machine) does not propagate. Per R16, this is the documented
trade-off.

### D.10 Edge case — project shrinks below threshold

A project that was at scale and is now smaller (resolved many TDs;
removed phases) may drop below thresholds. On next session:

- Guard 3: no signal crosses → `should_recommend` returns False.
- No active recommendation; static greeting only.
- The state file is unchanged (the chat doesn't reset
  `last_recommendation_*` just because signals dropped).

If the project later grows again past threshold AND signals are 25%
higher than `last_recommendation_signals` → recommendation fires.

### D.11 Edge case — user runs `pack tracker init` directly

User skips the recommendation prompt and runs `pack tracker init`
directly (perhaps they read about v11 and decided independently).
The init script runs; tracker mode is enabled; `tracker.toml`
records `mode.state = "tracker"`.

Next session: Guard 1 fires (tracker mode); no recommendation.
The state file is preserved (it might come back into use if the
user later runs `pack tracker disable`).

### D.12 Edge case — user disables tracker mode

User runs `pack tracker disable`. Reverse migration runs.
`tracker.toml` updates to `mode.state = "flat-file"`. The state file
is preserved (D-8 reverse contract).

Next session: Guard 1 doesn't fire (flat-file). The
`last_recommendation_*` from the prior pre-tracker recommendation
session is still in the file. Guard 4 evaluates: signals are
computed fresh (probably similar to what they were when tracker was
enabled, since the data is the same — just back in flat files);
within 25% of the last snapshot; no recommendation fires.

If the user *wants* the recommendation to fire again (e.g., they
disabled tracker for unrelated reasons and want to be re-prompted
later), they can:
- Just wait for project growth past 25%; recommendation fires
  organically.
- Or delete `.pack-tracker/recommendation-state.json` manually;
  state resets to default; first threshold-cross fires.
- Or run `pack tracker enable-recommendations` (which only matters
  if `persistent_refusal` was true, which it isn't in this scenario).

The system gracefully handles repeated tracker-toggle cycles.

---

## Appendix E — Per-CLI documentation cross-check (verified 2026-05-04)

This appendix is the verifiable record of the per-CLI documentation
checks that drove D-20's path choice. Each line is a citation pinned
to the doc URL and verbatim quote. Recency: all citations verified
2026-05-04 (the V3 design date), aligned with `EXTERNAL-RESEARCH.md`
§12 verification 2026-05-03.

### E.1 Claude Code

**Question 1: Does Claude Code document `/help` as a built-in slash
command?**

Yes. The commands reference at
`https://code.claude.com/docs/en/commands` describes `/help` as:
"Show help and available commands."

**Question 2: Does Claude Code document a mechanism to augment the
content of `/help` with custom user-provided content?**

No. The skills documentation at
`https://code.claude.com/docs/en/skills` documents the user-facing
extension mechanism: "Custom commands have been merged into skills.
A file at `.claude/commands/deploy.md` and a skill at
`.claude/skills/deploy/SKILL.md` both create `/deploy` and work the
same way."

The pattern is: add a skill or command file → that file becomes a
new slash command with the directory's name. The skill's `description`
field is documented as: "What the skill does and when to use it.
Claude uses this to decide when to apply the skill."

The `description` is for Claude's auto-invocation decision-making,
not for `/help` augmentation. There is no documented mechanism
saying "the description appears in the `/help` menu."

In practice: when the user types `/h` in the Claude Code composer,
the autocomplete may show `/help` (built-in) plus other commands
starting with `h`. When the user runs `/help`, the output is the
built-in command list — Claude Code may or may not include
user-installed commands in that list (this varies by version and
is not documented as a guaranteed feature). The pack does not
rely on this incidental behavior.

**Conclusion:** `/help` augmentation is **not** a documented best
practice in Claude Code.

### E.2 Codex CLI

**Question 1: Does Codex CLI have a `/help` slash command?**

No. The `SlashCommand` enum in `codex-rs/tui/src/slash_command.rs`
(verified at
`https://github.com/openai/codex/blob/main/codex-rs/tui/src/slash_command.rs`)
does not include `Help`. The complete enum (paraphrased; see source
for current list) includes `/skills`, `/mcp`, `/feedback`, `/status`,
`/model`, `/init`, `/compact`, `/review`, `/diff`, `/copy`,
`/permissions`, `/keymap`, `/vim`, `/sandbox-add-read-dir`,
`/experimental`, `/memories`, `/hooks`, `/apps`, `/plugins`,
`/logout`, `/quit`, `/exit`, `/clear`, `/personality`, `/realtime`,
`/settings`, and several debug commands. Notably absent: `/help`.

**Question 2: Does Codex CLI document a mechanism to augment a
non-existent `/help`?**

No. The slash-command enum is compiled-in; runtime extension is
not via the slash-command mechanism. User extension surfaces are:
- Skills at `~/.codex/skills/<name>` — invoked via `/skills` (the
  slash command that lists skills) and the user's chat interaction.
- Subagents at `~/.codex/agents/<name>.toml` — invoked via the
  Codex agent-spawning model.
- MCP servers at `~/.codex/config.toml [mcp_servers.<name>]`.
- Plugins at `~/.codex/plugins/...` — invoked via `/plugins`.

None of these augments `/help` because `/help` does not exist.

**Conclusion:** `/help` augmentation is **structurally not possible**
in Codex CLI.

### E.3 Gemini CLI

**Question 1: Does Gemini CLI have a `/help` slash command?**

Yes, as a built-in.

**Question 2: Does Gemini CLI document a mechanism to augment the
content of `/help` with custom user-provided content?**

Yes, indirectly. The custom-commands documentation at
`https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/custom-commands.md`
states: "**`description` (String): A brief, one-line description of
what the command does. This text will be displayed next to your
command in the `/help` menu.**" (verbatim; emphasis added)

This means: adding a custom command at
`.gemini/commands/<name>.toml` with a `description` field causes
that command's name and description to appear in the output of the
built-in `/help`. This is documented `/help` augmentation.

The augmentation is constrained: only commands you add appear; you
can't put arbitrary text in `/help`. But within the constraint,
the documented behavior is clear.

**Conclusion:** `/help` augmentation is a **documented feature** in
Gemini CLI.

### E.4 Cross-CLI summary

| Question | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| `/help` exists? | yes | **no** | yes |
| `/help` augmentation documented? | **no** | **structurally not possible** | yes |
| Best-practice citation across all three? | — — — | one of three | — |

The brief's directive: "If best-practice citations exist across all
three, this is the simpler choice. If not, prefer (b) [namespaced
`/pack-help`]."

One of three is **not** "across all three." Therefore (b).

### E.5 What if a future CLI release changes this?

Each CLI is on an active release stream:

- Claude Code: v2.1.126 (May 2026 stable) → future versions may add
  documented `/help` augmentation.
- Codex CLI: daily-cadence releases → future versions may add a
  `/help` slash command.
- Gemini CLI: v0.40.0 stable; v0.41.0 imminent → augmentation behavior
  is documented and stable.

If all three CLIs eventually document `/help` augmentation, V3's D-20
choice could be revisited in a future minor — but the pack-architect
agent's recommendation stands: **the namespaced `/pack-help` is the
robust choice today and has no failure mode if the CLI surface
evolves.** Switching from namespaced to augmentation later is an
additive change (the user already knows `/pack-help`; if the pack
later also auto-augments `/help`, the user benefits but doesn't lose
anything). Switching the other way would be a breaking change for
users who learned augmented-`/help` behavior.

V3 chooses the additive-friendly path.

---

## Appendix F — Conformance with DESIGN-BRIEF.md priorities

This appendix is a conformance check: every priority and success
criterion from `DESIGN-BRIEF.md` §3.4 and §4.1 is mapped to a V3
section that satisfies it.

### F.1 Priorities (§3.4)

| Priority | V3 satisfaction |
|---|---|
| P1 entry lifecycle | V2 §18 (preserved in V3) |
| P2 maintenance ergonomics | V2 §19 (preserved in V3); V3 §27.4.4 maintenance cadence for help docs |
| P3 backend extensibility | V2 §20 (preserved) |
| P4 auditability | V2 §21 (preserved) |
| P5 cognitive load floor | V2 §22 (preserved verb spellings); V3 §28.2 expands help-surface scope without adding new verbs (existing verbs were already in V2 §22; help just lists more of them) |
| P6 (revised) discoverability + proactive guidance | V3 §27 (architecture); V3 §28.1 (OQ-19); V3 §28.2 (OQ-20) |

### F.2 Success criteria (§4.1)

V2 already satisfied the original success criteria. V3 adds three
new criteria from the revised brief:

| Criterion | V3 satisfaction |
|---|---|
| "Default-flat-file users see no change in their workflow." | preserved from V2; V3 adds the static greeting + optional active recommendation, both of which are explicitly designed to be **non-disruptive** for users below threshold or with persistent refusal. The static line is ~30 tokens; not a workflow change. |
| "After opt-in, common queries cost measurably less in tokens..." | preserved from V2 §12 |
| "Reverse migration produces well-formed flat files..." | preserved from V2 §6.5 |
| "All three CLIs work identically at the LCD..." | preserved (LCD = `gh` for tracker, `pack help` shell verb for help discoverability) |
| "Architecture supports adding another tracker..." | preserved from V2 §20 |
| **NEW: "The chat proactively recommends tracker opt-in at most once per session, surfacing the recommendation when scale signals (per OQ-19) cross. The recommendation is dismissable per-session AND persistently. After persistent dismissal, no further recommendations until the user explicitly re-enables them. Verifiable by integration test."** | V3 §28.1 (signal sets, thresholds, state file, state machine); V3 §28.1.10 (integration tests); V3 D-19 (decision row) |
| **NEW: "The help-command surface (per OQ-20) lists every pack-shipped verb (tracker verbs from V2 §22 PLUS init / migrate / validate / agent-run / any other top-level verbs). Per-surface (pack repo / client repo) help content matches each surface's verb set. Tested by reading help output and matching against the verb manifest."** | V3 §28.2.1 (verb manifest), §28.2.4 (per-surface split), validate-pack Check 22 / 23 |
| **NEW: "External documentation (QUICKSTART.md, OPTIONAL-FEATURES.md, INSTALL-PROCEDURES.md) covers tracker mode, opt-in workflow, and verb reference at a depth appropriate to first-time users. In-chat help functionality covers the verb-list and quick-reference use case. Both are maintained as the pack evolves; both are tested for completeness independently."** | V3 §27.4 coexistence model; §27.4.3 drift-prevention test; §27.4.4 cadence; validate-pack Check 22 / 23 |

All success criteria pass.

---

## Appendix G — Reading path summary for V2 → V3 readers

For someone arriving at V3 with V2 in mind, the reading order:

1. **§0 (this document)** — change log, what changed materially,
   what's new, what's preserved. The reading index.
2. **§16 decisions table** — see V3 status of every V1/V2 decision
   plus D-19 / D-20 new rows. Two changes: D-19 and D-20 are new;
   nothing else changes. This is the fastest way to understand "what
   are the new decisions, given everything I already know from V2?"
3. **§17 risks** — three new risks (R15, R16, R17) layered on V1
   R1–R8, R10 and V2 R11–R14. Read these quickly to absorb the new
   surface area.
4. **§23 (V2 → V3 pointer)** — quick orientation that V2 §23 is
   replaced.
5. **§27 (P6 revised)** — the new architecture for discoverability
   and proactive guidance. Substantive read; understand the
   three-layer surface, hybrid static-dynamic balance,
   help-vs-external-docs coexistence model.
6. **§28.1 (OQ-19 resolution)** — the concrete design for
   inflection signals and thresholds. Substantive read; understand
   the signal sets, threshold values with research-data rationale,
   state file, state machine.
7. **§28.2 (OQ-20 resolution)** — the concrete design for help-verb
   scope, naming (with the per-CLI documentation defense), and
   per-surface content. Read §28.2.2 carefully — it's the
   research-driven choice between path (a) and path (b).
8. **Appendix A** — V3 deltas to artifact list. Quickly mappable
   files-to-touch view.
9. **Appendix B** — citation index for V3-specific decisions.
10. **Appendix C** — traceability index. Use as a quick reference to
    "which V3 element resolves which OQ / priority?"
11. **Appendix D** — worked examples. Optional; useful as test
    fixtures for the planner.
12. **Appendix E** — per-CLI documentation cross-check. The
    verifiable evidence behind D-20's path choice. Read if
    questioning the OQ-20 resolution.
13. **Appendix F** — conformance with DESIGN-BRIEF priorities. Read
    if questioning whether V3 satisfies the brief.
14. **Appendix G (this section)** — reading path summary.

For someone reading V3 as their *first* exposure (no V2 context),
the order is: V1 first (preserved sections); then V2 (deltas);
then V3. V3 is intentionally a delta document.

---

## Body sections complete; supplementary appendices follow

The body of V3 (§§0, 16, 17, 23, 27, 28 plus appendices A–G) is the
load-bearing architecture. Appendices H–K below are supplementary
material — alternatives considered and rejected, an implementation
surface summary for the planner, a gap analysis comparing V2's P6
to V3's, and a glossary of V3-introduced terms.

Reviewers can read body + appendices A–G as the minimum complete V3;
appendices H–K reward additional reading time but do not contain
new architectural decisions.


---

## Appendix H — Alternatives considered and rejected

V3's design was reached after evaluating alternatives. This appendix
documents the rejected paths so the maintainer (and a future reviewer)
sees the architect's reasoning. Each alternative is named, evaluated
against the brief's priorities, and rejected with rationale.

### H.1 Alternatives for OQ-19 (signals, thresholds, state)

**Alt 19-A — Single-signal trigger.**

Use only `td_count_active` (or pack-side `bd_count_active`) and ignore
other signals. Threshold: a single number per surface. Evaluated: this
is the simplest signal set, but it misses projects that scale on a
non-count axis (e.g., a project with 50 entries but a 200 KB BACKLOG
because each entry has long Description text). EXTERNAL-RESEARCH §6.1 token-cost
inflection (verified plausible by audit §A.5) is a *combined* signal; using only count understates the
tracker's value for verbose-text projects.

Rejected. The OR-logic multi-signal design (§28.1.3) catches both
count-scaled and verbosity-scaled projects without complexity cost.

**Alt 19-B — Time-based trigger.**

Trigger the recommendation at fixed time intervals (e.g., once per
month per surface). Evaluated: time-based ignores project state. A
project that's stable at small scale gets the same recommendation
cadence as one growing 10×. The brief's "scale signals indicate it
would be a good fit" sentence explicitly ties to scale, not time.

Rejected. State-driven > time-driven. Time-based degrades to the
"nag every N days" anti-pattern the brief's refusal-respecting
language implicitly forbids.

**Alt 19-C — User-configurable thresholds.**

Let the user set thresholds in `tracker.toml`. Evaluated: the user
can already disable recommendations persistently; finer-grained
threshold tuning is unnecessary for v11. Adds config surface area
without clear value. The architect-set thresholds are tied to
research data; users have no better information to set them with.

Rejected for v11. Future minor could add this if user feedback
demonstrates a need.

**Alt 19-D — In-process state (no file).**

Hold all state in chat session memory; no on-disk persistence.
Evaluated: this fails the brief's "persistent refusal until
explicitly re-enabled" because session memory is per-session. The
file is required for cross-session persistence.

Rejected by the brief.

**Alt 19-E — Tracker-toml inline state.**

Store recommendation state in a `[recommendations]` block of
`tracker.toml`. Evaluated: D-2's principle ("`tracker.toml` is the
user's mode declaration") gets blurred. The user might git-commit
`tracker.toml` (it's a typically-committed config file) and then
their persistent-refusal preference appears in PR diffs and merges
across machines — surprising behavior. Keeping state separate
(`.pack-tracker/recommendation-state.json`) and gitignored prevents
these surprises.

Rejected.

**Alt 19-F — Continuous monitoring (background process).**

Run a daemon that watches BACKLOG.md changes and pings the chat
when thresholds cross. Evaluated: out of scope for v11; adds OS-level
background-process complexity; not needed because session-start
checks are sufficient for the recommendation cadence.

Rejected. Future minor if the use case emerges.

**Alt 19-G — Webhooks from GitHub Issues (post-opt-in).**

Once tracker mode is enabled, use GH webhooks to surface
recommendations for re-tuning (e.g., "you're now over the
sub-issues-per-parent ceiling"). Evaluated: out of scope for v11
discoverability; this is a different problem (post-opt-in tuning vs
pre-opt-in opt-in recommendation). Captured in V2 §17 R12 territory.

Not directly relevant to OQ-19; mentioned only for completeness.

### H.2 Alternatives for OQ-19 prompt shape

**Alt 19-P-1 — Yes/No only (binary).**

Two options: yes (init) or no (silent forever). Evaluated: this
collapses "not now" and "never" into a single button. The brief
explicitly distinguishes them. Rejected.

**Alt 19-P-2 — Single-button "configure recommendations later."**

One option (init) plus a "configure recommendation cadence" link.
Evaluated: more buttons = more decisions for the user; the three-option
shape (yes / not now / never) maps cleanly onto the documented refusal
levels. Adding a fourth option ("configure") complicates the
common case.

Rejected. The three-option prompt is the right balance.

**Alt 19-P-3 — Asynchronous (dialog box, OS notification).**

Pop the recommendation as an OS notification or non-blocking
dialog. Evaluated: out of scope per `DESIGN-BRIEF.md` §1 (CLI-only;
no Desktop / Web). The CLI-text-prompt model is the LCD.

Rejected.

**Alt 19-P-4 — Multi-line prose with no explicit options.**

A free-form recommendation message that ends with "let me know if
you'd like to enable it." Evaluated: violates D-7's "clear actionable
messages" principle. The user has to figure out what to say. The
explicit three-option shape removes ambiguity.

Rejected.

### H.3 Alternatives for OQ-20 (help-verb naming)

**Alt 20-A — `pack` (root verb with sub-verbs).**

Use `pack` as the top-level verb with `pack help`, `pack tracker init`,
etc. Already in V2 §22. V3 reaffirms.

Status: this IS the V3 design (pack tracker init, pack tracker doctor,
pack help, etc.). Reaffirmed.

**Alt 20-B — `optiquity-pack` (more-namespaced).**

Use the full pack name as the verb prefix. Evaluated: longer to type;
`pack` is unambiguous in the user's project context (it always
refers to this pack). Adding the org name to every verb invocation
costs every-day usability for marginal namespace clarity.

Rejected.

**Alt 20-C — `op` (extreme abbreviation).**

Use `op` as the prefix. Evaluated: `op` collides with the `op` CLI
from 1Password (a popular CLI tool). Namespace collision is a real
risk on developer machines.

Rejected.

**Alt 20-D — Per-CLI-different verb names.**

`pack` on Codex, `pck` on Claude, etc. Evaluated: violates LCD parity
(`DESIGN-BRIEF.md` §3.1: "All three CLIs work identically at the
lowest common denominator"). The user shouldn't have to remember
different verb spellings per CLI.

Rejected.

**Alt 20-E — `/pack` parent command with sub-verb autocomplete.**

Each CLI ships `/pack` (a single command) which then prompts for or
autocompletes a sub-verb (e.g., `/pack help`, `/pack tracker init`).
Evaluated: this is a possibility, but each CLI's autocomplete
mechanism for parent-with-sub-verbs is different (Claude Code's
arguments via `argument-hint`; Codex's `supports_inline_args`; Gemini's
TOML `prompt` interpolation). Implementing parent-with-sub-verb
identically across the three is more complex than three flat slash
commands.

For v11, V3 chose flat namespaced verbs (`/pack-help`, NOT `/pack help`
as a parent-sub-verb pair via slash). The shell verb `pack help` IS
parent-with-sub-verb, but at the shell layer that's natural.

Rejected for the slash surface; preserved for the shell surface.

### H.4 Alternatives for OQ-20 (help-content-source location)

**Alt 20-F — Help content in HELP-FRAGMENT.md (V3 design).**

V3 chooses single source-of-truth at HELP-FRAGMENT.md.

**Alt 20-G — Help content in PACK-CHAT.md / PM-CHAT.md.**

Place verb list inside the chat-operating manual (PACK-CHAT.md,
PM-CHAT.md). Evaluated: those files are large (chat operating rules
+ colloquial routing tables); adding the verb list bloats them.
The trinity rule already applies; another section would be more
trinity propagation work.

Rejected. Keep PACK-CHAT.md / PM-CHAT.md focused on chat-operating
rules; HELP-FRAGMENT.md is dedicated to verb listing.

**Alt 20-H — Help content in trinity files (CLAUDE.md / AGENTS.md /
GEMINI.md).**

Add verb list to the trinity. Evaluated: trinity files are pack
context (rules for the agent); the verb list is human-facing
discovery surface. Mixing them violates separation of concerns.

Rejected.

**Alt 20-I — Help content auto-generated from script docstrings.**

Run `for f in scripts/*.sh; do head -5 $f | grep '^#'; done` and
print as help. Evaluated: relies on every script having a parseable
docstring header; ergonomics-fragile (a script without a docstring
gets a confusing entry). Fragments are easier to maintain.

Rejected for v11. Auto-generation could be a future minor (e.g.,
to validate that HELP-FRAGMENT.md matches script docstrings).

### H.5 Alternatives for the layer-3 (proactive recommendation) firing condition

**Alt 19-G-1 — At every flat-file session above threshold.**

Fire the recommendation every session when signals are over threshold,
regardless of whether the user dismissed earlier. Evaluated: violates
the brief's "refusal-respecting" mandate. Even per-session "not now"
should silence further recommendations in the current session.

Rejected.

**Alt 19-G-2 — At first session only after threshold cross.**

Fire once at the first session when threshold first crosses; never
again unless the user runs `pack tracker enable-recommendations`.
Evaluated: under-recommends. A project that crossed at session-1,
declined ("not now"), and grew further to 2× threshold by session-50
should see another recommendation (the situation has materially
changed). The 25%-growth re-trigger (§28.1.5 Guard 4) handles this.

Rejected. The 25% growth re-trigger is the right balance: not every
session, not just once, but when state has materially changed.

**Alt 19-G-3 — At every session, but only on threshold cross with
material change since last shown.**

This IS the V3 design (Guard 4 + 25% growth threshold). Reaffirmed.

### H.6 Alternatives for the per-CLI implementation files

**Alt 20-J — Single `.pack/help.md` shared across CLIs.**

Have one config file that all three CLIs read. Evaluated: the three
CLIs do not share a common config format. Each has its own location
and schema. Forcing a shared file would require teaching each CLI to
read a common file, which the CLIs don't do natively.

Rejected. Trinity-replicated per-CLI files are the cost of
cross-CLI parity; we pay it everywhere else (.claude/agents/,
.codex/agents/, .gemini/agents/) and pay it here too.

**Alt 20-K — One CLI's file plus a wrapper for the others.**

Have a single `.gemini/commands/pack-help.toml` and a wrapper script
that translates it for Claude / Codex. Evaluated: cute but fragile.
A change to the Gemini file might not propagate cleanly to the others.
Trinity rule already requires lockstep updates; wrapper-from-one-source
violates the spirit (one wrapper means one CLI is "primary").

Rejected.

### H.7 Alternatives for state-file format

**Alt 20-L — TOML state file.**

Use TOML instead of JSON. Evaluated: JSON is the more common runtime
state format (machine-managed); TOML is more human-readable but
state files are not human-edited (the chat manages them). JSON has
better support for nested structures, which the
`last_recommendation_signals` block uses.

Rejected. JSON is more appropriate for runtime-managed state.

**Alt 20-M — INI / properties file.**

Simpler format. Evaluated: doesn't handle nested state cleanly
(`last_recommendation_signals` is a map). JSON wins.

Rejected.

**Alt 20-N — SQLite database.**

Heavyweight. For v11's small state (~10 fields), SQLite is overkill.

Rejected.

---

## Appendix I — V3 implementation surface summary

This appendix is for the planner. It lists every file or section the
implementation phase will touch, as a single flat list, derived from
the body sections.

### I.1 New files (V3 introduces)

```
project-template/docs/pack/HELP-FRAGMENT.md           (rewrite from V2 tracker-only to entire pack)
HELP-FRAGMENT-PACK.md                                  (pack repo root; new — Pack Chat reads)
HELP-FRAGMENT-TRACKER.md                              (pack repo root; new — canonical shared tracker section)
project-template/docs/pack/HELP-FRAGMENT-TRACKER.md   (init-project.sh installs from pack-root canonical; byte-identical mirror)
.claude/skills/pack-help/SKILL.md                      (per surface)
.codex/skills/pack-help/SKILL.md                           (per surface)
.gemini/commands/pack-help.toml                        (per surface)
scripts/lib/recommendation.sh                          (signal computation, state I/O)
scripts/tests/recommendation-test.sh                   (integration tests for recommendation system)
scripts/tests/tracker-migrate-roundtrip-test.sh        (multi-template-version roundtrip test; per V1 §6.6.1)
.pack-tracker/recommendation-state.json                (lazy-created at first session; gitignored)
```

### I.2 Modified files (V3 extends)

```
PACK-CHAT.md                                           (Recommendation routing section added)
project-template/docs/pack/PM-CHAT.md                  (parallel addition)
CLAUDE.md / AGENTS.md / GEMINI.md (pack root)          (one-line "Pack commands" reference)
project-template/{CLAUDE,AGENTS,GEMINI}.md             (parallel addition)
.claude/skills/pack-startup/SKILL.md                   (Step 8 added: signal compute + recommendation)
.codex/skills/pack-startup/SKILL.md                        (parallel)
.gemini/commands/pack-startup.toml                     (parallel)
project-template/skills/pm-startup/SKILL.md            (Step 8 added)
.claude/skills/pm-startup/SKILL.md                     (parallel - distributed copy)
.codex/skills/pm-startup/SKILL.md                          (parallel)
.gemini/commands/pm-startup.toml                       (parallel)
scripts/init-project.sh                                (install per-CLI pack-help files; install fragments)
scripts/migrate-v9-to-v10.sh                           (or v10-to-v11 migrator: install help surfaces during upgrade)
scripts/validate-pack.py                               (Checks 21, 22, 23 added)
```

### I.3 Files preserved (V2 already sufficient)

```
scripts/pack-help.sh                                   (V2 named; V3 broadens internal logic without renaming)
.gitignore                                             (.pack-tracker/ already gitignored per V1 §3.4)
```

### I.4 Trinity propagation matrix

| Surface | Trinity files | Per-CLI command files | Skill files | Shared fragments |
|---|---|---|---|---|
| Pack repo | CLAUDE.md, AGENTS.md, GEMINI.md (root) | .claude/skills/pack-help/, .codex/skills/pack-help/SKILL.md, .gemini/commands/pack-help.toml | .claude/skills/pack-startup/, .codex/skills/pack-startup/SKILL.md, .gemini/commands/pack-startup.toml | HELP-FRAGMENT-TRACKER.md (pack root, canonical) |
| Client repo | project-template/CLAUDE.md, AGENTS.md, GEMINI.md | (same per-CLI in project-template/) | project-template/skills/pm-startup/SKILL.md (canonical), distributed to .claude/, .codex/, .gemini/ at init | project-template/docs/pack/HELP-FRAGMENT-TRACKER.md (mirror of pack-root canonical) |

The trinity rule applies to:
- Pack-root trinity (3 files, lockstep).
- Project-template trinity (3 files, lockstep).
- Per-CLI command files (3 per surface, lockstep).
- Per-CLI skill files for pack-help (3 per surface, lockstep).
- Per-CLI skill files for pack-startup / pm-startup (3 per surface, lockstep).
- Shared fragment `HELP-FRAGMENT-TRACKER.md` (pack-root canonical;
  client-tree mirror); identity enforced by `validate-pack.py`. The
  trinity rule does not apply file-wise (it is a single document, not a
  per-CLI triplet); it applies content-wise via the
  pack-root-canonical → client-mirror copy contract.

`validate-pack.py` Check 21 (V3) verifies the per-CLI command-file
parity. The existing trinity check (introduced in v9.x for trinity
files) extends to the new files.

### I.5 BD-NNN entries the planner will create (architect's hint, not a
prescription)

The planner is free to break the work into BD-NNN entries however
they see fit. As an architect's hint, the work decomposes naturally
into ~6–8 entries:

1. **OQ-19 implementation: signals, state, recommendation.**
   `scripts/lib/recommendation.sh`; state file schema; tests.
2. **OQ-19 implementation: skill integration.** Add Step 8 to
   pack-startup / pm-startup; per-CLI propagation.
3. **OQ-20 implementation: HELP-FRAGMENT.md rewrite.** Extract
   tracker section; create pack-side fragment; expand client-side
   fragment.
4. **OQ-20 implementation: per-CLI pack-help skill / command.**
   Three files per surface (~6 files total); install via
   init-project.sh.
5. **OQ-20 implementation: trinity addendum.** One-line "Pack
   commands" reference in CLAUDE.md / AGENTS.md / GEMINI.md (both
   pack and project-template trinity).
6. **OQ-20 implementation: PACK-CHAT.md / PM-CHAT.md additions.**
   Recommendation routing section.
7. **validate-pack.py extensions.** Checks 21, 22, 23 (V3).
8. **Documentation updates.** QUICKSTART.md, OPTIONAL-FEATURES.md,
   INSTALL-PROCEDURES.md add references to HELP-FRAGMENT.md and
   the recommendation system.

The planner may merge / split / re-sequence as needed.

---

## Appendix J — Comparison: V3 vs V2 design gap analysis

This appendix is a side-by-side comparison of V2's P6 design vs V3's,
showing exactly what gap the maintainer identified and how V3 fills
it. Useful for the maintainer reviewing whether V3 actually addresses
the concerns that prompted the V3 round.

### J.1 The maintainer's two identified gaps

From the V3 prompt:

> **Gap 1.** P6 (Discoverability) was scoped too narrowly in V2 — it
> covered "find tracker commands" but did not cover proactive guidance
> (the chat recognizing when a flat-file project would benefit from
> the tracker and surfacing that as a recommendation), nor
> refusal-respecting behavior (no nagging after the user declines), nor
> the relationship between in-chat help and external documentation.
>
> **Gap 2.** The help-command design was scoped only to tracker
> functionality, not to the entire pack — and the choice between
> augmenting each CLI's native `/help` versus introducing a namespaced
> `/pack-help` was not defended on best-practice grounds.

### J.2 V2's P6 design (what V2 had)

V2 §23 designed:
- §23.1: 5-minute path; static greeting at every flat-file-mode session.
- §23.2: `/help` integration via per-CLI HELP-FRAGMENT.md include.
- §23.3: `pack help` shell verb scoped to tracker.
- §23.4: Colloquial-form router for tracker verbs.
- §23.5: README discoverability mentions tracker.
- §23.6: In-error-message verb-naming (any error names next-step verb).
- §23.7: 5-minute SLA validated.

The V2 design is solid for finding tracker commands. It does **not**:
- Recognize when project state warrants opt-in.
- Refuse-respect (per-session vs persistent).
- Cover non-tracker verbs (init-project, agent-run, etc.) in help.
- Specify per-CLI documentation that supports the chosen `/help`
  augmentation pattern.
- Specify the maintenance cadence between in-chat help and external
  docs.

### J.3 V3's P6 design (what V3 adds)

V3 §27 + §28 add:

**For Gap 1 (proactive guidance + refusal):**

- §27.1 three-layer surface: Layer 3 is the *new* proactive
  recommendation; Layer 1 (static greeting) and Layer 2 (in-error
  verb-naming) carry forward V2.
- §27.2 hybrid static-dynamic balance: justified that hybrid wins
  over static-only or dynamic-only.
- §27.3 refusal-respecting design contract: per-session (memory only)
  vs persistent (file flag); state machine in §28.1.6.
- §27.4 help-vs-external-docs coexistence: explicit content split,
  source-of-truth at HELP-FRAGMENT.md, drift-prevention CI checks
  22 / 23, maintenance cadence.
- §28.1 (D-19) concrete signals + thresholds + state file + state
  machine + recommendation surface + integration tests.

**For Gap 2 (help scope + naming):**

- §28.2.1 verb manifest: every pack-shipped verb listed (tracker +
  init / migrate / validate / agent-run / etc.).
- §28.2.2 per-CLI documentation defense: Claude Code, Codex CLI,
  Gemini CLI verifiable citations; conclusion that path (b)
  namespaced is forced.
- §28.2.3 per-CLI implementation: Claude Code skill, Codex skill,
  Gemini command — all invoke the same `pack-help.sh`.
- §28.2.4 per-surface content split: pack-repo vs client-repo verb
  sets; shared tracker section.
- §28.2.5 trinity propagation: validate-pack Check 21 ensures parity.
- §28.2.6 self-discoverability test: 5-step UX walk demonstrates a
  user who has never seen v11 finds help in one session.
- D-20 (decision row).

### J.4 Mapping V2 elements to V3 (none lost; some revised)

| V2 §23 element | V3 status |
|---|---|
| §23.1 static greeting | reaffirmed in §27.1 Layer 1; sub-text "say 'set up the tracker'..." moved to the dynamic Layer 3 (where it only fires at threshold cross), so the static line is shorter and less recommendation-pushy |
| §23.2 `/help` integration | **revised** — V2 said "augment each CLI's `/help`"; V3 §28.2.2 documents that augmentation is not a documented best practice across all three CLIs and chooses path (b) instead |
| §23.3 `pack help` verb | reaffirmed; *scope expanded* in §28.2.1 from tracker-only to entire pack |
| §23.4 colloquial router | reaffirmed in §28.1.7 (recommendation router) and the existing V2 tracker-verb router |
| §23.5 README discoverability | reaffirmed; V3 §27.4.2 strengthens by naming HELP-FRAGMENT.md as canonical |
| §23.6 in-error verb-naming | reaffirmed in §27.1 Layer 2 |
| §23.7 5-minute SLA | reaffirmed in §28.2.6 5-step UX walk |

No V2 design is discarded. Some are reaffirmed verbatim; some are
extended; the `/help` augmentation choice is overruled by the new
per-CLI documentation evidence.

### J.5 Cross-check: does V3 satisfy both gaps fully?

| Gap | V3 satisfaction |
|---|---|
| Gap 1: proactive guidance | §28.1 (signals, thresholds, recommendation surface) |
| Gap 1: refusal-respecting | §28.1.6 (state machine), §28.1.7 (three-option prompt with persistent vs per-session distinction) |
| Gap 1: help-vs-external-docs coexistence | §27.4 (content split, source-of-truth, drift-prevention, cadence) |
| Gap 2: help scope expanded | §28.2.1 (full verb manifest) |
| Gap 2: naming defended on best-practice grounds | §28.2.2 (per-CLI documentation citations); §28.2.6 self-discoverability |

Both gaps fully addressed.

---

## Appendix K — Glossary of new terms introduced in V3

| Term | Definition | First introduced |
|---|---|---|
| **Active recommendation** | The full recommendation prompt (~150 tokens) shown when scale signals cross thresholds and the user hasn't dismissed | §27.1 Layer 3 |
| **Static greeting** | The ~30-token one-line hint at every session start (Layer 1) | §27.1 |
| **Per-session refusal ("not now")** | In-chat session memory dismissal; valid only for the current session | §27.3 |
| **Persistent refusal ("don't ask again")** | File-state flag in `.pack-tracker/recommendation-state.json` that silences recommendations indefinitely until the user re-enables | §27.3 |
| **`pack tracker enable-recommendations`** | The verb to clear persistent refusal | §28.1 |
| **Material change (25% growth)** | The threshold for re-firing a recommendation after a previous show; signals must be 25% higher than the snapshot at last-shown | §28.1.5 Guard 4 |
| **Recommendation state file** | `.pack-tracker/recommendation-state.json`; per-surface, machine-local, gitignored, schema in §28.1.4 | §28.1.4 |
| **HELP-FRAGMENT-TRACKER.md** | Shared tracker-verb section included by both pack-side and client-side help fragments | §28.2.4 |
| **Coexistence contract** | The maintenance discipline that keeps in-chat help and external docs in sync; documented in §27.4.4 | §27.4 |
| **Self-discoverability** | The property that a new user finds help without reading external docs; tested by §28.2.6 5-step UX walk | §28.2.6 |
| **Three-layer discoverability surface** | The combined Layer 1 (static), Layer 2 (in-error), Layer 3 (proactive) design | §27.1 |
| **Refusal-respecting state machine** | The diagram/table in §28.1.6 governing transitions between no-refusal / per-session-refused / persistent-refused states | §28.1.6 |

These terms are pack-internal vocabulary the maintainer and reviewers
will use; they are NOT user-facing. P5 (cognitive load floor) is
preserved: the user does not need to learn these terms. The user
sees only the prompts and verbs.

---

## End of architecture proposal V3

V3 is complete. The pack-reviewer audits next; the pack-planner
breaks the architecture (V1 + V2 deltas + V3 deltas) into BD-NNN
entries for v11 implementation. The maintainer's `DESIGN-BRIEF.md`
§8 (Decisions) table can be updated with D-1 through D-18 (per
V2's review acceptance, if not yet recorded), plus D-19 and D-20
(per V3's review acceptance).
