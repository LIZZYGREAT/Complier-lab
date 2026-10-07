#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LAB_DIR="$ROOT_DIR/lab"

source "$ROOT_DIR/env.sh"
cd "$LAB_DIR"
mkdir -p exploration outputs

printf 'Stage 7: generate -O0/-O2 IR and assembly comparisons\n'

printf '\n[Host LLVM IR]\n'
clang -S -emit-llvm -O0 source/example_clang.c -o exploration/O0.ll
clang -S -emit-llvm -O2 source/example_clang.c -o exploration/O2.ll

printf '\n[Host x86-64 assembly]\n'
clang -S -O0 source/example_clang.c -o exploration/O0.s
clang -S -O2 source/example_clang.c -o exploration/O2.s

printf '\n[RISC-V assembly]\n'
clang --target=riscv64-unknown-elf -march=rv64gc -mabi=lp64d \
    -S -O0 source/example_clang.c -o exploration/O0_riscv.s
clang --target=riscv64-unknown-elf -march=rv64gc -mabi=lp64d \
    -S -O2 source/example_clang.c -o exploration/O2_riscv.s

for comparison in \
    'exploration/O0.ll exploration/O2.ll outputs/optimization-ir.diff' \
    'exploration/O0.s exploration/O2.s outputs/optimization-x86.diff' \
    'exploration/O0_riscv.s exploration/O2_riscv.s outputs/optimization-riscv.diff'; do
    read -r before after diff_file <<< "$comparison"
    diff_status=0
    if diff -u "$before" "$after" > "$diff_file"; then
        :
    else
        diff_status=$?
        if [[ "$diff_status" -ne 1 ]]; then
            printf 'ERROR: diff failed for %s and %s\n' "$before" "$after" >&2
            exit "$diff_status"
        fi
    fi
    printf '\n[Diff: %s vs %s]\n' "$before" "$after"
    if [[ -s "$diff_file" ]]; then
        cat "$diff_file"
    else
        printf 'No differences.\n'
    fi
done

printf '\n[Instruction counts in LLVM IR]\n'
for ir_file in exploration/O0.ll exploration/O2.ll; do
    printf '%s\n' "$ir_file"
    printf '  alloca: '
    (grep -cE '^[[:space:]]*%[^=]+ = alloca ' "$ir_file" || true)
    printf '  load:   '
    (grep -cE '^[[:space:]]*%[^=]+ = load ' "$ir_file" || true)
    printf '  store:  '
    (grep -cE '^[[:space:]]*store ' "$ir_file" || true)
    printf '  call:   '
    (grep -cE 'call ' "$ir_file" || true)
done

printf '\nStage 7 optimization artifacts: PASS\n'
