---
name: pm-groupings
description: Query the project's phase groupings — the read-only groupings CLI as a slash command. Lists real groupings with derived status/target, resolves phase-to-grouping membership, derives inter-grouping dependency edges and execution order, and finds groupings sharing member phases. Read-only; never edits a grouping or phase file.
allowed-tools: Bash
---

Run the read-only groupings query CLI and report its rows. This skill is a thin
wrapper over `scripts/groupings.sh`: it selects a verb, runs the script, and
relays the deterministic output. It never writes a grouping or phase file —
there is no apply path.

## Verbs

| Verb | What it reports |
|---|---|
| `list` | Every real grouping, ID ascending: derived status, done/all counts, flags, target, title, members. |
| `list-membership <ref>` | A `phase-N` ref lists the grouping IDs that contain that phase; a `GRP-NNN` ref prints the grouping's detail header + its member phases. |
| `deps` | Derived inter-grouping edges (`GRP-A -> GRP-B`), computed at query time from member-phase dependency fields. |
| `order` | Derived grouping execution order; mutually-dependent groupings print as one interleaved cluster row. |
| `shared-with <GRP-NNN>` | Real groupings that share at least one member phase with the argument. |

## Step 1 — Run the verb

Run the verb the user named (default `list` when none is given), passing any
reference argument through verbatim:

```bash
bash scripts/groupings.sh list
bash scripts/groupings.sh list-membership GRP-001
bash scripts/groupings.sh deps
bash scripts/groupings.sh order
bash scripts/groupings.sh shared-with GRP-001
```

Two optional forms, used only when the user asks for them: add `-q` for the
machine rollup rows, or run `deps --deferral` for the deferral/supersession
cascade view.

## Step 2 — Report

Relay the script's stdout rows as-is. On a typed error (`groupings: ERROR(<code>):
<msg>` on stderr, exit 1) or a usage error (exit 2), report the message verbatim
— do not retry with a mutated argument.
