# ARCHITECTURE-V3.1-DELTA — three §7.2 resolutions

## §0 Status

- Date: 2026-05-04
- Scope: resolves §7.2 items 10, 11, 12 from ARCHITECTURE-REVIEW.md
- Author: pack-architect (focused re-spawn)
- All other V1/V2/V3 decisions reaffirmed unchanged. No new OQs. D-1..D-20 untouched. Cross-CLI parity floor and trinity rule unchanged.

---

## §1 Decision: §3.4 Codex /help discoverability — picked M2

**Pick: M2 (textually accept the gap as out-of-scope).**

**Rationale (brief).** The brief's P6 language is "without reading external documentation," but the same priority §3.4 explicitly authorizes per-CLI mechanism asymmetry: "A help-command path (`/help`, `pack help`, or namespaced `/pack-help` — the exact mechanism is OQ-20)." The brief also lists `pack help` as a valid mechanism alongside `/help`. M1 (forced static greeting at every Codex session start) would require an in-process hook the Codex CLI does not expose: Codex skills fire only when invoked by name (`/skills` listing → user picks → run), and there is no documented session-startup hook in Codex CLI's slash-command surface (compiled-in enum per EXTERNAL-RESEARCH §12.2 and `codex-rs/tui/src/slash_command.rs` cited in V3 Appendix B.2). Inventing one would mean either (a) wrapping the user's `codex` invocation in a shell prelude that prints a banner, which the pack does not control on the user's machine, or (b) shipping a "first thing in this repo, run `/pack-startup`" expectation — which V3 already does in `pack-startup` / `pm-startup` Step 1, and which V3 §28.2.6 already documents.

The discoverability path on Codex is therefore three honest layers, all native to Codex's documented surfaces:

1. The shell verb `pack help` (LCD floor; works in any terminal, including the one Codex runs in).
2. The Codex `/skills` listing (Codex's documented mechanism for surfacing user-installed extensions; the `pack-help` skill appears there).
3. External docs (QUICKSTART.md, OPTIONAL-FEATURES.md) cover Codex specifically.

This is consistent with the brief §3.4 last sub-bullet: "Help functionality coexists with external documentation … it does not replace them." The brief does not require parity of *mechanism* across CLIs; it requires parity of *outcome* (the user finds verbs). On Codex, the `pack help` shell verb plus `/skills` discovery achieves that outcome at the LCD floor. Forcing a per-session greeting on a CLI that does not expose a startup hook would be inventing a mechanism the CLI does not document, violating the §0.6 "no per-CLI hacks below the documented surface" floor.

**Textual replacement for V3 §28.2.6 (last paragraph "For Codex CLI specifically..." through end of "Negative case" block):**

> **Codex CLI discoverability (accepted asymmetry below the slash surface).**
>
> Codex CLI's slash-command surface is a compiled-in Rust enum
> (EXTERNAL-RESEARCH §12.2; `codex-rs/tui/src/slash_command.rs`); it
> exposes neither a built-in `/help` nor a documented mechanism for
> startup-banner injection. The pack therefore ships three documented
> Codex-native paths to the same help content, in priority order:
>
> 1. **Shell verb `pack help`** (LCD floor; available in the same terminal
>    Codex runs in). This is the first-class path for Codex users.
> 2. **`/skills` listing → `pack-help` skill** (Codex's documented surface
>    for user-installed extensions). The `pack-help` skill is installed
>    project-level at `.codex/skills/pack-help/SKILL.md` (ships with
>    `init-project.sh`). A user who runs `/skills` sees `pack-help` in
>    the listing; selecting it runs `pack-help.sh`.
> 3. **`pack-startup` / `pm-startup` static greeting** (Layer 1 from §27.1):
>    when the user invokes the startup skill (which the pack documents
>    as the recommended first action in any pack-managed repo, in both
>    QUICKSTART.md and the trinity files), the greeting prints "run
>    `pack help` for the full verb list."
>
> **What this means for the "no external docs" success criterion.** The
> brief §3.4 P6 first bullet asks for in-chat discovery without external
> docs. On Claude Code and Gemini CLI, native `/help` autocomplete shows
> `/pack-help` (Claude: `/help` is built-in and lists installed skills as
> slash commands; Gemini: custom commands' `description` field appears
> in `/help`, per `gemini-cli/docs/cli/custom-commands.md`). On Codex,
> the equivalent native discovery is `/skills` — Codex's documented
> listing surface for user extensions — which is one extra step (3 keys:
> `/`, `s`, Tab) but is **not** "external documentation" in the brief's
> sense; it is a Codex-native chat surface.
>
> **Accepted gap.** A Codex user who:
>
> - has not run `pack-startup` / `pm-startup` (no static greeting), AND
> - does not know to type `/skills` (Codex's listing surface), AND
> - does not type `pack help` in shell, AND
> - has not yet hit an error that names the next-step verb (Layer 2)
>
> will need to read QUICKSTART.md or OPTIONAL-FEATURES.md to discover
> the verb. This is acceptable scope for v11 because:
>
> - The brief explicitly authorizes `pack help` as a valid mechanism
>   (§3.4 first bullet, parenthetical: "the exact mechanism is OQ-20").
> - The brief explicitly authorizes coexistence with external docs (§3.4
>   last sub-bullet: "Help functionality coexists with external
>   documentation … it does not replace them").
> - The cross-CLI parity floor is at the LCD shell, not at the
>   slash-command surface; per-CLI mechanism above the floor is by
>   design (`DESIGN-BRIEF.md` §3.1: "All three CLIs work identically at
>   the **lowest common denominator**. Per-CLI tuning is allowed where
>   one CLI offers more capability").
> - Inventing a forced session-start banner on Codex would require a
>   mechanism Codex does not document; the pack does not invent
>   below-the-surface hooks (§0.6 stability floor).
>
> A future Codex CLI release that introduces documented `/help`
> augmentation or a session-startup hook would let v11.x lift this
> asymmetry; until then, the three documented paths above plus
> external docs satisfy the brief.
>
> **(There is no "negative case" subsection separate from this; the
> Codex path is the negative case, and it is now positively designed
> with three layers and one acknowledged residual gap covered by
> external docs.)**

---

## §2 Decision: §3.5 HELP-FRAGMENT cross-tree layout — picked L1

**Pick: L1 (co-locate `HELP-FRAGMENT-TRACKER.md` at pack root; `init-project.sh` copies it into `project-template/docs/pack/` at install time).**

**Rationale (brief).** The user's MEMORY rule "Separate pack ops from pack product" is a first-order constraint. `HELP-FRAGMENT-TRACKER.md` is consumed at runtime by **both** Pack Chat (operating on the pack repo) and PM Chat (operating on a client project). The reviewer is correct that V3's current layout makes Pack Chat read a file inside `project-template/`, which is pack *product* (the template shipped to clients), to render its own *operational* help. That couples ops to product and would force Pack Chat tests to depend on template content — an inversion of the dependency direction the pack repo otherwise enforces (e.g., `validate-pack.py` Check 8 reserves the `x-` prefix only for product files; ops files have no reciprocal dependency on product files).

L1 mirrors the existing pattern used for many pack files: the canonical authored copy lives at pack root (or a pack-ops directory); `init-project.sh` copies it into `project-template/docs/pack/` (or into a fresh client repo) at install time. The trinity rule is unchanged because `HELP-FRAGMENT-TRACKER.md` is a single file with a single canonical source — no per-CLI replication.

**Pack-Chat lookup path:** Pack Chat resolves `HELP-FRAGMENT-TRACKER.md` by bare-name lookup at pack root via the trinity `## Document locations` table (the same path-resolver mechanism documented in `INTERNAL-INVENTORY.md` §5.1). The pack-root trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) gains one row in the Document locations table: `HELP-FRAGMENT-TRACKER.md → ./HELP-FRAGMENT-TRACKER.md` (pack-root canonical).

**PM-Chat lookup path:** PM Chat resolves the same bare name via the project-template trinity's Document locations table, which points to the in-project copy at `docs/pack/HELP-FRAGMENT-TRACKER.md`. The in-project copy is installed by `init-project.sh` from the pack-root canonical at project initialization, and refreshed by `init-project.sh --update` (or the v10→v11 / v11.x→v11.y migrator) when the pack ships a new version. Each client project owns its installed copy after init; this matches every other template file's lifecycle.

**Drift control:** A new `validate-pack.py` Check (numbered by the planner; conceptually Check 24 sitting alongside the §28.2.5 Checks 21/22/23) verifies that `HELP-FRAGMENT-TRACKER.md` at pack root is byte-identical to `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` at every CI run, so the canonical-and-shipped pair never silently drifts during pack development.

**Textual update for V3 §I.1 and §I.4 (and the file-layout block in §28.2.4):**

In **V3 §I.1 (New files V3 introduces)**, replace the line:

> `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md   (extracted shared tracker section)`

with:

> `HELP-FRAGMENT-TRACKER.md                              (pack root; canonical shared tracker section)`
> `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md   (init-project.sh installs from pack-root canonical; byte-identical mirror)`

In **V3 §28.2.4 (file layout block)**, replace:

```
project-template/docs/pack/
├── HELP-FRAGMENT.md                 (client-surface verb list)
├── HELP-FRAGMENT-TRACKER.md         (shared tracker verbs)
└── ...

(pack root)
HELP-FRAGMENT-PACK.md                (pack-repo verb list)
```

with:

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

And replace the paragraph beginning "`HELP-FRAGMENT-PACK.md` and `project-template/docs/pack/HELP-FRAGMENT.md` each include `HELP-FRAGMENT-TRACKER.md`..." with:

> `HELP-FRAGMENT-PACK.md` includes `HELP-FRAGMENT-TRACKER.md` from
> pack root (sibling-file include via `pack-help.sh`'s text-include
> resolver). `project-template/docs/pack/HELP-FRAGMENT.md` includes
> `HELP-FRAGMENT-TRACKER.md` from `project-template/docs/pack/`
> (sibling-file include in the client tree). Each surface includes
> the copy that lives in its own tree; neither surface reads across
> the pack-ops/pack-product boundary at runtime. The two
> `HELP-FRAGMENT-TRACKER.md` copies are kept byte-identical by
> `validate-pack.py` (new identity check, planner-numbered alongside
> Checks 21/22/23) and by `init-project.sh` (which overwrites the
> client-side copy from the pack-root canonical on every install or
> `--update` run).

In **V3 §I.4 (Trinity propagation matrix)**, append a row:

| Surface | Trinity files | Per-CLI command files | Skill files | Shared fragments |
|---|---|---|---|---|
| Pack repo | (existing) | (existing) | (existing) | `HELP-FRAGMENT-TRACKER.md` (root, canonical) |
| Client repo | (existing) | (existing) | (existing) | `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (mirror) |

And add one bullet under the propagation list:

> - Shared fragment `HELP-FRAGMENT-TRACKER.md` (pack-root canonical;
>   client-tree mirror); identity enforced by `validate-pack.py`. The
>   trinity rule does not apply file-wise (it is a single file, not a
>   per-CLI triplet); it applies content-wise via the
>   pack-root-canonical → client-mirror copy contract.

---

## §3 Decision: §4.2 BACKLOG format drift in reverse migration — picked A2

**Pick: A2 (extend V1 §6.6 sidecar coverage to include `template_version` and any v11.x-introduced fields not representable in v10 grammar).**

**Rationale (brief).** Two reasons A2 is preferable to A1 (a new R18 rule):

1. **A1 just describes the problem; A2 solves it via a mechanism that already exists.** V1 §6.6 already designed the sidecar pattern for exactly this class of concern: data the tracker has that the v10 flat-file grammar cannot capture (reactions, attachments, comment threads, etc.). v11.x-introduced *fields* that v10 grammar lacks are the same shape of problem — tracker has them, v10 grammar does not — and the sidecar is the existing answer. Adding a new rule R18 saying "this exists" without leveraging the sidecar would force a future planner to invent a second mechanism.

2. **A2 directly satisfies the brief's `template_version` design requirement.** `DESIGN-BRIEF.md` §3.1 last bullet mandates that "every tracker-managed entry carries a `template_version` field … entries on old templates can be deterministically translated to current templates." OQ-18 designs where `template_version` lives in the entry (V3 reaffirms: HTML comment marker, parallel to `<!-- pack-id: TD-NNN -->`). The reverse migration must persist `template_version` somewhere on the v10 side so a re-forward migration can recover the original template generation. The sidecar is the natural home: it already persists tracker-only data round-trip-safely (V1 §6.7), and it is keyed by entry, which makes per-entry `template_version` recovery trivial.

A1 would still need to point at a mechanism; A2 *is* the mechanism. Choosing A2 also keeps R-numbers stable (no new risk in §17), which the planner prefers for stable BD-NNN cross-references.

**Textual addition — extension to V1 §6.6:**

Append the following subsection after V1 §6.6's existing "The user is told at reverse time…" paragraph (and before V1 §6.7):

> **§6.6.1 Template-version drift across pack minor versions.**
>
> Per `DESIGN-BRIEF.md` §3.1, every tracker-managed entry carries a
> `template_version` field. Between pack v11.0 and a later v11.x, the
> entry templates may add fields (per V2 §19 template-upgrade flow). A
> user who opted into the tracker on v11.0, upgraded to v11.x, and
> later runs reverse migration would otherwise lose any v11.x-only
> field — because the v10 BACKLOG grammar cannot represent fields the
> v10 grammar predates.
>
> The reverse migration captures this drift in the sidecar:
>
> `.pack-tracker/reverse.sidecar.YYYY-MM-DD.md` gains, per entry:
>
> - `template_version`: the value of the entry's `template_version`
>   field at reverse time (e.g., `bd-v11.2.0`).
> - `extra_fields`: the set of fields present on the tracker entry
>   but not representable in v10 grammar — emitted as a key/value
>   block under each entry's sidecar section. Field schema is
>   documented in `maintenance-docs/v11-research/templates-archive/
>   <template_version>/SCHEMA.md` (the existing template-archive
>   directory specified in `DESIGN-BRIEF.md` §3.4 P2).
> - `template_archive_path`: the relative path to the template
>   archive used to produce this entry, so a re-forward migration
>   can re-hydrate the v11.x-only fields deterministically.
>
> **Round-trip behavior (V1 §6.7 extended).** Forward → reverse →
> forward is a no-op for v10-grammar fields (existing guarantee).
> For v11.x-introduced fields:
>
> - Reverse: the field is captured in the sidecar's `extra_fields`
>   block.
> - Re-forward: the migrator reads the sidecar, sees the entry's
>   `template_version` and `extra_fields`, and re-applies them to
>   the new tracker issue. The re-forward result is byte-equivalent
>   on tracker side to the pre-reverse state.
> - If the user manually deletes the sidecar between reverse and
>   re-forward, the re-forward emits a warning per affected entry:
>   "TD-NNN was created on `bd-v11.2.0` template; sidecar missing;
>   v11.x-only fields will be defaulted. Run `pack tracker
>   doctor` after re-forward to review." The migrator does not
>   silently lose data; it surfaces the loss.
>
> **Documentation surfacing.** The user is told at reverse time, in
> addition to the existing sidecar message: "Sidecar `<path>` also
> contains template-version metadata. Keep it if you intend to
> re-enable the tracker later; without it, re-enable will default
> any pack-version-specific fields and warn for each affected
> entry."
>
> **Test coverage.** `scripts/tracker-migrate.sh roundtrip-test`
> (V1 §6.7) is extended: the test fixture now includes one entry
> on each of `bd-v11.0`, `bd-v11.1`, `bd-v11.2` template versions;
> forward → reverse → forward must produce zero diff on the tracker
> side. The test is part of CI per V3 §I.1 (`scripts/tests/`).

This change is purely additive to V1; it does not modify D-8 or any existing decision. R-numbering in V3 §17 is unchanged (no new R18). The brief's mandatory-reverse contract is now explicit about template-version drift and round-trip guarantees.

---

## §4 Cross-impact check

- **D-1..D-20 reopened?** No.
  - M2 reaffirms D-20 (per-CLI mechanism above the LCD floor; LCD floor = `pack help`); the §28.2.6 textual revision documents the existing Codex path more honestly without changing the design.
  - L1 reaffirms D-19 / D-20 file inventory; it relocates one file (`HELP-FRAGMENT-TRACKER.md`) and adds an install-time copy step that mirrors existing pack patterns. No decision identity changes.
  - A2 reaffirms D-8 (reverse migration via sidecar); it extends the sidecar's per-entry payload, which D-8 already authorizes ("Tracker-only data … → sidecar file").
- **Trinity rule unaffected?**
  - M2 adds no per-CLI files; the existing trinity (CLAUDE/AGENTS/GEMINI at pack root and project-template; per-CLI `pack-help` skills already trinity-replicated per V3 §I.4) is unchanged.
  - L1 adds one file at pack root (`HELP-FRAGMENT-TRACKER.md`) which is a single canonical document, not a per-CLI triplet; the trinity rule does not apply to it. The trinity rule continues to apply to CLAUDE/AGENTS/GEMINI (which gain identical Document-locations rows for the new pack-root file), to per-CLI `pack-help` skill files, and to per-CLI `pack-startup` / `pm-startup` skill files — all unchanged.
  - A2 modifies the migration script behavior and the sidecar format; no trinity files are touched.
- **Cross-CLI parity floor unaffected?** Yes, parity floor is unchanged.
  - M2 explicitly reaffirms the LCD floor (`pack help` shell verb) and documents that per-CLI mechanism above the floor (`/help` augmentation on Claude/Gemini, `/skills` listing on Codex) is by-design asymmetry permitted by the brief.
  - L1 changes only file locations and the install-time copy contract; it does not change what each CLI can or cannot do.
  - A2 is migration-script behavior; CLI-agnostic by construction.
- **No new OQs introduced.** A2 leverages OQ-18's already-designed `template_version` field; M2 closes the §3.4 acceptance question without opening anything; L1 closes the §3.5 layout question without opening anything.

---

## Recommendation summary

M2 (accept the Codex `/help` gap as documented, with the §28.2.6 negative case rewritten as a positive three-layer Codex-native discoverability design plus an explicit residual scope acknowledgement); L1 (relocate `HELP-FRAGMENT-TRACKER.md` to pack root as the canonical copy, mirrored into `project-template/docs/pack/` by `init-project.sh` at install time, with byte-identity enforced by `validate-pack.py`); A2 (extend V1 §6.6 sidecar to capture `template_version`, `extra_fields`, and `template_archive_path` per entry, with round-trip guarantee in §6.7 covering v11.x-introduced fields).
