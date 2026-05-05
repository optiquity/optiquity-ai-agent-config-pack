# IMPLEMENTATION-PLAN-ADDENDUM-2 — v11.0

## §0. Status

- **Date.** 2026-05-04.
- **Scope.** Closes the 2 remaining gaps after `IMPLEMENTATION-PLAN.md` (BD-060..BD-093) and `IMPLEMENTATION-PLAN-ADDENDUM.md` (BD-094..BD-101): (1) no explicit pack-repo dog-food migration BD; (2) no recovery path with bulk-delete tooling for when GH-side state goes wrong.
- **Adds.** BD-102 (pack-repo dog-food migration as final v11 validation) + BD-103 (`pack tracker reset` verb + 3-level recovery doc). Continues from BD-101; no renumbering of existing 42 BDs.
- **Updates.** Base plan §3.3 commit-order (insertions only, lettered after step 33a / before step 34); §6 MAINTAINER CHECK NEEDED list (2 new items §6.J, §6.K); §7 release-readiness checklist (new checkboxes).
- **Constraints honored.** General-use (zero OT/Optiquity strings in user-facing artifacts produced by either BD); A1 failure-mode UX globally; trinity rule N/A (neither BD touches trinity files); no new architecture decisions — sequencing and specificity only; pack-vs-PM-Chat workflow distinction documented per §2.
- **Acyclic.** BD-102 blockers: BD-101 (gates), BD-097 (audit), BD-100 (CP3) — all earlier (Addendum 1) or in base plan. BD-103 blockers: BD-066, BD-067, BD-070, BD-084, BD-098 — all in base plan + Addendum 1. No new cycles.
- **Highest BD now.** BD-103.

---

## §1. New BDs

### §1.1 BD-102 — Pack-repo dog-food migration (final v11 validation)

**Title.** Run the v11 migrator + tracker init against the pack's own working tree as the final pre-release validation; produce a confidence report; decide ship-in-tracker-or-flat; reverse if shipping flat.

**Type.** TODO(version)

**Scope.** B

**Workflow surface.** **Pack-Chat-direct.** The pack maintainer invokes the verbs themselves from a pack-repo shell, not via PM Chat. PM Chat is the client-side mediator surface (§2). This BD's audience is the maintainer.

**Files.**
- `maintenance-docs/v11-implementation/DOG-FOOD-MIGRATION-REPORT.md` (new — maintainer-authored, post-run). Report shape per §1.1.4 below.
- `scripts/tests/dog-food-checkpoint.sh` (new) — captures pre-run working-tree state (sha256 manifest of every file under VCS) so the post-reverse diff is mechanical, not subjective. Read-only against the working tree; writes only to `/tmp/pack-dogfood-checkpoint-<timestamp>.json`.
- `BACKLOG.md` (read-only target — the dog-food input). The pack's existing BD entries are the migration input.
- `CHANGELOG.md` (modified — extends BD-087) — v11.0 entry cites the dog-food report path as a release-evidence artifact alongside the BD-097 semantic audit and BD-100 checkpoint reports.

**Description.** §7 of the base plan has a release-readiness checkbox ("Tracker opt-in path verified end-to-end on the pack repo itself, per `DESIGN-BRIEF.md` §4.2") but no concrete BD owns it. This BD is that owner. It is the highest-confidence validation the pack can do because it uses the pack's own real BACKLOG (≈60+ BDs across resolved + open) and the pack's own real CI / agent / skill infrastructure as the substrate. A pass here predicts client migration will work; a failure here means v11.0 is not release-ready.

**Sequence.** Lands **after** BD-101 (Addendum 1 gates wired) and BD-097 (semantic audit pass green) and BD-100 CP3 (Scope-B integrated audit pass), and **before** BD-093 (release pin). Concretely: between current §3.3 step 33a (BD-097) and step 34 (BD-093). See §3.1.

**Procedure (the maintainer runs these verbs in this order).**

1. **Pre-run checkpoint.** `bash scripts/tests/dog-food-checkpoint.sh capture` — writes the manifest. Verify clean working tree (`git status` empty).
2. **Dry-run.** `bash scripts/migrate-v10-to-v11.sh --dry-run` (BD-095 mode). Review the resulting `.pack-tracker/migrate-v10-to-v11.dry-run-report.md`. Maintainer sanity-checks the per-file plan against their own knowledge of the pack repo.
3. **Apply.** `bash scripts/migrate-v10-to-v11.sh --apply`. Gate 2 (BD-101) runs at end of Phase A. Maintainer reviews Gate 2 output; if green, the script proceeds to ask about Phase B. Maintainer **answers no** to Phase B at this step (the migrator's interactive Phase B question), because Phase B opt-in is exercised separately in step 4 to keep concerns separated.
4. **Phase B opt-in (forward).** `bash scripts/pack-tracker.sh init` (BD-066). Answer prompts; verify `tracker.toml` written; verify GH issues created; verify mirror files regenerated; verify recommendation prompt no longer fires post-init (BD-072 + BD-077 behavior).
5. **Doctor.** `bash scripts/pack-tracker.sh doctor` (BD-066). Expect green: mapping integrity holds, mirror files fresh, every BACKLOG entry has matching `<!-- pack-id: BD-NNN -->` marker on its issue, every issue has matching BACKLOG entry.
6. **Phase B opt-out (reverse).** `bash scripts/pack-tracker.sh disable` (BD-067). Verify reverse migration completes; verify sidecar present; verify `tracker.toml mode.state` flipped to `flat-file`.
7. **Reverse round-trip diff.** `bash scripts/tests/dog-food-checkpoint.sh diff` against the post-reverse working tree. Expectation: whitespace-only diff (matches §7 release-readiness existing checkbox at line 1105 of the base plan).
8. **Author the report** at `maintenance-docs/v11-implementation/DOG-FOOD-MIGRATION-REPORT.md` (§1.1.4 below).
9. **Ship decision.** Per §1.1.5 below — proposed default is to **leave the pack in flat-file mode for v11.0 release**. If the maintainer chose to opt-in for evaluation, run `pack tracker disable` once more before BD-093 release pin. The post-disable working tree is the v11.0 release commit.

**§1.1.4 Report content (the report MUST contain these sections).**

```
# v11.0 Dog-Food Migration Report

## Summary
- Date: <ISO 8601>
- Source pack version: v10.x (specific minor)
- Target pack version: v11.0
- Outcome: PASS | PASS-WITH-DEVIATIONS | FAIL
- Ship decision: tracker | flat-file

## Inputs
- Input BD count (from BACKLOG.md, by Status):
  - Open: N
  - Resolved: M
  - Total processed: N+M
- Pack-repo working-tree fingerprint (pre-run): <sha256>

## Forward migration (Phase A)
- Files touched: <count>
- Customizations preserved: <count>
- BD-101 Gate 2: pass | fail
- Per-stage timing:
  - Trinity addenda apply: <seconds>
  - HELP-FRAGMENT install: <seconds>
  - Source column add: <seconds>
  - BD-042 relocation: <seconds>
  - validate-pack run: <seconds>
- Total Phase A wall-clock: <seconds>

## Forward migration (Phase B / tracker init)
- Issues created: <count>
- Sub-issue links established: <count>
- Mapping file populated: yes | no
- Mirror files generated: yes | no
- BD-101 Gate 3: pass | fail
- Per-stage timing:
  - Label / template ensure: <seconds>
  - Issue create loop: <seconds>
  - Mirror regeneration: <seconds>
- Total Phase B wall-clock: <seconds>

## Idempotency-marker integrity
- Every BACKLOG BD-NNN has matching `<!-- pack-id: BD-NNN -->` on its issue: yes | no
- Every pack-marked issue has matching BACKLOG entry: yes | no
- Mismatches: <enumerated; empty list = clean>

## Reverse round-trip
- Reverse migration completed: yes | no
- Working-tree diff vs pre-run checkpoint: whitespace-only | substantive
- Substantive diff details: <enumerated; empty = clean>
- Sidecar file present and well-formed: yes | no

## Recommendation prompt behavior
- Pre-init: prompt fires when threshold reached (BD-072): yes | no
- Post-init: prompt suppressed: yes | no
- Refusal mechanism (BD-073): exercised | not exercised

## Deviations from BD-085 / BD-101 expected behavior
<enumerated; empty list = clean>

## Confidence statement for client migration
- Properties verified that predict client-migration success:
  1. Idempotency-marker integrity holds end-to-end.
  2. Reverse round-trip diff is whitespace-only.
  3. BD-101 Gates 1, 2, 3 each pass on a real (not synthetic) input.
  4. Mirror files match flat files post-reverse.
  5. Recommendation prompt fires correctly post-init.
  6. Per-stage timing within expected bounds (informs client expectations).
- Properties NOT verified by this dog-food run (call out for client docs):
  <enumerated; e.g., heavy-customization shapes, language-heterogeneous shapes — those are covered by BD-096 fixtures, not by dog-food>

## Ship decision rationale
<one paragraph; see §1.1.5 of Addendum 2>
```

**§1.1.5 Ship decision.**

- **Proposed default: ship v11.0 in flat-file mode.** Rationale: clients on v11.0 start in flat-file mode by default (tracker is opt-in per V3 §28.2); if the pack itself ships in tracker mode, the pack repo's state-file shape diverges from clients' starting state, complicating mental models for both maintainers (eat-own-dog-food must mirror client experience to be honest) and contributors (PRs against a tracker-mode pack require `gh` auth to interact with backlog state).
- **Mechanic.** If the maintainer ran step 4 (Phase B opt-in) for evaluation, run `pack tracker disable` once more before BD-093 release pin. The post-reverse working tree is the v11.0 release commit. The dog-food report records both forward and reverse outcomes regardless of ship decision.
- **Maintainer can opt back in post-release.** A separate post-v11.0 commit on main can run `pack tracker init` if desired; it is not part of the v11.0 cut.
- **MAINTAINER CHECK §6.J** (see §3.3) — maintainer explicitly confirms the ship decision in writing inside the dog-food report's "Ship decision rationale" section before BD-093.

**Blockers.** BD-101 (gates wired); BD-100 CP3 (Scope-B integrated audit pass green); BD-097 (semantic audit pass green); BD-067 (reverse migration, for the round-trip); BD-066 (`pack tracker init` + `doctor`); BD-085 (migrator); BD-084 (MIGRATION doc — the maintainer reads it during the run as the user would).

**Verification.**
- Report exists at `maintenance-docs/v11-implementation/DOG-FOOD-MIGRATION-REPORT.md`; all sections per §1.1.4 present.
- Report Outcome is `PASS` or `PASS-WITH-DEVIATIONS` (each deviation has a maintainer disposition note matching the BD-097 audit shape).
- Reverse round-trip diff is whitespace-only (matches base plan §7 line 1105 checkbox).
- Idempotency-marker integrity is clean.
- Ship-decision section explicitly records the choice and rationale.
- `grep -i "OT\|Optiquity" maintenance-docs/v11-implementation/DOG-FOOD-MIGRATION-REPORT.md` may legitimately return hits (this is pack-internal maintainer documentation, not user-facing). Constraint applies to user-facing artifacts only; document this exception explicitly in the report's first paragraph.

**Failure handling.**
- Any step fails → halt. Address. Open follow-up BD if a regression is found in BD-085 / BD-088 / BD-101 / BD-066 / BD-067. Re-run from step 1.
- If the reverse round-trip diff is non-empty (substantive), that is a regression in BD-067 — halt v11.0 release; this is a release-blocker.
- If idempotency-marker integrity fails, halt — this indicates BD-064 forward-migration / BD-067 reverse-migration mismatch.
- If Gate 2 or Gate 3 fails, halt — this indicates BD-101 regression.

**Definition-of-Done.** Procedure executed; report authored at named path with all §1.1.4 sections; outcome PASS or PASS-WITH-DEVIATIONS; ship decision recorded; reverse round-trip diff clean; report cited in CHANGELOG v11.0 entry as release-evidence; pack working tree at release commit reflects the chosen ship mode (proposed: flat-file).

---

### §1.2 BD-103 — `pack tracker reset` verb + 3-level recovery documentation

**Title.** Add `pack tracker reset` subcommand for friction-by-design bulk-delete of pack-marked GH issues; document 3 recovery levels (soft / hard / nuclear); add CI test for forward → reset → forward cycle; cross-link from MIGRATION + OPTIONAL-FEATURES.

**Type.** TODO(version)

**Scope.** B

**Workflow surface.** **Both.** Pack maintainer uses it directly during dog-food / development (Pack-Chat-direct). Client users reach it via PM Chat routing rules when they hit a "migration produced wrong-shape issues" failure mode (PM-Chat-mediated). The verb is the same in both surfaces; the discovery surfaces differ.

**Files.**
- `scripts/pack-tracker.sh` (modified — extends BD-066) — adds the `reset` subcommand. Subcommand surface:
  - `pack tracker reset` (no flag) → prints the count of pack-marked issues that would be deleted, prints 3 example titles, prints the long confirm flag the user must add, then exits 1 without deleting.
  - `pack tracker reset --confirm-i-have-admin-and-want-to-delete-all-pack-issues` → performs the bulk delete.
  - **MAINTAINER CHECK §6.K** (see §3.3) — exact confirm-flag string. Proposed: `--confirm-i-have-admin-and-want-to-delete-all-pack-issues`. Rationale for length: must not be typeable by accident; must be visible in shell history during incident review; must be self-documenting (anyone reading it knows what it does).
- `scripts/lib/pack-tracker/reset.sh` (new) — reset implementation. Behavior:
  1. Verify `gh auth status` (BD-066 prerequisite check).
  2. Verify admin permission: attempt `gh api /repos/{owner}/{repo} -q .permissions.admin` and assert `true`. If non-admin, surface actionable error per BD-070 typed-error model: error code `TRACKER_RESET_REQUIRES_ADMIN`; diagnostic naming the auth identity and the target repo; next-step verb (`Re-authenticate with an account that has admin permissions on this repo, or use a soft recovery via 'pack tracker disable' + 'pack tracker init'`).
  3. Enumerate candidate issues: `gh issue list --search 'in:body "<!-- pack-id:"' --state all --limit 1000 --json number,title,body`. Filter to those whose body actually contains the marker (search is best-effort; filter is authoritative).
  4. Without confirm flag: print count + 3 example titles + the long confirm flag → exit 1.
  5. With confirm flag: loop and delete each issue via `gh issue delete <number> --yes`. Throttle: one issue per 100ms (10/s) to stay well under the 5,000/h authenticated rate limit. Tally successes + failures; on per-issue failure, log and continue (do not halt mid-loop — partial completion is recoverable; halt-on-error is not).
  6. Post-loop: clear `.pack-tracker/forward-migration-mapping.*` (the mapping file BD-064 wrote) since its issue numbers are now stale. Sidecar (BD-067) is preserved — it still has the round-trip data needed if the user later runs `pack tracker init` from flat-file state.
  7. Print summary + next-step guidance ("Run `pack tracker init` to forward again, or restore from backup if you intended a nuclear recovery").
- `scripts/tests/test-tracker-reset.sh` (new) — CI test. Fixture-based forward → reset → forward cycle on a sandbox (uses the same sandbox harness as BD-066 round-trip-test.sh). Cases:
  - `reset` without confirm flag exits 1 with the "would delete N" output and no deletions occurred.
  - `reset` with confirm flag deletes only marker-matched issues; user-created issues without the marker are untouched (fixture seeds 2 marker-matched + 2 user-created issues; expects 2 deletions, 2 preserved).
  - `reset` with non-admin auth fails with `TRACKER_RESET_REQUIRES_ADMIN` (mocked).
  - Sub-issue interaction: deleting a child issue auto-cleans the parent's sub-issue list; deleting a parent leaves children orphaned (no cascade); test asserts both behaviors.
  - Post-reset `pack tracker init` succeeds on the same input; resulting issue numbers differ but `<!-- pack-id: BD-NNN -->` markers match; mapping file repopulated.
- `supporting-docs/MIGRATION-v10-to-v11.md` (modified — extends BD-084) — Phase B troubleshooting subsection adds "Recovery levels" with the 3-level table below (cross-link only — full content lives in OPTIONAL-FEATURES per BD-098).
- `OPTIONAL-FEATURES.md` (modified — extends BD-098) — § GitHub Issue Tracker → "Failure modes" subsection extended with the 3-level recovery walkthrough (full content). Cross-links to `supporting-docs/MERGE-STRATEGY.md` for Phase A conflicts (already present) and to BD-070 typed-error reference.
- `HELP-FRAGMENT-pack-tracker.md` (or whichever fragment lists `pack tracker` verbs — set by BD-076) (modified) — adds `pack tracker reset` row + one-line description ending with "(destructive; requires admin and explicit confirm flag)".
- `PACK-CHAT.md` and `project-template/docs/pack/PM-CHAT.md` (modified — extends BD-092 + Addendum 1 BD-098 reference) — add a one-line entry under tracker orchestration: PACK-CHAT records that maintainer can invoke `pack tracker reset` directly during dog-food iteration; PM-CHAT records that when a client user reports "migration produced wrong-shape issues", the routing rule sends them to OPTIONAL-FEATURES.md "Failure modes" rather than to `pack tracker reset` directly (mediated discovery, friction-by-design).

**Description.** Migration can succeed at the script level but produce GH-side state the user does not want (e.g., wrong issue templates were ensured before init; sub-issue links missed because the `gh-sub-issue` extension was not installed; the user wants a fresh start after a customization-preserve fix). Without `pack tracker reset`, recovery requires either manual one-by-one issue deletion (impractical at pack scale: ≈60 BDs) or full repo restore (nuclear; loses non-pack issues + comments). This BD ships the missing middle option and documents all three recovery levels so the user can pick the right tool.

**§1.2.4 Three recovery levels (lives in OPTIONAL-FEATURES.md per BD-098).**

| Level | Trigger | Commands | Preserves | Loses | Reversible |
|-------|---------|----------|-----------|-------|------------|
| **Soft** | Mostly-good state with a few wrong-shape issues; want to fix in place. | `pack tracker disable` → fix the offending entries in `BACKLOG.md` / `IMPLEMENTATION_PLAN.md` → `pack tracker init` | Idempotency markers; user comments on existing issues; any user-created issues; cross-links. | Nothing material; re-init is mostly a no-op for unchanged entries (idempotency-marker preservation per BD-064). | Yes — reverse-migration sidecar restores prior state. |
| **Hard** | State is fundamentally wrong; fastest path is a fresh forward. | `pack tracker disable` → `pack tracker reset --confirm-...` → `pack tracker init` | User-created issues without `<!-- pack-id: -->` marker; sidecar; flat files. | All pack-marked issue history (comments, reactions, cross-references); old GH issue numbers (new ones assigned on re-forward — same TD-NNN markers). | Partial — flat files round-trip cleanly; GH-side history is gone. |
| **Nuclear** | Repo-wide corruption; not specific to tracker; want full restore. | `bash scripts/restore-from-backup.sh` (existing pack utility) | Whatever the backup captured. | Anything after the backup timestamp. | Out-of-scope for `pack tracker`; depends on backup mechanism. |

**§1.2.5 Sub-issue interaction.** Per the GH Issues API: deleting a child issue auto-removes it from the parent's sub-issue list (no cascade). Deleting a parent issue leaves children intact but orphaned (their `parent` reference becomes invalid; they appear unparented in the GH UI). `pack tracker reset` does not attempt to topologically order the deletion — it deletes in `gh issue list` order. The forward → reset → forward cycle restores the parent-child relationships from BACKLOG / IMPLEMENTATION_PLAN data (BD-064 already does this on every forward run, so this is a no-op verification rather than a new behavior).

**§1.2.6 Rate-limit considerations.** `gh` authenticated rate limit is 5,000 requests / hour. One issue delete = one DELETE request. Pack scale: ≈60 BDs → ≈60 deletes → 6 seconds at 10/s → well under the limit. The 100ms throttle is a courtesy + safety margin, not a hard constraint. Larger pack scales (hundreds) remain comfortably under.

**§1.2.7 Friction-by-design rationale.** The long confirm flag is intentionally awkward to type. It cannot be derived from a guess; it must be copied. Shell history captures it verbatim, surfacing intent at incident-review time. The flag string itself is a contract: changing it would require a deprecation cycle, so MAINTAINER CHECK §6.K matters.

**Blockers.** BD-066 (`pack-tracker.sh` script the subcommand attaches to); BD-067 (sidecar mechanic the soft recovery relies on); BD-070 (typed-error model for the non-admin error); BD-076 (HELP-FRAGMENT files exist); BD-084 (MIGRATION doc exists for cross-link); BD-098 (OPTIONAL-FEATURES tracker section exists for cross-link).

**Verification.**
- `scripts/tests/test-tracker-reset.sh` covers all 5 cases above; CI green.
- Manual smoke during BD-102 dog-food: maintainer runs `pack tracker reset` against the dog-food sandbox to confirm the verb works on real data; this is recorded as a step in the dog-food report (§1.1.4 deviations section if any anomalies).
- `grep -i "OT\|Optiquity" supporting-docs/MIGRATION-v10-to-v11.md OPTIONAL-FEATURES.md HELP-FRAGMENT-pack-tracker.md` returns zero hits in BD-103-modified content.
- validate-pack Check 22 (BD-082) — `pack tracker reset` verb appears in HELP-FRAGMENT.
- BD-097 semantic-audit re-run after BD-103 lands — confirms recovery-doc prose matches script behavior; specifically confirms the confirm-flag string in the doc matches the string in `scripts/lib/pack-tracker/reset.sh`.

**Definition-of-Done.** `pack tracker reset` subcommand wired; admin-permission check + confirm-flag check enforced; bulk-delete loop with rate-limit-aware throttling implemented; CI test green; 3-level recovery documented in OPTIONAL-FEATURES.md (full) + MIGRATION-v10-to-v11.md (cross-link); HELP-FRAGMENT updated; PACK-CHAT + PM-CHAT one-liners added per workflow distinction (§2); validate-pack exits 0.

---

## §2. Pack vs PM Chat workflow distinction

The two BDs in this addendum interact with the pack-vs-PM-Chat distinction in different ways. This section is the contract.

**Pack-Chat-direct surface.** The pack maintainer working on the pack repo. Pack Chat (per `PACK-CHAT.md`) handles BACKLOG / CHANGELOG / approvals; agents (per `PACK-AGENTS.md`) handle architecture / planning / review. There is no PM-style mediator between maintainer and verbs — the maintainer types `bash scripts/pack-tracker.sh init` themselves.

**PM-Chat-mediated surface.** The client project user working on their own project (a project that consumes the pack template). PM Chat (per `project-template/docs/pack/PM-CHAT.md`) is the conversational entry point. PM Chat orchestrates: when the user expresses intent ("I want to use GitHub Issues to track this work" or the recommendation prompt fires per V3 §28.1 / §28.2), PM Chat routes them to `pack tracker init`. PM Chat does **not** route directly to `pack tracker reset` — that verb is reachable only via the OPTIONAL-FEATURES.md "Failure modes" subsection (mediated discovery, friction-by-design layered on top of the confirm-flag friction).

**BD-102 implications.**
- Pack-side only. Maintainer invokes verbs directly. No PM Chat involvement.
- The dog-food report's "Confidence statement for client migration" section explicitly bridges to the client-side: "the verbs that worked here are the same verbs PM Chat will route client users to."
- The ship decision (flat-file vs tracker for v11.0) is a Pack-Chat decision the maintainer documents in the report; it has no PM-Chat-mediated equivalent.

**BD-103 implications.**
- Both surfaces converge on the same `pack tracker reset` verb.
- Pack-side discovery: HELP-FRAGMENT lists it; maintainer reads HELP-FRAGMENT directly.
- Client-side discovery: PM Chat does not surface it proactively. User reaches it via OPTIONAL-FEATURES.md "Failure modes" only after they describe a problem PM Chat recognizes as "migration-produced-wrong-shape-issues." This mediated path is documented in `project-template/docs/pack/PM-CHAT.md` as a routing rule; maintenance of the routing rule is a Pack-Chat responsibility.
- The confirm-flag friction is identical on both surfaces (the verb itself enforces it). The discovery friction is asymmetric (pack-side: one-hop; client-side: two-hop through PM Chat).

This asymmetry is intentional. Maintainers iterate during dog-food and need fast access. Client users encounter `reset` once or never; mediated discovery prevents accidental destructive use.

---

## §3. Updates to base plan

### §3.1 §3.3 commit-order integration (insertions only)

The base plan §3.3 sequence is steps 1..34. Addendum 1 inserted lettered steps (19a, 20a, 22a, 22b, 30a, 30b, 33a). Addendum 2 inserts two more, late in the sequence:

- **After step 33a (BD-097 semantic audit), insert step 33b: BD-103 — `pack tracker reset` + recovery doc.** Rationale: BD-103 is documentation + a new subcommand on existing infrastructure; lands after audit so audit can include the new prose; lands before dog-food so dog-food can exercise the new verb on real data.
- **After step 33b (BD-103), insert step 33c: BD-102 — pack-repo dog-food migration.** Rationale: dog-food is the final validation; consumes everything above; produces the report cited in CHANGELOG.

Updated tail of §3.3 (illustrative; full edit lands when this addendum is approved):

```
... 32. BD-086
33. BD-087
    33a. BD-097 — semantic audit
    33b. BD-103 — pack tracker reset + recovery doc
    33c. BD-102 — pack-repo dog-food migration
34. BD-093 — release pin
```

CI green at every numbered + lettered boundary. Note: BD-102 step 9 (ship decision: optional `pack tracker disable` to return to flat-file) executes within step 33c, not as a separate step; the working tree at the end of step 33c is the input to step 34's release pin.

### §3.2 §7 release-readiness checklist additions

Append to the existing `## §7. Definition of v11.0 release-readiness` checklist (after Addendum 1's additions):

- [ ] **BD-102 dog-food report** exists at `maintenance-docs/v11-implementation/DOG-FOOD-MIGRATION-REPORT.md`; outcome PASS or PASS-WITH-DEVIATIONS; reverse round-trip diff is whitespace-only; idempotency-marker integrity clean; ship decision recorded with rationale.
- [ ] **BD-102 ship decision applied**: working tree at v11.0 release commit reflects chosen mode (proposed: flat-file; if maintainer chose tracker, document why in the report).
- [ ] **BD-103 `pack tracker reset` subcommand** wired; admin-permission check + confirm-flag check enforced; `scripts/tests/test-tracker-reset.sh` green.
- [ ] **BD-103 recovery documentation**: OPTIONAL-FEATURES.md "Failure modes" subsection contains full 3-level table (soft / hard / nuclear); MIGRATION-v10-to-v11.md Phase B troubleshooting cross-links to it; HELP-FRAGMENT lists `pack tracker reset`; PACK-CHAT + PM-CHAT one-liners present.
- [ ] **General-use audit (Addendum 2 scope)**: `grep -i "OT\|Optiquity" OPTIONAL-FEATURES.md supporting-docs/MIGRATION-v10-to-v11.md HELP-FRAGMENT-pack-tracker.md` returns zero hits in BD-103-modified content. (BD-102 dog-food report is pack-internal maintainer doc; exempt; documented exemption in report intro.)
- [ ] **BD-103 forward-reset-forward CI cycle** passes against sandbox fixture.
- [ ] **Pack vs PM Chat workflow distinction** documented in PACK-CHAT.md (direct invocation note) and PM-CHAT.md (routing-rule note for `pack tracker reset` mediated discovery).

The existing checkbox at base plan line 1104 ("Tracker opt-in path verified end-to-end on the pack repo itself") is now satisfied by BD-102; cross-reference in the §7 prose at release-pin time.

The existing checkbox at base plan line 1105 ("Reverse-migration verified: from tracker mode, run `pack tracker disable` against the pack repo; resulting flat files diff = whitespace-only against pre-init state") is satisfied by BD-102 step 7; cross-reference accordingly.

### §3.3 §6 MAINTAINER CHECK NEEDED additions

Append to §6 of the base plan (Addendum 1 ends at §6.I):

- **§6.J — Ship v11.0 in tracker mode or flat-file mode? (BD-102 ship decision.)**
  - (a) **Flat-file (proposed).** Pack ships in same starting state as clients; mental-model alignment for maintainers and contributors; no `gh` auth needed for backlog state interaction; maintainer can opt-in post-release via a separate commit on main.
  - (b) Tracker mode. Pack eats own dog food more aggressively; pack BACKLOG lives in GH Issues with sidecar fallback; contributors must `gh auth` to interact with backlog state.
  - (c) Tracker mode for pack-internal BDs (BD-NNN), flat-file for everything else. Hybrid; rejected — adds complexity without clear win.
  - **Recommendation: (a).** Flat-file at v11.0 cut. Maintainer can opt-in post-release if they choose; that opt-in becomes a separate commit on main, not part of v11.0. Maintainer confirms at BD-102 land-time and records the rationale in the dog-food report.

- **§6.K — Exact confirm-flag string for `pack tracker reset` (BD-103).**
  - (a) **`--confirm-i-have-admin-and-want-to-delete-all-pack-issues` (proposed).** Long, specific, self-documenting; awkward to type; visible in shell history; intent unambiguous.
  - (b) `--yes-really-delete-all-pack-issues`. Shorter; less specific about the admin requirement; possibly typeable in a hurry.
  - (c) `--force-bulk-delete`. Standard CLI shape; too short; not friction-by-design.
  - (d) Two-flag combo: `--bulk-delete --confirm`. Mechanically separable; risk: aliases / shell history obscure the second flag.
  - **Recommendation: (a).** The point is friction. Length plus the admin assertion plus the explicit "all-pack-issues" scope makes this self-documenting in shell history and incident review. Maintainer confirms at BD-103 land-time; the chosen string must match in `scripts/lib/pack-tracker/reset.sh`, HELP-FRAGMENT, OPTIONAL-FEATURES.md, and `test-tracker-reset.sh` simultaneously (BD-097 semantic audit re-run will catch drift).

---

## §4. Verification additions

### §4.1 New entries in §4.1 per-BD test plan summary

| BD | Test mechanism |
|---|---|
| BD-102 | Manual procedure (§1.1.3 above); report at named path with all §1.1.4 sections; outcome PASS/PASS-WITH-DEVIATIONS; reverse round-trip diff whitespace-only |
| BD-103 | `scripts/tests/test-tracker-reset.sh` (5 cases); validate-pack Check 22; manual smoke during BD-102 dog-food |

### §4.2 New §4.3 fixtures

Append to base plan §4.3 (Addendum 1 already extended this list):

- `scripts/tests/fixtures/tracker-reset/marker-mixed-with-user-issues/` (BD-103) — sandbox seed of 2 marker-matched + 2 user-created issues; expected behavior: only 2 deletions.
- `scripts/tests/fixtures/tracker-reset/non-admin-auth-mock/` (BD-103) — mocked `gh` auth response without admin scope; expected behavior: `TRACKER_RESET_REQUIRES_ADMIN` typed error.
- `scripts/tests/fixtures/tracker-reset/sub-issue-cascade/` (BD-103) — parent + 2 children; delete parent → children orphaned; delete child → parent's sub-issue list auto-cleaned.

### §4.3 New §4.4 CI gates

Append to the CI workflow runner (Addendum 1 added gates 9, 10, 11):

12. `bash scripts/tests/test-tracker-reset.sh` (BD-103).

(BD-102 is a manual maintainer procedure; not a CI gate. Its evidence artifact — the dog-food report — is reviewed at release-pin time per §7 checkbox.)

### §4.4 Audit-pass discipline (extends Addendum 1 §5.4)

Addendum 1 named 4 audit artifacts before BD-093 (3 checkpoint reports + 1 semantic audit report). Addendum 2 adds a 5th: the dog-food migration report. Cumulatively:

1. CHECKPOINT-1-REPORT.md (BD-100 CP1).
2. CHECKPOINT-2-REPORT.md (BD-100 CP2).
3. CHECKPOINT-3-REPORT.md (BD-100 CP3).
4. SEMANTIC-AUDIT-REPORT.md (BD-097).
5. **DOG-FOOD-MIGRATION-REPORT.md (BD-102).**

All 5 cited from CHANGELOG v11.0 entry as evidence of staged-audit discipline + eat-own-dog-food validation. Failure of any halts release.

---

**End of Addendum 2.**
