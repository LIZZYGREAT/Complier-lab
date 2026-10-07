#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REFERENCE_BIN="${1:-$LAB_DIR/generated/reference}"

if [[ ! -x "$REFERENCE_BIN" ]]; then
    printf 'ERROR: reference executable is missing or not executable: %s\n' "$REFERENCE_BIN" >&2
    exit 1
fi

while read -r input expected; do
    [[ -n "$input" ]] || continue
    actual="$(printf '%s\n' "$input" | "$REFERENCE_BIN")"
    if [[ "$actual" != "$expected" ]]; then
        printf 'FAIL n=%s expected=%s actual=%s\n' "$input" "$expected" "$actual"
        exit 1
    fi
    printf 'n=%s -> %s PASS\n' "$input" "$actual"
done <<'CASES'
1 1
2 5
3 8
4 16
5 21
10 85
CASES
