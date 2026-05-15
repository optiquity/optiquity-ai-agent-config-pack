# IMPLEMENTATION REPORT — BD-133 retroactive review-fix (Batch 21c)

- **BD:** BD-133 — Reverse migration preserves BACKLOG.md header preamble
- **Original commit:** `c566c20` (combined with BD-131; BD-133 portion only is in scope here)
- **Retro review:** `maintenance-docs/v11-implementation/PACK-REVIEW-BD-133-RETRO.md`
- **Retro session HEAD (start):** `ea9fabee65e6c64419d8888af2c17ef22943540b`
- **Worktree HEAD at end of fix:** `a17ac2dc3df6642184a6de4b626c4863055aa299`
  - HEAD advanced from `ea9fabe` → `a17ac2d` during this session as two sibling Batch 21c retro fixes landed in parallel (BD-095 = `35b3b7a`; BD-078+BD-079 combined = `a17ac2d`). Neither touches any file in BD-133's scope; no merge issues.
- **Branch:** `v11-dev`
- **Author:** pack-coder (retro fix session, 2026-05-15)
- **Findings addressed:** F1, F2, F3, F4, F5 (5 of 5 — F5 explicitly deferred to v11.1 per the review's recommendation; F1–F4 fixed in this session).

---

## Disposition summary

| Finding | Severity | Disposition | Verification |
|---|---|---|---|
| F1 | SHOULD | Fixed (option (b) — docs-only). Added R18 risk paragraph in `ARCHITECTURE-V3.md` §17 + "Operator note — refreshing the snapshot" block in `tracker-header-snapshot.sh` header comment. | grep verifies both surfaces present |
| F2 | SHOULD | Fixed. 6 `$(_ths_extract_preamble ...)` capture sites in `tracker-bd133-header-preservation-test.sh` replaced with file-extraction + `cmp -s` direct file comparison. | Demonstration script shows old style masks trailing-newline drift; new style catches it (output below) |
| F3 | SHOULD | Fixed. New sidecar `.pack-tracker/backlog-header.snapshot` enumerated in `ARCHITECTURE-V3.md` Appendix A.1 (paragraph adjacent to `recommendation-state.json`) and Appendix I.1 (file list adjacent to `.pack-tracker/recommendation-state.json`). | grep finds 4 surfaces (R18 risk, A.1 entry, A.1 escape-hatch reference, I.1 file list) |
| F4 | NIT | Fixed. `_ths_extract_preamble` promoted to public `tracker_header_snapshot_extract_preamble` (review's preferred option (a)); back-compat alias kept until v12; all 6 internal-and-test call sites use the new public name. | Test still 30/30 PASS |
| F5 | NIT | Deferred to v11.1 per review's explicit recommendation ("cosmetic… could also be deferred to v11.1"). Risk of subtle behavior shift in Group 3's stateful-fake-gh path with mirror-header HTML comments was judged too high for a non-functional cleanup in a retro fix. | n/a (deferred) |

No MUSTs in the original review; no MUSTs introduced.

---

## Per-task summary

### F1 — first-write-wins documentation (SHOULD)

**Files touched:**

- `maintenance-docs/v11-research/ARCHITECTURE-V3.md` — added `R18` risk paragraph immediately before the existing "V1 §17.2 trade-offs T1–T6 stand…" line (near §17 close). 23 lines added.
- `scripts/lib/tracker-header-snapshot.sh` — added "Operator note — refreshing the snapshot" block to the public-API header comment, immediately after the `tracker_header_snapshot_apply` API description. 28 lines added.

**Approach.** Per the review's "Recommended for v11.0: option 1 (docs only)" disposition. Both the developer-facing source comment and the architecture risk register now describe:

1. The first-write-wins invariant and *why* it exists (preventing snapshot-eats-itself across degraded reverses).
2. The user-edit-between-cycles edge case (preamble edits in flat-file mode silently overwritten on next disable).
3. The exact 4-step escape hatch: `disable` → delete sidecar → `init` → `disable`.
4. A v11.1 follow-up note for a future `pack tracker resnap` verb.

**Verification.**

```
grep -n "backlog-header\|R18\|Operator note" \
  maintenance-docs/v11-research/ARCHITECTURE-V3.md \
  scripts/lib/tracker-header-snapshot.sh
```

Result: R18 paragraph at ARCHITECTURE-V3.md:251–272; "Operator note" block at tracker-header-snapshot.sh:75–101 (in the header comment).

### F2 — `cmp -s` byte-equality in tests (SHOULD)

**Files touched:** `scripts/tests/tracker-bd133-header-preservation-test.sh` — 6 `$(_ths_extract_preamble ...)` capture sites + 1 `$(cat …snapshot)` site rewritten to use tmp files + `cmp -s`. ~56 lines added / 25 deleted.

**Approach.** Each of Groups 2, 3, 4 now creates a per-group `WORK_GN` mktemp directory; preambles are extracted via `tracker_header_snapshot_extract_preamble file > tmp` (file output, no command substitution); comparisons use `cmp -s a b`. Each group's cleanup `rm -rf` extended to include the new work directory.

The 4.3 assertion (snapshot byte-equal to original preamble) was rewritten as a direct file-vs-file `cmp -s`, since both operands are now on-disk files.

**F2 demonstration — strip bug now caught.**

Two files differ only by one trailing newline (19 vs 20 bytes):

```
$ python3 - <<'PYEOF'
import os, subprocess, tempfile
work = tempfile.mkdtemp(prefix="bd133-f2-demo.")
a = os.path.join(work, "a.preamble")
b = os.path.join(work, "b.preamble")
with open(a, 'w') as fh: fh.write("# Backlog\n\nIntro.\n\n")
with open(b, 'w') as fh: fh.write("# Backlog\n\nIntro.\n\n\n")  # extra \n
print(f"file a: {os.path.getsize(a)} bytes; file b: {os.path.getsize(b)} bytes")

# OLD STYLE (pre-F2): A=$(cat a); B=$(cat b); [[ "$A" == "$B" ]]
sh = (f'A=$(cat {a}); B=$(cat {b}); '
      f'if [[ "$A" == "$B" ]]; then echo "OLD STYLE: equal (BUG masked)"; '
      f'else echo "OLD STYLE: different"; fi')
print(subprocess.check_output(["bash", "-c", sh], text=True).strip())

# NEW STYLE (post-F2): cmp -s a b
sh2 = (f'if cmp -s {a} {b}; then echo "NEW STYLE: equal (would NOT catch)"; '
       f'else echo "NEW STYLE: different (CAUGHT)"; fi')
print(subprocess.check_output(["bash", "-c", sh2], text=True).strip())
PYEOF
file a: 19 bytes; file b: 20 bytes
OLD STYLE: equal (BUG masked)
NEW STYLE: different (CAUGHT)
```

Old `$()`-based assertion silently treats the two files as equal; new `cmp -s` correctly rejects them. The BD-133 commit message and BACKLOG `Resolved:` line both make a "byte-identical" claim — the test contract now matches the doc contract.

### F3 — Sidecar enumeration in ARCHITECTURE-V3 (SHOULD)

**Files touched:** `maintenance-docs/v11-research/ARCHITECTURE-V3.md`. Two surfaces:

1. **Appendix A.1 (V3 deltas to V2 §A.1, new artifacts)** — added a paragraph immediately after the existing `.pack-tracker/recommendation-state.json` bullet. Documents path, lifecycle, operator escape hatch, gitignore status, source module, and sibling sidecars. 17 lines added.
2. **Appendix I.1 (New files V3 introduces)** — added three lines to the file list: `scripts/lib/tracker-header-snapshot.sh`, `scripts/tests/tracker-bd133-header-preservation-test.sh`, `.pack-tracker/backlog-header.snapshot`. 3 lines added.

**Why both surfaces?** Appendix A.1 is the prose enumeration; Appendix I.1 is the planner's flat file-list. Both already enumerate `recommendation-state.json` so a future reader scanning either surface for the sidecar inventory will now see the BD-133 file too.

**Verification.**

```
$ grep -n "backlog-header" maintenance-docs/v11-research/ARCHITECTURE-V3.md
258:(`.pack-tracker/backlog-header.snapshot`) introduced by BD-133 is
1675:- `.pack-tracker/backlog-header.snapshot` (per surface, machine-local,
1686:  `<surface-root>/.pack-tracker/backlog-header.snapshot` then runs
2873:.pack-tracker/backlog-header.snapshot                  (BD-133 / D-6: lazy-created on first reverse with substantive preamble; first-write-wins; gitignored)
```

Four mentions in ARCHITECTURE-V3 now: F1's R18 risk paragraph (line 258), F3's A.1 paragraph (line 1675 + 1686 escape-hatch reference), F3's I.1 file list (line 2873).

### F4 — Promote `_ths_extract_preamble` to public (NIT)

**Files touched:**

- `scripts/lib/tracker-header-snapshot.sh` — renamed `_ths_extract_preamble` to `tracker_header_snapshot_extract_preamble`; added a docstring section to the public API header comment; kept a back-compat alias `_ths_extract_preamble` that calls the new public function (deprecated, removed at v12). The internal `tracker_header_snapshot_capture` call site updated to use the new public name.
- `scripts/tests/tracker-bd133-header-preservation-test.sh` — all 6 `_ths_extract_preamble` references rewritten to `tracker_header_snapshot_extract_preamble` (folded into the F2 rewrites, so no separate diff hunk).

**Why option (a), not option (b)?** The review explicitly preferred (a) "since the helper is genuinely small and likely useful for future call sites (e.g., `pack tracker doctor` snapshot-vs-current drift check)." The drift check is exactly the kind of feature that wants a public preamble extractor. Option (b) (inline the regex in the tests) would have created a small Python heredoc duplicated 3× across the test file — worse than the rename.

**Why keep the alias?** Defensive: any third-party script (or follow-up BD this session) that already references `_ths_extract_preamble` continues to work in v11.x. The alias is one line + comment; the deprecation note explicitly schedules removal at v12.

**Verification.** Test still 30/30 PASS — see verification section below.

### F5 — Mirror-header staleness in snapshot file (NIT) — DEFERRED

**Disposition:** Deferred to v11.1, matching the review's explicit recommendation ("cosmetic… could also be deferred to v11.1").

**Why deferred.**

1. **Functionally invisible.** Per the review F5: "Functionally invisible (the mirror-strip cleans every cycle); only visible if a developer inspects the snapshot file. The 'stale timestamp' is meaningless in any operational sense."
2. **Risk of regression.** The fix would add a `<!--…-->` strip step to `tracker_header_snapshot_extract_preamble`. That helper is now called by tests, by capture, and (by F4 promotion) by potential future callers. Group 3's stateful-fake-gh fixture goes through real forward + reverse and would be the first place an unintended strip would surface. While the review notes "tests 1.1 and 1.5 wouldn't change behavior because they don't include a mirror header," Group 3 *does* and the verification matrix would need a fresh test for "snapshot does not contain `<!--…-->`" — work disproportionate to the cosmetic gain in a retro fix.
3. **No user-facing impact.** A v11.1 BD-NNN can pick this up alongside the F1 follow-up (`pack tracker resnap` verb).

The deferral is a deliberate, scoped decision — not a "didn't get to it" gap.

---

## New POQs introduced

None. All five findings either fix in place (F1, F2, F3, F4) or are deferred per the review's explicit recommendation (F5). No new architectural questions raised.

The "future `pack tracker resnap` verb" mentioned in F1's R18 paragraph and in the source-comment Operator note is a *forward-looking implementation hook*, not an architectural question. It would be a v11.1 BD-NNN. The reviewer flagged this as the natural option (3) escalation path; nothing in the v11.0 design contradicts it.

---

## Plan deviations

None. Every finding either tracks the review's explicit "concrete fix" (F1 option (b) docs, F2 `cmp -s`, F3 paragraph, F4 promote) or is deferred per the review's explicit recommendation (F5).

The one micro-deviation worth noting: I added F4 to F2's edits in the same hunk (since F2's rewrite already replaces the call sites that F4's rename would touch). The review listed them as separate findings; the implementation collapses them because every F2 site is also an F4 site. Net result: 6 sites get both fixes in one rewrite each, no double-touch.

---

## Files changed inventory

| Path | Type | Change |
|---|---|---|
| `scripts/lib/tracker-header-snapshot.sh` | modified | Public API expansion (F4): rename `_ths_extract_preamble` → `tracker_header_snapshot_extract_preamble` + back-compat alias; updated header docstring with new public function + Operator note (F1). +58 / -10 lines net. |
| `scripts/tests/tracker-bd133-header-preservation-test.sh` | modified | Replace 6 `$()`-based byte-equality sites with `cmp -s` against tmp files (F2); migrate 6 references from `_ths_extract_preamble` to `tracker_header_snapshot_extract_preamble` (F4); per-group `WORK_GN` mktemp + cleanup. +56 / -25 lines net. |
| `maintenance-docs/v11-research/ARCHITECTURE-V3.md` | modified | New R18 risk paragraph (F1); new sidecar paragraph in Appendix A.1 (F3); 3 new file-list entries in Appendix I.1 (F3). +46 / -2 lines net. |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-133-RETRO-FIX.md` | new | This report. |

No deletions. No moves. No `BACKLOG.md` / `CHANGELOG.md` edits (Pack Chat owns those for batch close).

No touches to:
- `scripts/lib/tracker-migrate-reverse.sh` — BD-133 wiring at lines 1087/1098 already correct; no review finding required reverse.sh edits.
- `scripts/lib/tracker-migrate-forward.sh` — BD-133 had no forward-side changes (the review's "BD-133 portion of forward.sh" is the empty set; the BD-133 capture wiring lives entirely in reverse.sh).
- BD-130's line 569 in `tracker-migrate-reverse-test.sh` (already fixed at `ea9fabe`).
- BD-131's line ranges in `tracker-migrate-forward.sh` (already shipped in BD-131 retro `89f5d45`).
- Any concurrent coder's files (BD-079, BD-095, BD-101).

---

## Verification commands & results

### Syntax checks (`bash -n`)

```
$ bash -n scripts/lib/tracker-header-snapshot.sh && echo OK
OK
$ bash -n scripts/lib/tracker-migrate-reverse.sh && echo OK
OK
$ bash -n scripts/tests/tracker-bd133-header-preservation-test.sh && echo OK
OK
```

### BD-133 regression suite

```
$ bash scripts/tests/tracker-bd133-header-preservation-test.sh 2>&1 | tail -7
  PASS 4.3 snapshot equals original preamble (first-write-wins)
  PASS 4.4 exactly one title line after N cycles

=== Summary ===
Passed: 30
Failed: 0
All tests passed.
```

30/30 PASS — count parity with HEAD baseline preserved.

Detailed breakdown unchanged from baseline:
- Group 1 (module API): 15 asserts PASS
- Group 2 (reverse-only round-trip): 6 asserts PASS (now using `cmp -s`)
- Group 3 (forward → reverse round-trip): 6 asserts PASS (now using `cmp -s`)
- Group 4 (multi-cycle stability N=5): 3 asserts PASS (now using `cmp -s` for both 4.2 preamble check and 4.3 snapshot=preamble check)

Total: 15 + 6 + 6 + 3 = 30 asserts. (Note: Group 4 has no 4.1 PASS line because 4.1 is the in-loop reverse-rc check that only emits a `t_fail` on failure; under success the loop runs silently. This is unchanged from baseline.)

### Composition with BD-111 (post-retrofit reverse decoder)

```
$ bash scripts/tests/tracker-migrate-reverse-test.sh 2>&1 | tail -7
  PASS 7.6 legacy-only: BD-002 from body marker
  PASS 7.6 legacy-only: exactly 1 blocker (no first-class)

=== Summary ===
Passed: 113
Failed: 0
All tests passed.

$ bash scripts/tests/tracker-migrate-roundtrip-test.sh 2>&1 | tail -7
  PASS 5.2 bd-v11.1 directory exists
  PASS 5.2 bd-v11.2 directory exists

=== Summary ===
Passed: 45
Failed: 0
All tests passed.
```

Reverse 113/113 PASS (BD-130 added 2 vs the prior 111). Roundtrip 45/45 PASS. The BD-133 snapshot path remains compositional with BD-111's first-class blocker decoder (orthogonal call surfaces — `_tmr_decode_blockers` per-issue vs. `tracker_header_snapshot_*` whole-file).

### Validator

```
$ python3 scripts/validate-pack.py 2>&1 | tail -3

============================================================
PASSED — all checks clean
```

All 32 validation checks PASS. The new file-list entries in ARCHITECTURE-V3 Appendix I.1 are documentation, not validator-driven.

### F2 demonstration — `cmp -s` catches what `$(...)` masks

See "Per-task summary → F2 demonstration" above for the executable proof.

---

## Definition of Done — checklist

| Item | Status | Evidence |
|---|---|---|
| F1 SHOULD addressed (docs option (b)) | PASS | R18 in ARCHITECTURE-V3 §17 + Operator note in `tracker-header-snapshot.sh` header |
| F2 SHOULD addressed (`cmp -s` at all 6 sites) | PASS | All 6 sites rewritten; demo above shows old style masks, new style catches |
| F3 SHOULD addressed (sidecar in ARCHITECTURE-V3) | PASS | Appendix A.1 paragraph + Appendix I.1 file-list entry |
| F4 NIT addressed (helper promoted, tests use public name) | PASS | `tracker_header_snapshot_extract_preamble` public; 6 test sites updated; back-compat alias retained |
| F5 NIT addressed (deferred) | PASS | Explicit deferral per review's recommendation; rationale documented above |
| All `bash -n` syntax checks PASS | PASS | 3 files checked, all OK |
| BD-133 regression test PASS count = baseline | PASS | 30/30 (baseline 30/30) |
| Sibling tracker tests still PASS | PASS | reverse 113/113, roundtrip 45/45 |
| Validator PASS | PASS | 32/32 checks clean |
| No edits to forbidden files (BACKLOG, CHANGELOG, ARCHITECTURE.md V1) | PASS | git diff stat shows only the 3 in-scope files + this new report |
| No edits to BD-130/BD-131/BD-095/BD-079/BD-101 line ranges | PASS | git diff path list does not include their files |
| No state-changing git verbs | PASS | Only `git rev-parse`, `git status`, `git diff`, `git log` used |
| Trinity rule respected | n/a | No trinity files touched |
| macOS bash 3.2 + BSD utils compatibility | PASS | All bash uses portable constructs (mktemp -t, cmp -s, [[ ]], $()); no bash-4 features; no GNU-only flags |

All checks PASS or n/a.

---

## Notes for Pack Chat

- Three files modified (`tracker-header-snapshot.sh`, `tracker-bd133-header-preservation-test.sh`, `ARCHITECTURE-V3.md`) plus one new report (`IMPLEMENTATION-REPORT-BD-133-RETRO-FIX.md`).
- No `BACKLOG.md` `Resolved:` line update required from this session — Pack Chat owns the BD-133 status flip on Batch 21c close, and the existing `Resolved:` line at BACKLOG.md:1906 still accurately describes the original BD-133 ship.
- A v11.1 follow-up BD candidate is mentioned in ARCHITECTURE-V3 R18 and in the source comment ("`pack tracker resnap` verb"); it is **not** a v11.0 ship-blocker. The user should decide at v11.0 ship-time whether to seed that as a v11.1 BD or leave it as a forward-looking note in the architecture doc.
- F5 deferral is documented in this report; a v11.1 BD candidate ("snapshot mirror-header strip in `tracker_header_snapshot_extract_preamble`") is a natural pairing with the resnap verb above.
