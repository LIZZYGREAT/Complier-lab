#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LAB_DIR="$ROOT_DIR/lab"

source "$ROOT_DIR/env.sh"
cd "$LAB_DIR"
mkdir -p generated outputs

printf 'Stage 2: observe the Clang compilation pipeline\n'

printf '\n[Preprocess]\n'
printf '+ clang -E source/example_clang.c -o generated/example.i\n'
clang -E source/example_clang.c -o generated/example.i

printf '\n[Emit LLVM IR at -O0]\n'
printf '+ clang -S -emit-llvm -O0 source/example_clang.c -o generated/example.ll\n'
clang -S -emit-llvm -O0 source/example_clang.c -o generated/example.ll

printf '\n[Emit host x86-64 assembly at -O0]\n'
printf '+ clang -S -O0 source/example_clang.c -o generated/example_x86.s\n'
clang -S -O0 source/example_clang.c -o generated/example_x86.s

printf '\n[Assemble object files]\n'
printf '+ clang -c -O0 source/example_clang.c -o generated/example.o\n'
clang -c -O0 source/example_clang.c -o generated/example.o
printf '+ clang -c -O0 source/host_runtime.c -o generated/host_runtime.o\n'
clang -c -O0 source/host_runtime.c -o generated/host_runtime.o

printf '\n[ELF object inspection]\n'
file generated/example.o generated/host_runtime.o
readelf -h generated/example.o
readelf -S generated/example.o
readelf -s generated/example.o
readelf -r generated/example.o
readelf -s generated/host_runtime.o
readelf -r generated/host_runtime.o

printf '\n[Explicit link]\n'
printf '+ clang -v generated/example.o generated/host_runtime.o -o generated/reference_linked\n'
clang -v generated/example.o generated/host_runtime.o -o generated/reference_linked
file generated/reference_linked

printf '\n[Run the same fixed input/output cases]\n'
bash source/test_reference.sh "$LAB_DIR/generated/reference_linked" | tee outputs/reference-linked-test.txt

printf '\nStage 2 compilation pipeline: PASS\n'
