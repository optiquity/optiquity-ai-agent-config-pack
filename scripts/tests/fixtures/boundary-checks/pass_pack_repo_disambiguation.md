# Fixture: pack-vs-project disambiguation context (Check 37 PASS)

Pretends to be a project-side document that names a pack-only file.
A pack-only filename appears explicitly qualified as "in the pack repo"
to disambiguate from the client-side equivalent. Expected: Check 37
passes with the BD-175-extension anchor-phrase exception.

See the tracker example template (tracker.toml.pack-example in the pack
repo, or tracker.toml.example at a client project root) and
OPTIONAL-FEATURES.md for full setup.

PACK-AGENTS.md lists pack-* agents — that file is pack-repo only and
not installed at clients.

End.
