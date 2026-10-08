# 阶段 12：编译 bishengir-opt

## 目标

在阶段 11 完成 CMake 配置验证的基础上，实际编译出 `bishengir-opt`，为第 8 节提供可运行的 Pass 工具。只构建这一个 target。

## 输入

- 阶段 11 配置好的构建目录 `../third_party/ascendnpu-ir/build`
- `scripts/12_ascend_build.sh`
- 并发度与内存约束：16 核 / 10 GiB 内存 / 3 GiB swap，故取 `-j 6`

## 执行命令

```bash
bash scripts/12_ascend_build.sh 2>&1 | tee logs/12_ascend_build.log
```

## 关键输出

最终成功：

```text
bishengir-opt 2.0.0 (https://gitcode.com/Ascend/ascendnpu-ir.git 2ac1b376da1d 2026-10-09)
llvm 19.1.7 06913395ef8a
Release build
```

产物 `build/bin/bishengir-opt`，180 MB，静态链接。

内存实测：编译期占用峰值约 4.8 GiB，**3 GiB swap 全程未被触发**。阶段 11 列为"唯一未验证风险"的 10 GiB 内存约束，实测不成立。

## 生成产物

仓库外：

- `../third_party/ascendnpu-ir/build/bin/bishengir-opt`：最终工具
- `../third_party/ascendnpu-ir/build/bin/FileCheck`：为逐条验证上游 CHECK 而单独构建
- `../third_party/ascendnpu-ir/build/`：完整构建树

仓库内：

- `scripts/12_ascend_build.sh`
- `logs/12_ascend_build.log`：含四次尝试的完整输出
- `scripts/patches/ascendnpu-ir-hivmc-link-order.patch`：对上游的一处必要修补
- `records/12_ascend_build.md`：本记录

## 结果解释

构建并非一次通过，前后四轮才成功。三次失败都在最后一步——先是生成头文件缺失，随后两次是链接期的符号缺失。三次都不是环境问题，而是**上游构建配置的缺陷在本机的具体组合下暴露出来**：

1. **生成头文件与编译步骤之间缺依赖边**（`SkewShapeTable.inc`）；
2. **`BISHENGIR_BUILD_HIVMC=OFF` 不可用**：编译库无条件引用 hivmc 符号；
3. **静态库存在真实循环**（`BiShengIRHIVMCLib` ↔ `BiShengIRHIVMCLibA3/A5`）。

第 3 条是真问题：A3/A5 的 `HIVMCMain*.cpp` 调用 `HIVMCLib` 的 `setSanitizerAddrArgName`，而 `HIVMCLib` 又调用 `runHIVMCCompileA3/A5`，构成静态库循环。CMake 按依赖顺序把 `HIVMCLib` 排在 A3/A5 之前，静态库单遍扫描无法解析，于是报 `undefined reference`。

用 CMake 的 `$<LINK_GROUP:RESCAN,...>` 解决：它让链接器对这组库重复扫描（GNU 工具链上生成 `--start-group/--end-group`），且**不建立 CMake 层面的依赖环**，因此不会与 OBJECT_LIBRARY 冲突。最初尝试的"补 `LINK_LIBS PUBLIC` + `LINK_INTERFACE_MULTIPLICITY`"被 CMake 直接拒绝（循环中含 OBJECT_LIBRARY 时不允许成环），该做法已回退。

需要说明的是：这是**本机为了跑通而做的一处补丁**（记录于 `scripts/patches/`），不是上游的正式修复。它只影响 `bishengir-opt` 这个可执行文件的链接参数，不改变任何 Pass 的行为。

另外，编译时未关闭 `MLIR_INCLUDE_TESTS`，导致 `bishengir-opt` 额外链接了一批 MLIR/Ascend 测试库（`MLIRLinalgTestPasses` 等）。对"跑 Pass"这一用途是多余的，重配时加 `-DLLVM_INCLUDE_TESTS=OFF -DMLIR_INCLUDE_TESTS=OFF` 可显著缩短构建时间。

## 验收结果

PASS — `bishengir-opt` 成功产出，版本自报与上游 commit 一致，且阶段 13 中全部上游 RUN 命令通过。

## 异常

见上"结果解释"的三条，详细过程见 `records/errors_and_fixes.md` 中 2026-10-08/09 的相关条目。
