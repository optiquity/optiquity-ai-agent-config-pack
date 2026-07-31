#!/usr/bin/env bash
# install-validate-hook.sh — opt-in installer for a local pre-push hook that
# runs the project's validate.sh quality gate before code leaves your machine.
#
# The project ships a quality gate, scripts/validate.sh, which fans out to
# every validator leg. This installer wires that same gate into a local git
# pre-push hook, so a push that would fail validate.sh is stopped before it
# leaves your machine.
#
# The hook is advisory: it never modifies your tree, and you can always bypass
# it for a single push with `git push --no-verify`.
#
# Run it once per clone:
#     bash scripts/install-validate-hook.sh
#
# To bypass the hook for a single push:
#     git push --no-verify
#
# If a pre-push hook already exists in this clone, this installer refuses to
# overwrite it (your hook is left untouched) and asks you to merge manually.
#
# Where it writes: the hook lands in the EFFECTIVE hooks directory resolved by
# `git rev-parse --git-path hooks`. That resolution honors a custom
# core.hooksPath, which may point inside your working tree (e.g. a team
# .githooks/ dir) — so the write is not guaranteed to land outside the tree.
# The safety guarantee is the CONSENT GATE (you run this installer
# deliberately) plus refuse-if-exists — NOT the write location. The installer
# prints the resolved path it wrote to.
set -u

HOOKS_DIR="$(git rev-parse --git-path hooks)"
HOOK="$HOOKS_DIR/pre-push"

mkdir -p "$HOOKS_DIR"

if [ -e "$HOOK" ]; then
  echo "install-validate-hook: a pre-push hook already exists at:" >&2
  echo "  $HOOK" >&2
  echo "Refusing to overwrite it. Merge the quality gate into your existing" >&2
  echo "hook manually — it should run:  bash \"\$(git rev-parse --show-toplevel)/scripts/validate.sh\"" >&2
  exit 1
fi

cat > "$HOOK" <<'HOOK_BODY'
#!/usr/bin/env bash
# pre-push — run the project's validate.sh quality gate before pushing.
# Installed by scripts/install-validate-hook.sh. Advisory: bypass a single
# push with `git push --no-verify`.
set -u

ROOT="$(git rev-parse --show-toplevel)"
bash "$ROOT/scripts/validate.sh"
status=$?
if [ "$status" -ne 0 ]; then
  echo "" >&2
  echo "pre-push: validate.sh failed (see above)." >&2
  echo "Fix the failures, or bypass this check for one push with:" >&2
  echo "  git push --no-verify" >&2
fi
exit "$status"
HOOK_BODY

chmod +x "$HOOK"
echo "install-validate-hook: installed pre-push at $HOOK"
echo "Bypass a single push with: git push --no-verify"
