#!/usr/bin/env bash
set -euo pipefail

target_path="${1:-docs}"
marker="${HOOK_TEST_MARKER:-}"

if [[ ! -e "$target_path" ]]; then
  echo "[docs-hook] skip: 경로 없음 ($target_path) ${marker}"
  exit 0
fi

invalid=0
files_count=0
seen_file="$(mktemp)"
scan_list="$(mktemp)"
trap 'rm -f "$seen_file" "$scan_list"' EXIT

if [[ -d "$target_path" ]]; then
  find "$target_path" -type f -name '*.md' 2>/dev/null | sort > "$scan_list"
elif [[ -f "$target_path" ]]; then
  if [[ "$target_path" == *.md ]]; then
    printf '%s\n' "$target_path" > "$scan_list"
  else
    echo "[docs-hook] skip: md 파일이 아님 ($target_path) ${marker}"
    exit 0
  fi
else
  echo "[docs-hook] skip: 지원하지 않는 경로 타입 ($target_path) ${marker}"
  exit 0
fi

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  files_count=$((files_count + 1))
  base="$(basename "$f")"
  if [[ ! "$base" =~ ^[0-9]{6}_[0-9]+_.+\.md$ ]]; then
    echo "[docs-hook] invalid name: $f ${marker}" >&2
    invalid=1
    continue
  fi
  prefix="$(sed -E 's/^([0-9]{6}_[0-9]+)_.+\.md$/\1/' <<< "$base")"
  prev="$(awk -F '\t' -v p="$prefix" '$1==p{print $2; exit}' "$seen_file")"
  if [[ -n "$prev" ]]; then
    echo "[docs-hook] duplicate prefix: $prefix -> $f and $prev ${marker}" >&2
    invalid=1
  else
    printf '%s\t%s\n' "$prefix" "$f" >> "$seen_file"
  fi
done < "$scan_list"

if [[ "$invalid" -eq 1 ]]; then
  echo "[docs-hook] blocked: docs 파일명 규칙 위반 ${marker}" >&2
  exit 71
fi

echo "[docs-hook] pass: docs 파일명 규칙 통과 (${files_count} files) ${marker}"
