#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LAB_DIR="$ROOT_DIR/lab"

source "$ROOT_DIR/env.sh"
cd "$LAB_DIR"
mkdir -p mlir/references

printf 'Stage 8: check local MLIR/AscendNPU exploration tools\n'
for tool in bishengir-opt bishengir-compile mlir-opt mlir-translate npu-smi; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf 'AVAILABLE %-20s %s\n' "$tool" "$(command -v "$tool")"
    else
        printf 'NOT AVAILABLE %s\n' "$tool"
    fi
done

printf '\n[Ascend environment]\n'
if [[ -n "${ASCEND_HOME_PATH:-}" ]]; then
    printf 'ASCEND_HOME_PATH=%s\n' "$ASCEND_HOME_PATH"
else
    printf 'ASCEND_HOME_PATH is unset.\n'
fi
for candidate in /usr/local/Ascend/ascend-toolkit /usr/local/ascend-toolkit; do
    if [[ -d "$candidate" ]]; then
        printf 'FOUND %s\n' "$candidate"
    else
        printf 'NOT FOUND %s\n' "$candidate"
    fi
done

printf '\n[Local course slides/documents]\n'
local_materials="$(
    rg --files "$ROOT_DIR" -g '*.pdf' -g '*.ppt' -g '*.pptx' -g '*.odp' \
        -g '!SysY_Compiler_2025/.git/**' 2>/dev/null || true
)"
if [[ -n "$local_materials" ]]; then
    printf '%s\n' "$local_materials"
else
    printf 'No local PDF/PPT course materials found under the workspace.\n'
fi

printf '\nNo Ascend/CANN installation or NPU execution is attempted in this stage.\n'
printf 'Stage 8 local tool inventory: PASS\n'
