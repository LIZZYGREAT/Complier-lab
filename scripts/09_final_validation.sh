#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LAB_DIR="$ROOT_DIR/lab"

source "$ROOT_DIR/env.sh"
cd "$LAB_DIR"
mkdir -p outputs

for executable in generated/reference generated/manual_llvm generated/manual_riscv; do
    if [[ ! -x "$executable" ]]; then
        printf 'ERROR: required executable is missing: %s\n' "$executable" >&2
        exit 1
    fi
done

printf 'Stage 9: final consistency check across reference, LLVM IR, and RISC-V\n'
printf 'Runtime outputs from the RISC-V library go to stderr and remain visible in this log.\n\n'

printf '| Input | Reference | LLVM | RISC-V | Result |\n' > outputs/final-validation.md
printf '| ---: | ---: | ---: | ---: | :---: |\n' >> outputs/final-validation.md

overall=PASS
for test_case in '1 1' '2 5' '3 8' '4 16' '5 21' '10 85'; do
    read -r input expected <<< "$test_case"
    reference="$(printf '%s\n' "$input" | "$LAB_DIR/generated/reference")"
    llvm="$(printf '%s\n' "$input" | "$LAB_DIR/generated/manual_llvm")"
    riscv="$(printf '%s\n' "$input" | "$LAB_DIR/source/run_manual_riscv.sh")"

    result=PASS
    if [[ "$reference" != "$expected" || "$llvm" != "$expected" || "$riscv" != "$expected" ]]; then
        result=FAIL
        overall=FAIL
    fi
    printf '| %s | %s | %s | %s | %s |\n' \
        "$input" "$reference" "$llvm" "$riscv" "$result" \
        >> outputs/final-validation.md
    printf 'n=%s expected=%s reference=%s llvm=%s riscv=%s %s\n' \
        "$input" "$expected" "$reference" "$llvm" "$riscv" "$result"
done

printf '\n[Final result table]\n'
cat outputs/final-validation.md
printf '\nStage 9 final consistency: %s\n' "$overall"
[[ "$overall" == PASS ]]
