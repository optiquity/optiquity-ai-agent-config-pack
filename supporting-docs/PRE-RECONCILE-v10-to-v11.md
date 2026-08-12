# Pre-reconciling before a v10 → v11 migration

This guide is for the **AI agent that drives your migration** (your project's
PM chat). Run it BEFORE `scripts/migrate-v10-to-v11.sh`. Its job: prepare the
files that BOTH you and the pack changed so the migrator merges them **with no
pause** for the dominant conflict class (the trinity), keeping your
customizations.

You do not need this guide to migrate — the migrator is safe without it (an
unprepared conflict pauses cleanly and you reconcile after). Use it when you
want the trinity to migrate hands-free.

---

## 1. What this is / when to use it

When a file was changed by BOTH you and the pack between v10 and v11, the
migrator cannot always auto-merge it. What it can do depends on the file's
**class**:

| Class | Pause avoidable by pre-reconciling? | Where this guide helps |
|---|---|---|
| **Trinity** (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) | **YES** — this is the whole point | §5 (the centerpiece) |
| **Structured configs** (JSON / TOML) | Mostly auto-merges already | §6 (short) |
| **Generic docs + pack scripts + pack agents** | **NO** (structural — see §7) | §7 routes you to the honest fallbacks |

The trinity is the dominant conflict class. Pre-reconciling it correctly is
the difference between a hands-free migration and a paused one. The rest of
this guide makes that recipe exact — and honest about what it cannot do.

---

## 2. Preflight (blocking)

The whole recipe reads the **v10 baseline** of each pack file straight from the
pack clone's `v10` git tag. If your pack clone has no `v10` tag (a shallow or
tarball clone), every step below fails. Check it first:

```sh
# $PACK = your on-disk pack clone (the same one the migrator uses)
git -C "$PACK" show v10:project-template/CLAUDE.md >/dev/null \
  && echo "v10 baseline OK" \
  || echo "MISSING v10 tag — run the remedy below"
```

Remedy if missing:

```sh
git -C "$PACK" fetch --tags
```

Do not proceed until the check prints `v10 baseline OK`.

---

## 3. The conflict-prone files + per-class reachability

These are the pack-shipped files the migrator merges. "Pre-fixable" = can you
edit your copy BEFORE migrating so the migrator does **not** pause on it while
still keeping your changes.

| Your project path | Class | Merge behavior | Pre-fixable to no-pause? |
|---|---|---|---|
| `CLAUDE.md` | trinity | marker-aware graft | **YES** (delicate — §5) |
| `AGENTS.md` | trinity | marker-aware graft | **YES** (delicate — §5) |
| `GEMINI.md` | trinity | marker-aware graft | **YES** (delicate — §5) |
| `.claude/settings.json` | JSON | key-merge | **Mostly auto** (§6) |
| `.mcp.json` | JSON | key-merge | Mostly auto (§6) |
| `.agents/mcp_config.json` | JSON | key-merge | Mostly auto (§6) |
| `.codex/config.toml` | TOML | key-merge | Mostly auto (§6) |
| `.codex/config.toml.example` | TOML | key-merge | Mostly auto (§6) |
| `.codex/requirements.toml` | TOML | key-merge | Mostly auto (§6) |
| `docs/pack/PM-CHAT.md` | generic text | line 3-way | **NO** (§7) |
| `docs/pack/PLATFORM-SKILLS.md` | generic text | line 3-way | **NO** (§7) |
| `docs/pack/PACK-FEEDBACK.md` | generic text | line 3-way | **NO** (§7) |
| `docs/pack/PROMPT-TEMPLATES.md` | generic text | line 3-way | **NO** (§7) |
| a pack-shipped `scripts/*` you edited | pack-script | line 3-way | **NO** (§7) |
| a pack-shipped `.claude/agents/*` or `.codex/agents/*` you edited | pack-agent | line 3-way | **NO** (§7) |
| your own `x-…` agents / your own added scripts | project-owned | left untouched | **N/A** (never pauses) |

**Authoritative source (verify this table against live code):** the map above
is derived from the migrator's own transform manifest — the functions
`migrator_manifest` and `migrator_directory_sweeps` in
`scripts/migrate-v10-to-v11.sh`. If a future pack version changes the file set,
those two functions are the source of truth; re-read them if in doubt.

---

## 4. The deterministic "who added what" recipe

You never need `git blame` on your own history. For any conflict-prone file the
migrator's own baseline is the v10-tagged pack template, and your additions are
just the diff from it:

```sh
# BASE = the pack's v10 baseline for this file
git -C "$PACK" show v10:project-template/CLAUDE.md > /tmp/CLAUDE.base.md

# Your additions = BASE vs your live file
diff /tmp/CLAUDE.base.md CLAUDE.md
```

The project→pack path map (used to fetch each BASE): your project path maps to
`project-template/<same relative path>` in the pack — e.g. your `CLAUDE.md` →
`project-template/CLAUDE.md`; your `docs/pack/PM-CHAT.md` →
`project-template/docs/pack/PM-CHAT.md`. **Exception — the two MCP configs are
`.example`-sourced:** your `.mcp.json` → `project-template/.mcp.json.example` and
your `.agents/mcp_config.json` → `project-template/.agents/mcp_config.json.example`
(fetch those `.example` BASEs; the suffix-less pack paths do not exist, so
`git show v10:project-template/.mcp.json` errors). Every other file (trinity, the
generic docs, the `.codex/*` configs) maps same-relative-path. This diff is
exactly the BASE→OURS panel the migrator itself computes.

---

## 5. Trinity prep recipe (the centerpiece)

The trinity engine is content-aware: it can **adopt the new v11 pack body AND
preserve your customizations** — but only when your file satisfies a strict,
byte-exact, rename-aware contract. Miss any part and it pauses instead. Follow
the four steps in order, then verify with `--dry-run` (§8).

The engine records a clean **`merged-with-customization`** disposition (no
pause, no sidecar) only when ALL of the following hold.

### (a) Capture your additions

Per §4, get `BASE = git -C "$PACK" show v10:project-template/<file>` and run
`diff BASE <file>`. Everything the diff shows as *added by you* is what must
end up inside a marker pair (step d). Everything else must match v10 exactly.

### (b) Reconcile the v10 → v11 pack-section renames

Any `## ` heading in your file that is **absent from the v11 template** pauses
the graft ("this section is absent from the new canonical — reconcile"). The
v11 template lives at `$PACK/project-template/<file>`. For every `## ` heading
in your copy that the v11 template does not have:

- **You did NOT customize it →** delete the whole section. The graft adopts
  the v11 canonical (possibly renamed) for you.
- **You DID customize it and want to keep your version →** keep it as a **Shape
  B override**: wrap the entire section (heading line + body) in a marker pair
  and name the v11 section it replaces on the BEGIN line:

  ```md
  <!-- BEGIN project-owned renamed-from "New v11 Heading Text" -->
  ## Your kept heading
  …your customized body…
  <!-- END project-owned -->
  ```

  The `renamed-from` name must match a heading that exists in the v11 template
  (or the v10 baseline), or the graft flags a likely typo.

A quick way to list the headings you must reconcile:

```sh
comm -23 \
  <(grep '^## ' CLAUDE.md | sort -u) \
  <(grep '^## ' "$PACK/project-template/CLAUDE.md" | sort -u)
```

### (c) Keep every out-of-marker pack body byte-identical to v10

For every pack section you keep un-wrapped, its body **outside the markers**
must be byte-for-byte your v10 baseline (including the preamble — the text above
the first `## ` heading). The engine strips the marker blocks and
compares what remains against v10; **any** stray out-of-marker byte — including
a single blank line — flips a clean graft to a pause. Do not leave edits sitting
in a pack section's body; move them inside a marker pair (step d).

### (d) Fold your additions into markers

Two shapes:

- **Shape A** — additions *inside* an existing pack section. Wrap only your
  lines; the `## ` heading stays OUTSIDE the pair. The `## Project addenda`
  section is the canonical home for free-standing additions:

  ```md
  ## Project addenda

  <!-- Project addenda go here… (pack comment, keep as-is) -->
  <!-- BEGIN project-owned -->
  - Your custom rule here.
  <!-- END project-owned -->
  ```

  Note there is **no blank line** between the pack comment and
  `<!-- BEGIN project-owned -->`: adding one is exactly the stray byte step (c)
  warns about.

- **Shape B** — a whole new project-owned section. The pair wraps the heading
  line and the entire body:

  ```md
  <!-- BEGIN project-owned -->
  ## My project conventions
  - Your rules…
  <!-- END project-owned -->
  ```

Pitfalls that route you back to a sidecar (the graft fails loud on each):

- an orphan marker (a BEGIN with no END, or vice versa);
- nested marker pairs;
- a `## `/`### ` heading **inside** a Shape A region (that makes it Shape B —
  wrap the heading too, or move the heading out);
- a leftover `[CONDITIONAL]` prefix on a kept heading (reconcile it per step b);
- a marker pair sitting in the preamble above the first heading.

### (e) Worked micro-example

Start from your v10 `CLAUDE.md` with one custom rule. Reconcile renames (step
b): delete the uncustomized `## [CONDITIONAL] …` sections and the renamed
`## Project memory` section (the graft adopts their v11 canonicals). Leave every
remaining pack body untouched (step c). Fold your one rule into a Shape A pair
under `## Project addenda` with no stray blank line (step d). Result:
`--dry-run` predicts `merged-with-customization` for `CLAUDE.md` — the v11
skeleton is adopted and your rule survives inside the marker pair. (This exact
shape is exercised by `scripts/tests/test-migrate-v10-to-v11-pre-reconcile.sh`,
case P1.)

---

## 6. Structured configs (short)

`.claude/settings.json`, `.mcp.json`, `.agents/mcp_config.json`,
`.codex/config.toml(.example)`, `.codex/requirements.toml` key-merge
automatically. They only pause on a genuine **same-key / different-value**
conflict. If `--dry-run` predicts a config pause, open the file and set the one
conflicting key to the value you want to keep; the rest merges on its own.
Low-volume — usually nothing to do.

---

## 7. Generic docs + pack scripts / pack agents (the honest part)

For the generic text class (`docs/pack/PM-CHAT.md`, `PLATFORM-SKILLS.md`,
`PACK-FEEDBACK.md`, `PROMPT-TEMPLATES.md`) and for any pack-shipped `scripts/*`
or pack-shipped agent (`.claude/agents/*`, `.codex/agents/*`) that **you
edited**, pre-editing **cannot** avoid the pause. The merge for these classes is
line-based and compares only BASE↔yours and BASE↔pack — never yours↔pack — so
no edit to your copy short of reverting it to the v10 baseline (which discards
your change) moves it out of "needs reconciliation". This is structural, not a
bug, and not something this guide can pre-fix to a merged, pause-free result.

Pick one per file:

| Choice | What you do | Result |
|---|---|---|
| Accept pack | discard your edit, take the v11 version | adopts v11 |
| Keep yours | restore your copy over the v11 version | keeps yours |
| Hand-merge | edit the sidecar, mark it `.resolved`, then `--resume` | your merged content |
| Interactive | run the migrator with `--interactive` and choose per file at the pause | resolved in one pass |

None of these needs pre-work — decide at (or after) the pause. The point of §5
is that the trinity does **not** land in this table.

---

## 8. The safety flow (mandatory)

Because the trinity recipe (§5) is byte-fragile, always verify with a dry-run
before touching the tree:

1. **Prepare** — apply §5 (and §6 if a config pause is predicted).
2. **`--dry-run`** — `PACK=<pack> bash scripts/migrate-v10-to-v11.sh --dry-run
   <target>`. The dry-run truthfully predicts the exact set of files that would
   pause. Confirm **zero trinity files** appear in the predicted pause set (only
   the expected generic tail from §7, if any, remains). If a trinity file still
   shows up, your fold is off — re-check step (b)/(c)/(d) and re-run the
   dry-run. This is the gate that catches a bad fold **before** anything is
   written.
3. **`--apply`** — once the dry-run is clean for the trinity, run the migration.
   The prepared trinity migrates with no pause and your customizations intact.

The dry-run is free and read-only — run it as many times as it takes to reach a
clean trinity prediction.

---

## 9. See also

- `MIGRATION-v10-to-v11.md` — the full v10 → v11 migration narrative (this
  guide is its optional "Step 0"). Return there for the actual migration steps,
  sidecar conventions, and rollback.
