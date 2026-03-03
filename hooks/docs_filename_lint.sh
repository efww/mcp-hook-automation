#!/usr/bin/env bash
set -euo pipefail

target_dir="${1:-docs}"
marker="${HOOK_TEST_MARKER:-}"

if [[ ! -d "$target_dir" ]]; then
  echo "[docs-hook] skip: docs 디렉터리 없음 ($target_dir) ${marker}"
  exit 0
fi

invalid=0
files_count=0
seen_file="$(mktemp)"
trap 'rm -f "$seen_file"' EXIT

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
done < <(find "$target_dir" -type f -name '*.md' 2>/dev/null | sort)

if [[ "$invalid" -eq 1 ]]; then
  echo "[docs-hook] blocked: docs 파일명 규칙 위반 ${marker}" >&2
  exit 71
fi

echo "[docs-hook] pass: docs 파일명 규칙 통과 (${files_count} files) ${marker}"
