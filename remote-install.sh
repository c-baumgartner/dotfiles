#!/usr/bin/env bash

set -euo pipefail

SOURCE="https://github.com/c-baumgartner/dotfiles"
TARBALL="$SOURCE/tarball/main"
TARGET="$HOME/.dotfiles"

is_executable() {
  type "$1" > /dev/null 2>&1
}

if [[ -d "$TARGET" ]]; then
  echo "Dotfiles already exist at $TARGET — skipping clone."
elif is_executable "git"; then
  CMD="git clone $SOURCE $TARGET"
elif is_executable "curl"; then
  CMD="curl -#L $TARBALL | tar -xzv -C \"$TARGET\" --strip-components=1 --exclude='.gitignore'"
elif is_executable "wget"; then
  CMD="wget --no-check-certificate -O - $TARBALL | tar -xzv -C \"$TARGET\" --strip-components=1 --exclude='.gitignore'"
else
  echo "Error: no git, curl or wget available. Aborting."
  exit 1
fi

if [[ -n "${CMD:-}" ]]; then
  echo "Installing dotfiles to $TARGET..."
  mkdir -p "$TARGET"
  eval "$CMD"
fi

echo ""
echo "Running setup..."
make -C "$TARGET" macos
