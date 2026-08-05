#!/usr/bin/env bash
# Rebase this fork's custom commits on top of the latest mainline Shotcut.
#
# Usage:
#   ./update-from-upstream.sh            # rebase onto upstream/master
#   ./update-from-upstream.sh v25.01.25  # rebase onto a specific release tag
#
# Your customizations are kept as commits on top of upstream, so after this
# runs the branch is "latest Shotcut + your patches".

set -euo pipefail

TARGET="${1:-upstream/master}"

cd "$(dirname "$0")"

if [ -n "$(git status --porcelain)" ]; then
    echo "error: you have uncommitted changes. Commit or stash them first." >&2
    git status --short >&2
    exit 1
fi

echo "==> Fetching upstream..."
git fetch upstream --tags

echo "==> Your commits on top of upstream, before rebase:"
git log --oneline upstream/master..HEAD || true

echo "==> Rebasing onto ${TARGET}..."
if ! git rebase "${TARGET}"; then
    cat >&2 <<'EOF'

Rebase hit a conflict. Upstream changed code your patch also touches.

  1. Edit the conflicted files (git status shows them)
  2. git add <files>
  3. git rebase --continue

To abort and return to where you were:
  git rebase --abort
EOF
    exit 1
fi

echo "==> Rebase complete. Your commits are now:"
git log --oneline "${TARGET}..HEAD"

cat <<'EOF'

==> Next steps:
  1. Build and test:
       cmake --preset cc-debug-linux && cmake --build build/cc-debug-linux
  2. Push (rebase rewrites history, so a force push is required):
       git push --force-with-lease origin master
  3. Bump pkgver in the AUR PKGBUILD and push that repo.
EOF
