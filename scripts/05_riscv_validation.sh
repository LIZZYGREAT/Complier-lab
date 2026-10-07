#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LAB_DIR="$ROOT_DIR/lab"
COURSE_DIR="$ROOT_DIR/SysY_Compiler_2025"

source "$ROOT_DIR/env.sh"
source "$COURSE_DIR/toolchain.conf"
cd "$LAB_DIR"
mkdir -p generated outputs

RISCV_GCC_BIN="$RISCV_TOOLCHAIN/bin/$RISCV_GCC"
RISCV_READELF_BIN="$RISCV_TOOLCHAIN/bin/riscv64-unknown-elf-readelf"

printf 'Stage 6: assemble, link SysY runtime, and execute hand-written RISC-V\n'
printf 'Compiler: %s\n' "$RISCV_GCC_BIN"
printf 'Runtime: %s\n' "$COURSE_DIR/lib/libsysy_riscv.a"
printf 'Configured text address: %s\n' "$TEXT_ADDR"
printf 'QEMU: %s\n' "$(command -v qemu-riscv64)"

printf '\n[Assemble manual source]\n'
printf '+ %s -march=rv64gc -mabi=lp64d -mcmodel=medany -c riscv/manual.s -o generated/manual_riscv.o\n' "$RISCV_GCC_BIN"
"$RISCV_GCC_BIN" -march=rv64gc -mabi=lp64d -mcmodel=medany \
    -c riscv/manual.s -o generated/manual_riscv.o

printf '\n[Link with the existing course SysY runtime]\n'
printf '+ %s generated/manual_riscv.o -o generated/manual_riscv -L%s -lsysy_riscv -static -march=rv64gc -mabi=lp64d -mcmodel=medany -Wl,--no-relax,-Ttext=%s\n' \
    "$RISCV_GCC_BIN" "$COURSE_DIR/lib" "$TEXT_ADDR"
"$RISCV_GCC_BIN" generated/manual_riscv.o -o generated/manual_riscv \
    -L"$COURSE_DIR/lib" -lsysy_riscv -static \
    -march=rv64gc -mabi=lp64d -mcmodel=medany \
    -Wl,--no-relax,-Ttext="$TEXT_ADDR"

printf '\n[ELF executable]\n'
file generated/manual_riscv
"$RISCV_READELF_BIN" -h generated/manual_riscv

printf '\n[Fixed input/output cases through QEMU]\n'
bash source/test_reference.sh "$LAB_DIR/source/run_manual_riscv.sh" | tee outputs/manual-riscv-test.txt

printf '\nStage 6 hand-written RISC-V: PASS\n'
