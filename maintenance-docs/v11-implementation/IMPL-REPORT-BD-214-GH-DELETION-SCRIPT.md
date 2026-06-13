# IMPL-REPORT — BD-214 GH-issue/label deletion script (DESIGN + DRY-RUN ONLY)

- **Author:** pack-coder (fresh)
- **Date:** 2026-06-13
- **Branch:** `v11-dev`
- **HEAD (worktree, unchanged by this task):** `6d5ba2dfcfa65dc853b1b58c40e1f72560674b93`
- **Charter:** BD-214 design §7 — write the one-off tool that (later, under
  explicit user GO) deletes the 213 inert pack-marked GH issues + 49
  pack-managed labels left by the abandoned BD-204 C-8 flip.
- **Scope performed:** WROTE the script + ran ONLY the read-only dry-run path to
  validate it. The destructive `--execute` path was NOT run. The real deletion
  remains HELD for the user.

---

## 1. Deliverable inventory

| Path | Type | Tracked? |
|---|---|---|
| `/tmp/bd214-gh-issue-deletion.sh` | NEW one-off script | **NO** — lives in `/tmp` only, never committed (BD-214 §7 D-I; BD-212 reusable verb is deferred) |
| `/tmp/bd214-gh-issue-deletion-manifest-20260613T181903Z.json` | dry-run snapshot artifact | NO — operational ephemera in `/tmp` |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-214-GH-DELETION-SCRIPT.md` | this report | (Pack Chat decides staging) |

**No repo source files were modified by this task.** `git status --short` shows
only the 8 pre-existing dirty `backlog/*.md` files that were already present at
session start (`git rev-parse HEAD` = `6d5ba2d` before and after). The script is
NOT in `git ls-files` (count = 0).

---

## 2. Script design (mapped to BD-214 §7 + RESEARCH-BD-212)

The script is a single `bash` file, macOS bash 3.2 + BSD-utils compatible
(no associative arrays, no `&>`, no GNU-only flags; JSON shaping via `python3`,
present on macOS). `set -u` is on; `set -e` is deliberately OFF so the delete
loop can classify per-item errors instead of aborting on the first non-zero
`gh` exit. Preflight failures call an explicit `die`.

### 2.1 Safety model (the spine)

- **DRY-RUN is the DEFAULT.** Invoking with no flags performs ONLY read-only
  `gh` queries (preflight, snapshot, candidate computation, preview) and exits
  0 without mutating anything. This is the path validated below.
- **Destructive path requires BOTH `--execute` AND an interactive typed
  confirmation phrase** (`DELETE ALL PACK ISSUES AND LABELS`). There is no
  non-interactive escape hatch — `--execute` alone still stops at the prompt.
- **Marker-scoped deletion ONLY.** An issue is a candidate iff it carries the
  `bd-entry` label OR a `<!-- pack-id: ... -->` body marker. If ANY repo issue
  matches NEITHER, the safety gate STOPS (exit 2) and lists the stray(s) — they
  are not in the user's "all 213" decision.
- **Labels:** only the 49 carrying description exactly `v11 pack-managed label`;
  the 9 GitHub defaults are never enumerated for deletion.
- **One repo only:** `DShaneNYC/optiquity-ai-agent-config-pack`, hard-coded;
  preflight asserts `nameWithOwner` equals the constant. No repo deletion path
  exists anywhere in the script.

### 2.2 Stage-by-stage (matches §7 procedure 1–7)

1. **Preflight** (§7.1): `gh auth status` must show account `DShaneNYC` and the
   classic `'repo'` scope; read-only GraphQL asserts `viewerCanAdminister == true`
   on the exact target repo. Any failure → `die` before any snapshot.
2. **Snapshot issues FIRST** (§7.2): paginates ALL issues (100/page,
   `orderBy CREATED_AT ASC`, `pageInfo.hasNextPage` loop) capturing number, node
   `id`, title, state, labels, and the `pack-id` parsed from each body via
   `<!-- pack-id: ([^\s]+) -->`. Writes the manifest to
   `/tmp/bd214-gh-issue-deletion-manifest-<UTC-stamp>.json`. This is the ONLY
   audit artifact (a personal account logs no issue-deletion event —
   RESEARCH §4); the script PRINTS a recommendation to archive a copy OUTSIDE
   `/tmp` before any real run.
3. **Snapshot labels** (§7.6): `gh label list --json name,description`, flags
   each label `is_pack_managed = (description == "v11 pack-managed label")`,
   appends to the manifest.
4. **Safety gate** (§7.3): asserts 0 stray issues (hard STOP / exit 2 if any),
   surfaces candidate count vs the expected 213 and pack-label count vs 49 as
   re-confirm WARNINGs (a pure count delta with zero strays is surfaced, not
   aborted, since entries may legitimately change after the design snapshot;
   ANY stray is an unconditional abort).
5. **Preview** (dry-run output): prints every candidate issue
   (number / pack-id / state / title) and every pack-managed label name, then
   on the no-flag path exits 0 having mutated nothing.
6. **Execute path** (§7.4, gated — NOT run here): serial loop,
   `deleteIssue(input:{issueId})` by node ID via `gh api graphql`; `sleep` ≥1s
   between mutations (RESEARCH §5.4); classifies `errors[0].type` —
   `NOT_FOUND` → idempotent skip (already deleted), `FORBIDDEN`/`INSUFFICIENT_SCOPES`
   → terminal `die`, `RATE_LIMITED` → 60s backoff then abort-to-resume; prints a
   per-item running log (idx/total, number, pack-id, node id, result). Then
   deletes the 49 pack-managed labels (`gh label delete --yes`, ≥1s pacing).
7. **Verify** (§7.5, after execute): re-queries issues carrying `bd-entry`
   (expect 0); REST spot-checks one deleted number (expect `410 Gone`); counts
   remaining pack-managed labels (expect 0).

### 2.3 Idempotent + resumable

`deleteIssue` on an already-deleted node returns `errors[0].type == NOT_FOUND`,
which the loop treats as a skip — so a re-run after a partial deletes only the
remainder. Label deletes likewise continue past an already-gone label. The
pre-delete manifest is retained across runs (new stamp per invocation).

---

## 3. Validation performed (READ-ONLY dry-run — `--execute` NOT run)

`bash -n` passed on bash 3.2.57. The dry-run path was run against the live
target repo (listing issues/labels is not a mutation). Post-run re-query
confirms the repo is UNCHANGED (still 213 issues). Quoted key output:

```
mode  : DRY-RUN (read-only, DEFAULT)
PREFLIGHT
  auth: account DShaneNYC present, 'repo' scope present.
  repo: DShaneNYC/optiquity-ai-agent-config-pack viewerCanAdminister=true.
SNAPSHOT (issues) -> /tmp/bd214-gh-issue-deletion-manifest-20260613T181903Z.json
  captured 213 issues into manifest.
SNAPSHOT (labels)
  captured 58 labels into manifest.
SAFETY GATE
  total issues in repo : 213
  candidate issues     : 213 (bd-entry label OR pack-id marker)
  STRAY (non-candidate): 0
  total labels in repo : 58
  pack-managed labels  : 49
  GitHub default labels: 9 (will NOT be touched)
  Safety gate PASSED: zero stray issues.
PREVIEW — what WOULD be deleted
ISSUES TO DELETE: 213
  ...#1 BD-001 ... through #213 BD-213...
LABELS TO DELETE: 49
  bd-entry, derived-from:TD-031, ... work-item  (49 names)
DRY-RUN COMPLETE. Nothing was mutated.
```

**Independent corroboration (read-only, before writing the script):**

```
$ gh api graphql ... repository.issues.totalCount   -> 213
$ search/issues  is:issue label:bd-entry            -> 213
$ search/issues  is:issue -label:bd-entry           -> 0     (zero stray)
$ gh label list (by description)  -> total 58 = 49 pack-managed + 9 defaults
```

The 9 excluded defaults are exactly GitHub's stock set
(`bug, documentation, duplicate, enhancement, good first issue, help wanted,
invalid, question, wontfix`) — none carry the pack-managed description.

**Post-dry-run repo-unchanged proof:**

```
$ gh api graphql ... repository.issues.totalCount   -> 213   (still all present)
```

**Manifest well-formedness:**

```
issues: 213 | candidates: 213 | strays: 0
labels: 58  | pack-managed: 49
sample: {"number":1,"node_id":"I_kwDORzTrHM8AAAABFKq8Vg","state":"CLOSED",
         "labels":["bd-entry","status:resolved","template:bd-v11.0"],
         "pack_id":"BD-001","is_candidate":true}
```

Result: candidate set = the 213 pack-marked issues; the 49 pack-managed labels
enumerated; ZERO stray/non-candidate issues. Validation CLEAN.

---

## 4. The exact command the user/executor will later run (HELD)

Held for explicit user GO. When authorized, in a shell on this machine:

1. Dry-run once more to refresh the snapshot + re-confirm zero strays (writes a
   fresh stamped manifest):

   ```
   bash /tmp/bd214-gh-issue-deletion.sh
   ```

2. **Archive the printed manifest OUTSIDE `/tmp`** (the only audit artifact),
   e.g. `cp /tmp/bd214-gh-issue-deletion-manifest-<stamp>.json ~/Desktop/`.

3. Execute the real deletion (will prompt for the typed phrase):

   ```
   bash /tmp/bd214-gh-issue-deletion.sh --execute
   # at the prompt, type exactly:  DELETE ALL PACK ISSUES AND LABELS
   ```

   ~213 issue deletes at ≥1s pacing ≈ 4–5 min, then 49 label deletes. The
   script auto-verifies (0 bd-entry issues remain; one number → 410 Gone; 0
   pack-managed labels remain).

4. Record a dated note on BD-214 with the before/after counts + the archived
   manifest location.

This step is a user-gated destructive op and was NOT performed by this agent.

---

## 5. Plan deviations

Zero design deviations. One implementation-mechanics correction during
development (not a design change): the label-snapshot helper initially piped
`gh label list` JSON to a here-doc `python3 -` reader, but a `<<'PY'` here-doc
overrides the stdin pipe (so `sys.stdin` read empty). Fixed by writing the
label JSON to a `mktemp` file and passing its path as `argv` (matching the
issue-snapshot helper's already-working file-based pattern). Re-validated clean.

## 6. New POQs introduced

None.

---

## 7. Definition-of-Done checklist

| Item | Status |
|---|---|
| Script written at `/tmp/bd214-gh-issue-deletion.sh` (not committed) | PASS |
| `bash -n` syntax check on bash 3.2 | PASS |
| Preflight: account + `repo` scope + `viewerCanAdminister` | PASS (live) |
| Snapshot-first manifest (issues + labels) written before any delete | PASS |
| Candidate set = bd-entry OR pack-id marker; count = 213 | PASS (213/213) |
| Safety gate STOPS on any stray issue | PASS (0 strays; gate PASSED) |
| Labels scoped to the 49 pack-managed (9 defaults excluded) | PASS |
| Dry-run is DEFAULT + read-only + exits without mutating | PASS |
| Repo confirmed UNCHANGED after dry-run | PASS (213 remain) |
| `--execute` gated behind flag + typed confirmation | PASS (NOT run) |
| ≥1s pacing + NOT_FOUND idempotent + FORBIDDEN terminal in execute loop | PASS (coded) |
| Post-execute verify (0 issues / 410 Gone / 0 labels) | PASS (coded) |
| Real deletion NOT performed | PASS (held) |
| No git state-change verbs run | PASS |

---

## 8. Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| **agents-never-commit** (git read-only only; script in /tmp) | Only git verbs run: `git rev-parse HEAD` (`6d5ba2d`), `git status`, `git ls-files \| grep -c bd214 -> 0`. No `add`/`commit`/`push`/`tag`. Script is in `/tmp`, untracked (`git ls-files` count 0). | COMPLIANT |
| **per-action-approval / no-destructive-on-own-authority** | Only execution performed = the no-flag DRY-RUN (read-only `gh` queries). `--execute` never passed; post-dry-run re-query shows repo unchanged (213 issues). Real deletion surfaced as HELD in §4. | COMPLIANT |
| **real-safe-tool-no-band-aids** | Safety gate hard-STOPS (exit 2) on any stray (`-label:bd-entry -> 0` proves none today, gate code lists them if present); snapshot-first manifest written before any mutation; ≥1s pacing constant `MIN_WRITE_INTERVAL_SEC=1`; `errors[0].type` classifier (NOT_FOUND skip / FORBIDDEN die / RATE_LIMITED backoff); `--execute` + typed phrase `DELETE ALL PACK ISSUES AND LABELS` double-gate. All functional, not cosmetic. | COMPLIANT |
| **scope-discipline** (sanctioned repo; marker-scoped; never repos/non-pack labels) | `TARGET_NWO="DShaneNYC/optiquity-ai-agent-config-pack"` hard-coded + preflight asserts `nameWithOwner`. Candidate = bd-entry OR pack-id only. No repo-delete code anywhere (`grep` of script has no `repo delete`/`repo archive`). Labels filtered to `description=="v11 pack-managed label"` (49); 9 defaults excluded (verified: bug/documentation/.../wontfix). | COMPLIANT |
| **rules-applied-verification-block** | This block; per-rule quoted evidence; terminal conclusions only. | COMPLIANT |
| **preflight-stop-means-stop** | Emitted before this Write: `PREFLIGHT: deletion script written to /tmp + dry-run validated (candidate set = 213 issues + 49 labels, 0 stray); real deletion NOT run (held); about to Write IMPL-REPORT to <path>`. No parent stop message received. | COMPLIANT |
| **agents-read-rule-docs-in-full** | Read FULL: `CLAUDE.md` (583 lines incl. `## Pack memory`); `RESEARCH-BD-212-GH-ISSUE-DELETION.md` (279 lines); `ARCHITECTURE-BD-214-...md` §7 (lines 506–542, the named spec section) + section map of the whole doc. | COMPLIANT |
| **filename-uniqueness-heuristic** | New names `bd214-gh-issue-deletion.sh` / `IMPL-REPORT-BD-214-GH-DELETION-SCRIPT.md` carry the BD-214 token + GH-deletion qualifier; the report path is given explicitly; the script is /tmp-only (not a repo collision concern). | COMPLIANT |

---

## 9. Full file contents — `/tmp/bd214-gh-issue-deletion.sh`

Reproduced verbatim so this script can be re-created without re-deriving (it is
not in the repo).

```bash
#!/usr/bin/env bash
#
# bd214-gh-issue-deletion.sh
# -----------------------------------------------------------------------------
# ONE-OFF, NON-COMMITTED tool (lives in /tmp ONLY; BD-214 design §7, D-I).
#
# Purpose: delete the inert pack-managed GitHub issues + pack-managed labels
# left on the pack's real tracker repo by the abandoned BD-204 C-8 flip.
#
# Spec sources (read in full by the author):
#   maintenance-docs/v11-implementation/ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md §7
#   maintenance-docs/v11-implementation/RESEARCH-BD-212-GH-ISSUE-DELETION.md
#
# SAFETY MODEL (absolute):
#   * DRY-RUN is the DEFAULT. Running with no flags performs ONLY read-only
#     `gh` queries (preflight + snapshot + candidate computation + preview)
#     and EXITS without mutating anything.
#   * The destructive path requires BOTH `--execute` AND an interactive typed
#     confirmation phrase. There is no non-interactive escape hatch.
#   * Marker-scoped deletion ONLY: an issue is a candidate iff it carries the
#     `bd-entry` label OR a `<!-- pack-id: ... -->` body marker. If ANY issue
#     in the repo matches NEITHER, the script STOPS (stray issues are NOT in
#     the user's "all 213" decision). Labels: only the 49 carrying
#     description "v11 pack-managed label"; the 9 GitHub defaults are never
#     touched.
#   * Only the sanctioned target repo. Never any other repo. Never repo delete.
#
# macOS bash 3.2 + BSD-utils compatible (no associative arrays, no `&>`,
# no GNU-only flags). Uses python3 for JSON shaping (present on macOS).
# -----------------------------------------------------------------------------

set -u
# NOTE: deliberately NOT `set -e`. The delete loop must classify per-item
# errors (NOT_FOUND -> idempotent skip) rather than abort the whole run on the
# first non-zero gh exit. Preflight failures call `die` explicitly.

# ----------------------------- constants -------------------------------------
readonly TARGET_OWNER="DShaneNYC"
readonly TARGET_REPO="optiquity-ai-agent-config-pack"
readonly TARGET_NWO="${TARGET_OWNER}/${TARGET_REPO}"
readonly EXPECTED_ACCOUNT="DShaneNYC"
readonly PACK_LABEL_DESC="v11 pack-managed label"
readonly BD_ENTRY_LABEL="bd-entry"
readonly EXPECTED_ISSUE_COUNT=213          # design decision-of-record (BD-214)
readonly EXPECTED_LABEL_COUNT=49           # 49 pack-managed; 9 GH defaults stay
readonly MIN_WRITE_INTERVAL_SEC=1          # >=1s mutation pacing (RESEARCH §5.4)
readonly CONFIRM_PHRASE="DELETE ALL PACK ISSUES AND LABELS"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
readonly STAMP
readonly MANIFEST="/tmp/bd214-gh-issue-deletion-manifest-${STAMP}.json"

EXECUTE=0   # 0 = dry-run (default, read-only); 1 = real delete (gated)

# ----------------------------- helpers ---------------------------------------
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
note() { printf '%s\n' "$*"; }
hr()  { printf -- '-----------------------------------------------------------------------------\n'; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

usage() {
  cat <<EOF
Usage: $0 [--execute]

  (no flags)   DRY-RUN (DEFAULT): read-only preflight + snapshot + candidate
               preview. Mutates NOTHING. This is the safe validation path.
  --execute    REAL DELETION. Requires an interactive typed confirmation.
               Deletes ${EXPECTED_ISSUE_COUNT} pack-marked issues then the
               ${EXPECTED_LABEL_COUNT} pack-managed labels on ${TARGET_NWO}.
  -h|--help    This help.
EOF
}

# ----------------------------- arg parse -------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --execute) EXECUTE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; die "unknown argument: $1" ;;
  esac
  shift
done

require_cmd gh
require_cmd python3

# ----------------------------- preflight -------------------------------------
preflight() {
  hr; note "PREFLIGHT"; hr

  # 1. gh auth: account + classic repo scope.
  local auth_out
  auth_out="$(gh auth status 2>&1)" || die "gh auth status failed; not logged in?"
  printf '%s\n' "$auth_out" | grep -q "account ${EXPECTED_ACCOUNT}" \
    || die "active gh account is not ${EXPECTED_ACCOUNT}. Aborting (scope discipline)."
  printf '%s\n' "$auth_out" | grep -q "'repo'" \
    || die "token is missing the classic 'repo' scope; deletion needs it."
  note "  auth: account ${EXPECTED_ACCOUNT} present, 'repo' scope present."

  # 2. admin on the EXACT target repo (read-only GraphQL).
  local admin nwo
  local pf_json
  pf_json="$(gh api graphql -f query='query($o:String!,$n:String!){repository(owner:$o,name:$n){viewerCanAdminister nameWithOwner}}' \
              -f o="${TARGET_OWNER}" -f n="${TARGET_REPO}" 2>&1)" \
    || die "preflight repository query failed: ${pf_json}"
  admin="$(printf '%s' "$pf_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["data"]["repository"]["viewerCanAdminister"])' 2>/dev/null)"
  nwo="$(printf '%s' "$pf_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["data"]["repository"]["nameWithOwner"])' 2>/dev/null)"
  [ "$nwo" = "$TARGET_NWO" ] || die "preflight returned unexpected repo '${nwo}' (expected ${TARGET_NWO})."
  [ "$admin" = "True" ] || die "viewerCanAdminister != true on ${TARGET_NWO}; cannot delete issues."
  note "  repo: ${TARGET_NWO} viewerCanAdminister=true."
}

# ----------------------------- snapshot --------------------------------------
# Page ALL issues, capture number/node-id/title/state/labels/pack-id; write the
# manifest. Read-only. This is the ONLY audit artifact (no GH audit event on a
# personal account -- RESEARCH §4).
snapshot_issues() {
  note ""; hr; note "SNAPSHOT (issues) -> ${MANIFEST}"; hr

  local cursor="null"
  local tmp_pages
  tmp_pages="$(mktemp -t bd214pages)" || die "mktemp failed"
  # Accumulate raw page node arrays as JSON lines, then merge with python.
  : > "$tmp_pages"

  while : ; do
    local page
    page="$(gh api graphql -f query='
      query($o:String!,$n:String!,$after:String){
        repository(owner:$o,name:$n){
          issues(first:100, after:$after, orderBy:{field:CREATED_AT, direction:ASC}){
            pageInfo{ hasNextPage endCursor }
            nodes{ number id title state body labels(first:30){nodes{name}} }
          }
        }
      }' -f o="${TARGET_OWNER}" -f n="${TARGET_REPO}" -F after="${cursor}" 2>&1)" \
      || die "issue page query failed: ${page}"

    printf '%s\n' "$page" >> "$tmp_pages"

    local has_next end
    has_next="$(printf '%s' "$page" | python3 -c 'import json,sys; print(json.load(sys.stdin)["data"]["repository"]["issues"]["pageInfo"]["hasNextPage"])' 2>/dev/null)"
    end="$(printf '%s' "$page" | python3 -c 'import json,sys; print(json.load(sys.stdin)["data"]["repository"]["issues"]["pageInfo"]["endCursor"])' 2>/dev/null)"
    [ "$has_next" = "True" ] || break
    cursor="$end"
  done

  # Merge pages -> manifest issues array (number,id,title,state,labels,pack_id,is_candidate).
  python3 - "$tmp_pages" "$MANIFEST" "$BD_ENTRY_LABEL" <<'PY'
import json, re, sys
pages_file, manifest_path, bd_label = sys.argv[1], sys.argv[2], sys.argv[3]
issues = []
with open(pages_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        obj = json.loads(line)
        for n in obj["data"]["repository"]["issues"]["nodes"]:
            labels = [l["name"] for l in n["labels"]["nodes"]]
            m = re.search(r"<!--\s*pack-id:\s*([^\s]+)\s*-->", n.get("body") or "")
            pack_id = m.group(1) if m else None
            is_candidate = (bd_label in labels) or (pack_id is not None)
            issues.append({
                "number": n["number"],
                "node_id": n["id"],
                "title": n["title"],
                "state": n["state"],
                "labels": labels,
                "pack_id": pack_id,
                "is_candidate": is_candidate,
            })
issues.sort(key=lambda x: x["number"])
with open(manifest_path, "w") as out:
    json.dump({"issues": issues}, out, indent=2)
PY
  rm -f "$tmp_pages"
  note "  captured $(python3 -c 'import json;print(len(json.load(open("'"$MANIFEST"'"))["issues"]))') issues into manifest."
}

# Append the label snapshot (all labels + pack-managed flag) into the manifest.
snapshot_labels() {
  note ""; hr; note "SNAPSHOT (labels)"; hr
  local labels_file
  labels_file="$(mktemp -t bd214labels)" || die "mktemp failed"
  gh label list --repo "${TARGET_NWO}" --limit 300 --json name,description > "$labels_file" 2>/dev/null \
    || die "label list failed"
  python3 - "$MANIFEST" "$PACK_LABEL_DESC" "$labels_file" <<'PY'
import json, sys
manifest_path, pack_desc, labels_file = sys.argv[1], sys.argv[2], sys.argv[3]
labels = json.load(open(labels_file))
out_labels = []
for l in labels:
    desc = l.get("description") or ""
    out_labels.append({
        "name": l["name"],
        "description": desc,
        "is_pack_managed": (desc == pack_desc),
    })
out_labels.sort(key=lambda x: x["name"])
m = json.load(open(manifest_path))
m["labels"] = out_labels
m["meta"] = {"target": "%s" % "DShaneNYC/optiquity-ai-agent-config-pack"}
json.dump(m, open(manifest_path, "w"), indent=2)
PY
  rm -f "$labels_file"
  note "  captured $(python3 -c 'import json;print(len(json.load(open("'"$MANIFEST"'")).get("labels",[])))') labels into manifest."
}

# ----------------------------- safety gate -----------------------------------
# Read the manifest; assert no stray issue; assert candidate/label counts.
# Exits the script (die) on any violation. Sets globals via the manifest only.
safety_gate() {
  note ""; hr; note "SAFETY GATE"; hr

  python3 - "$MANIFEST" "$EXPECTED_ISSUE_COUNT" "$EXPECTED_LABEL_COUNT" <<'PY'
import json, sys
manifest_path = sys.argv[1]
exp_issues = int(sys.argv[2])
exp_labels = int(sys.argv[3])
m = json.load(open(manifest_path))
issues = m["issues"]
labels = m["labels"]

strays = [i for i in issues if not i["is_candidate"]]
candidates = [i for i in issues if i["is_candidate"]]
pack_labels = [l for l in labels if l["is_pack_managed"]]
default_labels = [l for l in labels if not l["is_pack_managed"]]

print("  total issues in repo : %d" % len(issues))
print("  candidate issues     : %d (bd-entry label OR pack-id marker)" % len(candidates))
print("  STRAY (non-candidate): %d" % len(strays))
print("  total labels in repo : %d" % len(labels))
print("  pack-managed labels  : %d" % len(pack_labels))
print("  GitHub default labels: %d (will NOT be touched)" % len(default_labels))

fail = False
if strays:
    print("\n  STOP: %d issue(s) match NEITHER bd-entry label NOR a pack-id marker." % len(strays))
    print("        These are NOT in the user's 'all %d' decision. Listing:" % exp_issues)
    for s in strays:
        print("          #%s  state=%s  labels=%s  title=%r" % (s["number"], s["state"], s["labels"], s["title"]))
    fail = True

if len(candidates) != exp_issues:
    print("\n  WARNING: candidate count %d != expected %d (design decision-of-record)." % (len(candidates), exp_issues))
    print("           Re-confirm with the user before --execute; counts may have drifted.")
    # Not a hard stop by itself, but combined with strays it is. A pure count
    # delta with zero strays is surfaced for user re-confirmation, not aborted,
    # because entries may have legitimately changed since the design snapshot.

if len(pack_labels) != exp_labels:
    print("\n  WARNING: pack-managed label count %d != expected %d." % (len(pack_labels), exp_labels))

if fail:
    print("\n  Safety gate FAILED (stray issues present). Aborting before any mutation.")
    sys.exit(2)
print("\n  Safety gate PASSED: zero stray issues.")
PY
  local rc=$?
  [ "$rc" -eq 0 ] || die "safety gate failed (rc=${rc}); no mutation performed."
}

# ----------------------------- preview ---------------------------------------
preview() {
  note ""; hr; note "PREVIEW -- what WOULD be deleted"; hr
  python3 - "$MANIFEST" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
cands = [i for i in m["issues"] if i["is_candidate"]]
pack_labels = [l for l in m["labels"] if l["is_pack_managed"]]
print("ISSUES TO DELETE: %d" % len(cands))
for i in cands:
    print("  #%-4s  pack-id=%-8s  state=%-7s  %s" % (
        i["number"], i["pack_id"] or "-", i["state"], i["title"]))
print("")
print("LABELS TO DELETE: %d" % len(pack_labels))
for l in pack_labels:
    print("  %s" % l["name"])
PY
}

# ----------------------------- delete loop -----------------------------------
delete_issues() {
  note ""; hr; note "EXECUTE -- deleting issues (serial, >=${MIN_WRITE_INTERVAL_SEC}s pacing)"; hr

  # Emit candidate "number<TAB>node_id<TAB>pack_id" lines for the shell loop.
  local list
  list="$(python3 - "$MANIFEST" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
for i in m["issues"]:
    if i["is_candidate"]:
        print("%s\t%s\t%s" % (i["number"], i["node_id"], i["pack_id"] or "-"))
PY
)"

  local total deleted skipped failed
  total="$(printf '%s\n' "$list" | grep -c .)"
  deleted=0; skipped=0; failed=0
  local idx=0

  printf '%s\n' "$list" | while IFS="$(printf '\t')" read -r num node pid; do
    [ -n "$num" ] || continue
    idx=$((idx + 1))
    local resp errtype
    resp="$(gh api graphql -f query='mutation($id:ID!){deleteIssue(input:{issueId:$id}){repository{nameWithOwner}}}' \
             -f id="$node" 2>&1)"
    if printf '%s' "$resp" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d.get("data",{}).get("deleteIssue") else 1)' >/dev/null 2>&1; then
      note "  [${idx}/${total}] #${num} pack-id=${pid} node=${node} -> DELETED"
    else
      errtype="$(printf '%s' "$resp" | python3 -c 'import json,sys
try:
  d=json.load(sys.stdin); errs=d.get("errors") or []
  print(errs[0].get("type","") if errs else "")
except Exception:
  print("PARSE_ERROR")' 2>/dev/null)"
      case "$errtype" in
        NOT_FOUND)
          note "  [${idx}/${total}] #${num} pack-id=${pid} node=${node} -> SKIP (NOT_FOUND, already deleted; idempotent)"
          ;;
        FORBIDDEN|INSUFFICIENT_SCOPES)
          die "TERMINAL: deleteIssue returned ${errtype} on #${num}. Admin preflight or scope is wrong. STOP."
          ;;
        RATE_LIMITED)
          note "  [${idx}/${total}] #${num} -> RATE_LIMITED; backing off 60s then aborting this run (re-run resumes)."
          sleep 60
          die "rate limited; re-run the script to resume (idempotent: deleted issues skip via NOT_FOUND)."
          ;;
        *)
          note "  [${idx}/${total}] #${num} pack-id=${pid} -> FAILED (errtype='${errtype}'); raw: ${resp}"
          # Surface secondary-limit retry-after if present, then continue.
          ;;
      esac
    fi
    sleep "${MIN_WRITE_INTERVAL_SEC}"
  done
  note "  issue delete loop complete (NOT_FOUND treated as already-deleted)."
}

delete_labels() {
  note ""; hr; note "EXECUTE -- deleting pack-managed labels (>=${MIN_WRITE_INTERVAL_SEC}s pacing)"; hr
  local names
  names="$(python3 - "$MANIFEST" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
for l in m["labels"]:
    if l["is_pack_managed"]:
        print(l["name"])
PY
)"
  printf '%s\n' "$names" | while IFS= read -r ln; do
    [ -n "$ln" ] || continue
    if gh label delete "$ln" --repo "${TARGET_NWO}" --yes >/dev/null 2>&1; then
      note "  label DELETED: ${ln}"
    else
      note "  label delete FAILED or already gone: ${ln} (continuing)"
    fi
    sleep "${MIN_WRITE_INTERVAL_SEC}"
  done
  note "  label delete loop complete."
}

# ----------------------------- verify ----------------------------------------
verify_after() {
  note ""; hr; note "VERIFY (post-execute)"; hr
  local remaining sample_num status
  remaining="$(gh api -X GET search/issues -f q="repo:${TARGET_NWO} is:issue label:${BD_ENTRY_LABEL}" --jq '.total_count' 2>&1)"
  note "  issues still carrying '${BD_ENTRY_LABEL}': ${remaining} (expect 0)"

  # Spot-check one previously-deleted number -> expect 410 Gone.
  sample_num="$(python3 - "$MANIFEST" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
c = [i for i in m["issues"] if i["is_candidate"]]
print(c[0]["number"] if c else "")
PY
)"
  if [ -n "$sample_num" ]; then
    status="$(gh api "repos/${TARGET_NWO}/issues/${sample_num}" -i 2>&1 | head -1)"
    note "  spot-check #${sample_num} via REST -> ${status} (expect HTTP/2 410 or '410 Gone')"
  fi

  local lbl_remaining
  lbl_remaining="$(gh label list --repo "${TARGET_NWO}" --limit 300 --json description 2>&1 | python3 -c 'import json,sys; print(len([d for d in json.load(sys.stdin) if (d.get("description") or "")=="v11 pack-managed label"]))' 2>/dev/null)"
  note "  pack-managed labels remaining: ${lbl_remaining} (expect 0)"
}

# ----------------------------- main ------------------------------------------
main() {
  note "bd214-gh-issue-deletion.sh  (stamp ${STAMP})"
  note "target: ${TARGET_NWO}"
  note "mode  : $([ "$EXECUTE" -eq 1 ] && echo 'EXECUTE (real deletion)' || echo 'DRY-RUN (read-only, DEFAULT)')"

  preflight
  snapshot_issues
  snapshot_labels
  safety_gate
  preview

  note ""
  note "RECOMMENDATION: archive a copy of the manifest OUTSIDE /tmp before any"
  note "real run -- it is the ONLY audit artifact (a personal account logs no"
  note "issue-deletion event). Manifest: ${MANIFEST}"

  if [ "$EXECUTE" -ne 1 ]; then
    note ""
    hr
    note "DRY-RUN COMPLETE. Nothing was mutated. To execute the real deletion,"
    note "re-run with --execute and type the confirmation phrase when prompted."
    hr
    exit 0
  fi

  # --- gated destructive path ---
  note ""
  hr
  note "DESTRUCTIVE EXECUTION GATE"
  note "This will PERMANENTLY delete the issues + labels previewed above on"
  note "${TARGET_NWO}. There is no undo and no audit trail on a personal account."
  note "Type EXACTLY the following phrase to proceed, or anything else to abort:"
  note "  ${CONFIRM_PHRASE}"
  hr
  printf 'confirmation> '
  IFS= read -r typed
  [ "$typed" = "$CONFIRM_PHRASE" ] || die "confirmation phrase mismatch; aborted. Nothing deleted."

  delete_issues
  delete_labels
  verify_after

  note ""
  hr
  note "EXECUTE COMPLETE. Manifest (pre-delete snapshot) retained: ${MANIFEST}"
  note "Record a dated note on BD-214 with counts + manifest location."
  hr
}

main "$@"
```
