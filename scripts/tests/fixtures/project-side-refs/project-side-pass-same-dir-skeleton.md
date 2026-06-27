# Synthetic fixture — Check 43 PASS path (per-entry skeleton sibling)

This fixture exercises the per-entry skeleton sibling-file PASS
path. Per ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md §1.4:

  "_intro.md": "Per-entry tree intro sibling (same-dir resolution)"

The `_intro.md` basename is on the allowlist as a per-entry tree
sibling skeleton file that resolves same-dir within
`docs/project/backlog/` (or `docs/project/changelog/` or
`docs/project/implementation-plan/`).

Bare refs to `_intro.md`, `_rules.md`, `_index.md` MUST PASS
Check 43 via the allowlist entry. Per the per-entry tree
contract, each stream's `_rules.md` documents the stream's
per-entry schema (BD-206: `_format.md` is FORBIDDEN — its
content folds into the changelog `_rules.md`).

The bare ref `_intro.md` is on the allowlist (per-entry tree
sibling, same-dir resolution).
The bare ref `_rules.md` is also on the allowlist.
The bare ref `_index.md` is also on the allowlist (impl-plan
ordering sibling).
