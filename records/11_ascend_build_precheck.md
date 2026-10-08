# 阶段 11：AscendNPU-IR 构建环境预检（只配置，不编译）

## 目标

第 8 节目前是 ANALYSIS-ONLY：所有 Ascend 相关结论都来自官方文档和上游 Test Case，没有运行过 `bishengir-opt`。要把这一节升级为真实运行证据，必须先有一个可用的 `bishengir-opt`。

本阶段只做**低成本预检**：在不启动数小时编译的前提下，把"这条路能不能走通"的不确定项逐个消掉。具体要回答：

1. 构建 AscendNPU-IR 需要哪些前置条件，本机缺什么；
2. 是否需要 CANN、驱动或 NPU 硬件；
3. 是否需要改动系统环境；
4. CMake 配置阶段能否通过，`bishengir-opt` 这个 target 能否生成；
5. 编译规模量级，以及唯一剩余风险是什么。

## 输入

- 课程 `docs/AscendNPU_IR.md` 划定的任务边界（进阶 1 分、允许退化为资料分析、有明确停止条件）
- 本机环境：Ubuntu 22.04.5 / WSL2，Clang 14.0.0，GCC 11.4.0，16 核，内存 10 GiB
- 上游官方文档《Build and Installation》
- 上游仓库 `https://gitcode.com/Ascend/ascendnpu-ir.git`

## 执行命令

```bash
# 1. 隔离安装 CMake / Ninja（不改系统）
python3 -m venv ../.venv-ascendnpu
../.venv-ascendnpu/bin/python -m pip install cmake ninja

# 2. 克隆 AscendNPU-IR
git clone --depth 1 https://gitcode.com/Ascend/ascendnpu-ir.git ../third_party/ascendnpu-ir

# 3. 按固定 SHA 取 LLVM 子模块（blobless，单分支）
git clone --filter=blob:none --single-branch \
    --branch "Ascend/AscendNPU-IR/llvmorg-19.1.7" \
    https://gitcode.com/Ascend/llvm-project.git llvm-project
git -C llvm-project checkout 06913395ef8aca66a9814723f4ccc616570b0fed

# 4. 只做 CMake 配置验证
bash scripts/11_ascend_configure.sh
```

上述 1–3 步的产物都在 `lab/` 仓库之外（`../.venv-ascendnpu`、`../third_party/`），不进入版本管理。

## 关键输出

### 环境条件

| 要求 | 官方最低 | 本机 | 结论 |
| --- | --- | --- | --- |
| CMake | ≥ 3.28 | 系统缺失 → pip 装到 4.4.4 | 解决 |
| Ninja | ≥ 1.12.0 | 系统 1.10.1 → pip 装到 1.13.2 | 解决 |
| Clang | ≥ 10 | 14.0.0 | 满足 |
| LLD | ≥ 10（推荐） | 缺失 | 用 GNU gold 代替 |
| 磁盘 | — | 空闲 935 GB（LLVM 检出 2.8 GB） | 满足 |
| 内存 | — | 10 GiB | **唯一剩余风险** |

### 不需要 CANN、驱动或硬件

上游文档原文是 "End-to-end execution of AscendNPU IR depends on the CANN environment"，即只有"编译出 kernel `.o` 并在设备上执行"才需要 CANN。阅读 `build-tools/build.sh` 进一步确认：CANN 路径只出现在可选参数 `--bisheng-compiler`（供模板库使用，需 CANN 9.0.0），基础构建不引用它。

因此本任务（对 `.mlir` 运行 IR Pass 并观察 Before/After）不需要 CANN、不需要驱动、不需要 NPU 卡。

### 子模块全部来自 gitcode，不依赖 github

```
third-party/llvm-project → https://gitcode.com/Ascend/llvm-project.git   (LLVM 19.1.7)
third-party/torch-mlir   → https://gitcode.com/Ascend/torch-mlir.git
third-party/shmem        → https://gitcode.com/cann/shmem.git
```

这一点有实际意义：本次执行期间 github.com 一度无法直连，而 gitcode 始终可达，所以源码获取不受影响。只有 `torch-mlir` 与 `shmem` 是可选路径（分别对应 `--build-torch-mlir` 和模板库构建），本任务未克隆。

### 两个必须避开的坑

**坑一：`BISHENGIR_BUILD_STANDALONE_IR_ONLY=ON` 不能用。** 该选项名称容易被误解为"只构建 IR 工具"，但读 `CMakeLists.txt` 可见：

```cmake
if(NOT BISHENGIR_BUILD_STANDALONE_IR_ONLY)
  add_subdirectory(bishengir/tools)     # bishengir-opt 在这里
endif()
```

打开它之后 `bishengir/tools` 与 `bishengir/lib` 都不会被加入，**既不产出 `bishengir-opt`，也不编译任何 Pass**。必须走完整构建，用 `-DBISHENGIR_BUILD_HIVMC=OFF` 跳过不需要的硬件编译器后端。

**坑二：`build.sh` 默认执行全量 `ninja`。** 其 `cmake_build()` 直接跑 `ninja -j THREADS`。本任务只需一个可执行文件，应改为显式指定 target：`ninja -C build bishengir-opt`。

### 配置阶段结果

```
Configuring done (107.9s)
Generating done  (24.5s)
CONFIGURE_EXIT=0
```

Target 校验（这是"配置真的通过"而非"假通过"的证据）：

| Target | 结果 |
| --- | --- |
| `bishengir-opt` | 生成 |
| `bishengir-compile` | 生成 |
| `bishengir-translate` | 生成 |
| `mlir-opt` | 生成 |
| `hivmc` | 已按预期排除（0 条） |

### 编译规模量级

`ninja -t commands bishengir-opt`（只列命令，不执行）：

- **3123 条 C++ 编译命令**
- 10 条链接命令

按 16 核、受内存限制实际取 `-j 6` 估算，完整编译约需 1.5–3 小时。

### 顺带发现的报告错误

用本地真实检出核对上游 Test Case 时，发现此前保存的 PlanMemory `RUN` 命令**被简化过，丢失了必需参数**：

```diff
- bishengir-opt %s -hivm-plan-memory -split-input-file -verify-diagnostics | FileCheck %s
+ bishengir-opt %s -hacc-append-device-spec=target=Ascend910B1 -hivm-plan-memory -split-input-file -verify-diagnostics | FileCheck %s
```

该参数在 `bishengir/include/bishengir/Dialect/HACC/Transforms/Passes.td` 中注册为 `AppendTargetDeviceSpec`；PlanMemory 需要目标芯片规格才能应用对齐与容量约束，缺少该参数时命令无法执行。该偏差出现在摘录、分析记录、本阶段前序记录和报告正文四处，均已在提交 `769473f` 中修正，并补记了来源 commit 与第二条 `RUN`（`plan-memory-strategy=largest-first`）。

同时确认第 8 节引用的两个测试文件确实存在：`bishengir/test/Dialect/HIVM/plan-memory.mlir` 与 `inject-sync.mlir`。

## 生成产物

仓库外（不进版本管理）：

- `../.venv-ascendnpu/`：隔离的 CMake 4.4.4 / Ninja 1.13.2
- `../third_party/ascendnpu-ir/`：AscendNPU-IR 源码（commit `2ac1b376da1d4d4f263f41622a41e495370ea234`）
- `../third_party/ascendnpu-ir/third-party/llvm-project/`：LLVM 19.1.7（`06913395ef8aca66a9814723f4ccc616570b0fed`，2.8 GB）
- `../third_party/ascendnpu-ir/build/`：CMake 配置产物（已生成，未编译）

仓库内：

- `scripts/11_ascend_configure.sh`：配置验证脚本（可重跑，不会触发编译）
- `logs/11_ascend_configure.log`：配置与 target 校验的实际输出
- `records/11_ascend_build_precheck.md`：本记录

脚本已端到端验证通过（exit 0），标准执行形式同其他阶段：

```bash
bash scripts/11_ascend_configure.sh 2>&1 | tee logs/11_ascend_configure.log
```

## 结果解释

预检把原先"缺少 CMake、Ninja 版本不足"这一条笼统的阻塞，拆成了可执行的具体结论：

1. 前置条件有两个缺口，但都能用 pip 在**用户级 venv** 内补齐，无需 `sudo`、无需改动系统；
2. CANN 与硬件不是必需项，任务边界可以保持在"IR 层 Pass 实验"；
3. 源码获取路径不依赖 github；
4. 配置阶段通过，`bishengir-opt` target 确认存在；
5. 剩下的不确定性只有一个——**10 GiB 内存能否撑住 3123 个编译单元以及最后对 `bishengir-opt` 的静态链接**。

关于第 5 点，已经采取的对冲措施有：`-DLLVM_TARGETS_TO_BUILD=host` 砍掉无关后端、`-DLLVM_USE_LINKER=gold` 降低链接期内存、`-DLLVM_PARALLEL_LINK_JOBS=1` 限制链接并行、`-DBISHENGIR_BUILD_HIVMC=OFF` 少编一个后端。但这些措施是否足够，只有真正开始编译才能验证。

需要强调的是：**本阶段没有产出任何 Ascend 运行证据**。`mlir/outputs/` 仍然为空，报告中第 8 节仍应保持 ANALYSIS-ONLY 的表述，直到真正运行 `bishengir-opt` 并捕获 Before/After。

## 验收结果

PASS（就"配置验证"这一范围而言）——CMake 配置成功，`bishengir-opt` 等 target 确认生成，编译规模已量化，未执行任何编译。

## 异常

### 第一次配置失败：缺少 Triton 源码路径

原始报错：

```
CMake Error at cmake/modules/AddLLVM.cmake:568 (add_library):
  Cannot find source file:
    /lib/Conversion/TritonGPUToLLVM/MemoryOpToLLVM.cpp
```

路径前缀为空，说明 `LLVM_EXTERNAL_TRITON_SOURCE_DIR` 未被赋值。

原因：`bishengir/lib/Conversion/CMakeLists.txt` **无条件**加入 `TritonAscendGPUToLLVM`，而该库引用的 `LLVM_EXTERNAL_TRITON_SOURCE_DIR` 只在顶层 `CMakeLists.txt` 的 `if(BISHENGIR_ENABLE_TRITON_COMPILE)` 分支内才被设置。上游 `build.sh` 的 `BUILD_TRITON` 默认为 `ON`，会带上 `-DBISHENGIR_ENABLE_TRITON_COMPILE=ON`；手写 cmake 命令时漏了该参数。

修改：补上 `-DBISHENGIR_ENABLE_TRITON_COMPILE=ON`。同时确认 **triton 源码无需额外下载**，它就在仓库内 `bishengir/triton/`（9.4 MB），因为 `BISHENGIR_SRC_DIR = <repo>/bishengir`，所以 `${BISHENGIR_SRC_DIR}/triton` 指向正确位置。

重新执行：删除半途失败的 `build/` 目录后重新配置，一次通过。

另注：`--disable-build-triton` 并非可行退路——即使关掉 triton，`Conversion/CMakeLists.txt` 仍会无条件加入那个子目录，只是变量为空，错误依旧。
