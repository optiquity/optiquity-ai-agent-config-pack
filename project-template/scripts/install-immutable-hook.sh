#!/usr/bin/env bash
# install-immutable-hook.sh — opt-in installer for a local pre-commit hook that
# refuses commits which drift a pack-shipped immutable file.
#
# The project ships an integrity check, scripts/verify-immutable.sh, which is
# already run by scripts/validate.sh and in CI. This installer ADDITIONALLY
# wires that same check into a local git pre-commit hook, so a commit that
# would drift an immutable contract file is refused before it lands.
#
# The hook is advisory: it never modifies your tree, and you can always bypass
# it for a single commit with `git commit --no-verify`.
#
# Run it once per clone:
#     bash scripts/install-immutable-hook.sh
#
# To bypass the hook for a single commit:
#     git commit --no-verify
#
# If a pre-commit hook already exists in this clone, this installer refuses to
# overwrite it (your hook is left untouched) and asks you to merge manually.
set -u

HOOKS_DIR="$(git rev-parse --git-path hooks)"
HOOK="$HOOKS_DIR/pre-commit"

mkdir -p "$HOOKS_DIR"

if [ -e "$HOOK" ]; then
  echo "install-immutable-hook: a pre-commit hook already exists at:" >&2
  echo "  $HOOK" >&2
  echo "Refusing to overwrite it. Merge the integrity check into your existing" >&2
  echo "hook manually — it should run:  bash \"\$(git rev-parse --show-toplevel)/scripts/verify-immutable.sh\"" >&2
  exit 1
fi

cat > "$HOOK" <<'HOOK_BODY'
#!/usr/bin/env bash
# pre-commit — refuse commits that drift a pack-shipped immutable file.
# Installed by scripts/install-immutable-hook.sh. Advisory: bypass a single
# commit with `git commit --no-verify`.
set -u

ROOT="$(git rev-parse --show-toplevel)"
bash "$ROOT/scripts/verify-immutable.sh"
status=$?
if [ "$status" -ne 0 ]; then
  echo "" >&2
  echo "pre-commit: an immutable file drifted from the baseline (see above)." >&2
  echo "Restore the file, or bypass this check for one commit with:" >&2
  echo "  git commit --no-verify" >&2
fi
exit "$status"
HOOK_BODY

chmod +x "$HOOK"
echo "install-immutable-hook: installed pre-commit at $HOOK"
echo "Bypass a single commit with: git commit --no-verify"
