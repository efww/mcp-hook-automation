#!/usr/bin/env bash
set -euo pipefail

REQUIRED_VERSION="${1:-$(cat "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/VERSION")}" 
BOOTSTRAP_URL="https://raw.githubusercontent.com/efww/mcp-hook-automation/main/bootstrap.sh"

current=""
if [[ -f "$HOME/.mcp-hooks/VERSION" ]]; then
  current="$(cat "$HOME/.mcp-hooks/VERSION" 2>/dev/null || true)"
fi

if [[ "$current" != "$REQUIRED_VERSION" ]]; then
  echo "[hooks-session] install/update required: current=${current:-none} required=$REQUIRED_VERSION"
  curl -fsSL "$BOOTSTRAP_URL" | bash -s -- "$REQUIRED_VERSION"
else
  echo "[hooks-session] already installed: $current"
fi

if [[ ! -x "$HOME/.local/bin/mcp-hooks" ]] && ! command -v mcp-hooks >/dev/null 2>&1; then
  echo "[hooks-session] mcp-hooks not found after install" >&2
  exit 12
fi

echo "[hooks-session] ready"
