#!/usr/bin/env bash
set -euo pipefail

marker="${HOOK_TEST_MARKER:-}"
if [[ $# -lt 1 ]]; then
  echo "[git-hook] usage: $0 <pull|push|...>  (or: $0 git <pull|push|...>) ${marker}" >&2
  exit 2
fi

# Accept both forms:
#   mcp-hooks git pull
#   mcp-hooks git git pull   (legacy)
if [[ "${1:-}" == "git" ]]; then
  shift
fi

if [[ $# -lt 1 ]]; then
  echo "[git-hook] usage: $0 <pull|push|...>  (or: $0 git <pull|push|...>) ${marker}" >&2
  exit 2
fi

subcmd="$1"

run_cmd() {
  "$@"
}

if [[ "$subcmd" == "pull" ]]; then
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  branch="$(git branch --show-current 2>/dev/null || echo no-branch)"
  dirty=0
  if [[ -n "$(git status --short 2>/dev/null || true)" ]]; then
    dirty=1
  fi

  stashed=0
  if [[ "$dirty" -eq 1 ]]; then
    stash_msg="hook-auto-stash-${branch}-$(date +%Y%m%d%H%M%S) ${marker}"
    git stash push -u -m "$stash_msg" >/dev/null
    stashed=1
    echo "[git-hook] dirty 감지 -> stash 생성: $stash_msg ${marker}"
  fi

  # pull은 ff-only로 고정, 추가 인자(remote/branch 등)는 유지
  run_cmd git pull --ff-only "${@:2}"

  if [[ "$stashed" -eq 1 ]]; then
    echo "[git-hook] stash 요약(수동 확인 필요): ${marker}"
    git stash list | head -n 1
    echo "[git-hook] blocked: stash 적용 전 사용자 확인 필요 ${marker}" >&2
    exit 51
  fi
  exit 0
fi

if [[ "$subcmd" == "push" ]]; then
  run_cmd git "$@"
  exit 0
fi

# 기타 git 명령은 통과
run_cmd git "$@"
