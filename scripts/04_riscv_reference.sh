#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LAB_DIR="$ROOT_DIR/lab"

source "$ROOT_DIR/env.sh"
cd "$LAB_DIR"
mkdir -p generated

printf 'Stage 5: generate RISC-V reference assembly with Clang\n'
printf '+ clang --target=riscv64-unknown-elf -march=rv64gc -mabi=lp64d -S -O0 source/example_clang.c -o generated/example_riscv.s\n'
clang --target=riscv64-unknown-elf -march=rv64gc -mabi=lp64d \
    -S -O0 source/example_clang.c -o generated/example_riscv.s

printf '\n[Generated assembly file]\n'
file generated/example_riscv.s
cat generated/example_riscv.s

printf '\n[Course runtime/linker configuration]\n'
COURSE_DIR="$ROOT_DIR/SysY_Compiler_2025"
cat "$COURSE_DIR/toolchain.conf"
printf '\n[Assembly/link helper details]\n'
sed -n '1,100p' "$COURSE_DIR/asm2bin.sh"
printf '\n[Existing RISC-V runtime archive members]\n'
"$RISCV_TOOLCHAIN/bin/riscv64-unknown-elf-ar" t "$COURSE_DIR/lib/libsysy_riscv.a"
printf '\n[Available checked-in linker scripts]\n'
if find "$COURSE_DIR" -type f \( -name '*.ld' -o -name '*.lds' \) -print | grep .; then
    :
else
    printf 'No .ld/.lds files found; asm2bin.sh uses configured -Ttext address.\n'
fi

printf '\nStage 5 RISC-V reference generation: PASS\n'
