# Synthetic fixture — Check 40 FAIL path (broken ref)

This fixture exercises the FAIL-with-broken-ref path. Each bare ref
below has no candidate file in the pack repo (excluding test-fixtures
and scripts/tests/fixtures synthetic trees per OQ-S1). Check 40 MUST
FAIL each one with a "broken ref" message.

- A nonexistent doc: `THIS-FILE-DOES-NOT-EXIST.md`
- Another nonexistent: `STALE-REFERENCE.py`
- Phantom config: `phantom-config.toml`
- These refs are NOT on the allowlist; they are NOT in any
  anchor-phrase window; they have NO candidate path. FAIL each.
