#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <command...>"
  exit 2
fi

repo_name="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")"
remote_file="/root/progress/${repo_name}.txt"

get_count() {
  if [[ "$(hostname -s 2>/dev/null || true)" == "app-server" ]]; then
    if [[ -f "$remote_file" ]]; then
      wc -l < "$remote_file"
    else
      echo 0
    fi
  else
    ssh dev-vul "if [ -f '$remote_file' ]; then wc -l < '$remote_file'; else echo 0; fi"
  fi
}

before_count="$(get_count | tr -d '[:space:]')"
echo "[progress-hook] progress 게이트 시작: 이 검사는 전역 AGENTS 규칙이 아니라 훅 스크립트에서 강제됩니다."

set +e
"$@"
cmd_status=$?
set -e

after_count="$(get_count | tr -d '[:space:]')"
if [[ "$cmd_status" -ne 0 ]]; then
  echo "[progress-hook] gate: wrapped command failed (status=$cmd_status). progress check skipped."
  exit "$cmd_status"
fi

if (( after_count <= before_count )); then
  echo "[progress-hook] gate: blocked. progress 기록이 없어서 실패 처리합니다."
  echo "[progress-hook] hint: ./scripts/progress_append.sh \"완료 내용\" 을 먼저 실행해 주세요."
  exit 42
fi

echo "[progress-hook] gate: pass (progress lines $before_count -> $after_count)"
