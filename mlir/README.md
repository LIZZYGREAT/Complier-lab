# MLIR / AscendNPU IR 探索

本目录记录 Assignment 1 进阶部分的受控探索。项目中已有实验根目录是 `lab/`，因此本任务按仓库现有布局放在 `lab/mlir/`。

## 完成内容

- 保存 Ascend 官方 16×`i16` HIVM VecAdd 输入，并按 Arith/Tensor → HFusion → HIVM → 后续 HACC/LLVM 表示说明抽象层次变化。
- 解释 GM/UB、load、vadd、store 把内存层次和数据搬运策略显式带入 IR 的作用。
- 阅读官方 `hivm-plan-memory` 文档和上游 `plan-memory.mlir` Test Case；保存来源、测试片段和该用例中的 `RUN` / `CHECK`。
- 根据官方用例断言做 PlanMemory 结构分析。这里的 `CHECK` 是上游测试期望，不是本机产生的 Pass 输出。
- 保存只读环境检查、源码构建停止决策和 Pass 执行范围日志。

## 执行边界

系统既有的 CMake 缺失、Ninja 为 1.10.1（官方要求至少 1.12），因此**没有用系统工具链构建**。作为替代，CMake 4.4.4 与 Ninja 1.13.2 已通过 pip 安装在仓库外的用户级 venv `.venv-ascendnpu` 中，AscendNPU-IR 源码与其 LLVM 19.1.7 子模块也已按固定 commit 检出于 `../third_party/ascendnpu-ir`。

截至 `records/11_ascend_build_precheck.md`，**CMake 配置阶段已验证通过**，`bishengir-opt` target 确认生成，编译规模量化为 3123 个编译单元；但**尚未执行编译**，也没有运行任何 Pass。

因此 PlanMemory 目前仍是源码分析，`outputs/` 下没有 `plan_memory_before.mlir` / `plan_memory_after.mlir`。独立 Sync 用例跳过；同步仅在 VecAdd 与官方总体流程的层次说明中提及。

没有安装完整 CANN、配置驱动或使用 Ascend NPU；没有生成或运行 kernel `.o`。官方 VecAdd 是源码材料，不代表本机编译结果。已确认这些都不是本任务的必需项——CANN 只在"编 kernel `.o` 并上板执行"时才需要。

## 文件入口

- [VecAdd 输入](sources/vecadd_hivm.mlir)
- [PlanMemory 官方测试摘录](sources/selected_tests/plan_memory_input.mlir)
- [Lowering 主线](analysis/lowering_chain.md)
- [PlanMemory 分析](analysis/plan_memory_analysis.md)
- [官方来源索引](references/source_index.md)
- `logs/`：环境、构建决策、Pass 范围留痕
- `outputs/`：未运行 Pass，因此不保存伪造的 Before/After 文件

## 状态

| 项目 | 状态 |
| --- | --- |
| VecAdd 主线 | PASS |
| 官方资料和 Test Case 核对 | PASS |
| `bishengir-opt` 构建 | 配置已通过，编译未执行（见 `records/11_ascend_build_precheck.md`） |
| PlanMemory 实验 | ANALYSIS-ONLY |
| Sync 实验 | SKIPPED |
| CANN / NPU 上板 | NOT ATTEMPTED |
