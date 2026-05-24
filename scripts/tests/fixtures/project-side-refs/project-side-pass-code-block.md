# Synthetic fixture — Check 43 PASS path (code-block stripping)

This fixture exercises the `_strip_code_blocks` preprocess (shared
with Check 40 per ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md §1.3).
Bare-ref-shaped tokens INSIDE fenced code blocks MUST NOT be
flagged.

Below is a fenced code block that contains a bare ref to a
pack-internal target — Check 43 MUST NOT flag the content inside
the fence because `_strip_code_blocks` erases it before the
bare-ref regex runs.

```bash
# Example invocation showing pack-internal path (inside code fence):
python3 scripts/validate-pack.py
cat maintenance-docs/v11-implementation/ARCHITECTURE-FOO.md
echo "ARCHITECTURE-V3.md content here — INSIDE CODE BLOCK"
```

Done. The bare ref above (inside the fence) would otherwise FAIL
Check 43 (pack-internal target); the code-block stripping is what
makes this fixture PASS.

(Note: this prose section deliberately does NOT contain any new
bare-ref-shaped tokens that would resolve to pack-internal targets
— the test asserts that ONLY the in-fence content was the
candidate, and that it was stripped.)
