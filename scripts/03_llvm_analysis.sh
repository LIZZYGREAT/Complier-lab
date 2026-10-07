#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LAB_DIR="$ROOT_DIR/lab"

cd "$LAB_DIR"
mkdir -p outputs
test -s generated/example.ll

printf 'Stage 3: extract and inspect Clang-generated LLVM IR\n'
sed -n '/define.*@calc/,/^}/p' generated/example.ll > outputs/calc_generated.ll
sed -n '/define.*@main/,/^}/p' generated/example.ll > outputs/main_generated.ll

printf '\n[calc function: outputs/calc_generated.ll]\n'
cat outputs/calc_generated.ll
printf '\n[main function: outputs/main_generated.ll]\n'
cat outputs/main_generated.ll

printf '\n[Block labels and control-transfer instructions]\n'
grep -E '^[0-9]+:|^[[:space:]]+br |^[[:space:]]+ret ' outputs/calc_generated.ll

for instruction in alloca load store add mul srem icmp br call ret; do
    if ! grep -q "$instruction" outputs/calc_generated.ll outputs/main_generated.ll; then
        printf 'ERROR: expected IR instruction missing: %s\n' "$instruction" >&2
        exit 1
    fi
done

printf '\nStage 3 IR extraction and instruction checks: PASS\n'
