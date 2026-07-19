---
name: dashboard-render
description: Render a self-contained single-page HTML dashboard by running the committed build/verify script that produces the deterministic state, injected into a spec-fingerprinted HTML shell. The build selects each record's full-or-minimal tier deterministically, anchors every full-tier body to its own live backlog source, floors the plans and section sets, and stamps a dual {spec-sha, structure-sha} provenance fingerprint; the candidate render is not valid until the script's verify mode passes fail-closed. The shell is reused across renders and regenerated only on a spec or format-contract change.
allowed-tools: Read, Bash, Write, Grep
---

Render one self-contained HTML dashboard page for the pack frontier. The
load-bearing state is NOT hand-authored: it is produced by the ONE committed,
coder-authored build script, `scripts/dashboard-build.py`, which selects the
record set deterministically and floors it with its own fail-closed `verify`
oracle. This skill drives that committed script and authors only the
presentation shell the script injects state into. It reads two inputs fresh on
every render — the build-spec doc the caller names (for the pack frontier
dashboard, `pack-ops/DASHBOARD-SPEC-PACK.md`) and live repo state — and emits
one HTML page.

## Step 1 — Reuse or regenerate the fingerprinted shell

The shell is the state-independent HTML — skeleton, design system, render JS, and
hash router — persisted as a git-tracked file the caller names; for the pack
frontier dashboard, `pack-ops/dashboard-approvals/dashboard-shell.html`. It
carries a provenance comment stamping BOTH fingerprints and one inert state
element the build injects into:

```html
<!-- pack-dashboard shell · spec: pack-ops/DASHBOARD-SPEC-PACK.md · spec-sha: <40-hex> · structure-sha: <64-hex> -->
<script type="application/json" id="state">__PACK_DASHBOARD_STATE__</script>
```

- `spec-sha` = `git hash-object` of the build-spec doc (the LOGIC contract).
  `structure-sha` = the FORMAT-contract fold (the two per-entry `_rules.md`
  object ids, the session-state schema token, and the session-state
  required-keys value). The `{spec-sha, structure-sha}` PAIR is the
  reuse-or-regenerate key.
- Read the shell's embedded pair. If the shell is absent, or either fingerprint
  differs from the live value: **regenerate**. Otherwise: **reuse**.
- **Regenerate** — author the state-independent shell per the spec (head/body
  skeleton, design system, render functions, and hash router, all reading only
  from the injected state), embed the `__PACK_DASHBOARD_STATE__` sentinel at the
  state element, stamp the provenance comment with the live `{spec-sha,
  structure-sha}` pair, and Write it to the shell path. A spec or format-contract
  change flips a fingerprint and regenerates the shell; the committed build
  script is edited in the same reviewed change (script and shell stay paired on
  the same pair).
- **Reuse** — Read the persisted shell as-is; do not rewrite it (a reuse render
  leaves the shell file byte-unchanged).

Make the shell's router boot defensive: it MUST treat the
`__PACK_DASHBOARD_STATE__` sentinel — or any `JSON.parse` failure on the state
element — as EMPTY state and render an idle page, so the persisted shell opens
cleanly on its own.

## Step 2 — Build the deterministic state

Run the committed build:

```bash
python3 scripts/dashboard-build.py build
```

It reads all data fresh (the git-tracked backlog, each entry's Status /
Resolved-date / body, session-state, the rules / changelog / metrics / help
sources, and live git history), selects the deterministic full set, and emits
every record with a `tier:"full"|"minimal"` field. Each full-tier record carries
a source-anchored body drawn from that entry's own live Description/Context; the
committed-history plans floor and the read-fresh section floors are populated the
same way. The build injects this state into the fingerprint-matching shell (or a
minimal fail-safe shell when none matches) and writes
`pack-ops/dashboard-approvals/dashboard.html`. Selection is a deterministic
recompute every render — never a reuse of a prior render's payload and never a
hand-authored count. The serialized state escapes only `<` (the `</script`
breakout) for the JSON-in-`<script>` path.

## Step 3 — Verify (the fail-closed gate)

The candidate render is NOT valid until the script's oracle passes:

```bash
python3 scripts/dashboard-build.py verify
```

`verify` re-derives the full set FRESH and parses the produced `dashboard.html`
state as a black box, independent of the build's in-memory objects. It
HARD-FAILS (non-zero exit) on any shortfall: a full-set member not marked
`tier:"full"`, a full-tier body that is not source-anchored to its live source,
a plans-floor or section-floor gap, a `{spec-sha, structure-sha}` mismatch, a
status outside the live vocabulary, or less than 100% parse coverage. A non-zero
exit means the render is regenerated, never accepted short. The same floor is
re-checked independently at CI by the mechanical DEEP floor (Check 89), which
shares no code with the build script.

The spec's own requirements outrank any general guidance here. Identical (spec,
state) yields identical output.
