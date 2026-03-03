# Hook Automation 운영 매뉴얼

## 1. 목적
- 로컬마다 다른 수동 작업을 줄이고, 동일한 훅 규칙을 같은 방식으로 적용합니다.
- 세션 시작 시 1회 점검으로 설치 누락/버전 불일치를 자동으로 보정합니다.

## 2. 구성
- 설치 경로: `~/.mcp-hooks`
- 실행 명령: `~/.local/bin/mcp-hooks`
- 훅 스크립트:
  - `~/.mcp-hooks/hooks/progress_append.sh`
  - `~/.mcp-hooks/hooks/run_with_progress_gate.sh`
  - `~/.mcp-hooks/hooks/pnpm_guard.sh`
  - `~/.mcp-hooks/hooks/git_sync_guard.sh`
  - `~/.mcp-hooks/hooks/release_preflight.sh`
  - `~/.mcp-hooks/hooks/docs_filename_lint.sh`

## 3. 최초 설치
```bash
curl -fsSL https://raw.githubusercontent.com/efww/mcp-hook-automation/main/bootstrap.sh | bash
```

## 4. 세션 시작 1회 점검
```bash
HOOKS_REQUIRED_VERSION=2026.03.04.1
if [ ! -f ~/.mcp-hooks/VERSION ] || [ "$(cat ~/.mcp-hooks/VERSION 2>/dev/null)" != "$HOOKS_REQUIRED_VERSION" ]; then
  curl -fsSL https://raw.githubusercontent.com/efww/mcp-hook-automation/main/bootstrap.sh | bash -s -- "$HOOKS_REQUIRED_VERSION"
fi
[ -x ~/.local/bin/mcp-hooks ] || command -v mcp-hooks >/dev/null
```

## 5. 운영 명령 예시
- progress 기록:
```bash
mcp-hooks progress "완료 내용"
```
- progress 게이트:
```bash
mcp-hooks gate bash -lc 'mcp-hooks progress "완료" >/dev/null; echo done'
```
- pnpm 규칙 검사:
```bash
mcp-hooks pnpm pnpm install
```
- docs 파일명 검사:
```bash
mcp-hooks docs docs
```

## 6. 업데이트/롤백
- 업데이트:
```bash
curl -fsSL https://raw.githubusercontent.com/efww/mcp-hook-automation/main/bootstrap.sh | bash -s -- <버전>
```
- 롤백: 이전 버전 번호로 동일 명령 실행

## 7. 장애 대응
- `mcp-hooks`가 안 잡히면:
  - `export PATH="$HOME/.local/bin:$PATH"` 확인
  - `~/.local/bin/mcp-hooks version` 직접 실행
- 설치 실패 시:
  - 네트워크 차단 여부 확인
  - GitHub raw/codeload 접근 여부 확인
