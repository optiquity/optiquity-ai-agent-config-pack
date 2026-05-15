# IMPLEMENTATION REPORT — BD-111 (Switch blocks/blocked-by from comment-marker to first-class GH dependency API)

**Branch:** `v11-dev`
**Pre-flight HEAD (initial coder session):** `4a2d7cc` (per first prompt) — actual HEAD when initial session started: `8409153` (Pack Chat advanced the branch with two docs commits between when the first prompt was drafted and when the coder started). No state-changing git verb run by coder.
**Pre-flight HEAD (scope-extension follow-up session):** `eca769b` (PM-only commit that extended BD-111 scope to include `tracker_provider_gh_unlink()` symmetric `removeBlockedBy` path; see "Note on scope extension" below).
**Final working-tree HEAD (pre-impl-commit):** `eca769b` (unchanged; coder edits uncommitted in working tree as required).
**Plan deviations:** zero. The original §9 item 1 (unlink follow-up) was promoted into in-scope work via PM commit `eca769b` and shipped in this same session; see §9 update below.

> **Note on report authorship:** This report was authored by Pack Chat from the BD-111 coder's final message content (the coder declined to write the .md file directly per their own system prompt, but produced the structured report inline). Content is the coder's; formatting is preserved. **Scope-extension follow-up (§§ updated 2026-05-15):** the coder authored the §1 / §2 / §3 / §6 / §7 / §9 / DoD updates directly via Edit calls into this file in the follow-up session, after Pack Chat (a) wrote the original report from the coder's first-pass message and (b) extended BD-111 scope via PM-only commit `eca769b`.

> **Note on scope extension (2026-05-15).** PM-only commit `eca769b` extended BD-111's BACKLOG `File/Symbol` field to include the symmetric `removeBlockedBy` unlink path. Per pack rule "BDs are reserved for new scope / new feature / new architecture," `removeBlockedBy` is the symmetric pair of `addBlockedBy` (same API surface; same files; same integration-test verification ask), not new architecture. Splitting one feature across two BDs would violate "composition over special cases." The link/unlink asymmetry the coder flagged in the first-pass §9 item 1 was the right find — the right resolution was extend-in-session, not new-BD. The `removeBlockedBy` work shipped in this same coder session under unchanged BD-111.

---

## §1 Files modified / created

Combined inventory after the scope-extension follow-up:

| Path | Change | Diff stats (cumulative across both passes) |
|------|--------|------------|
| `scripts/lib/tracker-provider-gh.sh` | modified | +101 / -22 (net +79 lines; covers `tracker_provider_gh_link()` + `tracker_provider_gh_unlink()` first-class swap and the `_gh_classify_error` `FORBIDDEN` patch) |
| `scripts/tests/tracker-provider-test.sh` | modified | +233 / -19 (net +214 lines; includes new dispatch-mode harness, test 1.17a-e link suite, test 1.20a-c unlink suite, 1.19 retarget to related/duplicates, and renumber of 1.20→1.21 / 1.21→1.22 / 1.22→1.23) |
| `scripts/tests/fixtures/tracker-provider/gh-add-blocked-by.json` | new | +9 lines |
| `scripts/tests/fixtures/tracker-provider/gh-remove-blocked-by.json` | new | +9 lines (scope-extension follow-up; mirrors the addBlockedBy fixture for the removeBlockedBy happy path) |

`git diff --stat` (working tree, vs `HEAD=eca769b`):

```
 scripts/lib/tracker-provider-gh.sh     | 111 +++++++++++++--
 scripts/tests/tracker-provider-test.sh | 246 ++++++++++++++++++++++++++++++---
 2 files changed, 327 insertions(+), 30 deletions(-)
```

(plus two new untracked fixture files `gh-add-blocked-by.json` + `gh-remove-blocked-by.json`; total 4 paths.)

---

## §2 GraphQL mutation: name + args + evidence basis (call-outs 1, 2)

**Mutation name:** `addBlockedBy`

**Evidence basis (high confidence on name, medium-high on arg shape):**

- `EXTERNAL-RESEARCH.md` §1.5 line 86: *"GraphQL mutations including `addBlockedBy` / removal; full webhook events."* — names the mutation literally.
- `EXTERNAL-RESEARCH.md` §1.5 line 87: *"EMU users can hit `FORBIDDEN: Unauthorized; path: addBlockedBy` for cross-enterprise links."* — corroborates the literal name appears in error responses.
- GitHub Changelog 2025-08-21 *"Dependencies on issues"* (cited at line 80) — GA reference.

**Argument shape used:** `addBlockedBy(input: { issueId: <ID>, blockedByIssueId: <ID> }) { issue { number } }`

- `issueId` follows GH's universal mutation-arg convention (used by `addSubIssue`/`removeSubIssue` already present in this file at lines 581, 621 — both take an `issueId: ID!`).
- `blockedByIssueId` is the symmetric analog of `addSubIssue`'s `subIssueId`. GH GraphQL favors full-noun + `Id` suffix; the alternative would be `blockedById` (shorter form). Coder chose the longer form because (a) it matches the existing `subIssueId` pattern in this file, and (b) GH GraphQL types historically lean to descriptive naming. Confidence: medium-high — but the wrong-guess fix is one line at line 527 in `tracker-provider-gh.sh` plus one key in the test 1.17a/1.17b assertion strings.

**Direction handling.** EXTERNAL-RESEARCH names only the `addBlockedBy` direction. There is no documented `addBlocking` mutation, so `kind="blocks"` (A blocks B) is expressed by inverting the operands — the same edge as B blocked-by A. The case statement at lines 520-526 swaps the source/target node-ids accordingly. The public `provider_link()` shape (id, other_id, kind triple) is preserved; only the internal mutation invocation differs.

**Confidence summary:**

| Aspect | Confidence | Worst-case fix |
|--------|------------|----------------|
| Mutation name `addBlockedBy` | High (literal in EXTERNAL-RESEARCH §1.5) | n/a |
| Arg key `issueId` | High (universal GH convention) | n/a |
| Arg key `blockedByIssueId` | Medium-high (symmetric with `subIssueId`) | one-line edit at `tracker-provider-gh.sh:527` + two test-assertion key updates |
| Operand inversion for `blocks` | High (only documented direction) | n/a |
| Selection set `{ issue { number } }` | Medium (we discard the result) | the response is discarded; even if GH's actual selection differs, the existing `_gh_run` will still succeed (gh's GraphQL mode returns the JSON verbatim; we don't parse it on success) |

### §2 follow-up — `removeBlockedBy` (scope extension 2026-05-15)

**Mutation name:** `removeBlockedBy`

**Evidence basis (medium-high on name, medium-high on arg shape — both lower than the `addBlockedBy` side because EXTERNAL-RESEARCH does not name the remove-side literal):**

- `EXTERNAL-RESEARCH.md` §1.5 line 86: *"GraphQL mutations including `addBlockedBy` / removal; full webhook events."* — names the *add* side literally and pairs it with "removal" generically (no literal name for the remove-side mutation).
- GH GraphQL precedent in this same file: `addSubIssue` / `removeSubIssue` use the symmetric `add` / `remove` verb prefix. By analogy, `addBlockedBy` → `removeBlockedBy` is the most likely literal name. Alternatives a live-schema verification could surface include `deleteBlockedBy` (less common in GH GraphQL but possible) or `removeBlockedByDependency` (verbose form, also less common).
- The pre-existing `_gh_classify_error` `forbidden`/`Forbidden`/`FORBIDDEN` pattern at line 69 will catch the EMU `FORBIDDEN: Unauthorized; path: removeBlockedBy` form (same wire shape as `addBlockedBy`) without further changes.

**Argument shape used:** `removeBlockedBy(input: { issueId: <ID>, blockedByIssueId: <ID> }) { issue { number } }`

- Mirrors `addBlockedBy` exactly. Same `issueId` + `blockedByIssueId` pair. Same selection set. The presumption is that GitHub designed the remove-side mutation as a structural symmetric pair.

**Operand inversion for `kind="blocks"`** — same convention as the link side: removing "B blocked-by A" is the same edge as removing "A blocks B" — so `kind="blocks"` swaps the source/target node-ids before invoking `removeBlockedBy`.

**Confidence summary (remove side):**

| Aspect | Confidence | Worst-case fix |
|--------|------------|----------------|
| Mutation name `removeBlockedBy` | Medium-high (symmetric with literal `addBlockedBy`; GH `addX`/`removeX` precedent) | one-line edit at `tracker-provider-gh.sh` `tracker_provider_gh_unlink()` GraphQL string + one fixture key in `gh-remove-blocked-by.json` |
| Arg keys `issueId` + `blockedByIssueId` | Medium-high (mirror of add side) | same as add-side worst-case fix |
| Operand inversion for `blocks` | High (mirror of add side) | n/a |
| Selection set `{ issue { number } }` | Medium (discarded; same logic as add side) | n/a |

---

## §3 Error-path behavior (call-out 3)

The mutation runs through the existing `_gh_run` helper (lines 100-116), which routes `gh` non-zero exits into `_gh_classify_error` (lines 49-85). The classifier already covers:

- **EMU `FORBIDDEN: Unauthorized; path: addBlockedBy`** → typed `auth-insufficient-scope` (V1 §9.4). The classifier needed a small additive fix: the existing pattern matched `forbidden`/`Forbidden` but not the all-caps `FORBIDDEN` form documented in EXTERNAL-RESEARCH §1.5 line 87 as the literal wire shape. Added `*"FORBIDDEN"*` to the pattern at line 69 with a comment cite. The next-step verb resolves to `gh auth refresh -s <scope>` per V3 §27.1 Layer 2 (verb table at `tracker-errors.sh:116`).
- **Target-issue not found** → typed `not-found` (V1 §9-equivalent), via the existing `*"could not resolve to a Resource"*|*"Not Found"*|*"HTTP 404"*` pattern at line 54. Triggered if the user passes a stale `other_id`; classifier resolves in either the node-id resolution step (`gh api /repos/.../issues/N`) or in the GraphQL response.
- **Cycle detection (server-side)** → currently routes through the catch-all `validation` typed code at line 82. GitHub's server validates dependency cycles and rejects with an error; the exact wire shape is not documented in EXTERNAL-RESEARCH so the classifier falls through to the generic `validation` bucket. This is acceptable: the user receives a typed error block ending in `→ Run: review the backend message above`, and the actual GH error message (e.g., `Cannot add dependency: would create cycle`) appears in the `MESSAGE:` line. **Worth a follow-up** once the live wire shape is observed at BD-088/BD-093 land-time — at that point the classifier could grow a more specific pattern.
- **Per-issue cap exceeded (>50 deps)** → likely also `validation` via the `Validation Failed` / `unprocessable` catch at line 75. Same follow-up.
- **Auth missing / token expired / network unreachable** → covered by existing patterns; behavior unchanged.

All error sites use `tracker_error_emit` (the BD-106 fix-coder uniform contract), and every error message ends with one unambiguous `→ Run:` verb per V3 §27.1 Layer 2. No new typed codes were added (V1 §2.5 surface unchanged).

A new test case (1.17c) covers the EMU `FORBIDDEN` path explicitly and asserts the typed-code routing.

### §3 follow-up — unlink (`removeBlockedBy`) error coverage (scope extension 2026-05-15)

The `removeBlockedBy` mutation runs through the same `_gh_run` → `_gh_classify_error` chain as `addBlockedBy`. Per-mode behavior:

- **Target edge doesn't exist** — server returns `HTTP 404 Not Found` (or `could not resolve to a Resource`). Classified by the existing line 54 pattern → typed `not-found`. Verb: `verify the issue id and re-run`. **Covered by new test 1.20c.** (Note: the 404 may originate at either the node-id resolution step — issue ID itself doesn't exist — or at the GraphQL mutation step — the edge doesn't exist; both paths classify the same way, which is the correct UX.)
- **EMU `FORBIDDEN: Unauthorized; path: removeBlockedBy`** — same wire shape as the add-side EMU error; the line 69 `*"FORBIDDEN"*` pattern (added in the first pass) covers the remove side too. Typed `auth-insufficient-scope`; verb: `gh auth refresh -s <scope>`. Not separately tested (covered transitively by the link-side test 1.17c plus the Group 2 classifier sweep).
- **Cycle detection** — N/A on the remove side. `removeBlockedBy` cannot create a cycle.
- **Per-issue cap** — N/A on the remove side. Removing a dependency only ever decreases the count.
- **Auth missing / token expired / network unreachable** — covered by the same pre-existing classifier patterns.

No new typed codes were added on the unlink side (V1 §2.5 surface still unchanged). All error sites use `tracker_error_emit` and end in `→ Run:` verbs.

---

## §4 Comment-marker fallback preservation (call-out 4)

**Confirmed preserved.** Two distinct preservation surfaces:

1. **`provider_raw()` is unchanged** — function at `tracker-provider-gh.sh:688-716`. Callers that explicitly want to write a comment marker can call `provider_comment(id, "Blocks #N")` directly (the comment op is still wired through the dispatcher at `tracker-provider.sh:132`), or use `provider_raw("POST", "/repos/.../issues/N/comments", body)` for fully manual control.

2. **`tracker_provider_gh_comment()` is unchanged** — function at `tracker-provider-gh.sh:377-397`. The exact text shapes the prior `link()` wrote (`"Blocks #$other_id"` etc.) can be reproduced by a one-line caller invocation. Code that did `provider_link(42, 99, "blocks")` previously can become `provider_comment(42, "Blocks #99")` with byte-equivalent issue-body output.

3. **`related|duplicates` continue on the comment path** in `tracker_provider_gh_link()` itself (lines 530-537) — those kinds have no first-class GH API, so the V3 §28 fallback is the *only* path for them. This branch of the case statement preserves the original BD-060 behavior verbatim.

Updated function header documents this explicitly:

```
# Comment-based fallback for blocks/blocked-by remains available to
# callers that explicitly want it via provider_comment() or
# provider_raw() (the V3 §28 fallback path is preserved as an
# escape hatch; see ARCHITECTURE.md §2.4 line 334).
```

The "deferral note" demanded by the BD-111 success criteria — formerly *"GA 2025-08-21; mutation name verified at first live use — until then, fallback to comment-based marker which the tracker-mode merge agent already understands per V3 §28"* — has been removed and replaced with the BD-111 forward-looking commentary.

---

## §5 Backwards-compat with existing markers (call-out 6)

**Mixed-environment behavior:** clean for reads; one-time follow-up needed for full migration coverage.

- **Reads:** issues created before BD-111 lands carry comment-body markers (`Blocks #N`, `Blocked by #N`). Those comments persist through `provider_get(id)` (returns the full issue with all comments embedded as `body`/`comments`) and through any future `auditor-issue-tracking` Check-28 logic. Nothing in the BD-111 change *removes* the prior markers.
- **Writes:** new write calls land via the first-class API. They do not overwrite the prior comment markers; they create a new edge in the GH graph that lives alongside the legacy comments.
- **Mixed environment:** an issue can have both (a) a comment-body `Blocks #N` from BD-060 era and (b) a first-class `addBlockedBy` edge from BD-111 era. The first-class edge is the truth; the comment-body marker is informational scar tissue. `auditor-issue-tracking` Check-28 should — as the BACKLOG entry's Unblocks line states — read the first-class graph (no comment-body parsing); it can ignore the legacy markers. **No migration script is required for v11.0** — the legacy markers are harmless.
- **Optional follow-up (out of scope for BD-111):** a `pack tracker doctor`-style sweep could detect issues that have a comment-marker but no corresponding first-class edge and offer to upgrade them. That's a separate BD candidate; not blocking BD-111.

---

## §6 Test results

### New tracker-provider-test.sh totals

```
Group 1 (happy-path):  79 PASS
Group 2 (error map):    8 PASS
Group 3 (stub backend): 12 PASS
─────────────────────────
Total:                 99 PASS / 0 FAIL  (was 65 PASS at baseline; +34 new assertions across BD-111 link + scope-extended unlink)
```

New / updated assertions in test 1.17 (link side; replaces former 2-line 1.17):

- 1.17a: kind=blocked-by → `addBlockedBy` mutation called with issueId=NODE_42, blockedByIssueId=NODE_99 (9 sub-assertions including negative "does NOT invoke `issue comment`")
- 1.17b: kind=blocks → operands inverted (5 sub-assertions)
- 1.17c: EMU `FORBIDDEN: Unauthorized; path: addBlockedBy` → typed `auth-insufficient-scope` error
- 1.17d: kind=related → still comment-based (2 sub-assertions, no regression)
- 1.17e: kind=duplicates → still comment-based (1 sub-assertion, no regression)

Test 1.19 retargeted (was `unlink blocks → "not unlinkable"` after first pass; now that blocks/blocked-by are first-class on unlink too, 1.19 asserts the comment-based rejection only for `related` and `duplicates`):

- 1.19 (split): `unlink related → validation (comment-based)` + `unlink duplicates → validation (comment-based)` (2 assertions)

New assertions in test 1.20 (unlink side; scope extension 2026-05-15):

- 1.20a: kind=blocked-by → `removeBlockedBy` mutation called with issueId=NODE_42, blockedByIssueId=NODE_99 (10 sub-assertions including two negative assertions: does NOT invoke `addBlockedBy` and does NOT invoke `issue comment`)
- 1.20b: kind=blocks → operands inverted (5 sub-assertions)
- 1.20c: missing-edge `HTTP 404 Not Found` → typed `not-found` error (1 assertion)

Renumbered (no behavioral change):

- 1.20 sub_issue_create → 1.21
- 1.21 raw graphql empty body → 1.22
- 1.22 raw graphql with body → 1.23

### Fake-`gh` harness extension (additive, backward-compatible)

Added `FAKE_GH_DISPATCH_DIR` mode to the in-test fake `gh` (lines 91-152 of the updated `tracker-provider-test.sh`). When set, the fake selects its stdout file by inspecting argv:

| argv pattern | fixture file looked up |
|--------------|-----------------------|
| `api graphql ...` | `$DISPATCH_DIR/api-graphql` |
| `api /repos/<o>/<r>/issues/N ...` | `$DISPATCH_DIR/api-issue-N` |
| `repo view ...` | `$DISPATCH_DIR/repo` |
| `<verb> ...` (generic fallback) | `$DISPATCH_DIR/<verb>` |
| miss → falls back to `FAKE_GH_STDOUT_FILE` (legacy) |

When `FAKE_GH_DISPATCH_DIR` is unset, behavior is identical to the prior fake. All pre-existing test cases in Group 1 still pass without modification. The dispatch-mode harness is now used by both 1.17 (link) and 1.20 (unlink) test suites.

`reset_fake_gh()` updated to also unset `FAKE_GH_DISPATCH_DIR`.

### Fake-`gh` harness extension (additive, backward-compatible)

Added `FAKE_GH_DISPATCH_DIR` mode to the in-test fake `gh` (lines 91-152 of the updated `tracker-provider-test.sh`). When set, the fake selects its stdout file by inspecting argv:

| argv pattern | fixture file looked up |
|--------------|-----------------------|
| `api graphql ...` | `$DISPATCH_DIR/api-graphql` |
| `api /repos/<o>/<r>/issues/N ...` | `$DISPATCH_DIR/api-issue-N` |
| `repo view ...` | `$DISPATCH_DIR/repo` |
| `<verb> ...` (generic fallback) | `$DISPATCH_DIR/<verb>` |
| miss → falls back to `FAKE_GH_STDOUT_FILE` (legacy) |

When `FAKE_GH_DISPATCH_DIR` is unset, behavior is identical to the prior fake. All 22 pre-existing test cases in Group 1 still pass without modification.

`reset_fake_gh()` updated to also unset `FAKE_GH_DISPATCH_DIR`.

### Regression sweep — all tracker-* test scripts

| Test script | Result |
|-------------|--------|
| `test-tracker-cycle-check.sh` | 26 PASS / 0 FAIL |
| `test-tracker-links.sh` | 43 PASS / 0 FAIL |
| `test-tracker-phase-task.sh` | 90 PASS / 0 FAIL |
| `test-tracker-promote-direct.sh` | 31 PASS / 0 FAIL |
| `test-tracker-promote-path1.sh` | 80 PASS / 0 FAIL |
| `test-tracker-promote-path2.sh` | 59 PASS / 0 FAIL |
| `tracker-agent-read-test.sh` | 31 PASS / 0 FAIL |
| `tracker-bd129-gh-repo-test.sh` | 11 PASS / 0 FAIL |
| `tracker-bd130-doctor-wired-test.sh` | 8 PASS / 0 FAIL |
| `tracker-bd132-race-test.sh` | 29 PASS / 0 FAIL |
| `tracker-bd133-header-preservation-test.sh` | 30 PASS / 0 FAIL |
| `tracker-bd134-close-retry-test.sh` | 24 PASS / 0 FAIL |
| `tracker-config-schema-test.sh` | 17 PASS / 0 FAIL |
| `tracker-config-test.sh` | 32 PASS / 0 FAIL |
| `tracker-errors-test.sh` | 60 PASS / 0 FAIL |
| `tracker-init-test.sh` | 95 PASS / 0 FAIL |
| `tracker-migrate-forward-test.sh` | 134 PASS / 0 FAIL |
| `tracker-migrate-reverse-test.sh` | 95 PASS / 0 FAIL |
| `tracker-migrate-roundtrip-test.sh` | 45 PASS / 0 FAIL |
| `tracker-provider-test.sh` | **99 PASS / 0 FAIL** (this BD's headline test; was 82 PASS at end of first pass; +17 from the scope-extended unlink suite + 1.19 split) |

Zero regressions across the tracker test corpus. Scope-extended sweep re-run on 2026-05-15 against working-tree HEAD `eca769b`.

### validate-pack.py

```
PASSED — all checks clean   (32 / 32)
```

### Bash syntax check

```
bash -n scripts/lib/tracker-provider-gh.sh && bash -n scripts/tests/tracker-provider-test.sh && echo OK_SYNTAX
→ OK_SYNTAX
```

(no `[[` / `&>` / associative arrays / GNU-only flags introduced; bash 3.2 + BSD-utils compatible.)

---

## §7 Integration-test verification ask (for BD-088 or BD-093)

When the integration-test BD lands, please verify against the live GH GraphQL schema:

1. **Mutation name:** confirm `addBlockedBy` is the literal mutation name. Run:
   ```
   gh api graphql -f query='{ __schema { mutationType { fields { name } } } }' --jq '.data.__schema.mutationType.fields[].name' | grep -i block
   ```
   Expected: `addBlockedBy` and `removeBlockedBy` appear in the list. If either is named differently (e.g., `createBlockedByDependency`), update `tracker-provider-gh.sh:527` (and 1.17 fixture key `addBlockedBy` in `gh-add-blocked-by.json`).

2. **Argument key:** confirm the second arg is named `blockedByIssueId`. Run:
   ```
   gh api graphql -f query='{ __type(name: "AddBlockedByInput") { inputFields { name type { name } } } }'
   ```
   Expected: fields named `issueId` and `blockedByIssueId`, both `ID!`. If the key is `blockedById` instead, update line 527 (`-F "blockedByIssueId="` → `-F "blockedById="`) and the test assertions at 1.17a/1.17b (the `blockedByIssueId=NODE_99` substring matches).

3. **Cycle / cap error wire shape:** capture the actual error body when (a) attempting to create a cycle and (b) exceeding the 50-per-relationship cap. Use those literals to extend `_gh_classify_error` patterns in `tracker-provider-gh.sh` (lines 49-85) so cycle/cap errors classify as something more specific than the generic `validation` fallback.

4. **EMU `FORBIDDEN` path** (only relevant if the integration-test repo is in an EMU org with cross-enterprise issues): confirm the literal `FORBIDDEN: Unauthorized; path: addBlockedBy` shape; the `_gh_classify_error` pattern at line 69 was updated this BD to handle this all-caps form.

5. **`removeBlockedBy` mutation name** (scope extension follow-up; mirrors item 1 for the unlink side): confirm `removeBlockedBy` is the literal mutation name. The same `__schema { mutationType { fields { name } } }` introspection from item 1 will surface it; the grep already filters on `block`. If GH's actual remove-side name is `deleteBlockedBy` or `removeBlockedByDependency`, update the GraphQL string in `tracker_provider_gh_unlink()` (one line) and the response top-level key in `gh-remove-blocked-by.json` (one line).

6. **`removeBlockedBy` arg shape** (scope extension follow-up; mirrors item 2): confirm the input type is `RemoveBlockedByInput` with fields `issueId` + `blockedByIssueId` (both `ID!`). Run:
   ```
   gh api graphql -f query='{ __type(name: "RemoveBlockedByInput") { inputFields { name type { name } } } }'
   ```
   If the keys differ from `addBlockedBy`'s, update the `-F` flags in `tracker_provider_gh_unlink()` and the test 1.20a/1.20b assertions to match.

7. **`removeBlockedBy` 404 / missing-edge wire shape** (scope extension follow-up): when the target dependency edge does not exist, capture the exact error body. The current implementation assumes the existing `not-found` classifier pattern (`HTTP 404` / `Not Found` / `could not resolve to a Resource`) catches it; if GH returns `Validation Failed: dependency not found` instead, the catch-all `validation` typed code applies (still acceptable UX; the actual GH message appears in the `MESSAGE:` line). No fix needed unless we want a more specific verb than the generic `validation` one.

Worst-case fix-up footprint if any name-guess is wrong (combined add + remove sides): ≤ 8 lines across `tracker-provider-gh.sh` + 4 lines across the two fixture files + ~6 test-assertion key updates. Still small.

---

## §8 Decision call-outs (5 + extras)

**Call-out 5 (test coverage adequacy):** The new test suite covers:

- Happy path for both directions (kind=blocked-by, kind=blocks)
- Operand inversion (kind=blocks must call addBlockedBy with operands swapped)
- Negative assertion (no `issue comment` invocation in the GraphQL path — verifies legacy comment-marker write is gone)
- Error path (EMU FORBIDDEN → typed code)
- Backward-compat (kind=related, kind=duplicates still on comment-marker path)
- Existing tests 1.18 (invalid kind) and 1.19 (unlink rejection) updated to match new wording

**Coverage gaps deliberately not added** (would require live schema or are out-of-scope):
- Cycle-detected response (we don't know the wire shape; best to leave to integration-test land-time)
- Cap-exceeded response (same reason)
- The exact JSON content of a successful addBlockedBy response (we discard it; testing the discard would be tautological)
- Multi-call dispatch failure modes (e.g., node-id resolution fails on the first issue) — covered transitively by Group 2 error mapping

**Extra decision (capability flag):** Coder checked `tracker_provider_gh_capabilities()` (lines 631-679). The existing `dependencies.kinds` array already lists `"blocks", "blocked-by", "duplicates", "related"` and the `cross_repo_supported` value is `"same-org-internal-only"` — both are already accurate for the first-class API per EXTERNAL-RESEARCH §1.5 line 84. No capability change needed; the BD-111 swap is a pure backend implementation change, not a capability change. This matches the constraint in the prompt ("No new capability flag").

**Extra decision (deferral note):** The BACKLOG entry asked to "remove the 'GA 2025-08-21; mutation name verified at first live use' deferral note". Done — the original 4-line deferral comment block at the head of the function (formerly at lines 475-481) has been replaced with the new 21-line BD-111 commentary that documents (a) the chosen mutation name, (b) the arg-shape evidence basis, (c) the operand-inversion convention for kind=blocks, (d) the integration-test verification ask, and (e) the comment-marker fallback preservation surface.

---

## §9 Open issues / known limitations

> **Removed (resolved in scope-extension follow-up 2026-05-15):** the original §9 item 1 (`tracker_provider_gh_unlink()` for blocks/blocked-by deferred to follow-up BD) is no longer an open limitation. PM-only commit `eca769b` extended BD-111 scope to include the symmetric `removeBlockedBy` unlink path; the coder shipped it in the same session. See updated §1, §2 follow-up, §3 follow-up, §6 1.20a-c, §7 items 5-7.

1. **Cycle / cap error wire shapes are unknown offline.** Currently routed through the generic `validation` typed code. Will be tightened at integration-test land-time (see §7 item 3). N/A on the unlink side (cycles can't form on remove; cap can't be exceeded by a remove).

2. **`schema-reshape` typed code is the right home if the addBlockedBy / removeBlockedBy schema disappears or renames.** The classifier at line 78 already maps `*"undefined field"*|*"unknown field"*` → `schema-reshape`; if GH renames either mutation post-launch, users will get a clean schema-reshape error pointing them at `pack tracker doctor` (per V3 §27.1 Layer 2 verb table). No additional handling needed.

3. **The new fake-`gh` `FAKE_GH_DISPATCH_DIR` mode is an additive harness improvement.** Other tracker test scripts could adopt it to retire some of the "structural-only" test patterns (e.g., test 1.21 sub_issue_create which only checks "did not throw" — note the renumber from former 1.20). Not in scope for BD-111; just noting the harness is now richer for future test work.

4. **HEAD-state observation (initial pass).** When the initial coder session started, HEAD was `8409153` (two commits past the first prompt's stated `4a2d7cc`). Pack Chat made two docs commits (`8066817` opens BD-171; `8409153` is RESOLVED-RATIFIED §6.P/§6.Q updates) between the first prompt being drafted and that session starting. Neither commit touched files in BD-111's scope. Coder's edits applied cleanly on top of `8409153`.

5. **HEAD-state observation (scope-extension follow-up).** When the scope-extension session started, HEAD was `eca769b` (the PM commit that extended scope). The coder's first-pass uncommitted working-tree edits were preserved across the PM commit (PM commit only touched `BACKLOG.md`, no scope conflict). The follow-up edits — `tracker_provider_gh_unlink()` swap, new `gh-remove-blocked-by.json` fixture, test 1.20a-c, 1.19 retarget, 1.20→1.21/1.21→1.22/1.22→1.23 renumber, and this report's §1/§2/§3/§6/§7/§9/DoD updates — apply cleanly on top of `eca769b` and the prior uncommitted working-tree state.

6. **Comment-marker fallback footprint check.** Re-verified post-extension: `provider_raw()`, `provider_comment()`, and the `related|duplicates` comment-write branch in `tracker_provider_gh_link()` are all unchanged from the first pass. Callers wanting to write or remove a comment-marker (the V3 §28 fallback) still have the same surfaces. The new `removeBlockedBy` first-class path on `tracker_provider_gh_unlink()` does not affect comment-marker reads or removals — those are governed by `provider_get(id)` (returns full issue body and comments) and `provider_raw("DELETE", "/repos/.../issues/comments/<comment-id>")`.

---

## Definition-of-Done checklist

| DoD item | Result |
|----------|--------|
| `tracker_provider_gh_link()` `kind=blocks/blocked-by` invokes first-class GH dependency API | **PASS** — calls `addBlockedBy` GraphQL mutation; verified by test 1.17a/1.17b (positive: mutation name + args appear in fake-gh log; negative: no `issue comment` invocation) |
| `tracker_provider_gh_unlink()` `kind=blocks/blocked-by` invokes first-class GH dependency API (scope extension 2026-05-15) | **PASS** — calls `removeBlockedBy` GraphQL mutation; verified by test 1.20a/1.20b (positive: mutation name + args appear in fake-gh log; negative: no `addBlockedBy` invocation, no `issue comment` invocation) |
| Mutation-name guess documented for both `addBlockedBy` and `removeBlockedBy` (with evidence basis + confidence + worst-case fix) | **PASS** — §2 + §2 follow-up + comment blocks in both function headers |
| Argument-shape guess documented for both add and remove sides | **PASS** — §2 + §2 follow-up |
| Deferral note above `tracker_provider_gh_link()` removed (or rewritten) | **PASS** — replaced with 21-line BD-111 commentary |
| Deferral / "BD-111 follow-up" note above `tracker_provider_gh_unlink()` removed (or rewritten) | **PASS** — replaced with scope-extension commentary that documents the symmetric pair, evidence basis, operand inversion, and integration-test verification ask |
| New fixture-driven test mirroring test 1.17 for the GraphQL path (link side) | **PASS** — 1.17a (kind=blocked-by, 9 assertions), 1.17b (kind=blocks, 5 assertions), 1.17c (error path, 1 assertion), 1.17d/1.17e (backward-compat for related/duplicates, 3 assertions) |
| New fixture-driven test mirroring test 1.17 for the GraphQL path (unlink side, scope extension 2026-05-15) | **PASS** — 1.20a (kind=blocked-by, 10 assertions), 1.20b (kind=blocks, 5 assertions), 1.20c (missing-edge `not-found` error path, 1 assertion); test 1.19 retargeted to `related|duplicates` rejection (2 assertions); existing 1.20→1.21, 1.21→1.22, 1.22→1.23 renumber confirmed clean |
| New fixture file `gh-remove-blocked-by.json` (scope extension 2026-05-15) | **PASS** — created at `scripts/tests/fixtures/tracker-provider/gh-remove-blocked-by.json`; mirrors `gh-add-blocked-by.json` shape |
| Comment-based fallback still available via `provider_raw()` / `provider_comment()` | **PASS** — both ops unchanged; §4 + §9 item 6 (post-extension re-verification) document the preservation surface |
| All other tracker-* tests continue to pass | **PASS** — 19 tracker test scripts swept after the scope extension; zero regressions |
| `scripts/validate-pack.py` passes (32 checks) | **PASS** (re-run post-extension) |
| IMPLEMENTATION-REPORT flags assumed mutation names + verification steps + worst-case fix-up for both add and remove sides | **PASS** — §2, §2 follow-up, §7 items 1-7, §9 |
| No state-changing git verbs run | **PASS** — only `git status`, `git diff`, `git log`, `git rev-parse`, `git reflog`, `git show` used across both sessions |
| Trinity rule | **N/A** — no edits to CLAUDE.md / AGENTS.md / GEMINI.md trinity files |
| Bash 3.2 + BSD-utils compatibility | **PASS** — no GNU-only flags or bash 4+ features introduced (verified via `bash -n` syntax check + manual inspection of `case` patterns and `[[` usage) |
| Workflow rule: agents do not commit | **PASS** — uncommitted working-tree changes only across both sessions |
