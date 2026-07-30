# marker-fence-grammar — shared fence-classification fixture (BD-136 S2)

Inert test-DATA tree (never swept as a wired test; auto-excluded from the
`ci-shard-plan.py` KEEP set, Check 62, and `test-fixtures/README.md`). It is
NOT a `test-fixtures/` FIXTURE_NAMES fixture — it is a committed test-local
asset under `scripts/tests/fixtures/`, the pack's blessed inert data home.

## Why this exists

BD-136 has TWO hand-rolled parsers that must agree on ONE fence predicate:

- the bash merge engine `scripts/lib/marker-preserve.sh` (`_mp_count_tokens`
  + the region parser), and
- the Python validator Check 91 (`scripts/lib/validate_checks/trinity_markers.py`,
  landing in commit C5).

If they disagree, a marker example flips between "inert (in a fence)" and
"real", which would fail Check 91 on `PM-CHAT.md` OR let the merger mis-parse
a client trinity. This fixture is consumed by BOTH parsers' test suites (the
bash `scripts/tests/test-marker-preserve-bd136.sh` and the Python
`scripts/tests/test-validate-pack-check-91.sh`), which each assert the SAME
real-token counts recorded in `EXPECTED-TOKENS.tsv`.

## The single pinned fence predicate (BD-136 S2)

> A line whose first NON-whitespace run is **>=3 backticks** toggles
> fenced-code state.

Consequences both parsers implement identically:

- A backtick fence (```` ``` ````, or more backticks) opens/closes a fenced
  block; `<!-- BEGIN project-owned -->` / `<!-- END project-owned -->` tokens
  inside it are INERT (not counted, not merged).
- A tilde line (`~~~`) is **NOT** a fence — a marker token inside a `~~~`
  block is REAL. (This is exactly why authors must never wrap marker examples
  in `~~~`; the pinned predicate would treat them as live markers.)

## Files + expected REAL (out-of-fence) marker-token counts

`EXPECTED-TOKENS.tsv` is the machine-readable cross-parser contract
(`<filename>\t<expected-real-token-count>`):

| File | Real tokens | What it exercises |
|---|---|---|
| `fenced-inert.md` | 0 | every marker lives inside a backtick fence → all inert |
| `mixed.md` | 2 | one real pair outside a fence + an inert pair inside a fence |
| `tilde-not-a-fence.md` | 2 | a pair inside a `~~~` block, which is NOT a fence → real |

A "token" is a single `<!-- BEGIN project-owned` OR `<!-- END project-owned`
occurrence; a balanced pair is 2 tokens.
