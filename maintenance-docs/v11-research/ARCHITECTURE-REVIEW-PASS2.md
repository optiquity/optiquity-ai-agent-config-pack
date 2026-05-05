# ARCHITECTURE-REVIEW-PASS2 — second-pass after §7.1 + §7.2 edits

## §0. Status

- Date: 2026-05-04
- Inputs reviewed: `ARCHITECTURE-V3.md` (post-edit), `ARCHITECTURE.md` V1 (post-edit), `ARCHITECTURE-V3.1-DELTA.md`, `ARCHITECTURE-REVIEW.md` (first pass), spot-checks against pack-root trinity files, `QUICKSTART.md`, and `DESIGN-BRIEF.md` §3.4 P2.
- First-pass verdict: `approve-with-changes` (1 blocker, 8 warnings, 6 nits).
- This pass scope: did §7.1 + §7.2 land? new issues?

---

## §1. Per-§7.1 landing verification (items 1–9)

### §7.1.1 Codex skill format (§3.1 blocker)
**Verdict: `landed-correctly`.**

Evidence — V3 §28.2.3 line 1256 now reads:
> Codex CLI | `.codex/skills/pack-help/SKILL.md` (project-level only) | Codex skill that runs `pack-help.sh`. Surfaced via `/skills` …

V3 §A.1 line 1651: `.codex/skills/pack-help/SKILL.md (per surface)`. V3 §I.1 line 2809: `.codex/skills/pack-help/SKILL.md`. V3 §I.2 line 2824: `.codex/skills/pack-startup/SKILL.md`. V3 §I.4 line 2846 also uses SKILL.md form. A grep across V3 for `\.codex/skills/.*\.toml` returns zero hits. The blocker is fully resolved.

### §7.1.2 validate-pack check-number citation (§3.2)
**Verdict: `landed-correctly`.**

V1 §3.3 line 596 now reads:
> The validate-pack `Check 18 (check_trinity_h2_parity)` already enforces H2 parity.

V1 §17.1 R10 lines 1974–1977 now read:
> R10. The pack's own validate-pack.py Checks 16 / 18 / 19 must pass on the v11 trinity changes. Specifically: Check 16 (`check_trinity_addenda_h2`), Check 18 (`check_trinity_h2_parity`), and Check 19 (`check_trinity_no_scaffolding_comments`).

The stale Check-17 reference is removed; the three named functions are correctly disambiguated.

### §7.1.3 Verb-spelling contradiction (§3.3)
**Verdict: `landed-correctly` (parts a and b); `landed-partially` (part c).**

§0.6 line 104 now reads:
> The verb spellings in V2 §22.1 (existing verbs unchanged). Note: D-19 adds the `pack tracker enable-recommendations` subcommand; D-20 adds `pack help` (LCD shell) and per-CLI `/pack-help`. These are net-new verbs, not respellings of V2 verbs.

§28.1.9 lines 985–988 now read:
> Wrapper for `pack tracker enable-recommendations`. Sets `persistent_refusal: false` in the state file. V3 adds the `enable-recommendations` subcommand to the existing `pack tracker` verb (per D-19); the parent verb `pack tracker` already exists in V2 §22.1.

The factually-wrong "Already in V2 §22 verb table" sentence is rewritten to be correct (the parent `pack tracker` is in V2 §22; the subcommand is new).

Part c (the architect's optional addition of a §22-style justification mini-table for the two new verbs) is **not** present. The justifications remain scattered across §27/§28. This was flagged optional in §7.1; the planner can absorb the tradeoff.

### §7.1.4 Citation slip — "audit §A.5 token-cost crossover" (§3.6)
**Verdict: `landed-correctly`.**

A grep for `audit §A.5` against V3 returns occurrences exclusively in the corrected form "EXTERNAL-RESEARCH §6.1 … (verified plausible by audit §A.5)" — see lines 48, 175, 179, 588, 620, 1750, 1786–1787, 1835, 2523–2524. No remaining bare "audit §A.5 token-cost crossover" wording. D-19 row, §28.1.2 signal table, §28.1.2 threshold table, §B.1, §B.3, §H.1 Alt 19-A all updated.

### §7.1.5 D-6 pack-repo trinity scope (§3.7)
**Verdict: `landed-correctly`.**

V3 §16 D-6 row line 166 now reads:
> reaffirmed in V3 (Source column applies to project-template trinity only; pack-repo trinity has no `## Document locations` section.)

This addresses the OQ-6 ambiguity directly.

### §7.1.6 R16 editorial fragment (§3.8)
**Verdict: `landed-correctly`.**

V3 §17 R16 lines 222–224 now read:
> Each machine starts with no recommendation history. A user who declined "don't ask again" on machine A and switches to machine B will be re-prompted unless they decline again on machine B. Committing `.pack-tracker/recommendation-state.json` to share the refusal across machines would be wrong (machine-private state).

The mid-clause break is repaired; the sentence is now grammatical and the meaning is preserved.

### §7.1.7 R16 in-session implication (§4.1)
**Verdict: `landed-correctly`.**

V3 §28.1.4 "Failure modes" lines 745–749 now read:
> File corrupted (JSON parse fails) → log a typed warning; write a fresh file with default state; the user starts over. **No silent retry per D-7.** After rebuild, treat the current session as if the recommendation has already been shown; defer evaluation to the next session …

Parallel test added: §28.1.10 test #6 lines 1018–1023:
> Verify no recommendation fires in the same session as the rebuild (deferred to next session per §28.1.4 failure-mode contract); restart again at unchanged-over-threshold scale — recommendation fires.

### §7.1.8 Codex skill user-level vs project-level (§4.5)
**Verdict: `landed-correctly`.**

§28.2.3 lines 1256–1257 now annotate both Codex and Gemini installs as "(project-level only)". The remaining `~/.codex/skills/*` and `~/.gemini/commands/<name>.toml` references at lines 1154 and 1171 are within the per-CLI documentation defense prose describing each CLI's *user-extension surface in general* — they are research citations, not pack install paths. This is correct usage.

### §7.1.9 Reverse-migration recommendation-state clarification (§5.5)
**Verdict: `landed-correctly`.**

V3 §A.5 lines 1731–1735 now read:
> After reverse, the recommendation-state file remains as inert data; the recommendation system is no longer active without v11 skills. Reinstalling v11 reads the file fresh (and the lazy-create path covers the case where the user manually deleted it between reverse and re-forward).

---

## §2. Per-§7.2 landing verification (items 10–12: M2, L1, A2)

### §7.2.10 M2 — Codex `/help` discoverability gap accepted as scoped
**Verdict: `landed-correctly` with one new issue (see §5).**

V3 §28.2.6 lines 1403–1470 replace the old "negative case" with a positively-framed "accepted asymmetry below the slash surface" section. The text matches the architect's delta-doc spec almost verbatim — three documented Codex-native paths (shell `pack help`, `/skills` listing, static greeting), an explicit "Accepted gap" enumerating the four negative-precondition users, and the brief-citation-anchored justification (§3.4 first bullet, §3.4 last sub-bullet, §3.1 LCD floor, §0.6 stability floor).

The closing parenthetical "There is no separate negative case subsection: the Codex path is the negative case…" is also present at line 1464.

The "**(There is no "negative case" subsection separate from this; …)**" sentence in the delta-doc spec is rendered slightly differently in V3 (without the bold-bracketing) but with equivalent meaning.

Internal consistency: §28.2.10 (lines 1567–1579) was *not* removed. It still describes "/skills" as a 3-step path. That's not contradictory — §28.2.10 is descriptive, §28.2.6 is the accepted-scope rationale — but a reader skimming §28.2 will see the same Codex tradeoff documented twice with slightly different framings. Minor.

### §7.2.11 L1 — HELP-FRAGMENT-TRACKER.md relocated to pack root
**Verdict: `landed-partially`.**

What landed correctly:

- §A.1 lines 1638–1647 list all three artifacts as the architect specified: pack-root canonical, pack-root HELP-FRAGMENT-PACK.md, and the project-template mirror with the install-from-canonical contract.
- §28.2.4 file-layout block (lines 1297–1308) matches the architect's textual replacement: pack-root canonical at top, project-template mirror with the install-time copy annotation.
- §28.2.4 prose (lines 1310–1322) replaces the previous two-include description with the new "each surface includes the copy that lives in its own tree" wording, including the byte-identity contract via `validate-pack.py` and `init-project.sh`.
- §I.4 (lines 2842–2859) gains the "Shared fragments" column with both the pack-root canonical and the project-template mirror; the propagation list adds the bullet about identity-via-validate-pack and content-wise (not file-wise) trinity rule.

What did not land — **§I.1 (line 2806) was not updated:**

```
project-template/docs/pack/HELP-FRAGMENT.md           (rewrite from V2 tracker-only to entire pack)
project-template/docs/pack/HELP-FRAGMENT-TRACKER.md   (extracted shared tracker section)
HELP-FRAGMENT-PACK.md                                  (pack repo root; new)
```

The architect's delta-doc spec said replace the `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md   (extracted shared tracker section)` line with two lines (a new pack-root canonical line and a project-template mirror line that names the install-from-canonical contract). §A.1 has the full three-line list; §I.1 still has the old single-line list with the stale "extracted shared tracker section" description that doesn't reflect the canonical/mirror distinction. The pack-root `HELP-FRAGMENT-TRACKER.md` is missing from §I.1 entirely, even though it is the canonical and is listed in §A.1 and §I.4.

This is a `nit`-level inconsistency between §A.1 (correct) and §I.1 (stale). The planner reading §I.1 alone would miss the pack-root canonical.

Also unaddressed: the architect's delta-doc said the byte-identity check is "planner-numbered alongside Checks 21/22/23." V3 §28.2.4 mentions the check, but §28.2.5 enumerates only Checks 21/22/23 by number, and §A.2 line 1686–1688 says the validate-pack adds "Check 21 … Check 22 … Check 23" with no fourth entry. The byte-identity check is referenced but not listed. Whether to inline-number it now or defer to the planner is a maintainer call; per the delta-doc this is acceptable, but the implementation-surface lists are not consistent with the §28.2.4 prose.

### §7.2.12 A2 — V1 §6.6 sidecar extension for template-version drift
**Verdict: `landed-correctly`.**

V1 §6.6.1 (lines 1116–1169) is a new subsection between V1 §6.6 and V1 §6.7 with the exact contents the architect specified:

- Per-entry `template_version` capture in the sidecar.
- `extra_fields` block with the schema citation `maintenance-docs/v11-research/templates-archive/<template_version>/SCHEMA.md`.
- `template_archive_path` field for re-forward determinism.
- §6.7 round-trip extension covering reverse and re-forward of v11.x-introduced fields.
- Sidecar-missing warning text: "TD-NNN was created on `bd-v11.2.0` template; sidecar missing; v11.x-only fields will be defaulted. Run `pack tracker doctor` after re-forward to review."
- Documentation surfacing line at reverse time.
- Test coverage extension: `scripts/tracker-migrate.sh roundtrip-test` extended with v11.0/v11.1/v11.2 fixtures.

V3 §17 R-numbering is unchanged (no R18 added) — matches the architect's "additive to V1; no new R18" scope.

The cross-reference to V3 §I.1 in line 1169 ("the test is part of CI per V3 §I.1 (`scripts/tests/`)") is consistent — V3 §I.1 line 2812 lists `scripts/tests/recommendation-test.sh`. A2's roundtrip-test extension will land in `scripts/tracker-migrate.sh`, not in `recommendation-test.sh`; it's a test of an existing script, not a new test file. This is consistent with V1 §6.7 (which already names `roundtrip-test`).

---

## §3. Cross-reference consistency

### §3.1 Broken cross-references
None found. §28.2.5 → §28.2.4 → §I.4 chain holds. V1 §6.6 → §6.6.1 → §6.7 chain holds. D-6 → V1 §3.3 cross-reference holds.

### §3.2 New citation slips
None introduced. The "EXTERNAL-RESEARCH §6.1 (verified plausible by audit §A.5)" form is consistent across V3.

### §3.3 Trinity-rule violations
None. L1's relocation of `HELP-FRAGMENT-TRACKER.md` to pack root is content-wise (not file-wise) — see §I.4 propagation bullet at line 2855–2859. The trinity rule (CLAUDE.md / AGENTS.md / GEMINI.md replication) is unaffected because the file is not a per-CLI triplet.

The user's `feedback_ops_product_separation` MEMORY rule is now better honored, not violated: previously Pack Chat had to read inside `project-template/` (pack product) for its own help; now Pack Chat reads from pack root (pack ops) and `init-project.sh` mirrors into the client tree.

### §3.4 Source-column scope mismatch
None. D-6 (line 166), §3.3 (V1 line 596), §I.4 (the pack-repo trinity row at line 2846 lists only the trinity files without the Source column, while the client-repo row inherits the Source column from V1 §3.3 example) are now mutually consistent.

### §3.5 Stale references to dropped paths
The user-level paths `~/.codex/skills/...toml` are no longer claimed as install paths anywhere. Remaining `~/.codex/skills/*` references at line 1154 and 2331 are within research-citation prose describing Codex's general user-extension surface — appropriate context, not pack install spec.

`~/.gemini/commands/<name>.toml` at line 1171 is similarly within Gemini documentation prose.

### §3.6 Internal layout consistency between §A.1, §I.1, §I.4
Inconsistency found: §A.1 lists `HELP-FRAGMENT-TRACKER.md` (pack root) + `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (mirror); §I.4 lists the canonical/mirror split in the Shared-fragments column; but §I.1 line 2806 still has only the project-template path with stale "extracted shared tracker section" description. **This is a residual L1-landing issue** (see §2.7.2.11 above).

---

## §4. First-pass severity re-evaluation

### §4.1 First-pass blocker (§3.1 Codex skill format)
**Resolved.** Lines 1256, 1352, 1651, 2809, 2824, 2828, 2846 all consistently use SKILL.md. Zero `.codex/skills/.*\.toml` matches.

### §4.2 First-pass 8 warnings

| Warning | First-pass verdict | Pass-2 verdict | Evidence |
|---|---|---|---|
| §3.2 validate-pack check number | warning | resolved | V1 §3.3 line 596; V1 §17.1 R10 lines 1974–1977 |
| §3.3 verb-spelling contradiction | warning | resolved (a, b); part (c) noted as optional and not added | §0.6 line 104; §28.1.9 lines 985–988 |
| §3.4 Codex `/help` discoverability | warning (escalating) | resolved as scoped via M2 | §28.2.6 lines 1403–1470 |
| §3.5 HELP-FRAGMENT layout | warning | resolved (with §I.1 inconsistency, see §5.2 below) | §28.2.4 lines 1297–1322; §I.4 lines 2842–2859 |
| §3.6 audit §A.5 citation slip | warning | resolved | §B.1 line 1750; §28.1.2 lines 588, 620; D-19 row line 179; §28.1.2 line 588 |
| §3.7 D-6 pack-repo scope | warning (`nit`) | resolved | D-6 row line 166 |
| §4.1 R16 in-session implication | warning | resolved | §28.1.4 lines 745–749; §28.1.10 test #6 |
| §4.2 BACKLOG-format drift | warning | resolved via A2 | V1 §6.6.1 lines 1116–1169 |

### §4.3 First-pass 6 nits

| Nit | First-pass verdict | Pass-2 verdict |
|---|---|---|
| §3.8 R16 fragment | nit | resolved (line 222–224) |
| §4.3 GH search 1,000 cap | nit (deferred to v11.x) | unchanged; still deferred |
| §4.4 INTERNAL-INVENTORY R10 | nit (deferred) | unchanged; still deferred |
| §4.5 Codex user-level vs project-level | nit | resolved (lines 1256–1257) |
| §5.1–§5.5 clarity-for-planner | nit | unchanged; planner can absorb |

---

## §5. New issues surfaced this pass

### §5.1 M2 claims pack-startup is "documented as the recommended first action … in QUICKSTART.md and the trinity files" — but it is not today
**Severity: `warning`.**

V3 §28.2.6 lines 1418–1422 read:
> when the user invokes the startup skill (which the pack documents as the recommended first action in any pack-managed repo, in both QUICKSTART.md and the trinity files), the greeting prints "run `pack help` for the full verb list."

Spot-check against pack today: a grep for `pack-startup`, `pm-startup`, "first action", "recommended first" against `/Users/david/Developer/optiquity-ai-agent-config-pack/QUICKSTART.md`, pack-root `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`, and `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` returns zero hits. The claim is aspirational for v11 but presented as if already-true.

This isn't a fatal flaw — v11 ships these additions per §A.2 line 1683–1685 ("**Trinity files (CLAUDE.md / AGENTS.md / GEMINI.md, both pack and client)**: add a one-line 'Pack commands' reference to `pack help` / `/pack-help`") — but the §A.2 addition is a "Pack commands" reference, not a "recommended first action" instruction.

The architect's M2 prose claims a stronger contract than §A.2 promises to ship. The planner needs an explicit BD entry to add "run `pack-startup` / `pm-startup` first" prose to QUICKSTART.md and the trinity files. Today this is implicit in §A.2 but not enumerated.

**Recommendation:** §A.2 should explicitly add a bullet that v11 install adds the "recommended first action: run `pack-startup` / `pm-startup`" line to QUICKSTART.md. Or §28.2.6 should soften "documents" to "will document (per §A.2)."

### §5.2 §I.1 stale single-line entry vs §A.1 full three-line list
**Severity: `nit`.**

Documented in §2.7.2.11 above. §I.1 line 2806 has the pre-L1 single-line description; §A.1 has the post-L1 three-line list. The planner using §I.1 as their flat file-list (which is its stated purpose: "lists every file or section the implementation phase will touch, as a single flat list") will miss the pack-root canonical `HELP-FRAGMENT-TRACKER.md`. Easy textual fix.

### §5.3 Byte-identity check is referenced but not numbered or listed
**Severity: `nit`.**

§28.2.4 line 1318 names the new check ("planner-numbered alongside Checks 21/22/23"); §28.2.5 enumerates only 21/22/23; §A.2 line 1686–1688 says validate-pack adds "Check 21 … Check 22 … Check 23". The byte-identity check is in V3 prose but not in the implementation-surface list. The architect's delta-doc explicitly authorized "planner-numbered" so this is by design, but for symmetry the §A.2 implementation-surface bullet should add a fourth Check entry (numbered TBD). Otherwise a planner mechanically converting §A.2 to BD entries will miss it.

### §5.4 §28.1.9 cross-reference still names V2 §22.1 as if the verb table is now complete with the V3 additions
**Severity: `nit`.**

§28.1.9 line 988 reads "the parent verb `pack tracker` already exists in V2 §22.1." Correct. But V2 §22.1's "9-verb surface" closing sentence is unchanged in V2 (V3 cannot edit V2 prose by definition). A reader who fetches V2 §22.1 directly will see the "9-verb surface" sentence without a V3 footnote. §0.6 acknowledges the new verbs at the V3 level, but V2 §22.1 itself is silently out-of-date. This is intrinsic to V3's "additive on top of V2" structure and not really fixable without a V2 patch — flag it as a reader-orientation hazard the planner should know about, not as a defect.

### §5.5 §28.2.10 still describes Codex `/skills` as "3 steps vs 1 step" but §28.2.6 now describes it as "3 keys: `/`, `s`, Tab"
**Severity: `nit`.**

Different framings of the same tradeoff. Both are technically correct (one keystroke-counted, one step-counted) but the difference may confuse a reader skimming §28.2. Optional consolidation; not blocking.

### §5.6 templates-archive directory not yet present in repo
**Severity: `nit`.**

A2 cites `maintenance-docs/v11-research/templates-archive/<template_version>/SCHEMA.md` as "the existing template-archive directory specified in `DESIGN-BRIEF.md` §3.4 P2." DESIGN-BRIEF §3.4 P2 line 110 does specify this directory. But `ls maintenance-docs/v11-research/templates-archive` returns "No such file or directory" — the directory has not been created yet. This is fine for an architecture (it's a v11 deliverable) but the word "existing" in V1 §6.6.1 line 1136 is misleading; "specified" or "to-be-created" would be more accurate. The brief specifies it; the repo doesn't have it yet.

### §5.7 V1 §6.6.1 cites V3 §I.1 for `scripts/tests/`, but V3 §I.1 lists `recommendation-test.sh`, not `tracker-migrate.sh`
**Severity: `nit`.**

V1 §6.6.1 line 1169 says: "The test is part of CI per V3 §I.1 (`scripts/tests/`)." V3 §I.1 lists `scripts/tests/recommendation-test.sh` (line 2812). The roundtrip-test extension lives in `scripts/tracker-migrate.sh`, which is a V1 artifact. The cross-reference is loose: V1 §6.6.1 is pointing at "the new tests directory introduced in V3" generically, but the test it describes is an extension to a V1 script. A reader following the cross-reference will not find a `scripts/tests/tracker-migrate-roundtrip-test.sh` listed in V3 §I.1. The fix is either (a) name the test file explicitly in V1 §6.6.1, or (b) add it to V3 §I.1's `scripts/tests/` listing.

---

## §6. Per-section verdicts

| Section | Severity | Verdict | Evidence |
|---|---|---|---|
| V3 §0 change-log table | nit | approve | line 48 citation form; line 55 OQ reference |
| V3 §0.6 | (resolved warning) | approve | line 104 verb-spelling addendum |
| V3 §16 D-6 row | (resolved warning) | approve | line 166 scope-clarification |
| V3 §16 D-19 row | (resolved nit) | approve | line 179 EXTERNAL-RESEARCH citation form |
| V3 §17 R16 | (resolved nit) | approve | lines 222–224 grammatical fix |
| V3 §28.1.4 | (resolved warning) | approve | lines 745–749 corruption-recovery contract |
| V3 §28.1.9 | (resolved warning) | approve | lines 985–988 V2 §22.1 reference fix |
| V3 §28.1.10 | (resolved warning) | approve | test #6 lines 1018–1023 |
| V3 §28.2.3 | (resolved blocker) | approve | line 1256 SKILL.md |
| V3 §28.2.4 | (resolved warning, M2 + L1) | approve | file-layout 1297–1308; prose 1310–1322 |
| V3 §28.2.5 | nit | approve-with-changes | byte-identity check unlisted; see §5.3 |
| V3 §28.2.6 | (resolved via M2) | approve-with-changes | accepted-asymmetry well-framed; aspirational claim about QUICKSTART.md/trinity, see §5.1 |
| V3 §A.1 | (L1) | approve | lines 1638–1647 full three-line list |
| V3 §A.2 | nit | approve-with-changes | "recommended first action" not enumerated; byte-identity check not listed; see §5.1, §5.3 |
| V3 §A.5 | (resolved nit) | approve | lines 1731–1735 |
| V3 §B.1 | (resolved nit) | approve | line 1750 |
| V3 §B.3 | (resolved nit) | approve | lines 1786–1787 |
| V3 §I.1 | nit | approve-with-changes | line 2806 pre-L1 stale text; see §5.2 |
| V3 §I.4 | (resolved warning, L1) | approve | lines 2842–2859 |
| V1 §3.3 | (resolved warning) | approve | line 596 |
| V1 §6.6.1 | (new, A2) | approve-with-changes | lines 1116–1169 land correctly; minor "existing" / cross-reference loosenings, see §5.6, §5.7 |
| V1 §17.1 R10 | (resolved warning) | approve | lines 1974–1977 |

---

## §7. Final verdict

**`approve-with-changes`** — but the residual changes are all `nit`-class. The first-pass blocker is fully resolved. All eight first-pass warnings are resolved. Five of six first-pass nits are resolved or unchanged-as-deferred.

Six new issues surfaced this pass, all `warning` or `nit`:

- §5.1 (`warning`) — M2 prose claims QUICKSTART.md / trinity files document `pack-startup` as recommended first action; they don't today. §A.2 ships a thinner addendum. Recommend §A.2 add an explicit bullet, or §28.2.6 soften "documents" to "will document".
- §5.2 (`nit`) — §I.1 file list has stale single-line `HELP-FRAGMENT-TRACKER.md` entry; §A.1 has the correct three-line list. Bring §I.1 in line with §A.1.
- §5.3 (`nit`) — Byte-identity check referenced in §28.2.4 prose but not listed in §A.2 or §28.2.5 enumeration. Add a fourth Check entry, even if numbered TBD.
- §5.4 (`nit`) — V2 §22.1's "9-verb surface" sentence is silently out-of-date relative to V3; intrinsic to additive-on-V2 structure; reader-orientation hazard.
- §5.5 (`nit`) — §28.2.10 vs §28.2.6 use different framings of the same Codex /skills tradeoff. Optional consolidation.
- §5.6 (`nit`) — V1 §6.6.1 word "existing" describes a not-yet-created directory; should be "specified" or similar.
- §5.7 (`nit`) — V1 §6.6.1 cross-reference to V3 §I.1's `scripts/tests/` doesn't actually point at a listed file; either name the file in V1 §6.6.1 or add it to V3 §I.1.

### §7.1 Go / no-go for planner spawn

**Go.** None of the seven new issues blocks the planner. The single `warning` (§5.1) is a small textual / scope-of-work gap that the planner can absorb by adding a BD entry: "v11 install ships QUICKSTART.md update + trinity-file addendum naming `pack-startup` / `pm-startup` as the recommended first action." The six `nit`s are textual fixes the maintainer can apply directly without architect re-spawn, or that the planner can absorb mechanically.

The architecture is now substantively complete. The §7.2 architect re-spawn produced clean textual integrations; the maintainer's §7.1 application landed every required edit. The planner can spawn against V1 + V2 + V3 (post-edit) with the §5.x notes as small-scope follow-ups.

**Recommendation:** apply §5.1, §5.2, §5.3, §5.6, §5.7 as direct textual edits before planner spawn (10-minute task); §5.4 is intrinsic and worth flagging in the planner's reading-path note; §5.5 is optional. None requires architect re-spawn.

---

## End of pass-2 review
