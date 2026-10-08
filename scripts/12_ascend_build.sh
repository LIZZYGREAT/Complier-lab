#!/usr/bin/env bash
set -euo pipefail

# Stage 12: 编译 AscendNPU-IR 的 bishengir-opt（只这一个 target）。
#
# 前置：先跑 scripts/11_ascend_configure.sh 完成 CMake 配置。
#
# 并行度：本机 10 GiB 内存 + 3 GiB swap，是唯一已知风险。LLVM/MLIR 单个
# 编译单元约 0.5-1.5 GiB，故默认 -j 6 留出余量；可用 JOBS 覆盖：
#   JOBS=4 bash scripts/12_ascend_build.sh
#
# 预计耗时 1.5-3 小时，建议在后台运行并把输出写入 logs/。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$LAB_DIR/.." && pwd)"

REPO_DIR="$ROOT_DIR/third_party/ascendnpu-ir"
BUILD_DIR="$REPO_DIR/build"
VENV_BIN="$ROOT_DIR/.venv-ascendnpu/bin"
JOBS="${JOBS:-6}"

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ -f "$BUILD_DIR/build.ninja" ]] || die "未配置：先运行 scripts/11_ascend_configure.sh"
[[ -x "$VENV_BIN/ninja" ]] || die "缺少 $VENV_BIN/ninja"

export PATH="$VENV_BIN:$PATH"

printf 'Stage 12: build bishengir-opt\n'
printf 'build dir : %s\n' "$BUILD_DIR"
printf 'parallel  : -j %s\n' "$JOBS"
printf 'memory    : '; free -h | awk '/^Mem:/{print $7" available"}; /^Swap:/{print "            "$2" swap"}'
printf '\n'

START=$(date +%s)
ninja -C "$BUILD_DIR" bishengir-opt -j "$JOBS"
END=$(date +%s)

printf '\n[Build finished in %ss]\n' "$((END - START))"

BIN="$BUILD_DIR/bin/bishengir-opt"
[[ -x "$BIN" ]] || die "未找到可执行文件：$BIN"

printf '\n[Artifact]\n'
ls -la "$BIN"
printf '\n[Version]\n'
"$BIN" --version || true
printf '\n[Passes of interest]\n'
"$BIN" --help 2>&1 | grep -E "hivm-plan-memory|hivm-inject-sync|hacc-append-device-spec" || true

printf '\nStage 12 bishengir-opt build: PASS\n'
