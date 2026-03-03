#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 \"완료 내용(한글 문장 포함)\""
  exit 2
fi

message="$*"
lang_check_message="$(printf '%s' "$message" | sed -E 's/\([Hh][Oo][Oo]?[Kk][[:space:]]+[Tt][Ee][Ss][Tt]\)//g')"
if ! printf '%s' "$lang_check_message" | grep -Eq '[가-힣]'; then
  echo "error: 내용에 한글 문장을 최소 1회 포함해주세요."
  exit 2
fi

marker="${HOOK_TEST_MARKER:-}"
if [[ -n "$marker" && "$message" != *"$marker" ]]; then
  message="${message} ${marker}"
fi

repo_name="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")"
branch_name="$(git branch --show-current 2>/dev/null || echo no-branch)"
timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
line="${timestamp} (${branch_name}) - ${message}"
remote_file="/root/progress/${repo_name}.txt"

echo "[progress-hook] progress 훅으로 실행됨: ${remote_file} 에 완료 기록을 남깁니다."

if [[ "$(hostname -s 2>/dev/null || true)" == "app-server" ]]; then
  mkdir -p /root/progress
  printf '%s\n' "$line" >> "$remote_file"
else
  printf '%s\n' "$line" | ssh dev-vul "mkdir -p /root/progress && cat >> '$remote_file'"
fi

echo "[progress-hook] 기록 완료: $line"
