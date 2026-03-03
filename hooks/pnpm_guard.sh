#!/usr/bin/env bash
set -euo pipefail

marker="${HOOK_TEST_MARKER:-}"
fix_mode=0
if [[ "${1:-}" == "--fix" ]]; then
  fix_mode=1
  shift
fi

if [[ $# -lt 1 ]]; then
  echo "[pnpm-hook] usage: $0 [--fix] <command...> ${marker}" >&2
  exit 2
fi

cmd=("$@")

for arg in "${cmd[@]}"; do
  if [[ "$arg" == "npm" || "$arg" == "yarn" ]]; then
    echo "[pnpm-hook] blocked: npm/yarn 금지. pnpm만 사용하세요. ${marker}" >&2
    exit 44
  fi
done

if ! repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "[pnpm-hook] blocked: Git 리포 안에서만 실행 가능합니다. ${marker}" >&2
  exit 47
fi

lock_files="$(
  find "$repo_root" \
    \( -path '*/.git/*' -o -path '*/node_modules/*' \) -prune -o \
    -name 'package-lock.json' -type f -print 2>/dev/null || true
)"
if [[ -n "$lock_files" ]]; then
  if [[ "$fix_mode" -eq 1 ]]; then
    while IFS= read -r lf; do
      [[ -z "$lf" ]] && continue
      rm -f "$lf"
      echo "[pnpm-hook] removed disallowed lock file: $lf ${marker}" >&2
    done <<< "$lock_files"
  else
    while IFS= read -r lf; do
      [[ -z "$lf" ]] && continue
      echo "[pnpm-hook] found disallowed lock file: $lf ${marker}" >&2
    done <<< "$lock_files"
  fi
  echo "[pnpm-hook] blocked: package-lock.json 감지로 중단 ${marker}" >&2
  exit 45
fi

"${cmd[@]}"
