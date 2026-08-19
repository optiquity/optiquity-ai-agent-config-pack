---
name: resolve-merge-conflicts
description: Use during a v10→v11 migration pause to resolve the reconciliation rows the migrator left behind — same-line prose conflict markers (Case 1) and trinity sidecars folded section-aware into the new pack file (Case 2), each behind a mechanical zero-loss gate. Scripts and agents are out of scope (re-apply by hand).
allowed-tools: Read, Grep, Bash, Edit
---

# Resolve merge conflicts

The migrator auto-merges what it can deterministically and PAUSES on the rest,
recording each unresolved file in `<TARGET>/.pack-migrate-v10-to-v11/dispositions.tsv`.
This skill resolves the two classes the migrator leaves for an agent: same-line
**prose** markers (Case 1) and **trinity** sidecars (Case 2). It never runs
automatically — you run it during the pause, before `--resume`. On any doubt it
leaves the file untouched (still recoverable) and reports it as unresolved.

## Locate the in-scope rows

Read the disposition table under the migration state directory
(`<TARGET>/.pack-migrate-v10-to-v11/dispositions.tsv`). Columns are
tab-separated: `disposition⇥class⇥rel⇥action⇥sidecar⇥diff⇥notes`. Select rows
with this awk:

```bash
STATE="<TARGET>/.pack-migrate-v10-to-v11"
# One condition per continued line ends with an operator, never a bare `(` —
# BSD awk (stock macOS) rejects a line-final `(`.
awk -F'\t' '
  $1=="customization-detected-needs-reconciliation" &&
  ($2=="trinity" || ($4=="merged" && ($2=="generic" || $2=="pm-chat"))) { print }
' "$STATE/dispositions.tsv"
# $2=="trinity"                                → Case 2 (trinity sidecar)
# $4=="merged" && $2 in {generic, pm-chat}     → Case 1 (prose markers)
```

**Out of scope — do NOT touch these** (report them under "re-apply by hand"):

```bash
awk -F'\t' '
  $1=="customization-detected-needs-reconciliation" && $4=="sidecar" &&
  ($2=="pack-script" || $2=="pack-agent") { print }
' "$STATE/dispositions.tsv"
```

The live pack file is the valid v11 version; the project's prior edit is in the
`.v10-customized` sidecar. Executables and agents are never line-merged — the
client re-applies each edit by hand.

## Case 1 — prose markers (`generic` / `pm-chat`, action `merged`)

The live file (`rel`, column 3) already carries `--diff3` conflict markers with
the three sides inline (`your customization` / `v10 baseline` / `pack v11
update`); the full prior copy is the `.v10-customized` sidecar (column 5).

1. Open the live file. For each conflict hunk, resolve it into one sensible
   combined result that honors BOTH the project edit and the pack v11 update.
2. **Gate — zero markers.** Before declaring the file done, grep it for ALL
   FOUR `--diff3` tokens; the result MUST be empty:

   ```bash
   grep -nE '^(<<<<<<<|\|\|\|\|\|\|\||=======|>>>>>>>)' "$rel" && echo "MARKERS REMAIN — not done"
   ```

3. On a clean gate: remove the `.v10-customized` sidecar (recoverable from the
   pre-migration backup) and report the file resolved. If any marker remains,
   leave the file and sidecar and report it unresolved.

## Case 2 — trinity fold (`class` = `trinity`, action `sidecar`)

The trinity files (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) are section-
structured, so they are folded section-AWARE, never line-merged. Three inputs:

- **THEIRS** — the live file (`rel`), the v11 canonical the migrator just wrote.
  Copy it to a temp (`THEIRS_tmp`) BEFORE any edit.
- **OURS** — the `.v10-customized` sidecar (column 5): the full pre-migration
  project copy.
- **BASE** — `<live>.v10-base`, stashed next to the sidecar at migration time.

### Fold procedure

1. Compute the project's additions: `diff "$BASE" "$OURS"` — the exact lines the
   project added or changed since v10.
2. Start from THEIRS (the v11 body + section skeleton). Place each addition into
   the CORRECT v11 section, WRAPPED in a project-owned marker pair:
   - **Shape A** — an addition to a section the pack ships: wrap only your lines
     INSIDE that section's body, leaving the pack heading and body in place.
   - **Shape B** — a whole project-owned section (new, renamed, or an override):
     wrap the heading line AND the body.
   - A section the pack renamed v10→v11 is matched to its v11 name; a customized
     section whose heading still carries the literal `[CONDITIONAL]` prefix
     becomes a Shape B override (drop the prefix; optionally annotate the BEGIN
     marker with `renamed-from "<old heading>"`).
3. Preserve every addition BYTE-IDENTICALLY inside its marker — this is what the
   completeness gate checks and what lets the fold auto-graft on the next
   migration.

### Gate — zero-loss verification (run BEFORE writing the fold to the live file)

The fold is the one non-deterministic step, so a mechanical gate must pass
first. Prefer the pack's own tested marker engine as the verifier; the migrator
pause report names the pack clone as `PACK`.

**PRIMARY — round-trip through the marker engine.** Source the engine and run it
on the folded output as if it were a fresh trinity migrating to the SAME v11
canonical, with an EMPTY base:

```bash
( set -e
  export _CP_PACK_ROOT="$PACK"
  source "$PACK/scripts/lib/three-way.sh"
  source "$PACK/scripts/lib/customization-preserve.sh"   # sources marker-preserve.sh + three-way-merge.sh
  GATE="$(mktemp -d)"; customization_preserve_init "$GATE" ".v10-customized" >/dev/null
  marker_preserve_trinity "" "$FOLDED" "$THEIRS_tmp" "CLAUDE.md" "$GATE/throwaway" >/dev/null
  disp="$(tail -1 "$GATE/dispositions.tsv" | awk -F'\t' '{print $1}')"
  [ "$disp" = "merged-with-customization" ] || { echo "GATE FAIL: $disp"; exit 1; }
)
```

Passing this single check proves mechanically: well-formed markers; the v11 body
fully adopted (out-of-marker body byte-identical to the canonical); no
duplicated `##` heading; no residual conflict marker in the body;
no unreconciled rename or `[CONDITIONAL]` heading; and durability (it will
auto-graft next migration). Any of those defects routes the engine to a sidecar
— disposition `customization-detected-needs-reconciliation`, NOT
`merged-with-customization` — so the gate FAILS. (Section ORDER is not enforced:
the engine compares sections by heading NAME, not as an ordered stream, so a
reordered-but-complete fold still passes — reordering is non-lossy and re-emits
in canonical order next migration.)

**SUPPLEMENT — customization completeness.** A degenerate fold with EMPTY marker
regions still passes the round-trip, so also require every added line of
`diff "$BASE" "$OURS"` to appear INSIDE a marker region of the fold (scope the
check to the region, not the whole file, to avoid a coincidental body match).

**SUPPLEMENT — zero conflict markers.** Grep the fold for all four `--diff3`
tokens (as in Case 1); the result MUST be empty (catches a marker left inside a
project region, which the body comparison would hide).

**If `PACK` is unreachable** (no clone at pause time), fall back to the self-
contained checks — the four-token grep, a balanced-marker check
(`<!-- BEGIN project-owned -->` / `<!-- END project-owned -->` pair for pair),
a `##`-heading-set compare of the fold's out-of-marker body against `THEIRS_tmp`,
and the completeness leg — and report the file as resolved UNDER REDUCED
VERIFICATION. Never declare a file done under reduced verification without
saying so.

### On success

Only when every gate leg passes: write the fold to the live file; remove the
`.v10-customized` sidecar and the `.v10-base` stash (both recoverable from the
pre-migration backup). On any gate failure: leave the live file, sidecar, and
stash untouched, and report the file as unresolved for hand reconciliation.

## Report

For each in-scope file: `resolved` or `left for hand reconciliation`, with the
gate result. List the out-of-scope script/agent sidecars under "re-apply by
hand." Then the migration continues with `--resume`.
