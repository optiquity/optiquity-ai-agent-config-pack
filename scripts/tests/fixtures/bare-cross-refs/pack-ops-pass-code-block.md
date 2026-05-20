# Synthetic fixture — Check 40 PASS path (code-block stripping)

This fixture exercises the `_strip_code_blocks` preprocess. Bare-shaped
refs inside fenced code blocks MUST NOT be flagged per §3 D2 (code
block content is shell-CWD-resolved by construction).

Example invocation:

```bash
python3 scripts/validate-pack.py
bash scripts/migrate-v10-to-v11.sh
cat MIGRATION-v10-to-v11.md
ls docs/pack/HELP-FRAGMENT.md
```

The bare refs `MIGRATION-v10-to-v11.md` and `HELP-FRAGMENT.md` inside
the code block above MUST be ignored by Check 40 — they are example
commands, not doc references, and the user's shell CWD resolves them.

Same applies to indented blocks (4-space) — though those are less
common in pack-ops/ docs and not exercised here.
