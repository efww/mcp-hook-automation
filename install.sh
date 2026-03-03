#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"
if [[ ! -f "$SCRIPT_DIR/VERSION" ]]; then
  echo "[hooks-install] VERSION file not found in $SCRIPT_DIR" >&2
  echo "[hooks-install] tip: use bootstrap.sh for remote install" >&2
  exit 4
fi
PACKAGE_VERSION="$(cat "$SCRIPT_DIR/VERSION")"
TARGET_DIR="${MCP_HOOKS_HOME:-$HOME/.mcp-hooks}"
BIN_DIR="${MCP_HOOKS_BIN_DIR:-$HOME/.local/bin}"
WITH_CODEX_WRAPPER=0
REQUIRED_VERSION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-dir)
      TARGET_DIR="$2"
      shift 2
      ;;
    --bin-dir)
      BIN_DIR="$2"
      shift 2
      ;;
    --with-codex-wrapper)
      WITH_CODEX_WRAPPER=1
      shift
      ;;
    --version)
      REQUIRED_VERSION="$2"
      shift 2
      ;;
    *)
      echo "[hooks-install] unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -n "$REQUIRED_VERSION" && "$REQUIRED_VERSION" != "$PACKAGE_VERSION" ]]; then
  echo "[hooks-install] version mismatch: required=$REQUIRED_VERSION package=$PACKAGE_VERSION" >&2
  exit 3
fi

if [[ ! -d "$SCRIPT_DIR/hooks" ]]; then
  echo "[hooks-install] hooks directory not found: $SCRIPT_DIR/hooks" >&2
  exit 4
fi

mkdir -p "$TARGET_DIR/hooks" "$BIN_DIR"
cp "$SCRIPT_DIR/hooks/"*.sh "$TARGET_DIR/hooks/"
chmod +x "$TARGET_DIR/hooks/"*.sh
printf '%s\n' "$PACKAGE_VERSION" > "$TARGET_DIR/VERSION"
printf '%s\n' "$SCRIPT_DIR" > "$TARGET_DIR/INSTALL_SOURCE"

cat > "$BIN_DIR/mcp-hooks" <<'HOOKS'
#!/usr/bin/env bash
set -euo pipefail

HOOK_HOME="${MCP_HOOKS_HOME:-$HOME/.mcp-hooks}"
HOOK_DIR="$HOOK_HOME/hooks"

usage() {
  cat <<USAGE
usage:
  mcp-hooks version
  mcp-hooks progress "완료 내용"
  mcp-hooks gate <command...>
  mcp-hooks pnpm [--fix] <command...>
  mcp-hooks git <git command...>
  mcp-hooks release <dmg|exe> [repo_dir] [dotenv_path]
  mcp-hooks docs [target_dir]
USAGE
}

cmd="${1:-}"
if [[ -z "$cmd" ]]; then
  usage
  exit 2
fi
shift || true

case "$cmd" in
  version)
    cat "$HOOK_HOME/VERSION"
    ;;
  progress)
    "$HOOK_DIR/progress_append.sh" "$@"
    ;;
  gate)
    "$HOOK_DIR/run_with_progress_gate.sh" "$@"
    ;;
  pnpm)
    "$HOOK_DIR/pnpm_guard.sh" "$@"
    ;;
  git)
    "$HOOK_DIR/git_sync_guard.sh" "$@"
    ;;
  release)
    "$HOOK_DIR/release_preflight.sh" "$@"
    ;;
  docs)
    "$HOOK_DIR/docs_filename_lint.sh" "$@"
    ;;
  *)
    echo "unknown subcommand: $cmd" >&2
    usage
    exit 2
    ;;
esac
HOOKS
chmod +x "$BIN_DIR/mcp-hooks"

# Save real codex path for optional wrapper install
REAL_CODEX_PATH=""
if [[ -n "${REAL_CODEX_PATH:-}" ]]; then
  REAL_CODEX_PATH="$REAL_CODEX_PATH"
fi
while IFS= read -r cand; do
  [[ -z "$cand" ]] && continue
  if [[ "$cand" == "$BIN_DIR/codex" ]]; then
    continue
  fi
  REAL_CODEX_PATH="$cand"
  break
done < <(which -a codex 2>/dev/null | awk '!seen[$0]++')

if [[ -n "$REAL_CODEX_PATH" ]]; then
  printf '%s\n' "$REAL_CODEX_PATH" > "$TARGET_DIR/REAL_CODEX_PATH"
fi

if [[ "$WITH_CODEX_WRAPPER" -eq 1 ]]; then
  if [[ -z "$REAL_CODEX_PATH" ]]; then
    echo "[hooks-install] unable to detect real codex path" >&2
    exit 5
  fi

  cat > "$BIN_DIR/codex" <<'WRAP'
#!/usr/bin/env bash
set -euo pipefail

HOOK_HOME="${MCP_HOOKS_HOME:-$HOME/.mcp-hooks}"
REAL_FILE="$HOOK_HOME/REAL_CODEX_PATH"

if [[ ! -f "$REAL_FILE" ]]; then
  echo "[hooks-codex] REAL_CODEX_PATH not found at $REAL_FILE" >&2
  exit 90
fi

REAL_CODEX="$(cat "$REAL_FILE")"
if [[ ! -x "$REAL_CODEX" ]]; then
  echo "[hooks-codex] real codex not executable: $REAL_CODEX" >&2
  exit 91
fi

exec "$REAL_CODEX" "$@"
WRAP
  chmod +x "$BIN_DIR/codex"
fi

echo "[hooks-install] installed version=$PACKAGE_VERSION"
echo "[hooks-install] hook home: $TARGET_DIR"
echo "[hooks-install] command installed: $BIN_DIR/mcp-hooks"
if [[ "$WITH_CODEX_WRAPPER" -eq 1 ]]; then
  echo "[hooks-install] codex wrapper installed: $BIN_DIR/codex"
fi
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  echo "[hooks-install] add to PATH: export PATH=\"$BIN_DIR:\$PATH\""
fi
