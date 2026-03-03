#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   curl -fsSL https://raw.githubusercontent.com/efww/mcp-hook-automation/main/bootstrap.sh | bash
#   curl -fsSL .../bootstrap.sh | bash -s -- 2026.03.04.1

REQUIRED_VERSION=""
if [[ $# -gt 0 && "${1:-}" != --* ]]; then
  REQUIRED_VERSION="$1"
  shift
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TARBALL_URL="https://codeload.github.com/efww/mcp-hook-automation/tar.gz/refs/heads/main"
curl -fsSL "$TARBALL_URL" -o "$TMP_DIR/pkg.tar.gz"
tar -xzf "$TMP_DIR/pkg.tar.gz" -C "$TMP_DIR" --strip-components=1

if [[ -n "$REQUIRED_VERSION" ]]; then
  "$TMP_DIR/install.sh" --version "$REQUIRED_VERSION" "$@"
else
  "$TMP_DIR/install.sh" "$@"
fi
