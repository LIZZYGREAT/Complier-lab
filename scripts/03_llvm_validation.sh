#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LAB_DIR="$ROOT_DIR/lab"

source "$ROOT_DIR/env.sh"
cd "$LAB_DIR"
mkdir -p generated outputs

printf 'Stage 4: compile and validate the hand-written LLVM IR\n'
printf '+ clang -O0 llvm/manual.ll source/host_runtime.c -o generated/manual_llvm\n'
clang -O0 llvm/manual.ll source/host_runtime.c -o generated/manual_llvm

printf '\n[Executable]\n'
file generated/manual_llvm

printf '\n[Fixed input/output cases]\n'
bash source/test_reference.sh "$LAB_DIR/generated/manual_llvm" | tee outputs/manual-llvm-test.txt

printf '\nStage 4 hand-written LLVM IR: PASS\n'
