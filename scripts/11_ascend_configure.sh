#!/usr/bin/env bash
set -euo pipefail

# Stage 11: 只做 AscendNPU-IR 的 CMake 配置验证，不编译。
#
# 目的：在不启动数小时编译的前提下，确认依赖、编译器、目标注册能否通过配置阶段，
# 并验证 bishengir-opt 这个 target 确实被生成出来。
#
# 依赖（都在仓库之外，不进版本管理）：
#   ../third_party/ascendnpu-ir          AscendNPU-IR 源码（含其 llvm-project 子模块）
#   ../.venv-ascendnpu/bin/{cmake,ninja}  由 pip 提供的 CMake >= 3.28 与 Ninja >= 1.12
#
# 用法：
#   bash scripts/11_ascend_configure.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$LAB_DIR/.." && pwd)"

REPO_DIR="$ROOT_DIR/third_party/ascendnpu-ir"
LLVM_SRC="$REPO_DIR/third-party/llvm-project"
BUILD_DIR="$REPO_DIR/build"
VENV_BIN="$ROOT_DIR/.venv-ascendnpu/bin"

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ -d "$REPO_DIR" ]] || die "AscendNPU-IR 源码不存在：$REPO_DIR（需先克隆）"
[[ -d "$LLVM_SRC/llvm" ]] || die "LLVM 源码不存在：$LLVM_SRC/llvm（需先初始化子模块）"
[[ -x "$VENV_BIN/cmake" ]] || die "缺少 $VENV_BIN/cmake（pip install cmake）"
[[ -x "$VENV_BIN/ninja" ]] || die "缺少 $VENV_BIN/ninja（pip install ninja）"

export PATH="$VENV_BIN:$PATH"

printf 'Stage 11: AscendNPU-IR CMake configure check (no compilation)\n'
printf 'cmake : %s  %s\n' "$(command -v cmake)" "$(cmake --version | head -n 1)"
printf 'ninja : %s  %s\n' "$(command -v ninja)" "$(ninja --version)"
printf 'llvm  : %s\n' "$LLVM_SRC/llvm"
printf 'repo  : %s\n' "$REPO_DIR"
printf 'build : %s\n\n' "$BUILD_DIR"

# 关键选项说明：
#   LLVM_TARGETS_TO_BUILD=host     只看 IR 层 Pass，不需要 RISC-V/ARM 等后端
#   LLVM_ENABLE_PROJECTS=mlir      上游 build.sh 的默认值
#   BISHENGIR_ENABLE_TRITON_COMPILE=ON
#        必需。bishengir/lib/Conversion/CMakeLists.txt 会无条件加入
#        TritonAscendGPUToLLVM，而它引用的 LLVM_EXTERNAL_TRITON_SOURCE_DIR
#        只在 triton 打开时才被赋值；triton 源码在仓库内 bishengir/triton/。
#   BISHENGIR_BUILD_HIVMC=OFF      跳过硬件编译器后端，本任务不需要
#   LLVM_USE_LINKER=gold           无 lld 时用 gold，静态链接更省内存
#   LLVM_PARALLEL_LINK_JOBS=1      限制链接并行，避免内存峰值
cmake "$LLVM_SRC/llvm" -G Ninja -B "$BUILD_DIR" \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_PROJECTS=mlir \
    -DLLVM_EXTERNAL_PROJECTS=bishengir \
    -DLLVM_EXTERNAL_BISHENGIR_SOURCE_DIR="$REPO_DIR" \
    -DLLVM_TARGETS_TO_BUILD=host \
    -DLLVM_ENABLE_ASSERTIONS=OFF \
    -DLLVM_ENABLE_LLD=OFF \
    -DLLVM_USE_LINKER=gold \
    -DLLVM_PARALLEL_LINK_JOBS=1 \
    -DBUILD_SHARED_LIBS=OFF \
    -DBSPUB_DAVINCI_BISHENGIR=ON \
    -DLLVM_BSPUB_DAVINCI_BISHENGIR=ON \
    -DLLVM_BSPUB_DAVINCI_BISHENGIR_A5=ON \
    -DLLVM_BSPUB_DAVINCI_BISHENGIR_A5_NPUIR=ON \
    -DBISHENGIR_ENABLE_PM_CL_OPTIONS=ON \
    -DBISHENGIR_ENABLE_TRITON_COMPILE=ON \
    -DBISHENGIR_BUILD_HIVMC=OFF \
    -DBISHENGIR_BUILD_TEMPLATE=OFF \
    -DSHMEM_BUILD_TEMPLATE=OFF \
    -DMLIR_ENABLE_BINDINGS_PYTHON=OFF

printf '\n[Target check]\n'
# 先把输出落到文件再匹配。直接 `ninja ... | grep -q` 会在命中后让 grep 提前退出，
# ninja 收到 SIGPIPE 返回非零，配合 set -o pipefail 会把整条管道判为失败。
TARGETS_FILE="$(mktemp)"
CMDS_FILE="$(mktemp)"
trap 'rm -f "$TARGETS_FILE" "$CMDS_FILE"' EXIT
ninja -C "$BUILD_DIR" -t targets all >"$TARGETS_FILE" 2>/dev/null

grep -oE '^(bishengir-opt|bishengir-compile|bishengir-translate|mlir-opt):' \
    "$TARGETS_FILE" | sort -u

if ! grep -q '^bishengir-opt:' "$TARGETS_FILE"; then
    printf 'ERROR: bishengir-opt target 未生成\n' >&2
    exit 1
fi
if grep -q '^hivmc:' "$TARGETS_FILE"; then
    printf 'ERROR: hivmc 意外出现，BISHENGIR_BUILD_HIVMC=OFF 未生效\n' >&2
    exit 1
fi

# 统计编译规模（-t commands 只列命令，不执行）
ninja -C "$BUILD_DIR" -t commands bishengir-opt >"$CMDS_FILE" 2>/dev/null
printf '\n[Scale estimate] 编译单元数（未执行）：%s\n' \
    "$(grep -cE 'clang\+\+.* -c ' "$CMDS_FILE" || true)"

printf '\n如果 hivmc 未出现且 bishengir-opt 已列出，则配置验证通过。\n'
printf '注意：本脚本只做配置，不编译。编译请另行执行：\n'
printf '  ninja -C %s bishengir-opt -j 6\n' "$BUILD_DIR"
printf '\nStage 11 AscendNPU-IR configure: PASS\n'
