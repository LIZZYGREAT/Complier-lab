# 错误与修复记录

本文件按执行方案要求，记录实验过程中真实遇到的问题、原始报错、原因、修改方式和最终结果。没有问题的阶段不在此处虚增条目。

---

## 2026-10-07 / 阶段 0：设置全局 Git 身份

### 问题

需要在 `lab/` 仓库中提交实验产物，但提交前必须配置 Git 身份；用户家目录相关配置写入受限。

### 原始报错

尝试写入全局 Git 配置时，因家目录只读限制失败。

### 原因

运行环境对家目录的写权限受限，`git config --global` 无法落盘。

### 修改

未绕过限制、未改动系统配置。向用户说明该限制并取得明确授权后，才写入全局身份 `LIZZYGREAT <2660550447@qq.com>`。

### 重新执行

授权后重新执行配置命令，写入成功。

### 最终结果

Git 身份可用，`lab/` 仓库随后完成 Stage 0–10 的本地提交。未触碰 `SysY_Compiler_2025` 中的既有改动。

---

## 2026-10-07 / 阶段 8：源码构建 AscendNPU-IR 的前置条件不满足

### 问题

进阶部分原计划优先尝试源码构建 `bishengir-opt` 并运行真实 HIVM Pass。

### 原始报错

```text
cmake: command not found
ninja --version → 1.10.1
```

### 原因

AscendNPU-IR 官方构建要求 CMake ≥ 3.28、Ninja ≥ 1.12。本机没有 CMake，Ninja 版本低于最低要求。

按执行方案，此时不允许 `sudo apt upgrade`、覆盖系统 cmake/ninja 或大规模修改现有编译原理环境。

### 修改

按方案中预先约定的 Stage 1B 退路执行：不构建工具，改为「官方资料 + 上游源码 Test Case」分析路线。

### 重新执行

未重新执行构建。改为保存官方 VecAdd 输入、PlanMemory 上游测试片段及其原始 `RUN`/`CHECK`，并分析 HIVM 层的结构。

### 最终结果

Stage 8 标记为 PASS（范围说明为 ANALYSIS-ONLY）。`mlir/outputs/` 下不生成 Before/After 文件，报告中明确区分「本机运行结果」与「官方资料分析」。该限制已在 `mlir/README.md`、`records/08_mlir_exploration.md` 和报告正文中三处声明。

---

## 2026-10-08 / 阶段 10：报告修订时 Tectonic 下载中断

### 问题

修订报告后重新执行 `scripts/10_build_report.sh`，脚本需要下载隔离的 Tectonic 0.16.9。

### 原始报错

```text
curl: (56) OpenSSL SSL_read: error:0A000126:SSL routines::unexpected eof while reading, errno 0
```

### 原因

下载过程中连接被对端中断，属于网络波动，与脚本本身或报告源文件无关。脚本每次运行都在临时目录重新下载，因此该次失败会直接中断构建。

### 修改

未修改构建脚本的既有校验逻辑（校验和比对保持不变）。改为把 Tectonic 二进制下载到用户缓存目录 `~/.cache/compiler-labs/bin/`，并通过脚本已支持的 `TECTONIC_BIN` 环境变量复用，避免每次重新下载。

### 重新执行

使用带重试的下载取得二进制并通过 SHA-256 校验后，以 `TECTONIC_BIN` 指向该文件重新构建。

### 最终结果

报告编译成功，`report/report.pdf` 正常更新。此修改只影响本机构建便利性，不改变报告内容与校验方式。

---

## 2026-10-08 / 阶段 11：CMake 配置找不到 Triton 源码

### 问题

首次执行 AscendNPU-IR 的 CMake 配置验证时，配置阶段报错中止。

### 原始报错

```text
CMake Error at cmake/modules/AddLLVM.cmake:568 (add_library):
  Cannot find source file:
    /lib/Conversion/TritonGPUToLLVM/MemoryOpToLLVM.cpp
```

路径前缀为空，说明变量 `LLVM_EXTERNAL_TRITON_SOURCE_DIR` 未被赋值。

### 原因

两层原因叠加：

1. `bishengir/lib/Conversion/CMakeLists.txt` **无条件**加入 `TritonAscendGPUToLLVM` 子目录，而该库的源文件列表引用了 `${LLVM_EXTERNAL_TRITON_SOURCE_DIR}/lib/...`。
2. `LLVM_EXTERNAL_TRITON_SOURCE_DIR` 只在顶层 `CMakeLists.txt` 的 `if(BISHENGIR_ENABLE_TRITON_COMPILE)` 分支内才被设置。上游 `build.sh` 的 `BUILD_TRITON` 默认为 `ON`，会自动带上 `-DBISHENGIR_ENABLE_TRITON_COMPILE=ON`；手写 cmake 命令时漏掉了该参数，于是变量为空。

同时确认 `--disable-build-triton` 不是可行退路：即便关掉 triton，那个子目录仍会被无条件加入，错误依旧。

### 修改

补上 `-DBISHENGIR_ENABLE_TRITON_COMPILE=ON`，并确认 triton 源码**无需额外下载**——它就在仓库内 `bishengir/triton/`（9.4 MB），因为 `BISHENGIR_SRC_DIR = <repo>/bishengir`，所以 `${BISHENGIR_SRC_DIR}/triton` 指向正确位置。

### 重新执行

删除半途失败、缓存不可信的 `build/` 目录后重新配置。

### 最终结果

配置一次通过（`Configuring done 107.9s`、`Generating done 24.5s`、exit 0），`bishengir-opt` 等 target 确认生成。修正后的完整命令已固化为 `scripts/11_ascend_configure.sh`。

---

## 2026-10-08 / 阶段 11：配置脚本的 target 检查误报失败

### 问题

`scripts/11_ascend_configure.sh` 首次运行时，CMake 配置已经成功（`Configuring done` / `Generating done`），同一脚本上方也正确打印出了 `bishengir-opt:`，但脚本随后判定「bishengir-opt target 未生成」并以非零码退出。

### 原始报错

```text
[Target check]
bishengir-compile:
bishengir-opt:
bishengir-translate:
mlir-opt:
ERROR: bishengir-opt target 未生成
```

### 原因

脚本自身的缺陷，与上游无关。原写法是：

```bash
if ninja -C "$BUILD_DIR" -t targets all 2>/dev/null | grep -q '^bishengir-opt:'; then
```

在 `set -euo pipefail` 下，`grep -q` 一旦命中就立即退出并关闭管道，`ninja` 因此收到 SIGPIPE 并返回非零；`pipefail` 让整条管道的状态取到这个非零值，于是 `if` 判为假。命中越早，误报越稳定。

### 修改

不再对管道使用 `grep -q`：先把 `ninja -t targets all` 的输出落到临时文件，再对文件匹配；同时把「hivmc 不应出现」也做成显式校验，并在脚本退出时清理临时文件。

### 重新执行

`bash scripts/11_ascend_configure.sh` 端到端通过（exit 0），输出 target 列表、编译单元数 3123，并以 `Stage 11 AscendNPU-IR configure: PASS` 收尾。完整输出留存于 `logs/11_ascend_configure.log`。

### 最终结果

脚本可作为后续复现配置的入口。这个坑本身也值得记下来：在 `pipefail` 下用 `grep -q` 提前退出会污染管道状态。

---

## 2026-10-08 / 阶段 12：生成的 SkewShapeTable.inc 找不到

### 问题

首次执行 `ninja -C build bishengir-opt -j 6`，编译到 3901/4707 步时中止。

### 原始报错

```text
bishengir/lib/Dialect/HIVM/Utils/ShapeRegistry.cpp:23:10: fatal error:
  'SkewShapeTable.inc' file not found
```

### 原因

`SkewShapeTable.inc` 由 `build-tools/coverage/shape_registry.py` 经 `add_custom_command` 生成，并挂在 `BiShengIRSkewShapeTable` 目标上；但把它 include 进来的 `ShapeRegistry.cpp`（编译进 `obj.BiShengIRHIVMTransforms`）与该生成步骤之间**没有 order-only 依赖边**。`-j 6` 下编译抢在生成之前启动，于是找不到文件。核验 `build.ninja` 可见该库在链接行中出现的次数与依赖关系都表明依赖未生效。

### 修改

未改动上游源码。改为先生成该文件，再续跑增量构建：

```bash
ninja -C build BiShengIRSkewShapeTable
```

文件生成后即成为稳定的输入，后续编译都能找到。

### 重新执行

续跑后 `ShapeRegistry.cpp.o` 正常编译，越过该失败点。

### 最终结果

该问题不再出现。但后续暴露了另外两个链接期问题（见下两条）。

---

## 2026-10-08 / 阶段 12：`BISHENGIR_BUILD_HIVMC=OFF` 导致链接失败

### 问题

编译全部完成后，链接 `bin/bishengir-opt` 失败。

### 原始报错

```text
undefined reference to 'hivmcCanonicalizePath(llvm::SmallString<128u>&)'
undefined reference to 'bishengir::runHIVMCCompileA3(mlir::ModuleOp, bishengir::HIVMCMainConfig)'
undefined reference to 'bishengir::runHIVMCCompileA5(mlir::ModuleOp, bishengir::HIVMCMainConfig)'
```

### 原因

这是本实验自己的配置选择造成的。阶段 11 中为了"跳过用不到的硬件后端"设了 `-DBISHENGIR_BUILD_HIVMC=OFF`，但 `BiShengIRCompileMain.cpp` **无条件**引用上述 hivmc 符号，把它们编译掉了就没人提供定义。上游 `build.sh` 的默认值本来就是 `ON`。

### 修改

将配置改回 `-DBISHENGIR_BUILD_HIVMC=ON`（`scripts/11_ascend_configure.sh` 中的注释已同步更正并说明原因）。

### 重新执行

重配后编译 15 个步骤（hivmc 相关库）并重新链接。

### 最终结果

hivmc 符号解决，但暴露出第三个问题（见下条）。结论：`BISHENGIR_BUILD_HIVMC=OFF` 不是可用的省事选项。

---

## 2026-10-09 / 阶段 12：静态库循环导致 `setSanitizerAddrArgName` 未定义

### 问题

启用 hivmc 后重新链接 `bin/bishengir-opt`，仍报未定义符号。

### 原始报错

```text
lib/libBiShengIRHIVMCLibA5.a(HIVMCMainA5.cpp.o): error: undefined reference to
  'bishengir::setSanitizerAddrArgName(mlir::ModuleOp, std::unique_ptr<llvm::Module> const&)'
lib/libBiShengIRHIVMCLibA3.a(HIVMCMainA3.cpp.o): 同一符号
```

### 原因

上游存在**真实的静态库循环**：

- `HIVMCMainA5.cpp` / `HIVMCMainA3.cpp` 调用 `BiShengIRHIVMCLib` 的 `setSanitizerAddrArgName`；
- 而 `BiShengIRHIVMCLib` 的 CMakeLists 又 `LINK_LIBS PUBLIC BiShengIRHIVMCLibA3 BiShengIRHIVMCLibA5`（它调用 `runHIVMCCompileA3/A5`）。

CMake 按依赖关系把 `BiShengIRHIVMCLib` 排在 A3/A5 之前，而静态库是单遍扫描，扫描到 `HIVMCLib` 时还没有任何未解析引用指向它，等 A3/A5 需要该符号时已经错过了。核验链接行，三个库各只出现 **1 次**。

附带确认这**不是链接器差异**：把同一条链接命令的 `-fuse-ld=gold` 改成 `-fuse-ld=bfd` 后同样失败。

### 修改

**第一次尝试（失败）**：在 A3/A5 的 CMakeLists 里补 `LINK_LIBS PUBLIC BiShengIRHIVMCLib` 并设 `LINK_INTERFACE_MULTIPLICITY 3`。CMake 直接拒绝：

```text
At least one of these targets is not a STATIC_LIBRARY.
Cyclic dependencies are allowed only among static libraries.
```

因为该循环牵涉 `obj.BiShengIRHIVMCLib`（OBJECT_LIBRARY），而 CMake 只允许静态库之间成环。该做法已回退。

**第二次尝试（成功）**：改用 CMake 的链接组特性，在 `bishengir/tools/bishengir-opt/CMakeLists.txt` 中追加：

```cmake
target_link_libraries(bishengir-opt PRIVATE
  "$<LINK_GROUP:RESCAN,BiShengIRHIVMCLib,BiShengIRHIVMCLibA3,BiShengIRHIVMCLibA5>")
```

它在 GNU 工具链上生成 `--start-group` / `--end-group`，让链接器对这组库重复扫描，且**不建立 CMake 层面的依赖环**，因此不与 OBJECT_LIBRARY 冲突。补丁保存于 `scripts/patches/ascendnpu-ir-hivmc-link-order.patch`。

### 重新执行

重配并重新链接，`bin/bishengir-opt`（180 MB）成功产出。

### 最终结果

PASS。需明确：这是**本机为跑通所打的补丁**，不是上游的正式修复；它只影响该可执行文件的链接参数，不改变任何 Pass 的行为。阶段 13 中三个上游 RUN 命令连同 FileCheck 断言全部通过，说明 Pass 行为与上游期望一致。

---

## 说明

阶段 1–7、9 的日志与记录中「异常」均为「无」，即在这些阶段未发生需要修复的错误，因此不在此处补记条目。所有阶段记录见 `records/00_environment.md` 至 `records/10_report.md`。
