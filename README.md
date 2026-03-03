# MCP Hook Automation

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/efww/mcp-hook-automation/main/bootstrap.sh | bash
```

Install specific version:

```bash
curl -fsSL https://raw.githubusercontent.com/efww/mcp-hook-automation/main/bootstrap.sh | bash -s -- 2026.03.04.1
```

## Session 1-time check

```bash
HOOKS_REQUIRED_VERSION=2026.03.04.1
if [ ! -f ~/.mcp-hooks/VERSION ] || [ "$(cat ~/.mcp-hooks/VERSION 2>/dev/null)" != "$HOOKS_REQUIRED_VERSION" ]; then
  curl -fsSL https://raw.githubusercontent.com/efww/mcp-hook-automation/main/bootstrap.sh | bash -s -- "$HOOKS_REQUIRED_VERSION"
fi
[ -x ~/.local/bin/mcp-hooks ] || command -v mcp-hooks >/dev/null
```

## Commands

```bash
mcp-hooks version
mcp-hooks progress "작업 완료"
mcp-hooks gate <command...>
mcp-hooks pnpm [--fix] <command...>
mcp-hooks git <git command...>
mcp-hooks release <dmg|exe> [repo_dir] [dotenv_path]
mcp-hooks docs [target_dir]
```

Optional codex wrapper install:

```bash
curl -fsSL https://raw.githubusercontent.com/efww/mcp-hook-automation/main/bootstrap.sh | bash -s -- --with-codex-wrapper
```
