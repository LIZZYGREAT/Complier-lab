#!/usr/bin/env bash
set -euo pipefail

# Stage 13: 用本地构建的 bishengir-opt 实跑 AscendNPU-IR 上游 Pass。
#
# 本脚本做两件事：
#   1) 逐字执行上游 .mlir 文件里自带的 RUN 命令，并用上游自己的 CHECK
#      逐条 FileCheck 断言，确认本地构建复现了上游期望行为；
#   2) 为报告所需的两个具体用例保存干净的 Before / After。
#
# 前置：先跑 scripts/11_ascend_configure.sh 与 scripts/12_ascend_build.sh。
#
# 注意：上游 RUN 命令中的 -hacc-append-device-spec=target=Ascend910B1 是必需项，
# PlanMemory 需要目标芯片规格才能应用对齐与容量约束。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$LAB_DIR/.." && pwd)"

REPO_DIR="$ROOT_DIR/third_party/ascendnpu-ir"
BIN="$REPO_DIR/build/bin/bishengir-opt"
FC="$REPO_DIR/build/bin/FileCheck"
TESTS="$REPO_DIR/bishengir/test/Dialect/HIVM"
OUT="$LAB_DIR/mlir/outputs"
SRCDIR="$LAB_DIR/mlir/sources/selected_tests"

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
[[ -x "$BIN" ]] || die "未找到 bishengir-opt：$BIN"
[[ -x "$FC" ]] || die "未找到 FileCheck：$FC（可运行：ninja -C $REPO_DIR/build FileCheck）"

mkdir -p "$OUT" "$SRCDIR" "$LAB_DIR/mlir/logs"

printf 'bishengir-opt: %s\n' "$("$BIN" --version | head -n 1)"
printf 'FileCheck:     %s\n\n' "$FC"

########################################
# 第 1 部分：逐字执行上游 RUN + FileCheck
########################################
printf '=== [1] 上游 RUN 命令逐字执行（含 FileCheck 断言）===\n'

printf '\n--- plan-memory.mlir 默认策略 ---\n'
"$BIN" "$TESTS/plan-memory.mlir" -hacc-append-device-spec=target=Ascend910B1 \
    -hivm-plan-memory -split-input-file -verify-diagnostics 2>&1 \
  | "$FC" "$TESTS/plan-memory.mlir" && printf 'RESULT: PASS\n'

printf '\n--- plan-memory.mlir largest-first 策略（CHECK-REORDER）---\n'
"$BIN" "$TESTS/plan-memory.mlir" -hacc-append-device-spec=target=Ascend910B1 \
    -hivm-plan-memory=plan-memory-strategy=largest-first -split-input-file \
    -verify-diagnostics 2>&1 \
  | "$FC" "$TESTS/plan-memory.mlir" --check-prefix=CHECK-REORDER && printf 'RESULT: PASS\n'

printf '\n--- inject-sync.mlir ---\n'
"$BIN" -hivm-inject-sync -hivm-lower-multi-buffer-counter -split-input-file \
    "$TESTS/inject-sync.mlir" 2>&1 \
  | "$FC" "$TESTS/inject-sync.mlir" && printf 'RESULT: PASS\n'

########################################
# 第 2 部分：保存单用例 Before / After
########################################
printf '\n=== [2] 单用例 Before / After ===\n'

# PlanMemory：上游 plan-memory.mlir 的第一个用例（test_mem_allocate_basic）
sed -n '1,34p' "$TESTS/plan-memory.mlir" > "$SRCDIR/plan_memory_input.mlir"
cp "$SRCDIR/plan_memory_input.mlir" "$OUT/plan_memory_before.mlir"
"$BIN" "$OUT/plan_memory_before.mlir" -hacc-append-device-spec=target=Ascend910B1 \
    -hivm-plan-memory -split-input-file -verify-diagnostics > "$OUT/plan_memory_after.mlir"
printf 'plan-memory  before alloc=%s  after alloc=%s  pointer_cast=%s\n' \
    "$(grep -c 'memref\.alloc()' "$OUT/plan_memory_before.mlir" || true)" \
    "$(grep -c 'memref\.alloc()' "$OUT/plan_memory_after.mlir" || true)" \
    "$(grep -c 'pointer_cast' "$OUT/plan_memory_after.mlir" || true)"

# InjectSync：上游 inject-sync.mlir 的第一个用例（test_mem_injcet_sync_basic）
# 去掉开头的 "// -----" 分隔符，单用例不需要。
sed -n '4,30p' "$TESTS/inject-sync.mlir" > "$SRCDIR/sync_input.mlir"
cp "$SRCDIR/sync_input.mlir" "$OUT/sync_before.mlir"
"$BIN" "$OUT/sync_before.mlir" -hivm-inject-sync -hivm-lower-multi-buffer-counter \
    -split-input-file > "$OUT/sync_after.mlir"
# 统计时必须排除 // CHECK: 注释行，否则 Before 的计数会被上游断言文本污染，
# 得出"Before 也有同步"的错误结论。
count_code() { grep -v '^[[:space:]]*//' "$1" | grep -c "$2" || true; }
printf 'inject-sync  before(set_flag 代码行)=%s  after set_flag=%s  after wait_flag=%s  after barrier=%s\n' \
    "$(count_code "$OUT/sync_before.mlir" 'set_flag')" \
    "$(count_code "$OUT/sync_after.mlir" 'set_flag')" \
    "$(count_code "$OUT/sync_after.mlir" 'wait_flag')" \
    "$(count_code "$OUT/sync_after.mlir" 'pipe_barrier')"

printf '\nStage 13 AscendNPU-IR pass runs: PASS\n'
