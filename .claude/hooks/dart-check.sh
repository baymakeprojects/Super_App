#!/usr/bin/env bash
# Hook PostToolUse: setiap Claude Code mengedit file .dart,
# file itu diformat lalu dianalisis. Kalau analyze menemukan error/warning,
# hasilnya dikirim balik ke Claude (exit 2) supaya langsung diperbaiki.
# Tidak butuh jq, jadi jalan juga di Git Bash Windows.

input="$(cat)"

# Ambil "file_path":"..." dari JSON masukan hook.
file="$(printf '%s' "$input" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
# Path Windows memakai \\ di JSON; ubah jadi /.
file="${file//\\\\//}"

case "$file" in
  *.dart) ;;
  *) exit 0 ;;
esac

# Lewati kode turunan.
case "$file" in
  *.g.dart|*.freezed.dart) exit 0 ;;
esac

[ -f "$file" ] || exit 0

command -v dart >/dev/null 2>&1 || exit 0

dart format "$file" >/dev/null 2>&1

result="$(dart analyze --fatal-infos "$file" 2>&1)"
status=$?

if [ $status -ne 0 ]; then
  echo "dart analyze menemukan masalah di $file — perbaiki sebelum lanjut:" >&2
  echo "$result" >&2
  exit 2
fi

exit 0
