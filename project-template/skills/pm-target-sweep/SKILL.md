---
name: pm-target-sweep
description: Run a release-boundary target sweep — the read-only target-sweep CLI as a slash command. Enumerates the implementation-plan phases' Target claims and reports the overdue / re-encode / release-kind sweep sets. Read-only; never edits a phase file — dispositions are per-phase user decisions in the PM session.
allowed-tools: Bash
---

Run the read-only release-boundary target sweep and report its rows. This skill
is a thin wrapper over `scripts/target-sweep.sh`: it selects a verb, runs the
script, and relays the deterministic enumeration of the implementation-plan
tree's phase `Target:` claims. It never edits a phase file — there is no write
path and no apply mode.

## Verbs

Rows are `phase-N <target-value>`, phase-number ascending. The sweep filters
(overdue / re-encode-set / kind-set) key on token POSITION in the tree's own
target-enum, so they follow the project's declared release vocabulary rather
than hardcoded names.

| Verb | What it reports |
|---|---|
| `enumerate` | Every phase-epic carrying `Target:`, all statuses; the value is emitted verbatim. |
| `overdue` | Non-done, non-superseded phases whose target is the first enum token (the overdue window). |
| `re-encode-set` | Non-done, non-superseded phases whose target is the second enum token (the re-encode input). |
| `kind-set` | Non-done, non-superseded phases whose target is an interior enum token (the release-kind input). |

## Step 1 — Run the verb

Run the verb the user named (default `enumerate` when none is given):

```bash
bash scripts/target-sweep.sh enumerate
bash scripts/target-sweep.sh overdue
bash scripts/target-sweep.sh re-encode-set
bash scripts/target-sweep.sh kind-set
```

## Step 2 — Report

Relay the script's stdout rows as-is (including an empty-set line such as
`(no overdue targets)`). On a usage error, a missing implementation-plan tree,
or an unusable target-enum vocabulary the script exits 2 with a `target-sweep:`
message on stderr — report it verbatim; the tool makes no phase-file edits.
