# IMPL-REPORT — BD-204 first-class dependency GraphQL shapes verified live

**Task:** rename-class fix. BD-204 rehearsal run 1 (live scratch-repo oracle)
failed at forward step-7 `link blocked-by: BD-907 -> BD-901` because the
BD-111 first-class GitHub issue-dependency GraphQL shapes were written from
offline research and live schema introspection (2026-06-10) disproved them.
Three corrections, semantics unchanged (directionality logic untouched):

1. `addBlockedBy` mutation argument: `blockedByIssueId` → `blockingIssueId`
2. `removeBlockedBy` mutation argument: same rename
3. Reverse read query field: `Issue.blockedByIssues` → `Issue.blockedBy`

Plus every echo of the old tokens in tests / fixtures / comments, with the
stale "unverified offline / flagged for confirmation" comment hedges updated
to LIVE-VERIFIED (schema introspection, 2026-06-10), keeping the
directionality-convention explanations.

---

## 1. Branch + final HEAD SHA

- Branch: `v11-dev`
- HEAD (unchanged — pack-coder does not commit): `08fd605606017374d6005de88e7b3b48432a79ca`

## 2. Pre-flight check output

```
$ git rev-parse HEAD && git status --short && git branch --show-current
08fd605606017374d6005de88e7b3b48432a79ca
(clean)
v11-dev
```

Baseline token measurement at start (the in-scope occurrence map the gate
later proves empty):

```
$ grep -rn "blockedByIssueId" scripts/ .github/
scripts/tests/tracker-provider-test.sh        → 10 hits (lines 344, 360, 371, 384, 392, 456, 468, 479, 493, 501)
scripts/tests/tracker-migrate-roundtrip-test.sh → 1 hit (line 239)
scripts/lib/tracker-provider-gh.sh            → 10 hits (lines 495, 530, 531, 539, 540, 578, 620, 621, 629, 630)

$ grep -rn "blockedByIssues" scripts/ .github/
scripts/tests/tracker-migrate-reverse-test.sh   → 1 hit (line 1020)
scripts/tests/tracker-migrate-roundtrip-test.sh → 5 hits (lines 220, 273, 286, 514, 518)
scripts/tests/fixtures/tracker-provider/gh-list-blocked-by.json → 1 hit (line 5)
scripts/lib/tracker-migrate-reverse.sh          → 7 hits (lines 373, 374, 421, 434, 439, 448, 613)
```

(No hits anywhere in `.github/`.)

Live schema re-verification (read-only introspection, run this session,
2026-06-10, authenticated `gh` — matches Pack Chat's ground-truth evidence):

```
$ gh api graphql -f query='{ a: __type(name: "AddBlockedByInput") { inputFields { name type {...} } }
                             b: __type(name: "RemoveBlockedByInput") { inputFields { name } } }'
a.inputFields: clientMutationId (String), issueId (ID!), blockingIssueId (ID!)
b.inputFields: clientMutationId, issueId, blockingIssueId

$ gh api graphql -f query='{ __type(name: "Issue") { fields { name args { name } } } }' | <filter block*>
blockedBy ['orderBy', 'after', 'before', 'first', 'last']   (NON_NULL IssueConnection)
blocking  (NON_NULL IssueConnection)
```

No live mutations of any kind were run — introspection `__type` queries only.

## 3. Per-task summary

| File | Delta | What landed |
|---|---|---|
| `scripts/lib/tracker-provider-gh.sh` | +26 / -35 | `addBlockedBy` + `removeBlockedBy` mutation strings and `-F` flags renamed `blockedByIssueId` → `blockingIssueId` (link + unlink paths); both header comment hedges rewritten from "unverified offline / flagged for confirmation at BD-088/BD-093" to LIVE-VERIFIED (schema introspection of `AddBlockedByInput` / `RemoveBlockedByInput`, 2026-06-10, BD-204); directionality-convention comments (operand inversion for `kind="blocks"`) preserved and re-tokened. |
| `scripts/lib/tracker-migrate-reverse.sh` | +15 / -19 | Reverse read query field `blockedByIssues` → `blockedBy` in the GraphQL query string, the jq extraction path (`.data.repository.issue.blockedBy.nodes`), the response-shape comment, and the `_tmr_decode_blockers` / `tracker_migrate_reverse_reconstruct` source-list comments; field-name hedge rewritten to LIVE-VERIFIED (`Issue.blockedBy` is an IssueConnection, same `nodes { number }` shape); 50-cap rationale preserved. |
| `scripts/tests/tracker-provider-test.sh` | +10 / -10 | Mock-log assertions 1.17a/b and 1.20a/b renamed to assert `blockingIssueId=NODE_NN`; comment blocks (gh invocation chains, directionality examples) re-tokened. |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | +6 / -6 | Stateful fake-gh parser arm `blockingIssueId=*`; reverse-read dispatch arm now matches `*"blockedBy(first"*` (kept distinct from the `addBlockedBy` / `removeBlockedBy` mutation arms, which match earlier in the elif chain anyway); fake response shape emits `blockedBy`; two comment blocks re-tokened. |
| `scripts/tests/tracker-migrate-reverse-test.sh` | +1 / -1 | Group 7.6 legacy-only fake-gh inline JSON response shape `blockedBy`. (Groups 7.3/7.5 read the shared fixture file, covered below.) |
| `scripts/tests/fixtures/tracker-provider/gh-list-blocked-by.json` | +1 / -1 | Response fixture key `blockedByIssues` → `blockedBy` (consumed by reverse-test 7.3/7.5 via `cat`). |

Note on the prompt's known-site list: the prompt named
`scripts/tests/fixtures/tracker-provider/gh-add-blocked-by.json` as a known
old-token site. It is NOT one — its content is only the `addBlockedBy`
mutation *response* (`{"data":{"addBlockedBy":{"issue":{"number":42}}}}`),
which contains neither old token and is correct as-is (the mutation name
`addBlockedBy` is live-verified unchanged). The actual fixture hit was in
`gh-list-blocked-by.json`. The gate (grep), not the list, was the contract,
per the prompt's own framing.

## 4. Unified diffs (modified files, vs. worktree base 08fd605)

```diff
diff --git a/scripts/lib/tracker-migrate-reverse.sh b/scripts/lib/tracker-migrate-reverse.sh
index db27395..6133dd1 100644
--- a/scripts/lib/tracker-migrate-reverse.sh
+++ b/scripts/lib/tracker-migrate-reverse.sh
@@ -370,19 +370,15 @@ PYEOF
 # back to comment-marker-only behavior, which is still strictly an
 # improvement over the pre-BD-111 state for legacy issues.
 #
-# GraphQL query — repository(owner, name).issue(number).blockedByIssues
-# (first: 50) { nodes { number } }. The field name `blockedByIssues`
-# is the symmetric guess paired with the `addBlockedBy` mutation
-# (EXTERNAL-RESEARCH §1.3 line 86) and the existing `subIssues` field
-# accessor used at `tracker_provider_gh_sub_issue_list:686` (which
-# pairs with the `addSubIssue` mutation). The cap of 50 matches the
-# documented per-relationship ceiling (EXTERNAL-RESEARCH §1.8 line
-# 188; capabilities.dependencies.per_relationship_ceiling=50). The
-# exact field name is unverified offline; flagged for confirmation
-# at BD-088 / BD-093 integration-test land-time same as the link /
-# unlink mutation names. If GH's actual field is named `blockedBy`
-# (no `Issues` suffix) or `blockingIssues`, the fix is one line in
-# the query string below plus one path in the jq filter.
+# GraphQL query — repository(owner, name).issue(number).blockedBy
+# (first: 50) { nodes { number } }. The field name `blockedBy` is
+# LIVE-VERIFIED (schema introspection of `Issue`, 2026-06-10, BD-204):
+# `Issue.blockedBy` is an IssueConnection (args orderBy/after/before/
+# first/last) — the same nodes { number } shape assumed here, pairing
+# with the `addBlockedBy` mutation the forward side writes. The cap
+# of 50 matches the documented per-relationship ceiling
+# (EXTERNAL-RESEARCH §1.8 line 188;
+# capabilities.dependencies.per_relationship_ceiling=50).
 #
 # Routes through `provider_raw "POST" "graphql" "$query"`; any backend
 # error (auth, network, schema-reshape) classifies via
@@ -418,7 +414,7 @@ _tmr_fetch_first_class_blocked_by() {
     # values are tracker-controlled (owner/repo from gh; number is
     # integer), so direct interpolation is safe.
     local query response
-    query='query { repository(owner: "'"$owner"'", name: "'"$repo"'") { issue(number: '"$issue_number"') { blockedByIssues(first: 50) { nodes { number } } } } }'
+    query='query { repository(owner: "'"$owner"'", name: "'"$repo"'") { issue(number: '"$issue_number"') { blockedBy(first: 50) { nodes { number } } } } }'
     # provider_raw routes through _gh_run → _gh_classify_error. We
     # swallow any error and fall back to []; the reverse decoder must
     # remain best-effort per the function header rationale.
@@ -431,12 +427,12 @@ _tmr_fetch_first_class_blocked_by() {
         return 0
     fi
     # Extract the issue numbers. A well-formed response is:
-    #   {"data": {"repository": {"issue": {"blockedByIssues": {"nodes": [{"number": N}, ...]}}}}}
+    #   {"data": {"repository": {"issue": {"blockedBy": {"nodes": [{"number": N}, ...]}}}}}
     # The jq filter is defensive against missing keys (`// empty`)
     # and emits the integer numbers as a JSON array. On parse failure,
     # echo [] (the // [] guard at the end).
     printf '%s' "$response" \
-        | jq -c '[.data.repository.issue.blockedByIssues.nodes[]?.number] // []' 2>/dev/null \
+        | jq -c '[.data.repository.issue.blockedBy.nodes[]?.number] // []' 2>/dev/null \
         || echo "[]"
 }
 
@@ -445,7 +441,7 @@ _tmr_fetch_first_class_blocked_by() {
 # is open-string); for v11.0 we combine three sources:
 #
 #   1. (NEW — BD-111 retrofit, PACK-REVIEW-BD-111 F1) First-class
-#      `blockedByIssues` GraphQL edges. Pre-fetched by the caller
+#      `blockedBy` GraphQL edges. Pre-fetched by the caller
 #      (typically `tracker_migrate_reverse_reconstruct`) via
 #      `_tmr_fetch_first_class_blocked_by` and passed in as a JSON
 #      array of gh-issue-numbers (arg 4). Post-BD-111 writes from
@@ -610,7 +606,7 @@ print(m.group(1) if m else "")')
     issue_number=$(printf  '%s' "$issue" | jq -r '.number // ""')
 
     # BD-111 retrofit (PACK-REVIEW-BD-111 F1, scope-extension second
-    # pass 2026-05-15): fetch first-class `blockedByIssues` GraphQL
+    # pass 2026-05-15): fetch first-class `blockedBy` GraphQL
     # edges so post-BD-111 forward writes round-trip through reverse.
     # Best-effort — empty array on any error (auth, network, schema-
     # reshape); the decoder still reads body comment markers as the
diff --git a/scripts/lib/tracker-provider-gh.sh b/scripts/lib/tracker-provider-gh.sh
index a701ae4..1e00293 100644
--- a/scripts/lib/tracker-provider-gh.sh
+++ b/scripts/lib/tracker-provider-gh.sh
@@ -491,17 +491,14 @@ tracker_provider_gh_set_milestone() {
 # Implementation per V1 §2.7.1 row 12:
 #   - blocks/blocked-by: first-class GitHub issue-dependency GraphQL
 #     mutation (BD-111; GA 2025-08-21 per EXTERNAL-RESEARCH §1.3).
-#     Mutation name `addBlockedBy` per EXTERNAL-RESEARCH §1.3; the
-#     argument shape (`issueId` + `blockedByIssueId`) follows the
-#     symmetric convention established by `addSubIssue` (issueId +
-#     subIssueId) elsewhere in this file. The exact argument key is
-#     unverified offline and is flagged for confirmation at BD-088
-#     or BD-093 integration-test land-time; if GH's actual schema
-#     names the second arg `blockedById` (or any other shape), the
-#     fix is one line in the mutation string below plus one fixture
-#     line update. `kind="blocks"` is expressed by inverting the
-#     operands (B blocked-by A == A blocks B) since EXTERNAL-RESEARCH
-#     names only the `addBlockedBy` direction.
+#     Mutation name `addBlockedBy` per EXTERNAL-RESEARCH §1.3. The
+#     argument shape (`issueId` + `blockingIssueId`) is LIVE-VERIFIED
+#     (schema introspection of `AddBlockedByInput`, 2026-06-10,
+#     BD-204): inputFields are `issueId: ID!` (the issue that IS
+#     blocked) + `blockingIssueId: ID!` (the issue that BLOCKS it),
+#     plus optional clientMutationId. `kind="blocks"` is expressed by
+#     inverting the operands (B blocked-by A == A blocks B) since
+#     EXTERNAL-RESEARCH names only the `addBlockedBy` direction.
 #   - related/duplicates: comment-based marker (no first-class API).
 #   - parent/child: delegates to sub_issue_create.
 #
@@ -527,8 +524,8 @@ tracker_provider_gh_link() {
             owner_repo=$(_gh_run gh repo view --json nameWithOwner --jq '.nameWithOwner') || return 1
             issue_node=$(_gh_run gh api "/repos/$owner_repo/issues/$id"       --jq '.node_id') || return 1
             other_node=$(_gh_run gh api "/repos/$owner_repo/issues/$other_id" --jq '.node_id') || return 1
-            # blocked-by: id is blocked by other_id  → addBlockedBy(issueId=id,       blockedByIssueId=other_id)
-            # blocks:     id blocks other_id          → addBlockedBy(issueId=other_id, blockedByIssueId=id)
+            # blocked-by: id is blocked by other_id  → addBlockedBy(issueId=id,       blockingIssueId=other_id)
+            # blocks:     id blocks other_id          → addBlockedBy(issueId=other_id, blockingIssueId=id)
             if [[ "$kind" == "blocked-by" ]]; then
                 source_node="$issue_node"
                 target_node="$other_node"
@@ -536,8 +533,8 @@ tracker_provider_gh_link() {
                 source_node="$other_node"
                 target_node="$issue_node"
             fi
-            query='mutation($issueId: ID!, $blockedByIssueId: ID!) { addBlockedBy(input: { issueId: $issueId, blockedByIssueId: $blockedByIssueId }) { issue { number } } }'
-            _gh_run gh api graphql -f "query=$query" -F "issueId=$source_node" -F "blockedByIssueId=$target_node" >/dev/null || return 1
+            query='mutation($issueId: ID!, $blockingIssueId: ID!) { addBlockedBy(input: { issueId: $issueId, blockingIssueId: $blockingIssueId }) { issue { number } } }'
+            _gh_run gh api graphql -f "query=$query" -F "issueId=$source_node" -F "blockingIssueId=$target_node" >/dev/null || return 1
             ;;
         related|duplicates)
             local body
@@ -567,22 +564,16 @@ tracker_provider_gh_link() {
 # Implementation per V1 §2.7.1 row 13 (BD-111 scope-extended
 # 2026-05-15 to include the symmetric `removeBlockedBy` unlink path):
 #   - blocks/blocked-by: first-class GitHub issue-dependency removal
-#     GraphQL mutation. Mutation name `removeBlockedBy` chosen as the
-#     symmetric pair to `addBlockedBy` (which EXTERNAL-RESEARCH §1.3
-#     line 86 names literally and pairs with "removal" generically;
-#     line 86: "GraphQL mutations including `addBlockedBy` / removal").
-#     The remove-side literal name is unverified offline (could be
-#     `removeBlockedBy`, `deleteBlockedBy`, or `removeBlockedByDependency`);
-#     `removeBlockedBy` is the most likely guess given GH's symmetric
-#     `addSubIssue` / `removeSubIssue` precedent already used in this
-#     file. Argument shape (`issueId` + `blockedByIssueId`) mirrors
-#     `addBlockedBy`. Operand inversion for `kind="blocks"` matches
-#     the link side: removing "B blocked-by A" is the same edge as
-#     removing "A blocks B". Verify against the live schema at
-#     BD-088 / BD-093 integration-test land-time; if either the
-#     mutation name or arg shape differs, the fix is one line in the
-#     mutation string below plus one fixture line update in
-#     `gh-remove-blocked-by.json`.
+#     GraphQL mutation. Mutation name `removeBlockedBy` (the symmetric
+#     pair of `addBlockedBy`, matching GH's `addSubIssue` /
+#     `removeSubIssue` precedent already used in this file) and the
+#     argument shape (`issueId` + `blockingIssueId`, mirroring
+#     `addBlockedBy`) are LIVE-VERIFIED (schema introspection of
+#     `RemoveBlockedByInput`, 2026-06-10, BD-204): inputFields are
+#     `issueId` + `blockingIssueId` plus optional clientMutationId.
+#     Operand inversion for `kind="blocks"` matches the link side:
+#     removing "B blocked-by A" is the same edge as removing
+#     "A blocks B".
 #   - parent/child: first-class via sub_issue_unlink (unchanged).
 #   - related/duplicates: still comment-based on the link side; surface
 #     a typed validation error here (callers remove the marker comment
@@ -617,8 +608,8 @@ tracker_provider_gh_unlink() {
             owner_repo=$(_gh_run gh repo view --json nameWithOwner --jq '.nameWithOwner') || return 1
             issue_node=$(_gh_run gh api "/repos/$owner_repo/issues/$id"       --jq '.node_id') || return 1
             other_node=$(_gh_run gh api "/repos/$owner_repo/issues/$other_id" --jq '.node_id') || return 1
-            # blocked-by: id no-longer blocked by other_id  → removeBlockedBy(issueId=id,       blockedByIssueId=other_id)
-            # blocks:     id no-longer blocks other_id       → removeBlockedBy(issueId=other_id, blockedByIssueId=id)
+            # blocked-by: id no-longer blocked by other_id  → removeBlockedBy(issueId=id,       blockingIssueId=other_id)
+            # blocks:     id no-longer blocks other_id       → removeBlockedBy(issueId=other_id, blockingIssueId=id)
             if [[ "$kind" == "blocked-by" ]]; then
                 source_node="$issue_node"
                 target_node="$other_node"
@@ -626,8 +617,8 @@ tracker_provider_gh_unlink() {
                 source_node="$other_node"
                 target_node="$issue_node"
             fi
-            query='mutation($issueId: ID!, $blockedByIssueId: ID!) { removeBlockedBy(input: { issueId: $issueId, blockedByIssueId: $blockedByIssueId }) { issue { number } } }'
-            _gh_run gh api graphql -f "query=$query" -F "issueId=$source_node" -F "blockedByIssueId=$target_node" >/dev/null || return 1
+            query='mutation($issueId: ID!, $blockingIssueId: ID!) { removeBlockedBy(input: { issueId: $issueId, blockingIssueId: $blockingIssueId }) { issue { number } } }'
+            _gh_run gh api graphql -f "query=$query" -F "issueId=$source_node" -F "blockingIssueId=$target_node" >/dev/null || return 1
             ;;
         related|duplicates)
             tracker_error_emit "validation" \
diff --git a/scripts/tests/fixtures/tracker-provider/gh-list-blocked-by.json b/scripts/tests/fixtures/tracker-provider/gh-list-blocked-by.json
index c8ce103..3bd64dd 100644
--- a/scripts/tests/fixtures/tracker-provider/gh-list-blocked-by.json
+++ b/scripts/tests/fixtures/tracker-provider/gh-list-blocked-by.json
@@ -2,7 +2,7 @@
   "data": {
     "repository": {
       "issue": {
-        "blockedByIssues": {
+        "blockedBy": {
           "nodes": [
             {"number": 43},
             {"number": 55}
diff --git a/scripts/tests/tracker-migrate-reverse-test.sh b/scripts/tests/tracker-migrate-reverse-test.sh
index cf21f83..28fe9d2 100755
--- a/scripts/tests/tracker-migrate-reverse-test.sh
+++ b/scripts/tests/tracker-migrate-reverse-test.sh
@@ -1017,7 +1017,7 @@ cat > "$FAKE_G76/gh" <<'FG76'
 # decoder falls through to body comment markers.
 case "$1 $2" in
     "repo view")   echo "fixture-org/fixture-repo" ;;
-    "api graphql") echo '{"data":{"repository":{"issue":{"blockedByIssues":{"nodes":[]}}}}}' ;;
+    "api graphql") echo '{"data":{"repository":{"issue":{"blockedBy":{"nodes":[]}}}}}' ;;
     *) ;;
 esac
 exit 0
diff --git a/scripts/tests/tracker-migrate-roundtrip-test.sh b/scripts/tests/tracker-migrate-roundtrip-test.sh
index 0f8f57a..18ab9dd 100755
--- a/scripts/tests/tracker-migrate-roundtrip-test.sh
+++ b/scripts/tests/tracker-migrate-roundtrip-test.sh
@@ -217,7 +217,7 @@ case "$1 $2" in
         # BD-111 retrofit (PACK-REVIEW-BD-111 F1, scope-extension second
         # pass 2026-05-15): the round-trip fake-gh now handles the
         # `addBlockedBy` mutation (forward write side) and the
-        # `blockedByIssues` query (reverse read side) so post-BD-111
+        # `blockedBy` query (reverse read side) so post-BD-111
         # forward writes round-trip through reverse correctly.
         #
         # Arg parse: walk argv looking for -f query=... and -F key=val.
@@ -236,7 +236,7 @@ case "$1 $2" in
                     shift 2 ;;
                 -F) case "$2" in
                         issueId=*)          f_issue_id="${2#issueId=}" ;;
-                        blockedByIssueId=*) f_blocked_by="${2#blockedByIssueId=}" ;;
+                        blockingIssueId=*)  f_blocked_by="${2#blockingIssueId=}" ;;
                         owner=*)            f_owner="${2#owner=}" ;;
                         repo=*)             f_repo="${2#repo=}" ;;
                         number=*)           f_number="${2#number=}" ;;
@@ -270,7 +270,7 @@ case "$1 $2" in
                 printf '%s' "$new_st" > "$STATE"
             fi
             echo '{"data":{"removeBlockedBy":{"issue":{"number":0}}}}'
-        elif [[ "$gquery" == *"blockedByIssues"* ]]; then
+        elif [[ "$gquery" == *"blockedBy(first"* ]]; then
             # Reverse read: query embeds owner/name/number directly via
             # shell interpolation (per _tmr_fetch_first_class_blocked_by).
             # Extract the issue number from the query string.
@@ -283,7 +283,7 @@ case "$1 $2" in
                 edges='[]'
             fi
             jq -nc --argjson nodes "$edges" \
-                '{data: {repository: {issue: {blockedByIssues: {nodes: $nodes}}}}}'
+                '{data: {repository: {issue: {blockedBy: {nodes: $nodes}}}}}'
         else
             echo "{}"
         fi
@@ -511,11 +511,11 @@ fi
 
 # Blockers — BD-111 closes the round-trip gap. With the BD-111 link
 # swap (forward writes addBlockedBy GraphQL edge) plus the BD-111
-# retrofit per PACK-REVIEW-BD-111 F1 (reverse reads blockedByIssues
+# retrofit per PACK-REVIEW-BD-111 F1 (reverse reads blockedBy
 # GraphQL edges in addition to body comment markers), the Blockers
 # field round-trips through forward → state → reverse. The stateful
 # fake-gh now records first_class_edges in state on addBlockedBy and
-# serves them on blockedByIssues; the reverse decoder folds them
+# serves them on blockedBy; the reverse decoder folds them
 # into the Blockers list per scripts/lib/tracker-migrate-reverse.sh
 # `_tmr_fetch_first_class_blocked_by` + `_tmr_decode_blockers`.
 bd002_block_line=$(printf '%s' "$RECON_BACKLOG" | grep -A 3 "BD-002" | grep "Blockers:")
diff --git a/scripts/tests/tracker-provider-test.sh b/scripts/tests/tracker-provider-test.sh
index 98e679c..b1a8ead 100755
--- a/scripts/tests/tracker-provider-test.sh
+++ b/scripts/tests/tracker-provider-test.sh
@@ -341,7 +341,7 @@ assert_eq "1.16 set_milestone v11.1" "v11.1" "$(printf '%s' "$out" | jq -r '.mil
 #   1. gh repo view --json nameWithOwner --jq .nameWithOwner   → "owner/repo"
 #   2. gh api /repos/owner/repo/issues/42 --jq .node_id        → "NODE_42"
 #   3. gh api /repos/owner/repo/issues/99 --jq .node_id        → "NODE_99"
-#   4. gh api graphql -f query=... -F issueId=... -F blockedByIssueId=...
+#   4. gh api graphql -f query=... -F issueId=... -F blockingIssueId=...
 #      → addBlockedBy response fixture
 # The dispatch-dir fake-gh mode (set FAKE_GH_DISPATCH_DIR) supplies
 # different stdout per invocation by inspecting argv. The FAKE_GH_LOG
@@ -357,7 +357,7 @@ export FAKE_GH_DISPATCH_DIR="$LINK_DISPATCH_DIR"
 log=$(mktemp -t prov-link-log.XXXXXX); export FAKE_GH_LOG="$log"
 
 # 1.17a kind=blocked-by — id 42 is blocked by 99 →
-#       addBlockedBy(issueId=NODE_42, blockedByIssueId=NODE_99)
+#       addBlockedBy(issueId=NODE_42, blockingIssueId=NODE_99)
 : > "$log"
 out=$(provider_link 42 99 blocked-by)
 assert_eq "1.17a link kind=blocked-by"  "blocked-by" "$(printf '%s' "$out" | jq -r '.kind')"
@@ -368,7 +368,7 @@ assert_contains "1.17a resolves issue 42 node-id"      "$log_contents" "/repos/o
 assert_contains "1.17a resolves issue 99 node-id"      "$log_contents" "/repos/optiquity/pack/issues/99"
 assert_contains "1.17a invokes graphql addBlockedBy"   "$log_contents" "addBlockedBy"
 assert_contains "1.17a issueId=NODE_42 (blocked-by)"   "$log_contents" "issueId=NODE_42"
-assert_contains "1.17a blockedByIssueId=NODE_99"       "$log_contents" "blockedByIssueId=NODE_99"
+assert_contains "1.17a blockingIssueId=NODE_99"        "$log_contents" "blockingIssueId=NODE_99"
 # (PACK-REVIEW-BD-111 F7: a former positive `assert_contains
 # "graphql"` line was removed from here — it was redundant with the
 # `addBlockedBy` check above and the negative if/grep block below
@@ -381,7 +381,7 @@ else
 fi
 
 # 1.17b kind=blocks — operands invert: 42 blocks 99 →
-#       addBlockedBy(issueId=NODE_99, blockedByIssueId=NODE_42)
+#       addBlockedBy(issueId=NODE_99, blockingIssueId=NODE_42)
 : > "$log"
 out=$(provider_link 42 99 blocks)
 assert_eq "1.17b link kind=blocks"  "blocks" "$(printf '%s' "$out" | jq -r '.kind')"
@@ -389,7 +389,7 @@ assert_eq "1.17b link linked_to=99" "99"     "$(printf '%s' "$out" | jq -r '.lin
 log_contents=$(cat "$log")
 assert_contains "1.17b invokes graphql addBlockedBy" "$log_contents" "addBlockedBy"
 assert_contains "1.17b issueId=NODE_99 (inverted)"   "$log_contents" "issueId=NODE_99"
-assert_contains "1.17b blockedByIssueId=NODE_42"     "$log_contents" "blockedByIssueId=NODE_42"
+assert_contains "1.17b blockingIssueId=NODE_42"      "$log_contents" "blockingIssueId=NODE_42"
 
 # 1.17c EMU FORBIDDEN error path. PACK-REVIEW-BD-111 F6: this test
 # does NOT specifically isolate the api-graphql step — `FAKE_GH_EXIT`
@@ -453,7 +453,7 @@ assert_contains "1.19 unlink duplicates → validation (comment-based)" "$err" "
 #   1. gh repo view --json nameWithOwner --jq .nameWithOwner   → "owner/repo"
 #   2. gh api /repos/owner/repo/issues/42 --jq .node_id        → "NODE_42"
 #   3. gh api /repos/owner/repo/issues/99 --jq .node_id        → "NODE_99"
-#   4. gh api graphql -f query=... -F issueId=... -F blockedByIssueId=...
+#   4. gh api graphql -f query=... -F issueId=... -F blockingIssueId=...
 #      → removeBlockedBy response fixture (gh-remove-blocked-by.json)
 reset_fake_gh
 UNLINK_DISPATCH_DIR=$(mktemp -d -t prov-unlink-dispatch.XXXXXX)
@@ -465,7 +465,7 @@ export FAKE_GH_DISPATCH_DIR="$UNLINK_DISPATCH_DIR"
 log=$(mktemp -t prov-unlink-log.XXXXXX); export FAKE_GH_LOG="$log"
 
 # 1.20a kind=blocked-by — id 42 no-longer blocked by 99 →
-#       removeBlockedBy(issueId=NODE_42, blockedByIssueId=NODE_99)
+#       removeBlockedBy(issueId=NODE_42, blockingIssueId=NODE_99)
 : > "$log"
 out=$(provider_unlink 42 99 blocked-by)
 assert_eq "1.20a unlink kind=blocked-by"     "blocked-by" "$(printf '%s' "$out" | jq -r '.kind')"
@@ -476,7 +476,7 @@ assert_contains "1.20a resolves issue 42 node-id"        "$log_contents" "/repos
 assert_contains "1.20a resolves issue 99 node-id"        "$log_contents" "/repos/optiquity/pack/issues/99"
 assert_contains "1.20a invokes graphql removeBlockedBy"  "$log_contents" "removeBlockedBy"
 assert_contains "1.20a issueId=NODE_42 (blocked-by)"     "$log_contents" "issueId=NODE_42"
-assert_contains "1.20a blockedByIssueId=NODE_99"         "$log_contents" "blockedByIssueId=NODE_99"
+assert_contains "1.20a blockingIssueId=NODE_99"          "$log_contents" "blockingIssueId=NODE_99"
 # Negative: must NOT invoke addBlockedBy nor any comment-write path.
 if printf '%s' "$log_contents" | grep -q "addBlockedBy"; then
     t_fail "1.20a should not invoke addBlockedBy on unlink" "log: ${log_contents:0:200}"
@@ -490,7 +490,7 @@ else
 fi
 
 # 1.20b kind=blocks — operands invert: 42 no-longer blocks 99 →
-#       removeBlockedBy(issueId=NODE_99, blockedByIssueId=NODE_42)
+#       removeBlockedBy(issueId=NODE_99, blockingIssueId=NODE_42)
 : > "$log"
 out=$(provider_unlink 42 99 blocks)
 assert_eq "1.20b unlink kind=blocks"          "blocks" "$(printf '%s' "$out" | jq -r '.kind')"
@@ -498,7 +498,7 @@ assert_eq "1.20b unlink unlinked_from=99"     "99"     "$(printf '%s' "$out" | j
 log_contents=$(cat "$log")
 assert_contains "1.20b invokes graphql removeBlockedBy" "$log_contents" "removeBlockedBy"
 assert_contains "1.20b issueId=NODE_99 (inverted)"      "$log_contents" "issueId=NODE_99"
-assert_contains "1.20b blockedByIssueId=NODE_42"        "$log_contents" "blockedByIssueId=NODE_42"
+assert_contains "1.20b blockingIssueId=NODE_42"         "$log_contents" "blockingIssueId=NODE_42"
 
 # 1.20c missing-edge / not-found error path. Same caveat as 1.17c
 # (PACK-REVIEW-BD-111 F6): `FAKE_GH_EXIT` is global, so the chain
```

## 5. Verification output

### 5.1 Grep-zero completeness gate (rename-measure-then-bound; the contract)

Run at PREFLIGHT time, after all edits:

```
$ grep -rn "blockedByIssueId" scripts/ .github/
(no output)
exit=1

$ grep -rn "blockedByIssues" scripts/ .github/
(no output)
exit=1
```

ZERO hits for both old tokens across the entire in-scope file set.
No allowlist needed (none was expected).

Repo-wide read-only sweep outside the gate scope (for Pack Chat awareness;
NOT edited — see section 7 POQ-1):

```
$ grep -rln "blockedByIssueId\|blockedByIssues" . --exclude-dir=.git
backlog/BD-111.md
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-111.md
```

### 5.2 Syntax checks

```
$ bash -n <each edited script>
SYNTAX OK: scripts/lib/tracker-provider-gh.sh
SYNTAX OK: scripts/lib/tracker-migrate-reverse.sh
SYNTAX OK: scripts/tests/tracker-provider-test.sh
SYNTAX OK: scripts/tests/tracker-migrate-roundtrip-test.sh
SYNTAX OK: scripts/tests/tracker-migrate-reverse-test.sh
$ jq . scripts/tests/fixtures/tracker-provider/gh-list-blocked-by.json
JSON OK: gh-list-blocked-by.json
```

### 5.3 Directly affected mock suites (renamed assertions green)

```
$ bash scripts/tests/tracker-provider-test.sh          → Passed: 127  Failed: 0  rc=0
$ bash scripts/tests/tracker-migrate-reverse-test.sh   → Passed: 133  Failed: 0  rc=0
$ bash scripts/tests/tracker-migrate-forward-test.sh   → Passed: 181  Failed: 0  rc=0
$ bash scripts/tests/tracker-migrate-roundtrip-test.sh → Passed: 51   Failed: 0  rc=0
```

### 5.4 validate-pack (PyYAML native), normal + DEEP

```
$ python3 scripts/validate-pack.py                      → PASSED — all checks clean (rc=0)
$ PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py → PASSED — all checks clean (rc=0)
```

### 5.5 Full unattended CI battery (per `.github/workflows/validate-pack.yml` tests job)

Every battery step run locally; all rc=0:

```
scripts/test-detect.sh                                  rc=0  === Results: 100 passed, 0 failed ===
scripts/tests/tracker-provider-test.sh                  rc=0  Passed: 127 (run in 5.3)
scripts/tests/tracker-config-test.sh                    rc=0  Passed: 32
scripts/tests/tracker-init-test.sh                      rc=0  Passed: 95
scripts/tests/tracker-agent-read-test.sh                rc=0  Passed: 57
scripts/tests/tracker-migrate-forward-test.sh           rc=0  Passed: 181 (run in 5.3)
scripts/tests/tracker-migrate-reverse-test.sh           rc=0  Passed: 133 (run in 5.3)
scripts/tests/tracker-migrate-roundtrip-test.sh         rc=0  Passed: 51 (run in 5.3)
scripts/tests/test-tracker-phase-task.sh                rc=0  Passed: 100
scripts/tests/test-tracker-links.sh                     rc=0  Passed: 43
scripts/tests/test-tracker-cycle-check.sh               rc=0  Passed: 26
scripts/tests/tracker-errors-test.sh                    rc=0  Passed: 60
scripts/tests/tracker-config-schema-test.sh             rc=0  (all pass)
scripts/tests/recommendation-state-schema-test.sh       rc=0  (all pass)
scripts/tests/test-per-entry.sh                         rc=0  (all pass)
scripts/tests/test-validate-pack-checks-32-33-34.sh     rc=0  (all pass)
scripts/tests/test-validate-pack-checks-36-37-38.sh     rc=0  All tests passed.
scripts/tests/test-validate-pack-check-39.sh            rc=0  All tests passed.
scripts/tests/test-validate-pack-check-40.sh            rc=0  All tests passed.
scripts/tests/test-validate-pack-check-41.sh            rc=0  All tests passed.
scripts/tests/test-validate-pack-check-18.sh            rc=0  All tests passed.
scripts/tests/test-validate-pack-check-16.sh            rc=0  All tests passed.
scripts/tests/test-validate-pack-check-19.sh            rc=0  All tests passed.
scripts/tests/test-validate-pack-check-42.sh            rc=0  All tests passed.
scripts/tests/test-validate-pack-check-43.sh            rc=0  All tests passed.
scripts/tests/test-validate-pack-check-44.sh            rc=0  All tests passed.
scripts/tests/test-validate-pack-check-45.sh            rc=0  All tests passed.
scripts/tests/test-validate-pack-check-46.sh            rc=0  All tests passed.
scripts/tests/test-validate-pack-check-removed-doc-advisory.sh rc=0  All tests passed.
scripts/tests/test-validate-pack-check-49-field-faithfulness.sh rc=0  All tests passed.
scripts/tests/tracker-bd129-gh-repo-test.sh             rc=0  === Results: 14 passed, 0 failed ===
scripts/tests/tracker-bd130-doctor-wired-test.sh        rc=0  === Results: 24 passed, 0 failed ===
scripts/tests/tracker-bd132-race-test.sh                rc=0  === Results: 29 passed, 0 failed ===
scripts/tests/tracker-bd133-header-preservation-test.sh rc=0  All tests passed.
scripts/tests/tracker-bd134-close-retry-test.sh         rc=0  === Results: 24 passed, 0 failed ===
scripts/tests/recommendation-test.sh                    rc=0  All tests passed.
scripts/tests/pack-help-test.sh                         rc=0  All tests passed.
scripts/tests/test-customization-preserve.sh            rc=0  All tests passed.
scripts/tests/test-init-project.sh                      rc=0  All tests passed.
scripts/tests/test-migrate-v10-to-v11.sh                rc=0  All tests passed.
scripts/tests/test-migrate-v10-to-v11-dry-run.sh        rc=0  All BD-095 tests passed.
scripts/tests/test-migrate-v10-to-v11-gates.sh          rc=0  All BD-101 gate tests passed.
scripts/tests/test-migrate-v10-to-v11-decompose.sh      rc=0  All BD-165 decompose tests passed.
scripts/test-migrator-core.sh                           rc=0  === Results: 19 passed, 0 failed ===
scripts/test-migrator-manifest.sh                       rc=0  === Results: 12 passed, 0 failed ===
scripts/test-migrator-capability-translation.sh         rc=0  === Results: 12 passed, 0 failed ===
scripts/test-migrator-skills.sh                         rc=0  === Results: 19 passed, 0 failed ===
scripts/test-persona-contracts.sh                       rc=0  (all pass)
scripts/tests/template-translations-test.sh             rc=0  All tests passed.
scripts/tests/template-version-test.sh                  rc=0  All tests passed.
scripts/tests/test-issue-forms.sh                       rc=0  All tests passed.
scripts/tests/test-v11-realistic-ot.sh                  rc=0  PASS: 33 / FAIL: 0 — All v11-realistic-ot integration tests PASSED (33/33).
```

Live oracle stays default-SKIP (constraint honored; never run live):

```
$ bash scripts/tests/tracker-bd204-lossless-roundtrip-test.sh
SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)
rc=0
```

### 5.6 Fixture manifest (regenerate-manifest-v11-surface)

This fix touches `scripts/` (v11-surface trigger), so the rebuild was run:

```
$ bash test-fixtures/build.sh --all --clean
manifest written: .../test-fixtures/manifest.txt
build rc=0

$ git diff test-fixtures/manifest.txt
(empty — no drift)

$ bash test-fixtures/build.sh --verify
  v11-realistic-ot OK: ae3fc6ff4956e365cba79699c724dce94559509c
  v11-flat-file OK: f9705c2740f8788a486b1a90bcf9448b57c04391
  v11-tracker-on OK: 944ddee3108ce3634327b8b6ee105cb0cd825e5a
  existing-project-mid-dev OK: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
verify rc=0
```

Per the rule's canonical-authority clause: the post-rebuild manifest diff is
EMPTY, so the manifest is NOT part of this change (the edited files —
tracker libs under `scripts/lib/` and tests/fixtures under `scripts/tests/`
— are not among the fixture-copied client-install set; the trigger globs
fired the rebuild, the empty diff is the final authority). Command evidence
above.

## 6. Plan deviations

1. **`gh-add-blocked-by.json` not edited** (prompt's known-site list named
   it). Its content carries neither old token — only the `addBlockedBy`
   response, which is live-verified correct. The actual fixture rename
   landed in `gh-list-blocked-by.json`. The prompt itself made the grep the
   gate, not the list; gate is ZERO-clean. Not a behavioral deviation.
2. **Roundtrip fake-gh dispatch arm pattern** changed from
   `*"blockedByIssues"*` to `*"blockedBy(first"*` rather than bare
   `*"blockedBy"*`. Rationale: the bare token is a substring-overlap hazard
   class (the elif ordering already protects against the mutation strings,
   which carry capital-B `BlockedBy`, but `(first` anchors the match to the
   reverse-read query unambiguously and keeps the arm order-independent).
   Same recognized query, zero semantic change.

No other deviations; directionality logic is byte-identical (only token
names and comment hedges changed, per the diff in section 4).

## 7. POQs introduced

- **POQ-1 — out-of-scope historical references to the disproven shapes.**
  `backlog/BD-111.md` and
  `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-111.md`
  still contain `blockedByIssueId` / `blockedByIssues` strings.
  Disposition: ESCALATED to Pack Chat (both are outside this fix's gate
  scope: the backlog tree is pack-chat-only; the BD-111 IMPL-REPORT is a
  point-in-time historical record that arguably should stay as-written).
  Recommended default: leave the historical IMPL-REPORT untouched; Pack
  Chat decides whether BD-111's backlog entry warrants a one-line
  "superseded by BD-204 live verification" annotation.

## 8. Definition-of-Done checklist

| Item | Result | Evidence |
|---|---|---|
| `addBlockedBy` arg renamed to `blockingIssueId` (mutation string + `-F` flag + comments) | PASS | section 4 diff, `scripts/lib/tracker-provider-gh.sh` link path |
| `removeBlockedBy` arg renamed (same file, unlink path) | PASS | section 4 diff, unlink path |
| Reverse read field `blockedByIssues` → `blockedBy` (query + jq path + comments) | PASS | section 4 diff, `scripts/lib/tracker-migrate-reverse.sh` |
| Every echo in tests/fixtures/comments renamed | PASS | grep-zero gate, section 5.1 (0 hits both tokens) |
| Grep-ZERO gate quoted in PREFLIGHT + report | PASS | PREFLIGHT line (chat) + section 5.1 |
| Hedge comments updated to LIVE-VERIFIED, directionality explanation kept | PASS | section 4 diff (3 comment blocks) |
| Semantics unchanged (directionality logic as-is) | PASS | diff shows only token/comment changes in code paths; operand-inversion blocks intact |
| pack-only (no project-template/ or client-asset edits) | PASS | `git status --short` = 6 files, all under `scripts/` (+ this report under `maintenance-docs/`) |
| NO live GitHub mutations | PASS | only `__type` introspection queries run (section 2); oracle confirmed default-SKIP (section 5.5) |
| Targeted in-place edits, no full rewrites | PASS | all changes via targeted Edit calls; diff in section 4 shows untouched text byte-stable |
| Mock suites green with renamed assertions | PASS | section 5.3 (127/133/181/51, 0 failed) |
| Full CI battery green | PASS | sections 5.4-5.5 (validate-pack normal+DEEP PASSED; 47 battery suites rc=0; realistic-ot 33/33) |
| Manifest handled per v11-surface rule | PASS | section 5.6 (rebuild run; diff empty; verify rc=0) |
| No state-changing git verbs | PASS | only `rev-parse`/`status`/`diff`/`branch --show-current` run |

## 9. Proposed commit message

```
fix: v11 — BD-204 first-class dependency GraphQL shapes verified live (blockingIssueId + blockedBy) (pack-only)
```

(Check 36 note: all touched paths are under `scripts/` + this report under
`maintenance-docs/` — the `pack-only` keyword claim holds: nothing under
`project-template/` or `supporting-docs/`.)

## 10. Boundary discipline check (P-missed-7)

No project-side files were edited or scoped. All six edits live under
`scripts/` (pack-side per the `boundary-investigation` skill's "does NOT
apply" list: `scripts/`, `test-fixtures/`, `maintenance-docs/` are
pack-only surfaces). No pack-only reference was added to any project-side
surface; no boundary stop triggered. No SSOT investigation required for
pack-side-only edits — recorded here for the required-section contract.

## 11. Read-in-full attestation (agents-read-rule-docs-in-full)

| File | Lines | Read |
|---|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` (incl. full `## Pack memory`) | 579 | in full (system-context full text + disk spot-verification of §Pack memory) |
| `~/.claude/projects/.../memory/feedback_rename_plans_measure_then_bound.md` | 43 | in full |
| `~/.claude/projects/.../memory/feedback_verify_full_ci_suite.md` | 42 | in full |
| `~/.claude/projects/.../memory/feedback_edit_in_place_not_full_rewrite.md` | 14 | in full |
| `~/.claude/projects/.../memory/feedback_manifest_regen_on_v11_surface.md` | 15 | in full |
| `~/.claude/projects/.../memory/feedback_agent_output_rules_applied_block.md` | 14 | in full |

Conditional MUST-READ pointers followed:
`pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block`
(lines 206-233) and § `regenerate-manifest-v11-surface` (lines 479-533)
read before constructing this block / running the manifest step. Also read:
`pack-ops/PACK-AGENTS.md` (223 lines), `/backlog/_rules.md` (94),
`/changelog/_rules.md` (66), and skills `implementation-report`,
`verification-harness`, `commit-discipline`, `boundary-investigation`
(each in full).

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Git verbs run this session: `rev-parse HEAD`, `status --short`, `branch --show-current`, `diff`, `diff --stat`. Zero state-changing verbs; deliverable = 6 working-tree edits + this report. `git status --short` (section 5.6 era) shows ` M` (unstaged) for all 6 files — nothing staged. | COMPLIANT |
| per-action-approval-sub-agents | No `rm -rf` on trusted paths, no `git rm`, no trusted-file overwrite. Only `rm -f` on self-created `/tmp` scratch (`/tmp/bd204-rename-diff.txt` retained; report-build tempfile removed). No destructive op surfaced as needed. | COMPLIANT |
| preflight-stop-means-stop | PREFLIGHT line emitted in-chat before this report's first Write: "PREFLIGHT: 6/6 in-scope file edits complete; grep-zero gate PASS; verification PASS; HEAD 08fd605...; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-GH-DEP-SHAPES.md". No parent stop message received. | COMPLIANT |
| agent-output-rules-applied-block | This block, per-rule with quoted evidence; format per `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block (read this session, lines 206-233). | COMPLIANT |
| agents-read-rule-docs-in-full | Section 11 table: 6 named docs read in full with line counts (579/43/42/14/15/14), plus conditional rationale sections and the 4 skills + 3 standing docs. | COMPLIANT |
| rename-measure-then-bound | Gate: `grep -rn "blockedByIssueId" scripts/ .github/` → 0 hits (exit=1); `grep -rn "blockedByIssues" scripts/ .github/` → 0 hits (exit=1). Quoted in PREFLIGHT and section 5.1. Baseline measurement (34 hits across 6 files) in section 2; allowlist empty as expected. | COMPLIANT |
| verify-full-ci-suite | `python3 scripts/validate-pack.py` → "PASSED — all checks clean" (normal + `PACK_VALIDATE_DEEP=1`); all 47 unattended battery suites from `.github/workflows/validate-pack.yml` run locally, all rc=0 (section 5.5 table, incl. `test-v11-realistic-ot.sh` 33/33); affected mock suites 127/133/181/51 passed, 0 failed; live oracle default-SKIP confirmed (`SKIP: live-GH oracle ...`, rc=0). | COMPLIANT |
| regenerate-manifest-v11-surface | `bash test-fixtures/build.sh --all --clean` → rc=0, "manifest written"; `git diff test-fixtures/manifest.txt` → EMPTY; `build.sh --verify` → all fixture rows OK, rc=0. Per the rule's canonical-authority clause, empty diff = manifest not part of this change (evidence in section 5.6). | COMPLIANT |
| edit-in-place-not-full-rewrite | All 6 files changed via targeted Edit calls (no Write to any source file); section 4 unified diff confirms untouched regions byte-stable (e.g., `tracker-provider-gh.sh` 61-line diff in a ~700-line file); edited regions re-read via `git diff` review of the full 356-line diff. | COMPLIANT |
| pack-only | End-state `git status --short`: 6 ` M` entries, all under `scripts/`; plus this report under `maintenance-docs/v11-implementation/`. Nothing under `project-template/` or `supporting-docs/`; fixture manifest unchanged. | COMPLIANT |
| scope-deliverables-to-the-ask | Diff = token renames + the 3 hedge-comment LIVE-VERIFIED updates only; no refactors, no opportunistic edits (out-of-scope historical hits escalated as POQ-1 instead of edited). 6 files, +59/-72 lines total. | COMPLIANT |
