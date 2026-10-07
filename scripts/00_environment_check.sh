#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LAB_DIR="$ROOT_DIR/lab"

source "$ROOT_DIR/env.sh"
mkdir -p \
    "$LAB_DIR/source" \
    "$LAB_DIR/generated" \
    "$LAB_DIR/llvm" \
    "$LAB_DIR/riscv" \
    "$LAB_DIR/outputs" \
    "$LAB_DIR/exploration" \
    "$LAB_DIR/mlir/references" \
    "$LAB_DIR/report/figures" \
    "$LAB_DIR/scripts" \
    "$LAB_DIR/logs" \
    "$LAB_DIR/records"

cd "$LAB_DIR"

printf 'Compiler-Labs Stage 0 environment snapshot\n'
printf 'Date: %s\n' "$(date --iso-8601=seconds)"
printf 'Workspace: %s\n' "$ROOT_DIR"
printf 'Lab: %s\n' "$LAB_DIR"
printf 'COMPILER_HOME=%s\n' "$COMPILER_HOME"
printf 'RISCV_TOOLCHAIN=%s\n' "$RISCV_TOOLCHAIN"
printf '\n[Operating system]\n'
uname -a
grep -E '^(PRETTY_NAME|VERSION_ID)=' /etc/os-release

require_tool() {
    local tool="$1"
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'ERROR: required tool not found: %s\n' "$tool" >&2
        return 1
    fi
    printf '%-34s %s\n' "$tool" "$(command -v "$tool")"
}

printf '\n[Required tools]\n'
for tool in gcc clang make flex bison python3 qemu-riscv64 \
    riscv64-unknown-elf-gcc riscv64-unknown-elf-readelf; do
    require_tool "$tool"
done

printf '\n[Tool versions]\n'
gcc --version | sed -n '1p'
clang --version | sed -n '1p'
make --version | sed -n '1p'
flex --version | sed -n '1p'
bison --version | sed -n '1p'
python3 --version
qemu-riscv64 --version | sed -n '1p'
riscv64-unknown-elf-gcc --version | sed -n '1p'

printf '\n[Existing course compiler artifacts]\n'
COURSE_DIR="$ROOT_DIR/SysY_Compiler_2025"
for artifact in bin/compiler lib/libsysy_riscv.a lib/libsysy_x86.a; do
    if [[ -s "$COURSE_DIR/$artifact" ]]; then
        printf 'PRESENT %s\n' "$COURSE_DIR/$artifact"
    else
        printf 'MISSING %s\n' "$COURSE_DIR/$artifact"
    fi
done
git -C "$COURSE_DIR" status --short --branch

printf '\n[Stage 0 source files]\n'
for source_file in source/example.sy source/example_clang.c source/host_runtime.c; do
    if [[ -s "$source_file" ]]; then
        printf 'PRESENT %s\n' "$source_file"
    else
        printf 'MISSING %s\n' "$source_file"
        exit 1
    fi
done

printf '\nStage 0 environment and directory checks: PASS\n'
