# roundtrip/bd-v11.2 — stub directory

Per V1 §6.6.1 multi-template-version round-trip readiness, this
directory is a stub at v11.0. When v11.2 ships with another
template-field addition (per V2 §19), drop a fixture set in here.
See `bd-v11.1/README.md` for the fixture file shape.

The presence of two stub directories (v11.1 + v11.2) is intentional:
V1 §6.6.1 names a 2-version-skip case (forward on v11.0, upgrade to
v11.2, reverse) that requires the translation manifest to chain
v11.0→v11.1→v11.2 sequentially. Having both stubs lets the future
multi-skip test slot in without re-architecting the directory layout.
