# IMPL-REPORT-MODE3-OPS-COMMIT1 — BD-204 Mode-3 ops contract, Commit 1 (docs/contract)

> **Agent:** pack-coder (fresh instance). **Date:** 2026-06-11 session.
> **Authorities applied (precedence order, later amendment wins):**
> 1. `maintenance-docs/v11-implementation/PLAN-BD-204-MODE3-OPS-CONTRACT.md` (Commit-1 recipe baseline)
> 2. `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md` (element-1 content)
> 3. `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT-2.md` §B8 D1 (NORMATIVE; authoritative task list)
>
> **SUPERSEDED, not applied:** `ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT.md`
> (committed-id-map premise dissolved by Amendment-2 §B2). Verified by absence: this
> commit introduces ZERO references to `pack-ops/tracker-id-map.json`, zero
> BOUNDARY-DEFINITION row changes, zero id-map staging clauses.

---

## 0. KEYWORD CONCLUSION (prominent, per calling prompt)

**`pack-chat-only` does NOT survive the final staged set. Proposed fallback keyword:
`pack-only` (per PLAN §2.5 contingency). User decides at the commit gate.**

- The six EDITED files are all Check-36 pack-chat-only-permitted (verified against
  `scripts/validate-pack.py` `_PACK_CHAT_ONLY_PERMITTED_PATHS` + `_PREFIXES`):
  `backlog/_rules.md`, `changelog/_rules.md` (prefixes `backlog/` / `changelog/`),
  `pack-ops/PACK-CHAT.md`, `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (explicit paths).
  The plan's EE-3 verification holds for this subset.
- BUT the caller directs the untracked workflow artifacts to RIDE this commit
  (stage-list §9.2 below). `maintenance-docs/` is in NEITHER
  `_PACK_CHAT_ONLY_PERMITTED_PATHS` NOR `_PACK_CHAT_ONLY_PERMITTED_PREFIXES`.
  Simulation of Check 36 path classification over the prospective 12-path staged set:

  ```
  pack-chat-only violations: 6
     maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md
     maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT.md
     maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT-2.md
     maintenance-docs/v11-implementation/PLAN-BD-204-MODE3-OPS-CONTRACT.md
     maintenance-docs/v11-implementation/RESEARCH-REBASELINE-INVENTORY.md
     maintenance-docs/v11-implementation/IMPL-REPORT-MODE3-OPS-COMMIT1.md
  pack-only violations: 0
  ```

- `pack-only` is clean: zero staged paths under `project-template/` or
  `supporting-docs/` (the `_PROJECT_SIDE_PATH_PREFIXES` deny set), and the
  fixture manifest did NOT drift (so `test-fixtures/manifest.txt` does not ride).
- Alternative that preserves `pack-chat-only`: commit the maintenance-docs
  artifacts separately (a no-keyword or `pack-only` docs commit) and keep the
  six-file commit `pack-chat-only`. That is Pack Chat's + the user's call;
  this report's proposed subject (§9.1) uses the `pack-only` fallback for the
  single-commit shape the caller specified. Never `pack-chat-only` on the
  combined set — that is a CI-verified mis-claim.

---

## 1. Branch + final HEAD SHA

- Branch: `v11-dev`
- HEAD (unchanged; pack-coder does not commit): `9127907edd27a53e7504e5896365a8d01ff5561f`
- Worktree: `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`

## 2. Pre-flight check output

```
$ git rev-parse HEAD && git status --porcelain && git branch --show-current
9127907edd27a53e7504e5896365a8d01ff5561f
?? maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT-2.md
?? maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT.md
?? maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md
?? maintenance-docs/v11-implementation/PLAN-BD-204-MODE3-OPS-CONTRACT.md
?? maintenance-docs/v11-implementation/RESEARCH-REBASELINE-INVENTORY.md
?? tracker.toml
v11-dev
```

Base matches the caller's pin (HEAD `9127907`, branch `v11-dev`, tree clean except
the five untracked workflow artifacts and the untracked local `tracker.toml`).
The local `tracker.toml` and gitignored `.pack-tracker/` were NOT touched at any
point (Pack-Chat-owned live Mode-3 state). All three authority docs + both
`_rules.md` files + `pack-ops/PACK-CHAT.md` were verified present and read in full
before any edit (attestation §11).

## 3. Per-task summary (Amendment-2 §B8 D1 table = authoritative task list)

| D1 item | File | Delta applied | Lines |
|---|---|---|---|
| D1-1 | `backlog/_rules.md` | § "Source of truth — no mirror" REPLACED by § "Source of truth — mode-dependent (no monolith in either mode)": mode read from the LOCAL `tracker.toml` with the local-opt-in + always-flat-file-committed + sticky-by-construction clauses; "Flat-file mode" paragraph (sole SSOT, no monolith, GH Issues ignored, human/PM triage channel); "Tracker mode" paragraph (tracker sole SSOT on opted-in checkout, pack-id identity, one-way regenerated mirror, hand-edits OVERWRITTEN WITHOUT DETECTION, regeneration NOT a sync, `_toc.md` on every materialization); NEW "Published tree + single writing authority" paragraph carrying the §B1.4 publication model + the §B1.5 caveat (second-writer prohibitions (a)/(b), route through tracker or maintainer, `pack tracker disable` safe degradation). Both Check-32′ marker headings ("Flat-file mode", "Tracker mode") present. | +47 / −9 |
| D1-2 | `backlog/_rules.md` | § "Write authority": Pack-Chat-authority sentence kept VERBATIM; procedure now mode-conditional (flat-file arm = existing per-entry edit + `per_entry_regenerate_toc pack-backlog /backlog`; tracker arm = all writes via tracker tooling, GH-web not a write path, comparator/`--force`/doctor references, tree-rebuild-before-committing cadence). Staging list per ruling 4 + §B2: "the regenerated tree + `_toc.md`" ONLY, with the explicit never-staged statement for `tracker.toml` + `.pack-tracker/`. | +21 / −2 |
| D1-3 | `changelog/_rules.md` | "**Mode invariance.**" paragraph added to § "Source of truth — no mirror" (heading itself unchanged per architecture §1.2): flat-file in BOTH modes; tracker mode is pack-backlog-only AND a per-checkout local opt-in; migration neither reads nor writes `/changelog/`; write procedure mode-invariant. Marker "Mode invariance" present. Rest of file byte-stable. | +10 / −0 |
| D1-4 | `pack-ops/PACK-CHAT.md` | NEW § "Backlog write paths by mode (Mode-3 operations)" inserted immediately after § "File access strategy", realizing architecture §1.3 content items 1–9 (with §B5-surface-3 rewrites of items 1 + 5) plus the Amendment-2 NEW item (single-writing-authority caveat + publication, one-hop pointer to `/backlog/_rules.md`) as list item 10 — see numbering note in §6. Plus the File-access-strategy table `/backlog/<ID>.md` row "Why"-cell touch-up (design item 10): read valid in both modes; one-entry-edit reading scoped flat-file-only. | +65 / −1 |
| D1-5 | `CLAUDE.md` + `AGENTS.md` + `GEMINI.md` (root trinity) | The §1.4 two-sentence operational imperative appended to the "Per-entry trees — sole SSOT (pack: no mirror)" bullet's tracker-mode arm, WITH the Amendment-2 clause "(tracker mode is a per-checkout LOCAL opt-in — the committed repo is always flat-file; `tracker.toml` is local and gitignored)". BYTE-IDENTICAL ×3 (proof §5.4). All other bullet text byte-stable (the trailing STATUS.md sentence moved to its own line start, bytes unchanged). | +8 / −1 each |
| D1-6 | (plan-text item) | OQ-1 closed by Amendment-2 — no id-map staging clause written anywhere. Verified: `grep -rn "id-map" backlog/_rules.md changelog/_rules.md pack-ops/PACK-CHAT.md CLAUDE.md AGENTS.md GEMINI.md` → 0 hits in the edited sections (pre-existing trinity hits unrelated to this commit: none added). | n/a |
| D1-7 | (accepted transient) | Docs name `pack tracker tree-rebuild` and describe `tracker.toml` as gitignored ONE commit before Commit 2 lands the verb + the `.gitignore` rule. Accepted one-commit-window transient per D1-7 — with ONE empirical correction recorded as plan deviation PD-1 (§6): the transient is NOT fully CI-inert for word-only verb shapes. | n/a |

Rule-change propagation surfaces (PLAN §2.1): surface 1 = trinity ×3 (D1-5);
surface 2 (`pack-ops/PACK-MEMORY-RATIONALE.md`) N/A — the bullet carries no
`[rationale:]` slug and none was added; surface 4 = the PACK-CHAT.md §
"Backlog write paths by mode" section; surface 5 (`pack-ops/.spawn-rule-manifest.txt`)
N/A per PLAN EE-4 (re-verified by Check 46 passing); surface 6 (fixture manifest)
rebuilt — EMPTY diff (§5.6). Surface 3 (out-of-repo memory cache) is Pack-Chat
upkeep after the commit, not a coder action.

## 4. Unified diffs (modified files; no new files except this report)

```diff
diff --git a/AGENTS.md b/AGENTS.md
index 8c9d980..bff1139 100644
--- a/AGENTS.md
+++ b/AGENTS.md
@@ -447,7 +447,14 @@ PACK-AGENTS.md current".
   `mode.state = "tracker"` and `migration.forward_complete = true`), the
   tracker (e.g., GH Issues) is source of truth and the per-entry tree is
   regenerated from tracker state per the Mode 2 → Mode 3 transition
-  contract. STATUS.md and any other convenience view carry an explicit
+  contract. In tracker mode the tree + `_toc.md` are a ONE-WAY
+  regenerated mirror — never hand-edit them; a hand-edit is overwritten
+  without detection at the next `pack tracker tree-rebuild`, and all
+  entry writes go through the tracker tooling (tracker mode is a
+  per-checkout LOCAL opt-in — the committed repo is always flat-file;
+  `tracker.toml` is local and gitignored). Write procedure per
+  `<stream>/_rules.md`.
+  STATUS.md and any other convenience view carry an explicit
   "never source of truth" disclaimer; if a convenience view drifts, the
   per-entry tree (Mode 2) or the tracker (Mode 3) wins. Read more at
   `<stream>/_rules.md`. `[roles: universal]`
diff --git a/CLAUDE.md b/CLAUDE.md
index 41bc70b..875ac0a 100644
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -481,7 +481,14 @@ PACK-AGENTS.md current".
   `mode.state = "tracker"` and `migration.forward_complete = true`), the
   tracker (e.g., GH Issues) is source of truth and the per-entry tree is
   regenerated from tracker state per the Mode 2 → Mode 3 transition
-  contract. STATUS.md and any other convenience view carry an explicit
+  contract. In tracker mode the tree + `_toc.md` are a ONE-WAY
+  regenerated mirror — never hand-edit them; a hand-edit is overwritten
+  without detection at the next `pack tracker tree-rebuild`, and all
+  entry writes go through the tracker tooling (tracker mode is a
+  per-checkout LOCAL opt-in — the committed repo is always flat-file;
+  `tracker.toml` is local and gitignored). Write procedure per
+  `<stream>/_rules.md`.
+  STATUS.md and any other convenience view carry an explicit
   "never source of truth" disclaimer; if a convenience view drifts, the
   per-entry tree (Mode 2) or the tracker (Mode 3) wins. Read more at
   `<stream>/_rules.md`. `[roles: universal]`
diff --git a/GEMINI.md b/GEMINI.md
index 30e5cb3..37e312b 100644
--- a/GEMINI.md
+++ b/GEMINI.md
@@ -414,7 +414,14 @@ PACK-AGENTS.md current".
   `mode.state = "tracker"` and `migration.forward_complete = true`), the
   tracker (e.g., GH Issues) is source of truth and the per-entry tree is
   regenerated from tracker state per the Mode 2 → Mode 3 transition
-  contract. STATUS.md and any other convenience view carry an explicit
+  contract. In tracker mode the tree + `_toc.md` are a ONE-WAY
+  regenerated mirror — never hand-edit them; a hand-edit is overwritten
+  without detection at the next `pack tracker tree-rebuild`, and all
+  entry writes go through the tracker tooling (tracker mode is a
+  per-checkout LOCAL opt-in — the committed repo is always flat-file;
+  `tracker.toml` is local and gitignored). Write procedure per
+  `<stream>/_rules.md`.
+  STATUS.md and any other convenience view carry an explicit
   "never source of truth" disclaimer; if a convenience view drifts, the
   per-entry tree (Mode 2) or the tracker (Mode 3) wins. Read more at
   `<stream>/_rules.md`. `[roles: universal]`
diff --git a/backlog/_rules.md b/backlog/_rules.md
index 86f0d8e..470ed84 100644
--- a/backlog/_rules.md
+++ b/backlog/_rules.md
@@ -15,15 +15,53 @@ pack changes the per-entry contract.
 - Pack version that minted this contract: v11.0
 - Directory: `/backlog/`
 
-## Source of truth — no mirror
-
-The per-entry tree at `/backlog/` (plus its generated `/backlog/_toc.md`
-index) is the **SOLE source of truth and readable form** for pack
-backlog entries. **There is no monolithic mirror.** The former
-`pack-ops/BACKLOG.md` monolith was deleted at BD-203; do not recreate
-it. To read entries, read the per-entry files (or `_toc.md` for an
-index); to change an entry, edit its per-entry file and regenerate
-`_toc.md`.
+## Source of truth — mode-dependent (no monolith in either mode)
+
+The stream operates in one of two modes, read from the LOCAL pack
+`tracker.toml` (`[mode] state` + `[migration] forward_complete`;
+absent file = flat-file). Tracker mode is a per-checkout LOCAL
+opt-in: `tracker.toml` is gitignored and never committed, so the
+repo's COMMITTED state is always flat-file — every checkout and
+every version bump ships flat-file — and a local opt-in is sticky
+across pulls and version bumps by construction.
+
+**Flat-file mode (default).** The per-entry tree at `/backlog/` (plus
+its generated `/backlog/_toc.md` index) is the SOLE source of truth
+and readable form. There is no monolithic mirror — the former
+`pack-ops/BACKLOG.md` was deleted at BD-203; do not recreate it. GH
+Issues are IGNORED by all tooling in this mode; inbound-feedback
+issues are a human/PM triage channel only. Validation runs against
+the tree.
+
+**Tracker mode (`state = "tracker"` + `forward_complete = true`,
+local).** The tracker is the SOLE source of truth on the opted-in
+checkout. Entry identity is the `<!-- pack-id: BD-NNN -->` body
+marker — never an issue number. The per-entry tree + `_toc.md` are a
+REGENERATED MIRROR of tracker state: read-stable, never hand-written.
+A hand-edit to any `BD-NNN.md` or to `_toc.md` is INVALID and is
+OVERWRITTEN WITHOUT DETECTION at the next tree rebuild — the write
+direction is one-way (tracker → tree, always); this is a
+regeneration, NOT a sync. There is still no monolith, ever. `_toc.md`
+regenerates on EVERY tree materialization.
+
+**Published tree + single writing authority.** Because tracker mode
+is local, the COMMITTED tree (+ `_toc.md`) remains the published
+flat-file SSOT for every non-opted checkout; the (single)
+tracker-mode maintainer keeps it current by running
+`pack tracker tree-rebuild` and committing the regenerated tree
+through the normal commit gates — the COMMIT is the publication act.
+While the maintainer's local state is tracker mode, the committed
+tree is a PUBLISHED MIRROR of the tracker even though the repo's
+committed state is formally flat-file. A second writer must NOT
+(a) hand-edit `/backlog/` entry files or `_toc.md` and commit — the
+edit is silently CLOBBERED at the maintainer's next tree-rebuild
+publication (the tracker, not the committed tree, is what the
+maintainer's rebuild reads); nor (b) opt in to tracker mode on a
+second machine and publish concurrently — two publishers race on the
+committed tree. Entry-state changes route through the tracker (GH
+Issues) or through the maintainer. If the single-writer assumption
+ever breaks, the safe degradation is `pack tracker disable` back to
+flat-file, where the committed tree is directly writable again.
 
 ## Filename convention
 
@@ -90,5 +128,24 @@ history.
 Writes are Pack-Chat authority (the pack-backlog tree is a pack-chat-only
 directory per `pack-ops/PACK-AGENTS.md` § "pack-chat-only files and
 directories"; agents edit it only when a caller scopes it in for an
-explicit BD). After any entry edit, regenerate `_toc.md` via
-`per_entry_regenerate_toc pack-backlog /backlog` before staging.
+explicit BD). The write PROCEDURE is mode-dependent (mode per
+§ "Source of truth — mode-dependent (no monolith in either mode)"):
+
+- **Flat-file mode:** edit the per-entry file directly; entries
+  resolve in place. After any entry edit, regenerate `_toc.md` via
+  `per_entry_regenerate_toc pack-backlog /backlog` before staging.
+  Never hand-edit `_toc.md` (derived index).
+- **Tracker mode:** ALL entry creates / edits / status flips go
+  through the tracker tooling (`pack tracker` verbs /
+  `tracker_edit_entry`), which recomposes the H2 projection + the
+  `pack-entry-body-gz64` blob atomically. NEVER edit a `BD-NNN.md`
+  file or `_toc.md` by hand — the edit is overwritten without
+  detection at the next rebuild. Direct GH-web edits are NOT a write
+  path: body edits are blocked loudly by the divergence comparator
+  at the next rebuild (`--force` = blob-wins); label/state-only
+  flips are a coherence defect detected by `pack tracker doctor` and
+  at rebuild. After any tracker write batch — and ALWAYS before
+  committing tree state — run `pack tracker tree-rebuild`, then
+  stage the regenerated tree + `_toc.md` through the normal commit
+  gates. The local `tracker.toml` and `.pack-tracker/` are NEVER
+  staged (gitignored local state).
diff --git a/changelog/_rules.md b/changelog/_rules.md
index 169eddd..28e1e35 100644
--- a/changelog/_rules.md
+++ b/changelog/_rules.md
@@ -23,6 +23,16 @@ form** for the pack changelog. **There is no monolithic mirror.** The
 former `pack-ops/CHANGELOG.md` monolith was deleted at BD-203; do not
 recreate it.
 
+**Mode invariance.** The pack-changelog stream is FLAT-FILE IN BOTH
+modes: pack tracker mode (BD-204) applies to the pack-backlog stream
+only, and is in any case a per-checkout LOCAL opt-in of the
+maintainer's checkout — in every checkout without a local
+`tracker.toml`, this stream, like every committed stream, is simply
+flat-file. The tracker migration neither reads nor writes
+`/changelog/` (the pack reverse emits no changelog). The write
+procedure in § "Write authority" below applies regardless of the
+pack's tracker mode.
+
 ## Filename convention
 
 Per-entry files match `^v\d+\.md$` (e.g., `v11.md`, `v7.md`). One file
diff --git a/pack-ops/PACK-CHAT.md b/pack-ops/PACK-CHAT.md
index 5c24ab3..1a295bf 100644
--- a/pack-ops/PACK-CHAT.md
+++ b/pack-ops/PACK-CHAT.md
@@ -50,7 +50,7 @@ is sufficient.
 | `README.md` | Direct read (version table section) | Pack version history at a glance |
 | `supporting-docs/METHODOLOGY.md` | Direct read (on demand) | Author of this file — read directly when needed |
 | `project-template/docs/pack/prompts/*.md` | Direct read (on demand) | Author of this set of files — read directly when needed |
-| `/backlog/<ID>.md`, `/changelog/<ID>.md` (per-entry source) | Direct read of single entry when only that entry is needed | Per-entry tree is the SOLE source of truth + readable form (no monolithic mirror; per CLAUDE.md pack-memory + `<stream>/_rules.md`); read one entry file for one-entry edits |
+| `/backlog/<ID>.md`, `/changelog/<ID>.md` (per-entry source) | Direct read of single entry when only that entry is needed | Per-entry tree is the SOLE source of truth + readable form in flat-file mode and a read-stable regenerated mirror in tracker mode (no monolithic mirror; per CLAUDE.md pack-memory + `<stream>/_rules.md`) — direct read valid in both modes; read one entry file for one-entry edits (flat-file mode only — Mode-3 edits go through the tracker tooling per § "Backlog write paths by mode (Mode-3 operations)") |
 | `/backlog/_rules.md`, `/changelog/_rules.md` (per-stream contracts) | Direct read at session start (or on per-entry-tree-aware operation) | Per-stream contract authority — filename regex, lifecycle states admitted, supporting-file basenames admitted, write-authority pointer |
 
 **Rule-SSOT routing (one hop to the authority — no index, query the SSOT directly):**
@@ -58,6 +58,70 @@ For spawn-relevant rules, read trinity `## Pack memory`. For file placement, rea
 
 ---
 
+## Backlog write paths by mode (Mode-3 operations)
+
+The write-side complement of the read-side table above. The per-stream
+contract is `/backlog/_rules.md` + `/changelog/_rules.md` (one hop —
+this section points, never restates); the one-line imperative lives in
+trinity `## Pack memory` § "Repo conventions" (the per-entry-trees
+bullet).
+
+1. **Mode detection.** At session start / before any backlog write,
+   read the local `tracker.toml` (`[mode] state` +
+   `[migration] forward_complete`; absent file = flat-file). Tracker
+   mode is a per-checkout LOCAL opt-in — the file is gitignored and
+   never committed, so the repo's committed state is always
+   flat-file. The pack is currently Mode 3 ON THE MAINTAINER'S
+   MACHINE; every other checkout is flat-file.
+2. **Write channel per mode.** Flat-file: per-entry file edit +
+   `_toc.md` regen per `/backlog/_rules.md`. Tracker: ALL entry
+   creates / edits / status-flips via the tracker tooling (the
+   `pack tracker` `edit` / `new-entry` verbs) — NEVER the Edit/Write
+   tools against `/backlog/`.
+3. **One-way overwrite.** In tracker mode the tree + `_toc.md` are a
+   one-way regenerated mirror (tracker → tree, always — NOT a sync).
+   A hand-edit is invalid and is OVERWRITTEN WITHOUT DETECTION at
+   the next `pack tracker tree-rebuild`.
+4. **Flat-file ignores GH Issues.** In flat-file mode GH Issues are
+   IGNORED by all tooling; inbound feedback remains a human/PM
+   triage channel only.
+5. **Regen cadence + committed artifacts.** After any tracker write
+   batch, and ALWAYS before committing tree state, run
+   `pack tracker tree-rebuild`. The committed artifacts flowing
+   through the normal commit gates (staged-file review + user
+   approval) are the regenerated tree + `_toc.md` ONLY; the local
+   `tracker.toml` and `.pack-tracker/` are NEVER staged (gitignored
+   local state).
+6. **GH-web is not a write path.** Body edits → the divergence
+   comparator blocks loudly at the next rebuild (`--force` =
+   explicit blob-wins override). Label/state-only flips → a
+   coherence defect; recovery = re-apply the status via the tracker
+   tooling (the blob is truth).
+7. **Two lanes.** Pack-owned issues (`work-item` + resolved
+   `pack-id`) reverse into the tree; inbound-feedback issues
+   (`inbound` + `needs-triage` / `pack-id: PENDING`) are NEVER swept
+   until promoted at triage.
+8. **Minor-edit authority mapping.** The trinity
+   `pack-chat-minor-edits-only` boundary is UNCHANGED; only the
+   write CHANNEL changes in Mode 3. A bookkeeping edit Pack Chat may
+   apply directly (a `Status:`/`Resolved:` flip; a new-BD author) is
+   performed via the tracker tooling commands (Bash), not via
+   Edit-tool writes to the tree. MAJOR edits still route to
+   pack-coder — the coder likewise mutates via the tooling and runs
+   the rebuild.
+9. **Changelog unaffected.** The `/changelog/` stream stays
+   flat-file in both modes; its write procedure never changes with
+   tracker mode.
+10. **Publication + single writing authority.** The committed tree
+    is the published flat-file SSOT; the COMMIT of a regenerated
+    tree is the publication act, and exactly ONE writing authority
+    exists — the maintainer's Pack Chat on the machine holding the
+    local Mode-3 state. The full caveat (what a second writer must
+    not do; the safe degradation back to flat-file) lives at
+    `/backlog/_rules.md` § "Source of truth" (one hop).
+
+---
+
 ## Behavioral rules
 
 These rules are non-negotiable and always apply:
```

## 5. Verification output (full CI battery, FOREGROUND — verify-full-ci-suite)

All commands ran in the foreground in this session, in workflow order
(`.github/workflows/validate-pack.yml` is the battery source of truth; 56 run
commands extracted and executed). Zero live `gh` calls; zero network calls; the
live C-7 oracle is not in the unattended workflow (default-SKIP honored). No
real-tree forward run (PLAN B2).

### 5.1 validate-pack (both CI validate-job steps)

```
$ python3 scripts/validate-pack.py
PASSED — all checks clean        (0 FAIL lines; advisory Check-48 WARNs only)

$ PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py
PASSED — all checks clean
```

(The first validate run after the initial edits FAILED on Check 22 — see plan
deviation PD-1 in §6; after the item-2 reword the full battery is green.)

### 5.2 Test suites (every `tests:`-job step, in workflow order; [rc] + summary)

```
[0] scripts/test-detect.sh :: === Results: 100 passed, 0 failed ===
[0] tracker-provider-test.sh :: All tests passed.
[0] tracker-config-test.sh :: All tests passed.
[0] tracker-init-test.sh :: All tests passed.
[0] tracker-agent-read-test.sh :: All tests passed.
[0] tracker-migrate-forward-test.sh :: All tests passed.
[0] tracker-migrate-reverse-test.sh :: All tests passed.
[0] tracker-migrate-roundtrip-test.sh :: All tests passed.
[0] test-tracker-phase-task.sh :: All tests passed.
[0] test-tracker-links.sh :: All tests passed.
[0] test-tracker-cycle-check.sh :: All tests passed.
[0] tracker-errors-test.sh :: All tests passed.
[0] tracker-config-schema-test.sh :: PASS: 34
[0] recommendation-state-schema-test.sh :: PASS: 19
[0] test-per-entry.sh :: All per-entry tests PASSED (57/57).
[0] test-validate-pack-checks-32-33-34 :: All BD-168 validate-pack Check 32/33/34 tests PASSED (85/85).
[0] test-validate-pack-checks-36-37-38 :: All tests passed.
[0] test-validate-pack-check-39 :: All tests passed.
[0] test-validate-pack-check-40 :: All tests passed.
[0] test-validate-pack-check-41 :: All tests passed.
[0] test-validate-pack-check-18 :: All tests passed.
[0] test-validate-pack-check-16 :: All tests passed.
[0] test-validate-pack-check-19 :: All tests passed.
[0] test-validate-pack-check-42 :: All tests passed.
[0] test-validate-pack-check-43 :: All tests passed.
[0] test-validate-pack-check-44 :: All tests passed.
[0] test-validate-pack-check-45 :: All tests passed.
[0] test-validate-pack-check-46 :: All tests passed.
[0] test-validate-pack-check-removed-doc-advisory :: All tests passed.
[0] test-validate-pack-check-49-field-faithfulness :: All tests passed.
[0] tracker-bd129-gh-repo-test.sh :: === Results: 14 passed, 0 failed ===
[0] tracker-bd130-doctor-wired-test.sh :: === Results: 24 passed, 0 failed ===
[0] tracker-bd132-race-test.sh :: === Results: 29 passed, 0 failed ===
[0] tracker-bd133-header-preservation-test.sh :: All tests passed.
[0] tracker-bd134-close-retry-test.sh :: === Results: 24 passed, 0 failed ===
[0] recommendation-test.sh :: All tests passed.
[0] pack-help-test.sh :: All tests passed.
[0] test-customization-preserve.sh :: All tests passed.
[0] test-init-project.sh :: All tests passed.
[0] test-migrate-v10-to-v11.sh :: All tests passed.
[0] test-migrate-v10-to-v11-dry-run.sh :: All BD-095 tests passed.
[0] test-migrate-v10-to-v11-gates.sh :: All BD-101 gate tests passed.
[0] test-migrate-v10-to-v11-decompose.sh :: All BD-165 decompose tests passed.
[0] test-migrator-core.sh :: === Results: 19 passed, 0 failed ===
[0] test-migrator-manifest.sh :: === Results: 12 passed, 0 failed ===
[0] test-migrator-capability-translation.sh :: === Results: 12 passed, 0 failed ===
[0] test-v11-realistic-ot.sh :: All v11-realistic-ot integration tests PASSED (33/33).
[0] test-migrator-skills.sh :: === Results: 19 passed, 0 failed ===
[0] test-persona-contracts.sh :: PASS (suite rc=0)
[0] template-translations-test.sh :: All tests passed.
[0] template-version-test.sh :: All tests passed.
[0] test-issue-forms.sh :: All tests passed.
```

Every suite rc=0; zero failures across the battery.

### 5.3 Targeted greps (PLAN §2.6 step 4)

```
$ grep -n "Flat-file mode\|Tracker mode\|Mode invariance" backlog/_rules.md changelog/_rules.md
changelog/_rules.md:26:**Mode invariance.** The pack-changelog stream is FLAT-FILE IN BOTH
backlog/_rules.md:22:absent file = flat-file). Tracker mode is a per-checkout LOCAL
backlog/_rules.md:28:**Flat-file mode (default).** The per-entry tree at `/backlog/` (plus
backlog/_rules.md:36:**Tracker mode (`state = "tracker"` + `forward_complete = true`,
backlog/_rules.md:134:- **Flat-file mode:** edit the per-entry file directly; entries
backlog/_rules.md:138:- **Tracker mode:** ALL entry creates / edits / status flips go
```

Both Check-32′ marker headings present in `backlog/_rules.md` § Source of truth;
"Mode invariance" marker present in `changelog/_rules.md`. The PACK-CHAT.md
section contains NO verbatim trinity-bullet body text (independently enforced
GREEN by Check 46's anti-restate scan over `pack-ops/PACK-CHAT.md`, §5.1).

### 5.4 Trinity byte-parity proof

```
$ for f in CLAUDE.md AGENTS.md GEMINI.md; do
    sed -n "/Per-entry trees — sole SSOT/,/no Resolved section/p" "$f" | sed '$d' | shasum; done
a04dc4bed2d9dc772f9c12678c9e33b74feb08ca  -
a04dc4bed2d9dc772f9c12678c9e33b74feb08ca  -
a04dc4bed2d9dc772f9c12678c9e33b74feb08ca  -
```

The full edited bullet region is byte-identical across the three root files
(identical SHA1). validate-pack's trinity-parity + Check 18 legs are green (§5.1).

### 5.5 Zero-phase-references proof (user directive)

```
$ git diff | grep "^+" | grep -v "^+++" | grep -in "phase" ; echo rc=$?
rc=1   (zero matches — no phase/phase-entity reference in any added line)
```

(Pre-existing `phase` occurrences elsewhere in the edited files — e.g.,
PACK-CHAT.md "v11-dev phase" — are untouched lines, outside this commit's diff.)

### 5.6 Manifest evidence (regenerate-manifest-v11-surface; pack-ops/ trigger fired)

```
$ bash test-fixtures/build.sh --all --clean
manifest written: .../test-fixtures/manifest.txt
$ git diff test-fixtures/manifest.txt
(empty — NO drift; matches PLAN §2.5 expectation: PACK-CHAT.md / root trinity /
 _rules.md trees are not fixture-affecting)
$ bash test-fixtures/build.sh --verify
  v10-realistic-ot OK: 4c62945f72b037908b38967d5d8f019745263258
  v11-realistic-ot OK: ae3fc6ff4956e365cba79699c724dce94559509c
  v11-flat-file OK: f9705c2740f8788a486b1a90bcf9448b57c04391
  v11-tracker-on OK: 944ddee3108ce3634327b8b6ee105cb0cd825e5a
  existing-project-mid-dev OK: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

`test-fixtures/manifest.txt` does NOT ride this commit (empty diff). The
manifest-drift arm of the keyword contingency therefore did NOT fire; the
keyword conclusion in §0 is driven solely by the maintenance-docs ride-alongs.

### 5.7 Symbol-name verification (self-review constraint)

Every symbol/label named in the new prose verified against source:
`tracker_edit_entry` (`scripts/lib/tracker-edit.sh`); `per_entry_regenerate_toc`
(`scripts/lib/per-entry/toc-regenerate.sh`); `pack-entry-body-gz64`
(`scripts/lib/tracker-migrate-forward.sh`, 4 occurrences); `pack tracker disable`
/ `doctor` (existing verbs in `scripts/pack-tracker.sh` usage table); labels
`work-item` / `inbound` / `needs-triage` (`scripts/lib/tracker-labels.sh`);
`<!-- pack-id: PENDING -->` (`.github/ISSUE_TEMPLATE/inbound.yml` +
`work-item.yml`). Forward-named (Commit-2) symbols: `pack tracker tree-rebuild`,
the `edit` / `new-entry` verbs — D1-7 accepted transient. Zero line-number
references in any added line (grep over added diff lines: rc=1, no match).

## 6. Plan deviations

1. **PD-1 — PLAN §2.2 "no CI check resolves verb names in prose" is FALSIFIED
   for word-only verb shapes; architecture §1.3 item 2's exact verb spans
   reworded.** Check 22 (`check_help_fragment_freshness`, `scripts/validate-pack.py`,
   `_VERB_RE`) scans `pack-ops/PACK-CHAT.md` for backtick spans matching
   `pack(\s\w+)+` and FAILS when the verb is absent from
   `pack-ops/HELP-FRAGMENT-PACK.md` + `pack-ops/HELP-FRAGMENT-TRACKER.md`. The
   architecture-specified literal `` `pack tracker edit` `` tripped it
   (first validate run: `FAIL: missing: \`pack tracker edit\``). Hyphenated
   verbs (`tree-rebuild`, `new-entry`) are regex-inert (`\w+` stops at `-`
   before the closing backtick). Fix applied WITHIN the scoped file set:
   PACK-CHAT.md item 2 names the verbs as ``the `pack tracker` `edit` /
   `new-entry` verbs`` (the bare `` `pack tracker` `` token resolves as a
   substring of the tracker fragment; the split spans are not verb-shaped).
   Semantic content unchanged; the fragment rows themselves remain Commit-2
   scope (PLAN §3.1 HELP-FRAGMENT-PACK.md row). Post-reword: all green.
2. **PD-2 — PACK-CHAT.md list numbering.** The architecture's content items
   are 1–9 (+ item 10 = table touch-up applied to the existing table) and
   Amendment-2's NEW "item 11" (caveat/publication). The rendered section
   numbers its list 1–10: design items 1–9 → list items 1–9; design item 11 →
   list item 10. A list jumping 9→11 would read as a typo; content mapping is
   1:1 and complete. Cosmetic only.
3. **PD-3 — caller's stage-list arithmetic.** The calling prompt says "the
   FOUR untracked workflow artifacts" but enumerates FIVE paths (architecture
   + two amendments + plan + research inventory). This report stage-lists all
   five enumerated paths (+ this report = six maintenance-docs files).
   Flagged, not silently resolved — Pack Chat confirms the intended set at
   the staging gate.

No other deviation: dated/historic content untouched; no full-file rewrites
(targeted Edits only; per-file diffs in §4 show every hunk); no entry files
touched; no `scripts/`, `project-template/`, `supporting-docs/` edits.

## 7. POQs introduced

- **POQ-1 — Commit-2 must land the help-fragment verb rows BEFORE restoring
  exact-verb prose, and the PD-1 reword may then be optionally reverted.**
  Problem: after Commit 2 adds `tree-rebuild` / `edit` / `new-entry` rows to
  `pack-ops/HELP-FRAGMENT-PACK.md` (already in PLAN §3.1), the PACK-CHAT.md
  item-2 wording MAY be restored to the architecture's literal
  `` `pack tracker edit` `` / `` `pack tracker new-entry` `` form (Check 22
  would then pass). Disposition: deferred to the Commit-2 cycle as an
  OPTIONAL one-line follow-up; recommended default = keep the current
  wording (it is semantically identical and keyword-shape-stable). Anchor:
  this report §6 PD-1 + the Commit-2 coder prompt (Pack Chat scopes it).
- **POQ-2 — none further.** No scope gaps, no architecture gaps beyond the
  recorded PD-1 empirical correction.

## 8. Boundary discipline check (P-missed-7)

Scoped edits touch ONLY pack-side operational surfaces: `/backlog/` +
`/changelog/` tree supporting files (`_rules.md` only — no entry files),
`pack-ops/PACK-CHAT.md`, and the pack-root trinity. ZERO edits under
`project-template/` or `supporting-docs/`:

```
$ git diff --name-only | grep -E "^(project-template|supporting-docs)/" | wc -l
0
```

No project-side SSOT investigation was required (no project-side file edited);
the project-side analogs of this contract are the architecture §5 R1–R8 +
Amendment-2 §B6 R10–R12 REQUIREMENTS handed to BD-206/BD-207 — deliberately not
implemented here. No pack-only reference was introduced into any project-side
file (none was touched). No "Boundary discipline stop" triggered.

## 9. Proposed commit + staging proposal

### 9.1 Proposed commit subject

```
docs: v11 — BD-204 Mode-3 ops contract on session-load surfaces (pack-only)
```

Approved `docs:` shape, BD-204 anchor. The keyword is the PLAN §2.5 / calling-
prompt contingency fallback — `pack-chat-only` is a CI-verified mis-claim on
the combined staged set (§0). If Pack Chat instead splits the ride-alongs into
a separate commit, the six-file commit may carry the plan's original
`pack-chat-only` subject. Final wording is the user's at the commit gate.

### 9.2 Files-changed inventory + stage-list (proposal only — agents never stage)

| Path | Change type | Role |
|---|---|---|
| `backlog/_rules.md` | modified (+68/−11) | D1-1 + D1-2 |
| `changelog/_rules.md` | modified (+10/−0) | D1-3 |
| `pack-ops/PACK-CHAT.md` | modified (+65/−1) | D1-4 + table touch-up |
| `CLAUDE.md` | modified (+8/−1) | D1-5 (trinity) |
| `AGENTS.md` | modified (+8/−1) | D1-5 (trinity) |
| `GEMINI.md` | modified (+8/−1) | D1-5 (trinity) |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md` | new (untracked, ride-along; NOT edited) | workflow artifact |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT.md` | new (untracked, ride-along; NOT edited) | workflow artifact (superseded; kept for audit) |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT-2.md` | new (untracked, ride-along; NOT edited) | workflow artifact (normative) |
| `maintenance-docs/v11-implementation/PLAN-BD-204-MODE3-OPS-CONTRACT.md` | new (untracked, ride-along; NOT edited) | workflow artifact |
| `maintenance-docs/v11-implementation/RESEARCH-REBASELINE-INVENTORY.md` | new (untracked, ride-along; NOT edited) | workflow artifact (see §6 PD-3 count flag) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-MODE3-OPS-COMMIT1.md` | new | this report |

NOT staged / NOT touched: `tracker.toml` (untracked local Mode-3 state; never
committed per ruling 4), `.pack-tracker/` (gitignored), `test-fixtures/manifest.txt`
(no drift), everything else (clean per `git status`).

## 10. Definition-of-Done checklist

| Item | Result | Evidence |
|---|---|---|
| D1-1 `/backlog/_rules.md` Source-of-truth mode-conditional rewrite, local-opt-in + publication + caveat text, both mode headings preserved | PASS | §4 diff; §5.3 marker grep (lines 28/36) |
| D1-2 Write-authority mode-conditional; Pack-Chat sentence verbatim; staging list = tree + `_toc.md` only; never-staged statement | PASS | §4 diff; `backlog/_rules.md` § Write authority |
| D1-3 `/changelog/_rules.md` Mode-invariance paragraph + local-opt-in clause; marker present; rest unchanged | PASS | §4 diff; §5.3 grep (line 26) |
| D1-4 PACK-CHAT.md new section (items 1–9 + caveat item) after § File access strategy + table Why-cell touch-up | PASS | §4 diff; §6 PD-2 numbering note |
| D1-5 Trinity append ×3 with Amendment-2 clause, byte-identical | PASS | §5.4 identical SHA1 ×3 |
| D1-6 No id-map staging clause anywhere (OQ-1 closed) | PASS | §3 D1-6 grep (0 hits) |
| D1-7 Forward-naming transient bounded + CI-green | PASS (with PD-1 correction) | §5.1 green; §6 PD-1 |
| Superseded AMENDMENT content NOT introduced | PASS | header note; 0 refs to `pack-ops/tracker-id-map.json` in diff |
| Zero phase references in pack-side added text | PASS | §5.5 (rc=1) |
| `python3 scripts/validate-pack.py` green (incl. trinity parity, 18, 32′, 33, 36, 40, 44, 45, 46) | PASS | §5.1 "PASSED — all checks clean" |
| `PACK_VALIDATE_DEEP=1` run green | PASS | §5.1 |
| Full unattended battery green, foreground; live oracle default-SKIP; no live `gh` | PASS | §5.2 (all rc=0) |
| Fixture rebuild + EMPTY manifest diff + `--verify` OK | PASS | §5.6 |
| Check-36 keyword verified against FINAL staged set; conclusion surfaced prominently | PASS | §0 (fallback `pack-only`) |
| No git state changes; no edits outside the D1 set; ride-alongs unedited | PASS | §12 evidence row 1; `git status` (§2 vs final: only the 6 files + this report changed) |

## 11. READ-IN-FULL attestation (path + line count, read this session)

| # | File | Proof |
|---|---|---|
| 1 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` | Read IN FULL via Read tool, 580 lines pre-edit (incl. complete `## Pack memory`, lines 140–580). |
| 2 | `maintenance-docs/v11-implementation/PLAN-BD-204-MODE3-OPS-CONTRACT.md` | Read IN FULL, 451 lines (`wc -l` verified). |
| 3 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md` | Read IN FULL, 556 lines (`wc -l` verified). |
| 4 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT-2.md` | Read IN FULL, 624 lines (`wc -l` verified). |
| 5 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT.md` | Read IN FULL, 384 lines — recognition-only per calling prompt (content NOT applied). |
| 6 | `/backlog/_rules.md` | Read IN FULL pre-edit, 94 lines; re-read IN FULL post-edit, 152 lines. |
| 7 | `/changelog/_rules.md` | Read IN FULL pre-edit, 66 lines; edited region re-read post-edit. |
| 8 | `pack-ops/PACK-CHAT.md` | Read IN FULL pre-edit, 324 lines (incl. § File access strategy, § Behavioral rules, § Keeping CLAUDE.md…current + rule-change propagation procedure); new section re-read post-edit. |
| 9 | `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_edit_in_place_not_full_rewrite.md` | Read IN FULL, 15 lines. |
| 10 | `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_verify_full_ci_suite.md` | Read IN FULL, 43 lines. |
| 11 | `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_agent_output_rules_applied_block.md` | Read IN FULL, 15 lines; its conditional MUST-READ honored — `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block` (lines 206–233 region) read directly this session. |
| 12 | Supporting reads: `pack-ops/PACK-AGENTS.md` FULL (224 lines); root `AGENTS.md` / `GEMINI.md` bullet regions (lines 430–464 / 397–431) + byte-parity hash of full files' bullet region; `.claude/skills/{implementation-report,commit-discipline,verification-harness,boundary-investigation}/SKILL.md` FULL (139/174/218/186 lines); `scripts/validate-pack.py` Check-36 constants region (3990–4109), Check-40 region (5029–5193), Check-46 region (6780–6909), Check-22 region (1995–2121); `.github/workflows/validate-pack.yml` run-command extraction (56 commands); `scripts/tests/test-per-entry.sh` Write-authority fixture context (150–184). |

No named document was derived rather than read; every file above was opened via
Read/Bash this session at HEAD `9127907`.

## 12. Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| **agents-never-commit** | Git verbs run this session: `git rev-parse HEAD`, `git status --porcelain`, `git branch --show-current`, `git diff` (incl. `--stat`/`--numstat`/`--name-only`), `git ls-files` — read-only only. Zero `add/commit/push/tag/stash/reset/restore/checkout/rm` invocations (full bash history of this session contains none). Output = working-tree edits to the 6 scoped files + this report; the §9.2 stage-list is a PROPOSAL, no staging performed. | COMPLIANT |
| **per-action-approval-sub-agents** | Zero destructive ops: no `rm -rf`, no `git rm`, no overwrite of any trusted file — this report's path was verified non-existent pre-write (`ls maintenance-docs/v11-implementation/ \| grep IMPL-REPORT-MODE3` → only after my Write); scratch files confined to `/tmp/mode3-c1-diff.txt` + `/tmp/r1.md`. `tracker.toml` + `.pack-tracker/` untouched. Zero live GitHub calls (no `gh`, no GitHub MCP tools). | COMPLIANT |
| **preflight-stop-means-stop** | Emitted before this report's first Write, verbatim: `PREFLIGHT: 6/6 in-scope file edits complete; verification PASS; HEAD 9127907edd27a53e7504e5896365a8d01ff5561f; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-MODE3-OPS-COMMIT1.md`. The one verification failure encountered mid-run (Check 22) was FIXED before PREFLIGHT, not papered over (§6 PD-1). No parent stop/halt/revert message received; all commands ran FOREGROUND to completion (zero background tasks armed). | COMPLIANT |
| **agent-output-rules-applied-block** | This table: 10 rows (one per "Rules in force" item), each with quoted command/output evidence; zero empty cells. Format per `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block` (read this session per the memory file's MUST-READ line — §11 row 11). | COMPLIANT |
| **agents-read-rule-docs-in-full** | §11 attestation: all calling-prompt-named files read IN FULL with line counts (CLAUDE.md 580; plan 451; architecture 556; amendment-2 624; amendment 384; backlog/_rules 94; changelog/_rules 66; PACK-CHAT.md 324; three memory files 15/43/15) + supporting section-reads enumerated (§11 row 12). | COMPLIANT |
| **verify-full-ci-suite** | §5.1 both validate-pack runs ("PASSED — all checks clean" ×2, incl. `PACK_VALIDATE_DEEP=1`); §5.2 all 53 test-suite commands from the workflow run foreground with rc=0 and quoted summary lines (incl. the INTEGRATION suite `test-v11-realistic-ot.sh` 33/33); §5.6 fixture build + verify sequence. Live oracle default-SKIP (not in unattended workflow); zero `gh` calls. Battery source = `.github/workflows/validate-pack.yml` (56 run commands extracted; all executed). | COMPLIANT |
| **regenerate-manifest-v11-surface** | `pack-ops/PACK-CHAT.md` touched → trigger fired → `bash test-fixtures/build.sh --all --clean` run; `git diff test-fixtures/manifest.txt` EMPTY (quoted §5.6); `--verify` all 6 fixture rows OK. Manifest does not ride the commit; keyword contingency driven by ride-alongs only (§0). | COMPLIANT |
| **edit-in-place-not-full-rewrite** | 8 targeted Edit-tool calls over 6 files (zero Write-tool full-file rewrites of existing files); every edited region RE-READ post-edit (backlog/_rules.md full re-read 152 lines; changelog 18–35; PACK-CHAT.md 59–135 + table row; CLAUDE.md 469–495 + parity hash ×3); untouched text byte-stable — `git diff --numstat` shows exactly the intended hunks (8/1 ×3 trinity, 68/11 backlog, 10/0 changelog, 65/1 PACK-CHAT). | COMPLIANT |
| **boundary-investigation** | §8: `git diff --name-only \| grep -E "^(project-template\|supporting-docs)/" \| wc -l` → `0`. Pack-side ops surfaces only; project-side analogs remain BD-206/207 R-section requirements; no pack-only reference introduced into any project-side file. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Touched set == D1 file set exactly (6 files; `git status` diff list quoted §2/§9.2); the single in-scope wording adjustment beyond the recipes (PD-1) was forced by a CI gate, applied within the scoped file, and documented; discoveries surfaced as POQ-1 + PD-1..PD-3, not silently expanded; ride-alongs stage-LISTED only, never edited. | COMPLIANT |

---

**End of IMPL-REPORT-MODE3-OPS-COMMIT1.md**
