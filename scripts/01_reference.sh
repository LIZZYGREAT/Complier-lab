#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LAB_DIR="$ROOT_DIR/lab"

source "$ROOT_DIR/env.sh"
cd "$LAB_DIR"
mkdir -p generated outputs

printf 'Stage 1: compile and test the host reference program\n'
printf '+ clang -O0 source/example_clang.c source/host_runtime.c -o generated/reference\n'
clang source/example_clang.c source/host_runtime.c -O0 -o generated/reference

printf '\n[Executable]\n'
file generated/reference

printf '\n[Fixed input/output cases]\n'
bash source/test_reference.sh "$LAB_DIR/generated/reference" | tee outputs/reference-test.txt

printf '\nStage 1 reference baseline: PASS\n'
