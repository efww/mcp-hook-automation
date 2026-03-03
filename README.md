# MCP Hook Automation

Install once:

```bash
curl -fsSL https://raw.githubusercontent.com/efww/mcp-hook-automation/main/install.sh | bash
```

Then use:

```bash
mcp-hooks version
mcp-hooks progress "작업 완료"
mcp-hooks gate bash -lc 'mcp-hooks progress "완료" >/dev/null; echo done'
```

Optional codex wrapper install:

```bash
curl -fsSL https://raw.githubusercontent.com/efww/mcp-hook-automation/main/install.sh | bash -s -- --with-codex-wrapper
```
