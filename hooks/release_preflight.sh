#!/usr/bin/env bash
set -euo pipefail

mode="${1:-}"
repo_dir="${2:-$(pwd)}"
dotenv_path="${3:-$repo_dir/server-auth/.env}"
marker="${HOOK_TEST_MARKER:-}"

if [[ -z "$mode" || ( "$mode" != "dmg" && "$mode" != "exe" ) ]]; then
  echo "[release-hook] usage: $0 <dmg|exe> [repo_dir] [dotenv_path] ${marker}" >&2
  exit 2
fi

cargo_toml="$repo_dir/multichart-core/Cargo.toml"
if [[ ! -f "$cargo_toml" ]]; then
  echo "[release-hook] blocked: Cargo.toml 없음 ($cargo_toml) ${marker}" >&2
  exit 61
fi

version_line="$(rg '^version\s*=\s*"' "$cargo_toml" | head -n 1 || true)"
if [[ -z "$version_line" ]]; then
  echo "[release-hook] blocked: version 필드 없음 ${marker}" >&2
  exit 62
fi

version="$(sed -E 's/.*"([^"]+)".*/\1/' <<< "$version_line")"

echo "[release-hook] detected version=$version mode=$mode ${marker}"

if [[ "$mode" == "exe" && "$version" == *-dev* ]]; then
  echo "[release-hook] blocked: exe는 -dev 버전 금지 ${marker}" >&2
  exit 63
fi

if [[ ! -f "$dotenv_path" ]]; then
  echo "[release-hook] blocked: .env 없음 ($dotenv_path) ${marker}" >&2
  exit 64
fi

allowed_line="$(rg '^AUTH_ALLOWED_BUILD_IDS=' "$dotenv_path" | head -n 1 || true)"
if [[ -z "$allowed_line" ]]; then
  echo "[release-hook] blocked: AUTH_ALLOWED_BUILD_IDS 없음 ${marker}" >&2
  exit 65
fi

if ! grep -q "$version" <<< "$allowed_line"; then
  echo "[release-hook] blocked: AUTH_ALLOWED_BUILD_IDS에 현재 버전 누락 (${version}) ${marker}" >&2
  exit 66
fi

echo "[release-hook] pass: AUTH_ALLOWED_BUILD_IDS contains ${version} ${marker}"
