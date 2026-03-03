#!/usr/bin/env bash
set -euo pipefail

marker="${HOOK_TEST_MARKER:-}"
if [[ $# -lt 2 ]]; then
  echo "[git-hook] usage: $0 git <pull|push|...> ${marker}" >&2
  exit 2
fi

if [[ "$1" != "git" ]]; then
  echo "[git-hook] blocked: 첫 인자는 git 이어야 합니다. ${marker}" >&2
  exit 46
fi

subcmd="$2"

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

  # pull은 ff-only로 고정
  run_cmd git pull --ff-only

  if [[ "$stashed" -eq 1 ]]; then
    echo "[git-hook] stash 요약(수동 확인 필요): ${marker}"
    git stash list | head -n 1
    echo "[git-hook] blocked: stash 적용 전 사용자 확인 필요 ${marker}" >&2
    exit 51
  fi
  exit 0
fi

if [[ "$subcmd" == "push" ]]; then
  run_cmd "$@"
  exit 0
fi

# 기타 git 명령은 통과
run_cmd "$@"
